"""Auth-related configuration tests."""

import os

os.environ.setdefault("JWT_SECRET_KEY", "test_secret_key_minimum_32_characters_long")

import pytest

from app.core.config import Settings


def test_auth_methods_parsing() -> None:
    settings = Settings(
        jwt_secret_key="test_secret_key_minimum_32_characters_long",
        auth_methods="whatsapp_otp,password,google",
    )
    assert settings.auth_methods_list == ["whatsapp_otp", "password", "google"]
    assert settings.is_auth_method_enabled("password")
    assert not settings.is_auth_method_enabled("apple")


def test_otp_rate_limit_window() -> None:
    settings = Settings(
        jwt_secret_key="test_secret_key_minimum_32_characters_long",
        otp_rate_limit_window_minutes=10,
    )
    assert settings.otp_rate_limit_window_seconds == 600