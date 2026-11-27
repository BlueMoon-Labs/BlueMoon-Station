/datum/preferences
	var/tmp/datum/player_save_json/account/player_save_storage
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

/// Ckey для логов: у префов без клиента он берётся из пути сейва.
/datum/preferences/proc/player_save_ckey()
	if(parent?.ckey)
		return parent.ckey
	var/list/parts = splittext(path, "/")
	return length(parts) >= 2 ? parts[length(parts) - 1] : (path || "?")

/// Шаги переноса старого .sav в JSON, пока не выйдет budget_ms (хотя бы один шаг).
/// TRUE - аккаунт уже в JSON или переносить нечего; FALSE - перенос не закончен или запись заблокирована.
/datum/preferences/proc/run_player_save_migration(budget_ms = INFINITY)
	var/datum/player_save_json/account/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return FALSE
	var/started = TICK_USAGE_REAL
	var/steps = 0
	// Второй заход - если .sav поменялся по ходу переноса и копию пришлось снять заново.
	for(var/attempt in 1 to 2)
		if(!storage.migration_active())
			if(!storage.legacy_only())
				return TRUE
			if(steps && TICK_USAGE_TO_MS(started) >= budget_ms)
				return FALSE
			var/begin_ms = blocking_call_start()
			var/begin_usage = TICK_USAGE_REAL
			var/opened = storage.begin_migration()
			storage.note_migration_step(TICK_USAGE_TO_MS(begin_usage))
			steps++
			blocking_call_finish(begin_ms, "JSON (перенос)", "[player_save_ckey()]: копия .sav [storage.migration_size_kb] КБ")
			if(!opened)
				if(storage.error)
					player_save_error(storage.error)
					return FALSE
				return !storage.legacy_only()
		while(storage.migration_active())
			if(steps && TICK_USAGE_TO_MS(started) >= budget_ms)
				return FALSE
			var/step_ms = blocking_call_start()
			var/step_usage = TICK_USAGE_REAL
			var/label = storage.migration_next_label()
			storage.migration_step()
			storage.note_migration_step(TICK_USAGE_TO_MS(step_usage))
			steps++
			blocking_call_finish(step_ms, "JSON (перенос)", "[player_save_ckey()]: [label]")
		if(storage.error)
			player_save_error(storage.error)
			return FALSE
		if(storage.migration_published)
			storage.migration_published = FALSE
			log_game("Сохранения: [player_save_ckey()] перенесены в JSON за [round(storage.migration_work_ms)] мс, слотов [storage.migration_slots], .sav [storage.migration_size_kb] КБ, шагов [storage.migration_steps], самый долгий [round(storage.migration_worst_ms)] мс, за [round((world.time - storage.migration_started_at) / 10, 0.1)] с.")
			return TRUE
		if(!storage.legacy_only())
			return TRUE
	return FALSE

/// Запись и полное чтение работают с JSON: старый .sav сначала переносится целиком.
/datum/preferences/proc/ensure_player_save_migrated()
	var/datum/player_save_json/account/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return FALSE
	if(!storage.migration_active() && !storage.legacy_only())
		return TRUE
	return run_player_save_migration()

/datum/preferences/proc/open_player_save(scope)
	var/datum/player_save_json/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return null
	if(!ensure_player_save_migrated())
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

/// Корневые поля читаются без сборки savefile; миграции остаются у старого загрузчика.
/datum/preferences/proc/open_player_document()
	var/datum/player_save_json/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return null
	if(!ensure_player_save_migrated())
		return null
	var/datum/player_save_document/result = storage.snapshot()
	if(!result)
		player_save_error(storage.error)
		return null
	if(length(result.tree) && player_save_version_status(result.read("version")) == -2)
		player_save_error("Неподдерживаемая версия старого сохранения")
		return null
	return result

/datum/preferences/proc/commit_player_save(savefile/source, scope)
	var/datum/player_save_json/storage = get_player_save_storage()
	if(!storage || player_save_blocked)
		return FALSE
	if(!storage.commit(source, scope))
		player_save_error(storage.error)
		return FALSE
	return TRUE

/datum/preferences/proc/commit_character_save(savefile/source, slot, datum/player_save_character_transaction/transaction)
	if(!transaction)
		return commit_player_save(source, "/character[slot]")
	if(!transaction.commit())
		player_save_error(transaction.root.storage.error)
		return FALSE
	return TRUE

/// Модульные расширения дописывают тот же документ в памяти, затем идёт одна запись.
/datum/preferences/proc/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	var/blocking_started_ms = blocking_call_start()
	var/list/pending_before_write = pending_single_prefs?.Copy()
	var/list/patch_context = list()
	var/result
	try
		result = write_preferences(bypass_cooldown, silent, patch_context)
	catch(var/exception/preparation_failure)
		pending_single_prefs = pending_before_write
		player_save_error(preparation_failure.name)
		blocking_call_finish(blocking_started_ms, "JSON (полные префы)", "ошибка подготовки")
		return FALSE
	if(!istype(result, /savefile) && !istype(result, /datum/player_save_document))
		blocking_call_finish(blocking_started_ms, "JSON (запись)", "запись отложена или отменена")
		return FALSE
	var/datum/player_save_document/document = patch_context["document"]
	var/saved = FALSE
	if(document)
		try
			saved = document.commit()
			if(!saved)
				player_save_error(document.storage.error)
		catch(var/exception/failure)
			player_save_error(failure.name)
	if(!document)
		saved = commit_player_save(result, "/")
	if(!saved)
		pending_single_prefs = pending_before_write
		blocking_call_finish(blocking_started_ms, "JSON (полные префы)", "ошибка записи")
		return FALSE
	blocking_call_finish(blocking_started_ms, "JSON (полные префы)", "настройки")
	if(parent && !silent)
		to_chat(parent, span_notice("Настройки сохранены!"))
	return result

/datum/preferences/proc/save_character(bypass_cooldown = FALSE, silent = FALSE, export = FALSE, update_active_preset = TRUE)
	var/blocking_started_ms = blocking_call_start()
	var/list/patch_context = export ? null : list()
	var/result
	try
		result = write_character(bypass_cooldown, silent, export, patch_context, update_active_preset)
	catch(var/exception/failure)
		if(export)
			throw failure
		player_save_error(failure.name)
		blocking_call_finish(blocking_started_ms, "JSON (персонаж)", "ошибка подготовки")
		return FALSE
	if(!istype(result, /savefile) && !istype(result, /datum/player_save_document))
		blocking_call_finish(blocking_started_ms, "JSON (запись)", "запись отложена или отменена")
		return FALSE
	if(!export)
		var/datum/player_save_character_transaction/transaction = patch_context["transaction"]
		// Корень всё равно переписывается ради имени слота: буфер одиночных ключей уезжает с ним.
		var/list/pending_before_write
		if(transaction && length(pending_single_prefs))
			pending_before_write = pending_single_prefs
			pending_single_prefs = null
			for(var/key in pending_before_write)
				transaction.root.write(key, pending_before_write[key])
		var/saved = commit_character_save(result, default_slot, transaction)
		if(saved && pending_before_write && !length(pending_single_prefs) && single_pref_queue)
			deltimer(single_pref_queue)
			single_pref_queue = null
			single_pref_queue_deadline = 0
		if(!saved && pending_before_write)
			for(var/key in pending_single_prefs)
				pending_before_write[key] = pending_single_prefs[key]
			pending_single_prefs = pending_before_write
		if(!saved)
			blocking_call_finish(blocking_started_ms, "JSON (персонаж)", "ошибка записи")
			return FALSE
	blocking_call_finish(blocking_started_ms, "JSON (персонаж)", "слот [default_slot]")
	if(!export)
		if(length(slot_names_cache) == max_save_slots)
			slot_names_cache[default_slot] = real_name
		if(length(slot_custom_names_cache) == max_save_slots)
			slot_custom_names_cache[default_slot] = player_save_slot_name(character_slot_name)
		character_setup_ui?.record_saved_state()
	if(parent && !silent && !export)
		to_chat(parent, span_notice("Персонаж сохранён!"))
	return result

/// Записываем миграции только после загрузки всех модульных настроек.
/datum/preferences/proc/load_preferences(bypass_cooldown = FALSE)
	var/result = read_preferences(bypass_cooldown)
	if(istype(result, /datum/player_save_document))
		return result
	var/savefile/S = result
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
				if(!save_character(TRUE, TRUE, update_active_preset = FALSE))
					default_slot = old_default_slot
					max_save_slots = old_max_save_slots
					return FALSE
		default_slot = old_default_slot
		max_save_slots = old_max_save_slots
		if(!save_preferences(TRUE, TRUE))
			return FALSE

	return S
