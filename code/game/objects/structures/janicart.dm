/obj/structure/janitorialcart
	name = "janitorial cart"
	desc = "This is the alpha and omega of sanitation."
	icon = 'icons/obj/janitor.dmi'
	icon_state = "cart"
	anchored = FALSE
	density = TRUE
	//copypaste sorry
	var/obj/item/storage/bag/trash/mybag
	var/obj/item/mop/mymop
	var/obj/item/broom/mybroom
	var/obj/item/reagent_containers/spray/cleaner/myspray
	var/obj/item/lightreplacer/myreplacer
	var/signs = 0
	var/const/max_signs = 4


/obj/structure/janitorialcart/Initialize(mapload)
	. = ..()
	create_reagents(100, OPENCONTAINER)
	GLOB.janitor_devices += src
	register_context()

/obj/structure/janitorialcart/Destroy()
	GLOB.janitor_devices -= src
	return ..()

/obj/structure/janitorialcart/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(istype(held_item, /obj/item/mop))
		. = CONTEXTUAL_SCREENTIP_SET
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Намочить|Положить швабру")
		if(is_refillable())
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HARM, "Отжать швабру")
			LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, "Отжать швабру")

/obj/structure/janitorialcart/proc/wet_mop(obj/item/mop, mob/user)
	if(reagents.total_volume < 1)
		to_chat(user, span_warning("[src] is out of water!"))
		return FALSE
	else
		reagents.trans_to(mop, 5)
		to_chat(user, span_notice("You wet [mop] in [src]."))
		playsound(loc, 'sound/effects/slosh.ogg', 25, 1)
		return TRUE

/obj/structure/janitorialcart/proc/put_in_cart(obj/item/I, mob/user)
	if(!user.transferItemToLoc(I, src))
		return
	to_chat(user, span_notice("You put [I] into [src]."))
	return


/obj/structure/janitorialcart/attackby(obj/item/I, mob/user, params)
	var/fail_msg = span_warning("There is already one of those in [src]!")

	if(istype(I, /obj/item/mop))
		var/list/modifiers = params2list(params)
		if(is_refillable() && modifiers["ctrl"] || user.a_intent == INTENT_HARM) //BLUEMOON ADD: Ctrl+click or 4th (harm) intent wrings the I out into the cart tank
			if(I.reagents.total_volume <= 0)
				to_chat(user, span_warning("The I is dry!"))
				return
			if(reagents.total_volume >= reagents.maximum_volume)
				to_chat(user, span_warning("[src] is full!"))
				return
			I.reagents.remove_all(I.reagents.total_volume * SQUEEZING_DISPERSAL_RATIO)
			I.reagents.trans_to(src, I.reagents.total_volume)
			to_chat(user, span_notice("You squeeze [I] out into [src]."))
			playsound(loc, 'sound/effects/slosh.ogg', 25, 1)
		else if(I.reagents.total_volume < I.reagents.maximum_volume)
			if (wet_mop(I, user))
				return
		else if(!mymop)
			var/obj/item/mop/mop=I
			mop.janicart_insert(user, src)
		else
			to_chat(user, fail_msg)
	else if(istype(I, /obj/item/broom))
		if(!mybroom)
			var/obj/item/broom/b=I
			b.janicart_insert(user,src)
		else
			to_chat(user, fail_msg)
	else if(istype(I, /obj/item/storage/bag/trash))
		if(!mybag)
			var/obj/item/storage/bag/trash/t=I
			t.janicart_insert(user, src)
		else
			to_chat(user,  fail_msg)
	else if(istype(I, /obj/item/reagent_containers/spray/cleaner))
		if(!myspray)
			put_in_cart(I, user)
			myspray=I
			update_icon()
		else
			to_chat(user, fail_msg)
	else if(istype(I, /obj/item/lightreplacer))
		if(!myreplacer)
			var/obj/item/lightreplacer/l=I
			l.janicart_insert(user,src)
		else
			to_chat(user, fail_msg)
	else if(istype(I, /obj/item/clothing/suit/caution))
		if(signs < max_signs)
			put_in_cart(I, user)
			signs++
			update_icon()
		else
			to_chat(user, span_warning("[src] can't hold any more signs!"))
	else if(mybag)
		mybag.attackby(I, user)
	else if(I.tool_behaviour == TOOL_CROWBAR)
		user.visible_message("[user] begins to empty the contents of [src].", span_notice("You begin to empty the contents of [src]..."))
		if(I.use_tool(src, user, 30))
			to_chat(user, span_notice("You empty the contents of [src]'s bucket onto the floor."))
			reagents.reaction(src.loc)
			src.reagents.clear_reagents()
	else
		return ..()

/obj/structure/janitorialcart/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)

	var/list/items = list()
	if(mybag)
		items += list("Trash bag" = image(icon = mybag.icon, icon_state = mybag.icon_state))
	if(mymop)
		items += list("Mop" = image(icon = mymop.icon, icon_state = mymop.icon_state))
	if(mybroom)
		items += list("Broom" = image(icon = mybroom.icon, icon_state = mybroom.icon_state))
	if(myspray)
		items += list("Spray bottle" = image(icon = myspray.icon, icon_state = myspray.icon_state))
	if(myreplacer)
		items += list("Light replacer" = image(icon = myreplacer.icon, icon_state = myreplacer.icon_state))
	var/obj/item/clothing/suit/caution/sign = locate() in src
	if(sign)
		items += list("Sign" = image(icon = sign.icon, icon_state = sign.icon_state))

	if(!length(items))
		return
	items = sort_list(items)
	var/pick = items.len == 1 ? items[1] : show_radial_menu(user, src, items, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 38, require_near = TRUE)
	if(!pick)
		return
	switch(pick)
		if("Trash bag")
			if(!mybag)
				return
			user.put_in_hands(mybag)
			to_chat(user, span_notice("You take [mybag] from [src]."))
			mybag = null
		if("Mop")
			if(!mymop)
				return
			user.put_in_hands(mymop)
			to_chat(user, span_notice("You take [mymop] from [src]."))
			mymop = null
		if("Broom")
			if(!mybroom)
				return
			user.put_in_hands(mybroom)
			to_chat(user, span_notice("You take [mybroom] from [src]."))
			mybroom = null
		if("Spray bottle")
			if(!myspray)
				return
			user.put_in_hands(myspray)
			to_chat(user, span_notice("You take [myspray] from [src]."))
			myspray = null
		if("Light replacer")
			if(!myreplacer)
				return
			user.put_in_hands(myreplacer)
			to_chat(user, span_notice("You take [myreplacer] from [src]."))
			myreplacer = null
		if("Sign")
			if(signs <= 0)
				return
			user.put_in_hands(sign)
			to_chat(user, span_notice("You take \a [sign] from [src]."))
			signs--
		else
			return

	update_icon()

/**
  * check_menu: Checks if we are allowed to interact with a radial menu
  *
  * Arguments:
  * * user The mob interacting with a menu
  */
/obj/structure/janitorialcart/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated())
		return FALSE
	return TRUE

/obj/structure/janitorialcart/update_overlays()
	. = ..()
	if(mybag)
		. += "cart_garbage"
	if(mymop)
		. += "cart_mop"
	if(mybroom)
		. += "cart_broom"
	if(myspray)
		. += "cart_spray"
	if(myreplacer)
		. += "cart_replacer"
	if(signs)
		. += "cart_sign[signs]"
	if(reagents.total_volume > 0)
		. += "cart_water"

