import csv
import json
import re
from collections import Counter
from difflib import SequenceMatcher
from pathlib import Path


BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / "data"
JSON_PATH = DATA_DIR / "bns_sections.json"
CSV_PATH = DATA_DIR / "translation_audit.csv"

TELUGU_PATTERN = re.compile(r"[\u0C00-\u0C7F]")
ENGLISH_PATTERN = re.compile(r"[A-Za-z]")
WHITESPACE_PATTERN = re.compile(r"\s+")

EXPECTED_SECTIONS = set(range(1, 359))


def clean_text(text):
    """Normalize text for comparison without changing the source file."""
    text = str(text or "").strip().lower()
    return WHITESPACE_PATTERN.sub(" ", text)


def audit_section(section):
    """Check one section and return its audit findings."""

    number = section.get("section_number", "")
    status = str(section.get("translation_status", "")).strip()

    heading_en = str(section.get("heading_en", "") or "").strip()
    text_en = str(section.get("text_en", "") or "").strip()
    heading_te = str(section.get("heading_te", "") or "").strip()
    text_te = str(section.get("text_te", "") or "").strip()

    issues = []

    if status != "translated":
        issues.append("STATUS_NOT_TRANSLATED")

    if not heading_te:
        issues.append("MISSING_TELUGU_HEADING")

    if not text_te:
        issues.append("MISSING_TELUGU_TEXT")

    if text_te:
        telugu_count = len(TELUGU_PATTERN.findall(text_te))
        english_count = len(ENGLISH_PATTERN.findall(text_te))
        total_letters = telugu_count + english_count

        if len(text_te) < 50:
            issues.append("VERY_SHORT_TRANSLATION")

        if total_letters > 0:
            telugu_ratio = telugu_count / total_letters

            if telugu_ratio < 0.20:
                issues.append("LOW_TELUGU_CONTENT")

        # Flag text that appears almost identical to the English source.
        source_normalized = clean_text(text_en)
        translated_normalized = clean_text(text_te)

        if source_normalized and translated_normalized:
            similarity = SequenceMatcher(
                None,
                source_normalized,
                translated_normalized
            ).ratio()

            if similarity >= 0.85:
                issues.append("POSSIBLE_COPIED_ENGLISH")
        else:
            similarity = 0.0

    else:
        telugu_count = 0
        english_count = 0
        similarity = 0.0

    # Check whether the translated heading also contains Telugu.
    if heading_te:
        heading_telugu_count = len(
            TELUGU_PATTERN.findall(heading_te)
        )

        if heading_telugu_count == 0:
            issues.append("HEADING_HAS_NO_TELUGU")

    if not issues:
        issues.append("NO_AUTOMATED_FLAGS")

    return {
        "section_number": number,
        "translation_status": status,
        "heading_en": heading_en,
        "heading_te": heading_te,
        "english_text_length": len(text_en),
        "telugu_text_length": len(text_te),
        "telugu_character_count": telugu_count,
        "english_character_count": english_count,
        "source_similarity": round(similarity, 3),
        "audit_result": "; ".join(issues),
    }


def main():
    if not JSON_PATH.exists():
        print(f"ERROR: File not found: {JSON_PATH}")
        return

    try:
        with JSON_PATH.open("r", encoding="utf-8") as file:
            sections = json.load(file)
    except json.JSONDecodeError as error:
        print(f"ERROR: JSON file is invalid: {error}")
        return

    if not isinstance(sections, list):
        print("ERROR: Expected the JSON file to contain a list.")
        return

    results = []
    seen_numbers = []
    invalid_number_records = 0

    for section in sections:
        if not isinstance(section, dict):
            invalid_number_records += 1
            continue

        number = section.get("section_number")

        try:
            parsed_number = int(number)
            seen_numbers.append(parsed_number)
        except (TypeError, ValueError):
            invalid_number_records += 1

        results.append(audit_section(section))

    counts = Counter(
        row["translation_status"] or "MISSING_STATUS"
        for row in results
    )

    number_counts = Counter(seen_numbers)
    duplicates = sorted(
        number for number, count in number_counts.items()
        if count > 1
    )

    missing_numbers = sorted(EXPECTED_SECTIONS - set(seen_numbers))
    unexpected_numbers = sorted(set(seen_numbers) - EXPECTED_SECTIONS)

    flagged = [
        row for row in results
        if row["audit_result"] != "NO_AUTOMATED_FLAGS"
    ]

    DATA_DIR.mkdir(parents=True, exist_ok=True)

    columns = [
        "section_number",
        "translation_status",
        "heading_en",
        "heading_te",
        "english_text_length",
        "telugu_text_length",
        "telugu_character_count",
        "english_character_count",
        "source_similarity",
        "audit_result",
    ]

    with CSV_PATH.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.DictWriter(file, fieldnames=columns)
        writer.writeheader()
        writer.writerows(results)

    print("\n========== BNS TRANSLATION AUDIT ==========")
    print(f"JSON sections found: {len(results)}")
    print(f"Translation statuses: {dict(counts)}")
    print(f"Sections with automated flags: {len(flagged)}")
    print(f"Duplicate section numbers: {duplicates}")
    print(f"Missing section numbers: {missing_numbers}")
    print(f"Unexpected section numbers: {unexpected_numbers}")
    print(f"Invalid section records: {invalid_number_records}")
    print(f"\nCSV report saved to:\n{CSV_PATH}")

    print("\nSections needing review:")
    for row in flagged:
        print(
            f"Section {row['section_number']}: "
            f"{row['audit_result']}"
        )

    print("\nAudit complete. Original JSON was not modified.")


if __name__ == "__main__":
    main()
