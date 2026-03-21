"""
AURA Collaboration Routes — Workspaces, Tasks, Comments.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

from ..db import get_db
from ..models import Workspace, WorkspaceMember, Task, Comment, User
from ..security import get_current_user

router = APIRouter(prefix="/workspace", tags=["Collaboration"])


# ─── Schemas ──────────────────────────────────────────────────────────────── #
class WorkspaceCreate(BaseModel):
    name: str

class InviteRequest(BaseModel):
    email: str
    role:  str = "viewer"

class TaskCreate(BaseModel):
    title:       str
    description: Optional[str] = None
    assignee_id: Optional[int] = None
    due_date:    Optional[datetime] = None

class TaskUpdate(BaseModel):
    status: str   # todo | in_progress | done

class CommentCreate(BaseModel):
    text: str


# ─── Workspace CRUD ───────────────────────────────────────────────────────── #
@router.post("")
def create_workspace(req: WorkspaceCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    ws = Workspace(name=req.name, owner_id=current_user.id, plan="free")
    db.add(ws)
    db.flush()
    db.add(WorkspaceMember(workspace_id=ws.id, user_id=current_user.id, role="admin"))
    db.commit()
    return {"id": ws.id, "name": ws.name, "plan": ws.plan}


@router.get("")
def list_workspaces(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    memberships = db.query(WorkspaceMember).filter(WorkspaceMember.user_id == current_user.id).all()
    result = []
    for m in memberships:
        ws = db.query(Workspace).filter(Workspace.id == m.workspace_id).first()
        if ws:
            result.append({"id": ws.id, "name": ws.name, "plan": ws.plan, "role": m.role})
    return result


@router.get("/{workspace_id}/members")
def get_members(workspace_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_member(workspace_id, current_user.id, db)
    members = db.query(WorkspaceMember).filter(WorkspaceMember.workspace_id == workspace_id).all()
    result = []
    for m in members:
        user = db.query(User).filter(User.id == m.user_id).first()
        result.append({"user_id": m.user_id, "email": user.email if user else "", "role": m.role})
    return result


@router.post("/{workspace_id}/invite")
def invite_member(workspace_id: int, req: InviteRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_role(workspace_id, current_user.id, "admin", db)
    invitee = db.query(User).filter(User.email == req.email).first()
    if not invitee:
        raise HTTPException(status_code=404, detail="User not found")
    exists = db.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == workspace_id,
        WorkspaceMember.user_id == invitee.id,
    ).first()
    if exists:
        raise HTTPException(status_code=400, detail="Already a member")
    db.add(WorkspaceMember(workspace_id=workspace_id, user_id=invitee.id, role=req.role))
    db.commit()
    return {"message": f"{req.email} invited as {req.role}"}


# ─── Tasks ───────────────────────────────────────────────────────────────── #
@router.get("/{workspace_id}/tasks")
def list_tasks(workspace_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_member(workspace_id, current_user.id, db)
    tasks = db.query(Task).filter(Task.workspace_id == workspace_id).all()
    return [_task_dict(t) for t in tasks]


@router.post("/{workspace_id}/tasks")
def create_task(workspace_id: int, req: TaskCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_member(workspace_id, current_user.id, db)
    task = Task(
        workspace_id = workspace_id,
        title        = req.title,
        description  = req.description,
        assignee_id  = req.assignee_id,
        due_date     = req.due_date,
    )
    db.add(task)
    db.commit()
    return _task_dict(task)


@router.patch("/{workspace_id}/tasks/{task_id}")
def update_task(workspace_id: int, task_id: int, req: TaskUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_member(workspace_id, current_user.id, db)
    task = db.query(Task).filter(Task.id == task_id, Task.workspace_id == workspace_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task.status = req.status
    db.commit()
    return _task_dict(task)


@router.delete("/{workspace_id}/tasks/{task_id}")
def delete_task(workspace_id: int, task_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_role(workspace_id, current_user.id, "analyst", db)
    task = db.query(Task).filter(Task.id == task_id, Task.workspace_id == workspace_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
    return {"message": "Deleted"}


# ─── Comments ─────────────────────────────────────────────────────────────── #
@router.get("/{workspace_id}/tasks/{task_id}/comments")
def list_comments(workspace_id: int, task_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_member(workspace_id, current_user.id, db)
    comments = db.query(Comment).filter(Comment.task_id == task_id).all()
    return [{"id": c.id, "text": c.text, "user_id": c.user_id, "created_at": str(c.created_at)} for c in comments]


@router.post("/{workspace_id}/tasks/{task_id}/comments")
def add_comment(workspace_id: int, task_id: int, req: CommentCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _assert_member(workspace_id, current_user.id, db)
    comment = Comment(task_id=task_id, user_id=current_user.id, text=req.text)
    db.add(comment)
    db.commit()
    return {"id": comment.id, "text": comment.text}


# ─── Helpers ─────────────────────────────────────────────────────────────── #
def _assert_member(workspace_id: int, user_id: int, db: Session):
    m = db.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == workspace_id,
        WorkspaceMember.user_id == user_id,
    ).first()
    if not m:
        raise HTTPException(status_code=403, detail="Not a member")

def _assert_role(workspace_id: int, user_id: int, min_role: str, db: Session):
    hierarchy = {"viewer": 0, "analyst": 1, "admin": 2}
    m = db.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == workspace_id,
        WorkspaceMember.user_id == user_id,
    ).first()
    if not m or hierarchy.get(m.role, -1) < hierarchy.get(min_role, 99):
        raise HTTPException(status_code=403, detail=f"Role '{min_role}' required")

def _task_dict(t: Task) -> dict:
    return {
        "id":          t.id,
        "title":       t.title,
        "description": t.description,
        "status":      t.status,
        "assignee_id": t.assignee_id,
        "due_date":    str(t.due_date) if t.due_date else None,
        "created_at":  str(t.created_at),
    }
