"""OTP-based login for existing users."""

import redis.asyncio as aioredis

from app.core.config import Settings
from app.core.logging import get_logger
from app.domains.auth.providers import get_otp_provider
from app.domains.auth.services.otp_store import LoginOTPStore
from app.domains.common.exceptions import AuthenticationError
from app.domains.user.models import User
from app.domains.user.repository import UserRepository

logger = get_logger(__name__)


class LoginOTPService:
    """Send and verify WhatsApp OTP for registered users."""

    def __init__(
        self,
        redis: aioredis.Redis,
        settings: Settings,
        user_repo: UserRepository,
    ) -> None:
        self.settings = settings
        self.user_repo = user_repo
        self.otp_store = LoginOTPStore(redis, settings)
        self.otp_provider = get_otp_provider(settings)

    async def request_otp(self, phone_number: str) -> None:
        """Send login OTP to a registered, active user's phone."""
        phone = UserRepository.normalize_phone(phone_number)
        user = await self.user_repo.get_by_phone(phone)

        if user is None or not user.is_active:
            # Do not reveal whether the phone is registered
            logger.warning("login_otp_skipped", phone=phone, reason="user_not_found_or_inactive")
            return

        otp = await self.otp_store.create_login_session(phone=phone)
        await self.otp_provider.send_otp(phone, otp, self.settings.otp_expire_minutes)
        logger.info("login_otp_sent", phone=phone, user_id=str(user.id))

    async def verify_otp(self, phone_number: str, otp: str) -> User:
        """Verify login OTP and return the authenticated user."""
        phone = UserRepository.normalize_phone(phone_number)
        await self.otp_store.verify_and_consume(phone, otp)

        user = await self.user_repo.get_by_phone(phone)
        if user is None or not user.is_active:
            raise AuthenticationError("Invalid phone number or OTP")

        logger.info("login_otp_verified", user_id=str(user.id), phone=phone)
        return user