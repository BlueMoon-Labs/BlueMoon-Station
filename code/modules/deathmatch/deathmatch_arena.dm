// Loading a deathmatch arena into the world, and taking it back out again.
//
// BlueMoon cannot delete a z-level, and a new one costs 150-250 MB, so arenas
// are not z-levels of their own. Every arena is a rectangular block reserved on
// one shared virtual reality z-level, which is what makes unloading an arena
// cheap: every atom on the reserved turfs is deleted and the block is handed
// back to the reservation pool as empty space.

/// The arena maps all get this. A one tile indestructible ring keeps players in
/// and hides the void (and any other arena) from them.
/// The interior is plain space because the map is loaded on top of it.
/datum/turf_reservation/deathmatch
	turf_type = /turf/open/space
	borderturf = /turf/closed/indestructible/riveted

/datum/deathmatch_arena
	/// The map this arena was built from.
	var/datum/map_template/deathmatch/template
	/// The reserved block the map sits on, NULL while the arena is unloaded.
	var/datum/turf_reservation/reservation
	/// Bounds of the loaded map, [min x, min y, min z, max x, max y, max z].
	var/list/bounds
	/// z-level the arena is on. Not the same as arena.turf.z in any way, it is
	/// the number to hand to SSmapping when touching the level.
	var/z
	/// /obj/effect/landmark/deathmatch_player_spawn inside bounds.
	var/list/spawns = list()

/datum/deathmatch_arena/New(template)
	src.template = template

/datum/deathmatch_arena/proc/is_loaded()
	return !isnull(reservation)

/datum/deathmatch_arena/proc/get_name()
	return template?.display_name || "Deathmatch arena"

/datum/deathmatch_arena/proc/to_string()
	return "[get_name()] on z[z]"

/**
 * Reserves a block on the shared virtual reality z-level and loads the map into
 * it. Returns the arena on success, FALSE on failure.
 *
 * Every failure path is logged: this is called from a player facing lobby, and
 * a silent FALSE there is impossible to debug.
 */
/datum/deathmatch_arena/proc/load_arena()
	if(is_loaded())
		return FALSE
	if(isnull(template))
		log_game("Deathmatch: [src] has no map template, refusing to load.")
		return FALSE
	// The map is loaded into the reservation, so the block has to fit the map
	// plus a one tile border ring on every side.
	var/list/map_size = template.get_size() // sizes the template if nothing has yet
	var/map_width = map_size[1]
	var/map_height = map_size[2]
	if(map_width < 1 || map_height < 1)
		log_game("Deathmatch: [template] has no usable bounds, refusing to load.")
		return FALSE
	if(template.zdepth != 1)
		log_game("Deathmatch: [template] is [template.zdepth] z-levels deep, only single level maps are supported.")
		return FALSE

	var/arena_z = get_deathmatch_z()
	if(!arena_z)
		log_game("Deathmatch: could not get a virtual reality z-level for [template].")
		return FALSE

	var/datum/turf_reservation/block = SSmapping.RequestBlockReservation(\
		map_width + 2, map_height + 2, arena_z, /datum/turf_reservation/deathmatch)
	if(isnull(block))
		log_game("Deathmatch: no free [map_width + 2]x[map_height + 2] reservation left for [template].")
		return FALSE

	// Shift by one so the map fills the interior and the border ring is left
	// standing around it.
	var/turf/placement = locate(block.bottom_left_coords[1] + 1, block.bottom_left_coords[2] + 1, block.bottom_left_coords[3])
	if(isnull(placement))
		qdel(block)
		log_game("Deathmatch: reservation for [template] handed back broken coordinates.")
		return FALSE

	// Only now do we own the block, so a failed load must not leave it behind.
	reservation = block
	z = arena_z
	var/list/loaded_bounds = template.load(placement, FALSE, SOUTH, FALSE)
	if(isnull(loaded_bounds))
		log_game("Deathmatch: [template] failed to load, releasing the reservation.")
		unload_arena(TRUE)
		return FALSE

	bounds = loaded_bounds
	collect_spawns()
	GLOB.deathmatch_arenas += src
	log_game("Deathmatch: [to_string()] loaded at [bounds[MAP_MINX]],[bounds[MAP_MINY]],[z] with [length(spawns)] spawn(s).")
	return src

/// Picks up the landmarks the map dropped, so that a second arena on the same
/// z-level never hands out a spawn belonging to the first one.
/datum/deathmatch_arena/proc/collect_spawns()
	spawns = list()
	if(isnull(bounds))
		return spawns
	for(var/obj/effect/landmark/deathmatch_player_spawn/spawn_point as anything in GLOB.deathmatch_player_spawns)
		var/turf/spawn_turf = get_turf(spawn_point)
		if(isnull(spawn_turf))
			continue
		if(spawn_turf.z != z)
			continue
		if(spawn_turf.x < bounds[MAP_MINX] || spawn_turf.x > bounds[MAP_MAXX])
			continue
		if(spawn_turf.y < bounds[MAP_MINY] || spawn_turf.y > bounds[MAP_MAXY])
			continue
		spawns += spawn_point
	return spawns

/// A free spawn inside this arena, or the arena's own turf if the map somehow
/// has no landmarks, so that a game can always be started.
/datum/deathmatch_arena/proc/get_spawn_point()
	if(length(spawns))
		return pick(spawns)
	if(isnull(bounds))
		return null
	return locate(bounds[MAP_MINX], bounds[MAP_MINY], z)

/// True if somebody is standing in the arena right now. Unloading under a
/// player's feet would delete them along with the map.
/datum/deathmatch_arena/proc/occupants()
	var/list/found = list()
	if(isnull(reservation))
		return found
	for(var/turf/arena_turf as anything in reservation.reserved_turfs)
		for(var/mob/living/mob_in_arena in arena_turf)
			found += mob_in_arena
	return found

/**
 * Deletes the arena and hands its block back to the reservation pool.
 *
 * force = TRUE skips the "somebody is still inside" check, for a load that just
 * failed and has to clean up after itself.
 */
/datum/deathmatch_arena/proc/unload_arena(force = FALSE)
	if(!is_loaded())
		return FALSE
	var/stuck = occupants()
	if(length(stuck) && !force)
		return FALSE

	// Not /turf.empty(): it keeps landmarks, docks and mobs on purpose, and the
	// landmarks are the arena's own data. The border ring has no contents.
	for(var/turf/arena_turf as anything in reservation.reserved_turfs)
		for(var/atom/arena_atom as anything in arena_turf.contents.Copy())
			qdel(arena_atom)

	// This reclaims the turfs and turns them back into space.
	qdel(reservation)
	reservation = null
	bounds = null
	spawns = list()
	GLOB.deathmatch_arenas -= src
	log_game("Deathmatch: [to_string()] unloaded.")
	return TRUE

/// Names of the mobs blocking an unload, for the admin message.
/datum/deathmatch_arena/proc/occupant_names()
	var/list/names = list()
	for(var/mob/living/mob_in_arena in occupants())
		names += mob_in_arena.real_name || mob_in_arena.name
	return names

/**
 * The z-level shared by all deathmatch arenas, created on first use.
 *
 * Deliberately not the shuttle transit level: that one shares its z with every
 * shuttle in the game and its contents are not ours to delete.
 */
/proc/get_deathmatch_z()
	for(var/reserved_z in SSmapping.levels_by_trait(ZTRAIT_RESERVED))
		if(SSmapping.level_trait(reserved_z, ZTRAIT_VIRTUAL_REALITY))
			return reserved_z

	var/datum/space_level/arena_level = SSmapping.add_new_zlevel("Deathmatch Arenas", \
		list(ZTRAIT_RESERVED = TRUE, ZTRAIT_VIRTUAL_REALITY = TRUE, ZTRAIT_AWAY = TRUE))
	// Marks every turf of the new level as reservable. Nothing can be placed
	// here outside of an arena, so there is no old content to clear.
	SSmapping.initialize_reserved_level(arena_level.z_value)
	log_game("Deathmatch: created virtual reality z-level [arena_level.z_value] for arenas.")
	return arena_level.z_value

/datum/admins/proc/deathmatch_load_arena()
	set category = "Deathmatch"
	set name = "Deathmatch: Load Arena"
	set desc = "Load a deathmatch arena onto the virtual reality z-level."
	if(!check_rights(R_ADMIN))
		return

	var/list/choices = list()
	for(var/datum/map_template/deathmatch/arena_map as anything in get_deathmatch_templates())
		var/size = arena_map.get_size()
		choices["[arena_map.display_name] ([size[1]]x[size[2]])"] = arena_map
	if(!length(choices))
		to_chat(usr, span_danger("No deathmatch maps are compiled in."))
		return

	var/picked = input("Arena to load:", "Deathmatch", null) as null|anything in choices
	if(isnull(picked))
		return

	var/datum/deathmatch_arena/arena = new(choices[picked])
	if(arena.load_arena())
		to_chat(usr, span_adminnotice("Loaded [arena.to_string()]."))
	else
		to_chat(usr, span_danger("Could not load [arena.get_name()], see the game log."))
	log_admin("Deathmatch: [key_name(usr)] tried to load [arena.get_name()]. Result: [arena.is_loaded() ? "loaded" : "failed"].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Deathmatch: Load Arena")

/datum/admins/proc/deathmatch_unload_arena()
	set category = "Deathmatch"
	set name = "Deathmatch: Unload Arena"
	set desc = "Delete a loaded deathmatch arena and free its reservation."
	if(!check_rights(R_ADMIN))
		return

	var/list/loaded_arenas = list()
	for(var/datum/deathmatch_arena/arena as anything in GLOB.deathmatch_arenas)
		loaded_arenas["[arena.to_string()]"] = arena
	if(!length(loaded_arenas))
		to_chat(usr, span_danger("No deathmatch arena is loaded."))
		return

	var/picked = input("Arena to unload:", "Deathmatch", null) as null|anything in loaded_arenas
	if(isnull(picked))
		return

	var/datum/deathmatch_arena/arena = loaded_arenas[picked]
	if(arena.unload_arena())
		to_chat(usr, span_adminnotice("Unloaded [arena.get_name()]."))
	else
		to_chat(usr, span_danger("Players are still inside [arena.to_string()]: [english_list(arena.occupant_names(), "nobody")]."))
	log_admin("Deathmatch: [key_name(usr)] tried to unload [arena.get_name()]. Result: [!arena.is_loaded() ? "unloaded" : "failed"].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Deathmatch: Unload Arena")
