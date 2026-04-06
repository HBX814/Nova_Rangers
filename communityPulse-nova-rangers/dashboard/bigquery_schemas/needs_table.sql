-- =============================================================================
-- BigQuery Table Schema: needs
-- =============================================================================
-- Dataset: community_pulse_analytics
-- Synced from Firestore 'needs' collection for analytics and dashboarding.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `${GCP_PROJECT_ID}.community_pulse_analytics.needs` (
    need_id             STRING      NOT NULL,
    need_category       STRING      NOT NULL,   -- FLOOD|DROUGHT|MEDICAL|SHELTER|EDUCATION|FOOD|INFRASTRUCTURE|WATER
    title               STRING      NOT NULL,
    description         STRING,
    urgency_score       INT64       NOT NULL,   -- 1-10
    affected_population INT64       NOT NULL,
    primary_location_text STRING,
    lat                 FLOAT64     NOT NULL,
    lng                 FLOAT64     NOT NULL,
    priority_index      FLOAT64,
    status              STRING      NOT NULL,   -- OPEN|IN_PROGRESS|RESOLVED
    report_count        INT64       DEFAULT 1,
    submitted_at        TIMESTAMP   NOT NULL,
    org_id              STRING      NOT NULL,
    -- Partitioning and clustering for efficient queries
    _synced_at          TIMESTAMP   DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(submitted_at)
CLUSTER BY need_category, status, org_id;
