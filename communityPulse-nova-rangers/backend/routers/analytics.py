from fastapi import APIRouter
from backend.firebase_init import db
from cachetools import TTLCache, cached
from typing import Dict, Any, List

router = APIRouter()

summary_cache = TTLCache(maxsize=1, ttl=60)

@router.get("/summary")
@cached(cache=summary_cache)
def get_summary() -> Dict[str, Any]:
    open_needs_count = len(list(db.collection('needs').where('status', '==', 'OPEN').stream()))
    available_volunteers_count = len(list(db.collection('volunteers').where('availability_status', '==', 'AVAILABLE').stream()))
    completed_assignments_count = len(list(db.collection('assignments').where('status', '==', 'COMPLETED').stream()))
    
    return {
        "open_needs": open_needs_count,
        "available_volunteers": available_volunteers_count,
        "completed_assignments": completed_assignments_count,
        "top_category_this_week": "FLOOD",
        "avg_response_time_hours": 4.5
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
        lat = data.get('lat')
        lng = data.get('lng')
        
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
