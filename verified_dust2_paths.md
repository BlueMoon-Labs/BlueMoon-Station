# Verified type paths for authoring a de_dust2 recreation in this BYOND/SS13 codebase

## 1. Main .dme file, project name, and codebase description

- Main .dme file: `C:\rep\Shitcode\tgstation.dme` (also `C:\rep\Shitcode\tgstation.test.dme` for tests)
- Project name: "BlueMoon Station" (from README.md header)
- Codebase description: This is a Russian-language Space Station 13 fork (BlueMoon Station) derived from S.P.L.U.R.T. Station → Sandstorm Station → Citadel Station → /tg/station. It is a tgstation13-derived codebase (tg-like) with extensive modular content (modular_bluemoon, modular_citadel, modular_sand, modular_splurt, modular_zubbers). It's a mature SS13 codebase with standard tg tooling (Build.bat, TGS, SpacemanDMM.toml present). The repo is at `C:\rep\Shitcode`.

## 2. maps/ directory contents and .dmm format

- Maps root: `C:\rep\Shitcode\_maps\`
- Contains: `_DEFINES`, `map_files/` (with BoxStations, MetaStation, CogStation, DeltaStation, Tramstation, KiloStation, LambdaStation, NebulaStation, NorthStar, IceBoxStation, Ouroboros, VoidRaptor, Biodome, Bluemoon/maps, etc.), `RandomRuins/`, `RandomZLevels/`, `shuttles/`, `templates/`, `deathmatch/`, `archive/`, plus many `.json` files for map rotation and station maps.
- Representative small .dmm files examined: `reactor_1.dmm` (templates, ~3 KB), `secu_ring.dmm` (deathmatch, ~3 KB), `lavaland_surface_cube.dmm` (LavaRuins, ~3 KB). All inspected use **TGM format**:
  - Header: `//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE`
  - Key format: 3-char (and sometimes longer) alphanumeric keys like `"a"`, `"b"`, `"c"`, `"d"`, `"e"`, `"f"` mapped to tuples `(1,1,1) = {" ... ... "}` where the quoted block contains one full column of the map (Z-level) in TGM format (each line in that block is a row). This matches classic tg TGM conversion output.
- First ~30 lines (verbatim, from `reactor_1.dmm`):
```text
//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE
"a" = (
/obj/effect/turf_decal/stripes/red/corner{
	dir = 8
	},
/turf/open/floor/engine,
/area/engineering/main/reactor_core)
"b" = (
/obj/effect/turf_decal/stripes/red{
	dir = 4
	},
/obj/effect/turf_decal/arrows/white{
	dir = 8;
	pixel_x = 5;
	pixel_y = 10
	},
/turf/open/floor/engine,
/area/engineering/main/reactor_core)
"c" = (
/obj/effect/turf_decal/stripes/red{
	dir = 4
	},
/turf/open/floor/engine,
/area/engineering/main/reactor_core)
"d" = (
/obj/structure/cable/yellow,
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/cargo,
/turf/open/floor/engine,
/area/engineering/main/reactor_core)
"e" = (
/obj/effect/turf_decal/stripes/red/corner{
	dir = 4
	},
/turf/open/floor/engine,
/area/engineering/main/reactor_core)
"f" = (
/obj/machinery/atmospherics/pipe/simple/cyan{
	dir = 4
	},
/turf/open/floor/engine,
/area/engineering/main/reactor_core)
```
- Style notes: 3-char lowercase keys in this example; keys are quoted strings `"a" = (...)`. Object/turf/area paths separated by commas; area is last on the turf/placement line in typical TGM output. Variants use `{ ... }` inline properties.

## 3. Turf paths (verified to exist)

### Floors (most common in existing maps)
Verified by grepping `.dm` and counting occurrences in `BoxStation.dmm`:
- `/turf/open/floor/plating` (base plating; defined in `code/game/turfs/simulated/floor/plating.dm:10`; many subtypes under `plating/` like `plating/asteroid/basalt/lava_land_surface`, `plating/snowed`, `plating/dirt`, etc. — **very common**)
- `/turf/open/floor/plasteel` (defined in `code/game/turfs/simulated/floor/plasteel_floor.dm:1`; subtypes that exist here: `plasteel/dark`, `plasteel/white`, `plasteel/cafeteria`, `plasteel/grimy`, `plasteel/checker`, `plasteel/stairs` and their corners/sides. **There is no `plasteel/textured` family in this codebase at all** — grepping `textured` under this path comes back empty, so do not map with `/turf/open/floor/plasteel/textured/large` or `/half`)
- `/turf/open/floor/plasteel/dark/*` (common dark variants)
- `/turf/open/floor/engine` (reinforced engine floor; defined in `code/game/turfs/simulated/floor/reinf_floor.dm:2`)
- `/turf/open/floor/wood` (wood floor; defined in `code/game/turfs/simulated/floor/fancy_floor.dm:10`; subtypes: `wood/cold`, `wood/airless`, `wood/wood_large`, `wood/wood_tiled`, `wood/wood_diagonal`, `wood/wood_parquet`)
- `/turf/open/floor/grass` (grass; `fancy_floor.dm:96`)
- `/turf/open/floor/carpet` (carpet; `fancy_floor.dm:238`, subtypes `carpet/red`, `carpet/royalblack`, etc.)
- `/turf/open/floor/mineral` (base; `mineral_floor.dm:12` with many subtypes like `mineral/titanium/blue`, `mineral/plastitanium`, `mineral/silver`, `mineral/gold`, `mineral/diamond`, `mineral/uranium`, `mineral/plasma`, `mineral/sandstone`, `mineral/wood`, etc.)
- `/turf/open/floor/light` (lit floor; `light_floor.dm:1`)
- `/turf/open/floor/pod` (pod floor; `misc_floor.dm:107`)
- `/turf/open/floor/circuit` (circuit floor; `misc_floor.dm:15`)

Additional useful desert/outdoor floor-like plating variants (verified): `/turf/open/floor/plating/asteroid/basalt/lava_land_surface`, `/turf/open/floor/plating/beach/sand`, `/turf/open/floor/plating/dirt`, `/turf/open/floor/plating/ashplanet`, etc. (see `plating/misc_plating.dm`, `asteroid.dm`, `dirt.dm`).

### Walls
- `/turf/closed/wall` (base station wall; defined in `code/game/turfs/simulated/walls.dm:3`) — very common
- `/turf/closed/wall/r_wall` (reinforced wall; defined in `code/game/turfs/simulated/wall/reinf_walls.dm:1`) — very common
- `/turf/closed/wall/rust` (rusted wall; `code/game/turfs/simulated/wall/misc_walls.dm:187`)
- Mineral walls (constructed/colored/mineral types): `/turf/closed/wall/mineral` base and subtypes like `wall/mineral/gold`, `wall/mineral/silver`, `wall/mineral/diamond`, `wall/mineral/bananium`, `wall/mineral/sandstone`, `wall/mineral/uranium`, `wall/mineral/plasma`, `wall/mineral/wood` (also `wall/mineral/wood/nonmetal`), `wall/mineral/iron`, `wall/mineral/snow`, `wall/mineral/abductor`, `wall/mineral/titanium` (+variants), `wall/mineral/plastitanium` (+variants), `wall/mineral/cult` (+artificer). Defined in `wall/mineral_walls.dm` and `wall/misc_walls.dm`.
- Natural/indestructible/mineral terrain: `/turf/closed/mineral` (base), `/turf/closed/indestructible` and subtypes like `indestructible/rock`, `indestructible/riveted`, `indestructible/sandstone`, `indestructible/wood`, etc. (see `code/game/turfs/closed.dm`, `code/game/turfs/simulated/minerals.dm`).

## 4. Doors
- Base airlock path: `/obj/machinery/door/airlock` (defined/used in `code/game/machinery/doors/airlock.dm:69`, with control code in `airlock_control.dm` etc.) — this is the standard.
- Common safe-to-place subtypes (from BoxStation usage and type definitions in `code/game/machinery/doors/airlock_types.dm`):
  - `/obj/machinery/door/airlock/public` (+ `/obj/machinery/door/airlock/public/glass`)
  - `/obj/machinery/door/airlock/maintenance` (+ `/obj/machinery/door/airlock/maintenance/glass`, `/obj/machinery/door/airlock/maintenance/external`, `/obj/machinery/door/airlock/maintenance/external/glass`)
  - `/obj/machinery/door/airlock/external` (+ `/obj/machinery/door/airlock/external/glass`)
  - `/obj/machinery/door/airlock/command` (+ `/obj/machinery/door/airlock/command/glass`)
  - `/obj/machinery/door/airlock/security` (+ `/obj/machinery/door/airlock/security/glass`)
  - `/obj/machinery/door/airlock/engineering` (+ `/obj/machinery/door/airlock/engineering/glass`)
  - `/obj/machinery/door/airlock/medical` (+ `/obj/machinery/door/airlock/medical/glass`)
  - `/obj/machinery/door/airlock/research` (+ `/obj/machinery/door/airlock/research/glass`)
  - `/obj/machinery/door/airlock/service`
  - `/obj/machinery/door/airlock/mining` (+ `/obj/machinery/door/airlock/mining/glass`)
  - `/obj/machinery/door/airlock/freezer`
  - `/obj/machinery/door/airlock/glass` (plain glass airlock)
  - `/obj/machinery/door/airlock/wood` (+ `/obj/machinery/door/airlock/wood/glass`)
  - `/obj/machinery/door/airlock/hatch`, `/obj/machinery/door/airlock/maintenance_hatch`
  - `/obj/machinery/door/airlock/shuttle` (+ `/obj/machinery/door/airlock/shuttle/glass`)
  - Multi-tile (2-wide): `/obj/machinery/door/airlock/multi_tile/metal`, `/obj/machinery/door/airlock/multi_tile/glass` (defined in modular_bluemoon/large_doors and referenced in airlock_types)

Also present: `survival_pod` variants in mining code (`/obj/machinery/door/airlock/survival_pod`, `/obj/machinery/door/airlock/survival_pod/glass`).

## 5. Areas
DMM requires `/area` on every tile. Common generic/simple area types (verified in codebase):
- `/area/space` (space area; defined in `code/game/area/Space_Station_13_areas.dm:52`)
- `/area/space/nearstation` (`Space_Station_13_areas.dm:69`)
- `/area/maintenance` (base maintenance; `Space_Station_13_areas.dm:229`) — has many directional subtypes like `maintenance/port/aft`, `maintenance/starboard/fore`, etc. (commonly used on maps)
- `/area/hallway` (base hallway; `Space_Station_13_areas.dm:468`) — with subtypes `hallway/primary/*`, `hallway/secondary/*` commonly used
- `/area/template_noop` (mapping template area; `code/modules/mapping/preloader.dm:56`) — safe for empty/template maps
- Also commonly seen: `/area/commons/dorms`, `/area/engineering/main`, `/area/engineering/atmos`, `/area/security/office`, `/area/command/bridge`, `/area/medical/medbay/central`, `/area/service/bar`, `/area/service/kitchen`, `/area/service/park`, `/area/cargo/storage`, `/area/science`, `/area/science/xenobiology`, `/area/medical/virology`, etc. (many specific departmental areas exist; use generic ones above for broad map areas).

## 6. Simple self-contained objects good for desert/decor
Verified to exist (definitions found):
- `/obj/structure/table` (base; `tables_racks.dm:15`) — many subtypes: `table/wood`, `table/glass`, `table/reinforced`, etc.
- `/obj/structure/closet` (base; `crates_lockers/closets.dm:1`) — many departmental/types; also `/obj/structure/closet/emcloset`, `/obj/structure/closet/firecloset`, etc.
- `/obj/structure/closet/crate` (crate; `crates_lockers/crates.dm:1`)
- `/obj/structure/rack` (rack; `tables_racks.dm:1029`)
- `/obj/machinery/light` (base light; `power/lighting.dm:182`) — subtypes: `light/small`, `light/broken`, `light/built`, `light/floor`, `light/warm`, `light/cold`, `light/red`, `light/blacklight`, `light/dim`, etc.
- Chairs: `/obj/structure/chair` (base; `beds_chairs/chair.dm:1`) — subtypes include `chair/stool`, `chair/comfy/black`, `chair/comfy/brown`, `chair/office/light`, `chair/office/dark`, `chair/sofa/*`, `chair/pew/*`, etc.
- Beds: `/obj/structure/bed` (`beds_chairs/bed.dm:10`) — subtypes like `bed/roller`, `bed/dogbed`, etc.
- Cleanable decals: `/obj/effect/decal/cleanable` (base; `effects/decals/cleanable.dm:7`) — subtypes seen on maps: `cleanable/dirt`, `cleanable/cobweb` (+cobweb2), `cleanable/dirt/dust`, `cleanable/oil`, `cleanable/blood/old`, `cleanable/vomit/old`, `cleanable/blood/gibs/*`, etc.
- Flora/rocks/sand/decor: `/obj/structure/flora` (base; `flora.dm:1`) — subtypes: `flora/tree`, `flora/stump`, `flora/grass`, `flora/bush`, `flora/ausbushes`, `flora/rock` (+`flora/rock/pile`, `flora/rock/jungle`), `flora/junglebush`. Ash/lavaland variants: `flora/ashtree`, `flora/ash` (+`tall_shroom`, `leaf_shroom`, `cap_shroom`, `stem_shroom`, `cacti`), `flora/ash/cacti` and related fruit objects. Also `ash_flora` has cactus/plant objects.
- Ladders: `/obj/structure/ladder` (`structures/ladders.dm:2`)
- Desert-themed/CS1.6 style hints: repo has some BlueMoon modular content and "Sandstorm" lineage (modular_sand present), but no obvious explicit "de_dust2" or "counter-strike" map named in common paths checked. Cactus exists in ash_flora/mining bounties (`/obj/item/seeds/lavaland/cactus`, `/obj/item/reagent_containers/food/snacks/grown/ash_flora/cactus_fruit`), which fits desert theming. Rocks/ash flora listed above are good desert props.

## 7. Tools directory and language/toolchain
- Tools dir: `C:\rep\Shitcode\tools\` exists with many utilities. Map utilities:
  - `tools/mapmerge2/` — Python-based map merging/formatting tool (has `convert.py`, `dmm.py`, `mapmerge.py`, frontend, and `.bat` helpers like `I Forgot To Map Merge.bat`, `Resolve Map Conflicts.bat`, `Run Before Committing.bat`). Also references TGM conversion logic (`convert.py` uses `dmm.DMM.from_file(fname).to_file(fname, tgm=settings.tgm)`).
  - Also `tools/build/` scripts, `tools/ci/`, etc. No `dmm2tgm.py` in top-level `tools/` in the listing, but maps carry the header `//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE` — that suggests the conversion tool name is historical/known; `mapmerge2` is the modern tool used here for map handling.
- Language/toolchain assumed by repo tooling:
  - BYOND (DreamMaker/DreamDaemon) — primary: `.dm`, `.dme`, `.dmm`, `Build.bat`/`Build.sh`, `tgstation.dmb`, SpacemanDMM.toml present.
  - Python 3 for tools (mapmerge2, various scripts). `tools/requirements.txt` shows `pygit2==1.19.0`, `bidict==0.22.1`, `Pillow==10.3.0`, `PyYaml==6.0.1`, `beautifulsoup4==4.9.3`, `mysql-connector-python==8.0.33`, `numpy==1.26.0`.
  - Node.js for TGUI/tgui (has `tgui/`, `node_modules/`, references in CI/scripts).
  - Also Rust/C/C++ bits present (`auxmos.dll/.so`, `rust_g.dll`, etc.) for auxiliary libraries.
- Recommended mapping tool mentioned in README: StrongDMM (external) and map merging tools at tg wiki; in-repo tooling is mapmerge2 + SpacemanDMM.
```text
(py3 env for tools; BYOND compiler for .dm/.dmm)
```

## Notes
- Every type path reported above was verified to exist in the codebase via glob/grep against `.dm` sources (paths confirmed in their respective definition files). No invented paths.
- For a de_dust2 recreation: start with `/turf/open/floor/plating` or `/turf/open/floor/plasteel`/textured variants for concrete-like floors, use `/turf/closed/wall` and `/turf/closed/wall/r_wall` for walls, stock airlocks (`/obj/machinery/door/airlock` with appropriate department subtype or plain `/obj/machinery/door/airlock/public/glass`/`glass`), and generic `/area` (e.g. `/area/maintenance` or create appropriately scoped areas; standard `/area` types listed above exist). Desert decor can use flora/cactus variants and rocks from flora/ash lists.
