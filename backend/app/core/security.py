"""
Security utilities: JWT tokens and Argon2 password hashing.

Design notes:
  - Access tokens are short-lived JWTs (stateless verification).
  - Refresh tokens carry a unique `jti` stored in Redis for rotation/revocation.
  - Passwords are hashed with Argon2 (memory-hard, resistant to GPU attacks).

EXTENDING FOR OAUTH (Google / Apple):
  1. Add TOKEN_TYPE_OAUTH = "oauth" and provider claim in access token payload.
  2. After OAuth callback, call create_access_token(user_id, extra_claims={"provider": "google"}).
  3. Store OAuth refresh tokens separately or map provider sub → user.id in DB.
  4. See domains/auth/providers/oauth/ for the provider interface skeleton.
"""

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import Settings, get_settings

TOKEN_TYPE_ACCESS = "access"
TOKEN_TYPE_REFRESH = "refresh"
TOKEN_TYPE_OAUTH = "oauth"  # Reserved for Google / Apple Sign In


def _build_password_context(settings: Settings) -> CryptContext:
    return CryptContext(
        schemes=["argon2"],
        deprecated="auto",
        argon2__time_cost=settings.argon2_time_cost,
        argon2__memory_cost=settings.argon2_memory_cost,
        argon2__parallelism=settings.argon2_parallelism,
    )


class TokenPayload:
    """Decoded JWT payload."""

    def __init__(
        self,
        sub: str,
        token_type: str,
        exp: datetime,
        jti: str | None = None,
        provider: str | None = None,
    ) -> None:
        self.sub = sub
        self.token_type = token_type
        self.exp = exp
        self.jti = jti
        self.provider = provider

    @property
    def user_id(self) -> UUID:
        return UUID(self.sub)


def create_access_token(
    user_id: UUID,
    settings: Settings | None = None,
    extra_claims: dict[str, Any] | None = None,
) -> str:
    """
    Create a short-lived JWT access token.

    For OAuth flows, pass extra_claims={"provider": "google"} to tag the session.
    """
    settings = settings or get_settings()
    expire = datetime.now(UTC) + timedelta(minutes=settings.jwt_access_token_expire_minutes)
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "type": TOKEN_TYPE_ACCESS,
        "exp": expire,
        "iat": datetime.now(UTC),
    }
    if extra_claims:
        payload.update(extra_claims)
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def create_refresh_token(
    user_id: UUID,
    settings: Settings | None = None,
) -> tuple[str, str]:
    """
    Create a long-lived JWT refresh token with unique jti for rotation.
    Returns (token_string, jti).
    """
    settings = settings or get_settings()
    jti = str(uuid.uuid4())
    expire = datetime.now(UTC) + timedelta(days=settings.jwt_refresh_token_expire_days)
    payload = {
        "sub": str(user_id),
        "type": TOKEN_TYPE_REFRESH,
        "jti": jti,
        "exp": expire,
        "iat": datetime.now(UTC),
    }
    token = jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)
    return token, jti


def decode_token(token: str, settings: Settings | None = None) -> TokenPayload | None:
    """Decode and validate a JWT. Returns None if invalid or expired."""
    settings = settings or get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        sub = payload.get("sub")
        token_type = payload.get("type")
        exp = payload.get("exp")
        if not sub or not token_type or not exp:
            return None
        return TokenPayload(
            sub=sub,
            token_type=token_type,
            exp=datetime.fromtimestamp(exp, tz=UTC),
            jti=payload.get("jti"),
            provider=payload.get("provider"),
        )
    except JWTError:
        return None


def hash_password(password: str, settings: Settings | None = None) -> str:
    """Hash a password using Argon2. Never store plaintext passwords."""
    settings = settings or get_settings()
    return _build_password_context(settings).hash(password)


def verify_password(
    plain_password: str,
    hashed_password: str,
    settings: Settings | None = None,
) -> bool:
    """Constant-time Argon2 verification."""
    settings = settings or get_settings()
    return _build_password_context(settings).verify(plain_password, hashed_password)