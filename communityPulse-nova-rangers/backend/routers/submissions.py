import os
import uuid
import tempfile
import logging
from datetime import datetime
from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from google.cloud import pubsub_v1

# Import db from backend.firebase_init
from backend.firebase_init import db
from agents.pipeline import run_pipeline

router = APIRouter(tags=["submissions"])
logger = logging.getLogger(__name__)

@router.post("/upload")
async def upload_submission(
    file: UploadFile = File(...),
    org_id: str = Form(...),
    submitted_by: str = Form(...)
):
    # Validate mimetype
    allowed_mimetypes = {"application/pdf", "image/jpeg", "image/png"}
    if file.content_type not in allowed_mimetypes:
        raise HTTPException(status_code=400, detail="Invalid file type. Only PDF, JPEG, and PNG are allowed.")

    # Generate a UUID as submission_id
    submission_id = str(uuid.uuid4())
    
    # Determine type based on mimetype
    file_type = "pdf" if file.content_type == "application/pdf" else "image"

    # Save file bytes to a temp file
    file_bytes = await file.read()
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(file_bytes)

    # Create a Firestore document in submission_queue collection
    doc_ref = db.collection("submission_queue").document(submission_id)
    doc_ref.set({
        "submission_id": submission_id,
        "org_id": org_id,
        "submitted_by": submitted_by,
        "file_name": file.filename,
        "file_type": file_type,
        "status": "PENDING",
        "created_at": datetime.utcnow().isoformat(),
        "processed": False,
        "extracted_text": None
    })

    # Publish a Pub/Sub message
    try:
        topic_name = os.getenv("PUBSUB_TOPIC_SUBMISSION")
        project_id = os.getenv("GCP_PROJECT_ID")
        
        if topic_name and project_id:
            publisher = pubsub_v1.PublisherClient()
            topic_path = publisher.topic_path(project_id, topic_name)
            
            message_data = submission_id.encode("utf-8")
            future = publisher.publish(topic_path, data=message_data)
            future.result()  # block until successful publish or raise exception
        else:
            logger.warning("Pub/Sub publish skipped: PUBSUB_TOPIC_SUBMISSION or GCP_PROJECT_ID missing in env.")
    except Exception as e:
        logger.error(f"Failed to publish submission {submission_id} to Pub/Sub: {e}")

    return {
        "submission_id": submission_id,
        "status": "QUEUED"
    }

@router.get("/{submission_id}/status")
async def get_submission_status(submission_id: str):
    doc_ref = db.collection("submission_queue").document(submission_id)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Submission not found")
        
    data = doc.to_dict()
    
    return {
        "submission_id": data.get("submission_id"),
        "status": data.get("status"),
        "processed": data.get("processed"),
        "extracted_text": data.get("extracted_text"),
        "created_at": data.get("created_at")
    }

@router.post("/{submission_id}/process")
async def process_submission_manual(submission_id: str, org_id: str = "org-001"):
    import traceback
    try:
        result = await run_pipeline(submission_id, org_id)
        return result
    except Exception as e:
        return {"error_type": type(e).__name__, "error_msg": str(e), "traceback": traceback.format_exc()}
