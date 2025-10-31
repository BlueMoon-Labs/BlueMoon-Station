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
		ui.set_autoupdate(TRUE) // раз в ~2 сек

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
			var/list/accounts = list()
			for(var/datum/bank_account/B in GLOB.all_money_accounts)
				if(!istype(B, /datum/bank_account))
					continue
				accounts += list(list(
					"id" = GLOB.all_money_accounts.Find(B),
					"account_number" = "[B.account_id]",
					"owner_name" = "[B.account_holder]",
					"suspended" = (B.transferable ? "Active" : "Suspended"),
					"balance" = "[B.account_balance]",
					"account_index" = GLOB.all_money_accounts.Find(B)
				))
			data["accounts"] = accounts

		if(AUT_ACCINF)
			var/datum/bank_account/A = detailed_account_view
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
				txs += list(list(
					"date" = safe_text(T.date, "N/A"),
					"time" = safe_text(T.time, "--:--:--"),
					"target_name" = safe_text(T.target_name, "Unknown"),
					"purpose" = safe_text(T.purpose, "Unknown"),
					"amount" = "[safe_text(T.amount, "0")]",
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

	switch(action)
		if("view_account_detail")
			var/index = text2num(params["index"])
			if(index && index > 0 && index <= length(GLOB.all_money_accounts))
				detailed_account_view = GLOB.all_money_accounts[index]
				current_page = AUT_ACCINF

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

		if("finalise_transfer")
			var/from_index = text2num(params["from_index"])
			var/to_acc_id = params["to_account_id"]
			var/amount = text2num(params["amount"])
			if(!from_index || amount <= 0 || !length(to_acc_id))
				set_temp("Invalid transfer parameters.", "danger", TRUE)
				return
			var/list/accounts = GLOB.all_money_accounts
			if(from_index < 1 || from_index > length(accounts))
				set_temp("Source account not found.", "danger", TRUE)
				return
			var/datum/bank_account/From = accounts[from_index]
			var/datum/bank_account/To
			for(var/datum/bank_account/B in accounts)
				if(B.account_id == text2num(to_acc_id))
					To = B
					break
			if(!To)
				set_temp("Target account not found.", "danger", TRUE)
				return
			if(From.account_balance < amount)
				set_temp("Insufficient funds.", "danger", TRUE)
				return
			From.account_balance -= amount
			To.account_balance += amount
			set_temp("Transferred [amount] credits from [From.account_holder] to [To.account_holder].", "success", TRUE)

		if("change_pay_level")
			if(!detailed_account_view) return

			// 1) Выбор грейда
			var/list/pay_levels = list(
				"Assistant 25" = PAYCHECK_ASSISTANT,
				"Minimal 75"   = PAYCHECK_MINIMAL,
				"Normal 125"   = PAYCHECK_EASY,
				"Normal+ 175"  = PAYCHECK_MEDIUM,
				"High 200"     = PAYCHECK_HARD,
				"Command 250"  = PAYCHECK_COMMAND
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

	var/turf/T = get_turf(src)
	if(!T)
		//log_world("[src]: print_records_finish() failed — no turf found.")
		is_printing = FALSE
		return

	var/obj/item/paper/P = new /obj/item/paper(T)
	if(!P)
		//log_world("[src]: print_records_finish() failed to create paper.")
		is_printing = FALSE
		return

	P.name = "Account Report"
// ============================
// 🧾 МОД РЕЖИМОВ ПЕЧАТИ
// ============================

	switch(print_mode)
		if("details")
			var/datum/bank_account/A = detailed_account_view
			if(!A)
				P.add_raw_text("<b>Ошибка:</b> Не выбран счёт для подробного отчёта.<br>")
			else
				P.name = "Финансовый отчёт Nanotrasen"

				P.add_raw_text("<h1><div align=\"center\">ФИНАНСОВЫЙ ОТЧЁТ О СЧЁТЕ</div></h1>")
				P.add_raw_text("<hr />")
				P.add_raw_text("<p><strong>Владелец счёта:</strong> [A.account_holder]</p>")
				P.add_raw_text("<p><strong>Номер счёта:</strong> #[A.account_id]</p>")
				P.add_raw_text("<p><strong>Баланс:</strong> [A.account_balance] кредитов</p>")
				P.add_raw_text("<p><strong>Статус счёта:</strong> [(A.transferable ? "Активен" : "Заморожен")]</p>")

				if(A.suspicious_activity)
					P.add_raw_text("<p><font color=\"red\"><strong>⚠ Подозрительная активность:</strong> [A.suspicion_reason]</font></p>")

				P.add_raw_text("<hr />")
				P.add_raw_text("<p><strong>Дата формирования отчёта:</strong> [GLOB.current_date_string]</p>")
				P.add_raw_text("<p><strong>Источник:</strong> [src.name]</p>")
				P.add_raw_text("<p><strong>Авторизация терминала:</strong> [usr ? usr.real_name : "N/A"]</p>")
				P.add_raw_text("<hr />")

				P.add_raw_text("<p><strong><div align=\"center\">Печати</strong></div></p>")
				P.add_raw_text("<p><strong>Место для печатей:</strong></p>")
				P.add_raw_text("<hr />")

				P.add_raw_text("<font color=\"grey\"><div align=\"justify\">Данный отчёт составлен автоматически системой Nanotrasen Financial Uplink.")
				P.add_raw_text("Считается действительным только при наличии печати станции.</div></font>")
				var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
				P.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 300, 1, "stamp-machine")
				P.add_raw_text("<div align='center'><i>This document has been automatically stamped by the Accounts Database system.</i></div>")
				P.update_icon()

		// вот здесь закончился блок DETAILS, теперь начинается LIST 👇
		if("list")
			P.name = "Сводный финансовый отчёт"

			P.add_raw_text("<h1><div align=\"center\">СВОДНЫЙ ФИНАНСОВЫЙ ОТЧЁТ</div></h1>")
			P.add_raw_text("<hr />")
			P.add_raw_text("<p><strong>Описание:</strong> Автоматически сгенерированный отчёт о состоянии всех активных и замороженных счетов станции Nanotrasen.</p>")
			P.add_raw_text("<p><strong>Источник данных:</strong> Финансовый терминал станции #[GLOB.num_financial_terminals]</p>")
			P.add_raw_text("<p><strong>Дата формирования:</strong> [GLOB.current_date_string]</p>")
			P.add_raw_text("<hr />")

			var/list/all_accounts = GLOB.all_money_accounts

			//log_world("[src]: print_records_finish(list) — using GLOB.all_money_accounts ([length(all_accounts)] accounts total)")

			if(!all_accounts || !length(all_accounts))
				P.add_raw_text("<p><i>Не найдено активных счетов.</i></p>")
			else
				P.add_raw_text("<p><strong>Список счетов:</strong></p>")
				P.add_raw_text("<table border='1' width='100%' style='border-collapse: collapse; border: 1px solid #555;'>\n")
				P.add_raw_text("<tr style='background-color:#e6e6e6;'>\n")
				P.add_raw_text("<th width='5%'>№</th>\n")
				P.add_raw_text("<th width='35%'>Владелец</th>\n")
				P.add_raw_text("<th width='20%'>ID</th>\n")
				P.add_raw_text("<th width='20%'>Баланс</th>\n")
				P.add_raw_text("<th width='20%'>Статус</th>\n")
				P.add_raw_text("</tr>\n")

				var/i = 1
				for (var/datum/bank_account/ACC in all_accounts)
					P.add_raw_text("<tr>\n")
					P.add_raw_text("<td align='center'>[i]</td>\n")
					P.add_raw_text("<td>[ACC.account_holder]</td>\n")
					P.add_raw_text("<td align='center'>#[ACC.account_id]</td>\n")
					P.add_raw_text("<td align='right'>[ACC.account_balance]</td>\n")
					P.add_raw_text("<td align='center'>[(ACC.transferable ? "Активен" : "Заморожен")]</td>\n")
					P.add_raw_text("</tr>\n")
					i++

					P.add_raw_text("</table><br>\n")

				var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
				P.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 600, 1, "stamp-machine")
				P.add_raw_text("<div align='center'><i>This document has been automatically stamped by the Accounts Database system.</i></div>")
				P.update_icon()

			P.add_raw_text("<font color=\"grey\"><div align=\"justify\">Данный отчёт составлен автоматически системой Nanotrasen Financial Uplink. ")

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
