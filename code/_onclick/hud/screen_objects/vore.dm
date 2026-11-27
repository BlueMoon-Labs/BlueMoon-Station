/atom/movable/screen/voretoggle
	name = "Vore меню"
	icon = 'modular_citadel/icons/ui/screen_midnight.dmi'
	icon_state = "nom_off"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/voretoggle/Initialize()
	. = ..()
	register_context()

/atom/movable/screen/voretoggle/add_context(atom/source, list/context, obj/item/held_item, mob/living/carbon/human/user)
	. = ..()
	. = CONTEXTUAL_SCREENTIP_SET
	LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, user.voremode ? "Выключить режим Vore" : "Включить режим Vore")

/atom/movable/screen/voretoggle/Click(location, control, params)
	if(usr != hud.mymob)
		return
	var/mob/living/carbon/C = usr
	var/list/modifiers = params2list(params)
	if(modifiers["ctrl"])
		if(SEND_SIGNAL(usr, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE))
			to_chat(usr, span_warning("Для начала выключите боевой режим."))
			return
		C.toggle_vore_mode()
		return

	if(!C.vorePanel)
		log_game("VORE: [C] ([type], \ref[C]) didn't have a vorePanel and tried to use the verb.")
		C.vorePanel = new(C)

	C.vorePanel.ui_interact(C)

/atom/movable/screen/voretoggle/update_icon_state()
	var/mob/living/carbon/user = hud?.mymob
	if(!istype(user))
		return
	if(user.voremode)
		icon_state = "nom"
	else
		icon_state = "nom_off"
