#define SEC_DATA_R_LIST		1
#define SEC_DATA_MAINT		2
#define SEC_DATA_RECORD		3
#define SEC_DATA_LOGS		4

/obj/machinery/computer/secure_data
	name = "security records console"
	desc = "Used to view and edit personnel's security records."
	icon_screen = "security"
	icon_keyboard = "security_key"
	req_one_access = list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS)
	circuit = /obj/item/circuitboard/computer/secure_data
	/// Current screen page
	var/screen = SEC_DATA_R_LIST
	/// Active general record
	var/datum/data/record/active1 = null
	/// Active security record
	var/datum/data/record/active2 = null
	/// Temporary notice for UI
	var/list/temp = null
	/// Whether the console is currently printing
	var/printing = FALSE

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/secure_data/syndie
	icon_keyboard = "syndie_key"

/obj/machinery/computer/secure_data/laptop
	name = "security laptop"
	desc = "A cheap Nanotrasen security laptop, it functions as a security records console. It's bolted to the table."
	icon_state = "laptop"
	icon_screen = "seclaptop"
	icon_keyboard = "laptop_key"
	clockwork = TRUE
	pass_flags = PASSTABLE

/obj/machinery/computer/secure_data/Destroy()
	active1 = null
	active2 = null
	return ..()

/obj/machinery/computer/secure_data/attackby(obj/item/O, mob/user, params)
	if(ui_login_attackby(O, user))
		add_fingerprint(user)
		return
	return ..()

/obj/machinery/computer/secure_data/AltClick(mob/user)
	. = ..()
	if(!can_interact(user))
		return
	ui_login_eject()

/obj/machinery/computer/secure_data/ui_interact(mob/user, datum/tgui/ui)
	if(is_away_level(z))
		to_chat(user, span_boldannounce("Unable to establish a connection") + ": You're too far away from the station!")
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SecurityRecords", name)
		ui.open()
	ui.set_autoupdate(FALSE)

/obj/machinery/computer/secure_data/ui_login_on_login(datum/ui_login/state)
	screen = SEC_DATA_R_LIST
	active1 = null
	active2 = null

/obj/machinery/computer/secure_data/ui_data(mob/user)
	var/list/data = list()
	data["temp"] = temp
	data["currentPage"] = screen
	data["isPrinting"] = printing
	ui_login_data(data, user)

	if(data["loginState"]["logged_in"])
		var/datum/ui_login/state = ui_login_get()
		data["canDeleteLogs"] = (ACCESS_HOS in state.access)
		data["canDeleteAll"] = ((ACCESS_HOS in state.access) || (ACCESS_CAPTAIN in state.access))
		data["canEditRank"] = ((ACCESS_CAPTAIN in state.access) || (ACCESS_HOP in state.access) || (ACCESS_CENT_GENERAL in state.access))
		data["hasCentcomAuth"] = (ACCESS_CENT_CAPTAIN in state.access)

		switch(screen)
			if(SEC_DATA_R_LIST)
				var/list/sec_records_assoc = list()
				for(var/datum/data/record/S in GLOB.data_core.security)
					sec_records_assoc["[S.fields["name"]]|[S.fields["id"]]"] = S
				var/list/records = list()
				data["records"] = records
				for(var/datum/data/record/G in GLOB.data_core.general)
					var/datum/data/record/S = sec_records_assoc["[G.fields["name"]]|[G.fields["id"]]"]
					var/thumb = null
					if(istype(G.fields["photo_front"], /obj/item/photo))
						var/obj/item/photo/P = G.fields["photo_front"]
						if(P.picture?.picture_image)
							thumb = icon2base64(P.picture.picture_image)
					else if(isicon(G.fields["photo_front"]))
						thumb = icon2base64(G.fields["photo_front"])
					var/list/record_line = list(
						"ref" = "\ref[G]",
						"id" = G.fields["id"],
						"name" = G.fields["name"],
						"rank" = G.fields["rank"],
						"fingerprint" = G.fields["fingerprint"],
						"status" = S?.fields["criminal"] || "Нет записи",
						"thumb" = thumb,
					)
					records[++records.len] = record_line

			if(SEC_DATA_LOGS)
				var/list/all_logs = list()
				for(var/datum/data/record/S in GLOB.data_core.security)
					var/list/logs = S.fields["actions_logs"]
					if(!islist(logs) || !length(logs))
						continue
					for(var/log_entry in logs)
						all_logs += list(list(
							"name" = S.fields["name"],
							"id" = S.fields["id"],
							"text" = log_entry,
						))
				data["allLogs"] = all_logs
			if(SEC_DATA_RECORD)
				var/list/general = list()
				data["general"] = general
				if(istype(active1, /datum/data/record) && GLOB.data_core.general.Find(active1))
					general["empty"] = FALSE
					general["name"] = active1.fields["name"]
					general["id"] = active1.fields["id"]
					general["gender"] = active1.fields["gender"]
					general["age"] = active1.fields["age"]
					general["species"] = active1.fields["species"]
					general["rank"] = active1.fields["rank"]
					general["fingerprint"] = active1.fields["fingerprint"]
					general["p_stat"] = active1.fields["p_stat"]
					general["m_stat"] = active1.fields["m_stat"]
					var/list/photos = list()
					general["photos"] = photos
					if(istype(active1.fields["photo_front"], /obj/item/photo))
						var/obj/item/photo/P = active1.fields["photo_front"]
						if(P.picture?.picture_image)
							photos["front"] = icon2base64(P.picture.picture_image)
					else if(isicon(active1.fields["photo_front"]))
						photos["front"] = icon2base64(active1.fields["photo_front"])
					if(istype(active1.fields["photo_side"], /obj/item/photo))
						var/obj/item/photo/P = active1.fields["photo_side"]
						if(P.picture?.picture_image)
							photos["side"] = icon2base64(P.picture.picture_image)
					else if(isicon(active1.fields["photo_side"]))
						photos["side"] = icon2base64(active1.fields["photo_side"])
				else
					general["empty"] = TRUE

				var/list/security = list()
				data["security"] = security
				if(istype(active2, /datum/data/record) && GLOB.data_core.security.Find(active2))
					security["empty"] = FALSE
					security["criminal"] = active2.fields["criminal"]
					security["notes"] = active2.fields["notes"]

					var/list/minor_crimes = list()
					for(var/datum/data/crime/c in active2.fields["mi_crim"])
						minor_crimes[++minor_crimes.len] = list(
							"name" = c.crimeName,
							"details" = c.crimeDetails,
							"author" = c.author,
							"time" = c.time,
							"dataId" = c.dataId,
							"centcom" = c.centcom_enforced,
							"incurred" = c.penalties_incurred,
						)
					security["mi_crim"] = minor_crimes

					var/list/major_crimes = list()
					for(var/datum/data/crime/c in active2.fields["ma_crim"])
						major_crimes[++major_crimes.len] = list(
							"name" = c.crimeName,
							"details" = c.crimeDetails,
							"author" = c.author,
							"time" = c.time,
							"dataId" = c.dataId,
							"centcom" = c.centcom_enforced,
							"incurred" = c.penalties_incurred,
						)
					security["ma_crim"] = major_crimes

					var/list/logs = active2.fields["actions_logs"]
					security["logs"] = logs || list()

					var/list/comments = list()
					var/counter = 1
					while(active2.fields["com_[counter]"])
						comments[++comments.len] = list(
							"id" = counter,
							"text" = active2.fields["com_[counter]"],
							"deleted" = (active2.fields["com_[counter]"] == "<B>Deleted</B>"),
						)
						counter++
					security["comments"] = comments
				else
					security["empty"] = TRUE

	return data

/obj/machinery/computer/secure_data/ui_act(action, list/params)
	if(..())
		return
	if(machine_stat & (NOPOWER|BROKEN))
		return

	if(!GLOB.data_core.general.Find(active1))
		active1 = null
	if(!GLOB.data_core.security.Find(active2))
		active2 = null

	. = TRUE
	if(ui_login_act(action, params))
		return

	var/datum/ui_login/login_state = ui_login_get()
	var/logged_in = login_state.logged_in

	switch(action)
		if("cleartemp")
			temp = null
		if("page")
			if(!logged_in)
				return
			screen = clamp(text2num(params["page"]) || SEC_DATA_R_LIST, SEC_DATA_R_LIST, SEC_DATA_LOGS)
			active1 = null
			active2 = null
		if("view")
			if(!logged_in)
				return
			var/datum/data/record/G = locate(params["ref"]) in GLOB.data_core.general
			if(!G)
				set_temp("Запись не найдена!", "danger")
				return
			active1 = G
			active2 = null
			for(var/datum/data/record/E in GLOB.data_core.security)
				if(E.fields["name"] == G.fields["name"] && E.fields["id"] == G.fields["id"])
					active2 = E
					break
			screen = SEC_DATA_RECORD
		if("back")
			if(!logged_in)
				return
			screen = SEC_DATA_R_LIST
			active1 = null
			active2 = null
		if("new_general")
			if(!logged_in)
				return
			var/datum/data/record/G = new /datum/data/record()
			G.fields["name"] = "New Record"
			G.fields["id"] = "[num2hex(rand(1, 1.6777215E7), 6)]"
			G.fields["rank"] = "Unassigned"
			G.fields["gender"] = "Male"
			G.fields["age"] = "Unknown"
			G.fields["species"] = "Human"
			G.fields["photo_front"] = new /icon()
			G.fields["photo_side"] = new /icon()
			G.fields["fingerprint"] = "?????"
			G.fields["p_stat"] = "Active"
			G.fields["m_stat"] = "Stable"
			GLOB.data_core.general += G
			active1 = G

			var/datum/data/record/R = new /datum/data/record()
			R.fields["name"] = active1.fields["name"]
			R.fields["id"] = active1.fields["id"]
			R.name = "Security Record #[R.fields["id"]]"
			R.fields["criminal"] = SEC_RECORD_STATUS_NONE
			R.fields["mi_crim"] = list()
			R.fields["ma_crim"] = list()
			R.fields["notes"] = "No notes."
			R.fields["actions_logs"] = list(
				"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЗАПИСЬ НАЧАТА. СУБЪЕКТ - [active1.fields["name"]] | N/A | [active1.fields["id"]] -- ИНИЦИАТОР: [login_state.name] ([login_state.rank]);</u><br>"
			)
			GLOB.data_core.security += R
			active2 = R

			var/datum/data/record/M = new /datum/data/record()
			M.fields["id"] = active1.fields["id"]
			M.fields["name"] = active1.fields["name"]
			M.fields["blood_type"] = "?"
			M.fields["b_dna"] = "?????"
			M.fields["mi_dis"] = "None"
			M.fields["mi_dis_d"] = "No minor disabilities have been declared."
			M.fields["ma_dis"] = "None"
			M.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
			M.fields["alg"] = "None"
			M.fields["alg_d"] = "No allergies have been detected in this patient."
			M.fields["cdi"] = "None"
			M.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
			M.fields["notes"] = "No notes."
			GLOB.data_core.medical += M

			screen = SEC_DATA_RECORD
			set_temp("Запись создана.", "success")
		if("new_security")
			if(!logged_in || !active1 || active2)
				return
			var/datum/data/record/R = new /datum/data/record()
			R.fields["name"] = active1.fields["name"]
			R.fields["id"] = active1.fields["id"]
			R.name = "Security Record #[R.fields["id"]]"
			R.fields["criminal"] = SEC_RECORD_STATUS_NONE
			R.fields["mi_crim"] = list()
			R.fields["ma_crim"] = list()
			R.fields["notes"] = "No notes."
			R.fields["actions_logs"] = list(
				"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЗАПИСЬ НАЧАТА. СУБЪЕКТ - [active1.fields["name"]] | N/A | [active1.fields["id"]] -- ИНИЦИАТОР: [login_state.name] ([login_state.rank]);</u><br>"
			)
			GLOB.data_core.security += R
			active2 = R
			set_temp("Запись безопасности создана.", "success")
		if("delete_general")
			if(!logged_in || !active1)
				return
			investigate_log("[key_name(usr)] has deleted all records for [active1.fields["name"]].", INVESTIGATE_RECORDS)
			for(var/datum/data/record/R in GLOB.data_core.medical)
				if(R.fields["name"] == active1.fields["name"] && R.fields["id"] == active1.fields["id"])
					qdel(R)
					break
			qdel(active1)
			active1 = null
			if(active2)
				qdel(active2)
				active2 = null
			screen = SEC_DATA_R_LIST
			update_all_mob_security_hud()
			set_temp("Все записи удалены.")
		if("delete_security")
			if(!logged_in || !active2)
				return
			investigate_log("[key_name(usr)] has deleted the security records for [active1?.fields["name"]].", INVESTIGATE_RECORDS)
			qdel(active2)
			active2 = null
			update_all_mob_security_hud()
			set_temp("Запись безопасности удалена.")
		if("delete_security_all")
			if(!logged_in || !((ACCESS_HOS in login_state.access) || (ACCESS_CAPTAIN in login_state.access)))
				set_temp("Недостаточно полномочий: необходим доступ ГСБ или Капитана.", "danger")
				return
			investigate_log("[key_name(usr)] has purged all the security records.", INVESTIGATE_RECORDS)
			for(var/datum/data/record/R in GLOB.data_core.security)
				qdel(R)
			GLOB.data_core.security.Cut()
			set_temp("Все записи безопасности удалены.")
		if("set_criminal")
			if(!logged_in || !active2)
				return
			var/new_status = params["status"]
			if(!(new_status in list(SEC_RECORD_STATUS_NONE, SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_EXECUTE, SEC_RECORD_STATUS_INCARCERATED, SEC_RECORD_STATUS_RELEASED, SEC_RECORD_STATUS_PAROLLED, SEC_RECORD_STATUS_DEMOTE, SEC_RECORD_STATUS_SEARCH, SEC_RECORD_STATUS_MONITOR, SEC_RECORD_STATUS_DISCHARGED)))
				return
			var/reason = params["reason"] || ""
			if(new_status in list(SEC_RECORD_STATUS_EXECUTE, SEC_RECORD_STATUS_DEMOTE))
				if(!length(reason))
					set_temp("Необходимо указать причину для данного статуса!", "danger")
					return
			if(!set_criminal_status(usr, active2, new_status, reason, login_state.rank, login_state.access, login_state.name))
				set_temp("Недостаточно полномочий для установки данного статуса!", "danger")
				return
		if("edit_field")
			if(!logged_in)
				return
			var/field = params["field"]
			var/new_value = params["value"]
			if(!field || !length(new_value))
				return
			switch(field)
				if("name")
					if(!active1)
						return
					new_value = stripped_input(usr, "Введите имя:", "Записи безопасности", active1.fields["name"], MAX_MESSAGE_LEN)
					if(!length(new_value) || !can_use_console(usr))
						return
					GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% сменил поле \"имя\" с [active1.fields["name"]] на [new_value]", login_state.name, login_state.rank)
					active1.fields["name"] = new_value
					if(active2)
						active2.fields["name"] = new_value
				if("id")
					if(!active1)
						return
					new_value = stripped_input(usr, "Введите ID:", "Записи безопасности", active1.fields["id"])
					if(!length(new_value) || !can_use_console(usr))
						return
					GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% сменил поле \"ID\" с [active1.fields["id"]] на [new_value]", login_state.name, login_state.rank)
					active1.fields["id"] = new_value
					if(active2)
						active2.fields["id"] = new_value
				if("gender")
					if(!active1)
						return
					var/old_val = active1.fields["gender"]
					if(old_val == "Male")
						active1.fields["gender"] = "Female"
					else if(old_val == "Female")
						active1.fields["gender"] = "Other"
					else
						active1.fields["gender"] = "Male"
					GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% сменил поле \"гендер\" с [old_val] на [active1.fields["gender"]]", login_state.name, login_state.rank)
				if("age")
					if(!active1)
						return
					new_value = input(usr, "Введите возраст:", "Записи безопасности", active1.fields["age"]) as num|null
					if(isnull(new_value) || !can_use_console(usr))
						return
					GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% сменил поле \"возраст\" с [active1.fields["age"]] на [new_value]", login_state.name, login_state.rank)
					active1.fields["age"] = new_value
				if("species")
					if(!active1)
						return
					new_value = stripped_input(usr, "Введите название вида:", "Записи безопасности", active1.fields["species"])
					if(!length(new_value) || !can_use_console(usr))
						return
					GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% сменил поле \"вид\" с [active1.fields["species"]] на [new_value]", login_state.name, login_state.rank)
					active1.fields["species"] = new_value
				if("fingerprint")
					if(!active1)
						return
					new_value = stripped_input(usr, "Введите хэш отпечатков:", "Записи безопасности", active1.fields["fingerprint"])
					if(!length(new_value) || !can_use_console(usr))
						return
					GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% сменил поле \"отпечаток\" с [active1.fields["fingerprint"]] на [new_value]", login_state.name, login_state.rank)
					active1.fields["fingerprint"] = new_value
				if("notes")
					if(!active2)
						return
					new_value = stripped_multiline_input(usr, "Введите заметки:", "Записи безопасности", active2.fields["notes"], 8192)
					if(!length(new_value) || !can_use_console(usr))
						return
					active2.fields["notes"] = new_value
					GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% изменил служебные заметки субъекта", login_state.name, login_state.rank)
				if("rank")
					if(!active1 || !((ACCESS_CAPTAIN in login_state.access) || (ACCESS_HOP in login_state.access) || (ACCESS_CENT_GENERAL in login_state.access)))
						set_temp("Недостаточно полномочий!", "danger")
						return
					var/new_rank = params["value"]
					if(GetJobName(new_rank) != "Unknown" && GetJobName(new_rank) != "Centcom")
						active1.fields["rank"] = new_rank
						active1.fields["real_rank"] = GetJobName(new_rank)
		if("mi_crim_add")
			if(!logged_in || !active1 || !active2)
				return
			var/cname = stripped_input(usr, "Название правонарушения:", "Записи безопасности", "")
			if(!length(cname) || !can_use_console(usr))
				return
			var/cdetails = stripped_input(usr, "Подробности:", "Записи безопасности", "")
			if(!can_use_console(usr))
				return
			var/centcom_authority = (ACCESS_CENT_CAPTAIN in login_state.access)
			var/crime = GLOB.data_core.createCrimeEntry(cname, cdetails, login_state.name, STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), centcom_authority)
			GLOB.data_core.addMinorCrime(active1.fields["id"], crime)
			GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% записал некрупное преступление: <b>[cname]</b>, [cdetails]", login_state.name, login_state.rank)
			investigate_log("New Minor Crime: <strong>[cname]</strong>: [cdetails] | Added to [active1.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
		if("ma_crim_add")
			if(!logged_in || !active1 || !active2)
				return
			var/cname = stripped_input(usr, "Название правонарушения:", "Записи безопасности", "")
			if(!length(cname) || !can_use_console(usr))
				return
			var/cdetails = stripped_input(usr, "Подробности:", "Записи безопасности", "")
			if(!can_use_console(usr))
				return
			var/centcom_authority = (ACCESS_CENT_CAPTAIN in login_state.access)
			var/crime = GLOB.data_core.createCrimeEntry(cname, cdetails, login_state.name, STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), centcom_authority)
			GLOB.data_core.addMajorCrime(active1.fields["id"], crime)
			GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% записал крупное преступление: <b>[cname]</b>, [cdetails]", login_state.name, login_state.rank)
			investigate_log("New Major Crime: <strong>[cname]</strong>: [cdetails] | Added to [active1.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
		if("mi_crim_delete")
			if(!logged_in || !active1 || !active2)
				return
			var/cdataid = params["cdataid"]
			if(!cdataid)
				return
			var/centcom_authority = (ACCESS_CENT_CAPTAIN in login_state.access)
			GLOB.data_core.removeMinorCrime(active1.fields["id"], cdataid, centcom_authority)
			GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% удалил некрупное преступление №[cdataid]", login_state.name, login_state.rank)
		if("ma_crim_delete")
			if(!logged_in || !active1 || !active2)
				return
			var/cdataid = params["cdataid"]
			if(!cdataid)
				return
			var/centcom_authority = (ACCESS_CENT_CAPTAIN in login_state.access)
			GLOB.data_core.removeMajorCrime(active1.fields["id"], cdataid, centcom_authority)
			GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% удалил крупное преступление №[cdataid]", login_state.name, login_state.rank)
		if("crim_incur_switch")
			if(!logged_in || !active1 || !active2)
				return
			var/cdataid = params["cdataid"]
			if(!cdataid)
				return
			GLOB.data_core.switch_incur(active1.fields["id"], cdataid)
			GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% изменил пометку \"НАКАЗАНИЕ ПОНЕСЕНО\" у преступления №[cdataid]", login_state.name, login_state.rank)
		if("add_comment")
			if(!logged_in || !active2)
				return
			var/t1 = stripped_multiline_input(usr, "Добавить комментарий:", "Записи безопасности")
			if(!length(t1) || !can_use_console(usr))
				return
			var/counter = 1
			while(active2.fields["com_[counter]"])
				counter++
			active2.fields["com_[counter]"] = "Made by [login_state.name] ([login_state.rank]) on [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] [time2text(world.realtime, "MMM DD")] [GLOB.year_integer]<BR>[t1]"
		if("delete_comment")
			if(!logged_in || !active2)
				return
			var/del_c = text2num(params["id"])
			if(!del_c || !active2.fields["com_[del_c]"])
				return
			active2.fields["com_[del_c]"] = "<B>Deleted</B>"
		if("print_record")
			if(!logged_in || printing)
				return
			printing = TRUE
			playsound(loc, 'sound/items/poster_being_created.ogg', 100, TRUE)
			addtimer(CALLBACK(src, PROC_REF(print_record_finish)), 3 SECONDS)
		if("print_logs")
			if(!logged_in || printing || !active1 || !active2)
				return
			if(!can_use_console(usr))
				return
			printing = TRUE
			playsound(loc, 'sound/items/poster_being_created.ogg', 100, TRUE)
			addtimer(CALLBACK(src, PROC_REF(print_logs_finish)), 3 SECONDS)
		if("delete_logs")
			if(!logged_in || !active2)
				return
			if(!(ACCESS_HOS in login_state.access))
				set_temp("Недостаточно полномочий: необходим доступ ГСБ.", "danger")
				return
			active2.fields["actions_logs"] = list(
				"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЛОГИ ОЧИЩЕНЫ УПРАВЛЯЮЩИМ [login_state.name] | [login_state.rank];</u><br>"
			)
		if("print_poster")
			if(!logged_in || printing || !active1 || !active2)
				return
			var/wanted_name = stripped_input(usr, "Введите имя для розыскного плаката:", "Розыскной плакат", active1.fields["name"])
			if(!wanted_name || !can_use_console(usr))
				return
			var/default_description = "Плакат объявляет [wanted_name] опасным лицом, разыскиваемым Nanotrasen. Немедленно сообщайте о любых наблюдениях в службу безопасности."
			var/list/major_crimes = active2.fields["ma_crim"]
			var/list/minor_crimes = active2.fields["mi_crim"]
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
			var/info = stripped_multiline_input(usr, "Введите описание для плаката:", "Розыскной плакат", default_description)
			if(!info || !can_use_console(usr))
				return
			printing = TRUE
			playsound(loc, 'sound/items/poster_being_created.ogg', 100, TRUE)
			addtimer(CALLBACK(src, PROC_REF(print_poster_finish), wanted_name, info), 3 SECONDS)
		if("generate_warrant")
			if(!logged_in || printing || !active1 || !active2)
				return
			if(!can_use_console(usr))
				return
			var/list/crimes = active2.fields["ma_crim"] + active2.fields["mi_crim"]
			if(!length(crimes))
				set_temp("Правонарушения отсутствуют!", "danger")
				return
			printing = TRUE
			playsound(loc, 'sound/items/poster_being_created.ogg', 100, TRUE)
			addtimer(CALLBACK(src, PROC_REF(print_warrant_finish)), 3 SECONDS)
		if("upd_photo")
			if(!logged_in || !active1)
				return
			var/side = params["side"]
			if(!(side in list("front", "side")))
				return
			var/obj/item/photo/photo = get_photo(usr)
			if(!photo)
				return
			var/field_name = "photo_[side]"
			qdel(active1.fields[field_name])
			var/icon/I = photo.picture.picture_image
			var/w = I.Width()
			var/h = I.Height()
			var/dw = w - 32
			var/dh = h - 32
			I.Crop(dw/2, dh/2, w - dw/2, h - dh/2)
			active1.fields[field_name] = photo
			GLOB.data_core.append_sec_logs(active1.fields["id"], "%%GEN_AUTH%% отредактировал фотографию ([side])", login_state.name, login_state.rank)
		if("show_photo")
			if(!active1)
				return
			var/side = params["side"]
			var/field_name = "photo_[side]"
			if(istype(active1.fields[field_name], /obj/item/photo))
				var/obj/item/photo/P = active1.fields[field_name]
				P.show(usr)
		if("print_photo")
			if(!active1 || printing)
				return
			var/side = params["side"]
			var/field_name = "photo_[side]"
			if(istype(active1.fields[field_name], /obj/item/photo))
				var/obj/item/photo/P = active1.fields[field_name]
				print_photo(P.picture.picture_image, active1.fields["name"])
		if("get_jobs")
			if(!logged_in)
				return
			var/list/jobs = get_all_jobs()
			var/list/job_data = list()
			for(var/job_name in jobs)
				var/list/entry = list("name" = job_name)
				var/datum/job/JD = SSjob.name_occupations[job_name]
				if(JD && length(JD.alt_titles))
					entry["alts"] = JD.alt_titles.Copy()
				job_data[++job_data.len] = entry
			return job_data
		else
			return FALSE

	add_fingerprint(usr)

/// Check if the user can still use the console
/obj/machinery/computer/secure_data/proc/can_use_console(mob/user)
	if(!user)
		return FALSE
	var/datum/ui_login/state = ui_login_get()
	if(!state.logged_in)
		return FALSE
	if(!user.canUseTopic(src, !hasSiliconAccessInArea(user)))
		return FALSE
	return TRUE

/obj/machinery/computer/secure_data/proc/get_photo(mob/user)
	var/obj/item/photo/P = null
	if(issilicon(user))
		var/mob/living/silicon/tempAI = user
		var/datum/picture/selection = tempAI.GetPhoto(user)
		if(selection)
			P = new(null, selection)
	else if(istype(user.get_active_held_item(), /obj/item/photo))
		P = user.get_active_held_item()
	return P

/obj/machinery/computer/secure_data/proc/print_photo(icon/temp, person_name)
	if(printing)
		return
	printing = TRUE
	sleep(20)
	var/obj/item/photo/P = new/obj/item/photo(drop_location())
	var/datum/picture/toEmbed = new(name = person_name, desc = "The photo on file for [person_name].", image = temp)
	P.set_picture(toEmbed, TRUE, TRUE)
	P.pixel_x = rand(-10, 10)
	P.pixel_y = rand(-10, 10)
	printing = FALSE

/obj/machinery/computer/secure_data/proc/set_temp(text = "", style = "info")
	temp = list(text = text, style = style)
	SStgui.update_uis(src)

/obj/machinery/computer/secure_data/proc/print_record_finish()
	if(!active1 && !active2)
		printing = FALSE
		SStgui.update_uis(src)
		return
	GLOB.data_core.securityPrintCount++
	var/obj/item/paper/P = new /obj/item/paper(loc)
	var/report_text = "<CENTER><B>Security Record - (SR-[GLOB.data_core.securityPrintCount])</B></CENTER><BR>"
	if(istype(active1, /datum/data/record) && GLOB.data_core.general.Find(active1))
		report_text += "Name: [active1.fields["name"]] ID: [active1.fields["id"]]<BR>"
		report_text += "Gender: [active1.fields["gender"]]<BR>"
		report_text += "Age: [active1.fields["age"]]<BR>"
		report_text += "Species: [active1.fields["species"]]<BR>"
		report_text += "Fingerprint: [active1.fields["fingerprint"]]<BR>"
		report_text += "Physical Status: [active1.fields["p_stat"]]<BR>"
		report_text += "Mental Status: [active1.fields["m_stat"]]<BR>"
	else
		report_text += "<B>General Record Lost!</B><BR>"
	if(istype(active2, /datum/data/record) && GLOB.data_core.security.Find(active2))
		report_text += "<BR><CENTER><B>Security Data</B></CENTER><BR>"
		report_text += "Criminal Status: [active2.fields["criminal"]]<BR>"
		report_text += "<BR>Minor Crimes:<BR>"
		for(var/datum/data/crime/c in active2.fields["mi_crim"])
			report_text += "- [c.crimeName]: [c.crimeDetails] (by [c.author] at [c.time])<BR>"
		report_text += "<BR>Major Crimes:<BR>"
		for(var/datum/data/crime/c in active2.fields["ma_crim"])
			report_text += "- [c.crimeName]: [c.crimeDetails] (by [c.author] at [c.time])<BR>"
		report_text += "<BR>Important Notes: [active2.fields["notes"]]<BR>"
		report_text += "<BR><CENTER><B>Comments/Log</B></CENTER><BR>"
		var/counter = 1
		while(active2.fields["com_[counter]"])
			report_text += "[active2.fields["com_[counter]"]]<BR>"
			counter++
	else
		report_text += "<B>Security Record Lost!</B><BR>"
	if(istype(active1, /datum/data/record) && active1.fields["name"])
		P.name = "SR-[GLOB.data_core.securityPrintCount] '[active1.fields["name"]]'"
	else
		P.name = "SR-[GLOB.data_core.securityPrintCount] 'Record Lost'"
	P.add_raw_text(report_text)
	P.update_appearance()
	P.update_icon()
	printing = FALSE
	SStgui.update_uis(src)

/obj/machinery/computer/secure_data/proc/print_logs_finish()
	if(!active1 || !active2)
		printing = FALSE
		SStgui.update_uis(src)
		return
	GLOB.data_core.securityPrintCount++
	var/obj/item/paper/P = new /obj/item/paper(loc)
	var/list/logs = active2.fields["actions_logs"]
	var/log_text = {"
		<h1><div align="center">ЛОГИ ЗАПИСЕЙ | СЛУЖБА БЕЗОПАСНОСТИ</div></h1>
		<p><strong>ОБЪЕКТ:</strong> [GLOB.station_name]</p>
		<p><strong>ДАТА ЗАПРОСА:</strong> [GLOB.current_date_string]</p>
		<p><strong>ВРЕМЯ ЗАПРОСА:</strong> [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]</p>
		<p><strong>ЗАПИСЬ:</strong> [active1.fields["id"]]</p>
		<p><strong>ИМЯ СУБЪЕКТА:</strong> [active1.fields["name"]]</p>
		<hr><br><center><b>НАЧАЛО ЗАПИСИ</b></center>"}
	for(var/log in logs)
		log_text += "<br>[log]"
	log_text += "<br><br><center><b>КОНЕЦ ЗАПИСИ</b></center><hr><br>"
	P.add_raw_text(log_text)
	P.name = "Database Logs - [active1.fields["name"]] - [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
	P.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 50, 1, "stamp-machine")
	P.update_appearance()
	P.update_icon()
	printing = FALSE
	SStgui.update_uis(src)

/obj/machinery/computer/secure_data/proc/print_poster_finish(wanted_name, info)
	if(!active1 || !GLOB.data_core.general.Find(active1))
		printing = FALSE
		SStgui.update_uis(src)
		return
	var/obj/item/photo/photo = active1.fields["photo_front"]
	if(istype(photo))
		new /obj/item/poster/wanted(loc, photo.picture.picture_image, wanted_name, info)
	printing = FALSE
	SStgui.update_uis(src)

/obj/machinery/computer/secure_data/proc/print_warrant_finish()
	if(!active1 || !active2)
		printing = FALSE
		SStgui.update_uis(src)
		return
	var/datum/ui_login/login_state = ui_login_get()
	GLOB.data_core.securityPrintCount++
	var/obj/item/paper/P = new /obj/item/paper(loc)
	var/list/crimes = active2.fields["ma_crim"] + active2.fields["mi_crim"]
	var/report_text = {"
		<h1><div align="center">Ордер на арест №[GLOB.data_core.securityPrintCount]</div></h1>
		<p><strong>Задерживаемый субъект:</strong> [active1.fields["name"]]</p>
		<p><strong>Причина задержания:</strong></p>
		<p>Разыскивается службой безопасности [GLOB.station_name] в связи с нарушением статей Космического Закона:</p>"}
	for(var/datum/data/crime/c in crimes)
		if(c.penalties_incurred)
			continue
		report_text += "<p><b>[c.crimeName]</b> - [c.crimeDetails]"
		if(c.centcom_enforced)
			report_text += " <i>\[Центкомм\]</i>"
		report_text += "</p>"
	report_text += {"
		<p><strong><div align="center">Подписи и печати</div></strong></p>
		<p><strong>Подпись составителя:</strong></p>
		<p>\[________________________________________________________________\]</p>
		<p><strong>Должность составителя:</strong></p>
		<p>[login_state.rank]</p>
		<p><strong>Дата:</strong></p>
		<p>Время: [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]</p>
		<p>Дата: [time2text(world.realtime, "MMM DD")] [GLOB.year_integer]</p>
		<p><strong>Место для печатей</strong></p>
		<hr/><br><br><br><hr/>
		<font color="grey"><div align="justify">Основная часть документа сгенерирована автоматически.</div></font>
		<font color="grey"><div align="justify">Данный документ считается действительным только при наличии подписи и печати, если таковая имеется.</div></font>
		<font color="grey"><div align="justify">Данный документ имеет юридическую силу, только если составлен уполномоченным лицом.</div></font>"}
	P.add_raw_text(report_text)
	P.name = "Ордер на арест - [active1.fields["name"]]"
	P.update_appearance()
	P.update_icon()
	printing = FALSE
	SStgui.update_uis(src)

/obj/machinery/computer/secure_data/emp_act(severity)
	. = ..()
	if(machine_stat & (BROKEN|NOPOWER) || . & EMP_PROTECT_SELF)
		return
	for(var/datum/data/record/R in GLOB.data_core.security)
		if(prob(severity/10))
			switch(rand(1,8))
				if(1)
					if(prob(10))
						R.fields["name"] = "[pick(lizard_name(MALE),lizard_name(FEMALE))]"
					else
						R.fields["name"] = "[pick(pick(GLOB.first_names_male), pick(GLOB.first_names_female))] [pick(GLOB.last_names)]"
				if(2)
					R.fields["gender"] = pick("Male", "Female", "Other")
				if(3)
					R.fields["age"] = rand(5, 85)
				if(4)
					R.fields["criminal"] = pick(SEC_RECORD_STATUS_NONE, SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_INCARCERATED, SEC_RECORD_STATUS_PAROLLED, SEC_RECORD_STATUS_DISCHARGED)
				if(5)
					R.fields["p_stat"] = pick("*Unconscious*", "Active", "Physically Unfit")
				if(6)
					R.fields["m_stat"] = pick("*Insane*", "*Unstable*", "*Watch*", "Stable")
				if(7)
					R.fields["species"] = pick(GLOB.roundstart_races)
				if(8)
					var/datum/data/record/G = pick(GLOB.data_core.general)
					R.fields["photo_front"] = G.fields["photo_front"]
					R.fields["photo_side"] = G.fields["photo_side"]
			continue
		else if(prob(severity/80))
			qdel(R)
			continue

#undef SEC_DATA_R_LIST
#undef SEC_DATA_MAINT
#undef SEC_DATA_RECORD

