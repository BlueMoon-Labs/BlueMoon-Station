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
	var/atom/movable/screen/map_view/examine_panel_screen/examine_panel_screen
	var/mutable_appearance/current_mob_appearance
	var/mutable_appearance/current_background
	var/static/list/preview_backgrounds = list("000", "midgrey", "FFF", "white", "steel", "techmaint", "dark", "plating", "reinforced")

/datum/description_profile/New(var/host_mob)
	. = ..()
	host = WEAKREF(host_mob)


/datum/description_profile/Destroy(force, ...)
	. = ..()
	host = null

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

/atom/movable/screen/map_view/examine_panel_screen
	name = "description profile screen"

/datum/description_profile/ui_static_data(mob/user, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/data[0]
	var/mob/living/M = host.resolve()

	data["character_ref"] = examine_panel_screen.assigned_map
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

/datum/description_profile/proc/update_preview()

	if(!examine_panel_screen || !current_background)
		return

	var/mob/living/M = host.resolve()
	current_mob_appearance = new(M)
	current_mob_appearance.setDir(SOUTH)
	current_mob_appearance.transform = matrix() // We reset their rotation, in case they're lying down.

	// In case they're pixel-shifted, we bring 'em back!
	current_mob_appearance.pixel_x = 0
	current_mob_appearance.pixel_y = 0

	current_mob_appearance.add_overlay(current_background)

	examine_panel_screen.cut_overlays()
	examine_panel_screen.add_overlay(current_mob_appearance)

/datum/description_profile/ui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	var/mob/living/M = host.resolve()

	if(!examine_panel_screen)
		examine_panel_screen = new
		examine_panel_screen.name = "character icon"
		examine_panel_screen.assigned_map = "examine_panel_[REF(M)]_map"
		examine_panel_screen.del_on_map_removal = FALSE
		examine_panel_screen.screen_loc = "[examine_panel_screen.assigned_map]:1,1"

	if (!current_background)
		current_background = mutable_appearance('modular_citadel/icons/ui/backgrounds.dmi', "reinforced", layer = SPACE_LAYER)

	update_preview()

	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		user.client.register_map_obj(examine_panel_screen)
		examine_panel_screen.setDir(SOUTH)
		ui = new(user, src, "CharacterProfile", "Профиль персонажа [M]")
		ui.open()

/datum/description_profile/ui_act(action, list/params)
	. = ..()
	if (.)
		return

	switch (action)
		if("character_directory")
			var/static/datum/character_directory/character_directory = new
			character_directory.ui_interact(usr)
		if("char_right")
			examine_panel_screen.setDir(turn(examine_panel_screen.dir, -90))
		if("char_left")
			examine_panel_screen.setDir(turn(examine_panel_screen.dir, 90))
		if("change_background")
			current_background.icon_state = next_list_item(current_background.icon_state, preview_backgrounds)
			return TRUE


/datum/description_profile/robot/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyborgProfile", "Профиль юнита [src]")
		ui.open()

/datum/description_profile/robot/ui_static_data(mob/user, datum/tgui/ui, datum/ui_state/state)
	var/data[0]
	var/mob/living/M = host.resolve()
	if(!M || !istype(M))
		return
	if(M.mind)
		data["silicon_flavor_text"] = M.mind.silicon_flavor_text || ""
		data["oocnotes"] = M.mind.ooc_notes || ""
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
