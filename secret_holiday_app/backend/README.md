# Secret Holiday Backend

FastAPI backend for photo uploads (S3) and Firebase authentication.

## Quick Start

```bash
# Setup
python -m venv venv
source venv/Scripts/activate   # Windows
pip install -r requirements.txt
cp .env.example .env           # Then edit with your credentials

# Run
uvicorn app.main:app --reload
```

**Server:** http://localhost:8000 | **API Docs:** http://localhost:8000/docs

---

## Environment Variables

Copy `.env.example` to `.env` and fill in:

| Variable | Description |
|----------|-------------|
| `SECRET_KEY` | Run: `python -c "import secrets; print(secrets.token_urlsafe(32))"` |
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings |
| `AWS_ACCESS_KEY_ID` | AWS IAM credentials |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM credentials |
| `AWS_S3_BUCKET` | Your S3 bucket name |
| `AWS_REGION` | e.g., `eu-west-2` |

**Firebase Service Account:** Download from Firebase Console → Project Settings → Service Accounts → Generate New Private Key. Save as `credentials/firebase-service-account.json`.

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/upload/photo` | Upload photo to S3 |
| `GET` | `/photos/url?key=...` | Get fresh presigned URL for a photo |
| `POST` | `/photos/urls` | Get multiple presigned URLs (batch) |
| `GET` | `/admin/stats` | View data statistics |
| `POST` | `/admin/cleanup-all` | Delete all data (DEBUG mode only) |

All endpoints except `/health` require Firebase auth: `Authorization: Bearer <token>`

---

## Data Cleanup (Development Only)

⚠️ **Destructive - cannot be undone!**

```bash
# Delete groups, trips, memories, activities, and S3 files (keep users)
python scripts/cleanup_all_data.py

# Delete EVERYTHING including user documents
python scripts/cleanup_all_data.py --all
```

**Requirements:**
- Server must be running (`uvicorn app.main:app --reload`)
- `DEBUG=True` in `.env`

**What gets deleted:**
- All groups and their subcollections (trips, memories, activities)
- All files in S3 bucket
- User documents (only with `--all` flag)

---

## Project Structure

```
backend/
├── app/
│   ├── main.py          # FastAPI app
│   ├── config.py        # Environment config
│   ├── routers/
│   │   ├── upload.py    # Photo upload endpoints
│   │   ├── photos.py    # Presigned URL endpoints
│   │   └── admin.py     # Cleanup & stats
│   └── services/
│       ├── auth.py      # Firebase auth
│       ├── s3.py        # AWS S3 operations
│       └── firebase.py  # Firestore access
├── scripts/
│   └── cleanup_all_data.py
├── credentials/         # Firebase service account (gitignored)
├── .env                 # Your secrets (gitignored)
└── .env.example         # Template (committed)
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `ModuleNotFoundError` | Activate venv: `source venv/Scripts/activate` |
| Firebase auth fails | Check `credentials/firebase-service-account.json` exists |
| S3 upload fails | Verify AWS credentials in `.env` |
| Android can't connect | Use `http://10.0.2.2:8000` instead of localhost |


LOMIPIC576@EMAXASP.COM - Email
RedWine99