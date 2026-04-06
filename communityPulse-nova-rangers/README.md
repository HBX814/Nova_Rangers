# CommunityPulse — Nova Rangers

> **Google Solution Challenge 2026**
> A data-driven volunteer coordination platform for social-impact NGOs in Madhya Pradesh, India.

---

## Repository Structure

```
communityPulse-nova-rangers/
├── backend/            # FastAPI Python application
│   ├── main.py         # App entrypoint, CORS, OpenTelemetry, APScheduler
│   ├── config.py       # Centralised environment-variable config
│   ├── routers/        # API route modules (submissions, volunteers, needs …)
│   ├── models/         # Pydantic v2 data models matching Firestore schema
│   └── services/       # Firestore client, scheduler jobs, helpers
├── agents/             # Google ADK multi-agent pipeline
│   └── pipeline.py     # SequentialAgent → NeedsClassifier → Dedup → PriorityRanker → VolunteerMatcher
├── frontend/           # Flutter application (mobile + web)
│   ├── lib/            # Dart source code
│   └── pubspec.yaml    # Flutter dependencies
├── dashboard/          # Apache Superset configuration
│   ├── superset_config.py
│   ├── docker-compose.yml
│   └── bigquery_schemas/
├── scripts/            # Utility scripts
│   ├── seed_firestore.py
│   ├── clear_firestore.py
│   └── generate_data.py
├── docker/             # Dockerfiles
│   ├── Dockerfile.backend
│   └── Dockerfile.agents
├── .github/workflows/  # CI/CD
│   └── deploy.yml      # Cloud Run deployment on push to main
├── docker-compose.yml  # Local development orchestration
├── .env.example        # All required environment variables
└── README.md
```

---

## Quick Start

### 1. Clone & configure

```bash
git clone https://github.com/your-org/communityPulse-nova-rangers.git
cd communityPulse-nova-rangers
cp .env.example .env
# Fill in every value in .env — see comments for where to obtain each credential
```

### 2. Backend (local)

```bash
cd backend
pip install uv          # if not already installed
uv sync                 # installs all deps from pyproject.toml
uv run uvicorn main:app --host 0.0.0.0 --port 8080 --reload
```

### 3. Agents service

```bash
cd agents
uv run python pipeline.py   # standalone test run
```

### 4. Flutter frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome       # web
flutter run                 # mobile emulator
```

### 5. Docker Compose (all services)

```bash
docker compose up --build
```

---

## Architecture Highlights

| Component | Technology |
|---|---|
| API | FastAPI + Pydantic v2 |
| Database | Google Cloud Firestore |
| AI Agents | Google ADK (gemini-2.5-flash) |
| Messaging | Google Cloud Pub/Sub |
| Analytics | BigQuery + Apache Superset |
| Caching | Upstash Redis |
| Email | Resend |
| Observability | OpenTelemetry → Google Cloud Trace |
| CI/CD | GitHub Actions → Cloud Run (asia-south1) |
| Frontend | Flutter (mobile + web) |

---

## Environment Variables

See [`.env.example`](.env.example) for the complete list with inline documentation on where to obtain each credential.

---

## Deployment

Push to `main` triggers the GitHub Actions workflow (`.github/workflows/deploy.yml`) which:

1. Authenticates with GCP via `GCP_SA_KEY` repository secret.
2. Builds the backend Docker image.
3. Deploys to Cloud Run in `asia-south1`.

---

## License

MIT — built with purpose for the communities of Madhya Pradesh.
