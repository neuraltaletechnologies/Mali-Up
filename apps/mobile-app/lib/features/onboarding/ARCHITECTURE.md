# Mali Up Onboarding Architecture

This document describes the current Firebase-only onboarding flow used by the mobile app.

## Overview

- Firebase Auth handles identity and PIN-based sign-in.
- Cloud Firestore stores user, business, and invite state.
- The app no longer depends on a custom auth backend for onboarding lookup or recovery.
- PIN recovery uses Firebase Auth password reset.

## Flow

```text
Screen 1: Welcome + Language
Screen 2: Phone Entry
Screen 3: Returning User / Team Member / New User detection
Screen 4A: Returning User PIN Login
Screen 4B: Team Member Setup
Screen 4C: New User Personal Info
Screen 5: Business Details
Screen 6: PIN Setup
Screen 7: Success
```

## Key Data Sources

- `users` collection: returning user lookup and profile state
- `pendingInvites` collection: pending team-member onboarding
- `collectionGroup('team_members')`: legacy team-member lookup
- tenant-scoped `businesses` collections: active business context

## Repository Responsibilities

### `lookupByPhone(phone)`

- Queries Firestore directly
- Returns `ReturningUser`, `TeamMemberPending`, or `NewUser`
- No network hop to a custom auth service

### `sendPinRecovery(phone)`

- Derives the Firebase Auth email from the phone number
- Calls `FirebaseAuth.sendPasswordResetEmail`

### `createNewUserAccount(...)`

- Creates or signs in the Firebase Auth account
- Used for new owner onboarding

## Notes

- The app keeps the onboarding state inside Riverpod.
- The mobile app is now aligned with Firebase-only production deployment.

Part of the [Mali Up](../../../README.md) suite.
