#!/usr/bin/env bash
set -euo pipefail

# One-time fix: the mali-up Worker (apps/admin, the web app) rebuilds/
# redeploys on EVERY push to the live branch, unlike release-android.yml
# which only fires when apps/mobile-app/** changed. This sets a "Build
# Watch Path" on the Worker's build trigger via the Cloudflare Builds API,
# so it only rebuilds when apps/admin/** actually changed -- the repo-side
# equivalent of release-android.yml's `paths:` filter. Run once; safe to
# re-run (idempotent PATCH).
#
# Prerequisite: the mali-up Worker's production branch in Cloudflare
# (Workers & Pages -> mali-up -> Settings -> Build) must be set to `main`.
#
# Requires a Cloudflare *user-scoped* API token (account-scoped tokens
# return "Invalid token" on these endpoints) with:
#   - Workers Builds Configuration: Edit
#   - Workers Scripts: Read
# Create one at https://dash.cloudflare.com/profile/api-tokens
#
# Usage:
#   CLOUDFLARE_API_TOKEN=... CLOUDFLARE_ACCOUNT_ID=... \
#     .github/scripts/set-cloudflare-build-watch-paths.sh
#
# CLOUDFLARE_ACCOUNT_ID is the "Neuraltale's projects" account ID, visible
# in the Cloudflare dashboard URL or via `list_teams`/`list_projects` if
# you have the Cloudflare MCP connector.

: "${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN}"
: "${CLOUDFLARE_ACCOUNT_ID:?Set CLOUDFLARE_ACCOUNT_ID}"

WORKER_NAME="mali-up"
PRODUCTION_BRANCH="main"
WATCH_PATH="apps/admin/**"

API="https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID"
AUTH_HEADER="Authorization: Bearer $CLOUDFLARE_API_TOKEN"

echo "Looking up tag for Worker '$WORKER_NAME'..."
WORKER_TAG=$(curl -sf "$API/workers/scripts" --header "$AUTH_HEADER" \
  | jq -r --arg name "$WORKER_NAME" '.result[] | select(.id == $name) | .tag')

if [ -z "$WORKER_TAG" ]; then
  echo "Could not find a Worker named '$WORKER_NAME' on this account." >&2
  exit 1
fi
echo "Worker tag: $WORKER_TAG"

echo "Looking up the '$PRODUCTION_BRANCH' build trigger..."
TRIGGERS_JSON=$(curl -sf "$API/builds/workers/$WORKER_TAG/triggers" --header "$AUTH_HEADER")
TRIGGER_UUID=$(echo "$TRIGGERS_JSON" \
  | jq -r --arg branch "$PRODUCTION_BRANCH" '.result[] | select(.branch_includes | index($branch)) | .trigger_uuid' \
  | head -n1)

if [ -z "$TRIGGER_UUID" ]; then
  echo "Could not find a trigger watching the '$PRODUCTION_BRANCH' branch. Triggers found:" >&2
  echo "$TRIGGERS_JSON" | jq '.result[] | {trigger_uuid, trigger_name, branch_includes}' >&2
  exit 1
fi
echo "Trigger: $TRIGGER_UUID"

echo "Setting path_includes to [\"$WATCH_PATH\"]..."
curl -sf "$API/builds/triggers/$TRIGGER_UUID" --header "$AUTH_HEADER" \
  --header "Content-Type: application/json" \
  --request PATCH \
  --data "{\"path_includes\": [\"$WATCH_PATH\"]}" \
  | jq '.result | {trigger_uuid, trigger_name, path_includes, path_excludes}'

echo "Done. The $WORKER_NAME Worker will now only rebuild on '$PRODUCTION_BRANCH' pushes that touch $WATCH_PATH."
