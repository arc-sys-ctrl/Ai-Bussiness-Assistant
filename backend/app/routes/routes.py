from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from ..db import get_db
from ..models import Alert, User, ChatHistory
from ..services.service import AssistantService

router = APIRouter()
service = AssistantService()


class ChatRequest(BaseModel):
    message: str
    user_id: int | None = None


class FeedbackRequest(BaseModel):
    text: str
    correct_intent: str


# ──────────────────────────── Chat ──────────────────────────────────────────

@router.post("/chat")
def chat(req: ChatRequest, db: Session = Depends(get_db)):
    result   = service.respond(req.message, db=db)
    response_text = result["response"]

    if req.user_id:
        entry = ChatHistory(
            user_id  = req.user_id,
            message  = req.message,
            response = response_text,
        )
        db.add(entry)
        db.commit()

    return {"response": response_text}


# ──────────────────────────── Self-Learning Feedback ────────────────────────

@router.post("/feedback")
def feedback(req: FeedbackRequest):
    """
    Allows the frontend to correct the AI's intent classification.
    Triggers one backpropagation step and persists updated weights.
    """
    result = service.learn(req.text, req.correct_intent)
    return result


# ──────────────────────────── Dashboard ─────────────────────────────────────

@router.get("/dashboard/stats")
def get_dashboard_stats(db: Session = Depends(get_db)):
    total_chats    = db.query(ChatHistory).count()
    warning_alerts = db.query(Alert).filter(Alert.level == "warning").count()
    return {
        "projected_revenue": "$58,200",
        "market_sentiment":  "Positive (0.92)",
        "security_alerts":   f"{warning_alerts} Active Warning(s)",
        "total_interactions": total_chats,
    }


@router.get("/dashboard/insights")
def get_dashboard_insights():
    return [
        "Strategic focus: Shift marketing efforts to high-growth tech sectors.",
        "Operational efficiency: Automated workflow reduced overhead by 12%.",
        "Market trend: Rising interest in sustainable AI solutions noticed.",
        "AURA neural network is actively learning from each interaction.",
    ]


# ──────────────────────────── Alerts ────────────────────────────────────────

@router.get("/alerts")
def get_alerts(db: Session = Depends(get_db)):
    alerts = db.query(Alert).order_by(Alert.created_at.desc()).all()
    if not alerts:
        initial = [
            Alert(title="Revenue Anomaly",    details="Unusual dip in city center region.", level="warning"),
            Alert(title="Market Opportunity", details="High sentiment detected for green energy.", level="success"),
            Alert(title="System Update",      details="AURA neural weights initialized successfully.", level="info"),
        ]
        db.add_all(initial)
        db.commit()
        alerts = db.query(Alert).order_by(Alert.created_at.desc()).all()

    return [{"title": a.title, "details": a.details, "level": a.level, "created_at": str(a.created_at)} for a in alerts]


# ──────────────────────────── Profile ───────────────────────────────────────

@router.get("/profile/{user_id}")
def get_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "name":      user.name      or "Arc-Sys-Ctrl Ltd.",
        "suite":     user.suite     or "AURA Enterprise Suite",
        "region":    user.region    or "North America",
        "industry":  user.industry  or "Financial Technology",
        "team_size": user.team_size or "50-200 Employees",
    }
