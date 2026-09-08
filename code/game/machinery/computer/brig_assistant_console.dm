/**
 * Brig Assistant Tasks Console
 * TGUI console for assistants to take tasks - primarily hanging wanted posters.
 * Tasks have 5 min cooldown per criminal, max 3 identical tasks per assistant.
 * When criminal is caught (status changed), new task: remove their posters.
 */

GLOBAL_LIST_EMPTY(brig_assistant_remove_tasks) // ckey -> list of criminal_ids (active remove poster tasks)

#ifndef WANTED_POSTER_COOLDOWN
#define WANTED_POSTER_COOLDOWN (5 MINUTES)
#endif
#ifndef WANTED_POSTER_MAX_PER_ASSISTANT
#define WANTED_POSTER_MAX_PER_ASSISTANT 3
#endif
#ifndef WANTED_POSTER_MAX_PER_AREA
#define WANTED_POSTER_MAX_PER_AREA 2
#endif
#define BRIG_ASSISTANT_REMOVE_POSTER_STATUSES list(SEC_RECORD_STATUS_INCARCERATED, SEC_RECORD_STATUS_RELEASED, SEC_RECORD_STATUS_PAROLLED, SEC_RECORD_STATUS_DISCHARGED, SEC_RECORD_STATUS_DEMOTE)
#define BRIG_FINE_SCAN_TIME (3 SECONDS)

/obj/machinery/computer/brig_assistant_console
	name = "Консоль заданий брига"
	desc = "Консоль для выдачи заданий и оплаты штрафов. Вставьте ID-карту для проверки задолженности."
	icon_screen = "security"
	icon_keyboard = "security_key"
	circuit = /obj/item/circuitboard/computer/brig_assistant_console
	req_access = list()
	light_color = LIGHT_COLOR_RED

	/// ckey -> criminal_id -> list of take timestamps (hang poster tasks)
	var/static/list/assistant_task_takes = list()
	var/obj/item/card/id/inserted_id = null
	var/scanning = FALSE
	var/scan_end_time = 0
	var/scan_started_time = 0
	var/obj/item/radio/security_radio

/obj/machinery/computer/brig_assistant_console/Initialize(mapload)
	. = ..()
	security_radio = new /obj/item/radio(src)
	security_radio.listening = 0
	security_radio.set_frequency(FREQ_SECURITY)

/obj/machinery/computer/brig_assistant_console/Destroy()
	if(inserted_id)
		inserted_id.forceMove(drop_location())
		inserted_id = null
	QDEL_NULL(security_radio)
	return ..()

/obj/machinery/computer/brig_assistant_console/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/brig_assistant_console/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/card/id))
		if(inserted_id)
			to_chat(user, span_warning("В консоли уже есть карта. Извлеките её сначала."))
			return TRUE
		if(!user.transferItemToLoc(I, src))
			return TRUE
		inserted_id = I
		to_chat(user, span_notice("Вы вставили [I] в консоль."))
		playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
		start_scan()
		update_icon()
		SStgui.update_uis(src)
		return TRUE
	return ..()

/obj/machinery/computer/brig_assistant_console/AltClick(mob/user)
	if(!can_interact(user))
		return
	if(inserted_id)
		eject_id(user)
		return
	. = ..()

/obj/machinery/computer/brig_assistant_console/proc/eject_id(mob/user)
	if(!inserted_id)
		return
	if(scanning)
		to_chat(user, span_warning("Сканирование не завершено, подождите."))
		return
	playsound(src, 'sound/machines/terminal_eject_disc.ogg', 50, FALSE)
	if(user && !QDELETED(user))
		user.put_in_hands(inserted_id)
		to_chat(user, span_notice("Вы извлекли [inserted_id] из консоли."))
	else
		inserted_id.forceMove(drop_location())
	inserted_id = null
	scanning = FALSE
	scan_end_time = 0
	scan_started_time = 0
	update_icon()
	SStgui.update_uis(src)

/obj/machinery/computer/brig_assistant_console/proc/start_scan()
	if(!inserted_id || scanning)
		return
	scanning = TRUE
	scan_started_time = world.time
	scan_end_time = world.time + BRIG_FINE_SCAN_TIME
	playsound(src, 'sound/machines/terminal_processing.ogg', 50, FALSE)
	addtimer(CALLBACK(src, PROC_REF(finish_scan)), BRIG_FINE_SCAN_TIME)
	SStgui.update_uis(src)

/obj/machinery/computer/brig_assistant_console/proc/finish_scan()
	if(QDELETED(src) || !inserted_id)
		scanning = FALSE
		return
	scanning = FALSE
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
	playsound(src, 'sound/machines/terminal_success.ogg', 50, FALSE)
	SStgui.update_uis(src)

/obj/machinery/computer/brig_assistant_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BrigAssistantConsole", name)
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/brig_assistant_console/ui_data(mob/user)
	var/list/data = list()
	// ID state
	data["has_id"] = inserted_id ? TRUE : FALSE
	data["id_name"] = inserted_id ? (inserted_id.registered_name || inserted_id.registered_account?.account_holder || inserted_id.name) : null
	data["id_balance"] = inserted_id?.registered_account ? inserted_id.registered_account.account_balance : null
	data["scanning"] = scanning
	if(scanning)
		var/total = BRIG_FINE_SCAN_TIME
		var/elapsed = world.time - scan_started_time
		var/prog = clamp(elapsed / total, 0, 1)
		data["scan_progress"] = prog
		data["scan_time_left"] = max(0, scan_end_time - world.time)
	else
		data["scan_progress"] = 0
		data["scan_time_left"] = 0
	// Fines for inserted ID holder
	var/list/fines_list = list()
	var/fines_total = 0
	var/fines_paid = 0
	if(inserted_id && !scanning)
		var/holder = inserted_id.registered_name || inserted_id.registered_account?.account_holder
		if(holder)
			var/datum/data/record/sec = GLOB.data_core.security_by_name[holder]
			// fallback by id field matching card id? use registered_name strictly
			if(!sec && inserted_id.registered_account)
				// try by account holder name
				sec = GLOB.data_core.security_by_name[inserted_id.registered_account.account_holder]
			if(sec)
				var/list/fines = sec.fields["fines"]
				if(islist(fines))
					for(var/datum/data/crime/c in fines)
						var/time_left = c.fine_deadline ? max(0, c.fine_deadline - world.time) : 0
						var/overdue = (c.fine > 0 && time_left == 0 && c.fine_deadline != 0)
						fines_list += list(list(
							"dataId" = c.dataId,
							"name" = c.crimeName,
							"details" = c.crimeDetails,
							"author" = c.author,
							"time" = c.time,
							"fine" = c.fine,
							"paid" = c.paid,
							"total" = c.fine + c.paid,
							"deadline" = c.fine_deadline,
							"time_left" = time_left,
							"duration" = c.fine_duration,
							"overdue" = overdue,
							"display_time_left" = DisplayTimeText(time_left, 1),
							"display_duration" = DisplayTimeText(c.fine_duration, 1),
						))
						fines_total += c.fine + c.paid
						fines_paid += c.paid
	data["fines"] = fines_list
	data["fines_total"] = fines_total
	data["fines_paid"] = fines_paid
	data["fines_count"] = fines_list.len

	var/list/wanted_list = list()
	for(var/datum/data/record/S in GLOB.data_core.security)
		var/status = S.fields["criminal"]
		if(!is_wanted_status(status))
			continue
		var/datum/data/record/G = GLOB.data_core.general_by_name[S.fields["name"]]
		if(!G)
			continue
		var/criminal_id = S.fields["id"]
		var/ckey = user?.ckey
		var/can_take = FALSE
		var/reason = ""
		var/takes_count = 0
		if(!ckey)
			reason = "Требуется авторизация"
		else
			var/list/takes = assistant_task_takes[ckey]
			if(!takes)
				takes = list()
				assistant_task_takes[ckey] = takes
			var/list/criminal_takes = takes[criminal_id]
			if(!criminal_takes)
				criminal_takes = list()
				takes[criminal_id] = criminal_takes
			for(var/i in criminal_takes.len to 1 step -1)
				if(world.time - criminal_takes[i] > WANTED_POSTER_COOLDOWN)
					criminal_takes.Cut(i, i + 1)
			takes_count = criminal_takes.len
			if(criminal_takes.len >= WANTED_POSTER_MAX_PER_ASSISTANT)
				reason = "Достигнут лимит ([WANTED_POSTER_MAX_PER_ASSISTANT] на человека)"
			else if(criminal_takes.len > 0)
				var/last_take = criminal_takes[criminal_takes.len]
				var/time_left = (last_take + WANTED_POSTER_COOLDOWN) - world.time
				if(time_left > 0)
					reason = "КД: [round(time_left / 10)] сек"
				else
					can_take = TRUE
			else
				can_take = TRUE
		var/has_photo = (G.photo_source || G.fields["photo_front"] || G.fields["photo_side"]) ? TRUE : FALSE
		wanted_list += list(list(
			"id" = criminal_id,
			"name" = S.fields["name"],
			"status" = status,
			"can_take" = can_take,
			"reason" = reason,
			"has_photo" = has_photo,
			"takes_count" = takes_count,
		))
	data["wanted"] = wanted_list
	var/list/remove_list = list()
	for(var/datum/data/record/S in GLOB.data_core.security)
		var/status = S.fields["criminal"]
		if(!(status in BRIG_ASSISTANT_REMOVE_POSTER_STATUSES))
			continue
		var/criminal_id = S.fields["id"]
		var/ckey = user?.ckey
		var/has_remove_task = FALSE
		if(ckey)
			var/list/remove_tasks = GLOB.brig_assistant_remove_tasks[ckey]
			has_remove_task = remove_tasks && (criminal_id in remove_tasks)
		remove_list += list(list(
			"id" = criminal_id,
			"name" = S.fields["name"],
			"status" = status,
			"has_task" = has_remove_task,
		))
	data["remove"] = remove_list
	return data

/obj/machinery/computer/brig_assistant_console/proc/is_wanted_status(status)
	return status in list(SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_SEARCH, SEC_RECORD_STATUS_EXECUTE)

/obj/machinery/computer/brig_assistant_console/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	switch(action)
		if("eject_id")
			eject_id(user)
			return TRUE
		if("rescan")
			if(!inserted_id)
				to_chat(user, span_warning("Нет карты в консоли."))
				return
			if(scanning)
				to_chat(user, span_warning("Сканирование уже идет."))
				return
			start_scan()
			return TRUE
		if("pay_fine")
			if(!inserted_id)
				to_chat(user, span_warning("Вставьте ID-карту для оплаты."))
				return
			if(scanning)
				to_chat(user, span_warning("Дождитесь окончания сканирования."))
				return
			var/cdataid = params["cdataid"]
			var/amount = text2num(params["amount"])
			if(!cdataid || !amount)
				// try numeric amount
				amount = params["amount"]
				if(!isnum(amount))
					to_chat(user, span_warning("Неверная сумма."))
					return
			amount = round(amount)
			if(amount <= 0)
				to_chat(user, span_warning("Сумма должна быть положительной."))
				return
			var/datum/bank_account/account = inserted_id.registered_account
			if(!account)
				to_chat(user, span_warning("К карте не привязан банковский счет."))
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
				return
			var/holder = inserted_id.registered_name || account.account_holder
			var/datum/data/record/sec = GLOB.data_core.security_by_name[holder]
			if(!sec && account.account_holder)
				sec = GLOB.data_core.security_by_name[account.account_holder]
			if(!sec)
				to_chat(user, span_warning("Запись не найдена."))
				return
			var/datum/data/crime/fine = GLOB.data_core.getFine(sec.fields["id"], cdataid)
			if(!fine)
				to_chat(user, span_warning("Штраф не найден."))
				return
			if(fine.fine <= 0)
				to_chat(user, span_warning("Штраф уже оплачен."))
				return
			if(amount > fine.fine)
				amount = fine.fine
			if(!account.has_money(amount))
				to_chat(user, span_warning("Недостаточно средств на счете. Баланс: [account.account_balance] кр."))
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
				say("Недостаточно средств. Требуется [amount] кр.")
				return
			// Списываем
			account.adjust_money(-amount, "Оплата штрафа: [fine.crimeName]")
			var/datum/bank_account/sec_account = SSeconomy.get_dep_account(ACCOUNT_SEC)
			if(sec_account)
				sec_account.adjust_money(amount, "Поступление штрафа от [holder]")
			GLOB.data_core.payFine(sec.fields["id"], cdataid, amount)
			// логи
			GLOB.data_core.append_sec_logs(sec.fields["id"], "%%GEN_AUTH%% оплатил [amount] кр. по штрафу \"[fine.crimeName]\" (остаток [fine.fine] кр.) через консоль брига", holder, "Сотрудник")
			if(fine.fine == 0)
				GLOB.data_core.append_sec_logs(sec.fields["id"], "Штраф \"[fine.crimeName]\" полностью погашен сотрудником [holder]", "Система", "Автоматика")
				say("Штраф \"[fine.crimeName]\" полностью оплачен. Спасибо.")
				playsound(src, 'sound/machines/terminal_success.ogg', 50, FALSE)
				print_fine_receipt(sec, fine, amount, holder)
				if(security_radio)
					security_radio.talk_into(src, "Сотрудник [holder] полностью оплатил штраф \"[fine.crimeName]\" ([fine.paid + fine.fine] кр.).")
				var/msg_full = "Ваш штраф №[fine.dataId] (\"[fine.crimeName]\") полностью оплачен на [amount] кр. Всего уплачено [fine.paid] кр. Спасибо! Квитанция распечатана в консоли брига."
				fine.alert_fine_owner(user, src, holder, msg_full)
			else
				say("Оплачено [amount] кр. по штрафу \"[fine.crimeName]\". Остаток: [fine.fine] кр.")
				playsound(src, 'sound/machines/terminal_success.ogg', 50, FALSE)
				if(security_radio)
					security_radio.talk_into(src, "Сотрудник [holder] оплатил [amount] кр. по штрафу \"[fine.crimeName]\" (остаток [fine.fine] кр.).")
				print_fine_receipt(sec, fine, amount, holder)
				var/msg_part = "Ваш штраф №[fine.dataId] (\"[fine.crimeName]\") частично оплачен на [amount] кр. Уплачено [fine.paid]/[fine.paid + fine.fine] кр. Остаток [fine.fine] кр. Осталось [DisplayTimeText(max(0, fine.fine_deadline - world.time))]. Оплатите полностью до истечения срока во избежание ст. 303."
				fine.alert_fine_owner(user, src, holder, msg_part)
			SStgui.update_uis(src)
			return TRUE
		if("pay_fine_full")
			if(!inserted_id)
				return
			if(scanning)
				return
			var/cdataid = params["cdataid"]
			var/holder = inserted_id.registered_name || inserted_id.registered_account?.account_holder
			var/datum/data/record/sec = GLOB.data_core.security_by_name[holder]
			if(!sec && inserted_id.registered_account)
				sec = GLOB.data_core.security_by_name[inserted_id.registered_account.account_holder]
			if(!sec)
				return
			var/datum/data/crime/fine = GLOB.data_core.getFine(sec.fields["id"], cdataid)
			if(!fine || fine.fine <= 0)
				return
			var/amount = fine.fine
			var/datum/bank_account/account = inserted_id.registered_account
			if(!account || !account.has_money(amount))
				to_chat(user, span_warning("Недостаточно средств."))
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
				return
			account.adjust_money(-amount, "Оплата штрафа: [fine.crimeName]")
			var/datum/bank_account/sec_account = SSeconomy.get_dep_account(ACCOUNT_SEC)
			if(sec_account)
				sec_account.adjust_money(amount, "Поступление штрафа от [holder]")
			GLOB.data_core.payFine(sec.fields["id"], cdataid, amount)
			GLOB.data_core.append_sec_logs(sec.fields["id"], "%%GEN_AUTH%% полностью оплатил штраф \"[fine.crimeName]\" ([amount] кр.) через консоль брига", holder, "Сотрудник")
			say("Штраф полностью оплачен.")
			playsound(src, 'sound/machines/terminal_success.ogg', 50, FALSE)
			print_fine_receipt(sec, fine, amount, holder)
			if(security_radio)
				security_radio.talk_into(src, "Сотрудник [holder] полностью оплатил штраф \"[fine.crimeName]\".")
			var/msg_full2 = "Ваш штраф №[fine.dataId] (\"[fine.crimeName]\") полностью оплачен на [amount] кр. Всего уплачено [fine.paid] кр. Спасибо! Квитанция распечатана в консоли брига."
			fine.alert_fine_owner(user, src, holder, msg_full2)
			SStgui.update_uis(src)
			return TRUE
		if("take_task")
			var/criminal_id = params["id"]
			if(!criminal_id)
				return
			var/datum/data/record/S = GLOB.data_core.security_by_id[criminal_id]
			if(!S || !is_wanted_status(S.fields["criminal"]))
				to_chat(user, span_warning("Запись не найдена или преступник больше не в розыске."))
				return
			var/datum/data/record/G = GLOB.data_core.general_by_name[S.fields["name"]]
			if(!G)
				to_chat(user, span_warning("Общая запись не найдена."))
				return
			var/ckey = user.ckey
			if(!ckey)
				return
			var/list/takes = assistant_task_takes[ckey]
			if(!takes)
				takes = list()
				assistant_task_takes[ckey] = takes
			var/list/criminal_takes = takes[criminal_id]
			if(!criminal_takes)
				criminal_takes = list()
				takes[criminal_id] = criminal_takes
			for(var/i in criminal_takes.len to 1 step -1)
				if(world.time - criminal_takes[i] > WANTED_POSTER_COOLDOWN)
					criminal_takes.Cut(i, i + 1)
			if(criminal_takes.len >= WANTED_POSTER_MAX_PER_ASSISTANT)
				to_chat(user, span_warning("Вы уже взяли максимум заданий на этого преступника."))
				return
			if(criminal_takes.len > 0)
				var/last_take = criminal_takes[criminal_takes.len]
				if(world.time - last_take < WANTED_POSTER_COOLDOWN)
					to_chat(user, span_warning("Подождите ещё [round((last_take + WANTED_POSTER_COOLDOWN - world.time) / 10)] секунд."))
					return
			var/take_stamp = world.time
			criminal_takes += take_stamp
			var/obj/item/photo/photo = G.get_record_photo("photo_front") || G.get_record_photo("photo_side")
			if(QDELETED(src) || QDELETED(user) || QDELETED(S) || QDELETED(G) || !is_wanted_status(S.fields["criminal"]))
				criminal_takes -= take_stamp
				return
			var/icon/person_icon
			if(photo && photo.picture && photo.picture.picture_image)
				person_icon = photo.picture.picture_image
			else
				person_icon = icon('icons/mob/simple_human.dmi', "generic")
			var/wanted_name = S.fields["name"]
			var/default_description = "A poster declaring [wanted_name] to be a dangerous individual, wanted by Nanotrasen. Report any sightings to security immediately."
			var/list/major_crimes = S.fields["ma_crim"]
			var/list/minor_crimes = S.fields["mi_crim"]
			if(length(major_crimes) + length(minor_crimes))
				default_description += "\n[wanted_name] is wanted for the following crimes:\n"
			if(length(minor_crimes))
				default_description += "\nMinor Crimes:"
				for(var/datum/data/crime/c in minor_crimes)
					default_description += "\n[c.crimeName]\n[c.crimeDetails]\n"
			if(length(major_crimes))
				default_description += "\nMajor Crimes:"
				for(var/datum/data/crime/c in major_crimes)
					default_description += "\n[c.crimeName]\n[c.crimeDetails]\n"
			playsound(loc, 'sound/items/poster_being_created.ogg', 100, 1)
			var/obj/item/poster/wanted/P = new(loc, person_icon, wanted_name, default_description)
			P.poster_id = criminal_id
			if(P.poster_structure)
				P.poster_structure.poster_id = criminal_id
			user.put_in_hands(P)
			to_chat(user, span_notice("Вы взяли задание: развесить плакат по [wanted_name]. Не более [WANTED_POSTER_MAX_PER_AREA] плакатов в одной зоне."))
			return TRUE
		if("take_remove_task")
			var/criminal_id = params["id"]
			if(!criminal_id)
				return
			var/datum/data/record/S = GLOB.data_core.security_by_id[criminal_id]
			if(!S)
				to_chat(user, span_warning("Запись не найдена."))
				return
			if(S.fields["criminal"] in list(SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_SEARCH, SEC_RECORD_STATUS_EXECUTE))
				to_chat(user, span_warning("Этот человек ещё в розыске - снимайте плакаты только после поимки."))
				return
			if(!(S.fields["criminal"] in BRIG_ASSISTANT_REMOVE_POSTER_STATUSES))
				to_chat(user, span_warning("Задание на снятие доступно только после смены статуса в консоли СБ (тюрьма, выпуск, УДО и т.п.)."))
				return
			var/ckey = user.ckey
			if(!ckey)
				return
			var/list/remove_tasks = GLOB.brig_assistant_remove_tasks[ckey]
			if(!remove_tasks)
				remove_tasks = list()
				GLOB.brig_assistant_remove_tasks[ckey] = remove_tasks
			if(criminal_id in remove_tasks)
				to_chat(user, span_warning("Вы уже взяли это задание."))
				return
			remove_tasks += criminal_id
			to_chat(user, span_notice("Вы взяли задание: снять плакаты с [S.fields["name"]]. Используйте кусачки на плакате для снятия. Награда: 75-100 кредитов."))
			return TRUE
	return FALSE

/obj/machinery/computer/brig_assistant_console/proc/print_fine_receipt(datum/data/record/sec, datum/data/crime/fine, amount, holder)
	var/obj/item/paper/P = new /obj/item/paper(drop_location())
	var/status_text = fine.fine > 0 ? "ЧАСТИЧНО ОПЛАЧЕН (остаток [fine.fine] кр.)" : "ПОЛНОСТЬЮ ОПЛАЧЕН"
	var/payer_rank = "Неизвестно"
	if(inserted_id && inserted_id.assignment)
		payer_rank = inserted_id.assignment
	else
		var/datum/data/record/G = GLOB.data_core.general_by_name[holder]
		if(G)
			payer_rank = G.fields["rank"]
	var/violator_rank = sec.fields["rank"] || "Неизвестно"
	var/report_text = {"
		<h1><div align="center">КВИТАНЦИЯ ОПЛАТЫ ШТРАФА</div></h1>
		<p><strong>Объект:</strong> [GLOB.station_name]</p>
		<p><strong>Дата:</strong> [GLOB.current_date_string] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]</p>
		<p><strong>Плательщик:</strong> [holder] ([payer_rank])</p>
		<p><strong>Нарушитель:</strong> [sec.fields["name"]] ([violator_rank], [sec.fields["id"]])</p>
		<p><strong>Статья:</strong> [fine.crimeName]</p>
		<p><strong>Подробности:</strong> [fine.crimeDetails]</p>
		<p><strong>Выписал:</strong> [fine.author] ([fine.time])</p>
		<p><strong>Сумма штрафа:</strong> [fine.paid + fine.fine] кр.</p>
		<p><strong>Оплачено сейчас:</strong> [amount] кр.</p>
		<p><strong>Всего уплачено:</strong> [fine.paid] кр.</p>
		<p><strong>Остаток:</strong> [fine.fine] кр.</p>
		<p><strong>Статус:</strong> [status_text]</p>
		<p><strong>Исходный срок:</strong> [DisplayTimeText(fine.fine_duration)]</p>
		<hr>
		<p><strong><div align="center">Подписи и печати</div></strong></p>
		<p><strong>Кассир:</strong> Консоль заданий брига (автоматически)</p>
		<p><strong>Плательщик:</strong> [holder] ([payer_rank])</p>
		<p><strong>Место для печатей</strong></p>
		<hr/><br><br><br><hr/>
		<font color="grey"><div align="justify">Документ подтверждает оплату штрафа через терминальную сеть Службы Безопасности. Средства зачислены на счет Отдела Защиты [ACCOUNT_SEC_NAME].</div></font>"}
	P.add_raw_text(report_text)
	P.name = "Квитанция штрафа - [sec.fields["name"]] - [fine.crimeName]"
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
	P.add_stamp(sheet.icon_class_name("stamp-security"), 400, 50, 1, "stamp-security")
	P.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 120, 1, "stamp-machine")
	P.update_appearance()
	P.update_icon()
	playsound(loc, 'sound/items/poster_being_created.ogg', 100, TRUE)

#undef BRIG_ASSISTANT_REMOVE_POSTER_STATUSES
#undef BRIG_FINE_SCAN_TIME
