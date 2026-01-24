#define BLACKLISTED_GENITALS list(/obj/item/organ/genital/breasts, /obj/item/organ/genital/belly)

/obj/item/organ/genital/proc/can_be_chastened()
	for(var/blacklisted_genital in BLACKLISTED_GENITALS)
		if(type in typesof(blacklisted_genital))
			return FALSE

	return TRUE

/obj/item/key/chastity_key
	name = "cage key"
	icon_state = "key"
	desc = "You better not lose this."

/obj/item/genital_equipment/chastity_cage
	name = "chastity cage"
	desc = "Feeling submissive yet?"
	icon = 'modular_splurt/icons/obj/lewd_items/chastity.dmi'
	icon_state = "standard_cage"
	mob_overlay_icon = 'modular_splurt/icons/obj/lewd_items/chastity.dmi'
	w_class = WEIGHT_CLASS_TINY
	genital_slot = ORGAN_SLOT_PENIS

	var/obj/item/key/chastity_key/key
	var/obj/item/clothing/underwear/chastity_belt/belt

	var/break_require = TOOL_WIRECUTTER //Which tool is required to break the chastity_cage
	var/break_time = 25 SECONDS

	var/obj/item/organ/genital/genital
	var/mutable_appearance/cage_overlay
	var/worn_icon_state

	var/overlay_layer = -(GENITALS_FRONT_LAYER - 0.01)
	var/is_overlay_on

	var/cage_sprite
	var/resizeable = TRUE

/obj/item/genital_equipment/chastity_cage/Initialize(mapload, obj/item/key/chastity_key/newkey = null)
	. = ..()

	if(!key)
		key = newkey

	color = pick(list(COLOR_LIGHT_PINK, COLOR_STRONG_VIOLET, null))

/obj/item/genital_equipment/chastity_cage/Destroy()
	if(equipment.holder_genital)
		item_removed(src, equipment.holder_genital, usr)
	key = null
	belt = null
	return ..()

/obj/item/genital_equipment/chastity_cage/item_inserting(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE

	if(belt)
		return TRUE

	if(!(G.owner.client?.prefs.cit_toggles & CHASTITY))
		to_chat(user, span_warning("They don't want you to do that!"))
		return FALSE

	return equip(user, G.owner, G)

/obj/item/genital_equipment/chastity_cage/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE

	if(belt)
		return belt.handle_cage_equipping(source, G, user)

	var/mob/living/carbon/human/H = G.owner

	playsound(source, 'modular_sand/sound/lewd/latex.ogg', 50, 1, -1) // making it a belt sound

	//turn that flag on
	ENABLE_BITFIELD(G.genital_flags, GENITAL_CHASTENED)
	H.update_genitals()

	var/overlay_icon_state

	overlay_icon_state = "worn_[worn_icon_state || icon_state]"
	var/cock_taur = H?.dna?.features["cock_taur"]
	if(resizeable)
		if(cock_taur)
			if(G.size < 3)
				cage_sprite = G.size
			else
				cage_sprite = 3
		else
			switch(G.size)
				if(1 to 2)
					cage_sprite = 1
				if(3 to 4)
					cage_sprite = 2
				if(5)
					cage_sprite = 3

		overlay_icon_state += "_[cage_sprite]"
	if(cock_taur)
		overlay_icon_state += "_taur"
		mob_overlay_icon = 'modular_splurt/icons/obj/lewd_items/chastity_taur.dmi'
	else
		mob_overlay_icon = initial(mob_overlay_icon)

	cage_overlay = mutable_appearance(mob_overlay_icon, overlay_icon_state, overlay_layer)
	cage_overlay.color = color //Set the overlay's color to the cage item's

	cage_overlay = apply_overlay(G, cage_overlay)
	RegisterSignal(H, COMSIG_MOB_UPDATE_GENITALS, PROC_REF(mob_update_genitals))

/obj/item/genital_equipment/chastity_cage/item_removing(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE

	if(!equipment.holder_genital)
		return FALSE

	var/mob/living/carbon/human/H = G.owner

	var/obj/item/I = user.get_active_held_item()

	if(!I)
		to_chat(user, "<span class='warning'>You need \a [break_require] or its key to take it off!</span>")
		return FALSE

	if(I == key)
		to_chat(user, "<span class='warning'>You wield \the [I.name] and unlock the cage!</span>")
		return TRUE

	if(break_require == TOOL_WIRECUTTER && I.tool_behaviour == break_require)
		if(!do_mob(user, H, break_time))
			return FALSE
	else if(break_require == TOOL_WELDER && I.tool_behaviour == break_require)
		if(!I.tool_start_check(user, 0))
			return FALSE

		playsound(G.owner, pick(list('sound/items/welder.ogg', 'sound/items/welder2.ogg')), 100)
		if(!do_mob(user, H, break_time))
			return FALSE
	else if(break_require == TOOL_MULTITOOL && I.tool_behaviour == break_require)
		if(!do_mob(user, H, break_time))
			return FALSE
	else
		to_chat(user, span_warning("You can't take \the [src] off with \the [I.name]!"))
		return FALSE

	to_chat(user, span_warning("You manage to break \the [src] with \the [I.name]!"))
	qdel(src)
	return FALSE

/obj/item/genital_equipment/chastity_cage/item_removed(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE

	if(belt)
		return belt.handle_cage_dropping(source, G, user)

	if(!CHECK_BITFIELD(G.genital_flags, GENITAL_CHASTENED) && !equipment.holder_genital)
		return FALSE

	var/mob/living/carbon/human/H = G.owner

	DISABLE_BITFIELD(G.genital_flags, GENITAL_CHASTENED)
	UnregisterSignal(H, COMSIG_MOB_UPDATE_GENITALS)

	H.cut_overlay(cage_overlay)
	is_overlay_on = FALSE

	H.update_genitals()

/obj/item/genital_equipment/chastity_cage/proc/equip(mob/user, mob/living/carbon/target, obj/item/organ/genital/penor)
	. = TRUE

	if(target.has_penis() == HAS_EXPOSED_GENITAL && CHECK_BITFIELD(penor?.genital_flags, HAS_EQUIPMENT))
		if(locate(/obj/item/genital_equipment/chastity_cage) in penor.contents)
			to_chat(user, "<span class='notice'>\The [target] already have a cage on them!</span>")
			return FALSE
		if(isliving(target) && isliving(user))
			target.visible_message("<span class='warning'>\The <b>[user]</b> is trying to put \the [name] on \the <b>[target]</b>!</span>",\
						"<span class='warning'>\The <b>[user]</b> is trying to put \the [name] on you!</span>")
		if(!do_mob(user, target, 4 SECONDS))
			return FALSE
	else
		return FALSE

/obj/item/genital_equipment/chastity_cage/proc/try_insert_equipment(mob/living/source, obj/item/organ/genital/G, mob/user)
	SIGNAL_HANDLER

	if(source == equipment.get_wearer())
		to_chat(user, "<span class='warning'>You got to take [source.p_their()] cage off first!</span>")
		return TRUE

// The is_overlay_on changes in this proc, so in child call ..() after your code!
/obj/item/genital_equipment/chastity_cage/proc/mob_update_genitals(datum/source)
	var/action = updt_overlay(source, cage_overlay)
	if(isnull(action))
		return
	is_overlay_on = action

// manipulates overlays while the cage is being worn. return null == no updt, TRUE/FALSE == updt add/cut
/obj/item/genital_equipment/chastity_cage/proc/updt_overlay(mob/living/carbon/human/target, mutable_appearance/overlay)
	. = TRUE
	if(!target || !overlay)
		return null

	var/obj/item/organ/genital/organ = target.getorganslot(genital_slot)
	if(!istype(organ, /obj/item/organ/genital))
		organ = null
	var/organ_exposed = organ && organ.is_exposed()

	if(organ_exposed && !is_overlay_on)
		target.add_overlay(overlay)
		return TRUE
	else if(!organ_exposed && is_overlay_on)
		target.cut_overlay(overlay)
		return FALSE
	else
		return null // Don't need updt

// adjusts and applies the overlay when putting on the cage
/obj/item/genital_equipment/chastity_cage/proc/apply_overlay(obj/item/organ/genital/G, mutable_appearance/overlay)
	if(!G || !overlay)
		return overlay
	var/mob/living/carbon/human/H = G.owner
	overlay = adjust_overlay(G, overlay)

	if(G.is_exposed())
		H.add_overlay(overlay)
		is_overlay_on = TRUE

	return overlay

// adjusts overlay to sprite_accessory of cock
/obj/item/genital_equipment/chastity_cage/proc/adjust_overlay(obj/item/organ/genital/G, mutable_appearance/overlay)
	if(!G || !overlay)
		return overlay
	var/datum/sprite_accessory/S = GLOB.cock_shapes_list[G.shape]
	var/mob/living/carbon/human/H = G.owner
	if(S && S.icon_state != "none")
		var/do_center = S.center
		var/dim_x = S.dimension_x
		var/dim_y = S.dimension_y
		// copypaste from update_genitals()
		if(G.genital_flags & GENITAL_CAN_TAUR && S.taur_icon && (!S.feat_taur || H?.dna?.features[S.feat_taur]) && H?.dna?.species.mutant_bodyparts["taur"])
			var/datum/sprite_accessory/taur/T = GLOB.taur_list[H?.dna?.features["taur"]]
			if(T?.taur_mode & S.accepted_taurs)
				do_center = TRUE
				dim_x = S.taur_dimension_x
				dim_y = S.taur_dimension_y
		if(do_center)
			overlay = center_image(overlay, dim_x, dim_y)

	return overlay

#undef BLACKLISTED_GENITALS
