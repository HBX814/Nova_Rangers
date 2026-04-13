"""
Organizations Router
====================
CRUD operations for the 'organizations' Firestore collection.
"""

from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status

from backend.models.organization import Organization, OrganizationCreate, OrganizationUpdate
from backend.services.firestore_client import get_firestore_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("", response_model=Organization, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=Organization, status_code=status.HTTP_201_CREATED, include_in_schema=False)
async def create_organization(body: OrganizationCreate):
    """Register a new NGO / organisation."""
    db = get_firestore_client()

    org = Organization(
        org_id=str(uuid.uuid4()),
        name=body.name,
        description=body.description,
        contact_email=body.contact_email,
        contact_phone=body.contact_phone,
        address=body.address,
        district=body.district,
        created_at=datetime.now(timezone.utc),
    )

    doc_data = org.model_dump(mode="json")
    db.collection("organizations").document(org.org_id).set(doc_data)
    logger.info("Organization %s created", org.org_id)
    return org


@router.get("", response_model=list[Organization])
@router.get("/", response_model=list[Organization], include_in_schema=False)
async def list_organizations(limit: int = 100):
    """List all organisations."""
    db = get_firestore_client()
    results = []
    for doc in db.collection("organizations").limit(limit).stream():
        data = doc.to_dict()
        if data:
            results.append(Organization(**data))
    return results


@router.get("/{org_id}", response_model=Organization)
async def get_organization(org_id: str):
    """Get a single organisation by ID."""
    db = get_firestore_client()
    snap = db.collection("organizations").document(org_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Organization not found")
    return Organization(**snap.to_dict())


@router.patch("/{org_id}", response_model=Organization)
async def update_organization(org_id: str, body: OrganizationUpdate):
    """Partially update an organisation."""
    db = get_firestore_client()
    snap = db.collection("organizations").document(org_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Organization not found")

    updates = body.model_dump(exclude_none=True)
    db.collection("organizations").document(org_id).update(updates)

    refreshed = db.collection("organizations").document(org_id).get()
    return Organization(**refreshed.to_dict())


@router.delete("/{org_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_organization(org_id: str):
    """Remove an organisation (soft-delete recommended in production)."""
    db = get_firestore_client()
    snap = db.collection("organizations").document(org_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Organization not found")
    db.collection("organizations").document(org_id).delete()
