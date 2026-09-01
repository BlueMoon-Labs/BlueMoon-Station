#!/bin/bash
# Runs the same build N times and reports the run-to-run scatter.
#
# This is the calibration step for every A/B claim. Two runs of identical code
# never produce identical numbers - ruin RNG, OS scheduling and boot order all
# move the result - so without a measured noise floor a "12% faster" is just as
# likely to be the same code twice. Run this once per scenario, note the spread,
# and treat it as the smallest delta worth believing afterwards.
#
# Usage: tools/atmos_bench/run_repeat.sh <tag> <runs> [map] [cycles] [scenario] [event-cycle]
#   tag         label for the result files (a run index is appended)
#   runs        how many times to repeat, 2 or more to get a spread
#   map         json name from _maps/, default runtimestation
#   cycles      SSair cycles per run, default 240
#   scenario    synthetic arena, default none (plain map settling)
#   event-cycle scenario event cycle / recurring interval, default 60
#
# One build up front, then N boots reusing it. Analyze:
#   python tools/atmos_bench/analyze.py --variance tools/atmos_bench/results/*_<tag>-run*.jsonl
set -u
cd "$(dirname "$0")/../.." || { echo "ERROR: could not cd to project root" >&2; exit 1; }

TAG="${1:?usage: run_repeat.sh <tag> <runs> [map] [cycles] [scenario] [event-cycle]}"
RUNS="${2:?usage: run_repeat.sh <tag> <runs> [map] [cycles] [scenario] [event-cycle]}"
MAP="${3:-runtimestation}"
CYCLES="${4:-240}"
SCENARIO="${5:-}"
EVENT_CYCLE="${6:-60}"

if ! [ "$RUNS" -ge 1 ] 2>/dev/null; then
    echo "ERROR: runs must be a positive integer, got '$RUNS'" >&2
    exit 1
fi
if [ "$RUNS" -lt 2 ]; then
    echo "NOTE: a single run cannot show scatter; 3 or more is what makes the floor usable." >&2
fi

echo "=== building once with ATMOS_HEADLESS_BENCH ==="
touch code/modules/admin/verbs/atmos_benchmark.dm
node tools/build/build.js dm --define=ATMOS_HEADLESS_BENCH || exit 1

RESULTS=()
for RUN in $(seq 1 "$RUNS"); do
    echo ""
    echo "=== repeat $RUN/$RUNS ==="
    if ! tools/atmos_bench/run_headless.sh "${TAG}-run${RUN}" "$MAP" skip-build "$CYCLES" "$SCENARIO" "" "" "" "$EVENT_CYCLE"; then
        echo "WARNING: repeat $RUN failed, continuing" >&2
        continue
    fi
    LATEST=$(ls -t tools/atmos_bench/results/*_"${TAG}-run${RUN}".jsonl 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        RESULTS+=("$LATEST")
    fi
done

if [ "${#RESULTS[@]}" -lt 2 ]; then
    echo "=== only ${#RESULTS[@]} run(s) produced output, no spread to report ==="
    exit 0
fi

echo ""
echo "=== variance across ${#RESULTS[@]} runs ==="
if command -v python3 >/dev/null 2>&1; then
    python3 tools/atmos_bench/analyze.py --variance "${RESULTS[@]}"
else
    python tools/atmos_bench/analyze.py --variance "${RESULTS[@]}"
fi
