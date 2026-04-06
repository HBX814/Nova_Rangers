"""
Apache Superset Configuration
==============================
This file is mounted into the Superset container at
/app/pythonpath/superset_config.py via docker-compose.

Configure the BigQuery connection for CommunityPulse analytics.
"""

import os

# ---------------------------------------------------------------------------
# Superset core config
# ---------------------------------------------------------------------------
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "change-me-in-production")

# Use SQLite for Superset metadata in dev; Postgres in production
SQLALCHEMY_DATABASE_URI = os.environ.get(
    "SUPERSET_METADATA_DB_URI",
    "sqlite:////app/superset_home/superset.db",
)

# ---------------------------------------------------------------------------
# Feature flags
# ---------------------------------------------------------------------------
FEATURE_FLAGS = {
    "DASHBOARD_NATIVE_FILTERS": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "EMBEDDED_SUPERSET": True,
}

# ---------------------------------------------------------------------------
# BigQuery data source configuration
# ---------------------------------------------------------------------------
# After deploying Superset, add a BigQuery database connection via the UI:
#   Database → + Database → Google BigQuery
#   Use the service account JSON from GOOGLE_APPLICATION_CREDENTIALS.
#
# Or set it programmatically:
# SQLALCHEMY_BIGQUERY_URI = (
#     f"bigquery://{os.environ.get('GCP_PROJECT_ID', '')}"
#     f"/{os.environ.get('BIGQUERY_DATASET', 'community_pulse_analytics')}"
# )

# ---------------------------------------------------------------------------
# Cache (use Redis if available)
# ---------------------------------------------------------------------------
REDIS_URL = os.environ.get("UPSTASH_REDIS_URL", "")
if REDIS_URL:
    CACHE_CONFIG = {
        "CACHE_TYPE": "RedisCache",
        "CACHE_DEFAULT_TIMEOUT": 300,
        "CACHE_KEY_PREFIX": "superset_",
        "CACHE_REDIS_URL": REDIS_URL,
    }

# ---------------------------------------------------------------------------
# CORS for embedded dashboards
# ---------------------------------------------------------------------------
ENABLE_CORS = True
CORS_OPTIONS = {
    "supports_credentials": True,
    "allow_headers": ["*"],
    "resources": ["*"],
    "origins": os.environ.get("CORS_ALLOWED_ORIGINS", "*").split(","),
}

# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------
WTF_CSRF_ENABLED = True
PREVENT_UNSAFE_DB_CONNECTIONS = False
