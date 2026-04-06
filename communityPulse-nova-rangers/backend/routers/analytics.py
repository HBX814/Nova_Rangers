"""
Analytics Router
================
Endpoints for dashboard and reporting data.
Aggregates data from Firestore and optionally BigQuery.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from fastapi import APIRouter

from backend.services.firestore_client import get_firestore_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/summary")
async def get_summary():
    """
    High-level summary statistics for the CommunityPulse dashboard.
    Returns counts, category breakdowns, and status distributions.
    """
    db = get_firestore_client()

    needs = list(db.collection("needs").stream())
    volunteers = list(db.collection("volunteers").stream())
    assignments = list(db.collection("assignments").stream())

    needs_data = [n.to_dict() for n in needs if n.to_dict()]
    vol_data = [v.to_dict() for v in volunteers if v.to_dict()]
    assign_data = [a.to_dict() for a in assignments if a.to_dict()]

    # Need status counts
    status_counts = {"OPEN": 0, "IN_PROGRESS": 0, "RESOLVED": 0}
    category_counts: dict[str, int] = {}
    for n in needs_data:
        s = n.get("status", "OPEN")
        status_counts[s] = status_counts.get(s, 0) + 1
        cat = n.get("need_category", "UNKNOWN")
        category_counts[cat] = category_counts.get(cat, 0) + 1

    # Volunteer availability
    avail_counts = {"AVAILABLE": 0, "BUSY": 0, "OFFLINE": 0}
    for v in vol_data:
        a = v.get("availability_status", "OFFLINE")
        avail_counts[a] = avail_counts.get(a, 0) + 1

    # Assignment status
    assign_status = {"PENDING": 0, "ACCEPTED": 0, "IN_PROGRESS": 0, "COMPLETED": 0}
    for a in assign_data:
        s = a.get("status", "PENDING")
        assign_status[s] = assign_status.get(s, 0) + 1

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_needs": len(needs_data),
        "total_volunteers": len(vol_data),
        "total_assignments": len(assign_data),
        "needs_by_status": status_counts,
        "needs_by_category": category_counts,
        "volunteers_by_availability": avail_counts,
        "assignments_by_status": assign_status,
        "total_affected_population": sum(
            n.get("affected_population", 0) for n in needs_data
        ),
    }


@router.get("/top-volunteers")
async def top_volunteers(limit: int = 10):
    """Return top-performing volunteers sorted by performance_score."""
    db = get_firestore_client()
    docs = (
        db.collection("volunteers")
        .order_by("performance_score", direction="DESCENDING")
        .limit(limit)
        .stream()
    )
    results = []
    for doc in docs:
        data = doc.to_dict()
        if data:
            results.append({
                "volunteer_id": data.get("volunteer_id"),
                "name": data.get("name"),
                "performance_score": data.get("performance_score", 0),
                "tasks_completed": data.get("tasks_completed", 0),
            })
    return results


@router.get("/district-heatmap")
async def district_heatmap():
    """
    Return geo-aggregated need counts for heatmap visualisation.
    Groups needs by rounded lat/lng (0.1 degree grid).
    """
    db = get_firestore_client()
    docs = db.collection("needs").where("status", "==", "OPEN").stream()

    grid: dict[str, dict] = {}
    for doc in docs:
        data = doc.to_dict()
        if not data:
            continue
        lat = round(data.get("lat", 0), 1)
        lng = round(data.get("lng", 0), 1)
        key = f"{lat},{lng}"
        if key not in grid:
            grid[key] = {"lat": lat, "lng": lng, "count": 0, "total_urgency": 0}
        grid[key]["count"] += 1
        grid[key]["total_urgency"] += data.get("urgency_score", 1)

    return list(grid.values())
