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
   `android/app/build.gradle.kts` (alias `mali-up-key`):
   ```bash
   keytool -genkeypair -v \
     -keystore mali-up-release.jks \
     -alias mali-up-key \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -storepass "MaliUp@2026Key" -keypass "MaliUp@2026Key"
   ```
   (Change the passwords if you'd rather not reuse the ones already committed
   to this README/build file — just update both places to match.)
5. Extract the public certificate and upload it wherever Play Console's key
   reset flow asks for it (usually a `.pem` export):
   ```bash
   keytool -export -rfc -alias mali-up-key -keystore mali-up-release.jks -file upload_certificate.pem
   ```
6. Once Play Console confirms the new upload key is active, place
   `mali-up-release.jks` at `android/keystore/mali-up-release.jks` and
   continue with the CI/CD checklist below.

Do not generate the keystore and start pushing to the `production` branch
before the reset is approved — the first automated release will fail.

## Security Notice
⚠️ **CRITICAL**: This keystore file is used to sign all releases on Google Play Store. 
**DO NOT COMMIT THIS FOLDER TO GIT** — it's already in `.gitignore`.

## Keystore Details
- **File**: `mali-up-release.jks`
- **Alias**: `mali-up-key`
- **Store Password**: `MaliUp@2026Key`
- **Key Password**: `MaliUp@2026Key`
- **Validity**: 10,000 days (≈27 years)
- **Algorithm**: RSA 2048-bit

## Safe Storage
1. **Backup this keystore** to a secure location (e.g., encrypted USB, password manager, secure vault)
2. **Never share** the passwords
3. **Keep** this keystore in a safe place — losing it means you can't update your app on Google Play

## CI/CD setup checklist (`.github/workflows/release-android.yml`)

The pipeline only runs on pushes to the **`production`** branch — pushes to
`main` never trigger a store release. Steps to enable it:

### 1. Create the `production` branch
```bash
git checkout main
git pull
git checkout -b production
git push -u origin production
```
Merge `main` → `production` whenever you want to cut a release.

### 2. Add repo secrets
Repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `KEYSTORE_FILE_BASE64` | `base64 -i mali-up-release.jks` (only after the upload key reset above is approved) |
| `KEYSTORE_PASSWORD` | The keystore/key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Full contents of the Play service account JSON key (see step 3) |

### 3. Create a Google Play service account (one-time)
1. In [Google Cloud Console](https://console.cloud.google.com/), create (or pick)
   a project, then **IAM & Admin → Service Accounts → Create Service Account**.
2. Create a JSON key for it and download it.
3. In **Play Console → Setup → API access**, link the same Google Cloud
   project, then grant the service account access to this app with at least
   **"Release to production, exclude devices, and use Play App Signing"**
   permission (Release management).
4. Paste the full JSON file contents into the `PLAY_SERVICE_ACCOUNT_JSON`
   secret.

### 4. First automated release
The workflow ships to the `production` Play track at a 20% staged rollout
(`status: inProgress`). Bump it to 100% manually in Play Console once you've
confirmed the rollout is healthy — this is intentional so a bad build doesn't
reach every user immediately. Adjust `userFraction` in the workflow if you'd
rather change the starting percentage.
