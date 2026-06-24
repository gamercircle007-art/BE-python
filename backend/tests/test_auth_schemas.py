"""Auth schema validation tests."""

import pytest
from pydantic import ValidationError

from app.domains.auth.schemas import (
    LoginRequest,
    SignupRequestOTPRequest,
    SignupVerifyOTPRequest,
)


def test_signup_request_otp_valid() -> None:
    req = SignupRequestOTPRequest(
        name="John Doe",
        email="john@example.com",
        phone_number="+919876543210",
    )
    assert req.name == "John Doe"


def test_signup_request_otp_invalid_phone() -> None:
    with pytest.raises(ValidationError):
        SignupRequestOTPRequest(
            name="John",
            email="john@example.com",
            phone_number="abc",
        )


def test_signup_verify_weak_password() -> None:
    with pytest.raises(ValidationError):
        SignupVerifyOTPRequest(
            phone_number="+919876543210",
            otp="123456",
            password="weak",
        )


def test_signup_verify_strong_password() -> None:
    req = SignupVerifyOTPRequest(
        phone_number="+919876543210",
        otp="123456",
        password="SecurePass1",
    )
    assert req.otp == "123456"


def test_login_valid() -> None:
    req = LoginRequest(phone_number="+919876543210", password="SecurePass1")
    assert req.phone_number == "+919876543210"