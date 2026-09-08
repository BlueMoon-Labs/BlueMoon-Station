// Формат диска отделён от старых загрузчиков: savefile используется только в памяти.
// Это сохраняет порядок миграций, модульные поля и совместимость экспорта персонажей.
#define PLAYER_SAVE_JSON_VERSION 1
#define PLAYER_SAVE_JSON_DEPTH 64

/// Согласует небольшие кэши корня между несколькими датумами префов одного аккаунта.
/proc/player_save_revision(path, advance = FALSE)
	var/static/list/revisions = list()
	if(advance)
		revisions[path] = (revisions[path] || 0) + 1
	return revisions[path] || 0

/proc/player_save_encode_value(value, depth = 0)
	if(depth > PLAYER_SAVE_JSON_DEPTH)
		throw EXCEPTION("Слишком глубокий или циклический список в сохранении")
	if(isnull(value))
		return value
	if(isnum(value))
		// json_encode BYOND округляет дроби; 20 значащих цифр сохраняют исходный float.
		if(json_decode(json_encode(value)) != value)
			return list("type" = "number", "value" = num2text(value, 20))
		return value
	if(istext(value))
		// JSON удаляет служебные маркеры вроде \proper. Обычный текст остаётся читаемым.
		if(json_decode(json_encode(value)) != value)
			var/escaped = replacetext(replacetext(value, "%", "%25"), copytext("\proper x", 1, 2), "%ff")
			for(var/code in 1 to 31)
				escaped = replacetext(escaped, ascii2text(code), "%[num2text(code, 2, 16)]")
			if(json_decode(json_encode(escaped)) != escaped)
				throw EXCEPTION("Неизвестная кодировка строки в сохранении")
			return list("type" = "text", "value" = escaped)
		return value
	if(istype(value, /matrix))
		var/matrix/transform = value
		return list("type" = "matrix", "values" = player_save_encode_value(list(transform.a, transform.b, transform.c, transform.d, transform.e, transform.f), depth + 1))
	if(ispath(value))
		return list("type" = "path", "value" = "[value]")
	if(!islist(value))
		// У старых модулей встречаются сериализованные датумы и ресурсы. Для них
		// сохраняем штатное текстовое представление BYOND, не приводя объект к имени.
		var/savefile/compatibility = new
		compatibility["value"] << value
		return list("type" = "byond", "text" = player_save_encode_value(compatibility.ExportText("/"), depth + 1))
	var/list/source = value
	var/list/items = list()
	var/list/associations = list()
	for(var/index in 1 to source.len)
		var/key = source[index]
		items += list(player_save_encode_value(key, depth + 1))
		// Число при индексации списка означает позицию, а не ассоциативный ключ.
		var/associated = isnull(key) || isnum(key) ? null : source[key]
		associations += list(player_save_encode_value(associated, depth + 1))
	return list("type" = "list", "items" = items, "associations" = associations)

/proc/player_save_decode_value(value, depth = 0)
	if(depth > PLAYER_SAVE_JSON_DEPTH)
		throw EXCEPTION("Слишком глубокий JSON сохранения")
	if(isnull(value) || istext(value) || isnum(value))
		return value
	if(!islist(value))
		throw EXCEPTION("Некорректное значение JSON сохранения")
	var/list/node = value
	if(node["type"] == "text")
		if(!istext(node["value"]))
			throw EXCEPTION("Некорректная экранированная строка JSON сохранения")
		var/decoded = node["value"]
		for(var/code in 1 to 31)
			decoded = replacetext(decoded, "%[num2text(code, 2, 16)]", ascii2text(code))
		return replacetext(replacetext(decoded, "%ff", copytext("\proper x", 1, 2)), "%25", "%")
	if(node["type"] == "byond")
		var/serialized = player_save_decode_value(node["text"], depth + 1)
		if(!istext(serialized))
			throw EXCEPTION("Некорректное совместимое значение JSON сохранения")
		var/savefile/compatibility = new
		compatibility.ImportText("/", serialized)
		var/restored
		compatibility["value"] >> restored
		if(isnull(restored))
			throw EXCEPTION("Не удалось прочитать совместимое значение JSON сохранения")
		return restored
	if(node["type"] == "number")
		var/number = text2num(node["value"])
		if(!isnum(number))
			throw EXCEPTION("Некорректное точное число JSON сохранения")
		return number
	if(node["type"] == "matrix")
		var/list/numbers = player_save_decode_value(node["values"], depth + 1)
		if(!islist(numbers) || numbers.len != 6)
			throw EXCEPTION("Некорректная матрица JSON сохранения")
		return matrix(numbers[1], numbers[2], numbers[3], numbers[4], numbers[5], numbers[6])
	if(node["type"] == "path")
		var/resolved = text2path(node["value"])
		if(!resolved)
			throw EXCEPTION("Неизвестный путь типа в JSON сохранения")
		return resolved
	var/list/items = node["items"]
	var/list/associations = node["associations"]
	if(node["type"] != "list" || !islist(items) || !islist(associations) || items.len != associations.len)
		throw EXCEPTION("Некорректный список JSON сохранения")
	var/list/result = list()
	for(var/index in 1 to items.len)
		result += list(player_save_decode_value(items[index], depth + 1))
	for(var/index in 1 to items.len)
		var/associated = player_save_decode_value(associations[index], depth + 1)
		if(isnull(associated))
			continue
		var/key = result[index]
		if(isnull(key) || isnum(key))
			throw EXCEPTION("Некорректный ассоциативный ключ JSON сохранения")
		result[key] = associated
	return result

/// Копирует уже декодированные данные в памяти, без повторной сериализации каждого значения.
/proc/player_save_copy_tree(savefile/source, savefile/target, depth = 0)
	if(depth > PLAYER_SAVE_JSON_DEPTH)
		throw EXCEPTION("Слишком глубокое дерево сохранения")
	var/source_directory = source.cd
	var/target_directory = target.cd
	for(var/key in source.dir)
		var/value
		source[key] >> value
		target[key] << value
		source.cd = key
		target.cd = key
		player_save_copy_tree(source, target, depth + 1)
		source.cd = source_directory
		target.cd = target_directory

/// Переносит все узлы, включая неизвестные текущим загрузчикам поля и скрытые слоты.
/proc/player_save_encode_tree(savefile/source, depth = 0)
	if(depth > PLAYER_SAVE_JSON_DEPTH)
		throw EXCEPTION("Слишком глубокое дерево сохранения")
	var/original_directory = source.cd
	var/list/result = list()
	for(var/key in source.dir)
		var/value
		source[key] >> value
		source.cd = key
		var/list/children = player_save_encode_tree(source, depth + 1)
		source.cd = original_directory
		result[key] = list("value" = player_save_encode_value(value), "children" = children)
	return result

/proc/player_save_decode_tree(savefile/target, list/tree, depth = 0)
	if(!islist(tree) || depth > PLAYER_SAVE_JSON_DEPTH)
		throw EXCEPTION("Некорректное дерево JSON сохранения")
	var/original_directory = target.cd
	for(var/key in tree)
		if(!istext(key) || !length(key) || key == "." || key == ".." || findtext(key, "/") || findtext(key, "\\"))
			throw EXCEPTION("Некорректное имя узла JSON сохранения")
		var/list/node = tree[key]
		if(!islist(node) || !("value" in node) || !("children" in node))
			throw EXCEPTION("Неполный узел JSON сохранения")
		var/value = player_save_decode_value(node["value"])
		target[key] << value
		target.cd = key
		player_save_decode_tree(target, node["children"], depth + 1)
		target.cd = original_directory

/// Два поколения: оборванная запись одного файла не повреждает другое поколение.
/datum/player_save_json
	var/legacy_path
	var/json_path
	var/generation = 0
	var/active_path
	var/error
	var/recovered = FALSE
	var/recovery_reason
	var/list/directories
	var/content_fingerprint

/datum/player_save_json/New(source_path)
	legacy_path = source_path
	json_path = "[source_path].json"

/datum/player_save_json/proc/exists()
	return fexists(legacy_path) || fexists(json_path) || fexists("[json_path].recovery")

/datum/player_save_json/proc/read_document(source_path)
	var/list/document = json_decode(file2text(source_path))
	if(!islist(document) || document["format"] != "bluemoon-player-save")
		throw EXCEPTION("Неизвестный формат сохранения")
	if(document["version"] != PLAYER_SAVE_JSON_VERSION)
		// Не откатываемся к старому поколению при запуске старой версии сервера.
		error = "Неподдерживаемая версия JSON сохранения"
		throw EXCEPTION(error)
	var/sequence = document["generation"]
	if(!isnum(sequence) || sequence < 1 || sequence != round(sequence))
		throw EXCEPTION("Некорректное поколение JSON сохранения")
	var/list/tree = document["tree"]
	var/list/directory_versions = document["directories"]
	if(!isnull(directory_versions) && !islist(directory_versions))
		throw EXCEPTION("Некорректный каталог JSON сохранения")
	for(var/key in directory_versions)
		var/revision = directory_versions[key]
		if(!istext(key) || !isnum(revision) || revision < 1 || revision != round(revision))
			throw EXCEPTION("Некорректная версия раздела JSON сохранения")
	if(!islist(tree) || document["checksum"] != md5(json_encode(list(sequence, tree, directory_versions))))
		throw EXCEPTION("Не совпала контрольная сумма JSON сохранения")
	return document

/datum/player_save_json/proc/open(scope, required_generation)
	error = null
	directories = null
	recovered = FALSE
	generation = 0
	active_path = null
	content_fingerprint = null
	var/list/best
	var/found_json = FALSE
	for(var/candidate in list(json_path, "[json_path].recovery"))
		if(!fexists(candidate))
			continue
		found_json = TRUE
		var/list/document
		try
			document = read_document(candidate)
		catch(var/exception/failure)
			if(error)
				return null
			recovered = TRUE
			recovery_reason = failure.name
			continue
		if(required_generation && document["generation"] != required_generation)
			continue
		if(document["generation"] > generation)
			generation = document["generation"]
			active_path = candidate
			best = document
	if(found_json && !best)
		error = "Оба поколения JSON сохранения повреждены; запись заблокирована"
		return null
	if(required_generation && !best)
		error = "Не найдено поколение раздела, указанное в каталоге сохранения"
		return null
	var/savefile/result = new
	try
		var/list/tree
		if(best)
			tree = best["tree"]
			directories = best["directories"]
			content_fingerprint = md5(json_encode(list(tree, directories)))
		else if(fexists(legacy_path))
			// Открываем копию: даже чтение отсутствующего ключа изменяет savefile BYOND.
			var/static/import_sequence = 0
			var/import_id = md5("[world.realtime]-[world.timeofday]-[++import_sequence]")
			var/import_prefix = "[json_path].[import_id].import"
			var/import_path = "[import_prefix].sav"
			if(!fcopy(legacy_path, import_path))
				throw EXCEPTION("Не удалось скопировать старое сохранение")
			var/before_open = rustg_hash_file(RUSTG_HASH_MD5, import_path)
			var/savefile/legacy = new(import_path)
			legacy.Flush()
			if(rustg_hash_file(RUSTG_HASH_MD5, import_path) != before_open)
				throw EXCEPTION("BYOND исправил повреждённый старый файл; требуется проверка резервной копии")
			tree = player_save_encode_tree(legacy)
			legacy.Flush()
			if(fexists("[import_prefix]_bad_000.sav") || rustg_hash_file(RUSTG_HASH_MD5, import_path) != before_open)
				throw EXCEPTION("BYOND обнаружил повреждение старого файла; требуется проверка резервной копии")
			legacy = null
			fdel(import_path)
		if(!tree)
			tree = list()
		player_save_decode_tree(result, tree)
	catch(var/exception/failure)
		error = "Не удалось прочитать сохранение: [failure.name]"
		return null
	return result

/datum/player_save_json/proc/write_document(destination, encoded)
	if(fexists(destination) && !fdel(destination))
		return FALSE
	text2file(encoded, destination)
	return file2text(destination) == "[encoded]\n"

/datum/player_save_json/proc/commit(savefile/source, scope)
	if(error || !source)
		return FALSE
	var/original_directory = source.cd
	var/destination = active_path == json_path ? "[json_path].recovery" : json_path
	var/next_fingerprint
	try
		source.cd = "/"
		var/list/tree = player_save_encode_tree(source)
		source.cd = original_directory
		next_fingerprint = md5(json_encode(list(tree, directories)))
		// Повторное сохранение без изменений не расходует дисковые записи и поколения.
		if(active_path && !recovered && next_fingerprint == content_fingerprint)
			return TRUE
		var/list/document = list("format" = "bluemoon-player-save", "version" = PLAYER_SAVE_JSON_VERSION, "generation" = generation + 1, "tree" = tree, "directories" = directories, "checksum" = md5(json_encode(list(generation + 1, tree, directories))))
		var/encoded = json_encode(document)
		// Проверяем JSON до удаления старого поколения. Полный обход savefile здесь
		// не нужен: точность типизированного кодека проверяют тесты и прогон архива.
		if(json_encode(json_decode(encoded)) != encoded)
			throw EXCEPTION("JSON изменил данные при проверочном чтении")
		if(!write_document(destination, encoded))
			throw EXCEPTION("Записанный JSON не совпал с исходными данными")
	catch(var/exception/failure)
		source.cd = original_directory
		error = "Не удалось сохранить JSON: [failure.name]"
		return FALSE
	generation++
	active_path = destination
	content_fingerprint = next_fingerprint
	recovered = FALSE
	player_save_revision(json_path, TRUE)
	return TRUE

#undef PLAYER_SAVE_JSON_VERSION
#undef PLAYER_SAVE_JSON_DEPTH
