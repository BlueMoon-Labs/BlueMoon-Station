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
	var/state = DM_LOBBY_WAITING
	var/time_started
	/// A game cannot run forever: the host may have disconnected and left the
	/// remaining players with no way to end it.
	var/game_time = 8 MINUTES
	/// How often dead and abandoned arena bodies are swept up.
	var/reap_interval = 5 SECONDS

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

/datum/deathmatch_lobby/proc/is_full()
	return player_count() >= (template?.max_players || 2)

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
datum/deathmatch_lobby/proc/host_display_name()
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
datum/deathmatch_lobby/proc/players_needed()
	return max(0, (template?.min_players || 2) - player_count())

/**
 * Loads the arena and moves everybody waiting in this lobby into it.
 *
 * Refused until the mode's minimum player count is met, which is the same number
 * the TGUI greys the Start button out on, so the two can never disagree.
 */
datum/deathmatch_lobby/proc/begin_match()
	if(state != DM_LOBBY_WAITING)
		return FALSE
	if(players_needed() > 0)
		return FALSE
	if(isnull(arena) || arena.is_loaded() || !arena.load_arena())
		log_game("Deathmatch: [to_string()] could not load its arena.")
		end_lobby()
		return FALSE

	state = DM_LOBBY_RUNNING
	time_started = world.time
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
 * else leaving does not.
 *
 * Returns the /datum/deathmatch_player, or FALSE with a reason sent to the
 * player, because every failure here is something the player can act on.
 */
/datum/deathmatch_lobby/proc/join(mob/real_body, loadout = null, is_host = FALSE)
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
	if(is_full())
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
	// NULL means "whatever the mode came with", resolved here so the TGUI can
	// show the player what they will actually spawn with.
	player.loadout = loadout || src.loadout
	player.display_name = (real_body.real_name || real_body.name) || player_key || "Guest"
	players += player

	to_chat(real_body, span_boldnotice(template.display_name))
	to_chat(real_body, span_notice("Loadout: [loadout_name(player.loadout)]."))
	if(is_host)
		to_chat(real_body, span_notice("[players_needed()] more player(s) needed before you can start."))
	else
		to_chat(real_body, span_notice("Waiting for the host to start the game."))
	return player

/// Human readable name of a loadout type path.
datum/deathmatch_lobby/proc/loadout_name(loadout_path)
	if(!ispath(loadout_path))
		return "unknown"
	var/datum/outfit/O = loadout_path
	return O.name || loadout_path

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
	if(state == DM_LOBBY_RUNNING && players.len == 1)
		var/datum/deathmatch_player/winner = players[1]
		announce_victory(winner)
		end_lobby(reason = "[winner_name(winner)] was the last one standing")
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
datum/deathmatch_lobby/proc/announce_start()
	priority_announce("[template.display_name] has begun with [player_count()] player(s)!", "Deathmatch")

/// A player's name for a chat message: their character name, their ckey, or a
/// marker, in that order. A dead or disconnected player has no arena body left to
/// read a name off, so this never depends on one.
datum/deathmatch_lobby/proc/winner_name(datum/deathmatch_player/player)
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
datum/deathmatch_lobby/proc/announce_victory(datum/deathmatch_player/winner)
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
