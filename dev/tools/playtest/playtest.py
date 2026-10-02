#!/usr/bin/env python3
"""Headless bot playtests: many short runs in parallel, then a summary.

  python dev/tools/playtest/playtest.py run [--runs 6] [--days 20] [--out DIR] [--meta FILE] [--strategies a,b]
      Starts runs_per_strategy x each strategy (default: greedy, variety, careful, cheap) at
      once; "expert" knows every recipe and "gourmet" also tunes it for quality;
      both are left out unless named.
      Each run gets its own APPDATA, so the real saves are never touched. --meta copies a
      meta_progress.cfg into every run for a "veteran" profile. Output defaults to
      dev/tools/playtest/runs/<timestamp>/ (gitignored). 24 runs of 20 days take ~25 s.

  python dev/tools/playtest/playtest.py summary DIR
      One line per run (ending, reputation milestones, raids, ...), totals per strategy,
      and any script errors found in the logs.

  python dev/tools/playtest/playtest.py compare DIR [DIR ...]
      One line per batch, to compare balance changes side by side.

The Godot exe must match the editor version: set GODOT or pass --godot.
Only the expert and gourmet bots discover new styles. No bot does daily goals.
"""
import argparse
import collections
import glob
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DEFAULT_GODOT = r"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
STRATEGIES = ["greedy", "variety", "careful", "cheap"]
ALL_STRATEGIES = STRATEGIES + ["expert", "gourmet"]
USER_DIR = Path("Godot") / "app_userdata" / "Pimea Panimo"
IGNORED_ERROR = re.compile(r"ERROR: \d+ resources still")
ERROR_LINE = re.compile(r"(SCRIPT ERROR:.*|ERROR: .*)")


def run(args: argparse.Namespace) -> None:
    out = Path(args.out) if args.out else HERE / "runs" / datetime.now().strftime("%Y%m%d-%H%M%S")
    out.mkdir(parents=True, exist_ok=True)
    procs = []
    for strategy in args.strategies.split(","):
        for i in range(1, args.runs + 1):
            name = f"{strategy}-{i}"
            appdata = out / name
            if args.meta:
                (appdata / USER_DIR).mkdir(parents=True, exist_ok=True)
                shutil.copy(args.meta, appdata / USER_DIR / "meta_progress.cfg")
            cmd = [
                args.godot, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
                "--log-file", str(out / f"{name}.log"), "-s", str(HERE / "runner.gd"), "--",
                f"--bot={HERE / 'bot.gd'}", f"--strategy={strategy}", f"--max_days={args.days}",
                f"--speed={args.speed}", f"--out={out / f'{name}.json'}",
                f"--profile={'veteran' if args.meta else 'new'}",
            ]
            env = dict(os.environ, APPDATA=str(appdata))
            with open(out / f"{name}.out", "w") as stdout, open(out / f"{name}.err", "w") as stderr:
                procs.append(subprocess.Popen(cmd, env=env, stdout=stdout, stderr=stderr))
    for p in procs:
        p.wait()
    print(f"{len(procs)} runs in {out}")
    summary(argparse.Namespace(dir=str(out)))


def load_runs(directory: str) -> list:
    return [(Path(f).stem, json.load(open(f, encoding="utf-8"))) for f in sorted(glob.glob(os.path.join(directory, "*.json")))]


def first_day_at(report: dict, rep: int):
    return next((d["day"] for d in report["days"] if d["rep"] >= rep), None)


def peak_rep(report: dict) -> int:
    return max([d["rep"] for d in report["days"]] or [0])


def summary(args: argparse.Namespace) -> None:
    errors = collections.Counter()
    per_strategy = collections.defaultdict(list)
    row = "%-14s %-12s %4s %4s %7s %6s %5s %4s %4s %5s %5s %4s %4s %5s %5s %4s"
    print(row % ("run", "ending", "day", "rep", "money", "score", "raids", "30@", "60@", "100@", "peak", "frnd", "badr", "toast", "decay", "eclo"))
    for name, r in load_runs(args.dir):
        for ext in (".log", ".err"):
            log = Path(args.dir) / f"{name}{ext}"
            if log.exists():
                for line in ERROR_LINE.findall(log.read_text(encoding="utf-8", errors="replace")):
                    if not IGNORED_ERROR.match(line):
                        errors[line[:150]] += 1
        c, final = r["counts"], r["final"]
        print(row % (name, r["ending"], final["day"], final["rep"], final["money"], final.get("score", "-"), final["raids"],
                     first_day_at(r, 30), first_day_at(r, 60), first_day_at(r, 100), peak_rep(r),
                     c.get("friends", 0), c.get("bad_reviews", 0), c.get("tier_toasts", 0),
                     c.get("decay_total", 0), c.get("early_closes", 0)))
        per_strategy[name.rsplit("-", 1)[0]].append(r)
    print()
    for strategy, rs in per_strategy.items():
        endings = dict(collections.Counter(r["ending"] for r in rs))
        scores = sorted(r["final"].get("score", 0) for r in rs)
        print("%-8s endings=%s score mean %.0f median %.0f 60@=%s 100@=%s peak=%s lastday=%s" % (
            strategy, endings, sum(scores) / len(scores), scores[len(scores) // 2], [first_day_at(r, 60) for r in rs], [first_day_at(r, 100) for r in rs],
            [peak_rep(r) for r in rs], [r["final"]["day"] for r in rs]))
    print("errors:", errors.most_common(8) or "none")


def compare(args: argparse.Namespace) -> None:
    for directory in args.dirs:
        rs = load_runs(directory)
        if not rs:
            print(f"{directory}: no runs")
            continue
        endings = dict(collections.Counter(r["ending"] for _, r in rs))
        busted = dict(collections.Counter(n.rsplit("-", 1)[0] for n, r in rs if r["ending"] == "busted"))
        n = len(rs)
        print("%-16s %s raids/run %.2f busted by strategy %s avg money %.0f avg peak rep %.0f avg score %.0f" % (
            Path(directory).name, endings, sum(r["final"]["raids"] for _, r in rs) / n, busted,
            sum(r["final"]["money"] for _, r in rs) / n, sum(peak_rep(r) for _, r in rs) / n,
            sum(r["final"].get("score", 0) for _, r in rs) / n))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p_run = sub.add_parser("run")
    p_run.add_argument("--runs", type=int, default=6, help="runs per strategy")
    p_run.add_argument("--days", type=int, default=20)
    p_run.add_argument("--speed", type=float, default=4)
    p_run.add_argument("--out")
    p_run.add_argument("--meta", help="meta_progress.cfg to start every run with")
    p_run.add_argument("--godot", default=os.environ.get("GODOT", DEFAULT_GODOT))
    p_run.add_argument("--strategies", default=",".join(STRATEGIES), help="comma-separated, from: " + ", ".join(ALL_STRATEGIES))
    p_run.set_defaults(func=run)
    p_summary = sub.add_parser("summary")
    p_summary.add_argument("dir")
    p_summary.set_defaults(func=summary)
    p_compare = sub.add_parser("compare")
    p_compare.add_argument("dirs", nargs="+")
    p_compare.set_defaults(func=compare)
    args = parser.parse_args()
    if args.command == "run" and not Path(args.godot).exists():
        sys.exit(f"Godot exe not found: {args.godot} (set GODOT or pass --godot)")
    if args.command == "run" and not set(args.strategies.split(",")) <= set(ALL_STRATEGIES):
        sys.exit(f"Unknown strategy in {args.strategies}; choose from {', '.join(ALL_STRATEGIES)}")
    args.func(args)


if __name__ == "__main__":
    main()
