"""
Google ADK Multi-Agent Pipeline
================================
A SequentialAgent that processes incoming need submissions through four stages:

  1. NeedsClassifier   — classifies the need category from free text
  2. DeduplicationAgent — checks if the need is a duplicate of an existing one
  3. PriorityRanker     — computes a priority_index score
  4. VolunteerMatcher   — finds and assigns the best-fit volunteer

All agents use model: gemini-2.5-flash (configurable via ADK_MODEL_NAME env var).
Each agent has placeholder tool functions with clear TODO markers.

To run standalone:
    python -m agents.pipeline
"""

from __future__ import annotations

import json
import logging
import math
import os
from typing import Any

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# TODO: Set GOOGLE_GENAI_API_KEY in your environment or .env file
ADK_MODEL_NAME = os.environ.get("ADK_MODEL_NAME", "gemini-2.5-flash")

# ---------------------------------------------------------------------------
# Google ADK imports
# ---------------------------------------------------------------------------
try:
    from google.adk.agents import LlmAgent, SequentialAgent
    from google.adk.tools import FunctionTool

    ADK_AVAILABLE = True
except ImportError:
    ADK_AVAILABLE = False
    logger.warning(
        "google-adk is not installed. Agent pipeline will use mock implementations. "
        "Install with: pip install google-adk"
    )


# =============================================================================
# Tool Functions (used by agents as callable tools)
# =============================================================================

def classify_need_from_text(text: str, media_urls: list[str] | None = None) -> dict:
    """
    Classify the need category from the submission text and optional media.

    TODO: When connected to real Gemini:
      - Use multimodal input (text + images) for classification.
      - If media_urls contains PDFs, run OCR with pytesseract/pdfplumber first.
      - Return one of: FLOOD, DROUGHT, MEDICAL, SHELTER, EDUCATION, FOOD,
        INFRASTRUCTURE, WATER.

    Args:
        text: The submission description text.
        media_urls: Optional list of Cloud Storage URLs for images/PDFs.

    Returns:
        dict with keys: category (str), confidence (float), reasoning (str)
    """
    # Placeholder classification logic based on keyword matching
    text_lower = text.lower()
    keyword_map = {
        "FLOOD": ["flood", "water logging", "submerged", "inundation", "overflow"],
        "DROUGHT": ["drought", "dry", "no water", "water scarcity", "crop failure"],
        "MEDICAL": ["medical", "hospital", "injury", "disease", "health", "medicine", "doctor"],
        "SHELTER": ["shelter", "homeless", "displaced", "housing", "roof"],
        "EDUCATION": ["education", "school", "teacher", "books", "students", "learning"],
        "FOOD": ["food", "hunger", "ration", "meal", "nutrition", "starving"],
        "INFRASTRUCTURE": ["road", "bridge", "electricity", "infrastructure", "building", "damage"],
        "WATER": ["water", "drinking water", "bore well", "hand pump", "pipeline", "tanker"],
    }

    best_category = "FOOD"  # default fallback
    best_score = 0
    for category, keywords in keyword_map.items():
        score = sum(1 for kw in keywords if kw in text_lower)
        if score > best_score:
            best_score = score
            best_category = category

    return {
        "category": best_category,
        "confidence": min(best_score * 0.25, 1.0) if best_score > 0 else 0.3,
        "reasoning": f"Keyword match: found {best_score} keywords for {best_category}",
    }


def check_duplicate_need(
    need_title: str,
    need_description: str,
    lat: float,
    lng: float,
    radius_km: float = 5.0,
) -> dict:
    """
    Check if a similar need already exists within a geographic radius.

    TODO: When connected to real infrastructure:
      - Use ChromaDB vector store with sentence-transformers embeddings
        to find semantically similar needs.
      - Filter by geohash prefix for spatial proximity.
      - Use a similarity threshold (e.g., cosine > 0.85) to flag duplicates.

    Args:
        need_title: Title of the new need.
        need_description: Description text.
        lat: Latitude of the need location.
        lng: Longitude of the need location.
        radius_km: Search radius in kilometres.

    Returns:
        dict with keys: is_duplicate (bool), duplicate_of_need_id (str|None),
                        similarity_score (float)
    """
    # Placeholder: no duplicates found in local dev
    logger.info(
        "Checking duplicates for '%s' at (%f, %f) within %f km",
        need_title, lat, lng, radius_km,
    )
    return {
        "is_duplicate": False,
        "duplicate_of_need_id": None,
        "similarity_score": 0.0,
    }


def compute_priority_score(
    urgency_score: int,
    affected_population: int,
    report_count: int,
    hours_since_submission: float,
) -> float:
    """
    Compute the priority index for a need.

    Formula (as described in the architecture):
        priority = (urgency_score * 0.4)
                 + (log(affected_population + 1) * 0.3)
                 + (log(report_count + 1) * 0.15)
                 + (min(hours_since_submission / 72, 1.0) * 0.15)

    Args:
        urgency_score: 1-10 integer urgency rating.
        affected_population: Number of people affected.
        report_count: How many times this need has been reported.
        hours_since_submission: Hours elapsed since first submission.

    Returns:
        float priority index (higher = more urgent).
    """
    priority = (
        (urgency_score * 0.4)
        + (math.log(affected_population + 1) * 0.3)
        + (math.log(report_count + 1) * 0.15)
        + (min(hours_since_submission / 72.0, 1.0) * 0.15)
    )
    return round(priority, 4)


def match_volunteer_to_need(
    need_id: str,
    need_category: str,
    lat: float,
    lng: float,
    required_skills: list[str] | None = None,
) -> dict:
    """
    Find the best volunteer match for a given need.

    TODO: When connected to real infrastructure:
      - Query available volunteers near (lat, lng) using geohash prefix.
      - Score each candidate on: distance, skill match, performance_score,
        language match, current workload.
      - Use Gemini for nuanced matching when skill descriptions are ambiguous.
      - Create an Assignment document and send FCM push notification.

    Args:
        need_id: The ID of the need to assign.
        need_category: Category of the need (for skill matching).
        lat: Need location latitude.
        lng: Need location longitude.
        required_skills: Optional specific skills needed.

    Returns:
        dict with keys: matched (bool), volunteer_id (str|None),
                        assignment_id (str|None), match_score (float)
    """
    logger.info(
        "Matching volunteer for need %s (category=%s) at (%f, %f)",
        need_id, need_category, lat, lng,
    )
    # Placeholder: no match in local dev (no volunteers in mock store)
    return {
        "matched": False,
        "volunteer_id": None,
        "assignment_id": None,
        "match_score": 0.0,
    }


# =============================================================================
# Agent Pipeline Construction
# =============================================================================

def build_pipeline() -> Any:
    """
    Build the SequentialAgent pipeline with four LlmAgent stages.

    Returns the SequentialAgent if google-adk is available, otherwise
    returns a mock pipeline object for local development.
    """
    if not ADK_AVAILABLE:
        logger.warning("Returning mock pipeline (google-adk not installed)")
        return _MockPipeline()

    # --- Stage 1: Needs Classifier ---
    needs_classifier = LlmAgent(
        name="NeedsClassifier",
        model=ADK_MODEL_NAME,
        instruction="""You are a needs classification agent for CommunityPulse, a disaster
and social-need coordination platform operating in Madhya Pradesh, India.

Given a submission (text + optional media descriptions), classify it into exactly
one of these categories: FLOOD, DROUGHT, MEDICAL, SHELTER, EDUCATION, FOOD,
INFRASTRUCTURE, WATER.

Also estimate an urgency_score from 1 (low) to 10 (critical) based on the
severity described.

Use the classify_need_from_text tool to perform the classification.""",
        tools=[FunctionTool(classify_need_from_text)],
    )

    # --- Stage 2: Deduplication Agent ---
    dedup_agent = LlmAgent(
        name="DeduplicationAgent",
        model=ADK_MODEL_NAME,
        instruction="""You are a deduplication agent. Given a classified need with its
location coordinates, check if a substantially similar need already exists
within a 5 km radius.

Use the check_duplicate_need tool. If a duplicate is found (similarity > 0.85),
flag it and reference the existing need_id. Otherwise, mark it as new.""",
        tools=[FunctionTool(check_duplicate_need)],
    )

    # --- Stage 3: Priority Ranker ---
    priority_ranker = LlmAgent(
        name="PriorityRanker",
        model=ADK_MODEL_NAME,
        instruction="""You are a priority ranking agent. For each new (non-duplicate) need,
compute the priority_index using the compute_priority_score tool.

The formula weighs urgency (40%), affected population scale (30%),
report frequency (15%), and time sensitivity (15%).

Return the computed priority_index.""",
        tools=[FunctionTool(compute_priority_score)],
    )

    # --- Stage 4: Volunteer Matcher ---
    volunteer_matcher = LlmAgent(
        name="VolunteerMatcher",
        model=ADK_MODEL_NAME,
        instruction="""You are a volunteer matching agent. For each prioritised need,
find the best available volunteer using the match_volunteer_to_need tool.

Consider proximity, skills, past performance, language compatibility,
and current workload. Create an assignment if a suitable match is found.""",
        tools=[FunctionTool(match_volunteer_to_need)],
    )

    # --- Sequential Pipeline ---
    pipeline = SequentialAgent(
        name="CommunityPulseAgentPipeline",
        sub_agents=[needs_classifier, dedup_agent, priority_ranker, volunteer_matcher],
    )

    logger.info(
        "Built CommunityPulse agent pipeline with model=%s and %d stages",
        ADK_MODEL_NAME,
        4,
    )
    return pipeline


# =============================================================================
# Mock Pipeline (for local dev without google-adk)
# =============================================================================

class _MockPipeline:
    """Lightweight mock that simulates the pipeline for local testing."""

    name = "CommunityPulseAgentPipeline (mock)"

    def run(self, submission: dict) -> dict:
        """Process a submission through mock stages."""
        logger.info("[MockPipeline] Processing submission: %s", submission.get("title", ""))

        # Stage 1: Classify
        classification = classify_need_from_text(
            text=submission.get("description", ""),
            media_urls=submission.get("media_urls"),
        )

        # Stage 2: Deduplicate
        dedup = check_duplicate_need(
            need_title=submission.get("title", ""),
            need_description=submission.get("description", ""),
            lat=submission.get("lat", 0.0),
            lng=submission.get("lng", 0.0),
        )

        # Stage 3: Priority
        priority = compute_priority_score(
            urgency_score=submission.get("urgency_score", 5),
            affected_population=submission.get("affected_population", 100),
            report_count=submission.get("report_count", 1),
            hours_since_submission=submission.get("hours_since_submission", 0.5),
        )

        # Stage 4: Match
        match_result = match_volunteer_to_need(
            need_id=submission.get("need_id", "mock-need-id"),
            need_category=classification["category"],
            lat=submission.get("lat", 0.0),
            lng=submission.get("lng", 0.0),
        )

        return {
            "classification": classification,
            "deduplication": dedup,
            "priority_index": priority,
            "volunteer_match": match_result,
        }


# =============================================================================
# Standalone entry point
# =============================================================================

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    pipeline = build_pipeline()

    test_submission = {
        "title": "Flood in Sehore district",
        "description": "Heavy flooding in Sehore after 3 days of rain. Multiple villages submerged. Around 500 families displaced. Need immediate shelter and food supplies.",
        "lat": 23.2042,
        "lng": 77.0867,
        "urgency_score": 8,
        "affected_population": 2500,
        "report_count": 3,
        "hours_since_submission": 2.0,
        "media_urls": [],
        "need_id": "test-need-001",
    }

    result = pipeline.run(test_submission)
    print(json.dumps(result, indent=2, default=str))
