"""
SubmissionPayload model — used when field volunteers submit reports
(text, images, PDFs) that are processed by the agent pipeline.
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class SubmissionPayload(BaseModel):
    """
    Inbound payload from the Flutter app when a volunteer or citizen
    submits a new need report.  May include text, geo-coordinates, and
    references to uploaded media (images / PDFs stored in Cloud Storage).
    """

    submission_id: str = Field("", description="Auto-generated submission ID")
    submitted_by: str = Field(
        ..., description="volunteer_id or 'anonymous' for citizen reports"
    )
    title: str = Field(..., max_length=256, description="Short title for the report")
    description: str = Field(..., description="Detailed report text")
    lat: float = Field(..., description="Latitude of the reported location")
    lng: float = Field(..., description="Longitude of the reported location")
    location_text: str = Field(
        "", description="Optional human-readable location string"
    )
    media_urls: list[str] = Field(
        default_factory=list,
        description="Cloud Storage URLs for uploaded images / PDFs",
    )
    submitted_at: datetime = Field(
        default_factory=datetime.now, description="Submission timestamp"
    )
    org_id: Optional[str] = Field(
        None, description="If submitted through an NGO portal, the org_id"
    )

    # Fields populated by the agent pipeline
    extracted_category: Optional[str] = Field(
        None, description="Need category inferred by NeedsClassifier agent"
    )
    extracted_urgency: Optional[int] = Field(
        None, ge=1, le=10, description="Urgency score inferred by the pipeline"
    )
    is_duplicate: Optional[bool] = Field(
        None, description="Flag set by DeduplicationAgent"
    )
    duplicate_of_need_id: Optional[str] = Field(
        None, description="If duplicate, the need_id it duplicates"
    )
