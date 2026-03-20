from fastapi import FastAPI
from app.routes.routes import router as main_router
from app.routes.auth import router as auth_router

app = FastAPI(title="AI Business Assistant")

app.include_router(main_router)
app.include_router(auth_router)

@app.get("/")
def root():
    return {"message": "AI Assistant running"}
