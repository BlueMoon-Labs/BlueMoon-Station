// Deathmatch arena mapping.
// Arenas are lazily loaded into a reserved block of a virtual reality z-level,
// so nothing here may assume that a map is present at round start.

/area/deathmatch
	name = "Deathmatch Arena"
	requires_power = FALSE
	// Arenas are built with floors, walls and ladders in mind, and the base
	// /area type has gravity off. Without this nobody can jump or throw.
	has_gravity = TRUE
	// Set explicitly so that the flags are independent of the /area defaults.
	// These are the flags the base type has: fires are not suppressed, but a
	// deathmatch has no reason to let clutter and conversions spawn here.
	area_flags = VALID_TERRITORY | UNIQUE_AREA | NO_ALERTS
	// Bubber sets LOCAL_TELEPORT, EVENT_PROTECTED, QUIET_LOGS,
	// NO_DEATH_MESSAGE and BINARY_JAMMING here, but none of them exist in this
	// codebase. Left out on purpose instead of copying dead symbols. Noise is
	// handled per game by /datum/deathmatch_game, NOTLEPORT is deliberately not
	// used because loadout / cryo / shuttles teleports have to work in an arena.

/// BlueMoon has no area level fullbright (the 516 lighting rework dropped
/// base_lighting_alpha), so an arena is lit by the map template that loads it:
/// /datum/map_template/deathmatch/turn_on_the_lights() drops emitters over the
/// freshly loaded bounds. No lighting lives on the area for the reason spelled
/// out in /area/deathmatch below.
///
/// Left declared and unused. No .dmm in this codebase carries an "area" key, so
/// nothing can land on this subtype; it is kept as the obvious landing spot if
/// a per area opt-in is ever wanted, and must not be given state that a later
/// arena would inherit.
/area/deathmatch/fullbright
	name = "Deathmatch Arena (Lit)"

/obj/effect/light_emitter/deathmatch
	name = "Deathmatch arena light"
	icon = null
	// Emitters have no light map data of their own, this is the light they cast.
	set_luminosity = 7
	set_cap = 2

//
// de_dust2 TDM areas.
//
// Only used by _maps/TDM/de_dust2/de_dust2.dmm. The base area is what an
// unmarked tile is painted with; plant_a/plant_b gate C4, and the rest are the
// callout zones read by the team radio implant. Painting one over a region is
// all it takes for a message sent from there to name that region.
// All of them inherit has_gravity, requires_power and the area flags from
// /area/deathmatch above.
/area/deathmatch/tdm
	name = "Team Deathmatch"

/// The whole de_dust2 arena.
/area/deathmatch/tdm/de_dust2
	name = "de_dust2"

/// C4 may only be planted inside these two areas. Paint them over the desired
/// bomb sites on a TDM map; de_dust2 uses them for its A and B sites.
/area/deathmatch/tdm/plant_a
	name = "Bomb Plant Zone A"

/area/deathmatch/tdm/plant_b
	name = "Bomb Plant Zone B"

// Radio callout zones. `name` is what goes into the radio message, so these are
// written with spaces instead of underscores. The paths are what a mapper
// paints on the .dmm.
/area/deathmatch/tdm/de_dust2/mid
	name = "mid"

/area/deathmatch/tdm/de_dust2/mid_short
	name = "mid short"

/area/deathmatch/tdm/de_dust2/ct
	name = "CT"

/area/deathmatch/tdm/de_dust2/t
	name = "T"

/area/deathmatch/tdm/de_dust2/window
	name = "window"

/area/deathmatch/tdm/de_dust2/dance_stage
	name = "dance stage"

/area/deathmatch/tdm/de_dust2/hideout
	name = "hideout"

/area/deathmatch/tdm/de_dust2/b_doors
	name = "B doors"

/area/deathmatch/tdm/de_dust2/tunnel
	name = "tunnel"

/area/deathmatch/tdm/de_dust2/a_short
	name = "A short"

/area/deathmatch/tdm/de_dust2/mid_doors
	name = "mid doors"

/area/deathmatch/tdm/de_dust2/square
	name = "Square"

/area/deathmatch/tdm/de_dust2/dust
	name = "Dust"

/area/deathmatch/tdm/de_dust2/palace
	name = "Palace"

/area/deathmatch/tdm/de_dust2/down_palace
	name = "Down palace"

/area/deathmatch/tdm/de_dust2/bridge
	name = "bridge"

/area/deathmatch/tdm/de_dust2/ct_mid
	name = "CT mid"

/area/deathmatch/tdm/de_dust2/block
	name = "block"

/area/deathmatch/tdm/de_dust2/sands
	name = "sands"

/area/deathmatch/tdm/de_dust2/trap
	name = "trap"

/area/deathmatch/tdm/de_dust2/titanic
	name = "titanic"

/area/deathmatch/tdm/de_dust2/can
	name = "can"

/area/deathmatch/tdm/de_dust2/pit
	name = "pit"

/area/deathmatch/tdm/de_dust2/corner
	name = "corner"

/area/deathmatch/tdm/de_dust2/platform
	name = "platform"

/area/deathmatch/tdm/de_dust2/adds
	name = "adds"

/area/deathmatch/tdm/de_dust2/look_throug
	name = "look throug"

/area/deathmatch/tdm/de_dust2/goose
	name = "goose"

/area/deathmatch/tdm/de_dust2/upping
	name = "upping"

// Numeric callouts need a `zone_` prefix in the type path: a path segment
// cannot start with a digit. `name` is still the bare number used in chat.
/area/deathmatch/tdm/de_dust2/zone_20
	name = "20"

/area/deathmatch/tdm/de_dust2/zone_8
	name = "8"

/area/deathmatch/tdm/de_dust2/zone_0
	name = "0"

/area/deathmatch/tdm/de_dust2/zone_9
	name = "9"

/area/deathmatch/tdm/de_dust2/zone_11
	name = "11"

/area/deathmatch/tdm/de_dust2/zone_90
	name = "90"

/area/deathmatch/tdm/de_dust2/zone_7
	name = "7"

/area/deathmatch/tdm/de_dust2/zone_1
	name = "1"

/area/deathmatch/tdm/de_dust2/zone_3
	name = "3"

/area/deathmatch/tdm/de_dust2/long
	name = "long"

/obj/effect/landmark/deathmatch_player_spawn
	name = "Deathmatch Player Spawner"
	/// Team this spawn belongs to, used by Team Deathmatch. 0 means an open spawn
	/// that any mode and either team may use, so free-for-all maps do not need to
	/// be edited when they are picked for a team game.
	var/team = 0

/obj/effect/landmark/deathmatch_player_spawn/Initialize(mapload)
	. = ..()
	GLOB.deathmatch_player_spawns += src

/obj/effect/landmark/deathmatch_player_spawn/Destroy()
	GLOB.deathmatch_player_spawns -= src
	return ..()

/// Team spawn landmarks. They exist so a map can be set up in the map editor by
/// placing the landmark itself, without hand-typing `team = 1` or `team = 2`
/// into the variable list.
///
/// The literal 1/2 (instead of TDM_TEAM_ALPHA/TDM_TEAM_BRAVO) is deliberate:
/// deathmatch_mapping.dm is included before deathmatch_team.dm, so those macros
/// are not defined yet at this point in the file.
/obj/effect/landmark/deathmatch_player_spawn/terrorist
	name = "Deathmatch Terrorist Spawner"
	team = 1

/obj/effect/landmark/deathmatch_player_spawn/counter_terrorist
	name = "Deathmatch Counter-Terrorist Spawner"
	team = 2
