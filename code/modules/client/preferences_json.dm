/datum/preferences
	var/tmp/datum/player_save_json/player_save_storage
	var/tmp/player_save_blocked = FALSE

/datum/preferences/proc/player_save_error(message)
	player_save_blocked = TRUE
	log_game("Ошибка сохранения игрока [parent?.ckey || "без клиента"]: [message]")
	if(parent)
		to_chat(parent, span_userdanger("Не удалось прочитать или записать ваши сохранения. Запись заблокирована, чтобы сохранить исходные данные. Сообщите администрации. Ваши изменения в этой сессии могут не сохраниться."))

/datum/preferences/proc/get_player_save_storage()
	if(!path)
		return null
	if(!player_save_storage || player_save_storage.legacy_path != path)
		player_save_storage = new /datum/player_save_json/account(path)
		player_save_blocked = FALSE
	return player_save_storage

/datum/preferences/proc/player_save_exists()
	var/datum/player_save_json/storage = get_player_save_storage()
	return storage?.exists()

/datum/preferences/proc/player_character_names()
	var/datum/player_save_json/account/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return null
	var/list/names = storage.character_names(max_save_slots)
	if(!islist(names))
		player_save_error(storage.error)
	return names

/datum/preferences/proc/open_player_save(scope)
	var/datum/player_save_json/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return null
	var/savefile/result = storage.open(scope)
	if(!result)
		player_save_error(storage.error)
		return null
	if(length(result.dir) && savefile_needs_update(result) == -2)
		player_save_error("Неподдерживаемая версия старого сохранения")
		return null
	if(storage.recovered)
		log_game("Сохранение игрока [parent?.ckey || "без клиента"] прочитано из исправного поколения JSON после ошибки другого поколения.")
	return result

/datum/preferences/proc/commit_player_save(savefile/source, scope)
	var/datum/player_save_json/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return FALSE
	if(!storage.commit(source, scope))
		player_save_error(storage.error)
		return FALSE
	return TRUE

/// Модульные расширения сначала дописывают общий снимок в памяти, затем идёт одна запись.
/datum/preferences/proc/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	var/blocking_started_ms = blocking_call_start()
	var/list/pending_before_write = pending_single_prefs?.Copy()
	var/savefile/result = write_preferences(bypass_cooldown, silent)
	if(!istype(result))
		blocking_call_finish(blocking_started_ms, "JSON (запись)", "запись отложена или отменена")
		return FALSE
	if(!commit_player_save(result, "/"))
		pending_single_prefs = pending_before_write
		blocking_call_finish(blocking_started_ms, "JSON (полные префы)", "ошибка записи")
		return FALSE
	blocking_call_finish(blocking_started_ms, "JSON (полные префы)", "настройки")
	if(parent && !silent)
		to_chat(parent, span_notice("Настройки сохранены!"))
	return result

/datum/preferences/proc/save_character(bypass_cooldown = FALSE, silent = FALSE, export = FALSE)
	var/blocking_started_ms = blocking_call_start()
	var/savefile/result = write_character(bypass_cooldown, silent, export)
	if(!istype(result))
		blocking_call_finish(blocking_started_ms, "JSON (запись)", "запись отложена или отменена")
		return FALSE
	if(!export && !commit_player_save(result, "/character[default_slot]"))
		blocking_call_finish(blocking_started_ms, "JSON (персонаж)", "ошибка записи")
		return FALSE
	blocking_call_finish(blocking_started_ms, "JSON (персонаж)", "слот [default_slot]")
	if(parent && !silent && !export)
		to_chat(parent, span_notice("Слот персонажа сохранён!"))
	return result

/// Записываем миграции только после загрузки всех модульных настроек.
/datum/preferences/proc/load_preferences(bypass_cooldown = FALSE)
	var/savefile/S = read_preferences(bypass_cooldown)
	if(!istype(S))
		return FALSE
	if(savefile_needs_update(S) >= 0)
		var/old_default_slot = default_slot
		var/old_max_save_slots = max_save_slots

		for (var/slot in S.dir.Copy())
			if (copytext(slot, 1, 10) != "character")
				continue
			var/slotnum = text2num(copytext(slot, 10))
			if (!slotnum || slotnum < 1 || slotnum != round(slotnum) || slot != "character[slotnum]")
				continue
			if (slotnum > SAVEFILE_MIGRATION_MAX_CHARACTER_SLOT)
				continue
			max_save_slots = max(max_save_slots, slotnum)
			default_slot = slotnum
			if (load_character(null, TRUE))
				if(!save_character(TRUE, TRUE))
					default_slot = old_default_slot
					max_save_slots = old_max_save_slots
					return FALSE
		default_slot = old_default_slot
		max_save_slots = old_max_save_slots
		if(!save_preferences(TRUE, TRUE))
			return FALSE

	return S
