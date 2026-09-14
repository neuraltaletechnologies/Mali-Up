# whatsnew-* files are auto-generated -- don't hand-edit

As of the "Generate release notes from commits" step in
`.github/workflows/release-android.yml`, `whatsnew-en-US` and `whatsnew-sw`
are regenerated on every release run by
`.github/scripts/generate-release-notes.sh`, from `feat:`/`fix:`/`perf:`
commit subjects (under `apps/mobile-app`) merged since the last release.
That step overwrites both files in the CI checkout right before the Play
Store upload step reads them -- the result is never committed back to the
repo, so whatever is checked in here is just a stale snapshot from
whichever run last happened to write it, not what will actually ship.

Practical implications:

- **Editing these files by hand does nothing.** The next release
  overwrites them regardless of what's committed here.
- **Release-note quality now comes from commit message quality.** Only
  `feat:`/`fix:`/`perf:` subjects (optionally scoped, e.g. `fix(mobile):`)
  are surfaced; write the part after the colon as if a user were going to
  read it verbatim, because they might.
- **Swahili bullets are machine-translated**, not human-reviewed -- the
  section headers ("Vipya:" / "Marekebisho:" / "Maboresho:") are hardcoded,
  but each bullet's English text goes through MyMemory's free translation
  API. It's plain MT quality, not the bar `l10n/DEVELOPER_STYLE_GUIDE.md`
  holds real in-app strings to -- released notes only. If that API call
  fails for a given bullet (timeout, rate limit, whatever), it silently
  falls back to the English text for that line rather than blocking the
  release -- so an occasional English sentence under a Swahili header in
  a past release isn't a bug, it's that fallback. See the script's header
  comment for details.
- Google Play hard-rejects the whole release if either language exceeds
  500 characters, so the script caps items per section and the overall
  length; a long tail of commits shows up as `(+N more)` / `(+N zaidi)`
  instead of being listed out.

To change how notes are generated (grouping, headers, item caps, the
500-char margin), edit the script, not these files.
