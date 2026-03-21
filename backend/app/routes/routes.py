from fastapi import APIRouter
from app.services.service import AssistantService

router = APIRouter()
service = AssistantService()

@router.post("/chat")
def chat(user_input: dict):
    return service.respond(user_input["message"])

@router.get("/dashboard/stats")
def get_dashboard_stats():
    return {
        "projected_revenue": "$58,200",
        "market_sentiment": "Positive (0.92)",
        "security_alerts": "2 Low Priority",
    }

@router.get("/dashboard/insights")
def get_dashboard_insights():
    return [
        "Strategic focus: Shift marketing efforts to high-growth tech sectors.",
        "Operational efficiency: Automated workflow reduced overhead by 12%.",
        "Market trend: Rising interest in sustainable AI solutions noticed."
    ]

@router.get("/alerts")
def get_alerts():
    return [
        {"title": "Revenue Anomaly", "details": "Unusual dip in city center region.", "level": "warning"},
        {"title": "Market Opportunity", "details": "High sentiment detected for green energy.", "level": "success"},
        {"title": "System Update", "details": "New AI weights deployed to backend.", "level": "info"},
    ]

@router.get("/profile")
def get_profile():
    return {
        "name": "Arc-Sys-Ctrl Ltd.",
        "suite": "Enterprise Suite",
        "region": "North America",
        "industry": "Financial Technology",
        "team_size": "50-200 Employees",
    }
