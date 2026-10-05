// The Deathmatch browser as something that is not a machine.
//
// The panel itself lives on /obj/machinery/vr_sleeper: the host's real body has to
// end up somewhere when the game is over, and the sleeper is where that happens, so
// the window that opens a game is opened from a machine. A guest has no body to put
// in a sleeper and no hands to reach one with, so this datum serves the same
// DeathmatchPanel to anybody, from anywhere on the map, with the sleeper's own
// controls left out.
//
// Everything the two windows have in common - the mode catalogue, the lobby table,
// and Join/Spectate/View - is built once here and used by both. Duplicating it is
// how the row indices in DeathmatchPanel.tsx and the payload in vr_sleeper.dm
// drifted apart in the first place.

/// One browser for the whole server. It is stateless apart from the notice channel
/// below, and every window it hands out is keyed on the user who asked for it, so a
/// shared src_object hands two guests two windows rather than one window twice.
GLOBAL_DATUM_INIT(deathmatch_browser, /datum/deathmatch_browser, new)

/datum/deathmatch_browser
	/// What the last button press had to say, keyed by ckey. Read once by ui_data()
	/// and cleared, the same as the sleeper's own sleeper_notices: a refusal sent to
	/// chat alone looks exactly like a dead button to somebody staring at the panel.
	var/list/browser_notices = list()

GLOBAL_DATUM_INIT(deathmatch_browser_state, /datum/ui_state/deathmatch_browser_state, new)

/datum/ui_state/deathmatch_browser_state
	// There is no machine here to test range against or a body to test for, and the
	// whole point of this window is that a guest in the afterlife can open it. The
	// only thing that can stop a button is not having a client to press it with.
/datum/ui_state/deathmatch_browser_state/can_use_topic(src_object, mob/user)
	if(isnull(user?.client))
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/deathmatch_browser/ui_state(mob/user)
	return GLOB.deathmatch_browser_state

/datum/deathmatch_browser/ui_interact(mob/user, datum/tgui/ui)
	if(isnull(user))
		return FALSE
	// Per user, and never cached on the datum: the same argument as
	// /datum/deathmatch_lobby/ui_interact, and for the same reason. A stored window
	// would hand the second guest the first guest's, because try_update_ui() takes
	// whatever UI it is handed without checking who owns it.
	ui = SStgui.try_update_ui(user, src, ui)
	if(isnull(ui))
		// Autoupdate because the lobby table changes under it: somebody joins,
		// somebody starts, somebody leaves, and none of that is a button press.
		ui = new(user, src, "DeathmatchPanel", "Deathmatch")
		ui.set_autoupdate(TRUE)
		ui.open()
	return TRUE

/datum/deathmatch_browser/ui_static_data(mob/user)
	return list("modes" = get_deathmatch_mode_rows())

/datum/deathmatch_browser/ui_data(mob/user)
	var/list/data = get_deathmatch_browser_data(user)
	// No machine behind this window. The flags are sent as well as has_machine so a
	// panel built against an older payload renders greyed out rather than reaching
	// into undefined.
	data["has_machine"] = FALSE
	data["can_create_lobby"] = FALSE
	data["toggle_open"] = FALSE
	data["emagged"] = FALSE
	data["isoccupant"] = FALSE
	data["can_delete_avatar"] = FALSE
	data["vr_avatar"] = FALSE
	data["isliving"] = FALSE
	data["sleeper_notice"] = browser_notices[user.ckey]
	browser_notices[user.ckey] = null
	return data

/datum/deathmatch_browser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	// create_lobby is deliberately not handled: opening a game means lying in a
	// sleeper, so it belongs to the machine panel and only to it.
	handle_deathmatch_browser_act(browser_notices, action, params, usr)
	return TRUE

/**
 * Opens the browser for somebody who is not standing next to a sleeper.
 *
 * The ghost button used to walk view(7) looking for a machine and refuse with
 * "No VR sleeper in sight" when it found none, which meant a guest who died in the
 * first thirty seconds of the round could not get into the game at all.
 *
 * returns TRUE if a window was opened or refreshed.
 */
/proc/open_deathmatch_browser(mob/user)
	if(isnull(user) || !user.client)
		return FALSE
	return GLOB.deathmatch_browser.ui_interact(user)

/// The mode catalogue, sent once per window rather than on every status update.
/// Compiled into the dmb, so it cannot change while the server is up.
/proc/get_deathmatch_mode_rows()
	var/list/modes = list()
	for(var/map_ref as anything in get_deathmatch_templates())
		var/datum/map_template/deathmatch/mode = map_ref
		var/list/row = list()
		UNTYPED_LIST_ADD(row, mode.name)
		UNTYPED_LIST_ADD(row, mode.display_name)
		UNTYPED_LIST_ADD(row, mode.description)
		UNTYPED_LIST_ADD(row, mode.min_players)
		UNTYPED_LIST_ADD(row, mode.max_players)
		UNTYPED_LIST_ADD(modes, row)
	return modes

/**
 * Every lobby that is open right now, whoever is hosting it.
 *
 * Not just the ones with room: a running game's roster is the thing a guest most
 * wants to look at, and the Join button on that row greys itself out through
 * `joinable` rather than by the row being quietly missing.
 *
 * Rows are plain lists built with UNTYPED_LIST_ADD, so the top level has to be an
 * assignment - the macro is `list += ...` and would wrap the whole thing. The index
 * constants in DeathmatchPanel.tsx are the contract; if this row is reordered, they
 * move with it.
 *
 * user is passed rather than taken from usr: ui_data() is also called off the
 * autoupdate tick, where usr is whoever happened to press something last.
 */
/proc/get_deathmatch_lobby_rows(mob/user)
	var/list/lobbies = list()
	for(var/lobby_ref as anything in GLOB.deathmatch_lobbies)
		if(!istype(lobby_ref, /datum/deathmatch_lobby))
			continue
		var/datum/deathmatch_lobby/lobby = lobby_ref
		if(QDELETED(lobby) || lobby.is_finished())
			continue
		var/list/row = list()
		UNTYPED_LIST_ADD(row, lobby.template?.name)
		UNTYPED_LIST_ADD(row, lobby.template?.display_name)
		UNTYPED_LIST_ADD(row, lobby.template?.description)
		UNTYPED_LIST_ADD(row, lobby.host_display_name())
		UNTYPED_LIST_ADD(row, lobby.state == DM_LOBBY_RUNNING)
		UNTYPED_LIST_ADD(row, lobby.combatant_count())
		UNTYPED_LIST_ADD(row, lobby.observer_count())
		UNTYPED_LIST_ADD(row, lobby.template?.max_players)
		UNTYPED_LIST_ADD(row, lobby.template?.min_players)
		// Two refusals, reported separately, because they are two different things a
		// player might want to do: a full arena cannot be joined but can be watched,
		// and a running one cannot be joined at all because the roster closed.
		UNTYPED_LIST_ADD(row, !lobby.is_full() && lobby.state == DM_LOBBY_WAITING)
		UNTYPED_LIST_ADD(row, !get_deathmatch_lobby_of(user?.ckey))
		UNTYPED_LIST_ADD(lobbies, row)
	return lobbies

/// The half of the panel payload that is about Deathmatch rather than about a
/// particular machine, so both src_objects send exactly the same keys.
/proc/get_deathmatch_browser_data(mob/user)
	var/list/data = list()
	data["lobbies"] = get_deathmatch_lobby_rows(user)
	var/datum/deathmatch_lobby/mine = get_deathmatch_lobby_of(user?.ckey)
	data["in_lobby"] = !isnull(mine)
	data["lobby_map"] = mine?.template?.name
	data["lobby_name"] = mine?.template?.display_name
	data["lobby_running"] = mine?.state == DM_LOBBY_RUNNING
	data["lobby_is_host"] = mine?.is_host(user?.ckey) || FALSE
	return data

/**
 * Says the same thing in chat and in the panel, whichever window is open.
 *
 * notices is the caller's own list, passed in rather than looked up through src: a
 * /datum has no proc to hang a per-player message off that both /obj/machinery/vr_sleeper
 * and /datum/deathmatch_browser could share without the base class growing a
 * Deathmatch concept, and BYOND rejects the dynamic call at compile time anyway.
 */
/proc/deathmatch_browser_feedback(list/notices, mob/user, message)
	if(isnull(user))
		return
	to_chat(user, message)
	if(!isnull(notices))
		notices[user.ckey] = message

/**
 * Join, Spectate and View, shared by the machine panel and the standalone browser.
 *
 * notices is where the answer should be left for the panel to pick up on its next
 * refresh: sleeper_notices on the machine, browser_notices on the standalone one.
 *
 * Every branch answers, in the panel if not in chat. A button that returns without a
 * word reads as a dead button, and these were the ones reported as dead.
 *
 * returns TRUE if the action was one of ours.
 */
/proc/handle_deathmatch_browser_act(list/notices, action, list/params, mob/user)
	switch(action)
		if("join_lobby")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of_mode(params["map"])
			if(isnull(lobby))
				deathmatch_browser_feedback(notices, user, span_warning("That lobby is gone."))
				return TRUE
			if(lobby.join(user))
				deathmatch_browser_feedback(notices, user, span_notice("Joined [lobby.template.display_name]."))
				open_lobby_window(user, lobby)
			else
				// join() has already said why in chat. Repeating it in the panel is
				// the difference between a refusal and a dead button.
				deathmatch_browser_feedback(notices, user, span_warning("[lobby.template.display_name] would not take you. The chat says why."))
			return TRUE
		if("spectate_lobby")
			// Any lobby for the mode, waiting or running: watching a game that has
			// already started is the normal thing to want, and get_deathmatch_lobby_of_mode()
			// only reports the ones still recruiting.
			var/datum/deathmatch_lobby/lobby = get_open_deathmatch_lobby(params["map"])
			if(isnull(lobby))
				deathmatch_browser_feedback(notices, user, span_warning("That lobby is gone."))
				return TRUE
			// join()'s fourth argument seats them as a watcher: a spot at the table and
			// a landmark in the arena, but out of the player count and out of the win.
			if(lobby.join(user, null, FALSE, TRUE))
				deathmatch_browser_feedback(notices, user, span_notice("Watching [lobby.template.display_name]."))
				open_lobby_window(user, lobby)
			else
				deathmatch_browser_feedback(notices, user, span_warning("[lobby.template.display_name] would not seat you as a watcher. The chat says why."))
			return TRUE
		if("view_lobby")
			// Looking does not join. The lobby window opens on the roster, and its state
			// proc closes it again for anybody not at the table, so "View" on somebody
			// else's game shows a roster for as long as the window is open and no longer.
			var/datum/deathmatch_lobby/lobby = get_open_deathmatch_lobby(params["map"])
			if(isnull(lobby))
				deathmatch_browser_feedback(notices, user, span_warning("That lobby is gone."))
				return TRUE
			lobby.show_roster(user)
			return TRUE
	return FALSE
