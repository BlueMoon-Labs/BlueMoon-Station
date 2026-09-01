#!/bin/bash
# Interleaved A/B: alternates two prebuilt .dmb files run by run,
# A,B,A,B,... instead of AAA,BBB.
#
# Why interleaving and not two blocks: a headless run is 5-6 minutes of wall
# clock, and the machine underneath is not constant over half an hour - other
# builds, an editor indexing, thermal throttling. Run in blocks, all of that
# drift lands on whichever side ran second and is indistinguishable from the
# patch. The tell is a result where every measured slot moves the same way by
# the same fifth, including the ones the change cannot reach; analyze.py now
# names that pattern explicitly. Alternating spreads the drift across both
# sides instead, which is the only thing that makes a 5% effect readable at all.
#
# Usage: tools/atmos_bench/run_ab_interleaved.sh <base.dmb> <cand.dmb> <tag> <pairs> [map] [cycles] [scenario]
#
# Build the two .dmb files first, e.g.:
#   node tools/build/build.js dm -DATMOS_HEADLESS_BENCH && cp tgstation.dmb tgstation.ab-base.dmb
#   ...apply the change...
#   node tools/build/build.js dm -DATMOS_HEADLESS_BENCH && cp tgstation.dmb tgstation.ab-cand.dmb
#
# Then compare with:
#   python tools/atmos_bench/analyze.py \
#     --baseline tools/atmos_bench/results/*<tag>-base-*.jsonl \
#     --candidate tools/atmos_bench/results/*<tag>-cand-*.jsonl
set -u
cd "$(dirname "$0")/../.." || { echo "ERROR: could not cd to project root" >&2; exit 1; }

BASE_DMB="${1:?usage: run_ab_interleaved.sh <base.dmb> <cand.dmb> <tag> <pairs> [map] [cycles] [scenario]}"
CAND_DMB="${2:?need a candidate .dmb}"
TAG="${3:?need a tag}"
# Чётное по умолчанию. ABBA уравнивает средний старт двух сторон только при чётном
# числе пар: на трёх парах порядок выходит base,cand / cand,base / base,cand, то есть
# кандидат в среднем стоит позже - ровно тот монотонный дрейф, ради устранения
# которого скрипт и написан.
PAIRS="${4:-4}"
MAP="${5:-runtimestation}"
# 600, а не 400: дефолтный сценарий - sustained-leak, а он держит стоячий градиент
# и просит от 600 циклов (см. шапку run_headless.sh). На 400 прогон обрывался на
# наборе нагрузки, то есть дефолтный запуск мерил не тот режим, ради которого
# сценарий и написан.
CYCLES="${6:-600}"
SCENARIO="${7:-sustained-leak}"

# Без проверки нечисловой PAIRS (например, съехавший на слот раньше map) валит seq,
# цикл не выполняется ни разу, и скрипт бодро печатает "done" с нулём прогонов.
case "$PAIRS" in
    ''|*[!0-9]*)
        echo "ERROR: pairs must be a whole number, got '$PAIRS'" >&2
        exit 1
        ;;
esac
if [ "$PAIRS" -lt 1 ]; then
    echo "ERROR: need at least one pair, got '$PAIRS'" >&2
    exit 1
fi
if [ $((PAIRS % 2)) -ne 0 ]; then
    echo "WARNING: odd pair count ($PAIRS) leaves the candidate systematically later in wall clock;" >&2
    echo "         ABBA only balances on an even count. Prefer $((PAIRS + 1))." >&2
fi

for dmb in "$BASE_DMB" "$CAND_DMB"; do
    if [ ! -f "$dmb" ]; then
        echo "ERROR: no such .dmb: $dmb" >&2
        exit 1
    fi
done

# The runner always launches tgstation.dmb, so swapping sides means swapping
# that file. Keep whatever was there and put it back at the end, otherwise the
# next ordinary build silently inherits one of the two A/B artifacts.
LIVE_DMB="tgstation.dmb"
RESTORE_DMB=""
LIVE_DMB_EXISTED=0
if [ -f "$LIVE_DMB" ]; then
    LIVE_DMB_EXISTED=1
    RESTORE_DMB="tgstation.ab-restore.dmb"
    cp "$LIVE_DMB" "$RESTORE_DMB"
fi

restore_live_dmb() {
    if [ "$LIVE_DMB_EXISTED" -eq 1 ]; then
        if [ -f "$RESTORE_DMB" ]; then
            cp "$RESTORE_DMB" "$LIVE_DMB"
            rm -f "$RESTORE_DMB"
        fi
        return
    fi
    # Своего .dmb тут не было: оставить артефакт A/B значит подсунуть его
    # следующему запуску как "уже собранное" - убираем, восстанавливаем пустоту.
    rm -f "$LIVE_DMB"
}
trap restore_live_dmb EXIT INT TERM

# Pair 0 is a throwaway: the first run after a build is reliably the slowest one
# of the batch (measured 51.5us/turf against 47.6 and 47.8 for the two that
# followed, on both sides). Dropping it took the run-to-run spread of the phase
# budget from +-8% to +-0.5%, which is the difference between being able to see a
# 2% change and not.
#
# Order alternates ABBA rather than ABAB. Plain interleaving still leaves the
# second side systematically later in wall-clock time, and the machine drifts
# monotonically over half an hour - which showed up as every slot moving the same
# way by 2-5%, including slots the patch cannot reach. Swapping the order every
# other pair equalises the mean start time of the two sides.
for pair in $(seq 0 "$PAIRS"); do
    if [ "$pair" -eq 0 ]; then
        ORDER="base cand"
        LABEL="warmup"
    elif [ $((pair % 2)) -eq 1 ]; then
        ORDER="base cand"
        LABEL="$pair"
    else
        ORDER="cand base"
        LABEL="$pair"
    fi
    for side in $ORDER; do
        if [ "$side" = "base" ]; then
            cp "$BASE_DMB" "$LIVE_DMB"
        else
            cp "$CAND_DMB" "$LIVE_DMB"
        fi
        if [ "$pair" -eq 0 ]; then
            echo "=== warm-up (discarded), side $side ==="
            tools/atmos_bench/run_headless.sh "${TAG}-warmup-${side}" "$MAP" skip-build "$CYCLES" "$SCENARIO" >/dev/null || {
                echo "ERROR: warm-up run failed" >&2
                exit 1
            }
            continue
        fi
        echo "=== pair $LABEL/$PAIRS, side $side ==="
        # skip-build is mandatory here: a rebuild would overwrite the very file
        # this script just put in place.
        tools/atmos_bench/run_headless.sh "${TAG}-${side}-${pair}" "$MAP" skip-build "$CYCLES" "$SCENARIO" || {
            echo "ERROR: run failed on pair $pair side $side" >&2
            exit 1
        }
    done
done

echo "=== done: $PAIRS pairs, interleaved ==="
