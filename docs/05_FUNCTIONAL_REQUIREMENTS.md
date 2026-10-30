# LexIndia-AI --- Functional Requirements

## Home

-   Show app identity and concise introduction.
-   Prominent search and Browse BNS shortcut.
-   Show recent and saved sections when available.
-   Provide a useful first-launch state.
-   Do not fetch all full legal texts just to render Home.
-   Keep local bookmarks available during server outages.

## Browse/search

-   Browse sections with server-side pagination.
-   Search section number, heading, or text.
-   Numeric query follows exact-number backend behavior.
-   Text query uses `search`.
-   Debounce typing; reset page on a new query.
-   Ignore stale responses.
-   Show section number and heading in results.
-   Preserve query/page when returning from details where practical.
-   Handle loading, empty, offline, and retry states.
-   Keep `page_size` within 1--100.

## Section details

-   Show section number, heading, and full legal text.
-   Support English/Telugu selector using the language endpoint.
-   Show loading feedback during requests and language switches.
-   Explain unavailable Telugu and offer English explicitly.
-   Never show English while labelling it Telugu.
-   Do not claim legal verification unless source data supports it.
-   Support long text without overflow/freezing.
-   Provide bookmark, copy, and share actions.
-   Show source information where available.
-   Include an accessible legal-information disclaimer.

## Bookmarks

-   Save from section details.
-   Open or remove saved sections.
-   Keep bookmark state consistent across screens.
-   Persist locally across app restarts.
-   Show an empty state.
-   No login or cloud sync for MVP.
-   Preserve bookmarks if a server fetch temporarily fails.

## Recent history

-   Record viewed sections locally.
-   Update recency instead of duplicating an existing section.
-   Keep a bounded list.
-   Persist across restarts.
-   Support opening recent sections and an empty state.

## Language

-   Support `en` and `te`.
-   Persist default language locally.
-   A preference does not mean every section has a translation.
-   Use a Telugu-capable font and verify wrapping/paragraph layout.

## Settings

-   Light default; Dark and System options.
-   Persist appearance preference.
-   Language preference, About, source information, translation
    limitations, and legal disclaimer.
-   Do not add account features that do not exist.

## Copy/share

-   Operate only on content actually loaded.
-   Share actual section text and useful identifying metadata.
-   Show success only after the action succeeds.
-   Handle platform errors safely.

## Errors/accessibility

-   Handle 400, 404, 422, server errors, timeouts, and connectivity
    errors.
-   Do not show stack traces.
-   Support system text scaling, semantic labels, adequate contrast and
    tap targets.
-   Prevent clipping on small screens and with long headings.
-   Do not fabricate legal text to fill missing data.

## Explicit MVP non-goals

AI-generated legal answers, semantic search, user accounts, cloud
bookmarks, payments, and claims of verified translations are out of
scope unless separately approved and implemented.

## Verification Status (Phase 8 Complete)

All functional requirements specified above are implemented and backed by automated test suites (192 Flutter tests, 13 FastAPI backend tests). Manual acceptance procedures and responsive verification across viewports (320px to 1200px) have confirmed no regressions or uncaught exceptions.
