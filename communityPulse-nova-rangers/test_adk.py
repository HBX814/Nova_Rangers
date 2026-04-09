import asyncio
from google.adk.agents import LlmAgent
from google.adk.apps import App
from google.adk.runners import InMemoryRunner
from google.genai import types
import uuid

agent = LlmAgent(name="test", model="gemini-2.5-flash", instruction="say hi")

async def main():
    app = App(name="testApp", root_agent=agent)
    runner = InMemoryRunner(app=app)
    sess_id = uuid.uuid4().hex
    await runner.session_service.create_session(user_id="u1", session_id=sess_id, app_name="testApp")
    
    msg = types.Content(parts=[types.Part.from_text(text="hello")])
    responses = []
    async for e in runner.run_async(user_id="u1", session_id=sess_id, new_message=msg):
        if getattr(e, 'type', None) == 'agent_response':
            responses.append(e.agent_response.message.parts[0].text)
    print("GOT:", responses)

asyncio.run(main())
