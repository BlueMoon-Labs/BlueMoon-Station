#define PLAYER_SAVE_BRANCH_CACHE_LIMIT 2

/// Корень и слоты записываются отдельно: одиночная настройка не переписывает все анкеты.
/// Корень хранит точные поколения разделов и публикуется последним при каждой транзакции.
/datum/player_save_json/account
	var/list/branches = list()
	var/savefile/cached_root
	var/cached_revision
	var/list/cached_names = list()
	var/list/cached_name_generations = list()
	/// Поэтапный перенос старого .sav: открытая копия файла и ещё не записанные разделы.
	var/savefile/migration_source
	var/migration_prefix
	var/migration_hash
	var/list/migration_keys
	var/list/migration_directories
	var/migration_revision
	var/migration_fingerprint
	/// TRUE, когда последний перенос опубликовал корень JSON.
	var/migration_published = FALSE
	var/migration_slots = 0
	var/migration_size_kb = 0
	var/migration_steps = 0
	var/migration_work_ms = 0
	var/migration_worst_ms = 0
	var/migration_started_at = 0

/datum/player_save_json/account/proc/character_names(limit)
	return character_index_column(limit, 1)

/datum/player_save_json/account/proc/character_slot_names(limit)
	return character_index_column(limit, 2)

/datum/player_save_json/account/proc/character_index_column(limit, column)
	var/list/index = character_index(limit)
	if(!index)
		return null
	var/list/result = list()
	for(var/key in index)
		var/list/entry = index[key]
		result[key] = entry[column]
	return result

/// Меню не загружает все анкеты заново после каждой смены вкладки или настройки корня.
/// Результат: ключ слота -> list(имя персонажа, название слота).
/datum/player_save_json/account/proc/character_index(limit)
	if(legacy_only())
		return legacy_character_fields(limit, PLAYER_SAVE_SLOT_INDEX_FIELDS)
	var/datum/player_save_document/root = snapshot()
	if(!root)
		return null
	var/list/result = list()
	for(var/slot in 1 to limit)
		var/key = "character[slot]"
		if(!(key in root.tree))
			continue
		var/list/entry
		var/indexed = isnull(directories) ? null : root.read(key)
		if(isnull(directories))
			var/list/node = root.tree[key]
			var/list/children = node["children"]
			entry = list()
			for(var/field in PLAYER_SAVE_SLOT_INDEX_FIELDS)
				var/list/field_node = children[field]
				entry += list(field_node ? player_save_decode_value(field_node["value"]) : null)
		else if(player_save_slot_index_valid(indexed))
			entry = list(indexed[1], indexed[2] || null)
		else if(directories[key])
			var/revision = directories[key]
			if(cached_name_generations[key] == revision && !recovered)
				entry = cached_names[key]
			else
				var/datum/player_save_json/child = branch(key)
				entry = child.read_fields(PLAYER_SAVE_SLOT_INDEX_FIELDS, revision)
				if(child.error)
					// Используем тот же согласованный откат, что и при загрузке персонажа.
					var/savefile/recovery = open()
					if(!recovery)
						return null
					result = list()
					for(var/recovery_slot in 1 to limit)
						var/recovery_key = "character[recovery_slot]"
						if(!(recovery_key in recovery.dir))
							continue
						recovery.cd = "/[recovery_key]"
						var/list/recovered_entry = list()
						for(var/field in PLAYER_SAVE_SLOT_INDEX_FIELDS)
							var/value
							recovery[field] >> value
							recovered_entry += list(value)
						result[recovery_key] = recovered_entry
						recovery.cd = "/"
					cached_names = list()
					cached_name_generations = list()
					return result
				cached_names[key] = entry
				cached_name_generations[key] = revision
			// Индекс без названий слотов (старые разделённые сейвы и прежние сборки) дописывается при первом открытии меню.
			if(istext(entry[1]))
				root.write(key, player_save_slot_index(entry[1], entry[2]))
		else if(istext(indexed))
			entry = list(indexed, null)
		if(entry)
			result[key] = entry
	// Все найденные имена публикуются вместе, без перезаписи самих разделов.
	if(root.dirty && !root.commit())
		return null
	return result


/datum/player_save_json/account/load_tree(required_generation, validate = TRUE)
	cached_root = null
	if(!required_generation && !set_aside_stale_json())
		return null
	return ..()

/// Отпечаток .sav, из которого перенесён JSON. Новые сборки .sav не пишут, так что другой
/// отпечаток значит, что после переноса играли на старой сборке и JSON устарел.
/datum/player_save_json/account/proc/legacy_marker_path()
	return "[json_path].legacy"

/datum/player_save_json/account/on_first_publish()
	if(!fexists(legacy_path))
		return
	var/fingerprint = rustg_hash_file(RUSTG_HASH_XXH64, legacy_path)
	if(fingerprint)
		fdel(legacy_marker_path())
		text2file(fingerprint, legacy_marker_path())

/// Устаревший JSON уходит в отдельный каталог, и сейв заново переносится из .sav.
/// FALSE - отложить JSON не удалось, чтение блокируется до разбора вручную.
/datum/player_save_json/account/proc/set_aside_stale_json()
	if(!fexists(legacy_path) || !(fexists(json_path) || fexists("[json_path].recovery")))
		return TRUE
	var/fingerprint = rustg_hash_file(RUSTG_HASH_XXH64, legacy_path)
	if(!fingerprint)
		return TRUE
	var/marker = legacy_marker_path()
	if(!fexists(marker))
		// JSON сборки без отметки: принимаем его как есть и отмечаем текущий .sav.
		text2file(fingerprint, marker)
		return TRUE
	if(trimtext(file2text(marker)) == fingerprint)
		return TRUE
	var/archive = "[json_path].stale-[time2text(world.realtime, "YYYYMMDD-hhmmss")]-[rand(1000, 9999)]/"
	var/list/moved = list(json_path, "[json_path].recovery", marker)
	for(var/source in moved)
		if(fexists(source) && !fcopy(source, "[archive][copytext(source, findlasttext(source, "/") + 1)]"))
			error = "Старый сейв изменён после переноса, но устаревший JSON не удалось отложить"
			return FALSE
	if(fexists("[json_path].d/") && !fcopy("[json_path].d/", "[archive]d/"))
		error = "Старый сейв изменён после переноса, но разделы устаревшего JSON не удалось отложить"
		return FALSE
	for(var/source in moved)
		fdel(source)
	fdel("[json_path].d/")
	branches = list()
	cached_names = list()
	cached_name_generations = list()
	player_save_revision(json_path, TRUE)
	log_game("Сохранения: [legacy_path] изменён после переноса в JSON, устаревший JSON отложен в [archive], сейв перенесён заново.")
	return TRUE

/datum/player_save_json/account/snapshot(required_generation, use_cache = TRUE)
	var/datum/player_save_document/document = ..()
	if(!document)
		return null
	for(var/key in document.directories)
		if(key in document.tree)
			continue
		// Старый адаптер умеет откатывать каталог вместе с разделами. Прямое
		// чтение должно замечать те же повреждения, даже если нужен только корень.
		if(!required_generation && open("/"))
			return ..(generation, TRUE)
		error = error || "Раздел отсутствует в корне сохранения"
		return null
	return document

/datum/player_save_json/account/commit_snapshot(datum/player_save_document/document)
	cached_root = null
	return ..()

/datum/player_save_json/account/proc/character_transaction(key, allow_recovery = TRUE)
	var/datum/player_save_document/root = snapshot()
	if(!root || isnull(root.directories))
		return null
	var/datum/player_save_json/child = branch(key)
	var/datum/player_save_document/character = child.snapshot(root.directories[key])
	if(!character && !root.directories[key])
		character = child.empty_snapshot()
	if(!character)
		// Повреждённый раздел восстанавливаем вместе с соответствующим корнем.
		if(allow_recovery && open("/[key]"))
			return character_transaction(key, FALSE)
		error = error || child.error
		return null
	if(!root.directories[key])
		// Удалённый слот может оставить файлы: новая анкета не наследует их поля.
		character.mark_dirty()
		character.tree = list()
	var/datum/player_save_character_transaction/result = new
	result.root = root
	result.character = character
	result.key = key
	return result

/datum/player_save_json/account/proc/branch(key)
	var/datum/player_save_json/result = branches[key]
	if(!result)
		result = new("[json_path].d/[md5(key)].sav")
	else
		branches -= key
	branches[key] = result
	// Держим два последних раздела, чтобы переключение слотов не раздувало кэш аккаунта.
	if(length(branches) > PLAYER_SAVE_BRANCH_CACHE_LIMIT)
		branches.Cut(1, length(branches) - PLAYER_SAVE_BRANCH_CACHE_LIMIT + 1)
	return result

/datum/player_save_json/account/open(scope, required_generation, savefile/target, use_cache = FALSE)
	var/savefile/result
	if(scope && !required_generation && cached_root && cached_revision == player_save_revision(json_path) && !error)
		result = cached_root
		cached_root = null
	else
		cached_root = null
		result = ..(null, required_generation, null, !!scope && !required_generation)
	if(!result || isnull(directories))
		return result
	var/root_generation = generation
	try
		for(var/key in directories)
			if(!(key in result.dir))
				throw EXCEPTION("Раздел отсутствует в корне сохранения")
			if(scope == "/" || (scope && scope != "/[key]"))
				continue
			var/datum/player_save_json/child = branch(key)
			result.cd = key
			if(!child.open(null, directories[key], result, !!scope && !required_generation))
				throw EXCEPTION("Не удалось прочитать раздел сохранения: [child.error]")
			result.cd = "/"
	catch(var/exception/failure)
		var/recovery_error
		// Предыдущий корень ссылается на предыдущие исправные поколения разделов.
		if(!required_generation && root_generation > 1)
			result = open(scope, root_generation - 1)
			if(result)
				recovered = TRUE
				recovery_reason = failure.name
				return result
			recovery_error = error
		error = recovery_error ? "[failure.name]; ошибка восстановления: [recovery_error]" : failure.name
		cached_root = null
		return null
	return result

/datum/player_save_json/account/proc/root_snapshot(savefile/source)
	var/savefile/result = new
	var/original_directory = source.cd
	source.cd = "/"
	for(var/key in source.dir)
		var/value
		source[key] >> value
		result[key] << value
	source.cd = original_directory
	return result

/// Записывает раздел key из source, его поколение кладёт в next_directories.
/datum/player_save_json/account/proc/commit_branch(savefile/source, key, list/previous_directories, list/next_directories)
	var/datum/player_save_json/child = branch(key)
	var/expected_generation = previous_directories ? previous_directories[key] : null
	// Загруженный раздел уже проверен. После чужой записи или при другом
	// поколении заново выбираем именно опубликованный корнем снимок.
	if(!expected_generation || child.error || child.generation != expected_generation || child.open_revision != player_save_revision(child.json_path))
		if(!child.open(null, expected_generation))
			if(expected_generation)
				throw EXCEPTION("Не удалось подготовить раздел сохранения: [child.error]")
			// Корень на раздел не ссылается: остатки прерванного переноса не мешают записи.
			child.empty_snapshot()
	if(!child.commit(source, "/[key]"))
		throw EXCEPTION("Не удалось записать раздел сохранения: [child.error]")
	next_directories[key] = child.generation

/// JSON ещё не опубликован: незаконченный перенос оставляет только файлы разделов без корня.
/datum/player_save_json/account/proc/legacy_only()
	return fexists(legacy_path) && !fexists(json_path) && !fexists("[json_path].recovery")

/// Одно поле каждой анкеты старого .sav из одной копии файла, без разбора анкет целиком.
/// Список полей вместо одного даёт по анкете список значений в том же порядке.
/datum/player_save_json/account/proc/legacy_character_fields(limit, field)
	error = null
	var/list/result = list()
	var/savefile/legacy
	var/prefix
	try
		legacy = open_legacy_copy()
		prefix = legacy_copy_prefix
		for(var/slot in 1 to limit)
			var/key = "character[slot]"
			legacy.cd = "/"
			if(!(key in legacy.dir))
				continue
			legacy.cd = "/[key]"
			if(islist(field))
				var/list/values = list()
				for(var/name in field)
					var/value
					if(name in legacy.dir)
						legacy[name] >> value
					values += list(value)
				result[key] = values
				continue
			var/value
			if(field in legacy.dir)
				legacy[field] >> value
			result[key] = value
		legacy.cd = "/"
		verify_legacy_copy(legacy, prefix)
	catch(var/exception/failure)
		error = "Не удалось прочитать старое сохранение: [failure.name]"
		result = null
	legacy = null
	close_legacy_copy(prefix)
	return result

/datum/player_save_json/account/commit(savefile/source, scope)
	// Проверяем корень до записи разделов, чтобы устаревший писатель не оставлял новое поколение.
	if(!source || !check_revision())
		return FALSE
	var/original_directory = source.cd
	var/list/previous_directories = directories
	var/list/next_directories = islist(directories) ? directories.Copy() : list()
	var/savefile/next_root
	// Первый перенос и полные транзакции включают все вложенные разделы.
	var/full_snapshot = isnull(directories) || !scope
	if(full_snapshot)
		next_directories = list()
	if(player_save_is_legacy_view(source))
		error = "Частичная копия старого сохранения не записывается"
		return FALSE
	try
		source.cd = "/"
		var/list/keys = full_snapshot ? source.dir.Copy() : (scope == "/" ? list() : list(copytext(scope, 2)))
		for(var/key in keys)
			source.cd = "/[key]"
			if(!length(source.dir))
				continue
			commit_branch(source, key, previous_directories, next_directories)
			// Имя публикуется с тем же поколением, что и содержимое анкеты.
			if(copytext(key, 1, 10) == "character")
				source.cd = "/[key]"
				var/list/entry = player_save_slot_index_from(source)
				source.cd = "/"
				source[key] << entry
		source.cd = original_directory
		directories = next_directories
		// До этой записи читатели видят старый согласованный набор поколений.
		next_root = root_snapshot(source)
		if(!..(next_root))
			directories = previous_directories
			cached_root = null
			return FALSE
	catch(var/exception/failure)
		source.cd = original_directory
		directories = previous_directories
		error = failure.name
		cached_root = null
		return FALSE
	cached_root = next_root
	cached_revision = player_save_revision(json_path)
	return TRUE

/datum/player_save_json/account/proc/migration_active()
	return !isnull(migration_source)

/// Открывает копию старого .sav для переноса по разделам. FALSE с error - файл не прочитан,
/// FALSE без error - переносить нечего.
/datum/player_save_json/account/proc/begin_migration()
	if(migration_source)
		return TRUE
	error = null
	migration_published = FALSE
	if(!legacy_only())
		return FALSE
	try
		migration_fingerprint = rustg_hash_file(RUSTG_HASH_XXH64, legacy_path)
		migration_source = open_legacy_copy()
		migration_prefix = legacy_copy_prefix
		migration_hash = legacy_copy_hash
	catch(var/exception/failure)
		migration_source = null
		close_legacy_copy(legacy_copy_prefix)
		error = "Не удалось прочитать сохранение: [failure.name]"
		return FALSE
	migration_source.cd = "/"
	var/root_version
	if("version" in migration_source.dir)
		migration_source["version"] >> root_version
	if(length(migration_source.dir) && player_save_version_status(root_version) == -2)
		abort_migration()
		error = "Неподдерживаемая версия старого сохранения"
		return FALSE
	migration_keys = list()
	migration_slots = 0
	for(var/key in migration_source.dir)
		migration_source.cd = "/[key]"
		if(length(migration_source.dir))
			migration_keys += key
			if(player_save_is_slot_key(key))
				migration_slots++
		migration_source.cd = "/"
	migration_directories = list()
	migration_revision = player_save_revision(json_path)
	migration_size_kb = round(length(file(legacy_path)) / 1024)
	migration_steps = 0
	migration_work_ms = 0
	migration_worst_ms = 0
	migration_started_at = world.time
	return TRUE

/// Обрывает перенос. Разделы без корня никто не читает, следующий перенос их перепишет.
/datum/player_save_json/account/proc/abort_migration()
	migration_source = null
	close_legacy_copy(migration_prefix)
	migration_prefix = null
	migration_keys = null
	migration_directories = null

/datum/player_save_json/account/proc/migration_next_label()
	return length(migration_keys) ? "раздел [migration_keys[1]]" : "корень"

/datum/player_save_json/account/proc/note_migration_step(cost_ms)
	migration_steps++
	migration_work_ms += cost_ms
	migration_worst_ms = max(migration_worst_ms, cost_ms)

/// Один раздел или, когда разделы кончились, корень. TRUE - перенос закончен: опубликован
/// (migration_published), упал (error) или прерван чужой записью.
/datum/player_save_json/account/proc/migration_step()
	if(!migration_source)
		return TRUE
	// Чужая полная запись уже опубликовала корень: наш снимок устарел и не нужен.
	if(player_save_revision(json_path) != migration_revision || !legacy_only())
		abort_migration()
		return TRUE
	if(length(migration_keys))
		var/key = migration_keys[1]
		migration_keys.Cut(1, 2)
		try
			commit_branch(migration_source, key, null, migration_directories)
		catch(var/exception/failure)
			abort_migration()
			error = failure.name
			return TRUE
		return FALSE
	return finish_migration()

/// Корень публикуется последним: до него читатели видят только старый .sav.
/datum/player_save_json/account/proc/finish_migration()
	var/savefile/source = migration_source
	var/list/previous_directories = directories
	try
		// .sav изменился после копии - снимок устарел, перенос начнётся заново.
		if(rustg_hash_file(RUSTG_HASH_XXH64, legacy_path) != migration_fingerprint)
			source = null
			abort_migration()
			return TRUE
		// Чтения при входе открывают свои копии: сверяемся с хешем своей.
		verify_legacy_copy(source, migration_prefix, migration_hash)
		player_save_apply_legacy_journal(source, legacy_path)
		var/savefile/next_root = root_snapshot(source)
		for(var/key in migration_directories)
			if(copytext(key, 1, 10) != "character")
				continue
			source.cd = "/[key]"
			next_root[key] << player_save_slot_index_from(source)
		source.cd = "/"
		directories = migration_directories
		if(!commit_tree(player_save_encode_tree(next_root)))
			throw EXCEPTION(error || "Не удалось записать корень сохранения")
	catch(var/exception/failure)
		directories = previous_directories
		source = null
		abort_migration()
		error = error || failure.name
		return TRUE
	source = null
	cached_root = null
	migration_published = TRUE
	abort_migration()
	return TRUE

#undef PLAYER_SAVE_BRANCH_CACHE_LIMIT
