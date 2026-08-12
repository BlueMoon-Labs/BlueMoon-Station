/obj/item/paicard
	name = "personal AI device"
	desc = "Загружает персонального ИИ-помощника для сопровождения своего владельца или других."
	icon = 'icons/obj/aicards.dmi'
	icon_state = "pai"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	var/mob/living/silicon/pai/pai
	var/panel_open = FALSE
	var/request_spam = FALSE
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_integrity = 200

/obj/item/paicard/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] печально смотрит на [src]! [user.ru_who()] не может продолжать жить без настоящей человеческой близости!"))
	return OXYLOSS

/obj/item/paicard/Initialize(mapload)
	SSpai.pai_card_list += src
	add_overlay("pai-off")
	AddElement(/datum/element/bed_tuckable, 6, -5, 90)
	return ..()

/obj/item/paicard/Destroy()
	//Will stop people throwing friend pAIs into the singularity so they can respawn
	SSpai.pai_card_list -= src
	if (!QDELETED(pai))
		QDEL_NULL(pai)
	return ..()

/obj/item/paicard/attack_self(mob/user)
	if(!in_range(src, user))
		return
	ui_interact(user)

/obj/item/paicard/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaiCard")
		ui.set_autoupdate(TRUE)
		ui.open()

/obj/item/paicard/ui_status(mob/user, datum/ui_state/state)
	if(user in get_nested_locs(src))
		return UI_INTERACTIVE
	return ..()

/obj/item/paicard/ui_static_data(mob/user)
	. = ..()
	.["range_max"] = 7
	.["range_min"] = 1

/obj/item/paicard/ui_data(mob/user)
	. = ..()
	var/list/data = list()
	if(!pai)
		data["candidates"] = pool_candidates() || list()
		return data
	data["pai"] = list(
		can_holo = pai.canholo,
		dna = pai.master_dna,
		emagged = pai.emagged,
		laws = pai.laws.supplied,
		master = pai.master,
		name = pai.name,
		transmit = pai.radio ? !pai.radio.wires.is_cut(WIRE_TX) : FALSE,
		receive = pai.radio ? !pai.radio.wires.is_cut(WIRE_RX) : FALSE,
		leashed = pai.leashed,
		range = pai.range,
	)
	return data

/obj/item/paicard/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return TRUE
	if(action == "download")
		if(!pai)
			SSpai.download_candidate_card(params["ckey"], src, usr)
		return TRUE
	if(action == "request")
		find_pai(usr)
		return TRUE
	if(!pai)
		return FALSE
	switch(action)
		if("fix_speech")
			to_chat(pai, "<span class='notice'>Коррекция модуляции речи.</span>")
			return TRUE
		if("reset_software")
			pai.reset_software()
			. = TRUE
		if("set_dna")
			pai.set_dna(usr)
			. = TRUE
		if("set_laws")
			pai.set_laws(usr)
			. = TRUE
		if("toggle_holo")
			pai.canholo = !pai.canholo
			to_chat(pai, "<span class='userdanger'>Ваш хозяин [pai.canholo ? "включил" : "отключил"] ваши голоматричные проекторы!</span>")
			to_chat(usr, "<span class='notice'>Вы [pai.canholo ? "включили" : "отключили"] голоматрицу вашего ПИИ!</span>")
			. = TRUE
		if("toggle_leash")
			pai.toggle_leash()
			. = TRUE
		if("toggle_radio")
			if(pai.radio)
				pai.radio.wires.cut(params["option"] == "transmit" ? WIRE_TX : WIRE_RX)
			. = TRUE
		if("increase_range")
			pai.range = min(pai.range + 1, 7)
			. = TRUE
		if("decrease_range")
			pai.range = max(pai.range - 1, 1)
			. = TRUE
		if("wipe_pai")
			pai.wipe_pai(usr)
			ui.close()
			return TRUE
	if(.)
		SStgui.update_uis(src)
		return TRUE
	return FALSE

/obj/item/paicard/proc/find_pai(mob/user)
	if(pai)
		return FALSE
	if(request_spam)
		to_chat(user, "<span class='warning'>Запрос отправляется слишком часто.</span>")
		return FALSE
	request_spam = TRUE
	playsound(src, 'sound/machines/ping.ogg', 20, TRUE)
	for(var/mob/dead/observer/G in GLOB.player_list)
		if(!G.key || !G.client)
			continue
		if(!G.can_reenter_round())
			continue
		SEND_SOUND(G, sound('sound/effects/ghost2.ogg'))
		window_flash(G.client)
		var/atom/movable/screen/alert/notify_action/A = G.throw_alert("[REF(src)]_pai", /atom/movable/screen/alert/notify_action)
		if(A)
			if(istype(src, /obj/item/paicard/inteq))
				A.name = "Нелегальный ПИИ"
				A.desc = "[user.real_name] ищет личность для нелегального ПИИ! Нажмите, чтобы подать заявку."
			else
				A.name = "ПИИ"
				A.desc = "[user.real_name] ищет личность для ПИИ! Нажмите, чтобы подать заявку."
			A.action = NOTIFY_ATTACK
			A.target = src
			var/mutable_appearance/alert_overlay = new(src)
			alert_overlay.layer = FLOAT_LAYER
			alert_overlay.plane = FLOAT_PLANE
			A.add_overlay(alert_overlay)
	addtimer(VARSET_CALLBACK(src, request_spam, FALSE), 10 SECONDS, TIMER_UNIQUE|TIMER_DELETE_ME)
	return TRUE

/obj/item/paicard/attack_ghost(mob/dead/observer/user)
	if(pai)
		to_chat(user, "<span class='warning'>Это устройство уже занято другой личностью.</span>")
		return FALSE
	var/area/A = get_area(get_turf(src))
	if(A.type in SSpai.restricted_areas)
		to_chat(user, "<span class='warning'>Вы не можете загрузиться в запрещённую зону!</span>")
		return FALSE
	SSpai.recruitWindow(user, src)
	return TRUE

/obj/item/paicard/proc/pool_candidates()
	var/list/candidates = list()
	if(pai || !length(SSpai?.candidates))
		return candidates
	for(var/datum/paiCandidate/candidate in SSpai.candidates)
		if(SSpai.check_ready(candidate) != candidate)
			continue
		candidates += list(list(
			ckey = candidate.key,
			comments = candidate.comments,
			description = candidate.description,
			name = candidate.name,
		))
	return candidates

/obj/item/paicard/proc/setPersonality(mob/living/silicon/pai/personality)
	src.pai = personality
	personality.card = src
	src.add_overlay("pai-null")
	var/list/policies = CONFIG_GET(keyed_list/policy)
	var/policy = policies[POLICYCONFIG_PAI]
	if(policy)
		to_chat(personality, policy)
	playsound(loc, 'sound/effects/pai_boot.ogg', 50, 1, -1)
	audible_message(span_notice("[src] издаёт радостный шум запуска!"))

/obj/item/paicard/proc/setEmotion(emotion)
	if(pai)
		src.cut_overlays()
		switch(emotion)
			if(1)
				src.add_overlay("pai-happy")
			if(2)
				src.add_overlay("pai-cat")
			if(3)
				src.add_overlay("pai-extremely-happy")
			if(4)
				src.add_overlay("pai-face")
			if(5)
				src.add_overlay("pai-laugh")
			if(6)
				src.add_overlay("pai-off")
			if(7)
				src.add_overlay("pai-sad")
			if(8)
				src.add_overlay("pai-angry")
			if(9)
				src.add_overlay("pai-what")
			if(10)
				src.add_overlay("pai-null")
			if(11)
				src.add_overlay("pai-exclamation")
			if(12)
				src.add_overlay("pai-question")
			if(13)
				src.add_overlay("pai-sunglasses")
			if(14)
				src.add_overlay("pai-mal-0")

/obj/item/paicard/proc/alertUpdate()
	visible_message(span_notice("[src] высвечивает сообщение на экране: новые персонали доступны для скачивания!"), span_notice("[src] издаёт электронный сигнал."))

/obj/item/paicard/inteq
	name = "InteQ personal AI device"
	desc = "Модифицированное InteQ устройство ПИИ. Кажется, оно деактивировано."
	icon_state = "pai"

/obj/item/paicard/inteq/setPersonality(mob/living/silicon/pai/personality)
	. = ..()
	log_world("PAI_DEBUG: inteq card setPersonality pai=[personality] pai.type=[personality?.type]")
	personality.inteq_model = TRUE
	personality.software = list("thermal vision", "chemical injector", "internal camera bug", "weakened ai capability")
	if(istype(personality, /mob/living/silicon/pai/inteq))
		var/mob/living/silicon/pai/inteq/S = personality
		S.chemical_injector_active = TRUE
	if(!istype(personality.cell, /obj/item/stock_parts/cell/bluespace))
		log_world("PAI_DEBUG: forcing bluespace cell (was [personality.cell?.type])")
		if(personality.cell)
			QDEL_NULL(personality.cell)
		personality.cell = new /obj/item/stock_parts/cell/bluespace(personality)
		personality.cell.charge = personality.cell.maxcharge
	if(!istype(personality.radio, /obj/item/radio/headset/silicon/pai/inteq))
		log_world("PAI_DEBUG: forcing inteq radio (was [personality.radio?.type])")
		if(personality.radio)
			QDEL_NULL(personality.radio)
		personality.radio = new /obj/item/radio/headset/silicon/pai/inteq(personality)

/obj/item/paicard/get_cell()
	if(pai?.cell)
		return pai.cell
	return ..()

/obj/item/paicard/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(pai && !pai.holoform)
		pai.emp_act(severity)
