#!/usr/bin/env python3
"""Build assets/data/laws.json from the official sources in data_sources/raw/.

Usage:
    python3 tools/build_data.py --download   # fetch sources, then build
    python3 tools/build_data.py              # build from files already in raw/

Raw files are HTML (lawphil.net) or PDF. Each law is split by Section into
chunks: {id, source, section, title, text, tags, url, as_of, notes}.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, OrderedDict
from datetime import date
from pathlib import Path

import pdfplumber
import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data_sources" / "raw"
MANIFEST = RAW_DIR / "manifest.json"
OUT = ROOT / "assets" / "data" / "laws.json"

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) BiyaheBuddyDataBot/1.0"
MAX_CHUNK_CHARS = 2500
TARGET_PART_CHARS = 1800

SOURCES = [
    {
        "key": "ra4136",
        "name": "RA 4136 (Land Transportation and Traffic Code)",
        "file": "ra_4136_1964.html",
        "urls": ["https://lawphil.net/statutes/repacts/ra1964/ra_4136_1964.html"],
    },
    {
        "key": "ra10913",
        "name": "RA 10913 (Anti-Distracted Driving Act)",
        "file": "ra_10913_2016.html",
        "urls": ["https://lawphil.net/statutes/repacts/ra2016/ra_10913_2016.html"],
    },
    {
        "key": "ra10586",
        "name": "RA 10586 (Anti-Drunk and Drugged Driving Act of 2013)",
        "file": "ra_10586_2013.html",
        "urls": ["https://lawphil.net/statutes/repacts/ra2013/ra_10586_2013.html"],
    },
    {
        "key": "ra10054",
        "name": "RA 10054 (Motorcycle Helmet Act of 2009)",
        "file": "ra_10054_2010.html",
        "urls": ["https://lawphil.net/statutes/repacts/ra2010/ra_10054_2010.html"],
    },
    {
        "key": "ra8750",
        "name": "RA 8750 (Seat Belts Use Act of 1999)",
        "file": "ra_8750_1999.html",
        "urls": ["https://lawphil.net/statutes/repacts/ra1999/ra_8750_1999.html"],
    },
    {
        "key": "ra11229",
        "name": "RA 11229 (Child Safety in Motor Vehicles Act)",
        "file": "ra_11229_2019.html",
        "urls": ["https://lawphil.net/statutes/repacts/ra2019/ra_11229_2019.html"],
    },
    {
        "key": "lto-manual",
        "name": "LTO Driver's Manual",
        "file": "lto_drivers_manual.pdf",
        "urls": ["https://lto.gov.ph/"],
        "optional": True,
    },
]

# Concept -> (regex that triggers it on the chunk text, Taglish tags to add).
TAG_RULES: list[tuple[str, list[str]]] = [
    (r"helmet", ["helmet", "walang helmet", "motor", "motorsiklo", "angkas", "backrider"]),
    (r"motorcycle|back rider", ["motor", "motorsiklo", "rider", "angkas"]),
    (r"mobile|cellular|communications device|texting|electronic entertainment",
     ["cellphone", "cp", "phone", "texting", "nagte-text", "tumatawag", "distracted", "selpon"]),
    (r"alcohol|liquor|intoxicat|drunk|breath analyzer",
     ["lasing", "nakainom", "alak", "drunk driving", "breathalyzer", "inuman"]),
    (r"dangerous drugs|narcotic|drugged", ["droga", "drugs", "drug test", "naka-droga"]),
    (r"seat belt", ["seatbelt", "seat belt", "sinturon", "walang seatbelt"]),
    (r"child restraint|child passenger|children|infant|car seat",
     ["bata", "anak", "car seat", "child seat", "baby"]),
    (r"overtak|passing", ["overtake", "nag-overtake", "singit", "lusot", "pasingit"]),
    (r"signal", ["signal light", "signal", "hand signal", "senyas"]),
    (r"\bturn(?:ing|s)?\b", ["liko", "kumanan", "kumaliwa", "u-turn", "pagliko"]),
    (r"intersection", ["intersection", "kanto", "interseksyon"]),
    (r"right of way|yield|give way", ["right of way", "pagbibigay-daan", "unahan"]),
    (r"pedestrian|crosswalk|crossing", ["tawiran", "pedestrian", "tumatawid"]),
    (r"accident|collision|injur|death", ["bangga", "nabangga", "aksidente", "sagasa", "nasagasaan"]),
    (r"speed|miles per hour|kilometers per hour|kph", ["bilis", "overspeeding", "speed limit", "mabilis"]),
    (r"reckless", ["reckless", "pabaya", "kaskasero", "barumbado"]),
    (r"park", ["parking", "park", "paradahan", "illegal parking"]),
    (r"license|licence", ["lisensya", "license", "walang lisensya"]),
    (r"student-driver|student permit", ["student permit", "student driver"]),
    (r"regist", ["rehistro", "registration", "OR/CR", "expired rehistro"]),
    (r"number plate|plates", ["plaka", "plate number", "walang plaka"]),
    (r"headlight|head-light|headlamp|tail light|tail-light|\blights\b", ["ilaw", "headlight", "tail light"]),
    (r"\bhorn", ["busina", "horn", "bumusina"]),
    (r"brake", ["preno", "brakes"]),
    (r"muffler", ["tambutso", "muffler", "maingay na tambutso"]),
    (r"sidewalk", ["bangketa", "sidewalk"]),
    (r"right side of the highway|keep to the right|right side of highway", ["kanan", "keep right", "lane"]),
    (r"capacity|overload|freight", ["overloading", "sobrang pasahero", "sobrang karga"]),
    (r"tamper|hitch|hang on", ["sabit", "pagsabit"]),
    (r"police|emergency vehicle|ambulance|fire", ["ambulansya", "bumbero", "pulis", "emergency vehicle"]),
    (r"fine|penalt|imprison|punish|suspension|revocation|confiscat",
     ["multa", "penalty", "fine", "parusa", "kulong", "huli"]),
    (r"enforcement|deputized|apprehend|law enforcement officer",
     ["enforcer", "traffic enforcer", "nahuli", "na-flag", "tiket"]),
    (r"field sobriety|chemical test|sobriety", ["sobriety test", "breath test", "pinahinto"]),
    (r"public utility|jeepney|bus|taxi|for hire", ["jeep", "bus", "taxi", "pampasaherong sasakyan", "PUV"]),
]

SOURCE_TAGS = {
    "ra4136": ["LTO", "traffic code", "batas trapiko"],
    "ra10913": ["anti-distracted driving", "cellphone", "distracted"],
    "ra10586": ["anti-drunk driving", "lasing", "drunk driving"],
    "ra10054": ["helmet law", "helmet", "motor"],
    "ra8750": ["seatbelt law", "seatbelt"],
    "ra11229": ["child car seat law", "car seat", "bata"],
    "lto-manual": ["LTO", "driver's manual", "rules of the road"],
}

SECTION_RE = re.compile(r"^(?:Section|SECTION|Sec\.|SEC\.)\s*(\d+[A-Z]?)\.?\s*(.*)$", re.S)
SUBPARA_RE = re.compile(r"^\(([a-z]{1,2}|\d{1,2})\)\s")
WATERMARK_RE = re.compile(r"1?\S?wphi1")
DASH_RE = re.compile(r"^\s*[-–—:]+\s*")


# --------------------------------------------------------------------- download

def download() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    manifest = load_manifest()
    for src in SOURCES:
        entry = {"name": src["name"], "file": src["file"], "attempts": []}
        for url in src["urls"]:
            try:
                r = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=60)
                blocked = r.status_code != 200 or "Just a moment" in r.text[:2000]
                entry["attempts"].append({"url": url, "status": r.status_code,
                                          "blocked": blocked})
                if blocked:
                    continue
                if src["file"].endswith(".pdf") and not r.content.startswith(b"%PDF"):
                    continue
                (RAW_DIR / src["file"]).write_bytes(r.content)
                entry.update(url=url, retrieved=date.today().isoformat(),
                             sha256=hashlib.sha256(r.content).hexdigest())
                break
            except requests.RequestException as e:
                entry["attempts"].append({"url": url, "error": str(e)})
        old = manifest.get(src["key"], {})
        if "url" not in entry and "url" in old:
            entry.update(url=old["url"], retrieved=old["retrieved"], sha256=old["sha256"])
        manifest[src["key"]] = entry
        state = "ok" if entry.get("retrieved") == date.today().isoformat() else "BLOCKED/FAILED"
        print(f"  download {src['key']:<11} {state}  {entry['attempts'][-1]}")
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}


# ---------------------------------------------------------------------- cleaning

def clean(text: str) -> str:
    text = WATERMARK_RE.sub("", text)
    text = text.replace("\u00a0", " ").replace("\u2033", '"').replace("\u2032", "'")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" *\n *", "\n", text)
    text = re.sub(r"\n{2,}", "\n", text)
    return text.strip()


# ------------------------------------------------------------------- HTML (laws)

def parse_lawphil_html(path: Path) -> list[dict]:
    """Return [{num, title, paras, heading}] for every Section in a lawphil page."""
    html = path.read_bytes().decode("cp1252", errors="replace")
    soup = BeautifulSoup(html, "lxml")
    for tag in soup(["script", "style", "gcse:searchbox-only"]):
        tag.decompose()

    sections: list[dict] = []
    current: dict | None = None
    heading = ""
    for p in soup.find_all("p"):
        raw = clean(p.get_text(" ", strip=True))
        if not raw:
            continue
        if raw.startswith("The Lawphil Project") or re.match(r"^Approved[,:]?", raw):
            current = None  # signature block / site footer: stop collecting
            if sections:
                break
            continue
        if p.get("align") == "center":
            if re.match(r"^(CHAPTER|ARTICLE|RULE|TITLE)\b", raw, re.I):
                heading = re.sub(r"\s+", " ", raw)
            continue
        m = SECTION_RE.match(raw)
        bold = p.find("b")
        if m and bold and SECTION_RE.match(clean(bold.get_text(" ", strip=True))):
            num, rest = m.group(1), m.group(2)
            title = ""
            ital = p.find("i")
            if ital and ital.get_text(strip=True):
                title = clean(ital.get_text(" ", strip=True)).rstrip(".")
                idx = rest.find(ital.get_text(" ", strip=True).strip())
                if idx != -1:
                    rest = rest[idx + len(ital.get_text(" ", strip=True).strip()):]
            elif rest and len(rest) <= 120 and not re.search(r"[.,;:]\s*\S", rest.rstrip(". -")):
                title, rest = rest.rstrip(" .-"), ""
            elif rest:
                lead = re.match(r"^([A-Z][^.]{3,100}?)\.\s*[-–—]\s*(.*)$", rest, re.S)
                if lead:
                    title, rest = lead.group(1), lead.group(2)
            rest = DASH_RE.sub("", rest).strip()
            current = {"num": num, "title": title, "heading": heading,
                       "paras": [rest] if rest else []}
            sections.append(current)
        elif current is not None:
            current["paras"].append(raw)
    return sections


# --------------------------------------------------------------------- PDF (LTO)

def parse_pdf(path: Path) -> list[dict]:
    """Generic PDF splitter used for the LTO Driver's Manual.

    Lines repeated on many pages (running headers/footers) and bare page
    numbers are dropped; chunks start at CHAPTER/PART/numbered headings.
    """
    with pdfplumber.open(path) as pdf:
        pages = [(pg.extract_text() or "").splitlines() for pg in pdf.pages]
    heading_re = re.compile(
        r"^(CHAPTER|PART|UNIT|LESSON)\s+[\dIVXLC]+\b.*|^\d{1,2}(\.\d{1,2})?\s+[A-Z][A-Z ,'&/-]{3,}$")

    def norm(line: str) -> str:
        return re.sub(r"\d+", "#", line.strip().lower())

    edge_counts: Counter = Counter()
    for lines in pages:
        for ln in set(lines[:2] + lines[-2:]):
            if len(ln) < 80 and not heading_re.match(ln.strip()):
                edge_counts[norm(ln)] += 1
    threshold = max(3, len(pages) // 2)
    repeated = {k for k, v in edge_counts.items() if v >= threshold and k}

    sections: list[dict] = []
    current = None
    for lines in pages:
        for ln in lines:
            s = ln.strip()
            if not s or norm(s) in repeated or re.fullmatch(r"(page\s*)?\d{1,3}", s, re.I):
                continue
            if heading_re.match(s):
                current = {"num": str(len(sections) + 1), "title": s.title() if s.isupper() else s,
                           "heading": "", "paras": []}
                sections.append(current)
            elif current is not None:
                current["paras"].append(s)
    for sec in sections:  # re-join wrapped lines into sentence-ending paragraphs
        paras, buf = [], []
        for ln in sec["paras"]:
            buf.append(ln)
            if re.search(r"[.:;!?]$", ln):
                paras.append(clean(" ".join(buf)))
                buf = []
        if buf:
            paras.append(clean(" ".join(buf)))
        sec["paras"] = paras
    return sections


# ------------------------------------------------------------------- chunking

def split_long(paras: list[str]) -> list[list[str]]:
    """Group paragraphs into parts of ~TARGET_PART_CHARS, breaking at (a)/(1) items."""
    if sum(len(p) for p in paras) <= MAX_CHUNK_CHARS:
        return [paras]
    parts: list[list[str]] = [[]]
    size = 0
    for p in paras:
        at_item = SUBPARA_RE.match(p) and size + len(p) > TARGET_PART_CHARS
        if parts[-1] and (at_item or size + len(p) > MAX_CHUNK_CHARS):
            parts.append([])
            size = 0
        parts[-1].append(p)
        size += len(p)
    return parts


def part_label(part: list[str], i: int, n: int) -> str:
    """'(a)–(c)' when the part starts at a lettered item, else ' (part i of n)'."""
    labels = [m.group(1) for p in part if (m := SUBPARA_RE.match(p))]
    letters = [lb for lb in labels if lb.isalpha()] or labels
    if not SUBPARA_RE.match(part[0]) or not letters:
        return f" (part {i} of {n})"
    return f"({letters[0]})" if letters[0] == letters[-1] else f"({letters[0]})–({letters[-1]})"


def heading_title(heading: str) -> str:
    """'CHAPTER IV ... ARTICLE IV Accessories of Motor Vehicles' -> 'Accessories of Motor Vehicles'."""
    m = re.search(r"(?:ARTICLE|CHAPTER)\s+[IVXLC\d]+\s+(?!.*(?:ARTICLE|CHAPTER)\s)(.+)$", heading)
    return m.group(1).strip() if m else ""


def tags_for(key: str, title: str, text: str) -> list[str]:
    hay = f"{title}\n{text}".lower()
    tags: list[str] = list(SOURCE_TAGS.get(key, []))
    for pattern, words in TAG_RULES:
        if re.search(pattern, hay):
            tags.extend(words)
    return list(OrderedDict.fromkeys(tags))


def build_chunks(src: dict, sections: list[dict], meta: dict) -> list[dict]:
    chunks = []
    for sec in sections:
        title = sec["title"] or heading_title(sec["heading"]) or f"Section {sec['num']}"
        parts = split_long(sec["paras"])
        for i, part in enumerate(parts, 1):
            text = "\n".join(part).strip()
            if not text:
                text = title
            label = part_label(part, i, len(parts)) if len(parts) > 1 else ""
            cid = f"{src['key']}-s{sec['num']}" + (f"-p{i}" if len(parts) > 1 else "")
            sec_label = ("Chapter " if src["key"] == "lto-manual" else "Sec. ") + sec["num"] + label
            chunks.append({
                "id": cid,
                "source": src["name"],
                "section": sec_label,
                "title": title,
                "text": text,
                "tags": tags_for(src["key"], title, text),
                "url": meta["url"],
                "as_of": meta["retrieved"],
                "notes": [],
            })
    return chunks


# ------------------------------------------------------------------ amendments

RA_REF_RE = re.compile(r"Republic Act No\.?\s*(\d+)", re.I)
TARGET_RE = re.compile(
    r"(?:subparagraph\s*\((?P<sub>[a-z0-9]+)\),?\s*)?Section\s+(?P<sec>\d+)(?P<rest>[^;.]*?)"
    r"(?:of\s+Republic Act No\.?\s*(?P<ra>\d+)|(?P<thereof>thereof))", re.I | re.S)


def annotate_amendments(chunks: list[dict]) -> list[str]:
    """Mark sections that an amending/repealing clause in our sources names.

    Only explicit references ("Section 34 ... of Republic Act No. 4136 is hereby
    amended") are used; blanket "all laws inconsistent..." clauses are ignored.
    """
    by_key: dict[str, list[dict]] = {}
    for c in chunks:
        by_key.setdefault(c["id"].split("-s")[0], []).append(c)
    log = []
    for c in chunks:
        if not re.search(r"repeal|amend", c["title"], re.I):
            continue
        amending_ra = c["id"].split("-s")[0].replace("ra", "")
        specific = re.split(r"\b(?:and\s+)?(?:all other|any law|any\s+and\s+all|All other)\b", c["text"])[0]
        verb_match = re.search(r"hereby\s+(amended|repealed|repealed or modified|modified)", c["text"])
        if not verb_match:
            continue
        verb = verb_match.group(1)
        last_ra = None
        for m in TARGET_RE.finditer(specific):
            ra = m.group("ra") or last_ra
            last_ra = ra
            if not ra or ra == amending_ra:
                continue
            sub = m.group("sub")
            target_ref = f"RA {ra}, Sec. {m.group('sec')}" + (f"({sub})" if sub else "")
            note_src = f"RA {amending_ra}, {c['section']} ({c['title']})"
            c["notes"].append(f"Amends/repeals {target_ref} ('{verb}').")
            for t in by_key.get(f"ra{ra}", []):
                if not re.match(rf"Sec\. {m.group('sec')}(\(| |$)", t["section"]):
                    continue
                if sub and not re.search(rf"(^|\n)\({sub}\)", t["text"]):
                    continue
                what = f"Subparagraph ({sub}) {verb}" if sub else verb.capitalize()
                t["notes"].append(
                    f"{what} by {note_src}. Text shown is the original as published; "
                    f"read together with RA {amending_ra}.")
                log.append(f"{t['id']}: {what} by RA {amending_ra}")
    return log


# ------------------------------------------------------------------- validate

def validate(chunks: list[dict]) -> list[str]:
    errors = []
    seen = set()
    required = ["id", "source", "section", "title", "text", "tags", "url", "as_of"]
    for c in chunks:
        for k in required:
            if not c.get(k):
                errors.append(f"{c.get('id')}: empty {k}")
        if c["id"] in seen:
            errors.append(f"{c['id']}: duplicate id")
        seen.add(c["id"])
        if not str(c.get("url", "")).startswith("http"):
            errors.append(f"{c['id']}: bad url")
        if len(c["text"]) < 20:
            errors.append(f"{c['id']}: suspiciously short text")
        if "wphi1" in c["text"] or "Lawphil Project" in c["text"]:
            errors.append(f"{c['id']}: site header/footer leaked into text")
    json.loads(json.dumps(chunks, ensure_ascii=False))
    return errors


# ----------------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--download", action="store_true", help="fetch sources into data_sources/raw/ first")
    args = ap.parse_args()
    if args.download:
        download()

    manifest = load_manifest()
    chunks: list[dict] = []
    counts: dict[str, int] = {}
    missing = []
    for src in SOURCES:
        path = RAW_DIR / src["file"]
        meta = manifest.get(src["key"], {})
        if not path.exists() or not meta.get("url"):
            missing.append(src["key"])
            continue
        sections = parse_pdf(path) if path.suffix == ".pdf" else parse_lawphil_html(path)
        src_chunks = build_chunks(src, sections, meta)
        counts[src["key"]] = len(src_chunks)
        chunks.extend(src_chunks)

    amend_log = annotate_amendments(chunks)
    for c in chunks:
        c["notes"] = list(OrderedDict.fromkeys(c["notes"]))
        if not c["notes"]:
            del c["notes"]

    errors = validate(chunks)
    if errors:
        print("VALIDATION FAILED:\n  " + "\n  ".join(errors), file=sys.stderr)
        return 1

    OUT.write_text(json.dumps(chunks, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {OUT.relative_to(ROOT)}")
    print("Chunk counts:")
    for k, v in counts.items():
        print(f"  {k:<11} {v:>4}")
    print(f"  {'TOTAL':<11} {len(chunks):>4}")
    if amend_log:
        print("Amendment notes:\n  " + "\n  ".join(amend_log))
    for k in missing:
        src = next(s for s in SOURCES if s["key"] == k)
        level = "skipped (optional)" if src.get("optional") else "MISSING"
        print(f"  {level}: {k} — put {src['file']} in data_sources/raw/ and add it to manifest.json")
    return 0 if not [k for k in missing if not next(s for s in SOURCES if s["key"] == k).get("optional")] else 1


if __name__ == "__main__":
    sys.exit(main())
