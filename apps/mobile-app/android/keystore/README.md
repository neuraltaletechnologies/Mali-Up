# Mali Up Release Keystore

## ⚠️ Upload key must be reset before generating a new keystore

Confirmed state: **Play App Signing is ON**, and the original upload keystore
is lost. Google holds the real app signing key, so this is recoverable — but
you must request an upload key reset and get it approved **before** generating
or using a new `.jks` file. Skipping this step means Play Console will reject
the upload from a keystore it doesn't recognize.

1. Go to **Play Console → your app → Setup → App integrity → Upload key**.
2. Click **"Request upload key reset"**. Google reviews this (can take from a
   few hours to a couple of days).
3. Once approved, Play Console will show you the new upload key requirements
   (or let you upload a PEM certificate generated from a new keystore).
4. Generate the new keystore locally, matching the config already wired into
   `android/app/build.gradle.kts` (alias `mali-up-key`). Pick a new password
   yourself — do not reuse any password that was ever committed to this repo:
   ```bash
   keytool -genkeypair -v \
     -keystore mali-up-release.jks \
     -alias mali-up-key \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -storepass "<your-new-password>" -keypass "<your-new-password>"
   ```
   `build.gradle.kts` reads the password from the `KEYSTORE_PASSWORD`
   environment variable only (no fallback) — set it locally when building
   release variants, and as the `KEYSTORE_PASSWORD` repo secret for CI.
5. Extract the public certificate and upload it wherever Play Console's key
   reset flow asks for it (usually a `.pem` export):
   ```bash
   keytool -export -rfc -alias mali-up-key -keystore mali-up-release.jks -file upload_certificate.pem
   ```
6. Once Play Console confirms the new upload key is active, place
   `mali-up-release.jks` at `android/keystore/mali-up-release.jks` and
   continue with the CI/CD checklist below.

Do not merge an `apps/mobile-app/**` change into `main` before the reset is
approved — the automated release will fail.

## Security Notice
⚠️ **CRITICAL**: This keystore file is used to sign all releases on Google Play Store. 
**DO NOT COMMIT THIS FOLDER TO GIT** — it's already in `.gitignore`.

## Keystore Details
- **File**: `mali-up-release.jks`
- **Alias**: `mali-up-key`
- **Store/Key Password**: set by you when generating the keystore — kept only
  in your password manager and the `KEYSTORE_PASSWORD` secret, never in git
- **Validity**: 10,000 days (≈27 years)
- **Algorithm**: RSA 2048-bit

## Safe Storage
1. **Backup this keystore** to a secure location (e.g., encrypted USB, password manager, secure vault)
2. **Never share** the passwords
3. **Keep** this keystore in a safe place — losing it means you can't update your app on Google Play

## CI/CD setup checklist (`.github/workflows/release-android.yml`)

`main` is the live branch. `release-android.yml` runs when a push to `main`
touches `apps/mobile-app/**`. In practice that means: **merging a reviewed
PR into `main` that changed the mobile app ships an Open Testing release.**
The PR review is the human checkpoint. Day-to-day work goes on feature
branches or `dev`, never straight to `main` — see the repo-root `CLAUDE.md`
section "Branching & releases".

### 1. Add repo secrets
Repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `KEYSTORE_FILE_BASE64` | `base64 -i mali-up-release.jks` (only after the upload key reset above is approved) |
| `KEYSTORE_PASSWORD` | The keystore/key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Full contents of the Play service account JSON key (see step 3) |

### 2. Create a Google Play service account (one-time)
1. In [Google Cloud Console](https://console.cloud.google.com/), create (or pick)
   a project, then **IAM & Admin → Service Accounts → Create Service Account**.
2. Create a JSON key for it and download it.
3. In **Play Console → Setup → API access**, link the same Google Cloud
   project, then grant the service account access to this app with at least
   **"Release to production, exclude devices, and use Play App Signing"**
   permission (Release management).
4. Paste the full JSON file contents into the `PLAY_SERVICE_ACCOUNT_JSON`
   secret.

### 3. What the workflow ships
`release-android.yml` uploads the App Bundle to the **Open Testing** track
(`track: beta`, `status: completed`) — a full release to testers, not the
Play Store production track. To reach production, promote a verified build
from Open Testing → Production manually in Play Console.

The version code is minutes-since-epoch, computed at build time, so it is
always monotonic with no manual bookkeeping.

Do not merge an `apps/mobile-app/**` change into `main` until the upload key
reset above has been approved — the release will fail otherwise.
