"""
CommunityPulse — FastAPI Application Entrypoint
================================================
Initialises:
  • CORS middleware (configured for Flutter web + any allowed origins)
  • OpenTelemetry tracer exporting to Google Cloud Trace
  • APScheduler with two cron jobs:
      – midnight IST  → compute_volunteer_scores
      – Monday 6 AM IST → generate_weekly_report
  • All API routers mounted under /api/v1
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# ---------------------------------------------------------------------------
# Config (reads .env once at import time)
# ---------------------------------------------------------------------------
from backend.config import (
    CORS_ALLOWED_ORIGINS,
    ENABLE_CLOUD_TRACE,
    GCP_PROJECT_ID,
)

# ---------------------------------------------------------------------------
# OpenTelemetry setup
# ---------------------------------------------------------------------------
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor

tracer_provider = TracerProvider()

if ENABLE_CLOUD_TRACE and GCP_PROJECT_ID:
    # TODO: Uncomment when deploying with real GCP credentials
    # from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
    # cloud_trace_exporter = CloudTraceSpanExporter(project_id=GCP_PROJECT_ID)
    # tracer_provider.add_span_processor(SimpleSpanProcessor(cloud_trace_exporter))
    pass

trace.set_tracer_provider(tracer_provider)
tracer = trace.get_tracer(__name__)

# ---------------------------------------------------------------------------
# APScheduler
# ---------------------------------------------------------------------------
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from backend.services.scheduler_jobs import compute_volunteer_scores, generate_weekly_report

scheduler = AsyncIOScheduler(timezone="Asia/Kolkata")

# Midnight IST every day
scheduler.add_job(
    compute_volunteer_scores,
    trigger=CronTrigger(hour=0, minute=0, timezone="Asia/Kolkata"),
    id="compute_volunteer_scores",
    replace_existing=True,
)

# Monday 6 AM IST
scheduler.add_job(
    generate_weekly_report,
    trigger=CronTrigger(day_of_week="mon", hour=6, minute=0, timezone="Asia/Kolkata"),
    id="generate_weekly_report",
    replace_existing=True,
)

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
from backend.routers.submissions import router as submissions_router
from backend.routers.volunteers import router as volunteers_router
from backend.routers.needs import router as needs_router
from backend.routers.organizations import router as organizations_router
from backend.routers.analytics import router as analytics_router
from backend.routers.auth import router as auth_router


# ---------------------------------------------------------------------------
# Lifespan (startup / shutdown)
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    scheduler.start()
    yield
    # Shutdown
    scheduler.shutdown(wait=False)
    tracer_provider.shutdown()


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title="CommunityPulse API",
    description="Data-driven volunteer coordination platform for social-impact NGOs in Madhya Pradesh",
    version="0.1.0",
    lifespan=lifespan,
)

# ---------------------------------------------------------------------------
# CORS Middleware — allows Flutter web (localhost:3000+) and production domains
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOWED_ORIGINS if CORS_ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Mount routers under /api/v1
# ---------------------------------------------------------------------------
app.include_router(submissions_router, prefix="/api/v1/submissions", tags=["Submissions"])
app.include_router(volunteers_router, prefix="/api/v1/volunteers", tags=["Volunteers"])
app.include_router(needs_router, prefix="/api/v1/needs", tags=["Needs"])
app.include_router(organizations_router, prefix="/api/v1/organizations", tags=["Organizations"])
app.include_router(analytics_router, prefix="/api/v1/analytics", tags=["Analytics"])
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Auth"])


# ---------------------------------------------------------------------------
# Health check (root)
# ---------------------------------------------------------------------------
@app.get("/", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "CommunityPulse API",
        "version": "0.1.0",
    }
