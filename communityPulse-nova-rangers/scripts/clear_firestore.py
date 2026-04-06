"""
Clear Firestore
===============
Deletes all documents from the main CommunityPulse collections.
Useful for resetting the database during development.

Usage:
    python scripts/clear_firestore.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from backend.services.firestore_client import get_firestore_client

COLLECTIONS = [
    "organizations",
    "volunteers",
    "needs",
    "assignments",
    "submissions",
]


def clear():
    """Delete all documents from CommunityPulse collections."""
    db = get_firestore_client()

    for collection_name in COLLECTIONS:
        print(f"Clearing '{collection_name}'...")
        docs = list(db.collection(collection_name).stream())
        count = 0
        for doc in docs:
            db.collection(collection_name).document(doc.id).delete()
            count += 1
        print(f"  Deleted {count} documents from '{collection_name}'")

    print("All collections cleared.")


if __name__ == "__main__":
    confirm = input(
        "This will DELETE ALL data from Firestore collections. "
        "Type 'yes' to confirm: "
    )
    if confirm.strip().lower() == "yes":
        clear()
    else:
        print("Aborted.")
