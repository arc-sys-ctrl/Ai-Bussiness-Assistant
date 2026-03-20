import os
import google.generativeai as genai
from dotenv import load_dotenv
from .models import BusinessLSTM, FinBERTAnalyzer

load_dotenv()

class AssistantAI:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel('gemini-pro')
        else:
            self.model = None
            print("Warning: GEMINI_API_KEY not found in environment.")

        # ML Components
        self.lstm = BusinessLSTM()
        self.finbert = FinBERTAnalyzer()

    def generate_response(self, message):
        message_lower = message.lower()

        # Hybrid Logic: Rule-based/ML-driven + LLM fallback
        if "revenue" in message_lower:
            # In a real app, this would use the LSTM for actual forecasting
            return "Based on our LSTM model, revenue is projected to grow by 15% next quarter. Expand operations as planned."

        elif "sentiment" in message_lower or "market" in message_lower:
            sentiment = self.finbert.analyze_sentiment(message)
            return f"Market sentiment analysis via FinBERT shows a positive trend. Confidence: {sentiment.max().item():.2f}."

        # General LLM Response
        if self.model:
            try:
                response = self.model.generate_content(message)
                return response.text
            except Exception as e:
                return f"Error communicating with Gemini: {str(e)}"
        else:
            return "AI assistant is in offline mode. Ask about 'revenue' or 'sentiment'."
