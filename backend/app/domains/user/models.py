"""
User domain ORM model.

Fields map to API as:
  full_name  → name
  phone      → phone_number

FUTURE OAUTH:
  Add optional columns: auth_provider (password|google|apple), oauth_provider_id
  Or a separate user_identities table for multiple linked providers per user.
"""

from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Core user entity.

    Account is created only after WhatsApp OTP verification during signup.
    Password is stored as Argon2 hash — never plaintext.
    """

    __tablename__ = "users"

    # Identity
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True, nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, index=True, nullable=True)

    # Credentials (null for OAuth-only users in future)
    hashed_password: Mapped[str | None] = mapped_column(String(512), nullable=True)

    # Status flags
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    phone_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email} phone={self.phone}>"