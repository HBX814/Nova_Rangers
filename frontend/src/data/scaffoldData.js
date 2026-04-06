export const FILE_TREE = [
  { name: "communityPulse-nova-rangers/", type: "folder", children: [
    { name: "backend/", type: "folder", children: [
      { name: "main.py", type: "file" },
      { name: "config.py", type: "file" },
      { name: "pyproject.toml", type: "file" },
      { name: "models/", type: "folder", children: [
        { name: "need.py", type: "file" },
        { name: "volunteer.py", type: "file" },
        { name: "organization.py", type: "file" },
        { name: "assignment.py", type: "file" },
        { name: "submission.py", type: "file" },
      ]},
      { name: "routers/", type: "folder", children: [
        { name: "submissions.py", type: "file" },
        { name: "volunteers.py", type: "file" },
        { name: "needs.py", type: "file" },
        { name: "organizations.py", type: "file" },
        { name: "analytics.py", type: "file" },
        { name: "auth.py", type: "file" },
      ]},
      { name: "services/", type: "folder", children: [
        { name: "firestore_client.py", type: "file" },
        { name: "scheduler_jobs.py", type: "file" },
      ]},
    ]},
    { name: "agents/", type: "folder", children: [
      { name: "pipeline.py", type: "file" },
    ]},
    { name: "frontend/", type: "folder", children: [
      { name: "lib/", type: "folder", children: [
        { name: "main.dart", type: "file" },
        { name: "screens/ (5 files)", type: "file" },
        { name: "services/api_service.dart", type: "file" },
        { name: "models/models.dart", type: "file" },
      ]},
      { name: "pubspec.yaml", type: "file" },
    ]},
    { name: "dashboard/", type: "folder", children: [
      { name: "superset_config.py", type: "file" },
      { name: "bigquery_schemas/ (3 files)", type: "file" },
    ]},
    { name: "scripts/", type: "folder", children: [
      { name: "seed_firestore.py", type: "file" },
      { name: "clear_firestore.py", type: "file" },
      { name: "generate_data.py", type: "file" },
    ]},
    { name: ".github/workflows/deploy.yml", type: "file" },
    { name: "docker/", type: "folder", children: [
      { name: "Dockerfile.backend", type: "file" },
      { name: "Dockerfile.agents", type: "file" },
    ]},
    { name: ".env.example", type: "file" },
    { name: "docker-compose.yml", type: "file" },
    { name: "README.md", type: "file" },
  ]},
];

export const TECH_STACK = [
  { name: "FastAPI", desc: "Python API framework", color: "#00C48C" },
  { name: "Flutter", desc: "Mobile + Web frontend", color: "#0047FF" },
  { name: "Google ADK", desc: "Multi-agent pipeline", color: "#FF3B30" },
  { name: "Firestore", desc: "NoSQL document store", color: "#FFD000" },
  { name: "BigQuery", desc: "Analytics warehouse", color: "#002FA7" },
  { name: "Superset", desc: "Dashboard & reporting", color: "#6B7280" },
  { name: "Cloud Run", desc: "Serverless deployment", color: "#00C48C" },
  { name: "Pub/Sub", desc: "Event messaging", color: "#0047FF" },
];

export const PIPELINE_STAGES = [
  { name: "NeedsClassifier", desc: "Classifies need category from text + media", tool: "classify_need_from_text" },
  { name: "DeduplicationAgent", desc: "Checks semantic similarity within 5km radius", tool: "check_duplicate_need" },
  { name: "PriorityRanker", desc: "Computes priority_index using weighted formula", tool: "compute_priority_score" },
  { name: "VolunteerMatcher", desc: "Matches best-fit volunteer by proximity & skills", tool: "match_volunteer_to_need" },
];

export const API_ROUTES = [
  { method: "POST", path: "/api/v1/submissions/", desc: "Submit a new need report" },
  { method: "GET", path: "/api/v1/submissions/", desc: "List recent submissions" },
  { method: "POST", path: "/api/v1/needs/", desc: "Create a new need" },
  { method: "GET", path: "/api/v1/needs/", desc: "List needs (filterable)" },
  { method: "PATCH", path: "/api/v1/needs/{id}", desc: "Update a need" },
  { method: "POST", path: "/api/v1/needs/{id}/resolve", desc: "Resolve a need" },
  { method: "GET", path: "/api/v1/needs/priority/top", desc: "Top priority needs" },
  { method: "POST", path: "/api/v1/volunteers/", desc: "Register volunteer" },
  { method: "GET", path: "/api/v1/volunteers/", desc: "List volunteers" },
  { method: "PATCH", path: "/api/v1/volunteers/{id}", desc: "Update volunteer" },
  { method: "GET", path: "/api/v1/volunteers/nearby/", desc: "Find nearby volunteers" },
  { method: "POST", path: "/api/v1/organizations/", desc: "Register organization" },
  { method: "GET", path: "/api/v1/organizations/", desc: "List organizations" },
  { method: "GET", path: "/api/v1/analytics/summary", desc: "Dashboard summary stats" },
  { method: "GET", path: "/api/v1/analytics/top-volunteers", desc: "Top performers" },
  { method: "GET", path: "/api/v1/analytics/district-heatmap", desc: "Geo heatmap data" },
  { method: "POST", path: "/api/v1/auth/token", desc: "Get auth token" },
  { method: "GET", path: "/api/v1/auth/me", desc: "Current user info" },
];

export const MODELS = [
  { name: "Need", fields: ["need_id: str", "need_category: enum", "title: str", "description: str", "urgency_score: int(1-10)", "affected_population: int", "primary_location_text: str", "lat: float", "lng: float", "priority_index: float", "status: enum", "report_count: int", "submitted_at: datetime", "org_id: str"] },
  { name: "Volunteer", fields: ["volunteer_id: str", "name: str", "phone: str", "skills: list[str]", "current_lat: float", "current_lng: float", "availability_status: enum", "performance_score: float", "tasks_completed: int", "fcm_token: str", "geohash: str", "languages: list[str]", "joined_date: date"] },
  { name: "Assignment", fields: ["assignment_id: str", "need_id: str", "volunteer_id: str", "status: enum", "assigned_at: datetime", "accepted_at: datetime?", "completed_at: datetime?", "ngo_satisfaction_rating: int?"] },
  { name: "Organization", fields: ["org_id: str", "name: str", "description: str", "contact_email: str", "district: str", "is_verified: bool", "created_at: datetime"] },
  { name: "SubmissionPayload", fields: ["submission_id: str", "submitted_by: str", "title: str", "description: str", "lat: float", "lng: float", "media_urls: list[str]", "submitted_at: datetime", "extracted_category: str?", "is_duplicate: bool?"] },
];

export const ENV_VARS = `# Google Cloud Platform
GCP_PROJECT_ID=your-gcp-project-id
GCP_REGION=asia-south1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json

# Firebase / Firestore
FIREBASE_CREDENTIALS_PATH=/path/to/firebase-sa.json
FIRESTORE_DATABASE_ID=(default)

# Gemini / ADK
GOOGLE_GENAI_API_KEY=your-gemini-api-key
ADK_MODEL_NAME=gemini-2.5-flash

# Pub/Sub & BigQuery
PUBSUB_TOPIC_NEW_NEED=new-need-created
BIGQUERY_DATASET=community_pulse_analytics

# Upstash Redis
UPSTASH_REDIS_URL=https://your-instance.upstash.io
UPSTASH_REDIS_TOKEN=your-token

# Resend (email)
RESEND_API_KEY=re_your_resend_api_key

# JWT Auth
JWT_SECRET_KEY=change-me

# Server
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8080`;

export const ENUMS = {
  NeedCategory: ["FLOOD","DROUGHT","MEDICAL","SHELTER","EDUCATION","FOOD","INFRASTRUCTURE","WATER"],
  NeedStatus: ["OPEN","IN_PROGRESS","RESOLVED"],
  AvailabilityStatus: ["AVAILABLE","BUSY","OFFLINE"],
  AssignmentStatus: ["PENDING","ACCEPTED","IN_PROGRESS","COMPLETED"],
};
