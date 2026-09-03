GLOBAL_VAR(current_date_string)

//─────────────────────────────────────────────
//  ACCOUNTS DATABASE TERMINAL
//─────────────────────────────────────────────

#define AUT_ACCLST 1
#define AUT_ACCINF 2
#define AUT_ACCNEW 3

/obj/machinery/computer/account_database
	name = "Accounts Uplink Terminal"
	desc = "Access transaction logs, account data and other financial records."
	icon_screen = "vault"
	icon_keyboard = "teleport_key"
	req_one_access = list(ACCESS_HOP)
	light_color = LIGHT_COLOR_GREEN

	var/obj/item/card/id/linked_id = null
	var/activated = TRUE
	var/receipt_num
	var/machine_id = ""
	var/const/fund_cap = 1000000
	var/datum/bank_account/detailed_account_view
	var/current_page = AUT_ACCLST
	var/is_printing = FALSE
	var/temp_notice
	var/last_dep_click_count = 0

/obj/machinery/computer/account_database/New()
	if(!GLOB.station_account)
		create_station_account()
	if(!GLOB.current_date_string)
		GLOB.current_date_string = "[time2text(world.timeofday, "DD Month")], [GLOB.year_integer]"
	machine_id = "[station_name()] Acc. DB #[GLOB.num_financial_terminals++]"
	..()

/obj/machinery/computer/account_database/attackby(obj/item/O, mob/user, params)
	if(ui_login_attackby(O, user))
		add_fingerprint(user)
		return TRUE

	if(istype(O, /obj/item/screwdriver))
		if(linked_id)
			to_chat(user, span_notice("You remove [linked_id.registered_name]'s ID card from the terminal."))
			linked_id.forceMove(get_turf(src))
			linked_id = null
		else
			to_chat(user, span_warning("No ID card inserted."))
		return TRUE
	return ..()

/obj/machinery/computer/account_database/attack_hand(mob/user)
	if(..())
		return TRUE
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/account_database/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AccountsUplinkTerminal", name)
		ui.open()
	else
		// 🔧 Чтобы не было двойных вызовов ui_act при детальном просмотре
		if(current_page == AUT_ACCLST)
			ui.set_autoupdate(TRUE) // обновляем только список
		else
			ui.set_autoupdate(FALSE) // подробная страница — статична

/proc/safe_text(value, default = "Unknown")
	if(isnull(value))
		return "[default]"
	if(istext(value))
		return value
	return "[value]"

/obj/machinery/computer/account_database/ui_host()
	return src

/obj/machinery/computer/account_database/ui_data(mob/user)
	var/list/data = list()
	data["currentPage"] = current_page
	data["isPrinting"] = is_printing
	ui_login_data(data, user)
	data["modal"] = ui_modal_data()
	data["temp"] = temp_notice

	if(!data["loginState"]["logged_in"])
		return data

	switch(current_page)
		if(AUT_ACCLST)
			var/list/dep_accounts = list()
			var/list/player_accounts = list()

			// 🏛️ Сначала — департаменты
			var/i = 1
			for (var/datum/bank_account/department/D in SSeconomy.generated_accounts)
				dep_accounts += list(list(
					"id" = "dep_[i]",
					"dep_index" = i,
					"dep_id" = "[D.department_id]",
					"account_number" = "##",
					"owner_name" = "[D.account_holder] (Department)",
					"target_name" = "[D.account_holder]",
					"suspended" = (D.transferable ? "Active" : "Suspended"),
					"balance" = "[D.account_balance]",
					"account_index" = -1
				))
				i++

			// 👤 Потом — обычные счета
			for (var/datum/bank_account/B in GLOB.all_money_accounts)
				if (!istype(B, /datum/bank_account/department))
					player_accounts += list(list(
						"id" = GLOB.all_money_accounts.Find(B),
						"account_number" = "[B.account_id]",
						"owner_name" = "[B.account_holder]",
						"suspended" = (B.transferable ? "Active" : "Suspended"),
						"balance" = "[B.account_balance]",
						"account_index" = GLOB.all_money_accounts.Find(B)
					))

			// 📋 Объединяем: департаменты сверху, игроки снизу
			data["accounts"] = dep_accounts + player_accounts


		if(AUT_ACCINF)
			var/datum/bank_account/A = detailed_account_view
			data["is_department"] = istype(A, /datum/bank_account/department)
			if(!A)
				return data

			data["account_number"] = "[A.account_id]"
			data["owner_name"] = "[A.account_holder]"
			data["money"] = "[A.account_balance]"
			data["suspended"] = (A.transferable ? FALSE : TRUE)
			data["pay_level"] = (A.account_job && A.account_job.paycheck) ? "[A.account_job.paycheck]" : "Not set"

			data["suspicious"] = A.suspicious_activity
			data["suspicious_reason"] = A.suspicion_reason

			// 📜 История транзакций
			var/list/txs = list()
			for(var/datum/transaction/T in A.transaction_history)
				var/amt_text = isnum(T.amount) ? "[T.amount]" : "[T.amount]"
				// Нормализуем вид: -1250 / 1250 (знак оставляем как есть)
				txs += list(list(
					"date" = safe_text(T.date, "N/A"),
					"time" = safe_text(T.time, "--:--:--"),
					"target_name" = safe_text(T.target_name, "Unknown"),
					"purpose" = safe_text(T.purpose, "Unknown"),
					"amount" = amt_text,
					"source_terminal" = safe_text(T.source_terminal, "Unknown")
				))
			data["transactions"] = txs

		if(AUT_ACCNEW)
			data["create_form"] = TRUE

	// 👇 Вставь сюда, ПЕРЕД return data
	// Fallback compatibility for old TGUI code expecting "account"
	if(src.detailed_account_view)
		data["account"] = list(
			"account_number" = "[src.detailed_account_view.account_id]",
			"owner_name" = "[src.detailed_account_view.account_holder]",
			"balance" = "[src.detailed_account_view.account_balance]"
		)
	else
		data["account"] = null

	return data

/obj/machinery/computer/account_database/proc/set_temp(text = "", style = "info", update_now = FALSE)
	temp_notice = list(text = text, style = style)
	if(update_now)
		SStgui.update_uis(src)

/obj/machinery/computer/account_database/ui_act(action, list/params)
	if(..()) return
	. = TRUE
	if(ui_login_act(action, params)) return
	if(ui_act_modal(action, params)) return
	if(!ui_login_get().logged_in) return
	// Если выбран департаментский счёт — запретить любые операции
	if (detailed_account_view && istype(detailed_account_view, /datum/bank_account/department))
		switch(action)
			if("toggle_suspension", "finalise_transfer", "change_pay_level", "create_new_account")
				set_temp("Department accounts are read-only.", "warning", TRUE)
				return

	switch(action)
		if("view_account_detail")
			var/index = text2num(params["index"])

			if (index == -1)

				var/dep_i = text2num(params["dep_index"])
				if (dep_i)
					var/i = 1
					for (var/datum/bank_account/department/D in SSeconomy.generated_accounts)
						if (i == dep_i)
							detailed_account_view = D
							current_page = AUT_ACCINF
							return
						i++

				var/dep_id = params["dep_id"]
				if (istext(dep_id) && length(dep_id))
					for (var/datum/bank_account/department/D in SSeconomy.generated_accounts)
						if ("[D.department_id]" == "[dep_id]")
							detailed_account_view = D
							current_page = AUT_ACCINF
							return

				var/target_name = params["target_name"]
				if (istext(target_name) && length(target_name))
					var/clean_target = lowertext(trim(replacetext(target_name, " (Department)", "")))
					for (var/datum/bank_account/department/D in SSeconomy.generated_accounts)
						var/clean_holder = lowertext(trim(D.account_holder))
						if (clean_holder == clean_target)
							detailed_account_view = D
							current_page = AUT_ACCINF
							return

				set_temp("Department account not found for the clicked row.", "danger", TRUE)
				return

			if(index && index > 0 && index <= length(GLOB.all_money_accounts))
				detailed_account_view = GLOB.all_money_accounts[index]
				current_page = AUT_ACCINF
				return

			set_temp("Account not found.", "danger", TRUE)

		if("back")
			detailed_account_view = null
			current_page = AUT_ACCLST

		if("toggle_suspension")
			if(detailed_account_view)
				detailed_account_view.transferable = !detailed_account_view.transferable

		if("create_new_account")
			current_page = AUT_ACCNEW
			ui_modal_input(src, "create_account", "Enter new account holder name:")

		if("finalise_create_account")
			var/holder = params["holder_name"]
			var/startf = text2num(params["starting_funds"])
			if(!length(holder))
				set_temp("Invalid account name.", "danger", TRUE)
				return
			var/datum/bank_account/M = create_account(holder, startf, src)
			if(!M)
				set_temp("Account creation failed.", "danger", TRUE)
				return
			set_temp("Account [M.account_holder] created successfully. ID: [M.account_id].", "success", TRUE)
			current_page = AUT_ACCLST


		//Временно вырезано из-за возможности выдавать себе бесконечно денег. Стас, ты вообще тестишь свой нейрослоп?
		//прок set_temp тоже НЕ работает. Совсем. Ты бы хоть комментарии от нейронки убрал для приличия.

		// if("finalise_transfer")
		// 	var/from_index = text2num(params["from_index"])
		// 	var/to_acc_id = params["to_account_id"]
		// 	var/amount = text2num(params["amount"])
		// 	if(!from_index || amount <= 0 || !length(to_acc_id))
		// 		set_temp("Invalid transfer parameters.", "danger", TRUE)
		// 		return
		// 	var/list/accounts = GLOB.all_money_accounts
		// 	if(from_index < 1 || from_index > length(accounts))
		// 		set_temp("Source account not found.", "danger", TRUE)
		// 		return
		// 	var/datum/bank_account/From = accounts[from_index]
		// 	var/datum/bank_account/To
		// 	for(var/datum/bank_account/B in accounts)
		// 		if(B.account_id == text2num(to_acc_id))
		// 			To = B
		// 			break
		// 	if(!To)
		// 		set_temp("Target account not found.", "danger", TRUE)
		// 		return
		// 	if(From.account_balance < amount)
		// 		set_temp("Insufficient funds.", "danger", TRUE)
		// 		return
		// 	From.account_balance -= amount
		// 	To.account_balance += amount
		// 	set_temp("Transferred [amount] credits from [From.account_holder] to [To.account_holder].", "success", TRUE)

		if("change_pay_level")
			if(!detailed_account_view) return

			// 1) Выбор грейда
			var/list/pay_levels = list(
				"Assistant" = PAYCHECK_ASSISTANT,
				"Minimal"   = PAYCHECK_MINIMAL,
				"Normal"   = PAYCHECK_EASY,
				"Normal+"  = PAYCHECK_MEDIUM,
				"High"     = PAYCHECK_HARD,
				"Command"  = PAYCHECK_COMMAND
			)
			var/choice = tgui_input_list(usr, "Select new pay grade", "Pay Adjustment", pay_levels)
			if(!choice) return
			var/new_pay = pay_levels[choice]

			// 2) Выбор отдела (откуда платим)
			var/list/dep_choices = list(
				"[ACCOUNT_CIV_NAME]" = ACCOUNT_CIV,
				"[ACCOUNT_ENG_NAME]" = ACCOUNT_ENG,
				"[ACCOUNT_SCI_NAME]" = ACCOUNT_SCI,
				"[ACCOUNT_MED_NAME]" = ACCOUNT_MED,
				"[ACCOUNT_SRV_NAME]" = ACCOUNT_SRV,
				"[ACCOUNT_CAR_NAME]" = ACCOUNT_CAR,
				"[ACCOUNT_SEC_NAME]" = ACCOUNT_SEC
			)
			var/dep_choice = tgui_input_list(usr, "Choose budget (department)", "Pay Budget", dep_choices)
			if(!dep_choice) return
			var/new_dep = dep_choices[dep_choice]

			// 3) Применяем к аккаунту
			var/datum/bank_account/A = detailed_account_view
			if(!A.account_job)
				A.account_job = new()
			A.account_job.paycheck = new_pay
			A.account_job.paycheck_department = new_dep

			// 4) Сообщения и всплывашка
			to_chat(usr, span_notice("Set [A.account_holder]'s paycheck to [new_pay] credits ([choice]) and budget to [dep_choice]."))
			set_temp("Pay updated: [choice] ([new_pay]) • Budget: [dep_choice].", "success", TRUE)

			// (опционально) Лог в историю для наглядности
			A.makeTransactionLog(0, "Pay profile updated: [choice], budget: [dep_choice]", "[src.name]", "[dep_choice]", FALSE)


		if("print_records")
			//world.log << "[src]: UI action 'print_records' triggered."
			if(is_printing)
				set_temp("Printer busy, please wait.", "warning", TRUE)
				return
			addtimer(CALLBACK(src, PROC_REF(print_records_finish), "list"), 2 SECONDS)

		if("print_account_details")
			//world.log << "[src]: UI action 'print_account_details' triggered."
			if(is_printing)
				set_temp("Printer busy, please wait.", "warning", TRUE)
				return
			addtimer(CALLBACK(src, PROC_REF(print_records_finish), "details"), 2 SECONDS)

	add_fingerprint(usr)

/obj/machinery/computer/account_database/proc/print_records_finish(print_mode)
	if(is_printing)
		//log_world("[src]: print_records_finish() called while already printing.")
		return
	is_printing = TRUE

	playsound(get_turf(src), 'sound/goonstation/machines/printer_thermal.ogg', 50, TRUE)

	var/turf/TT = get_turf(src)
	if(!TT)
		//log_world("[src]: print_records_finish() failed — no turf found.")
		is_printing = FALSE
		return

	var/obj/item/paper/P = new /obj/item/paper(TT)
	if(!P)
		//log_world("[src]: print_records_finish() failed to create paper.")
		is_printing = FALSE
		return

	P.name = "Account Report"
// ============================
// МОД РЕЖИМОВ ПЕЧАТИ
// ============================

	switch(print_mode)
		if("details")
			var/datum/bank_account/A = detailed_account_view
			if(!A)
				P.add_raw_text("<b>Ошибка:</b> Не выбран счёт для подробного отчёта.<br>")
			else
				P.name = "Финансовый отчёт Nanotrasen"

				// Заголовок
				P.add_raw_text("<h1><div align='center'>ФИНАНСОВЫЙ ОТЧЁТ О СЧЁТЕ</div></h1>")
				P.add_raw_text("<hr />")
				P.add_raw_text("<p><strong>Владелец счёта:</strong> [A.account_holder]</p>")
				P.add_raw_text("<p><strong>Номер счёта:</strong> #[A.account_id]</p>")
				P.add_raw_text("<p><strong>Баланс:</strong> [A.account_balance] кредитов</p>")
				P.add_raw_text("<p><strong>Статус счёта:</strong> [(A.transferable ? "Активен" : "Заморожен")]</p>")

				if(A.suspicious_activity)
					P.add_raw_text("<p><font color='red'><strong>⚠ Подозрительная активность:</strong> [A.suspicion_reason]</font></p>")

				P.add_raw_text("<hr />")
				P.add_raw_text("<p><strong>Дата формирования отчёта:</strong> [GLOB.current_date_string]</p>")
				P.add_raw_text("<p><strong>Источник:</strong> [src.name]</p>")
				var/author_name = usr ? usr.real_name : "N/A"
				P.add_raw_text("<p><strong>Авторизация терминала:</strong> [author_name]</p>")
				P.add_raw_text("<hr />")

				// ────────────────────────────────
				// ПЕЧАТИ
				// ────────────────────────────────
				P.add_raw_text("<p><div align='center'><strong>Печати</strong></div></p>")
				P.add_raw_text("<p><strong>Место для печатей:</strong></p>")
				P.add_raw_text("<hr />")

				P.add_raw_text("<font color='grey'><div align='justify'>Данный отчёт составлен автоматически системой Nanotrasen Financial Uplink. Считается действительным только при наличии печати станции.</div></font>")

				var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
				P.add_stamp(sheet.icon_class_name("stamp-machine"), 350, 250, 1, "stamp-machine")

				P.add_raw_text("<div align='center'><i>This document has been automatically stamped by the Accounts Database system.</i></div>")
				P.update_icon()

				// ────────────────────────────────
				// ИСТОРИЯ ТРАНЗАКЦИЙ
				// ────────────────────────────────
				P.add_raw_text("<p><div align='center'><strong>История транзакций</strong></div></p>")
				P.add_raw_text("<table border='0' width='100%' style='border-collapse: collapse; line-height: 1.4;'>")

				// Заголовки таблицы — теперь отделены
				P.add_raw_text("<thead>")
				P.add_raw_text("<tr style='font-weight:bold; border-bottom:2px solid #000;'>")
				P.add_raw_text("<td width='5%'>№</td>")
				P.add_raw_text("<td width='15%'>Дата</td>")
				P.add_raw_text("<td width='10%'>Время</td>")
				P.add_raw_text("<td width='25%'>Цель</td>")
				P.add_raw_text("<td width='25%'>Описание</td>")
				P.add_raw_text("<td width='10%' align='right'>Сумма</td>")
				P.add_raw_text("<td width='10%'>Терминал</td>")
				P.add_raw_text("</tr>")
				P.add_raw_text("</thead>")

				P.add_raw_text("<tbody>")
				P.add_raw_text("<tr><td colspan='7'><br></td></tr>") // отступ между заголовком и первой строкой

				if(!A.transaction_history || !length(A.transaction_history))
					P.add_raw_text("<tr><td colspan='7' align='center'><i>Нет зарегистрированных транзакций.</i></td></tr>")
				else
					var/i = 1
					for(var/datum/transaction/TX in A.transaction_history)
						P.add_raw_text("<tr style='border-top:1px solid #ccc;'>")
						P.add_raw_text("<td align='center'><b>[i].</b></td>")
						P.add_raw_text("<td>[TX.date]</td>")
						P.add_raw_text("<td>[TX.time]</td>")
						P.add_raw_text("<td>[TX.target_name]</td>")
						P.add_raw_text("<td>[TX.purpose]</td>")
						P.add_raw_text("<td align='right'>[TX.amount]</td>")
						P.add_raw_text("<td>[TX.source_terminal]</td>")
						P.add_raw_text("</tr>")
						P.add_raw_text("<tr><td colspan='7'><br></td></tr>") // разделитель строк
						i++

				P.add_raw_text("</tbody></table><hr />")

// вот здесь закончился блок DETAILS, теперь начинается LIST
		if("list")
			P.name = "Сводный финансовый отчёт"

			P.add_raw_text("<h1><div align='center'>СВОДНЫЙ ФИНАНСОВЫЙ ОТЧЁТ</div></h1>")
			P.add_raw_text("<hr />")
			P.add_raw_text("<p><strong>Описание:</strong> Автоматически сгенерированный отчёт о состоянии всех активных и замороженных счетов станции Nanotrasen.</p>")
			P.add_raw_text("<p><strong>Источник данных:</strong> Финансовый терминал станции #[GLOB.num_financial_terminals]</p>")
			P.add_raw_text("<p><strong>Дата формирования:</strong> [GLOB.current_date_string]</p>")
			P.add_raw_text("<hr />")

			var/list/all_accounts = GLOB.all_money_accounts

			if(!all_accounts || !length(all_accounts))
				P.add_raw_text("<p><i>Не найдено активных счетов.</i></p>")
			else
				P.add_raw_text("<p><strong>Список счетов:</strong></p>")
				P.add_raw_text("<table border='0' width='100%' style='border-collapse: collapse; line-height: 1.5;'>")

				// 🔹 Заголовки таблицы — отдельно и с нижней границей
				P.add_raw_text("<thead>")
				P.add_raw_text("<tr style='font-weight:bold; border-bottom:2px solid #000;'>")
				P.add_raw_text("<td width='5%'>№</td>")
				P.add_raw_text("<td width='35%'>Владелец</td>")
				P.add_raw_text("<td width='20%'>Номер счёта</td>")
				P.add_raw_text("<td width='20%' align='right'>Баланс</td>")
				P.add_raw_text("<td width='20%' align='center'>Статус</td>")
				P.add_raw_text("</tr>")
				P.add_raw_text("</thead>")

				// Добавляем визуальный отступ между шапкой и первой записью
				P.add_raw_text("<tbody>")
				P.add_raw_text("<tr><td colspan='5'><br></td></tr>")

				var/i = 1
				for(var/datum/bank_account/ACC in all_accounts)
					P.add_raw_text("<tr style='border-top:1px solid #ccc;'>")
					P.add_raw_text("<td align='center'><b>[i].</b></td>")
					P.add_raw_text("<td>[ACC.account_holder]</td>")
					P.add_raw_text("<td>#[ACC.account_id]</td>")
					P.add_raw_text("<td align='right'>[ACC.account_balance]</td>")
					P.add_raw_text("<td align='center'>[(ACC.transferable ? "Активен" : "Заморожен")]</td>")
					P.add_raw_text("</tr>")
					P.add_raw_text("<tr><td colspan='5'><br></td></tr>")
					i++

				P.add_raw_text("</tbody></table><hr />")

				// Автоматическая печать
				var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
				P.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 600, 1, "stamp-machine")
				P.add_raw_text("<div align='center'><i>This document has been automatically stamped by the Accounts Database system.</i></div>")
				P.update_icon()

			// Сноска
			P.add_raw_text("<font color='grey'><div align='justify'>Данный отчёт составлен автоматически системой Nanotrasen Financial Uplink. Считается действительным только при наличии печати станции.</div></font>")

		else
			P.add_raw_text("<b>Unknown print mode:</b> [print_mode]<br>")

	// ============================

	P.add_raw_text("<br><i>Date:</i> [GLOB.current_date_string]<br>")
	P.update_icon()

	visible_message(span_notice("[src] prints out a financial report."))
	is_printing = FALSE
	//log_world("[src]: print_records_finish('[print_mode]') completed successfully.")

// ───────────────────────────────
//  Modal Input Support (SRD style)
// ───────────────────────────────
/obj/machinery/computer/account_database/proc/ui_act_modal(action, list/params)
	if(!ui_login_get().logged_in)
		return
	. = TRUE
	var/id = params["id"]
	if(istext(params["arguments"]))
		params["arguments"] = json_decode(params["arguments"])

	switch(ui_modal_act(src, action, params))
		if(UI_MODAL_OPEN)
			if(id == "create_account")
				ui_modal_input(src, id, "Enter account holder name:")

		if(UI_MODAL_ANSWER)
			var/answer = params["answer"]
			if(id == "create_account")
				if(!length(answer))
					set_temp("Invalid name.", "danger", TRUE)
					return
				var/datum/bank_account/M = create_account(answer, 0, src)
				set_temp("Account [M.account_holder] created successfully.", "success", TRUE)
				current_page = AUT_ACCLST
				return
		else
			return FALSE

#undef AUT_ACCLST
#undef AUT_ACCINF
#undef AUT_ACCNEW
