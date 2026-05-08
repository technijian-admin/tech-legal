"""
Overlay Ravi's signature onto the 6 termination/retrenchment letters.

Source signature PDF: ...Employees\India\HR\restructuring-2026\letters\pdf\signature.pdf
Renders that page at high DPI, removes the white background to make it transparent,
crops to the signature's bounding box, then stamps the signature on each letter
just above the "Ravi Jain" text on the signature line.

Output: letters\pdf-signed\<original filename>
"""

import io
from pathlib import Path

import fitz  # PyMuPDF
from PIL import Image

ROOT = Path(r"c:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026")
LETTERS_DIR = ROOT / "letters" / "pdf"
SIGNED_DIR  = ROOT / "letters" / "pdf-signed"
SIGNED_DIR.mkdir(parents=True, exist_ok=True)

LEAVE_DIR        = ROOT / "leave-applications" / "pdf"
LEAVE_SIGNED_DIR = ROOT / "leave-applications" / "pdf-signed"
LEAVE_SIGNED_DIR.mkdir(parents=True, exist_ok=True)

SIG_PDF = LETTERS_DIR / "signature.pdf"

LETTER_FILES = [
    "01-Devesh-Bhattacharya-Termination.pdf",
    "02-Rajat-Kumar-Termination.pdf",
    "03-Aditya-Saraf-Termination.pdf",
    "04-Suresh-Kumar-Sharma-Termination.pdf",
    "05-Yogesh-Kumar-Retrenchment.pdf",
    "06-Rahul-Uniyal-Retrenchment.pdf",
]

LEAVE_FILES = [
    "01-Yogesh-Kumar-Leave-Application.pdf",
    "02-Rahul-Uniyal-Leave-Application.pdf",
    "03-Suresh-Kumar-Sharma-Leave-Application.pdf",
]


def load_signature_png(pdf_path: Path, dark_threshold: int = 110) -> tuple[bytes, float]:
    """Render the signature PDF page, keep only DARK pixels (the ink), drop the
    rest (page background and faint scanning specks), and crop tightly to the
    full signature (all meaningful strokes, not just the single largest blob).

    Returns (png_bytes, aspect_w_over_h)."""
    import numpy as np
    from scipy import ndimage

    doc = fitz.open(pdf_path)
    page = doc[0]
    pix = page.get_pixmap(matrix=fitz.Matrix(4, 4))
    img = Image.open(io.BytesIO(pix.tobytes("png"))).convert("RGBA")
    doc.close()
    print(f"  Source signature page: {img.width}x{img.height}")

    arr = np.array(img)
    brightness = arr[:, :, :3].mean(axis=2)
    ink_mask = brightness < dark_threshold

    # Find connected components.
    labeled, n = ndimage.label(ink_mask)
    if n == 0:
        raise RuntimeError("No dark pixels detected in signature.pdf")
    sizes = ndimage.sum(ink_mask, labeled, range(1, n + 1))
    largest_size = int(sizes.max())

    # Keep ALL components above 1% of the largest (filters scanning specks but
    # keeps every meaningful stroke -- dots on i, separate letters, the J tail,
    # etc.) Discard truly tiny isolated noise.
    min_size = max(50, largest_size * 0.01)
    keep_labels = [i + 1 for i, s in enumerate(sizes) if s >= min_size]
    print(f"  Found {n} dark regions; keeping {len(keep_labels)} above {int(min_size)}px")

    main_mask = np.isin(labeled, keep_labels)

    out = np.zeros_like(arr)
    out[main_mask] = arr[main_mask]
    out[main_mask, 3] = 255

    img_out = Image.fromarray(out)
    bbox = img_out.getbbox()
    print(f"  Bounding box of signature: {bbox}")
    if bbox:
        img_out = img_out.crop(bbox)
    print(f"  Cropped signature: {img_out.width}x{img_out.height}")

    debug_path = pdf_path.parent / "_signature_debug.png"
    img_out.save(debug_path, format="PNG")
    print(f"  Debug PNG saved: {debug_path}")

    buf = io.BytesIO()
    img_out.save(buf, format="PNG")
    return buf.getvalue(), img_out.width / img_out.height


def find_signature_line(page: fitz.Page) -> fitz.Rect | None:
    """Locate the signature line directly above the LAST 'Ravi Jain' on the page.

    Strategy: anchor on the LAST 'Ravi' position on the page (the signature
    block). The underscore line in the generated doc is 31 underscores in
    Calibri 11pt, starting at the left margin and extending ~170pt across.
    PyMuPDF's text extraction sometimes splits the underscore run into
    segments, so we synthesize the line geometrically from the known layout.
    """
    ravi_rects = page.search_for("Ravi")
    if not ravi_rects:
        return None
    # Pick the lowest occurrence on the page (the signature block); ignores
    # any 'Ravi' that may appear earlier in the body text.
    ravi_rect = max(ravi_rects, key=lambda r: r.y0)

    # The signature line starts at the same x as 'Ravi' (both align to the
    # left margin) and ends ~170pt to the right.
    line_x0 = ravi_rect.x0
    line_x1 = ravi_rect.x0 + 170
    # Vertical position: ~12-18pt above the top of 'Ravi'.
    line_y0 = ravi_rect.y0 - 16
    line_y1 = ravi_rect.y0 - 8
    return fitz.Rect(line_x0, line_y0, line_x1, line_y1)


def stamp(letter_path: Path, out_path: Path, sig_png: bytes, sig_aspect: float) -> bool:
    doc = fitz.open(letter_path)
    stamped = False
    for page in doc:
        line = find_signature_line(page)
        if line is None:
            continue

        # Aim for a natural-looking signature: ~40pt tall (~0.55"), capped by
        # 90% of the underscore line width. Maintain aspect ratio.
        target_h = 40.0
        target_w = target_h * sig_aspect
        max_w = (line.x1 - line.x0) * 0.90
        if target_w > max_w:
            target_w = max_w
            target_h = target_w / sig_aspect

        # Center horizontally on the line. Bottom of signature ~5pt below the
        # line top so the signature visually crosses the underscore line.
        cx = (line.x0 + line.x1) / 2
        x0 = cx - target_w / 2
        x1 = cx + target_w / 2
        y1 = line.y0 + 5
        y0 = y1 - target_h
        rect = fitz.Rect(x0, y0, x1, y1)

        page.insert_image(rect, stream=sig_png, keep_proportion=True)
        print(f"  [signed] {letter_path.name}  (page {page.number + 1}, "
              f"rect={x0:.1f},{y0:.1f}-{x1:.1f},{y1:.1f})")
        stamped = True
        break

    if stamped:
        doc.save(out_path)
    doc.close()
    return stamped


def main():
    if not SIG_PDF.exists():
        raise FileNotFoundError(SIG_PDF)

    print(f"Loading signature: {SIG_PDF.name}")
    sig_png, sig_aspect = load_signature_png(SIG_PDF)
    print(f"  Cropped signature aspect ratio: {sig_aspect:.2f}")
    print(f"  PNG size: {len(sig_png)/1024:.1f} KB")

    print("\nStamping letters:")
    for fname in LETTER_FILES:
        src = LETTERS_DIR / fname
        dst = SIGNED_DIR / fname
        if not src.exists():
            print(f"  [missing]  {fname}")
            continue
        if not stamp(src, dst, sig_png, sig_aspect):
            print(f"  [FAILED]  {fname}  (no signature line located)")

    print("\nStamping leave applications (director approval block):")
    for fname in LEAVE_FILES:
        src = LEAVE_DIR / fname
        dst = LEAVE_SIGNED_DIR / fname
        if not src.exists():
            print(f"  [missing]  {fname}")
            continue
        if not stamp(src, dst, sig_png, sig_aspect):
            print(f"  [FAILED]  {fname}  (no signature line located)")

    print(f"\nDone.")
    print(f"  Letters:           {SIGNED_DIR}")
    print(f"  Leave applications: {LEAVE_SIGNED_DIR}")


if __name__ == "__main__":
    main()
