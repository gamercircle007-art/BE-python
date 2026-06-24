"""
OTP provider factory — single entry point for delivery channel selection.

Registered providers:
  twilio        → TwilioWhatsAppProvider (default, production-ready)
  twilio_sms    → TwilioSmsProvider (stub)
  email         → EmailOTPProvider (stub)

TO ADD A PROVIDER:
  1. Implement OTPProvider in a new file
  2. Add elif branch below
  3. Document env vars in .env.example and backend/README.md
"""

from app.core.config import Settings
from app.domains.auth.providers.base import OTPProvider
from app.domains.auth.providers.email_otp import EmailOTPProvider
from app.domains.auth.providers.sms_otp import TwilioSmsProvider
from app.domains.auth.providers.twilio_whatsapp import TwilioWhatsAppProvider


def get_otp_provider(settings: Settings) -> OTPProvider:
    """Return the configured OTP delivery provider."""
    registry: dict[str, type[OTPProvider]] = {
        "twilio": TwilioWhatsAppProvider,
        "twilio_sms": TwilioSmsProvider,
        "email": EmailOTPProvider,
    }
    provider_cls = registry.get(settings.otp_provider)
    if provider_cls is None:
        raise ValueError(
            f"Unknown OTP provider '{settings.otp_provider}'. "
            f"Available: {', '.join(registry)}"
        )
    return provider_cls(settings)