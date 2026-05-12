"""One-off: patch + convert ONLY the revised Rajat MSA DOCX to PDF (after regenerate)."""
import os, shutil, zipfile, tempfile
from pathlib import Path
import win32com.client

ROOT = Path(__file__).parent
SRC_DIR = ROOT / "letters"
PDF_DIR = SRC_DIR / "pdf"
PDF_DIR.mkdir(exist_ok=True)
NAME = "02-Rajat-Kumar-Mutual-Separation-Agreement.docx"


def patch_docx(docx_path):
    work = Path(tempfile.mkdtemp())
    try:
        with zipfile.ZipFile(docx_path, "r") as zin:
            zin.extractall(work)
        ct_path = work / "[Content_Types].xml"
        ct = ct_path.read_text(encoding="utf-8")
        if 'Extension="undefined"' not in ct:
            ct = ct.replace(
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="undefined" ContentType="image/png"/>',
                1,
            )
            ct_path.write_text(ct, encoding="utf-8")
        new_path = docx_path.with_suffix(".docx.tmp")
        with zipfile.ZipFile(new_path, "w", zipfile.ZIP_DEFLATED) as zout:
            for root, _, files in os.walk(work):
                for f in files:
                    full = Path(root) / f
                    zout.write(full, full.relative_to(work).as_posix())
        os.replace(new_path, docx_path)
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main():
    docx_path = SRC_DIR / NAME
    if not docx_path.exists():
        raise FileNotFoundError(docx_path)
    patch_docx(docx_path)
    print(f"[patched] {NAME}")
    word = win32com.client.DispatchEx("Word.Application")
    word.Visible = False
    word.DisplayAlerts = 0
    try:
        pdf_path = PDF_DIR / NAME.replace(".docx", ".pdf")
        doc = word.Documents.Open(str(docx_path), ConfirmConversions=False, ReadOnly=True, AddToRecentFiles=False)
        try:
            doc.SaveAs2(str(pdf_path), FileFormat=17)
        finally:
            doc.Close(SaveChanges=False)
        print(f"[pdf] {pdf_path.name}  ({pdf_path.stat().st_size/1024:.1f} KB)")
    finally:
        word.Quit()
    print("Done.")


if __name__ == "__main__":
    main()
