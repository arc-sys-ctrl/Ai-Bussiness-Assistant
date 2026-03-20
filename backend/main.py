from fastapi import FastAPI
from app.routes.routes import router

app = FastAPI(title="AI Business Assistant")

app.include_router(router)

@app.get("/")
def root():
    return {"message": "AI Assistant running"}
