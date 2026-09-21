#!/usr/bin/env python3
"""Checks that every folder in systems/ is self-contained and can be copied to another project.

  python tools/check_systems.py

Inside systems/<name>/ a script or scene may only reference what lives in that same folder,
plus the engine. The one exception is a `*_wiring.gd` file: it is the single place allowed to
touch the project (its signals, autoloads, wording), and is what you edit after copying the
system. The check lists the project things each wiring file uses, so you can see what to
replace. Exits with 1 when a non-wiring file breaks the rule.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SYSTEMS = ROOT / "systems"
SKIPPED_TOP_FOLDERS = {"addons", ".godot"}


def strip_code(text: str) -> str:
    """Code with string literals and comments blanked, line structure kept."""
    lines = []
    for line in text.split("\n"):
        line = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '""', line)
        lines.append(re.sub(r"#.*", "", line))
    return "\n".join(lines)


def project_names(exclude_folder: Path) -> set:
    """Every class_name and autoload of the project that lives outside `exclude_folder`."""
    names = set()
    for path in ROOT.rglob("*.gd"):
        if path.relative_to(ROOT).parts[0] in SKIPPED_TOP_FOLDERS:
            continue
        if exclude_folder in path.parents:
            continue
        match = re.search(r"^class_name\s+(\w+)", path.read_text(encoding="utf-8"), re.M)
        if match:
            names.add(match.group(1))
    in_autoload = False
    for line in (ROOT / "project.godot").read_text(encoding="utf-8").splitlines():
        if line.startswith("["):
            in_autoload = line.strip() == "[autoload]"
        elif in_autoload:
            match = re.match(r"^(\w+)=", line)
            if match and not match.group(1).startswith("_mcp"):
                names.add(match.group(1))
    return names


def scan_script(path: Path, names: set, folder: Path):
    """(line number, what) for every project reference in one script."""
    raw = path.read_text(encoding="utf-8")
    found = []
    for number, line in enumerate(strip_code(raw).split("\n"), 1):
        for name in sorted(set(re.findall(r"\b([A-Za-z_]\w*)\b", line)) & names):
            found.append((number, name))
    for number, line in enumerate(raw.split("\n"), 1):
        code = line.split("#")[0] if line.strip().startswith("#") else line
        for target in re.findall(r'"(res://[^"]+)"', code):
            if not target.startswith("res://systems/" + folder.name + "/") and not line.strip().startswith("#"):
                found.append((number, target))
    return found


def scan_scene(path: Path, folder: Path):
    found = []
    for number, line in enumerate(path.read_text(encoding="utf-8").split("\n"), 1):
        for target in re.findall(r'path="(res://[^"]+)"', line):
            if not target.startswith("res://systems/" + folder.name + "/"):
                found.append((number, target))
    return found


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    if not SYSTEMS.is_dir():
        print("No systems/ folder.")
        return 0

    violations = 0
    for folder in sorted(p for p in SYSTEMS.iterdir() if p.is_dir()):
        names = project_names(folder)
        problems, wiring = [], []
        for path in sorted(folder.rglob("*")):
            rel = path.relative_to(ROOT).as_posix()
            if path.suffix == ".gd":
                hits = scan_script(path, names, folder)
                (wiring if path.name.endswith("_wiring.gd") else problems).extend((rel, n, w) for n, w in hits)
            elif path.suffix == ".tscn":
                problems.extend((rel, n, w) for n, w in scan_scene(path, folder))

        status = "OK" if not problems else f"{len(problems)} problem(s)"
        print(f"systems/{folder.name}: {status}")
        for rel, number, what in problems:
            print(f"  ! {rel}:{number} references {what}")
        if wiring:
            uses = sorted({w for _, _, w in wiring})
            print(f"  wiring (edit after copying) uses: {', '.join(uses)}")
        violations += len(problems)
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main())
