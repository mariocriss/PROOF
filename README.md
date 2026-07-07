# PROOF — Physical Identity Platform

PROOF is a Physical Identity Platform. It is **not** a workout tracker.

The core product loop:

**Identity → Skill → Proof → Proof Stack → Confidence → Timeline → Passport**

## Stack

- Flutter 3.x
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Riverpod + go_router

## Setup

### 1. Firebase project

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Enable **Email/Password** authentication
3. Create a **Cloud Firestore** database
4. Enable **Firebase Storage**
5. Deploy security rules: `firebase deploy --only firestore:rules`

### 2. Connect Flutter to Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This replaces the placeholder `lib/firebase_options.dart` and `android/app/google-services.json`.

### 3. Run on Android emulator

```bash
flutter pub get
flutter run
```

Ensure an Android emulator is running (`flutter emulators --launch <id>`).

## Project structure

```
lib/
  core/           # theme, constants, router, utils
  features/
    auth/         # sign in / sign up
    identity/     # create & edit physical identity, profile
    skills/       # register physical capabilities
    proofs/       # document evidence + proof stack
    timeline/     # identity history
    passport/     # public physical passport view
  shared/
    models/       # User, PhysicalIdentity, Skill, Proof, Timeline
    services/     # Auth, Firestore, Storage
    widgets/      # shared UI components
```

## Data model

| Collection | Purpose |
|---|---|
| `users/{uid}` | Account metadata |
| `users/{uid}/identity/profile` | Physical Identity (core object) |
| `users/{uid}/skills/{id}` | Registered capabilities |
| `users/{uid}/proofs/{id}` | Documented evidence |
| `users/{uid}/timeline/{id}` | Identity history events |
| `handles/{handle}` | Public handle → userId lookup |

## What this MVP includes

- Email/password authentication
- Physical identity creation with unique handle
- Profile and edit profile screens
- Skills, proofs, proof stack with confidence labels
- Timeline of identity events
- Public passport view

## What is intentionally excluded

- Workouts, programs, calorie tracking
- Apple Health integration
- AI features
- Complex rankings
