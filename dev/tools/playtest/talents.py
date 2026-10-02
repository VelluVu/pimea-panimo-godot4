#!/usr/bin/env python3
"""Olutoppi spec comparison: the same bots, each batch started with a different talent spec.

  python dev/tools/playtest/talents.py [--runs 10] [--budgets 300,full] [--strategies expert,gourmet]
      Builds a meta_progress.cfg per spec from src/resources/meta_unlocks/, runs
      playtest.py once per spec with it, then prints one row per spec and strategy.
      Specs: "none", every path at every budget ("bar-300", "brewing-full", ...) and
      "balanced-<budget>", which spreads the largest budget over all three paths.
      A budget is spent one level at a time on the cheapest level the tree allows.

  python dev/tools/playtest/talents.py --report DIR [DIR ...]
      Prints the table again for earlier output folders, pooling runs of the same spec.
"""
import argparse
import json
import re
import statistics
import subprocess
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
UNLOCK_DIR = ROOT / "src" / "resources" / "meta_unlocks"
PATHS = {0: "bar", 1: "brewing", 2: "marketing"}


def load_unlocks() -> list:
    unlocks = []
    for f in sorted(UNLOCK_DIR.glob("*.tres")):
        text = f.read_text(encoding="utf-8")
        field = lambda name, default: (re.search(rf"^{name} = (.*)$", text, re.M) or [None, default])[1]
        unlocks.append({
            "id": field("unlock_id", "").strip('"'),
            "path": int(field("path", 0)),
            "max_level": int(field("max_level", 1)),
            "cost": int(field("renown_cost_per_level", 0)),
            "prerequisites": re.findall(r'"([^"]+)"', field("prerequisite_ids", "")),
            "any": field("requires_any_prerequisite", "false") == "true",
        })
    return unlocks


def available(unlock: dict, levels: dict) -> bool:
    if levels.get(unlock["id"], 0) >= unlock["max_level"]:
        return False
    invested = [levels.get(p, 0) > 0 for p in unlock["prerequisites"]]
    return not invested or (any(invested) if unlock["any"] else all(invested))


def buy(unlocks: list, paths: list, budget: float) -> dict:
    """Spends `budget` one level at a time, rotating through `paths`, always on the
    cheapest level the tree allows in that path."""
    levels, spent, turn = {}, 0, 0
    while True:
        bought = False
        for _ in paths:
            path = paths[turn % len(paths)]
            turn += 1
            options = [u for u in unlocks if u["path"] == path and available(u, levels) and spent + u["cost"] <= budget]
            if options:
                pick = min(options, key=lambda u: u["cost"])
                levels[pick["id"]] = levels.get(pick["id"], 0) + 1
                spent += pick["cost"]
                bought = True
                break
        if not bought:
            return levels


def specs(unlocks: list, budgets: list) -> dict:
    result = {"none": {}}
    for path, name in PATHS.items():
        for budget in budgets:
            result[f"{name}-{budget}"] = buy(unlocks, [path], float("inf") if budget == "full" else int(budget))
    largest = max(sum(u["cost"] * u["max_level"] for u in unlocks if u["path"] == p) for p in PATHS) \
        if "full" in budgets else max(int(b) for b in budgets)
    result[f"balanced-{budgets[-1]}"] = buy(unlocks, list(PATHS), largest)
    return result


def write_cfg(path: Path, levels: dict) -> None:
    body = ", ".join(f'"{k}": {v}' for k, v in levels.items())
    path.write_text(f"[meta_progress]\n\nrenown=0\nunlocked_levels={{{body}}}\ndiscovered_styles=[]\n", encoding="utf-8")


def report(outs: list, unlocks: list) -> None:
    cost = {u["id"]: u["cost"] for u in unlocks}
    pooled = {}
    for out in outs:
        for spec_dir in (p for p in out.iterdir() if p.is_dir() and (p / "spec.txt").exists()):
            levels = json.loads((spec_dir / "spec.txt").read_text(encoding="utf-8"))
            entry = pooled.setdefault(spec_dir.name, {"spent": sum(cost.get(k, 0) * v for k, v in levels.items()), "runs": []})
            entry["runs"] += [json.loads(f.read_text(encoding="utf-8")) for f in spec_dir.glob("*.json")]
    row = "%-16s %-8s %6s %6s %7s %7s %5s %6s %6s"
    print(row % ("spec", "bot", "spent", "surv", "mean", "median", "rep", "money", "raids"))
    for name, entry in sorted(pooled.items()):
        spent, runs = entry["spent"], entry["runs"]
        for strategy in sorted({r["strategy"] for r in runs}):
            rs = [r for r in runs if r["strategy"] == strategy]
            scores = [r["final"].get("score", 0) for r in rs]
            print(row % (name, strategy, spent, "%d/%d" % (sum(r["ending"] == "survived" for r in rs), len(rs)),
                         round(statistics.mean(scores)), round(statistics.median(scores)),
                         round(statistics.mean(r["final"]["rep"] for r in rs)),
                         round(statistics.mean(r["final"]["money"] for r in rs)),
                         "%.2f" % statistics.mean(r["final"]["raids"] for r in rs)))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--runs", type=int, default=10, help="runs per strategy and spec")
    parser.add_argument("--days", type=int, default=16)
    parser.add_argument("--budgets", default="300,full")
    parser.add_argument("--strategies", default="expert,gourmet")
    parser.add_argument("--only", help="comma-separated spec names to run")
    parser.add_argument("--out")
    parser.add_argument("--report", nargs="+", help="print the table for earlier output folders")
    args = parser.parse_args()
    unlocks = load_unlocks()
    if args.report:
        report([Path(d) for d in args.report], unlocks)
        return

    out = Path(args.out) if args.out else HERE / "runs" / ("talents-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
    out.mkdir(parents=True, exist_ok=True)
    all_specs = specs(unlocks, args.budgets.split(","))
    wanted = args.only.split(",") if args.only else list(all_specs)
    for name in wanted:
        spec_dir = out / name
        spec_dir.mkdir(exist_ok=True)
        (spec_dir / "spec.txt").write_text(json.dumps(all_specs[name], indent=1), encoding="utf-8")
        cmd = [sys.executable, str(HERE / "playtest.py"), "run", "--runs", str(args.runs), "--days", str(args.days),
               "--strategies", args.strategies, "--out", str(spec_dir)]
        if all_specs[name]:
            write_cfg(spec_dir / "meta_progress.cfg", all_specs[name])
            cmd += ["--meta", str(spec_dir / "meta_progress.cfg")]
        print(f"{name}: {all_specs[name] or 'no talents'}", flush=True)
        subprocess.run(cmd, stdout=subprocess.DEVNULL, check=True)
    print()
    report([out], unlocks)


if __name__ == "__main__":
    main()
