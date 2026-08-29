# Google Play Console install reports

The dashboard's **Growth & Retention** section (installs, uninstalls, acquisition
funnel) reads from Google Play Console's exported **statistics CSV reports**.

There is no real-time Play API for install/uninstall counts. Google drops daily
CSVs into a private Cloud Storage bucket instead; the data lags reality by ~2 days
and is aggregated per day. `apps/admin/lib/play-reports.ts` fetches and parses the
monthly `installs_<package>_<YYYYMM>_overview.csv` files.

## Setup

### 1. Find the report bucket id

Play Console → **Download reports** → **Statistics** → **Copy Cloud Storage URI**.

It looks like `gs://pubsite_prod_1234567890/`. You want just the bucket id
(`pubsite_prod_1234567890`), no `gs://` and no trailing slash.

### 2. Grant a service account read access

Either reuse the existing Firebase Admin service account
(`firebase-adminsdk-fbsvc@neuraltale-mali-up.iam.gserviceaccount.com`) or create a
dedicated one. Then grant it read access to the bucket, using **one** of:

- **Play Console** → **Users and permissions** → **Invite new users** → enter the
  service-account email → grant **View app information (read-only)** and
  **View financial data, orders, and cancellation survey responses**. Play then
  authorises that identity on the report bucket.
- **Google Cloud Console** (if the Play account is linked to a GCP project):
  grant the SA `roles/storage.objectViewer` on the `pubsite_prod_…` bucket.

### 3. Set the environment variables

Worker runtime vars (Cloudflare → Settings → Variables and Secrets), or
`.env.local` for local dev:

| Var | Value |
| --- | --- |
| `PLAY_REPORTS_BUCKET` | `pubsite_prod_1234567890` |
| `PLAY_PACKAGE_NAME` | `com.neuraltale.maliup` (default if unset) |
| `PLAY_SA_CLIENT_EMAIL` | *(optional)* dedicated SA email |
| `PLAY_SA_PRIVATE_KEY` | *(optional)* dedicated SA PEM, literal `\n` escapes |

If `PLAY_SA_*` are omitted, `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` are
used — that SA must have been granted bucket access in step 2.

## Verifying

- With the vars unset, the dashboard shows a "Connect Google Play Console" card
  and the funnel starts at "Signed up". No errors.
- With them set, the "Installs vs Uninstalls" chart and the Installs/Uninstalls
  KPI cards populate. Cross-check one 30-day total against Play Console →
  Statistics for the same date range (numbers should match within the ~2-day
  reporting lag).
- The route caches for 30 minutes (`withCache('growth', …)`), so allow for that
  when checking a fresh change.

## What we read

From `*_overview.csv` (UTF-16LE, CRLF): `Date`, `Daily User Installs`,
`Daily User Uninstalls`, `Active Device Installs`, `Total User Installs`.

The per-country / per-device dimension CSVs in the same folder are not used yet.
