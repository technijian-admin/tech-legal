"""
Patch the docx-library content-type bug for the 3 leave application DOCX files,
then convert each to PDF using Word COM automation.
Output: leave-applications/pdf/
"""

import os
import shutil
import zipfile
import tempfile
from pathlib import Path

import win32com.client

ROOT = Path(__file__).parent
SRC_DIR = ROOT / "leave-applications"
PDF_DIR = SRC_DIR / "pdf"
PDF_DIR.mkdir(exist_ok=True)

DOCX_FILES = [
    "01-Yogesh-Kumar-Leave-Application.docx",
    "02-Rahul-Uniyal-Leave-Application.docx",
    "03-Suresh-Kumar-Sharma-Leave-Application.docx",
]


def patch_docx(docx_path: Path) -> None:
    """
    npm docx library embeds logo as media/<hash>.undefined which breaks Word.
    Patch [Content_Types].xml to add a Default for 'undefined' extension,
    then rename .undefined references to .png in the .rels files.
    """
    work = Path(tempfile.mkdtemp())
    try:
        with zipfile.ZipFile(docx_path, "r") as zin:
            zin.extractall(work)

        # 1. Patch [Content_Types].xml
        ct_path = work / "[Content_Types].xml"
        ct = ct_path.read_text(encoding="utf-8")
        if "Extension=\"undefined\"" not in ct:
            ct = ct.replace(
                "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">",
                "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\"><Default Extension=\"undefined\" ContentType=\"image/png\"/>",
                1,
            )
            ct_path.write_text(ct, encoding="utf-8")

        # 2. Repack
        new_path = docx_path.with_suffix(".docx.tmp")
        with zipfile.ZipFile(new_path, "w", zipfile.ZIP_DEFLATED) as zout:
            for root, _, files in os.walk(work):
                for f in files:
                    full = Path(root) / f
                    arc = full.relative_to(work).as_posix()
                    zout.write(full, arc)
        os.replace(new_path, docx_path)
    finally:
        shutil.rmtree(work, ignore_errors=True)


def docx_to_pdf(word, docx_path: Path, pdf_path: Path) -> None:
    """Open DOCX in Word and SaveAs2 as PDF (FileFormat=17)."""
    doc = word.Documents.Open(
        str(docx_path),
        ConfirmConversions=False,
        ReadOnly=True,
        AddToRecentFiles=False,
    )
    try:
        doc.SaveAs2(str(pdf_path), FileFormat=17)
    finally:
        doc.Close(SaveChanges=False)


def main():
    print(f"Source: {SRC_DIR}")
    print(f"Output: {PDF_DIR}\n")

    print("Patching DOCX content types...")
    for name in DOCX_FILES:
        path = SRC_DIR / name
        if not path.exists():
            raise FileNotFoundError(path)
        patch_docx(path)
        print(f"  [patched] {name}")

    print("\nLaunching Word for PDF conversion...")
    word = win32com.client.DispatchEx("Word.Application")
    word.Visible = False
    word.DisplayAlerts = 0  # wdAlertsNone
    try:
        for name in DOCX_FILES:
            docx_path = SRC_DIR / name
            pdf_name = name.replace(".docx", ".pdf")
            pdf_path = PDF_DIR / pdf_name
            print(f"  [pdf] {name} -> {pdf_name}", end=" ")
            docx_to_pdf(word, docx_path, pdf_path)
            size_kb = pdf_path.stat().st_size / 1024
            print(f"({size_kb:.1f} KB)")
    finally:
        word.Quit()

    print("\nDone.")


if __name__ == "__main__":
    main()
