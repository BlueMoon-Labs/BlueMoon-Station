//Glorified teleporter that puts you in a new human body.
// it's """VR"""
/obj/machinery/vr_sleeper
	name = "virtual reality sleeper"
	desc = "A sleeper modified to alter the subconscious state of the user, allowing them to visit virtual worlds."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	state_open = TRUE
	occupant_typecache = list(/mob/living/carbon/human) // turned into typecache in Initialize
	circuit = /obj/item/circuitboard/machine/vr_sleeper
	var/you_die_in_the_game_you_die_for_real = FALSE
	var/datum/effect_system/spark_spread/sparks
	var/mob/living/vr_mob
	var/virtual_mob_type = /mob/living/carbon/human
	var/vr_category = "default" //Specific category of spawn points to pick from
	var/allow_creating_vr_mobs = TRUE //So you can have vr_sleepers that always spawn you as a specific person or 1 life/chance vr games
	var/only_current_user_can_interact = FALSE
	/// What the panel last said to each player, keyed by ckey. Whoever presses a
	/// button is not always whoever has to read the answer, and a chat line that
	/// scrolls off the bottom of the screen looks exactly like a dead button, so
	/// the same text is shown inside the panel too. Read once by ui_data() and
	/// cleared, so it survives a single refresh and no longer.
	var/list/sleeper_notices = list()

/**
 * tgui state: sleeper_guest_state
 *
 * The whole panel runs on this one state, because the alternatives are wrong for
 * somebody and stale for everybody else.
 *
 * default_state will not admit a guest at all. Its can_use_topic() defers to
 * /mob/proc/default_can_use_topic(), which is the proc a ghost actually gets -
 * being neither /mob/living nor a robot - and that returns UI_CLOSE for
 * everything. Opening a window only needs UI_UPDATE, so the panel appeared to
 * work and then every button in it was silently inert.
 *
 * Picking contained_state for the occupant and default_state for everyone else
 * fixes the ghost but breaks the reverse case: a tgui state is read once, when
 * the window is created, so a host who is lying in the sleeper keeps
 * contained_state, and the moment their mind moves into a virtual body they stop
 * being in contents and their own Leave button goes dead too. Deciding per press
 * instead of per window avoids that.
 *
 * observer_state would hand a ghost the panel unconditionally, but it is not used
 * because it also says nothing about anybody else, and the occupant still needs
 * the shared interaction check so a body that cannot act does not get full
 * control of the machine it is lying in.
 */
GLOBAL_DATUM_INIT(sleeper_guest_state, /datum/ui_state/sleeper_guest_state, new)

/datum/ui_state/sleeper_guest_state/can_use_topic(src_object, mob/user)
	if(!user)
		return UI_CLOSE
	// A guest has no hands to reach anything with, so nothing physical to test: the
	// panel is theirs wherever they are on the map. Gating this on view distance
	// only produced a window that opened and then went inert the moment the ghost
	// drifted, which reads as a broken button rather than as a refused one.
	if(isobserver(user))
		return UI_INTERACTIVE
	// In the sleeper, they own it. Delegated to the same shared check contained_state
	// would use, so an occupant who cannot act does not get full control.
	// Cast, because the base proc hands src_object over untyped.
	var/atom/machine = src_object
	if(!isnull(machine) && machine.contains(user))
		return user.shared_ui_interaction(machine)
	// Anybody else gets the ordinary range-based rules.
	return GLOB.default_state.can_use_topic(src_object, user)

/// Says the same thing to a player in chat and in the panel, so a refusal or a
/// result cannot be missed by somebody looking straight at the button they pressed.
/obj/machinery/vr_sleeper/proc/feedback(mob/user, message)
	if(isnull(user))
		return
	to_chat(user, message)
	sleeper_notices[user.ckey] = message

/obj/machinery/vr_sleeper/Initialize(mapload)
	. = ..()
	sparks = new /datum/effect_system/spark_spread()
	sparks.set_up(2,0)
	sparks.attach(src)
	update_icon()
	new_occupant_dir = dir

/obj/machinery/vr_sleeper/setDir(newdir)
	. = ..()
	new_occupant_dir = dir

/obj/machinery/vr_sleeper/attackby(obj/item/I, mob/user, params)
	if(!state_open && !occupant)
		if(default_deconstruction_screwdriver(user, "[initial(icon_state)]-o", initial(icon_state), I))
			return
	if(default_change_direction_wrench(user, I))
		return
	if(default_pry_open(I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/vr_sleeper/relaymove(mob/user)
	open_machine()

/obj/machinery/vr_sleeper/container_resist(mob/living/user)
	open_machine()

/obj/machinery/vr_sleeper/Destroy()
	open_machine()
	cleanup_vr_mob()
	QDEL_NULL(sparks)
	return ..()

/obj/machinery/vr_sleeper/hugbox
	desc = "A sleeper modified to alter the subconscious state of the user, allowing them to visit virtual worlds. Seems slightly more secure."
	flags_1 = NODECONSTRUCT_1
	only_current_user_can_interact = TRUE

/obj/machinery/vr_sleeper/emag_act(mob/user)
	. = ..()
	if(!(obj_flags & EMAGGED))
		return
	if(!only_current_user_can_interact)
		obj_flags |= EMAGGED
		log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
		you_die_in_the_game_you_die_for_real = TRUE
		sparks.start()
		addtimer(CALLBACK(src, PROC_REF(emagNotify)), 150)
		return TRUE

/obj/machinery/vr_sleeper/update_icon_state()
	icon_state = "[initial(icon_state)][state_open ? "-open" : ""]"


/obj/machinery/vr_sleeper/MouseDrop_T(mob/target, mob/user)
	if(user.lying || !iscarbon(target) || !Adjacent(target) || !user.canUseTopic(src, BE_CLOSE, TRUE, NO_TK))
		return
	if(occupant)
		to_chat(user, "<span class='boldnotice'>The VR Sleeper is already occupied!</span>")
		return
	close_machine(target)
	ui_interact(user)

/obj/machinery/vr_sleeper/ui_state(mob/user)
	// One state for everybody, occupant and ghost alike. See sleeper_guest_state for
	// why splitting this per user is what left guests pressing dead buttons.
	return GLOB.sleeper_guest_state

/obj/machinery/vr_sleeper/attack_hand(mob/user)
	// A guest opens this panel from the floor next to the sleeper. The stock
	// machinery path gates the click on canUseTopic, which a ghost sitting on the
	// other side of the room never passes, and the panel is the only place a
	// loadout can be picked - which is the only way into a game as a guest. Left
	// alone, a guest reaches for the Join Deathmatch verb instead and gets
	// dropped into whichever lobby happens to be first.
	if(istype(user, /mob/dead))
		ui_interact(user)
		return TRUE
	return ..()

/obj/machinery/vr_sleeper/ui_interact(mob/user, datum/tgui/ui)
	// One window for the whole machine now. It used to be "VrSleeper", which
	// carried the machine's own VR controls *and* a half-written deathmatch browser
	// in the same payload, and every button in it was fighting for the same space.
	// DeathmatchPanel keeps the machine controls and replaces that browser with the
	// real one: a list of open lobbies, and a Create button per mode.
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DeathmatchPanel", "VR Sleeper")
		ui.open()

/obj/machinery/vr_sleeper/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	switch(action)
		if("vr_connect")
			var/mob/M = occupant
			if(M?.mind && M == usr)
				to_chat(M, "<span class='warning'>Transferring to virtual reality...</span>")
				var/datum/component/virtual_reality/VR
				if(vr_mob)
					VR = vr_mob.GetComponent(/datum/component/virtual_reality)
				if(!(VR?.connect(M)))
					if(allow_creating_vr_mobs)
						to_chat(occupant, "<span class='warning'>Virtual avatar [vr_mob ? "corrupted" : "missing"], attempting to create one...</span>")
						var/obj/effect/landmark/vr_spawn/V = get_vr_spawnpoint()
						var/turf/T = get_turf(V)
						if(T)
							new_player(occupant, T, V.vr_outfit)
						else
							to_chat(occupant, "<span class='warning'>Virtual world misconfigured, aborting transfer</span>")
					else
						to_chat(occupant, "<span class='warning'>The virtual world does not support the creation of new virtual avatars, aborting transfer</span>")
				else
					to_chat(vr_mob, "<span class='notice'>Transfer successful! You are now playing as [vr_mob] in VR!</span>")
			. = TRUE
		if("delete_avatar")
			if(!occupant || usr == occupant)
				if(vr_mob)
					cleanup_vr_mob()
			else
				to_chat(usr, "<span class='warning'>The VR Sleeper's safeties prevent you from doing that.</span>")
			. = TRUE
		if("toggle_open")
			if(state_open)
				close_machine()
			else if ((!occupant || usr == occupant) || !only_current_user_can_interact)
				open_machine()
			. = TRUE
		if("create_lobby")
			var/mode_name = params["mode"]
			var/datum/map_template/deathmatch/mode = get_deathmatch_map(mode_name)
			// Never swallow this. A button that returns without a word reads as a
			// dead button, and this one used to fail exactly that way.
			if(isnull(mode))
				feedback(usr, span_warning("Unknown deathmatch mode \"[mode_name]\"."))
				return TRUE
			// Already on a roster. The Create buttons are how somebody opens a game,
			// not how they leave the one they are in.
			var/datum/deathmatch_lobby/mine = get_deathmatch_lobby_of(usr.ckey)
			if(!isnull(mine))
				if(mine.template?.name == mode_name)
					feedback(usr, "<span class='notice'>You are already in the [mode.display_name] roster.</span>")
				else
					feedback(usr, "<span class='warning'>You are already in [mine.template.display_name].</span>")
				return TRUE
			// Somebody already recruiting for this mode? Walk in on them rather than
			// opening a second lobby for the same map. A guest can only ever join one,
			// never open one, so this is the only door they have.
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of_mode(mode_name)
			if(!isnull(lobby))
				if(lobby.join(usr))
					feedback(usr, "<span class='notice'>Joined the [mode.display_name] lobby.</span>")
				else
					feedback(usr, "<span class='warning'>[mode.display_name] would not take you. The chat says why.</span>")
				open_lobby_window(usr, lobby)
				return TRUE
			// No lobby for this mode. A guest can only ever join one, never open
			// one, so saying "lie in the sleeper" to somebody standing next to a
			// sleeper they cannot lie in is just a dead end.
			// occupant is a plain /obj machine var, not a typed mob, so both the mind
			// check and the hand-off to start_deathmatch_lobby() need a cast.
			var/mob/host = occupant
			if(usr != host || isnull(host?.mind))
				if(!isnull(host))
					feedback(usr, "<span class='warning'>[host.name] is in the sleeper. Ask them to open a [mode.display_name] lobby.</span>")
				else
					feedback(usr, "<span class='warning'>No [mode.display_name] lobby is open. Lie in a VR sleeper and open one, or wait for a host.</span>")
				return TRUE
			if(!allow_creating_vr_mobs)
				feedback(usr, "<span class='warning'>This sleeper does not open new virtual worlds.</span>")
				return TRUE
			feedback(usr, "<span class='notice'>Opening a [mode.display_name] lobby...</span>")
			var/datum/deathmatch_lobby/started = start_deathmatch_lobby(host, mode_name)
			if(!isnull(started))
				open_lobby_window(usr, started)
			return TRUE
		if("join_lobby")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of_mode(params["map"])
			if(isnull(lobby))
				feedback(usr, span_warning("That lobby is gone."))
				return TRUE
			if(lobby.join(usr))
				feedback(usr, "<span class='notice'>Joined [lobby.template.display_name].</span>")
				open_lobby_window(usr, lobby)
			return TRUE
		if("spectate_lobby")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of_mode(params["map"])
			if(isnull(lobby))
				feedback(usr, span_warning("That lobby is gone."))
				return TRUE
			// join()'s fourth argument seats them as a watcher: a spot at the table and
			// a landmark in the arena, but out of the player count and out of the win.
			if(lobby.join(usr, null, FALSE, TRUE))
				feedback(usr, "<span class='notice'>Watching [lobby.template.display_name].</span>")
				open_lobby_window(usr, lobby)
			return TRUE
		if("view_lobby")
			// Looking does not join. The lobby window opens on the roster, and its
			// state proc closes it again for anybody not at the table, so "View" on
			// somebody else's game shows a roster for as long as the window is open and
			// no longer.
			var/datum/deathmatch_lobby/lobby = get_open_deathmatch_lobby(params["map"])
			if(isnull(lobby))
				feedback(usr, span_warning("That lobby is gone."))
				return TRUE
			lobby.show_roster(usr)
			return TRUE

/**
 * Puts a player's own lobby window in front of them.
 *
 * ui_interact() rather than an explicit UI object, because the lobby is a datum the
 * player does not necessarily own: hand-building a UI here would leave a window that
 * outlives the lobby and one that the state proc then refuses to talk to.
 */
proc/open_lobby_window(mob/user, datum/deathmatch_lobby/lobby)
	if(isnull(user) || isnull(lobby) || lobby.is_finished())
		return
	lobby.ui_interact(user)

/**
 * Puts the browser back in front of somebody who has just left a lobby.
 *
 * Searches for a sleeper the way the ghost button does, because a guest who left a
 * game is usually standing next to the machine they joined it from and would
 * otherwise have to find it again to join the next one.
 */
proc/open_sleeper_browser(mob/user)
	if(isnull(user))
		return
	// A fixed radius: a ghost has no `range()` of its own, and 7 tiles is what they
	// can click a machine from anyway.
	for(var/atom/A as anything in view(7, user))
		if(istype(A, /obj/machinery/vr_sleeper))
			A.ui_interact(user)
			return
	to_chat(user, span_danger("No VR sleeper in sight. Stand next to one to open its panel."))

/**
 * The mode catalogue, sent once.
 *
 * The list of arenas cannot change while the server is up - it is compiled into the
 * dmb - so it belongs in static data rather than riding along on every status
 * update, where it would be re-sent roughly once a second per client.
 */
/obj/machinery/vr_sleeper/ui_static_data(mob/user)
	. = list()
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
	.["modes"] = modes
/obj/machinery/vr_sleeper/ui_data(mob/user)
	var/list/data = list()
	var/is_living
	if(vr_mob && !QDELETED(vr_mob))
		is_living = isliving(vr_mob)
		data["can_delete_avatar"] = TRUE
		data["vr_avatar"] = list("name" = vr_mob.name)
		data["isliving"] = is_living
		if(is_living)
			var/status
			switch(vr_mob.stat)
				if(CONSCIOUS)
					status = "Conscious"
				if(DEAD)
					status = "Dead"
				if(UNCONSCIOUS)
					status = "Unconscious"
				if(SOFT_CRIT)
					status = "Barely Conscious"
			data["vr_avatar"] += list("status" = status, "health" = vr_mob.health, "maxhealth" = vr_mob.maxHealth)
	else
		data["can_delete_avatar"] = FALSE
		data["vr_avatar"] = FALSE
		data["isliving"] = FALSE

	data["toggle_open"] = state_open
	data["emagged"] = you_die_in_the_game_you_die_for_real
	data["isoccupant"] = (user == occupant)
	// Whatever the last button press had to say, read once and cleared. A guest who
	// presses Join is looking at the panel, not at the chat log.
	data["sleeper_notice"] = sleeper_notices[user.ckey]
	sleeper_notices[user.ckey] = null

	//
	// Deathmatch: the browser.
	//
	// Every lobby that is open right now, whoever is hosting it. Not just the ones
	// with room: a running game's roster is the thing a guest standing next to a
	// sleeper most wants to look at, and the Join button on it greys itself out
	// through `joinable` rather than by the row being quietly missing.
	//
	// Rows are plain lists built with UNTYPED_LIST_ADD. The old payload sent flat
	// "deathmatch_lobby_1_name" keys instead, on the theory that a DM list of assoc
	// lists does not survive the trip to the browser; it does, and the flat version
	// was the reason every field had to be read out of a string index.
	//
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
		// player might want to do. A full arena cannot be joined but can be watched;
		// a running one cannot be joined at all, because the roster closed.
		UNTYPED_LIST_ADD(row, !lobby.is_full() && lobby.state == DM_LOBBY_WAITING)
		UNTYPED_LIST_ADD(row, !get_deathmatch_lobby_of(user.ckey))
		UNTYPED_LIST_ADD(lobbies, row)
	data["lobbies"] = lobbies
	var/datum/deathmatch_lobby/mine = get_deathmatch_lobby_of(user.ckey)
	data["in_lobby"] = !isnull(mine)
	data["lobby_map"] = mine?.template?.name
	data["lobby_name"] = mine?.template?.display_name
	data["lobby_running"] = mine?.state == DM_LOBBY_RUNNING
	data["lobby_is_host"] = mine?.is_host(user.ckey) || FALSE
	// Only the occupant may open a lobby, because the machine is where their real
	// body ends up when the game is over. occupant is untyped on /obj/machinery and
	// this codebase is in strict mode.
	var/mob/deathmatch_host = occupant
	data["can_create_lobby"] = (user == deathmatch_host) && !isnull(deathmatch_host?.mind) \
		&& allow_creating_vr_mobs && isnull(mine)
	return data

/obj/machinery/vr_sleeper/proc/get_vr_spawnpoint() //proc so it can be overridden for team games or something
	return safepick(GLOB.vr_spawnpoints[vr_category])

/obj/machinery/vr_sleeper/proc/build_spawnpoints() // used to rebuild the list for admins if need be
	GLOB.vr_spawnpoints = list()
	for(var/obj/effect/landmark/vr_spawn/V in GLOB.landmarks_list)
		GLOB.vr_spawnpoints[V.vr_category] = V

/obj/machinery/vr_sleeper/proc/new_player(mob/M, location, datum/outfit/outfit, transfer = TRUE)
	if(!M)
		return
	cleanup_vr_mob()
	vr_mob = new virtual_mob_type(location)
	if(vr_mob.build_virtual_character(M, outfit) && iscarbon(vr_mob))
		var/mob/living/carbon/C = vr_mob
		C.updateappearance(TRUE, TRUE, TRUE)
	var/datum/component/virtual_reality/VR = vr_mob.AddComponent(/datum/component/virtual_reality, you_die_in_the_game_you_die_for_real)
	if(VR.connect(M))
		RegisterSignal(VR, COMSIG_COMPONENT_UNREGISTER_PARENT, PROC_REF(unset_vr_mob))
		RegisterSignal(VR, COMSIG_COMPONENT_REGISTER_PARENT, PROC_REF(set_vr_mob))
		if(!only_current_user_can_interact)
			VR.RegisterSignal(src, COMSIG_ATOM_EMAG_ACT, TYPE_PROC_REF(/datum/component/virtual_reality, you_only_live_once))
		VR.RegisterSignal(src, COMSIG_MACHINE_EJECT_OCCUPANT, TYPE_PROC_REF(/datum/component/virtual_reality, revert_to_reality))
		VR.RegisterSignal(src, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/datum/component/virtual_reality, machine_destroyed))
		to_chat(vr_mob, "<span class='notice'>Transfer successful! You are now playing as [vr_mob] in VR!</span>")
	else
		to_chat(M, "<span class='notice'>Transfer failed! virtual reality data likely corrupted!</span>")

/obj/machinery/vr_sleeper/proc/unset_vr_mob(datum/component/virtual_reality/VR)
	vr_mob = null

/obj/machinery/vr_sleeper/proc/set_vr_mob(datum/component/virtual_reality/VR)
	vr_mob = VR.parent

/obj/machinery/vr_sleeper/proc/cleanup_vr_mob()
	if(vr_mob)
		QDEL_NULL(vr_mob)

/obj/machinery/vr_sleeper/proc/emagNotify()
	if(vr_mob)
		vr_mob.Dizzy(10)

/obj/effect/landmark/vr_spawn //places you can spawn in VR, auto selected by the vr_sleeper during get_vr_spawnpoint()
	var/vr_category = "default" //So we can have specific sleepers, eg: "Basketball VR Sleeper", etc.
	var/vr_outfit = /datum/outfit/vr

/obj/effect/landmark/vr_spawn/Initialize(mapload)
	. = ..()
	LAZYADD(GLOB.vr_spawnpoints[vr_category], src)

/obj/effect/landmark/vr_spawn/Destroy()
	LAZYREMOVE(GLOB.vr_spawnpoints[vr_category], src)
	return ..()

/obj/effect/landmark/vr_spawn/team_1
	vr_category = "team_1"

/obj/effect/landmark/vr_spawn/team_2
	vr_category = "team_2"

/obj/effect/landmark/vr_spawn/admin
	vr_category = "event"

/obj/effect/landmark/vr_spawn/syndicate // Multiple missions will use syndicate gear
	vr_outfit = /datum/outfit/vr/syndicate

/obj/effect/vr_clean_master // Will keep VR areas that have this relatively clean.
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "x2"
	color = "#00FF00"
	invisibility = INVISIBILITY_ABSTRACT
	var/area/vr_area
	var/list/corpse_party

/obj/effect/vr_clean_master/Initialize(mapload)
	. = ..()
	vr_area = get_base_area(src)
	if(!vr_area)
		return INITIALIZE_HINT_QDEL
	addtimer(CALLBACK(src, PROC_REF(clean_up)), 3 MINUTES, TIMER_LOOP)

/obj/effect/vr_clean_master/proc/clean_up()
	if (!vr_area)
		qdel(src)
		return
	var/list/contents = get_sub_areas_contents(vr_area)
	for (var/obj/item/ammo_casing/casing in contents)
		qdel(casing)
	for(var/obj/effect/decal/cleanable/C in contents)
		qdel(C)
	for (var/A in corpse_party)
		var/mob/M = A
		if(!QDELETED(M) && (M in contents) && M.stat == DEAD)
			qdel(M)
		corpse_party -= M
	addtimer(CALLBACK(src, PROC_REF(clean_up)), 3 MINUTES)
