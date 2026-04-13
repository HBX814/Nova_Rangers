from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException

from backend.firebase_init import db

router = APIRouter(tags=["assignments"])


@router.patch("/{assignment_id}/accept")
async def accept_assignment(assignment_id: str):
    doc_ref = db.collection("assignments").document(assignment_id)
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Assignment not found")

    updates = {
        "status": "ACCEPTED",
        "accepted_at": datetime.now(timezone.utc).isoformat(),
    }
    doc_ref.update(updates)

    updated = doc_ref.get().to_dict() or {}
    updated["id"] = assignment_id
    return updated


@router.patch("/{assignment_id}/complete")
async def complete_assignment(assignment_id: str):
    doc_ref = db.collection("assignments").document(assignment_id)
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Assignment not found")

    updates = {
        "status": "COMPLETED",
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }
    doc_ref.update(updates)

    updated = doc_ref.get().to_dict() or {}
    updated["id"] = assignment_id
    return updated
