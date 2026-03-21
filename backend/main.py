from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from app.routes.routes        import router as main_router
from app.routes.auth          import router as auth_router
from app.routes.collaboration  import router as collab_router
from app.db import Base, engine

# Create all tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title       = "AURA Business Intelligence API",
    description = "Enterprise AI Platform — Neural Network + Analytics + Market Intel",
    version     = "2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins     = ["*"],
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

app.include_router(auth_router,   prefix="/api/v1")
app.include_router(main_router,   prefix="/api/v1")
app.include_router(collab_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "AURA Intelligence Platform is running", "version": "2.0.0"}

@app.get("/health")
def health():
    return {"status": "healthy"}
