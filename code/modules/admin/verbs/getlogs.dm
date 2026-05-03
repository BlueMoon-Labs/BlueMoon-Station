//This proc allows download of past server logs saved within the data/logs/ folder.
/client/proc/getserverlogs()
	set name = "Get Server Logs"
	set desc = "View/retrieve logfiles."
	set category = "Admin"

	browseserverlogs()

/client/proc/getcurrentlogs()
	set name = "Get Current Logs"
	set desc = "View/retrieve logfiles for the current round."
	set category = "Admin"

	browseserverlogs("[GLOB.log_directory]/")

/client/proc/browseserverlogs(path = "data/logs/")
	if(!check_rights(R_SENSITIVE))
		return
	path = browse_files(path)
	if(!path)
		return

	if(file_spam_check())
		return

	message_admins("[key_name_admin(src)] accessed file: [path]")
	switch(alert("View (in game), Open (in your system's text editor), or Download?", path, "View", "Open", "Download"))
		if ("View")
			if(!is_safe_path_for_admin_shell(path))
				to_chat(src, span_warning("Просмотр в игре недоступен: в пути есть небезопасные символы. Используйте Open или Download."), confidential = TRUE)
				return
			var/file_bytes = get_admin_log_file_size_bytes(path)
			var/preview = read_admin_log_preview(path)
			if(isnull(preview))
				to_chat(src, span_warning("Не удалось сформировать превью лога (ошибка чтения или окружения). Используйте Open или Download."), confidential = TRUE)
				return
			var/list/header = list()
			if(file_bytes >= 0 && file_bytes > (512 * 1024))
				header += "<p><b>Внимание:</b> в превью только первые ~512 КиБ из [round(file_bytes / 1024)] КиБ. Полный файл — через Open или Download.</p>"
			else if(length(preview) >= (512 * 1024))
				header += "<p><b>Внимание:</b> показано ограниченное превью (~512 КиБ). Полный файл — через Open или Download.</p>"
			var/datum/browser/popup = new(src, "viewfile_[ckey(path)]", "File: [path]")
			popup.set_content("[header.Join()]\n<pre style='word-wrap: break-word;'>[html_encode(preview)]</pre>")
			popup.open(FALSE)
		if ("Open")
			src << run(file(path))
		if ("Download")
			src << ftp(file(path))
		else
			return
	to_chat(src, "Attempting to send [path], this may take a fair few minutes if the file is very large.", confidential = TRUE)
	return
