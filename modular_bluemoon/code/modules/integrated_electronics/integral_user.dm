/obj/item/integrated_circuit/manipulation/interacter
	name = "Usage module"
	desc = "A circuit capable of using objects."
	icon_state = "grabber"
	extended_desc = "На вход данной интегралки надо подавать референс объекта для взаимодействия на первый вход. Интент и части тела для взаимодействия указываются как help, harm, disarm, grab и chest, head, groin и т.д. соответственно. Если в интегралку не вставлен инструмент, то она взаимодействует с объектами как обычная пустая рука, иначе использует поданый на вход(или напрямую вставленный в интегралку) инструмент. Нет, вы не можете вставить инструмент внутрь интегралки и одновременно с этим подать на вход иной. Она не будет работать. МОЖНО ВСТАВИТЬ НЕ БОЛЕЕ ОДНОЙ ТАКОЙ ДЕТАЛИ В ОДНУ СХЕМУ."
	w_class = WEIGHT_CLASS_SMALL
	size = 4
	cooldown_per_use = 15
	complexity = 20
	inputs = list("target" = IC_PINTYPE_REF, "intent" = IC_PINTYPE_STRING, "body_zone" = IC_PINTYPE_STRING, "Tool" = IC_PINTYPE_REF)
	outputs = list("used object(item, mob)" = IC_PINTYPE_REF, "last intent" = IC_PINTYPE_STRING)
	activators = list("pulse in" = IC_PINTYPE_PULSE_IN,"pulse out" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_COMBAT
	power_draw_per_use = 200
	var/mob/living/carbon/integral/mob_for_using_items

/mob/living/carbon/integral
	name = "integrated robotic hand"
	var/obj/item/integrated_circuit/manipulation/interacter/my_interacter

//mob/living/carbon/integral/get_active_held_item()
//	return(my_interacter.installed_item)

/mob/living/carbon/integral/has_hand_for_held_index()
	return TRUE //В стандартной версии прока у родителя вызывает рантаймы

/obj/item/integrated_circuit/manipulation/interacter/Initialize(mapload)
	. = ..()
	mob_for_using_items = new /mob/living/carbon/integral(src)
	mob_for_using_items.status_flags ^= GODMODE
	mob_for_using_items.my_interacter = src

/obj/item/integrated_circuit/manipulation/interacter/do_work()
	var/atom
	var/intent = get_pin_data(IC_INPUT, 2)
	var/body_zone = get_pin_data(IC_INPUT, 3)
	var/obj/item/tool = get_pin_data_as_type(IC_INPUT, 4, /obj/item) //Получаем предмет из референса

	if(intent)
		mob_for_using_items.a_intent = intent //Интенты есть только у мобов. Я впинхул моба в переменную. Это позволяет использовать предметы и машинерию как игроку. Так же в будущем, возможно перенаправление окон UI
	if(body_zone)
		mob_for_using_items.zone_selected = body_zone
	atom = get_pin_data_as_type(IC_INPUT, 1, /atom)
	if(atom)
		interacting(atom, tool)
	update_outputs()
	activate_pin(2)

/obj/item/integrated_circuit/manipulation/interacter/proc/interacting(var/atom/object_to_use, var/obj/item/tool)
	if(get_dist(src, object_to_use) <= 1 || src.assembly.loc == object_to_use.loc) //Если объект и деталька находятся на одном тайле, то расстояние до них расчитвается как INF и все ломается. Приходится ухищряться. //Так как мы уже проверили расстояние до tool, то стоит глянуть, есть ли в интегралке инструмент. Если да, то заменить и выкинуть на пол.
		var/tempvar = locate(tool.type) in assembly
		if(tool && tool != object_to_use)
		if(tool.drop_location() == src.drop_location()) //если они фактически на одном тайле, но вложены во что-то или не вложены вовсе. Один фиг мы получим turf и сравним его. Если он один и тот же, то все окей.
			tool.melee_attack_chain(mob_for_using_items, object_to_use, NONE)
			return
		else
			object_to_use.attack_hand(mob_for_using_items)
	else
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1) //Явный намек на то, что то-то не так.

/obj/item/integrated_circuit/manipulation/interacter/proc/update_outputs()
	set_pin_data(IC_OUTPUT, 1, null)
	set_pin_data(IC_OUTPUT, 2, null)
	push_data()

/obj/item/integrated_circuit/manipulation/interacter/attack_self(var/mob/user)
	update_outputs()
	push_data()
