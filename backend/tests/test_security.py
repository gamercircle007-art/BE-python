"""Security utilities tests."""

import os

os.environ.setdefault("JWT_SECRET_KEY", "test_secret_key_minimum_32_characters_long")

from app.core.security import hash_password, verify_password


def test_argon2_hash_and_verify() -> None:
    hashed = hash_password("SecurePass1")
    assert hashed.startswith("$argon2")
    assert verify_password("SecurePass1", hashed)
    assert not verify_password("WrongPass1", hashed)