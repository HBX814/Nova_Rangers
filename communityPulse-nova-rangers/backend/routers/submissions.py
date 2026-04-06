"""
Submissions Router
==================
Handles citizen / volunteer report submissions.
The submission is validated, stored, and then published to Pub/Sub
for processing by the Google ADK agent pipeline.
"""

from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status

from backend.models.submission import SubmissionPayload
from backend.services.firestore_client import get_firestore_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/", response_model=SubmissionPayload, status_code=status.HTTP_201_CREATED)
async def create_submission(payload: SubmissionPayload):
    """
    Accept a new need report submission.

    Steps:
      1. Assign a unique submission_id and timestamp.
      2. Persist to Firestore 'submissions' collection.
      3. Publish a message to Pub/Sub topic so the agent pipeline processes it.
    """
    db = get_firestore_client()

    payload.submission_id = str(uuid.uuid4())
    payload.submitted_at = datetime.now(timezone.utc)

    doc_data = payload.model_dump(mode="json")
    db.collection("submissions").document(payload.submission_id).set(doc_data)

    # TODO: Publish to Pub/Sub topic for agent pipeline consumption
    # from google.cloud import pubsub_v1
    # publisher = pubsub_v1.PublisherClient()
    # topic_path = publisher.topic_path(GCP_PROJECT_ID, PUBSUB_TOPIC_NEW_NEED)
    # publisher.publish(topic_path, json.dumps(doc_data).encode("utf-8"))

    logger.info("Submission %s created and queued for processing", payload.submission_id)
    return payload


@router.get("/", response_model=list[SubmissionPayload])
async def list_submissions(limit: int = 50):
    """List recent submissions, newest first."""
    db = get_firestore_client()
    docs = (
        db.collection("submissions")
        .order_by("submitted_at", direction="DESCENDING")
        .limit(limit)
        .stream()
    )
    results = []
    for doc in docs:
        data = doc.to_dict()
        if data:
            results.append(SubmissionPayload(**data))
    return results


@router.get("/{submission_id}", response_model=SubmissionPayload)
async def get_submission(submission_id: str):
    """Retrieve a single submission by ID."""
    db = get_firestore_client()
    snap = db.collection("submissions").document(submission_id).get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Submission not found")
    return SubmissionPayload(**snap.to_dict())
