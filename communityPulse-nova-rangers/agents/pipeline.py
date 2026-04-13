import os
import json
import math
import re
import uuid
from datetime import datetime

from google.genai import types
from google.adk.agents import LlmAgent, SequentialAgent
from google.adk.apps import App
from google.adk.runners import InMemoryRunner

from backend.firebase_init import db
from backend.services.vector_store import add_need, search_similar
from backend.services.embedding_service import embed_text
from backend.services.priority_ranker import compute_priority_score, get_nearby_unresolved_count

class SubmissionNotFoundError(ValueError):
    """Raised when submission_queue document is missing."""


class SubmissionOrgMismatchError(PermissionError):
    """Raised when request org_id does not match submission org_id."""


class PipelineInvariantError(RuntimeError):
    """Raised when pipeline cannot produce required linked entities."""


DISTRICT_COORDS = {
    "harda": ("Harda, Madhya Pradesh", 22.33, 77.08),
    "dewas": ("Dewas, Madhya Pradesh", 22.96, 76.05),
    "barwani": ("Barwani, Madhya Pradesh", 22.03, 74.90),
    "betul": ("Betul, Madhya Pradesh", 21.90, 77.90),
    "mandla": ("Mandla, Madhya Pradesh", 22.60, 80.37),
    "bhopal": ("Bhopal, Madhya Pradesh", 23.26, 77.41),
    "indore": ("Indore, Madhya Pradesh", 22.72, 75.86),
    "jabalpur": ("Jabalpur, Madhya Pradesh", 23.18, 79.99),
    "gwalior": ("Gwalior, Madhya Pradesh", 26.22, 78.18),
}

CATEGORY_KEYWORDS = {
    "FLOOD": ["flood", "flash flood", "barish", "water logging", "submerged", "overflow"],
    "DROUGHT": ["drought", "water crisis", "dry", "no rain"],
    "MEDICAL": ["medical", "hospital", "ambulance", "health", "dengue", "fever", "injury"],
    "SHELTER": ["shelter", "temporary shelter", "camp", "housing", "relief camp"],
    "EDUCATION": ["school", "students", "education", "classroom", "teacher"],
    "FOOD": ["food", "ration", "meal", "packets", "nutrition", "dry food"],
    "INFRASTRUCTURE": ["road", "bridge", "electricity", "power", "infrastructure"],
    "WATER": ["drinking water", "clean water", "water supply", "water tanker"],
}

def read_submission_text(submission_id: str) -> str:
    """Reads submission_queue Firestore document and returns extracted_text."""
    doc = db.collection('submission_queue').document(submission_id).get()
    if doc.exists:
        return doc.to_dict().get('extracted_text', '')
    return ""

def _infer_location(text: str) -> tuple[str, float, float]:
    lower = text.lower()
    for district, value in DISTRICT_COORDS.items():
        if district in lower:
            return value
    return ("Madhya Pradesh", 23.26, 77.41)

def _infer_category(text: str) -> str:
    lower = text.lower()
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in lower for keyword in keywords):
            return category
    return "INFRASTRUCTURE"

def _infer_affected_population(text: str) -> int:
    numbers = [int(v) for v in re.findall(r"\b\d{2,6}\b", text)]
    if not numbers:
        return 100
    return max(50, min(max(numbers), 100000))

def _create_need_from_submission_text(submission_id: str, org_id: str, extracted_text: str) -> str:
    location, lat, lng = _infer_location(extracted_text)
    category = _infer_category(extracted_text)
    affected_population = _infer_affected_population(extracted_text)
    title = f"{category.title()} emergency in {location.split(',')[0]}"
    title = title[:60]
    description = extracted_text.strip()
    if len(description) > 500:
        description = description[:500].rstrip() + "..."
    return write_need_record(
        submission_id=submission_id,
        need_category=category,
        title=title,
        description=description,
        urgency_score=8,
        affected_population=affected_population,
        primary_location_text=location,
        lat=lat,
        lng=lng,
        org_id=org_id,
    )

def write_need_record(submission_id: str, need_category: str, title: str, 
                      description: str, urgency_score: int, affected_population: int, 
                      primary_location_text: str, lat: float, lng: float, org_id: str) -> str:
    """Generates a new need and stores it in the Firestore needs collection."""
    need_id = "need_" + str(uuid.uuid4()).replace("-", "")[:8]
    
    need_data = {
        'submission_id': submission_id,
        'need_category': need_category,
        'title': title,
        'description': description,
        'urgency_score': urgency_score,
        'affected_population': affected_population,
        'primary_location_text': primary_location_text,
        'lat': lat,
        'lng': lng,
        # Backward compatibility for services that still read legacy keys.
        'latitude': lat,
        'longitude': lng,
        'org_id': org_id,
        'status': 'OPEN',
        'priority_index': 0.0,
        'report_count': 1,
        'submitted_at': datetime.utcnow().isoformat()
    }
    
    db.collection('needs').document(need_id).set(need_data)
    return need_id

def check_duplicate(need_id: str, title: str, description: str) -> dict:
    """Checks for existing similar needs via vector search."""
    search_text = f"{title} {description}"
    results = search_similar(search_text)
    
    is_duplicate = False
    existing_need_id = None
    similarity_score = 1.0
    
    for r in results:
        # Lower distance means higher similarity
        if r.get('distance', 1.0) < 0.15:
            is_duplicate = True
            existing_need_id = r.get('need_id')
            similarity_score = r.get('distance')
            break
            
    return {
        "is_duplicate": is_duplicate,
        "existing_need_id": existing_need_id,
        "similarity_score": similarity_score
    }

def add_need_to_vector_store(need_id: str, title: str, description: str) -> str:
    """Adds combined title and description text exactly mapped to the provided need_id."""
    add_need(need_id, f"{title} {description}")
    return "added"

def increment_report_count(need_id: str) -> str:
    """Increments the report_count inside the Firestore needs document."""
    ref = db.collection('needs').document(need_id)
    doc = ref.get()
    if doc.exists:
        current_count = doc.to_dict().get('report_count', 0)
        ref.update({'report_count': current_count + 1})
    return "incremented"

def rank_need(need_id: str) -> float:
    """Calculates the priority score using ranker service routines and applies it."""
    ref = db.collection('needs').document(need_id)
    doc = ref.get()
    if doc.exists:
        data = doc.to_dict()
        lat = data.get('lat', data.get('latitude', 0.0))
        lng = data.get('lng', data.get('longitude', 0.0))
        urgency = data.get('urgency_score', 0)
        reports = data.get('report_count', 1)
        population = data.get('affected_population', 0)
        
        nearby_count = get_nearby_unresolved_count(lat, lng, db)
        score = compute_priority_score(urgency, reports, population, nearby_count)
        
        ref.update({'priority_index': score})
        return score
    return 0.0

def query_available_volunteers(lat: float, lng: float, need_category: str) -> list:
    """Queries AVAILABLE volunteers near the need; falls back to any available volunteer."""
    vol_ref = db.collection('volunteers').where('availability_status', '==', 'AVAILABLE').stream()
    nearby_candidates = []
    all_available_candidates = []
    
    for v in vol_ref:
        data = v.to_dict()
        v_lat = data.get('current_lat')
        v_lng = data.get('current_lng')
        candidate = {
            'volunteer_id': v.id,
            'name': data.get('name', ''),
            'skills': data.get('skills', []),
            'performance_score': data.get('performance_score', 0.0),
            'current_lat': v_lat,
            'current_lng': v_lng
        }
        all_available_candidates.append(candidate)
        
        if v_lat is not None and v_lng is not None:
            # ~2.5 degrees keeps matching practical across districts.
            if abs(v_lat - lat) <= 2.5 and abs(v_lng - lng) <= 2.5:
                nearby_candidates.append(candidate)

    candidates = nearby_candidates if nearby_candidates else all_available_candidates
    candidates.sort(key=lambda x: x.get('performance_score', 0.0), reverse=True)
    return candidates[:5]

def create_assignment(need_id: str, volunteer_id: str) -> str:
    """Dispatches the record to the assignments collection and marks volunteer BUSY."""
    assignment_id = "assgn_" + str(uuid.uuid4()).replace("-", "")[:8]
    
    db.collection('assignments').document(assignment_id).set({
        'need_id': need_id,
        'volunteer_id': volunteer_id,
        'status': 'PENDING',
        'assigned_at': datetime.utcnow().isoformat(),
        'accepted_at': None,
        'completed_at': None,
        'ngo_satisfaction_rating': None
    })
    
    db.collection('volunteers').document(volunteer_id).update({
        'availability_status': 'BUSY'
    })
    
    return assignment_id

def _get_existing_active_assignment_id(need_id: str) -> str | None:
    assignments = db.collection('assignments').where('need_id', '==', need_id).stream()
    for assignment in assignments:
        data = assignment.to_dict() or {}
        status = str(data.get('status', '')).upper()
        if status in {"PENDING", "ACCEPTED"}:
            return assignment.id
    return None

def _skills_for_category(need_category: str) -> set[str]:
    mapping = {
        "FLOOD": {"flood_rescue", "logistics"},
        "MEDICAL": {"medical", "first_aid"},
        "FOOD": {"food_distribution", "logistics"},
        "DROUGHT": {"water_purification", "logistics"},
        "EDUCATION": {"teaching"},
        "SHELTER": {"construction"},
    }
    return mapping.get((need_category or "").upper(), set())

def _pick_best_candidate(candidates: list, need_category: str) -> dict | None:
    if not candidates:
        return None

    required_skills = _skills_for_category(need_category)
    best_match = None
    best_fallback = None

    for candidate in candidates:
        skills = {
            str(skill).strip().lower()
            for skill in (candidate.get("skills") or [])
            if str(skill).strip()
        }
        if required_skills:
            has_skill_match = bool(skills.intersection(required_skills))
            if has_skill_match:
                if best_match is None or candidate.get("performance_score", 0.0) > best_match.get("performance_score", 0.0):
                    best_match = candidate
            elif best_fallback is None or candidate.get("performance_score", 0.0) > best_fallback.get("performance_score", 0.0):
                best_fallback = candidate
        else:
            if best_fallback is None or candidate.get("performance_score", 0.0) > best_fallback.get("performance_score", 0.0):
                best_fallback = candidate

    return best_match or best_fallback

classifier_agent = LlmAgent(
    name="NeedsClassifier",
    model="gemini-2.5-flash",
    tools=[read_submission_text, write_need_record],
    instruction="You are a needs classification agent for CommunityPulse in Madhya Pradesh India. Given a submission_id, read the extracted text and classify the community need. Extract: need_category (one of FLOOD DROUGHT MEDICAL SHELTER EDUCATION FOOD INFRASTRUCTURE WATER), title (max 60 chars English), description (2-3 sentences), urgency_score (1-10), affected_population (estimate from text), primary_location_text (most specific location mentioned), lat and lng (estimate coordinates for the MP location mentioned, MP is 21-26N 74-82E), org_id (pass through from context). Call write_need_record with all extracted fields and return the new need_id. IMPORTANT: You must always provide lat and lng coordinates. Madhya Pradesh coordinates range from 21.0 to 26.8 latitude and 74.0 to 82.8 longitude. If the location is Harda district use lat 22.33 lng 77.08. If Dewas use lat 22.96 lng 76.05. If Barwani use lat 22.03 lng 74.90. If Betul use lat 21.90 lng 77.90. If Mandla use lat 22.60 lng 80.37. If Bhopal use lat 23.26 lng 77.41. If Indore use lat 22.72 lng 75.86. If Jabalpur use lat 23.18 lng 79.99. If Gwalior use lat 26.22 lng 78.18. Never return null for lat or lng — always estimate based on the MP district mentioned."
)

dedup_agent = LlmAgent(
    name="DeduplicationAgent",
    model="gemini-2.5-flash",
    tools=[check_duplicate, add_need_to_vector_store, increment_report_count],
    instruction="You are a deduplication agent. Given a need_id, title, and description, call check_duplicate. If is_duplicate is True, call increment_report_count on the existing_need_id and return DUPLICATE plus the existing need_id. If not duplicate, call add_need_to_vector_store and return NEW plus the need_id."
)

ranker_agent = LlmAgent(
    name="PriorityRanker",
    model="gemini-2.5-flash",
    tools=[rank_need],
    instruction="You are a priority ranking agent. Given a need_id, call rank_need and return the priority score."
)

matcher_agent = LlmAgent(
    name="VolunteerMatcher",
    model="gemini-2.5-flash",
    tools=[query_available_volunteers, create_assignment],
    instruction="You are a volunteer matching agent. Given a need_id, lat, lng, and need_category, call query_available_volunteers. Select the volunteer with the highest performance_score whose skills best match the need_category using this mapping: FLOOD needs flood_rescue or logistics, MEDICAL needs medical or first_aid, FOOD needs food_distribution or logistics, DROUGHT needs water_purification or logistics, EDUCATION needs teaching, SHELTER needs construction, all others accept any skill. Call create_assignment with the need_id and best volunteer_id. Return the assignment_id."
)

pipeline = SequentialAgent(
    name="NeedProcessingPipeline",
    sub_agents=[classifier_agent, dedup_agent, ranker_agent, matcher_agent]
)

pipeline_app = App(name="CommunityPulseApp", root_agent=pipeline)
runner = InMemoryRunner(app=pipeline_app)

async def run_single_agent(agent, user_id: str, session_id: str, input_str: str) -> str:
    app = App(name=agent.name + "App", root_agent=agent)
    agent_runner = InMemoryRunner(app=app)
    await agent_runner.session_service.create_session(user_id=user_id, session_id=session_id, app_name=app.name)
    
    new_msg = types.Content(parts=[types.Part.from_text(text=input_str)])
    events = agent_runner.run(user_id=user_id, session_id=session_id, new_message=new_msg)
    
    responses = []
    for e in events:
        if getattr(e, 'type', None) == 'agent_response':
            try:
                responses.append(e.agent_response.message.parts[0].text)
            except Exception:
                pass
    return "\n".join(responses)

async def run_pipeline(submission_id: str, org_id: str | None) -> dict:
    session_id = f"sess_{uuid.uuid4().hex[:8]}"
    submission_ref = db.collection('submission_queue').document(submission_id)
    submission_doc = submission_ref.get()
    if not submission_doc.exists:
        raise SubmissionNotFoundError(f"Submission not found: {submission_id}")

    submission_data = submission_doc.to_dict() or {}
    stored_org_id = str(submission_data.get("org_id", "")).strip()
    requested_org_id = str(org_id).strip() if org_id is not None else ""
    if not stored_org_id:
        raise PipelineInvariantError(f"Submission {submission_id} is missing org_id.")
    if requested_org_id and requested_org_id != stored_org_id:
        raise SubmissionOrgMismatchError(
            f"org_id mismatch for submission {submission_id}: requested {requested_org_id}, actual {stored_org_id}"
        )
    org_id = stored_org_id

    submission_ref.update({
        "status": "PROCESSING",
        "processed": False,
        "processing_started_at": datetime.utcnow().isoformat(),
    })

    try:
        classifier_input = f"Process this submission. submission_id: {submission_id} org_id: {org_id} Read the extracted_text from Firestore submission_queue collection for this submission_id and classify the need."
        classifier_result = await run_single_agent(classifier_agent, org_id, session_id, classifier_input)

        needs_ref = db.collection('needs').where('submission_id', '==', submission_id).stream()
        need_id = None
        lat = 0.0
        lng = 0.0
        need_category = ""
        title = ""
        description = ""
        latest_submitted_at = ""

        for need in needs_ref:
            data = need.to_dict()
            if not data:
                continue
            if str(data.get("org_id", "")).strip() != org_id:
                continue

            submitted_at = str(data.get('submitted_at', ''))
            if need_id is None or submitted_at >= latest_submitted_at:
                need_id = need.id
                latest_submitted_at = submitted_at
                lat = data.get('lat', data.get('latitude', 0.0))
                lng = data.get('lng', data.get('longitude', 0.0))
                need_category = data.get('need_category', '')
                title = data.get('title', '')
                description = data.get('description', '')

        # Some model replies include "need_<id>" in plain text; use it as a fallback.
        if not need_id:
            match = re.search(r"\b(need_[a-zA-Z0-9]+)\b", classifier_result or "")
            if match:
                candidate_need_id = match.group(1)
                candidate_doc = db.collection('needs').document(candidate_need_id).get()
                if candidate_doc.exists:
                    data = candidate_doc.to_dict() or {}
                    if data.get('submission_id') == submission_id and str(data.get("org_id", "")).strip() == org_id:
                        need_id = candidate_need_id
                        lat = data.get('lat', data.get('latitude', 0.0))
                        lng = data.get('lng', data.get('longitude', 0.0))
                        need_category = data.get('need_category', '')
                        title = data.get('title', '')
                        description = data.get('description', '')

        # Deterministic fallback: if classifier path produced no linked need, create one
        # from extracted_text so the pipeline can continue.
        if not need_id:
            extracted_text = (submission_data or {}).get('extracted_text', '')
            if isinstance(extracted_text, str) and extracted_text.strip():
                generated_need_id = _create_need_from_submission_text(
                    submission_id=submission_id,
                    org_id=org_id,
                    extracted_text=extracted_text,
                )
                generated_doc = db.collection('needs').document(generated_need_id).get()
                if generated_doc.exists:
                    data = generated_doc.to_dict() or {}
                    need_id = generated_need_id
                    lat = data.get('lat', data.get('latitude', 0.0))
                    lng = data.get('lng', data.get('longitude', 0.0))
                    need_category = data.get('need_category', '')
                    title = data.get('title', '')
                    description = data.get('description', '')

        if not need_id:
            raise PipelineInvariantError(
                "Need not found for this submission_id. Classifier did not create a linked need record."
            )

        dedup_input = f"Check for duplicates. need_id: {need_id} title: {title} description: {description}"
        await run_single_agent(dedup_agent, org_id, session_id, dedup_input)

        ranker_input = f"Rank this need. need_id: {need_id}"
        await run_single_agent(ranker_agent, org_id, session_id, ranker_input)

        matcher_input = f"Match a volunteer. need_id: {need_id} lat: {lat} lng: {lng} need_category: {need_category}"
        matcher_result = await run_single_agent(matcher_agent, org_id, session_id, matcher_input)
        assignment_id = None

        assignment_match = re.search(r"\b(assgn_[a-zA-Z0-9]+)\b", matcher_result or "")
        if assignment_match:
            assignment_id = assignment_match.group(1)
        else:
            assignment_id = _get_existing_active_assignment_id(need_id)
        if not assignment_id:
            candidates = query_available_volunteers(lat, lng, need_category)
            selected_candidate = _pick_best_candidate(candidates, need_category)
            if selected_candidate:
                assignment_id = create_assignment(need_id, selected_candidate["volunteer_id"])
                matcher_result = (
                    (matcher_result or "").strip() + f"\nfallback_assignment_created:{assignment_id}"
                ).strip()
            else:
                matcher_result = (
                    (matcher_result or "").strip() + "\nno_available_volunteers"
                ).strip()
        elif not (matcher_result or "").strip():
            matcher_result = "matcher_no_text_output_used_existing_assignment"

        if not (classifier_result or "").strip():
            classifier_result = "classifier_no_text_output_used_firestore_need_record"

        submission_ref.update({
            "status": "COMPLETED",
            "processed": True,
            "processed_at": datetime.utcnow().isoformat(),
            "need_id": need_id,
            "assignment_id": assignment_id,
            "processing_error": None,
        })

        return {
            "submission_id": submission_id,
            "status": "completed",
            "need_id": need_id,
            "assignment_id": assignment_id,
            "classifier_result": classifier_result,
            "matcher_result": matcher_result
        }
    except Exception as exc:
        submission_ref.update({
            "status": "FAILED",
            "processed": False,
            "processed_at": datetime.utcnow().isoformat(),
            "processing_error": str(exc),
        })
        raise
