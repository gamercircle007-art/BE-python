"""
Async HTTP client utilities using httpx.

Use for inter-service communication when domains are extracted to microservices.
"""

from typing import Any

import httpx

from app.core.logging import get_logger

logger = get_logger(__name__)


async def post_json(
    url: str,
    payload: dict[str, Any],
    headers: dict[str, str] | None = None,
    timeout: float = 30.0,
) -> httpx.Response:
    """POST JSON to an external service (future microservice calls)."""
    async with httpx.AsyncClient(timeout=timeout) as client:
        response = await client.post(url, json=payload, headers=headers)
        logger.info(
            "http_post",
            url=url,
            status_code=response.status_code,
        )
        return response