
import json
import re
from pathlib import Path

# pyrefly: ignore[missing-import]
import pymupdf


# Paths
BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / "data"
PDF_PATH = DATA_DIR / "bns_english.pdf"
TEXT_PATH = DATA_DIR / "bns_extracted.txt"
SECTIONS_PATH = DATA_DIR / "bns_sections.json"

SECTION_ONE_TITLE = "Short title, commencement and application"


def extract_pdf_text():
    """Extract text from every page of the BNS PDF."""

    if not PDF_PATH.exists():
        raise FileNotFoundError(
            f"BNS PDF not found: {PDF_PATH}\n"
            "Run download_law.py first."
        )

    pages = []

    with pymupdf.open(PDF_PATH) as document:
        for page_number, page in enumerate(document, start=1):
            page_text = page.get_text("text")
            pages.append(
                f"\n--- PAGE {page_number} ---\n{page_text}"
            )

    full_text = "\n".join(pages)

    TEXT_PATH.write_text(full_text, encoding="utf-8")

    print(f"Pages processed: {len(pages)}")
    print(f"Extracted text saved to: {TEXT_PATH}")
    print(f"Total characters extracted: {len(full_text)}")

    return full_text


def find_actual_act_start(text):
    """Find the actual Section 1 provision, not a contents entry."""

    matches = list(
        re.finditer(
            rf"(?m)^[ \t]*1\.\s+{re.escape(SECTION_ONE_TITLE)}",
            text,
            flags=re.IGNORECASE,
        )
    )

    for match in reversed(matches):
        following_text = text[match.start():match.start() + 1500]

        if re.search(
            r"shall come into force|comes into force|appointed date|"
            r"Central Government",
            following_text,
            flags=re.IGNORECASE,
        ):
            print(
                f"Using Section 1 occurrence at character "
                f"{match.start()}."
            )
            return match.start()

    raise ValueError(
        "Could not confidently identify the actual Section 1. "
        "Inspect bns_extracted.txt before continuing."
    )



def parse_section(full_text):
    """Extract numbered BNS sections while allowing missed headings."""

    start = find_actual_act_start(full_text)
    actual_text = full_text[start:]

   
    heading_pattern = re.compile(
        r"(?m)^[ \t]*(\d{1,3})[.]"
        r"(?:[ \t]*[—–-][ \t]*|[ \t]+)"
        r"([^\n]{1,200})"
    )


    candidates = list(heading_pattern.finditer(actual_text))

    accepted_matches = []
    last_section_number = 0

    for match in candidates:
        section_number = int(match.group(1))
        heading = match.group(2).strip()

        # The BNS section numbers range from 1 through 358.
        if not 1 <= section_number <= 358:
            continue

        # Ignore repeated or decreasing numbers, such as footnote 1.
        if section_number <= last_section_number:
            continue

        # Avoid treating unusually long lines as headings.
        if not heading or len(heading) > 200:
            continue

        accepted_matches.append(match)
        last_section_number = section_number

    if not accepted_matches:
        raise ValueError("No section headings were detected.")

    sections = []

    for index, match in enumerate(accepted_matches):
        section_number = int(match.group(1))
        heading = match.group(2).strip()

        section_start = match.start()
        section_end = (
            accepted_matches[index + 1].start()
            if index + 1 < len(accepted_matches)
            else len(actual_text)
        )

        section_text = actual_text[section_start:section_end].strip()

        section_text = re.sub(
            r"(?m)^--- PAGE \d+ ---[ \t]*\n?",
            "",
            section_text,
        ).strip()

        sections.append({
            "section_number": section_number,
            "heading_en": heading,
            "text_en": section_text,
            "heading_te": "",
            "text_te": "",
            "translation_status": "not_translated",
            "source": "India Code - Bharatiya Nyaya Sanhita, 2023",
        })

    detected_numbers = {
        section["section_number"] for section in sections
    }
    missing_numbers = sorted(set(range(1, 359)) - detected_numbers)

    print(f"Sections detected: {len(sections)}")
    print(f"Missing section numbers: {missing_numbers}")

    for section in sections[:5]:
        print(
            f"\nSection {section['section_number']}: "
            f"{section['heading_en']}"
        )
        print(section["text_en"][:250])

    if missing_numbers:
        print(
            "\nWARNING: Some sections are missing. "
            "Validate the extracted data before using it."
        )

    return sections




def save_sections(sections):
    """Save the extracted sections as readable JSON."""

    DATA_DIR.mkdir(parents=True, exist_ok=True)

    SECTIONS_PATH.write_text(
        json.dumps(sections, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"\nSections saved: {len(sections)}")
    print(f"Saved section data to: {SECTIONS_PATH}")



def validate_sections(sections):
    """Check section numbering, duplicates, and empty text."""

    numbers = [section["section_number"] for section in sections]
    expected_numbers = list(range(1, 359))

    if numbers != expected_numbers:
        print("VALIDATION FAILED: Section numbers are missing or out of order.")
        return False

    for section in sections:
        if not section["heading_en"].strip():
            print(f"VALIDATION FAILED: Section {section['section_number']} has no heading.")
            return False

        if not section["text_en"].strip():
            print(f"VALIDATION FAILED: Section {section['section_number']} has no text.")
            return False

    for number in (1, 2, 48, 254, 255, 256, 358):
        section = sections[number - 1]

        print(f"\nSection {number}: {section['heading_en']}")
        print(f"Text length: {len(section['text_en'])} characters")
        print(f"Text starts: {section['text_en'][:150]}")
        print(f"Text ends: {section['text_en'][-150:]}")

        if number < 358:
            next_section = sections[number]
            next_number = next_section["section_number"]

            if next_number != number + 1:
                print(f"WARNING: Unexpected next section after {number}.")

    print("\nBasic section validation passed.")
    print("Note: This does not prove every legal provision is complete.")
    return True


def main():
    full_text = extract_pdf_text()
    sections = parse_section(full_text)

    if not validate_sections(sections):
        raise ValueError("Section validation failed. JSON was not saved.")

    save_sections(sections)


if __name__ == "__main__":
    main()
