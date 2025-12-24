# Secret Holiday Backend

FastAPI backend for the Secret Holiday app. Handles photo uploads to AWS S3 with Firebase authentication.

## Quick Start

```bash
# 1. Set up Python virtual environment
python -m venv venv
source venv/Scripts/activate  # Windows Git Bash
# OR: .\venv\Scripts\Activate.ps1  # Windows PowerShell
# OR: source venv/bin/activate     # macOS/Linux

# 2. Install dependencies
pip install -r requirements.txt

# 3. Create environment file
cp .env.example .env
# Then edit .env with your actual credentials (see below)

# 4. Run the server
uvicorn app.main:app --reload
```

Server runs at http://localhost:8000 | API docs at http://localhost:8000/docs

---

## Configuration

### Why `.env.example`?

- **`.env.example`** = Template file that gets committed to Git (safe, no secrets)
- **`.env`** = Your actual secrets (NEVER committed, in .gitignore)

You copy the example, then fill in real values. This way:
- New developers know what variables are needed
- No one accidentally commits passwords to Git

### Required Environment Variables

| Variable | Description | How to Get It |
|----------|-------------|---------------|
| `SECRET_KEY` | Server security key | Run: `python -c "import secrets; print(secrets.token_urlsafe(32))"` |
| `FIREBASE_PROJECT_ID` | Your Firebase project | Firebase Console → Project Settings |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Firebase service account JSON | See below |
| `AWS_ACCESS_KEY_ID` | AWS access key | AWS Console → IAM → Security Credentials |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | AWS Console → IAM → Security Credentials |
| `AWS_S3_BUCKET` | S3 bucket name | AWS Console → S3 |
| `AWS_REGION` | AWS region (e.g., `eu-west-2`) | Where you created your S3 bucket |

### Getting Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → **Project Settings** (gear icon)
3. **Service Accounts** tab
4. Click **Generate New Private Key**
5. Save as `credentials/firebase-service-account.json`

---

## Project Structure

```
backend/
├── .env.example          # Environment template (commit this)
├── .env                   # Your secrets (NEVER commit)
├── .gitignore            # Ignores .env, credentials/, venv/
├── requirements.txt      # Python dependencies
├── README.md             # This file
├── credentials/          # Service account keys (gitignored)
│   └── firebase-service-account.json
└── app/
    ├── __init__.py
    ├── main.py           # FastAPI app entry point
    ├── config.py         # Environment variable loading
    ├── routers/
    │   ├── __init__.py
    │   └── upload.py     # Photo upload endpoints
    └── services/
        ├── __init__.py
        ├── auth.py       # Firebase token verification
        └── s3.py         # AWS S3 operations
```

---

## API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/` | Health check | No |
| GET | `/health` | Detailed health status | No |
| POST | `/upload/photo` | Upload a photo to S3 | Yes (Firebase token) |
| GET | `/upload/photos/{trip_id}` | List photos for a trip | Yes |
| DELETE | `/upload/photo/{photo_id}` | Delete a photo | Yes |

### Authentication

All protected endpoints require a Firebase ID token in the Authorization header:

```
Authorization: Bearer <firebase-id-token>
```

Get this token from your Flutter app using `FirebaseAuth.instance.currentUser?.getIdToken()`.

---

## Development

```bash
# Run with auto-reload
uvicorn app.main:app --reload --port 8000

# Run tests
pytest

# Format code
black app/

# Type checking
mypy app/
```

### Connecting from Android Emulator

Android emulators can't use `localhost`. Use `10.0.2.2` instead:

```dart
// In your Flutter app
final apiUrl = Platform.isAndroid 
    ? 'http://10.0.2.2:8000' 
    : 'http://localhost:8000';
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `ModuleNotFoundError` | Activate venv: `source venv/Scripts/activate` |
| `FileNotFoundError: .env` | Copy example: `cp .env.example .env` |
| Firebase auth fails | Check `GOOGLE_APPLICATION_CREDENTIALS` path |
| S3 upload fails | Verify AWS credentials and bucket permissions |
| CORS errors | Check `ALLOWED_ORIGINS` in `.env` matches your app URL |
