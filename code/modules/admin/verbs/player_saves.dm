#define PLAYER_SAVE_PREVIEW_MAX_BYTES (1024 * 1024)
/// Старый .sav для просмотра разворачивается в текст целиком, поэтому исходник ограничен отдельно.
#define PLAYER_SAVE_PREVIEW_MAX_SOURCE (32 * 1024 * 1024)
#define PLAYER_SAVE_BUNDLE_MAX_BYTES (128 * 1024 * 1024)
/// Слоты сверх этого номера в списке файлов останутся без номера, но не пропадут.
#define PLAYER_SAVE_INSPECTOR_SLOT_LIMIT 200

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

/proc/player_save_debug_is_json(source_path)
	return copytext(source_path, -5) == ".json" || copytext(source_path, -14) == ".json.recovery"

/// JSON читается как текст даже при повреждении. Старый savefile открывается только на копии.
/proc/player_save_debug_text(source_path, max_bytes = PLAYER_SAVE_PREVIEW_MAX_BYTES)
	if(!fexists(source_path))
		throw EXCEPTION("Файл больше не существует.")
	if(max_bytes && length(file(source_path)) > max_bytes)
		throw EXCEPTION("Файл больше [round(max_bytes / (1024 * 1024))] МиБ. Скачайте его для просмотра целиком.")
	if(player_save_debug_is_json(source_path))
		return file2text(source_path)
	var/static/sequence = 0
	var/temp_directory = "data/player_save_debug/[num2text(world.realtime, 12)]_[++sequence]/"
	fdel(temp_directory)
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

/// Номер слота по имени раздела в каталоге .d/: файл называется md5 ключа слота.
/proc/player_save_debug_slot_by_hash()
	var/static/list/slots
	if(!slots)
		slots = list()
		for(var/slot in 1 to PLAYER_SAVE_INSPECTOR_SLOT_LIMIT)
			slots[md5("character[slot]")] = slot
	return slots

/// Разбор строки файла: вид, номер слота. Имя персонажа добавляет вызывающий из корня.
/proc/player_save_debug_describe(relative_path)
	var/list/entry = list("path" = relative_path, "kind" = "other", "slot" = null)
	var/branch_at = findtext(relative_path, ".json.d/")
	if(branch_at)
		var/branch_name = copytext(relative_path, branch_at + length(".json.d/"))
		entry["kind"] = "slot"
		entry["slot"] = player_save_debug_slot_by_hash()[copytext(branch_name, 1, 33)]
	else if(relative_path == "preferences.sav.json")
		entry["kind"] = "root"
	else if(relative_path == "preferences.sav.json.recovery")
		entry["kind"] = "recovery"
	else if(relative_path == "preferences.sav" || relative_path == "preferences.sav.updatebac")
		entry["kind"] = "legacy"
	entry["recovery"] = copytext(relative_path, -9) == ".recovery"
	return entry

/// Имена персонажей и активный слот берутся из сырого корня: учётная запись при этом не открывается и ничего не пишет.
/proc/player_save_debug_root_summary(root_path)
	var/list/summary = list("names" = list(), "default_slot" = null)
	if(!fexists(root_path))
		return summary
	try
		var/list/document = json_decode(file2text(root_path))
		var/list/tree = islist(document) ? document["tree"] : null
		if(!islist(tree))
			return summary
		var/list/default_node = tree["default_slot"]
		if(islist(default_node))
			var/default_slot = player_save_decode_value(default_node["value"])
			if(isnum(default_slot))
				summary["default_slot"] = default_slot
		var/list/names = summary["names"]
		for(var/key in tree)
			if(!istext(key) || copytext(key, 1, 10) != "character")
				continue
			var/slot = text2num(copytext(key, 10))
			var/list/node = tree[key]
			if(!isnum(slot) || !islist(node))
				continue
			var/indexed = player_save_decode_value(node["value"])
			if(islist(indexed))
				var/list/index = indexed
				indexed = length(index) ? index[1] : null
			if(istext(indexed) && length(indexed))
				names["[slot]"] = indexed
	catch
		// Повреждённый корень всё равно показываем списком файлов, просто без имён.
		return list("names" = list(), "default_slot" = null)
	return summary

/// Все сейвы одним JSON: тексты как есть, старые savefile - в виде ExportText, его возвращает ImportText.
/proc/player_save_debug_bundle(player_ckey, directory, list/relative_paths)
	var/list/files = list()
	var/total = 0
	for(var/relative_path in relative_paths)
		var/source_path = "[directory][relative_path]"
		var/list/entry = list("size" = length(file(source_path)))
		total += entry["size"]
		if(total > PLAYER_SAVE_BUNDLE_MAX_BYTES)
			throw EXCEPTION("Сейвы больше [PLAYER_SAVE_BUNDLE_MAX_BYTES / (1024 * 1024)] МиБ, скачайте файлы по одному.")
		var/json = player_save_debug_is_json(source_path)
		entry["encoding"] = json ? "text" : "savefile_export_text"
		entry["content"] = player_save_debug_text(source_path, 0)
		files[relative_path] = entry
	return json_encode(list(
		"format" = "bluemoon-player-save-bundle",
		"version" = 1,
		"ckey" = player_ckey,
		"created" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"),
		"round_id" = GLOB.round_id,
		"files" = files,
	))

/proc/player_save_debug_send(mob/user, text, filename)
	var/static/sequence = 0
	var/temp_path = "data/player_save_debug/bundle_[num2text(world.realtime, 12)]_[++sequence].json"
	fdel(temp_path)
	if(!text2file(text, temp_path))
		return FALSE
	var/resource = fcopy_rsc(temp_path)
	fdel(temp_path)
	if(!resource)
		return FALSE
	user << ftp(resource, filename)
	return TRUE

/client/proc/inspect_player_saves()
	set name = "Inspect Player Saves"
	set category = "Debug.2) Info"
	set desc = "Просмотр и скачивание сохранённых файлов игрока по ckey."

	if(!check_rights_for(src, R_DEBUG))
		return
	var/datum/player_save_inspector/inspector = new
	inspector.ui_interact(mob)

/// Окно отладки сейвов: файлы игрока по слотам, просмотр и выгрузка. Читает диск, ничего не пишет в сейвы.
/datum/player_save_inspector
	var/player_ckey
	var/directory
	var/list/file_rows = list()
	var/default_slot
	var/selected
	var/preview
	var/preview_error
	var/preview_truncated = FALSE
	var/message

/datum/player_save_inspector/ui_state(mob/user)
	return GLOB.debug_state

/datum/player_save_inspector/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlayerSaveInspector", "Сейвы игрока")
		// Превью до 1 МиБ не гоняем каждую секунду: окно обновляется только по действиям.
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/player_save_inspector/ui_close(mob/user)
	qdel(src)

/datum/player_save_inspector/Destroy()
	SStgui.close_uis(src)
	return ..()

/datum/player_save_inspector/proc/set_target(player_key)
	player_ckey = ckey(player_key)
	directory = player_save_debug_directory(player_ckey)
	selected = null
	clear_preview()
	refresh()

/datum/player_save_inspector/proc/clear_preview()
	preview = null
	preview_error = null
	preview_truncated = FALSE

/datum/player_save_inspector/proc/refresh()
	file_rows = list()
	default_slot = null
	if(!directory)
		return
	var/list/summary = player_save_debug_root_summary("[directory]preferences.sav.json")
	default_slot = summary["default_slot"]
	var/list/names = summary["names"]
	for(var/relative_path in player_save_debug_files(directory))
		var/list/row = player_save_debug_describe(relative_path)
		row["size"] = length(file("[directory][relative_path]"))
		if(row["slot"])
			row["character"] = names["[row["slot"]]"]
		file_rows += list(row)
	if(selected && !has_file(selected))
		selected = null
		clear_preview()

/datum/player_save_inspector/proc/has_file(relative_path)
	if(!istext(relative_path))
		return FALSE
	for(var/list/row as anything in file_rows)
		if(row["path"] == relative_path)
			return TRUE
	return FALSE

/datum/player_save_inspector/ui_data(mob/user)
	var/list/data = list()
	data["ckey"] = player_ckey
	data["files"] = file_rows
	data["default_slot"] = default_slot
	data["selected"] = selected
	data["preview"] = preview
	data["preview_error"] = preview_error
	data["preview_truncated"] = preview_truncated
	data["message"] = message
	return data

/datum/player_save_inspector/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!check_rights_for(user?.client, R_DEBUG))
		return
	message = null
	switch(action)
		if("open")
			set_target(params["ckey"])
			if(player_ckey && !length(file_rows))
				message = "У [player_ckey] не найдено файлов сохранений."
			return TRUE
		if("refresh")
			refresh()
			return TRUE
		if("view")
			var/relative_path = params["path"]
			// Пути только из серверного списка, заново прочитанного с диска.
			refresh()
			if(!has_file(relative_path))
				message = "Файл больше не существует."
				return TRUE
			selected = relative_path
			clear_preview()
			log_admin("[key_name(user)] запросил сейв [player_ckey]: [relative_path] (просмотр).")
			try
				var/text = player_save_debug_text("[directory][relative_path]", PLAYER_SAVE_PREVIEW_MAX_SOURCE)
				preview_truncated = length(text) > PLAYER_SAVE_PREVIEW_MAX_BYTES
				preview = preview_truncated ? copytext(text, 1, PLAYER_SAVE_PREVIEW_MAX_BYTES + 1) : text
			catch(var/exception/failure)
				preview_error = failure.name
			return TRUE
		if("download")
			var/relative_path = params["path"]
			refresh()
			if(!has_file(relative_path))
				message = "Файл больше не существует."
				return TRUE
			log_admin("[key_name(user)] запросил сейв [player_ckey]: [relative_path] (скачивание).")
			var/resource = fcopy_rsc("[directory][relative_path]")
			if(!resource)
				message = "Не удалось прочитать файл."
				return TRUE
			user << ftp(resource, "[player_ckey]-[replacetext(relative_path, "/", "--")]")
			return TRUE
		if("download_bundle")
			refresh()
			var/slot = text2num(params["slot"])
			var/list/paths = list()
			for(var/list/row as anything in file_rows)
				// Для одного персонажа берём его раздел и корень аккаунта с откатом: без корня раздел не читается.
				if(isnull(slot) || row["slot"] == slot || row["kind"] == "root" || row["kind"] == "recovery")
					paths += row["path"]
			if(!length(paths))
				message = "Нечего скачивать."
				return TRUE
			var/scope = isnull(slot) ? "все файлы" : "слот [slot]"
			log_admin("[key_name(user)] скачал сейвы [player_ckey]: [scope], файлов [length(paths)].")
			try
				var/text = player_save_debug_bundle(player_ckey, directory, paths)
				if(!player_save_debug_send(user, text, "[player_ckey]-[isnull(slot) ? "saves" : "slot[slot]"].json"))
					message = "Не удалось подготовить файл."
			catch(var/exception/failure)
				message = failure.name
			return TRUE

#undef PLAYER_SAVE_PREVIEW_MAX_BYTES
#undef PLAYER_SAVE_PREVIEW_MAX_SOURCE
#undef PLAYER_SAVE_BUNDLE_MAX_BYTES
#undef PLAYER_SAVE_INSPECTOR_SLOT_LIMIT
