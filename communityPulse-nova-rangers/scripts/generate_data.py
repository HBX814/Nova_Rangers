"""
Generate Synthetic Data
=======================
Creates large-volume synthetic data for load testing and analytics development.
Generates randomised needs, volunteers, and assignments based on realistic
Madhya Pradesh district data.

Usage:
    python scripts/generate_data.py --needs 500 --volunteers 100 --assignments 200
"""

import sys
import argparse
import random
import uuid
from datetime import datetime, date, timezone, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from backend.services.firestore_client import get_firestore_client

# ---------------------------------------------------------------------------
# Madhya Pradesh reference data
# ---------------------------------------------------------------------------

MP_DISTRICTS = [
    {"name": "Bhopal", "lat": 23.2599, "lng": 77.4126},
    {"name": "Indore", "lat": 22.7196, "lng": 75.8577},
    {"name": "Jabalpur", "lat": 23.1815, "lng": 79.9864},
    {"name": "Gwalior", "lat": 26.2183, "lng": 78.1828},
    {"name": "Ujjain", "lat": 23.1793, "lng": 75.7849},
    {"name": "Sagar", "lat": 23.8388, "lng": 78.7378},
    {"name": "Satna", "lat": 24.5803, "lng": 80.8322},
    {"name": "Rewa", "lat": 24.5373, "lng": 81.2985},
    {"name": "Chhindwara", "lat": 22.0574, "lng": 78.9382},
    {"name": "Mandla", "lat": 22.5975, "lng": 80.3619},
    {"name": "Sehore", "lat": 23.2042, "lng": 77.0867},
    {"name": "Chattarpur", "lat": 24.9166, "lng": 79.5900},
    {"name": "Hoshangabad", "lat": 22.7467, "lng": 77.7260},
    {"name": "Betul", "lat": 21.9050, "lng": 77.9000},
    {"name": "Shahdol", "lat": 23.2793, "lng": 81.3551},
]

CATEGORIES = ["FLOOD", "DROUGHT", "MEDICAL", "SHELTER", "EDUCATION", "FOOD", "INFRASTRUCTURE", "WATER"]
STATUSES_NEED = ["OPEN", "IN_PROGRESS", "RESOLVED"]
STATUSES_VOLUNTEER = ["AVAILABLE", "BUSY", "OFFLINE"]
STATUSES_ASSIGNMENT = ["PENDING", "ACCEPTED", "IN_PROGRESS", "COMPLETED"]

SKILLS_POOL = [
    "first_aid", "flood_rescue", "driving", "medical", "counseling",
    "construction", "plumbing", "electrical", "teaching", "nutrition",
    "community_outreach", "logistics", "food_distribution", "water_purification",
    "disaster_management", "hindi_translation", "communication", "data_entry",
]

LANGUAGES = ["Hindi", "English", "Urdu", "Marathi", "Bundeli", "Malvi", "Nimadi"]

FIRST_NAMES = [
    "Rajesh", "Priya", "Amit", "Sunita", "Mohammad", "Neha", "Deepak",
    "Kavita", "Rahul", "Lakshmi", "Suresh", "Anjali", "Vikram", "Rekha",
    "Arjun", "Meena", "Sanjay", "Pooja", "Mukesh", "Geeta",
]

LAST_NAMES = [
    "Sharma", "Patel", "Verma", "Thakur", "Khan", "Singh", "Yadav",
    "Jain", "Gupta", "Dubey", "Mishra", "Tiwari", "Chouhan", "Rajput",
]

NEED_TITLES = {
    "FLOOD": [
        "Flash flooding in {district} villages",
        "River overflow affecting {district} settlements",
        "Urban water-logging in {district} city",
    ],
    "DROUGHT": [
        "Severe water scarcity in {district}",
        "Bore wells dried up in {district} block",
        "Crop failure due to drought in {district}",
    ],
    "MEDICAL": [
        "Disease outbreak in {district} slums",
        "Medical supplies needed in {district}",
        "Mobile health clinic required for {district} rural areas",
    ],
    "SHELTER": [
        "Families displaced by storm in {district}",
        "Temporary shelter needed in {district}",
        "Housing damage from landslide in {district}",
    ],
    "EDUCATION": [
        "School damaged in {district}",
        "Learning materials needed in {district} tribal area",
        "Teachers required for {district} relief camp school",
    ],
    "FOOD": [
        "Food shortage in {district} tribal villages",
        "Emergency ration kits needed in {district}",
        "Mid-day meal disruption in {district} schools",
    ],
    "INFRASTRUCTURE": [
        "Road collapse in {district}",
        "Bridge damaged in {district} block",
        "Power lines down in {district} after storm",
    ],
    "WATER": [
        "Drinking water contamination in {district}",
        "Hand pump repair needed in {district}",
        "Water tanker supply required for {district}",
    ],
}


def _jitter(base: float, amount: float = 0.05) -> float:
    return base + random.uniform(-amount, amount)


def generate(num_needs: int, num_volunteers: int, num_assignments: int):
    """Generate synthetic data and persist to Firestore."""
    db = get_firestore_client()

    # --- Generate Volunteers ---
    print(f"Generating {num_volunteers} volunteers...")
    vol_ids = []
    for i in range(num_volunteers):
        district = random.choice(MP_DISTRICTS)
        vid = str(uuid.uuid4())
        vol_ids.append(vid)
        vol = {
            "volunteer_id": vid,
            "name": f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            "phone": f"+91-{random.randint(70000, 99999)}-{random.randint(10000, 99999)}",
            "skills": random.sample(SKILLS_POOL, k=random.randint(1, 4)),
            "current_lat": _jitter(district["lat"]),
            "current_lng": _jitter(district["lng"]),
            "availability_status": random.choice(STATUSES_VOLUNTEER),
            "performance_score": round(random.uniform(40, 100), 1),
            "tasks_completed": random.randint(0, 50),
            "fcm_token": "",
            "geohash": "",
            "languages": random.sample(LANGUAGES, k=random.randint(1, 3)),
            "joined_date": (date.today() - timedelta(days=random.randint(30, 365))).isoformat(),
        }
        db.collection("volunteers").document(vid).set(vol)

    # --- Generate Needs ---
    print(f"Generating {num_needs} needs...")
    need_ids = []
    org_ids = ["org-001", "org-002", "org-003"]
    for i in range(num_needs):
        district = random.choice(MP_DISTRICTS)
        category = random.choice(CATEGORIES)
        nid = str(uuid.uuid4())
        need_ids.append(nid)
        titles = NEED_TITLES.get(category, ["{district} needs help"])
        title = random.choice(titles).format(district=district["name"])
        need = {
            "need_id": nid,
            "need_category": category,
            "title": title,
            "description": f"Auto-generated need for testing. {title}. Affecting communities in {district['name']} district.",
            "urgency_score": random.randint(1, 10),
            "affected_population": random.randint(10, 20000),
            "primary_location_text": f"{district['name']}, Madhya Pradesh",
            "lat": _jitter(district["lat"]),
            "lng": _jitter(district["lng"]),
            "priority_index": 0.0,
            "status": random.choice(STATUSES_NEED),
            "report_count": random.randint(1, 20),
            "submitted_at": (datetime.now(timezone.utc) - timedelta(hours=random.randint(1, 720))).isoformat(),
            "org_id": random.choice(org_ids),
        }
        db.collection("needs").document(nid).set(need)

    # --- Generate Assignments ---
    print(f"Generating {num_assignments} assignments...")
    for i in range(min(num_assignments, len(need_ids), len(vol_ids))):
        aid = str(uuid.uuid4())
        status = random.choice(STATUSES_ASSIGNMENT)
        assigned_at = datetime.now(timezone.utc) - timedelta(hours=random.randint(1, 168))
        assign = {
            "assignment_id": aid,
            "need_id": need_ids[i % len(need_ids)],
            "volunteer_id": vol_ids[i % len(vol_ids)],
            "status": status,
            "assigned_at": assigned_at.isoformat(),
            "accepted_at": (assigned_at + timedelta(hours=1)).isoformat() if status != "PENDING" else None,
            "completed_at": (assigned_at + timedelta(hours=random.randint(4, 48))).isoformat() if status == "COMPLETED" else None,
            "ngo_satisfaction_rating": random.randint(3, 5) if status == "COMPLETED" else None,
        }
        db.collection("assignments").document(aid).set(assign)

    print(f"Done! Generated {num_volunteers} volunteers, {num_needs} needs, {min(num_assignments, len(need_ids), len(vol_ids))} assignments.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate synthetic CommunityPulse data")
    parser.add_argument("--needs", type=int, default=50, help="Number of needs to generate")
    parser.add_argument("--volunteers", type=int, default=20, help="Number of volunteers")
    parser.add_argument("--assignments", type=int, default=30, help="Number of assignments")
    args = parser.parse_args()
    generate(args.needs, args.volunteers, args.assignments)
