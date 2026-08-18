# Firestore rules tests

Verifies the `DataScope.own` read fallback added to `firestore.rules`
(sales_invoices / expenses / inventory_items) against the local Firestore
emulator — never against the real project. Not part of the Flutter app or
its `flutter test` run; run it separately when `firestore.rules` changes.

## Setup (one-time)

```bash
cd apps/mobile-app/firestore-rules-tests
npm install
```

## Run

Requires a JVM on PATH (the emulator is Java-based) and the Firebase CLI
(`npm i -g firebase-tools`, or use the repo's local `firebase` if present).

```bash
firebase emulators:exec --project demo-mali-up-rules-test --only firestore "npm test"
```

If `java` isn't on PATH but you have Android Studio installed, its bundled
JBR works — point `JAVA_HOME` at it for this command, e.g. on Windows:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
firebase emulators:exec --project demo-mali-up-rules-test --only firestore "npm test"
```

`firebase.json` (one level up) already declares the `firestore` emulator on
port 8080 — that's what `rules.test.mjs` connects to.
