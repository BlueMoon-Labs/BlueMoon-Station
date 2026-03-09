#define DATA_ICON "icon"
#define DATA_ICON_STATE "icon_state"
#define DATA_ICON_WORN_OVERLAY "mob_overlay_icon"

/obj/item/clothing/glasses/cover
	icon = 'modular_bluemoon/icons/obj/clothing/glasses.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/eyes.dmi'
	custom_materials = list(/datum/material/cloth = 250)
	is_edible = TRUE
	var/alist/previous_icon_data = alist(
		DATA_ICON = "",
		DATA_ICON_STATE = "",
		DATA_ICON_WORN_OVERLAY = ""
	)
	var/obj/item/clothing/glasses/wrapped_on
	var/can_switch_eye = TRUE
	var/flipped = FALSE
	var/has_adapt_icon_states = TRUE

/obj/item/clothing/glasses/cover/examine(mob/user)
	. = ..()
	. += span_notice("Под [src] можно установить очки.")
	if(can_switch_eye)
		. += span_notice("Ctrl-shift-click чтобы сменить закрываемый [src] глаз.")

/obj/item/clothing/glasses/cover/update_icon_state()
	if(wrapped_on && has_adapt_icon_states)
		icon_state = "[wrapped_on.glasses_type][base_icon_state][flipped ? "_flipped" : ""]"
	else
		icon_state = "[base_icon_state][flipped ? "_flipped" : ""]"

	if(wrapped_on)
		wrapped_on.icon_state = icon_state

/obj/item/clothing/glasses/cover/afterattack(obj/item/clothing/glasses/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return
	if(!istype(target))
		return
	if(istype(target, /obj/item/clothing/glasses/cover) || locate(/obj/item/clothing/glasses/cover) in target)
		return

	wrapped_on = target
	previous_icon_data[DATA_ICON] = target.icon
	previous_icon_data[DATA_ICON_STATE] = target.icon_state
	previous_icon_data[DATA_ICON_WORN_OVERLAY] = target.mob_overlay_icon
	update_icon(UPDATE_ICON_STATE)
	target.icon = icon
	target.icon_state = icon_state
	target.mob_overlay_icon = mob_overlay_icon
	RegisterSignal(target, COMSIG_ATOM_TOOL_ACT(TOOL_SCREWDRIVER), PROC_REF(remove))
	RegisterSignal(target, COMSIG_CLICK_CTRL_SHIFT, PROC_REF(wrapped_on_CtrlShiftClick))
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(wrapped_on_examine))
	RegisterSignal(target, COMSIG_ATOM_UPDATE_ICON_STATE, PROC_REF(on_update_icon))
	forceMove(target)

/obj/item/clothing/glasses/cover/proc/on_update_icon(datum/source)
	SIGNAL_HANDLER
	update_icon(UPDATE_ICON_STATE)

/obj/item/clothing/glasses/cover/proc/wrapped_on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("Под [src] находится [wrapped_on]. Их можно разъединить при помощи отвёртки!")
	if(can_switch_eye)
		examine_list += span_notice("Ctrl-shift-click чтобы сменить закрываемый [src] глаз.")

/obj/item/clothing/glasses/cover/proc/remove(datum/source, mob/living/user, obj/item/I, list/mutable_recipes)
	SIGNAL_HANDLER
	if(I)
		I.play_tool_sound(src, 50)
	UnregisterSignal(wrapped_on, list(COMSIG_ATOM_TOOL_ACT(TOOL_SCREWDRIVER), COMSIG_CLICK_CTRL_SHIFT,
									COMSIG_PARENT_EXAMINE, COMSIG_ATOM_UPDATE_ICON_STATE))
	if(QDELETED(wrapped_on))
		return

	wrapped_on.icon = previous_icon_data[DATA_ICON]
	wrapped_on.icon_state = previous_icon_data[DATA_ICON_STATE]
	if(previous_icon_data[DATA_ICON_WORN_OVERLAY])
		wrapped_on.mob_overlay_icon = previous_icon_data[DATA_ICON_WORN_OVERLAY]
	else
		wrapped_on.mob_overlay_icon = null
	previous_icon_data[DATA_ICON] = ""
	previous_icon_data[DATA_ICON_STATE] = ""
	previous_icon_data[DATA_ICON_WORN_OVERLAY] = ""
	forceMove(get_turf(wrapped_on))
	wrapped_on = null
	if(user)
		user.update_inv_glasses()
	update_icon(UPDATE_ICON_STATE)

/obj/item/clothing/glasses/cover/proc/wrapped_on_CtrlShiftClick(datum/source, mob/user)
	SIGNAL_HANDLER
	CtrlShiftClick(user)

/obj/item/clothing/glasses/cover/CtrlShiftClick(mob/user)
	. = ..()
	if(!can_switch_eye)
		return
	flipped = !flipped
	update_icon(UPDATE_ICON_STATE)
	if(user)
		user.update_inv_glasses()

/obj/item/clothing/glasses/cover/Destroy()
	if(QDELETED(wrapped_on))
		wrapped_on = null
	else if(wrapped_on)
		remove()
	. = ..()

/obj/item/clothing/glasses/cover/eyepatch
	name = "eyepatch"
	desc = "Yarr."
	icon_state = "eyepatch"
	base_icon_state = "eyepatch"

/obj/item/clothing/glasses/cover/fakeblindfold
	name = "thin blindfold"
	desc = "Covers the eyes, but not thick enough to obscure vision. Mostly for aesthetic."
	icon_state = "blindfoldwhite"
	base_icon_state = "blindfoldwhite"
	can_switch_eye = FALSE
	has_adapt_icon_states = FALSE

/obj/item/clothing/glasses/cover/obsolete
	name = "obsolete fake blindfold"
	desc = "An ornate fake blindfold, devoid of any electronics. It's believed to be originally worn by members of bygone military force that sought to protect humanity."
	icon_state = "fold"
	base_icon_state = "fold"

/obj/item/clothing/glasses/cover/lace
	name = "silk blindfold"
	desc = "A blindfold made from black silk, it feels nice to the touch."
	icon_state = "fold_silk"
	base_icon_state = "fold_silk"
	can_switch_eye = FALSE
	has_adapt_icon_states = FALSE

#undef DATA_ICON
#undef DATA_ICON_STATE
#undef DATA_ICON_WORN_OVERLAY
