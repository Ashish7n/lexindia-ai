# LexIndia-AI --- Database Schema

## Database

SQLite at `backend/data/lexindia.db`. Known table: `bns_sections`.
Verify the live schema with `PRAGMA table_info(bns_sections)` before
migrations.

## Table: `bns_sections`

  ----------------------------------------------------------------------------------
  Field                  Type              Constraints/default   Meaning
  ---------------------- ----------------- --------------------- -------------------
  `section_number`       INTEGER           PRIMARY KEY           BNS section number

  `heading_en`           TEXT              NOT NULL DEFAULT ''   English heading

  `text_en`              TEXT              NOT NULL DEFAULT ''   English text

  `heading_te`           TEXT              NOT NULL DEFAULT ''   Telugu heading

  `text_te`              TEXT              NOT NULL DEFAULT ''   Telugu text

  `translation_status`   TEXT              NOT NULL DEFAULT      Translation
                                           'not_translated'      workflow status

  `source`               TEXT              NOT NULL DEFAULT ''   Source/provenance
                                                                 label

  `updated_at`           TEXT              NOT NULL DEFAULT      Update timestamp
                                           CURRENT_TIMESTAMP     
  ----------------------------------------------------------------------------------

An index on `translation_status` was reported.

## Status meanings

-   `translated`: marked as translated; this alone does not mean legally
    reviewed.
Latest verified counts in `backend/data/lexindia.db`:
- Total sections: 358
- Translated: 315 (with Telugu characters in both heading and body)
- Not translated: 43 (Sections 316–358)
- Failed: 0
The Telugu fields contain machine-drafted translations verified for Unicode presence and length, not certified legal review. Source provenance for all records cites "India Code - Bharatiya Nyaya Sanhita, 2023".

## Relationships and local data

`section_number` is the known primary key. No other database tables or
foreign keys were established. Bookmarks, recent history, and
preferences are planned as Flutter local storage for the MVP, not as
known backend tables.

## Synchronization rules discussed

The JSON-to-SQLite importer should insert new sections, avoid replacing
existing Telugu with empty/non-Telugu input, preserve existing
translations/status where appropriate, and log changes. A later run
reported 0 inserted, 0 updated, and 358 skipped as unchanged or invalid.

Caution: incoming Telugu content containing Telugu characters may still
overwrite existing text. Do not assume conflict handling is perfect.
Before import, back up the database and JSON, validate input, define
source-of-truth rules, log changes, and re-run validation.

## Validation

Recommended checks: unique section numbers; expected count; non-empty
English fields; accepted status values; Telugu fields present for
translated records; Telugu Unicode check; separate legal-quality review;
SQLite `PRAGMA integrity_check`.

The user chose to skip a proposed `check_database.py` run. Do not claim
a full integrity audit passed.

## Illustrative record

``` json
{
  "section_number": 1,
  "heading_en": "Example heading",
  "text_en": "Example legal text",
  "heading_te": "",
  "text_te": "",
  "translation_status": "not_translated",
  "source": "source identifier",
  "updated_at": "database timestamp"
}
```

This is a structural example, not actual legal content.
