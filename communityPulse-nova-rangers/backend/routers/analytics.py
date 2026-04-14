from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from cachetools import TTLCache, cached
from fastapi import APIRouter

from backend.firebase_init import db

router = APIRouter()

summary_cache = TTLCache(maxsize=1, ttl=10)


def _parse_datetime(value: Any) -> Optional[datetime]:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if not isinstance(value, str):
        return None

    normalized = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


@router.get("/summary")
@cached(cache=summary_cache)
def get_summary() -> Dict[str, Any]:
    now_utc = datetime.now(timezone.utc)
    start_of_week = (now_utc - timedelta(days=now_utc.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )

    open_needs_docs = db.collection("needs").where("status", "==", "OPEN").stream()
    open_needs = [doc.to_dict() or {} for doc in open_needs_docs]
    open_needs_count = len(open_needs)

    available_volunteers_count = len(
        list(
            db.collection("volunteers")
            .where("availability_status", "==", "AVAILABLE")
            .stream()
        )
    )

    completed_assignments_count = 0
    response_time_hours: List[float] = []
    for assignment in db.collection("assignments").stream():
        assignment_data = assignment.to_dict() or {}
        if str(assignment_data.get("status", "")).upper() != "COMPLETED":
            continue

        assigned_at = _parse_datetime(assignment_data.get("assigned_at"))
        completed_at = _parse_datetime(assignment_data.get("completed_at"))
        if completed_at and completed_at >= start_of_week:
            completed_assignments_count += 1

        if not assigned_at or not completed_at:
            continue
        if completed_at <= assigned_at:
            continue

        response_time_hours.append((completed_at - assigned_at).total_seconds() / 3600)

    avg_response_time_hours = (
        round(sum(response_time_hours) / len(response_time_hours), 2)
        if response_time_hours
        else None
    )

    category_counts_this_week: Dict[str, int] = {}
    for need in open_needs:
        category = need.get("need_category")
        submitted_at = _parse_datetime(need.get("submitted_at"))
        if not category or not submitted_at or submitted_at < start_of_week:
            continue
        category_counts_this_week[category] = category_counts_this_week.get(category, 0) + 1

    if category_counts_this_week:
        top_category_this_week = max(
            category_counts_this_week.items(), key=lambda item: item[1]
        )[0]
    else:
        top_category_this_week = None

    return {
        # Canonical keys (should be consumed by all dashboards)
        "open_needs": open_needs_count,
        "available_volunteers": available_volunteers_count,
        "completed_assignments_this_week": completed_assignments_count,
        "avg_response_time_hours": avg_response_time_hours,
        "top_category_this_week": top_category_this_week,
        # Backward-compatible keys expected by current Flutter UI
        "total_needs_open": open_needs_count,
        "total_volunteers_available": available_volunteers_count,
        "total_assignments_completed_this_week": completed_assignments_count,
        # Legacy alias kept for older clients
        "completed_assignments": completed_assignments_count,
    }

@router.get("/needs-by-category")
def get_needs_by_category() -> List[Dict[str, Any]]:
    needs = db.collection('needs').stream()
    category_counts = {}
    for need in needs:
        data = need.to_dict()
        if not data:
            continue
        category = data.get('need_category')
        if category:
            category_counts[category] = category_counts.get(category, 0) + 1
            
    result = [{"category": k, "count": v} for k, v in category_counts.items()]
    result.sort(key=lambda x: x["count"], reverse=True)
    return result

@router.get("/geographic")
def get_geographic() -> Dict[str, Any]:
    open_needs = db.collection('needs').where('status', '==', 'OPEN').stream()
    features = []
    
    for need in open_needs:
        data = need.to_dict()
        if not data:
            continue
        lat = data.get('lat', data.get('latitude'))
        lng = data.get('lng', data.get('longitude'))
        
        if lat is not None and lng is not None:
            feature = {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [lng, lat]
                },
                "properties": {
                    "need_id": data.get('need_id'),
                    "need_category": data.get('need_category'),
                    "urgency_score": data.get('urgency_score'),
                    "affected_population": data.get('affected_population'),
                    "priority_index": data.get('priority_index')
                }
            }
            features.append(feature)
            
    return {
        "type": "FeatureCollection",
        "features": features
    }
