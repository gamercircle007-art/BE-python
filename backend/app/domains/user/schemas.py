"""User domain Pydantic schemas (API contracts)."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class UserBase(BaseModel):
    email: EmailStr | None = None
    phone_number: str | None = Field(default=None, pattern=r"^\+?[1-9]\d{6,14}$")
    name: str | None = Field(default=None, min_length=2, max_length=100)


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    email: EmailStr | None = None
    phone_number: str | None = Field(default=None, pattern=r"^\+?[1-9]\d{6,14}$")


class UserResponse(BaseModel):
    """
    Public user profile returned by /auth/me and token responses.

    Serializes ORM fields full_name → name, phone → phone_number.
    """

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    name: str | None = Field(validation_alias="full_name")
    email: str | None = None
    phone_number: str | None = Field(validation_alias="phone")
    is_active: bool
    is_verified: bool
    email_verified: bool
    phone_verified: bool
    created_at: datetime
    updated_at: datetime

    @field_validator("name", mode="before")
    @classmethod
    def accept_full_name(cls, value: str | None, info) -> str | None:
        return value