/// InteQ bluespace evac / siege protocol console. Place on the InteQ battlefield map.
/obj/machinery/computer/inteq_pact_siege
	name = "InteQ bluespace evac console"
	desc = "Консоль подготовки БС-двигателей эвакуационного шаттла. Запуск поднимает сигнатуру для ЦК и открывает «красный канал» врат ПАКТ на объект InteQ."
	icon_screen = "inteqshuttle"
	icon_keyboard = "inteq_key"
	light_color = LIGHT_COLOR_ORANGE
	circuit = /obj/item/circuitboard/computer/inteq_pact_siege
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/item/circuitboard/computer/inteq_pact_siege
	name = "InteQ Bluespace Evac Console (Computer Board)"
	build_path = /obj/machinery/computer/inteq_pact_siege

/obj/machinery/computer/inteq_pact_siege/ui_interact(mob/user, datum/tgui/ui)
	return

/obj/machinery/computer/inteq_pact_siege/Initialize(mapload)
	. = ..()
	update_siege_desc()

/obj/machinery/computer/inteq_pact_siege/examine(mob/user)
	update_siege_desc()
	return ..()

/obj/machinery/computer/inteq_pact_siege/proc/update_siege_desc()
	var/datum/inteq_pact_siege/siege = GLOB.inteq_pact_siege
	var/base_desc = initial(desc)
	if(!siege?.active)
		desc = base_desc
		return
	var/list/status = list()
	status += "Протокол осады активен."
	if(siege.gates_unlocked())
		status += "Красный канал врат открыт."
	else
		status += "До открытия красного канала: [DisplayTimeText(siege.time_until_gates())]."
	if(siege.evac_ready)
		status += "Эвакуационный шаттл готов к запуску — подтвердите отбытие на этой консоли с палубы шаттла."
	else
		status += "До готовности шаттла: [DisplayTimeText(siege.time_until_evac())]."
	status += "Живых обороняющихся (учёт): [siege.living_defenders_count()]."
	status += "InteQ на шаттле: [siege.living_inteq_on_shuttle_count()]."
	desc = "[base_desc]\n\n[status.Join(" ")]"

/obj/machinery/computer/inteq_pact_siege/interact(mob/user)
	. = ..()
	if(.)
		return
	if(!isliving(user))
		return TRUE

	var/mob/living/L = user
	var/datum/inteq_pact_siege/siege = GLOB.inteq_pact_siege
	update_siege_desc()

	if(siege?.active)
		if(siege.evac_ready)
			if(!siege.role_check_inteq(L))
				to_chat(L, span_warning("Консоль не реагирует: нет авторизации InteQ."))
				return TRUE
			if(!siege.is_on_evac_shuttle(L))
				to_chat(L, span_warning("Для запуска шаттла вы должны находиться на его палубе."))
				return TRUE
			var/aboard = siege.living_inteq_on_shuttle_count()
			var/ask = tgui_alert(
				L,
				"Подтвердить запуск БС-двигателей эвакуации? На шаттле сейчас [aboard] живых InteQ. Если хоть один InteQ улетит на шаттле — победа InteQ, иначе победа ПАКТ.",
				"Запуск шаттла InteQ",
				list("Запустить", "Отмена"),
				timeout = 30 SECONDS,
			)
			if(ask != "Запустить")
				return TRUE
			if(QDELETED(src) || QDELETED(L))
				return TRUE
			if(!siege.active || !siege.evac_ready)
				to_chat(L, span_warning("Протокол осады уже завершён."))
				return TRUE
			if(!siege.role_check_inteq(L))
				to_chat(L, span_warning("Консоль не реагирует: нет авторизации InteQ."))
				return TRUE
			if(!siege.is_on_evac_shuttle(L))
				to_chat(L, span_warning("Для запуска шаттла вы должны находиться на его палубе."))
				return TRUE
			L.visible_message(
				span_notice("[L] инициирует финальную последовательность запуска emergency bluespace drive..."),
				span_notice("Вы инициируете финальную последовательность запуска БС-двигателей..."),
			)
			if(!do_after(L, 12 SECONDS, target = src))
				return TRUE
			if(siege.launch_evac(L))
				playsound(src, 'sound/machines/gateway/gateway_open.ogg', 65, TRUE)
				balloon_alert(L, "шаттл запущен")
		else
			to_chat(L, span_notice(desc))
		return TRUE

	if(!siege.role_check_inteq(L))
		to_chat(L, span_warning("Консоль не реагирует: нет авторизации InteQ."))
		return TRUE

	var/mode_block = siege.siege_mode_blocked_reason()
	if(mode_block)
		to_chat(L, span_warning(mode_block))
		return TRUE

	var/ask = tgui_alert(
		L,
		"Инициировать запуск БС-двигателей эвакуации? Станция получит объявление ЦК, через [DisplayTimeText(PACT_SIEGE_PREP_TIME)] откроется красный канал врат для ПАКТ. Окно удержания: [DisplayTimeText(PACT_SIEGE_TIMER)].",
		"БС-двигатель InteQ",
		list("Запустить", "Отмена"),
		timeout = 30 SECONDS,
	)
	if(ask != "Запустить")
		return TRUE
	if(QDELETED(src) || QDELETED(L))
		return TRUE
	if(!siege.role_check_inteq(L))
		to_chat(L, span_warning("Консоль не реагирует: нет авторизации InteQ."))
		return TRUE
	if(siege.active)
		to_chat(L, span_warning("Протокол осады уже активен."))
		return TRUE

	L.visible_message(
		span_notice("[L] начинает последовательность синхронизации emergency bluespace drive..."),
		span_notice("Вы начинаете последовательность синхронизации БС-двигателей..."),
	)
	if(!do_after(L, 12 SECONDS, target = src))
		return TRUE
	if(siege.activate(L))
		playsound(src, 'sound/machines/gateway/gateway_open.ogg', 65, TRUE)
		balloon_alert(L, "протокол активирован")
		update_siege_desc()
	return TRUE
