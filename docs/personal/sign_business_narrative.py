"""
Overlay onto the filled Business Narrative PDF:
  1. Real scanned "Ravi Jain" signature image stamped into Signature23 (page 2)
  2. A filled circle on Commercial/warehouse radio (page 1) — workaround for the form's
     defective Group10 which makes legal-structure and space-type share one radio group.

We delete the conflicting widget annotations first (so their empty placeholder doesn't
render on top), then draw the overlay underneath.
"""
import io
import fitz
from PIL import Image
import numpy as np
from scipy import ndimage

SRC      = r"c:\VSCode\tech-legal\tech-legal\docs\personal\Business_Narrative_filled.pdf"
DST      = r"c:\VSCode\tech-legal\tech-legal\docs\personal\Business_Narrative_signed.pdf"
SIG_JPG  = r"c:\VSCode\tech-legal\tech-legal\docs\personal\signature.jpg"


def build_signature_png(jpg_path: str, rotate: int = -90) -> bytes:
    """Threshold + connected-component clean + transparent background, returned as PNG bytes."""
    im = Image.open(jpg_path).convert("RGBA")
    W, H = im.size
    # Crop out the right-side shadow region (signature is in the left ~60% of the frame).
    arr = np.array(im.crop((0, 0, int(W * 0.6), H)))
    brightness = arr[:, :, :3].mean(axis=2)
    ink = brightness < 100
    labeled, n = ndimage.label(ink)
    sizes = ndimage.sum(ink, labeled, range(1, n + 1))
    maxsz = sizes.max() if sizes.size else 0
    keep = [i + 1 for i, s in enumerate(sizes) if s >= max(50, maxsz * 0.01)]
    main = np.isin(labeled, keep)
    out_arr = np.zeros_like(arr)
    out_arr[main, :3] = arr[main, :3]
    out_arr[main, 3] = 255
    img = Image.fromarray(out_arr).crop(Image.fromarray(out_arr).getbbox())
    img = img.rotate(rotate, expand=True)
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue(), img.size  # PNG bytes + (w, h) px


doc = fitz.open(SRC)

# ---- Page 2: replace Signature23 widget with the real scanned signature ----
page2 = doc[1]
sig_target_rect = None
for w in list(page2.widgets()):
    if w.field_name == "Signature23":
        sig_target_rect = fitz.Rect(w.rect)  # already in MuPDF top-origin coords
        page2.delete_widget(w)
        break

if sig_target_rect is None:
    raise RuntimeError("Signature23 widget not found")

sig_png, (sw, sh) = build_signature_png(SIG_JPG)
aspect = sw / sh

# Box: fit inside the widget rect, preserve aspect, slight inset and tilted ink color
box_h = sig_target_rect.height + 6           # let the signature breathe a bit
box_w = box_h * aspect
max_w = sig_target_rect.width                # don't exceed the widget width
if box_w > max_w:
    box_w = max_w
    box_h = box_w / aspect

# Anchor: align signature's left to widget left, vertically centered within widget
x0 = sig_target_rect.x0 + 2
y0 = sig_target_rect.y0 + (sig_target_rect.height - box_h) / 2
sig_rect = fitz.Rect(x0, y0, x0 + box_w, y0 + box_h)
page2.insert_image(sig_rect, stream=sig_png, keep_proportion=True)

# ---- Page 1: fill the Commercial/warehouse radio (Group10) ----
page1 = doc[0]
comm_rect = None
for w in list(page1.widgets()):
    if w.field_name == "Group10":
        states = w.button_states() or {}
        normal = states.get("normal", []) or []
        if any("Comm" in s for s in normal if isinstance(s, str)):
            comm_rect = fitz.Rect(w.rect)
            page1.delete_widget(w)
            break

if comm_rect is None:
    raise RuntimeError("Comm/Warehouse radio widget not found")

# Draw the radio circle outline + filled center dot (mimic a selected radio button)
cx = (comm_rect.x0 + comm_rect.x1) / 2
cy = (comm_rect.y0 + comm_rect.y1) / 2
ro = (comm_rect.width / 2)        # outer ring radius
ri = ro * 0.45                    # inner filled dot radius
page1.draw_circle(fitz.Point(cx, cy), ro, color=(0, 0, 0), fill=None, width=0.7)
page1.draw_circle(fitz.Point(cx, cy), ri, color=(0, 0, 0), fill=(0, 0, 0), width=0)

doc.save(DST, deflate=True, garbage=3)
print(f"Wrote {DST}")
