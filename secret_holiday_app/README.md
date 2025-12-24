# Secret Holiday App

A Flutter app for planning group holidays with friends and family. Create groups, plan trips together, and share memories.

## Features

- **Authentication**: Email/password sign-up and login with Firebase Auth
- **Groups**: Create or join groups with invite codes
- **Trips**: Plan trips with dates, locations, budgets, and itineraries
- **Timeline**: View past, current, and upcoming trips
- **Memories**: Share photos and videos from your trips (coming soon)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10+)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for Firebase setup)
- A Firebase project with:
  - Authentication (Email/Password enabled)
  - Cloud Firestore
  - Storage (optional, for media)

## Getting Started

### 1. Clone and Install Dependencies

```bash
cd secret_holiday_app
flutter pub get
```

### 2. Configure Firebase

This project uses Firebase. You'll need to set up your own Firebase project:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password Authentication**
3. Create a **Cloud Firestore** database
4. Add your platforms (iOS, Android, Web) and download config files
5. Run `flutterfire configure` to generate `firebase_options.dart`

### 3. Run the App

```bash
# Run in debug mode
flutter run

# Run on a specific device
flutter run -d chrome      # Web
flutter run -d emulator    # Android Emulator
flutter run -d iphone      # iOS Simulator (macOS only)
```

### 4. Run with Hot Reload (Development)

```bash
flutter run --debug
```

Then press `r` in the terminal for hot reload, or `R` for hot restart.

## Project Structure

```
lib/
├── core/                    # Shared utilities and config
│   ├── config/              # Firebase options
│   ├── constants/           # App & route constants
│   ├── error/               # Error handling
│   ├── presentation/        # Shared widgets
│   ├── router/              # GoRouter configuration
│   ├── theme/               # App theme & colors
│   └── utils/               # Utilities & extensions
├── features/                # Feature modules
│   ├── auth/                # Authentication
│   ├── chat/                # Group chat (coming soon)
│   ├── groups/              # Group management
│   ├── home/                # Main scaffold & drawer
│   ├── map/                 # Map view (coming soon)
│   ├── planning/            # AI planning (coming soon)
│   ├── profile/             # User profile
│   └── timeline/            # Trips & itineraries
└── main.dart                # App entry point
```

## Build for Production

```bash
# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Backend Setup (Optional)

For photo uploads to AWS S3, you need the Python FastAPI backend.

**→ See [backend/README.md](backend/README.md) for full setup instructions.**

Quick start:
```bash
cd backend
python -m venv venv && source venv/Scripts/activate
pip install -r requirements.txt
cp .env.example .env  # Then edit with your credentials
uvicorn app.main:app --reload
```

API docs: http://localhost:8000/docs

## Troubleshooting

**Firebase not initialized**: Make sure you've run `flutterfire configure` and have `firebase_options.dart`.

**Android emulator can't connect to backend**: Use `10.0.2.2:8000` instead of `localhost:8000` on Android emulators.

**iOS build fails**: Run `cd ios && pod install` to install CocoaPods dependencies.

## License

Private - All rights reserved
