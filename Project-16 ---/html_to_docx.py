"""
Project 16 -- Word copy of the review-fixes page
================================================

Input  : doc/Review_fixes.html  (point-by-point reviewer comments, explanations, fixed values)
Output : doc/Review_fixes.docx

A purpose-built converter for that page's structure (cards, status chips, verbatim
quote blocks, stat tiles, tables with row/column spans, embedded PNG figures), so the
Word copy keeps the same content and visual cues. Re-run after the HTML changes:

    python3 html_to_docx.py

Needs: beautifulsoup4, python-docx.
"""

import base64
import io

from bs4 import BeautifulSoup, NavigableString, Tag
from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

SRC, OUT = "doc/Review_fixes.html", "doc/Review_fixes.docx"

# Colours mirror the page's light theme (Okabe-Ito based, no red).
ACCENT, MUTED, INK = "0072B2", "5F5F5A", "1D1D1B"
CHIP = {"fixed": ("00785A", "E3F4EE"), "part": ("8A5A00", "FDF0D6"), "client": ("005A8C", "E2EEF7")}
QUOTE_BG, PLAIN_BG, HEAD_BG, LINE = "F1F1EC", "E2EEF7", "DCE9F3", "BFBFBF"
FONT = "Calibri"


# ---------------------------------------------------------------------------
# 1. Low-level XML helpers
# ---------------------------------------------------------------------------
def rgb(h):
    return RGBColor.from_string(h)


def shade_run(run, fill):
    rpr = run._r.get_or_add_rPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    rpr.append(shd)


def shade_par(par, fill):
    ppr = par._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    ppr.append(shd)


def border_par(par, side, color, size=12, space=6):
    ppr = par._p.get_or_add_pPr()
    bdr = ppr.find(qn("w:pBdr"))
    if bdr is None:
        bdr = OxmlElement("w:pBdr")
        ppr.append(bdr)
    el = OxmlElement(f"w:{side}")
    el.set(qn("w:val"), "single")
    el.set(qn("w:sz"), str(size))
    el.set(qn("w:space"), str(space))
    el.set(qn("w:color"), color)
    bdr.append(el)


def shade_cell(cell, fill):
    tcpr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    tcpr.append(shd)


def cell_borders(table, color=LINE):
    tblpr = table._tbl.tblPr
    b = OxmlElement("w:tblBorders")
    for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{side}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), color)
        b.append(el)
    tblpr.append(b)


def keep_with_next(par):
    par.paragraph_format.keep_with_next = True


# ---------------------------------------------------------------------------
# 2. Inline content (b, strong, code, br, span.was/.now/.chip)
# ---------------------------------------------------------------------------
def inline(par, node, size=None, fmt=None):
    fmt = dict(fmt or {})
    for ch in node.children:
        if isinstance(ch, NavigableString):
            text = str(ch)
            if not text.strip() and "\n" in text:
                continue
            text = " ".join(text.split()) if "\n" in text else text
            if not text:
                continue
            r = par.add_run(text)
            r.font.name = fmt.get("font", FONT)
            if size:
                r.font.size = Pt(size)
            r.bold = fmt.get("bold")
            r.italic = fmt.get("italic")
            r.font.strike = fmt.get("strike")
            if fmt.get("color"):
                r.font.color.rgb = rgb(fmt["color"])
            if fmt.get("fill"):
                shade_run(r, fmt["fill"])
            continue
        if not isinstance(ch, Tag):
            continue
        cls = ch.get("class", [])
        f = dict(fmt)
        if ch.name == "br":
            par.add_run().add_break(WD_BREAK.LINE)
            continue
        if ch.name in ("b", "strong"):
            f["bold"] = True
        elif ch.name in ("i", "em"):
            f["italic"] = True
        elif ch.name == "code":
            f["font"] = "Consolas"
        elif ch.name == "span" and "was" in cls:
            f.update(strike=True, color=MUTED)
        elif ch.name == "span" and "now" in cls:
            f["bold"] = True
        elif ch.name == "span" and "chip" in cls:
            key = next(k for k in CHIP if k in cls)
            f.update(bold=True, color=CHIP[key][0], fill=CHIP[key][1])
            r = par.add_run(f" {ch.get_text()} ")
            r.bold, r.font.name = True, FONT
            r.font.size = Pt((size or 10.5) - 1)
            r.font.color.rgb = rgb(CHIP[key][0])
            shade_run(r, CHIP[key][1])
            continue
        inline(par, ch, size, f)


def para(doc_or_cell, node=None, text=None, size=None, color=None, align=None, space_after=4, style=None):
    p = doc_or_cell.add_paragraph(style=style) if style else doc_or_cell.add_paragraph()
    p.paragraph_format.space_after = Pt(space_after)
    if node is not None:
        inline(p, node, size, {"color": color} if color else None)
    if text is not None:
        r = p.add_run(text)
        r.font.name = FONT
        if size:
            r.font.size = Pt(size)
        if color:
            r.font.color.rgb = rgb(color)
    if align:
        p.alignment = align
    return p


# ---------------------------------------------------------------------------
# 3. Block elements
# ---------------------------------------------------------------------------
def add_table(doc, tbl):
    rows = tbl.find_all("tr")
    # Lay the HTML grid out, honouring rowspan/colspan.
    grid, spans = {}, []
    for ri, tr in enumerate(rows):
        ci = 0
        for cell in tr.find_all(["th", "td"], recursive=False):
            while (ri, ci) in grid:
                ci += 1
            rs, cs = int(cell.get("rowspan", 1)), int(cell.get("colspan", 1))
            for dr in range(rs):
                for dc in range(cs):
                    grid[(ri + dr, ci + dc)] = cell if (dr, dc) == (0, 0) else "SPAN"
            if rs > 1 or cs > 1:
                spans.append((ri, ci, ri + rs - 1, ci + cs - 1))
            ci += cs
    ncol = max(c for _, c in grid) + 1
    t = doc.add_table(rows=len(rows), cols=ncol)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell_borders(t)
    for (ri, ci), cell in grid.items():
        if cell == "SPAN":
            continue
        dc = t.cell(ri, ci)
        p = dc.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        head = cell.name == "th"
        inline(p, cell, 9, {"bold": True, "color": MUTED} if head else None)
        if "n" in cell.get("class", []):
            p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        if head:
            shade_cell(dc, HEAD_BG)
    for r0, c0, r1, c1 in spans:
        t.cell(r0, c0).merge(t.cell(r1, c1))
    # Header row repeats across pages.
    trpr = t.rows[0]._tr.get_or_add_trPr()
    th = OxmlElement("w:tblHeader")
    th.set(qn("w:val"), "true")
    trpr.append(th)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_stats(doc, grid):
    tiles = grid.find_all("div", class_="stat")
    t = doc.add_table(rows=1, cols=len(tiles))
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell_borders(t)
    for i, tile in enumerate(tiles):
        c = t.cell(0, i)
        b, s = tile.find("b"), tile.find("span")
        p = c.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(b.get_text())
        r.bold, r.font.size, r.font.name = True, Pt(15), FONT
        style = b.get("style", "")
        for key, (fg, _) in CHIP.items():
            if f"--{key}" in style:
                r.font.color.rgb = rgb(fg)
        p2 = c.add_paragraph()
        p2.paragraph_format.space_after = Pt(2)
        r2 = p2.add_run(s.get_text())
        r2.font.size, r2.font.name = Pt(8.5), FONT
        r2.font.color.rgb = rgb(MUTED)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_list(doc, ul, size=None, quote=False):
    for li in ul.find_all("li", recursive=False):
        p = doc.add_paragraph(style="List Bullet")
        p.paragraph_format.space_after = Pt(2)
        inline(p, li, size)
        if quote:
            quote_style(p)


def quote_style(p):
    p.paragraph_format.left_indent = Cm(1.0) if p.style.name == "List Bullet" else Cm(0.35)
    shade_par(p, QUOTE_BG)
    border_par(p, "left", ACCENT, size=18, space=8)


def add_image(doc, img):
    src = img["src"]
    data = base64.b64decode(src.split(",", 1)[1])
    doc.add_picture(io.BytesIO(data), width=Cm(15.5))
    doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
    alt = img.get("alt")
    if alt:
        para(doc, text=alt, size=8.5, color=MUTED, align=WD_ALIGN_PARAGRAPH.CENTER)


def block(doc, el, first_label):
    cls = el.get("class", [])
    if el.name == "div" and "head" in cls:
        num = el.find("span", class_="num")
        h = doc.add_heading(level=1)
        if num:
            r = h.add_run(num.get_text() + "  ")
            r.font.color.rgb = rgb(ACCENT)
        h.add_run(el.find("h2").get_text() + "  ")
        chip = el.find("span", class_="chip")
        if chip:
            inline(h, BeautifulSoup(str(chip), "html.parser"), 10.5)
        return
    if el.name == "h2":
        doc.add_heading(el.get_text(), level=1)
        return
    if el.name == "div" and "part-label" in cls:
        p = para(doc, text=el.get_text().upper(), size=8.5, color=ACCENT, space_after=3)
        p.runs[0].bold = True
        p.paragraph_format.space_before = Pt(8)
        if not first_label:
            border_par(p, "top", LINE, size=4, space=6)
        keep_with_next(p)
        return
    if el.name == "blockquote":
        for ch in el.find_all(["p", "ul"], recursive=False):
            if ch.name == "ul":
                add_list(doc, ch, 10, quote=True)
            else:
                p = para(doc, ch, size=10, space_after=0)
                quote_style(p)
        doc.add_paragraph().paragraph_format.space_after = Pt(0)
        return
    if el.name == "p" and "plain" in cls:
        p = para(doc, el, size=10, space_after=6)
        shade_par(p, PLAIN_BG)
        return
    if el.name == "h3":
        h = doc.add_heading(el.get_text(), level=2)
        return
    if el.name == "p" and "note" in cls:
        para(doc, el, size=8.5, color=MUTED)
        return
    if el.name == "p":
        para(doc, el)
        return
    if el.name == "ul":
        add_list(doc, el)
        return
    if el.name == "div" and "tw" in cls:
        add_table(doc, el.find("table"))
        return
    if el.name == "div" and "grid" in cls:
        add_stats(doc, el)
        return
    if el.name == "img":
        add_image(doc, el)
        return
    raise ValueError(f"unhandled element: <{el.name} class={cls}>")


# ---------------------------------------------------------------------------
# 4. Build
# ---------------------------------------------------------------------------
soup = BeautifulSoup(open(SRC, encoding="utf-8").read(), "html.parser")
doc = Document()
sec = doc.sections[0]
sec.page_width, sec.page_height = Cm(21.0), Cm(29.7)  # A4
for side in ("left_margin", "right_margin", "top_margin", "bottom_margin"):
    setattr(sec, side, Cm(2.0))

st = doc.styles
st["Normal"].font.name, st["Normal"].font.size = FONT, Pt(10.5)
st["Normal"].font.color.rgb = rgb(INK)
for name, size, color in [("Title", 20, INK), ("Heading 1", 14, INK), ("Heading 2", 9.5, MUTED)]:
    s = st[name]
    s.font.name, s.font.size, s.font.color.rgb = FONT, Pt(size), rgb(color)
    s.font.bold = True
    s.paragraph_format.keep_with_next = True
st["Heading 1"].paragraph_format.space_before = Pt(16)
st["Heading 1"].paragraph_format.space_after = Pt(4)
st["Heading 2"].paragraph_format.space_before = Pt(8)
st["Heading 2"].paragraph_format.space_after = Pt(2)
st["Heading 2"].font.all_caps = True
# Heading styles carry theme fonts; point every script slot at FONT.
for name in ("Title", "Heading 1", "Heading 2"):
    rf = st[name].element.get_or_add_rPr().find(qn("w:rFonts"))
    for attr in ("w:asciiTheme", "w:hAnsiTheme", "w:eastAsiaTheme", "w:cstheme"):
        if rf is not None and rf.get(qn(attr)) is not None:
            del rf.attrib[qn(attr)]

# Footer page numbers.
fp = sec.footer.paragraphs[0]
fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
for tag, text in (("begin", None), (None, "PAGE"), ("end", None)):
    r = fp.add_run()
    if tag:
        fc = OxmlElement("w:fldChar")
        fc.set(qn("w:fldCharType"), tag)
        r._r.append(fc)
    else:
        it = OxmlElement("w:instrText")
        it.set(qn("xml:space"), "preserve")
        it.text = text
        r._r.append(it)
    r.font.size = Pt(9)

main = soup.find("main")
for el in main.find_all(recursive=False):
    cls = el.get("class", [])
    if el.name == "h1":
        doc.add_heading(el.get_text(), level=0)
    elif el.name == "p" and "sub" in cls:
        para(doc, el, size=9.5, color=MUTED, space_after=8)
    elif el.name == "div" and "grid" in cls:
        add_stats(doc, el)
    elif el.name == "div" and "card" in cls:
        first = True
        for ch in el.find_all(recursive=False):
            block(doc, ch, first_label=first)
            if ch.name == "div" and "part-label" in ch.get("class", []):
                first = False
    else:
        raise ValueError(f"unhandled top-level element: <{el.name} class={cls}>")

# ---------------------------------------------------------------------------
# 5. Schema order: raw-appended shd/pBdr/tblBorders must sit in the order the
#    OOXML schema requires, or strict validators (and some Word builds) reject them.
# ---------------------------------------------------------------------------
ORDER = {
    "pPr": ["pStyle", "keepNext", "keepLines", "pageBreakBefore", "framePr", "widowControl", "numPr",
            "suppressLineNumbers", "pBdr", "shd", "tabs", "suppressAutoHyphens", "kinsoku", "wordWrap",
            "overflowPunct", "topLinePunct", "autoSpaceDE", "autoSpaceDN", "bidi", "adjustRightInd",
            "snapToGrid", "spacing", "ind", "contextualSpacing", "mirrorIndents", "suppressOverlap", "jc",
            "textDirection", "textAlignment", "textboxTightWrap", "outlineLvl", "divId", "cnfStyle", "rPr",
            "sectPr", "pPrChange"],
    "rPr": ["rStyle", "rFonts", "b", "bCs", "i", "iCs", "caps", "smallCaps", "strike", "dstrike", "outline",
            "shadow", "emboss", "imprint", "noProof", "snapToGrid", "vanish", "webHidden", "color", "spacing",
            "w", "kern", "position", "sz", "szCs", "highlight", "u", "effect", "bdr", "shd", "fitText",
            "vertAlign", "rtl", "cs", "em", "lang", "eastAsianLayout", "specVanish", "oMath"],
    "tblPr": ["tblStyle", "tblpPr", "tblOverlap", "bidiVisual", "tblStyleRowBandSize", "tblStyleColBandSize",
              "tblW", "jc", "tblCellSpacing", "tblInd", "tblBorders", "shd", "tblLayout", "tblCellMar",
              "tblLook", "tblCaption", "tblDescription"],
    "tcPr": ["cnfStyle", "tcW", "gridSpan", "hMerge", "vMerge", "tcBorders", "shd", "noWrap", "tcMar",
             "textDirection", "tcFitText", "vAlign", "hideMark"],
}


def reorder(root):
    for tag, order in ORDER.items():
        rank = {qn(f"w:{n}"): i for i, n in enumerate(order)}
        for el in root.iter(qn(f"w:{tag}")):
            kids = list(el)
            kids.sort(key=lambda k: rank.get(k.tag, len(order)))
            for k in kids:
                el.remove(k)
                el.append(k)


reorder(doc.element.body)
reorder(doc.styles.element)
reorder(sec.footer._element)
zoom = doc.settings.element.find(qn("w:zoom"))
if zoom is not None and zoom.get(qn("w:percent")) is None:
    zoom.set(qn("w:percent"), "100")

doc.core_properties.title = soup.title.get_text()
doc.save(OUT)
print("wrote", OUT)
