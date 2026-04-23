import json
import os
import shutil
import uuid
import traceback
from pathlib import Path

from fastapi import FastAPI, File, Form, UploadFile, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session as DBSession

from database import create_tables, get_db, Session as SessionModel
from audio_processor import extract_metrics
from analyzer import analyse_speech, generate_topics, generate_general_review

# ── Setup ───────────────────────────────────────────────────────────────────
AUDIO_DIR = Path("audio_files")
AUDIO_DIR.mkdir(exist_ok=True)

app = FastAPI(title="SpeechCoach API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup():
    create_tables()


# ── Pydantic schemas ────────────────────────────────────────────────────────
class FeedbackItem(BaseModel):
    title: str
    detail: str

class SolutionItem(BaseModel):
    weakness_title: str
    exercise: str
    duration: str

class SessionResponse(BaseModel):
    id: int
    user_id: str
    duration_s: float
    transcript: str
    words_per_minute: float
    pause_ratio: float
    filler_count: int
    volume_variance: float
    speech_score: float | None = None
    relevancy_score: float | None = None
    overall_score: float
    topic: str | None = None
    strengths: list[FeedbackItem]
    weaknesses: list[FeedbackItem]
    solutions: list[SolutionItem]
    created_at: str

    class Config:
        from_attributes = True


# ── Helpers ─────────────────────────────────────────────────────────────────
def _session_to_response(s: SessionModel) -> SessionResponse:
    return SessionResponse(
        id=s.id,
        user_id=s.user_id,
        duration_s=s.duration_s,
        transcript=s.transcript,
        words_per_minute=s.words_per_minute,
        pause_ratio=s.pause_ratio,
        filler_count=s.filler_count,
        volume_variance=s.volume_variance,
        speech_score=s.speech_score,
        relevancy_score=s.relevancy_score,
        overall_score=s.overall_score,
        topic=s.topic,
        strengths=[FeedbackItem(**i) for i in json.loads(s.strengths)],
        weaknesses=[FeedbackItem(**i) for i in json.loads(s.weaknesses)],
        solutions=[SolutionItem(**i) for i in json.loads(s.solutions)],
        created_at=s.created_at.isoformat(),
    )


# ── Routes ───────────────────────────────────────────────────────────────────
@app.post("/sessions/analyse", response_model=SessionResponse)
async def analyse_session(
    audio: UploadFile = File(...),
    user_id: str = Form(default="anonymous"),
    topic: str | None = Form(default=None),
    db: DBSession = Depends(get_db),
):
    """
    Accept an audio file, run STT + acoustic analysis + Ollama feedback,
    persist everything to SQLite, and return the full report.
    """
    # 1. Save audio locally
    ext = Path(audio.filename).suffix or ".wav"
    filename = f"{uuid.uuid4()}{ext}"
    audio_path = AUDIO_DIR / filename
    with audio_path.open("wb") as f:
        shutil.copyfileobj(audio.file, f)

    try:
        # 2. Extract transcript + acoustic metrics
        metrics = extract_metrics(str(audio_path))

        # 3. Ollama analysis
        feedback = analyse_speech(metrics, topic)
        
        # Calculate scores with penalties
        base_speech = feedback.get("speech_score", 0)
        filler_penalty = metrics.filler_count * 2.5
        pause_penalty = max(0, metrics.pause_ratio - 0.15) * 50
        
        speech_score = max(0, min(100, base_speech - filler_penalty - pause_penalty))
        relevancy_score = feedback.get("relevancy_score") if topic else None
        
        if topic and relevancy_score is not None:
            overall_score = (speech_score + relevancy_score) / 2
        else:
            overall_score = speech_score

        # 4. Persist
        session = SessionModel(
            user_id=user_id,
            audio_path=str(audio_path),
            duration_s=metrics.duration_s,
            transcript=metrics.transcript,
            words_per_minute=metrics.words_per_minute,
            pause_ratio=metrics.pause_ratio,
            filler_count=metrics.filler_count,
            volume_variance=metrics.volume_variance,
            speech_score=speech_score,
            relevancy_score=relevancy_score,
            overall_score=overall_score,
            topic=topic,
            strengths=json.dumps(feedback.get("strengths", [])),
            weaknesses=json.dumps(feedback.get("weaknesses", [])),
            solutions=json.dumps(feedback.get("solutions", [])),
        )
        db.add(session)
        db.commit()
        db.refresh(session)

        return _session_to_response(session)

    except Exception as e:
        traceback.print_exc()
        audio_path.unlink(missing_ok=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/sessions/{session_id}", response_model=SessionResponse)
def get_session(session_id: int, db: DBSession = Depends(get_db)):
    s = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Session not found")
    return _session_to_response(s)

@app.delete("/sessions/{session_id}")
def delete_session(session_id: int, db: DBSession = Depends(get_db)):
    s = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Remove physical audio file
    if s.audio_path:
        Path(s.audio_path).unlink(missing_ok=True)

    db.delete(s)
    db.commit()
    return {"status": "deleted"}


@app.get("/sessions", response_model=list[SessionResponse])
def list_sessions(user_id: str = "anonymous", db: DBSession = Depends(get_db)):
    sessions = (
        db.query(SessionModel)
        .filter(SessionModel.user_id == user_id)
        .order_by(SessionModel.created_at.desc())
        .limit(20)
        .all()
    )
    return [_session_to_response(s) for s in sessions]


@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/topics")
def get_topics():
    topics = generate_topics()
    return {"topics": topics}

@app.get("/dashboard/review")
def get_dashboard_review(user_id: str = "anonymous", db: DBSession = Depends(get_db)):
    sessions = (
        db.query(SessionModel)
        .filter(SessionModel.user_id == user_id)
        .order_by(SessionModel.created_at.desc())
        .limit(3)
        .all()
    )
    if not sessions:
        return {
            "general_review": "You don't have any sessions yet! Record a session to receive your personalized dashboard insights.",
            "strengths": [],
            "weaknesses": [],
            "solutions": []
        }
    
    metrics_list = []
    for s in sessions:
        metrics_list.append({
            "wpm": s.words_per_minute,
            "pause_ratio": s.pause_ratio,
            "fillers": s.filler_count,
            "overall_score": s.overall_score
        })
        
    review = generate_general_review(metrics_list)
    return review
