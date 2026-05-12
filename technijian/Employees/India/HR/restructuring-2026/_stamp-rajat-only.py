"""One-off: stamp Ravi's signature on ONLY the revised Rajat MSA PDF.

Uses the pre-cropped signature PNG (letters/pdf/_signature_debug.png) produced
by an earlier run of stamp-signatures.py, so we don't need scipy here. Reuses
find_signature_line()/stamp() logic inline.
"""
import io
from pathlib import Path
import fitz
from PIL import Image

ROOT = Path(__file__).parent
PDF_DIR = ROOT / "letters" / "pdf"
SIGNED_DIR = ROOT / "letters" / "pdf-signed"
SIGNED_DIR.mkdir(parents=True, exist_ok=True)
SIG_PNG_PATH = PDF_DIR / "_signature_debug.png"
NAME = "02-Rajat-Kumar-Mutual-Separation-Agreement.pdf"


def find_signature_line(page):
    rects = page.search_for("Ravi")
    if not rects:
        return None
    r = max(rects, key=lambda x: x.y0)
    return fitz.Rect(r.x0, r.y0 - 16, r.x0 + 170, r.y0 - 8)


def main():
    if not SIG_PNG_PATH.exists():
        raise FileNotFoundError(SIG_PNG_PATH)
    sig_img = Image.open(SIG_PNG_PATH).convert("RGBA")
    buf = io.BytesIO(); sig_img.save(buf, format="PNG")
    sig_png = buf.getvalue()
    sig_aspect = sig_img.width / sig_img.height
    print(f"signature png {sig_img.width}x{sig_img.height}  aspect={sig_aspect:.2f}")

    src = PDF_DIR / NAME
    dst = SIGNED_DIR / NAME
    doc = fitz.open(src)
    stamped = False
    for page in doc:
        line = find_signature_line(page)
        if line is None:
            continue
        target_h = 40.0
        target_w = target_h * sig_aspect
        max_w = (line.x1 - line.x0) * 0.90
        if target_w > max_w:
            target_w = max_w
            target_h = target_w / sig_aspect
        cx = (line.x0 + line.x1) / 2
        x0, x1 = cx - target_w / 2, cx + target_w / 2
        y1 = line.y0 + 5
        y0 = y1 - target_h
        page.insert_image(fitz.Rect(x0, y0, x1, y1), stream=sig_png, keep_proportion=True)
        print(f"[signed] page {page.number+1}  rect={x0:.1f},{y0:.1f}-{x1:.1f},{y1:.1f}")
        stamped = True
        break
    if not stamped:
        raise SystemExit("FAILED — no signature line located")
    doc.save(dst)
    doc.close()
    print(f"-> {dst}  ({dst.stat().st_size/1024:.1f} KB)")


if __name__ == "__main__":
    main()
