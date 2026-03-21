"""
AURA AI Orchestrator
Routes every incoming message through:
  1. SelfLearner  → detect intent (neural network + keyword heuristic)
  2. web_search   → if intent is 'search'
  3. IdeaGenerator → if intent is 'ideas' or 'strategy'
  4. Knowledge base + synthesized response → for all other intents

No LLMs, No external AI APIs. Everything runs locally.
"""
from .learner        import SelfLearner
from .idea_generator import IdeaGenerator
from . import web_search
from ..models import Alert


# Intent → knowledge base response templates
RESPONSE_TEMPLATES = {
    "greeting":  "Hello! I'm AURA, your AI Business Assistant. How can I help you today?",
    "farewell":  "Goodbye! AURA is always here when you need strategic insights.",
    "help":      "I can help you with: market analysis, revenue forecasting, business strategy, idea generation, and web search. Just ask!",
    "revenue":   (
        "Based on current trend analysis, revenue growth depends on:\n"
        "• Expanding into high-margin product lines\n"
        "• Optimizing customer acquisition cost (CAC)\n"
        "• Increasing average contract value (ACV) through upselling\n"
        "Ask me to 'search' for the latest revenue benchmarks in your industry."
    ),
    "sentiment": (
        "Market sentiment analysis (rule-based heuristics):\n"
        "• Strong BUY signals: rising volume + positive news flow\n"
        "• HOLD signals:  mixed macro indicators\n"
        "• SELL signals:  elevated risk metrics + declining margins\n"
        "Say 'search market sentiment [sector]' for real-time data."
    ),
    "risk": (
        "Key risk vectors to monitor:\n"
        "• Regulatory changes — track compliance news\n"
        "• Currency volatility — hedge exposure\n"
        "• Supply chain disruption — diversify suppliers\n"
        "• Cyber threats — audit access controls quarterly"
    ),
    "market": (
        "Market intelligence brief:\n"
        "• Emerging sectors: Green tech, AI infrastructure, Health-tech\n"
        "• Maturing sectors: Traditional retail, Legacy banking\n"
        "• Opportunity zones: Southeast Asia, Gulf markets, Tier-2 US cities\n"
        "Use 'search [topic]' to get live market data."
    ),
    "forecast": (
        "Forecasting framework (AURA proprietary):\n"
        "• Short-term (0–3 months): driven by order backlog and pipeline data\n"
        "• Mid-term  (3–12 months): driven by macro trends + sector velocity\n"
        "• Long-term (1–5 years):  driven by technology adoption curves\n"
        "Share your data points and I'll refine the projection."
    ),
    "alert": (
        "Active alert protocol — check the Alerts panel for real-time notifications. "
        "You can configure thresholds in Settings."
    ),
    "profile":  "Access your company profile, team settings, and subscription details in the Profile section.",
    "setting":  "You can adjust notification thresholds, integrations, and AI parameters from the Settings screen.",
    "general":  (
        "AURA is processing your request. For best results, be specific:\n"
        "• 'search [topic]' — live web search\n"
        "• 'generate ideas for [domain]' — AI idea synthesis\n"
        "• 'revenue forecast' — business projections\n"
        "• 'market analysis' — sector intelligence"
    ),
    "unknown":  "I'm not sure I understood that. Try: 'search [topic]', 'generate ideas for [domain]', or ask about revenue, market, or risk.",
}


class AssistantAI:
    def __init__(self):
        self.learner   = SelfLearner()
        self.idea_gen  = IdeaGenerator()

    def generate_response(self, message: str, db=None) -> str:
        intent_data = self.learner.process(message)
        intent      = intent_data["intent"]
        confidence  = intent_data["confidence"]

        # Enrich with DB context if available
        db_context = ""
        if db:
            try:
                alerts = db.query(Alert).order_by(Alert.created_at.desc()).limit(3).all()
                if alerts:
                    db_context = " | ".join(f"{a.title}: {a.details}" for a in alerts)
            except Exception:
                pass

        # ── Route by intent ────────────────────────────────────────────── #

        # 1. WEB SEARCH
        if intent == "search":
            # Strip search keyword from query
            query = message.lower()
            for kw in ["search", "find", "look up", "google"]:
                query = query.replace(kw, "").strip()
            query = query or "business trends 2025"
            results = web_search.search(query, max_results=5)
            formatted = web_search.format_results_as_text(results)
            return f"🔍 **Web Search: '{query}'**\n\n{formatted}"

        # 2. IDEA GENERATION
        if intent in ("ideas", "strategy"):
            # Extract domain from message
            domain = message.lower()
            for kw in ["generate ideas for", "ideas for", "strategy for", "suggest", "generate"]:
                domain = domain.replace(kw, "").strip()
            domain = domain or "business"
            result = self.idea_gen.generate(
                domain      = domain,
                db_context  = db_context,
                n_ideas     = 4,
                use_web     = True,
            )
            lines = [f"💡 **AURA Idea Engine — '{domain}'**\n"]
            for i, idea in enumerate(result["ideas"], 1):
                lines.append(f"{i}. {idea}")
            if result["web_context"]:
                lines.append(f"\n📰 **Market Context (live)**")
                for r in result["web_context"]:
                    lines.append(f"• [{r['title']}]({r['url']}): {r['snippet'][:100]}…")
            return "\n".join(lines)

        # 3. KNOWLEDGE BASE RESPONSE
        base_response = RESPONSE_TEMPLATES.get(intent, RESPONSE_TEMPLATES["general"])

        # Append relevant DB context if available
        if db_context and intent in ("alert", "market", "forecast", "revenue", "risk"):
            base_response += f"\n\n📌 **Live Alerts:**\n{db_context}"

        # Confidence indicator footer
        footer = f"\n\n_AURA confidence: {confidence:.0%} · intent: {intent}_"
        return base_response + footer
