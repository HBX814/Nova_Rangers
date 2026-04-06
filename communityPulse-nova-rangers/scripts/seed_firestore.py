"""
Seed Firestore
==============
Populates Firestore with realistic sample data for development and testing.
Uses the mock Firestore client if no real credentials are available.

Usage:
    python scripts/seed_firestore.py
"""

import sys
import os
import uuid
from datetime import datetime, date, timezone, timedelta
from pathlib import Path

# Add the project root to the Python path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from backend.services.firestore_client import get_firestore_client


# ---------------------------------------------------------------------------
# Sample data for Madhya Pradesh
# ---------------------------------------------------------------------------

SAMPLE_ORGANIZATIONS = [
    {
        "org_id": "org-001",
        "name": "Madhya Pradesh Relief Foundation",
        "description": "Disaster response and relief coordination across MP",
        "contact_email": "admin@mprelief.org",
        "contact_phone": "+91-755-1234567",
        "address": "45, Arera Colony, Bhopal, MP 462016",
        "district": "Bhopal",
        "logo_url": "",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_verified": True,
    },
    {
        "org_id": "org-002",
        "name": "Narmada Seva Samiti",
        "description": "River basin community development and flood preparedness",
        "contact_email": "contact@narmadaseva.org",
        "contact_phone": "+91-733-9876543",
        "address": "12, Civil Lines, Jabalpur, MP 482001",
        "district": "Jabalpur",
        "logo_url": "",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_verified": True,
    },
    {
        "org_id": "org-003",
        "name": "Bundelkhand Drought Action Network",
        "description": "Drought mitigation and water conservation in Bundelkhand",
        "contact_email": "info@bdanmp.org",
        "contact_phone": "+91-761-5556789",
        "address": "8, Cantonment, Sagar, MP 470001",
        "district": "Sagar",
        "logo_url": "",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_verified": False,
    },
]

SAMPLE_VOLUNTEERS = [
    {
        "volunteer_id": "vol-001",
        "name": "Rajesh Kumar Sharma",
        "phone": "+91-98765-43210",
        "skills": ["first_aid", "flood_rescue", "driving"],
        "current_lat": 23.2599,
        "current_lng": 77.4126,
        "availability_status": "AVAILABLE",
        "performance_score": 82.5,
        "tasks_completed": 15,
        "fcm_token": "",
        "geohash": "teh8u5",
        "languages": ["Hindi", "English"],
        "joined_date": "2025-03-15",
    },
    {
        "volunteer_id": "vol-002",
        "name": "Priya Patel",
        "phone": "+91-98765-43211",
        "skills": ["medical", "counseling", "hindi_translation"],
        "current_lat": 23.1815,
        "current_lng": 79.9864,
        "availability_status": "AVAILABLE",
        "performance_score": 91.0,
        "tasks_completed": 28,
        "fcm_token": "",
        "geohash": "teh3mk",
        "languages": ["Hindi", "English", "Marathi"],
        "joined_date": "2024-11-20",
    },
    {
        "volunteer_id": "vol-003",
        "name": "Amit Verma",
        "phone": "+91-98765-43212",
        "skills": ["construction", "plumbing", "electrical"],
        "current_lat": 22.7196,
        "current_lng": 75.8577,
        "availability_status": "BUSY",
        "performance_score": 75.0,
        "tasks_completed": 10,
        "fcm_token": "",
        "geohash": "tesb9v",
        "languages": ["Hindi"],
        "joined_date": "2025-06-01",
    },
    {
        "volunteer_id": "vol-004",
        "name": "Sunita Devi Thakur",
        "phone": "+91-98765-43213",
        "skills": ["teaching", "nutrition", "community_outreach"],
        "current_lat": 23.8388,
        "current_lng": 78.7378,
        "availability_status": "AVAILABLE",
        "performance_score": 88.0,
        "tasks_completed": 22,
        "fcm_token": "",
        "geohash": "tehfq2",
        "languages": ["Hindi", "Bundeli"],
        "joined_date": "2025-01-10",
    },
    {
        "volunteer_id": "vol-005",
        "name": "Mohammad Irfan",
        "phone": "+91-98765-43214",
        "skills": ["logistics", "driving", "food_distribution"],
        "current_lat": 23.5120,
        "current_lng": 80.3310,
        "availability_status": "OFFLINE",
        "performance_score": 68.5,
        "tasks_completed": 7,
        "fcm_token": "",
        "geohash": "tehck8",
        "languages": ["Hindi", "Urdu", "English"],
        "joined_date": "2025-08-22",
    },
]

SAMPLE_NEEDS = [
    {
        "need_id": "need-001",
        "need_category": "FLOOD",
        "title": "Severe flooding in Sehore villages",
        "description": "Three villages in Sehore district have been submerged after 72 hours of continuous rain. Approximately 500 families displaced. Immediate need for rescue boats, food packets, and temporary shelters.",
        "urgency_score": 9,
        "affected_population": 2500,
        "primary_location_text": "Sehore, Madhya Pradesh",
        "lat": 23.2042,
        "lng": 77.0867,
        "priority_index": 0.0,
        "status": "OPEN",
        "report_count": 5,
        "submitted_at": (datetime.now(timezone.utc) - timedelta(hours=6)).isoformat(),
        "org_id": "org-001",
    },
    {
        "need_id": "need-002",
        "need_category": "DROUGHT",
        "title": "Water crisis in Chattarpur",
        "description": "Prolonged drought in Chattarpur district. Bore wells have dried up in 12 villages. Cattle dying. Urgent need for water tankers and bore well repair teams.",
        "urgency_score": 8,
        "affected_population": 8000,
        "primary_location_text": "Chattarpur, Madhya Pradesh",
        "lat": 24.9166,
        "lng": 79.5900,
        "priority_index": 0.0,
        "status": "IN_PROGRESS",
        "report_count": 12,
        "submitted_at": (datetime.now(timezone.utc) - timedelta(days=3)).isoformat(),
        "org_id": "org-003",
    },
    {
        "need_id": "need-003",
        "need_category": "MEDICAL",
        "title": "Dengue outbreak in Gwalior slums",
        "description": "Rising dengue cases in Hazira and Thatipur slums. Over 200 confirmed cases. Need fumigation drives, mosquito nets, and mobile health clinics.",
        "urgency_score": 7,
        "affected_population": 15000,
        "primary_location_text": "Gwalior, Madhya Pradesh",
        "lat": 26.2183,
        "lng": 78.1828,
        "priority_index": 0.0,
        "status": "OPEN",
        "report_count": 8,
        "submitted_at": (datetime.now(timezone.utc) - timedelta(days=1)).isoformat(),
        "org_id": "org-001",
    },
    {
        "need_id": "need-004",
        "need_category": "EDUCATION",
        "title": "School destroyed by landslide in Chhindwara",
        "description": "Primary school in Tamia block collapsed after a landslide. 180 students need temporary learning spaces. Teachers available but no materials or shelter.",
        "urgency_score": 6,
        "affected_population": 180,
        "primary_location_text": "Chhindwara, Madhya Pradesh",
        "lat": 22.0574,
        "lng": 78.9382,
        "priority_index": 0.0,
        "status": "OPEN",
        "report_count": 2,
        "submitted_at": (datetime.now(timezone.utc) - timedelta(days=5)).isoformat(),
        "org_id": "org-002",
    },
    {
        "need_id": "need-005",
        "need_category": "FOOD",
        "title": "Food shortage in tribal areas of Mandla",
        "description": "Tribal communities in Mandla district facing acute food shortage after crop failure. PDS supply irregular. 350 families need emergency ration kits.",
        "urgency_score": 8,
        "affected_population": 1750,
        "primary_location_text": "Mandla, Madhya Pradesh",
        "lat": 22.5975,
        "lng": 80.3619,
        "priority_index": 0.0,
        "status": "OPEN",
        "report_count": 6,
        "submitted_at": (datetime.now(timezone.utc) - timedelta(hours=18)).isoformat(),
        "org_id": "org-002",
    },
]

SAMPLE_ASSIGNMENTS = [
    {
        "assignment_id": "assign-001",
        "need_id": "need-002",
        "volunteer_id": "vol-003",
        "status": "IN_PROGRESS",
        "assigned_at": (datetime.now(timezone.utc) - timedelta(days=2)).isoformat(),
        "accepted_at": (datetime.now(timezone.utc) - timedelta(days=2, hours=-1)).isoformat(),
        "completed_at": None,
        "ngo_satisfaction_rating": None,
    },
    {
        "assignment_id": "assign-002",
        "need_id": "need-001",
        "volunteer_id": "vol-001",
        "status": "ACCEPTED",
        "assigned_at": (datetime.now(timezone.utc) - timedelta(hours=4)).isoformat(),
        "accepted_at": (datetime.now(timezone.utc) - timedelta(hours=3)).isoformat(),
        "completed_at": None,
        "ngo_satisfaction_rating": None,
    },
]


def seed():
    """Seed Firestore (or mock) with sample data."""
    db = get_firestore_client()

    print("Seeding organisations...")
    for org in SAMPLE_ORGANIZATIONS:
        db.collection("organizations").document(org["org_id"]).set(org)

    print("Seeding volunteers...")
    for vol in SAMPLE_VOLUNTEERS:
        db.collection("volunteers").document(vol["volunteer_id"]).set(vol)

    print("Seeding needs...")
    for need in SAMPLE_NEEDS:
        db.collection("needs").document(need["need_id"]).set(need)

    print("Seeding assignments...")
    for assign in SAMPLE_ASSIGNMENTS:
        db.collection("assignments").document(assign["assignment_id"]).set(assign)

    print(
        f"Done! Seeded {len(SAMPLE_ORGANIZATIONS)} orgs, "
        f"{len(SAMPLE_VOLUNTEERS)} volunteers, "
        f"{len(SAMPLE_NEEDS)} needs, "
        f"{len(SAMPLE_ASSIGNMENTS)} assignments."
    )


if __name__ == "__main__":
    seed()
