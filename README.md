# 🎙️ SpeechCoach

An AI-powered speech therapy and communication coaching application. 

SpeechCoach allows users to record their speaking sessions and uses local AI models to analyze acoustic metrics (like speaking pace, pause ratios, and filler words) to provide actionable, personalized feedback to improve their communication skills.

## ✨ Features

- **Audio Recording**: Record impromptu speech sessions directly from the app.
- **Acoustic Analysis**: Automatically calculates Words Per Minute (WPM), pause ratios, filler word counts, and volume variance.
- **AI-Powered Feedback**: Uses local LLMs (via Ollama) to generate a personalized evaluation, including strengths, weaknesses, and actionable exercises.
- **Topic Generation**: Provides users with dynamically generated interesting topics to practice speaking.
- **Progress Dashboard**: Tracks your historical performance and gives a comprehensive review of your overall progress.
- **Privacy First**: All audio processing and AI feedback are done locally using your own hardware! No data is sent to the cloud.

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Web & Mobile ready)
- **Backend**: [FastAPI](https://fastapi.tiangolo.com/) (Python)
- **Database**: SQLite
- **AI Inference**: [Ollama](https://ollama.com/) (Local LLMs)
- **Audio Processing**: `librosa` and custom audio metrics extraction

## 🚀 Getting Started

### Prerequisites

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Install [Python 3.9+](https://www.python.org/downloads/).
3. Install [Ollama](https://ollama.com/) and download your preferred model (e.g., `llama3.2`).

### 1. Start the Backend Server

```bash
cd backend

# Create a virtual environment (optional but recommended)
python -m venv venv

# Activate the virtual environment (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the FastAPI server
uvicorn main:app --reload --port 8000
```

*Note: Make sure your Ollama service is running locally on port 11434.*

### 2. Run the Flutter Frontend

Open a new terminal window in the root `speech_coach` directory:

```bash
# Get dependencies
flutter pub get

# Run the app (e.g., on Chrome for web testing)
flutter run -d chrome
```

## 📂 Project Structure

- `/lib`: Flutter frontend source code (UI screens, models, and API services).
- `/backend`: Python backend containing the FastAPI server, SQLite database, and audio processing logic.

## 📝 License

This project is licensed under the MIT License.
