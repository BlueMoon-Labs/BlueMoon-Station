// Deathmatch modifiers: rules a host bolts onto a game before it starts.
//
// Ported from the newTG Deathmatch module, cut down hard. newTG leans on
// /mob/innate_traits, and this fork has no such var - there is no add_trait(),
// has_trait() or remove_trait() here at all - so a literal port of its thirty
// modifiers would not compile. Everything below is built out of what this codebase
// actually has: /mob/maxHealth and /mob/health, /datum/movespeed_modifier via
// add_movespeed_modifier(), and lobby-level hooks.
//
// That is why the list is short. The UI does not care: it walks
// get_deathmatch_modifiers() and renders one checkbox per entry, so a modifier is
// written, then usable. Add more here as the underlying systems allow.

GLOBAL_LIST_INIT(deathmatch_modifiers, list())

/**
 * Every modifier subtype, by type path, built on first use.
 *
 * Populated lazily rather than by hand so that adding a subtype to this file is
 * the only step between writing a modifier and being able to select it in the UI.
 */
proc/get_deathmatch_modifiers()
	if(length(GLOB.deathmatch_modifiers))
		return GLOB.deathmatch_modifiers
	for(var/item in subtypesof(/datum/deathmatch_modifier))
		GLOB.deathmatch_modifiers += item
	return GLOB.deathmatch_modifiers

/**
 * Resolves a catalogue entry to a live instance, or null.
 *
 * The catalogue is built from subtypesof(), which hands out type paths, and the
 * window sends those paths back through TGUI as plain strings. Both a raw path
 * and a string can end up cast into a /datum var, and calling a proc on that
 * mixed value dies at runtime with "Cannot execute /datum/... (...).selectable()".
 * So the path is resolved with text2path() and instantiated by hand; only a real
 * instance ever leaves here.
 */
proc/get_deathmatch_modifier_instance(modifier_path)
	var/modifier_type = ispath(modifier_path) ? modifier_path : text2path(modifier_path)
	if(!(modifier_type in subtypesof(/datum/deathmatch_modifier)))
		return null
	return new modifier_type()

/datum/deathmatch_modifier
	/// Shown in the modifier list.
	var/name = "Modifier"
	/// Tooltip. Why somebody would want this, not what it does.
	var/description = ""
	/// Arenas this modifier cannot be used on, by map template type.
	var/list/blacklisted_maps = list()
	/// Set on modifiers that change the lobby rather than the players. Those are
	/// never switched off by a map change and never re-rolled by `random`, because
	/// they are the reason `random` is able to pick anything at all.
	var/lobby_wide = FALSE

/**
 * Whether the host may turn this on right now.
 *
 * lobby is the /datum/deathmatch_lobby. The base refuses nothing; subtypes that
 * depend on the map check it here rather than failing later at game start, so the
 * checkbox greys out instead of the game breaking.
 *
 * The argument is called `lobby` and not `src` on purpose. `src` is a BYOND keyword
 * meaning the datum the proc was called on, and using it as an argument name is
 * accepted by the compiler but produces a proc with an empty argument list - so the
 * call site, which passes the lobby, dies at runtime with "Cannot execute
 * /datum/deathmatch_modifier/....selectable()".
 */
/datum/deathmatch_modifier/proc/selectable(datum/deathmatch_lobby/lobby)
	if(length(blacklisted_maps) && lobby?.template in blacklisted_maps)
		return FALSE
	return TRUE

/// Called on the lobby when this modifier is switched on.
/datum/deathmatch_modifier/proc/on_select(lobby)

/// Called on the lobby when this modifier is switched off.
/datum/deathmatch_modifier/proc/on_unselect(lobby)

/// Called on the lobby if the host changes the arena while this is on, so a
/// modifier the new map forbids can step itself out instead of surviving onto an
/// arena it was never balanced for.
/datum/deathmatch_modifier/proc/on_map_changed(lobby)
	if(!selectable(lobby))
		on_unselect(lobby)

/// Called on the lobby as the arena finishes loading. Lobby-wide work belongs
/// here; per-player work belongs in apply().
/datum/deathmatch_modifier/proc/on_start_game(lobby)

/// Called on the lobby as the game ends, before the arena is deleted.
/datum/deathmatch_modifier/proc/on_end_game(lobby)

/**
 * Applies to one player, once, as their arena body is built.
 *
 * Nothing here may assume the player stays alive: this runs from spawn_player(),
 * before the body is fully handed over, and a modifier that throws leaves the game
 * one player down with no explanation in chat.
 *
 * target is typed /mob/living because a deathmatch player is always a body, never
 * a ghost, by the time this is reached.
 */
/datum/deathmatch_modifier/proc/apply(mob/living/target, datum/deathmatch_lobby/lobby)

//
// Health. The cheapest thing to add and the reason most hosts reach for a
// modifier at all.
//

/datum/deathmatch_modifier/health
	name = "Double Health"
	description = "Two hearts instead of one."
	var/multiplier = 2

/datum/deathmatch_modifier/health/apply(mob/living/target, datum/deathmatch_lobby/lobby)
	if(isnull(target) || QDELETED(target))
		return
	target.maxHealth = target.maxHealth * multiplier
	// Scaled after maxHealth on purpose: healing to the new maximum would hand out
	// the extra hit for free, and the point of the modifier is that the extra hit
	// has to be earned.
	target.health = target.health * multiplier

/datum/deathmatch_modifier/health/half
	name = "Half Health"
	description = "One hit and you are down. Bring friends."
	multiplier = 0.5

/datum/deathmatch_modifier/health/triple
	name = "Triple Health"
	description = "An enormous mistake. Probably the funniest modifier here."
	multiplier = 3

//
// Movement, via the movespeed system this codebase actually has.
//

/datum/deathmatch_modifier/snail_crawl
	name = "Snail Crawl"
	description = "You are slow. Deliberately, unendurably slow."
	var/extra_slowdown = 1

/datum/deathmatch_modifier/snail_crawl/apply(mob/living/target, datum/deathmatch_lobby/lobby)
	if(isnull(target) || QDELETED(target))
		return
	target.add_movespeed_modifier(/datum/movespeed_modifier/deathmatch_snail)

/datum/movespeed_modifier/deathmatch_snail
	multiplicative_slowdown = 1

/datum/deathmatch_modifier/speed_demon
	name = "Speed Demon"
	description = "You move as though the floor were lava."
	var/boost = 5

/datum/deathmatch_modifier/speed_demon/apply(mob/living/target, datum/deathmatch_lobby/lobby)
	if(isnull(target) || QDELETED(target))
		return
	target.add_movespeed_modifier(/datum/movespeed_modifier/deathmatch_speed_demon)

/datum/movespeed_modifier/deathmatch_speed_demon
	max_tiles_per_second_boost = 5

//
// Lobby-wide. These rewrite the game rather than the bodies in it.
//

/**
 * Drops the map's loadout rules, so every kit in the module becomes selectable.
 *
 * The one modifier that is genuinely about the lobby, and the reason a host ever
 * opens the modifier menu: most arenas are balanced around two or three kits and
 * the fun one is not on the list.
 */
/datum/deathmatch_modifier/any_loadout
	name = "Any Loadout"
	description = "Drop the map's loadout rules: every kit in the game becomes available."
	lobby_wide = TRUE

/**
 * Rolls a handful of modifiers when the game starts, instead of the host picking
 * them one by one.
 *
 * lobby_wide, so that rolling never rolls another randomiser, and so that a map
 * change cannot switch it out from under a game that is already running on it.
 */
/datum/deathmatch_modifier/random
	name = "Random Modifiers"
	description = "Roll three to five modifiers when the game starts. You brought this on yourself."
	lobby_wide = TRUE
	var/least = 3
	var/most = 5

/datum/deathmatch_modifier/random/on_start_game(datum/deathmatch_lobby/lobby)
	if(isnull(lobby))
		return
	// Built from the catalogue rather than a hand-written list, so a modifier added
	// to this file is eligible for the roll the day it is written.
	var/list/pool = list()
	for(var/modifier_path as anything in get_deathmatch_modifiers())
		var/datum/deathmatch_modifier/modifier = get_deathmatch_modifier_instance(modifier_path)
		// Never roll another randomiser: that is a loop, not a surprise.
		if(modifier?.type == /datum/deathmatch_modifier/random)
			continue
		// Already on, so rolling it again changes nothing and wastes a slot.
		if(modifier_path in lobby.selected_modifiers)
			continue
		if(!modifier.selectable(lobby))
			continue
		pool += modifier_path
	if(!length(pool))
		return
	// Cast, not a bare `var/instance = src`: the codebase is in strict mode, so
	// reading a var off an untyped one is a compile error rather than a runtime one.
	var/datum/deathmatch_modifier/random/instance = src
	var/how_many = clamp(rand(instance.least, instance.most), 1, length(pool))
	// A while loop rather than `for(1..how_many)`: the count comes out of clamp(),
	// and this compiler will not take a range built from one.
	while(how_many > 0)
		var/rolled = pool[rand(1, length(pool))]
		// Drawn by index and then removed, so the same modifier cannot be rolled
		// twice out of one set.
		pool -= rolled
		lobby.set_modifier(rolled, TRUE)
		how_many--
