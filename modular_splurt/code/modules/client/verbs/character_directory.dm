GLOBAL_DATUM(character_directory, /datum/character_directory)

/client
	COOLDOWN_DECLARE(char_directory_cooldown)
	var/list/directory_notes

/client/verb/show_character_directory()
	set name = "Character Directory"
	set category = "OOC"
	set desc = "Shows a listing of all active characters, along with their associated OOC notes, flavor text, and more."

	// This is primarily to stop malicious users from trying to lag the server by spamming this verb
	if(!COOLDOWN_FINISHED(src, char_directory_cooldown))
		to_chat(usr, "<span class='warning'>Don't spam character directory refresh.</span>")
		return
	COOLDOWN_START(src, char_directory_cooldown, 10)

	if(!GLOB.character_directory)
		GLOB.character_directory = new
	GLOB.character_directory.ui_interact(mob)


// This is a global singleton. Keep in mind that all operations should occur on usr, not src.
/datum/character_directory

/datum/character_directory/ui_state(mob/user)
	return GLOB.always_state

/datum/character_directory/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CharacterDirectory", "Библиотека Персонажей")
		ui.open()

/datum/character_directory/ui_data(mob/user)
	. = ..()
	var/list/data = .

	if (user?.mind && !isdead(user))
		data["personalVisibility"] = user.mind.show_in_directory
		data["personalTag"] = user.mind.directory_tag || "Unset"
		data["personalErpTag"] = user.mind.directory_erptag || "Unset"
		data["personalGenderTag"] = user.mind.directory_gendertag || "Unset"
		data["prefsOnly"] = FALSE
	else if (user?.client?.prefs)
		data["personalVisibility"] = user.client.prefs.show_in_directory
		data["personalTag"] = user.client.prefs.directory_tag || "Unset"
		data["personalErpTag"] = user.client.prefs.directory_erptag || "Unset"
		data["personalGenderTag"] = user.client.prefs.directory_gendertag || "Unset"
		data["prefsOnly"] = TRUE

	// Preference-based tags (always from prefs)
	if (user?.client?.prefs)
		data["personalNonconTag"] = user.client.prefs.nonconpref || "No"
		data["personalUnholyTag"] = user.client.prefs.unholypref || "No"
		data["personalExtremeTag"] = user.client.prefs.extremepref || "No"
		data["personalExtremeHarmTag"] = user.client.prefs.extremeharm || "No"
		data["personalHornyAntagsTag"] = user.client.prefs.hornyantagspref || "No"

	data["canOrbit"] = isobserver(user)

	// Personal notes
	if(user?.client)
		if(!user.client.directory_notes)
			user.client.directory_notes = load_player_notes(user.client.ckey)
		data["directory_notes"] = user.client.directory_notes

	return data

/datum/character_directory/ui_static_data(mob/user)
	. = ..()
	var/list/data = .

	var/list/directory_mobs = list()
	for(var/client/C in GLOB.clients)
		// Allow opt-out and filter players not in the game
		if(C?.mob?.mind ? !C.mob.mind.show_in_directory : !C?.prefs?.show_in_directory)
			continue

		// These are the three vars we're trying to find
		// The approach differs based on the mob the client is controlling
		var/name = null
		var/species = null
		var/ooc_notes = null
		var/flavor_text = null
		var/tag
		var/erptag
		var/gendertag
		var/character_ad
		var/noncon_tag
		var/unholy_tag
		var/extreme_tag
		var/extreme_harm_tag
		var/hornyantags_tag
		var/list/headshot_links = list()
		var/ref = REF(C?.mob)
		if (C.mob?.mind) //could use ternary for all three but this is more efficient
			tag = C.mob.mind.directory_tag || "Unset"
			erptag = C.mob.mind.directory_erptag || "Unset"
			gendertag = C.mob.mind.directory_gendertag || "Unset"
			character_ad = C.mob.mind.directory_ad
		else
			tag = C.prefs.directory_tag || "Unset"
			erptag = C.prefs.directory_erptag || "Unset"
			gendertag = C.prefs.directory_gendertag || "Unset"
			character_ad = C.prefs.directory_ad
		// Preference-based tags (always from prefs)
		noncon_tag = C.prefs?.nonconpref || "No"
		unholy_tag = C.prefs?.unholypref || "No"
		extreme_tag = C.prefs?.extremepref || "No"
		extreme_harm_tag = C.prefs?.extremeharm || "No"
		hornyantags_tag = C.prefs?.hornyantagspref || "No"

		if(ishuman(C.mob))
			var/mob/living/carbon/human/H = C.mob
			if(GLOB.data_core && GLOB.data_core.general)
				if(!find_record("name", H.real_name, GLOB.data_core.general))
					continue
			name = H.real_name
			species = "[H.custom_species ? H.custom_species : H.dna.species]"
			ooc_notes = H.mind.ooc_notes
			flavor_text = H.mind.flavor_text
			if(H.dna?.headshot_links)
				headshot_links = H.dna.headshot_links.Copy()

		if(isAI(C.mob))
			var/mob/living/silicon/ai/A = C.mob
			name = A.name
			species = "Artificial Intelligence"
			ooc_notes = A.mind.ooc_notes
			flavor_text = null // No flavor text for AIs :c

		if(iscyborg(C.mob))
			var/mob/living/silicon/robot/R = C.mob
			if(R.scrambledcodes)
				continue
			name = R.name
			species = "Cyborg"
			ooc_notes = R.mind.ooc_notes
			flavor_text = R.mind.silicon_flavor_text

		// It's okay if we fail to find OOC notes and flavor text
		// But if we can't find the name, they must be using a non-compatible mob type currently.
		if(!name)
			continue

		directory_mobs.Add(list(list(
			"name" = name,
			"ckey" = C.ckey,
			"species" = species,
			"ooc_notes" = ooc_notes,
			"tag" = tag,
			"erptag" = erptag,
			"gender_tag" = gendertag,
			"character_ad" = character_ad,
			"flavor_text" = flavor_text,
			"noncon_tag" = noncon_tag,
			"unholy_tag" = unholy_tag,
			"extreme_tag" = extreme_tag,
			"extreme_harm_tag" = extreme_harm_tag,
			"hornyantags_tag" = hornyantags_tag,
			"headshot_links" = headshot_links,
			"ref" = ref
		)))

	data["directory"] = directory_mobs

	return data

/datum/character_directory/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()

	if(.)
		return

	switch(action)
		if("refresh")
			// This is primarily to stop malicious users from trying to lag the server by spamming this verb
			if(!COOLDOWN_FINISHED(usr.client, char_directory_cooldown))
				to_chat(usr, "<span class='warning'>Don't spam character directory refresh.</span>")
				return
			COOLDOWN_START(usr.client, char_directory_cooldown, 10)
			update_static_data(usr, ui)
			return TRUE
		if("orbit")
			var/ref = params["ref"]
			var/mob/dead/observer/ghost = usr
			var/atom/movable/poi = (locate(ref) in GLOB.mob_list) || (locate(ref) in GLOB.poi_list)
			if (poi == null)
				return TRUE
			ghost.ManualFollow(poi)
			ghost.reset_perspective(null)
			return TRUE
		if("setNonconTag")
			if(!usr.client?.prefs)
				return
			var/new_val = tgui_input_list(usr, "Выберите настройку Non-Con", "Non-Con", GLOB.lewd_prefs_choices)
			if(!new_val)
				return
			usr.client.prefs.nonconpref = new_val
			usr.client.prefs.save_character()
			return TRUE
		if("setUnholyTag")
			if(!usr.client?.prefs)
				return
			var/new_val = tgui_input_list(usr, "Выберите настройку Unholy", "Unholy", GLOB.lewd_prefs_choices)
			if(!new_val)
				return
			usr.client.prefs.unholypref = new_val
			usr.client.prefs.save_character()
			return TRUE
		if("setExtremeTag")
			if(!usr.client?.prefs)
				return
			var/new_val = tgui_input_list(usr, "Выберите настройку Extreme", "Extreme", GLOB.lewd_prefs_choices)
			if(!new_val)
				return
			usr.client.prefs.extremepref = new_val
			usr.client.prefs.save_character()
			return TRUE
		if("setExtremeHarmTag")
			if(!usr.client?.prefs)
				return
			var/new_val = tgui_input_list(usr, "Выберите настройку Extreme Harm", "Extreme Harm", GLOB.lewd_prefs_choices)
			if(!new_val)
				return
			usr.client.prefs.extremeharm = new_val
			usr.client.prefs.save_character()
			return TRUE
		if("setHornyAntagsTag")
			if(!usr.client?.prefs)
				return
			var/new_val = tgui_input_list(usr, "Выберите настройку Horny Antags", "Horny Antags", GLOB.lewd_prefs_choices)
			if(!new_val)
				return
			usr.client.prefs.hornyantagspref = new_val
			usr.client.prefs.save_character()
			return TRUE
		if("editNote")
			if(!usr?.client)
				return
			var/target_ckey = params["target_ckey"]
			if(!target_ckey)
				return
			if(!usr.client.directory_notes)
				usr.client.directory_notes = load_player_notes(usr.client.ckey)
			var/current_note = usr.client.directory_notes?[target_ckey]
			var/new_note = strip_html_simple(tgui_input_text(usr, "Заметка об этом игроке", "Личная заметка", current_note, MAX_FLAVOR_LEN, multiline = TRUE, prevent_enter = TRUE), MAX_FLAVOR_LEN)
			if(isnull(new_note))
				return
			if(length(new_note) > 0)
				usr.client.directory_notes[target_ckey] = new_note
			else
				usr.client.directory_notes -= target_ckey
			save_player_notes(usr.client.ckey, usr.client.directory_notes)
			return TRUE
		else
			return check_for_mind_or_prefs(usr, action, params["overwrite_prefs"])

/datum/character_directory/proc/check_for_mind_or_prefs(mob/user, action, overwrite_prefs)
	if (!user.client)
		return
	var/can_set_prefs = overwrite_prefs && !!user.client.prefs
	var/can_set_mind = !!user.mind && !isdead(user)
	if (!can_set_prefs && !can_set_mind)
		if (!overwrite_prefs && !!user.client.prefs)
			to_chat(user, "<span class='warning'>You cannot change these settings if you don't have a mind to save them to. Enable overwriting prefs and switch to a slot you're fine with overwriting.</span>")
		return
	switch(action)
		if ("setTag")
			var/list/new_tag = tgui_input_list(usr, "Pick a new Vore tag for the character directory", "Character Tag", GLOB.char_directory_tags)
			if(!new_tag)
				return
			return set_for_mind_or_prefs(user, action, new_tag, can_set_prefs, can_set_mind)
		if ("setErpTag")
			var/list/new_erptag = tgui_input_list(usr, "Pick a new ERP tag for the character directory", "Character ERP Tag", GLOB.char_directory_erptags)
			if(!new_erptag)
				return
			return set_for_mind_or_prefs(user, action, new_erptag, can_set_prefs, can_set_mind)
		if ("setGenderTag")
			var/list/new_gendertag = tgui_input_list(usr, "Pick a gender tag for the character directory", "Gender Tag", GLOB.char_directory_gendertags)
			if(!new_gendertag)
				return
			return set_for_mind_or_prefs(user, action, new_gendertag, can_set_prefs, can_set_mind)
		if ("setVisible")
			var/visible = TRUE
			if (can_set_mind)
				visible = user.mind.show_in_directory
			else if (can_set_prefs)
				visible = user.client.prefs.show_in_directory
			to_chat(usr, "<span class='notice'>You are now [!visible ? "shown" : "not shown"] in the directory.</span>")
			return set_for_mind_or_prefs(user, action, !visible, can_set_prefs, can_set_mind)
		if ("editAd")
			var/current_ad = (can_set_mind ? usr.mind.directory_ad : null) || (can_set_prefs ? usr.client.prefs.directory_ad : null)
			var/new_ad = strip_html_simple(tgui_input_text(usr, "Change your character ad", "Character Ad", current_ad, MAX_FLAVOR_LEN, multiline = TRUE, prevent_enter = TRUE), MAX_FLAVOR_LEN)
			if(isnull(new_ad))
				return
			return set_for_mind_or_prefs(user, action, new_ad, can_set_prefs, can_set_mind)
		else
			to_chat(usr, span_warning("You can only make temporary changes while in game"))

/datum/character_directory/proc/set_for_mind_or_prefs(mob/user, action, new_value, can_set_prefs, can_set_mind)
	can_set_prefs &&= !!user.client.prefs
	can_set_mind &&= !!user.mind
	if (!can_set_prefs && !can_set_mind)
		to_chat(user, "<span class='warning'>You seem to have lost either your mind, or your current preferences, while changing the values.[action == "editAd" ? " Here is your ad that you wrote. [new_value]" : null]</span>")
		return
	switch(action)
		if ("setTag")
			if (can_set_prefs)
				user.client.prefs.directory_tag = new_value
				user.client.prefs.save_character()
			if (can_set_mind)
				user.mind.directory_tag = new_value
			return TRUE
		if ("setErpTag")
			if (can_set_prefs)
				user.client.prefs.directory_erptag = new_value
				user.client.prefs.save_character()
			if (can_set_mind)
				user.mind.directory_erptag = new_value
			return TRUE
		if ("setGenderTag")
			if (can_set_prefs)
				user.client.prefs.directory_gendertag = new_value
				user.client.prefs.save_character()
			if (can_set_mind)
				user.mind.directory_gendertag = new_value
			return TRUE
		if ("setVisible")
			if (can_set_prefs)
				user.client.prefs.show_in_directory = new_value
				user.client.prefs.save_character()
			if (can_set_mind)
				user.mind.show_in_directory = new_value
			return TRUE
		if ("editAd")
			if (can_set_prefs)
				user.client.prefs.directory_ad = new_value
				user.client.prefs.save_character()
			if (can_set_mind)
				user.mind.directory_ad = new_value
			return TRUE

/datum/character_directory/proc/load_player_notes(ckey)
	var/json_file = file("data/player_saves/[ckey[1]]/[ckey]/directory_notes.json")
	if(!fexists(json_file))
		return list()
	var/raw = file2text(json_file)
	if(!raw)
		return list()
	var/list/data = json_decode(raw)
	if(!islist(data))
		return list()
	return data

/datum/character_directory/proc/save_player_notes(ckey, list/notes)
	var/json_file = file("data/player_saves/[ckey[1]]/[ckey]/directory_notes.json")
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(notes))
