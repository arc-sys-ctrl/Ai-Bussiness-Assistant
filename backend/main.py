from fastapi import FastAPI
from app.routes.routes import router as main_router
from app.routes.auth import router as auth_router
from app.db import Base, engine

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="AI Business Assistant")

app.include_router(auth_router, prefix="/api/v1")
app.include_router(main_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "AI Assistant running"}
