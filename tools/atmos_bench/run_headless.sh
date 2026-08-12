#!/bin/bash
# Headless atmos settling benchmark: builds with ATMOS_HEADLESS_BENCH, boots the
# map from _maps/<map>.json with no clients, lets SSair run a fixed number of
# cycles and collects data/atmos_headless_bench_*.jsonl. The server shuts itself
# down when done (see atmos_benchmark.dm, ATMOS_HEADLESS_BENCH section).
#
# Usage: tools/atmos_bench/run_headless.sh <tag> [map] [skip-build] [cycles] [scenario] [breaches] [firelocks] [seed] [event-cycle] [sleeping-edges]
#   tag        label for the result file (e.g. baseline, fix1)
#   map        json name from _maps/, default icemoonstation
#   skip-build pass "skip-build" to reuse the existing tgstation.dmb
#   cycles     SSair cycles to run, default 240 (compile-time default)
#   scenario   synthetic arena: multi-breach, plasma-fire, giant-hall,
#              giant-hall-eq, room-grid, pipenet-stress, heat-wall, space-wind,
#              reaction-zoo, he-loop, atom-churn, changeturf-storm;
#              station-breach runs on the loaded map instead of a reservation
#   breaches   number of simultaneous breaches, 1-4 (multi-breach only)
#   firelocks  1 closes firelocks, 0 welds the same doors open (multi-breach only)
#   seed       deterministic world seed, default 29051994 in headless builds
#   event-cycle cycle of the scenario event (breach/ignite/open); recurring
#              interval for pipenet-stress; default 20
#   sleeping-edges pass "1" to force SSair.sleeping_edges_enabled for the run
#              (A/B against the config default without touching config files)
#
# Result: tools/atmos_bench/results/<timestamp>_<tag>.jsonl
# Analyze: python tools/atmos_bench/analyze.py <file> [file2 ...]
set -u
cd "$(dirname "$0")/../.." || { echo "ERROR: could not cd to project root" >&2; exit 1; }

TAG="${1:?usage: run_headless.sh <tag> [map] [skip-build] [cycles] [scenario] [breaches] [firelocks] [seed] [event-cycle]}"
MAP="${2:-icemoonstation}"
SKIP_BUILD="${3:-}"
CYCLES="${4:-}"
SCENARIO="${5:-}"
BREACHES="${6:-}"
FIRELOCKS="${7:-}"
SEED="${8:-}"
EVENT_CYCLE="${9:-}"
SLEEPING_EDGES="${10:-}"
DD_EXE="${BYOND_DD:-/d/Program Files (x86)/BYOND/bin/dd.exe}"
TIMEOUT_SECONDS=2700
NEXT_MAP_BACKUP=""
DD_PID=""

# Git Bash exposes D: as /d, while WSL exposes it as /mnt/d. Keep the existing
# override for custom installs, but make the repository's documented runner
# work in either shell on Windows.
if [ ! -x "$DD_EXE" ] && [ -x "/mnt/d/Program Files (x86)/BYOND/bin/dd.exe" ]; then
    DD_EXE="/mnt/d/Program Files (x86)/BYOND/bin/dd.exe"
fi
if [ ! -x "$DD_EXE" ]; then
    echo "ERROR: DreamDaemon not found at '$DD_EXE' (set BYOND_DD to override)" >&2
    exit 1
fi

terminate_benchmark() {
    if [ -z "$DD_PID" ] || ! kill -0 "$DD_PID" 2>/dev/null; then
        return
    fi
    WIN_PID=$(tasklist //FI "IMAGENAME eq dd.exe" //FO CSV 2>/dev/null | tail -1 | cut -d, -f2 | tr -d '"')
    if [ -n "$WIN_PID" ]; then
        taskkill //F //PID "$WIN_PID" >/dev/null 2>&1 || true
    fi
    kill "$DD_PID" 2>/dev/null || true
}

restore_next_map() {
    if [ -n "$NEXT_MAP_BACKUP" ] && [ -f "$NEXT_MAP_BACKUP" ]; then
        cp "$NEXT_MAP_BACKUP" data/next_map.json
        rm -f "$NEXT_MAP_BACKUP"
        NEXT_MAP_BACKUP=""
    fi
}

cleanup() {
    terminate_benchmark
    restore_next_map
}
trap cleanup EXIT
trap 'exit 130' INT TERM

if tasklist //FI "IMAGENAME eq dd.exe" 2>/dev/null | grep -q dd.exe; then
    echo "ERROR: dd.exe already running, refusing to start a second server" >&2
    exit 1
fi

if [ "$SKIP_BUILD" != "skip-build" ]; then
    echo "=== building with ATMOS_HEADLESS_BENCH ==="
    # Juke's timestamp cache does not distinguish two invocations that only
    # differ by --define. Force the benchmark source newer than the current DMB
    # so a preceding normal build cannot be reused accidentally.
    touch code/modules/admin/verbs/atmos_benchmark.dm
    node tools/build/build.js dm --define=ATMOS_HEADLESS_BENCH || exit 1
fi

# Point the map loader at the target map; restore whatever was there afterwards.
if [ -f data/next_map.json ]; then
    NEXT_MAP_BACKUP="$(mktemp)"
    cp data/next_map.json "$NEXT_MAP_BACKUP"
fi
if ! cp "_maps/${MAP}.json" data/next_map.json; then
    echo "ERROR: could not copy _maps/${MAP}.json to data/next_map.json" >&2
    exit 1
fi
echo '{"data":"GRACEFULLY_ENDED"}' > data/GracefulEnding.json
rm -f data/atmos_headless_bench_*.jsonl

echo "=== launching DreamDaemon (map=$MAP, cycles=${CYCLES:-default}, scenario=${SCENARIO:-map}) ==="
DD_PARAMS=()
PARAM_STRING=""
append_param() {
    if [ -n "$PARAM_STRING" ]; then
        PARAM_STRING="${PARAM_STRING}&$1"
    else
        PARAM_STRING="$1"
    fi
}
if [ -n "$CYCLES" ]; then
    append_param "atmos-bench-cycles=$CYCLES"
fi
if [ -n "$SCENARIO" ]; then
    append_param "atmos-bench-scenario=$SCENARIO"
fi
if [ -n "$BREACHES" ]; then
    append_param "atmos-bench-breaches=$BREACHES"
fi
if [ -n "$FIRELOCKS" ]; then
    append_param "atmos-bench-firelocks=$FIRELOCKS"
fi
if [ -n "$SEED" ]; then
    append_param "atmos-bench-seed=$SEED"
fi
if [ -n "$EVENT_CYCLE" ]; then
    append_param "atmos-bench-event-cycle=$EVENT_CYCLE"
fi
if [ -n "$SLEEPING_EDGES" ]; then
    append_param "atmos-bench-sleeping-edges=$SLEEPING_EDGES"
fi
if [ -n "$PARAM_STRING" ]; then
    DD_PARAMS=(-params "$PARAM_STRING")
fi
"$DD_EXE" tgstation.dmb 1337 -trusted -logself "${DD_PARAMS[@]}" >/dev/null 2>&1 &
DD_PID=$!

ELAPSED=0
while kill -0 "$DD_PID" 2>/dev/null; do
    if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
        echo "ERROR: benchmark did not finish within ${TIMEOUT_SECONDS}s, killing server" >&2
        terminate_benchmark
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done
DD_PID=""
echo "=== server exited after ~${ELAPSED}s ==="

# Restore the previous next_map so local rotation is untouched.
restore_next_map

RESULT_SRC=$(ls -t data/atmos_headless_bench_*.jsonl 2>/dev/null | head -1)
if [ -z "$RESULT_SRC" ]; then
    echo "ERROR: no benchmark output produced" >&2
    exit 1
fi
mkdir -p tools/atmos_bench/results
RESULT="tools/atmos_bench/results/$(date +%Y-%m-%d_%H-%M-%S)_${TAG}.jsonl"
mv "$RESULT_SRC" "$RESULT"
echo "=== result: $RESULT ==="
if command -v python3 >/dev/null 2>&1; then
    python3 tools/atmos_bench/analyze.py "$RESULT"
else
    python tools/atmos_bench/analyze.py "$RESULT"
fi
