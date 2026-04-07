from fastapi import APIRouter, HTTPException, Query, Header
from typing import Optional, List
from cachetools import TTLCache
from firebase_admin import firestore
from backend.firebase_init import db

router = APIRouter(tags=["needs"])

# Cache for heatmap: maxsize=1, ttl=30 seconds
heatmap_cache = TTLCache(maxsize=1, ttl=30)

@router.get("/")
async def get_needs(
    category: Optional[str] = None,
    status: Optional[str] = None,
    min_urgency: Optional[int] = None,
    limit: int = Query(20, le=100)
):
    query = db.collection("needs")

    if category:
        query = query.where("need_category", "==", category)
    if status:
        query = query.where("status", "==", status)
    if min_urgency is not None:
        query = query.where("urgency_score", ">=", min_urgency)

    docs = query.stream()
    results = []
    for doc in docs:
        doc_data = doc.to_dict()
        doc_data['id'] = doc.id
        results.append(doc_data)

    # Sort in memory to avoid Firestore composite index requirements
    results.sort(key=lambda x: x.get("priority_index", 0), reverse=True)
    
    # Apply limit in memory
    results = results[:limit]

    return results

@router.get("/heatmap")
async def get_heatmap():
    # Check cache first
    cached_data = heatmap_cache.get("heatmap_data")
    if cached_data is not None:
        return cached_data

    # Query all needs where status is OPEN
    query = db.collection("needs").where("status", "==", "OPEN")
    docs = query.stream()

    results = []
    for doc in docs:
        data = doc.to_dict()
        results.append({
            "need_id": data.get("need_id", doc.id),
            "lat": data.get("lat"),
            "lng": data.get("lng"),
            "need_category": data.get("need_category"),
            "urgency_score": data.get("urgency_score"),
            "affected_population": data.get("affected_population")
        })

    # Store in cache
    heatmap_cache["heatmap_data"] = results

    return results

@router.get("/{need_id}")
async def get_need(need_id: str):
    doc_ref = db.collection("needs").document(need_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="Need not found")

    data = doc.to_dict()
    data['id'] = doc.id
    return data

@router.post("/{need_id}/escalate")
async def escalate_need(need_id: str, authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Unauthorized: Missing Authorization header")

    doc_ref = db.collection("needs").document(need_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="Need not found")

    # Update document in Firestore
    doc_ref.update({
        "urgency_score": 10,
        "status": "IN_PROGRESS"
    })

    # Fetch and return the updated document
    updated_doc = doc_ref.get().to_dict()
    updated_doc['id'] = doc_ref.id
    return updated_doc
