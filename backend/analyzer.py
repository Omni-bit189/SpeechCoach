import json
import os
import ollama
from audio_processor import AudioMetrics

OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma4:31b-cloud")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

def build_system_prompt(has_topic: bool) -> str:
    base = """You are an expert speech therapist and communication coach.
Analyse the provided speech transcript and acoustic metrics, then return a JSON
object with EXACTLY this structure — no markdown fences, no extra keys:

{
  "speech_score": <integer 0-100>,"""

    if has_topic:
        base += """
  "relevancy_score": <integer 0-100>,"""

    base += """
  "strengths": [
    {"title": "<short title>", "detail": "<1-2 sentence explanation>"}
  ],
  "weaknesses": [
    {"title": "<short title>", "detail": "<1-2 sentence explanation>"}
  ],
  "solutions": [
    {
      "weakness_title": "<matches a weakness title above>",
      "exercise": "<concrete, actionable exercise the speaker can practice today>",
      "duration": "<e.g. '5 minutes daily'>"
    }
  ]
}

Provide 2-4 items in each of strengths, weaknesses, and solutions.
Be specific, empathetic, and constructive. Base all observations on the data given."""
    return base


def build_user_prompt(metrics: AudioMetrics, topic: str = None) -> str:
    prompt = f"Analyse the following speech session:\n"
    if topic:
        prompt += f"THE SPEAKER CHOSE THIS TOPIC: {topic}\nEvaluate if their speech was relevant to this topic.\n\n"
        
    prompt += f"""TRANSCRIPT:
\"\"\"{metrics.transcript}\"\"\"

ACOUSTIC METRICS:
- Duration: {metrics.duration_s:.1f} seconds
- Speaking pace: {metrics.words_per_minute:.0f} words per minute (ideal range: 120-160 wpm)
- Silence / pause ratio: {metrics.pause_ratio:.1%} of total time
- Filler word count: {metrics.filler_count} occurrences
- Volume variance (expressiveness): {metrics.volume_variance:.3f} (higher = more dynamic)

Return the JSON object now."""
    return prompt


def analyse_speech(metrics: AudioMetrics, topic: str = None) -> dict:
    """Send metrics to Ollama and parse the structured feedback."""
    client = ollama.Client(host=OLLAMA_HOST)

    response = client.chat(
        model=OLLAMA_MODEL,
        messages=[
            {"role": "system", "content": build_system_prompt(bool(topic))},
            {"role": "user", "content": build_user_prompt(metrics, topic)},
        ],
        format="json",
    )
    raw = response["message"]["content"].strip()

    # Strip accidental markdown fences if the model adds them
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    return json.loads(raw)


def generate_topics() -> list:
    """Generate 3 interesting topics for the user to practice speaking about."""
    client = ollama.Client(host=OLLAMA_HOST)
    
    prompt = """Generate 3 interesting, distinct scenarios or topics for a user to practice their impromptu speaking skills. 
Return ONLY a JSON array of objects with EXACTLY this structure:
[
  {
    "title": "<short engaging topic title>",
    "tip": "<1 short sentence offering a tip on what to focus on when speaking about this topic>"
  }
]"""

    response = client.chat(
        model=OLLAMA_MODEL,
        messages=[{"role": "user", "content": prompt}],
        format="json",
    )
    raw = response["message"]["content"].strip()

    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
            
    fallbacks = [
        {"title": "Your favorite trip", "tip": "Focus on descriptive words and sensory details."},
        {"title": "A skill you learned recently", "tip": "Explain the process step by step clearly."},
        {"title": "A moment that changed you", "tip": "Use emotional language and reflect on the impact."},
    ]

    try:
        parsed = json.loads(raw)
        topics = []
        if isinstance(parsed, dict):
            for v in parsed.values():
                if isinstance(v, list):
                    topics = v
                    break
            if not topics and "title" in parsed:
                topics = [parsed]
        elif isinstance(parsed, list):
            topics = parsed

        # Ensure exactly 3 topics
        topics = [t for t in topics if isinstance(t, dict) and "title" in t][:3]
        while len(topics) < 3:
            topics.append(fallbacks[len(topics)])
        return topics
    except:
        return fallbacks

def generate_general_review(metrics_list: list) -> dict:
    client = ollama.Client(host=OLLAMA_HOST)
    
    prompt = f"""You are an expert speech therapist generating a dashboard summary.
The user has recorded {len(metrics_list)} recent sessions. Below are some aggregate stats:
{metrics_list}

Based on this trend, return a JSON object with EXACTLY this structure:
{{
  "general_review": "<2-3 engaging, conversational paragraphs summarizing their overall progress, strengths, and areas needed for improvement>",
  "strengths": ["<short string>", "..."],
  "weaknesses": ["<short string>", "..."],
  "solutions": [
    {{
      "weakness_title": "<matching above weakness>",
      "exercise": "<actionable exercise>",
      "duration": "<e.g. 5 mins>"
    }}
  ]
}}
Provide exactly 3 items in strengths, weaknesses, and solutions.
"""

    response = client.chat(
        model=OLLAMA_MODEL,
        messages=[{"role": "user", "content": prompt}],
        format="json",
    )
    raw = response["message"]["content"].strip()

    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
            
    try:
        parsed = json.loads(raw)
        return parsed
    except:
        return {
            "general_review": "Keep practicing! We don't have enough complex data to generate a deep summary yet.",
            "strengths": ["Consistent effort"],
            "weaknesses": ["Pacing"],
            "solutions": [{"weakness_title": "Pacing", "exercise": "Read a book out loud slowly.", "duration": "5 min"}]
        }
