#!/usr/bin/env python3
"""The English translation of the game's Finnish texts.

The texts are written in Finnish and are their own translation keys: a Label or Button
whose text is a key shows the English automatically, and code that fills numbers into a
text calls tr() on it first. Godot imports the CSV into strings.en.translation, which
SettingsWiring loads.

  python dev/tools/i18n.py extract
      Finds the player-facing texts in src/ (string constants in scripts, text in scenes)
      and adds the new ones to src/resources/translations/strings.csv. English already
      written is kept, and texts no longer found are dropped.

  python dev/tools/i18n.py check
      Lists texts with no English yet and English whose %d/%s/%.1f placeholders differ
      from the Finnish. Exit code 1 if any.

The CSV's columns are keys (Finnish), en and _source (where the text is, ignored by
Godot). Edit it in a spreadsheet like the sheets.py exports, then run check. The editor
reimports the CSV when it regains focus; until then the game shows the old English.
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = ROOT / "src" / "resources" / "translations" / "strings.csv"
SCRIPT_DIRS = ["src"]
# Dev-only text and content files (phase 2) stay out.
SKIP_DIRS = ["src/console", "src/systems/console", "src/resources", "addons", "tests", "dev"]

CONST_STRING = re.compile(r'^\s*const\s+(\w+)\s*:\s*String\s*=\s*"((?:[^"\\]|\\.)*)"', re.M)
CONST_ARRAY = re.compile(r'^\s*const\s+(\w+)\s*:\s*Array\[String\]\s*=\s*\[(.*?)\]', re.M | re.S)
CONST_DICT = re.compile(r'^\s*const\s+(\w+)\s*:\s*Dictionary\s*=\s*\{(.*?)\}', re.M | re.S)
QUOTED = re.compile(r'"((?:[^"\\]|\\.)*)"')
# A dictionary entry on its own line, like `ACTION_SHOP: "Kauppa",` or `"hint": "...",`.
DICT_ENTRY = re.compile(r'^\s*(?:[A-Z][A-Z0-9_]*|"\w+")\s*:\s*"((?:[^"\\]|\\.)*)",?\s*$', re.M)
SCENE_TEXT = re.compile(r'^(text|tooltip_text|placeholder_text) = "((?:[^"\\]|\\.)*)"', re.M)
TEXT_NAME = re.compile(r'(_LABEL|_TEXT|_STRING|_HINT)$')
PLACEHOLDER = re.compile(r'%[-+0-9.]*[dsf%]')
# Constant names that hold paths, keys or log text rather than player-facing words.
SKIP_NAME = re.compile(r'(SPAWN_POINT|PATH|DIR|FOLDER|SECTION|^KEY|_KEY|_GROUP$|ACTION|ANIM|BUS|ERROR|WARNING|MESSAGE|_ID$|SCENE|SUFFIX|PREFIX|FILE|URL|META|SAVE|CONFIG|SIGNAL|NODE|^TITLE_|_TITLE$|EXTENSION|DEBUG|LOG_|^DATABASE_STRING$|^INVENTORY_STRING$|^LIST_STRING$|^MONEY_STRING$)')


def _is_text(value, name=""):
    """Words a player reads: has a letter, is not a path or a snake_case identifier. A
    single lowercase word counts only from a constant named like a text (_LABEL, _TEXT)."""
    words = PLACEHOLDER.sub("", value).replace("\n", " ")
    if not re.search(r'[A-Za-zÄÖÅäöå]{2,}', words):
        return False
    if value.startswith(("res://", "user://", "uid://", "http")):
        return False
    if re.fullmatch(r'[a-z0-9_./]+', value) and not (re.fullmatch(r'[a-zäöå]+', value) and TEXT_NAME.search(name)):
        return False
    return True


def _unescape(value):
    return value.encode("utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")


def _rel(path):
    return path.relative_to(ROOT).as_posix()


def _skipped(path):
    rel = _rel(path)
    return any(rel == d or rel.startswith(d + "/") for d in SKIP_DIRS)


def find_texts():
    """Finnish text -> the first file it was found in."""
    found = {}

    def add(value, source, name=""):
        value = _unescape(value)
        if _is_text(value, name) and value not in found:
            found[value] = source

    for base in SCRIPT_DIRS:
        for path in sorted((ROOT / base).rglob("*.gd")):
            if _skipped(path):
                continue
            text = path.read_text(encoding="utf-8")
            for name, value in CONST_STRING.findall(text):
                if not SKIP_NAME.search(name):
                    add(value, _rel(path), name)
            for value in DICT_ENTRY.findall(text):
                add(value, _rel(path))
            for pattern in (CONST_ARRAY, CONST_DICT):
                for name, body in pattern.findall(text):
                    if not SKIP_NAME.search(name):
                        for value in QUOTED.findall(body):
                            add(value, _rel(path))
        for path in sorted((ROOT / base).rglob("*.tscn")):
            if _skipped(path):
                continue
            for _prop, value in SCENE_TEXT.findall(path.read_text(encoding="utf-8")):
                add(value, _rel(path))
    return found


def read_csv():
    rows = {}
    if CSV_PATH.exists():
        with CSV_PATH.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                rows[row["keys"]] = row
    return rows


def write_csv(rows):
    CSV_PATH.parent.mkdir(parents=True, exist_ok=True)
    with CSV_PATH.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["keys", "en", "_source"], lineterminator="\n")
        writer.writeheader()
        for key in sorted(rows, key=lambda k: (rows[k]["_source"], k)):
            writer.writerow(rows[key])


def extract():
    old = read_csv()
    found = find_texts()
    rows = {}
    for key, source in found.items():
        rows[key] = {"keys": key, "en": old.get(key, {}).get("en", ""), "_source": source}
    write_csv(rows)
    added = len([k for k in found if k not in old])
    dropped = len([k for k in old if k not in found])
    print(f"{len(rows)} texts, {added} new, {dropped} dropped -> {_rel(CSV_PATH)}")


def check():
    problems = 0
    for key, row in read_csv().items():
        if not row["en"]:
            print(f"missing: {key!r} ({row['_source']})")
            problems += 1
        elif sorted(PLACEHOLDER.findall(key)) != sorted(PLACEHOLDER.findall(row["en"])):
            print(f"placeholders differ: {key!r} -> {row['en']!r}")
            problems += 1
    print(f"{problems} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command == "extract":
        extract()
    elif command == "check":
        sys.exit(check())
    else:
        print(__doc__)
        sys.exit(2)
