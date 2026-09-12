#define PLAYER_SAVE_PREVIEW_MAX_BYTES (1024 * 1024)

/// Путь строится только из нормализованного ckey, без пользовательских частей пути.
/proc/player_save_debug_directory(player_key)
	var/player_ckey = ckey(player_key)
	if(!length(player_ckey))
		return null
	return "data/player_saves/[player_ckey[1]]/[player_ckey]/"

/// Относительные пути нужны и для выбора файла, и для сохранения структуры при разборе бага.
/proc/player_save_debug_files(directory, prefix = "", depth = 0)
	var/list/result = list()
	for(var/entry in flist("[directory][prefix]"))
		if(findtext(entry, "\\") || findtext(entry, ".."))
			continue
		if(copytext(entry, -1) == "/")
			if(depth < 2 && !findtext(copytext(entry, 1, -1), "/"))
				result += player_save_debug_files(directory, "[prefix][entry]", depth + 1)
			continue
		if(findtext(entry, "/"))
			continue
		if(copytext(entry, -4) == ".sav" || copytext(entry, -10) == ".updatebac" || copytext(entry, -5) == ".json" || copytext(entry, -14) == ".json.recovery")
			result += "[prefix][entry]"
	return sort_list(result)

/// JSON читается как текст даже при повреждении. Старый savefile открывается только на копии.
/proc/player_save_debug_text(source_path)
	if(!fexists(source_path))
		throw EXCEPTION("Файл больше не существует.")
	if(length(file(source_path)) > PLAYER_SAVE_PREVIEW_MAX_BYTES)
		throw EXCEPTION("Файл больше 1 МиБ. Скачайте его для просмотра целиком.")
	if(copytext(source_path, -5) == ".json" || copytext(source_path, -14) == ".json.recovery")
		return file2text(source_path)
	var/static/sequence = 0
	var/temp_directory = "data/player_save_debug/[world.realtime]_[++sequence]/"
	var/temp_path = "[temp_directory]preview.sav"
	var/result
	var/savefile/copy
	try
		if(!fcopy(source_path, temp_path))
			throw EXCEPTION("Не удалось создать копию для просмотра.")
		copy = new(temp_path)
		result = copy.ExportText("/")
		copy = null
	catch(var/exception/failure)
		copy = null
		fdel(temp_directory)
		throw failure
	fdel(temp_directory)
	return result

/client/proc/inspect_player_saves()
	set name = "Inspect Player Saves"
	set category = "Debug.2) Info"
	set desc = "Просмотр и скачивание сохранённых файлов игрока по ckey."

	if(!check_rights_for(src, R_DEBUG))
		return
	var/player_key = input(src, "Введите ckey игрока; присутствие на сервере не требуется.", "Сейвы игрока") as null|text
	if(!check_rights_for(src, R_DEBUG))
		return
	var/directory = player_save_debug_directory(player_key)
	if(!directory)
		return
	var/player_ckey = ckey(player_key)
	while(check_rights_for(src, R_DEBUG))
		var/list/files = player_save_debug_files(directory)
		if(!length(files))
			to_chat(src, span_warning("У [player_ckey] не найдено файлов сохранений."))
			return
		var/selected = input(src, "Файлы [player_ckey] на диске. Несохранённые изменения в меню сюда не входят. Для полного JSON-сейва нужны корень, .recovery и каталог .d/.", "Сейвы игрока") as null|anything in files
		if(!selected || !check_rights_for(src, R_DEBUG))
			return
		if(!(selected in files))
			return
		var/action = input(src, "[player_ckey]: [selected]", "Сейвы игрока") as null|anything in list("Просмотреть", "Скачать исходник")
		if(!check_rights_for(src, R_DEBUG))
			return
		if(!action)
			continue
		// После диалогов файл мог исчезнуть. Пути всегда берём из серверного списка.
		if(!(selected in player_save_debug_files(directory)))
			to_chat(src, span_warning("Файл больше не существует."))
			continue
		var/source_path = "[directory][selected]"
		log_admin("[key_name(src)] запросил сейв [player_ckey]: [selected] ([action]).")
		if(action == "Скачать исходник")
			var/resource = fcopy_rsc(source_path)
			if(!resource)
				to_chat(src, span_warning("Не удалось прочитать файл."))
				continue
			src << ftp(resource, "[player_ckey]-[replacetext(selected, "/", "--")]")
			continue
		var/preview
		try
			preview = player_save_debug_text(source_path)
		catch(var/exception/failure)
			to_chat(src, span_warning("Просмотр не выполнен: [html_encode(failure.name)]"))
			continue
		var/truncated = length(preview) > PLAYER_SAVE_PREVIEW_MAX_BYTES
		preview = copytext(preview, 1, PLAYER_SAVE_PREVIEW_MAX_BYTES + 1)
		var/datum/browser/popup = new(mob, "player_save_preview", "Сейв [player_ckey]", 900, 700)
		popup.set_content({"
			<p>[html_encode(selected)]</p>
			<p>Содержимое файла на диске. [truncated ? "Показан только начальный фрагмент; скачайте исходник для полного просмотра." : ""]</p>
			<pre id='save-content' style='white-space:pre-wrap;word-wrap:break-word'>[html_encode(preview)]</pre>
			<script>
				var element = document.getElementById('save-content');
				try { element.innerText = JSON.stringify(JSON.parse(element.textContent || element.innerText), null, 2); } catch (error) {}
			</script>
		"})
		popup.open()
		return

#undef PLAYER_SAVE_PREVIEW_MAX_BYTES
