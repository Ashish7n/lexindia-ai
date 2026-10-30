# LexIndia-AI --- Testing and Acceptance

## Current known status (Phase 8 Verified)

The latest test runs report:
- **Backend**: **13 passing tests** (`pytest backend/test_api.py -v`), 1 Starlette deprecation warning.
- **Frontend**: **193 passing tests** across 19 unit and widget test suites (`flutter test`), **0 analyzer issues** (`flutter analyze`), clean formatting (`dart format lib test`), and a successful web production build (`flutter build web`).

Run from `backend/` with the virtual environment active:

``` powershell
python -m pytest test_api.py -v
```

## Backend expectations

-   `GET /`: 200, success status.
-   List sections: 200 with pagination metadata and list.
-   `page=1&page_size=5`: at most five results.
-   Search: 200 with `sections`.
-   Missing section: 404.
-   Translation progress: 200 with expected counts.
-   English/Telugu language endpoints: 200 for existing section.
-   `page=0`, `page_size=0`, `page_size=101`: 422.
-   Unsupported language `hi`: 400.
-   Missing section language endpoint: 404.

## Flutter integration acceptance

### Browse/search

-   Real API data loads.
-   Pagination respects server limit and does not duplicate results.
-   Numeric/text search follows backend behavior.
-   Empty state, loading, retry, stale-response protection, query/page
    preservation work.

### Section details

-   Correct section opens.
-   Full content comes from API.
-   Language switch uses correct endpoint.
-   Missing translation is explained honestly.
-   Long text is readable and doesn't overflow.
-   Source/status reflects actual data.

### Bookmarks/history

-   Bookmark, open, remove work.
-   State updates across screens.
-   Bookmarks and recent history survive restart.
-   Recent list avoids duplicates and is bounded.
-   Local saved data remains available during temporary network failure.

### Preferences/accessibility

-   Light default; Dark/System work and persist.
-   Language preference persists.
-   Telugu renders correctly.
-   Text scaling, contrast, semantic labels, tap targets, and responsive
    layouts are acceptable.

### Errors

Handle 400, 404, 422, 5xx, timeouts, connectivity failures, and invalid
responses. No raw exceptions in user-facing UI. Copy/share success
appears only after success.

## Flutter quality commands

Run where supported:

``` powershell
flutter pub get
flutter analyze
flutter test
```

Use mocked responses for deterministic tests. Do not claim commands
passed unless actually run.

## Translation/data caveat

The verified SQLite database contains 358 total sections, 315 translated, and 43 not translated (Sections 316–358). Automated Unicode checks confirm the presence of Telugu glyphs, but this does not constitute certified legal translation quality. The UI explicitly alerts users to this limitation and cites the official India Code source.

## Phase 8 End-to-End Acceptance and Verification Matrix

### 1. Automated Verification (All Passing)
- **Home Dashboard & Empty States**: `test/widget/home_screen_test.dart`
- **Home-to-Browse Search Handoff**: `test/widget/home_screen_test.dart`, `test/widget/navigation_test.dart`
- **Numeric & Keyword Search**: `test/widget/browse_screen_test.dart`, `test/unit/section_repository_test.dart`, `backend/test_api.py`
- **Pagination & Stale-Response Protection**: `test/widget/browse_screen_test.dart`, `test/unit/connectivity_recovery_test.dart`
- **Section Details & Copy Feedback**: `test/widget/section_detail_screen_test.dart`
- **Previous/Next Navigation at Section 1 & 358**: `test/widget/section_detail_screen_test.dart`
- **English/Telugu Language Switching & Fallback**: `test/widget/section_detail_screen_test.dart`, `test/widget/section_detail_language_preference_test.dart`
- **Bookmark Persistence & Saved Screen**: `test/unit/bookmark_controller_test.dart`, `test/widget/saved_screen_test.dart`, `test/widget/section_detail_bookmark_test.dart`
- **Recent History Ordering & 20-Item Cap**: `test/unit/history_controller_test.dart`, `test/widget/section_detail_history_test.dart`
- **Theme & Language Preference Persistence**: `test/unit/theme_controller_test.dart`, `test/unit/language_controller_test.dart`, `test/widget/settings_screen_test.dart`
- **About Screen, Legal Attribution & Disclaimer**: `test/widget/about_screen_test.dart`, `test/widget/settings_screen_test.dart`
- **Network Failure, Retry & Recovery**: `test/unit/connectivity_recovery_test.dart`, `test/widget/section_detail_screen_test.dart`
- **Responsive Layouts (320px to 1200px) & 1.5x Text Scale**: `test/widget/responsive_text_scale_test.dart`, `test/widget/settings_screen_test.dart`
- **Keyboard Navigation & Accessibility (48dp targets, tooltips)**: `test/widget/accessibility_test.dart`
- **AppConfig Base URL & Serialization**: `test/unit/api_client_test.dart`

### 2. Manual Release Verification Checklist (To Be Run On Final Target Deployments)
- [x] Backend running on `http://127.0.0.1:8000` via Uvicorn.
- [x] Flutter web build completes cleanly into `frontend/build/web`.
- [ ] In live browser: Search `42` (numeric) and verify exact Section 42 card renders.
- [ ] In live browser: Search `murder` (text) and verify Section 103 card renders.
- [ ] In live browser: Open Section 1; verify "Previous" button is disabled and "Next" goes to Section 2.
- [ ] In live browser: Open Section 358; verify "Next" button is disabled and "Previous" goes to Section 357.
- [ ] In live browser: Switch to Telugu on Section 1 (translated); verify Telugu legal text renders.
- [ ] In live browser: Switch to Telugu on Section 358 (untranslated); verify alert banner renders and English switch works.
- [ ] In live browser: Toggle Bookmark on Section 1; navigate to Saved tab; verify Section 1 appears.
- [ ] In live browser: Refresh browser page; verify Saved item and Theme preference persist.
- [ ] In live browser: Stop backend; attempt opening Section 10; verify recoverable error card with Retry button renders.
- [ ] In live browser: Restart backend; click Retry; verify Section 10 content loads.

## Performance

No latency or load benchmark has been completed. Measure average and p95
response time, throughput, and error rate under a defined load before
claiming performance.

## Definition of done

Feature behavior matches requirements; loading/empty/error states exist;
correct API/local storage is used; tests cover important paths;
analysis/tests pass or failures are documented; manual device
verification is recorded where practical; existing behavior is
preserved; no inert control is presented as functional.
