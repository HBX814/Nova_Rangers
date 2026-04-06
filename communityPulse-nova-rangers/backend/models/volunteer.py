"""
Volunteer model — matches the Firestore 'volunteers' collection schema exactly.
"""

from __future__ import annotations

from datetime import date, datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class AvailabilityStatus(str, Enum):
    AVAILABLE = "AVAILABLE"
    BUSY = "BUSY"
    OFFLINE = "OFFLINE"


class Volunteer(BaseModel):
    """Firestore document schema for the 'volunteers' collection."""

    volunteer_id: str = Field(..., description="Unique identifier")
    name: str = Field(..., description="Full name of the volunteer")
    phone: str = Field(..., description="Phone number (Indian format preferred)")
    skills: list[str] = Field(default_factory=list, description="List of skill tags")
    current_lat: float = Field(..., description="Current latitude")
    current_lng: float = Field(..., description="Current longitude")
    availability_status: AvailabilityStatus = Field(
        AvailabilityStatus.OFFLINE, description="Current availability"
    )
    performance_score: float = Field(
        0.0, ge=0.0, description="Computed performance score (0–100)"
    )
    tasks_completed: int = Field(0, ge=0, description="Total tasks completed")
    fcm_token: str = Field("", description="Firebase Cloud Messaging token for push notifications")
    geohash: str = Field("", description="Geohash of current location for proximity queries")
    languages: list[str] = Field(
        default_factory=list, description="Languages spoken (e.g., ['Hindi', 'English'])"
    )
    joined_date: date = Field(
        default_factory=date.today, description="Date the volunteer joined"
    )


class VolunteerCreate(BaseModel):
    """Request body for volunteer registration."""

    name: str
    phone: str
    skills: list[str] = Field(default_factory=list)
    current_lat: float
    current_lng: float
    languages: list[str] = Field(default_factory=list)
    fcm_token: str = ""


class VolunteerUpdate(BaseModel):
    """Partial update payload for a volunteer."""

    name: Optional[str] = None
    phone: Optional[str] = None
    skills: Optional[list[str]] = None
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None
    availability_status: Optional[AvailabilityStatus] = None
    fcm_token: Optional[str] = None
    languages: Optional[list[str]] = None
