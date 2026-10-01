// Deathmatch arena map templates.
//
// None of these maps is part of a z-level at compile time. They are loaded on
// demand into a reserved block of the shared virtual reality z-level, which is
// what /datum/deathmatch_arena does. Keep them out of tgstation.dme: a ticked
// map is loaded for the whole round and costs 150-250 MB by itself.

/**
 * Every arena map, instanced on first call.
 *
 * Nothing in this codebase instances /datum/map_template subtypes by itself:
 * SSmapping.preloadTemplates() only scans _maps/templates/ for .dmm files and
 * preloads ruin/shuttle/shelter subtypes by hand. Without this getter the mode
 * picker and the admin verb would both report that no deathmatch maps are
 * compiled in. It also keeps five .dmm headers from being parsed during init
 * for a game nobody plays.
 *
 * Always use this instead of touching GLOB.deathmatch_maps directly.
 */
/proc/get_deathmatch_templates()
	if(length(GLOB.deathmatch_maps))
		return GLOB.deathmatch_maps
	for(var/map_type as anything in GLOB.deathmatch_template_types)
		var/datum/map_template/deathmatch/new_map = new(map_type)
		if(isnull(new_map))
			log_game("Deathmatch: could not instantiate the arena map [map_type].")
	return GLOB.deathmatch_maps

/datum/map_template/deathmatch
	/// Name shown in the mode selection list.
	var/display_name = "Deathmatch"
	/// One line blurb for the mode selection list.
	var/description = "No description."
	/// Player counts the map is balanced for, the lobby uses these.
	var/min_players = 2
	var/max_players = 2
	/// Loadout every player on this map spawns with. See deathmatch_loadouts.dm.
	var/loadout = /datum/outfit/deathmatch_loadout/bare

	/// The map is complete by the time this runs, so the freshly loaded bounds
	/// can be walked turfs and lit.
	on_map_loaded(z, list/bounds)
		. = ..()
		turn_on_the_lights(bounds)

/datum/map_template/deathmatch/proc/turn_on_the_lights(list/bounds)
	/// BlueMoon dropped area level fullbright (the 516 lighting rework removed
	/// base_lighting_alpha), so the freshly loaded bounds have to be lit from
	/// here. Doing it from the template, over the bounds of this load only, is
	/// what keeps two arenas up at the same time from lighting each other's
	/// turfs: /area is one object shared by every tile of its type in the world,
	/// so a per area flag or cache would outlive the arena it belonged to.
	///
	/// This lights every turf in the bounds, not a subset. An earlier version
	/// gated it on /area/deathmatch/fullbright, but no .dmm in this codebase
	/// carries an "area" key - 0 of them did - so that check could never pass and
	/// arenas loaded unlit. Do not reintroduce an area based gate here.
	if(!bounds)
		return 0
	var/turf/bottom_left = locate(bounds[MAP_MINX], bounds[MAP_MINY], bounds[MAP_MINZ])
	var/turf/top_right = locate(bounds[MAP_MAXX], bounds[MAP_MAXY], bounds[MAP_MAXZ])
	if(!bottom_left || !top_right)
		return 0

	/// Distance between two emitters, in tiles. Lower is smoother and costlier.
	var/light_spacing = 7
	var/light_radius = 7
	var/light_cap = 2

	var/turf/last_lit
	var/counted = 0
	for(var/turf/turf_to_light as anything in block(bottom_left, top_right))
		if(last_lit && (abs(turf_to_light.x - last_lit.x) < light_spacing) && (abs(turf_to_light.y - last_lit.y) < light_spacing))
			continue
		var/obj/effect/light_emitter/deathmatch/emitter = new(turf_to_light)
		emitter.set_light(light_radius, light_cap)
		last_lit = turf_to_light
		counted++
	return counted

/datum/map_template/deathmatch/New(path = null, rename = null, cache = FALSE)
	. = ..()
	// Guarded because get_deathmatch_templates() can be reached from several
	// places at once, and a second copy would be a second map to keep in sync.
	if(!(src in GLOB.deathmatch_maps))
		LAZYADD(GLOB.deathmatch_maps, src)

/datum/map_template/deathmatch/secu_ring
	name = "Deathmatch - SecuRing"
	display_name = "SecuRing"
	description = "Presenting the Security Ring, ever wanted to shoot people with disablers? Well now you can."
	mappath = "_maps/deathmatch/secu_ring.dmm"
	min_players = 2
	max_players = 4
	loadout = /datum/outfit/deathmatch_loadout/disabler

/datum/map_template/deathmatch/instagib
	name = "Deathmatch - Instagib"
	display_name = "Instagib"
	description = "EVERYONE GETS AN INSTAKILL RIFLE!"
	mappath = "_maps/deathmatch/instagib.dmm"
	min_players = 2
	max_players = 8
	loadout = /datum/outfit/deathmatch_loadout/laser

/datum/map_template/deathmatch/final_destination
	name = "Deathmatch - Final Destination"
	display_name = "Final Destination"
	description = "1v1v1v1, 1 Stock, Final Destination."
	mappath = "_maps/deathmatch/finaldestination.dmm"
	min_players = 2
	max_players = 8
	loadout = /datum/outfit/deathmatch_loadout/sidearm

/datum/map_template/deathmatch/sniper_elite
	name = "Deathmatch - Sniper Elite"
	display_name = "Sniper Elite"
	description = "Sound of gunfire and screaming people make my day."
	mappath = "_maps/deathmatch/sniper_elite.dmm"
	min_players = 2
	max_players = 8
	loadout = /datum/outfit/deathmatch_loadout/laser

/datum/map_template/deathmatch/shooting_range
	name = "Deathmatch - Shooting Range"
	display_name = "Shooting Range"
	description = "A simple room with a bunch of wooden barricades."
	mappath = "_maps/deathmatch/shooting_range.dmm"
	min_players = 2
	max_players = 6
	loadout = /datum/outfit/deathmatch_loadout/laser
