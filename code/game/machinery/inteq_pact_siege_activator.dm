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

/obj/machinery/computer/inteq_pact_siege/interact(mob/user)
	. = ..()
	if(.)
		return
	if(!isliving(user))
		return TRUE

	var/mob/living/L = user
	var/datum/inteq_pact_siege/siege = GLOB.inteq_pact_siege
	if(siege?.active)
		var/status = "Протокол осады активен.\n"
		status += "До открытия красного канала: [DisplayTimeText(siege.time_until_gates())].\n"
		status += "До эвакуации шаттла: [DisplayTimeText(siege.time_until_evac())].\n"
		status += "Живых обороняющихся (учёт): [siege.living_defenders_count()]."
		to_chat(L, span_notice(status))
		return TRUE

	if(!siege.role_check_inteq(L))
		to_chat(L, span_warning("Консоль не реагирует: нет авторизации InteQ."))
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
	return TRUE
