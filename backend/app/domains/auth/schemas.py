"""Auth domain request/response schemas with strict validation and OpenAPI examples."""

import re

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.domains.user.schemas import UserResponse

_PASSWORD_PATTERN = re.compile(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,128}$")


class SignupRequestOTPRequest(BaseModel):
    """Step 1: Provide name, email, phone — receive WhatsApp OTP."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "name": "Jane Doe",
                    "email": "jane@example.com",
                    "phone_number": "+919876543210",
                }
            ]
        }
    )

    name: str = Field(..., min_length=2, max_length=100, description="User's full name")
    email: EmailStr = Field(..., description="Unique email address")
    phone_number: str = Field(
        ...,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="E.164 phone number (e.g. +919876543210)",
        examples=["+919876543210"],
    )


class SignupVerifyOTPRequest(BaseModel):
    """Step 2: Verify OTP and set password — account is created."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "phone_number": "+919876543210",
                    "otp": "123456",
                    "password": "SecurePass1",
                }
            ]
        }
    )

    phone_number: str = Field(..., pattern=r"^\+?[1-9]\d{6,14}$")
    otp: str = Field(..., min_length=4, max_length=8, pattern=r"^\d+$", description="6-digit OTP")
    password: str = Field(
        ...,
        min_length=8,
        max_length=128,
        description="Min 8 chars with uppercase, lowercase, and digit",
    )

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, value: str) -> str:
        if not _PASSWORD_PATTERN.match(value):
            raise ValueError(
                "Password must be 8-128 characters with at least one uppercase, "
                "one lowercase, and one digit"
            )
        return value


class LoginRequestOtpRequest(BaseModel):
    """Step 1: Request WhatsApp OTP for login."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [{"phone_number": "+919876543210"}]
        }
    )

    phone_number: str = Field(..., pattern=r"^\+?[1-9]\d{6,14}$")


class LoginVerifyOtpRequest(BaseModel):
    """Step 2: Verify login OTP and receive JWT tokens."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {"phone_number": "+919876543210", "otp": "123456"}
            ]
        }
    )

    phone_number: str = Field(..., pattern=r"^\+?[1-9]\d{6,14}$")
    otp: str = Field(..., min_length=4, max_length=8, pattern=r"^\d+$", description="6-digit OTP")


class LoginRequest(BaseModel):
    """Login with phone number and password (legacy)."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {"phone_number": "+919876543210", "password": "SecurePass1"}
            ]
        }
    )

    phone_number: str = Field(..., pattern=r"^\+?[1-9]\d{6,14}$")
    password: str = Field(..., min_length=8, max_length=128)


class RefreshTokenRequest(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}]
        }
    )

    refresh_token: str = Field(..., min_length=10)


class LogoutRequest(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}]
        }
    )

    refresh_token: str = Field(..., min_length=10)


class TokenResponse(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "access_token": "eyJ...",
                    "refresh_token": "eyJ...",
                    "token_type": "bearer",
                    "expires_in": 1800,
                    "user": {
                        "id": "550e8400-e29b-41d4-a716-446655440000",
                        "name": "Jane Doe",
                        "email": "jane@example.com",
                        "phone_number": "+919876543210",
                        "is_active": True,
                        "is_verified": True,
                        "email_verified": True,
                        "phone_verified": True,
                        "created_at": "2026-06-24T12:00:00Z",
                        "updated_at": "2026-06-24T12:00:00Z",
                    },
                }
            ]
        }
    )

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Access token lifetime in seconds")
    user: UserResponse


class MessageResponse(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "message": "OTP sent to your WhatsApp number.",
                    "success": True,
                }
            ]
        }
    )

    message: str
    success: bool = True