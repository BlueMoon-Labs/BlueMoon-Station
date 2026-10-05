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
 * observer_state would hand a ghost the panel unconditionally, but that skips the
 * range check and would let them drive any sleeper on the map from anywhere.
 */
GLOBAL_DATUM_INIT(sleeper_guest_state, /datum/ui_state/sleeper_guest_state, new)

/datum/ui_state/sleeper_guest_state/can_use_topic(src_object, mob/user)
	if(!user)
		return UI_CLOSE
	// A guest has no hands to reach anything with, so the only sensible test is
	// whether the machine is on their screen. Out of view keeps the window open
	// so they can walk over to it, which is what the observer branch of the shared
	// access check does for them.
	if(isobserver(user))
		if(isnull(user.client))
			return UI_CLOSE
		var/list/view = getviewsize(user.client.view)
		if(isnull(view) || get_dist(src_object, user) >= max(view[1], view[2]))
			return UI_UPDATE
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
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VrSleeper", "VR Sleeper")
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
		if("select_deathmatch_mode")
			var/mode_name = params["mode"]
			var/datum/map_template/deathmatch/mode = get_deathmatch_map(mode_name)
			// Never swallow this. A button that returns without a word reads as a
			// dead button, and this one used to fail exactly that way.
			if(isnull(mode))
				feedback(usr, span_warning("Unknown deathmatch mode \"[mode_name]\"."))
				return TRUE
			var/datum/deathmatch_lobby/mine = get_deathmatch_lobby_of(usr.ckey)
			if(!isnull(mine))
				// Already on a roster. The mode buttons are how a player picks
				// which game to walk into, not how they leave the one they are in.
				// Said either way. Returning quietly here is what made a guest who
				// was already in a lobby think the button was broken.
				if(mine.template?.name == mode_name)
					feedback(usr, "<span class='notice'>You are already in the [mode.display_name] roster.</span>")
				else
					feedback(usr, "<span class='warning'>You are already in [mine.template.display_name].</span>")
				return TRUE
			// Somebody already recruiting for this mode? Walk in on them rather
			// than opening a second lobby for the same map.
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of_mode(mode_name)
			if(!isnull(lobby))
				// join() reports its own refusal in chat, with the detail. Say it here
				// too, so a guest watching the panel finds out at all.
				if(lobby.join(usr))
					feedback(usr, "<span class='notice'>Joined the [mode.display_name] lobby.</span>")
				else
					feedback(usr, "<span class='warning'>[mode.display_name] would not take you. The chat says why.</span>")
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
			start_deathmatch_lobby(host, mode_name)
			return TRUE
		if("select_deathmatch_loadout")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(usr.ckey)
			if(isnull(lobby))
				feedback(usr, span_warning("You are not in a deathmatch lobby."))
				return TRUE
			// An index into the mode's own list, not a type path. See the matching
			// comment in ui_data() for why the path is not trusted back from here.
			var/list/options = lobby.template.get_loadouts()
			var/choice = params["loadout"]
			// The picker sends a JSON number, but a round trip through a URL can
			// leave it as a string, and text2num() on a real number is a no-op
			// that warns. Accept both.
			if(!isnum(choice))
				choice = text2num(choice)
			if(isnum(choice))
				choice = round(choice)
			if(!isnum(choice) || choice < 1 || choice > length(options))
				feedback(usr, span_warning("\"[params["loadout"]]\" is not one of the [lobby.template.display_name] loadouts."))
				return TRUE
			var/datum/outfit/vr/deathmatch_loadout/loadout = options[choice]
			for(var/deathmatch_player_ref as anything in lobby.players)
				var/datum/deathmatch_player/entry = deathmatch_player_ref
				if(entry.ckey != usr.ckey)
					continue
				entry.loadout = loadout.type
				feedback(usr, "<span class='notice'>Loadout set to [lobby.loadout_name(entry.loadout)].</span>")
				break
			. = TRUE
		if("leave_deathmatch")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(usr.ckey)
			if(isnull(lobby))
				return TRUE
			for(var/deathmatch_player_ref as anything in lobby.players.Copy())
				var/datum/deathmatch_player/entry = deathmatch_player_ref
				if(entry.ckey != usr.ckey)
					continue
				lobby.remove_player(entry, "you left")
				break
			. = TRUE
		if("start_deathmatch")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(usr.ckey)
			if(isnull(lobby))
				feedback(usr, "<span class='warning'>You are not in a deathmatch lobby.</span>")
				return TRUE
			if(lobby.host_key != usr.ckey)
				feedback(usr, "<span class='warning'>Only the host can start the game.</span>")
				return TRUE
			if(lobby.state != DM_LOBBY_WAITING)
				return TRUE
			if(lobby.players_needed() > 0)
				feedback(usr, "<span class='warning'>[lobby.players_needed()] more player(s) needed.</span>")
				return TRUE
			feedback(usr, "<span class='notice'>Loading [lobby.template.display_name]...</span>")
			if(lobby.begin_match())
				SStgui.close_user_uis(usr, src)
			. = TRUE
		if("end_deathmatch")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(usr.ckey)
			if(isnull(lobby) || lobby.host_key != usr.ckey)
				feedback(usr, "<span class='warning'>You are not hosting a deathmatch game.</span>")
				return TRUE
			lobby.end_lobby(reason = "the host ended the game")
			. = TRUE

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

	// Deathmatch: only the occupant may open a lobby, because the machine is
	// where their real body ends up when the game is over. Typed, because
	// /obj/machinery/occupant is untyped and this codebase is in strict mode.
	var/mob/deathmatch_host = occupant
	var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(user.ckey)
	// Everything below is sent as flat "deathmatch_*_N_field" keys rather than
	// lists of assoc lists. A DM list of assoc lists reaches the browser as a
	// list of *lists*, so every mode.name/mode.id read as undefined and the mode
	// buttons rendered as bare "()" with nothing to select. Only scalars directly
	// under ui_data survive as JSON object fields.
	var/list/all_modes = get_deathmatch_templates()
	data["deathmatch_mode_count"] = length(all_modes)
	var/mode_index = 0
	for(var/map_ref as anything in all_modes)
		mode_index++
		var/datum/map_template/deathmatch/mode = map_ref
		data["deathmatch_mode_[mode_index]_id"] = mode.name
		data["deathmatch_mode_[mode_index]_name"] = mode.display_name
		data["deathmatch_mode_[mode_index]_description"] = mode.description
		data["deathmatch_mode_[mode_index]_players"] = "[mode.min_players]-[mode.max_players]"
		data["deathmatch_mode_[mode_index]_waiting"] = get_deathmatch_lobby_of_mode(mode.name)?.player_count()

	// Only the mode this player is actually in. Sending every loadout in the game
	// put a sniper rifle one click away from the Security Ring, where the map is
	// balanced around disablers.
	var/list/all_loadouts = lobby?.template?.get_loadouts() || list()
	data["deathmatch_loadout_count"] = length(all_loadouts)
	// The browser gets an index, never a type path. A path is a long string that
	// has to survive a JSON round trip to come back as the same string, and when
	// it did not the picker reported every loadout as unknown. An index into a
	// list DM is holding cannot drift like that, and the list is regenerated in
	// the same order for every player.
	var/loadout_index = 0
	for(var/loadout_ref as anything in all_loadouts)
		loadout_index++
		var/datum/outfit/vr/deathmatch_loadout/loadout = loadout_ref
		data["deathmatch_loadout_[loadout_index]_id"] = loadout_index
		data["deathmatch_loadout_[loadout_index]_name"] = loadout.name

	// This player's own roster entry, which is what the loadout picker writes to.
	var/datum/deathmatch_player/self_entry
	if(!isnull(lobby))
		for(var/player_ref as anything in lobby.players)
			var/datum/deathmatch_player/entry = player_ref
			if(entry.ckey == user.ckey)
				self_entry = entry
				break

	data["in_deathmatch_lobby"] = !isnull(lobby)
	data["deathmatch_lobby_mode"] = lobby?.template?.name
	data["deathmatch_lobby_name"] = lobby?.template?.display_name
	data["deathmatch_lobby_running"] = lobby?.state == DM_LOBBY_RUNNING
	data["deathmatch_player_count"] = lobby?.player_count() || 0
	data["deathmatch_min_players"] = lobby?.template?.min_players || 2
	data["deathmatch_players_needed"] = lobby?.players_needed() || 0
	data["deathmatch_selected_loadout"] = null
	if(!isnull(self_entry))
		// The player's own kit, reported as the index the picker uses, so the
		// button can highlight what they are actually going to spawn in. Matched
		// on the type path by hand: all_loadouts holds datums and self_entry.loadout
		// holds a path, so list.Find() would never equate them.
		var/self_index = 0
		for(var/option_ref as anything in all_loadouts)
			self_index++
			var/datum/outfit/vr/deathmatch_loadout/option = option_ref
			if(option.type == self_entry.loadout)
				data["deathmatch_selected_loadout"] = self_index
				break
	data["deathmatch_roster_count"] = length(lobby?.players)
	var/roster_index = 0
	if(!isnull(lobby))
		for(var/player_ref as anything in lobby.players)
			roster_index++
			var/datum/deathmatch_player/entry = player_ref
			data["deathmatch_roster_[roster_index]_name"] = entry.display_name
			data["deathmatch_roster_[roster_index]_host"] = entry.is_host
			data["deathmatch_roster_[roster_index]_loadout"] = lobby.loadout_name(entry.loadout)
			data["deathmatch_roster_[roster_index]_self"] = (entry == self_entry)

	// The Start button greys itself out on the same number begin_match() refuses
	// on, so the two can never disagree about who may start.
	data["can_start_deathmatch"] = (user == deathmatch_host) && !isnull(deathmatch_host?.mind) \
		&& allow_creating_vr_mobs && !isnull(lobby) && (lobby.host_key == user.ckey) \
		&& (lobby.state == DM_LOBBY_WAITING) && (lobby.players_needed() <= 0)
	data["is_hosting_deathmatch"] = !isnull(lobby) && (lobby.host_key == user.ckey)
	data["hosting_deathmatch"] = null
	if(data["is_hosting_deathmatch"])
		data["hosting_deathmatch"] = list("name" = lobby.template.display_name, "players" = lobby.player_count())
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
