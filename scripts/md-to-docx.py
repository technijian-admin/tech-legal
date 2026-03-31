"""Convert markdown SOW to formatted DOCX"""
import sys
import markdown
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from htmldocx import HtmlToDocx
import re

def convert_md_to_docx(md_path, docx_path):
    with open(md_path, 'r', encoding='utf-8') as f:
        md_content = f.read()

    # Convert markdown to HTML
    html = markdown.markdown(md_content, extensions=['tables', 'sane_lists'])

    # Create document
    doc = Document()

    # Set default font
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Calibri'
    font.size = Pt(10)

    # Set narrow margins
    for section in doc.sections:
        section.top_margin = Inches(0.75)
        section.bottom_margin = Inches(0.75)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)

    # Use HtmlToDocx for conversion
    parser = HtmlToDocx()
    parser.table_style = 'Table Grid'
    parser.add_html_to_document(html, doc)

    # Style headings
    for paragraph in doc.paragraphs:
        if paragraph.style.name.startswith('Heading'):
            for run in paragraph.runs:
                run.font.color.rgb = RGBColor(0, 0x6D, 0xB6)  # Technijian blue

    doc.save(docx_path)
    print(f"Saved: {docx_path}")

if __name__ == '__main__':
    md_path = sys.argv[1]
    docx_path = sys.argv[2]
    convert_md_to_docx(md_path, docx_path)
