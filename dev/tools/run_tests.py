#!/usr/bin/env python3
"""Runs the unit tests headless (tests/run_headless.gd) with a throwaway APPDATA.

  python dev/tools/run_tests.py [--suite NAME] [--test PART] [--all-output]

Prints the summary line and every FAIL line, exit code 1 on a failure. Use this instead
of the MCP test_run: in the editor, .tres resources with non-tool scripts load as
placeholders, so the tests that call into the game's data fail there.
The Godot exe must match the editor version: set GODOT or pass --godot.
"""
import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GODOT = r"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--suite", default="", help="run only this suite")
    parser.add_argument("--test", default="", help="run only tests whose name contains this")
    parser.add_argument("--all-output", action="store_true", help="print the whole Godot output")
    parser.add_argument("--godot", default=os.environ.get("GODOT", DEFAULT_GODOT))
    args = parser.parse_args()
    if not Path(args.godot).exists():
        sys.exit(f"Godot exe not found: {args.godot} (set GODOT or pass --godot)")

    # The save tests write user data; a fresh APPDATA keeps the real saves safe.
    with tempfile.TemporaryDirectory(prefix="pimea_tests_") as appdata:
        cmd = [args.godot, "--headless", "--path", str(ROOT), "-s", "res://tests/run_headless.gd", "--",
               f"--suite={args.suite}", f"--test={args.test}"]
        env = dict(os.environ, APPDATA=appdata)
        done = subprocess.run(cmd, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace")

    output = done.stdout + done.stderr
    if args.all_output:
        print(output)
    else:
        for line in output.splitlines():
            if line.startswith("[tests]") or line.lstrip().startswith(("FAIL ", "SCRIPT ERROR", "Parse Error")):
                print(line)
    sys.exit(done.returncode)


if __name__ == "__main__":
    main()
