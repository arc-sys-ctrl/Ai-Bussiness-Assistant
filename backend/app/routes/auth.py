from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["Authentication"])

class UserAuth(BaseModel):
    email: str
    password: str

@router.post("/signup")
def signup(user: UserAuth):
    # Placeholder: In a real app, save to database with hashed password
    return {"message": "User created successfully", "user": user.email}

@router.post("/login")
def login(user: UserAuth):
    # Placeholder: Verify credentials and return JWT
    if user.email == "admin@example.com" and user.password == "admin":
        return {"access_token": "fake-jwt-token", "token_type": "bearer"}
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")
