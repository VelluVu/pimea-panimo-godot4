#!/usr/bin/env python3
"""The English translation of the game's Finnish texts.

The texts are written in Finnish and are their own translation keys: a Label or Button
whose text is a key shows the English automatically, and code that fills numbers into a
text calls tr() on it first. SettingsWiring loads src/resources/translations/en.po,
which Godot reads as it is (no import step).

  python dev/tools/i18n.py extract
      Finds the player-facing texts in src/ (string constants in scripts, text in scenes)
      and adds the new ones to en.po. English already written is kept, and texts no
      longer found are dropped.

  python dev/tools/i18n.py check
      Lists texts with no English yet and English whose %d/%s/%.1f placeholders differ
      from the Finnish. Exit code 1 if any.

Each entry in en.po is the file the text was found in, the Finnish (msgid) and the
English below it (msgstr); write the English in msgstr, then run check. Any text editor
or Poedit works. Long texts are wrapped over several quoted lines, which join with no
added spaces or line breaks; a line break in the text is written \\n.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PO_PATH = ROOT / "src" / "resources" / "translations" / "en.po"
PO_HEADER = (
    'msgid ""\nmsgstr ""\n'
    '"Language: en\\n"\n'
    '"MIME-Version: 1.0\\n"\n'
    '"Content-Type: text/plain; charset=UTF-8\\n"\n'
    '"Content-Transfer-Encoding: 8bit\\n"\n'
)
# Texts longer than this, or with line breaks, go on their own quoted lines.
PO_WRAP = 76
SCRIPT_DIRS = ["src"]
# Dev-only text and content files (phase 2) stay out.
# Content resources whose fields hold player-facing text. Phase 2 adds the rest here.
CONTENT_FIELDS = {
    "src/resources/ingredients": ("name", "description"),
    "src/resources/daily_goals": ("goal_name",),
    "src/resources/reputation_tiers": ("tier_name", "description"),
    "src/resources/beer_styles": ("style_name",),
    "src/resources/bars": ("bar_name", "description"),
    "src/resources/cellar_upgrades": ("perk_name", "description"),
    "src/resources/perks": ("perk_name", "description"),
    "src/resources/meta_unlocks": ("perk_name", "description"),
    "src/resources/achievements": ("title", "description"),
    "src/resources/customers": ("title", "dialogue_intro", "dialogue_success", "dialogue_fallback", "dialogue_wrong_style",
                                "dialogue_reject", "dialogue_no_match", "dialogue_preview_format",
                                "dialogue_nothing_available", "dialogue_bar_fight", "dialogue_purity_law_broken"),
    "src/resources/day_events": ("announcement_text", "effect_toast_format"),
    "src/resources/group_events": ("banner_text",),
    "src/resources/special_events": ("event_caller_name", "intro_dialogue", "success_dialogue", "fail_dialogue", "reject_dialogue"),
}
# Content fields that hold a list of texts, like Array[String](["a", "b"]).
CONTENT_ARRAY_FIELDS = {
    "src/resources/group_events": ("chant_texts",),
}
SKIP_DIRS = ["src/console", "src/systems/console", "src/resources", "addons", "tests", "dev"]
# Player-facing files inside the skipped folders. The other console sets are gitignored cheats.
KEEP_FILES = ["src/console/player_commands.gd", "src/systems/console/console_wiring.gd"]

CONST_STRING = re.compile(r'^\s*const\s+(\w+)\s*:\s*String\s*=\s*"((?:[^"\\]|\\.)*)"', re.M)
CONST_ARRAY = re.compile(r'^\s*const\s+(\w+)\s*:\s*(?:Array\[String\]|PackedStringArray)\s*=\s*\[(.*?)\]', re.M | re.S)
CONST_DICT = re.compile(r'^\s*const\s+(\w+)\s*:\s*Dictionary\s*=\s*\{(.*?)\}', re.M | re.S)
QUOTED = re.compile(r'"((?:[^"\\]|\\.)*)"')
# A dictionary entry on its own line, like `ACTION_SHOP: "Kauppa",` or `"hint": "...",`.
DICT_ENTRY = re.compile(r'^\s*(?:[A-Z][A-Z0-9_]*|"\w+")\s*:\s*"((?:[^"\\]|\\.)*)",?\s*$', re.M)
SCENE_TEXT = re.compile(r'^(text|tooltip_text|placeholder_text) = "((?:[^"\\]|\\.)*)"', re.M)
TEXT_NAME = re.compile(r'(_LABEL|_TEXT|_STRING|_HINT|^KPL)$')
PLACEHOLDER = re.compile(r'%[-+0-9.]*[dsf%]')
# Constant names that hold paths, keys or log text rather than player-facing words.
SKIP_NAME = re.compile(r'(SPAWN_POINT|PATH|DIR|FOLDER|SECTION|^KEY|_KEY|_GROUP$|ACTION|ANIM|^BUS_|ERROR|WARNING|_ID$|SCENE|SUFFIX|PREFIX|FILE|URL|META|CONFIG|SIGNAL|NODE|EXTENSION|DEBUG|LOG_|^DATABASE_STRING$|^INVENTORY_STRING$|^LIST_STRING$|^MONEY_STRING$)')


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
    if rel in KEEP_FILES:
        return False
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
    for folder, fields in CONTENT_FIELDS.items():
        field_re = re.compile(r'^(?:' + "|".join(fields) + r') = "((?:[^"\\]|\\.)*)"', re.M)
        for path in sorted((ROOT / folder).rglob("*.tres")):
            for value in field_re.findall(path.read_text(encoding="utf-8")):
                add(value, _rel(path), "_TEXT")
    for folder, fields in CONTENT_ARRAY_FIELDS.items():
        array_re = re.compile(r'^(?:' + "|".join(fields) + r') = Array\[String\]\(\[(.*?)\]\)', re.M | re.S)
        for path in sorted((ROOT / folder).rglob("*.tres")):
            for body in array_re.findall(path.read_text(encoding="utf-8")):
                for value in QUOTED.findall(body):
                    add(value, _rel(path), "_TEXT")
    # A .tres leaves out a field still at its script default, so read the defaults too.
    fields = sorted({field for names in CONTENT_FIELDS.values() for field in names})
    default_re = re.compile(r'^@export\w*\s+var\s+(?:' + "|".join(fields) + r')\s*:\s*String\s*=\s*"((?:[^"\\]|\\.)*)"', re.M)
    for path in sorted((ROOT / "src").rglob("*.gd")):
        if not _skipped(path):
            for value in default_re.findall(path.read_text(encoding="utf-8")):
                add(value, _rel(path), "_TEXT")
    return found


def _po_escape(text):
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t").replace("\n", "\\n")


def _po_unescape(text):
    return re.sub(r'\\(.)', lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), text)


def _po_pieces(text):
    """Splits after each line break, then wraps long lines after a space."""
    pieces = []
    for line in re.findall(r'[^\n]*\n|[^\n]+', text):
        while len(line) > PO_WRAP:
            cut = line.rfind(" ", 0, PO_WRAP) + 1
            if cut <= 0:
                break
            pieces.append(line[:cut])
            line = line[cut:]
        pieces.append(line)
    return pieces


def _po_field(name, text):
    pieces = _po_pieces(text)
    if len(pieces) <= 1:
        return f'{name} "{_po_escape(text)}"\n'
    return f'{name} ""\n' + "".join(f'"{_po_escape(p)}"\n' for p in pieces)


def read_po():
    """Finnish -> {"en", "source"}. The header entry (empty msgid) is left out."""
    rows = {}
    if not PO_PATH.exists():
        return rows
    entry, field = {"source": ""}, None
    for line in PO_PATH.read_text(encoding="utf-8").splitlines() + [""]:
        line = line.strip()
        if not line:
            if entry.get("msgid"):
                rows[entry["msgid"]] = {"en": entry.get("msgstr", ""), "source": entry["source"]}
            entry, field = {"source": ""}, None
        elif line.startswith("#:"):
            entry["source"] = line[2:].strip()
        elif line.startswith(("msgid ", "msgstr ")):
            field, quoted = line.split(" ", 1)
            entry[field] = _po_unescape(quoted[1:-1])
        elif line.startswith('"') and field:
            entry[field] += _po_unescape(line[1:-1])
    return rows


def write_po(rows):
    PO_PATH.parent.mkdir(parents=True, exist_ok=True)
    entries = [PO_HEADER]
    for key in sorted(rows, key=lambda k: (rows[k]["source"], k)):
        entries.append(f'#: {rows[key]["source"]}\n' + _po_field("msgid", key) + _po_field("msgstr", rows[key]["en"]))
    PO_PATH.write_text("\n".join(entries), encoding="utf-8", newline="\n")


def extract():
    old = read_po()
    found = find_texts()
    rows = {}
    for key, source in found.items():
        rows[key] = {"en": old.get(key, {}).get("en", ""), "source": source}
    write_po(rows)
    added = len([k for k in found if k not in old])
    dropped = len([k for k in old if k not in found])
    print(f"{len(rows)} texts, {added} new, {dropped} dropped -> {_rel(PO_PATH)}")


def check():
    problems = 0
    for key, row in read_po().items():
        if not row["en"]:
            print(f"missing: {key!r} ({row['source']})")
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
