"""
AURA Authentication — Real JWT with access + refresh tokens.
python-jose handles signing. passlib handles password hashing.
"""
import os
import hashlib
import secrets
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Depends, Request
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from jose import jwt, JWTError
import bcrypt

from ..db import get_db
from ..models import User, RefreshToken, Workspace, WorkspaceMember, AuditLog

router = APIRouter(prefix="/auth", tags=["Authentication"])
# router = APIRouter(prefix="/auth", tags=["Authentication"])
# pwd_context removed because of passlib/bcrypt 4.0 incompatibility on Python 3.13

SECRET_KEY  = os.getenv("SECRET_KEY", "aura-super-secret-change-in-prod-64-chars-minimum!")
ALGORITHM   = "HS256"
ACCESS_TTL  = timedelta(minutes=15)
REFRESH_TTL = timedelta(days=7)


# ─── Schemas ──────────────────────────────────────────────────────────────── #
class SignupRequest(BaseModel):
    email:    str
    password: str
    name:     str | None = None

class LoginRequest(BaseModel):
    email:    str
    password: str

class RefreshRequest(BaseModel):
    refresh_token: str


# ─── Helpers ──────────────────────────────────────────────────────────────── #
def hash_password(pw: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pw.encode('utf-8'), salt).decode('utf-8')

def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode('utf-8'), hashed.encode('utf-8'))
    except Exception:
        return False

def create_access_token(user_id: int) -> str:
    expire = datetime.utcnow() + ACCESS_TTL
    return jwt.encode({"sub": str(user_id), "exp": expire, "type": "access"}, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token_value() -> str:
    return secrets.token_urlsafe(64)

def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()

def decode_access_token(token: str) -> int:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "access":
            raise HTTPException(status_code=401, detail="Invalid token type")
        return int(payload["sub"])
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

def _log(db: Session, user_id: int | None, action: str, resource: str, request: Request | None = None, detail: str = ""):
    log = AuditLog(
        user_id    = user_id,
        action     = action,
        resource   = resource,
        ip_address = request.client.host if request else "unknown",
        detail     = detail,
    )
    db.add(log)


# ─── Routes ───────────────────────────────────────────────────────────────── #
@router.post("/signup")
def signup(req: SignupRequest, request: Request, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        email           = req.email,
        hashed_password = hash_password(req.password),
        name            = req.name or req.email.split("@")[0],
    )
    db.add(user)
    db.flush()

    # Create a default personal workspace
    ws = Workspace(name=f"{user.name}'s Workspace", owner_id=user.id, plan="free")
    db.add(ws)
    db.flush()
    db.add(WorkspaceMember(workspace_id=ws.id, user_id=user.id, role="admin"))

    _log(db, user.id, "signup", "user", request)
    db.commit()

    access  = create_access_token(user.id)
    refresh = create_refresh_token_value()
    db.add(RefreshToken(
        user_id    = user.id,
        token_hash = hash_token(refresh),
        expires_at = datetime.utcnow() + REFRESH_TTL,
    ))
    db.commit()
    return {
        "access_token":  access,
        "refresh_token": refresh,
        "token_type":    "bearer",
        "user_id":       user.id,
        "workspace_id":  ws.id,
    }


@router.post("/login")
def login(req: LoginRequest, request: Request, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not verify_password(req.password, user.hashed_password):
        _log(db, None, "login_failed", "user", request, detail=req.email)
        db.commit()
        raise HTTPException(status_code=401, detail="Invalid credentials")

    access  = create_access_token(user.id)
    refresh = create_refresh_token_value()
    db.add(RefreshToken(
        user_id    = user.id,
        token_hash = hash_token(refresh),
        expires_at = datetime.utcnow() + REFRESH_TTL,
    ))
    _log(db, user.id, "login", "user", request)
    db.commit()

    # Get first workspace
    member = db.query(WorkspaceMember).filter(WorkspaceMember.user_id == user.id).first()
    return {
        "access_token":  access,
        "refresh_token": refresh,
        "token_type":    "bearer",
        "user_id":       user.id,
        "workspace_id":  member.workspace_id if member else None,
    }


@router.post("/refresh")
def refresh(req: RefreshRequest, db: Session = Depends(get_db)):
    th = hash_token(req.refresh_token)
    record = db.query(RefreshToken).filter(
        RefreshToken.token_hash == th,
        RefreshToken.revoked == False,
    ).first()
    if not record or record.expires_at < datetime.utcnow():
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    # Rotate: revoke old, issue new
    record.revoked = True
    new_refresh    = create_refresh_token_value()
    db.add(RefreshToken(
        user_id    = record.user_id,
        token_hash = hash_token(new_refresh),
        expires_at = datetime.utcnow() + REFRESH_TTL,
    ))
    db.commit()
    return {
        "access_token":  create_access_token(record.user_id),
        "refresh_token": new_refresh,
        "token_type":    "bearer",
    }


@router.post("/logout")
def logout(req: RefreshRequest, db: Session = Depends(get_db)):
    th = hash_token(req.refresh_token)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == th).first()
    if record:
        record.revoked = True
        db.commit()
    return {"message": "Logged out"}
