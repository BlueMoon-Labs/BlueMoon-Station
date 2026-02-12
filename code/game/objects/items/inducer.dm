/obj/item/inducer
	name = "Engineer inducer"
	desc = "Инструмент для индуктивного заряжания внешних аккумуляторов."
	icon = 'icons/obj/tools.dmi'
	icon_state = "inducer-engi"
	item_state = "inducer-engi"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	force = 7
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	item_flags = SURGICAL_TOOL
	var/powertransfer = 1000
	var/opened = FALSE
	var/cell_type = /obj/item/stock_parts/cell/high
	var/obj/item/stock_parts/cell/cell
	var/recharging = FALSE
	var/gun_charger = FALSE

/obj/item/inducer/Initialize(mapload)
	. = ..()
	if(!cell && cell_type)
		cell = new cell_type

/obj/item/inducer/proc/induce(obj/item/stock_parts/cell/target, coefficient)
	var/totransfer = min(cell.charge,(powertransfer * coefficient))
	var/transferred = target.give(totransfer)
	cell.use(transferred)
	cell.update_icon()
	target.update_icon()

/obj/item/inducer/get_cell()
	return cell

/obj/item/inducer/emp_act(severity)
	. = ..()
	if(!opened)
		severity *= 0.75
	if(cell && !(. & EMP_PROTECT_CONTENTS))
		cell.emp_act(severity)


/obj/item/inducer/proc/cantbeused(mob/user)
	if(!user.IsAdvancedToolUser())
		to_chat(user, span_warning("Вам не хватит ловкости рук для использования [src]!"))
		return TRUE

	if(!cell)
		to_chat(user, span_warning("При использовании [src] ничего не происходит!"))
		return TRUE

	if(!cell.charge)
		to_chat(user, span_warning("[src] издаёт негромкий низкий гул!"))
		return TRUE
	return FALSE


/obj/item/inducer/proc/recharge(atom/movable/A, mob/user)
	if(!isturf(A) && user.loc == A)
		return FALSE
	if(istype(A, /obj/item/gun/energy) && gun_charger != TRUE)
		to_chat(user, span_warning("ОШИБКА: невозможно соединиться с устройством."))
		return FALSE
	if(recharging)
		return TRUE
	else
		recharging = TRUE
	var/obj/item/stock_parts/cell/C = A.get_cell()
	var/obj/O
	var/coefficient = 1
	if(istype(A, /obj))
		O = A
	if(C)
		var/done_any = FALSE
		if(C.charge >= C.maxcharge)
			to_chat(user, span_notice("Заряд [A] на максимуме!</span>"))
			recharging = FALSE
			return TRUE
		user.visible_message("[user] начинает заряжать [A] при помощи [src].", span_notice("Вы начали заряжать [A] при помощи [src]."))
		while(C.charge < C.maxcharge)
			if(do_after(user, 10, target = user) && cell.charge)
				done_any = TRUE
				induce(C, coefficient)
				if(opened)
					do_sparks(1, FALSE, A)
				if(O)
					O.update_icon()
				update_icon()
			else
				break
		if(done_any) // Only show a message if we succeeded at least once
			user.visible_message("[user] перезарядил [A]!", span_notice("Вы перезарядили [A]!"))
		recharging = FALSE
		return TRUE
	recharging = FALSE


/obj/item/inducer/attack(mob/M, mob/user)
	if(user.a_intent == INTENT_HARM)
		return ..()

/obj/item/inducer/attackby(obj/item/W, mob/user)
	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		W.play_tool_sound(src)
		if(!opened)
			to_chat(user, span_notice("Вы отвинтили батарейный слот."))
			opened = TRUE
			update_icon()
			return
		else
			to_chat(user, span_notice("Вы закрыли батарейный слот."))
			opened = FALSE
			update_icon()
			return
	if(istype(W, /obj/item/stock_parts/cell))
		if(opened)
			if(!cell)
				if(!user.transferItemToLoc(W, src))
					return
				to_chat(user, span_notice("Вы вставили [W] внутрь [src]."))
				cell = W
				update_icon()
				return
			else
				to_chat(user, span_notice("[src] уже имеет внутри \a [cell]!"))
				return

	if(cantbeused(user))
		return

	return ..()

/obj/item/inducer/attack_obj(obj/O, mob/living/carbon/user)
	if(user.a_intent == INTENT_HARM)
		return ..()

/obj/item/inducer/attack_self(mob/user)
	if(opened && cell)
		user.visible_message("[user] извлекает [cell] из [src]!", span_notice("Вы извлекли [cell]."))
		cell.update_icon()
		user.put_in_hands(cell)
		cell = null
		update_icon()

/obj/item/inducer/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return

	if(user.a_intent == INTENT_HARM)
		return

	if(cantbeused(user))
		return

	if(recharge(target, user))
		return

/obj/item/inducer/examine(mob/living/M)
	. = ..()
	if(cell)
		. += span_notice("Дисплей сообщает о наличии батареи внутри: [cell.name].")
	else
		. += span_notice("Дисплей устройства матово-тёмный.")
	if(opened)
		. += span_notice("Слот батареи открыт.")

/obj/item/inducer/update_overlays()
	. = ..()
	if(!opened)
		return
	if(!cell)
		. += "inducer-nobat"
	else
		var/charge_percent = cell.percent()
		if(charge_percent >= 98) // Первый слой в списке: статус заряда батареи индусера
			. += "inducer-charge_full"
		else if(charge_percent >= 6)
			. += "inducer-charge_mid"
		else if(charge_percent >= 1)
			. += "inducer-charge_midblink"
		else
			. += "inducer-charge_no"

		if(istype(cell, /obj/item/stock_parts/cell/bluespace) || istype(cell, /obj/item/stock_parts/cell/bluespacereactor))  // Второй слой в списке: тип батареи в индусере. Он кладётся ПОВЕРХ предыдущего слоя
			. += "inducer-bat_bscell"
		else if(istype(cell, /obj/item/stock_parts/cell/vortex))
			. += "inducer-bat_vcell"
		else if(istype(cell, /obj/item/stock_parts/cell/hyper))
			. += "inducer-bat_hpcell"
		else if(istype(cell, /obj/item/stock_parts/cell/super))
			. += "inducer-bat_scell"
		else if(istype(cell, /obj/item/stock_parts/cell/high/plus))
			. += "inducer-bat_h+cell"
		else if(istype(cell, /obj/item/stock_parts/cell/high))
			. += "inducer-bat_hcell"
		else
			. += "inducer-bat"

/obj/item/inducer/dry
	cell_type = null
	opened = TRUE

/obj/item/inducer/dry/Initialize(mapload) //Just in case
	. = ..()
	update_icon()

/obj/item/inducer/sci
	name = "Science inducer"
	icon_state = "inducer-sci"
	item_state = "inducer-sci"
	desc = "Инструмент для индуктивного заряжания внешних аккумуляторов. Этот окрашен в цвета научно-исследовательского отдела и, похоже, менее мощный в сравнении с инженерным аналогом."
	cell_type = null
	powertransfer = 500
	opened = TRUE

/obj/item/inducer/sci/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/inducer/sci/combat
	name = "Combat inducer"
	icon_state = "inducer-combat"
	item_state = "inducer-combat"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_NORMAL
	desc = "Инструмент для индуктивного заряжания внешних аккумуляторов. Видны модификации и улучшения, которые утяжеляют индусер взамен на возможность зарядки энергооружия."
	cell_type = /obj/item/stock_parts/cell/hyper
	opened = FALSE
	gun_charger = TRUE

/obj/item/inducer/sci/combat/dry
	cell_type = null
	opened = TRUE

/obj/item/inducer/sci/combat/dry/Initialize(mapload) //Just in case
	. = ..()
	update_icon()

/obj/item/inducer/sci/combat/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/inducer/sci/supply
	opened = FALSE
	cell_type = /obj/item/stock_parts/cell/inducer_supply

/obj/item/inducer/syndicate
	name = "Syndicate inducer"
	icon_state = "inducer-syndi"
	item_state = "inducer-syndi"
	desc = "Инструмент для индуктивного заряжания внешних аккумуляторов. У этого.. Какая-то знакомая цветовая схема. С ним явно как-то \"пошаманили\" для максимальной скорости зарядки."
	powertransfer = 2000
	cell_type = /obj/item/stock_parts/cell/super

/obj/item/inducer/syndicate/dry
	cell_type = null
	opened = TRUE

/obj/item/inducer/syndicate/dry/Initialize(mapload)
	. = ..()
	update_icon()
