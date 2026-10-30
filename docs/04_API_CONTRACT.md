# LexIndia-AI --- API Contract

## Conventions

Base URL is environment-specific and should be configured once. Confirm
exact JSON fields in the current source before implementing frontend
models. Examples below are illustrative.

## `GET /`

Basic backend status.

``` json
{"message":"LexIndia-AI backend is running","status":"success"}
```

Expected status: `200`. This is not a full dependency-readiness check.

## `GET /sections/`

List/search BNS sections.

  -----------------------------------------------------------------------
  Query parameter   Type              Default           Rules
  ----------------- ----------------- ----------------- -----------------
  `page`            integer           1                 Minimum 1

  `page_size`       integer           20                1--100

  `search`          string            omitted           Numeric query is
                                                        exact section
                                                        number; text
                                                        query searches
                                                        English/Telugu
                                                        fields
  -----------------------------------------------------------------------

Known response keys: `total`, `page`, `page_size`, `total_pages`,
`sections`. Section item fields are sourced from the database; inspect
current route to confirm exact selection.

``` json
{
  "total": 358,
  "page": 1,
  "page_size": 20,
  "total_pages": 18,
  "sections": [
    {
      "section_number": 1,
      "heading_en": "Example heading",
      "text_en": "Example text",
      "heading_te": "",
      "text_te": "",
      "translation_status": "not_translated",
      "source": ""
    }
  ]
}
```

The example section content is not real legal text. `total_pages` varies
with the actual total/page size.

Tested errors: `page=0`, `page_size=0`, and `page_size=101` return
`422`. Search with no matches should produce an empty list if current
route uses standard list semantics.

## `GET /sections/{section_number}`

Returns the full section record. Expected `200`; nonexistent section
returns `404`. Known implementation uses `SELECT *`, so the response may
include `section_number`, English/Telugu fields, status, source, and
`updated_at`. Verify actual fields.

## `GET /sections/{section_number}/language/{language}`

Supported language values: `en`, `te`. - Success: `200`, fields include
`section_number`, `language`, `heading`, `text`. - Telugu response was
reported to include `translation_status`. - Unsupported language such as
`hi`: tested `400`. - Missing section: tested `404`.

Do not label content as Telugu if the Telugu fields are empty or the
response contains English fallback content.

## `GET /sections/translation/progress`

Known keys: `total_sections`, `translated_sections`,
`remaining_sections`. Verified current live response:

``` json
{"total_sections":358,"translated_sections":315,"remaining_sections":43}
```

The frontend client connects via `AppConfig` (`frontend/lib/core/config/app_config.dart`). At build or run time, specify `--dart-define=API_BASE_URL=https://<your-backend-domain>` or rely on the default development fallback `http://127.0.0.1:8000`.

These values are not constants.

## Error behavior

Known tested status codes: - `400`: unsupported language. - `404`:
missing section. - `422`: invalid query/path parameters. Exact
error-body schema has not been recorded; inspect actual responses and
handle defensively.

Frontend handling: - 400: invalid/unsupported request. - 404: missing
section. - 422: invalid parameters. - Network/timeouts: retry state. -
5xx: service error and retry. - Empty search: empty state, not fatal
error.

## Not established

Do not invent endpoints for authentication, bookmarks, history, AI legal
answers, semantic search, or translation writes. These require separate
design and implementation.

## Performance

Thirteen functional tests passed, but no latency/load benchmark has been
completed. Text `LIKE` searches across full text may need measurement as
data grows; optimize based on evidence.
