# Firebase Setup Guide for Mali UP Mobile App

## Overview
The Mali UP app uses Firebase for authentication, data storage, and notifications. This guide explains how to properly configure Firebase credentials for development and production.

## 🔐 Security Notes

**IMPORTANT:** 
- Never commit real Firebase credentials to GitHub
- `lib/firebase_options.dart` is in `.gitignore` and should NOT be committed
- Each developer/environment needs their own Firebase project
- Use the provided template (`firebase_options.template.dart`) for reference only

## 📋 Setup Steps

### 1. Prerequisites
```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Ensure you have Firebase CLI installed
npm install -g firebase-tools
# or
brew install firebase-cli
```

### 2. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a new project" → Name it (e.g., "Mali UP Dev" or "Mali UP Production")
3. Enable Google Analytics (optional)
4. Create the project

### 3. Configure Firebase for Flutter
```bash
# From the mobile-app directory
cd apps/mobile-app

# Run FlutterFire configuration
flutterfire configure

# Select your Firebase project from the list
# Choose Android and iOS when prompted
# FlutterFire will automatically generate lib/firebase_options.dart
```

### 4. Enable Required Firebase Services

#### Authentication
- Go to Firebase Console → Authentication
- Enable **Phone Number** sign-in method
- Add test phone numbers for development (optional)

#### Firestore Database
- Go to Firestore Database
- Create database in **production mode**
- Set security rules (see Security Rules section below)
- Create collections: `users`, `tenants`, `personal_accounts`, `email_otp_auth`, `mail`

#### Cloud Messaging (for notifications)
- Go to Cloud Messaging
- Generate Server Key (needed for backend services)

#### Email Extension (for email OTP)
- Install [Firebase Trigger Email](https://firebase.google.com/docs/extensions/official/firestore-send-email) extension
- Configure to send emails from `mail` collection

### 5. Update Environment Variables (Optional)
Create `.env.local` in `apps/mobile-app/`:
```env
FIREBASE_PROJECT_ID=mali-up-dev
FIREBASE_API_KEY=YOUR_API_KEY
```

### 6. Verify Setup
```bash
# Build and run the app
flutter run

# Test phone authentication with your test number
```

---

## 🔒 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - only user can read/write own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Tenants collection - owner and staff can access
    match /tenants/{tenantId} {
      allow read, write: if request.auth.uid in get(/databases/$(database)/documents/tenants/$(tenantId)).data.staffUids
                            || request.auth.uid == get(/databases/$(database)/documents/tenants/$(tenantId)).data.ownerUid;
    }

    // Personal accounts
    match /personal_accounts/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Email OTP - allow write for unauthenticated (signup flow)
    match /email_otp_auth/{document=**} {
      allow create, write: if true;
      allow read, write: if request.auth != null;
    }

    // Mail collection - for email sending trigger
    match /mail/{document=**} {
      allow create: if true;
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📱 Android Configuration

FlutterFire will auto-configure, but verify:
1. `android/app/build.gradle` has Google Play Services
2. `android/build.gradle` has Firebase dependencies
3. `google-services.json` is in `android/app/` (auto-added by FlutterFire)

## 🍎 iOS Configuration

FlutterFire will auto-configure, but verify:
1. `ios/Runner/GoogleService-Info.plist` exists (auto-added by FlutterFire)
2. `ios/Podfile` has Firebase pods
3. `ios/Runner/Runner.xcworkspace` (not `.xcodeproj`) is opened in Xcode

---

## 🚀 Production Deployment

1. **Create a separate Firebase project** for production
2. Run `flutterfire configure` and **select the production project**
3. This updates `lib/firebase_options.dart` with production credentials
4. Update app signing credentials in `android/app/build.gradle` and iOS
5. Never commit production `firebase_options.dart` to GitHub

---

## 🔧 Troubleshooting

### "Firebase not initialized"
- Ensure `Firebase.initializeApp()` is called in `main.dart` before `runApp()`
- Check that `firebase_options.dart` has valid credentials

### "Permission Denied" errors
- Review Firestore Security Rules (see above)
- Ensure user is authenticated
- Check user UID matches rules

### "SMS code not arriving"
- Ensure phone number includes country code (+255 for Tanzania)
- Check Firebase has phone number auth enabled
- Verify test numbers in Firebase Console

### "FlutterFire CLI not found"
- Run: `dart pub global activate flutterfire_cli`
- Ensure `~/.pub-cache/bin` is in your PATH

---

## 📚 Useful Links
- [Firebase Console](https://console.firebase.google.com)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite) (for local testing)
