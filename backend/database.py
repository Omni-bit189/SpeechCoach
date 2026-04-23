from sqlalchemy import create_engine, Column, Integer, String, Float, Text, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os

DATABASE_URL = "sqlite:///./speech_therapy.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class Session(Base):
    __tablename__ = "sessions"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(String, index=True)
    audio_path  = Column(String)
    duration_s  = Column(Float)
    transcript  = Column(Text)
    created_at  = Column(DateTime, default=datetime.utcnow)

    # Voice metrics
    words_per_minute = Column(Float)
    pause_ratio      = Column(Float)
    filler_count     = Column(Integer)
    volume_variance  = Column(Float)

    # AI feedback (stored as JSON strings)
    strengths    = Column(Text)   # JSON array
    weaknesses   = Column(Text)   # JSON array
    solutions    = Column(Text)   # JSON array
    speech_score = Column(Float)
    relevancy_score = Column(Float)
    overall_score = Column(Float)
    topic        = Column(String)


def create_tables():
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
