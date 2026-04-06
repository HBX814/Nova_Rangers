"""
Auth Router
===========
Authentication and authorisation endpoints.
Uses Firebase Auth (via fastapi-cloudauth) for token verification
with JWT fallback for local development.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from backend.config import JWT_SECRET_KEY, JWT_ALGORITHM, JWT_ACCESS_TOKEN_EXPIRE_MINUTES

logger = logging.getLogger(__name__)
router = APIRouter()


# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------

class TokenRequest(BaseModel):
    """Login request — in production this would be a Firebase ID token."""
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UserInfo(BaseModel):
    uid: str
    email: str
    role: str  # "admin" | "org_manager" | "volunteer"


# ---------------------------------------------------------------------------
# Placeholder JWT helpers (swap with Firebase Auth in production)
# ---------------------------------------------------------------------------

def _create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    """
    Create a signed JWT.

    TODO: In production, replace with Firebase Auth custom tokens or
    verify incoming Firebase ID tokens using fastapi-cloudauth:
        from fastapi_cloudauth import FirebaseCurrentUser
        current_user = FirebaseCurrentUser(project_id=GCP_PROJECT_ID)
    """
    import jwt  # PyJWT — add to pyproject.toml if not present

    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode["exp"] = expire
    return jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post("/token", response_model=TokenResponse)
async def login(body: TokenRequest):
    """
    Issue an access token.

    In production:
      - Accept a Firebase ID token from the Flutter app.
      - Verify it server-side using firebase_admin.auth.verify_id_token().
      - Return a custom JWT or use the Firebase token directly.

    This placeholder accepts email/password for local testing only.
    """
    # TODO: Replace with real Firebase Auth verification
    # import firebase_admin.auth as fb_auth
    # decoded = fb_auth.verify_id_token(body.firebase_id_token)

    # Placeholder: accept any non-empty credentials for local dev
    if not body.email or not body.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    token = _create_access_token(
        data={"sub": body.email, "role": "org_manager"},
    )

    return TokenResponse(
        access_token=token,
        expires_in=JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.get("/me", response_model=UserInfo)
async def get_current_user():
    """
    Return the currently authenticated user's info.

    TODO: Extract user from the Authorization header token.
    In production, use a FastAPI dependency:
        from fastapi_cloudauth import FirebaseCurrentUser
        current_user = Depends(FirebaseCurrentUser(project_id=...))
    """
    # Placeholder — in production, decode the JWT from the request
    return UserInfo(
        uid="placeholder-uid",
        email="dev@communitypulse.org",
        role="org_manager",
    )
