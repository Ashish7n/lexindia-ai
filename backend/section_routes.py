
from fastapi import APIRouter, HTTPException, Query
from database import get_connection

router = APIRouter(prefix="/sections", tags=["BNS Sections"])



@router.get("/")
def list_sections(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None, max_length=200),
):
    offset = (page - 1) * page_size

    sql = """
        SELECT section_number, heading_en, text_en,
                   heading_te, text_te , translation_status
        FROM bns_sections
    """

    count_sql = "SELECT COUNT(*) FROM bns_sections"
    params = []
    count_params = []

    if search and search.strip():
        term = search.strip()

        if term.isdigit():
            condition = "section_number = ?"
            value = int(term)
        else:
            condition = """
                (
                    heading_en LIKE ? OR
                    heading_te LIKE ? OR
                    text_en LIKE ? OR
                    text_te LIKE ?
                )
            """
            value = f"%{term}%"

        sql += " WHERE " + condition
        count_sql += " WHERE " + condition

        if term.isdigit():
            params.append(value)
            count_params.append(value)
        else:
            params.extend([value] * 4)
            count_params.extend([value] * 4)

    sql += " ORDER BY section_number LIMIT ? OFFSET ?"
    params.extend([page_size, offset])

    with get_connection() as connection:
        total = connection.execute(
            count_sql, count_params
        ).fetchone()[0]

        rows = connection.execute(sql, params).fetchall()

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
        "sections": [dict(row) for row in rows],
    }



@router.get("/{section_number}")
def get_section(section_number: int):
    with get_connection() as connection:
        row = connection.execute("""
            SELECT *
            FROM bns_sections
            WHERE section_number = ?
        """, (section_number,)).fetchone()

    if row is None:
        raise HTTPException(
            status_code=404,
            detail="BNS section not found"
        )

    return dict(row)



@router.get("/{section_number}/language/{language}")
def get_section_by_language(
    section_number: int,
    language: str,
):
    language = language.lower()

    if language not in ["en", "te"]:
        raise HTTPException(
            status_code=400,
            detail="Unsupported language. Use 'en' for English or 'te' for Telugu."
        )

    with get_connection() as connection:
        row = connection.execute(
            """
            SELECT section_number, heading_en, text_en,
                   heading_te, text_te, translation_status
            FROM bns_sections
            WHERE section_number = ?
            """,
            (section_number,),
        ).fetchone()

    if row is None:
        raise HTTPException(
            status_code=404,
            detail="BNS section not found"
        )

    data = dict(row)

    if language == "en":
        return {
            "section_number": data["section_number"],
            "language": "en",
            "heading": data["heading_en"],
            "text": data["text_en"],
        }

    return {
        "section_number": data["section_number"],
        "language": "te",
        "heading": data["heading_te"],
        "text": data["text_te"],
        "translation_status": data["translation_status"],
    }

@router.get("/translation/progress")
def translation_progress():
    from database import get_translation_progress

    return get_translation_progress()