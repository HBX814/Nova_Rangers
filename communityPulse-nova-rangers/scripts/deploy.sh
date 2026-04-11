#!/usr/bin/env bash
# =============================================================================
# deploy.sh — CommunityPulse Backend Deployment Script
# =============================================================================
# Usage: bash scripts/deploy.sh
# Requires: docker, gcloud (authenticated), .env file in the project root
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

# FIX: Dockerfile lives under docker/, not at project root
DOCKERFILE="${PROJECT_ROOT}/docker/Dockerfile.backend"

# Tag requested by user
FULL_IMAGE="asia-south1-docker.pkg.dev/communitypulse-nova-rangers/communitypulse/backend:latest"

CLOUD_RUN_SERVICE="communitypulse-api"
CLOUD_RUN_REGION="asia-south1"
CLOUD_RUN_PLATFORM="managed"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()   { echo -e "\033[1;32m[ OK ]\033[0m  $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m  $*" >&2; exit 1; }
step() { echo -e "\n\033[1;36m==> $*\033[0m"; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
step "Running pre-flight checks..."

command -v docker  >/dev/null 2>&1 || err "docker is not installed or not in PATH."
command -v gcloud  >/dev/null 2>&1 || err "gcloud is not installed or not in PATH."

[[ -f "${ENV_FILE}" ]]   || err ".env file not found at ${ENV_FILE}"
[[ -f "${DOCKERFILE}" ]] || err "Dockerfile not found at ${DOCKERFILE}"

ok "All pre-flight checks passed."

# ---------------------------------------------------------------------------
# Load environment variables from .env
# ---------------------------------------------------------------------------
step "Loading environment variables from .env..."

load_env_var() {
  local key="$1"
  local value
  value=$(grep -E "^${key}=" "${ENV_FILE}" | head -n1 | cut -d'=' -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
  # FIX: Trim any trailing carriage returns (Windows line endings in .env files)
  value="${value//$'\r'/}"
  if [[ -z "${value}" ]]; then
    err "Required variable '${key}' not found or empty in ${ENV_FILE}"
  fi
  echo "${value}"
}

GCP_PROJECT_ID=$(load_env_var "GCP_PROJECT_ID")
GEMINI_API_KEY=$(load_env_var "GEMINI_API_KEY")
PUBSUB_TOPIC_SUBMISSION=$(load_env_var "PUBSUB_TOPIC_SUBMISSION")
PUBSUB_TOPIC_MATCH=$(load_env_var "PUBSUB_TOPIC_MATCH")
RESEND_API_KEY=$(load_env_var "RESEND_API_KEY")

log "GCP_PROJECT_ID          = ${GCP_PROJECT_ID}"
log "PUBSUB_TOPIC_SUBMISSION = ${PUBSUB_TOPIC_SUBMISSION}"
log "PUBSUB_TOPIC_MATCH      = ${PUBSUB_TOPIC_MATCH}"
log "ENVIRONMENT             = production"
ok "Environment variables loaded."

# ---------------------------------------------------------------------------
# Step 1 — Build the Docker image
# ---------------------------------------------------------------------------
step "Step 1/4 — Building Docker image..."
log "Dockerfile : ${DOCKERFILE}"
log "Context    : ${PROJECT_ROOT}"
log "Tag        : ${FULL_IMAGE}"

docker build \
  --file "${DOCKERFILE}" \
  --tag  "${FULL_IMAGE}" \
  "${PROJECT_ROOT}"

ok "Docker image built successfully: ${FULL_IMAGE}"

# ---------------------------------------------------------------------------
# Step 2 — Push the image to Google Artifact Registry
# ---------------------------------------------------------------------------
step "Step 2/4 — Pushing image to Google Artifact Registry..."

# FIX: configure-docker can print warnings; only fail on non-zero exit code
gcloud auth configure-docker "asia-south1-docker.pkg.dev" --quiet || \
  err "gcloud auth configure-docker failed. Run: gcloud auth login"

docker push "${FULL_IMAGE}"

ok "Image pushed to Artifact Registry: ${FULL_IMAGE}"

# ---------------------------------------------------------------------------
# Step 3/4 — Deploy to Cloud Run
# ---------------------------------------------------------------------------
step "Step 3/4 — Deploying to Cloud Run..."
log "Service  : ${CLOUD_RUN_SERVICE}"
log "Region   : ${CLOUD_RUN_REGION}"
log "Platform : ${CLOUD_RUN_PLATFORM}"
log "Image    : ${FULL_IMAGE}"

# Environment variables as a comma-separated list
# Note: we pass both GEMINI_API_KEY and GOOGLE_GENAI_API_KEY for compatibility 
# between config.py and router-level os.getenv calls.
ENV_VARS="\
GCP_PROJECT_ID=${GCP_PROJECT_ID},\
GEMINI_API_KEY=${GEMINI_API_KEY},\
GOOGLE_GENAI_API_KEY=${GEMINI_API_KEY},\
PUBSUB_TOPIC_SUBMISSION=${PUBSUB_TOPIC_SUBMISSION},\
PUBSUB_TOPIC_MATCH=${PUBSUB_TOPIC_MATCH},\
RESEND_API_KEY=${RESEND_API_KEY},\
ENVIRONMENT=production"

gcloud run deploy "${CLOUD_RUN_SERVICE}" \
  --image           "${FULL_IMAGE}" \
  --region          "${CLOUD_RUN_REGION}" \
  --platform        "${CLOUD_RUN_PLATFORM}" \
  --allow-unauthenticated \
  --project         "${GCP_PROJECT_ID}" \
  --set-env-vars    "${ENV_VARS}" \
    --cpu             "1" \
    --memory          "2Gi" \
    --timeout         "600s" \
    --concurrency     "80" \
  --min-instances   "0" \
  --max-instances   "10"

ok "Deployment complete!"

# ---------------------------------------------------------------------------
# Step 4/4 — Output Service URL
# ---------------------------------------------------------------------------
step "Step 4/4 — Service URL:"
gcloud run services describe "${CLOUD_RUN_SERVICE}" \
  --region  "${CLOUD_RUN_REGION}" \
  --project "${GCP_PROJECT_ID}" \
  --format  "value(status.url)"