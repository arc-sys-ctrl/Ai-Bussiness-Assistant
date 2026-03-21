from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..db import get_db
from ..models import Alert, User, ChatHistory
from ..services.service import AssistantService

router = APIRouter()
service = AssistantService()

@router.post("/chat")
def chat(user_input: dict, db: Session = Depends(get_db)):
    message = user_input.get("message")
    user_id = user_input.get("user_id") # We'll need user_id from frontend

    response = service.respond(message, db=db)

    if user_id:
        chat_entry = ChatHistory(user_id=user_id, message=message, response=response)
        db.add(chat_entry)
        db.commit()

    return response

@router.get("/dashboard/stats")
def get_dashboard_stats(db: Session = Depends(get_db)):
    # In a real app, calculate stats from DB records
    # For now, return dynamic data from DB if available, else static
    return {
        "projected_revenue": "$58,200",
        "market_sentiment": "Positive (0.92)",
        "security_alerts": f"{db.query(Alert).filter(Alert.level == 'warning').count()} Active",
    }

@router.get("/dashboard/insights")
def get_dashboard_insights():
    return [
        "Strategic focus: Shift marketing efforts to high-growth tech sectors.",
        "Operational efficiency: Automated workflow reduced overhead by 12%.",
        "Market trend: Rising interest in sustainable AI solutions noticed."
    ]

@router.get("/alerts")
def get_alerts(db: Session = Depends(get_db)):
    alerts = db.query(Alert).all()
    if not alerts:
        # Seed with initial data if empty (for demo)
        initial_alerts = [
            Alert(title="Revenue Anomaly", details="Unusual dip in city center region.", level="warning"),
            Alert(title="Market Opportunity", details="High sentiment detected for green energy.", level="success"),
            Alert(title="System Update", details="New AI weights deployed to backend.", level="info"),
        ]
        db.add_all(initial_alerts)
        db.commit()
        alerts = db.query(Alert).all()

    return [{"title": a.title, "details": a.details, "level": a.level} for a in alerts]

@router.get("/profile/{user_id}")
def get_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "name": user.name or "Arc-Sys-Ctrl Ltd.",
        "suite": user.suite or "Enterprise Suite",
        "region": user.region or "North America",
        "industry": user.industry or "Financial Technology",
        "team_size": user.team_size or "50-200 Employees",
    }
