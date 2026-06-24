"""
SMS OTP provider — STUB for Twilio SMS fallback.

TO ENABLE:
  1. Set TWILIO_SMS_FROM to your Twilio phone number
  2. Register in providers/__init__.py: OTP_PROVIDER=twilio_sms
  3. Add AUTH_METHODS=whatsapp_otp,sms_otp,password
"""

from app.core.config import Settings
from app.core.logging import get_logger
from app.domains.auth.providers.base import OTPChannel, OTPProvider
from app.domains.common.exceptions import DomainError

logger = get_logger(__name__)


class TwilioSmsProvider(OTPProvider):
    """Send OTP via Twilio SMS — fallback when WhatsApp is unavailable."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    @property
    def channel(self) -> OTPChannel:
        return OTPChannel.SMS

    async def send_otp(self, phone_number: str, otp: str, expiry_minutes: int) -> None:
        if not self.settings.twilio_sms_from:
            raise DomainError("SMS OTP is not configured. Set TWILIO_SMS_FROM")

        logger.info("sms_otp_stub", phone=phone_number, expiry_minutes=expiry_minutes)
        raise NotImplementedError(
            "SMS OTP provider is scaffolded. Implement Twilio SMS in this class."
        )