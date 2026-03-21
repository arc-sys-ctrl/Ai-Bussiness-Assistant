"""
AURA Strategy, Ideas, OKR, Market, Analytics, Subscription,
Integrations, AI Status, and Developer API Key routes.
All in one file to register with the main FastAPI app.
"""
import os
import secrets
import hashlib
from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

import requests as http_requests

from ..db import get_db
from ..models import (
    Alert, User, ChatHistory, Workspace, WorkspaceMember,
    Idea, OKR, Subscription, Integration, ApiKey, MarketNews
)
from ..security import get_current_user
from ..ai.analytics    import predict_revenue, detect_anomaly
from ..ai.market_intel import fetch_news, generate_swot
from ..services.service import AssistantService

router  = APIRouter()
service = AssistantService()


# ══════════════════════════════════════════════════════════════
#  CHAT
# ══════════════════════════════════════════════════════════════
class ChatRequest(BaseModel):
    message:      str
    user_id:      Optional[int] = None
    workspace_id: Optional[int] = None

class FeedbackRequest(BaseModel):
    text:           str
    correct_intent: str

class MessageFeedback(BaseModel):
    chat_id:  int
    feedback: str   # "up" | "down"

@router.post("/chat")
def chat(req: ChatRequest, db: Session = Depends(get_db)):
    result        = service.respond(req.message, db=db)
    response_text = result["response"]
    if req.user_id:
        entry = ChatHistory(
            user_id      = req.user_id,
            workspace_id = req.workspace_id,
            message      = req.message,
            response     = response_text,
        )
        db.add(entry)
        db.commit()
        return {"response": response_text, "chat_id": entry.id}
    return {"response": response_text}

@router.post("/feedback")
def feedback(req: FeedbackRequest):
    result = service.learn(req.text, req.correct_intent)
    return result

@router.post("/chat/{chat_id}/feedback")
def rate_message(chat_id: int, req: MessageFeedback, db: Session = Depends(get_db)):
    entry = db.query(ChatHistory).filter(ChatHistory.id == chat_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Chat entry not found")
    if req.feedback not in ("up", "down"):
        raise HTTPException(status_code=400, detail="feedback must be 'up' or 'down'")
    entry.feedback = req.feedback
    db.commit()
    # If downvoted, attempt to self-correct
    if req.feedback == "down":
        service.learn(entry.message, "general")
    return {"status": "recorded"}

@router.get("/ai/status")
def ai_status():
    import os, torch
    weights_file = os.path.join(os.path.dirname(__file__), "..", "ai", "weights", "aura_weights.pt")
    weight_version = "untrained"
    if os.path.exists(weights_file):
        mtime = os.path.getmtime(weights_file)
        weight_version = datetime.fromtimestamp(mtime).isoformat()
    return {
        "model":          "AURA Neural Net v1",
        "architecture":   "InputLayer[2048×64] → Hidden[64→128→64] → OutputLayer[64→16]",
        "weights_updated": weight_version,
        "intents":        16,
    }


# ══════════════════════════════════════════════════════════════
# DASHBOARD
# ══════════════════════════════════════════════════════════════
@router.get("/dashboard/stats")
def get_dashboard_stats(workspace_id: Optional[int] = None, db: Session = Depends(get_db)):
    total_chats    = db.query(ChatHistory).filter(
        ChatHistory.workspace_id == workspace_id if workspace_id else True
    ).count()
    open_tasks     = 0
    warning_alerts = db.query(Alert).filter(Alert.level == "warning").count()
    if workspace_id:
        from ..models import Task
        open_tasks = db.query(Task).filter(
            Task.workspace_id == workspace_id,
            Task.status != "done",
        ).count()
    return {
        "projected_revenue":   "$58,200",
        "market_sentiment":    "Positive (0.92)",
        "security_alerts":     f"{warning_alerts} Active Warning(s)",
        "total_interactions":  total_chats,
        "open_tasks":          open_tasks,
    }

@router.get("/dashboard/insights")
def get_dashboard_insights():
    return [
        "Strategic focus: Shift marketing efforts to high-growth tech sectors.",
        "Operational efficiency: Automated workflow reduced overhead by 12%.",
        "Market trend: Rising interest in sustainable AI solutions noticed.",
        "AURA neural network is actively learning from each interaction.",
    ]

@router.get("/dashboard/history")
def get_chat_history(user_id: int, limit: int = 20, db: Session = Depends(get_db)):
    entries = db.query(ChatHistory).filter(ChatHistory.user_id == user_id)\
        .order_by(ChatHistory.timestamp.desc()).limit(limit).all()
    return [
        {"id": e.id, "message": e.message, "response": e.response, "timestamp": str(e.timestamp)}
        for e in entries
    ]


# ══════════════════════════════════════════════════════════════
# ALERTS
# ══════════════════════════════════════════════════════════════
@router.get("/alerts")
def get_alerts(workspace_id: Optional[int] = None, db: Session = Depends(get_db)):
    query = db.query(Alert)
    if workspace_id:
        query = query.filter(Alert.workspace_id == workspace_id)
    alerts = query.order_by(Alert.created_at.desc()).all()
    if not alerts:
        initial = [
            Alert(workspace_id=workspace_id, title="Revenue Anomaly",    details="Unusual dip in city center region.", level="warning"),
            Alert(workspace_id=workspace_id, title="Market Opportunity",  details="High sentiment detected for green energy.", level="success"),
            Alert(workspace_id=workspace_id, title="System Update",       details="AURA neural weights initialized successfully.", level="info"),
        ]
        db.add_all(initial)
        db.commit()
        alerts = db.query(Alert).order_by(Alert.created_at.desc()).all()
    return [{"id": a.id, "title": a.title, "details": a.details, "level": a.level, "created_at": str(a.created_at)} for a in alerts]


# ══════════════════════════════════════════════════════════════
# PROFILE
# ══════════════════════════════════════════════════════════════
@router.get("/profile/{user_id}")
def get_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    member = db.query(WorkspaceMember).filter(WorkspaceMember.user_id == user_id).first()
    plan = "free"
    if member:
        sub = db.query(Subscription).filter(Subscription.workspace_id == member.workspace_id).first()
        if sub:
            plan = sub.plan
    return {
        "id":        user.id,
        "name":      user.name      or "AURA User",
        "email":     user.email,
        "suite":     "AURA Enterprise Suite",
        "region":    user.region    or "Not set",
        "industry":  user.industry  or "Not set",
        "team_size": user.team_size or "Not set",
        "plan":      plan,
    }

class ProfileUpdate(BaseModel):
    name:      Optional[str] = None
    region:    Optional[str] = None
    industry:  Optional[str] = None
    team_size: Optional[str] = None

@router.patch("/profile/{user_id}")
def update_profile(user_id: int, req: ProfileUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if req.name:      user.name      = req.name
    if req.region:    user.region    = req.region
    if req.industry:  user.industry  = req.industry
    if req.team_size: user.team_size = req.team_size
    db.commit()
    return {"message": "Profile updated"}


# ══════════════════════════════════════════════════════════════
# ANALYTICS (#1)
# ══════════════════════════════════════════════════════════════
class ForecastRequest(BaseModel):
    historical:     List[float]
    periods_ahead:  int = 4

class AnomalyRequest(BaseModel):
    series:    List[float]
    threshold: float = 2.5

@router.post("/analytics/forecast")
def analytics_forecast(req: ForecastRequest):
    if len(req.historical) < 2:
        raise HTTPException(status_code=400, detail="Provide at least 2 data points")
    return predict_revenue(req.historical, req.periods_ahead)

@router.post("/analytics/anomaly")
def analytics_anomaly(req: AnomalyRequest):
    return {"anomalies": detect_anomaly(req.series, req.threshold)}


# ══════════════════════════════════════════════════════════════
# MARKET INTELLIGENCE (#6)
# ══════════════════════════════════════════════════════════════
@router.get("/market/news")
def market_news(topic: str = "AI business", db: Session = Depends(get_db)):
    articles = fetch_news(topic, max_results=10)
    # Persist to DB (dedup by URL)
    for a in articles:
        if a.get("url") and a["url"] != "#":
            exists = db.query(MarketNews).filter(MarketNews.url == a["url"]).first()
            if not exists:
                db.add(MarketNews(
                    topic        = topic,
                    title        = a["title"],
                    url          = a["url"],
                    source       = a.get("source", ""),
                    published_at = datetime.fromisoformat(a["published_at"]) if a.get("published_at") else None,
                ))
    db.commit()
    return {"topic": topic, "articles": articles}

@router.get("/market/history")
def market_news_history(topic: str = "", limit: int = 20, db: Session = Depends(get_db)):
    query = db.query(MarketNews)
    if topic:
        query = query.filter(MarketNews.topic.ilike(f"%{topic}%"))
    rows = query.order_by(MarketNews.fetched_at.desc()).limit(limit).all()
    return [{"title": r.title, "url": r.url, "source": r.source, "published_at": str(r.published_at)} for r in rows]


# ══════════════════════════════════════════════════════════════
# STRATEGY & SWOT (#7)
# ══════════════════════════════════════════════════════════════
@router.get("/strategy/swot")
def swot_analysis(workspace_id: int, db: Session = Depends(get_db)):
    alerts     = db.query(Alert).filter(Alert.workspace_id == workspace_id).all()
    open_tasks = 0
    from ..models import Task
    open_tasks = db.query(Task).filter(Task.workspace_id == workspace_id, Task.status != "done").count()
    ideas_rows = db.query(Idea).filter(Idea.workspace_id == workspace_id).limit(5).all()

    ws = db.query(Workspace).filter(Workspace.id == workspace_id).first()
    plan = ws.plan if ws else "free"

    context = {
        "alerts":     [{"level": a.level, "title": a.title} for a in alerts],
        "tasks_open": open_tasks,
        "ideas":      [i.idea_text for i in ideas_rows],
        "plan":       plan,
    }
    return generate_swot(context)


# ══════════════════════════════════════════════════════════════
# IDEAS
# ══════════════════════════════════════════════════════════════
class IdeaGenerateRequest(BaseModel):
    domain:       str
    workspace_id: Optional[int] = None
    n_ideas:      int = 4

@router.post("/ideas/generate")
def generate_ideas(req: IdeaGenerateRequest, db: Session = Depends(get_db)):
    from ..ai.idea_generator import IdeaGenerator
    gen = IdeaGenerator()
    db_context = ""
    if req.workspace_id:
        recent = db.query(Alert).filter(Alert.workspace_id == req.workspace_id).limit(3).all()
        db_context = " ".join(f"{a.title}: {a.details}" for a in recent)
    result = gen.generate(domain=req.domain, db_context=db_context, n_ideas=req.n_ideas, use_web=True)
    # Persist generated ideas
    if req.workspace_id:
        for idea_text in result["ideas"]:
            db.add(Idea(workspace_id=req.workspace_id, domain=req.domain, idea_text=idea_text))
        db.commit()
    return result

@router.get("/ideas")
def list_ideas(workspace_id: int, db: Session = Depends(get_db)):
    ideas = db.query(Idea).filter(Idea.workspace_id == workspace_id).order_by(Idea.created_at.desc()).all()
    return [{"id": i.id, "domain": i.domain, "text": i.idea_text, "created_at": str(i.created_at)} for i in ideas]


# ══════════════════════════════════════════════════════════════
# OKRs
# ══════════════════════════════════════════════════════════════
class OKRCreate(BaseModel):
    objective:   str
    key_results: list   # [{text: str, progress: 0-100}]
    due_date:    Optional[datetime] = None

class OKRUpdate(BaseModel):
    key_results:      Optional[list]  = None
    overall_progress: Optional[float] = None

@router.get("/okr")
def list_okrs(workspace_id: int, db: Session = Depends(get_db)):
    okrs = db.query(OKR).filter(OKR.workspace_id == workspace_id).all()
    return [_okr_dict(o) for o in okrs]

@router.post("/okr")
def create_okr(workspace_id: int, req: OKRCreate, db: Session = Depends(get_db)):
    okr = OKR(workspace_id=workspace_id, objective=req.objective,
               key_results=req.key_results, due_date=req.due_date)
    db.add(okr)
    db.commit()
    return _okr_dict(okr)

@router.patch("/okr/{okr_id}")
def update_okr(okr_id: int, req: OKRUpdate, db: Session = Depends(get_db)):
    okr = db.query(OKR).filter(OKR.id == okr_id).first()
    if not okr:
        raise HTTPException(status_code=404, detail="OKR not found")
    if req.key_results is not None:
        okr.key_results = req.key_results
        progresses = [kr.get("progress", 0) for kr in req.key_results]
        okr.overall_progress = sum(progresses) / len(progresses) if progresses else 0
    if req.overall_progress is not None:
        okr.overall_progress = req.overall_progress
    db.commit()
    return _okr_dict(okr)

def _okr_dict(o: OKR) -> dict:
    return {"id": o.id, "objective": o.objective, "key_results": o.key_results,
            "overall_progress": o.overall_progress, "due_date": str(o.due_date) if o.due_date else None}


# ══════════════════════════════════════════════════════════════
# SUBSCRIPTION (#8)
# ══════════════════════════════════════════════════════════════
PLAN_FEATURES = {
    "free":       {"queries_per_month": 50,   "integrations": 0, "members": 3},
    "pro":        {"queries_per_month": -1,   "integrations": 5, "members": 25},
    "enterprise": {"queries_per_month": -1,   "integrations": -1, "members": -1},
}

@router.get("/subscription")
def get_subscription(workspace_id: int, db: Session = Depends(get_db)):
    sub = db.query(Subscription).filter(Subscription.workspace_id == workspace_id).first()
    if not sub:
        sub = Subscription(workspace_id=workspace_id, plan="free")
        db.add(sub)
        db.commit()
    plan = sub.plan
    return {"workspace_id": workspace_id, "plan": plan, "features": PLAN_FEATURES.get(plan, {}),
            "expires_at": str(sub.expires_at) if sub.expires_at else None}

@router.post("/subscription/upgrade")
def upgrade_subscription(workspace_id: int, plan: str, db: Session = Depends(get_db)):
    if plan not in PLAN_FEATURES:
        raise HTTPException(status_code=400, detail=f"Invalid plan: {plan}")
    sub = db.query(Subscription).filter(Subscription.workspace_id == workspace_id).first()
    if not sub:
        sub = Subscription(workspace_id=workspace_id)
        db.add(sub)
    sub.plan = plan
    db.query(Workspace).filter(Workspace.id == workspace_id).update({"plan": plan})
    db.commit()
    return {"message": f"Upgraded to {plan}", "features": PLAN_FEATURES[plan]}


# ══════════════════════════════════════════════════════════════
# INTEGRATIONS (#3)
# ══════════════════════════════════════════════════════════════
class IntegrationSave(BaseModel):
    type:         str
    config:       dict
    workspace_id: int

@router.post("/integrations")
def save_integration(req: IntegrationSave, db: Session = Depends(get_db)):
    existing = db.query(Integration).filter(
        Integration.workspace_id == req.workspace_id,
        Integration.type == req.type,
    ).first()
    if existing:
        existing.config  = req.config
        existing.enabled = True
    else:
        db.add(Integration(workspace_id=req.workspace_id, type=req.type, config=req.config))
    db.commit()
    return {"message": f"{req.type} integration saved"}

@router.get("/integrations")
def list_integrations(workspace_id: int, db: Session = Depends(get_db)):
    rows = db.query(Integration).filter(Integration.workspace_id == workspace_id).all()
    return [{"id": r.id, "type": r.type, "enabled": r.enabled} for r in rows]

@router.post("/integrations/slack/notify")
def slack_notify(workspace_id: int, message: str, db: Session = Depends(get_db)):
    integration = db.query(Integration).filter(
        Integration.workspace_id == workspace_id,
        Integration.type == "slack",
        Integration.enabled == True,
    ).first()
    if not integration:
        raise HTTPException(status_code=404, detail="Slack integration not configured")
    webhook_url = integration.config.get("webhook_url")
    if not webhook_url:
        raise HTTPException(status_code=400, detail="Slack webhook URL missing in config")
    resp = http_requests.post(webhook_url, json={"text": message}, timeout=5)
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Slack returned {resp.status_code}")
    return {"message": "Slack notification sent"}

@router.post("/integrations/webhook")
async def receive_webhook(request: Request, db: Session = Depends(get_db)):
    payload = await request.json()
    # Store as an alert for visibility
    db.add(Alert(title="Inbound Webhook", details=str(payload)[:500], level="info"))
    db.commit()
    return {"status": "received"}


# ══════════════════════════════════════════════════════════════
# DEVELOPER API KEYS (#11)
# ══════════════════════════════════════════════════════════════
@router.post("/developer/api-key")
def create_api_key(workspace_id: int, label: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    raw_key = f"aura_{secrets.token_urlsafe(32)}"
    key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
    db.add(ApiKey(user_id=current_user.id, workspace_id=workspace_id, key_hash=key_hash, label=label))
    db.commit()
    # Only show raw key once
    return {"api_key": raw_key, "label": label, "note": "Store this key securely — it will not be shown again"}

@router.get("/developer/api-keys")
def list_api_keys(workspace_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    keys = db.query(ApiKey).filter(ApiKey.workspace_id == workspace_id, ApiKey.revoked == False).all()
    return [{"id": k.id, "label": k.label, "created_at": str(k.created_at)} for k in keys]

@router.delete("/developer/api-key/{key_id}")
def revoke_api_key(key_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    key = db.query(ApiKey).filter(ApiKey.id == key_id, ApiKey.user_id == current_user.id).first()
    if not key:
        raise HTTPException(status_code=404, detail="Key not found")
    key.revoked = True
    db.commit()
    return {"message": "API key revoked"}
