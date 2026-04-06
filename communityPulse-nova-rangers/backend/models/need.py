"""
Need model — matches the Firestore 'needs' collection schema exactly.
"""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class NeedCategory(str, Enum):
    FLOOD = "FLOOD"
    DROUGHT = "DROUGHT"
    MEDICAL = "MEDICAL"
    SHELTER = "SHELTER"
    EDUCATION = "EDUCATION"
    FOOD = "FOOD"
    INFRASTRUCTURE = "INFRASTRUCTURE"
    WATER = "WATER"


class NeedStatus(str, Enum):
    OPEN = "OPEN"
    IN_PROGRESS = "IN_PROGRESS"
    RESOLVED = "RESOLVED"


class Need(BaseModel):
    """Firestore document schema for the 'needs' collection."""

    need_id: str = Field(..., description="Unique identifier for the need")
    need_category: NeedCategory = Field(..., description="Category of the need")
    title: str = Field(..., max_length=256, description="Short title for the need")
    description: str = Field(..., description="Detailed description of the need")
    urgency_score: int = Field(
        ..., ge=1, le=10, description="Urgency score from 1 (low) to 10 (critical)"
    )
    affected_population: int = Field(
        ..., ge=0, description="Estimated number of people affected"
    )
    primary_location_text: str = Field(
        ..., description="Human-readable location (e.g., 'Bhopal, Madhya Pradesh')"
    )
    lat: float = Field(..., description="Latitude of the need location")
    lng: float = Field(..., description="Longitude of the need location")
    priority_index: float = Field(
        0.0, description="Computed priority index (set by PriorityRanker agent)"
    )
    status: NeedStatus = Field(NeedStatus.OPEN, description="Current lifecycle status")
    report_count: int = Field(
        1, ge=0, description="Number of times this need has been reported"
    )
    submitted_at: datetime = Field(
        default_factory=datetime.now,
        description="Timestamp when the need was first submitted",
    )
    org_id: str = Field(..., description="ID of the NGO / organisation that owns this need")


class NeedCreate(BaseModel):
    """Request body for creating a new need (server generates need_id & timestamps)."""

    need_category: NeedCategory
    title: str = Field(..., max_length=256)
    description: str
    urgency_score: int = Field(..., ge=1, le=10)
    affected_population: int = Field(..., ge=0)
    primary_location_text: str
    lat: float
    lng: float
    org_id: str


class NeedUpdate(BaseModel):
    """Partial update payload for an existing need."""

    title: Optional[str] = None
    description: Optional[str] = None
    urgency_score: Optional[int] = Field(None, ge=1, le=10)
    affected_population: Optional[int] = Field(None, ge=0)
    status: Optional[NeedStatus] = None
    priority_index: Optional[float] = None
