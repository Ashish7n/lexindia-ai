# pyrefly: ignore[missing-import]

import json
import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

JSON_PATH = DATA_DIR / "bns_sections.json"
DATABASE_PATH = DATA_DIR / "lexindia.db"


def get_connection():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")

    return connection


def create_tables():
    with get_connection() as connection:
        connection.execute("""
            CREATE TABLE IF NOT EXISTS bns_sections (
                section_number INTEGER PRIMARY KEY,
                heading_en TEXT NOT NULL DEFAULT '',
                text_en TEXT NOT NULL DEFAULT '',
                heading_te TEXT NOT NULL DEFAULT '',
                text_te TEXT NOT NULL DEFAULT '',
                translation_status TEXT NOT NULL DEFAULT 'not_translated',
                source TEXT NOT NULL DEFAULT '',
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)

        connection.execute("""
            CREATE INDEX IF NOT EXISTS idx_bns_translation_status
            ON bns_sections(translation_status)
        """)

    print(f"Database ready: {DATABASE_PATH}")



def has_telugu(text):
    return any("\u0C00" <= char <= "\u0C7F" for char in (text or ""))


def import_sections():
    if not JSON_PATH.exists():
        raise FileNotFoundError(
            f"Sections JSON not found: {JSON_PATH}"
        )

    with JSON_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)

    if isinstance(data, dict):
        data = data.get("sections", [])

    if not isinstance(data, list):
        raise ValueError("Expected a list of BNS section records.")

    inserted = 0
    updated = 0
    skipped = 0

    with get_connection() as connection:
        for section in data:
            if not isinstance(section, dict):
                skipped += 1
                continue

            number = section.get("section_number")
            if number is None:
                skipped += 1
                continue

            number = int(number)

            incoming_heading_en = section.get("heading_en") or ""
            incoming_text_en = section.get("text_en") or ""
            incoming_heading_te = section.get("heading_te") or ""
            incoming_text_te = section.get("text_te") or ""
            incoming_status = section.get(
                "translation_status", "not_translated"
            )
            incoming_source = section.get("source") or ""

            existing = connection.execute(
                """
                SELECT *
                FROM bns_sections
                WHERE section_number = ?
                """,
                (number,),
            ).fetchone()

            if existing is None:
                # Never mark a record translated unless both fields
                # contain Telugu characters.
                if not (
                    has_telugu(incoming_heading_te)
                    and has_telugu(incoming_text_te)
                ):
                    incoming_status = (
                        "failed"
                        if incoming_status == "failed"
                        else "not_translated"
                    )

                connection.execute(
                    """
                    INSERT INTO bns_sections (
                        section_number, heading_en, text_en,
                        heading_te, text_te, translation_status,
                        source, updated_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                    """,
                    (
                        number,
                        incoming_heading_en,
                        incoming_text_en,
                        incoming_heading_te,
                        incoming_text_te,
                        incoming_status,
                        incoming_source,
                    ),
                )
                inserted += 1
                continue

            old = dict(existing)

            # Preserve existing English fields if incoming values are empty.
            heading_en = incoming_heading_en or old["heading_en"]
            text_en = incoming_text_en or old["text_en"]

            # Accept incoming Telugu only when it contains Telugu characters.
            heading_te = (
                incoming_heading_te
                if has_telugu(incoming_heading_te)
                else old["heading_te"]
            )
            text_te = (
                incoming_text_te
                if has_telugu(incoming_text_te)
                else old["text_te"]
            )

            valid_telugu = (
                has_telugu(heading_te) and has_telugu(text_te)
            )

            # Preserve a valid existing translation if incoming data is
            # incomplete. Never downgrade it to not_translated.
            if old["translation_status"] == "translated" and valid_telugu:
                status = "translated"
            elif (
                incoming_status == "translated"
                and valid_telugu
            ):
                status = "translated"
            elif incoming_status == "failed" and not valid_telugu:
                status = "failed"
            elif valid_telugu and incoming_status == "translated":
                status = "translated"
            else:
                status = (
                    old["translation_status"]
                    if old["translation_status"] == "translated"
                    else incoming_status
                )

            # Count unchanged records separately.
            new_values = (
                heading_en,
                text_en,
                heading_te,
                text_te,
                status,
                incoming_source or old["source"],
            )
            old_values = (
                old["heading_en"],
                old["text_en"],
                old["heading_te"],
                old["text_te"],
                old["translation_status"],
                old["source"],
            )

            if new_values == old_values:
                skipped += 1
                continue

            connection.execute(
                """
                UPDATE bns_sections
                SET heading_en = ?,
                    text_en = ?,
                    heading_te = ?,
                    text_te = ?,
                    translation_status = ?,
                    source = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE section_number = ?
                """,
                (*new_values, number),
            )
            updated += 1

    print("Database synchronization complete.")
    print(f"New sections inserted: {inserted}")
    print(f"Existing sections updated: {updated}")
    print(f"Unchanged or invalid records skipped: {skipped}")


def get_section(section_number):
    with get_connection() as connection:
        row = connection.execute("""
            SELECT *
            FROM bns_sections
            WHERE section_number = ?
        """, (section_number,)).fetchone()

    return dict(row) if row else None


def get_translation_progress():
    with get_connection() as connection:
        total = connection.execute("""
            SELECT COUNT(*) FROM bns_sections
        """).fetchone()[0]

        translated = connection.execute("""
            SELECT COUNT(*)
            FROM bns_sections
            WHERE translation_status = 'translated'
        """).fetchone()[0]

    return {
        "total_sections": total,
        "translated_sections": translated,
        "remaining_sections": total - translated
    }


if __name__ == "__main__":
    create_tables()
    import_sections()

    print("\nTranslation progress:")
    print(get_translation_progress())
