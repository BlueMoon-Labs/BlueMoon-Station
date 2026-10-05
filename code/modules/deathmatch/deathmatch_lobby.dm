// A deathmatch lobby: one host, one arena, everybody who joined.
//
// The host is an ordinary player who lay down in a /obj/machinery/vr_sleeper, so
// their real body stays on the station while
// /datum/component/virtual_reality moves their mind into an arena body. Guests
// join a lobby somebody else opened; they never open one themselves.
//
// When the last player is out the arena is deleted and its reservation handed
// back to SSmapping, which is the only reason this is cheap enough to run in a
// live round.

#define DM_LOBBY_WAITING 0
#define DM_LOBBY_RUNNING 1
#define DM_LOBBY_FINISHED 2

/// One participant, and the two mobs that participant is between.
/datum/deathmatch_player
	/// The lobby's key for them. Taken before the transfer, because the real body
	/// has no ckey by the time add_player() is done with it.
	var/ckey
	/// The mob they go back to, captured at join time. Looking it up from the mind
	/// later is not safe: the mind may have been transferred, and
	/// virtual_reality/quit() needs somewhere to put the ckey.
	var/mob/real_body
	/// The arena body the mind is driving, NULL until the match starts, and again
	/// once they are back.
	var/mob/living/vr_body
	/// The /obj/effect/landmark/deathmatch_player_spawn held for them, so two
	/// players are never sent in through the same door. See
	/// /datum/deathmatch_arena/proc/claim_spawn_point.
	var/spawn_landmark
	var/is_host = FALSE
	/// Loadout type path this player fights with, picked in the TGUI. NULL means
	/// the one the mode comes with. See deathmatch_loadouts.dm.
	var/loadout
	/// What the player list shows: their character name, or a marker for a guest.
	var/display_name
	/// Volunteer started the game: the host's Start button waits on these. Players
	/// who never touch the box are the reason this is opt-in rather than a rule
	/// that assumes "in the lobby" means "wants to play".
	var/is_ready = FALSE
	/// Watching instead of fighting. Observers are seated in the arena as ghosts so
	/// they can actually watch, which means they hold a spawn landmark and get a
	/// spot in the player table, but they never count as combatants: not towards
	/// the player minimum, not towards the cap, and not towards the win.
	var/is_observer = FALSE

/datum/deathmatch_lobby
	/// ckey of the player who opened this lobby. Key into GLOB.deathmatch_lobbies.
	var/host_key
	/// The host's real mob, so start() does not have to find them again.
	var/mob/host_body
	var/datum/map_template/deathmatch/template
	var/datum/deathmatch_arena/arena
	var/loadout
	/// list(/datum/deathmatch_player)
	var/list/players = list()
	/// list(/datum/deathmatch_modifier type paths) the host has switched on.
	/// Held by type path and not by datum so that on_map_changed() can compare
	/// against a modifier that a map change has just made illegal, and so the set
	/// survives the arena being deleted and rebuilt under the same lobby.
	var/list/selected_modifiers = list()
	var/state = DM_LOBBY_WAITING
	var/time_started
	/// A game cannot run forever: the host may have disconnected and left the
	/// remaining players with no way to end it.
	var/game_time = 8 MINUTES
	/// How often dead and abandoned arena bodies are swept up.
	var/reap_interval = 5 SECONDS

	// No cached /datum/tgui/ui here on purpose. There used to be one, and it was a
	// bug waiting for a second player: try_update_ui() never checks that the UI it is
	// handed belongs to the user asking, so a stored window meant the guest who joined
	// second got handed the host's. Every entry point now looks the window up per user
	// through SStgui.get_open_ui(user, src), which is keyed on both.

/datum/deathmatch_lobby/New(datum/map_template/deathmatch/map, mob/host, loadout = null)
	src.template = map
	src.loadout = loadout || map?.loadout
	src.arena = new(map)
	if(isnull(host))
		return
	src.host_key = host.ckey
	src.host_body = host

/datum/deathmatch_lobby/proc/to_string()
	return "[template?.display_name || "Deathmatch"] lobby (host [host_key], [player_count()] player(s))"

/datum/deathmatch_lobby/proc/is_finished()
	return state == DM_LOBBY_FINISHED

/// Players still holding an arena body. Guests use this to refuse a spot in a
/// full game, so a lobby whose players have all walked out is not full.
/datum/deathmatch_lobby/proc/player_count()
	return players.len

/// Everybody at the table, spectators included. This is the number the player
/// table shows.
/datum/deathmatch_lobby/proc/seat_count()
	return players.len

/// The people who are actually playing: everyone except the observers. The player
/// minimum and the cap are about this number, not about seat_count(), otherwise a
/// lobby of watchers would refuse to start a game.
/datum/deathmatch_lobby/proc/combatant_count()
	var/count = 0
	for(var/datum/deathmatch_player/player as anything in players)
		if(!player?.is_observer)
			count++
	return count

/datum/deathmatch_lobby/proc/observer_count()
	return players.len - combatant_count()

/// Players who said yes to starting, out of the fighters.
///
/// Observers are excluded outright rather than counted as ready. They are never asked,
/// so counting them would push the number past the number of people who actually
/// consented, and the window renders this against fighters.length - "3/2 ready".
/datum/deathmatch_lobby/proc/ready_count()
	var/count = 0
	for(var/datum/deathmatch_player/player as anything in players)
		if(player?.is_observer)
			continue
		if(player?.is_ready)
			count++
	return count

/datum/deathmatch_lobby/proc/is_full()
	return combatant_count() >= (template?.max_players || 2)

/datum/deathmatch_lobby/proc/player_keys()
	var/list/keys = list()
	for(var/datum/deathmatch_player/player as anything in players)
		keys += player.ckey
	return keys

/// What to call the host in public. Their character name: a ckey is not something
/// to broadcast to the whole server, and once the match starts it is also the name
/// the other players actually see standing in the arena.
///
/// Read off the waiting roster when the host has no arena body yet, which is the
/// case for every announcement a lobby makes before it starts.
/datum/deathmatch_lobby/proc/host_display_name()
	for(var/datum/deathmatch_player/player as anything in players)
		if(!player?.is_host)
			continue
		if(!isnull(player.vr_body) && !QDELETED(player.vr_body))
			return player.vr_body.name
		return player.display_name || host_key
	return host_key || "unknown"

/**
 * Opens the lobby: registers it, seats the host as its first player and tells
 * the server the game is looking for players. The arena is deliberately NOT
 * loaded here - people gather in the lobby first, and begin_match() is what
 * spends a map reservation on them.
 *
 * Returns TRUE once the lobby is open, FALSE (having cleaned up after itself) if
 * it cannot be.
 */
/datum/deathmatch_lobby/proc/open()
	if(state != DM_LOBBY_WAITING)
		return FALSE
	if(isnull(host_body) || QDELETED(host_body) || !host_key)
		log_game("Deathmatch: [to_string()] has no usable host.")
		return FALSE
	GLOB.deathmatch_lobbies += src
	if(isnull(join(host_body, null, TRUE)))
		log_game("Deathmatch: [to_string()] could not seat its host.")
		end_lobby()
		return FALSE

	announce()
	addtimer(CALLBACK(src, PROC_REF(reap_bodies)), reap_interval)
	log_game("Deathmatch: [to_string()] opened, waiting for [template.min_players] player(s).")
	return TRUE

/// How many more players this mode needs before the host is allowed to start it.
/// Counted over combatants, so a table of spectators reads as the empty table it
/// is.
/datum/deathmatch_lobby/proc/players_needed()
	return max(0, (template?.min_players || 2) - combatant_count())

/**
 * Loads the arena and moves everybody waiting in this lobby into it.
 *
 * Refused until the mode's minimum player count is met, which is the same number
 * the TGUI greys the Start button out on, so the two can never disagree.
 */
/datum/deathmatch_lobby/proc/begin_match()
	if(state != DM_LOBBY_WAITING)
		return FALSE
	if(players_needed() > 0)
		return FALSE
	// The unready check lives in start_refusal() so that the Start button greys
	// itself out on exactly this. It is repeated here rather than trusted from the
	// TGUI because /mob/verb/deathmatch_leave_game and any future caller would go
	// around the button entirely, and loading an arena under somebody who never
	// agreed to be in it is the one outcome the ready box exists to prevent.
	if(length(start_refusal()))
		return FALSE
	if(isnull(arena) || arena.is_loaded() || !arena.load_arena())
		log_game("Deathmatch: [to_string()] could not load its arena.")
		end_lobby()
		return FALSE

	state = DM_LOBBY_RUNNING
	time_started = world.time
	// Lobby-wide modifiers get their one chance to rewrite the game before the
	// bodies go in, so that anything they add is in place for spawn_player().
	for(var/modifier_path as anything in selected_modifiers)
		var/datum/deathmatch_modifier/modifier = modifier_path
		if(isnull(modifier) || !modifier.selectable(src))
			continue
		try
			modifier.on_start_game(src)
		catch(var/exception/e)
			log_game("Deathmatch: modifier [modifier] failed on lobby start: [e]")
	// Everybody waiting goes in now. One that cannot be built is dropped instead
	// of ending the game: the people who did get a body came here to play.
	for(var/datum/deathmatch_player/player as anything in players.Copy())
		if(spawn_player(player))
			continue
		if(player.is_host)
			log_game("Deathmatch: [to_string()] could not seat its host.")
			end_lobby()
			return FALSE
		remove_player(player, "Your avatar could not be built.")

	announce_start()
	addtimer(CALLBACK(src, PROC_REF(on_time_up)), game_time)
	log_game("Deathmatch: [to_string()] started on [arena.to_string()].")
	return TRUE

/**
 * Puts a player on the roster without giving them a body yet: the lobby fills up
 * in here and begin_match() walks everybody into the arena at once.
 *
 * loadout is a loadout type path, or NULL to fight with whatever the mode came
 * with. is_host is bookkeeping only: the host leaving ends the game, everybody
 * else leaving does not. observe seats them as a watcher instead of a fighter:
 * they still need a spot at the table and a landmark in the arena, but they are
 * left out of the player minimum, the cap and the win.
 *
 * Returns the /datum/deathmatch_player, or FALSE with a reason sent to the
 * player, because every failure here is something the player can act on.
 */
/datum/deathmatch_lobby/proc/join(mob/real_body, loadout = null, is_host = FALSE, observe = FALSE)
	if(isnull(real_body) || QDELETED(real_body))
		return FALSE
	if(is_finished())
		to_chat(real_body, span_danger("That deathmatch game has already ended."))
		return FALSE
	// Only people still gathering can be added. Once the arena is loaded the
	// roster closes and the game plays itself out.
	if(state != DM_LOBBY_WAITING)
		to_chat(real_body, span_danger("[template.display_name] has already started."))
		return FALSE
	// A mob with no client cannot be moved into an avatar, and cannot read the
	// TGUI that got them here. A missing mind is NOT refused: guests routinely
	// have none, and spawn_player() gives them one when it builds their body.
	if(!real_body.client)
		to_chat(real_body, span_danger("You have no body to put in a virtual one."))
		return FALSE
	// Only the fighters are capped: a spectator joining a full arena should still
	// be allowed to watch it, and is_full() counts combatants for exactly this.
	if(!observe && is_full())
		to_chat(real_body, span_danger("[template.display_name] is full ([template.max_players] players)."))
		return FALSE

	// Captured now, because transfer_ckey() takes the ckey off the body it is
	// leaving once the match starts.
	var/player_key = real_body.ckey || real_body.key
	if(player_key && (player_key in player_keys()))
		to_chat(real_body, span_danger("You are already in this game."))
		return FALSE

	var/datum/deathmatch_player/player = new()
	player.ckey = player_key
	player.real_body = real_body
	player.is_host = is_host
	player.is_observer = observe
	// NULL means "whatever the mode came with", resolved here so the TGUI can
	// show the player what they will actually spawn with.
	player.loadout = loadout || src.loadout
	player.display_name = (real_body.real_name || real_body.name) || player_key || "Guest"
	players += player

	if(observe)
		to_chat(real_body, span_boldnotice("You are watching [template.display_name]."))
		to_chat(real_body, span_notice("Spectators are put into the arena as ghosts and do not count as players."))
		return player

	to_chat(real_body, span_boldnotice(template.display_name))
	to_chat(real_body, span_notice("Loadout: [loadout_name(player.loadout)]."))
	if(is_host)
		to_chat(real_body, span_notice("[players_needed()] more player(s) needed before you can start."))
	else
		to_chat(real_body, span_notice("Waiting for the host to start the game."))
	return player

/// Human readable name of a loadout type path.
///
/// Through get_deathmatch_loadout() rather than instantiating inline, so a NULL, a
/// non-path or an abstract path all come back as the same marker instead of the last
/// two throwing. Falls back to the outfit's own `name` for any kit that never set a
/// display_name, which is what the pre-metadata loadouts do.
/datum/deathmatch_lobby/proc/loadout_name(loadout_path)
	var/datum/outfit/vr/deathmatch_loadout/kit = get_deathmatch_loadout(loadout_path)
	if(isnull(kit))
		return "unknown"
	return kit.get_display_name()

/**
 * Builds a waiting player's arena body and moves them into it. Called from
 * begin_match() once the arena exists.
 *
 * Returns TRUE if they are in, FALSE with a reason sent to them if they are not.
 */
/datum/deathmatch_lobby/proc/spawn_player(datum/deathmatch_player/player)
	if(isnull(player) || isnull(player.real_body) || QDELETED(player.real_body))
		return FALSE
	var/mob/real_body = player.real_body
	// Already in: begin_match() can be reached twice if the host double clicks.
	if(!isnull(player.vr_body) && !QDELETED(player.vr_body))
		return TRUE
	// Observers arrive as ghosts, usually, and are simply walked into the arena.
	// No mind transfer and no avatar means nothing here that can strand a ckey on
	// a body about to be deleted, and nothing for evict_body() to give back - only
	// the landmark, which is handled on the shared path below.
	if(player.is_observer)
		// Claimed once: get_spawn_point() reserves the landmark it returns, so
		// calling it twice for the same player would strand two.
		var/obj/effect/landmark/deathmatch_player_spawn/observe_landmark = arena.get_spawn_point()
		var/turf/observe_turf = get_turf(isnull(observe_landmark) ? arena.get_fallback_spawn_point() : observe_landmark)
		if(isnull(observe_turf))
			to_chat(real_body, span_danger("[arena.get_name()] has nowhere to put you."))
			return FALSE
		player.spawn_landmark = isobj(observe_landmark) ? observe_landmark : null
		real_body.forceMove(observe_turf)
		to_chat(real_body, span_notice("The game is running with [combatant_count()] fighter(s). You are watching."))
		return TRUE
	if(isnull(arena) || !arena.is_loaded())
		to_chat(real_body, span_danger("The arena is not loaded."))
		return FALSE
	// A guest with no mind of their own still needs one: virtual_reality moves a
	// mind between the two bodies, and quit() hands the ckey back to whatever
	// mind.current is. For a guest that is their ghost, which is where they
	// should end up. Built the same way /mob/dead/new_player/Login() does it.
	if(!real_body.mind)
		real_body.mind = new /datum/mind(real_body.key)
		real_body.mind.active = TRUE
		real_body.mind.set_current(real_body)

	var/obj/effect/landmark/deathmatch_player_spawn/spawn_landmark = arena.get_spawn_point()
	var/turf/spawn_turf = get_turf(isnull(spawn_landmark) ? arena.get_fallback_spawn_point() : spawn_landmark)
	if(isnull(spawn_turf))
		to_chat(real_body, span_danger("[arena.get_name()] has nowhere to put you."))
		return FALSE

	// A landmark has to be given back, or a player who leaves holds it for the
	// rest of the game and the last arrivals stack up in the corner.
	player.spawn_landmark = isobj(spawn_landmark) ? spawn_landmark : null

	var/mob/living/carbon/human/vr_body = new(spawn_turf)
	// build_virtual_character() is what gives the body a mind, and
	// virtual_reality/Initialize() refuses a mob without one, so the character
	// has to be built before the component is added. It also equips the loadout.
	if(isnull(vr_body) || !vr_body.build_virtual_character(real_body, player.loadout))
		QDEL_NULL(vr_body)
		to_chat(real_body, span_danger("Your virtual avatar could not be built."))
		return FALSE
	vr_body.updateappearance(TRUE, TRUE, TRUE)

	var/datum/component/virtual_reality/VR = vr_body.AddComponent(/datum/component/virtual_reality, FALSE)
	if(isnull(VR))
		QDEL_NULL(vr_body)
		to_chat(real_body, span_danger("Virtual reality is unavailable on this avatar."))
		return FALSE
	// Guests are very often ghosts, and connect() turns away a dead mob without
	// this. Cheap way of keeping the guest list from filling with people who then
	// get bussed out of the arena.
	VR.allow_ghost_connect = TRUE
	if(!VR.connect(real_body))
		// quit(cleanup = TRUE) hands the half finished session back before
		// deleting the body, so the ckey is not left on a mob about to be qdel'd.
		VR.quit(FALSE, TRUE)
		QDEL_NULL(vr_body)
		to_chat(real_body, span_danger("Transfer to [template.display_name] failed."))
		return FALSE

	player.vr_body = vr_body
	// Per-player modifiers, applied once the body is real so that a body which
	// failed to build is not left carrying a health change nobody can see. A
	// modifier that throws here is logged and skipped rather than taking the game
	// down with it: the other players are already in the arena by now.
	for(var/modifier_path as anything in selected_modifiers)
		var/datum/deathmatch_modifier/modifier = modifier_path
		if(isnull(modifier) || !modifier.selectable(src))
			continue
		try
			modifier.apply(vr_body, src)
		catch(var/exception/e)
			log_game("Deathmatch: modifier [modifier] failed on [vr_body]: [e]")

	to_chat(vr_body, span_notice("Players: [player_count()]/[template.max_players]. The game ends on its own in [DisplayTimeText(game_time)]."))
	to_chat(vr_body, span_notice("Killing you in here only kills the avatar."))
	return TRUE

/// Takes one player out of the arena and puts them back on the station. The arena
/// body is deleted either way, so nothing is left behind to sweep up.
/datum/deathmatch_lobby/proc/remove_player(datum/deathmatch_player/player, reason = "")
	if(isnull(player))
		return FALSE
	// A player still on the waiting roster has no arena body to hand anybody
	// back to, so evict_body() has nothing to say to them and this does.
	var/had_body = !isnull(player.vr_body) && !QDELETED(player.vr_body)
	players -= player
	var/message = reason ? "You left [template.display_name]: [reason]" : "You left [template.display_name]."
	evict_body(player, message)
	if(!had_body && !isnull(player.real_body) && !QDELETED(player.real_body))
		to_chat(player.real_body, span_notice(message))
	if(player.is_host)
		// An arena with no host cannot be joined, ended or debugged by the people
		// standing in it, so the game goes with them.
		end_lobby(reason = "the host left")
	return TRUE

/**
 * Returns a player to their real body and deletes the arena body. message is
 * sent to that real body, or skipped when there is nowhere to send it.
 *
 * virtual_reality/quit() is called before the qdel() so that the ckey transfer is
 * explicit and can be messaged about. Deleting the body afterwards is safe: the
 * component's game_over() hook fires on COMSIG_PARENT_QDELETING, but
 * session_paused is already TRUE, so the transfer is not attempted twice.
 */
/datum/deathmatch_lobby/proc/evict_body(datum/deathmatch_player/player, message = null)
	if(isnull(player))
		return FALSE
	var/mob/living/vr_body = player.vr_body
	player.vr_body = null
	// Handed back before the qdel() so a player leaving mid game does not keep
	// their landmark claimed against the people still arriving.
	if(!isnull(arena))
		arena.release_spawn_point(player.spawn_landmark)
		player.spawn_landmark = null
	// Observers are parked inside the arena with nothing but the mob they walked
	// in on, so they have to be walked back out: end_lobby() unloads the map right
	// after this, and whatever is standing on it when that happens goes with it.
	if(player.is_observer && !isnull(player.real_body) && !QDELETED(player.real_body))
		var/turf/safe_turf = get_random_station_turf()
		if(!isnull(safe_turf))
			player.real_body.forceMove(safe_turf)
		return TRUE
	if(isnull(vr_body) || QDELETED(vr_body))
		return FALSE

	var/datum/component/virtual_reality/VR = vr_body.GetComponent(/datum/component/virtual_reality)
	if(!isnull(VR))
		VR.quit(FALSE, FALSE)
		if(!isnull(message) && !isnull(player.real_body))
			to_chat(player.real_body, span_notice(message))
	qdel(vr_body)
	return TRUE

/**
 * Drops the arena bodies nobody is using any more: the dead, and the husks left
 * by players who disconnected or pressed the Quit Virtual Reality action.
 *
 * virtual_reality has already taken both of those players back to their real
 * body by the time this sees them, so the body is all that is left, and it is
 * standing on the reservation that the next game needs.
 *
 * This does the sweeping itself rather than leaning on
 * /obj/effect/vr_clean_master, which cleans by base area, and every loaded arena
 * shares one /area/deathmatch.
 */
/datum/deathmatch_lobby/proc/reap_bodies()
	if(is_finished())
		return
	// Players on the waiting roster have no arena body yet, so there is nothing
	// to sweep: only a running game leaves husks behind.
	if(state == DM_LOBBY_RUNNING)
		for(var/datum/deathmatch_player/player as anything in players.Copy())
			// Observers hold no avatar, so the sweeps below have nothing to look at.
			// All that can happen to one is their client leaving, which is the same
			// thing that would be swept for a fighter.
			if(player.is_observer)
				if(isnull(player.real_body) || QDELETED(player.real_body) || !player.real_body.key)
					players -= player
				continue
			var/mob/living/vr_body = player.vr_body
			if(isnull(vr_body) || QDELETED(vr_body))
				players -= player
				continue
			if(vr_body.stat == DEAD)
				players -= player
				evict_body(player, "You were killed in [template.display_name] and put back in your body.")
				continue
			// Alive and no ckey: the player disconnected or left VR by hand, and the
			// husk is what is left of them.
			if(!vr_body.key)
				players -= player
				evict_body(player, "You left [template.display_name].")
				continue
	// Everybody is gone, host included. reap_bodies() strips players straight out
	// of the list instead of going through remove_player(), so the host leaving
	// never reaches that proc's end_lobby(), and the game would sit in
	// GLOB.deathmatch_lobbies forever, locking the host out of starting the next.
	if(!players.len)
		end_lobby(reason = "everybody left")
		return
	// One left standing. A running game with a single survivor left in it is
	// over whether or not anybody asked for it to be, and the survivor is told so
	// by name rather than finding out the game went on without them.
	//
	// Counted over fighters, not over seats: a lobby whose only remaining entries
	// are spectators has no survivors, and calling a spectator the winner of a game
	// they sat out is worse than saying nothing at all.
	if(state == DM_LOBBY_RUNNING && combatant_count() <= 1)
		var/datum/deathmatch_player/winner = null
		for(var/datum/deathmatch_player/player as anything in players)
			if(!player.is_observer)
				winner = player
				break
		announce_victory(winner)
		end_lobby(reason = winner ? "[winner_name(winner)] was the last one standing" : "everybody fighting was killed")
		return
	// Re-armed instead of TIMER_LOOP, so a finished lobby has no timer left
	// running against a deleted datum.
	if(!is_finished())
		addtimer(CALLBACK(src, PROC_REF(reap_bodies)), reap_interval)

/datum/deathmatch_lobby/proc/on_time_up()
	if(is_finished())
		return
	to_chat(world, span_boldnotice("[template.display_name] has run its course."))
	end_lobby(reason = "the game ran out of time")

/datum/deathmatch_lobby/proc/announce()
	var/message = "[template.display_name] ждёт игроков! Организатор — [host_display_name()]. Нужно [template.min_players], сейчас [player_count()]. Откройте VR-слипер и выберите этот режим."
	// Ghosts and ghosts only. priority_announce() would put a lobby recruiting for
	// players in front of everybody on the station, which is not station business;
	// the people this lobby is short of are the ones with nothing else to do.
	for(var/mob/M as anything in GLOB.player_list)
		if(!istype(M, /mob/dead))
			continue
		to_chat(M, "<span class='announcement'>[message]</span>")

/// The game actually starting, as opposed to the lobby opening.
/datum/deathmatch_lobby/proc/announce_start()
	priority_announce("[template.display_name] has begun with [player_count()] player(s)!", "Deathmatch")

/// A player's name for a chat message: their character name, their ckey, or a
/// marker, in that order. A dead or disconnected player has no arena body left to
/// read a name off, so this never depends on one.
/datum/deathmatch_lobby/proc/winner_name(datum/deathmatch_player/player)
	if(isnull(player))
		return "somebody"
	return player.display_name || player.ckey || "somebody"

/**
 * The last one standing.
 *
 * The winner is told personally, in the body they are standing in, and everyone
 * else hears who won. to_chat(world, ...) rather than priority_announce(): this is
 * the end of a game people opted into, not station business.
 */
/datum/deathmatch_lobby/proc/announce_victory(datum/deathmatch_player/winner)
	// A null winner is a real outcome, not a bug: the last two fighters can kill
	// each other on the same tick, and reap_bodies() sees an arena with nobody
	// left standing in it. Saying "nobody wins" is the truth; naming a spectator
	// the winner of a game they sat out would not be.
	if(isnull(winner))
		to_chat(world, span_boldnotice("Nobody wins [template.display_name]."))
		return
	var/who = winner_name(winner)
	if(!isnull(winner) && !isnull(winner.vr_body) && !QDELETED(winner.vr_body))
		to_chat(winner.vr_body, span_boldnotice("You are the last one standing in [template.display_name]."))
	to_chat(world, span_boldnotice("[who] wins [template.display_name]!"))

/**
 * Tears the lobby down: everybody home, arena deleted, entry unregistered.
 *
 * delete_arena = FALSE is for a lobby that never got as far as loading one. An
 * arena that will not unload is left loaded and logged rather than force
 * deleted, because force deleting is how players get deleted with the map.
 */
/datum/deathmatch_lobby/proc/end_lobby(delete_arena = TRUE, reason = "")
	if(is_finished())
		return FALSE
	state = DM_LOBBY_FINISHED

	// Modifiers get told first, while the arena still exists: anything they clean
	// up has to happen before the map is handed back to SSmapping.
	for(var/modifier_path as anything in selected_modifiers)
		var/datum/deathmatch_modifier/modifier = modifier_path
		if(isnull(modifier))
			continue
		try
			modifier.on_end_game(src)
		catch(var/exception/e)
			log_game("Deathmatch: modifier [modifier] failed on lobby end: [e]")

	for(var/datum/deathmatch_player/player as anything in players)
		evict_body(player, "Deathmatch is over[reason ? ": [reason]" : ""].")
	players = list()
	GLOB.deathmatch_lobbies -= src

	if(delete_arena && !isnull(arena) && arena.is_loaded() && !arena.unload_arena())
		log_game("Deathmatch: [to_string()] still has [english_list(arena.occupant_names(), "nobody")] in it, leaving it loaded.")
	log_game("Deathmatch: [to_string()] shut down ([reason ? reason : "no reason given"]).")
	return TRUE

/// The host deciding the game is over.
/mob/verb/deathmatch_end_game()
	set name = "End Deathmatch"
	set category = "Deathmatch"
	set desc = "End the deathmatch game you are hosting."
	if(isnull(client))
		return
	var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(ckey)
	if(isnull(lobby))
		to_chat(src, span_danger("You are not hosting a deathmatch game."))
		return
	if(lobby.host_key != ckey)
		to_chat(src, span_danger("Only the host can end this game."))
		return
	to_chat(world, span_boldnotice("[lobby.template.display_name] was ended early by [ckey]."))
	lobby.end_lobby(reason = "the host ended the game")

/// Getting out of a game without waiting for the host to end it.
/mob/verb/deathmatch_leave_game()
	set name = "Leave Deathmatch"
	set category = "Deathmatch"
	set desc = "Leave the deathmatch game you are in."
	if(isnull(client))
		return
	var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(ckey)
	if(isnull(lobby))
		return
	for(var/datum/deathmatch_player/player as anything in lobby.players)
		if(player.ckey == ckey)
			lobby.remove_player(player, "you left")
			return
	to_chat(src, span_danger("You are not in a deathmatch game."))

/// The lobby a ckey is in, whether they host it or just play it.
///
/// Finished lobbies are skipped, so a game that has already been torn down cannot
/// lock its host out of starting the next one.
/proc/get_deathmatch_lobby_of(ckey)
	if(!ckey)
		return null
	for(var/lobby_ref as anything in GLOB.deathmatch_lobbies)
		if(!istype(lobby_ref, /datum/deathmatch_lobby))
			continue
		var/datum/deathmatch_lobby/lobby = lobby_ref
		if(QDELETED(lobby) || lobby.is_finished())
			continue
		if(lobby.host_key == ckey || (ckey in lobby.player_keys()))
			return lobby
	return null

/// A compiled arena map by its /datum/map_template name, for the sleeper UI.
/proc/get_deathmatch_map(name)
	if(!name)
		return null
	for(var/map_ref as anything in get_deathmatch_templates())
		var/datum/map_template/deathmatch/template = map_ref
		if(template.name == name)
			return template
	return null

/**
 * Entry point from /obj/machinery/vr_sleeper. Creates the lobby and seats the host
 * on its waiting roster. The arena is not loaded here.
 * Returns the lobby on success, NULL on failure.
 */
/proc/start_deathmatch_lobby(mob/host, mode = null)
	if(isnull(host) || QDELETED(host) || !host.mind)
		return null
	if(!isnull(get_deathmatch_lobby_of(host.ckey)))
		to_chat(host, span_danger("You are already in a deathmatch game."))
		return null
	var/datum/map_template/deathmatch/template = get_deathmatch_map(mode)
	if(isnull(template))
		to_chat(host, span_danger("Unknown deathmatch mode."))
		return null
	var/datum/deathmatch_lobby/lobby = new(template, host)
	if(!lobby.open())
		return null
	return lobby

/// The open lobby for a mode, if somebody is already recruiting for it. This is
/// what lets the second person through the door join the first person's game
/// instead of opening a rival lobby for the same map.
/proc/get_deathmatch_lobby_of_mode(mode)
	if(!mode)
		return null
	for(var/lobby_ref as anything in GLOB.deathmatch_lobbies)
		if(!istype(lobby_ref, /datum/deathmatch_lobby))
			continue
		var/datum/deathmatch_lobby/lobby = lobby_ref
		if(QDELETED(lobby) || lobby.state != DM_LOBBY_WAITING || lobby.is_full())
			continue
		if(lobby.template?.name == mode)
			return lobby
	return null

/**
 * Any open lobby for a mode, running or not.
 *
 * get_deathmatch_lobby_of_mode() only reports lobbies that are still recruiting, so
 * it is the right one for Join and for "somebody is already opening this" - a full
 * or running game must not be walked into by accident. The browser's View button
 * wants the opposite: a running game's roster is the most interesting thing on the
 * panel, and joining it is a separate button that says so.
 */
proc/get_open_deathmatch_lobby(mode)
	if(!mode)
		return null
	for(var/lobby_ref as anything in GLOB.deathmatch_lobbies)
		if(!istype(lobby_ref, /datum/deathmatch_lobby))
			continue
		var/datum/deathmatch_lobby/lobby = lobby_ref
		if(QDELETED(lobby) || lobby.is_finished())
			continue
		if(lobby.template?.name == mode)
			return lobby
	return null

//
// TGUI: the lobby window.
//
// Two windows, ported from the newTG Deathmatch module: DeathmatchPanel is the
// browser the VR sleeper opens, listing the lobbies currently recruiting, and this
// one is the lobby itself - who is here, what they picked, and the host controls.
// The newTG version runs on a ghost lobby with no machine behind it; this one keeps
// the VR sleeper as the way in, so `host_body` is set and the host is a player with
// a body on the station rather than a ckey holding a slot.
//

/// Lets anybody sitting at the lobby table drive it, host or not. The lobby is
/// reachable only through the sleeper panel, which has already done the guest
/// checks, so re-running them here would only make the window flicker shut for the
/// people it is meant to be for. Anyone not at the table gets the roster and
/// nothing else, which is what the browser's View button is for.
/datum/ui_state/deathmatch_lobby_state
	var/datum/deathmatch_lobby/lobby
	/// Set when the window was opened by somebody who is not on the roster. They see
	/// the player table and the host controls greyed out, and ui_act() refuses them
	/// every action, so this is a display mode rather than a permission.
	var/readonly = FALSE

/datum/ui_state/deathmatch_lobby_state/can_use_topic(src_object, mob/user)
	// Two arguments, matching /datum/ui_state/proc/can_use_topic(). Declaring only the
	// first binds user to src_object, so every `user` below is the lobby datum and the
	// first ckey read comes back as "undefined variable /datum/deathmatch_lobby/var/ckey".
	if(isnull(user?.ckey) || isnull(lobby) || lobby.is_finished())
		return UI_CLOSE
	if(readonly)
		return UI_INTERACTIVE
	for(var/datum/deathmatch_player/player as anything in lobby.players)
		if(player?.ckey == user.ckey)
			return UI_INTERACTIVE
	return UI_CLOSE

/datum/deathmatch_lobby/ui_state(mob/user)
	// new() with no arguments and the fields assigned by hand. `new(lobby = src)` is the
	// usual spelling and it is why this proc used to be reached at all: if the named
	// argument cannot be resolved against the type, BYOND throws at runtime rather than
	// at compile time, and the crash lands here with the ui_state line as the site.
	var/datum/ui_state/deathmatch_lobby_state/new_state = new
	new_state.lobby = src
	// A window opened by somebody who is not on the roster is a scoreboard, not a
	// set of controls: ui_act() already refuses them every action, and this is what
	// stops the window from being closed on them a tick after it opens.
	new_state.readonly = isnull(player_of(user?.ckey))
	return new_state

/datum/deathmatch_lobby/ui_interact(mob/user, ui_obj)
	if(isnull(user))
		return FALSE
	// The sleeper panel is the way in, so it has to get out of the way rather than
	// sit behind this window for the rest of the game. Two windows on one mob fight
	// over the same payload and the player ends up clicking a stale one.
	close_sleeper_panels(user)
	// Deliberately not cached on the datum, and looked up per user. A lobby has one
	// host and up to a dozen guests, and try_update_ui() takes whatever UI it is
	// handed without checking who owns it: a stored var would hand the second player
	// the host's window, return non-null, and leave the second player with no window
	// at all. Passing null makes it call get_open_ui(user, src_object) instead.
	var/datum/tgui/this_users_ui = SStgui.try_update_ui(user, src)
	if(isnull(this_users_ui))
		// The clock in the header counts down on its own, and a running game changes
		// the roster without anybody pressing anything.
		this_users_ui = new(user, src, "DeathmatchLobby", "[template?.display_name || "Deathmatch"]")
		this_users_ui.set_autoupdate(TRUE)
		this_users_ui.open()
	return TRUE

/// Closes the browser on whatever sleeper is within reach of the player.
proc/close_sleeper_panels(mob/user)
	if(isnull(user))
		return
	// A fixed radius, matching the ghost button: a ghost has no `range()` of its own
	// and 7 tiles is what they can click a machine from anyway.
	for(var/atom/A as anything in view(7, user))
		if(istype(A, /obj/machinery/vr_sleeper))
			A.ui_close(user)
			return

/// The browser's View button. Same window, and ui_interact() works out by itself
/// whether the viewer is on the roster or just looking.
/datum/deathmatch_lobby/proc/show_roster(mob/user)
	ui_interact(user)

/// The player's own entry in this lobby, or null if they are not in it.
/datum/deathmatch_lobby/proc/player_of(ckey)
	if(!ckey)
		return null
	for(var/datum/deathmatch_player/player as anything in players)
		if(player?.ckey == ckey)
			return player
	return null

/datum/deathmatch_lobby/proc/is_host(ckey)
	return ckey && (host_key == ckey)

/**
 * Loadout type paths a player may pick right now, in picker order.
 *
 * Paths, not datums, even though /datum/map_template/deathmatch/proc/get_loadouts()
 * hands back datums. A player's own `loadout` is stored as a path - it has to be,
 * because build_virtual_character() takes a path - so the list a picker indexes into
 * has to be in the same shape or the two can never be compared.
 *
 * The `any_loadout` modifier overrides the map's rules with the whole module.
 */
/datum/deathmatch_lobby/proc/available_loadouts()
	if(/datum/deathmatch_modifier/any_loadout in selected_modifiers)
		return get_deathmatch_loadout_paths()
	var/list/paths = list()
	for(var/kit_ref as anything in (template?.get_loadouts() || list()))
		var/datum/outfit/vr/deathmatch_loadout/kit = kit_ref
		if(isnull(kit))
			continue
		// Indexed by hand rather than list.Find(): the list holds datums and the
		// player's choice is a path, and a datum is never equal to its own type.
		if(!(kit.type in paths))
			paths += kit.type
	return paths

/// Whether a player may hold this loadout here. Used both by select_loadout() and
/// by change_map(), which has to re-check everybody when it swaps the rules out
/// from under them.
/datum/deathmatch_lobby/proc/loadout_allowed(path)
	if(ispath(path) && (path in available_loadouts()))
		return TRUE
	// NULL is "the mode's default", which is always allowed - it is whatever the
	// template says it is.
	return isnull(path)

/**
 * Puts a player on the waiting roster as a watcher instead of a fighter.
 *
 * Only legal before the match: an observer never gets an avatar, so turning
 * somebody into one halfway through a game would leave their body standing in the
 * arena belonging to somebody who is no longer driving it.
 */
/datum/deathmatch_lobby/proc/set_observer(datum/deathmatch_player/player, observe)
	if(isnull(player) || state != DM_LOBBY_WAITING)
		return FALSE
	if(player.is_observer == observe)
		return FALSE
	// The host drives the lobby and is the one who has to be in it to start it. An
	// observer-host would leave host_key pointing at somebody who is not fighting,
	// and every host-only control would belong to a ghost.
	if(observe && player.is_host)
		to_chat(player.real_body, span_danger("You are the host. Hand hosting over before you sit out."))
		return FALSE
	if(!observe && is_full())
		to_chat(player.real_body, span_danger("[template.display_name] is full ([template.max_players] players)."))
		return FALSE
	player.is_observer = observe
	// Ready is a promise to fight. Handing it back on the way out means a
	// spectator cannot sit on the host's "everyone said yes" count.
	if(observe)
		player.is_ready = FALSE
	if(observe)
		to_chat(player.real_body, span_notice("You are now watching [template.display_name]."))
	else
		to_chat(player.real_body, span_notice("You are fighting in [template.display_name]. Loadout: [loadout_name(player.loadout)]."))
	return TRUE

/datum/deathmatch_lobby/proc/set_ready(datum/deathmatch_player/player, ready)
	if(isnull(player) || state != DM_LOBBY_WAITING)
		return FALSE
	// An observer cannot be ready for a game they are not in, and letting them tick
	// the box would pad ready_count() past the number of people who said yes.
	if(player.is_observer && ready)
		return FALSE
	player.is_ready = ready
	return TRUE

/**
 * Removes somebody from the lobby at another player's request.
 *
 * The host leaving is handled by remove_player(), which ends the game, so that is
 * refused here: "kick the host" has to go through transfer_host() first, or it is
 * just a slower way of ending everyone's game.
 */
/datum/deathmatch_lobby/proc/kick_player(datum/deathmatch_player/player, by_key)
	if(isnull(player) || player.is_host)
		return FALSE
	if(!is_host(by_key))
		return FALSE
	var/who = winner_name(player)
	remove_player(player, "the host kicked you")
	to_chat(world, span_notice("[who] was kicked from [template.display_name]."))
	return TRUE

/**
 * Hands hosting to somebody else at the table.
 *
 * Only one host is a thing this lobby can have, so this moves the flag rather than
 * adding a second one. host_body follows, because begin_match() refuses a lobby
 * whose host has no body to move - and on a map change the new host is the only
 * one who can start anything.
 */
/datum/deathmatch_lobby/proc/transfer_host(datum/deathmatch_player/player)
	if(isnull(player) || player.is_observer || player.is_host)
		return FALSE
	var/datum/deathmatch_player/old_host = null
	for(var/datum/deathmatch_player/other as anything in players)
		if(other?.is_host)
			old_host = other
			break
	if(!isnull(old_host))
		old_host.is_host = FALSE
	player.is_host = TRUE
	host_key = player.ckey
	host_body = player.real_body
	// A host who has walked off has no body to move, and begin_match() would end
	// the lobby on their behalf the moment the game was started.
	if(isnull(host_body) || QDELETED(host_body))
		host_body = player.vr_body
	to_chat(player.real_body, span_boldnotice("You are now hosting [template.display_name]."))
	if(!isnull(old_host) && !isnull(old_host.real_body))
		to_chat(old_host.real_body, span_notice("[winner_name(player)] is now hosting [template.display_name]."))
	return TRUE

/**
 * Swaps the arena for a different one, keeping everyone already seated.
 *
 * Refused once the arena is loaded. The bodies in it were built for this map's
 * bounds, its landmarks and its loadouts, and rebuilding all of that under people
 * who are already playing is a different feature from changing the map before a
 * game. Before the start there are no bodies to invalidate, so it is free.
 *
 * Anyone whose chosen loadout the new mode does not allow is moved back onto the
 * new default rather than left holding a kit the map was not balanced around, and
 * modifiers the new map blacklists are switched off through on_map_changed().
 */
/datum/deathmatch_lobby/proc/change_map(new_template)
	if(isnull(new_template) || !istype(new_template, /datum/map_template/deathmatch))
		return FALSE
	// Cast. The guard above proves what this is but does not narrow it, and every
	// read of it below is a template var.
	var/datum/map_template/deathmatch/new_map = new_template
	if(state != DM_LOBBY_WAITING)
		to_chat(host_body, span_danger("The map cannot be changed once the game has started."))
		return FALSE
	if(new_map == template)
		return FALSE
	// A host with no body cannot be told why their request failed, and is almost
	// certainly a host who disconnected anyway.
	if(!isnull(host_body) && !QDELETED(host_body))
		to_chat(host_body, span_notice("[template.display_name] is now [new_map.display_name]."))

	template = new_map
	loadout = new_map.loadout
	// Rebuilding the arena rather than reloading it: the old one holds a
	// reservation that is handed back here rather than leaked.
	if(!isnull(arena))
		if(arena.is_loaded() && !arena.unload_arena())
			log_game("Deathmatch: [to_string()] changed map with the old arena still loaded.")
	qdel(arena)
	arena = new(new_map)

	var/list/allowed = available_loadouts()
	for(var/datum/deathmatch_player/player as anything in players)
		if(player.loadout in allowed)
			continue
		// Kept before the reset: the notice is about the kit that was refused, so
		// reading player.loadout afterwards would name the replacement instead.
		var/rejected = player.loadout
		player.loadout = loadout
		if(!player.is_observer && !isnull(player.real_body) && !QDELETED(player.real_body))
			to_chat(player.real_body, span_notice("[new_map.display_name] does not allow [loadout_name(rejected)], so you are on the default now."))
	for(var/modifier_path as anything in selected_modifiers.Copy())
		var/datum/deathmatch_modifier/modifier = modifier_path
		if(isnull(modifier))
			selected_modifiers -= modifier_path
			continue
		modifier.on_map_changed(src)
		// on_map_changed() only gets a chance to run the modifier's own teardown; it
		// has no reason to touch the lobby's list. Left in, the modifier would sit in
		// selected_modifiers forever: selectable() is FALSE for it, so it could never
		// be switched back on, while the window would keep showing it as active.
		if(!modifier.selectable(src))
			selected_modifiers -= modifier_path
	return TRUE

/**
 * Turns a modifier on or off for this lobby.
 *
 * Kept by type path, and checked against selectable() so that a modifier the map
 * forbids cannot be switched on in the first place.
 */
/datum/deathmatch_lobby/proc/set_modifier(modifier_path, enabled)
	if(isnull(modifier_path) || !ispath(modifier_path))
		return FALSE
	var/modifier_type = modifier_path
	if(!(modifier_type in subtypesof(/datum/deathmatch_modifier)))
		return FALSE
	var/datum/deathmatch_modifier/modifier = modifier_type
	if(!modifier.selectable(src))
		return FALSE
	if(enabled)
		if(modifier_type in selected_modifiers)
			return FALSE
		selected_modifiers += modifier_type
		modifier.on_select(src)
		return TRUE
	if(!(modifier_type in selected_modifiers))
		return FALSE
	selected_modifiers -= modifier_type
	modifier.on_unselect(src)
	return TRUE

/// Why the Start button is disabled, in words the host can act on. Empty means it
/// is not disabled.
/datum/deathmatch_lobby/proc/start_refusal()
	if(state == DM_LOBBY_RUNNING)
		return "The game is already running."
	if(players_needed() > 0)
		return "Waiting on [players_needed()] more player(s)."
	// Anyone who is here to fight but has not said yes holds the game up. Without
	// this the host starts a game that somebody walks out of on tick one.
	var/unready = ""
	for(var/datum/deathmatch_player/player as anything in players)
		if(player.is_observer || player.is_ready)
			continue
		unready += "[player.display_name] is not ready."
	if(unready)
		return unready
	return ""

/**
 * Everything the lobby window shows that does not change while it is open.
 *
 * The modifier and loadout catalogues are here rather than in ui_data() because
 * they never change once the game is compiled: putting them in static means the
 * server sends each list once per client instead of on every update tick.
 */
/datum/deathmatch_lobby/ui_static_data(mob/user)
	. = list()

	var/list/modes = list()
	for(var/mode_path as anything in get_deathmatch_templates())
		var/datum/map_template/deathmatch/mode = mode_path
		var/list/modes_row = list()
		UNTYPED_LIST_ADD(modes_row, mode.name)
		UNTYPED_LIST_ADD(modes_row, mode.display_name)
		UNTYPED_LIST_ADD(modes_row, mode.description)
		UNTYPED_LIST_ADD(modes_row, mode.min_players)
		UNTYPED_LIST_ADD(modes_row, mode.max_players)
		UNTYPED_LIST_ADD(modes, modes_row)
	.["modes"] = modes
	var/list/loadouts = list()
	for(var/loadout_path as anything in get_deathmatch_loadout_paths())
		var/datum/outfit/vr/deathmatch_loadout/kit = get_deathmatch_loadout(loadout_path)
		if(isnull(kit))
			continue
		var/list/loadout_row = list()
		UNTYPED_LIST_ADD(loadout_row, loadout_path)
		UNTYPED_LIST_ADD(loadout_row, kit.get_display_name())
		UNTYPED_LIST_ADD(loadout_row, kit.desc)
		UNTYPED_LIST_ADD(loadouts, loadout_row)
	.["loadouts"] = loadouts
	var/list/modifiers = list()
	for(var/modifier_path as anything in get_deathmatch_modifiers())
		var/datum/deathmatch_modifier/modifier = modifier_path
		var/datum/deathmatch_modifier/instance = modifier
		if(isnull(instance) || !instance.selectable(src))
			continue
		var/list/modifier_row = list()
		UNTYPED_LIST_ADD(modifier_row, modifier_path)
		UNTYPED_LIST_ADD(modifier_row, instance.name)
		UNTYPED_LIST_ADD(modifier_row, instance.description)
		UNTYPED_LIST_ADD(modifier_row, instance.lobby_wide)
		UNTYPED_LIST_ADD(modifiers, modifier_row)
	.["modifiers"] = modifiers

/// The lobby as the window sees it, rebuilt whenever anything in it moves.
/datum/deathmatch_lobby/ui_data(mob/user)
	. = list()
	var/your_ckey = user?.ckey
	var/datum/deathmatch_player/you = player_of(your_ckey)
	var/hosting = is_host(your_ckey)

	.["map_name"] = template?.name
	.["map_display_name"] = template?.display_name
	.["map_description"] = template?.description
	.["host"] = host_display_name()
	.["state"] = state == DM_LOBBY_RUNNING ? "running" : "waiting"
	.["seat_count"] = seat_count()
	.["player_count"] = combatant_count()
	.["observer_count"] = observer_count()
	.["max_players"] = template?.max_players
	.["min_players"] = template?.min_players
	.["ready_count"] = ready_count()
	.["players_needed"] = players_needed()
	.["is_host"] = hosting
	.["are_you_in"] = !isnull(you)
	.["you_are_observer"] = you?.is_observer || FALSE
	var/time_left = 0
	if(state == DM_LOBBY_RUNNING && !isnull(time_started))
		time_left = max(0, game_time - (world.time - time_started))
	.["time_left"] = DisplayTimeText(time_left)
	.["time_left_seconds"] = time_left
	// Start is gated on the same refusal string the host sees, so the greyed out
	// button and the message under it can never disagree.
	var/refusal = start_refusal()
	.["can_start"] = is_host(your_ckey) && !length(refusal)
	.["start_refusal"] = refusal
	var/list/rows = list()
	for(var/datum/deathmatch_player/player as anything in players)
		var/list/row = list()
		UNTYPED_LIST_ADD(row, player.ckey)
		UNTYPED_LIST_ADD(row, player.display_name)
		UNTYPED_LIST_ADD(row, player.is_host)
		UNTYPED_LIST_ADD(row, player.is_ready)
		UNTYPED_LIST_ADD(row, player.is_observer)
		UNTYPED_LIST_ADD(row, player.ckey == your_ckey)
		UNTYPED_LIST_ADD(row, player.is_observer ? "watching" : loadout_name(player.loadout))
		UNTYPED_LIST_ADD(row, !isnull(player.vr_body) && !QDELETED(player.vr_body))
		UNTYPED_LIST_ADD(rows, row)
	.["players"] = rows
	var/list/picked = list()
	for(var/modifier_path as anything in selected_modifiers)
		UNTYPED_LIST_ADD(picked, modifier_path)
	.["selected_modifiers"] = picked
	var/list/allowed = available_loadouts()
	.["your_loadout"] = (you?.loadout in allowed) ? you?.loadout : loadout
	// The kits this player may actually pick, in picker order, so the dropdown's
	// index lines up with what select_loadout() resolves it against. Not static
	// data: the list is the mode's own, so it changes when the host swaps arenas or
	// switches the any_loadout modifier on.
	var/list/your_loadouts = list()
	for(var/kit_path as anything in allowed)
		var/datum/outfit/vr/deathmatch_loadout/kit = get_deathmatch_loadout(kit_path)
		if(isnull(kit))
			continue
		var/list/kit_row = list()
		UNTYPED_LIST_ADD(kit_row, kit_path)
		UNTYPED_LIST_ADD(kit_row, kit.get_display_name())
		UNTYPED_LIST_ADD(kit_row, kit.desc)
		UNTYPED_LIST_ADD(your_loadouts, kit_row)
	.["your_loadouts"] = your_loadouts

/// Pushed to the window rather than polled from it.
///
/// ui_interact() turns autoupdate on, which re-sends ui_data() once a second, so
/// this is deliberately not a separate ui_status_update(): two paths that both write
/// the same keys is how the clock and the player count end up disagreeing.
/datum/deathmatch_lobby/proc/refresh_uis()
	for(var/datum/tgui/viewer as anything in SStgui.get_all_open_uis(src))
		viewer.needs_update = TRUE

/**
 * The lobby window's buttons.
 *
 * Every action re-reads who is asking from their ckey rather than trusting anything
 * the browser sent about identity: a stale window is not a security boundary, and
 * the host-only actions are exactly the ones worth getting wrong.
 */
/datum/deathmatch_lobby/ui_act(action, list/params, ui_obj, datum/ui_state/tgui_state)
	// The parent's bail on a non-interactive UI is the real guard here, so it has to
	// run before anything here looks at params.
	if(..())
		return
	var/mob/user = usr
	var/your_ckey = user?.ckey
	var/datum/deathmatch_player/you = player_of(your_ckey)
	if(isnull(your_ckey) || isnull(you))
		return FALSE
	var/hosting = is_host(your_ckey)

	switch(action)
		if("set_ready")
			// Toggles rather than setting: the window sends no value, so a checkbox
			// that was ticked by hand elsewhere still lands on the right answer.
			if(state == DM_LOBBY_WAITING)
				set_ready(you, !you.is_ready)

		if("select_loadout")
			if(state != DM_LOBBY_WAITING)
				return FALSE
			// The kit is picked by index into the same list the window was sent, so
			// an index from an older window still resolves to a kit rather than to
			// whatever happens to sit at that index now.
			var/list/allowed = available_loadouts()
			var/choice = clamp(text2num(params["choice"]) + 1, 1, length(allowed))
			if(!choice)
				return FALSE
			you.loadout = allowed[choice]
			to_chat(you.real_body, span_notice("Loadout: [loadout_name(you.loadout)]."))

		if("toggle_observe")
			if(state != DM_LOBBY_WAITING)
				return FALSE
			if(!set_observer(you, !you.is_observer))
				return FALSE

		if("host_toggle_observe")
			// The host turning somebody else's watcher bit. Not the same action as
			// toggle_observe: that one lets a player opt themselves out of the game, and
			// this one must not be reachable by anybody who is not the host.
			if(!hosting || state != DM_LOBBY_WAITING)
				return FALSE
			var/datum/deathmatch_player/target = player_of(params["ckey"])
			if(isnull(target) || target.is_host)
				return FALSE
			set_observer(target, !target.is_observer)

		if("start_game")
			if(!hosting)
				return FALSE
			if(length(start_refusal()))
				return FALSE
			begin_match()

		if("end_game")
			if(!hosting)
				return FALSE
			to_chat(world, span_boldnotice("[template.display_name] was ended early by [host_display_name()]."))
			end_lobby(reason = "the host ended the game")

		if("kick_player")
			kick_player(player_of(params["ckey"]), your_ckey)

		if("transfer_host")
			if(!hosting)
				return FALSE
			transfer_host(player_of(params["ckey"]))

		if("change_map")
			if(!hosting)
				return FALSE
			change_map(get_deathmatch_map(params["map"]))

		if("toggle_modifier")
			if(!hosting || state != DM_LOBBY_WAITING)
				return FALSE
			set_modifier(params["modifier"], !(params["modifier"] in selected_modifiers))

		if("leave_game")
			remove_player(you, "you left")
			// This player's own window, found the same way ui_interact() found it. A
			// shared var here would close whoever's window happened to be cached.
			var/datum/tgui/leaving_ui = SStgui.get_open_ui(user, src)
			if(leaving_ui)
				leaving_ui.close()
			// Back to the browser rather than nowhere, so a player who left on
			// purpose can pick another lobby without re-opening the sleeper.
			open_sleeper_browser(user)

		else
			return FALSE
	return TRUE
