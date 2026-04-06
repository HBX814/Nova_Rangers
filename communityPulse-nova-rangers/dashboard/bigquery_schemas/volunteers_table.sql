-- =============================================================================
-- BigQuery Table Schema: volunteers
-- =============================================================================
-- Dataset: community_pulse_analytics
-- Synced from Firestore 'volunteers' collection.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `${GCP_PROJECT_ID}.community_pulse_analytics.volunteers` (
    volunteer_id        STRING      NOT NULL,
    name                STRING      NOT NULL,
    phone               STRING,
    skills              ARRAY<STRING>,
    current_lat         FLOAT64,
    current_lng         FLOAT64,
    availability_status STRING,     -- AVAILABLE|BUSY|OFFLINE
    performance_score   FLOAT64     DEFAULT 0.0,
    tasks_completed     INT64       DEFAULT 0,
    geohash             STRING,
    languages           ARRAY<STRING>,
    joined_date         DATE,
    _synced_at          TIMESTAMP   DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY joined_date
CLUSTER BY availability_status, performance_score;
