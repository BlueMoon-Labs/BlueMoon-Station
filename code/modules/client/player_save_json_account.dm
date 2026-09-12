#define PLAYER_SAVE_BRANCH_CACHE_LIMIT 2

/// Корень и слоты записываются отдельно: одиночная настройка не переписывает все анкеты.
/// Корень хранит точные поколения разделов и публикуется последним при каждой транзакции.
/datum/player_save_json/account
	var/list/branches = list()
	var/savefile/cached_root
	var/cached_revision
	var/list/cached_names = list()
	var/list/cached_name_generations = list()

/// Меню не загружает все анкеты заново после каждой смены вкладки или настройки корня.
/datum/player_save_json/account/proc/character_names(limit)
	var/datum/player_save_document/root = snapshot()
	if(!root)
		return null
	var/list/result = list()
	for(var/slot in 1 to limit)
		var/key = "character[slot]"
		if(!(key in root.tree))
			continue
		var/name
		if(isnull(directories))
			var/list/node = root.tree[key]
			var/list/children = node["children"]
			var/list/name_node = children["real_name"]
			name = name_node ? player_save_decode_value(name_node["value"]) : null
		else if(istext(root.read(key)))
			name = root.read(key)
		else if(directories[key])
			var/revision = directories[key]
			if(cached_name_generations[key] == revision && !recovered)
				name = cached_names[key]
			else
				var/datum/player_save_json/child = branch(key)
				name = child.read_field("real_name", revision)
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
						recovery["real_name"] >> name
						result[recovery_key] = name
						recovery.cd = "/"
					cached_names = list()
					cached_name_generations = list()
					return result
				cached_names[key] = name
				cached_name_generations[key] = revision
			// Старые разделённые сейвы получают индекс имён при первом открытии меню.
			if(istext(name))
				root.write(key, name)
		result[key] = name
	// Все найденные имена публикуются вместе, без перезаписи самих разделов.
	if(root.dirty && !root.commit())
		return null
	return result

/datum/player_save_json/account/load_tree(required_generation, validate = TRUE)
	cached_root = null
	return ..()

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
	try
		source.cd = "/"
		var/list/keys = full_snapshot ? source.dir.Copy() : (scope == "/" ? list() : list(copytext(scope, 2)))
		for(var/key in keys)
			source.cd = "/[key]"
			if(!length(source.dir))
				continue
			var/datum/player_save_json/child = branch(key)
			var/expected_generation = previous_directories ? previous_directories[key] : null
			// Загруженный раздел уже проверен. После чужой записи или при другом
			// поколении заново выбираем именно опубликованный корнем снимок.
			if(!expected_generation || child.error || child.generation != expected_generation || child.open_revision != player_save_revision(child.json_path))
				if(!child.open(null, expected_generation))
					throw EXCEPTION("Не удалось подготовить раздел сохранения: [child.error]")
			if(!child.commit(source, "/[key]"))
				throw EXCEPTION("Не удалось записать раздел сохранения: [child.error]")
			next_directories[key] = child.generation
			// Имя публикуется с тем же поколением, что и содержимое анкеты.
			if(copytext(key, 1, 10) == "character")
				var/name
				source["real_name"] >> name
				source.cd = "/"
				source[key] << name
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

#undef PLAYER_SAVE_BRANCH_CACHE_LIMIT
