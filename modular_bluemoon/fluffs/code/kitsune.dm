/datum/hud/dextrous/kitsune/New(mob/living/owner)
	. = ..()
	var/atom/movable/screen/inventory/inv_box
	var/atom/movable/screen/using
	inv_box = new /atom/movable/screen/inventory(null, src)
	inv_box.name = "back"
	inv_box.icon = ui_style
	inv_box.icon_state = "back"
	inv_box.icon_full = "template"
	inv_box.screen_loc = ui_back
	inv_box.slot_id = ITEM_SLOT_BACK
	static_inventory += inv_box

	using = new/atom/movable/screen/language_menu(null, src)
	using.icon = ui_style
	using.screen_loc = ui_boxlang
	static_inventory += using

	action_intent = new /atom/movable/screen/act_intent/segmented(null, src)
	action_intent.icon = ui_style_modular(ui_style)
	action_intent.icon_state = "[action_intent.base_icon_state]_[mymob.a_intent]"
	static_inventory += action_intent

	clickdelay = new(null, src)
	clickdelay.screen_loc = ui_clickdelay
	static_inventory += clickdelay

	resistdelay = new(null, src)
	resistdelay.screen_loc = ui_resistdelay
	static_inventory += resistdelay

	using = new /atom/movable/screen/drop(null, src)
	using.icon = ui_style
	using.screen_loc = ui_drop_throw
	static_inventory += using

/mob/living/simple_animal/kitsune
	name = "Kitsune"
	icon = 'modular_bluemoon/fluffs/icons/mob/kitsune.dmi'
	icon_state = "base"
	icon_living = "base"
	icon_dead = "sleep"
	dextrous_hud_type = /datum/hud/dextrous/kitsune
	held_items = list(null, null)
	active_hand_index = 1
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)
	a_intent = INTENT_HELP
	dextrous = TRUE
	vocal_bark_id = "mutedc4"
	melee_damage_upper = 10
	melee_damage_lower = 5
	var/obj/item/back = null
	var/current_lying_pose = "lying"
	var/aroused_state = "aroused"
	var/already_aroused = FALSE
	var/obj/item/clothing/mask/wear_mask = null

/mob/living/simple_animal/kitsune/UnarmedAttack(atom/A, proximity, intent = a_intent, flags = NONE)
	if(!CheckActionCooldown(CLICK_CD_MELEE))
		return
	return !isnull(A.attack_paw(src, intent, flags))

/mob/living/simple_animal/kitsune/update_inv_back()
	if(client && hud_used)
		var/atom/movable/screen/inventory/inv = hud_used.inv_slots[TOBITSHIFT(ITEM_SLOT_BACK) + 1]
		inv?.update_icon()
	update_small_sprite()

/mob/living/simple_animal/kitsune/get_item_by_slot(slot_id)
	if(slot_id == ITEM_SLOT_BACK)
		return back
	return null

/mob/living/simple_animal/kitsune/can_equip(obj/item/I, slot, disable_warning = FALSE, mob/living/carbon/human/H, bypass_equip_delay_self = FALSE, clothing_check = FALSE, list/return_warning)
	if(clothing_check && (slot in check_obscured_slots()))
		if(return_warning)
			return_warning[1] = "<span class='warning'>You are unable to equip that with your current garments in the way!</span>"
		return FALSE

	switch(slot)
		if(ITEM_SLOT_BACK)
			if(back)
				return FALSE
			if(!(I.slot_flags & ITEM_SLOT_BACK))
				return FALSE
			return TRUE

	return FALSE

/mob/living/simple_animal/kitsune/get_item_by_slot(slot_id)
	switch(slot_id)
		if(ITEM_SLOT_BACK)
			return back
	return null

/mob/living/simple_animal/kitsune/equip_to_slot(obj/item/I, slot)
	if(!slot)
		return
	if(!istype(I))
		return

	var/index = get_held_index_of_item(I)
	if(index)
		held_items[index] = null
	update_inv_hands()

	if(I.pulledby)
		I.pulledby.stop_pulling()

	I.screen_loc = null
	I.forceMove(src)
	I.layer = ABOVE_HUD_LAYER
	I.plane = ABOVE_HUD_PLANE

	switch(slot)
		if(ITEM_SLOT_BACK)
			back = I
			update_inv_back()
		else
			to_chat(src, "<span class='danger'>You are trying to equip this item to an unsupported inventory slot. Report this to a coder!</span>")
			return

	I.equipped(src, slot)

/mob/living/simple_animal/kitsune/getBackSlot()
	return ITEM_SLOT_BACK

/mob/living/simple_animal/kitsune/getBeltSlot()
	return null

/mob/living/simple_animal/kitsune/doUnEquip(obj/item/I, force, newloc, no_move, invdrop = TRUE, silent = FALSE)
	if(..())
		update_inv_hands()
		if(I == back)
			back = null
			update_inv_back()
		return TRUE
	return FALSE

/mob/living/simple_animal/kitsune/Initialize(mapload)
	. = ..()
	var/datum/action/innate/kitsune/toggle_aroused/toggle_aroused = new(src)
	var/datum/action/innate/kitsune/set_lying_pose/set_lying_pose = new(src)
	toggle_aroused.Grant(src)
	set_lying_pose.Grant(src)

/datum/action/innate/kitsune
	name = "kitsune action"
	background_icon_state = "bg_default"
	button_icon_state = "velvet_chords"
	var/mob/living/simple_animal/kitsune/my_kitsune

/datum/action/innate/kitsune/toggle_aroused
	name = "Toggle_aroused"

/datum/action/innate/kitsune/set_lying_pose
	name = "Set lying pose"
	background_icon_state = "bg_default"
	var/list/avaible_poses = list(
		"lying_radial" = "lying",
		"sit_radial" = "sit",
		"sleep_radial" = "sleep"
	)

/datum/action/innate/kitsune/set_lying_pose/Activate()
	. = ..()
	var/list/choices = list()
	for(var/icon_state in avaible_poses)
		var/display_name = avaible_poses[icon_state]
		var/image/img = image(icon = my_kitsune.icon, icon_state = icon_state)
		choices[display_name] = img

	if(!length(choices))
		return
	var/pick = show_radial_menu(my_kitsune, my_kitsune, choices = choices)
	if(!pick)
		return
	my_kitsune.current_lying_pose = pick

/datum/action/innate/kitsune/toggle_aroused/Activate()
	. = ..()
	var/aroused = my_kitsune.already_aroused
	if(!aroused)
		my_kitsune.icon_state = my_kitsune.aroused_state
	else
		my_kitsune.icon_state = my_kitsune.icon_living
	my_kitsune.already_aroused = !aroused //инвертируется

/datum/action/innate/kitsune/Grant(mob/grant_to)
	. = ..()
	my_kitsune = grant_to

/mob/living/simple_animal/kitsune/update_mobility()
	. = ..()
	if(client && stat != DEAD)
		if(!CHECK_MOBILITY(src, MOBILITY_STAND))
			icon_state = current_lying_pose
		else
			icon_state = "[icon_living]"
	regenerate_icons()

/mob/living/simple_animal/kitsune/death(gibbed)
	. = ..()
	playsound(get_turf(src.loc), 'sound/magic/Repulse.ogg', 100, 1)

	src.ghostize(1, voluntary = TRUE)

	var/datum/effect_system/spark_spread/quantum/sparks = new
	sparks.set_up(10, 1, src)
	sparks.attach(src.loc)
	sparks.start()

	qdel(src)
