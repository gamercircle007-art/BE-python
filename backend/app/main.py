"""
Paythan API entry point.

Routers are mounted per domain. Auth router handles signup, login, tokens.
See domains/auth/ for the full authentication module.
"""

from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.trustedhost import TrustedHostMiddleware

from app.core.config import get_settings
from app.core.logging import get_logger, setup_logging
from app.domains.auth.router import router as auth_router
from app.domains.common.exceptions import (
    AuthenticationError,
    DomainError,
    NotFoundError,
    RateLimitError,
    ValidationError,
)
from app.domains.user.router import router as user_router

logger = get_logger(__name__)

OPENAPI_TAGS = [
    {
        "name": "Authentication",
        "description": (
            "Enterprise auth: WhatsApp OTP signup, phone+password login, "
            "JWT access/refresh tokens with rotation. "
            "Future: Google OAuth, Apple Sign In, Email/SMS OTP."
        ),
    },
    {
        "name": "Users",
        "description": "User profile management for authenticated users.",
    },
    {
        "name": "Health",
        "description": "Service health and readiness checks.",
    },
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    settings = get_settings()
    logger.info("application_starting", app_name=settings.app_name, env=settings.app_env)
    yield
    logger.info("application_shutdown")


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=f"{settings.app_name.title()} API",
        description=(
            "## Paythan Backend API\n\n"
            "Modular monolith with domain-driven design.\n\n"
            "### Authentication\n"
            "- **Signup**: Name + Email + Phone → WhatsApp OTP → Password → Account\n"
            "- **Login**: Phone + Password → JWT tokens\n"
            "- **Security**: Argon2 passwords, Redis OTP, token rotation, brute-force lockout\n\n"
            "### Extensibility\n"
            "OAuth (Google/Apple) and alternative OTP channels (Email/SMS) are scaffolded "
            "in `domains/auth/providers/`."
        ),
        version="0.2.0",
        openapi_tags=OPENAPI_TAGS,
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        openapi_url="/openapi.json" if not settings.is_production else None,
        lifespan=lifespan,
        contact={"name": "Paythan Engineering"},
        license_info={"name": "Proprietary"},
    )

    # --- Security middleware ---
    if settings.allowed_hosts_list != ["*"]:
        app.add_middleware(TrustedHostMiddleware, allowed_hosts=settings.allowed_hosts_list)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=settings.cors_allow_credentials,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["X-Request-ID"],
    )

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Cache-Control"] = "no-store"
        if settings.is_production:
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response

    # --- Exception handlers ---
    @app.exception_handler(DomainError)
    async def domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
        status_code = status.HTTP_400_BAD_REQUEST
        if isinstance(exc, NotFoundError):
            status_code = status.HTTP_404_NOT_FOUND
        elif isinstance(exc, AuthenticationError):
            status_code = status.HTTP_401_UNAUTHORIZED
        elif isinstance(exc, RateLimitError):
            status_code = status.HTTP_429_TOO_MANY_REQUESTS
        elif isinstance(exc, ValidationError):
            status_code = status.HTTP_422_UNPROCESSABLE_ENTITY

        logger.warning("domain_error", code=exc.code, message=exc.message, path=request.url.path)
        return JSONResponse(
            status_code=status_code,
            content={"error": exc.code, "message": exc.message, "details": exc.details},
        )

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "error": "validation_error",
                "message": "Invalid request",
                "details": exc.errors(),
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        logger.exception("unhandled_exception", path=request.url.path)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": "internal_error", "message": "An unexpected error occurred"},
        )

    @app.get("/health", tags=["Health"], summary="Health check")
    async def health_check() -> dict[str, Any]:
        return {
            "status": "healthy",
            "service": settings.app_name,
            "environment": settings.app_env,
            "auth_methods": settings.auth_methods_list,
        }

    # --- Domain routers ---
    api_prefix = settings.api_v1_prefix
    app.include_router(auth_router, prefix=api_prefix)
    app.include_router(user_router, prefix=api_prefix)

    return app


app = create_app()