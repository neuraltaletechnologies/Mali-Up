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
- **Only the section headers are Swahili** ("Vipya:" / "Marekebisho:" /
  "Maboresho:") -- the commit text itself is not machine-translated and
  stays in English in both files. See the script's header comment for why.
- Google Play hard-rejects the whole release if either language exceeds
  500 characters, so the script caps items per section and the overall
  length; a long tail of commits shows up as `(+N more)` / `(+N zaidi)`
  instead of being listed out.

To change how notes are generated (grouping, headers, item caps, the
500-char margin), edit the script, not these files.
