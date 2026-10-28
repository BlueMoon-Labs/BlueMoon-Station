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
// Only used by _maps/TDM/de_dust2/de_dust2.dmm. They exist as separate types so
// that an admin can point at a part of the map and the map itself shows which
// callout it is, and so the map does not have to fall back on one giant area.
// All of them inherit has_gravity, requires_power and the area flags from
// /area/deathmatch above.
/area/deathmatch/tdm
	name = "Team Deathmatch"

/area/deathmatch/tdm/de_dust2/t_spawn
	name = "de_dust2 - T Spawn"

/area/deathmatch/tdm/de_dust2/ct_spawn
	name = "de_dust2 - CT Spawn"

/area/deathmatch/tdm/de_dust2/a_site
	name = "de_dust2 - Bombsite A"

/area/deathmatch/tdm/de_dust2/b_site
	name = "de_dust2 - Bombsite B"

/area/deathmatch/tdm/de_dust2/mid
	name = "de_dust2 - Mid"

/area/deathmatch/tdm/de_dust2/long_a
	name = "de_dust2 - Long A"

/area/deathmatch/tdm/de_dust2/outside_long
	name = "de_dust2 - Outside Long"

/area/deathmatch/tdm/de_dust2/pit
	name = "de_dust2 - Pit"

/area/deathmatch/tdm/de_dust2/a_short
	name = "de_dust2 - A Short"

/area/deathmatch/tdm/de_dust2/catwalk
	name = "de_dust2 - Catwalk"

/area/deathmatch/tdm/de_dust2/tunnels
	name = "de_dust2 - Lower Tunnels"

/area/deathmatch/tdm/de_dust2/upper_tunnels
	name = "de_dust2 - Upper Tunnels"

/area/deathmatch/tdm/de_dust2/b_doors
	name = "de_dust2 - B Doors"

/area/deathmatch/tdm/de_dust2/catacombs
	name = "de_dust2 - Catacombs"

/area/deathmatch/tdm/de_dust2/underground
	name = "de_dust2 - Underground"

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
