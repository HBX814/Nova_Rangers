import os
import uuid
import logging
import asyncio
from datetime import datetime
from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from google.cloud import pubsub_v1

# Import db from backend.firebase_init
from backend.firebase_init import db
from backend.services.ocr_service import process_document
from agents.pipeline import (
    run_pipeline,
    SubmissionNotFoundError,
    SubmissionOrgMismatchError,
    PipelineInvariantError,
)

router = APIRouter(tags=["submissions"])
logger = logging.getLogger(__name__)


async def _run_pipeline_with_logging(submission_id: str, org_id: str) -> None:
    """Best-effort local fallback when Pub/Sub processing isn't available."""
    try:
        await run_pipeline(submission_id, org_id)
    except Exception as e:
        logger.exception(
            "Local pipeline processing failed for submission %s: %s",
            submission_id,
            e,
        )

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

    # Read bytes and extract text immediately so the classifier has real content.
    file_bytes = await file.read()
    ocr_result = process_document(file_bytes, file_type)
    extracted_text = ocr_result.get("extracted_text") or ""
    if not extracted_text.strip():
        # Allow queueing when AI OCR quota is exhausted; classifier fallback can still proceed.
        ocr_method = str(ocr_result.get('ocr_method', 'unknown'))
        if "ResourceExhausted" not in ocr_method:
            raise HTTPException(
                status_code=422,
                detail=(
                    "Could not extract text from document. "
                    f"OCR method: {ocr_method} "
                    f"(confidence: {ocr_result.get('confidence', 0)}). "
                    "Please upload a clearer PDF/image with readable text."
                ),
            )
        extracted_text = f"Emergency field report uploaded by {submitted_by} for org {org_id} in Madhya Pradesh."

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
        "extracted_text": extracted_text,
        "ocr_method": ocr_result.get("ocr_method"),
        "ocr_confidence": ocr_result.get("confidence"),
    })

    # Publish a Pub/Sub message
    published = False
    try:
        topic_name = os.getenv("PUBSUB_TOPIC_SUBMISSION")
        project_id = os.getenv("GCP_PROJECT_ID")
        
        if topic_name and project_id:
            publisher = pubsub_v1.PublisherClient()
            topic_path = publisher.topic_path(project_id, topic_name)
            
            message_data = submission_id.encode("utf-8")
            future = publisher.publish(topic_path, data=message_data)
            future.result()  # block until successful publish or raise exception
            published = True
        else:
            logger.warning("Pub/Sub publish skipped: PUBSUB_TOPIC_SUBMISSION or GCP_PROJECT_ID missing in env.")
    except Exception as e:
        logger.error(f"Failed to publish submission {submission_id} to Pub/Sub: {e}")

    # Local-dev fallback: process directly when Pub/Sub isn't wired.
    if not published:
        asyncio.create_task(_run_pipeline_with_logging(submission_id, org_id))

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
    try:
        result = await run_pipeline(submission_id, org_id)
        return result
    except SubmissionNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except SubmissionOrgMismatchError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except PipelineInvariantError as e:
        raise HTTPException(status_code=500, detail=str(e))
