import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "")

# Fall back to SQLite if no DATABASE_URL is configured or it still has the
# Docker-compose placeholder values (useful for local development).
_is_placeholder = (
    not DATABASE_URL
    or "user:password@db" in DATABASE_URL
    or "your_" in DATABASE_URL
)
if _is_placeholder:
    _db_path = os.path.join(os.path.dirname(__file__), "..", "aura_local.db")
    DATABASE_URL = f"sqlite:///{os.path.abspath(_db_path)}"
    print(f"[AURA] Using local SQLite DB: {DATABASE_URL}")

# SQLite needs check_same_thread=False; other DBs don't need it
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
