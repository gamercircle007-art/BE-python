"""
Email OTP provider — STUB for future implementation.

TO ENABLE:
  1. Set EMAIL_OTP_ENABLED=true and configure EMAIL_* vars in .env
  2. Add AUTH_METHODS=whatsapp_otp,password,email_otp
  3. Implement send_otp using fastapi-mail (see domains/common/notifications.py)
  4. Register in providers/__init__.py: OTP_PROVIDER=email
  5. Update SignupService to accept channel parameter
"""

from app.core.config import Settings
from app.core.logging import get_logger
from app.domains.auth.providers.base import OTPChannel, OTPProvider
from app.domains.common.exceptions import DomainError

logger = get_logger(__name__)


class EmailOTPProvider(OTPProvider):
    """Send OTP via SMTP — not yet wired to signup flow."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    @property
    def channel(self) -> OTPChannel:
        return OTPChannel.EMAIL

    async def send_otp(self, phone_number: str, otp: str, expiry_minutes: int) -> None:
        # phone_number is repurposed as email address when this provider is selected
        if not self.settings.email_otp_enabled:
            raise DomainError("Email OTP is not enabled. Set EMAIL_OTP_ENABLED=true")

        logger.info("email_otp_stub", recipient=phone_number, expiry_minutes=expiry_minutes)
        raise NotImplementedError(
            "Email OTP provider is scaffolded. Implement SMTP delivery in this class."
        )