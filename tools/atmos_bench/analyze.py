#!/usr/bin/env python3
"""Summarize atmos_headless_bench JSONL files (see run_headless.sh).

Usage: analyze.py <file.jsonl> [more files...]
With several files the active-turf curves are printed side by side for A/B runs.
"""
import json
import sys


def load(path):
    hb, snaps, summary = [], [], None
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line:
            continue
        rec = json.loads(line)
        kind = rec.get("rec")
        if kind == "hb":
            hb.append(rec)
        elif kind == "snapshot":
            snaps.append(rec)
        elif kind == "summary":
            summary = rec
    return hb, snaps, summary


def curve(hb, points=16):
    if not hb:
        return {}
    step = max(1, len(hb) // points)
    sampled = hb[::step]
    if sampled[-1] is not hb[-1]:
        sampled.append(hb[-1])
    return {r["cyc"]: r["at"] for r in sampled}


def describe(path):
    hb, snaps, summary = load(path)
    print(f"\n### {path}")
    if summary:
        print(f"summary: cycles={summary['cycles']} final_active={summary['at']} groups={summary['eg']} map={summary.get('map')}")
    if hb:
        costs = [r.get("c_at", 0) for r in hb[len(hb) // 2:]]
        print(f"cost_turfs second half: avg={sum(costs) / max(1, len(costs)):.1f}ms max={max(costs):.1f}ms")
    if snaps:
        s = snaps[-1]
        pc = s.get("planet_compare") or {}
        equal = pc.get("equal", 0)
        off = sum(v for k, v in pc.items() if k != "equal")
        print(f"last snapshot: cyc={s['cyc']} active={s['at']} planet_equal={equal} planet_off={off} temp_max={s['temp_max']:.0f}")
        groups = sorted(s.get("groups") or [], key=lambda g: -g["size"])[:5]
        for g in groups:
            print(f"  group size={g['size']} awake={g['awake']} dm_cd={g['dm_cd']} {g['area']}")
        print("  top areas:", dict(list((s.get("top_areas") or {}).items())[:6]))
    return curve(hb)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    curves = {}
    for path in sys.argv[1:]:
        curves[path] = describe(path)
    if len(curves) > 1:
        print("\n### active turfs by cycle")
        all_cycles = sorted({c for cv in curves.values() for c in cv})
        names = list(curves)
        header = "cycle".ljust(8) + "".join(n.split("_")[-1].replace(".jsonl", "").ljust(14) for n in names)
        print(header)
        for cyc in all_cycles:
            row = str(cyc).ljust(8)
            for n in names:
                row += str(curves[n].get(cyc, "")).ljust(14)
            print(row)
    else:
        only = next(iter(curves.values()))
        print("\ncycle -> active:", only)


if __name__ == "__main__":
    main()
