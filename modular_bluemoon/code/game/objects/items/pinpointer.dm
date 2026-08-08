GLOBAL_LIST_INIT(possible_squad_leader_first_names, list(\
"Кощей","Башня","Патриарх", "Чернобог","Душегуб","Басурман","Мародёр","Апостол","Дипломат","Голиаф","Миллениум",\
"Гадюка","Носорог","Кабан","Орёл","Слон","Крокодил","Бегемот","Журавль","Тигр","Лев","Анаконда","Волк","Гиена","Шакал","Цербер"))

// Трекер на командира

/obj/item/pinpointer/squad
	name = "squad tracker"
	desc = "A handheld tracking device that locates the leader. <b>SQUAD, ON ME!</b>"
	icon_state = "pinpointer_syndicate"
	item_state = "pinpointer_black"
	var/leader = null

/obj/item/pinpointer/squad/Destroy()
	leader = null
	. = ..()

/obj/item/pinpointer/squad/examine(mob/user)
	. = ..()
	if(leader)
		var/obj/item/squad_leader_tracker/leader_beacon = leader
		if(leader_beacon.tracking_name)
			. += "<hr>"
			. += span_info("Вы - часть отряда <b>\"[leader_beacon.tracking_name]\"</b>.")
	. += span_info("Трекер можно поднести к маячку лидера, чтобы присоединиться к его отряду.")

/obj/item/pinpointer/squad/scan_for_target()
	set_target(leader)

// Командирский маячок

/obj/item/squad_leader_tracker
	name = "squad beacon"
	desc = "Устройство с функционалом маячка. Излучает сигнал, улавливаемый определёнными пинпоинтерами. \
	Такая модель часто используется в военных и полу-военных подразделениях для поиска командира отряда - её они и носят. \
	Как правило, к ней прикреплены только те маячки, что идут в комплекте. Позволяет усилить организацию над приматами и детьми до 8 лет."
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-white"
	item_state = "radio"
	var/tracking_name = ""

/obj/item/squad_leader_tracker/Initialize(mapload)
	. = ..()
	if(length(GLOB.possible_squad_leader_first_names))
		tracking_name = pick(GLOB.possible_squad_leader_first_names)
		GLOB.possible_squad_leader_first_names -= tracking_name
	else
		tracking_name = "[rand(1,999)]"

/obj/item/squad_leader_tracker/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(istype(I, /obj/item/pinpointer/squad)) // По клику на маячок трекером, можно привязаться к отряду
		var/obj/item/pinpointer/squad/tracker = I
		if(tracker.leader == src)
			to_chat(user, span_danger("Этот пинпоинтер уже привязан к данному отряду."))
			return
		tracker.leader = src
		playsound(src, 'sound/items/timer.ogg', 50, 1, -5)
		to_chat(user, span_notice("Вы переназначаете отряд на \"[tracking_name]\". Теперь, это ваш отряд."))
		return
	. = ..()

/obj/item/squad_leader_tracker/examine(mob/user)
	. = ..()
	if(tracking_name)
		. += "<hr>"
		. += span_info("Этот маяк относится к отряду <b>\"[tracking_name]\"</b>.")

// Коробочка с полным набором

/obj/item/storage/box/pinpointer_squad/PopulateContents()
	var/obj/item/pinpointer/squad/A = new(src)
	var/obj/item/pinpointer/squad/B = new(src)
	var/obj/item/pinpointer/squad/C = new(src)
	var/obj/item/pinpointer/squad/D = new(src)
	var/obj/item/pinpointer/squad/E = new(src)
	var/obj/item/pinpointer/squad/F = new(src)
	var/obj/item/squad_leader_tracker/master = new(src)

	A.leader = master
	B.leader = master
	C.leader = master
	D.leader = master
	E.leader = master
	F.leader = master

// Добавление обоих предметов в техфабы с начала смены

/datum/design/squad_beacon
	name = "Squad Beacon"
	id = "squad_beacon"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1500, /datum/material/gold = 200)
	build_path = /obj/item/squad_leader_tracker
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/squad_tracker
	name = "Squad Tracker"
	desc = "A handheld tracking device that locates the leader. <b>SQUAD, ON ME!</b>"
	id = "squad_tracker"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1500, /datum/material/gold = 200)
	build_path = /obj/item/pinpointer/squad
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/techweb_node/base/New()
	var/list/extra_designs = list(
		"squad_beacon",
		"squad_tracker"
	)
	LAZYADD(design_ids, extra_designs)
	. = ..()

/obj/item/pinpointer/adv
	name = "Advanced Pinpointer"
	desc = "Усовершенствованный трекер с квантовым детектором сигнатур. \
		Отслеживает персонал без датчиков, киборгов и ИИ, а также предметы. \
		ALT-ЛКМ — смена режима, ЛКМ — выбор цели и вкл/выкл."
	icon_state = "pinpointer_syndicate"
	item_state = "electronic"
	resets_target = FALSE
	var/mode = ADVPINPOINTER_MODE_PERSON
	var/datum/objective_item/search_item_datum
	var/imprecise_person_range = 8

/obj/item/pinpointer/adv/Initialize(mapload)
	. = ..()
	set_mode_precision(mode)

/obj/item/pinpointer/adv/examine(mob/user)
	. = ..()
	. += "Режим: <b>[get_mode_name()]</b>. ALT-ЛКМ — сменить режим."
	if(active && target)
		. += "Цель: <b>[target]</b>."

/obj/item/pinpointer/adv/proc/get_mode_name()
	switch(mode)
		if(ADVPINPOINTER_MODE_PERSON)
			return "персонал"
		if(ADVPINPOINTER_MODE_SILICON)
			return "киборги и ИИ"
		if(ADVPINPOINTER_MODE_ITEM)
			return "предметы"
	return "неизвестный"

/obj/item/pinpointer/adv/proc/set_mode_precision(new_mode)
	if(new_mode == ADVPINPOINTER_MODE_PERSON)
		if(ishuman(target))
			update_person_tracking_precision(target, imprecise_person_range)
		else
			minimum_range = imprecise_person_range
	else
		minimum_range = 0

/obj/item/pinpointer/adv/AltClick(mob/living/user)
	switch_tracking_mode(user)

/obj/item/pinpointer/adv/proc/switch_tracking_mode(mob/living/user)
	if(!user || !user.canUseTopic(src, BE_CLOSE, FALSE))
		return
	mode = (mode % ADVPINPOINTER_MODE_ITEM) + 1
	set_mode_precision(mode)
	unset_target()
	search_item_datum = null
	if(active)
		active = FALSE
		STOP_PROCESSING(SSfastprocess, src)
		update_icon()
	to_chat(user, "<span class='notice'>Пинпоинтер переключён в режим «[get_mode_name()]».</span>")

/obj/item/pinpointer/adv/attack_self(mob/living/user)
	if(active)
		return ..()
	if(!pick_target(user))
		return
	return ..()

/obj/item/pinpointer/adv/proc/pick_target(mob/living/user)
	switch(mode)
		if(ADVPINPOINTER_MODE_PERSON)
			return pick_person_target(user)
		if(ADVPINPOINTER_MODE_SILICON)
			return pick_silicon_target(user)
		if(ADVPINPOINTER_MODE_ITEM)
			return pick_item_target(user)
	return FALSE

/obj/item/pinpointer/adv/proc/pick_person_target(mob/living/user)
	var/list/name_counts = list()
	var/list/names = list()
	var/turf/here = get_turf(user)
	for(var/mob/living/carbon/human/H in GLOB.carbon_list)
		if(!adv_trackable_human(H, here))
			continue
		var/crewmember_name = H.real_name || "Unknown"
		if(H.wear_id || H.wear_neck)
			var/obj/item/card/id/I = H.wear_id?.GetID()
			if(!I)
				I = H.wear_neck?.GetID()
			if(I?.registered_name)
				crewmember_name = I.registered_name
		while(crewmember_name in name_counts)
			name_counts[crewmember_name]++
			crewmember_name = text("[] ([])", crewmember_name, name_counts[crewmember_name])
		names[crewmember_name] = H
		name_counts[crewmember_name] = 1
	if(!length(names))
		to_chat(user, "<span class='notice'>Не удалось обнаружить персонал на этом уровне.</span>")
		return FALSE
	var/choice = tgui_input_list(user, "Кого отслеживать?", "Продвинутый пинпоинтер", names)
	if(!choice || QDELETED(src) || !user || !user.is_holding(src) || user.incapacitated())
		return FALSE
	set_target(names[choice])
	update_person_tracking_precision(names[choice], imprecise_person_range)
	return TRUE

/obj/item/pinpointer/adv/proc/pick_silicon_target(mob/living/user)
	var/list/names = list()
	var/turf/here = get_turf(user)
	for(var/mob/living/silicon/S in GLOB.silicon_mobs)
		if(S.stat == DEAD)
			continue
		var/turf/there = get_turf(S)
		if(!there || there.z != here.z)
			continue
		names["[S.name] ([isAI(S) ? "ИИ" : "киборг"])"] = S
	if(!length(names))
		to_chat(user, "<span class='notice'>На этом уровне нет активных киборгов или ИИ.</span>")
		return FALSE
	var/choice = tgui_input_list(user, "Кого отслеживать?", "Продвинутый пинпоинтер", names)
	if(!choice || QDELETED(src) || !user || !user.is_holding(src) || user.incapacitated())
		return FALSE
	set_target(names[choice])
	return TRUE

/obj/item/pinpointer/adv/proc/pick_item_target(mob/living/user)
	if(!GLOB.possible_items.len)
		for(var/I in subtypesof(/datum/objective_item/steal))
			new I
	var/list/item_names = list()
	var/list/item_datums = list()
	for(var/datum/objective_item/steal_item in GLOB.possible_items)
		item_names += steal_item.name
		item_datums[steal_item.name] = steal_item
	var/choice = tgui_input_list(user, "Какой предмет искать?", "Продвинутый пинпоинтер", item_names)
	if(!choice || QDELETED(src) || !user || !user.is_holding(src) || user.incapacitated())
		return FALSE
	search_item_datum = item_datums[choice]
	var/obj/item/found = find_closest_steal_item(search_item_datum)
	if(!found)
		to_chat(user, "<span class='warning'>Не удалось найти «[search_item_datum.name]» на станции.</span>")
		return FALSE
	set_target(found)
	to_chat(user, "<span class='notice'>Сигнатура «[search_item_datum.name]» захвачена.</span>")
	return TRUE

/obj/item/pinpointer/adv/proc/adv_trackable_human(mob/living/carbon/human/H, turf/here)
	if(!H || H.stat == DEAD || isbrain(H))
		return FALSE
	var/turf/there = get_turf(H)
	return there && here && there.z == here.z

/obj/item/pinpointer/adv/proc/find_closest_steal_item(datum/objective_item/item_info)
	if(!item_info)
		return null
	var/turf/here = get_turf(src)
	var/obj/item/best_same_z
	var/best_same_dist = INFINITY
	var/obj/item/best_other_z
	var/best_other_dist = INFINITY
	var/list/candidates = get_all_of_type(item_info.targetitem, subtypes = TRUE)
	for(var/obj/item/candidate in candidates)
		if(!istype(candidate, item_info.targetitem))
			var/valid_alt = FALSE
			for(var/alt_path in item_info.altitems)
				if(istype(candidate, alt_path))
					valid_alt = TRUE
					break
			if(!valid_alt)
				continue
		if(!item_info.check_special_completion(candidate))
			continue
		var/turf/there = get_turf(candidate)
		if(!there || is_centcom_level(there.z) || is_away_level(there.z))
			continue
		var/dist = get_dist(here, candidate)
		if(there.z == here?.z)
			if(dist < best_same_dist)
				best_same_dist = dist
				best_same_z = candidate
		else if(is_station_level(there.z) && dist < best_other_dist)
			best_other_dist = dist
			best_other_z = candidate
	return best_same_z || best_other_z

/obj/item/pinpointer/adv/scan_for_target()
	if(!active)
		return
	switch(mode)
		if(ADVPINPOINTER_MODE_PERSON)
			if(ishuman(target))
				var/mob/living/carbon/human/H = target
				update_person_tracking_precision(H, imprecise_person_range)
				if(!adv_trackable_human(H, get_turf(src)))
					unset_target()
		if(ADVPINPOINTER_MODE_SILICON)
			if(issilicon(target))
				var/mob/living/silicon/S = target
				if(S.stat == DEAD)
					unset_target()
			else if(target)
				unset_target()
		if(ADVPINPOINTER_MODE_ITEM)
			if(search_item_datum)
				var/obj/item/found = find_closest_steal_item(search_item_datum)
				if(found)
					set_target(found)
				else
					unset_target()
	..()
