/area/deathmatch
	name = "Deathmatch Arena"
	requires_power = FALSE
	area_flags = UNIQUE_AREA

/obj/effect/landmark/deathmatch_player_spawn
	name = "Deathmatch Player Spawner"

/obj/effect/landmark/deathmatch_player_spawn/Initialize(mapload)
	. = ..()
	GLOB.deathmatch_player_spawns += src

/obj/effect/landmark/deathmatch_player_spawn/Destroy()
	GLOB.deathmatch_player_spawns -= src
	return ..()