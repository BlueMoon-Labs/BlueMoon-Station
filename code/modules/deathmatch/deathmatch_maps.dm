// Deathmatch arena map templates.
//
// None of these maps is part of a z-level at compile time. They are loaded on
// demand into a reserved block of the shared virtual reality z-level, which is
// what /datum/deathmatch_arena does. Keep them out of tgstation.dme: a ticked
// map is loaded for the whole round and costs 150-250 MB by itself.

/**
 * Every arena map, instanced on first call.
 *
 * These are deliberately not registered with SSmapping.preloadTemplates(),
 * which only scans _maps/templates/ and would parse all five .dmm headers
 * during init for a game nobody plays. Enumerated with subtypesof() the way the
 * ruin, shuttle and shelter loaders do, so a new arena map needs no bookkeeping
 * here, and gated on mappath so the abstract base type is skipped.
 *
 * Always use this instead of touching GLOB.deathmatch_maps directly.
 */
/proc/get_deathmatch_templates()
	if(length(GLOB.deathmatch_maps))
		return GLOB.deathmatch_maps
	for(var/item in subtypesof(/datum/map_template/deathmatch))
		var/datum/map_template/deathmatch/arena_type = item
		if(!(initial(arena_type.mappath)))
			continue
		// new arena_type() with a space, never new(arena_type). The
		// parenthesised form instantiates the *declared* type of the
		// assignment and hands the first argument to New() as `path`, so the
		// parent's `mappath = path` pointed preload_size() at a file called
		// "/datum/map_template/deathmatch/..." and every arena died on
		// "invalid filename" the first time the sleeper UI asked for a list.
		var/datum/map_template/deathmatch/arena_map = new arena_type()
		if(isnull(arena_map))
			log_game("Deathmatch: could not instantiate the arena map [item].")
	return GLOB.deathmatch_maps

/**
 * Every loadout in the module, as type paths, ordered by their display name.
 *
 * This is the `any_loadout` modifier's list: the modes themselves pick from
 * /datum/map_template/deathmatch/proc/get_loadouts() so that an arena is balanced
 * around two or three kits, and this is everything else in the game.
 *
 * Sorted because a list built from subtypesof() comes back in definition order,
 * which puts a new loadout wherever its file happened to sit. Hosts pick kits out
 * of a dropdown, and a dropdown that reorders itself every time somebody adds a
 * kit is unusable.
 */
proc/get_deathmatch_loadout_paths()
	var/list/paths = list()
	for(var/item in subtypesof(/datum/outfit/vr/deathmatch_loadout))
		if(item == /datum/outfit/vr/deathmatch_loadout)
			continue
		paths += item
	return sort_list(paths, GLOBAL_PROC_REF(cmp_deathmatch_loadout_path))

/// Display name for a loadout type path, for sorting a list of them. Both sides
/// are compared on the name the player sees, not on the path, or the picker would be
/// ordered by /datum/outfit/vr/deathmatch_loadout/brawler rather than by "Brawler".
proc/cmp_deathmatch_loadout_path(path_a, path_b)
	var/datum/outfit/vr/deathmatch_loadout/kit_a = get_deathmatch_loadout(path_a)
	var/datum/outfit/vr/deathmatch_loadout/kit_b = get_deathmatch_loadout(path_b)
	var/name_a = isnull(kit_a) ? "zzzz" : kit_a.get_display_name()
	var/name_b = isnull(kit_b) ? "zzzz" : kit_b.get_display_name()
	return name_a == name_b ? 0 : (name_a < name_b ? -1 : 1)

/**
 * A deathmatch loadout by its type path.
 *
 * Deliberately not cached and not read out of a list of live /datum/outfit
 * instances. Comparing a path the browser sent back against loadout.type in such
 * a list came up empty for every single loadout, which is why picking one reported
 * it as unknown no matter which one it was. Comparing against subtypesof() has no
 * such indirection: the string either is one of these paths or it is not.
 *
 * The base type is rejected as well as NULL. It is the abstract parent every
 * subtype inherits `name` from, so on its own it is not a kit anybody can equip,
 * and instantiating it would hand build_virtual_character() an outfit with
 * nothing in it.
 */
proc/get_deathmatch_loadout(path)
	if(!ispath(path))
		return null
	if(path == /datum/outfit/vr/deathmatch_loadout)
		return null
	if(!(path in subtypesof(/datum/outfit/vr/deathmatch_loadout)))
		return null
	// new <var>() with a space, never new(<var>). The parenthesised form builds
	// the declared type of the assignment instead of the type the variable holds.
	var/loadout_type = path
	var/datum/outfit/vr/deathmatch_loadout/loadout = new loadout_type()
	if(isnull(loadout))
		return null
	return loadout

/datum/map_template/deathmatch
	/// Name shown in the mode selection list.
	var/display_name = "Deathmatch"
	/// One line blurb for the mode selection list.
	var/description = "No description."
	/// Player counts the map is balanced for, the lobby uses these.
	var/min_players = 2
	var/max_players = 2
	/// Loadout every player on this map spawns with. See deathmatch_loadouts.dm.
	/// A type path, not a datum: this is handed to build_virtual_character(),
	/// which instantiates it, the same way /obj/machinery/vr_sleeper passes
	/// vr_outfit.
	var/loadout = /datum/outfit/vr/deathmatch_loadout/bare
	/// The other loadouts a player may pick for this map, as type paths.
	///
	/// Deliberately per map and not one global list. Offering the sniper rifle on
	/// the Security Ring lets a player walk into an arena balanced around
	/// disablers holding the one weapon in the game that punishes cover, and the
	/// map cannot be balanced for five kits at once. The mode's own `loadout` is
	/// always offered on top of these, so it does not have to be repeated here.
	var/list/loadout_options = list()

	/**
	 * The loadouts this mode offers, in picker order, as datums.
	 *
	 * The map's default kit first, then loadout_options, with the default
	 * dropped from the tail if a map lists it redundantly. Resolved through
	 * get_deathmatch_loadout(), so an option naming a path that does not exist is
	 * skipped instead of handing the outfit code a null to equip.
	 */
	proc/get_loadouts()
		var/list/result = list()
		var/datum/outfit/vr/deathmatch_loadout/default = get_deathmatch_loadout(loadout)
		if(!isnull(default))
			result += default
		for(var/option_path in loadout_options)
			var/datum/outfit/vr/deathmatch_loadout/option = get_deathmatch_loadout(option_path)
			if(isnull(option) || (option in result))
				continue
			result += option
		return result

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
	loadout = /datum/outfit/vr/deathmatch_loadout/officer

/datum/map_template/deathmatch/instagib
	name = "Deathmatch - Instagib"
	display_name = "Instagib"
	description = "EVERYONE GETS AN INSTAKILL RIFLE!"
	mappath = "_maps/deathmatch/instagib.dmm"
	min_players = 2
	max_players = 8
	loadout = /datum/outfit/vr/deathmatch_loadout/instakill

/datum/map_template/deathmatch/final_destination
	name = "Deathmatch - Final Destination"
	display_name = "Final Destination"
	description = "1v1v1v1, 1 Stock, Final Destination."
	mappath = "_maps/deathmatch/finaldestination.dmm"
	min_players = 2
	max_players = 8
	loadout = /datum/outfit/vr/deathmatch_loadout/captain
	loadout_options = list(
		/datum/outfit/vr/deathmatch_loadout/head_of_security,
		/datum/outfit/vr/deathmatch_loadout/traitor,
		/datum/outfit/vr/deathmatch_loadout/nukie,
		/datum/outfit/vr/deathmatch_loadout/tider,
		/datum/outfit/vr/deathmatch_loadout/abductor,
		/datum/outfit/vr/deathmatch_loadout/master_chef,
		/datum/outfit/vr/deathmatch_loadout/clown_commando,
		/datum/outfit/vr/deathmatch_loadout/mime,
		/datum/outfit/vr/deathmatch_loadout/pete,
	)

/datum/map_template/deathmatch/sniper_elite
	name = "Deathmatch - Sniper Elite"
	display_name = "Sniper Elite"
	description = "Sound of gunfire and screaming people make my day."
	mappath = "_maps/deathmatch/sniper_elite.dmm"
	min_players = 2
	max_players = 8
	loadout = /datum/outfit/vr/deathmatch_loadout/sniper

/datum/map_template/deathmatch/shooting_range
	name = "Deathmatch - Shooting Range"
	display_name = "Shooting Range"
	description = "A simple room with a bunch of wooden barricades."
	mappath = "_maps/deathmatch/shooting_range.dmm"
	min_players = 2
	max_players = 6
	loadout = /datum/outfit/vr/deathmatch_loadout/sidearm
	loadout_options = list(
		/datum/outfit/vr/deathmatch_loadout/butt_naked,
		/datum/outfit/vr/deathmatch_loadout/brawler,
	)
