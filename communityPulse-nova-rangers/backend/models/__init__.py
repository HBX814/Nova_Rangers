"""
Pydantic v2 models matching the Firestore document schemas.
"""

from backend.models.need import Need, NeedCategory, NeedStatus
from backend.models.volunteer import Volunteer, AvailabilityStatus
from backend.models.organization import Organization
from backend.models.assignment import Assignment, AssignmentStatus
from backend.models.submission import SubmissionPayload

__all__ = [
    "Need",
    "NeedCategory",
    "NeedStatus",
    "Volunteer",
    "AvailabilityStatus",
    "Organization",
    "Assignment",
    "AssignmentStatus",
    "SubmissionPayload",
]
