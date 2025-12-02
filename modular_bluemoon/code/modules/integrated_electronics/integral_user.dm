/obj/item/integrated_circuit/manipulation/interacter
	name = "Usage module"
	desc = "A circuit capable of using objects."
	icon_state = "grabber"
	extended_desc = "На вход данной интегралки надо подавать референс объекта для взаимодействия на первый вход. Интент и части тела для взаимодействия указываются как help, harm, disarm, grab и chest, head, groin и т.д. соответственно. Если в интегралку не вставлен инструмент, то она взаимодействует с объектами как обычная пустая рука, иначе использует поданый на вход инструмент. МОЖНО ВСТАВИТЬ НЕ БОЛЕЕ ОДНОЙ ТАКОЙ ДЕТАЛИ В ОДНУ СХЕМУ."
	w_class = WEIGHT_CLASS_SMALL
	size = 4
	cooldown_per_use = 15
	complexity = 20
	inputs = list("target" = IC_PINTYPE_REF, "intent" = IC_PINTYPE_STRING, "body_zone" = IC_PINTYPE_STRING, "Tool" = IC_PINTYPE_REF)
	outputs = list("last target" = IC_PINTYPE_REF, "used tool" = IC_PINTYPE_REF, "last intent" = IC_PINTYPE_STRING)
	activators = list("pulse in" = IC_PINTYPE_PULSE_IN,"pulse out" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_COMBAT
	power_draw_per_use = 200
	var/mob/living/carbon/integral/mob_for_using_items

/mob/living/carbon/integral
	name = "integrated robotic hand"
	var/obj/item/integrated_circuit/manipulation/interacter/my_interacter
	hand_bodyparts = null

/mob/living/carbon/integral/breathe()
	return

/mob/living/carbon/integral/update_body_parts()
	return

/mob/living/carbon/integral/Initialize(mapload)
	. = ..()
	mind = new /datum/mind

/mob/living/carbon/integral/CheckActionCooldown(cooldown = 0.5, from_next_action = FALSE, ignore_mod = FALSE, ignore_next_action = FALSE, immediate = FALSE)
	return TRUE //У нас уже есть кулдаун в виде кулдауна самого модуля. А вот родительская версия прока ломает взаимодействие со стенами(например, использование сварки)

/mob/living/carbon/integral/put_in_hand(obj/item/I, hand_index, forced, ignore_anim)
	return TRUE
/mob/living/carbon/integral/IsAdvancedToolUser()
	return TRUE

/mob/living/carbon/integral/has_hand_for_held_index()
	return TRUE //В стандартной версии прока у родителя вызывает рантаймы

/mob/living/carbon/integral/get_active_held_item()
    return(my_interacter.get_pin_data_as_type(IC_INPUT, 4, /obj/item))

/obj/item/integrated_circuit/manipulation/interacter/Initialize(mapload)
	. = ..()
	mob_for_using_items = new /mob/living/carbon/integral(src)
	mob_for_using_items.status_flags ^= GODMODE
	mob_for_using_items.my_interacter = src

/obj/item/integrated_circuit/manipulation/interacter/do_work()
	var/intent = get_pin_data(IC_INPUT, 2)
	var/body_zone = get_pin_data(IC_INPUT, 3)
	var/obj/item/tool = get_pin_data_as_type(IC_INPUT, 4, /obj/item) //Получаем предмет из референса

	if(intent)
		mob_for_using_items.a_intent = intent //Интенты есть только у мобов. Я впинхул моба в переменную. Это позволяет использовать предметы и машинерию как игроку. Так же в будущем, возможно перенаправление окон UI
	if(body_zone)
		mob_for_using_items.zone_selected = body_zone
	var/atom = get_pin_data_as_type(IC_INPUT, 1, /atom)
	if(atom)
		interacting(atom, tool)
	update_outputs(atom, tool)
	activate_pin(2)

/obj/item/integrated_circuit/manipulation/interacter/proc/interacting(atom/object_to_use, obj/item/tool)
    if(get_dist(src, object_to_use) > 1)
        if(src.assembly.loc != object_to_use.loc)
            return
    if (tool && tool != object_to_use && tool.drop_location() == src.drop_location())
        tool.melee_attack_chain(mob_for_using_items, object_to_use, "icon-x=7;icon-y=20;left=1;button=left;screen-loc=10:7,9:20")
    else
        object_to_use.attack_hand(mob_for_using_items)

/obj/item/integrated_circuit/manipulation/interacter/proc/update_outputs(object_to_use, tool)
	set_pin_data(IC_OUTPUT, 1, WEAKREF(object_to_use))
	set_pin_data(IC_OUTPUT, 2, WEAKREF(tool))
	set_pin_data(IC_OUTPUT, 3, mob_for_using_items.a_intent)
	push_data()

/obj/item/integrated_circuit/manipulation/interacter/attack_self(var/mob/user)
	update_outputs()
	push_data()
