/atom/proc/investigate_log(message, subject)
	if(!message || !subject)
		return
	//Раньше тут на КАЖДУЮ строку создавался файловый датум и делалась синхронная запись
	//мимо rust-g. Пишем тем же буферизованным логгером, что и весь остальной репозиторий;
	//формат отключён, потому что метку времени мы ставим свою, внутри разметки
	WRITE_LOG_NO_FORMAT("[GLOB.log_directory]/[subject].html", "<small>[TIME_STAMP("hh:mm:ss", FALSE)] [REF(src)] ([x],[y],[z])</small> || [src] [message]<br>")

/client/proc/investigate_show()
	set name = "Investigate"
	set category = "Admin.Game"
	if(!holder)
		return

	//Логи уходят в буфер rust-g, и хвост файла может ещё не лежать на диске - без сброса
	//админ увидел бы обрезанный лог или вовсе счёл его пустым. Отдельного флаша у rust-g
	//нет, только закрытие всех хендлов; они переоткроются сами на следующей записи,
	//файлы открываются на дозапись
	rustg_log_close_all()

	var/list/investigates = list(INVESTIGATE_RCD, INVESTIGATE_RESEARCH, INVESTIGATE_EXONET, INVESTIGATE_PORTAL, INVESTIGATE_SINGULO, INVESTIGATE_WIRES, INVESTIGATE_TELESCI, INVESTIGATE_GRAVITY, INVESTIGATE_RECORDS, INVESTIGATE_CARGO, INVESTIGATE_SUPERMATTER, INVESTIGATE_HYPERTORUS, INVESTIGATE_ATMOS, INVESTIGATE_EXPERIMENTOR, INVESTIGATE_BOTANY, INVESTIGATE_HALLUCINATIONS, INVESTIGATE_RADIATION, INVESTIGATE_CIRCUIT, INVESTIGATE_NANITES, INVESTIGATE_CRYOGENICS)

	var/list/logs_present = list("notes, memos, watchlist")
	var/list/logs_missing = list("---")

	for(var/subject in investigates)
		var/temp_file = file("[GLOB.log_directory]/[subject].html")
		if(fexists(temp_file))
			logs_present += subject
		else
			logs_missing += "[subject] (empty)"

	var/list/combined = sort_list(logs_present) + sort_list(logs_missing)

	var/selected = input("Investigate what?", "Investigate") as null|anything in combined

	if(!(selected in combined) || selected == "---")
		return

	selected = replacetext(selected, " (empty)", "")

	if(selected == "notes, memos, watchlist" && check_rights(R_ADMIN))
		browse_messages()
		return

	var/F = file("[GLOB.log_directory]/[selected].html")
	if(!fexists(F))
		to_chat(src, "<span class='danger'>No [selected] logfile was found.</span>", confidential = TRUE)
		return
	var/datum/browser/popup = new(src, "investigate[ckey(selected)]", "Investigate: [selected]", 800, 300)
	popup.set_content(file2text(F))
	popup.open(FALSE)
