/obj/machinery/cell_charger
	name = "cell charger"
	desc = "Заряжает батареи."
	icon = 'icons/obj/power.dmi'
	icon_state = "ccharger"
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 120
	power_channel = EQUIP
	circuit = /obj/item/circuitboard/machine/cell_charger
	pass_flags = PASSTABLE
	var/obj/item/stock_parts/cell/charging = null
	var/charge_rate = 250
	var/recharge_coeff = 1

/obj/machinery/cell_charger/Initialize(mapload)
	. = ..()
	register_context()

/obj/machinery/cell_charger/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	. = CONTEXTUAL_SCREENTIP_SET

	if(held_item?.tool_behaviour == TOOL_SCREWDRIVER)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, panel_open ? "Закрутить панель" : "Открутить панель")
		return .
	if(held_item?.tool_behaviour == TOOL_WRENCH)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, anchored ? "Открутить" : "Прикрутить")
		return .

	LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Вставить батарею")

/obj/machinery/cell_charger/examine(mob/user)
	. = ..()
	. += "В слоте [charging ? "находится \a [charging]" : "отсутствует батарея"]."
	if(charging)
		. += "Текущий заряд: [round(charging.percent(), 1)]%."
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Статус-дисплей сообщает: \n\
		- Скорость зарядки: <b>[recharge_coeff*100]%</b>.")

/obj/machinery/cell_charger/update_overlays()
	. = ..()

	if(!charging)
		return

	if(!(machine_stat & (BROKEN|NOPOWER)))
		var/newlevel = round(charging.percent() * 4 / 100)
		. += "ccharger-o[newlevel]"
	if(!charging.charging_icon)
		. += image(charging.icon, charging.icon_state)
	else
		.+= image('icons/obj/power.dmi', charging.charging_icon)

/obj/machinery/cell_charger/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(charging)
		return FALSE
	if(default_unfasten_wrench(user, tool))
		update_appearance()
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/cell_charger/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stock_parts/cell) && !panel_open)
		if(machine_stat & BROKEN)
			to_chat(user, "<span class='warning'>Устройство сломано!</span>")
			return
		if(!anchored)
			to_chat(user, span_warning("Устройство не прикручено к полу!"))
			return
		if(charging)
			to_chat(user, span_warning("Здесь уже находится батарея!"))
			return
		//SKYRAT EDIT ADDITION
		var/obj/item/stock_parts/cell/inserting_cell = W
		if(inserting_cell.chargerate <= 0)
			to_chat(user, span_warning("[inserting_cell] не может заряжаться!"))
			return
		//SKYRAT EDIT END
		else
			var/area/a = loc.loc // Gets our locations location, like a dream within a dream
			if(!isarea(a))
				return
			if(a.power_equip == 0) // There's no APC in this area, don't try to cheat power!
				to_chat(user, span_warning("[src] мигаети красным при попытке вставить батарею!"))
				return
			if(!user.transferItemToLoc(W,src))
				return

			charging = W
			user.visible_message(span_notice("[user] вставляет батарею в [src]."), span_notice("Вы вставили батарею в [src]."))
			update_appearance()
	else
		if(!charging && default_deconstruction_screwdriver(user, icon_state, icon_state, W))
			return
		if(default_deconstruction_crowbar(W))
			return
		return ..()

/obj/machinery/cell_charger/deconstruct()
	if(charging)
		charging.forceMove(drop_location())
	return ..()

/obj/machinery/cell_charger/Destroy()
	QDEL_NULL(charging)
	return ..()

/obj/machinery/cell_charger/proc/removecell()
	charging.update_appearance()
	charging = null
	update_appearance()

/obj/machinery/cell_charger/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!charging)
		return

	user.put_in_hands(charging)
	charging.add_fingerprint(user)

	user.visible_message(span_notice("[user] извлекает [charging] из [src]."), span_notice("Вы извлекли [charging] из [src]."))

	removecell()


/obj/machinery/cell_charger/attack_tk(mob/user)
	if(!charging)
		return

	charging.forceMove(loc)
	to_chat(user, span_notice("Вы извлекли телекинезом [charging] из [src]."))

	removecell()
	return COMPONENT_CANCEL_ATTACK_CHAIN


/obj/machinery/cell_charger/attack_ai(mob/user)
	return

/obj/machinery/cell_charger/emp_act(severity)
	. = ..()

	if(machine_stat & (BROKEN|NOPOWER) || . & EMP_PROTECT_CONTENTS)
		return

	if(charging)
		charging.emp_act(severity)

/obj/machinery/cell_charger/RefreshParts()
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		recharge_coeff = C.rating

/obj/machinery/cell_charger/process()
	if(!charging || !anchored || (machine_stat & (BROKEN|NOPOWER)))
		return

	if(charging)
		var/obj/item/stock_parts/cell/C = charging.get_cell()
		if(C)
			if(C.charge < C.maxcharge)
				C.give(C.chargerate * recharge_coeff)
				use_power(250 * recharge_coeff)

	update_icon()
