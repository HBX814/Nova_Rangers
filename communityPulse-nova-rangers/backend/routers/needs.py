"""
Needs Router
============
CRUD and query operations for the 'needs' Firestore collection.
"""

from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status

from backend.models.need import Need, NeedCreate, NeedUpdate, NeedStatus
from backend.services.firestore_client import get_firestore_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/", response_model=Need, status_code=status.HTTP_201_CREATED)
async def create_need(body: NeedCreate):
    """Create a new need and persist to Firestore."""
    db = get_firestore_client()

    need = Need(
        need_id=str(uuid.uuid4()),
        need_category=body.need_category,
        title=body.title,
        description=body.description,
        urgency_score=body.urgency_score,
        affected_population=body.affected_population,
        primary_location_text=body.primary_location_text,
        lat=body.lat,
        lng=body.lng,
        org_id=body.org_id,
        submitted_at=datetime.now(timezone.utc),
    )

    doc_data = need.model_dump(mode="json")
    db.collection("needs").document(need.need_id).set(doc_data)
    logger.info("Need %s created (category=%s)", need.need_id, need.need_category)
    return need


@router.get("/", response_model=list[Need])
async def list_needs(
    status_filter: str | None = None,
    category: str | None = None,
    limit: int = 100,
):
    """List needs with optional filters."""
    db = get_firestore_client()

    query = db.collection("needs")
    if status_filter:
        query = query.where("status", "==", status_filter)
    if category:
        query = query.where("need_category", "==", category)
    query = query.limit(limit)

    results = []
    for doc in query.stream():
        data = doc.to_dict()
        if data:
            results.append(Need(**data))
    return results


@router.get("/{need_id}", response_model=Need)
async def get_need(need_id: str):
    """Get a single need by ID."""
    db = get_firestore_client()
    snap = db.collection("needs").document(need_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Need not found")
    return Need(**snap.to_dict())


@router.patch("/{need_id}", response_model=Need)
async def update_need(need_id: str, body: NeedUpdate):
    """Partially update a need."""
    db = get_firestore_client()
    snap = db.collection("needs").document(need_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Need not found")

    updates = body.model_dump(exclude_none=True)
    db.collection("needs").document(need_id).update(updates)

    refreshed = db.collection("needs").document(need_id).get()
    return Need(**refreshed.to_dict())


@router.post("/{need_id}/resolve", response_model=Need)
async def resolve_need(need_id: str):
    """Mark a need as RESOLVED."""
    db = get_firestore_client()
    snap = db.collection("needs").document(need_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Need not found")

    db.collection("needs").document(need_id).update({"status": NeedStatus.RESOLVED.value})
    refreshed = db.collection("needs").document(need_id).get()
    return Need(**refreshed.to_dict())


@router.get("/priority/top", response_model=list[Need])
async def top_priority_needs(limit: int = 10):
    """Return the highest-priority open needs."""
    db = get_firestore_client()

    docs = (
        db.collection("needs")
        .where("status", "==", "OPEN")
        .order_by("priority_index", direction="DESCENDING")
        .limit(limit)
        .stream()
    )

    results = []
    for doc in docs:
        data = doc.to_dict()
        if data:
            results.append(Need(**data))
    return results
