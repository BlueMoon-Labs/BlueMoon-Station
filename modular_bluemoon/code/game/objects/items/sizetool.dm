/obj/item/melee/sizetool
	name = "size tool"
	desc = "A small tool with ability to change size of living creatures. While manufactured by Syntech, it was banned in most of the civilized countries, \
	as it is a popular tool for slave traders and perverts alike. There are rumors they have used some unknown alien technologies for it. \
	Seems like NT doesn't give much of attention to its status since the station is out of borders.<br><br> \
	It has an information patch at a side: <i>\"Do not remain under the effect of the device for more than 24 hours to reduce sensory deprivation, \
	as well as the risk of cancer development!\"</i>"
	icon_state = "silencer"
	icon_state = "silencer"
	icon = 'icons/obj/abductor.dmi'
	lefthand_file = 'icons/mob/inhands/antag/abductor_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/abductor_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	custom_premium_price = 2000
	w_class = WEIGHT_CLASS_SMALL

	var/obj/item/stock_parts/cell/cell
	var/in_use = FALSE
	var/size_set_to = 1
	var/charge_modif = 1
	var/time_modif = 1
	var/min_size = 0.25
	var/max_size = RESIZE_BIG

/obj/item/melee/sizetool/Initialize(mapload)
	. = ..()
	min_size = RESIZE_MICRO
	cell = new /obj/item/stock_parts/cell/high(src)
	register_item_context()

/obj/item/melee/sizetool/attack_self(mob/user)
	. = ..()
	var/size_select

	if(check_for_ghostcafe())
		size_select = tgui_input_number(usr, "Set prefered size ([RESIZE_MICRO * 100]-[RESIZE_MACRO * 100]%).", "Set Size", size_set_to * 100, RESIZE_MACRO * 100, RESIZE_MICRO * 100)
		size_set_to = clamp((size_select/100), min_size, RESIZE_MACRO) //не будем делать переменную для гост кафе размера
	else
		size_select = tgui_input_number(usr, "Set prefered size ([min_size * 100]-[max_size * 100]%).", "Set Size", size_set_to * 100, max_size * 100, min_size * 100)
		size_set_to = clamp((size_select/100), min_size, max_size)
	if(!size_select) return

	to_chat(usr, "<span class='notice'>You set the size to [size_set_to * 100]%</span>")

/obj/item/melee/sizetool/attackby(obj/item/new_item, mob/user, params)
	if(istype(new_item, /obj/item/stock_parts/cell)) // замена батарейки
		var/obj/item/stock_parts/cell/new_cell = new_item
		if(cell)
			to_chat(user, span_warning("[src] already has a cell."))
		else
			if(!user.transferItemToLoc(new_cell, src))
				return
			cell = new_cell
			to_chat(user, span_notice("You install a cell in [src]."))

	else if(new_item.tool_behaviour == TOOL_SCREWDRIVER) // выкручивание батарейки
		if(cell)
			cell.update_icon()
			cell.forceMove(get_turf(src))
			cell = null
			to_chat(user, span_notice("You remove the cell from [src]."))
	else
		return ..()

/obj/item/melee/sizetool/examine(mob/user)
	. = ..()
	. += "<hr>"
	. += span_info("You can use it in ghostcafe to make someone even bigger than 200%.")
	if(cell)
		. += span_info("Its cell can be removed with a screwdriver.")
		. += span_info("[src] is [round(cell.percent())]% charged.")
	else
		. += span_danger("[src] does not have a power source installed.")
	. += span_info("Current prefered size set to <b>[size_set_to * 100]%</b>.")

/obj/item/melee/sizetool/proc/check_for_ghostcafe() // Вы можете использовать весь функционал (в виде повышения размера до 600%) в госткафе
	if(istype(get_area(src), /area/centcom/holding))
		return TRUE
	return FALSE

/obj/item/melee/sizetool/attack(mob/living/target, mob/living/carbon/human/user)
	if(user.a_intent != INTENT_HELP) // если режим взаимодействия не "help", то устройством можно бить
		return ..()
	if(in_use) // нельзя спамить
		return
	if(!isliving(target) || issilicon(target)) // только для существ, не киборгов
		return
	if(user.zone_selected == BODY_ZONE_PRECISE_MOUTH && user == target && user.actions) //съесть сайз тул
		for(var/datum/action/innate/ability/humanoid_customization/HC in user.actions)
			if(HC.body_size_max >= max_size)
				break
			to_chat(user, span_warning("You trying to adapt [src] to yourself."))
			if(do_after(user, 5 SECONDS, target = target))
				HC.body_size_max = max_size
				to_chat(user, span_warning("You feel more freedom and can change body size to [HC.body_size_max * 100]%"))
				qdel(src)
			return

	var/ghostcafe = check_for_ghostcafe()
	var/target_size = get_size(target)
	var/diff = abs(size_set_to - target_size)
	var/charge_per_use = 0
	var/time_per_use = 5 //секунды (важно для гост кафе)
	if(!diff) return
	if(!ghostcafe) //welp если в гост кафе, то статичные 5 секунд на любое изменение размера
		charge_per_use = diff * 4000 * charge_modif // 1000 энергии на каждые 25% размера
		time_per_use = diff * 20 * time_modif //5 секунд на 25% размера
		if(cell?.charge < charge_per_use) // есть ли батарейка и хватает ли в ней энергии
			to_chat(user, span_warning("[src] has not enough power to be used."))
			return

	in_use = TRUE // использование началось

	user.visible_message(span_warning("[user] points [src] at [target] and hold its trigger!"), span_notice("You point your [src] at [target] and hold the trigger. It begins to vibrate and is getting hotter, as the charge is being gained. You need [time_per_use] seconds to finish."))

	if(do_after(user, time_per_use SECONDS, target = target)) // КД перед применением на цель
		in_use = FALSE

		if(!ghostcafe && (!cell || !cell.use(charge_per_use))) // в госткафе заряд не тратится
			to_chat(user, span_warning("[src] goes cold after failed usage. Looks like its power cell has gone out of charge."))
			return

		if(target.GetComponent(/datum/component/size_normalized)) //нормализаторы не дружат с изменениями размера во время их ношения
			to_chat(user, span_warning("[src] goes cold after failed usage. It vibrates, as if it located normalization device on the target."))
			return

		if(HAS_TRAIT(target, TRAIT_BLUEMOON_ANTI_NORMALIZER))
			to_chat(user, span_notice("[src] buzzes in your hand while goes cold after usage. Looks like nothing changed?"))
			playsound(src, 'sound/machines/buzz-sigh.ogg', 50, 1)
			return

		target.update_size(size_set_to)

		playsound(target, 'sound/effects/magic.ogg', 50, 1)
		target.flash_lighting_fx(3, 3, LIGHT_COLOR_PURPLE)
		target.visible_message(span_warning("A flash of purple light engulfs \the [target], before [target.ru_who()] jump[target.p_s()] to [target_size > size_set_to ? "bigger" : "smaller"] size!"), \
		span_notice("You feel warm for a moment, before everything [target_size > size_set_to  ? "becomes smaller" : "becomes bigger"]..."))
		return
	else
		in_use = FALSE // использование прервано
		to_chat(user, span_warning("You must stand still to use [src]!"))
		return

/obj/item/melee/sizetool/upgraded
	name = "upgraded size tool"
	max_size = RESIZE_MACRO
	charge_modif = 0
	time_modif = 0.1
