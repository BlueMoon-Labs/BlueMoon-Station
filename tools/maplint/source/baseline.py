import json
import pathlib
from collections import Counter
from dataclasses import dataclass, field
from typing import Iterable

from .error import MaplintError

"""Lint name used for maps that could not be parsed at all"""
PARSE_LINT = "dmm_parse"

"""(map file, lint name, typepath). No coordinates or pop keys, so moving content around a map keeps the key."""
BaselineKey = tuple[str, str, str]

def normalize_map_path(path) -> str:
    return str(path).replace("\\", "/")

def key_for(error: MaplintError) -> BaselineKey:
    return (
        normalize_map_path(error.file_name),
        error.lint_name or PARSE_LINT,
        error.typepath or "",
    )

"""Counts every turf a failing pop is placed on, so copying a violation elsewhere in the same map still raises the count."""
def count_errors(errors: Iterable[MaplintError]) -> Counter:
    counts: Counter = Counter()
    for error in errors:
        counts[key_for(error)] += error.instances
    return counts

def from_json(data: dict) -> dict[BaselineKey, int]:
    baseline: dict[BaselineKey, int] = {}
    for map_file, lints in data.items():
        for lint_name, typepaths in lints.items():
            for typepath, count in typepaths.items():
                baseline[(map_file, lint_name, typepath)] = int(count)
    return baseline

def to_json(baseline: dict[BaselineKey, int]) -> dict:
    data: dict = {}
    for (map_file, lint_name, typepath), count in baseline.items():
        if count <= 0:
            continue
        data.setdefault(map_file, {}).setdefault(lint_name, {})[typepath] = count
    return data

def load(path: pathlib.Path) -> dict[BaselineKey, int]:
    if not path.exists():
        return {}
    return from_json(json.loads(path.read_text(encoding = "utf-8")))

def save(path: pathlib.Path, baseline: dict[BaselineKey, int]):
    text = json.dumps(to_json(baseline), indent = "\t", sort_keys = True, ensure_ascii = False)
    with open(path, "w", encoding = "utf-8", newline = "\n") as file:
        file.write(text + "\n")

@dataclass
class Comparison:
    """Keys found more often than the baseline allows: key -> (found, allowed)"""
    over: dict[BaselineKey, tuple[int, int]] = field(default_factory = dict)

    """Baseline entries that allow more than was found: key -> (found, allowed)"""
    stale: dict[BaselineKey, tuple[int, int]] = field(default_factory = dict)

def in_scope(key: BaselineKey, checked_maps: set[str], checked_lints: set[str]) -> bool:
    return key[0] in checked_maps and (key[1] == PARSE_LINT or key[1] in checked_lints)

def compare(found: Counter, baseline: dict[BaselineKey, int], checked_maps: set[str], checked_lints: set[str]) -> Comparison:
    comparison = Comparison()

    for key, count in found.items():
        allowed = baseline.get(key, 0)
        if count > allowed:
            comparison.over[key] = (count, allowed)

    for key, allowed in baseline.items():
        if not in_scope(key, checked_maps, checked_lints):
            continue

        count = found.get(key, 0)
        if count < allowed:
            comparison.stale[key] = (count, allowed)

    return comparison

"""Replaces the entries of everything that was checked with what was found, keeping the rest untouched."""
def merge(baseline: dict[BaselineKey, int], found: Counter, checked_maps: set[str], checked_lints: set[str]) -> dict[BaselineKey, int]:
    merged = {key: count for key, count in baseline.items() if not in_scope(key, checked_maps, checked_lints)}
    for key, count in found.items():
        if count > 0:
            merged[key] = count
    return merged
