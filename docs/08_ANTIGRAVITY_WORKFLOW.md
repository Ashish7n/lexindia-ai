# LexIndia-AI --- Antigravity Workflow

## Purpose

Implement the Flutter frontend in small, reviewable phases while
preserving the existing FastAPI backend, SQLite database, and
translation pipeline. The owner is learning while manually reviewing and
applying changes, so explanations and verification steps must be clear.

## Non-negotiable rules

1.  Inspect before editing.
2.  Do not assume file structure; inspect current files.
3.  Do not overwrite working code without explaining why.
4.  Do not invent endpoints or response fields.
5.  Do not modify legal data/database during unrelated frontend work.
6.  Avoid unnecessary dependencies.
7.  Implement one clear feature at a time.
8.  Never claim a test/build passed unless it was run.
9.  Preserve passing tests.
10. Report changed files, commands, results, and limitations.
11. Do not expose secrets or embed API keys in Flutter.
12. If current source conflicts with this document, report the mismatch
    and follow verified source.

## Mandatory inspection

Inspect the entire `frontend/` directory, `pubspec.yaml`, entry point,
routes, screens, theme, state management, networking, local persistence,
assets/fonts, tests, and platform config. Also inspect backend
`main.py`, `section_routes.py`, and `database.py`. Confirm actual JSON
schemas and status codes.

Before coding, report current architecture, reusable code, gaps,
proposed file structure, dependencies to reuse/add, phased plan, and any
discrepancies. Do not write implementation code before presenting this
plan.

## Phases

1.  Design foundation: colors, typography, Telugu support, themes,
    navigation, reusable components.
2.  API layer: base URL config, typed models, timeouts/errors, parsing
    tests.
3.  Browse/search: server pagination, numeric/text search, debounce,
    stale-request protection, empty/error states.
4.  Section details: full content, language switch, translation
    availability, long-text layout, working bookmark/copy/share.
5.  Home and local data: shortcuts, local history, locally persisted
    bookmarks.
6.  Settings: language, Light/Dark/System, About and disclaimer.
7.  Quality: accessibility, responsiveness, Telugu rendering,
    offline/error states, tests.
8.  Final verification (Complete): Flutter analysis/tests (192 passing, 0 issues),
    backend tests (13 passing), web release build (`build/web`), deployment
    configuration (`--dart-define=API_BASE_URL=...`), documentation synchronization,
    and release handoff. Ready for release decision.

## Change-control protocol

Before each task, state the feature, files to change, reason, behavior
to preserve, and tests to run. Afterward, report files changed,
implemented behavior, commands actually run, results, limitations, and
manual steps. Avoid unrelated refactors. Ask before expanding scope for
unrelated defects.

## Data protection

Never delete/recreate `backend/data/lexindia.db`. Never overwrite PDFs,
extracted text, section JSON, or audit CSV during frontend work. Do not
trigger translation/import jobs as a side effect. Keep `.venv`, `.git`,
caches, and `.env` out of source archives unless specifically needed.
Back up before approved migrations.

## Backend contract discipline

Known endpoints: - `GET /` - `GET /sections/` -
`GET /sections/{section_number}` -
`GET /sections/{section_number}/language/{language}` -
`GET /sections/translation/progress`

Do not call endpoints for bookmarks, accounts, cloud history, or AI
answers unless implemented later. Confirm exact response fields from
source; this documentation summarizes conversation and does not replace
code inspection.

## Confirmed design

Professional Legal; navy/ivory/restrained gold; light default,
dark/system options; reading comfort first; audience includes students
and general public; navigation Home/Browse/Saved/Settings; Section
Details is secondary; translations must be represented honestly.

## Completion rule

A phase is complete only when the owner can review it, relevant tests
have actually been run, and failures are explained. Obtain approval
before the next major phase. Start with inspection and plan; do not
generate the entire app in one uncontrolled batch.
