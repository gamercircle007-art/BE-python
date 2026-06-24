"""Pytest fixtures for API testing."""

import os

import pytest
from httpx import ASGITransport, AsyncClient

# Set test env before importing app
os.environ.setdefault("JWT_SECRET_KEY", "test_secret_key_minimum_32_characters_long")
os.environ.setdefault("APP_ENV", "local")
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://paythan:test@localhost:5432/paythan_test")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/1")

from app.main import app  # noqa: E402


@pytest.fixture
async def client() -> AsyncClient:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac