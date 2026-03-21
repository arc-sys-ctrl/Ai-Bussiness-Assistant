"""
AURA Full DB Models — All tables for the enterprise platform.
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, Float, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from .db import Base


# ─── User & Auth ───────────────────────────────────────────────────────────── #
class User(Base):
    __tablename__ = "users"
    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    name            = Column(String(255))
    region          = Column(String(255))
    industry        = Column(String(255))
    team_size       = Column(String(255))
    created_at      = Column(DateTime, default=datetime.utcnow)

    workspaces   = relationship("WorkspaceMember", back_populates="user")
    history      = relationship("ChatHistory", back_populates="user")
    audit_logs   = relationship("AuditLog", back_populates="user")
    api_keys     = relationship("ApiKey", back_populates="user")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False)
    token_hash = Column(String(512), unique=True, nullable=False)
    revoked    = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)


class AuditLog(Base):
    __tablename__ = "audit_logs"
    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=True)
    action     = Column(String(255), nullable=False)
    resource   = Column(String(255))
    ip_address = Column(String(64))
    detail     = Column(Text)
    timestamp  = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="audit_logs")


# ─── Workspace & Collaboration ─────────────────────────────────────────────── #
class Workspace(Base):
    __tablename__ = "workspaces"
    id         = Column(Integer, primary_key=True, index=True)
    name       = Column(String(255), nullable=False)
    owner_id   = Column(Integer, ForeignKey("users.id"), nullable=False)
    plan       = Column(String(50), default="free")   # free | pro | enterprise
    created_at = Column(DateTime, default=datetime.utcnow)

    members  = relationship("WorkspaceMember", back_populates="workspace")
    tasks    = relationship("Task", back_populates="workspace")
    alerts   = relationship("Alert", back_populates="workspace")
    ideas    = relationship("Idea", back_populates="workspace")
    okrs     = relationship("OKR", back_populates="workspace")


class WorkspaceMember(Base):
    __tablename__ = "workspace_members"
    id           = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=False)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False)
    role         = Column(String(50), default="viewer")  # admin | analyst | viewer
    joined_at    = Column(DateTime, default=datetime.utcnow)

    workspace = relationship("Workspace", back_populates="members")
    user      = relationship("User", back_populates="workspaces")


class Task(Base):
    __tablename__ = "tasks"
    id           = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=False)
    title        = Column(String(255), nullable=False)
    description  = Column(Text)
    assignee_id  = Column(Integer, ForeignKey("users.id"), nullable=True)
    status       = Column(String(50), default="todo")  # todo | in_progress | done
    due_date     = Column(DateTime, nullable=True)
    created_at   = Column(DateTime, default=datetime.utcnow)

    workspace = relationship("Workspace", back_populates="tasks")
    comments  = relationship("Comment", back_populates="task")


class Comment(Base):
    __tablename__ = "comments"
    id         = Column(Integer, primary_key=True, index=True)
    task_id    = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False)
    text       = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    task = relationship("Task", back_populates="comments")


# ─── Alerts ────────────────────────────────────────────────────────────────── #
class Alert(Base):
    __tablename__ = "alerts"
    id           = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True)
    title        = Column(String(255), nullable=False)
    details      = Column(Text)
    level        = Column(String(50))
    created_at   = Column(DateTime, default=datetime.utcnow)

    workspace = relationship("Workspace", back_populates="alerts")


# ─── Chat History ──────────────────────────────────────────────────────────── #
class ChatHistory(Base):
    __tablename__ = "chat_history"
    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True)
    message      = Column(Text, nullable=False)
    response     = Column(Text, nullable=False)
    intent       = Column(String(100))
    feedback     = Column(String(10), nullable=True)  # up | down
    timestamp    = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="history")


# ─── Market Intelligence ───────────────────────────────────────────────────── #
class MarketNews(Base):
    __tablename__ = "market_news"
    id           = Column(Integer, primary_key=True, index=True)
    topic        = Column(String(255))
    title        = Column(String(500), nullable=False)
    url          = Column(String(1000))
    source       = Column(String(255))
    published_at = Column(DateTime, nullable=True)
    fetched_at   = Column(DateTime, default=datetime.utcnow)


# ─── Ideas & Strategy ──────────────────────────────────────────────────────── #
class Idea(Base):
    __tablename__ = "ideas"
    id           = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True)
    domain       = Column(String(255))
    idea_text    = Column(Text, nullable=False)
    source       = Column(String(100), default="aura")
    created_at   = Column(DateTime, default=datetime.utcnow)

    workspace = relationship("Workspace", back_populates="ideas")


class OKR(Base):
    __tablename__ = "okrs"
    id             = Column(Integer, primary_key=True, index=True)
    workspace_id   = Column(Integer, ForeignKey("workspaces.id"), nullable=False)
    objective      = Column(String(500), nullable=False)
    key_results    = Column(JSON, nullable=False)   # list of {text, progress: 0-100}
    overall_progress = Column(Float, default=0.0)
    due_date       = Column(DateTime, nullable=True)
    created_at     = Column(DateTime, default=datetime.utcnow)

    workspace = relationship("Workspace", back_populates="okrs")


# ─── Subscription ──────────────────────────────────────────────────────────── #
class Subscription(Base):
    __tablename__ = "subscriptions"
    id           = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), unique=True, nullable=False)
    plan         = Column(String(50), default="free")   # free | pro | enterprise
    started_at   = Column(DateTime, default=datetime.utcnow)
    expires_at   = Column(DateTime, nullable=True)


# ─── Integrations ──────────────────────────────────────────────────────────── #
class Integration(Base):
    __tablename__ = "integrations"
    id           = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=False)
    type         = Column(String(100), nullable=False)   # slack | webhook | crm
    config       = Column(JSON)                          # {webhook_url, token, etc}
    enabled      = Column(Boolean, default=True)
    created_at   = Column(DateTime, default=datetime.utcnow)


# ─── Developer API Keys ────────────────────────────────────────────────────── #
class ApiKey(Base):
    __tablename__ = "api_keys"
    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True)
    key_hash     = Column(String(512), unique=True, nullable=False)
    label        = Column(String(255))
    revoked      = Column(Boolean, default=False)
    created_at   = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="api_keys")
