"""
APScheduler Job Functions
=========================
These functions are invoked by the scheduler configured in main.py.

  • compute_volunteer_scores — runs at midnight IST daily
  • generate_weekly_report   — runs Monday 6 AM IST

Both use the Firestore client to read/write data.
"""

import logging
from datetime import datetime, timezone

logger = logging.getLogger(__name__)


async def compute_volunteer_scores() -> None:
    """
    Recalculate the performance_score for every volunteer based on:
      - tasks_completed
      - average ngo_satisfaction_rating from their assignments
      - recency of last completed task

    TODO: Implement full scoring algorithm once Firestore is connected.
    Steps:
      1. Fetch all volunteers from the 'volunteers' collection.
      2. For each volunteer, fetch their COMPLETED assignments.
      3. Compute weighted score:
           score = 0.4 * normalised_tasks_completed
                 + 0.4 * avg_satisfaction_rating / 5
                 + 0.2 * recency_factor
      4. Update volunteer document with new performance_score.
    """
    logger.info(
        "[CRON] compute_volunteer_scores triggered at %s",
        datetime.now(timezone.utc).isoformat(),
    )

    # --- Placeholder implementation ---
    from backend.services.firestore_client import get_firestore_client

    db = get_firestore_client()
    volunteers = db.collection("volunteers").stream()

    updated_count = 0
    for vol_snap in volunteers:
        vol = vol_snap.to_dict()
        if vol is None:
            continue

        tasks = vol.get("tasks_completed", 0)
        # Simple placeholder score — replace with full algorithm
        placeholder_score = min(round(tasks * 0.5, 2), 100.0)

        db.collection("volunteers").document(vol_snap.id).update(
            {"performance_score": placeholder_score}
        )
        updated_count += 1

    logger.info("[CRON] Updated scores for %d volunteers", updated_count)


async def generate_weekly_report() -> None:
    """
    Aggregate the past week's data and generate a summary report:
      - Total needs created / resolved
      - Top 10 performing volunteers
      - District-level heatmap data
      - Send email digest to org admins via Resend

    TODO: Implement full report generation once Firestore + BigQuery + Resend
          are connected.
    Steps:
      1. Query needs created/resolved in the last 7 days.
      2. Query top volunteers by performance_score.
      3. Aggregate geo data for district heatmap.
      4. Write summary to BigQuery analytics table.
      5. Send email via Resend to each org admin.
    """
    logger.info(
        "[CRON] generate_weekly_report triggered at %s",
        datetime.now(timezone.utc).isoformat(),
    )

    from backend.services.firestore_client import get_firestore_client

    db = get_firestore_client()

    # --- Placeholder: count documents ---
    needs = list(db.collection("needs").stream())
    volunteers = list(db.collection("volunteers").stream())

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_needs": len(needs),
        "total_volunteers": len(volunteers),
        "resolved_needs": sum(
            1 for n in needs if (n.to_dict() or {}).get("status") == "RESOLVED"
        ),
        # TODO: add district breakdown, top volunteers, email dispatch
    }

    logger.info("[CRON] Weekly report: %s", report)
