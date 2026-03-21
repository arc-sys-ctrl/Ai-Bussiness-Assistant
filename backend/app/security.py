"""
AURA Security Dependencies — JWT verification and RBAC.
"""
from fastapi import HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from .routes.auth import decode_access_token
from .db import get_db
from .models import User, WorkspaceMember

bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    user_id = decode_access_token(credentials.credentials)
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def require_role(minimum_role: str):
    """
    Factory that returns a FastAPI dependency checking workspace membership role.
    Role hierarchy: viewer < analyst < admin
    """
    hierarchy = {"viewer": 0, "analyst": 1, "admin": 2}

    def checker(
        workspace_id: int,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
    ):
        member = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == current_user.id,
        ).first()
        if not member:
            raise HTTPException(status_code=403, detail="Not a member of this workspace")
        if hierarchy.get(member.role, -1) < hierarchy.get(minimum_role, 99):
            raise HTTPException(status_code=403, detail=f"Role '{minimum_role}' required")
        return current_user

    return checker
