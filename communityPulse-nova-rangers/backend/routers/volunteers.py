"""
Volunteers Router
=================
CRUD operations for the 'volunteers' Firestore collection.
"""

from __future__ import annotations

import logging
import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, status
from geopy.distance import geodesic
import geohash2

from backend.models.volunteer import Volunteer, VolunteerCreate, VolunteerUpdate
from backend.services.firestore_client import get_firestore_client

logger = logging.getLogger(__name__)
router = APIRouter()


def _compute_geohash(lat: float, lng: float, precision: int = 6) -> str:
    """Compute a geohash string from lat/lng for proximity queries."""
    return geohash2.encode(lat, lng, precision=precision)


@router.post("/", response_model=Volunteer, status_code=status.HTTP_201_CREATED)
async def register_volunteer(body: VolunteerCreate):
    """Register a new volunteer."""
    db = get_firestore_client()

    vol = Volunteer(
        volunteer_id=str(uuid.uuid4()),
        name=body.name,
        phone=body.phone,
        skills=body.skills,
        current_lat=body.current_lat,
        current_lng=body.current_lng,
        languages=body.languages,
        fcm_token=body.fcm_token,
        geohash=_compute_geohash(body.current_lat, body.current_lng),
        joined_date=date.today(),
    )

    doc_data = vol.model_dump(mode="json")
    db.collection("volunteers").document(vol.volunteer_id).set(doc_data)
    logger.info("Volunteer %s registered", vol.volunteer_id)
    return vol


@router.get("/", response_model=list[Volunteer])
async def list_volunteers(
    status_filter: str | None = None,
    limit: int = 100,
):
    """List volunteers, optionally filtered by availability_status."""
    db = get_firestore_client()

    query = db.collection("volunteers")
    if status_filter:
        query = query.where("availability_status", "==", status_filter)
    query = query.limit(limit)

    results = []
    for doc in query.stream():
        data = doc.to_dict()
        if data:
            results.append(Volunteer(**data))
    return results


@router.get("/{volunteer_id}", response_model=Volunteer)
async def get_volunteer(volunteer_id: str):
    """Retrieve a single volunteer by ID."""
    db = get_firestore_client()
    snap = db.collection("volunteers").document(volunteer_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Volunteer not found")
    return Volunteer(**snap.to_dict())


@router.patch("/{volunteer_id}", response_model=Volunteer)
async def update_volunteer(volunteer_id: str, body: VolunteerUpdate):
    """Partially update a volunteer's profile."""
    db = get_firestore_client()
    snap = db.collection("volunteers").document(volunteer_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Volunteer not found")

    updates = body.model_dump(exclude_none=True)

    # Recompute geohash if location changed
    if "current_lat" in updates or "current_lng" in updates:
        existing = snap.to_dict()
        lat = updates.get("current_lat", existing.get("current_lat", 0))
        lng = updates.get("current_lng", existing.get("current_lng", 0))
        updates["geohash"] = _compute_geohash(lat, lng)

    db.collection("volunteers").document(volunteer_id).update(updates)

    refreshed = db.collection("volunteers").document(volunteer_id).get()
    return Volunteer(**refreshed.to_dict())


@router.get("/nearby/", response_model=list[Volunteer])
async def find_nearby_volunteers(
    lat: float,
    lng: float,
    radius_km: float = 25.0,
    limit: int = 20,
):
    """
    Find available volunteers within a given radius of a location.
    Uses in-memory distance filtering (for production, use geohash range queries).
    """
    db = get_firestore_client()

    available = (
        db.collection("volunteers")
        .where("availability_status", "==", "AVAILABLE")
        .stream()
    )

    origin = (lat, lng)
    nearby = []
    for doc in available:
        data = doc.to_dict()
        if not data:
            continue
        vol_loc = (data.get("current_lat", 0), data.get("current_lng", 0))
        dist = geodesic(origin, vol_loc).km
        if dist <= radius_km:
            nearby.append((dist, Volunteer(**data)))

    # Sort by distance, closest first
    nearby.sort(key=lambda x: x[0])
    return [vol for _, vol in nearby[:limit]]
