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

GLOBAL_DATUM_INIT(spare_id_safe, /obj/structure/safe/spare_id, null)

/// Золотой сейф для запасной карты капитана. Случайный код (3 числа по диапазону 0–99) выдается главам на бумажке.
/// Спрайт из tgstation: icons/obj/storage/storage.dmi
/obj/structure/safe/spare_id
	name = "golden safe"
	desc = "A prestigious safe with a golden sheen, designated for storing the Captain's spare ID. The combination is known to station heads."
	icon = 'modular_bluemoon/icons/obj/storage/storage.dmi'
	icon_state = "spare_safe_locked"
	density = FALSE
	number_of_tumblers = 3
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF

/obj/structure/safe/spare_id/Initialize(mapload)
	. = ..()
	if(!mapload)
		return

	if(!GLOB.spare_id_safe)
		GLOB.spare_id_safe = src
	if(!locate(/obj/item/card/id/captains_spare) in src)
		var/obj/item/card/id/captains_spare/card = new(src)
		space += card.w_class

/obj/structure/safe/spare_id/Destroy()
	if(GLOB.spare_id_safe == src)
		GLOB.spare_id_safe = null
	return ..()

/obj/structure/safe/spare_id/update_icon_state()
	// tgstation storage.dmi: spare_safe (open), spare_safe_locked (closed)
	if(open)
		icon_state = "spare_safe"
	else
		icon_state = "spare_safe_locked"

/// C4/X4 (EXPLODE_HEAVY/DEVASTATE, target == src) — взлом с одного заряда (эквив. BROKEN_THRESHOLD в safe.dm)
/obj/structure/safe/spare_id/ex_act(severity, target, origin)
	if(!open && explosion_count < 3 && target == src && (severity == EXPLODE_HEAVY || severity == EXPLODE_DEVASTATE))
		explosion_count = 3
		desc = initial(desc) + "\nThe lock seems to be broken."
		locked = FALSE
		open = TRUE
		current_tumbler_index = number_of_tumblers + 1
		update_icon()
		visible_message(span_warning("[src] взломан взрывом — замок выбит!"))
		return
	return ..()

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
	maxspace = 70
	open_security_levels = list(SEC_LEVEL_RED, SEC_LEVEL_LAMBDA, SEC_LEVEL_GAMMA)
	tgui_theme = "syndicate"

/obj/structure/safe/floor/syndi/armory/Initialize(mapload)
	. = ..()
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(code_opening)) // Ловим сигнал смены кода на станции

/obj/structure/safe/floor/syndi/armory/code_opening()
	if(GLOB.security_level in open_security_levels && !open) // Если кодов нет в списке - не откроет
		playsound(src, 'modular_bluemoon/sound/effects/opening-gears.ogg', 200, ignore_walls = TRUE)
		visible_message("<span class='warning'>You hear a loud sound of something heavy opening.</span>")
		locked = FALSE
		open = TRUE
		current_tumbler_index = 7
		update_icon()

/obj/structure/safe/floor/syndi/armory/Destroy()
	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)
	return ..()
