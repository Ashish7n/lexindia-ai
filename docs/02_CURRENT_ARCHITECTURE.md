# LexIndia-AI --- Current Architecture

## Overview

Known components: Flutter frontend (actual files still need inspection),
FastAPI backend, SQLite database, and scripts for downloading/extracting
English source material, parsing sections, translating, and validating
translation status.

## Known project structure

``` text
lexindia-ai/
├── .venv/
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── section_routes.py
│   ├── translate_law.py
│   ├── extract_law.py
│   ├── download_law.py
│   ├── validate_translations.py
│   ├── test_api.py
│   ├── requirements.txt
│   └── data/
│       ├── bns_english.pdf
│       ├── bns_extracted.txt
│       ├── bns_sections.json
│       ├── translation_audit.csv
│       └── lexindia.db
└── frontend/ (Flutter source; inspect before editing)
```

A `check_database.py` script was suggested but the user chose to skip
it; do not assume it exists or that an integrity audit was completed.

## Backend

`main.py` creates `FastAPI(title="LexIndia-AI API")`, exposes `GET /`,
and includes the section router. The development command used from
`backend/` is `python -m uvicorn main:app --reload`.

`section_routes.py` provides paginated listing/search, full section
lookup, language-specific lookup, and translation progress. See
`04_API_CONTRACT.md`.

## Database layer

SQLite file: `backend/data/lexindia.db`. Known functions in
`database.py`: `get_connection()`, `create_tables()`,
`import_sections()`, `get_section()`, and `get_translation_progress()`.

## Translation pipeline

`download_law.py`, `extract_law.py`, and `translate_law.py` are the
known processing scripts. Data artifacts include the official English
PDF, extracted text, parsed JSON, and translation audit CSV. The
extraction was reported as 112 pages and approximately 402,000
characters; the parser found 358 sections.

Groq models were tried, but free-tier token quota was exhausted during
earlier translation work. The process was interrupted. Do not assume all
sections are translated or that another run will fit the same quota.

`validate_translations.py` checks for Telugu Unicode characters and
status; it does not validate legal accuracy.

## Importer caution

The importer was adjusted to avoid overwriting existing Telugu fields
with incoming empty/non-Telugu values and to preserve status in common
cases. A later sync reported 0 inserted, 0 updated, and 358
unchanged/invalid. Incoming Telugu text can still potentially overwrite
existing text even if stale or incomplete. Inspect actual code before
changing synchronization behavior.

## Frontend status

The Flutter architecture is fully organized with typed models, repositories, and ChangeNotifier controllers:
- `LocalStorageService` handles local persistence with centralized `StorageKeys`.
- `BookmarkController` manages persistent bookmarks.
- `HistoryController` manages 20-item capped recency history.
- `ThemeController` manages and persists Light, Dark, and System modes.
- `LanguageController` manages and persists default reading language (`en`/`te`).
- `HomeScreen` provides a functional dashboard with search handoff, recency, and saved summaries.
- `BrowseScreen` provides server-side paginated catalog search.
- `SectionDetailScreen` provides full statutory text, language switching, copy, and sequential Previous/Next navigation.
- `SavedScreen` provides persistent bookmark review and deletion.
- `SettingsScreen` and `AboutScreen` provide preference selection and verified legal source attribution.

## Known verification and release build

Phase 8 verification confirmed:
- **Backend API**: **13 passing tests** (`pytest backend/test_api.py -v`), 1 Starlette deprecation warning (using `httpx` with `starlette.testclient`).
- **Frontend Quality**: **192 passing unit and widget tests** across 19 suites (`flutter test`), clean code formatting (`dart format lib test`), and **0 analyzer issues** (`flutter analyze`).
- **Production Build**: Verified web build (`flutter build web`) generated in `frontend/build/web`.
- **API Configuration**: Centralized in `AppConfig` (`frontend/lib/core/config/app_config.dart`), supporting compile-time `--dart-define=API_BASE_URL=https://<domain>` with automatic fallback to `http://127.0.0.1:8000` (web/desktop) and `http://10.0.2.2:8000` (Android emulator).
- **Backend CORS**: `main.py` configured with `CORSMiddleware` (`allow_origins=["*"]`). For production, origin restrictions should be applied in accordance with target domain policy. API load tests have not yet been run.
