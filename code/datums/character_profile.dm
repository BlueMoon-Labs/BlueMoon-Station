/mob/living/carbon/human
	var/datum/description_profile/profile

/mob/living/silicon/robot
	var/datum/description_profile/robot/profile

/client/verb/regenerate_cached_character_appearance()
	set name = "Regenerate Cached Profile Appearance"
	set category = "OOC"
	set desc = "Regenerates the cached appearance of your character in their profile."

	if (usr.name in GLOB.cached_previews)
		GLOB.cached_previews[usr.name] = getFlatIcon(usr)
		to_chat(usr, span_notice("Your cached appearance has been regenerated."))
	else
		to_chat(usr, span_boldwarning("Your current mob was not found in the appearance cache."))

GLOBAL_LIST_EMPTY(cached_previews)

/datum/description_profile
	var/datum/weakref/host
	var/list/viewer_screens
	var/current_bg_state = "plating"
	var/static/list/preview_backgrounds = list("plating", "engine", "showroomfloor", "freezerfloor", "floor_padded", "grimy")

/datum/description_profile/New(var/host_mob)
	. = ..()
	host = WEAKREF(host_mob)


/datum/description_profile/Destroy(force, ...)
	SStgui.close_uis(src)
	var/mob/M = host?.resolve()
	if(M)
		UnregisterSignal(M, COMSIG_ATOM_UPDATED_ICON)
	host = null
	for(var/mob/viewer as anything in viewer_screens)
		var/atom/movable/screen/map_view/viewer_screen = viewer_screens[viewer]
		if(viewer_screen)
			viewer_screen.hide_from(viewer)
			qdel(viewer_screen)
	viewer_screens = null
	return ..()

/datum/description_profile/proc/on_host_icon_updated(datum/source, updates, result)
	SIGNAL_HANDLER
	update_preview()

/datum/description_profile/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(. <= UI_DISABLED)
		return .
	var/mob/M = host.resolve()
	if(M in view(10, user))
		return .
	else if(get_turf(M) == get_turf(user))
		return .
	else
		return UI_UPDATE

/datum/description_profile/ui_state()
	return GLOB.always_state

/datum/description_profile/ui_close(mob/user)
	var/atom/movable/screen/map_view/viewer_screen = LAZYACCESS(viewer_screens, user)
	LAZYREMOVE(viewer_screens, user)
	if(viewer_screen)
		viewer_screen.hide_from(user)
		qdel(viewer_screen)

/atom/movable/screen/map_view/examine_panel_screen
	name = "description profile screen"
	icon = 'icons/turf/floors.dmi'
	icon_state = "plating"

/atom/movable/screen/map_view/examine_panel_screen/proc/update_character(mob/target)
	var/mutable_appearance/current_mob_appearance = new(target)
	current_mob_appearance.setDir(SOUTH)
	current_mob_appearance.transform = matrix()
	current_mob_appearance.pixel_x = 0
	current_mob_appearance.pixel_y = 0
	cut_overlays()
	add_overlay(current_mob_appearance)

/datum/description_profile/ui_static_data(mob/user, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/data[0]
	var/mob/living/M = host.resolve()

	data["directory_visible"] = M?.client?.prefs?.show_in_directory

	// BLUEMOON EDIT START - перепривязка к ДНК и майнду флаворов

	if(iscarbon(M))
		var/mob/living/carbon/H = M
		data["oocnotes"] = H.dna?.ooc_notes || ""
		// mechanical_erp_verbs_examine AHEAD
		if(H.client?.prefs.toggles & VERB_CONSENT)
			data["erp_verbs"] = "Allowed"
		else
			data["erp_verbs"] = "Text Only"
		// mechanical_erp_verbs_examine END
	if (isobserver(user))
		data["security_records"] = M?.client?.prefs.security_records || "" //BLUEMOON ADD - призраки видят базы данных в описании персонажей
		data["medical_records"] = M?.client?.prefs.medical_records || "" //BLUEMOON ADD - призраки видят базы данных в описании персонажей
	// BLUEMOON EDIT END
	data["vore_tag"] = M?.client?.prefs?.vorepref || "No"
	data["erp_tag"] = M?.client?.prefs?.erppref || "No"
	data["mob_tag"] = M?.client?.prefs?.mobsexpref || "No"
	data["hornyantags_tag"] = M?.client?.prefs?.hornyantagspref || "No"
	data["nc_tag"] = M?.client?.prefs?.nonconpref || "No"
	data["unholy_tag"] = M?.client?.prefs?.unholypref || "No"
	data["extreme_tag"] = M?.client?.prefs?.extremepref || "No"
	data["very_extreme_tag"] = M?.client?.prefs?.extremeharm || "No"

	return data

/datum/description_profile/ui_data(mob/user)
	. = ..()
	var/data[0]
	var/mob/living/M = host.resolve()
	var/unknown = FALSE

	var/atom/movable/screen/map_view/examine_panel_screen/viewer_screen = LAZYACCESS(viewer_screens, user)
	data["character_ref"] = viewer_screen?.assigned_map
	// BLUEMOON EDIT START - правка видимости текстов персонажа и привязка их к ДНК
	if (iscarbon(M))
		var/mob/living/carbon/C = M
		unknown = (C.wear_mask && (C.wear_mask.flags_inv & HIDEEYES) && !isobserver(user)) || (C.head && (C.head.flags_inv & HIDEEYES) && !isobserver(user))
		data["flavortext"] = (!unknown) ? (C.dna?.flavor_text || "") : "Скрыто"
		data["headshot_links"] = (!unknown) ? (C.dna.headshot_links.Copy() || "") : list()
		data["species_name"] = (!unknown) ? (C.dna?.custom_species || C.dna?.species) : "????"
		data["custom_species_lore"] = (!unknown) ? (C.dna?.custom_species_lore || "")  : ""
		if (istype(M, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = C
			var/can_see_naked = TRUE
			var/list/obj/item/clothings = list(
				H.wear_suit,
				H.w_uniform,
				H.belt,
				H.w_underwear,
				H.w_socks,
				H.w_shirt,
				H.wrists,
				H.wear_neck
			)
			removeNullsFromList(clothings)
			for (var/obj/item/clothing/clothpiece in clothings)
				if(clothpiece.body_parts_covered & GROIN || clothpiece.body_parts_covered & CHEST)
					can_see_naked = FALSE
					break
			data["flavortext_naked"] = can_see_naked ? (C.dna?.naked_flavor_text || "") : ""
			data["headshot_naked_links"] =  (check_rights_for(user.client, R_ADMIN) && isobserver(user)) || ((!unknown) && can_see_naked) ? (C.dna.headshot_naked_links.Copy() || "") : list()
	// BLUEMOON EDIT END

	data["is_unknown"] = unknown

	return data

/datum/description_profile/proc/update_preview(mob/user)
	var/mob/living/M = host.resolve()
	if(!M)
		return

	var/list/screens_to_update = list()
	if(user)
		var/atom/movable/screen/map_view/examine_panel_screen/vs = LAZYACCESS(viewer_screens, user)
		if(vs)
			screens_to_update += vs
	else
		for(var/mob/viewer in viewer_screens)
			screens_to_update += viewer_screens[viewer]

	for(var/atom/movable/screen/map_view/examine_panel_screen/vs as anything in screens_to_update)
		vs.icon_state = current_bg_state
		vs.update_character(M)

/datum/description_profile/ui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	var/mob/living/M = host.resolve()

	var/atom/movable/screen/map_view/examine_panel_screen/viewer_screen = LAZYACCESS(viewer_screens, user)
	if(isnull(viewer_screen))
		viewer_screen = new
		viewer_screen.generate_view("examine_panel_[REF(M)]_[REF(user)]_map")
		LAZYSET(viewer_screens, user, viewer_screen)

	viewer_screen.icon_state = current_bg_state
	viewer_screen.update_character(M)

	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "CharacterProfile", "Профиль персонажа [M]")
		ui.open()
		viewer_screen.display_to(user, ui.window)

/datum/description_profile/ui_act(action, list/params)
	. = ..()
	if (.)
		return

	var/atom/movable/screen/map_view/examine_panel_screen/viewer_screen = LAZYACCESS(viewer_screens, usr)

	switch (action)
		if("character_directory")
			var/static/datum/character_directory/character_directory = new
			character_directory.ui_interact(usr)
		if("char_right")
			if(viewer_screen)
				viewer_screen.setDir(turn(viewer_screen.dir, -90))
		if("char_left")
			if(viewer_screen)
				viewer_screen.setDir(turn(viewer_screen.dir, 90))
		if("change_background")
			current_bg_state = next_list_item(current_bg_state, preview_backgrounds)
			update_preview()
			return TRUE


/datum/description_profile/robot/ui_interact(mob/user, datum/tgui/ui)
	var/mob/living/M = host.resolve()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyborgProfile", "Профиль юнита [M || "неизвестный юнит"]")
		ui.open()

/datum/description_profile/robot/ui_static_data(mob/user, datum/tgui/ui, datum/ui_state/state)
	var/data[0]
	var/mob/living/M = host.resolve()
	if(!M || !istype(M))
		return
	if(M.mind)
		data["silicon_flavor_text"] = M.mind.silicon_flavor_text || ""
		data["oocnotes"] = M.mind.ooc_notes || ""
		data["headshot_links"] = M.mind.headshot_links.Copy() || list()
	if(M.client?.prefs)
		var/datum/preferences/prefs = M.client.prefs
		data["vore_tag"] = prefs.vorepref
		data["erp_tag"] = prefs.erppref
		data["mob_tag"] = prefs.mobsexpref
		data["nc_tag"] = prefs.nonconpref
		data["unholy_tag"] = prefs.unholypref
		data["extreme_tag"] = prefs.extremepref
		data["very_extreme_tag"] = prefs.extremeharm
	else for(var/i in list("vore_tag", "erp_tag", "mob_tag", "nc_tag", "unholy_tag", "extreme_tag", "very_extreme_tag"))
		data[i] = "No"

	return data
