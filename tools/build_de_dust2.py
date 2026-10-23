"""Builds the three-level Team Deathmatch de_dust2 map.

The layout is a tile-based reconstruction of Counter-Strike's de_dust2, scaled
so that one tile is roughly one metre. The first z-level is the surface (T and
CT spawns, long A, mid, catacombs entrances, A and B sites, tunnels); the two
levels below are a catacomb network with ladders at matching coordinates, so
they link automatically.

Run from the repository root:

    python tools/build_de_dust2.py

The script writes _maps/TDM/de_dust2/de_dust2.dmm in TGM format.
"""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / "mapmerge2"))

from dmm import Coordinate, DMM  # noqa: E402

WIDTH = 200
HEIGHT = 200
DEPTH = 3

OUT = Path(__file__).resolve().parent.parent / "_maps" / "TDM" / "de_dust2" / "de_dust2.dmm"

# Turf paths, verified against this codebase.
SAND = "/turf/open/floor/plating/beach/sand"
TUNNEL = "/turf/open/floor/plasteel/dark"
WALL = "/turf/closed/wall/mineral/sandstone"
HARD_WALL = "/turf/closed/indestructible/sandstone"
SPACE = "/turf/open/space/basic"
SPACE_AREA = "/area/space"
ARENA_AREA = "/area/deathmatch"

# Area types, declared in code/modules/deathmatch/deathmatch_mapping.dm.
T_SPAWN = "/area/deathmatch/tdm/de_dust2/t_spawn"
CT_SPAWN = "/area/deathmatch/tdm/de_dust2/ct_spawn"
A_SITE = "/area/deathmatch/tdm/de_dust2/a_site"
B_SITE = "/area/deathmatch/tdm/de_dust2/b_site"
MID = "/area/deathmatch/tdm/de_dust2/mid"
LONG_A = "/area/deathmatch/tdm/de_dust2/long_a"
OUTSIDE_LONG = "/area/deathmatch/tdm/de_dust2/outside_long"
PIT = "/area/deathmatch/tdm/de_dust2/pit"
A_SHORT = "/area/deathmatch/tdm/de_dust2/a_short"
CATWALK = "/area/deathmatch/tdm/de_dust2/catwalk"
TUNNELS = "/area/deathmatch/tdm/de_dust2/tunnels"
UPPER_TUNNELS = "/area/deathmatch/tdm/de_dust2/upper_tunnels"
B_DOORS = "/area/deathmatch/tdm/de_dust2/b_doors"
CATACOMBS = "/area/deathmatch/tdm/de_dust2/catacombs"
UNDERGROUND = "/area/deathmatch/tdm/de_dust2/underground"

SPAWN = "/obj/effect/landmark/deathmatch_player_spawn"
LADDER = "/obj/structure/ladder"
CRATE = "/obj/structure/closet/crate"


class Dust2:
    def __init__(self):
        self.tiles = {}
        self.objects = {}
        self.dmm = DMM(3, Coordinate(WIDTH, HEIGHT, DEPTH))
        for z in range(1, DEPTH + 1):
            for y in range(1, HEIGHT + 1):
                for x in range(1, WIDTH + 1):
                    # Everything outside the playable rectangle is open space,
                    # which keeps the map's bounds at 200x200 while leaving a
                    # comfortable void margin around the walls.
                    if 4 <= x <= 195 and 4 <= y <= 195:
                        border = x in (4, 195) or y in (4, 195)
                        self.tiles[(x, y, z)] = (HARD_WALL if border else WALL, ARENA_AREA)
                    else:
                        self.tiles[(x, y, z)] = (SPACE, SPACE_AREA)

    def carve(self, x1, y1, x2, y2, z, area, floor):
        """Turns a rectangle into walkable floor."""
        for y in range(min(y1, y2), max(y1, y2) + 1):
            for x in range(min(x1, x2), max(x1, x2) + 1):
                if (x, y, z) in self.tiles and 5 <= x <= 194 and 5 <= y <= 194:
                    self.tiles[(x, y, z)] = (floor, area)

    def add(self, x, y, z, path):
        self.objects.setdefault((x, y, z), []).append(path)

    def add_if_floor(self, x, y, z, path):
        turf, _ = self.tiles.get((x, y, z), (None, None))
        if turf in (SAND, TUNNEL):
            self.add(x, y, z, path)

    def build_surface(self):
        # ---------------------------------------------------------------- T side
        self.carve(84, 12, 116, 40, 1, T_SPAWN, SAND)
        # T spawn to mid.
        self.carve(96, 38, 104, 46, 1, T_SPAWN, SAND)
        # T spawn to outside long.
        self.carve(56, 22, 84, 36, 1, OUTSIDE_LONG, SAND)
        # Long doors, the narrow choke between outside long and long A.
        self.carve(44, 26, 56, 32, 1, LONG_A, SAND)
        self.carve(34, 24, 44, 126, 1, LONG_A, SAND)
        # Long corner and pit.
        self.carve(22, 112, 44, 140, 1, LONG_A, SAND)
        self.carve(16, 136, 32, 166, 1, PIT, SAND)
        # T spawn to lower tunnels.
        self.carve(116, 22, 146, 34, 1, TUNNELS, SAND)

        # --------------------------------------------------------------- A site
        self.carve(26, 128, 76, 170, 1, A_SITE, SAND)
        # A short runs all the way down to the catwalk, so the two are actually
        # connected instead of ending a few tiles apart.
        self.carve(76, 136, 92, 160, 1, A_SHORT, SAND)

        # --------------------------------------------------------------- Mid
        self.carve(94, 40, 106, 92, 1, MID, SAND)
        # Mid doors: a five tile choke instead of the full width.
        self.carve(98, 90, 102, 98, 1, MID, SAND)
        self.carve(94, 96, 106, 150, 1, MID, SAND)
        # Catwalk from mid to A short.
        self.carve(72, 124, 96, 136, 1, CATWALK, SAND)
        # Mid to B, joining the east tunnel spine.
        self.carve(106, 96, 142, 106, 1, TUNNELS, SAND)

        # -------------------------------------------------------------- CT side
        self.carve(84, 146, 116, 180, 1, CT_SPAWN, SAND)
        self.carve(96, 136, 104, 150, 1, MID, SAND)
        # CT to B, through B doors.
        self.carve(116, 150, 130, 162, 1, B_DOORS, SAND)

        # --------------------------------------------------------------- B site
        self.carve(126, 132, 176, 170, 1, B_SITE, SAND)
        # Lower tunnels up the east side, and upper tunnels into B.
        self.carve(134, 26, 150, 122, 1, TUNNELS, SAND)
        self.carve(132, 118, 158, 140, 1, UPPER_TUNNELS, SAND)

        # --------------------------------------------------------------- Cover
        # T spawn.
        for x in (88, 89, 111, 112):
            self.add(x, 16, 1, CRATE)
        # Mid, the "xbox" pair.
        for x, y in ((99, 84), (100, 84), (99, 85), (100, 85)):
            self.add(x, y, 1, CRATE)
        # Long A.
        for x, y in ((36, 58), (37, 58), (41, 104), (42, 104), (36, 110)):
            self.add(x, y, 1, CRATE)
        # A site: A platform, goose and default plant cover.
        for x, y in ((30, 156), (31, 156), (32, 156), (30, 157),
                     (50, 148), (51, 148), (52, 148), (60, 162), (61, 162)):
            self.add(x, y, 1, CRATE)
        # CT spawn.
        for x, y in ((88, 172), (112, 172), (88, 173), (112, 173)):
            self.add(x, y, 1, CRATE)
        # B site: platform and doors cover.
        for x, y in ((156, 150), (157, 150), (158, 150), (156, 151),
                     (166, 160), (166, 161), (120, 156), (120, 157)):
            self.add(x, y, 1, CRATE)
        # Tunnels.
        for x, y in ((140, 48), (141, 48), (140, 80), (147, 112)):
            self.add(x, y, 1, CRATE)

    def build_catacombs(self):
        # ------------------------------------------------------- upper level (z2)
        self.carve(80, 72, 120, 128, 2, CATACOMBS, TUNNEL)
        # South shafts from T spawn up, and the corridor to the central hall.
        self.carve(86, 24, 90, 28, 2, CATACOMBS, TUNNEL)
        self.carve(86, 26, 90, 74, 2, CATACOMBS, TUNNEL)
        self.carve(110, 24, 114, 28, 2, CATACOMBS, TUNNEL)
        self.carve(110, 26, 114, 44, 2, CATACOMBS, TUNNEL)
        self.carve(86, 44, 112, 74, 2, CATACOMBS, TUNNEL)
        # North corridor to CT spawn.
        self.carve(86, 128, 114, 180, 2, CATACOMBS, TUNNEL)
        self.carve(108, 168, 112, 172, 2, CATACOMBS, TUNNEL)
        # West side, with both long A and A site ladders.
        self.carve(30, 88, 80, 104, 2, CATACOMBS, TUNNEL)
        self.carve(30, 134, 80, 146, 2, CATACOMBS, TUNNEL)
        self.carve(32, 138, 36, 142, 2, CATACOMBS, TUNNEL)
        self.carve(31, 87, 35, 91, 2, CATACOMBS, TUNNEL)
        self.carve(76, 120, 96, 146, 2, CATACOMBS, TUNNEL)
        # East side, with tunnel and B site ladders.
        self.carve(120, 88, 160, 104, 2, CATACOMBS, TUNNEL)
        self.carve(136, 36, 152, 88, 2, CATACOMBS, TUNNEL)
        self.carve(143, 79, 145, 81, 2, CATACOMBS, TUNNEL)
        self.carve(120, 134, 170, 146, 2, CATACOMBS, TUNNEL)
        self.carve(166, 138, 170, 142, 2, CATACOMBS, TUNNEL)
        self.carve(110, 124, 130, 146, 2, CATACOMBS, TUNNEL)

        # Cover in the upper level.
        for x, y in ((84, 76), (84, 77), (116, 124), (116, 125),
                     (60, 92), (61, 92), (140, 52), (141, 52),
                     (146, 96), (147, 96), (124, 138), (125, 138)):
            self.add(x, y, 2, CRATE)

        # --------------------------------------------------------- lower level (z3)
        self.carve(80, 80, 120, 120, 3, UNDERGROUND, TUNNEL)
        # South tunnel from T spawn.
        self.carve(86, 24, 114, 80, 3, UNDERGROUND, TUNNEL)
        # North tunnel to CT spawn.
        self.carve(86, 120, 114, 176, 3, UNDERGROUND, TUNNEL)
        # West and east spines.
        self.carve(30, 80, 80, 104, 3, UNDERGROUND, TUNNEL)
        self.carve(30, 130, 80, 170, 3, UNDERGROUND, TUNNEL)
        self.carve(50, 100, 60, 134, 3, UNDERGROUND, TUNNEL)
        self.carve(120, 80, 170, 104, 3, UNDERGROUND, TUNNEL)
        self.carve(120, 130, 170, 170, 3, UNDERGROUND, TUNNEL)
        self.carve(150, 100, 160, 134, 3, UNDERGROUND, TUNNEL)

        # Cover in the lower level.
        for x, y in ((92, 60), (93, 60), (108, 60), (108, 61),
                     (92, 140), (93, 140), (108, 140), (108, 141),
                     (44, 92), (45, 92), (44, 150), (45, 150),
                     (150, 92), (151, 92), (150, 150), (151, 150)):
            self.add(x, y, 3, CRATE)

    def build_ladders(self):
        # Matching x/y across z-levels: /obj/structure/ladder links itself to the
        # ladder directly above and below at LateInitialize.
        shafts = (
            (88, 26), (112, 26), (100, 90), (100, 170), (34, 90),
            (34, 140), (168, 140), (144, 80), (144, 100), (110, 170),
        )
        for x, y in shafts:
            for z in range(1, DEPTH + 1):
                self.add_if_floor(x, y, z, LADDER)

    def build_spawns(self):
        alpha = (
            (90, 20), (94, 20), (98, 20), (102, 20), (106, 20),
            (90, 24), (94, 24), (98, 24), (102, 24), (106, 24),
        )
        bravo = (
            (90, 162), (94, 162), (98, 162), (102, 162), (106, 162),
            (90, 166), (94, 166), (98, 166), (102, 166), (106, 166),
        )
        for x, y in alpha:
            self.add(x, y, 1, SPAWN + "{team = 1}")
        for x, y in bravo:
            self.add(x, y, 1, SPAWN + "{team = 2}")

    def write(self):
        for z in range(1, DEPTH + 1):
            for y in range(1, HEIGHT + 1):
                for x in range(1, WIDTH + 1):
                    floor = self.tiles[(x, y, z)]
                    objects = self.objects.get((x, y, z), [])
                    tile = tuple(objects) + floor
                    self.dmm.set_tile(Coordinate(x, y, z), tile)
        # save_tgm() writes TGM_HEADER itself; setting dmm.header here as well
        # would put the same comment on two lines.
        OUT.parent.mkdir(parents=True, exist_ok=True)
        self.dmm.to_file(str(OUT), tgm=True)
        print(f"wrote {OUT} ({WIDTH}x{HEIGHT}x{DEPTH}, {len(self.dmm.dictionary)} tile types)")


def main():
    map_data = Dust2()
    map_data.build_surface()
    map_data.build_catacombs()
    map_data.build_ladders()
    map_data.build_spawns()
    map_data.write()


if __name__ == "__main__":
    main()
