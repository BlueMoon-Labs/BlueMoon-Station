/obj/item/integrated_circuit/manipulation/interacter
	name = "Usage module"
	desc = "A circuit capable of using objects."
	icon_state = "grabber"
	extended_desc = "На вход данной интегралки надо подавать референс объекта для взаимодействия на первый вход. Если же этим объектом является моб, то не забудьте это отметить в входе номер четыре. Интент и части тела для взаимодействия указываются как help, harm, disarm, grab и chest, head, groin и т.д. соответственно. Если в интегралку не вставлен инструмент, то она взаимодействует с объектами как обычная пустая рука, иначе использует поданый на вход(или напрямую вставленный в интегралку) инструмент. Нет, вы не можете вставить инструмент внутрь интегралки и одновременно с этим подать на вход иной. Она не будет работать. МОЖНО ВСТАВИТЬ НЕ БОЛЕЕ ОДНОЙ ТАКОЙ ДЕТАЛИ В ОДНУ СХЕМУ."
	w_class = WEIGHT_CLASS_SMALL
	size = 4
	cooldown_per_use = 15
	complexity = 20
	inputs = list("target" = IC_PINTYPE_REF, "intent" = IC_PINTYPE_STRING, "body_zone" = IC_PINTYPE_STRING, "is Mob" = IC_PINTYPE_BOOLEAN, "Tool" = IC_PINTYPE_REF)
	outputs = list("used object(item, mob)" = IC_PINTYPE_REF, "last intent" = IC_PINTYPE_STRING)
	activators = list("pulse in" = IC_PINTYPE_PULSE_IN,"pulse out" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_COMBAT
	power_draw_per_use = 200
	var/mob/living/carbon/integral/mob_for_using_items
	var/obj/item/installed_item

/mob/living/carbon/integral
	name = "integrated robotic hand"
	var/obj/item/integrated_circuit/manipulation/interacter/my_interacter

/mob/living/carbon/integral/get_active_held_item()
	return(my_interacter.installed_item)

/mob/living/carbon/integral/has_hand_for_held_index()
	return TRUE //В стандартной версии прока у родителя вызывает рантаймы

/obj/item/integrated_circuit/manipulation/interacter/Initialize(mapload)
	. = ..()
	mob_for_using_items = new /mob/living/carbon/integral(src)
	mob_for_using_items.status_flags ^= GODMODE
	mob_for_using_items.my_interacter = src

/obj/item/integrated_circuit/manipulation/interacter/attackby(var/obj/item/item, var/mob/user)
	if(!installed_item)
		var/obj/item/new_item = item
		item.loc = src
		installed_item = new_item
		to_chat(user, "<span class='notice'>You slide \the [new_item] into the using mechanism.</span>")
		playsound(src, 'sound/items/Crowbar.ogg', 50, 1)
		push_data()
	else
		src.attack_self(user)
		item.loc = src
		installed_item = item
		playsound(src, 'sound/items/Crowbar.ogg', 50, 1)

/obj/item/integrated_circuit/manipulation/interacter/do_work()
	var/obj/object //на вход может подаваться как моб, так и объект. Делать миллионы проверок я не собираюсь
	var/mob/mob //поэтому пусть пользователь сам скажет что ему надо.

	var/intent = get_pin_data(IC_INPUT, 2)
	var/body_zone = get_pin_data(IC_INPUT, 3)
	var/is_mob = get_pin_data(IC_INPUT, 4) //И вот тут он об этом рассказывает

	if(intent)
		mob_for_using_items.a_intent = intent //Интенты есть только у мобов. Я впинхул моба в переменную. Это позволяет использовать предметы и машинерию как игроку. Так же в будущем, возможно перенаправление окон UI
	if(body_zone)
		mob_for_using_items.zone_selected = body_zone
	if(is_mob)
		mob = get_pin_data_as_type(IC_INPUT, 1, /mob)
		interact_mob(mob)
	if(!is_mob)
		object = get_pin_data_as_type(IC_INPUT, 1, /obj)
		interact_obj(object)
	update_outputs()
	activate_pin(2)

/obj/item/integrated_circuit/manipulation/interacter/proc/interact_obj(var/obj/object_to_use)
	var/obj/item/tool = get_pin_data_as_type(IC_INPUT, 5, /obj/item) //Получаем предмет из референса
	if(tool && tool != installed_item)
		object_to_use = tool
		src.attackby(tool, mob_for_using_items)
	if(get_dist(src, object_to_use) <= 1 || src.assembly.loc == object_to_use.loc) //Если объект и деталька находятся на одном тайле, то расстояние до них расчитвается как INF и все ломается. Приходится ухищряться. //Так как мы уже проверили расстояние до tool, то стоит глянуть, есть ли в интегралке инструмент. Если да, то заменить и выкинуть на пол.
		if(installed_item && installed_item != object_to_use)
			object_to_use.attackby(installed_item, mob_for_using_items, NONE)
			return
		else
			object_to_use.attack_hand(mob_for_using_items)
	else
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1) //Явный намек на то, что то-то не так.

/obj/item/integrated_circuit/manipulation/interacter/proc/interact_mob(var/mob/mob_to_act)
	if(get_dist(src, mob_to_act) <= 1 || src.assembly.loc == mob_to_act.loc)
		if(installed_item && installed_item != mob_to_act)
			mob_to_act.attackby(installed_item, mob_for_using_items, NONE)
			return
		else
			mob_to_act.attack_hand(mob_for_using_items)
	else
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)

/obj/item/integrated_circuit/manipulation/interacter/proc/update_outputs()
	set_pin_data(IC_OUTPUT, 1, null)
	set_pin_data(IC_OUTPUT, 2, null)
	push_data()

/obj/item/integrated_circuit/manipulation/interacter/attack_self(var/mob/user)
	update_outputs()
	push_data()
	if(installed_item)
		installed_item.forceMove(drop_location())
		installed_item = null
		to_chat(user, "<span class='notice'>You slide \the [installed_item] out of the using mechanism.</span>")
		size = initial(size)
		playsound(src, 'sound/items/Crowbar.ogg', 50, 1)
