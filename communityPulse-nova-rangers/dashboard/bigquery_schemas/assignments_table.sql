-- =============================================================================
-- BigQuery Table Schema: assignments
-- =============================================================================
-- Dataset: community_pulse_analytics
-- Synced from Firestore 'assignments' collection.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `${GCP_PROJECT_ID}.community_pulse_analytics.assignments` (
    assignment_id           STRING      NOT NULL,
    need_id                 STRING      NOT NULL,
    volunteer_id            STRING      NOT NULL,
    status                  STRING      NOT NULL,   -- PENDING|ACCEPTED|IN_PROGRESS|COMPLETED
    assigned_at             TIMESTAMP   NOT NULL,
    accepted_at             TIMESTAMP,
    completed_at            TIMESTAMP,
    ngo_satisfaction_rating INT64,                   -- 1-5 (nullable)
    _synced_at              TIMESTAMP   DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(assigned_at)
CLUSTER BY status, volunteer_id;
