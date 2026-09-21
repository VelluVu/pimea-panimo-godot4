#!/usr/bin/env python3
"""Round-trip the game's tunable data through spreadsheets.

  python dev/tools/sheets.py export [--out dev/tools/sheets]
      Writes customers_sheet.xlsx and beer_styles_sheet.xlsx from the .tres files.
      Open them in Excel or Google Sheets (File > Import) and edit the light-headed columns.

  python dev/tools/sheets.py import FILE.xlsx [--apply] [--resources src/resources]
      Compares an edited sheet with the .tres files and prints every difference.
      Nothing is written without --apply. Only the editable columns are read.

Needs openpyxl (pip install openpyxl). Only existing `key = value` lines are rewritten and
missing keys are added; nothing else in a .tres file is touched.
"""
import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from openpyxl import Workbook, load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RESOURCES = ROOT / "src" / "resources"
DEFAULT_OUT = ROOT / "dev" / "tools" / "sheets"

HEADER_FILL_READONLY = "4A3B2A"
HEADER_FILL_EDITABLE = "8A6D3B"
HOP_PROFILES = ["-", "Sitrus", "Trooppinen", "Mänty", "Jalo", "Maanläheinen"]
FLOAT_TOLERANCE = 1e-6


# --------------------------------------------------------------------------- .tres files

class Tres:
    """One .tres file; edits keep every other line, and the line endings, as they were."""

    def __init__(self, path: Path):
        raw = path.read_bytes().decode("utf-8")
        self.path = path
        self.newline = "\r\n" if "\r\n" in raw else "\n"
        self.lines = raw.replace("\r\n", "\n").split("\n")
        self.start = next(i for i, line in enumerate(self.lines) if line.startswith("[resource]")) + 1
        self.dirty = False

    def _index(self, key: str) -> int:
        prefix = key + " = "
        for i in range(self.start, len(self.lines)):
            if self.lines[i].startswith(prefix):
                return i
        return -1

    def get_raw(self, key: str):
        i = self._index(key)
        return None if i < 0 else self.lines[i][len(key) + 3:]

    def set_raw(self, key: str, raw: str) -> None:
        i = self._index(key)
        if i >= 0:
            self.lines[i] = f"{key} = {raw}"
        else:
            self.lines.insert(self._insert_position(), f"{key} = {raw}")
        self.dirty = True

    def remove(self, key: str) -> None:
        i = self._index(key)
        if i >= 0:
            del self.lines[i]
            self.dirty = True

    def _insert_position(self) -> int:
        for i in range(self.start, len(self.lines)):
            if self.lines[i].startswith("metadata/"):
                return i
        return len(self.lines) - 1 if self.lines[-1] == "" else len(self.lines)

    def save(self) -> None:
        self.path.write_bytes(self.newline.join(self.lines).encode("utf-8"))


def parse_value(raw):
    """A .tres value as a Python value; anything unrecognised comes back as its raw text."""
    if raw is None:
        return None
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        return raw[1:-1]
    if raw in ("true", "false"):
        return raw == "true"
    array = re.match(r"^Array\[[^\]]*\]\(\[(.*)\]\)$", raw)
    if array:
        body = array.group(1).strip()
        items = [item.strip() for item in body.split(",")] if body else []
        return [int(x) if re.fullmatch(r"-?\d+", x) else x.strip('"') for x in items]
    try:
        return float(raw) if ("." in raw or "e" in raw.lower()) else int(raw)
    except ValueError:
        return raw


def format_float(value: float) -> str:
    text = ("%.4f" % value).rstrip("0")
    return text + "0" if text.endswith(".") else text


# --------------------------------------------------------------------------- column definitions

@dataclass
class Column:
    header: str
    key: str
    kind: str          # style, styles, bool, float, int
    default: object    # what an absent key means; also what an empty cell means
    editable: bool = True


CUSTOMER_COLUMNS = [
    Column("Suosikki (ensisijainen)", "primary_style", "style", 1),
    Column("Toissijainen", "secondary_style", "style", 0),
    Column("Hyväksytyt tyylit (accepted_styles)", "accepted_styles", "styles", []),
    Column("Vain suosikit", "requires_preference_match", "bool", False),
    Column("Min. ABV", "min_required_abv", "float", -1.0),
    Column("Max ABV", "max_required_abv", "float", -1.0),
    Column("Max hinta €", "max_required_price", "float", -1.0),
    Column("Min. laatu", "min_quality", "float", 0.5),
    Column("Min. maine", "min_reputation_to_appear", "int", 0),
    Column("Vaatii löydetyn tyylin", "required_discovered_style", "style", -1),
    Column("Arpoo suosikit", "randomizes_preference", "bool", False),
    Column("Pulloja min", "min_bottles_per_visit", "int", 1),
    Column("Pulloja max", "max_bottles_per_visit", "int", 1),
]

STYLE_COLUMNS = [
    Column("ABV %", "abv", "float", 5.0),
    Column("Hinta €", "fixed_price_per_bottle", "float", 0.0),
    Column("Min. maltaiden määrä", "min_malt_weight", "int", 3),
    Column("EBC min", "min_ebc", "int", 0),
    Column("EBC max", "max_ebc", "int", 999),
    Column("IBU min", "min_ibu", "int", 0),
    Column("IBU max", "max_ibu", "int", 999),
]

RANGE_PAIRS = [("Min. ABV", "Max ABV"), ("Pulloja min", "Pulloja max"), ("EBC min", "EBC max"), ("IBU min", "IBU max")]


# --------------------------------------------------------------------------- game data

class GameData:
    def __init__(self, resources: Path):
        self.resources = resources
        self.styles = sorted((Tres(p) for p in (resources / "beer_styles").glob("*.tres")),
                             key=lambda t: parse_value(t.get_raw("style")) or 0)
        self.style_names = {}   # id -> name
        self.style_ids = {}     # name -> id
        for tres in self.styles:
            style_id = parse_value(tres.get_raw("style")) or 0
            name = parse_value(tres.get_raw("style_name"))
            self.style_names[style_id] = name
            self.style_ids[name] = style_id

    def customers(self):
        for path in sorted((self.resources / "customers").glob("**/*.tres")):
            tres = Tres(path)
            if tres.get_raw("customer_name") is not None:
                yield tres

    def ingredients(self, folder: str):
        return [Tres(p) for p in sorted((self.resources / "ingredients" / folder).glob("*.tres"))]

    def style_name(self, style_id) -> str:
        return self.style_names.get(style_id, str(style_id))


def current_value(tres: Tres, column: Column):
    value = parse_value(tres.get_raw(column.key))
    return column.default if value is None else value


def to_cell(column: Column, value, data: GameData):
    if column.kind == "style":
        return "" if value == -1 else data.style_name(value)
    if column.kind == "styles":
        return ", ".join(data.style_name(v) for v in value)
    if column.kind == "bool":
        return "kyllä" if value else ""
    if column.kind == "float" and value == column.default and column.default == -1.0:
        return None
    return value


def from_cell(column: Column, cell, data: GameData):
    """The cell as a canonical value; raises ValueError with a readable reason."""
    empty = cell is None or (isinstance(cell, str) and not cell.strip())
    if column.kind == "style":
        if empty:
            return -1
        return _style_id(cell, data)
    if column.kind == "styles":
        if empty:
            return []
        return [_style_id(part, data) for part in str(cell).split(",") if part.strip()]
    if column.kind == "bool":
        return not empty and str(cell).strip().lower() in ("kyllä", "kylla", "yes", "true", "1", "x")
    if empty:
        return column.default
    try:
        return float(cell) if column.kind == "float" else int(round(float(cell)))
    except (TypeError, ValueError):
        raise ValueError(f"'{cell}' is not a number")


def _style_id(text, data: GameData) -> int:
    text = str(text).strip()
    if text in data.style_ids:
        return data.style_ids[text]
    if re.fullmatch(r"-?\d+", text):
        return int(text)
    raise ValueError(f"unknown beer style '{text}'")


def same(a, b) -> bool:
    if isinstance(a, float) or isinstance(b, float):
        return abs(float(a) - float(b)) < FLOAT_TOLERANCE
    return a == b


def to_raw(column: Column, value) -> str:
    if column.kind == "bool":
        return "true" if value else "false"
    if column.kind == "float":
        return format_float(value)
    if column.kind == "styles":
        return "Array[int]([" + ", ".join(str(v) for v in value) + "])"
    return str(int(value))


# --------------------------------------------------------------------------- export

def write_sheet(ws, headers, editable, rows, widths):
    ws.append(headers)
    for row in rows:
        ws.append(row)
    for i, cell in enumerate(ws[1]):
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor=HEADER_FILL_EDITABLE if editable[i] else HEADER_FILL_READONLY)
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    for i, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = width
    for row in ws.iter_rows(min_row=2):
        for cell in row:
            cell.alignment = Alignment(wrap_text=True, vertical="top")
    ws.freeze_panes = "C2" if headers[0] == "Tiedosto" else "B2"
    ws.auto_filter.ref = ws.dimensions


def add_help_sheet(wb, lines):
    ws = wb.create_sheet("Ohje")
    for line in lines:
        ws.append([line])
    ws.column_dimensions["A"].width = 110


BUYABLE_HEADER = "Ostaa oikeasti (kovien rajojen jälkeen)"
CUSTOMER_READONLY = {"Tiedosto", "Asiakas", BUYABLE_HEADER, "Vaatii saavutuksen"}
CUSTOMER_WIDTHS = [30, 24, 20, 20, 34, 10, 60, 8, 8, 10, 10, 10, 20, 10, 9, 9, 20]


def buyable_styles(data: GameData, values: dict) -> list:
    """The styles a customer can actually buy after the hard gates."""
    allowed = []
    for style in data.styles:
        sid = parse_value(style.get_raw("style")) or 0
        abv = parse_value(style.get_raw("abv")) or 5.0
        price = parse_value(style.get_raw("fixed_price_per_bottle")) or 0.0
        if values["min_required_abv"] >= 0 and abv < values["min_required_abv"]:
            continue
        if values["max_required_abv"] >= 0 and abv > values["max_required_abv"]:
            continue
        if values["max_required_price"] >= 0 and price > values["max_required_price"]:
            continue
        if values["accepted_styles"] and sid not in values["accepted_styles"]:
            continue
        if values["requires_preference_match"] and sid not in (values["primary_style"], values["secondary_style"]):
            continue
        allowed.append(data.style_name(sid))
    return allowed


def export_customers(data: GameData, out: Path) -> Path:
    columns = CUSTOMER_COLUMNS
    headers = (["Tiedosto", "Asiakas"] + [c.header for c in columns[:4]] + [BUYABLE_HEADER]
               + [c.header for c in columns[4:]] + ["Vaatii saavutuksen"])
    rows = []
    for tres in data.customers():
        values = {c.key: current_value(tres, c) for c in columns}
        buyable = buyable_styles(data, values)
        row = {"Tiedosto": tres.path.name, "Asiakas": parse_value(tres.get_raw("title")) or "",
               BUYABLE_HEADER: "kaikki" if len(buyable) == len(data.styles) else ", ".join(buyable),
               "Vaatii saavutuksen": parse_value(tres.get_raw("required_achievement_id")) or ""}
        for column in columns:
            row[column.header] = to_cell(column, values[column.key], data)
        rows.append([row[h] for h in headers])

    wb = Workbook()
    ws = wb.active
    ws.title = "Asiakkaat"
    write_sheet(ws, headers, [h not in CUSTOMER_READONLY for h in headers], rows, CUSTOMER_WIDTHS)
    add_help_sheet(wb, [
        "Muokkaa vain vaaleampia otsikkosarakkeita. Tumman otsikon sarakkeet ovat vain luettavia.",
        "Tyylit kirjoitetaan nimillä (esim. Märzen), useampi pilkulla eroteltuna. Tyhjä = ei rajoitusta.",
        "Tuo muutokset peliin: python dev/tools/sheets.py import tiedosto.xlsx  (lisää --apply kirjoittaaksesi).",
    ])
    path = out / "customers_sheet.xlsx"
    wb.save(path)
    return path


def export_styles(data: GameData, out: Path) -> Path:
    yeasts = {parse_value(t.get_raw("id")): t for t in data.ingredients("yeasts")}
    malts = {parse_value(t.get_raw("id")): t for t in data.ingredients("malts")}
    headers = (["Tyyli"] + [c.header for c in STYLE_COLUMNS[:2]] + ["Vaadittu hiiva", "Vaadittu mallas"]
               + [c.header for c in STYLE_COLUMNS[2:]] + ["Humalaprofiili"])
    rows = []
    for tres in data.styles:
        yeast = yeasts.get(parse_value(tres.get_raw("required_yeast_id")) or 301)
        malt = malts.get(parse_value(tres.get_raw("required_malt_id")) if tres.get_raw("required_malt_id") else -1)
        values = {c.header: current_value(tres, c) for c in STYLE_COLUMNS}
        rows.append([parse_value(tres.get_raw("style_name"))] + [values[c.header] for c in STYLE_COLUMNS[:2]]
                    + [parse_value(yeast.get_raw("name")) if yeast else "?", parse_value(malt.get_raw("name")) if malt else "-"]
                    + [values[c.header] for c in STYLE_COLUMNS[2:]]
                    + [HOP_PROFILES[parse_value(tres.get_raw("preferred_hop_profile")) or 0]])

    readonly = {"Tyyli", "Vaadittu hiiva", "Vaadittu mallas", "Humalaprofiili"}
    wb = Workbook()
    ws = wb.active
    ws.title = "Oluttyylit"
    write_sheet(ws, headers, [h not in readonly for h in headers], rows, [24, 8, 9, 24, 20, 12, 9, 9, 9, 9, 16])

    write_sheet(wb.create_sheet("Maltaat"), ["ID", "Mallas", "EBC", "Hinta", "Min. maine"], [False] * 5,
                [[parse_value(t.get_raw("id")), parse_value(t.get_raw("name")), parse_value(t.get_raw("ebc")),
                  parse_value(t.get_raw("base_price")), parse_value(t.get_raw("min_reputation")) or 0]
                 for t in sorted(malts.values(), key=lambda t: parse_value(t.get_raw("ebc")))], [8, 24, 8, 8, 12])
    write_sheet(wb.create_sheet("Humalat"), ["ID", "Humala", "Alfahapot %", "Beetahapot %", "Profiili", "Hinta", "Min. maine"], [False] * 7,
                [[parse_value(t.get_raw("id")), parse_value(t.get_raw("name")), parse_value(t.get_raw("alpha_acids")),
                  parse_value(t.get_raw("beta_acids")), HOP_PROFILES[parse_value(t.get_raw("flavor_profile")) or 0],
                  parse_value(t.get_raw("base_price")), parse_value(t.get_raw("min_reputation")) or 0]
                 for t in data.ingredients("hops")], [8, 26, 12, 12, 16, 8, 12])
    write_sheet(wb.create_sheet("Hiivat"), ["ID", "Hiiva", "Vetelöityminen %", "Hinta", "Min. maine"], [False] * 5,
                [[parse_value(t.get_raw("id")), parse_value(t.get_raw("name")), parse_value(t.get_raw("attentuation_percent")),
                  parse_value(t.get_raw("base_price")), parse_value(t.get_raw("min_reputation")) or 0]
                 for t in sorted(yeasts.values(), key=lambda t: parse_value(t.get_raw("id")))], [8, 26, 16, 8, 12])
    add_help_sheet(wb, [
        "Muokkaa vain 'Oluttyylit'-välilehden vaaleampia otsikkosarakkeita (ABV, hinta, EBC, IBU, maltaiden määrä).",
        "Hiiva, mallas ja humalaprofiili ovat vain luettavia. Muut välilehdet ovat viitetietoja.",
        "Tuo muutokset peliin: python dev/tools/sheets.py import tiedosto.xlsx  (lisää --apply kirjoittaaksesi).",
    ])
    path = out / "beer_styles_sheet.xlsx"
    wb.save(path)
    return path


# --------------------------------------------------------------------------- import

def read_rows(ws):
    headers = [c.value for c in ws[1]]
    for row in ws.iter_rows(min_row=2, values_only=True):
        if any(cell is not None and str(cell).strip() for cell in row):
            yield dict(zip(headers, row))


def import_sheet(path: Path, data: GameData, apply: bool) -> int:
    if not path.is_file():
        print(f"File not found: {path}")
        return 1
    wb = load_workbook(path, data_only=True)
    if "Asiakkaat" in wb.sheetnames:
        ws, columns, id_header = wb["Asiakkaat"], CUSTOMER_COLUMNS, "Tiedosto"
        targets = {t.path.name: t for t in data.customers()}
    elif "Oluttyylit" in wb.sheetnames:
        ws, columns, id_header = wb["Oluttyylit"], STYLE_COLUMNS, "Tyyli"
        targets = {parse_value(t.get_raw("style_name")): t for t in data.styles}
    else:
        print("Unknown workbook: expected an 'Asiakkaat' or 'Oluttyylit' sheet.")
        return 1

    errors = 0
    changed_files = []
    for row in read_rows(ws):
        name = row.get(id_header)
        tres = targets.get(name)
        if tres is None:
            print(f"! {name}: no such {'file' if id_header == 'Tiedosto' else 'style'}, row skipped")
            errors += 1
            continue

        lines = []
        for column in columns:
            if column.header not in row:
                continue
            try:
                new = from_cell(column, row[column.header], data)
            except ValueError as error:
                print(f"! {name} / {column.header}: {error}, cell skipped")
                errors += 1
                continue
            old = current_value(tres, column)
            if same(old, new):
                continue
            lines.append(f"    {column.key}: {display(column, old, data)} -> {display(column, new, data)}")
            if same(new, column.default):
                tres.remove(column.key)
            else:
                tres.set_raw(column.key, to_raw(column, new))
        for low, high in RANGE_PAIRS:
            lo, hi = row.get(low), row.get(high)
            if isinstance(lo, (int, float)) and isinstance(hi, (int, float)) and lo > hi and hi >= 0:
                print(f"! {name}: '{low}' ({lo}) is above '{high}' ({hi})")
        if lines:
            print(f"{name}")
            print("\n".join(lines))
            changed_files.append(tres)

    if not changed_files:
        print("No changes.")
    elif apply:
        for tres in changed_files:
            tres.save()
        print(f"\nWrote {len(changed_files)} file(s). Rescan the project in Godot and run the tests.")
    else:
        print(f"\n{len(changed_files)} file(s) would change. Run again with --apply to write them.")
    return 1 if errors else 0


def display(column: Column, value, data: GameData) -> str:
    if column.kind in ("style", "styles"):
        return to_cell(column, value, data) or "(none)"
    return str(value)


# --------------------------------------------------------------------------- main

def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    export = sub.add_parser("export")
    export.add_argument("--out", type=Path, default=DEFAULT_OUT)
    export.add_argument("--resources", type=Path, default=DEFAULT_RESOURCES)
    imp = sub.add_parser("import")
    imp.add_argument("file", type=Path)
    imp.add_argument("--apply", action="store_true")
    imp.add_argument("--resources", type=Path, default=DEFAULT_RESOURCES)
    args = parser.parse_args()

    data = GameData(args.resources)
    if args.command == "export":
        args.out.mkdir(parents=True, exist_ok=True)
        for path in (export_customers(data, args.out), export_styles(data, args.out)):
            print(f"Wrote {path}")
        return 0
    return import_sheet(args.file, data, args.apply)


if __name__ == "__main__":
    sys.exit(main())
