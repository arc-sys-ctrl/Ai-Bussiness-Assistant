from app.ai.assistant import AssistantAI

class AssistantService:
    def __init__(self):
        self.ai = AssistantAI()

    def respond(self, message, db=None):
        return {
            "response": self.ai.generate_response(message, db=db)
        }
