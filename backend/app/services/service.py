from app.ai.assistant import AssistantAI

class AssistantService:
    def __init__(self):
        self.ai = AssistantAI()

    def respond(self, message, db=None):
        return {
            "response": self.ai.generate_response(message, db=db)
        }

    def learn(self, text: str, correct_intent: str):
        return self.ai.learner.learn_from_feedback(text, correct_intent)
