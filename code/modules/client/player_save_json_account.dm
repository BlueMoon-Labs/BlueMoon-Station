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
	var/savefile/root = open("/")
	if(!root)
		return null
	var/list/result = list()
	for(var/slot in 1 to limit)
		var/key = "character[slot]"
		if(!(key in root.dir))
			continue
		var/name
		if(isnull(directories))
			root.cd = "/[key]"
			root["real_name"] >> name
			root.cd = "/"
		else if(directories[key])
			var/revision = directories[key]
			if(cached_name_generations[key] == revision && !recovered)
				name = cached_names[key]
			else
				var/datum/player_save_json/child = branch(key)
				var/savefile/character = child.open(null, revision)
				if(!character)
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
				character["real_name"] >> name
				cached_names[key] = name
				cached_name_generations[key] = revision
		result[key] = name
	if(islist(directories))
		cached_root = root
		cached_revision = player_save_revision(json_path)
	return result

/datum/player_save_json/account/proc/branch(key)
	var/datum/player_save_json/result = branches[key]
	if(!result)
		result = new("[json_path].d/[md5(key)].sav")
		branches[key] = result
	return result

/datum/player_save_json/account/open(scope, required_generation)
	branches = list()
	var/savefile/result
	if(scope && !required_generation && cached_root && cached_revision == player_save_revision(json_path) && !error)
		result = cached_root
		cached_root = null
	else
		cached_root = null
		result = ..(null, required_generation)
		if(result && islist(directories))
			cached_root = root_snapshot(result)
			cached_revision = player_save_revision(json_path)
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
			var/savefile/contents = child.open(null, directories[key])
			if(!contents)
				throw EXCEPTION("Не удалось прочитать раздел сохранения: [child.error]")
			result.cd = key
			player_save_copy_tree(contents, result)
			result.cd = "/"
	catch(var/exception/failure)
		// Предыдущий корень ссылается на предыдущие исправные поколения разделов.
		if(!required_generation && root_generation > 1)
			result = open(scope, root_generation - 1)
			if(result)
				recovered = TRUE
				recovery_reason = failure.name
				return result
		error = failure.name
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
	if(error || !source)
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
			if(!child.open(null, expected_generation))
				throw EXCEPTION("Не удалось подготовить раздел сохранения: [child.error]")
			var/savefile/contents = new
			player_save_copy_tree(source, contents)
			if(!child.commit(contents))
				throw EXCEPTION("Не удалось записать раздел сохранения: [child.error]")
			next_directories[key] = child.generation
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
