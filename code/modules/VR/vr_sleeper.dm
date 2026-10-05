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
	if(user == occupant)
		return GLOB.contained_state
	return GLOB.default_state

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

/obj/machinery/vr_sleeper/ui_act(action, params)
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
			var/datum/map_template/deathmatch/mode = get_deathmatch_map(params["mode"])
			if(isnull(mode))
				return TRUE
			var/datum/deathmatch_lobby/mine = get_deathmatch_lobby_of(usr.ckey)
			if(!isnull(mine))
				// Already on a roster. The mode buttons are how a player picks
				// which game to walk into, not how they leave the one they are in.
				if(mine.template?.name != params["mode"])
					to_chat(usr, "<span class='warning'>You are already in [mine.template.display_name].</span>")
				return TRUE
			// Somebody already recruiting for this mode? Walk in on them rather
			// than opening a second lobby for the same map.
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of_mode(params["mode"])
			if(!isnull(lobby))
				if(lobby.join(usr))
					to_chat(usr, "<span class='notice'>Joined the [mode.display_name] lobby.</span>")
				return TRUE
			// Nobody recruiting, so this player is opening one. That takes the
			// sleeper they are lying in, because that machine is where their real
			// body ends up when the game is over.
			var/mob/host_mob = occupant
			if(usr != host_mob || !host_mob?.mind)
				to_chat(usr, "<span class='warning'>Lie in the sleeper to open a deathmatch lobby.</span>")
				return TRUE
			if(!allow_creating_vr_mobs)
				to_chat(usr, "<span class='warning'>This sleeper does not open new virtual worlds.</span>")
				return TRUE
			to_chat(usr, "<span class='notice'>Opening a [mode.display_name] lobby...</span>")
			start_deathmatch_lobby(host_mob, params["mode"])
			. = TRUE
		if("select_deathmatch_loadout")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(usr.ckey)
			if(isnull(lobby))
				return TRUE
			var/datum/outfit/vr/deathmatch_loadout/loadout = get_deathmatch_loadout(params["loadout"])
			if(isnull(loadout))
				return TRUE
			// Refuse anything this mode does not offer, so a stale window or a
			// hand-rolled packet cannot equip a kit the arena was not balanced for.
			if(!(loadout in lobby.template.get_loadouts()))
				return TRUE
			for(var/deathmatch_player_ref as anything in lobby.players)
				var/datum/deathmatch_player/entry = deathmatch_player_ref
				if(entry.ckey != usr.ckey)
					continue
				entry.loadout = loadout.type
				to_chat(usr, "<span class='notice'>Loadout set to [lobby.loadout_name(entry.loadout)].</span>")
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
				to_chat(usr, "<span class='warning'>You are not in a deathmatch lobby.</span>")
				return TRUE
			if(lobby.host_key != usr.ckey)
				to_chat(usr, "<span class='warning'>Only the host can start the game.</span>")
				return TRUE
			if(lobby.state != DM_LOBBY_WAITING)
				return TRUE
			if(lobby.players_needed() > 0)
				to_chat(usr, "<span class='warning'>[lobby.players_needed()] more player(s) needed.</span>")
				return TRUE
			to_chat(usr, "<span class='notice'>Loading [lobby.template.display_name]...</span>")
			if(lobby.begin_match())
				SStgui.close_user_uis(usr, src)
			. = TRUE
		if("end_deathmatch")
			var/datum/deathmatch_lobby/lobby = get_deathmatch_lobby_of(usr.ckey)
			if(isnull(lobby) || lobby.host_key != usr.ckey)
				to_chat(usr, "<span class='warning'>You are not hosting a deathmatch game.</span>")
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
	var/loadout_index = 0
	for(var/loadout_ref as anything in all_loadouts)
		loadout_index++
		var/datum/outfit/vr/deathmatch_loadout/loadout = loadout_ref
		data["deathmatch_loadout_[loadout_index]_id"] = loadout.type
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
	data["deathmatch_selected_loadout"] = self_entry?.loadout
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
