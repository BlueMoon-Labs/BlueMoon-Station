/*
	Screen objects
	Todo: improve/re-implement

	Screen objects are only used for the hud and should not appear anywhere "in-game".
	They are used with the client/screen list and the screen_loc var.
	For more information, see the byond documentation on the screen_loc and screen vars.
*/
/atom/movable/screen
	name = ""
	icon = 'icons/mob/screen_gen.dmi'
	plane = HUD_PLANE
	animate_movement = SLIDE_STEPS
	speech_span = SPAN_ROBOT
	vis_flags = VIS_INHERIT_PLANE
	appearance_flags = APPEARANCE_UI
	/// A reference to the object in the slot. Grabs or items, generally.
	var/obj/master = null
	/// A reference to the owner HUD, if any.
	VAR_PRIVATE/datum/hud/hud = null
	/**
	 * Map name assigned to this object.
	 * Automatically set by /client/proc/add_obj_to_map.
	 */
	var/assigned_map
	/**
	 * Mark this object as garbage-collectible after you clean the map
	 * it was registered on.
	 *
	 * This could probably be changed to be a proc, for conditional removal.
	 * But for now, this works.
	 */
	var/del_on_map_removal = TRUE
	/// If FALSE, this will not be cleared when calling /client/clear_screen()
	// var/clear_with_screen = TRUE // Unimplemented
	/// If TRUE, clicking the screen element will fall through and perform a default "Click" call
	/// Obviously this requires your Click override, if any, to call parent on their own.
	/// This is set to FALSE to default to dissade you from doing this.
	/// Generally we don't want default Click stuff, which results in bugs like using Telekinesis on a screen element
	/// or trying to point your gun at your screen.
	var/default_click = FALSE
	/// If FALSE, this will not be cleared when calling /client/clear_screen()
	var/clear_with_screen = TRUE

/atom/movable/screen/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	if(isnull(hud_owner)) //some screens set their hud owners on /new, this prevents overriding them with null post atoms init
		return
	set_new_hud(hud_owner)

/atom/movable/screen/Destroy()
	if(istype(hud) && hud.mymob?.client)
		hud.mymob.client.screen -= src
	// Подметать moused_over_objects больше не нужно: память автопарри держит
	// текстовые ref'ы (см. register_moused_over), а не сами экраны.
	// Экраны карт (консоль камер, secureye, под-лаунчер, попапы) регистрируются
	// в чужих client.screen напрямую и hud'а не имеют - выписываем их сами,
	// иначе удаление владельца при открытом UI оставляет весь набор
	// плейн-мастеров жить в клиенте смотрящего.
	if(assigned_map)
		for(var/client/viewer as anything in GLOB.clients)
			if(detach_screen_from_client_maps(viewer.screen_maps, src))
				viewer.screen -= src
	set_new_hud(null)
	master = null
	vis_contents.Cut()
	return ..()

/atom/movable/screen/Click(location, control, params)
	if(flags_1 & INITIALIZED_1)
		SEND_SIGNAL(src, COMSIG_SCREEN_ELEMENT_CLICK, location, control, params, usr)
	if(default_click)
		return ..()

///Screen elements are always on top of the players screen and don't move so yes they are adjacent
/atom/movable/screen/Adjacent(atom/neighbor, atom/target, atom/movable/mover)
	return TRUE

/atom/movable/screen/examine(mob/user)
	return list()

/atom/movable/screen/orbit()
	return

/atom/movable/screen/proc/component_click(atom/movable/screen/component_button/component, params)
	return

///setter used to set our new hud
/atom/movable/screen/proc/set_new_hud(datum/hud/hud_owner)
	if(istype(hud, /datum))
		UnregisterSignal(hud, COMSIG_PARENT_QDELETING)
	if(isnull(hud_owner))
		hud = null
		return
	hud = hud_owner
	if(istype(hud, /datum))
		RegisterSignal(hud, COMSIG_PARENT_QDELETING, PROC_REF(on_hud_delete))

/// Returns the mob this is being displayed to, if any
/atom/movable/screen/proc/get_mob()
	RETURN_TYPE(/mob)
	return hud?.mymob

/atom/movable/screen/proc/on_hud_delete(datum/source)
	SIGNAL_HANDLER

	set_new_hud(hud_owner = null)

/atom/movable/screen/proc/clear()
	invisibility = INVISIBILITY_ABSTRACT

/atom/movable/screen/proc/show()
	invisibility = 0

/atom/movable/screen/text
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "CENTER-7,CENTER-7"
	maptext_height = 480
	maptext_width = 480

/atom/movable/screen/swap_hand
	plane = HUD_PLANE
	name = "swap hand"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/swap_hand/Click()
	// At this point in client Click() code we have passed the 1/10 sec check and little else
	// We don't even know if it's a middle click
	if(usr.incapacitated())
		return TRUE

	if(ismob(usr))
		var/mob/M = usr
		M.swap_hand()
	return TRUE

// /atom/movable/screen/skills
// 	name = "skills"
// 	icon = 'icons/mob/screen_midnight.dmi'
// 	icon_state = "skills"
// 	screen_loc = ui_skill_menu

// /atom/movable/screen/skills/Click()
// 	if(ishuman(usr))
// 		var/mob/living/carbon/human/H = usr
// 		H.mind.print_levels(H)

/atom/movable/screen/craft
	name = "crafting menu"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "craft"
	screen_loc = ui_crafting
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/area_creator
	name = "create new area"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "area_edit"
	screen_loc = ui_building
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/area_creator/Click()
	if(usr.incapacitated() || (isobserver(usr) && !IsAdminGhost(usr)))
		return TRUE
	var/area/A = get_area(usr)
	if(!A.outdoors)
		to_chat(usr, span_warning("There is already a defined structure here."))
		return TRUE
	create_area(usr)

/atom/movable/screen/language_menu
	name = "language menu"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "talk_wheel"
	screen_loc = ui_language_menu
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/language_menu/Click()
	hud.mymob.get_language_holder().open_language_menu(hud.mymob)

/atom/movable/screen/inventory
	/// The identifier for the slot. It has nothing to do with ID cards.
	var/slot_id
	/// Icon when empty. For now used only by humans.
	var/icon_empty
	/// Icon when contains an item. For now used only by humans.
	var/icon_full
	/// The overlay when hovering over with an item in your hand
	var/image/object_overlay
	plane = HUD_PLANE

/atom/movable/screen/inventory/Click(location, control, params)
	// At this point in client Click() code we have passed the 1/10 sec check and little else
	// We don't even know if it's a middle click

	if(usr.incapacitated()) // ignore_stasis = TRUE
		return TRUE
	if(ismecha(usr.loc)) // stops inventory actions in a mech
		return TRUE

	if(hud?.mymob && slot_id)
		var/obj/item/inv_item = hud.mymob.get_item_by_slot(slot_id)
		if(inv_item)
			return inv_item.Click(location, control, params)

	if(usr.attack_ui(slot_id))
		usr.update_inv_hands()
	return TRUE

/atom/movable/screen/inventory/MouseEntered(location, control, params)
	. = ..()
	add_overlays()

/atom/movable/screen/inventory/MouseExited()
	..()
	cut_overlay(object_overlay)
	QDEL_NULL(object_overlay)

/atom/movable/screen/inventory/update_icon_state()
	if(!icon_empty)
		icon_empty = icon_state

	if(hud?.mymob && slot_id && icon_full)
		icon_state = hud.mymob.get_item_by_slot(slot_id) ? icon_full : icon_empty
	return ..()

/atom/movable/screen/inventory/proc/add_overlays()
	var/mob/user = hud?.mymob

	if(!user || !slot_id)
		return

	var/obj/item/holding = user.get_active_held_item()

	if(!holding || user.get_item_by_slot(slot_id))
		return

	var/image/item_overlay = image(holding)
	item_overlay.alpha = 92

	if(!user.can_equip(holding, slot_id, disable_warning = TRUE, bypass_equip_delay_self = TRUE))
		item_overlay.color = "#FF0000"
	else
		item_overlay.color = "#00ff00"

	cut_overlay(object_overlay)
	object_overlay = item_overlay
	add_overlay(object_overlay)

/atom/movable/screen/inventory/hand
	var/mutable_appearance/handcuff_overlay
	var/static/mutable_appearance/blocked_overlay = mutable_appearance('icons/mob/screen_gen.dmi', "blocked")
	var/held_index = 0

/atom/movable/screen/inventory/hand/update_overlays()
	. = ..()

	if(!handcuff_overlay)
		var/state = (!(held_index % 2)) ? "markus" : "gabrielle"
		handcuff_overlay = mutable_appearance('icons/mob/screen_gen.dmi', state)

	if(!hud?.mymob)
		return

	if(iscarbon(hud.mymob))
		var/mob/living/carbon/C = hud.mymob
		if(C.handcuffed)
			. += handcuff_overlay

		if(held_index)
			if(!C.has_hand_for_held_index(held_index))
				. += blocked_overlay

	if(held_index == hud.mymob.active_hand_index)
		. += (held_index % 2) ? "lhandactive" : "rhandactive"


/atom/movable/screen/inventory/hand/Click(location, control, params)
	// At this point in client Click() code we have passed the 1/10 sec check and little else
	// We don't even know if it's a middle click
	var/mob/user = hud?.mymob
	if(usr != user)
		return TRUE
	if(user.incapacitated())
		return TRUE
	if (ismecha(user.loc)) // stops inventory actions in a mech
		return TRUE

	if(user.active_hand_index == held_index)
		var/obj/item/I = user.get_active_held_item()
		if(I)
			I.Click(location, control, params)
	else
		user.swap_hand(held_index)
	return TRUE

// /atom/movable/screen/close
// 	name = "close"
// 	plane = ABOVE_HUD_PLANE
// 	icon_state = "backpack_close"

// /atom/movable/screen/close/Initialize(mapload, datum/hud/hud_owner, new_master)
// 	. = ..()
// 	master = new_master

// /atom/movable/screen/close/Click()
// 	var/datum/component/storage/S = master
// 	S.hide_from(usr)
// 	return TRUE

/atom/movable/screen/drop
	name = "drop"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "act_drop"
	plane = HUD_PLANE
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/drop/Click()
	if(usr.stat == CONSCIOUS)
		usr.dropItemToGround(usr.get_active_held_item())

/atom/movable/screen/act_intent
	name = "intent"
	icon_state = "help"
	screen_loc = ui_acti
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/act_intent/Click(location, control, params)
	hud.mymob.a_intent_change(INTENT_HOTKEY_RIGHT)

/atom/movable/screen/act_intent/update_icon_state()
	icon_state = hud.mymob.a_intent || initial(icon_state)

/atom/movable/screen/act_intent/segmented
	base_icon_state = "intent"

/atom/movable/screen/act_intent/segmented/Click(location, control, params)
	if(!(hud.mymob?.client.prefs.toggles & INTENT_STYLE))
		return ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if(_x<=16 && _y<=16)
		usr.a_intent_change(INTENT_HARM)

	else if(_x<=16 && _y>=17)
		usr.a_intent_change(INTENT_HELP)

	else if(_x>=17 && _y<=16)
		usr.a_intent_change(INTENT_GRAB)

	else if(_x>=17 && _y>=17)
		usr.a_intent_change(INTENT_DISARM)

	update_icon()

/atom/movable/screen/act_intent/segmented/update_icon_state()
	icon_state = "[base_icon_state]_[hud.mymob.a_intent]"

/atom/movable/screen/act_intent/alien
	icon = 'icons/mob/screen_alien.dmi'
	screen_loc = ui_movi

/atom/movable/screen/act_intent/robot
	icon = 'icons/mob/screen_cyborg.dmi'
	screen_loc = ui_borg_intents

/atom/movable/screen/mov_intent
	name = "run/walk toggle"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "running"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/mov_intent/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_icon()

/atom/movable/screen/mov_intent/Click()
	toggle(usr)

/atom/movable/screen/mov_intent/update_icon_state()
	if(!hud || !hud.mymob || !isliving(hud.mymob))
		return
	var/mob/living/living_hud_owner = hud.mymob
	switch(living_hud_owner.m_intent)
		if(MOVE_INTENT_WALK)
			icon_state = CONFIG_GET(flag/sprint_enabled)? "walking" : "walking_nosprint"
		if(MOVE_INTENT_RUN)
			icon_state = CONFIG_GET(flag/sprint_enabled)? "running" : "running_nosprint"
	return ..()

/atom/movable/screen/mov_intent/proc/toggle(mob/user)
	if(isobserver(user))
		return
	user.toggle_move_intent(user)

/atom/movable/screen/pull
	name = "stop pulling"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "pull"
	base_icon_state = "pull"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/pull/Click()
	if(isobserver(usr))
		return
	usr.stop_pulling()

/atom/movable/screen/pull/update_icon_state()
	icon_state = "[base_icon_state][hud?.mymob?.pulling ? null : 0]"
	return ..()

/atom/movable/screen/resist
	name = "resist"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "act_resist"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/resist/Click()
	if(isliving(usr))
		var/mob/living/L = usr
		L.resist()

/atom/movable/screen/rest
	name = "rest"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "act_rest"
	base_icon_state = "act_rest"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/rest/Click()
	if(isliving(usr))
		var/mob/living/L = usr
		L.lay_down()

/atom/movable/screen/rest/update_icon_state()
	var/mob/living/user = hud?.mymob
	if(!istype(user))
		return ..()
	icon_state = "[base_icon_state][user.resting ? 0 : null]"
	return ..()

/atom/movable/screen/throw_catch
	name = "throw/catch"
	icon = 'icons/mob/screen_midnight.dmi'
	icon_state = "act_throw_off"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/throw_catch/Click()
	if(iscarbon(usr))
		var/mob/living/carbon/C = usr
		C.toggle_throw_mode()
	else if(istype(usr, /mob/living/simple_animal))
		var/mob/living/simple_animal/S = usr
		if(S.dextrous)
			S.toggle_throw_mode()

/atom/movable/screen/zone_sel
	name = "damage zone"
	icon_state = "zone_sel"
	screen_loc = ui_zonesel
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/overlay_icon = 'icons/mob/screen_gen.dmi'
	var/list/hover_overlays_cache = list()
	var/hovering

/atom/movable/screen/zone_sel/Destroy()
	QDEL_LIST_ASSOC_VAL(hover_overlays_cache)
	return ..()

/atom/movable/screen/zone_sel/Click(location, control,params)
	if(isobserver(usr))
		return

	var/list/modifiers = params2list(params)
	var/icon_x = text2num(LAZYACCESS(modifiers, "icon-x"))
	var/icon_y = text2num(LAZYACCESS(modifiers, "icon-y"))
	var/choice = get_zone_at(icon_x, icon_y)
	if (!choice)
		return TRUE

	return set_selected_zone(choice, usr)

/atom/movable/screen/zone_sel/MouseEntered(location, control, params)
	. = ..()
	MouseMove(location, control, params)

/atom/movable/screen/zone_sel/MouseMove(location, control, params)
	if(isobserver(usr))
		return

	var/list/modifiers = params2list(params)
	var/icon_x = text2num(LAZYACCESS(modifiers, "icon-x"))
	var/icon_y = text2num(LAZYACCESS(modifiers, "icon-y"))
	var/choice = get_zone_at(icon_x, icon_y)

	if(hovering == choice)
		return
	vis_contents -= hover_overlays_cache[hovering]
	hovering = choice

	var/obj/effect/overlay/zone_sel/overlay_object = hover_overlays_cache[choice]
	if(!overlay_object)
		overlay_object = new
		overlay_object.icon_state = "[choice]"
		hover_overlays_cache[choice] = overlay_object
	vis_contents += overlay_object

/obj/effect/overlay/zone_sel
	icon = 'icons/mob/screen_gen.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 128
	anchored = TRUE
	plane = ABOVE_HUD_PLANE

/atom/movable/screen/zone_sel/MouseExited(location, control, params)
	if(!isobserver(usr) && hovering)
		vis_contents -= hover_overlays_cache[hovering]
		hovering = null

/atom/movable/screen/zone_sel/proc/get_zone_at(icon_x, icon_y)
	switch(icon_y)
		if(1 to 9) //Legs
			switch(icon_x)
				if(10 to 15)
					return BODY_ZONE_R_LEG
				if(17 to 22)
					return BODY_ZONE_L_LEG
		if(10 to 13) //Hands and groin
			switch(icon_x)
				if(8 to 11)
					return BODY_ZONE_R_ARM
				if(12 to 20)
					return BODY_ZONE_PRECISE_GROIN
				if(21 to 24)
					return BODY_ZONE_L_ARM
		if(14 to 22) //Chest and arms to shoulders
			switch(icon_x)
				if(8 to 11)
					return BODY_ZONE_R_ARM
				if(12 to 20)
					return BODY_ZONE_CHEST
				if(21 to 24)
					return BODY_ZONE_L_ARM
		if(23 to 30) //Head, but we need to check for eye or mouth
			if(icon_x in 12 to 20)
				switch(icon_y)
					if(23 to 24)
						if(icon_x in 15 to 17)
							return BODY_ZONE_PRECISE_MOUTH
					if(26) //Eyeline, eyes are on 15 and 17
						if(icon_x in 14 to 18)
							return BODY_ZONE_PRECISE_EYES
					if(25 to 27)
						if(icon_x in 15 to 17)
							return BODY_ZONE_PRECISE_EYES
				return BODY_ZONE_HEAD

/atom/movable/screen/zone_sel/proc/set_selected_zone(choice, mob/user)
	if(user != hud?.mymob)
		return

	if(choice != hud.mymob.zone_selected)
		hud.mymob.zone_selected = choice
		update_appearance()

	return TRUE

/atom/movable/screen/zone_sel/update_overlays()
	. = ..()
	if(!hud?.mymob)
		return
	. += mutable_appearance(overlay_icon, "[hud.mymob.zone_selected]")

/atom/movable/screen/zone_sel/alien
	icon = 'icons/mob/screen_alien.dmi'
	overlay_icon = 'icons/mob/screen_alien.dmi'

/atom/movable/screen/zone_sel/robot
	icon = 'icons/mob/screen_cyborg.dmi'

/atom/movable/screen/flash
	name = "flash"
	icon_state = "blank"
	blend_mode = BLEND_ADD
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	layer = FLASH_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/damageoverlay
	icon = 'icons/mob/screen_full.dmi'
	icon_state = "oxydamageoverlay0"
	name = "dmg"
	blend_mode = BLEND_MULTIPLY
	screen_loc = "CENTER-7,CENTER-7"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/healths
	name = "health"
	icon_state = "health0"
	screen_loc = ui_health

/atom/movable/screen/healths/alien
	icon = 'icons/mob/screen_alien.dmi'
	screen_loc = ui_alien_health

/atom/movable/screen/healths/robot
	icon = 'icons/mob/screen_cyborg.dmi'
	screen_loc = ui_borg_health

/atom/movable/screen/healths/blob
	name = "blob health"
	icon_state = "block"
	screen_loc = ui_internal
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/blob/naut
	name = "health"
	icon = 'icons/mob/blob.dmi'
	icon_state = "nauthealth"

/atom/movable/screen/healths/blob/naut/core
	name = "overmind health"
	screen_loc = ui_health
	icon_state = "corehealth"

/atom/movable/screen/healths/guardian
	name = "summoner health"
	icon = 'icons/mob/guardian.dmi'
	icon_state = "base"
	screen_loc = ui_health
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/clock
	icon = 'icons/mob/actions.dmi'
	icon_state = "bg_clock"
	screen_loc = ui_health
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/clock/gear
	icon = 'icons/mob/clockwork_mobs.dmi'
	icon_state = "bg_gear"
	screen_loc = ui_internal

/atom/movable/screen/healths/revenant
	name = "essence"
	icon = 'icons/mob/actions.dmi'
	icon_state = "bg_revenant"
	screen_loc = ui_health
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/construct
	icon = 'icons/mob/screen_construct.dmi'
	icon_state = "artificer_health0"
	screen_loc = ui_construct_health
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/lavaland_elite
	icon = 'icons/mob/screen_elite.dmi'
	icon_state = "elite_health0"
	screen_loc = ui_health
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

///////////////////////////////////////////////////

/atom/movable/screen/healthdoll
	name = "health doll"
	screen_loc = ui_healthdoll
	mouse_over_pointer = MOUSE_HAND_POINTER
	/// Last state the overlays were drawn for, see /mob/living/carbon/human/proc/get_healthdoll_cache_key.
	/// Lives on the doll rather than the mob so rebuilding the HUD invalidates it for free.
	var/doll_cache_key

/atom/movable/screen/healthdoll/Click()
	if (iscarbon(usr))
		var/mob/living/carbon/C = usr
		C.check_self_for_injuries()

/atom/movable/screen/healthdoll/living
	icon_state = "fullhealth0"
	screen_loc = ui_living_healthdoll
	var/filtered = FALSE //so we don't repeatedly create the mask of the mob every update

/atom/movable/screen/healthdoll/Click(location, control, params)
	if(hud?.mymob)
		return hud.mymob.Click(arglist(args))

/atom/movable/screen/healthdoll/examine(mob/user)
	if(hud?.mymob)
		return hud.mymob.examine(arglist(args))

/atom/movable/screen/healthdoll/examine_more(mob/user)
	if(hud?.mymob)
		return hud.mymob.examine_more(arglist(args))

/atom/movable/screen/healthdoll/MouseEntered(location, control, params)
	if(hud?.mymob)
		return hud.mymob.MouseEntered(arglist(args))

/atom/movable/screen/healthdoll/MouseExited(location, control, params)
	if(hud?.mymob)
		return hud.mymob.MouseExited(arglist(args))

/atom/movable/screen/healthdoll/MouseDown(location, control, params)
	if(hud?.mymob)
		return hud.mymob.MouseDown(arglist(args))

/atom/movable/screen/healthdoll/MouseUp(location, control, params)
	if(hud?.mymob)
		return hud.mymob.MouseUp(arglist(args))

/atom/movable/screen/healthdoll/MouseDrag(over_object, src_location, over_location, src_control, over_control, params)
	if(hud?.mymob)
		return hud.mymob.MouseDrag(arglist(args))

///////////////////////////////////////////////////

/atom/movable/screen/mood
	name = "mood"
	icon_state = "mood5"
	screen_loc = ui_mood
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/mood/attack_tk()
	return

// Mousedrop won't work, behavior is usually defined on the thing that MouseDrag started on
/atom/movable/screen/sanity
	name = "sanity"
	icon = 'modular_sand/icons/mob/sanity.dmi'
	icon_state = "sanity3"
	screen_loc = ui_mood

/atom/movable/screen/splash
	icon = 'icons/blank_title.png'
	icon_state = ""
	screen_loc = "1,1"
	layer = SPLASHSCREEN_LAYER
	plane = SPLASHSCREEN_PLANE
	var/client/holder

INITIALIZE_IMMEDIATE(/atom/movable/screen/splash)

/atom/movable/screen/splash/Initialize(mapload, datum/hud/hud_owner, client/C, visible, use_previous_title)
	. = ..(mapload)
	if(!istype(C))
		return

	holder = C

	if(!visible)
		alpha = 0

	if(!use_previous_title)
		if(SStitle.icon)
			icon = SStitle.icon
	else
		if(!SStitle.previous_icon)
			return INITIALIZE_HINT_QDEL
		icon = SStitle.previous_icon

	holder.screen += src

/atom/movable/screen/splash/proc/Fade(out, qdel_after = TRUE)
	if(QDELETED(src))
		return
	if(out)
		animate(src, alpha = 0, time = 30)
	else
		alpha = 0
		animate(src, alpha = 255, time = 30)
	if(qdel_after)
		QDEL_IN(src, 30)

/atom/movable/screen/splash/Destroy()
	if(holder)
		holder.screen -= src
		holder = null
	return ..()


/atom/movable/screen/component_button
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/atom/movable/screen/parent

/atom/movable/screen/component_button/Initialize(mapload, datum/hud/hud_owner, atom/movable/screen/parent)
	. = ..()
	src.parent = parent

/atom/movable/screen/component_button/Click(params)
	if(parent)
		parent.component_click(src, params)

/atom/movable/screen/combo
	icon_state = ""
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = ui_combo
	layer = ABOVE_HUD_LAYER
	var/timerid

/atom/movable/screen/combo/proc/clear_streak()
	cut_overlays()
	icon_state = ""

/atom/movable/screen/combo/update_icon_state(streak = "")
	clear_streak()
	if (timerid)
		deltimer(timerid)
	if (!streak)
		return
	timerid = addtimer(CALLBACK(src, PROC_REF(clear_streak)), 20, TIMER_UNIQUE | TIMER_STOPPABLE)
	icon_state = "combo"
	for (var/i = 1; i <= length(streak); ++i)
		var/intent_text = copytext(streak, i, i + 1)
		var/image/intent_icon = image(icon,src,"combo_[intent_text]")
		intent_icon.pixel_x = 16 * (i - 1) - 8 * length(streak)
		add_overlay(intent_icon)

// Z
/atom/movable/screen/floor_changer
	name = "Сменить уровень"
	icon = 'icons/mob/screen_ghost.dmi'
	icon_state = "floor_change_v" // Иронично
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/floor_changer/Click(location, control, params)
	var/list/modifiers = params2list(params)
	var/mouse_y = text2num(LAZYACCESS(modifiers, "icon-y"))
	var/mob/dead/observer/ghost = usr
	if(!isobserver(ghost))
		return
	var/turf/current = get_turf(ghost)
	if(!current)
		return
	var/target_z = (mouse_y > 16) ? current.z + 1 : current.z - 1
	if(target_z < 1 || target_z > world.maxz)
		return
	var/turf/target = locate(current.x, current.y, target_z)
	if(!target)
		return
	ghost.forceMove(target)

/atom/movable/screen/floor_changer/ghost
	icon = 'icons/mob/screen_ghost.dmi'

/atom/movable/screen/hunger
	name = "hunger"
	icon = 'modular_sand/icons/hud/screen_gen.dmi'
	icon_state = "nutrition0"
	screen_loc = ui_hunger_thirst

/atom/movable/screen/thirst
	name = "thirst"
	icon = 'modular_sand/icons/hud/screen_gen.dmi'
	icon_state = "hydration0"
	screen_loc = ui_hunger_thirst

/// "Голод" для синтетов
/atom/movable/screen/hunger/robotic
	name = "charge"
	icon_state = "charge0"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/hunger/robotic/Click(location, control, params)
	. = ..()
	if(isliving(usr))
		var/mob/living/L = usr
		var/charge_units = max(L.nutrition * 6, 0)
		var/charge_status
		switch(charge_units)
			if(0 to 1100)
				charge_status = span_danger("низкий")
			if(1100 to 2200)
				charge_status = span_notice("средний")
			else
				charge_status = span_green("высокий")
		var/info_text = ""
		info_text += span_info("<div align=center><b>Диагностика энергосистем</b></div>")
		info_text += "<hr>"
		info_text += "<div style='margin-top:6px'>Уровень заряда батареи: <b>[charge_status]</b>.</div>"
		info_text += "<div style='margin-top:6px'>Текущая доступная мощность: <b>[charge_units]W</b>.</div>"
		info_text += "<div style='margin-top:6px'>[charge_units <= 1100 ? "Работает энергосберегающий режим. Ожидается торможение физических узлов" : "Включена защита от перезаряда"].</div>"
		to_chat(L, examine_block(info_text))
/////////////////////////////////////////

/atom/movable/screen/devil
	invisibility = INVISIBILITY_ABSTRACT

/atom/movable/screen/devil/soul_counter
	icon = 'icons/mob/screen_gen.dmi'
	name = "souls owned"
	icon_state = "Devil-6"
	screen_loc = ui_devilsouldisplay

/atom/movable/screen/devil/soul_counter/proc/update_counter(souls = 0)
	invisibility = 0
	maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#FF0000'>[souls]</font></div>")
	switch(souls)
		if(0,null)
			icon_state = "Devil-1"
		if(1,2)
			icon_state = "Devil-2"
		if(3 to 5)
			icon_state = "Devil-3"
		if(6 to 8)
			icon_state = "Devil-4"
		if(9 to INFINITY)
			icon_state = "Devil-5"
		else
			icon_state = "Devil-6"

/atom/movable/screen/ling
	invisibility = INVISIBILITY_ABSTRACT

/atom/movable/screen/ling/sting
	name = "current sting"
	screen_loc = ui_lingstingdisplay
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/ling/sting/Click()
	if(isobserver(usr))
		return
	var/mob/living/carbon/U = usr
	U.unset_sting()

/atom/movable/screen/ling/chems
	name = "chemical storage"
	icon_state = "power_display"
	screen_loc = ui_lingchemdisplay

/////////////////////////////////////////

/atom/movable/screen/synth
	invisibility = INVISIBILITY_ABSTRACT

/atom/movable/screen/synth/proc/update_counter(mob/living/carbon/human/owner)
	invisibility = 0

/atom/movable/screen/synth/coolant_counter
	icon = 'icons/mob/screen_synth.dmi'
	name = "hydraulic fluid system" // BLUEMOON EDIT - написал "гидравлическая жидкость"
	icon_state = "coolant-3-1"
	screen_loc = ui_coolant_display
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/jammed = 0

/atom/movable/screen/synth/coolant_counter/Click(location, control, params)
	. = ..()
	show_stats()

/atom/movable/screen/synth/coolant_counter/update_counter(mob/living/carbon/owner)
	..()
	var/valuecolor = "#ff2525"
	if(owner.stat == DEAD)
		maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='[valuecolor]'>ERR-0F</font></div>")
		icon_state = "coolant-3-1"
		return
	var/coolant_efficiency
	var/coolant
	if(!jammed)
		coolant_efficiency = owner.get_cooling_efficiency()
		coolant = owner.blood_volume
	else
		coolant_efficiency = rand(1, 15) / 10
		coolant = rand(1, 600)
		jammed--
	if(coolant > BLOOD_VOLUME_SAFE * owner.blood_ratio)	//I unfortunately have to use this else-if stack because switch doesn't support variables.
		valuecolor =  "#4bbd34"
	else if(coolant > BLOOD_VOLUME_OKAY * owner.blood_ratio)
		valuecolor = "#dabb0d"
	else if(coolant > BLOOD_VOLUME_BAD * owner.blood_ratio)
		valuecolor =  "#dd8109"
	else if(coolant > BLOOD_VOLUME_SURVIVE * owner.blood_ratio)
		valuecolor = "#e7520d"
	maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:0px'><font color='[valuecolor]'>[round((coolant / (BLOOD_VOLUME_NORMAL * owner.blood_ratio)) * 100, 1)]</font></div>")
	maptext_x = -2

	var/efficiency_suffix
	var/state_suffix
	switch(coolant_efficiency)
		if(-INFINITY to 0.4)
			efficiency_suffix = "1"
		if(0.4 to 0.75)
			efficiency_suffix = "2"
		if(0.75 to 0.95)
			efficiency_suffix = "3"
		if(0.95 to 1.3)
			efficiency_suffix = "4"
		else
			efficiency_suffix = "5"
	var/obj/item/organ/lungs/ipc/L = owner.getorganslot(ORGAN_SLOT_LUNGS)
	if(istype(L) && L.is_cooling)
		state_suffix = "2"
	else
		state_suffix = "1"
	icon_state = "coolant-[efficiency_suffix]-[state_suffix]"

/atom/movable/screen/synth/coolant_counter/proc/show_stats(mob/user)
	var/mob/living/carbon/human/owner = hud.mymob
	if(owner.stat == DEAD)
		return
	var/coolant
	var/total_efficiency
	var/environ_efficiency
	var/suitlink_efficiency
	if(!jammed)
		coolant = owner.blood_volume
		total_efficiency = owner.get_cooling_efficiency()
		environ_efficiency = owner.get_environment_cooling_efficiency()
		suitlink_efficiency = owner.check_suitlinking() // BLUEMOON TODO REDO - suitlink больше нет у синтетиков
	else
		coolant = rand(1, 600)
		total_efficiency = rand(1, 15) / 10
		environ_efficiency = rand(1, 20) / 10
	if(isliving(usr))
		var/mob/living/L = usr
		var/info_text = ""
		info_text += span_info("<div align=center><b>Диагностика систем охлаждения</b></div>")
		info_text += "<hr>"
		info_text += "<div style='margin-top:6px'>Кол-во гидравлической жидкости: [span_notice("[coolant]u")], <b>[round(coolant / (BLOOD_VOLUME_NORMAL * owner.blood_ratio) * 100, 0.1)]%</b>.</div>"
		info_text += "<div style='margin-top:6px'>Эффективность охлаждения: <b>[round(total_efficiency * 100, 0.1)]%</b>.</div>"
		info_text += "<div style='margin-top:6px'>[suitlink_efficiency ? "<font color='green'>Обнаружен активный suit-линк</font>, \
		обеспечивающий <font color='green'>[suitlink_efficiency * 100]%</font> охладительной эффективности." : \
		"Охладительная мощность атмосферы: <b>[round(environ_efficiency * 100, 0.1)]%</b>."]</div>"
		to_chat(L, examine_block(info_text))

/atom/movable/screen/synth/coolant_counter/proc/jam(amount, cap = 20)
	if(jammed > cap)	//Preserve previous more impactful event.
		return
	jammed = min(jammed + amount, cap)

/////////////////////////////////////////
