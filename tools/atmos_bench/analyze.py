#!/usr/bin/env python3
"""Summarize and compare atmos_headless_bench JSONL files (see run_headless.sh).

Usage:
  analyze.py <file.jsonl> [more files...]
      Per-file summary. With several files the active-turf curves are printed
      side by side.

  analyze.py --baseline <run...> --candidate <run...> [--warmup N]
      A/B verdict: per-phase deltas over the stable window. Pass several runs
      per side (see run_repeat.sh) and the within-side spread becomes the noise
      floor, so the verdict distinguishes a real change from run-to-run scatter.

  analyze.py --variance <run...> [--warmup N]
      Spread across repeats of one build. Run this once per scenario to learn
      how big a delta has to be before it means anything.

The first cycles of every run are the map settling after boot, not the steady
state under test, so all comparison modes drop them (--warmup, default 30).
"""
import argparse
import json
import math
import sys
from pathlib import Path


def load(path):
    if not Path(path).is_file():
        # These paths get typed by hand against a directory of timestamped runs;
        # a stack trace is a poor way to say "you mistyped the timestamp".
        print(f"ERROR: no such result file: {path}", file=sys.stderr)
        sys.exit(2)
    records = {
        "hb": [], "snapshot": [], "event": [], "breakdown": [],
        "mprof": [], "tprof": [], "summary": None, "features": None,
    }
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line:
            continue
        rec = json.loads(line)
        kind = rec.get("rec")
        if kind in ("summary", "features"):
            records[kind] = rec
        elif kind in records:
            records[kind].append(rec)
    return records


PHASES = {
    "c_at": "active turfs",
    "c_eg": "excited groups",
    "c_eq": "equalize",
    "c_hp": "high pressure",
    "c_hs": "hotspots",
    "c_sc": "superconduction",
    "c_pn": "pipenets",
    "c_am": "machinery",
    "c_ao": "atmos atoms",
    "c_dc": "decompression",
    "c_pp": "post process",
}

# Everything an A/B run should look at, not just the timing columns: a change
# that halves a phase by leaving work undone shows up in the counts, not the ms.
COMPARE_METRICS = {
    "cost": "SSair total ms",
    "c_at": "active turfs ms",
    "c_at_raw": "active turfs ms (unsmoothed)",
    "c_eg": "excited groups ms",
    "c_eq": "equalize ms",
    "c_hp": "high pressure ms",
    "c_hs": "hotspots ms",
    "c_sc": "superconduction ms",
    "c_pn": "pipenets ms",
    "c_am": "machinery ms",
    "c_ao": "atmos atoms ms",
    "c_dc": "decompression ms",
    "c_pp": "post process ms",
    "at": "active turfs",
    "eg": "excited groups",
    "hs": "hotspots",
    "am": "awake machines",
    "ami": "idle machines",
    "ao": "atmos-sensitive atoms",
    "hbw": "heartbeat wakes",
    "mc": "MC slices per fire",
}

# Metrics where a rise is the improvement. Everything else is a cost or a
# backlog, so lower wins; without this list a change that puts machines to
# sleep gets reported as a regression on the very metric that proves it worked.
HIGHER_IS_BETTER = {"ami"}


def percentile(values, fraction):
    if not values:
        return 0
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    weight = position - lower
    return ordered[lower] * (1 - weight) + ordered[upper] * weight


def stable(hb, warmup):
    """Heartbeats past the boot transient - the part that describes steady state."""
    return [rec for rec in hb if rec.get("cyc", 0) > warmup]


def metric_values(hb, key):
    return [rec.get(key) or 0 for rec in hb]


def stress_report(hb, events, mprofs):
    """Hotspot-hunting view: which SSair phase is expensive, when, and why."""
    if not hb:
        return
    print("phase costs (MC_AVERAGE-smoothed ms per fire):")
    rows = []
    for key, name in PHASES.items():
        values = metric_values(hb, key)
        if not any(values):
            continue
        worst = max(hb, key=lambda rec: rec.get(key) or 0)
        rows.append((
            max(values), percentile(values, 0.95),
            sum(values) / len(values), name, worst.get("cyc"),
        ))
    rows.sort(reverse=True)
    print(f"  {'phase':<18}{'avg':>8}{'p95':>8}{'max':>8}  worst@cycle")
    for peak, p95, avg, name, cyc in rows:
        print(f"  {name:<18}{avg:>8.2f}{p95:>8.2f}{peak:>8.2f}  {cyc}")

    totals = metric_values(hb, "cost")
    median = percentile(totals, 0.5)
    spike_floor = max(1.0, median * 3)
    spikes = [rec for rec in hb if (rec.get("cost") or 0) > spike_floor]
    if spikes:
        spikes.sort(key=lambda rec: -(rec.get("cost") or 0))
        print(f"spikes (> {spike_floor:.2f}ms, median {median:.2f}ms): {len(spikes)} cycles")
        for rec in spikes[:5]:
            dominant = max(PHASES, key=lambda key: rec.get(key) or 0)
            print(
                f"  cyc={rec.get('cyc')} cost={rec.get('cost'):.2f}ms "
                f"dominant={PHASES[dominant]}={rec.get(dominant) or 0:.2f}ms "
                f"at={rec.get('at')} eg={rec.get('eg')} hs={rec.get('hs')}"
            )
    if events:
        timeline = ", ".join(
            f"{event.get('event')}@{event.get('cyc', 0)}" for event in events
        )
        print(f"events: {timeline}")
    if mprofs:
        latest = mprofs[-1]
        types = latest.get("types") or {}
        expensive = sorted(types.items(), key=lambda item: -item[1].get("ms", 0))[:8]
        print(
            f"machinery profile (last, {latest.get('n')} machines, "
            f"{latest.get('ms')}ms total, {latest.get('np')} unpowered):"
        )
        for type_path, bucket in expensive:
            count = bucket.get("n", 0)
            total_ms = bucket.get("ms", 0)
            each = total_ms / count if count else 0
            print(f"  {type_path}: n={count} {total_ms:.2f}ms ({each:.3f}ms each)")


def turf_profile_report(tprofs):
    """Where the turf phase actually spends its time (see ATMOS_TPROF_* macros)."""
    if not tprofs:
        return
    latest = tprofs[-1]
    slots = latest.get("slots") or {}
    counts = latest.get("counts") or {}
    phase_ms = latest.get("phase_ms") or 0
    parts_ms = latest.get("parts_ms") or 0
    turfs = counts.get("turfs", 0)
    attributed = (parts_ms / phase_ms * 100) if phase_ms else 0
    print(
        f"turf phase breakdown (cyc={latest.get('cyc')}, {turfs} turfs, "
        f"phase={phase_ms:.2f}ms, parts={parts_ms:.2f}ms, {attributed:.0f}% attributed):"
    )
    # "space" is nested inside "neighbors", so it is shown but not ranked with
    # the top-level slots - otherwise its time would be counted twice.
    nested = {"space"}
    ranked = sorted(
        ((name, ms) for name, ms in slots.items() if name not in nested),
        key=lambda item: -item[1],
    )
    for name, ms in ranked:
        share = (ms / parts_ms * 100) if parts_ms else 0
        per_1k = (ms / turfs * 1000) if turfs else 0
        extra = ""
        if name == "neighbors" and "space" in slots:
            extra = f"  (space branch {slots['space']:.2f}ms)"
        print(f"  {name:<14}{ms:>8.2f}ms{share:>7.0f}%{per_1k:>9.3f}ms/1k turfs{extra}")
    if counts:
        interesting = sorted(counts.items(), key=lambda item: -item[1])
        print("  counts: " + " ".join(f"{name}={value}" for name, value in interesting))


def metric_line(label, values, suffix="ms"):
    if not values:
        return
    print(
        f"{label}: max={max(values):.2f}{suffix} "
        f"p95={percentile(values, 0.95):.2f}{suffix} "
        f"p99={percentile(values, 0.99):.2f}{suffix}"
    )


def active_auc(hb, key="at"):
    if len(hb) < 2:
        return 0
    return sum(
        (left.get(key, 0) + right.get(key, 0)) * 0.5 *
        max(0, right.get("t", 0) - left.get("t", 0)) * 0.1
        for left, right in zip(hb, hb[1:])
    )


def tail_cycle(hb, breach_cycle, threshold, key="at"):
    if breach_cycle is None:
        return None
    post_breach = [rec for rec in hb if rec.get("cyc", 0) >= breach_cycle]
    if not post_breach:
        return None
    peak_index = max(range(len(post_breach)), key=lambda index: post_breach[index].get(key, 0))
    if post_breach[peak_index].get(key, 0) < threshold:
        return 0
    for rec in post_breach[peak_index:]:
        if rec.get(key, 0) < threshold:
            return rec["cyc"] - breach_cycle
    return None


def curve(hb, points=16):
    if not hb:
        return {}
    step = max(1, len(hb) // points)
    sampled = hb[::step]
    if sampled[-1] is not hb[-1]:
        sampled.append(hb[-1])
    return {r["cyc"]: r["at"] for r in sampled}


def describe(path):
    records = load(path)
    hb = records["hb"]
    events = records["event"]
    summary = records["summary"]
    features = records["features"]
    print(f"\n### {path}")
    if summary:
        print(
            f"summary: cycles={summary['cycles']} final_active={summary['at']} "
            f"groups={summary['eg']} map={summary.get('map')} "
            f"scenario={summary.get('scenario')} breaches={summary.get('breaches')} "
            f"firelocks={summary.get('firelocks')} seed={summary.get('seed')}"
        )
    if hb:
        breach = next((event for event in events if event.get("event") == "breach"), None)
        breach_cycle = breach.get("cyc") if breach else None
        print(
            f"active: peak={max(r.get('at', 0) for r in hb)} "
            f"AUC={active_auc(hb):.0f} turf-seconds "
            f"tail<100={tail_cycle(hb, breach_cycle, 100)} cycles "
            f"tail<50={tail_cycle(hb, breach_cycle, 50)} cycles"
        )
        if any(r.get("scenario_at") is not None for r in hb):
            print(
                f"scenario active: peak={max(r.get('scenario_at', 0) for r in hb)} "
                f"AUC={active_auc(hb, 'scenario_at'):.0f} turf-seconds "
                f"tail<100={tail_cycle(hb, breach_cycle, 100, 'scenario_at')} cycles "
                f"tail<50={tail_cycle(hb, breach_cycle, 50, 'scenario_at')} cycles"
            )
        metric_line("SSair total", metric_values(hb, "cost"))
        stress_report(hb, events, records["mprof"])
        turf_profile_report(records["tprof"])
        print(
            f"runtime: largest_group={max(r.get('largest_eg', 0) for r in hb)} "
            f"scenario_largest_group={max(r.get('scenario_largest_eg', 0) or 0 for r in hb)} "
            f"max_mc_slices={max(r.get('mc', 0) for r in hb)} "
            f"max_td={max(r.get('td_c', 0) for r in hb):.2f}% "
            f"decomp_events={sum(r.get('da', 0) for r in hb)}"
        )
        last = hb[-1]
        print(
            f"safety: doors={last.get('doors_closed', 0)}/{last.get('doors_total', 0)} "
            f"alarmed_areas={last.get('alarms', 0)}"
        )
    if records["breakdown"]:
        breakdowns = records["breakdown"]
        completed = [rec for rec in breakdowns if rec.get("completed")]
        cancelled = len(breakdowns) - len(completed)
        durations = [rec.get("duration_ds", 0) * 100 for rec in completed]
        metric_line("breakdown elapsed", durations)
        print(
            f"breakdowns: completed={len(completed)} cancelled={cancelled} "
            f"max_members={max((r.get('members', 0) for r in breakdowns), default=0)} "
            f"max_slices={max((r.get('slices', 0) for r in breakdowns), default=0)}"
        )
    if records["snapshot"]:
        s = records["snapshot"][-1]
        pc = s.get("planet_compare") or {}
        equal = pc.get("equal", 0)
        off = sum(v for k, v in pc.items() if k != "equal")
        print(f"last snapshot: cyc={s['cyc']} active={s['at']} planet_equal={equal} planet_off={off} temp_max={s['temp_max']:.0f}")
        groups = sorted(s.get("groups") or [], key=lambda g: -g["size"])[:5]
        for g in groups:
            print(f"  group size={g['size']} awake={g['awake']} dm_cd={g['dm_cd']} {g['area']}")
        print("  top areas:", dict(list((s.get("top_areas") or {}).items())[:6]))
    if features:
        checks = features.get("checks") or {}
        failed = [name for name, passed in checks.items() if not passed]
        print(
            f"feature probe: iterations={features.get('iterations')} "
            f"checks={len(checks) - len(failed)}/{len(checks)} "
            f"failed={failed or 'none'}"
        )
        for name, value in (features.get("costs") or {}).items():
            print(f"  {name}={value:.3f}ms total")
    return curve(hb)


def side_stats(paths, warmup):
    """Median and p95 per metric for one side of an A/B, plus per-run medians.

    Keeping the individual run medians is what makes the noise floor possible:
    the spread between repeats of the SAME build is the smallest delta any
    verdict is allowed to call real.
    """
    per_run = []
    # Fields the benchmark itself gained over time (c_at_raw, hpd) are simply
    # absent from older runs. Recording presence separately keeps a schema
    # change from being read as a dramatic improvement.
    present = set()
    for path in paths:
        hb = stable(load(path)["hb"], warmup)
        if not hb:
            print(f"WARNING: {path} has no cycles past warmup {warmup}", file=sys.stderr)
            continue
        for rec in hb:
            present.update(key for key in COMPARE_METRICS if key in rec)
        per_run.append({
            key: (percentile(metric_values(hb, key), 0.5), percentile(metric_values(hb, key), 0.95))
            for key in COMPARE_METRICS
        })
    if not per_run:
        return None
    combined = {}
    for key in COMPARE_METRICS:
        medians = [run[key][0] for run in per_run]
        p95s = [run[key][1] for run in per_run]
        spread = (max(medians) - min(medians)) if len(medians) > 1 else None
        combined[key] = {
            "median": percentile(medians, 0.5),
            "p95": percentile(p95s, 0.5),
            "spread": spread,
            "present": key in present,
        }
    return combined


def compare(baseline_paths, candidate_paths, warmup):
    base = side_stats(baseline_paths, warmup)
    cand = side_stats(candidate_paths, warmup)
    if not base or not cand:
        print("ERROR: not enough usable data to compare", file=sys.stderr)
        return 1
    print(f"### A/B (cycles > {warmup})")
    print(f"  baseline : {', '.join(Path(p).stem for p in baseline_paths)}")
    print(f"  candidate: {', '.join(Path(p).stem for p in candidate_paths)}")
    # A noise floor needs repeats on at least one side; the verdict then uses the
    # widest scatter available. Repeats on both sides is stronger, so say which
    # of the three situations this actually is rather than implying a clean A/B.
    if len(baseline_paths) < 2 and len(candidate_paths) < 2:
        print(
            "  NOTE: one run per side, so there is no measured noise floor and the\n"
            "        verdict column stays empty. Use run_repeat.sh to get one."
        )
    elif len(baseline_paths) < 2 or len(candidate_paths) < 2:
        thin = "baseline" if len(baseline_paths) < 2 else "candidate"
        print(
            f"  NOTE: the {thin} side is a single run, so the noise floor comes from\n"
            f"        the other side alone. Treat verdicts near the floor as weak."
        )
    print()
    header = f"  {'metric':<28}{'baseline':>11}{'candidate':>11}{'delta':>11}{'%':>8}   verdict"
    print(header)
    rows = []
    for key, name in COMPARE_METRICS.items():
        base_value = base[key]["median"]
        cand_value = cand[key]["median"]
        if not base_value and not cand_value:
            continue
        if base[key]["present"] != cand[key]["present"]:
            missing = "baseline" if not base[key]["present"] else "candidate"
            rows.append((0, key, name, base_value, cand_value, 0, 0,
                         f"field absent in {missing}"))
            continue
        delta = cand_value - base_value
        percent = (delta / base_value * 100) if base_value else float("inf")
        # Noise floor: the worst within-build scatter seen on either side. A
        # delta smaller than that is indistinguishable from re-running the same
        # code, no matter how confident the percentage looks.
        spreads = [s for s in (base[key]["spread"], cand[key]["spread"]) if s is not None]
        noise = max(spreads) if spreads else None
        improved = delta > 0 if key in HIGHER_IS_BETTER else delta < 0
        if noise is None:
            verdict = "-"
        elif abs(delta) <= max(noise, 1e-9):
            verdict = f"noise (+-{noise:.2f})"
        else:
            verdict = "BETTER" if improved else "WORSE"
        rows.append((abs(percent) if percent != float("inf") else 0, key, name,
                     base_value, cand_value, delta, percent, verdict))
    rows.sort(reverse=True)
    for _, _, name, base_value, cand_value, delta, percent, verdict in rows:
        percent_text = "  n/a" if percent == float("inf") else f"{percent:>7.1f}"
        print(
            f"  {name:<28}{base_value:>11.2f}{cand_value:>11.2f}"
            f"{delta:>11.2f}{percent_text}   {verdict}"
        )
    return 0


def variance(paths, warmup):
    """Run-to-run scatter of one build: the calibration for every later verdict."""
    stats = side_stats(paths, warmup)
    if not stats:
        print("ERROR: no usable runs", file=sys.stderr)
        return 1
    print(f"### variance across {len(paths)} runs (cycles > {warmup})")
    for path in paths:
        print(f"  {Path(path).stem}")
    print()
    print(f"  {'metric':<28}{'median':>11}{'spread':>11}{'spread %':>11}")
    rows = []
    for key, name in COMPARE_METRICS.items():
        median = stats[key]["median"]
        spread = stats[key]["spread"]
        if spread is None or (not median and not spread):
            continue
        percent = (spread / median * 100) if median else float("inf")
        rows.append((percent if percent != float("inf") else 0, name, median, spread, percent))
    rows.sort(reverse=True)
    for _, name, median, spread, percent in rows:
        percent_text = "  n/a" if percent == float("inf") else f"{percent:>10.1f}"
        print(f"  {name:<28}{median:>11.2f}{spread:>11.2f}{percent_text}")
    print(
        "\n  Read this as the minimum delta worth believing: anything an A/B\n"
        "  reports below the spread for that metric is scatter, not a change."
    )
    return 0


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("files", nargs="*", help="JSONL results to summarize")
    parser.add_argument("--baseline", nargs="+", metavar="RUN", help="A/B: reference runs")
    parser.add_argument("--candidate", nargs="+", metavar="RUN", help="A/B: runs under test")
    parser.add_argument("--variance", nargs="+", metavar="RUN", help="spread across repeats of one build")
    parser.add_argument(
        "--warmup", type=int, default=30, metavar="N",
        help="cycles of boot settling to drop before comparing (default 30)",
    )
    args = parser.parse_args()

    if args.variance:
        return variance(args.variance, args.warmup)
    if args.baseline or args.candidate:
        if not (args.baseline and args.candidate):
            parser.error("--baseline and --candidate must be given together")
        return compare(args.baseline, args.candidate, args.warmup)
    if not args.files:
        parser.print_help()
        return 1

    curves = {path: describe(path) for path in args.files}
    if len(curves) > 1:
        print("\n### active turfs by cycle")
        all_cycles = sorted({c for cv in curves.values() for c in cv})
        names = list(curves)
        labels = {name: Path(name).stem for name in names}
        width = max(14, max(len(label) for label in labels.values()) + 2)
        print("cycle".ljust(8) + "".join(labels[name].ljust(width) for name in names))
        for cyc in all_cycles:
            row = str(cyc).ljust(8)
            for name in names:
                row += str(curves[name].get(cyc, "")).ljust(width)
            print(row)
    else:
        only = next(iter(curves.values()))
        print("\ncycle -> active:", only)
    return 0


if __name__ == "__main__":
    sys.exit(main())
