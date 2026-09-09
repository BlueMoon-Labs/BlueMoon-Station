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
    with open(path, encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                # A run killed on TIMEOUT_SECONDS leaves the world mid-append, so
                # the last line is half-written. Everything before it is still good
                # data and is the only record of what the timed-out run managed to
                # do - dying on a traceback here would make it unreachable.
                rec = None
            # A truncated append can also leave behind a fragment that happens to
            # parse as a bare scalar or list, and .get() on that is an
            # AttributeError - i.e. the same traceback the guard above exists to
            # avoid, taking the whole file's good records with it.
            if not isinstance(rec, dict):
                print(
                    f"WARNING: {path}:{lineno}: skipping malformed line "
                    f"(truncated run?)", file=sys.stderr
                )
                continue
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


# The nb_* slots run inside the neighbour loop while "neighbors" is still open,
# so they may not be added to the parts total - their time is already counted
# once by the enclosing stopwatch. "space" is NOT one of them: its stopwatch
# starts after "neighbors" has been closed, so it is a standalone slot.
# Keep in sync with ATMOS_TPROF_NESTED_SLOTS in code/__DEFINES/atmospherics.dm.
NESTED_SLOTS = {"nb_compare", "nb_share", "nb_archive", "nb_sky_compare"}


def turf_profile_stats(records):
    """Pool every armed tprof cycle into one budget.

    The driver arms the profiler once every ATMOS_HEADLESS_BENCH_SNAPSHOT_EVERY
    cycles, so a 240-cycle run carries ~16 independent samples spanning the whole
    curve - the post-event peak included. Reading only the last one (which is what
    this did until 2026-08-14) reports the quiet tail of the run and calls it the
    profile: on station-breach that is ~250 turfs against a peak of ~2000, i.e.
    the regime nobody is trying to optimise.

    Pooling also fixes the unit. A single cycle's slot in milliseconds says
    nothing across runs whose turf counts differ; microseconds per processed turf
    is comparable, and it is the number that multiplies out to the phase cost.
    """
    if not records:
        return None
    slots = {}
    counts = {}
    turfs = 0
    phase_ms = 0.0
    parts_ms = 0.0
    for rec in records:
        for name, value in (rec.get("slots") or {}).items():
            slots[name] = slots.get(name, 0.0) + value
        for name, value in (rec.get("counts") or {}).items():
            counts[name] = counts.get(name, 0) + value
        turfs += (rec.get("counts") or {}).get("turfs", 0)
        phase_ms += rec.get("phase_ms") or 0
        parts_ms += rec.get("parts_ms") or 0
    return {
        "samples": len(records),
        "slots": slots,
        "counts": counts,
        "turfs": turfs,
        "phase_ms": phase_ms,
        "parts_ms": parts_ms,
        "us_per_turf": (phase_ms * 1000 / turfs) if turfs else 0,
    }


def split_tprofs(tprofs):
    """Loaded samples vs settled ones, split at the median active-turf count.

    Cost per turf is not constant along the curve - production rounds measured
    57 -> 104 us as the same station degraded - so one pooled number hides the
    half that matters. The split keeps both visible without inventing a
    threshold: the run's own median is whatever regime that run spent its time in.
    """
    usable = [rec for rec in tprofs if (rec.get("counts") or {}).get("turfs")]
    if len(usable) < 4:
        return None, None
    ordered = sorted(usable, key=lambda rec: rec.get("at", 0))
    middle = len(ordered) // 2
    return ordered[middle:], ordered[:middle]


def print_turf_budget(label, stats):
    if not stats or not stats["turfs"]:
        return
    parts_ms = stats["parts_ms"]
    turfs = stats["turfs"]
    attributed = (parts_ms / stats["phase_ms"] * 100) if stats["phase_ms"] else 0
    print(
        f"  {label}: {stats['samples']} armed cycles, {turfs} turfs, "
        f"{stats['us_per_turf']:.1f}us/turf, {attributed:.0f}% attributed"
    )
    ranked = sorted(
        (
            (name, ms)
            for name, ms in stats["slots"].items()
            if name not in NESTED_SLOTS and not name.startswith("hs_")
        ),
        key=lambda item: -item[1],
    )
    for name, ms in ranked:
        share = (ms / parts_ms * 100) if parts_ms else 0
        per_turf = ms * 1000 / turfs
        print(f"    {name:<14}{share:>6.0f}%{per_turf:>9.2f}us/turf")
    nested_present = [
        (name, ms) for name, ms in stats["slots"].items() if name in NESTED_SLOTS
    ]
    if nested_present:
        inner = " ".join(
            f"{name}={ms * 1000 / turfs:.2f}us"
            for name, ms in sorted(nested_present, key=lambda item: -item[1])
        )
        print(f"    (nested, already inside the slot above) {inner}")


def hotspot_profile_report(tprofs):
    """Where the hotspot phase spends its time - the fire regime's second bill.

    The hs_* slots share the tprof dictionary with the turf ones but belong to a
    different phase, so they carry their own budget (hs_parts_ms against
    hs_phase_ms) and are normalised per hotspot, not per turf.
    """
    hotspots = 0
    phase_ms = 0.0
    parts_ms = 0.0
    slots = {}
    for rec in tprofs:
        hotspots += rec.get("hs") or 0
        phase_ms += rec.get("hs_phase_ms") or 0
        parts_ms += rec.get("hs_parts_ms") or 0
        for name, value in (rec.get("slots") or {}).items():
            if name.startswith("hs_"):
                slots[name] = slots.get(name, 0.0) + value
    if not hotspots or not slots:
        return
    attributed = (parts_ms / phase_ms * 100) if phase_ms else 0
    print(
        f"hotspot phase breakdown: {hotspots} hotspot-cycles, "
        f"{phase_ms * 1000 / hotspots:.1f}us/hotspot, {attributed:.0f}% attributed"
    )
    for name, ms in sorted(slots.items(), key=lambda item: -item[1]):
        share = (ms / parts_ms * 100) if parts_ms else 0
        print(f"    {name:<14}{share:>6.0f}%{ms * 1000 / hotspots:>9.2f}us/hotspot")


def turf_profile_report(tprofs):
    """Where the turf phase actually spends its time (see ATMOS_TPROF_* macros)."""
    if not tprofs:
        return
    pooled = turf_profile_stats(tprofs)
    if not pooled or not pooled["turfs"]:
        return
    print("turf phase breakdown (all armed cycles pooled):")
    print_turf_budget("whole run", pooled)
    loaded, settled = split_tprofs(tprofs)
    if loaded and settled:
        print_turf_budget("loaded half", turf_profile_stats(loaded))
        print_turf_budget("settled half", turf_profile_stats(settled))
    counts = pooled["counts"]
    if counts:
        interesting = sorted(counts.items(), key=lambda item: -item[1])
        print("  counts: " + " ".join(f"{name}={value}" for name, value in interesting))
    series = " ".join(
        f"{rec.get('cyc')}:{rec.get('at', 0)}t/"
        f"{((rec.get('phase_ms') or 0) * 1000 / ((rec.get('counts') or {}).get('turfs') or 1)):.0f}us"
        for rec in tprofs
        if (rec.get("counts") or {}).get("turfs")
    )
    if series:
        print(f"  per-sample (cycle:turfs/cost): {series}")


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
        hotspot_profile_report(records["tprof"])
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
        # Gas-list census. This is the evidence for "a third key costs the two-gas
        # fast path in react()/share()/update_visuals()": keys is the histogram of
        # gas-list length per active turf, prunable2 counts turfs that hold exactly
        # two SIGNIFICANT gases (O2+N2) but miss the fast path because of trace keys
        # on top, and orphan names which gases those traces actually are.
        keys = s.get("keys") or {}
        if keys:
            ordered = sorted(keys.items(), key=lambda kv: (len(kv[0]), kv[0]))
            print("  gas keys/turf:", " ".join(f"{k}={v}" for k, v in ordered))
            prunable = s.get("prunable2", 0)
            if prunable:
                over_two = sum(v for k, v in keys.items() if k not in ("0", "1", "2"))
                share = f" ({prunable / over_two * 100:.0f}% of 3+)" if over_two else ""
                print(f"  two significant gases behind trace keys: {prunable}{share}")
            bands = s.get("bands") or {}
            if bands:
                print("  trace bands:", dict(sorted(bands.items())))
            orphan = s.get("orphan") or {}
            if orphan:
                top = sorted(orphan.items(), key=lambda kv: -kv[1])[:6]
                print("  top non-air gases:", dict(top))
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
    check_comparable(baseline_paths, candidate_paths)
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
        percent_text = "    n/a" if percent == float("inf") else f"{percent:>7.1f}"
        print(
            f"  {name:<28}{base_value:>11.2f}{cand_value:>11.2f}"
            f"{delta:>11.2f}{percent_text}   {verdict}"
        )
    compare_turf_profile(baseline_paths, candidate_paths, warmup)
    return 0


def pooled_turf_profile(paths, warmup):
    """One turf budget for a whole side of an A/B.

    Warmup-filtered like every other comparison: boot samples carry both the
    highest turf counts and the highest us/turf, so pooling them weights the
    settling transient heaviest in exactly the ratio this table reports. Two
    runs differing only in how long the map took to settle would otherwise show
    a us/turf delta here that the (correctly filtered) header table calls noise.
    """
    tprofs = []
    for path in paths:
        tprofs.extend(stable(load(path)["tprof"], warmup))
    return turf_profile_stats(tprofs)


def turf_profile_noise(paths, warmup):
    """Per-slot scatter between repeats of the SAME build, in us per turf.

    Without this the budget table reads as authoritative while being nothing of
    the sort. The tell is a delta that lands on every slot at once, including the
    ones the change cannot possibly touch: a swap inside total_moles() has no
    route to superconduct or expose, so when all of them move together by the
    same fifth, what got measured was the machine, not the patch.
    """
    per_run = []
    for path in paths:
        stats = turf_profile_stats(stable(load(path)["tprof"], warmup))
        if not stats or not stats["turfs"]:
            continue
        per_run.append({
            name: ms * 1000 / stats["turfs"]
            for name, ms in stats["slots"].items()
        })
    if len(per_run) < 2:
        return {}
    spread = {}
    for name in set().union(*per_run):
        values = [run.get(name, 0.0) for run in per_run]
        spread[name] = max(values) - min(values)
    return spread


def compare_turf_profile(baseline_paths, candidate_paths, warmup):
    """Which part of process_cell moved, not just whether the phase did.

    The phase column answers "did it get faster"; this answers "where", which is
    what decides whether the change did what it claimed or bought its win
    somewhere unintended (a slot that got cheaper because turfs stopped being
    processed at all shows up here as a count, not a time).
    """
    base = pooled_turf_profile(baseline_paths, warmup)
    cand = pooled_turf_profile(candidate_paths, warmup)
    if not base or not cand or not base["turfs"] or not cand["turfs"]:
        return
    base_noise = turf_profile_noise(baseline_paths, warmup)
    cand_noise = turf_profile_noise(candidate_paths, warmup)
    print()
    print("  turf phase budget, us per processed turf")
    print(f"  {'slot':<20}{'baseline':>11}{'candidate':>11}{'delta':>11}{'%':>8}   verdict")
    # hs_* принадлежат фазе ХОТСПОТОВ и живут в общем словаре слотов только ради
    # одной записи на цикл. В бюджете фазы турфов им не место: они завышали бы
    # TOTAL PHASE стороны, где инструментовка вообще есть, - а в A/B двух сборок
    # это ровно та сторона, которую и проверяют. Своя таблица ниже.
    names = sorted(
        name for name in (set(base["slots"]) | set(cand["slots"]))
        if not name.startswith("hs_")
    )
    rows = []
    for name in names:
        base_us = base["slots"].get(name, 0.0) * 1000 / base["turfs"]
        cand_us = cand["slots"].get(name, 0.0) * 1000 / cand["turfs"]
        delta = cand_us - base_us
        percent = (delta / base_us * 100) if base_us else float("inf")
        spreads = [s for s in (base_noise.get(name), cand_noise.get(name)) if s is not None]
        noise = max(spreads) if spreads else None
        if noise is None:
            verdict = "-"
        elif abs(delta) <= noise:
            verdict = f"noise (+-{noise:.2f})"
        else:
            verdict = "BETTER" if delta < 0 else "WORSE"
        rows.append((abs(delta), name, base_us, cand_us, delta, percent, verdict))
    rows.sort(reverse=True)
    for _, name, base_us, cand_us, delta, percent, verdict in rows:
        marker = " (nested)" if name in NESTED_SLOTS else ""
        percent_text = "    n/a" if percent == float("inf") else f"{percent:>7.1f}"
        print(
            f"  {name:<20}{base_us:>11.2f}{cand_us:>11.2f}"
            f"{delta:>11.2f}{percent_text}   {verdict}{marker}"
        )
    # A change that lands on every slot at once, untouched ones included, is the
    # machine drifting between the two batches - not the patch. Say so, because
    # the per-slot percentages look identical either way.
    real_slots = [row for row in rows if row[1] not in NESTED_SLOTS and row[2] > 0.05]
    if len(real_slots) >= 4:
        signs = {row[4] > 0 for row in real_slots}
        percents = sorted(abs(row[5]) for row in real_slots if row[5] != float("inf"))
        if len(signs) == 1 and percents and percents[0] > 5:
            direction = "slower" if real_slots[0][4] > 0 else "faster"
            print(
                f"  !! every slot moved the same way ({direction}, "
                f"{percents[0]:.0f}-{percents[-1]:.0f}%), including ones the change\n"
                f"     cannot reach. That is batch drift. Re-run the two sides "
                f"INTERLEAVED (A,B,A,B), not in blocks."
            )
    # The guard above only covers turfs; us_per_turf is phase_ms-derived and a
    # side whose tprof carries turf counts but no phase_ms (an older result file,
    # or a renamed field) makes this zero. Dying here would throw away the whole
    # per-slot table that was just printed.
    total_delta = cand["us_per_turf"] - base["us_per_turf"]
    total_percent = (
        f"{(total_delta / base['us_per_turf'] * 100):>7.1f}"
        if base["us_per_turf"] else "    n/a"
    )
    print(
        f"  {'TOTAL PHASE':<20}{base['us_per_turf']:>11.2f}{cand['us_per_turf']:>11.2f}"
        f"{total_delta:>11.2f}{total_percent}"
    )
    # Counts that changed by more than a few percent mean the two builds did not
    # simulate the same thing, which invalidates a timing comparison outright.
    shifted = []
    for name in sorted(set(base["counts"]) | set(cand["counts"])):
        if name.startswith("hs_"):
            continue  # счётчики фазы хотспотов, своя таблица ниже
        base_per = base["counts"].get(name, 0) / base["turfs"]
        cand_per = cand["counts"].get(name, 0) / cand["turfs"]
        if base_per < 0.01 and cand_per < 0.01:
            continue
        if not base_per:
            # Work that did not exist on the base side at all. Relative change is
            # undefined, and skipping the counter reported "nothing shifted" for
            # the single most interesting case: the candidate invented new work.
            shifted.append(f"{name} NEW ->{cand_per:.3f}/turf")
        elif not cand_per:
            shifted.append(f"{name} {base_per:.3f}->GONE")
        elif abs(cand_per - base_per) / base_per > 0.05:
            shifted.append(f"{name} {base_per:.3f}->{cand_per:.3f}/turf")
    if shifted:
        print("  work-per-turf shifted: " + ", ".join(shifted))


def run_shape(path):
    """The knobs that have to match for two runs to be comparable at all."""
    records = load(path)
    summary = records["summary"] or {}
    ready = next(
        (e for e in records["event"] if e.get("event") == "scenario_ready"), {}
    )
    return (
        summary.get("scenario") or ready.get("scenario"),
        summary.get("map"),
        summary.get("cycles"),
        summary.get("seed"),
        ready.get("equalize"),
        ready.get("heat"),
    )


def check_comparable(baseline_paths, candidate_paths):
    """Refuse to let a mismatched pair be read as an A/B result.

    A candidate accidentally launched without the scenario argument runs a
    completely different world and still produces a full, plausible-looking
    result file. That happened on 2026-08-13 (cand-1, scenario=None against a
    station-breach baseline) and the numbers went into a comparison table
    unflagged.
    """
    shapes = {}
    for path in baseline_paths + candidate_paths:
        shapes[path] = run_shape(path)
    fields = ("scenario", "map", "cycles", "seed", "equalize", "heat")
    problems = []
    for index, field in enumerate(fields):
        values = {shape[index] for shape in shapes.values()}
        if len(values) > 1:
            rendered = ", ".join(
                f"{Path(p).stem}={shapes[p][index]!r}" for p in shapes
            )
            problems.append(f"{field} differs: {rendered}")
    if problems:
        print("  !! RUNS ARE NOT COMPARABLE")
        for problem in problems:
            print(f"     {problem}")
        print("     Any delta below is confounded by the mismatch above.")
        print()


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
        percent_text = "       n/a" if percent == float("inf") else f"{percent:>10.1f}"
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
