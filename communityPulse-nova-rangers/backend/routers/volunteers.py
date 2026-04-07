from fastapi import APIRouter, HTTPException, Query, Path
from typing import Optional
from pydantic import BaseModel
from backend.firebase_init import db
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore import Query as FirestoreQuery

router = APIRouter(tags=["volunteers"])

class StatusUpdate(BaseModel):
    availability_status: str

@router.get("/")
async def list_volunteers(
    status: Optional[str] = Query(None, description="Filter by availability_status"),
    skill: Optional[str] = Query(None, description="Check if value is in skills array"),
    limit: int = Query(20, ge=1, description="Limit the number of returned volunteers")
):
    volunteers_ref = db.collection("volunteers")
    query = volunteers_ref

    if status:
        query = query.where(filter=FieldFilter("availability_status", "==", status))
    if skill:
        query = query.where(filter=FieldFilter("skills", "array_contains", skill))
    
    query = query.limit(limit)
    docs = query.stream()
    
    volunteers = []
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        volunteers.append(data)
        
    return volunteers

@router.get("/{volunteer_id}")
async def get_volunteer(volunteer_id: str = Path(...)):
    doc_ref = db.collection("volunteers").document(volunteer_id)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Volunteer not found")
        
    data = doc.to_dict()
    data["id"] = doc.id
    return data

@router.patch("/{volunteer_id}/status")
async def update_volunteer_status(
    status_update: StatusUpdate,
    volunteer_id: str = Path(...)
):
    valid_statuses = {"AVAILABLE", "BUSY", "OFFLINE"}
    if status_update.availability_status not in valid_statuses:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid availability_status. Must be one of: {', '.join(valid_statuses)}"
        )
        
    doc_ref = db.collection("volunteers").document(volunteer_id)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Volunteer not found")
        
    doc_ref.update({"availability_status": status_update.availability_status})
    
    updated_doc = doc_ref.get()
    data = updated_doc.to_dict()
    data["id"] = updated_doc.id
    return data

@router.get("/{volunteer_id}/assignments")
async def get_volunteer_assignments(
    volunteer_id: str = Path(...)
):
    assignments_ref = db.collection("assignments")
    query = assignments_ref.where(filter=FieldFilter("volunteer_id", "==", volunteer_id))
    query = query.order_by("assigned_at", direction=FirestoreQuery.DESCENDING)
    query = query.limit(50)
    
    docs = query.stream()
    assignments = []
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        assignments.append(data)
        
    return assignments
