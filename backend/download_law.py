
from pathlib import Path
import requests

# Official English BNS PDF
PDF_URL = (
    "https://www.indiacode.nic.in/bitstream/"
    "123456789/20062/1/a202345.pdf"
)

# Folder where we will save the PDF
DATA_DIR = Path(__file__).parent / "data"
PDF_PATH = DATA_DIR / "bns_english.pdf"


def download_pdf():
    """Download the official English BNS PDF."""

    # Create the data folder if it does not exist
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # Avoid downloading the same PDF again
    if PDF_PATH.exists() and PDF_PATH.stat().st_size > 0:
        print(f"PDF already exists: {PDF_PATH}")
        return

    print("Downloading the official BNS PDF...")

    response = requests.get(PDF_URL, timeout=60)
    response.raise_for_status()

    # Check whether the downloaded file is a PDF
    if not response.content.startswith(b"%PDF-"):
        raise ValueError("The downloaded file is not a valid PDF.")

    # Save the PDF
    PDF_PATH.write_bytes(response.content)

    print(f"Download complete: {PDF_PATH}")



download_pdf()