#!/bin/bash
# Runs the full synthetic stress-scenario suite back to back and prints the
# hotspot report for each result. One build, one DreamDaemon boot per scenario.
# The point is not A/B: each scenario abuses one SSair phase so its cost story
# is readable in isolation (see atmos_bench_scenarios.dm).
#
# Usage: tools/atmos_bench/run_stress_suite.sh [map] [cycles] [skip-build]
#   map        json name from _maps/, default runtimestation (fast boot)
#   cycles     SSair cycles per scenario, default 180
#   skip-build pass "skip-build" to reuse the existing tgstation.dmb
set -u
cd "$(dirname "$0")/../.." || { echo "ERROR: could not cd to project root" >&2; exit 1; }

MAP="${1:-runtimestation}"
CYCLES="${2:-240}"
SKIP_BUILD="${3:-}"
SCENARIOS=(plasma-fire giant-hall giant-hall-eq room-grid pipenet-stress heat-wall multi-breach
           space-wind reaction-zoo he-loop atom-churn changeturf-storm station-breach)

# Burst scenarios fire their one-shot event after the map's own settling noise
# has decayed; the recurring ones keep a short interval so their load never
# settles into sleep for the rest of the run.
event_cycle_for() {
    case "$1" in
        pipenet-stress|he-loop|atom-churn) echo 20 ;;
        reaction-zoo|changeturf-storm) echo 10 ;;
        *) echo 60 ;;
    esac
}

if [ "$SKIP_BUILD" != "skip-build" ]; then
    echo "=== building once with ATMOS_HEADLESS_BENCH ==="
    touch code/modules/admin/verbs/atmos_benchmark.dm
    node tools/build/build.js dm --define=ATMOS_HEADLESS_BENCH || exit 1
fi

RESULTS=()
for SCENARIO in "${SCENARIOS[@]}"; do
    echo ""
    echo "=== scenario: $SCENARIO ==="
    if ! tools/atmos_bench/run_headless.sh "stress-$SCENARIO" "$MAP" skip-build "$CYCLES" "$SCENARIO" "" "" "" "$(event_cycle_for "$SCENARIO")"; then
        echo "WARNING: scenario $SCENARIO failed, continuing" >&2
        continue
    fi
    LATEST=$(ls -t tools/atmos_bench/results/*_stress-"$SCENARIO".jsonl 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        RESULTS+=("$LATEST")
    fi
done

echo ""
echo "=== suite complete: ${#RESULTS[@]}/${#SCENARIOS[@]} scenarios ==="
for RESULT in "${RESULTS[@]}"; do
    echo "  $RESULT"
done
