"""JWT refresh token storage with rotation and revocation."""

import redis.asyncio as aioredis

from app.core.config import Settings
from app.core.logging import get_logger
from app.core.security import (
    TOKEN_TYPE_REFRESH,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.domains.common.exceptions import AuthenticationError
from app.domains.user.models import User
from app.domains.user.repository import UserRepository
from app.domains.user.schemas import UserResponse

logger = get_logger(__name__)


class TokenService:
    """Manages refresh tokens in Redis for rotation and logout invalidation."""

    def __init__(self, redis: aioredis.Redis, settings: Settings) -> None:
        self.redis = redis
        self.settings = settings

    def _refresh_key(self, jti: str) -> str:
        return f"auth:refresh:{jti}"

    async def _store_refresh_jti(self, jti: str, user_id: str) -> None:
        ttl = self.settings.jwt_refresh_token_expire_days * 86400
        await self.redis.setex(self._refresh_key(jti), ttl, user_id)

    async def issue_tokens(self, user: User) -> dict:
        """Create access + refresh tokens and store refresh jti in Redis."""
        access = create_access_token(user.id, self.settings)
        refresh, jti = create_refresh_token(user.id, self.settings)
        await self._store_refresh_jti(jti, str(user.id))
        logger.info("tokens_issued", user_id=str(user.id))
        return {
            "access_token": access,
            "refresh_token": refresh,
            "token_type": "bearer",
            "expires_in": self.settings.jwt_access_token_expire_minutes * 60,
            "user": UserResponse.model_validate(user),
        }

    async def rotate_refresh_token(
        self,
        refresh_token: str,
        user_repo: UserRepository,
    ) -> dict:
        """Validate refresh token, revoke old jti, issue new token pair (rotation)."""
        payload = decode_token(refresh_token, self.settings)
        if payload is None or payload.token_type != TOKEN_TYPE_REFRESH or not payload.jti:
            raise AuthenticationError("Invalid or expired refresh token")

        key = self._refresh_key(payload.jti)
        stored_user_id = await self.redis.get(key)
        if stored_user_id is None or stored_user_id != payload.sub:
            raise AuthenticationError("Refresh token has been revoked or is invalid")

        user = await user_repo.get_by_id(payload.user_id)
        if user is None or not user.is_active:
            raise AuthenticationError("User not found or inactive")

        await self.redis.delete(key)
        logger.info("refresh_token_rotated", user_id=payload.sub)
        return await self.issue_tokens(user)

    async def revoke_refresh_token(self, jti: str) -> None:
        await self.redis.delete(self._refresh_key(jti))
        logger.info("refresh_token_revoked", jti=jti)

    async def revoke_by_token_string(self, refresh_token: str) -> None:
        payload = decode_token(refresh_token, self.settings)
        if payload and payload.jti:
            await self.revoke_refresh_token(payload.jti)