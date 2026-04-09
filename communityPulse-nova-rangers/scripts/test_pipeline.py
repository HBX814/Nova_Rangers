import os
from datetime import datetime
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

def main():
    # Load environment variables from .env file
    load_dotenv()

    # Get credentials path from environment variable
    cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
    if not cred_path:
        print("Error: FIREBASE_CREDENTIALS_PATH environment variable not set.")
        return

    # Initialize Firebase Admin SDK
    if not firebase_admin._apps:
        try:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        except Exception as e:
            print(f"Error initializing Firebase Admin SDK: {e}")
            return

    # Initialize Firestore client
    db = firestore.client()

    # Document data
    doc_data = {
        'submission_id': 'test-real-001',
        'org_id': 'org-001',
        'submitted_by': 'test-user',
        'file_type': 'image',
        'status': 'PENDING',
        'processed': True,
        'created_at': datetime.utcnow().isoformat(),
        'extracted_text': 'Emergency report from Harda district. Severe flooding in Timarni block. Three villages submerged after Tawa river overflow. Approximately 800 families displaced. Immediate need for rescue boats and food packets. Very urgent situation. Reported by Narmada Seva Samiti NGO field worker.'
    }

    # Create document in firestore
    try:
        db.collection('submission_queue').document('test-real-001').set(doc_data)
        print("Document created successfully.")
    except Exception as e:
        print(f"Error creating document: {e}")

if __name__ == "__main__":
    main()
