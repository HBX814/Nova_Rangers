"""
Assignment model — matches the Firestore 'assignments' collection schema exactly.
"""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class AssignmentStatus(str, Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"


class Assignment(BaseModel):
    """Firestore document schema for the 'assignments' collection."""

    assignment_id: str = Field(..., description="Unique assignment identifier")
    need_id: str = Field(..., description="ID of the associated need")
    volunteer_id: str = Field(..., description="ID of the assigned volunteer")
    status: AssignmentStatus = Field(
        AssignmentStatus.PENDING, description="Current assignment status"
    )
    assigned_at: datetime = Field(
        default_factory=datetime.now, description="When the assignment was created"
    )
    accepted_at: Optional[datetime] = Field(
        None, description="When the volunteer accepted"
    )
    completed_at: Optional[datetime] = Field(
        None, description="When the assignment was completed"
    )
    ngo_satisfaction_rating: Optional[int] = Field(
        None,
        ge=1,
        le=5,
        description="NGO's satisfaction rating for the volunteer (1-5)",
    )


class AssignmentCreate(BaseModel):
    need_id: str
    volunteer_id: str


class AssignmentUpdate(BaseModel):
    status: Optional[AssignmentStatus] = None
    accepted_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    ngo_satisfaction_rating: Optional[int] = Field(None, ge=1, le=5)
