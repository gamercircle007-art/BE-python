"""Phone + password login with brute-force protection."""

import redis.asyncio as aioredis

from app.core.config import Settings
from app.core.logging import get_logger
from app.core.security import verify_password
from app.domains.common.exceptions import AuthenticationError, RateLimitError
from app.domains.user.models import User
from app.domains.user.repository import UserRepository

logger = get_logger(__name__)


class LoginService:
    """Handles credential-based login with Redis-backed lockout."""

    def __init__(
        self,
        redis: aioredis.Redis,
        settings: Settings,
        user_repo: UserRepository,
    ) -> None:
        self.redis = redis
        self.settings = settings
        self.user_repo = user_repo

    def _attempts_key(self, phone: str) -> str:
        return f"auth:login_attempts:{phone}"

    def _lockout_key(self, phone: str) -> str:
        return f"auth:login_lockout:{phone}"

    async def _is_locked_out(self, phone: str) -> bool:
        return await self.redis.exists(self._lockout_key(phone)) > 0

    async def _record_failed_attempt(self, phone: str) -> None:
        key = self._attempts_key(phone)
        count = await self.redis.incr(key)
        if count == 1:
            await self.redis.expire(key, self.settings.login_lockout_minutes * 60)

        if count >= self.settings.login_max_attempts:
            await self.redis.setex(
                self._lockout_key(phone),
                self.settings.login_lockout_minutes * 60,
                "1",
            )
            await self.redis.delete(key)
            logger.warning("account_locked", phone=phone)
            raise RateLimitError(
                f"Account temporarily locked due to too many failed attempts. "
                f"Try again in {self.settings.login_lockout_minutes} minutes."
            )

    async def _clear_attempts(self, phone: str) -> None:
        await self.redis.delete(self._attempts_key(phone))

    async def authenticate(self, phone_number: str, password: str) -> User:
        """Verify phone + password. Raises AuthenticationError on failure."""
        phone = UserRepository.normalize_phone(phone_number)

        if await self._is_locked_out(phone):
            logger.warning("login_blocked_lockout", phone=phone)
            raise RateLimitError(
                "Account temporarily locked. Please try again later."
            )

        user = await self.user_repo.get_by_phone(phone)

        # Generic message — never reveal whether phone exists
        invalid_msg = "Invalid phone number or password"

        if user is None or not user.is_active or not user.hashed_password:
            await self._record_failed_attempt(phone)
            logger.warning("login_failed", phone=phone, reason="user_not_found_or_inactive")
            raise AuthenticationError(invalid_msg)

        if not verify_password(password, user.hashed_password, self.settings):
            await self._record_failed_attempt(phone)
            logger.warning("login_failed", phone=phone, reason="invalid_password")
            raise AuthenticationError(invalid_msg)

        await self._clear_attempts(phone)
        logger.info("login_success", user_id=str(user.id), phone=phone)
        return user