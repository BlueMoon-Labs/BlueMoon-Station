// Формат диска отделён от старых загрузчиков: savefile используется только в памяти.
// Это сохраняет порядок миграций, модульные поля и совместимость экспорта персонажей.
#define PLAYER_SAVE_JSON_VERSION 1
#define PLAYER_SAVE_JSON_DEPTH 64
#define PLAYER_SAVE_VALID_NODE_NAME(key) (istext(key) && length(key) && key != "." && key != ".." && !findtext(key, "/") && !findtext(key, "\\"))

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
		// Малые целые точно помещаются в шесть значащих цифр JSON BYOND.
		// Остальные числа сразу сохраняем точно, без пробного кодирования и разбора.
		if(value == round(value) && abs(value) < 1000000)
			return value
		return list("type" = "number", "value" = num2text(value, 20))
	if(istext(value))
		// JSON удаляет служебные маркеры вроде \proper. Ищем их без повторного разбора JSON.
		var/static/regex/control_characters = regex("\[\\x00-\\x1f\]")
		if(control_characters.Find(value) || findtext(value, copytext("\proper x", 1, 2)))
			var/escaped = replacetext(replacetext(value, "%", "%25"), copytext("\proper x", 1, 2), "%ff")
			for(var/code in 1 to 31)
				escaped = replacetext(escaped, ascii2text(code), "%[num2text(code, 2, 16)]")
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
	items.len = source.len
	associations.len = source.len
	for(var/index in 1 to source.len)
		var/key = source[index]
		items[index] = player_save_encode_value(key, depth + 1)
		// Число при индексации списка означает позицию, а не ассоциативный ключ.
		var/associated = isnull(key) || isnum(key) ? null : source[key]
		if(!isnull(associated))
			associations[index] = player_save_encode_value(associated, depth + 1)
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
		if(!istext(node["value"]))
			throw EXCEPTION("Некорректный путь типа в JSON сохранения")
		return text2path(node["value"])
	var/list/items = node["items"]
	var/list/associations = node["associations"]
	if(node["type"] != "list" || !islist(items) || !islist(associations) || items.len != associations.len)
		throw EXCEPTION("Некорректный список JSON сохранения")
	var/list/result = list()
	result.len = items.len
	for(var/index in 1 to items.len)
		result[index] = player_save_decode_value(items[index], depth + 1)
	for(var/index in 1 to items.len)
		if(isnull(associations[index]))
			continue
		var/associated = player_save_decode_value(associations[index], depth + 1)
		if(isnull(associated))
			continue
		var/key = result[index]
		if(isnull(key) || isnum(key))
			throw EXCEPTION("Некорректный ассоциативный ключ JSON сохранения")
		result[key] = associated
	return result

/// Читает значения исходного savefile через >>, пишет в целевой через << и рекурсивно копирует каталоги.
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
		if(depth + 1 > PLAYER_SAVE_JSON_DEPTH)
			throw EXCEPTION("Слишком глубокое дерево сохранения")
		var/list/children = length(source.dir) ? player_save_encode_tree(source, depth + 1) : list()
		source.cd = original_directory
		result[key] = list("value" = player_save_encode_value(value), "children" = children)
	return result

/proc/player_save_decode_tree(savefile/target, list/tree, depth = 0)
	if(!islist(tree) || depth > PLAYER_SAVE_JSON_DEPTH)
		throw EXCEPTION("Некорректное дерево JSON сохранения")
	var/original_directory = target.cd
	for(var/key in tree)
		if(!PLAYER_SAVE_VALID_NODE_NAME(key))
			throw EXCEPTION("Некорректное имя узла JSON сохранения")
		var/list/node = tree[key]
		if(!islist(node) || !("value" in node) || !("children" in node))
			throw EXCEPTION("Неполный узел JSON сохранения")
		var/value = player_save_decode_value(node["value"])
		target[key] << value
		var/list/children = node["children"]
		if(!islist(children) || depth + 1 > PLAYER_SAVE_JSON_DEPTH)
			throw EXCEPTION("Некорректное дерево JSON сохранения")
		if(length(children))
			target.cd = key
			player_save_decode_tree(target, children, depth + 1)
			target.cd = original_directory

/// Проверка снимка без записи каждого поля во временный savefile.
/proc/player_save_validate_tree(list/tree, depth = 0)
	if(!islist(tree) || depth > PLAYER_SAVE_JSON_DEPTH)
		throw EXCEPTION("Некорректное дерево JSON сохранения")
	for(var/key in tree)
		if(!PLAYER_SAVE_VALID_NODE_NAME(key))
			throw EXCEPTION("Некорректное имя узла JSON сохранения")
		var/list/node = tree[key]
		if(!islist(node) || !("value" in node) || !("children" in node))
			throw EXCEPTION("Неполный узел JSON сохранения")
		player_save_decode_value(node["value"])
		var/list/children = node["children"]
		if(!islist(children) || depth + 1 > PLAYER_SAVE_JSON_DEPTH)
			throw EXCEPTION("Некорректное дерево JSON сохранения")
		if(length(children))
			player_save_validate_tree(children, depth + 1)

/// Снимок раздела. Общие узлы неизменяемы; первая правка отделяет дерево читателя.
/datum/player_save_document
	var/datum/player_save_json/storage
	var/list/tree
	var/list/directories
	var/revision
	var/generation
	var/dirty = FALSE
	var/list/node_json

/datum/player_save_document/New(datum/player_save_json/owner, list/contents)
	storage = owner
	tree = contents
	directories = owner.directories
	revision = owner.open_revision
	generation = owner.generation
	node_json = owner.node_json || list()

/// Декодер возвращает отдельные списки: правка результата не изменяет снимок.
/datum/player_save_document/proc/read(key)
	var/list/node = tree[key]
	return node ? player_save_decode_value(node["value"]) : null

/datum/player_save_document/proc/write(key, value)
	if(!PLAYER_SAVE_VALID_NODE_NAME(key))
		throw EXCEPTION("Некорректное имя поля сохранения")
	var/encoded = player_save_encode_value(value)
	var/list/previous = tree[key]
	if(previous && !islist(encoded) && previous["value"] == encoded)
		return FALSE
	var/list/node = previous ? previous.Copy() : list("children" = list())
	node["value"] = encoded
	var/encoded_key = json_encode(key)
	var/encoded_node = "[encoded_key]:[json_encode(node)]"
	if(previous && encoded_node == (node_json[key] || "[encoded_key]:[json_encode(previous)]"))
		return FALSE
	mark_dirty()
	tree[key] = node
	node_json[key] = encoded_node
	return TRUE

/datum/player_save_document/proc/commit()
	return storage.commit_snapshot(src)

/// Перед первой правкой отделяет дерево и кэш JSON от опубликованного снимка.
/datum/player_save_document/proc/mark_dirty()
	if(dirty)
		return
	tree = tree.Copy()
	node_json = node_json.Copy()
	dirty = TRUE

/// Удаляет узел только из снимка; файлы раздела остаются доступны предыдущему поколению.
/datum/player_save_document/proc/remove(key)
	if(!(key in tree))
		return FALSE
	mark_dirty()
	tree -= key
	node_json -= key
	if(islist(directories) && (key in directories))
		directories = directories.Copy()
		directories -= key
	return TRUE

/// Писатель присылает только известные ему поля; неизвестные поля и ветви сохраняются.
/proc/player_save_merge_tree(list/original, list/patch)
	if(!length(patch))
		return original
	var/list/result = original
	for(var/key in patch)
		var/list/incoming = patch[key]
		var/list/previous = original[key]
		var/list/children = previous ? player_save_merge_tree(previous["children"], incoming["children"]) : incoming["children"]
		var/value = incoming["value"]
		if(previous && children == previous["children"] && (islist(value) ? json_encode(previous["value"]) == json_encode(value) : previous["value"] == value))
			continue
		if(result == original)
			result = original.Copy()
		result[key] = list("value" = value, "children" = children)
	return result

/datum/player_save_document/proc/merge(savefile/source)
	var/list/merged = player_save_merge_tree(tree, player_save_encode_tree(source))
	if(merged != tree)
		mark_dirty()
		for(var/key in merged)
			if(merged[key] != tree[key])
				node_json -= key
		tree = merged

/// Корень публикуется после раздела, как и в старой транзакции через savefile.
/datum/player_save_character_transaction
	var/datum/player_save_document/root
	var/datum/player_save_document/character
	var/key

/datum/player_save_character_transaction/proc/commit(savefile/source)
	var/datum/player_save_json/account/account = root.storage
	if(account.error || root.revision != player_save_revision(account.json_path) || root.generation != account.generation)
		account.error = "Аккаунт изменился во время подготовки персонажа"
		return FALSE
	var/original_directory = source.cd
	try
		source.cd = "/[key]"
		character.merge(source)
		source.cd = original_directory
		if(!character.commit())
			account.error = character.storage.error
			return FALSE
		root.write(key, character.read("real_name"))
		if(root.directories[key] != character.generation)
			root.directories = root.directories.Copy()
			root.directories[key] = character.generation
			root.dirty = TRUE
		return root.commit()
	catch(var/exception/failure)
		source.cd = original_directory
		account.error = failure.name
		return FALSE

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
	/// Канонический JSON содержимого нужен и для сравнения, и для контрольной суммы.
	var/content_json
	var/open_revision
	/// Последний проверенный или успешно записанный снимок; наружу выдаются документы.
	var/list/loaded_tree
	/// JSON неизменяемых узлов используется повторно при сравнении и публикации снимка.
	var/list/node_json

/datum/player_save_json/New(source_path)
	legacy_path = source_path
	json_path = "[source_path].json"

/datum/player_save_json/proc/exists()
	return fexists(legacy_path) || fexists(json_path) || fexists("[json_path].recovery")

/// Совместимый писатель тоже не должен затирать изменения другого датума после открытия.
/datum/player_save_json/proc/check_revision()
	if(error)
		return FALSE
	if(!isnull(open_revision) && open_revision != player_save_revision(json_path))
		error = "Сохранение изменилось после открытия; требуется повторное чтение"
		return FALSE
	return TRUE

/// Заголовок служит только подсказкой порядка; выбранный файл всё равно проверяется целиком.
/datum/player_save_json/proc/peek_generation(source_text)
	var/prefix = "{\"format\":\"bluemoon-player-save\",\"version\":[PLAYER_SAVE_JSON_VERSION],\"generation\":"
	if(copytext(source_text, 1, length(prefix) + 1) != prefix)
		return null
	var/end = findtext(source_text, ",\"tree\":", length(prefix) + 1, length(prefix) + 40)
	if(!end)
		return null
	var/encoded = copytext(source_text, length(prefix) + 1, end)
	var/sequence = text2num(encoded)
	if(!isnum(sequence) || sequence < 1 || sequence != round(sequence) || json_encode(sequence) != encoded)
		return null
	return sequence

/datum/player_save_json/proc/read_document(source_path, source_text)
	var/list/document = json_decode(isnull(source_text) ? file2text(source_path) : source_text)
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
	if(!islist(tree))
		throw EXCEPTION("Некорректное дерево JSON сохранения")
	var/list/encoded_nodes = list()
	var/encoded_content = "[encode_nodes(tree, encoded_nodes)],[json_encode(directory_versions)]"
	if(document["checksum"] != md5("\[[json_encode(sequence)],[encoded_content]\]"))
		throw EXCEPTION("Не совпала контрольная сумма JSON сохранения")
	document["content_json"] = encoded_content
	document["node_json"] = encoded_nodes
	return document

/// Порядок ключей и представление пустого дерева совпадают с json_encode(tree).
/datum/player_save_json/proc/encode_nodes(list/tree, list/encoded_nodes)
	if(!length(tree))
		return json_encode(tree)
	var/list/parts = list()
	parts.len = tree.len
	var/index = 0
	for(var/key in tree)
		var/encoded = encoded_nodes[key]
		if(isnull(encoded))
			encoded = "[json_encode(key)]:[json_encode(tree[key])]"
			encoded_nodes[key] = encoded
		parts[++index] = encoded
	return "{[jointext(parts, ",")]}"

/datum/player_save_json/proc/load_tree(required_generation, validate = TRUE)
	error = null
	directories = null
	recovered = FALSE
	generation = 0
	active_path = null
	content_json = null
	open_revision = null
	loaded_tree = null
	node_json = null
	recovery_reason = null
	var/list/best
	var/found_json = FALSE
	var/list/candidates = list()
	var/list/texts = list()
	var/list/sequences = list()
	var/known_headers = TRUE
	for(var/candidate in list(json_path, "[json_path].recovery"))
		if(!fexists(candidate))
			continue
		found_json = TRUE
		candidates += candidate
		texts[candidate] = file2text(candidate)
		sequences[candidate] = peek_generation(texts[candidate])
		if(isnull(sequences[candidate]))
			// Старое форматирование, неизвестная версия или оборванный заголовок:
			// полный разбор сохраняет прежние правила блокировки и восстановления.
			known_headers = FALSE
	if(known_headers && candidates.len == 2 && sequences[candidates[2]] > sequences[candidates[1]])
		candidates.Swap(1, 2)
	for(var/candidate in candidates)
		if(known_headers && required_generation && sequences[candidate] != required_generation)
			continue
		var/list/document
		try
			document = read_document(candidate, texts[candidate])
			if(required_generation && document["generation"] != required_generation)
				continue
			if(validate)
				player_save_validate_tree(document["tree"])
		catch(var/exception/failure)
			if(error)
				return null
			recovered = TRUE
			recovery_reason = failure.name
			continue
		if(document["generation"] > generation)
			generation = document["generation"]
			active_path = candidate
			best = document
		if(known_headers && best)
			break
	if(found_json && !best)
		error = "Оба поколения JSON сохранения повреждены; запись заблокирована"
		return null
	if(required_generation && !best)
		error = "Не найдено поколение раздела, указанное в каталоге сохранения"
		return null
	var/list/tree
	try
		if(best)
			tree = best["tree"]
			directories = best["directories"]
			content_json = best["content_json"]
			node_json = best["node_json"]
		else if(fexists(legacy_path))
			// Открываем копию: даже чтение отсутствующего ключа изменяет savefile BYOND.
			var/static/import_sequence = 0
			var/import_id = md5("[world.realtime]-[world.timeofday]-[++import_sequence]")
			var/import_prefix = "[json_path].[import_id].import"
			var/import_path = "[import_prefix].sav"
			var/savefile/legacy
			try
				if(!fcopy(legacy_path, import_path))
					throw EXCEPTION("Не удалось скопировать старое сохранение")
				var/before_open = rustg_hash_file(RUSTG_HASH_MD5, import_path)
				legacy = new(import_path)
				legacy.Flush()
				if(rustg_hash_file(RUSTG_HASH_MD5, import_path) != before_open)
					throw EXCEPTION("BYOND исправил повреждённый старый файл; требуется проверка резервной копии")
				tree = player_save_encode_tree(legacy)
				legacy.Flush()
				if(fexists("[import_prefix]_bad_000.sav") || rustg_hash_file(RUSTG_HASH_MD5, import_path) != before_open)
					throw EXCEPTION("BYOND обнаружил повреждение старого файла; требуется проверка резервной копии")
			catch(var/exception/failure)
				legacy = null
				fdel(import_path)
				fdel("[import_prefix]_bad_000.sav")
				throw failure
			legacy = null
			fdel(import_path)
			fdel("[import_prefix]_bad_000.sav")
		if(!tree)
			tree = list()
		if(validate && !best)
			player_save_validate_tree(tree)
	catch(var/exception/failure)
		error = "Не удалось прочитать сохранение: [failure.name]"
		return null
	open_revision = player_save_revision(json_path)
	loaded_tree = tree
	return tree

/datum/player_save_json/proc/snapshot(required_generation, use_cache = TRUE)
	if(!use_cache || error || !loaded_tree || open_revision != player_save_revision(json_path) || (required_generation && required_generation != generation))
		if(!load_tree(required_generation))
			return null
	return new /datum/player_save_document(src, loaded_tree)

/// Для меню достаточно проверить файл и одно поле, не декодируя всю анкету.
/datum/player_save_json/proc/read_field(key, required_generation)
	var/list/tree = loaded_tree
	if(error || !tree || open_revision != player_save_revision(json_path) || (required_generation && required_generation != generation))
		tree = load_tree(required_generation, FALSE)
		// Непроверенные поля не должны попасть в кэш последующего snapshot().
		loaded_tree = null
	if(!tree)
		return null
	try
		if(!(key in tree))
			return null
		var/list/node = tree[key]
		if(!islist(node) || !("value" in node) || !islist(node["children"]))
			throw EXCEPTION("Неполный узел JSON сохранения")
		return player_save_decode_value(node["value"])
	catch(var/exception/failure)
		error = "Не удалось прочитать поле сохранения: [failure.name]"
		return null

/datum/player_save_json/proc/open(scope, required_generation, savefile/target, use_cache = FALSE)
	// Декодирование ниже само проверяет дерево; не разбираем значения дважды.
	var/list/tree = loaded_tree
	if(!use_cache || error || !tree || open_revision != player_save_revision(json_path) || (required_generation && required_generation != generation))
		tree = load_tree(required_generation, FALSE)
	if(!tree)
		return null
	var/savefile/result = target || new /savefile
	try
		player_save_decode_tree(result, tree)
	catch(var/exception/failure)
		error = "Не удалось прочитать сохранение: [failure.name]"
		return null
	return result

/datum/player_save_json/proc/write_document(destination, encoded)
	if(fexists(destination) && !fdel(destination))
		throw EXCEPTION("Не удалось удалить предыдущее содержимое файла JSON")
	if(!text2file(encoded, destination))
		throw EXCEPTION("Не удалось записать содержимое файла JSON")
	return TRUE

/datum/player_save_json/proc/commit(savefile/source, scope)
	if(error || !source)
		return FALSE
	var/original_directory = source.cd
	var/list/tree
	try
		source.cd = scope || "/"
		tree = player_save_encode_tree(source)
		source.cd = original_directory
	catch(var/exception/failure)
		source.cd = original_directory
		error = "Не удалось подготовить сохранение: [failure.name]"
		return FALSE
	return commit_tree(tree)

/// Единственная точка публикации: снимок становится текущим только после записи.
/datum/player_save_json/proc/commit_tree(list/tree, list/encoded_nodes)
	if(!tree || !check_revision())
		return FALSE
	var/destination = active_path == json_path ? "[json_path].recovery" : json_path
	var/next_content
	if(!encoded_nodes)
		encoded_nodes = list()
	try
		var/encoded_tree = encode_nodes(tree, encoded_nodes)
		var/encoded_directories = json_encode(directories)
		next_content = "[encoded_tree],[encoded_directories]"
		// Повторное сохранение без изменений не расходует дисковые записи и поколения.
		if(active_path && !recovered && next_content == content_json)
			return TRUE
		// Вставляем готовые JSON-значения: дерево кодируется один раз, формат v1 сохранён.
		var/encoded_generation = json_encode(generation + 1)
		var/checksum = md5("\[[encoded_generation],[next_content]\]")
		var/encoded = "{\"format\":\"bluemoon-player-save\",\"version\":[PLAYER_SAVE_JSON_VERSION],\"generation\":[encoded_generation],\"tree\":[encoded_tree],\"directories\":[encoded_directories],\"checksum\":\"[checksum]\"}"
		if(!write_document(destination, encoded))
			throw EXCEPTION("Не удалось записать файл JSON")
	catch(var/exception/failure)
		error = "Не удалось сохранить JSON: [failure.name]"
		return FALSE
	generation++
	active_path = destination
	content_json = next_content
	recovered = FALSE
	open_revision = player_save_revision(json_path, TRUE)
	loaded_tree = tree
	node_json = encoded_nodes
	return TRUE

/datum/player_save_json/proc/commit_snapshot(datum/player_save_document/document)
	if(error || document.storage != src || document.revision != player_save_revision(json_path) || document.generation != generation)
		error = error || "Снимок сохранения устарел; требуется повторное чтение"
		return FALSE
	if(!document.dirty && active_path && !recovered)
		return TRUE
	var/list/previous_directories = directories
	directories = document.directories
	if(!commit_tree(document.tree, document.node_json))
		directories = previous_directories
		return FALSE
	document.revision = open_revision
	document.generation = generation
	document.dirty = FALSE
	return TRUE

#undef PLAYER_SAVE_JSON_VERSION
#undef PLAYER_SAVE_JSON_DEPTH
#undef PLAYER_SAVE_VALID_NODE_NAME
