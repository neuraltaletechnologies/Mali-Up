# Mali-Up Onboarding Flow Redesign — Complete Architecture

## Overview

A production-ready, 7-screen onboarding system built with clean architecture principles:
- **Pure Logic & State Management** — Riverpod 2.x with immutable models
- **Data Persistence** — Firebase Auth + Firestore with graceful error handling
- **Validation Layer** — Comprehensive Tanzania phone/password/PIN validation
- **Multi-Language** — English & Swahili for all 7 screens
- **Routing Guards** — GoRouter with step-prevention logic
- **Error Resilience** — OTP cooldown, retry limits, network graceful degradation

---

## 7-Screen Flow

```
Screen 1: Welcome + Language Picker (step=0)
    ↓
Screen 2: Phone Number Entry (step=1)
    ↓
Screen 3: OTP Verification (step=2)
    ↓
         ├─→ Screen 4A: Returning User Detected (step=3)
         │
         └─→ Screen 4B: New User Personal Info (step=3)
    ↓
Screen 5: Business Details + Personalized Greeting (step=4)
    ↓
Screen 6: Password + 4-Digit PIN (step=5)
    ↓
Screen 7: Success + Dashboard Entry (step=6)
    ↓
Dashboard (onboarding_complete = true)
```

---

## Core Components

### 1. **State Models** (`/models/`)

#### `OnboardingState` (freezed)
Complete immutable state for the entire flow.

**Key Fields:**
- `language` — 'en' or 'sw'
- `currentStep` — 0–7 (screen index)
- `phone`, `firstName`, `lastName`, `businessName`, `businessType`, `password`, `pin`
- `isReturningUser` — Determined after OTP lookup
- `otpCode`, `otpAttempts`, `otpInCooldown`, `otpCooldownEndTime`, `otpExpiryTime`
- `userLookupResult` — UserLookupResult (populated after phone verification)
- `errorMessage`, `otpErrorMessage`

**Helper Methods:**
- `isOtpCoolingDown` — Check if user is in cooldown
- `isOtpExpired` — Check if OTP code expired
- `isStepValid(step)` — Validate all required fields for a step
- `factory OnboardingState.initial()` — Create clean initial state

---

#### `UserLookupResult` (sealed class)

Two variants:
```dart
ReturningUser(
  userId, firstName, lastName,
  businessId, businessName, businessType, city, businessLogo
)

NewUser()
```

Returned by `OnboardingRepository.lookupByPhone()`. On Firebase errors, gracefully returns `NewUser()`.

---

#### `OtpState` (freezed)
Sub-state for OTP verification logic.

**Key Fields:**
- `code` — OTP entered
- `attempts`, `maxAttempts` (default 3)
- `isLocked`, `lockoutExpiryTime`
- `cooldownDurationSeconds` (default 30)
- `expiryTime`, `isExpired`
- `errorMessage`, `isLoading`

**Helper Methods:**
- `isCurrentlyLocked` — Check lockout status
- `canRetry` — User can attempt again
- `lockoutRemainingSec` — Seconds until unlock

---

### 2. **Validation Layer** (`domain/validators/`)

#### `OnboardingValidator`

Static methods, each returns `String?` (null = valid, string = error message):

- **`validatePhone(phone, language)`**
  - Requires Tanzania format: 9 digits after +255
  - Valid prefixes: 7, 6, 1 (Vodacom, Airtel, TTCL)
  - Example: "756123456" or "+255756123456"

- **`validateName(name, language)`**
  - Min 2 chars, only letters/spaces/hyphens
  - No numbers allowed
  - Works for first and last names

- **`validatePassword(password, language)`**
  - Min 8 chars
  - At least 1 number
  - At least 1 letter
  - (Optionally: uppercase, special chars)

- **`validatePin(pin, language)`**
  - Exactly 4 digits
  - No other characters

- **`validateBusinessName(name, language)`**
  - Min 2 chars
  - Empty check

- **`validateOtpCode(code, language)`**
  - Exactly 6 digits

**Language Support:** All error messages in English ('en') and Swahili ('sw').

---

### 3. **Data Layer** (`data/repositories/`)

#### `OnboardingRepository`

Pure Firestore access. All field names match spec exactly:
- `phone`, `firstName`, `lastName`, `city`, `role`
- `businessName`, `businessType`
- `createdAt`, `lastActiveAt`, `updatedAt`

**Methods:**

- **`lookupByPhone(String phone) → UserLookupResult`**
  - Queries `users` collection first
  - If not found, queries `businesses` collection
  - On Firestore error: silently returns `NewUser()`
  - Normalizes phone (removes spaces/dashes)

- **`createUser({phone, firstName, lastName, businessId}) → String?`**
  - Returns user ID or null
  - Sets `createdAt` and `lastActiveAt` to server timestamp
  - Sets status to 'active'

- **`createBusiness({userId, phone, businessName, businessType, city}) → String?`**
  - Returns business ID or null
  - Links to user via `userId`
  - Server timestamps + status='active'

- **`updateUserSecurity({userId, passwordHash, pinHash}) → bool`**
  - Saves hashed credentials (use bcrypt in production!)
  - Returns success/failure

- **`completeOnboarding({userId, businessId}) → bool`**
  - Sets `onboardingComplete = true`
  - Sets `onboardingCompletedAt` to server timestamp
  - Updates both users and businesses collections

- **`linkPhoneToAuth({phone, userId}) → bool`**
  - Associates Firestore user with Firebase Auth
  - Stores Firebase UID in user document

**Error Handling:**
- All methods catch `FirebaseException` and return null/false
- Firestore lookup errors silently return `NewUser()` (no flow blocking)
- All errors logged to console for debugging

---

### 4. **Service Layer** (`domain/services/`)

#### `OnboardingService`

Orchestration layer between repository, validation, state, and persistence.

**Constructor:**
```dart
OnboardingService({
  required OnboardingRepository repository,
  FirebaseAuth? firebaseAuth,
  required SharedPreferences preferences,
})
```

**Methods:**

- **`verifyOtpAndLookup({phone, otpCode}) → UserLookupResult`**
  - Validates OTP format
  - Calls repository lookup
  - On error: returns `NewUser()` for graceful degradation

- **`saveNewUserProfile({phone, firstName, lastName, businessName, businessType, city, password, pin})`**
  - Validates all inputs
  - Creates business, then user, then security
  - Returns `(userId, businessId)` tuple
  - On error: returns `(null, null)`

- **`saveReturningUserSecurity({userId, password, pin}) → bool`**
  - For returning users completing security screen
  - Validates password and PIN

- **`completeOnboarding({userId, businessId}) → bool`**
  - Calls repository completion
  - Sets SharedPreferences:
    - `onboarding_complete = true`
    - `current_user_id = userId`
    - `current_business_id = businessId`

- **`checkOnboardingStatus() → bool`**
  - Called on app launch
  - Returns `onboarding_complete` from SharedPreferences
  - If true, skip onboarding and go to dashboard

- **`resetOnboarding() → void`**
  - Clears all SharedPreferences onboarding flags
  - For testing or explicit user action

- **`getCurrentUserId() → String?`**
- **`getCurrentBusinessId() → String?`**

---

### 5. **State Management** (`providers/`)

#### `OnboardingNotifier` (Riverpod)

Manages full onboarding state using `StateNotifier<OnboardingState>`.

**Key Methods:**
- `updateLanguage(language)` — Set language
- `updatePhone(phone)` — Set phone, validate format
- `updateFirstName(firstName)` — Validate against naming rules
- `updateLastName(lastName)`
- `updateBusinessName(businessName)`
- `updateBusinessType(type)`
- `updatePassword(password)` — Validate strength
- `updatePin(pin)` — Validate 4 digits
- `updateOtpCode(code)` — Update OTP, track attempts
- `advanceStep()` — Move to next screen
- `retreat()` — Go back one screen
- `setReturningUser(userLookupResult)` — Populate returning user data
- `setLookupResult(result)` — Set phone lookup result
- `incrementOtpAttempts()` — Track failed attempts
- `startOtpCooldown()` — Lock account for 30 seconds after 3 attempts
- `resetOtpState()` — Clear OTP for resend

**Providers:**
- `onboardingProvider` — Exposes `StateNotifierProvider<OnboardingNotifier, OnboardingState>`
- `onboardingServiceProvider` — Injects dependencies (repository, prefs)

---

### 6. **Content Strings** (`providers/strings/`)

#### `AppStrings`

Centralized strings for all 7 screens + errors in English and Swahili.

**Screen 1 (Welcome):**
```dart
welcomeTitle(language)      // "Karibu Mali Up" / "Welcome to Mali Up"
welcomeSubtitle(language)
welcomeDescription(language)
selectLanguage(language)
english(language)
swahili(language)
continueButton(language)
```

**Screen 2 (Phone):**
```dart
phoneTitle(language)        // "Namba yako ya simu"
phoneSubtitle(language)
phoneLabel(language)
phonePlaceholder(language)  // "756 123 456"
phoneError(language)
getOtpButton(language)      // "Pata OTP"
```

**Screen 3 (OTP):**
```dart
otpTitle(language)          // "Thibitisha simu yako"
otpSubtitle(language)       // Interpolates with $phone
otpLabel(language)
otpPlaceholder(language)    // "000000"
otpWrongCode(language)
otpExpired(language)
otpTooManyAttempts(language)
resendOtp(language)
resendCooldown(language, seconds)  // "Omba nyingine kwa 30 sec"
verifyButton(language)
```

**Screen 4A (Returning User):**
```dart
returningUserTitle(language)                // "Karibu tena!"
returningUserMessage(language, businessName) // Dynamic greeting
continueWithBusiness(language)  // "Endelea na $businessName"
startFresh(language)
```

**Screen 4B (New User):**
```dart
newUserTitle(language)
newUserSubtitle(language)
firstNameLabel(language)
firstNamePlaceholder(language)  // "Juma"
lastNameLabel(language)
lastNamePlaceholder(language)   // "Salim"
nameRequired(language)
nameMinLength(language)
nextButton(language)
```

**Screen 5 (Business):**
```dart
businessTitle(language, firstName)  // "Habari John, biashara gani..."
businessSubtitle(language)
businessNameLabel(language)
businessNamePlaceholder(language)
businessTypeLabel(language)
cityLabel(language)
cityPlaceholder(language)           // "Dar es Salaam"

// Business type options
businessTypeRetail(language)        // "Duka la Rejareja"
businessTypeWholesale(language)
businessTypeServices(language)      // "Huduma"
businessTypeManufacturing(language) // "Uzalishaji"
businessTypeRestaurant(language)    // "Ukahawa"
businessTypeBeauty(language)        // "Uzuri & Spa"
businessTypeAgriculture(language)   // "Kilimo"
businessTypeTransport(language)
businessTypeEducation(language)
businessTypeOther(language)

getBusinessTypes(language) → List<Map<'value', 'label'>>
```

**Screen 6 (Security):**
```dart
securityTitle(language)        // "Usalama wa akaunti"
securitySubtitle(language)
passwordLabel(language)
passwordPlaceholder(language)
passwordHint(language)
passwordWeak(language)
pinLabel(language)             // "PIN (tarakimu 4)"
pinPlaceholder(language)       // "0000"
pinHint(language)
confirmButton(language)
```

**Screen 7 (Success):**
```dart
successTitle(language)              // "Umefanikiwa!"
successMessage(language, businessName) // Dynamic
successTip1(language)               // "📊 Tazama muhtasari..."
successTip2(language)
successTip3(language)
goToDashboard(language)             // "Nenda kwa Dashboard"
```

**Error Messages:**
```dart
networkError(language)
firebaseError(language)
savingError(language)
retryButton(language)
backButton(language)
cancelButton(language)
```

---

### 7. **Routing** (`config/routing/`)

#### `OnboardingRoutes`

Named route constants and helper functions.

**Route Constants:**
```dart
OnboardingRoutes.welcome          // '/onboarding/welcome'
OnboardingRoutes.phone            // '/onboarding/phone'
OnboardingRoutes.otp              // '/onboarding/otp'
OnboardingRoutes.returningUser    // '/onboarding/returning-user'
OnboardingRoutes.newUser          // '/onboarding/new-user'
OnboardingRoutes.business         // '/onboarding/business'
OnboardingRoutes.security         // '/onboarding/security'
OnboardingRoutes.success          // '/onboarding/success'
OnboardingRoutes.dashboard        // '/dashboard'
```

**Helper Methods:**
- `getNextRoute({currentStep, isReturningUser})` — Determine next screen
- `getPreviousRoute({currentStep})` — Go back one screen

**GoRouter Configuration:**
- Initialize GoRouter with 7 onboarding routes + dashboard
- Redirect guard: if `onboarding_complete == true`, skip to `/dashboard`
- Dynamic routing: after OTP, route to `/returning-user` or `/new-user` based on lookup
- Step guards prevent advancing without completing current screen validation

---

## Error Handling & Resilience

### OTP Errors
```
User enters wrong OTP code
  → Show inline error: "Namba si sahihi. Jaribu tena."
  → Increment otpAttempts
  → Allow retry (up to 3 attempts)

After 3 failed attempts
  → Lock account: isLocked = true
  → Start 30-second cooldown
  → Show: "Jaribu mara nyingi sana. Jaribu baada ya dakika 30."

OTP expires (10 minutes)
  → Show: "Namba imeishia umeme. Omba nyingine."
  → Show resend button
  → 30-second cooldown before resend allowed
```

### Firestore Errors
```
lookupByPhone() fails
  → Silently return NewUser()
  → Never block the flow
  → Log error for debugging

Save user/business fails
  → Show: "Tatizo katika kuokoa data. Jaribu tena."
  → Show retry button
  → Do NOT advance to next step
```

### Network Errors
```
Any network operation fails
  → Show: "Tatizo la mtandao. Tafadhali jaribu tena."
  → Show retry button
  → Preserve state for retry
```

---

## Data Flow Diagram

```
┌─────────────┐
│ Screen 1: Login (Phone + Language)
├─────────────┤
│ User selects language → OnboardingNotifier updates language
│ User enters phone      → OnboardingValidator validates
│ User taps "Get OTP"    → OnboardingService.verifyOtpAndLookup()
│                           └─→ OnboardingRepository.lookupByPhone()
│                               └─→ Firestore query (users + businesses)
└──────────────┘
        ↓
┌──────────────────────┐
│ Screen 2-3: OTP      │
├──────────────────────┤
│ Firebase Auth sends OTP
│ User enters code      → OnboardingValidator.validateOtpCode()
│ Verify OTP           → OnboardingService.verifyOtpAndLookup()
│ Get lookup result    → UserLookupResult (Returning/New)
└──────────────────────┘
        ↓
   ┌────────────────────────────┐
   │ Route decision             │
   ├────────────────────────────┤
   │ isReturningUser?           │
   ├────────────────────────────┤
   │  YES → Screen 4A           │  NO → Screen 4B
   │        (Returning logic)   │       (New User Form)
   └────────────────────────────┘
        ↓ ↓
    ┌───────────────────────────────────────────┐
    │ Screen 4A: Returning User (if found)      │
    │ - Populate firstName, lastName, business  │
    │ - Skip directly to Screen 6               │
    │ - Allow "Start Fresh" to go back to 4B    │
    └───────────────────────────────────────────┘
        ↓
    ┌───────────────────────────────────────────┐
    │ Screen 4B: New User Personal Info         │
    │ - Enter firstName, lastName               │
    │ - OnboardingValidator.validateName()      │
    └───────────────────────────────────────────┘
        ↓
    ┌───────────────────────────────────────────┐
    │ Screen 5: Business Details                │
    │ - Enter businessName, businessType, city  │
    │ - Show personalized greeting              │
    │ - Validation for all fields               │
    └───────────────────────────────────────────┘
        ↓
    ┌───────────────────────────────────────────┐
    │ Screen 6: Security (Password + PIN)       │
    │ - Enter password                          │
    │ - OnboardingValidator.validatePassword()  │
    │ - Enter PIN                               │
    │ - OnboardingValidator.validatePin()       │
    │ - OnboardingService.saveNewUserProfile()  │
    │   ├─→ createBusiness()                    │
    │   ├─→ createUser()                        │
    │   └─→ updateUserSecurity(hashes)          │
    └───────────────────────────────────────────┘
        ↓
    ┌───────────────────────────────────────────┐
    │ Screen 7: Success                         │
    │ - Show success message with business name │
    │ - OnboardingService.completeOnboarding()  │
    │   ├─→ Repository.completeOnboarding()     │
    │   └─→ SharedPreferences.set(flags)        │
    │ - User taps "Go to Dashboard"             │
    └───────────────────────────────────────────┘
        ↓
    ┌───────────────────────────────────────────┐
    │ Dashboard                                  │
    │ (onboarding_complete = true in prefs)     │
    └───────────────────────────────────────────┘
```

---

## Firestore Collections & Fields

### `users` Collection

```javascript
{
  phone: "+255756123456",           // Normalized
  firstName: "John",
  lastName: "Doe",
  businessId: "biz_123",            // Reference to business
  passwordHash: "bcrypt_hash",      // Use bcrypt in production
  pinHash: "bcrypt_hash",
  firebaseUid: "uid_from_auth",
  createdAt: Timestamp,
  lastActiveAt: Timestamp,
  updatedAt: Timestamp,
  status: "active",
  onboardingComplete: true,
  onboardingCompletedAt: Timestamp
}
```

### `businesses` Collection

```javascript
{
  userId: "user_123",                      // Reference to owner
  phone: "+255756123456",                  // Normalized
  businessName: "John's Shop",
  businessType: "retail",                  // retail, wholesale, services, etc.
  city: "Dar es Salaam",
  logo: "https://...",                     // Optional
  createdAt: Timestamp,
  lastActiveAt: Timestamp,
  updatedAt: Timestamp,
  status: "active",
  onboardingComplete: true,
  onboardingCompletedAt: Timestamp
}
```

---

## Installation & Setup

### 1. Add Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter_riverpod: ^3.3.1
  go_router: ^17.1.0
  firebase_core: ^3.10.1
  firebase_auth: ^5.4.1
  cloud_firestore: ^5.6.1
  shared_preferences: ^2.3.2
  freezed_annotation: ^2.4.1

dev_dependencies:
  freezed: ^2.4.1
  build_runner: ^2.4.8
```

### 2. Generate Freezed Models
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Initialize Services at App Launch
```dart
final serviceProvider = FutureProvider((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final repo = OnboardingRepository();
  return OnboardingService(
    repository: repo,
    preferences: prefs,
  );
});
```

### 4. Check Onboarding Status at App Start
```dart
final isOnboardingComplete = await service.checkOnboardingStatus();
if (isOnboardingComplete) {
  // Navigate to /dashboard
} else {
  // Navigate to /onboarding/welcome
}
```

---

## Testing Checklists

### Validation Tests
- [ ] Phone: TZ format +255, 9 digits after code, valid prefix
- [ ] Name: 2+ chars, no numbers, allows spaces/hyphens
- [ ] Password: 8+ chars, 1 number, 1 letter
- [ ] PIN: exactly 4 digits
- [ ] Business name: 2+ chars, not empty
- [ ] OTP: exactly 6 digits

### State Management Tests
- [ ] Language switch updates all UI strings
- [ ] Advancing step validates current screen
- [ ] Cannot skip steps forward
- [ ] Can retreat to previous step
- [ ] OTP cooldown timer ticks correctly
- [ ] OTP expires after 10 minutes

### Firebase Tests
- [ ] Phone lookup finds returning user
- [ ] Phone lookup returns NewUser for unfound number
- [ ] On Firestore error, gracefully returns NewUser
- [ ] Create user writes correct fields
- [ ] Create business links to user
- [ ] Security update saves hashes
- [ ] Completion flag set in both collections

### Routing Tests
- [ ] Cannot access /business before /otp
- [ ] After OTP, route to /returning-user or /new-user correctly
- [ ] Returning user can skip /new-user and go directly to /business
- [ ] Success screen redirects to /dashboard
- [ ] On app launch, if complete, skip to /dashboard
- [ ] Deep links respect step guards

---

## File Structure

```
lib/features/onboarding/
├── models/
│   ├── onboarding_state.dart        (Freezed main state)
│   ├── user_lookup_result.dart      (Sealed class)
│   └── otp_state.dart               (Freezed OTP tracking)
│
├── data/
│   └── repositories/
│       └── onboarding_repository.dart (Firebase access layer)
│
├── domain/
│   ├── validators/
│   │   └── onboarding_validator.dart (Phone, name, password, PIN validation)
│   └── services/
│       └── onboarding_service.dart   (Orchestration layer)
│
├── providers/
│   ├── onboarding_notifier.dart      (StateNotifier)
│   ├── onboarding_provider.dart      (Riverpod exports)
│   └── strings/
│       └── app_strings.dart          (EN + SW strings, all 7 screens)
│
├── presentation/
│   └── screens/
│       ├── screen_1_welcome.dart
│       ├── screen_2_phone.dart
│       ├── screen_3_otp.dart
│       ├── screen_4a_returning.dart
│       ├── screen_4b_new_user.dart
│       ├── screen_5_business.dart
│       ├── screen_6_security.dart
│       └── screen_7_success.dart
│
└── core/
    └── routing/
        └── onboarding_routes.dart    (GoRouter config + route constants)

lib/config/
└── routing/
    └── onboarding_routes.dart         (Routing constants & helpers)
```

---

## Next Steps

1. **Implement UI Screens** — Use the state/validation/strings layer as provided
2. **Add Animations** — Lottie animations for transitions between steps
3. **Password Hashing** — Replace placeholder hashing with bcrypt
4. **OTP Service** — Integrate Firebase Phone Authentication
5. **Testing** — Unit tests for validators, integration tests for repository
6. **Error Analytics** — Track onboarding drop-off rates
7. **Localization** — Extend AppStrings to more languages

---

## Key Design Decisions

### 1. **Graceful Firestore Degradation**
If Firestore lookup fails, treat as NewUser. Never block the flow on network issues.

### 2. **Linear Step Progression**
Users cannot skip ahead. GoRouter guards enforce step completion before advancing.

### 3. **Immutable State**
Freezed models ensure predictable state transitions and easier debugging.

### 4. **Service Layer Orchestration**
Repository handles data; Service handles business logic and coordination.
Notifier manages UI state; Service is injected dependency.

### 5. **Centralized Content**
All strings in AppStrings class, no hardcoded strings in UI code.
Easy to add languages later (ARB format ready).

### 6. **Tanzania-First Validation**
Phone validation specifically for TZ format (+255, 9 digits, valid prefixes).
Business types and cities tailored for African SMEs.

---

## Security Notes

⚠️ **TODO:** Before production:
- [ ] Use bcrypt (or argon2) for password hashing, not plaintext
- [ ] Use bcrypt for PIN hashing
- [ ] Implement rate limiting on OTP requests
- [ ] Validate Firebase tokens server-side
- [ ] Use HTTPS-only for all Firestore calls
- [ ] Implement audit logging for sensitive operations
- [ ] Regular security audits of Firestore rules

---

**Status:** Complete logical implementation, ready for UI integration and Firebase Auth setup.

