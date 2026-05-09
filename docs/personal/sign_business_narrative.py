"""
Overlay onto the filled Business Narrative PDF:
  1. Cursive "Ravi Jain" signature in the Signature23 box (page 2)
  2. A filled circle on Commercial/warehouse radio (page 1) — workaround for the form's
     defective Group10 which makes legal-structure and space-type share one radio group.

We delete the conflicting widget annotations first (so their empty placeholder doesn't
render on top), then draw the overlay underneath.
"""
import fitz

SRC = r"c:\VSCode\tech-legal\tech-legal\docs\personal\Business_Narrative_filled.pdf"
DST = r"c:\VSCode\tech-legal\tech-legal\docs\personal\Business_Narrative_signed.pdf"
SIG_FONT = r"C:\Windows\Fonts\segoesc.ttf"  # Segoe Script

doc = fitz.open(SRC)

# ---- Page 2: replace Signature23 widget with rendered cursive text ----
page2 = doc[1]
sig_target_rect = None
for w in list(page2.widgets()):
    if w.field_name == "Signature23":
        sig_target_rect = fitz.Rect(w.rect)  # widget.rect is already in MuPDF top-origin coords
        page2.delete_widget(w)
        break

if sig_target_rect is None:
    raise RuntimeError("Signature23 widget not found")

# Use insert_text (positional baseline) — robust against tight boxes
baseline = fitz.Point(sig_target_rect.x0 + 2,
                      sig_target_rect.y1 - 4)  # bottom of widget minus a small gap
page2.insert_text(
    baseline,
    "Ravi Jain",
    fontname="sigfont",
    fontfile=SIG_FONT,
    fontsize=22,
    color=(0, 0, 0.55),  # navy ink
)

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
