/*
CONTAINS:
SAFES
FLOOR SAFES
*/

/// Chance for a sound clue
#define SOUND_CHANCE 10
/// Explosion number threshold for opening safe
#define BROKEN_THRESHOLD 3
#define DRILL_TICK_TIME 5 DECISECONDS

//SAFES
/obj/structure/safe
	name = "safe"
	desc = "Огромный \"шмат\" железа с циферблатным замком на нём. Мелкий шрифт на нём пишет: \"Scarborough Arms - двухсувальдный сейф с гарантией термитозащиты, взрывозащитой и ассистенто-защитой.\""
	icon = 'icons/obj/structures.dmi'
	icon_state = "safe"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	/// The maximum combined w_class of stuff in the safe
	var/maxspace = 24
	/// The amount of tumblers that will be generated
	var/number_of_tumblers = 2
	/// Whether the safe is open or not
	var/open = FALSE
	/// Whether the safe is locked or not
	var/locked = TRUE
	/// The position the dial is pointing to
	var/dial = 0
	/// The list of tumbler dial positions that need to be hit
	var/list/tumblers = list()
	/// The index in the tumblers list of the tumbler dial position that needs to be hit
	var/current_tumbler_index = 1
	/// The combined w_class of everything in the safe
	var/space = 0
	/// Tough, but breakable if explosion counts reaches set value
	var/explosion_count = 0
	/// Список кодов, при которых открывается сейф
	var/list/open_security_levels = list()
	/// Переменная кастомизации интерфейса TGUI
	var/tgui_theme = "ntos"
	/// Переменная для while условия производится ли бурение
	var/drill_process = FALSE
	/// Прочность замка, чтобы не трогать obj_integrity
	var/max_lock_integrity = 300
	var/lock_integrity
	/// Булева проверка на то, может ли бур бурить этот конкретный сейф
	var/drillable = TRUE

/obj/structure/safe/Initialize(mapload)
	. = ..()

	if(max_lock_integrity)
		lock_integrity = max_lock_integrity
	else
		lock_integrity = max_integrity

	// Combination generation
	for(var/i in 1 to number_of_tumblers)
		tumblers.Add(rand(0, 99))

	if(!mapload)
		return

	// Put as many items on our turf inside as possible
	for(var/obj/item/I in loc)
		if(space >= maxspace)
			return
		if(I.w_class + space <= maxspace)
			space += I.w_class
			I.forceMove(src)

/obj/structure/safe/update_icon_state()
	if(open)
		icon_state = "[initial(icon_state)]-open"
	else
		icon_state = initial(icon_state)

/obj/structure/safe/examine(mob/user)
	. = ..()
	if(lock_integrity < max_lock_integrity)
		var/lock_integrity_persentage = (lock_integrity / max_lock_integrity) * 100
		switch(lock_integrity_persentage)
			if(80 to 95)
				. += span_notice("Выглядит слегка потёртым.")
			if(26 to 79.99)
				. += span_warning("Имеет сильные повреждения замка.")
			if(1 to 25.99)
				. += span_danger("Замок просверлен насквозь!")
	if(explosion_count)
		switch(explosion_count)
			if(1)
				. += span_notice("Видны лёгкие вмятины.")
			if(2)
				. += span_notice("Видно сильные вмятины и повреждения.")
			if(3)
				. += span_danger("Сейф взорван!")

/obj/structure/safe/attackby(obj/item/I, mob/user, params)
	if(open)
		. = TRUE //no afterattack
		if(I.w_class + space <= maxspace)
			space += I.w_class
			if(!user.transferItemToLoc(I, src))
				to_chat(user, span_warning("Пока [I] липнет к вашей руке – в сейф положить не получится!"))
				return
			to_chat(user, span_notice("Вы поместили [I] внутрь [src]."))
		else
			to_chat(user, span_warning("[I] не поместится внутрь [src]."))
	else
		if(istype(I, /obj/item/clothing/neck/stethoscope))
			attack_hand(user)
			return TRUE
		if(istype(I, /obj/item/pickaxe/drill) && !check_broken())
			if(I.type == /obj/item/pickaxe/drill/jackhammer)
				return to_chat(user, span_warning("Отбойный молоток для этого не подойдёт!"))
			if(!drillable)
				return to_chat(user, span_warning("Похоже, материал [src] слишком вязкий для работы сверлом!"))
			var/obj/item/pickaxe/drill/drill = I
			start_drilling_sequence(user, drill, drill.diamonded)
			return TRUE
		else
			to_chat(user, span_warning("Вы не можете положить [I] внутрь сейфа, пока тот закрыт!"))
			return TRUE

/obj/structure/safe/proc/start_drilling_sequence(mob/user, obj/item/drill, diamond)
	if(drill_process)
		return
	if(check_broken())
		to_chat(user, span_warning("Замок [src] уже вскрыт!"))
		return FALSE

	user.visible_message(
		span_danger("[user] начинает сверлить [src] с помощью [drill]!"),
		span_notice("Вы начинаете сверлить [src]..."),
		span_hear("Вы слышите работу бура."))

	drill_process = TRUE
	while(!QDELETED(src) && lock_integrity > 0 && !open)
		if(!do_after(user, DRILL_TICK_TIME, src, progress = FALSE))
			break
		if(QDELETED(drill) || !user.is_holding(drill))
			break
		if(!diamond)
			drill.take_damage(1, BRUTE, MELEE, FALSE)
			if(QDELETED(drill))
				break

		if(user.mob_weight <= MOB_WEIGHT_LIGHT || get_size(user) <= 0.8)
			user.Shake(duration = DRILL_TICK_TIME)
		else
			user.Jitter(5)

		playsound(src, drill.usesound, 100, TRUE, 5)
		--lock_integrity
		if(check_broken())
			locked = 0
			break

	drill_process = FALSE
	if(!QDELETED(src) && !lock_integrity)
		visible_message(span_danger("Замок [src] просверлен!"))
		return TRUE
	return FALSE

/obj/structure/safe/blob_act(obj/structure/blob/B)
	return

/obj/structure/safe/ex_act(severity, target, origin)
	if(((severity == 2 && target == src) || severity == 1) && explosion_count < BROKEN_THRESHOLD)
		explosion_count++

/obj/structure/safe/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/safe),
	)

/obj/structure/safe/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/safe/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Safe", name)
		ui.open()

/obj/structure/safe/ui_static_data(mob/user)
	var/list/data = list()
	data["theme"] = tgui_theme

	return data

/obj/structure/safe/ui_data(mob/user)
	var/list/data = list()
	data["dial"] = dial
	data["open"] = open
	data["locked"] = locked
	data["broken"] = check_broken()

	if(open)
		var/list/contents_names = list()
		data["contents"] = contents_names
		for(var/obj/O in contents)
			contents_names[++contents_names.len] = list("name" = O.name, "sprite" = O.icon_state)
			user << browse_rsc(icon(O.icon, O.icon_state), "[O.icon_state].png")

	return data

/obj/structure/safe/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(!ishuman(usr))
		return
	var/mob/living/carbon/human/user = usr
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	var/canhear = FALSE
	if(user.is_holding_item_of_type(/obj/item/clothing/neck/stethoscope))
		canhear = TRUE

	switch(action)
		if("open")
			if(!check_unlocked() && !open && !broken)
				to_chat(user, span_warning("Вы не можете открыть [src], пока замок закрыт!"))
				return
			to_chat(user, span_notice("Вы [open ? "закрыли" : "открыли"] [src]."))
			open = !open
			update_icon()
			return TRUE
		if("turnright")
			if(open)
				return
			if(broken)
				to_chat(user, span_warning("Циферблат не поворачивается: механизм сломан!"))
				return
			var/ticks = text2num(params["num"])
			for(var/i = 1 to ticks)
				dial = WRAP(dial - 1, 0, 100)

				var/invalid_turn = current_tumbler_index % 2 == 0 || current_tumbler_index > number_of_tumblers
				if(invalid_turn) // The moment you turn the wrong way or go too far, the tumblers reset
					current_tumbler_index = 1

				if(!invalid_turn && dial == tumblers[current_tumbler_index])
					notify_user(user, canhear, list("tink", "krink", "plink"), ticks, i)
					current_tumbler_index++
				else
					notify_user(user, canhear, list("clack", "scrape", "clank"), ticks, i)
			check_unlocked()
			return TRUE
		if("turnleft")
			if(open)
				return
			if(broken)
				to_chat(user, span_warning("Циферблат не поворачивается: механизм сломан!"))
				return
			var/ticks = text2num(params["num"])
			for(var/i = 1 to ticks)
				dial = WRAP(dial + 1, 0, 100)

				var/invalid_turn = current_tumbler_index % 2 != 0 || current_tumbler_index > number_of_tumblers
				if(invalid_turn) // The moment you turn the wrong way or go too far, the tumblers reset
					current_tumbler_index = 1

				if(!invalid_turn && dial == tumblers[current_tumbler_index])
					notify_user(user, canhear, list("tonk", "krunk", "plunk"), ticks, i)
					current_tumbler_index++
				else
					notify_user(user, canhear, list("click", "chink", "clink"), ticks, i)
			check_unlocked()
			return TRUE
		if("retrieve")
			if(!open)
				return
			var/index = text2num(params["index"])
			if(!index || index < 1 || index > length(contents))
				return
			var/obj/item/I = contents[index]
			if(!I || !in_range(src, user))
				return
			user.put_in_hands(I)
			space -= I.w_class
			return TRUE

/**
 * Checks if safe is considered in a broken state for force-opening the safe
 */
/obj/structure/safe/proc/check_broken()
	return broken || explosion_count >= BROKEN_THRESHOLD || lock_integrity <= 0

/**
 * Called every dial turn to determine whether the safe should unlock or not.
 */
/obj/structure/safe/proc/check_unlocked()
	if(check_broken())
		return TRUE
	if(current_tumbler_index > number_of_tumblers)
		locked = FALSE
		visible_message(span_boldnotice("[pick("Spring", "Sprang", "Sproing", "Clunk", "Krunk")]!"))
		return TRUE
	else
		locked = TRUE
	return FALSE

/**
 * Called every dial turn to provide feedback if possible.
 */
/obj/structure/safe/proc/notify_user(user, canhear, sounds, total_ticks, current_tick)
	if(!canhear)
		return
	if(current_tick == 2)
		to_chat(user, span_italics("Звуки внутри [src] слишком быстро сменяют друг друга и перемешиваются."))
	if(total_ticks == 1 || prob(SOUND_CHANCE))
		to_chat(user, span_italics("Вы слышите [pick(sounds)] изнутри [src]."))

/**
 * Returns TRUE when the given security level should auto-open this safe.
 */
/obj/structure/safe/proc/security_level_opens_safe(level)
	if(isnull(level))
		level = GLOB.security_level
	if(!isnum(level))
		level = SECLEVEL2NUM(level)
	return length(open_security_levels) && (level in open_security_levels)

/*
 * Proc for opening safe via certain condition, using station code in our case.
 */
/obj/structure/safe/proc/code_opening(datum/source, level)
	SIGNAL_HANDLER
	return

//FLOOR SAFES
/obj/structure/safe/floor
	name = "floor safe"
	icon_state = "floorsafe"
	density = FALSE
	level = 1	//underfloor
	layer = LOW_OBJ_LAYER

/obj/structure/safe/floor/Initialize(mapload)
	. = ..()
	if(mapload)
		var/turf/T = loc
		hide(T.turf_flags & TURF_INTACT)

//////////////////////////////////////////////////

GLOBAL_DATUM_INIT(spare_id_safe, /obj/structure/safe/spare_id, null)

/// Золотой сейф для запасной карты капитана. Случайный код (3 числа по диапазону 0–99) выдается главам на бумажке.
/// Спрайт из tgstation: icons/obj/storage/storage.dmi
/obj/structure/safe/spare_id
	name = "golden safe"
	desc = "Престижный сейф с золотой вставкой, спроектированный для хранения капитанской запасной ID-карты. Комбинация известна только станционным главам."
	icon = 'modular_bluemoon/icons/obj/storage/storage.dmi'
	icon_state = "spare_safe_locked"
	density = FALSE
	number_of_tumblers = 3
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF
	drillable = FALSE

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
	if(!open && explosion_count < BROKEN_THRESHOLD && target == src && (severity == EXPLODE_HEAVY || severity == EXPLODE_DEVASTATE))
		explosion_count = BROKEN_THRESHOLD
		desc += "\nЗамок выломан!"
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
	desc = "Выглядит скорее как огромная пластитановая глыба, а не сейф. Надёжно закрепленный к поверхности и с брендовым цифербладом с синдикатовской инсигнией на нём."
	icon = 'modular_bluemoon/icons/obj/structures.dmi'
	icon_state = "floorsafe_syndi"
	number_of_tumblers = 4
	max_lock_integrity = 600

/// Сейф оружейной СБ и только оружейной
/obj/structure/safe/floor/syndi/armory
	name = "armory safe"
	number_of_tumblers = 8
	maxspace = 70
	open_security_levels = list(SEC_LEVEL_RED, SEC_LEVEL_LAMBDA, SEC_LEVEL_GAMMA)
	tgui_theme = "syndicate"

/obj/structure/safe/floor/syndi/armory/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL || . == INITIALIZE_HINT_QDEL_FORCE)
		return .
	return INITIALIZE_HINT_LATELOAD

/obj/structure/safe/floor/syndi/armory/LateInitialize()
	. = ..()
	if(!is_station_level(z))
		return
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(code_opening)) // Ловим сигнал смены кода на станции
	if(security_level_opens_safe())
		code_opening()

/obj/structure/safe/floor/syndi/armory/code_opening(datum/source, level)
	. = ..()
	if(!security_level_opens_safe(level) || open)
		return
	playsound(src, 'modular_bluemoon/sound/effects/opening-gears.ogg', 200, ignore_walls = TRUE, extrarange = 7)
	visible_message(span_warning("Вы слышите громкий, тяжёлый звук распахивающейся дверцы."))
	locked = FALSE
	open = TRUE
	current_tumbler_index = number_of_tumblers + 1
	update_icon()

/obj/structure/safe/floor/syndi/armory/Destroy()
	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)
	return ..()

#undef SOUND_CHANCE
#undef BROKEN_THRESHOLD
#undef DRILL_TICK_TIME
