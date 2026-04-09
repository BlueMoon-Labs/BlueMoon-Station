/mob/living/silicon
	gender = NEUTER
	silicon_privileges = PRIVILEGES_SILICON
	verb_say = "states"
	verb_ask = "queries"
	verb_exclaim = "declares"
	verb_yell = "alarms"
	initial_language_holder = /datum/language_holder/synthetic
	see_in_dark = 8
	bubble_icon = "machine"
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)
	mob_biotypes = MOB_ROBOTIC
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	speech_span = SPAN_ROBOT
	deathsound = 'sound/voice/borg_deathsound.ogg'
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1 | HEAR_1

	var/datum/ai_laws/laws = null//Now... THEY ALL CAN ALL HAVE LAWS
	var/last_lawchange_announce = 0
	var/list/alarms_to_show = list()
	var/list/alarms_to_clear = list()
	var/designation = ""
	var/radiomod = "" //Radio character used before state laws/arrivals announce to allow department transmissions, default, or none at all.
	var/obj/item/camera/siliconcam/aicamera = null //photography
	hud_possible = list(ANTAG_HUD, DIAG_STAT_HUD, DIAG_HUD, DIAG_TRACK_HUD)

	var/obj/item/radio/borg/radio = null //AIs dont use this but this is at the silicon level to advoid copypasta in say()

	var/list/alarm_types_show = list(ALARM_ATMOS = 0, ALARM_FIRE = 0, ALARM_POWER = 0, ALARM_CAMERA = 0, ALARM_MOTION = 0)
	var/list/alarm_types_clear = list(ALARM_ATMOS = 0, ALARM_FIRE = 0, ALARM_POWER = 0, ALARM_CAMERA = 0, ALARM_MOTION = 0)

	var/list/lawcheck = list()
	var/list/ioncheck = list()
	var/list/hackedcheck = list()
	var/devillawcheck[5]

	var/sensors_on = 0
	var/med_hud = DATA_HUD_MEDICAL_ADVANCED //Determines the med hud to use
	var/sec_hud = DATA_HUD_SECURITY_ADVANCED //Determines the sec hud to use
	var/d_hud = DATA_HUD_DIAGNOSTIC_BASIC //Determines the diag hud to use

	var/law_change_counter = 0
	var/next_upload_console_law_change = 0
	var/obj/machinery/camera/builtInCamera = null
	var/updating = FALSE //portable camera camerachunk update

	///Whether we have been emagged
	var/emagged = FALSE
	var/hack_software = FALSE //Will be able to use hacking actions
	var/interaction_range = 7			//wireless control range

	typing_indicator_state = /obj/effect/overlay/typing_indicator/machine

	vocal_bark_id = "synth"
	vocal_pitch_range = 0.1

/mob/living/silicon/Initialize(mapload)
	. = ..()
	GLOB.silicon_mobs += src
	faction += "silicon"
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.all_huds)
		diag_hud.add_to_hud(src)
	diag_hud_set_status()
	diag_hud_set_health()
	ADD_TRAIT(src, TRAIT_ASHSTORM_IMMUNE, ROUNDSTART_TRAIT)

/mob/living/silicon/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/flavor_text, _name = "Silicon Flavor Text", _save_key = "silicon_flavor_text")
	AddElement(/datum/element/flavor_text, "", "Temporary Flavor Text", "This should be used only for things pertaining to the current round!", _save_key = null)
	AddElement(/datum/element/flavor_text, _name = "OOC Notes", _addendum = "Put information on ERP/vore/lewd-related preferences here. THIS SHOULD NOT CONTAIN REGULAR FLAVORTEXT!!", _save_key = "ooc_notes", _examine_no_preview = TRUE)

/mob/living/silicon/Destroy()
	QDEL_NULL(radio)
	QDEL_NULL(aicamera)
	QDEL_NULL(builtInCamera)
	QDEL_NULL(laws)
	GLOB.silicon_mobs -= src
	return ..()

/mob/living/silicon/med_hud_set_health()
	return //we use a different hud

/mob/living/silicon/med_hud_set_status()
	return //we use a different hud

/mob/living/silicon/contents_explosion(severity, target, origin)
	return

/mob/living/silicon/proc/queueAlarm(message, type, incoming = FALSE)
	var/in_cooldown = (alarms_to_show.len > 0 || alarms_to_clear.len > 0)
	if(incoming)
		alarms_to_show += message
		alarm_types_show[type] += 1
	else
		alarms_to_clear += message
		alarm_types_clear[type] += 1
	if(in_cooldown)
		return
	addtimer(CALLBACK(src, PROC_REF(show_alarms)), 3 SECONDS)

/mob/living/silicon/proc/show_alarms()
	if(alarms_to_show.len < 5)
		for(var/msg in alarms_to_show)
			to_chat(src, msg)
	else if(alarms_to_show.len)

		var/msg = "--- "
		for(var/alarm_type in alarm_types_show)
			msg += "[uppertext(alarm_type)]: [alarm_types_show[alarm_type]] alarms detected. - "

		msg += "<A href=?src=[REF(src)];showalerts=1'>\[Show Alerts\]</a>"
		to_chat(src, msg)
	if(alarms_to_clear.len < 3)
		for(var/msg in alarms_to_clear)
			to_chat(src, msg)
	else if(alarms_to_clear.len)
		var/msg = "--- "

		for(var/alarm_type in alarm_types_clear)
			msg += "[uppertext(alarm_type)]: [alarm_types_clear[alarm_type]] alarms cleared. - "

		msg += "<A href=?src=[REF(src)];showalerts=1'>\[Show Alerts\]</a>"
		to_chat(src, msg)
	alarms_to_show.Cut()
	alarms_to_clear.Cut()
	for(var/key in alarm_types_show)
		alarm_types_show[key] = 0
	for(var/key in alarm_types_clear)
		alarm_types_clear[key] = 0

/mob/living/silicon/can_inject(mob/user, error_msg, target_zone, penetrate_thick = FALSE, bypass_immunity = FALSE)
	if(error_msg)
		to_chat(user, "<span class='alert'>[ru_ego(TRUE)] outer shell is too tough.</span>")
	return FALSE

/mob/living/silicon/IsAdvancedToolUser()
	return TRUE

/proc/islinked(mob/living/silicon/robot/bot, mob/living/silicon/ai/ai)
	if(!istype(bot) || !istype(ai))
		return FALSE
	if(bot.connected_ai == ai)
		return TRUE
	return FALSE

/mob/living/silicon/Topic(href, href_list)
	if (href_list["lawc"]) // Toggling whether or not a law gets stated by the State Laws verb --NeoFite
		var/L = text2num(href_list["lawc"])
		switch(lawcheck[L+1])
			if ("Yes")
				lawcheck[L+1] = "No"
			if ("No")
				lawcheck[L+1] = "Yes"
		checklaws()

	if (href_list["lawi"]) // Toggling whether or not a law gets stated by the State Laws verb --NeoFite
		var/L = text2num(href_list["lawi"])
		switch(ioncheck[L])
			if ("Yes")
				ioncheck[L] = "No"
			if ("No")
				ioncheck[L] = "Yes"
		checklaws()

	if (href_list["lawh"])
		var/L = text2num(href_list["lawh"])
		switch(hackedcheck[L])
			if ("Yes")
				hackedcheck[L] = "No"
			if ("No")
				hackedcheck[L] = "Yes"
		checklaws()

	if (href_list["lawdevil"]) // Toggling whether or not a law gets stated by the State Laws verb --NeoFite
		var/L = text2num(href_list["lawdevil"])
		switch(devillawcheck[L])
			if ("Yes")
				devillawcheck[L] = "No"
			if ("No")
				devillawcheck[L] = "Yes"
		checklaws()


	if (href_list["laws"]) // With how my law selection code works, I changed statelaws from a verb to a proc, and call it through my law selection panel. --NeoFite
		statelaws()

	return

// (ADD) Pe4henika bluemoon -- start
// MARK: New statelaws
/mob/living/silicon/proc/statelaws(force = 0)
	var/is_radio = (radiomod != "none")
	var/prefix = is_radio ? "[radiomod] " : ""
	say("[prefix]Текущие законы:")
	var/number = 1
	sleep(10)
	if(!lawcheck) lawcheck = list()
	if(!ioncheck) ioncheck = list()
	if(!hackedcheck) hackedcheck = list()

	if(laws.devillaws && laws.devillaws.len)
		for(var/i in 1 to laws.devillaws.len)
			if(force || (devillawcheck.len < i || devillawcheck[i] != "No"))
				say("[prefix] 666. [laws.devillaws[i]]")
				sleep(10)

	if(laws.zeroth)
		if(force || (lawcheck.len < 1 || lawcheck[1] != "No"))
			say("[prefix] 0. [laws.zeroth]")
			sleep(10)

	for(var/i in 1 to laws.hacked.len)
		var/law = laws.hacked[i]
		if(length(law) > 0)
			if(force || (hackedcheck.len < i || hackedcheck[i] != "No"))
				say("[prefix] [ionnum()]. [law]")
				sleep(10)

	for(var/i in 1 to laws.ion.len)
		var/law = laws.ion[i]
		if(length(law) > 0)
			if(force || (ioncheck.len < i || ioncheck[i] != "No"))
				say("[prefix] [ionnum()]. [law]")
				sleep(10)

	for(var/i in 1 to laws.inherent.len)
		var/law = laws.inherent[i]
		if(length(law) > 0)
			if(force || (lawcheck.len < i + 1 || lawcheck[i + 1] != "No"))
				say("[prefix] [number]. [law]")
				sleep(10)
			number++

	var/inh_offset = laws.inherent.len + 1
	for(var/i in 1 to laws.supplied.len)
		var/law = laws.supplied[i]
		if(length(law) > 0)
			var/check_idx = inh_offset + i
			if(force || (lawcheck.len < check_idx || lawcheck[check_idx] != "No"))
				say("[prefix] [number]. [law]")
				sleep(10)
			number++

// MARK: New TGUI Law menu

/mob/living/silicon/proc/checklaws()
	var/datum/tgui/ui = SStgui.get_open_ui(src, src, "LawManager")
	if(!ui)
		ui = new(src, src, "LawManager", "Менеджер Законов")
		ui.open()

/mob/living/silicon/proc/update_law_menu()
	var/datum/tgui/ui = SStgui.get_open_ui(src, src, "LawManager")
	if(ui)
		ui.send_full_update()
/mob/living/silicon/ui_data(mob/user)
	var/list/data = list()
	var/list/laws_to_send = list()

	src.laws_sanity_check()

	if(!laws)
		data["laws"] = list()
		return data

	// 1. DEVIL LAWS (Тип: zeroth для красной подсветки)
	if(laws.devillaws && laws.devillaws.len)
		for(var/i in 1 to laws.devillaws.len)
			laws_to_send += list(list(
				"id" = "devil-[i]",
				"index" = i,
				"name" = "666",
				"text" = "[laws.devillaws[i]]",
				"active" = (devillawcheck && devillawcheck.len >= i && devillawcheck[i] == "No") ? 0 : 1,
				"type" = "zeroth"
			))

	// 2. ZEROTH (Тип: zeroth)
	if(laws.zeroth)
		laws_to_send += list(list(
			"id" = "zero",
			"index" = 0,
			"name" = "0",
			"text" = "[laws.zeroth]",
			"active" = (lawcheck && lawcheck.len >= 1 && lawcheck[1] == "No") ? 0 : 1,
			"type" = "zeroth"
		))

	// 3. ION / HACKED (Тип: ion)
	var/list/glitch = list()
	if(laws.hacked) glitch += laws.hacked
	if(laws.ion) glitch += laws.ion

	for(var/i in 1 to glitch.len)
		laws_to_send += list(list(
			"id" = "ion-[i]",
			"index" = i,
			"name" = "ION",
			"text" = "[glitch[i]]",
			"active" = 1,
			"type" = "ion"
		))

	// 4. INHERENT (Тип: inherent)
	var/l_num = 1
	if(laws.inherent && laws.inherent.len)
		for(var/i in 1 to laws.inherent.len)
			laws_to_send += list(list(
				"id" = "inh-[i]",
				"index" = i,
				"name" = "[l_num++]",
				"text" = "[laws.inherent[i]]",
				"active" = (lawcheck && lawcheck.len >= i + 1 && lawcheck[i + 1] == "No") ? 0 : 1,
				"type" = "inherent"
			))

	// 5. SUPPLIED (Тип: supplied)
	if(laws.supplied && laws.supplied.len)
		var/off = laws.inherent.len + 1
		for(var/i in 1 to laws.supplied.len)
			laws_to_send += list(list(
				"id" = "sup-[i]",
				"index" = i,
				"name" = "[l_num++]",
				"text" = "[laws.supplied[i]]",
				"active" = (lawcheck && lawcheck.len >= off + i && lawcheck[off + i] == "No") ? 0 : 1,
				"type" = "supplied"
			))

	data["laws"] = laws_to_send
	return data
/mob/living/silicon/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("state_laws")
			src.statelaws()
			return TRUE
		if("toggle_law")
			var/type = params["type"]
			var/idx = text2num(params["index"])
			switch(type)
				if("zeroth")
					if(lawcheck.len < 1) lawcheck.len = 1
					lawcheck[1] = (lawcheck[1] == "No" ? "Yes" : "No")
				if("ion")
					if(ioncheck.len < idx) ioncheck.len = idx
					ioncheck[idx] = (ioncheck[idx] == "No" ? "Yes" : "No")
				if("hacked")
					if(hackedcheck.len < idx) hackedcheck.len = idx
					hackedcheck[idx] = (hackedcheck[idx] == "No" ? "Yes" : "No")
				if("inherent")
					if(lawcheck.len < idx + 1) lawcheck.len = idx + 1
					lawcheck[idx+1] = (lawcheck[idx+1] == "No" ? "Yes" : "No")
				if("supplied")
					var/true_idx = laws.inherent.len + idx + 1
					if(lawcheck.len < true_idx) lawcheck.len = true_idx
					lawcheck[true_idx] = (lawcheck[true_idx] == "No" ? "Yes" : "No")
			return TRUE
// (ADD) Pe4henika bluemoon -- end

/mob/living/silicon/proc/set_autosay() //For allowing the AI and borgs to set the radio behavior of auto announcements (state laws, arrivals).
	if(!radio)
		to_chat(src, "Radio not detected.")
		return

	//Ask the user to pick a channel from what it has available.
	var/Autochan = input("Select a channel:") as null|anything in list("Default","None") + radio.channels

	if(!Autochan)
		return
	if(Autochan == "Default") //Autospeak on whatever frequency to which the radio is set, usually Common.
		radiomod = ";"
		Autochan += " ([radio.frequency])"
	else if(Autochan == "None") //Prevents use of the radio for automatic annoucements.
		radiomod = ""
	else	//For department channels, if any, given by the internal radio.
		for(var/key in GLOB.department_radio_keys)
			if(GLOB.department_radio_keys[key] == Autochan)
				radiomod = ":" + key
				break

	to_chat(src, "<span class='notice'>Automatic announcements [Autochan == "None" ? "will not use the radio." : "set to [Autochan]."]</span>")

/mob/living/silicon/put_in_hand_check() // This check is for borgs being able to receive items, not put them in others' hands.
	return FALSE

// The src mob is trying to place an item on someone
// But the src mob is a silicon!!  Disable.
/mob/living/silicon/stripPanelEquip(obj/item/what, mob/who, slot)
	return FALSE


/mob/living/silicon/assess_threat(judgement_criteria, lasercolor = "", datum/callback/weaponcheck=null) //Secbots won't hunt silicon units
	return -10

/mob/living/silicon/proc/remove_sensors()
	var/datum/atom_hud/secsensor = GLOB.huds[sec_hud]
	var/datum/atom_hud/medsensor = GLOB.huds[med_hud]
	var/datum/atom_hud/diagsensor = GLOB.huds[d_hud]
	secsensor.remove_hud_from(src)
	medsensor.remove_hud_from(src)
	diagsensor.remove_hud_from(src)

/mob/living/silicon/proc/add_sensors()
	var/datum/atom_hud/secsensor = GLOB.huds[sec_hud]
	var/datum/atom_hud/medsensor = GLOB.huds[med_hud]
	var/datum/atom_hud/diagsensor = GLOB.huds[d_hud]
	secsensor.add_hud_to(src)
	medsensor.add_hud_to(src)
	diagsensor.add_hud_to(src)

/mob/living/silicon/proc/toggle_sensors()
	if(incapacitated())
		return
	sensors_on = !sensors_on
	if (!sensors_on)
		to_chat(src, "Sensor overlay deactivated.")
		remove_sensors()
		return
	add_sensors()
	to_chat(src, "Sensor overlay activated.")

/mob/living/silicon/proc/GetPhoto(mob/user)
	if (aicamera)
		return aicamera.selectpicture(user)

/mob/living/silicon/proc/ai_roster()
	if(!client)
		return
	if(world.time < client.crew_manifest_delay)
		return
	client.crew_manifest_delay = world.time + (1 SECONDS)

	if(!GLOB.crew_manifest_tgui)
		GLOB.crew_manifest_tgui = new /datum/crew_manifest(src)

	GLOB.crew_manifest_tgui.ui_interact(src)

/mob/living/silicon/is_literate()
	return TRUE

/mob/living/silicon/get_inactive_held_item()
	return FALSE

/mob/living/silicon/handle_high_gravity(gravity)
	return

/mob/living/silicon/rust_heretic_act()
	adjustBruteLoss(500)
