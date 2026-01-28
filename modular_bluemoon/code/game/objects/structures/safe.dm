// Armory redcode safe

/obj/structure/safe
	/// Список кодов, при которых открывается сейф
	var/list/open_security_levels = list()
	/// Переменная кастомизации интерфейса TGUI
	var/tgui_theme = "ntos"

/obj/structure/safe/ui_static_data(mob/user)
	var/list/data = list()
	data["theme"] = tgui_theme

	return data

/// Proc for opening safe via certain condition, using station code in our case.
/obj/structure/safe/proc/code_opening()
	SIGNAL_HANDLER
	return

//////////////////////////////////////////////////

/obj/structure/safe/floor/syndi
	name = "plastitanium safe"
	desc = "This looks like a hell of plastitanium chunk of armored safe, built into a wall or floor, with a dial and syndicate insignia on it."
	icon = 'modular_bluemoon/icons/obj/structures.dmi'
	icon_state = "floorsafe_syndi"
	number_of_tumblers = 4

/// Сейф оружейной СБ и только оружейной
/obj/structure/safe/floor/syndi/armory
	name = "armory safe"
	number_of_tumblers = 8
	maxspace = 48
	open_security_levels = list(SEC_LEVEL_RED, SEC_LEVEL_LAMBDA, SEC_LEVEL_GAMMA)
	tgui_theme = "syndicate"

/obj/structure/safe/floor/syndi/armory/Initialize(mapload)
	. = ..()
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(code_opening)) // Ловим сигнал смены кода на станции

/obj/structure/safe/floor/syndi/armory/code_opening()
	if(GLOB.security_level in open_security_levels) // Если кодов нет в списке - не откроет
		playsound(src, 'modular_bluemoon/sound/effects/opening-gears.ogg', 200, ignore_walls = TRUE)
		visible_message("<span class='warning'>You hear a loud sound of something heavy opening.</span>")
		locked = 0
		open = 1
		current_tumbler_index = 7
		update_icon()

/obj/structure/safe/floor/syndi/armory/Destroy()
	. = ..()
	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)

