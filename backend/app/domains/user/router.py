"""
User domain API routes.

MICROSERVICE EXTRACTION: Copy this router + service + repository + models to a new
FastAPI app. Register at /users. Auth service validates JWT and passes user_id.
"""

from uuid import UUID

from fastapi import APIRouter, status

from app.core.dependencies import CurrentUserDep, DbSessionDep
from app.domains.user.schemas import UserResponse, UserUpdate
from app.domains.user.service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: CurrentUserDep) -> UserResponse:
    """Return the authenticated user's profile."""
    return current_user


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    db: DbSessionDep,
    current_user: CurrentUserDep,
) -> UserResponse:
    """Get user by ID (authenticated). Extend with RBAC as needed."""
    _ = current_user  # Ensure authenticated; add authorization later
    service = UserService(db)
    return await service.get_user(user_id)


@router.patch("/me", response_model=UserResponse)
async def update_current_user(
    data: UserUpdate,
    db: DbSessionDep,
    current_user: CurrentUserDep,
) -> UserResponse:
    """Update the authenticated user's profile."""
    service = UserService(db)
    return await service.update_user(current_user.id, data)