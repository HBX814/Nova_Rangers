# CommunityPulse Nova Rangers — PRD

## Original Problem Statement
Build a complete monorepo scaffold for CommunityPulse, a data-driven volunteer coordination platform for social-impact NGOs in Madhya Pradesh, India, for the Google Solution Challenge 2026.

## Architecture
- **Backend**: FastAPI + Pydantic v2 + Firestore + Pub/Sub + BigQuery + APScheduler + OpenTelemetry
- **Agents**: Google ADK SequentialAgent with 4 LlmAgents (gemini-2.5-flash)
- **Frontend**: Flutter (mobile + web) with Riverpod, GoRouter, Dio
- **Dashboard**: Apache Superset + BigQuery
- **CI/CD**: GitHub Actions → Cloud Run (asia-south1)
- **Infra**: Docker, uv package manager

## User Personas
- **NGO Coordinators**: Create/manage needs, assign volunteers, view analytics
- **Volunteers**: Accept assignments, submit reports, update availability
- **Citizens**: Submit anonymous need reports with geo-location + media

## Core Requirements (Static)
1. Need management with 8 categories (FLOOD, DROUGHT, MEDICAL, SHELTER, EDUCATION, FOOD, INFRASTRUCTURE, WATER)
2. Volunteer registration with skills, location, availability tracking
3. AI-powered agent pipeline: classify → deduplicate → prioritize → match
4. Priority scoring: urgency*0.4 + log(pop)*0.3 + log(reports)*0.15 + time_decay*0.15
5. Scheduled jobs: daily volunteer score computation, weekly reports
6. Real-time notifications via FCM
7. Analytics dashboards via BigQuery + Superset

## What's Been Implemented (Feb 2026)
- [x] Complete monorepo scaffold (47 files) at `/app/communityPulse-nova-rangers/`
- [x] Backend: FastAPI app with CORS, OpenTelemetry, APScheduler, 6 routers, 5 Pydantic models
- [x] Agents: pipeline.py with SequentialAgent, 4 LlmAgents, tool functions, mock pipeline
- [x] Frontend: Flutter scaffold with 5 screens, API service, Dart models, GoRouter navigation
- [x] Dashboard: Superset config, BigQuery schemas (3 tables), docker-compose
- [x] Scripts: seed_firestore.py, clear_firestore.py, generate_data.py
- [x] CI/CD: deploy.yml for Cloud Run via GitHub Actions
- [x] Docker: Dockerfile.backend and Dockerfile.agents
- [x] .env.example with all 20+ environment variables documented
- [x] React preview dashboard showing full scaffold overview
- [x] Mock Firestore client for local development without GCP credentials

## Prioritized Backlog
### P0 (Critical for MVP)
- [ ] Connect real Firestore credentials and test CRUD operations
- [ ] Implement Firebase Auth integration (replace JWT placeholder)
- [ ] Set up Pub/Sub message flow between backend and agents service
- [ ] Deploy to Cloud Run and verify CI/CD pipeline

### P1 (Important)
- [ ] Implement ChromaDB vector store for deduplication agent
- [ ] Add FCM push notification service
- [ ] Build out Flutter screens with real API integration
- [ ] Set up BigQuery data sync from Firestore

### P2 (Nice to have)
- [ ] OCR processing for submitted images/PDFs (pytesseract + pdfplumber)
- [ ] Superset dashboard creation with pre-built charts
- [ ] Rate limiting via Upstash Redis
- [ ] Email digests via Resend

## Next Tasks
1. Drop in real Firebase/GCP credentials and test end-to-end
2. Run `uv sync` in backend/ and verify all dependencies install
3. Test Docker build locally
4. Push to GitHub and verify CI/CD workflow triggers
