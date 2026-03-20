from fastapi import APIRouter
from app.services.service import AssistantService

router = APIRouter()
service = AssistantService()

@router.post("/chat")
def chat(user_input: dict):
    return service.respond(user_input["message"])
