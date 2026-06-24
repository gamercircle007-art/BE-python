"""OTP provider factory tests."""

import os

os.environ.setdefault("JWT_SECRET_KEY", "test_secret_key_minimum_32_characters_long")

from app.core.config import Settings
from app.domains.auth.providers import get_otp_provider
from app.domains.auth.providers.base import OTPChannel
from app.domains.auth.providers.twilio_whatsapp import TwilioWhatsAppProvider


def test_get_twilio_whatsapp_provider() -> None:
    settings = Settings(
        jwt_secret_key="test_secret_key_minimum_32_characters_long",
        otp_provider="twilio",
    )
    provider = get_otp_provider(settings)
    assert isinstance(provider, TwilioWhatsAppProvider)
    assert provider.channel == OTPChannel.WHATSAPP


def test_unknown_provider_raises() -> None:
    settings = Settings(
        jwt_secret_key="test_secret_key_minimum_32_characters_long",
        otp_provider="unknown_vendor",
    )
    try:
        get_otp_provider(settings)
        raise AssertionError("Expected ValueError")
    except ValueError as exc:
        assert "unknown_vendor" in str(exc)