#!/bin/bash
# Headless atmos settling benchmark: builds with ATMOS_HEADLESS_BENCH, boots the
# map from _maps/<map>.json with no clients, lets SSair run a fixed number of
# cycles and collects data/atmos_headless_bench_*.jsonl. The server shuts itself
# down when done (see atmos_benchmark.dm, ATMOS_HEADLESS_BENCH section).
#
# Usage: tools/atmos_bench/run_headless.sh <tag> [map] [skip-build] [cycles]
#   tag        label for the result file (e.g. baseline, fix1)
#   map        json name from _maps/, default icemoonstation
#   skip-build pass "skip-build" to reuse the existing tgstation.dmb
#   cycles     SSair cycles to run, default 240 (compile-time default)
#
# Result: tools/atmos_bench/results/<timestamp>_<tag>.jsonl
# Analyze: python tools/atmos_bench/analyze.py <file> [file2 ...]
set -u
cd "$(dirname "$0")/../.." || { echo "ERROR: could not cd to project root" >&2; exit 1; }

TAG="${1:?usage: run_headless.sh <tag> [map] [skip-build] [cycles]}"
MAP="${2:-icemoonstation}"
SKIP_BUILD="${3:-}"
CYCLES="${4:-}"
DD_EXE="${BYOND_DD:-/d/Program Files (x86)/BYOND/bin/dd.exe}"
TIMEOUT_SECONDS=2700

if tasklist //FI "IMAGENAME eq dd.exe" 2>/dev/null | grep -q dd.exe; then
    echo "ERROR: dd.exe already running, refusing to start a second server" >&2
    exit 1
fi

if [ "$SKIP_BUILD" != "skip-build" ]; then
    echo "=== building with ATMOS_HEADLESS_BENCH ==="
    node tools/build/build.js dm --define=ATMOS_HEADLESS_BENCH || exit 1
fi

# Point the map loader at the target map; restore whatever was there afterwards.
NEXT_MAP_BACKUP=""
if [ -f data/next_map.json ]; then
    NEXT_MAP_BACKUP="$(mktemp)"
    cp data/next_map.json "$NEXT_MAP_BACKUP"
fi
if ! cp "_maps/${MAP}.json" data/next_map.json; then
    echo "ERROR: could not copy _maps/${MAP}.json to data/next_map.json" >&2
    if [ -n "$NEXT_MAP_BACKUP" ]; then
        cp "$NEXT_MAP_BACKUP" data/next_map.json
        rm -f "$NEXT_MAP_BACKUP"
    fi
    exit 1
fi
echo '{"data":"GRACEFULLY_ENDED"}' > data/GracefulEnding.json
rm -f data/atmos_headless_bench_*.jsonl

echo "=== launching DreamDaemon (map=$MAP, cycles=${CYCLES:-default}) ==="
DD_PARAMS=()
if [ -n "$CYCLES" ]; then
    DD_PARAMS=(-params "atmos-bench-cycles=$CYCLES")
fi
"$DD_EXE" tgstation.dmb 1337 -trusted -logself "${DD_PARAMS[@]}" >/dev/null 2>&1 &
DD_PID=$!

ELAPSED=0
while kill -0 "$DD_PID" 2>/dev/null; do
    if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
        echo "ERROR: benchmark did not finish within ${TIMEOUT_SECONDS}s, killing server" >&2
        taskkill //F //PID "$(tasklist //FI "IMAGENAME eq dd.exe" //FO CSV 2>/dev/null | tail -1 | cut -d, -f2 | tr -d '"')" >/dev/null 2>&1
        break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done
echo "=== server exited after ~${ELAPSED}s ==="

# Restore the previous next_map so local rotation is untouched.
if [ -n "$NEXT_MAP_BACKUP" ]; then
    cp "$NEXT_MAP_BACKUP" data/next_map.json
    rm -f "$NEXT_MAP_BACKUP"
fi

RESULT_SRC=$(ls -t data/atmos_headless_bench_*.jsonl 2>/dev/null | head -1)
if [ -z "$RESULT_SRC" ]; then
    echo "ERROR: no benchmark output produced" >&2
    exit 1
fi
mkdir -p tools/atmos_bench/results
RESULT="tools/atmos_bench/results/$(date +%Y-%m-%d_%H-%M-%S)_${TAG}.jsonl"
mv "$RESULT_SRC" "$RESULT"
echo "=== result: $RESULT ==="
python tools/atmos_bench/analyze.py "$RESULT"
