
import json
import os
import time
import shutil
from pathlib import Path

from dotenv import load_dotenv
from groq import Groq


# Paths
BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / "data"
SECTIONS_PATH = DATA_DIR / "bns_sections.json"
BACKUP_PATH = DATA_DIR / "bns_sections_backup.json"

# API configuration
load_dotenv(BASE_DIR / ".env")

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = os.getenv("GROQ_MODEL", "openai/gpt-oss-20b")

if not GROQ_API_KEY:
    raise ValueError(
        "GROQ_API_KEY not found. Add it to backend/.env."
    )

client = Groq(api_key=GROQ_API_KEY)

def has_telugu(text):
    """Check whether text contains Telugu characters."""
    return any("\u0C00" <= char <= "\u0C7F" for char in text)



def translate_section(section):
    """Translate one BNS section into Telugu using smaller chunks."""

    def translate_text(text, task):
        prompt = f"""
        You are a professional English-to-Telugu legal translator.

        Translate the supplied Bharatiya Nyaya Sanhita legal text into
        accurate, formal Telugu.

        Rules:
        1. Preserve the complete legal meaning.
        2. Do not summarize or omit anything.
        3. Preserve section numbers, clause numbers, references,
        explanations, exceptions, and illustrations.
        4. Do not add commentary.
        5. Return only the Telugu translation, without JSON or markdown.

        Task: {task}

        TEXT TO TRANSLATE:
        {text}
        """

        delays = [45, 90, 120]

        for attempt in range(4):
            try:
                response = client.chat.completions.create(
                    model=GROQ_MODEL,
                    messages=[
                        {
                            "role": "user",
                            "content": prompt,
                        }
                    ],
                    temperature=0.1,
                    max_completion_tokens=4000,
                )

                content = response.choices[0].message.content

                if not content or not content.strip():
                    raise ValueError("The API returned an empty response.")

                content = content.strip()

                if not has_telugu(content):
                    print("DEBUG: Response has no Telugu characters.")
                    print("DEBUG: Finish reason:", response.choices[0].finish_reason)
                    print("DEBUG: Response preview:", repr(content[:300]))

                    raise ValueError(
                        "Response contains no Telugu characters."
                    )

                return content

            except Exception as error:
                print(
                    f"API attempt {attempt + 1}/4 failed: {error}"
                )

                if attempt < 3:
                    wait_seconds = delays[attempt]
                    print(f"Waiting {wait_seconds} seconds...")
                    time.sleep(wait_seconds)

        raise RuntimeError(
            "Translation failed after 4 attempts."
        )

    heading_te = translate_text(
        section["heading_en"],
        "Translate only the legal section heading."
    )

    original_text = section["text_en"].strip()

    # Split at paragraph boundaries to keep requests manageable.
    paragraphs = original_text.splitlines()
    chunks = []
    current_chunk = ""

    for paragraph in paragraphs:
        paragraph = paragraph.strip()

        if not paragraph:
            continue

        if len(current_chunk) + len(paragraph) + 1 <= 2500:
            current_chunk += ("\n" if current_chunk else "") + paragraph
        else:
            if current_chunk:
                chunks.append(current_chunk)

            # Split exceptionally long individual paragraphs.
            while len(paragraph) > 2500:
                chunks.append(paragraph[:2500])
                paragraph = paragraph[2500:]

            current_chunk = paragraph

    if current_chunk:
        chunks.append(current_chunk)

    translated_chunks = []

    for index, chunk in enumerate(chunks, start=1):
        print(
            f"  Translating chunk {index}/{len(chunks)} "
            f"for section {section['section_number']}..."
        )

        translated_chunk = translate_text(
            chunk,
            "Translate this part of a legal provision completely. "
            "Preserve all numbers and clauses."
        )

        translated_chunks.append(translated_chunk)

    text_te = "\n".join(translated_chunks)

    if len(text_te) < len(original_text) * 0.25:
        raise ValueError("Combined translation is suspiciously short.")

    return heading_te, text_te

def save_sections(sections):
    """Save translation progress to the existing JSON file."""

    SECTIONS_PATH.write_text(
        json.dumps(sections, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def main():
    """Translate pending sections and save progress incrementally."""

    if not SECTIONS_PATH.exists():
        raise FileNotFoundError(
            f"Section JSON not found: {SECTIONS_PATH}\n"
            "Run extract_law.py first."
        )

    # Create one backup before modifying the original JSON.
    if not BACKUP_PATH.exists():
        shutil.copy2(SECTIONS_PATH, BACKUP_PATH)
        print(f"Backup created: {BACKUP_PATH}")

    with SECTIONS_PATH.open("r", encoding="utf-8") as file:
        sections = json.load(file)

    total = len(sections)
    translated = 0
    failed = []

    print(f"Total sections: {total}")
    print(f"Using Groq model: {GROQ_MODEL}")

    for index, section in enumerate(sections):
        section_number = section["section_number"]

        # Resume by skipping successfully translated sections.
        if (
            section.get("translation_status") == "translated"
            and has_telugu(section.get("heading_te", ""))
            and has_telugu(section.get("text_te", ""))
            and section.get("heading_te", "").strip()
            and section.get("text_te", "").strip()
        ):
            translated += 1
            continue

        print(
            f"\nTranslating section {section_number} "
            f"({index + 1}/{total})..."
        )

        success = False
        retry_delays = [50, 90, 120]
        total_attempts = 4

        for attempt in range(1, 2):
            try:
                heading_te, text_te = translate_section(section)

                section["heading_te"] = heading_te
                section["text_te"] = text_te
                section["translation_status"] = "translated"

                # Save after every successful section.
                save_sections(sections)

                translated += 1
                print(f"Section {section_number} translated and saved.")

                success = True
                break

            except Exception as error:
                print(
                    f"Attempt {attempt}/{total_attempts} failed "
                    f"for section {section_number}: {error}"
                )

                if attempt < total_attempts:
                    wait_seconds = retry_delays[attempt - 1]

                    print(
                        f"Retrying section {section_number} "
                        f"in {wait_seconds} seconds..."
                    )
                    time.sleep(wait_seconds)

        if not success:
            section["translation_status"] = "failed"
            save_sections(sections)
            failed.append(section_number)

            print(
                f"Section {section_number} failed after "
                f"{total_attempts} attempts. "
                "Continuing to the next section."
            )

    print("\nTranslation run finished.")
    print(f"Sections successfully translated: {translated}/{total}")
    print(f"Sections failed during this run: {failed}")
    print(f"Updated JSON: {SECTIONS_PATH}")
    print(f"Backup JSON: {BACKUP_PATH}")


if __name__ == "__main__":
    main()


