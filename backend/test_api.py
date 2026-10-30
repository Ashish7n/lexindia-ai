
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_home_endpoint():
    response = client.get("/")

    assert response.status_code == 200

    data = response.json()
    assert data["status"] == "success"
    assert "message" in data


def test_list_sections():
    response = client.get("/sections/")

    assert response.status_code == 200

    data = response.json()
    assert "sections" in data
    assert "total" in data
    assert isinstance(data["sections"], list)


def test_section_pagination():
    response = client.get("/sections/?page=1&page_size=5")

    assert response.status_code == 200

    data = response.json()
    assert data["page"] == 1
    assert data["page_size"] == 5
    assert len(data["sections"]) <= 5


def test_section_search():
    response = client.get("/sections/?search=1")

    assert response.status_code == 200

    data = response.json()
    assert "sections" in data


def test_section_not_found():
    response = client.get("/sections/999999")

    assert response.status_code == 404


def test_translation_progress():
    response = client.get("/sections/translation/progress")

    assert response.status_code == 200

    data = response.json()
    assert "total_sections" in data
    assert "translated_sections" in data
    assert "remaining_sections" in data


def test_english_language_endpoint():
    response = client.get("/sections/1/language/en")

    assert response.status_code == 200

    data = response.json()
    assert data["language"] == "en"
    assert "heading" in data
    assert "text" in data


def test_telugu_language_endpoint():
    response = client.get("/sections/1/language/te")

    assert response.status_code == 200

    data = response.json()
    assert data["language"] == "te"
    assert "heading" in data
    assert "text" in data



def test_invalid_page_number():
    response = client.get("/sections/?page=0")

    assert response.status_code == 422


def test_page_size_over_limit():
    response = client.get("/sections/?page_size=101")

    assert response.status_code == 422


def test_unsupported_language():
    response = client.get("/sections/1/language/hi")

    assert response.status_code == 400


def test_missing_section_language_endpoint():
    response = client.get("/sections/999999/language/en")

    assert response.status_code == 404


def test_invalid_page_size_zero():
    response = client.get("/sections/?page_size=0")

    assert response.status_code == 422
