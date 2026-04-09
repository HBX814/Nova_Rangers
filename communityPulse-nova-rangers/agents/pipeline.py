import os
import json
import math
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

def read_submission_text(submission_id: str) -> str:
    """Reads submission_queue Firestore document and returns extracted_text."""
    doc = db.collection('submission_queue').document(submission_id).get()
    if doc.exists:
        return doc.to_dict().get('extracted_text', '')
    return ""

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
        lat = data.get('latitude', 0.0)
        lng = data.get('longitude', 0.0)
        urgency = data.get('urgency_score', 0)
        reports = data.get('report_count', 1)
        population = data.get('affected_population', 0)
        
        nearby_count = get_nearby_unresolved_count(lat, lng, db)
        score = compute_priority_score(urgency, reports, population, nearby_count)
        
        ref.update({'priority_index': score})
        return score
    return 0.0

def query_available_volunteers(lat: float, lng: float, need_category: str) -> list:
    """Queries for AVAILABLE volunteers within roughly 0.5 degrees and returns top 5."""
    vol_ref = db.collection('volunteers').where('availability_status', '==', 'AVAILABLE').stream()
    candidates = []
    
    for v in vol_ref:
        data = v.to_dict()
        v_lat = data.get('current_lat')
        v_lng = data.get('current_lng')
        
        if v_lat is not None and v_lng is not None:
            if abs(v_lat - lat) <= 0.5 and abs(v_lng - lng) <= 0.5:
                candidates.append({
                    'volunteer_id': v.id,
                    'name': data.get('name', ''),
                    'skills': data.get('skills', []),
                    'performance_score': data.get('performance_score', 0.0),
                    'current_lat': v_lat,
                    'current_lng': v_lng
                })
                
    # Sort descending by score
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

classifier_agent = LlmAgent(
    name="NeedsClassifier",
    model="gemini-2.5-flash",
    tools=[read_submission_text, write_need_record],
    instruction="You are a needs classification agent for CommunityPulse in Madhya Pradesh India. Given a submission_id, read the extracted text and classify the community need. Extract: need_category (one of FLOOD DROUGHT MEDICAL SHELTER EDUCATION FOOD INFRASTRUCTURE WATER), title (max 60 chars English), description (2-3 sentences), urgency_score (1-10), affected_population (estimate from text), primary_location_text (most specific location mentioned), lat and lng (estimate coordinates for the MP location mentioned, MP is 21-26N 74-82E), org_id (pass through from context). Call write_need_record with all extracted fields and return the new need_id."
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

async def run_pipeline(submission_id: str, org_id: str) -> dict:
    session_id = f"sess_{uuid.uuid4().hex[:8]}"
    
    classifier_input = f"Process this submission. submission_id: {submission_id} org_id: {org_id} Read the extracted_text from Firestore submission_queue collection for this submission_id and classify the need."
    classifier_result = await run_single_agent(classifier_agent, org_id, session_id, classifier_input)
    
    needs_ref = db.collection('needs').order_by('submitted_at', direction='DESCENDING').limit(1).stream()
    need_id = None
    lat = 0.0
    lng = 0.0
    need_category = ""
    title = ""
    description = ""
    
    for need in needs_ref:
        need_id = need.id
        data = need.to_dict()
        lat = data.get('latitude', 0.0)
        lng = data.get('longitude', 0.0)
        need_category = data.get('need_category', '')
        title = data.get('title', '')
        description = data.get('description', '')
        break
        
    if not need_id:
        return {"submission_id": submission_id, "status": "failed", "error": "Need not found"}

    dedup_input = f"Check for duplicates. need_id: {need_id} title: {title} description: {description}"
    await run_single_agent(dedup_agent, org_id, session_id, dedup_input)
    
    ranker_input = f"Rank this need. need_id: {need_id}"
    await run_single_agent(ranker_agent, org_id, session_id, ranker_input)
    
    matcher_input = f"Match a volunteer. need_id: {need_id} lat: {lat} lng: {lng} need_category: {need_category}"
    matcher_result = await run_single_agent(matcher_agent, org_id, session_id, matcher_input)
    
    return {
        "submission_id": submission_id,
        "status": "completed",
        "need_id": need_id,
        "classifier_result": classifier_result,
        "matcher_result": matcher_result
    }
