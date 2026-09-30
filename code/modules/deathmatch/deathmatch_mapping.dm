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
/// base_lighting_alpha), so tiles in this subtype are lit by the map template
/// that loads them: /datum/map_template/deathmatch/turn_on_the_lights() drops
/// emitters once the map is in place. Only a handful of maps actually use it.
///
/// The lighting is deliberately not done here. An /area in this codebase is one
/// object shared by every tile of its type in the world, not one per map load,
/// so a flag or a cache kept on the area would survive the arena it belonged to
/// and either leave the second game on a map dark or light somebody else's
/// turfs.
 /area/deathmatch/fullbright
	name = "Deathmatch Arena (Lit)"

/obj/effect/light_emitter/deathmatch
	name = "Deathmatch arena light"
	icon = null
	// Emitters have no light map data of their own, this is the light they cast.
	set_luminosity = 7
	set_cap = 2

/obj/effect/landmark/deathmatch_player_spawn
	name = "Deathmatch Player Spawner"

/obj/effect/landmark/deathmatch_player_spawn/Initialize(mapload)
	. = ..()
	GLOB.deathmatch_player_spawns += src

/obj/effect/landmark/deathmatch_player_spawn/Destroy()
	GLOB.deathmatch_player_spawns -= src
	return ..()
