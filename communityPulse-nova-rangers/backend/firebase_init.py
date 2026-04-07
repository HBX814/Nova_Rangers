import os
import firebase_admin
from firebase_admin import credentials, firestore, auth, storage
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Check if Firebase is already initialized to avoid ValueError on re-initialization
try:
    firebase_admin.get_app()
except ValueError:
    # App is not initialized, so initialize it
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
    if not cred_path:
        raise RuntimeError("FIREBASE_CREDENTIALS_PATH environment variable not set")
    
    # If the path is relative, resolve it relative to the project root
    if not os.path.isabs(cred_path):
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        cred_path = os.path.join(project_root, cred_path)
    
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred, {
        'storageBucket': 'communitypulse-nova-rangers.appspot.com'
    })

# Export the requested clients
db = firestore.client()
# Note: authentication functions are available directly on the auth module
# bucket uses the specified storage bucket
bucket = storage.bucket('communitypulse-nova-rangers.appspot.com')
