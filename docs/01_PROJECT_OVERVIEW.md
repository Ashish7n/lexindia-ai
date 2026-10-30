# LexIndia-AI --- Project Overview

## Purpose

LexIndia-AI is a Flutter mobile application for browsing and reading
Bharatiya Nyaya Sanhita (BNS) provisions. A FastAPI backend serves
section data from SQLite. The app is a legal-information reference, not
a substitute for advice from a qualified legal professional.

## Goals

-   Find provisions by section number, heading, or text.
-   Read long legal text comfortably.
-   Switch between English and Telugu where content exists.
-   Clearly communicate translation availability and review status.
-   Save bookmarks and recent sections locally.
-   Keep the architecture simple and testable before adding advanced
    features.

## Users

-   Law students and competitive-exam aspirants.
-   Members of the public looking up legal provisions.

## MVP scope

Browse/search BNS sections; server-side pagination; section details;
English/Telugu selection; translation availability notices; local
bookmarks and recent history; language and theme preferences; loading,
empty, offline, and error states; tests and documentation.

## Not established as implemented

AI legal answers, semantic/vector search, accounts, cloud-synced
bookmarks, production deployment, and legally verified review of every
Telugu translation. Do not present these as working features until
implemented and tested.

## Current data snapshot

The SQLite legal reference database (`lexindia.db`) contains 358 BNS sections:
- 315 marked `translated` (with Telugu characters in both heading and body).
- 43 marked `not_translated` (Sections 316–358, providing truthful untranslated notice and English fallback in the UI).
- 0 marked `failed`.
This reflects automated character and pipeline status checks, not certified legal review. Source attribution cites the Gazette of India / India Code. Phase 8 automated verification confirms 192 frontend tests and 13 backend tests passing.

## Confirmed design direction

Professional legal identity: navy `#14253F`, ivory `#F8F5EE`, restrained
antique gold `#B58B3B`, white surfaces `#FFFFFF`, body text `#354153`.
Light mode is default; dark and system modes are options. Reading
comfort is the primary design priority.

Primary navigation: Home, Browse, Saved, Settings. Section Details is
opened from search results, recent items, or bookmarks.

## Success criteria

A user can find a section, read the correct content, switch language
when available, bookmark it, and return later. Errors and translation
limitations are clearly explained, and unverified content is not
misrepresented as legally approved.
