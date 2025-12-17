// Configuration defines
#define AUTODOC_TIME_BASE	CONFIG_GET(number/autodoc_time_surgery_base)

/obj/machinery/autodoc
	name = "Autodoc"
	desc = "Продвинутое устройство, позволяющее устанавливать органы и импланты в пациента без участия хирурга."
	density = TRUE
	icon = 'modular_sand/icons/obj/machines/autodoc.dmi'
	icon_state = "autodoc_machine"
	verb_say = "states"
	idle_power_usage = 50
	circuit = /obj/item/circuitboard/machine/autodoc
	allow_oversized_characters = TRUE

	var/obj/item/organ/stored_organ
	var/organ_type = /obj/item/organ
	var/processing = FALSE
	var/surgery_time = 30 SECONDS
	var/speed_up_percent = 0

/obj/machinery/autodoc/Initialize(mapload)
	. = ..()
	update_icon()

	occupant_typecache = single_path_typecache_immutable(/mob/living/carbon)

/obj/machinery/autodoc/on_deconstruction()
	. = ..()
	if(stored_organ)
		stored_organ.forceMove(drop_location())
		stored_organ = null

/obj/machinery/autodoc/RefreshParts()
	surgery_time = AUTODOC_TIME_BASE

	var/parts_rating = 0
	var/i = 0
	for(var/obj/item/stock_parts/L in component_parts)
		parts_rating += L.rating
		++i
	// Average rating of all details
	var/rating = round_down(parts_rating / i)
	var/const/speed_up_per_rating = 16.6 // T4 = 50% speed up
	speed_up_percent = max(ceil((rating-1) * speed_up_per_rating),0)
	surgery_time -= surgery_time*(speed_up_percent / 100)
	surgery_time = max(round(surgery_time), 1 SECONDS)

/obj/machinery/autodoc/examine(mob/user)
	. = ..()
	if(get_dist(src, user) <= 1 || isobserver(user))
		. += span_notice("Статус-дисплей сообщает: \n\
		- Время операции: [DisplayTimeText(surgery_time)].")
		if(speed_up_percent)
			. += span_notice("- Машина работает на [span_nicegreen("[speed_up_percent]%")] быстрее.")
		if(processing)
			. += span_notice("- В процессе имплантации [icon2html(stored_organ, user)] [stored_organ.name] в [occupant].")
		else if(stored_organ)
			. += span_notice("- Внутрь загружен и подготовлен к установке [icon2html(stored_organ, user)] [stored_organ.name].")
			. += span_notice("Alt-click для извлечения органа/имплантата.")
		if((obj_flags & EMAGGED) && panel_open)
			. += span_boldwarning("Протоколы работы повреждены, выставлен режим РАСЧЛЕНЕНИЕ!")
	else
		. += span_warning("Нужно подойти ближе, чтобы получить больше информации.")

/obj/machinery/autodoc/close_machine(mob/user)
	..()
	playsound(src, 'sound/machines/click.ogg', 50)
	if(occupant)
		do_surgery()

/obj/machinery/autodoc/proc/do_surgery()
	if(!stored_organ && !(obj_flags & EMAGGED))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30)
		to_chat(occupant, span_warning("[src] не содержит органа или импланта для установки."))
		return
	playsound(get_turf(occupant), 'sound/weapons/circsawhit.ogg', 50, 1)
	processing = TRUE
	update_icon()
	var/mob/living/carbon/C = occupant
	if(obj_flags & EMAGGED)

		var/self_message = span_userdanger("Вы чувствуете... ОСТРУЮ БОЛЬ! [src] РАСЧЛЕНЯЕТ ВАС ЗАЖИВО!")
		var/has_pain = !HAS_TRAIT(occupant, TRAIT_ROBOTIC_ORGANISM) && !HAS_TRAIT(occupant, TRAIT_PAINKILLER)
		if(!has_pain)
			self_message = span_big_warning("Вы ничего не чувствуете, но [src] явно делает что-то не так, начав отпиливать ваши конечности...")
		occupant.visible_message(span_notice("[occupant] нажимает на кнопку [src], и вы слышите работу механизов."), \
								self_message)

		if(HAS_TRAIT(occupant, TRAIT_BLUEMOON_FEAR_OF_SURGEONS))
			SEND_SIGNAL(occupant, COMSIG_ADD_MOOD_EVENT, "autodoc", /datum/mood_event/surgery_pain/trait)
		else
			SEND_SIGNAL(occupant, COMSIG_ADD_MOOD_EVENT, "autodoc", /datum/mood_event/surgery_pain)

		for(var/obj/item/bodypart/BP in reverseList(C.bodyparts)) //Chest and head are first in bodyparts, so we invert it to make them suffer more
			if(has_pain)
				C.emote("realagony")
				C.say(pick("AAA!!", "АААХ!!", "ААГХ!!"), forced = "autodoc")
				C.Stun(20)
				C.Jitter(50)
				C.blur_eyes(15)
				C.dizziness += 50
				C.confused += 30
				C.stuttering += 30
			if(!HAS_TRAIT(C, TRAIT_NODISMEMBER))
				BP.dismember()
				C.apply_damage(round(10 * speed_up_percent/100), BRUTE, BP) // Больнее бъет при улучшении
			else
				C.apply_damage(round(40 * speed_up_percent/100), BRUTE, BP) // Больнее бъет при улучшении
			playsound(src, 'sound/weapons/chainsawhit.ogg', 100)

			//40 seconds to get help before dying
			if(!do_after(occupant, 10 SECONDS, src, IGNORE_HELD_ITEM|IGNORE_INCAPACITATED|IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(check_surgery))))
				open_machine()
				return

		occupant.visible_message(span_big_warning("[src] расчленяет [occupant]!"), span_userdanger("[src] расчленяет ваше тело!"))

	else
		occupant.visible_message(span_notice("[occupant] нажимает на кнопку [src], и вы слышите работу механизов."), \
							span_notice("Вы чувствуете укол и онемение, после чего [src] начинает имплантировать [icon2html(stored_organ, occupant)] [stored_organ.name] в ваше тело."))
		ADD_TRAIT(C, TRAIT_PAINKILLER, PAINKILLER_AUTODOC)
		C.throw_alert("painkiller", /atom/movable/screen/alert/painkiller)
		if(HAS_TRAIT(occupant, TRAIT_BLUEMOON_FEAR_OF_SURGEONS))
			SEND_SIGNAL(occupant, COMSIG_ADD_MOOD_EVENT, "autodoc", /datum/mood_event/surgery_pain/painkiller)
		if(!do_after(occupant, surgery_time, src, IGNORE_HELD_ITEM|IGNORE_INCAPACITATED|IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(check_surgery))))
			open_machine()
			return
		var/obj/item/organ/currentorgan = C.getorganslot(stored_organ.slot)
		if(currentorgan)
			currentorgan.Remove(C)
			currentorgan.forceMove(get_turf(src))
		stored_organ.Insert(occupant)//insert stored organ into the user
		occupant.visible_message(span_notice("[src] заканчивает хирургическую операцию."), span_notice("[src] имплантирует [icon2html(stored_organ, occupant)] [stored_organ.name] в ваше тело."))
		stored_organ = null
		REMOVE_TRAIT(C, TRAIT_PAINKILLER, PAINKILLER_AUTODOC)
		C.clear_alert("painkiller", /atom/movable/screen/alert/painkiller)
	playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, 0)
	processing = FALSE
	open_machine()

/obj/machinery/autodoc/open_machine(drop)
	if(processing)
		to_chat(occupant, span_warning("[src] прекращает операцию над твоим телом."))
		if(iscarbon(occupant))
			var/mob/living/carbon/C = occupant
			REMOVE_TRAIT(C, TRAIT_PAINKILLER, PAINKILLER_AUTODOC)
			C.clear_alert("painkiller", /atom/movable/screen/alert/painkiller)
		processing = FALSE
	. = ..()

/obj/machinery/autodoc/interact(mob/user)
	if(panel_open)
		balloon_alert(user, "Закрой панель!")
		return

	if(state_open)
		close_machine()
		return

	if(processing)
		balloon_alert(user, span_balloon_warning("[user == occupant ? "Заперто" : "Не могу открыть руками!"]"))
		return
	open_machine()

/obj/machinery/autodoc/attackby(obj/item/I, mob/user, params)
	if(istype(I, organ_type))
		if(!user.temporarilyRemoveItemFromInventory(I))
			return
		if(stored_organ)
			user.put_in_hands(stored_organ)
			to_chat(user, span_notice("Вы извлекли [icon2html(stored_organ, user)] [stored_organ.name] из [src]."))
			stored_organ = null
		stored_organ = I
		stored_organ.moveToNullspace()
		to_chat(user, span_notice("Вы загрузили [icon2html(stored_organ, user)] [stored_organ.name] внутрь [src]."))
	else
		return ..()

/obj/machinery/autodoc/tool_act(mob/living/user, obj/item/I, tool_type)
	if(user == occupant)
		return FALSE
	else
		return ..()

/obj/machinery/autodoc/screwdriver_act(mob/living/user, obj/item/I)
	. = TRUE
	if(..())
		return
	if(occupant)
		balloon_alert(user, "Внутри пациент!")
		return
	if(state_open)
		balloon_alert(user, "Сперва нужно открыть машину!")
		return
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, I))
		if(stored_organ)
			stored_organ.forceMove(drop_location())
			stored_organ = null
		update_icon()
		return
	return FALSE

/obj/machinery/autodoc/crowbar_act(mob/living/user, obj/item/I)
	if(default_deconstruction_crowbar(I))
		return TRUE
	else if(!state_open && processing)
		playsound(src, 'sound/machines/airlock_alien_prying.ogg',50,1)
		if(I.use_tool(src, user, 2 SECONDS, skill_gain_mult = 0))
			open_machine(user)
		return TRUE

/obj/machinery/autodoc/AltClick(mob/user)
	. = ..()
	if(stored_organ && !processing && occupant != user)
		user.put_in_hands(stored_organ)
		to_chat(user, span_notice("Вы извлекли [icon2html(stored_organ, user)] [stored_organ.name] из [src]."))
		stored_organ = null

/obj/machinery/autodoc/update_icon()
	overlays.Cut()
	if(!state_open)
		if(processing)
			overlays += "[icon_state]_door_on"
			overlays += "[icon_state]_stack"
			overlays += "[icon_state]_smoke"
			overlays += "[icon_state]_green"
		else
			overlays += "[icon_state]_door_off"
			if(occupant)
				if(powered(EQUIP))
					overlays += "[icon_state]_stack"
					overlays += "[icon_state]_yellow"
			else
				overlays += "[icon_state]_red"
	else if(powered(EQUIP))
		overlays += "[icon_state]_red"
	if(panel_open)
		overlays += "[icon_state]_panel"

/obj/machinery/autodoc/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	to_chat(user, span_warning("Вы активируете режим РАСЧЛЕНЕНИЕ на [src]."))

/obj/machinery/autodoc/relaymove(mob/living/user)
	container_resist(user)

/obj/machinery/autodoc/container_resist(mob/living/user)
	. = ..()
	if(user.stat || processing)
		return
	open_machine(user)

/obj/machinery/autodoc/proc/check_surgery()
	return processing

#undef AUTODOC_TIME_BASE
