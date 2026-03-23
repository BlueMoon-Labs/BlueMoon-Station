/** BLUEMOON OVERRIDE semi change кода под ново-тг, конечно без использованиях их навороченных фич
 * # Janicart
 */
/obj/vehicle/ridden/janicart
	name = "janicart (pimpin' ride)"
	desc = "A brave janitor cyborg gave its life to produce such an amazing combination of speed and utility."
	icon_state = "pussywagon"
	key_type = /obj/item/key/janitor
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	/// The attached garbage bag, if present
	var/obj/item/storage/bag/trash/trash_bag
	/// The installed upgrade, if present
	var/obj/item/janicart_upgrade/installed_upgrade
	/// BLUEMOON ADD переключение режимов работы жаникарта
	var/static/radial_eject_trash = image(icon = 'icons/obj/janitor.dmi', icon_state = "trashbag")
	var/static/radial_eject_key = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_eject_key")
	// var/static/radial_buffer_mode = image(icon = 'icons/obj/service/janicart_upgrade.dmi', icon_state = "/obj/item/janicart_upgrade/buffer")
	// var/static/radial_vacuum_mode = image(icon = 'icons/obj/service/janicart_upgrade.dmi', icon_state = "/obj/item/janicart_upgrade/vacuum")
	var/static/radial_unbuckle = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_eject")
	var/use_buffer = TRUE
	var/use_vacuum = TRUE

/obj/vehicle/ridden/janicart/Initialize(mapload)
	. = ..()
	register_context()
	update_icon()
	var/datum/component/riding/D = LoadComponent(/datum/component/riding)
	D.set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 7), TEXT_EAST = list(-12, 7), TEXT_WEST = list( 12, 7)))
	GLOB.janitor_devices += src
	if(installed_upgrade)
		installed_upgrade.install(src)

/obj/vehicle/ridden/janicart/Destroy()
	GLOB.janitor_devices -= src
	if(trash_bag)
		QDEL_NULL(trash_bag)
	if(installed_upgrade)
		QDEL_NULL(installed_upgrade)
	return ..()

/obj/vehicle/ridden/janicart/examine(mob/user)
	. = ..()
	if(installed_upgrade)
		. += "It has been upgraded with [installed_upgrade], which can be removed with a screwdriver."

/obj/vehicle/ridden/janicart/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(istype(I, /obj/item/storage/bag/trash))
		if(trash_bag)
			to_chat(user, span_warning("[src] already has a trashbag hooked!"))
			return
		if(!user.transferItemToLoc(I, src))
			return
		to_chat(user, span_notice("You hook the trashbag onto [src]."))
		trash_bag = I
		RegisterSignal(trash_bag, COMSIG_PARENT_QDELETING, PROC_REF(bag_deleted))
		SEND_SIGNAL(src, COMSIG_VACUUM_BAG_ATTACH, I)
		update_appearance()
	else if(istype(I, /obj/item/janicart_upgrade))
		if(installed_upgrade)
			to_chat(user, span_warning("[src] already has an upgrade installed! Use a screwdriver to remove it."))
			return
		var/obj/item/janicart_upgrade/new_upgrade = I
		new_upgrade.forceMove(src)
		new_upgrade.install(src)
		to_chat(user, span_notice("You upgrade [src] with [new_upgrade]."))
		update_appearance()
		if(new_upgrade.cleaning)
			initialize_controller_action_type(/datum/action/vehicle/ridden/buffer_mode, VEHICLE_CONTROL_DRIVE)
		if(new_upgrade.vacuum)
			initialize_controller_action_type(/datum/action/vehicle/ridden/vacuum_mode, VEHICLE_CONTROL_DRIVE)
	else if(I.tool_behaviour == TOOL_SCREWDRIVER && installed_upgrade)
		remove_controller_action_type(/datum/action/vehicle/ridden/buffer_mode, VEHICLE_CONTROL_DRIVE)
		remove_controller_action_type(/datum/action/vehicle/ridden/vacuum_mode, VEHICLE_CONTROL_DRIVE)
		installed_upgrade.forceMove(get_turf(user))
		user.put_in_hands(installed_upgrade)
		I.play_tool_sound(src, 50)
		to_chat(user, span_notice("You remove [installed_upgrade] from [src]"))
		installed_upgrade.uninstall(src)
		update_appearance()
	else if(user.a_intent == INTENT_HARM && trash_bag && (!is_key(I) || is_key(inserted_key))) // don't put a key in the trash when we need it
		var/datum/component/storage/STR = trash_bag.GetComponent(/datum/component/storage)
		if(STR.can_be_inserted(I, TRUE))
			STR.handle_item_insertion(I, TRUE)
	else
		return ..()

/obj/vehicle/ridden/janicart/update_overlays()
	. = ..()
	if(trash_bag)
		if(istype(trash_bag, /obj/item/storage/bag/trash/bluespace))
			. += "cart_bluespace_garbage"
		else
			. += "cart_garbage"
	if(installed_upgrade)
		. += "[installed_upgrade.janicart_overlay]"

// BLUEMOON CHANGE ui интеракции вместо простой атаки рукой
/obj/vehicle/ridden/janicart/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(act_intent == INTENT_HARM)
		..()

/obj/vehicle/ridden/janicart/ui_interact(mob/user) // The microwave Menu //I am reasonably certain that this is not a microwave
	. = ..()
	if(user.a_intent == INTENT_HARM)
		return
	if(!user.canUseTopic(src, !issilicon(user)))
		return

	var/list/options = list()

	if(trash_bag)
		options["remove trash bag"] = radial_eject_trash
	if(inserted_key)
		options["remove key"] = radial_eject_key
	// if(installed_upgrade)
	// 	if(installed_upgrade.cleaning)
	// 		options["switch buffer mode"] = radial_buffer_mode
	// 	if(installed_upgrade.vacuum)
	// 		options["switch vacuum mode"] = radial_vacuum_mode
	if(occupants)
		options["unbuckle driver"] = radial_unbuckle

	var/choice = show_radial_menu(user, src, options, require_near = !hasSiliconAccessInArea(user))

	switch(choice)
		if("remove trash bag")
			try_remove_bag(user)
		if("remove key")
			AltClick(user)
		// if("switch buffer mode")
		// 	switch_mode("buffer", user)
		// if("switch vacuum mode")
		// 	switch_mode("vacuum", user)
		if("unbuckle driver")
			user_unbuckle_mob(buckled_mobs[1],user)

/obj/vehicle/ridden/janicart/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(!held_item && occupant_amount() > 0 && is_key(inserted_key) && occupants.Find(user))
		LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Remove key")
		return CONTEXTUAL_SCREENTIP_SET

	if(istype(held_item, /obj/item/storage/bag/trash) && !trash_bag)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Add trash bag")
		return CONTEXTUAL_SCREENTIP_SET

	if(istype(held_item, /obj/item/janicart_upgrade) && !installed_upgrade)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Install upgrade")
		return CONTEXTUAL_SCREENTIP_SET

	if(istype(held_item, /obj/item/screwdriver) && installed_upgrade)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Remove upgrade")
		return CONTEXTUAL_SCREENTIP_SET

	if(is_key(held_item) && !is_key(inserted_key))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Insert key")
		return CONTEXTUAL_SCREENTIP_SET

	if(trash_bag)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Insert into trash bag")
		return CONTEXTUAL_SCREENTIP_SET

/**
 * Called if the attached bag is being qdeleted, ensures appearance is maintained properly
 */
/obj/vehicle/ridden/janicart/proc/bag_deleted(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(try_remove_bag))

/**
 * Attempts to remove the attached trash bag, returns true if bag was removed
 *
 * Arguments:
 * * remover - The (optional) mob attempting to remove the bag
 */
/obj/vehicle/ridden/janicart/proc/try_remove_bag(mob/remover = null)
	if (!trash_bag)
		return FALSE
	if (remover)
		trash_bag.forceMove(get_turf(remover))
		remover.put_in_hands(trash_bag)
	UnregisterSignal(trash_bag, COMSIG_PARENT_QDELETING)
	trash_bag = null
	SEND_SIGNAL(src, COMSIG_VACUUM_BAG_DETACH)
	update_appearance()
	return TRUE

/obj/vehicle/ridden/janicart/proc/switch_mode(var/switched_functional, mob/user)
	switch(switched_functional)
		if("buffer")
			use_buffer = !use_buffer
			to_chat(user, span_notice("You switched [src] [switched_functional] [use_buffer ? "on" : "off"]."))
		if("vacuum")
			use_vacuum = !use_vacuum
			to_chat(user, span_notice("You switched [src] [switched_functional] [use_vacuum ? "on" : "off"]."))
	update_abilities()

/obj/vehicle/ridden/janicart/proc/update_abilities()
	if(!installed_upgrade)
		RemoveElement(/datum/element/cleaning)
		qdel(GetComponent(/datum/component/vacuum))
		use_buffer = initial(use_buffer)
		use_vacuum = initial(use_vacuum)
		return

	if(installed_upgrade.cleaning)
		if(use_buffer)
			AddElement(/datum/element/cleaning)
		else
			RemoveElement(/datum/element/cleaning)
	if(installed_upgrade.vacuum)
		if(use_vacuum)
			AddComponent(/datum/component/vacuum, trash_bag)
		else
			qdel(GetComponent(/datum/component/vacuum))

/obj/vehicle/ridden/janicart/upgraded
	installed_upgrade = new /obj/item/janicart_upgrade/buffer

/obj/vehicle/ridden/janicart/upgraded/vacuum
	installed_upgrade = new /obj/item/janicart_upgrade/vacuum

/obj/vehicle/ridden/janicart/upgraded/omni
	installed_upgrade = new /obj/item/janicart_upgrade/omni

/**
 * # Janicart Upgrade
 *
 * Functional upgrades that can be installed into a janicart.
 *
 */
/obj/item/janicart_upgrade
	name = "base upgrade"
	desc = "An abstract upgrade for mobile janicarts."
	icon = 'icons/obj/service/janicart_upgrade.dmi'
	icon_state = "janicart_upgrade"
	var/janicart_overlay
	var/cleaning = FALSE
	var/vacuum = FALSE

/**
 * Called when upgrade is installed into a janicart
 *
 * Arguments:
 * * installee - The cart the upgrade is being installed into
 */
/obj/item/janicart_upgrade/proc/install(obj/vehicle/ridden/janicart/installee)
	installee.installed_upgrade = src
	installee.update_abilities()

/**
 * Called when upgrade is uninstalled from a janicart
 *
 * Arguments:
 * * installee - The cart the upgrade is being removed from
 */
/obj/item/janicart_upgrade/proc/uninstall(obj/vehicle/ridden/janicart/installee)
	installee.installed_upgrade = null
	installee.update_abilities()

/obj/item/janicart_upgrade/buffer
	name = "floor buffer upgrade"
	desc = "An upgrade for mobile janicarts which adds a floor buffer functionality."
	icon_state = "/obj/item/janicart_upgrade/buffer"
	janicart_overlay = "buffer_upgrade"
	cleaning = TRUE

/obj/item/janicart_upgrade/vacuum
	name = "vacuum upgrade"
	desc = "An upgrade for mobile janicarts which adds a vacuum functionality."
	icon_state = "/obj/item/janicart_upgrade/vacuum"
	janicart_overlay = "vacuum_upgrade"
	vacuum = TRUE

// омни улучшение, комбинация предыдущих двух
/obj/item/janicart_upgrade/omni
	name = "omni upgrade"
	desc = "An upgrade for mobile janicarts which adds both functionality of vacuum and floor buffer upgrade."
	icon_state = "/obj/item/janicart_upgrade/omni"
	janicart_overlay = "omni_upgrade"
	cleaning = TRUE
	vacuum = TRUE


/datum/action/vehicle/ridden/buffer_mode
	name = "buffer"
	icon_icon = 'icons/obj/service/janicart_upgrade.dmi'
	button_icon_state = "/obj/item/janicart_upgrade/buffer"

/datum/action/vehicle/ridden/buffer_mode/Trigger()
	. = ..()
	if(. && istype(vehicle_ridden_target, /obj/vehicle/ridden/janicart))
		var/obj/vehicle/ridden/janicart/J = vehicle_ridden_target
		J.switch_mode("buffer", owner)
		UpdateButtons()

/datum/action/vehicle/ridden/buffer_mode/UpdateButton(atom/movable/screen/movable/action_button/button, status_only, force)
	if(istype(vehicle_ridden_target, /obj/vehicle/ridden/janicart))
		var/obj/vehicle/ridden/janicart/J = vehicle_ridden_target
		if(J.use_buffer)
			background_icon_state = "bg_default_on"
		else
			background_icon_state = "bg_default"
	. = ..()

/datum/action/vehicle/ridden/vacuum_mode
	name = "vacuum"
	icon_icon = 'icons/obj/service/janicart_upgrade.dmi'
	button_icon_state = "/obj/item/janicart_upgrade/vacuum"

/datum/action/vehicle/ridden/vacuum_mode/Trigger()
	. = ..()
	if(. && istype(vehicle_ridden_target, /obj/vehicle/ridden/janicart))
		var/obj/vehicle/ridden/janicart/J = vehicle_ridden_target
		J.switch_mode("vacuum", owner)
		UpdateButtons()

/datum/action/vehicle/ridden/vacuum_mode/UpdateButton(atom/movable/screen/movable/action_button/button, status_only, force)
	if(istype(vehicle_ridden_target, /obj/vehicle/ridden/janicart))
		var/obj/vehicle/ridden/janicart/J = vehicle_ridden_target
		if(J.use_vacuum)
			background_icon_state = "bg_default_on"
		else
			background_icon_state = "bg_default"
	. = ..()
