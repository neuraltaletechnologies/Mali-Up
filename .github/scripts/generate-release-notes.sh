#!/usr/bin/env bash
set -euo pipefail

# Auto-generates the Play Store "what's new" text for the current release:
#   apps/mobile-app/distribution/whatsnew/whatsnew-en-US
#   apps/mobile-app/distribution/whatsnew/whatsnew-sw
# Called from release-android.yml before the "Publish to Play Store" step,
# replacing whatever a human previously committed to those files.
#
# Source: conventional-commit subjects (feat:/fix:/perf:) touching
# apps/mobile-app, since the last automated version-bump commit (the
# "chore(release): bump mobile app to ..." marker release-android.yml's
# bump step leaves on main -- see that step for why it exists).
#
# Section headers are hardcoded Swahili; each bullet's commit text is
# machine-translated via the free MyMemory API (no key needed at this
# volume: https://mymemory.translated.net) -- deliberately not an LLM
# call, to avoid an Anthropic API key/cost in this pipeline. Quality is
# "plain MT", not reviewed Swahili copy -- see CLAUDE.md ("Swahili-first,
# English fallback") and l10n/DEVELOPER_STYLE_GUIDE.md for the bar real
# in-app strings are held to; this is a lower bar, released notes only.
# Network hiccups degrade gracefully: any bullet that fails to translate
# (timeout, rate limit, bad response) falls back to its English text
# rather than failing the step.
#
# Must run from the repo root (not apps/mobile-app) and needs full git
# history (actions/checkout with fetch-depth: 0) -- both the release-marker
# search and the fallback below walk arbitrarily far back.
#
# Google Play rejects the ENTIRE release if EITHER language's recentChanges
# exceeds 500 characters, so each output is capped with margin to spare:
# https://developers.google.com/resources/api-libraries/documentation/androidpublisher/v3/java/latest/com/google/api/services/androidpublisher/model/LocalizedText.html

MAX_CHARS=450
OUT_DIR="apps/mobile-app/distribution/whatsnew"

base_commit=$(git log --format='%H' --grep='^chore(release): bump mobile app to' -n 1 || true)

if [ -n "$base_commit" ]; then
  range="$base_commit..HEAD"
else
  # First run of this script, or history was rewritten -- no marker commit
  # to anchor on yet. Bootstrap from a bounded recent window instead of the
  # whole repo history.
  echo "No prior release marker found -- falling back to the last 30 commits."
  range="-30"
fi

# shellcheck disable=SC2086 -- $range is a single git-log revision argument
# ("X..Y" or "-30"), never meant to be quoted as one token.
subjects=$(git log $range --no-merges --format='%s' -- apps/mobile-app)

new_items=()
fixed_items=()
improved_items=()

# Regexes live in variables, not inline in `[[ =~ ]]` -- bash's parser
# chokes on the unquoted `(...)` groups otherwise ("syntax error in
# conditional expression").
feat_re='^feat(\([^)]*\))?!?:[[:space:]]*(.+)$'
fix_re='^fix(\([^)]*\))?!?:[[:space:]]*(.+)$'
perf_re='^perf(\([^)]*\))?!?:[[:space:]]*(.+)$'

while IFS= read -r subject; do
  [ -z "$subject" ] && continue
  if [[ "$subject" =~ $feat_re ]]; then
    new_items+=("${BASH_REMATCH[2]}")
  elif [[ "$subject" =~ $fix_re ]]; then
    fixed_items+=("${BASH_REMATCH[2]}")
  elif [[ "$subject" =~ $perf_re ]]; then
    improved_items+=("${BASH_REMATCH[2]}")
  fi
  # Anything else (chore/build/ci/docs/style/test/refactor/revert/no
  # prefix) is internal, not user-facing -- deliberately left out of
  # release notes.
done <<< "$subjects"

# Caps each section to MAX_ITEMS_PER_SECTION lines. Without this, a busy
# "New" section alone can eat the whole 450-char budget before "Fixed" (the
# section users most want to see) ever gets written -- truncate_text's
# final cut-off is a safety net, not the primary control. Also bounds how
# many translate_to_sw calls happen per release (at most 3 sections x this).
MAX_ITEMS_PER_SECTION=4

# Translates one line of English text to Swahili via MyMemory's free API.
# On any failure (network, timeout, rate limit, empty/malformed response)
# prints the original English text unchanged -- a translation hiccup must
# never fail the release. 10s cap so one slow request can't stall the job.
translate_to_sw() {
  local text="$1" response translated
  response=$(curl -sf --max-time 10 -G \
    --data-urlencode "q=$text" \
    --data-urlencode "langpair=en|sw" \
    "https://api.mymemory.translated.net/get" 2>/dev/null) || { printf '%s' "$text"; return; }
  translated=$(printf '%s' "$response" | jq -r '.responseData.translatedText // empty' 2>/dev/null || true)
  if [ -z "$translated" ]; then
    printf '%s' "$text"
  else
    printf '%s' "$translated"
  fi
}

build_section() {
  local header="$1" more_label="$2" translate="$3"; shift 3
  local items=("$@")
  [ "${#items[@]}" -eq 0 ] && return 0
  echo "$header"
  local shown=$(( ${#items[@]} < MAX_ITEMS_PER_SECTION ? ${#items[@]} : MAX_ITEMS_PER_SECTION ))
  for ((i = 0; i < shown; i++)); do
    local item="${items[$i]}"
    [ "$translate" = "yes" ] && item=$(translate_to_sw "$item")
    echo "- $item"
  done
  local remaining=$(( ${#items[@]} - shown ))
  [ "$remaining" -gt 0 ] && echo "$(printf "$more_label" "$remaining")"
  return 0
  # ^ Without this, the function's own exit status is whatever the `[ ... ]`
  # above returned. Under `set -e`, a false condition there (the common
  # case -- most sections don't overflow) would make THIS function "fail",
  # which aborts the whole `en_body=$(...)`/`sw_body=$(...)` subshell
  # (command substitutions inherit -e) before the remaining sections ever
  # run. Confirmed by hand: dropping this line breaks the script on almost
  # every real run.
}

en_body=$(
  build_section "New:" "(+%s more)" "no" "${new_items[@]}"
  build_section "Fixed:" "(+%s more)" "no" "${fixed_items[@]}"
  build_section "Improved:" "(+%s more)" "no" "${improved_items[@]}"
)

sw_body=$(
  build_section "Vipya:" "(+%s zaidi)" "yes" "${new_items[@]}"
  build_section "Marekebisho:" "(+%s zaidi)" "yes" "${fixed_items[@]}"
  build_section "Maboresho:" "(+%s zaidi)" "yes" "${improved_items[@]}"
)

if [ -z "$en_body" ]; then
  en_body="General improvements and bug fixes."
  sw_body="Maboresho ya jumla na marekebisho ya hitilafu."
fi

truncate_text() {
  local text="$1"
  [ "${#text}" -le "$MAX_CHARS" ] && { printf '%s' "$text"; return; }
  local cut="${text:0:$((MAX_CHARS - 3))}"
  # Prefer cutting at the last full line so this drops a whole bullet
  # instead of chopping one in half; only fall back to a mid-line cut if
  # there's no earlier newline to land on (e.g. one very long item).
  local last_nl="${cut%$'\n'*}"
  if [ "${#last_nl}" -lt "${#cut}" ] && [ -n "$last_nl" ]; then
    printf '%s' "$last_nl"
  else
    printf '%s...' "$cut"
  fi
}

mkdir -p "$OUT_DIR"
truncate_text "$en_body" > "$OUT_DIR/whatsnew-en-US"
truncate_text "$sw_body" > "$OUT_DIR/whatsnew-sw"

echo "--- whatsnew-en-US ($(wc -c < "$OUT_DIR/whatsnew-en-US") bytes) ---"
cat "$OUT_DIR/whatsnew-en-US"
echo
echo "--- whatsnew-sw ($(wc -c < "$OUT_DIR/whatsnew-sw") bytes) ---"
cat "$OUT_DIR/whatsnew-sw"
