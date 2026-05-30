@echo off
setlocal

if not exist sentry.local.json (
  echo [Sentry] Missing sentry.local.json
  echo Copy sentry.example.json to sentry.local.json and fill SENTRY_DSN first.
  exit /b 1
)

flutter run --dart-define-from-file=sentry.local.json
