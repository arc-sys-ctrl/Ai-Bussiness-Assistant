import os
import google.generativeai as genai
from dotenv import load_dotenv
from .models import BusinessLSTM, FinBERTAnalyzer
from ..models import Alert, ChatHistory

load_dotenv()

class AssistantAI:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment. AI Assistant requires a valid API key.")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')

        # ML Components
        self.lstm = BusinessLSTM()
        self.finbert = FinBERTAnalyzer()

    def generate_response(self, message, db=None):
        # Prepare context from database if available
        context = ""
        if db:
            recent_alerts = db.query(Alert).order_by(Alert.created_at.desc()).limit(5).all()
            if recent_alerts:
                context += "\nRecent Business Alerts:\n"
                for alert in recent_alerts:
                    context += f"- {alert.level.upper()}: {alert.title} - {alert.details}\n"

        # Construct prompt with context
        prompt = f"System Context: You are an AI Business Assistant. Use the following context if relevant to the user request. Do not mention the context source unless asked. If information is missing, state it clearly.\n{context}\n\nUser: {message}\nAssistant:"

        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"AI Service Error: {str(e)}"
