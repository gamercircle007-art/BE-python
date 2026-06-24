"""Abstract OAuth provider for social login (Google, Apple)."""

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class OAuthUserInfo:
    """Normalized user info from any OAuth provider."""

    provider: str
    provider_user_id: str
    email: str | None
    name: str | None


class OAuthProvider(ABC):
    """Interface for verifying OAuth ID tokens and extracting user info."""

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """e.g. 'google' or 'apple'"""

    @abstractmethod
    async def verify_id_token(self, id_token: str) -> OAuthUserInfo:
        """Validate the ID token from the client and return user info."""
        ...