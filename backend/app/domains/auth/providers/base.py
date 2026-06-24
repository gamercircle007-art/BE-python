"""
Abstract OTP delivery provider.

Swap implementations without changing signup/login business logic.

HOW TO ADD A NEW OTP CHANNEL:
  1. Create a class implementing OTPProvider (e.g. email_otp.py, sms_otp.py)
  2. Register it in providers/__init__.py → get_otp_provider()
  3. Set OTP_PROVIDER=<name> in .env
  4. Optionally add channel selection in SignupService.request_otp()
"""

from abc import ABC, abstractmethod
from enum import StrEnum


class OTPChannel(StrEnum):
    """Delivery channels — extend when adding email or SMS fallback."""

    WHATSAPP = "whatsapp"
    SMS = "sms"          # Future: TwilioSmsProvider
    EMAIL = "email"      # Future: EmailOTPProvider


class OTPProvider(ABC):
    """Interface for sending OTP messages via any channel."""

    @property
    @abstractmethod
    def channel(self) -> OTPChannel:
        """Return the channel this provider handles."""

    @abstractmethod
    async def send_otp(self, phone_number: str, otp: str, expiry_minutes: int) -> None:
        """
        Deliver OTP to the recipient.

        For email OTP, phone_number can be repurposed as email in a subclass,
        or extend the interface with a separate `send_otp_to_email()` method.
        """
        ...