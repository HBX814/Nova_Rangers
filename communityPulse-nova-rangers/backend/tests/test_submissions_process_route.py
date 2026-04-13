from fastapi import FastAPI
from fastapi.testclient import TestClient

from backend.routers import submissions as submissions_router


def _build_client() -> TestClient:
    app = FastAPI()
    app.include_router(submissions_router.router, prefix="/api/v1/submissions")
    return TestClient(app)


def test_process_route_returns_403_on_org_mismatch(monkeypatch):
    async def fake_run_pipeline(submission_id: str, org_id: str):
        raise submissions_router.SubmissionOrgMismatchError("org_id mismatch for submission abc")

    monkeypatch.setattr(submissions_router, "run_pipeline", fake_run_pipeline)

    client = _build_client()
    response = client.post("/api/v1/submissions/abc/process", params={"org_id": "org-001"})

    assert response.status_code == 403
    assert "org_id mismatch" in response.json()["detail"]


def test_process_route_returns_404_when_submission_missing(monkeypatch):
    async def fake_run_pipeline(submission_id: str, org_id: str):
        raise submissions_router.SubmissionNotFoundError("Submission not found: abc")

    monkeypatch.setattr(submissions_router, "run_pipeline", fake_run_pipeline)

    client = _build_client()
    response = client.post("/api/v1/submissions/abc/process", params={"org_id": "org-001"})

    assert response.status_code == 404
    assert "Submission not found" in response.json()["detail"]

