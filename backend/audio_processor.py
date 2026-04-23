import librosa
import numpy as np
import re
from faster_whisper import WhisperModel
from faster_whisper.audio import decode_audio
from dataclasses import dataclass
from typing import Optional

# Load once at startup — "base" is ~150MB, fast on CPU.
# Swap to "small" or "medium" for better accuracy at the cost of speed.
_model: Optional[WhisperModel] = None

FILLER_WORDS = re.compile(
    r'\b(um|uh|er|ah|like|you know|basically|literally|actually|so|right)\b',
    re.IGNORECASE
)


def get_whisper_model() -> WhisperModel:
    global _model
    if _model is None:
        _model = WhisperModel("base", device="cpu", compute_type="int8")
    return _model


@dataclass
class AudioMetrics:
    transcript: str
    duration_s: float
    words_per_minute: float
    pause_ratio: float        # 0–1, proportion of near-silence
    filler_count: int
    volume_variance: float    # normalised RMS std dev


def transcribe(audio_path: str) -> tuple[str, float]:
    """Return (transcript, duration_seconds) using faster-whisper."""
    model = get_whisper_model()
    segments, info = model.transcribe(audio_path, beam_size=5)
    transcript = " ".join(seg.text.strip() for seg in segments)
    return transcript, info.duration


def extract_metrics(audio_path: str) -> AudioMetrics:
    """Run STT + acoustic analysis in one call."""
    transcript, duration_s = transcribe(audio_path)

    # ── Acoustic features via librosa ──────────────────────────────────────
    # PyAV (faster-whisper) natively decodes any format perfectly without ffmpeg.exe natively installed
    y = decode_audio(audio_path)
    sr = 16000

    # Pace: words per minute
    word_count = len(transcript.split())
    wpm = (word_count / duration_s) * 60 if duration_s > 0 else 0

    # Pause ratio: frames where RMS energy is below 5% of peak
    frame_length = int(sr * 0.025)   # 25ms frames
    hop_length   = int(sr * 0.010)   # 10ms hop
    rms = librosa.feature.rms(y=y, frame_length=frame_length, hop_length=hop_length)[0]
    threshold    = rms.max() * 0.05
    pause_ratio  = float(np.mean(rms < threshold))

    # Volume variance: how dynamic is the speech?
    volume_variance = float(np.std(rms) / (rms.mean() + 1e-9))

    # Filler words
    filler_count = len(FILLER_WORDS.findall(transcript))

    return AudioMetrics(
        transcript=transcript,
        duration_s=duration_s,
        words_per_minute=round(wpm, 1),
        pause_ratio=round(pause_ratio, 3),
        filler_count=filler_count,
        volume_variance=round(volume_variance, 3),
    )
