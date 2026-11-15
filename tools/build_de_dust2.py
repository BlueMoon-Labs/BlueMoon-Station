"""Builds the Team Deathmatch de_dust2 arena from a dmm2tgm export.

The arena is no longer generated tile by tile. It is converted from a real
de_dust2 .dmm (75x75, two z-levels, ladders between them), which this script
paints with the deathmatch areas and decorates with the team spawn landmarks:

  * every tile gets /area/deathmatch/tdm/de_dust2;
  * the two bomb sites get /area/deathmatch/tdm/plant_a and .../plant_b;
  * eight Terrorist and eight Counter-Terrorist spawn landmarks are placed on
    the upper level, one room per team;
  * the source map's /turf/open/misc floors are replaced with sand, because
    this codebase only has that path as the abstract parent of
    /turf/open/misc/grass, where it has no icon of its own.

Run from the repository root:

    python tools/build_de_dust2.py path/to/dd2v03.dmm

The result is written to _maps/TDM/de_dust2/de_dust2.dmm in TGM format. Keep the
coordinate constants below in sync with the source map if it is ever replaced:
they are the only thing tying the script to that particular layout.
"""

import re
import sys
from pathlib import Path
from string import ascii_letters

OUT = Path(__file__).resolve().parent.parent / "_maps" / "TDM" / "de_dust2" / "de_dust2.dmm"

ARENA_AREA = "/area/deathmatch/tdm/de_dust2"
PLANT_A_AREA = "/area/deathmatch/tdm/plant_a"
PLANT_B_AREA = "/area/deathmatch/tdm/plant_b"
T_SPAWN = "/obj/effect/landmark/deathmatch_player_spawn/terrorist"
CT_SPAWN = "/obj/effect/landmark/deathmatch_player_spawn/counter_terrorist"

# Bomb sites and spawn tiles on the upper level: x1, y1, x2, y2, z. The plant
# zones are rectangles; spawns are individual tiles, one landmark each.
PLANT_A = (48, 33, 52, 38, 2)
PLANT_B = (13, 10, 21, 13, 2)

T_SPAWNS = [
    (8, 55, 2), (10, 55, 2), (12, 55, 2), (14, 55, 2),
    (8, 58, 2), (10, 58, 2), (12, 58, 2), (14, 58, 2),
]
CT_SPAWNS = [
    (48, 56, 2), (50, 56, 2), (52, 56, 2), (54, 56, 2), (56, 56, 2),
    (48, 59, 2), (50, 59, 2), (52, 59, 2),
]

# The source map is drawn on /turf/open/misc, which this codebase only knows as
# the abstract parent of /turf/open/misc/grass: instanced directly, it has no
# icon and the arena floor would be invisible. Replace it with the sand the
# previous arena used. Keep the rest of the source map's turfs untouched.
TURF_REPLACEMENTS = {
    "/turf/open/misc": "/turf/open/floor/plating/beach/sand",
}


def split_atoms(body):
    """Split the body of a .dmm model definition into its atoms.

    Commas inside braces (the variable list of an object) or inside a quoted
    string are not separators, which a plain split would get wrong. The trailing
    separator of every atom is dropped, so serialization can put exactly one
    comma between atoms and none on the last one.
    """
    atoms = []
    depth = 0
    in_str = False
    escape = False
    current = []
    for ch in body:
        if in_str:
            current.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
            current.append(ch)
        elif ch == "{":
            depth += 1
            current.append(ch)
        elif ch == "}":
            depth -= 1
            current.append(ch)
        elif ch == "," and depth == 0:
            atoms.append("".join(current).strip("\n"))
            current = []
        else:
            current.append(ch)
    tail = "".join(current).strip()
    if tail:
        atoms.append(tail)
    return atoms


def read_source(path):
    source = path.read_text(encoding="utf-8", errors="replace")

    entries = {}
    for match in re.finditer(r'^"([^"]+)" = \(\n(.*?)\)$', source, re.M | re.S):
        atoms = split_atoms(match.group(2))
        assert atoms, "empty model entry " + match.group(1)
        assert all(not atom.endswith(",") for atom in atoms), match.group(1)
        entries[match.group(1)] = atoms

    blocks = {}
    for match in re.finditer(r'^\((\d+),(\d+),(\d+)\) = \{"\n(.*?)\n"\}$', source, re.M | re.S):
        blocks[(int(match.group(1)), int(match.group(2)), int(match.group(3)))] = match.group(4).splitlines()

    heights = {len(rows) for rows in blocks.values()}
    assert len(heights) == 1, "ragged columns: %s" % heights
    height = heights.pop()
    width = max(key[0] for key in blocks)
    depth = max(key[2] for key in blocks)
    assert len(blocks) == width * depth, (len(blocks), width, depth)

    # grid[(x, y, z)] = atoms; the first line of a block is the top (y = height).
    grid = {}
    for (x, block_y, z), rows in blocks.items():
        for index, key in enumerate(rows):
            assert key in entries, ("undefined key", key)
            grid[(x, block_y + height - 1 - index, z)] = list(entries[key])
    assert len(grid) == width * height * depth
    return grid, width, height, depth


def in_rect(x, y, z, rect):
    x1, y1, x2, y2, rect_z = rect
    return z == rect_z and x1 <= x <= x2 and y1 <= y <= y2


def paint(grid):
    t_spawns = set(T_SPAWNS)
    ct_spawns = set(CT_SPAWNS)
    assert not (t_spawns & ct_spawns)

    for (x, y, z), atoms in grid.items():
        area = PLANT_A_AREA if in_rect(x, y, z, PLANT_A) else \
               PLANT_B_AREA if in_rect(x, y, z, PLANT_B) else ARENA_AREA
        assert atoms[-1].startswith("/area/"), (x, y, z, atoms[-1])
        atoms[-1] = area
        for index, atom in enumerate(atoms):
            path = atom.split("{", 1)[0].strip()
            if path in TURF_REPLACEMENTS:
                atoms[index] = TURF_REPLACEMENTS[path] + atom[len(path):]
        if (x, y, z) in t_spawns:
            atoms.insert(0, T_SPAWN)
        elif (x, y, z) in ct_spawns:
            atoms.insert(0, CT_SPAWN)

    leftovers = {
        atom.split("{", 1)[0].strip()
        for atoms in grid.values()
        for atom in atoms
        if atom.split("{", 1)[0].strip() in TURF_REPLACEMENTS
    }
    assert not leftovers, leftovers


def write_map(grid, width, height, depth):
    # Two character keys are plenty for a map with a few dozen distinct tiles,
    # and .dmm requires one uniform key length across the whole file.
    alphabet = ascii_letters
    keys = {}
    for index, tile in enumerate(sorted({tuple(atoms) for atoms in grid.values()})):
        if index >= len(alphabet) ** 2:
            raise SystemExit("too many distinct tiles for two character keys")
        keys[tile] = alphabet[index // len(alphabet)] + alphabet[index % len(alphabet)]

    out = ["//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE"]
    for tile, key in keys.items():
        out.append(f'"{key}" = (')
        out.append(",\n".join(tile) + ")")

    for z in range(1, depth + 1):
        for x in range(1, width + 1):
            out.append(f'({x},1,{z}) = {{"')
            for index in range(height):
                y = height - index
                out.append(keys[tuple(grid[(x, y, z)])])
            out.append('"}')

    with open(OUT, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")


def main(argv):
    if len(argv) != 2:
        raise SystemExit("usage: python tools/build_de_dust2.py path/to/dd2v03.dmm")
    grid, width, height, depth = read_source(Path(argv[1]))
    paint(grid)
    write_map(grid, width, height, depth)
    print(f"wrote {OUT} ({width}x{height}x{depth}, {len(T_SPAWNS)} T spawns, {len(CT_SPAWNS)} CT spawns)")


if __name__ == "__main__":
    main(sys.argv)
