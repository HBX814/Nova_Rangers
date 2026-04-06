"""
Centralised configuration — every external credential and tuneable is read from
environment variables here so the rest of the codebase never touches os.environ
directly.  See .env.example at the repo root for documentation on each variable.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env from the repo root (one level above backend/)
_env_path = Path(__file__).resolve().parent.parent / ".env"
if _env_path.exists():
    load_dotenv(_env_path)


# ---------------------------------------------------------------------------
# Google Cloud Platform
# ---------------------------------------------------------------------------
GCP_PROJECT_ID: str = os.environ.get("GCP_PROJECT_ID", "")
GCP_REGION: str = os.environ.get("GCP_REGION", "asia-south1")
GOOGLE_APPLICATION_CREDENTIALS: str = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")

# ---------------------------------------------------------------------------
# Firebase / Firestore
# ---------------------------------------------------------------------------
FIREBASE_CREDENTIALS_PATH: str = os.environ.get("FIREBASE_CREDENTIALS_PATH", "")
FIRESTORE_DATABASE_ID: str = os.environ.get("FIRESTORE_DATABASE_ID", "(default)")

# ---------------------------------------------------------------------------
# Gemini / ADK
# ---------------------------------------------------------------------------
GOOGLE_GENAI_API_KEY: str = os.environ.get("GOOGLE_GENAI_API_KEY", "")
ADK_MODEL_NAME: str = os.environ.get("ADK_MODEL_NAME", "gemini-2.5-flash")

# ---------------------------------------------------------------------------
# Pub/Sub
# ---------------------------------------------------------------------------
PUBSUB_TOPIC_NEW_NEED: str = os.environ.get("PUBSUB_TOPIC_NEW_NEED", "new-need-created")
PUBSUB_SUBSCRIPTION_AGENTS: str = os.environ.get("PUBSUB_SUBSCRIPTION_AGENTS", "agents-new-need-sub")

# ---------------------------------------------------------------------------
# BigQuery
# ---------------------------------------------------------------------------
BIGQUERY_DATASET: str = os.environ.get("BIGQUERY_DATASET", "community_pulse_analytics")

# ---------------------------------------------------------------------------
# OpenTelemetry / Cloud Trace
# ---------------------------------------------------------------------------
ENABLE_CLOUD_TRACE: bool = os.environ.get("ENABLE_CLOUD_TRACE", "false").lower() == "true"

# ---------------------------------------------------------------------------
# Upstash Redis
# ---------------------------------------------------------------------------
UPSTASH_REDIS_URL: str = os.environ.get("UPSTASH_REDIS_URL", "")
UPSTASH_REDIS_TOKEN: str = os.environ.get("UPSTASH_REDIS_TOKEN", "")

# ---------------------------------------------------------------------------
# Resend (email)
# ---------------------------------------------------------------------------
RESEND_API_KEY: str = os.environ.get("RESEND_API_KEY", "")
RESEND_FROM_EMAIL: str = os.environ.get("RESEND_FROM_EMAIL", "noreply@example.com")

# ---------------------------------------------------------------------------
# JWT / Auth
# ---------------------------------------------------------------------------
JWT_SECRET_KEY: str = os.environ.get("JWT_SECRET_KEY", "change-me")
JWT_ALGORITHM: str = os.environ.get("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.environ.get("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------
BACKEND_HOST: str = os.environ.get("BACKEND_HOST", "0.0.0.0")
BACKEND_PORT: int = int(os.environ.get("BACKEND_PORT", "8080"))

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
CORS_ALLOWED_ORIGINS: list[str] = [
    origin.strip()
    for origin in os.environ.get("CORS_ALLOWED_ORIGINS", "*").split(",")
    if origin.strip()
]
