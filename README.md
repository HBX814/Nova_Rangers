<div align="center">
  <h1>Nova Rangers — CommunityPulse</h1>
  <p><strong>Google Solution Challenge 2026</strong></p>
  <p>A data-driven volunteer coordination platform for social-impact NGOs in Madhya Pradesh, India.</p>
</div>

---

## 🌟 Overview

**CommunityPulse** is an intelligent, scalable platform designed to bridge the gap between NGOs and volunteers. By leveraging modern cloud infrastructure and AI-driven matching, the platform ensures that community needs are addressed efficiently and volunteers are assigned to tasks where they can make the most impact.

---

## 🚀 Key Features

- **AI-Powered Matching**: Utilizes Google ADK (`gemini-2.5-flash`) to classify needs, remove duplicates, rank priorities, and match the best volunteers.
- **Cross-Platform Access**: A Flutter application providing seamless access across mobile (iOS/Android) and web.
- **Robust Backend**: Built with FastAPI and Pydantic v2 for high performance and strict data validation.
- **Real-Time Data**: Backed by Google Cloud Firestore for fast, real-time database syncing.
- **Automated Workflows**: Includes scheduled tasks (APScheduler) for computing volunteer scores and generating weekly reports.
- **Comprehensive Analytics**: Integrated with Apache Superset and BigQuery for deep insights into community needs and volunteer engagement.

---

## 🏗️ Architecture & Tech Stack

| Component | Technology |
|---|---|
| **API** | FastAPI + Pydantic v2 |
| **Database** | Google Cloud Firestore |
| **AI Agents** | Google ADK (`gemini-2.5-flash`) |
| **Messaging** | Google Cloud Pub/Sub |
| **Analytics** | BigQuery + Apache Superset |
| **Caching** | Upstash Redis |
| **Email** | Resend |
| **Observability** | OpenTelemetry → Google Cloud Trace |
| **CI/CD** | GitHub Actions → Cloud Run (asia-south1) |
| **Frontend** | Flutter (Mobile + Web) using Riverpod, GoRouter, Firebase Auth |

---

## 📂 Repository Structure

```text
Nova_Rangers/
└── communityPulse-nova-rangers/
    ├── backend/            # FastAPI Python application
    │   ├── main.py         # App entrypoint, CORS, OpenTelemetry, APScheduler
    │   ├── config.py       # Centralized environment-variable config
    │   ├── routers/        # API route modules (submissions, volunteers, needs)
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
    ├── scripts/            # Utility scripts (seed_firestore, clear_firestore, etc.)
    ├── docker/             # Dockerfiles
    │   ├── Dockerfile.backend
    │   └── Dockerfile.agents
    ├── .github/workflows/  # CI/CD pipelines
    │   └── deploy.yml      # Cloud Run deployment on push to main
    └── docker-compose.yml  # Local development orchestration
```

---

## 💻 Getting Started

### 1. Clone & Configure

```bash
git clone https://github.com/HBX814/Nova_Rangers.git
cd Nova_Rangers/communityPulse-nova-rangers
cp .env.example .env
# Fill in every value in .env — see comments for where to obtain each credential
```

### 2. Backend (Local Setup)

```bash
cd communityPulse-nova-rangers/backend
pip install uv          # Install UV if not already installed
uv sync                 # Installs all dependencies from pyproject.toml
uv run uvicorn main:app --host 0.0.0.0 --port 8080 --reload
```

### 3. AI Agents Service

```bash
cd communityPulse-nova-rangers/agents
uv run python pipeline.py   # Standalone test run for the agent pipeline
```

### 4. Flutter Frontend

```bash
cd communityPulse-nova-rangers/frontend
flutter pub get
flutter run -d chrome       # Run on Web
flutter run                 # Run on Mobile Emulator
```

### 5. Docker Compose (Run All Services)

```bash
cd communityPulse-nova-rangers
docker compose up --build
```

---

## 🚢 Deployment

Pushing to the `main` branch automatically triggers the GitHub Actions workflow (`.github/workflows/deploy.yml`), which performs the following:
1. Authenticates with GCP via the `GCP_SA_KEY` repository secret.
2. Builds the backend Docker image.
3. Deploys the service to Google Cloud Run in the `asia-south1` region.

---

## 📄 License

MIT License — Built with purpose for the communities of Madhya Pradesh.
