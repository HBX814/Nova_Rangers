"""
Organization model — matches the Firestore 'organizations' collection schema.
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class Organization(BaseModel):
    """Firestore document schema for the 'organizations' collection."""

    org_id: str = Field(..., description="Unique organisation identifier")
    name: str = Field(..., description="Organisation / NGO name")
    description: str = Field("", description="Brief description of the org")
    contact_email: str = Field(..., description="Primary contact email")
    contact_phone: str = Field("", description="Primary contact phone")
    address: str = Field("", description="Office address")
    district: str = Field("", description="Operating district in Madhya Pradesh")
    logo_url: str = Field("", description="URL to organisation logo")
    created_at: datetime = Field(
        default_factory=datetime.now, description="Account creation timestamp"
    )
    is_verified: bool = Field(False, description="Has the org been verified by an admin?")


class OrganizationCreate(BaseModel):
    name: str
    description: str = ""
    contact_email: str
    contact_phone: str = ""
    address: str = ""
    district: str = ""


class OrganizationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    address: Optional[str] = None
    district: Optional[str] = None
    is_verified: Optional[bool] = None
