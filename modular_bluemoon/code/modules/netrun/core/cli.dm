// MARK: Командная строка терминала
//
// Каждая команда CLI - датум /datum/netrun_cli_command (синглтон в SSnetrun.cli_commands).
// HELP и автодополнение строятся рефлексией по реестру: перебор датумов, чтение их полей
// и вызов их же методов (usage/detailed_help). Новая команда = новый подтип, ничего больше.

/datum/netrun_cli_command
	/// Имя команды (первое слово ввода)
	var/id
	/// Подсказка по аргументам, например "<адрес>"
	var/args = ""
	/// Короткое описание (одна строка, для общего help)
	var/desc = ""
	/// Раздел в справке
	var/category = "Общие"
	/// Stable UI pool key for verbs sharing the same completion values.
	var/completion_group

/// Подробная справка - список строк. По умолчанию из desc + usage; команды могут дополнять.
/datum/netrun_cli_command/proc/detailed_help(datum/netrun_console/console)
	. = list("[id] [args]", desc)

/// Выполнить. words - все слова ввода (words[1] = id), raw - исходная строка
/datum/netrun_cli_command/proc/execute(datum/netrun_console/console, list/words, raw)
	return

/// Варианты автодополнения для аргумента (адреса, коды сетей, имена файлов...)
/datum/netrun_cli_command/proc/completions(datum/netrun_console/console, partial)
	return list()

// MARK: Реестр и диспетчер

/datum/controller/subsystem/netrun/var/list/cli_commands

/datum/netrun_console
	/// One UI serialization only; caller clears it when the request has finished.
	var/list/ui_completion_cache
	var/list/cli_projection_context
	var/list/cli_projection_values
	var/list/cli_cached_context
	var/list/cli_cached_payload
	var/cli_cached_revision = 0

/// Authorization/loadout events invalidate both retained projections and an in-flight UI key.
/datum/netrun_console/proc/invalidate_projection_caches()
	ui_projection_cache = null
	ui_catalog_context = null
	ui_network_catalog = null
	ui_completion_cache?.Cut()
	cli_projection_context = null
	cli_projection_values = null
	cli_cached_context = null
	cli_cached_payload = null

/datum/controller/subsystem/netrun/proc/get_cli_commands()
	if(!cli_commands)
		cli_commands = list()
		for(var/datum/netrun_cli_command/path as anything in subtypesof(/datum/netrun_cli_command))
			if(!initial(path.id))
				continue
			var/datum/netrun_cli_command/command = new path
			cli_commands[command.id] = command
	return cli_commands

/// Quoting is shared by every verb: filenames are arguments, never daemon definition IDs.
/proc/netrun_cli_tokens(text)
	var/list/result = list()
	var/token = ""
	var/quote
	var/started = FALSE
	for(var/index = 1; index <= length_char(text); index++)
		var/character = copytext_char(text, index, index + 1)
		if(character == "\\")
			if(index == length_char(text))
				return null
			index++
			token += copytext_char(text, index, index + 1)
			started = TRUE
		else if(quote)
			if(character == quote)
				quote = null
			else
				token += character
		else if(character == "\"" || character == "'")
			quote = character
			started = TRUE
		else if(character == " " || character == "\t" || character == "\n")
			if(started)
				result += token
				token = ""
				started = FALSE
		else
			token += character
			started = TRUE
	if(quote)
		return null
	if(started)
		result += token
	return result

/datum/netrun_console/proc/cli(text)
	text = trim(copytext_char("[text]", 1, 513))
	if(!length(text))
		return
	log_line("$ [text]", "label")
	var/list/words = netrun_cli_tokens(text)
	if(isnull(words))
		log_line("Незакрытая кавычка или обратная косая черта в конце. Пример: exec \"Мой демон.exe\".", "bad")
		return
	if(!length(words))
		return
	var/verb_name = lowertext(words[1])
	var/list/registry = SSnetrun.get_cli_commands()
	var/datum/netrun_cli_command/command = registry[verb_name]
	if(!command)
		log_line("Неизвестная команда «[verb_name]». help — список команд.", "bad")
		return
	command.execute(src, words, text)

/// Список команд и актуальных аргументов для автодополнения в tgui
/datum/netrun_console/proc/cli_verbs()
	. = list()
	for(var/verb_name in SSnetrun.get_cli_commands())
		var/datum/netrun_cli_command/command = SSnetrun.cli_commands[verb_name]
		. += list(list("id" = command.id, "args" = command.args, "desc" = command.desc, "category" = command.category, "completions" = command.completions(src, "")))

/// Send shared address lists once rather than serializing one copy for each CLI verb.
/// Breach-only UI updates may request metadata without traversing completion candidates.
/datum/netrun_console/proc/cli_payload(include_completions = TRUE)
	var/datum/component/netrun_node/selected = selected_node()
	var/list/current_context = list(include_completions, ui_projection_context(), selected?.address,
		selected?.all_command_ids(), remote_session.windows.Copy())
	if(cli_cached_payload && netrun_snapshot_equal(cli_cached_context, current_context))
		return cli_cached_payload
	cli_cached_context = current_context
	var/list/verbs = list()
	var/list/pools = list()
	for(var/verb_name in SSnetrun.get_cli_commands())
		var/datum/netrun_cli_command/command = SSnetrun.cli_commands[verb_name]
		// Verb names and shared pool names occupy separate namespaces: the
		// no-argument `nodes` verb must not replace the shared address pool.
		var/group = command.completion_group || "verb:[command.id]"
		verbs += list(list("id" = command.id, "args" = command.args, "desc" = command.desc, "category" = command.category, "completion_key" = group))
		if(include_completions && !(group in pools))
			pools[group] = command.completions(src, "")
	cli_cached_payload = list("verbs" = verbs, "completions" = pools)
	cli_cached_revision++
	return cli_cached_payload

/// TGUI merges omitted top-level fields. Quiet polls do not serialize large completion pools.
/// ui_static_data supplies a baseline even after a browser refresh with the same UI datum.
/datum/netrun_console/proc/append_cli_payload(list/data, include_completions, list/session)
	var/list/payload = cli_payload(include_completions)
	if(!session || session["cli_revision"] != cli_cached_revision)
		data["cli"] = payload
		if(session)
			session["cli_revision"] = cli_cached_revision

/// Address and network completion share one projection of the current reachable graph.
/// Returned lists are read-only: callers combining categories must copy before appending.
/datum/netrun_console/proc/cli_completion_values(kind)
	if(islist(ui_completion_cache?[kind]))
		return ui_completion_cache[kind]
	var/list/current_context = ui_projection_context()
	if(cli_projection_values && netrun_snapshot_equal(cli_projection_context, current_context))
		return cli_projection_values[kind]
	// Standalone help/completion callers also get one bounded routing snapshot.
	var/owns_routes = !ui_routes
	if(owns_routes)
		ui_routes = connection.read_path_tree()
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/list/node_addresses = list()
	var/list/network_codes = list()
	var/list/network_levels = list()
	for(var/address in ui_routes.reached)
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node) || QDELETED(node.parent) || !node.network)
			continue
		var/datum/netrun_network/network = node.network
		// A LAN has one access level in this synchronous projection. Checking it
		// for every endpoint repeatedly resolves the same source, ID and route.
		if(isnull(network_levels[network.id]))
			network_levels[network.id] = network_level(network)
			network_codes += network.code
		// Keep the original CLI disclosure policy. Mapper alone does not reveal
		// locked endpoint addresses through these shared completion lists.
		// DM evaluates `in` after `||`: keep membership separate from authorization.
		if(network_levels[network.id] >= NETRUN_ACCESS_GUEST || (node.node_type in list(NETRUN_NODE_APC, NETRUN_NODE_GATEWAY)))
			node_addresses += node.address
	if(owns_routes)
		var/datum/netrun_path_tree/tree = ui_routes
		ui_routes = null
		release_path_tree(tree)
	cli_projection_context = current_context
	cli_projection_values = list("nodes" = node_addresses, "networks" = network_codes)
	if(ui_completion_cache)
		ui_completion_cache["nodes"] = node_addresses
		ui_completion_cache["networks"] = network_codes
	return kind == "nodes" ? node_addresses : network_codes

// MARK: help

/datum/netrun_cli_command/help
	id = "help"
	args = "\[команда\]"
	desc = "Список команд или подробная справка по одной."

/datum/netrun_cli_command/help/detailed_help(datum/netrun_console/console)
	return list("help \[команда\]", "Без аргумента - все команды по разделам. С аргументом - подробно об одной.")

/datum/netrun_cli_command/help/execute(datum/netrun_console/console, list/words, raw)
	var/list/registry = SSnetrun.get_cli_commands()
	if(length(words) > 1)
		var/datum/netrun_cli_command/target = registry[lowertext(words[2])]
		if(!target)
			var/datum/component/netrun_node/node = console.selected_node()
			var/full_id = lowertext(words[2])
			var/datum/netrun_command/request = SSnetrun.get_command(full_id)
			if(node && request && (full_id in node.all_command_ids()))
				console.log_line("run [full_id] — [request.display_name(node, netrun_command_arg(full_id))]", "label")
				for(var/line in splittext(request.help_text(node, console, full_id), "\n"))
					console.log_line(line)
				return
			console.log_line("Нет такой команды. help run — запросы выбранного узла.", "bad")
			return
		for(var/line in target.detailed_help(console))
			console.log_line(line)
		return
	// Автогенерация: группировка по разделам
	var/list/by_cat = list()
	for(var/verb_name in registry)
		var/datum/netrun_cli_command/command = registry[verb_name]
		LAZYADD(by_cat[command.category], command)
	for(var/category in by_cat)
		console.log_line("── [category]", "label")
		for(var/datum/netrun_cli_command/command as anything in by_cat[category])
			console.log_line("  [command.id] [command.args] — [command.desc]")
	console.log_line("help <команда> — подробно.", "label")

/datum/netrun_cli_command/help/completions(datum/netrun_console/console, partial)
	. = list()
	for(var/verb_name in SSnetrun.get_cli_commands())
		. += verb_name
	var/datum/component/netrun_node/node = console.selected_node()
	if(node)
		. |= node.all_command_ids()

// MARK: Навигация

/datum/netrun_cli_command/net
	id = "net"
	completion_group = "networks"
	args = "\[код|id\]"
	desc = "Список доступных сетей или открыть одну."
	category = "Навигация"

/datum/netrun_cli_command/net/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) < 2)
		for(var/network_id in SSnetrun.networks)
			var/datum/netrun_network/network = SSnetrun.networks[network_id]
			if(console.can_reach(network))
				console.log_line("[network.code] ([network.id]) — [network.name], узлов: [length(network.nodes)], доступ: [netrun_access_name(console.network_level(network))]")
		return
	var/datum/netrun_network/network = SSnetrun.find_network(words[2])
	if(!network || !console.can_reach(network))
		console.log_line("Сеть недоступна.", "bad")
		return
	console.map_view.viewed_network_id = network.id
	console.map_view.selected_network = network.id
	console.map_view.selected_address = null
	console.remote_session.active_window = null
	console.log_line("Открыта сеть [network.code].")

/datum/netrun_cli_command/net/completions(datum/netrun_console/console, partial)
	return console.cli_completion_values("networks")

/datum/netrun_cli_command/sel
	id = "sel"
	completion_group = "nodes"
	args = "<адрес>"
	desc = "Выбрать узел по адресу."
	category = "Навигация"

/datum/netrun_cli_command/sel/execute(datum/netrun_console/console, list/words, raw)
	var/datum/component/netrun_node/node = SSnetrun.find_node(length(words) > 1 ? words[2] : null)
	if(!node || !console.node_visible(node))
		console.log_line("Узел не найден или нет доступа.", "bad")
		return
	console.map_view.selected_address = node.address
	console.map_view.selected_network = null
	console.remote_session.active_window = null
	console.map_view.viewed_network_id = null
	console.log_line("Выбран [node.get_name()] [node.address].")

/datum/netrun_cli_command/sel/completions(datum/netrun_console/console, partial)
	return console.cli_completion_values("nodes")

/datum/netrun_cli_command/nodes
	id = "nodes"
	desc = "Список узлов текущей сети."
	category = "Навигация"

/datum/netrun_cli_command/nodes/execute(datum/netrun_console/console, list/words, raw)
	var/datum/netrun_network/network = SSnetrun.networks[console.map_view.selected_network || console.map_view.viewed_network_id]
	if(!network)
		var/datum/component/netrun_node/node = console.selected_node()
		network = node?.network || console.connection.jack?.network
	if(!network || console.network_level(network) < NETRUN_ACCESS_GUEST)
		console.log_line("Нет открытой сети.", "bad")
		return
	for(var/datum/component/netrun_node/node as anything in network.nodes)
		console.log_line("[node.address] [node.get_name()] ([node.node_type], [netrun_access_name(console.node_level(node))])")

/datum/netrun_cli_command/open
	id = "open"
	completion_group = "nodes"
	args = "\[адрес\]"
	desc = "Открыть выбранный узел или указанный адрес во вкладке."
	category = "Навигация"

/datum/netrun_cli_command/open/execute(datum/netrun_console/console, list/words, raw)
	var/datum/component/netrun_node/node = length(words) > 1 ? SSnetrun.find_node(words[2]) : console.selected_node()
	if(!node || !console.open_window(node.address))
		console.log_line("Узел не найден или недоступен.", "bad")

/datum/netrun_cli_command/open/completions(datum/netrun_console/console, partial)
	var/list/registry = SSnetrun.get_cli_commands()
	var/datum/netrun_cli_command/command = registry["sel"]
	return command.completions(console, partial)

/datum/netrun_cli_command/close
	id = "close"
	args = "\[адрес\]"
	desc = "Закрыть активную вкладку или вкладку указанного узла."
	category = "Навигация"

/datum/netrun_cli_command/close/execute(datum/netrun_console/console, list/words, raw)
	var/address = length(words) > 1 ? uppertext(words[2]) : console.remote_session.active_window
	if(!(address in console.remote_session.windows))
		console.log_line("Такая вкладка не открыта.", "bad")
		return
	console.close_window(address)

/datum/netrun_cli_command/close/completions(datum/netrun_console/console, partial)
	return console.remote_session.windows.Copy()

/datum/netrun_cli_command/info
	id = "info"
	desc = "Связь, точка подключения, трассировка и выбранный узел."
	category = "Общие"

/datum/netrun_cli_command/info/execute(datum/netrun_console/console, list/words, raw)
	console.log_line("Точка: [console.name] ([console.origin]); [console.connection.wireless ? "беспроводная связь" : "проводная связь"].", "label")
	console.log_line("NTnet: [console.has_uplink() ? "связь есть" : "нет связи"]. Трассировка: [round(console.intrusion.trace, 0.1)]%.")
	if(console.is_locked())
		console.log_line("Блокировка: [round((console.intrusion.lockout_until - world.time) / (1 SECONDS))] с.", "bad")
	var/datum/component/netrun_node/node = console.selected_node()
	if(node)
		console.log_line("Цель: [node.get_name()] [node.address], доступ [netrun_access_name(console.node_level(node))], сеть [node.network?.code].")
	else
		console.log_line("Узел не выбран. sel <адрес> — выбрать, net — список кодов сетей.")

// MARK: Действия с узлами

/datum/netrun_cli_command/run
	id = "run"
	args = "<команда|файл> \[цель\]"
	desc = "Команда выбранного узла или исполняемый файл по текущему имени."
	category = "Действия"

/datum/netrun_cli_command/run/detailed_help(datum/netrun_console/console)
	. = list("run <команда|файл> \[цель\]", "Команды выбранного узла перечислены ниже. Для файла используйте текущее имя или UID; exec всегда обращается к файлу.", "Имена с пробелами заключайте в кавычки: exec \"Мой щит.exe\". Боевой цели нужен REF из targets.", "Демоны дают пассивный эффект, пока находятся на подключённом носителе.", "Доступные команды узла:")
	var/datum/component/netrun_node/node = console.selected_node()
	if(!node)
		. += "  (узел не выбран)"
		return
	for(var/command_id in node.all_command_ids())
		var/datum/netrun_command/command = SSnetrun.get_command(command_id)
		if(command)
			. += "  [command_id] — [command.desc || command.name] ([netrun_access_name(command.access)])"

/datum/netrun_cli_command/run/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) < 2)
		console.log_line("Укажите команду: run <команда>.", "bad")
		return
	var/datum/component/netrun_node/node = console.selected_node()
	var/command_id = lowertext(words[2])
	if(node && (command_id in node.all_command_ids()))
		console.run_command(node, command_id)
		return
	console.cli_execute_file(words[2], length(words) > 2 ? words[3] : null)

/datum/netrun_cli_command/run/completions(datum/netrun_console/console, partial)
	. = list()
	var/datum/component/netrun_node/node = console.selected_node()
	if(node)
		for(var/command_id in node.all_command_ids())
			. += command_id
	. |= console.cli_file_completions(list(NETRUN_FILE_DAEMON, NETRUN_FILE_PROGRAM))

/datum/netrun_cli_command/scan
	id = "scan"
	desc = "Сканировать выбранный узел."
	category = "Действия"

/datum/netrun_cli_command/scan/execute(datum/netrun_console/console, list/words, raw)
	console.run_command(console.selected_node(), "scan")

/datum/netrun_cli_command/ping
	id = "ping"
	completion_group = "nodes"
	args = "\[адрес\]"
	desc = "Задержка маршрута до узла."
	category = "Действия"

/datum/netrun_cli_command/ping/execute(datum/netrun_console/console, list/words, raw)
	var/datum/component/netrun_node/node = length(words) > 1 ? SSnetrun.find_node(words[2]) : console.selected_node()
	console.run_command(node, "ping")

/datum/netrun_cli_command/ping/completions(datum/netrun_console/console, partial)
	var/list/registry = SSnetrun.get_cli_commands()
	var/datum/netrun_cli_command/command = registry["sel"]
	return command.completions(console, partial)

/datum/netrun_cli_command/breach
	id = "breach"
	completion_group = "targets"
	args = "\[адрес|код сети\]"
	desc = "Запустить подбор доступа."
	category = "Действия"

/datum/netrun_cli_command/breach/execute(datum/netrun_console/console, list/words, raw)
	var/token = length(words) > 1 ? words[2] : null
	var/datum/netrun_network/network = token ? SSnetrun.find_network(token) : null
	if(network)
		console.start_breach("network", network.id)
	else
		console.start_breach("node", token || console.map_view.selected_address)

/datum/netrun_cli_command/breach/completions(datum/netrun_console/console, partial)
	var/list/node_addresses = console.cli_completion_values("nodes")
	. = node_addresses.Copy()
	. += console.cli_completion_values("networks")

// MARK: Память

/datum/netrun_cli_command/ls
	id = "ls"
	desc = "Файлы в локальном хранилище и на шарде."
	category = "Память"

/datum/netrun_cli_command/ls/execute(datum/netrun_console/console, list/words, raw)
	var/list/files = console.all_files()
	if(!length(files))
		console.log_line("Хранилище пусто.")
		return
	for(var/datum/netrun_file/file as anything in files)
		console.log_line("[file.name] — [file.kind], [file.size] памяти · [console.inventory.store_for(file) == console.inventory.local_store ? "local" : "shard"] · UID [file.uid]")

/datum/netrun_cli_command/mem
	id = "mem"
	desc = "Занятость памяти терминала и шарда."
	category = "Память"

/datum/netrun_cli_command/mem/execute(datum/netrun_console/console, list/words, raw)
	console.log_line("Память: [netrun_storage_used(console.inventory.local_store.files)]/[console.inventory.local_store.capacity]")
	if(console.inventory.shard)
		console.log_line("Шард [console.inventory.shard.name]: [netrun_storage_used(console.inventory.shard.file_store.files)]/[console.inventory.shard.file_store.capacity]")

/datum/netrun_cli_command/daemons
	id = "daemons"
	args = "\[id\]"
	desc = "Каталог программ, их эффекты и наличие в памяти или на шарде."
	category = "Память"

/datum/netrun_cli_command/daemons/detailed_help(datum/netrun_console/console)
	. = ..()
	. += "Демоны работают автоматически из локальной памяти или подключённого шарда. Копии не складываются."
	for(var/list/definition as anything in SSnetrun.daemon_definitions())
		. += "  [definition["id"]] — [definition["name"]]: [definition["desc"]]"

/datum/netrun_cli_command/daemons/execute(datum/netrun_console/console, list/words, raw)
	var/filter = length(words) > 1 ? lowertext(words[2]) : null
	if(filter && !SSnetrun.get_daemon(filter))
		console.log_line("Программа не найдена. daemons — каталог.", "bad")
		return
	for(var/list/definition as anything in SSnetrun.daemon_definitions())
		if(filter && definition["id"] != filter)
			continue
		var/list/installed = list()
		for(var/datum/netrun_file/file as anything in console.all_files())
			if(file.kind == NETRUN_FILE_DAEMON && file.content == definition["id"])
				installed += "[file.name] (#[file.uid])"
		console.log_line("[definition["id"]] — [definition["name"]] ([definition["size"]] памяти): [length(installed) ? "активна: [jointext(installed, ", ")]" : "не установлена"].", length(installed) ? "good" : "label")
		console.log_line("  [definition["desc"]]")

/datum/netrun_cli_command/daemons/completions(datum/netrun_console/console, partial)
	. = list()
	for(var/list/definition as anything in SSnetrun.daemon_definitions())
		. += definition["id"]

/datum/netrun_cli_command/rm
	id = "rm"
	args = "<имя|UID>"
	desc = "Удалить файл из памяти или подключённого шарда."
	category = "Память"

/datum/netrun_cli_command/rm/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) < 2)
		console.log_line("Укажите имя файла.", "bad")
		return
	var/datum/netrun_file/file = console.cli_file(words[2])
	if(file)
		var/file_name = file.name
		if(console.delete_local_file(file))
			console.log_line("Удалён [file_name].", "good")

/datum/netrun_cli_command/rm/completions(datum/netrun_console/console, partial)
	return console.cli_file_completions()

/// Always resolve live disk membership. Definition IDs describe effects, not executable paths.
/datum/netrun_console/proc/cli_file(selector, list/kinds)
	if(!istext(selector) || !length(selector))
		log_line("Укажите текущее имя файла или #UID. ls — содержимое носителей.", "bad")
		return null
	var/wanted = lowertext(selector)
	var/datum/netrun_file_store/disk
	if(findtext(wanted, "local:") == 1)
		disk = inventory.local_store
		wanted = copytext(wanted, 7)
	else if(findtext(wanted, "shard:") == 1)
		disk = inventory.shard?.file_store
		wanted = copytext(wanted, 7)
		if(!disk)
			log_line("Шард не подключён.", "bad")
			return null
	var/list/files = disk ? disk.files : all_files(TRUE)
	var/list/matches = list()
	var/explicit_uid = findtext(wanted, "#") == 1
	for(var/datum/netrun_file/file as anything in files)
		if(explicit_uid && wanted == "#[file.uid]")
			matches = list(file)
			break
		if(!explicit_uid && lowertext(file.name) == wanted)
			matches += file
	// A bare number can be a real current filename. Preserve that name before
	// accepting legacy unprefixed UIDs; #UID is the explicit identity namespace.
	if(!explicit_uid && !length(matches))
		for(var/datum/netrun_file/file as anything in files)
			if(wanted == file.uid)
				matches = list(file)
				break
	if(length(matches) != 1)
		if(!length(matches))
			log_line("Файл «[selector]» не найден. ls — текущие имена и UID.", "bad")
		else
			var/list/options = list()
			for(var/datum/netrun_file/file as anything in matches)
				options += "#[file.uid] ([inventory.store_for(file) == inventory.local_store ? "local" : "shard"])"
			log_line("Несколько файлов «[selector]»: [jointext(options, ", ")]. Укажите #UID или local:/shard: перед именем.", "bad")
		return null
	var/datum/netrun_file/result = matches[1]
	if(length(kinds) && !(result.kind in kinds))
		log_line("Файл [result.name] не подходит для этой операции ([result.kind]).", "bad")
		return null
	return result

/datum/netrun_console/proc/cli_file_completions(list/kinds)
	. = list()
	for(var/datum/netrun_file/file as anything in all_files())
		if(!length(kinds) || (file.kind in kinds))
			. |= list(file.name, "#[file.uid]")

/datum/netrun_console/proc/cli_execute_file(selector, target_ref)
	var/datum/netrun_file/file = cli_file(selector, list(NETRUN_FILE_DAEMON, NETRUN_FILE_PROGRAM, NETRUN_FILE_BOT))
	if(!file)
		return FALSE
	if(file.kind == NETRUN_FILE_BOT)
		// target_ref doubles as an optional node address for the agent's launch site.
		return launch_bot_file(file.uid, target_ref)
	if(file.kind == NETRUN_FILE_DAEMON)
		var/datum/netrun_program/daemon/daemon = SSnetrun.get_daemon(file.content)
		if(!daemon)
			log_line("Исполняемый файл [file.name] повреждён.", "bad")
			return FALSE
		log_line("[file.name]: пассивный демон уже работает с подключённого носителя. [daemon.desc]", "good")
		return TRUE
	return program_use(file.uid, target_ref)

/datum/netrun_cli_command/exec
	id = "exec"
	args = "<имя|#UID> \[REF цели\]"
	desc = "Запустить боевой файл, программу-агента или проверить работу пассивного демона."
	category = "Память"

/datum/netrun_cli_command/exec/execute(datum/netrun_console/console, list/words, raw)
	console.cli_execute_file(length(words) > 1 ? words[2] : null, length(words) > 2 ? words[3] : null)

/datum/netrun_cli_command/exec/detailed_help(datum/netrun_console/console)
	. = ..()
	. += list("Пример: exec \"Мой щит.exe\". Имена и #UID смотрите в ls.", "Файлы выбираются по текущему имени, не по ID из каталога демонов. При совпадениях используйте #UID, local:имя или shard:имя.", "Демоны работают пассивно из памяти и подключённого шарда. Боевые программы запускаются через тот же механизм, что во вкладке боя; targets показывает REF целей.")

/datum/netrun_cli_command/exec/completions(datum/netrun_console/console, partial)
	return console.cli_file_completions(list(NETRUN_FILE_DAEMON, NETRUN_FILE_PROGRAM, NETRUN_FILE_BOT))

/datum/netrun_cli_command/targets
	id = "targets"
	desc = "Цели доступных боевых программ и их REF для exec."
	category = "Действия"

/datum/netrun_cli_command/targets/execute(datum/netrun_console/console, list/words, raw)
	var/list/targets = console.combat_targets()
	if(!length(targets))
		console.log_line("Нет боевых контактов. Цель должна быть на вашем узле или атаковать вашу сессию.")
	for(var/list/entry as anything in targets)
		console.log_line("[entry["name"]] · [entry["integrity"]]/[entry["max_integrity"]] · [entry["ref"]][entry["unavailable_reason"] ? " · [entry["unavailable_reason"]]" : ""]")

/datum/netrun_cli_command/pursue
	id = "pursue"
	args = "<REF цели|stop>"
	desc = "Зафиксировать процесс и идти за ним по разрешённым узлам; атаки запускаются вручную."
	category = "Действия"

/datum/netrun_cli_command/pursue/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) < 2)
		console.log_line("Использование: pursue <REF из targets> или pursue stop.", "average")
		return
	if(lowertext(words[2]) == "stop")
		console.stop_pursuit()
	else
		console.start_pursuit(words[2])

/datum/netrun_cli_command/pursue/completions(datum/netrun_console/console, partial)
	. = list("stop")
	for(var/list/target as anything in console.combat_targets())
		if(target["kind"] in list("entity", "bot"))
			. += target["ref"]

/datum/netrun_cli_command/cat
	id = "cat"
	args = "<имя|#UID>"
	desc = "Прочитать текстовый файл прямо в терминале."
	category = "Память"

/datum/netrun_cli_command/cat/execute(datum/netrun_console/console, list/words, raw)
	var/datum/netrun_file/file = console.cli_file(length(words) > 1 ? words[2] : null, list(NETRUN_FILE_TEXT))
	if(file)
		console.inventory.selected_file_uid = file.uid
		console.log_line("── [file.name] · #[file.uid]", "label")
		console.log_line(file.content || "(пустой файл)")

/datum/netrun_cli_command/cat/completions(datum/netrun_console/console, partial)
	return console.cli_file_completions(list(NETRUN_FILE_TEXT))

/datum/netrun_cli_command/rename
	id = "rename"
	args = "<имя|#UID> <новое имя>"
	desc = "Переименовать файл. Для пробелов используйте кавычки."
	category = "Память"

/datum/netrun_cli_command/rename/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) != 3)
		console.log_line("Использование: rename <имя|#UID> <новое имя>. Имена с пробелами заключайте в кавычки.", "bad")
		return
	var/datum/netrun_file/file = console.cli_file(words[2])
	if(file)
		console.rename_local_file(file, words[3])

/datum/netrun_cli_command/rename/completions(datum/netrun_console/console, partial)
	return console.cli_file_completions()

/datum/netrun_cli_command/cp
	id = "cp"
	args = "<имя|#UID> <local|shard>"
	desc = "Скопировать файл на выбранный носитель."
	category = "Память"
	var/move = FALSE

/datum/netrun_cli_command/cp/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) != 3 || !(lowertext(words[3]) in list("local", "shard")))
		console.log_line("Использование: [id] <имя|#UID> <local|shard>.", "bad")
		return
	var/datum/netrun_file/file = console.cli_file(words[2])
	if(file)
		console.transfer_local_file(file, lowertext(words[3]) == "shard", move)

/datum/netrun_cli_command/cp/completions(datum/netrun_console/console, partial)
	return console.cli_file_completions() | list("local", "shard")

/datum/netrun_cli_command/mv
	parent_type = /datum/netrun_cli_command/cp
	id = "mv"
	desc = "Переместить файл между памятью и шардом без изменения UID."
	move = TRUE

// MARK: Оформление клиента и личность процесса

/datum/netrun_cli_command/agent
	id = "agent"
	args = "\[REF behavior <profile|patrol|scavenge|guard> <агрессия> <осторожность> <on|off>\]"
	desc = "Список собственных агентов или изменение их стратегии, агрессии, осторожности и сотрудничества через обычный пакет приказа."
	category = "Действия"

/datum/netrun_cli_command/agent/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) == 1)
		var/list/agents = console.agents()
		if(!length(agents))
			console.log_line("Нет запущенных собственных агентов.")
		for(var/mob/camera/netrun_entity/bot/agent as anything in agents)
			var/list/behavior = agent.behavior_settings()
			console.log_line("[agent.real_name] · [REF(agent)] · [behavior?["strategy"] || "нет паттерна"] · агрессия [behavior?["aggression"]] · осторожность [behavior?["caution"]] · сотрудничество [behavior?["cooperation"] ? "on" : "off"]")
		return
	if(length(words) != 7 || lowertext(words[3]) != "behavior" || !(lowertext(words[7]) in list("on", "off")))
		console.log_line("Использование: agent <REF> behavior <profile|patrol|scavenge|guard> <0–100> <0–100> <on|off>.", "bad")
		return
	var/list/changes = list("strategy" = lowertext(words[4]), "aggression" = text2num(words[5]), "caution" = text2num(words[6]), "cooperation" = lowertext(words[7]) == "on")
	if(console.agent_order(words[2], "behavior", null, changes))
		console.log_line("Изменение поведения отправлено агенту.", "average")

/datum/netrun_cli_command/agent/completions(datum/netrun_console/console, partial)
	. = list("behavior", "profile", "patrol", "scavenge", "guard", "on", "off")
	for(var/mob/camera/netrun_entity/bot/agent as anything in console.agents())
		. += REF(agent)

/datum/netrun_cli_command/theme
	id = "theme"
	args = "\[стиль\]"
	desc = "Текущая тема интерфейса или выбор нового оформления."
	category = "Оформление"

/datum/netrun_cli_command/theme/execute(datum/netrun_console/console, list/words, raw)
	if(length(words) < 2)
		console.log_line("Тема: [console.theme_id()]. Доступны: [jointext(netrun_theme_ids(), ", ")].", "label")
	else if(console.set_ui_theme(lowertext(words[2]), console.operator))
		console.log_line("Выбрана тема [console.theme_id()].", "good")
	else
		console.log_line("Не удалось сменить тему. theme — доступные стили.", "bad")

/datum/netrun_cli_command/theme/completions(datum/netrun_console/console, partial)
	return netrun_theme_ids()

/datum/netrun_cli_command/profile
	id = "profile"
	args = "\[name|avatar|accent|tagline\] \[значение\]"
	desc = "Посмотреть или изменить собственный профиль сетевой сущности."
	category = "Оформление"

/datum/netrun_cli_command/profile/execute(datum/netrun_console/console, list/words, raw)
	if(!istype(console.host, /mob/camera/netrun_entity))
		console.log_line("Профиль доступен собственной сетевой сущности. Для оформления клиента используйте theme.", "bad")
		return
	var/mob/camera/netrun_entity/entity = console.host
	if(length(words) < 2)
		var/datum/netrun_persona/persona = entity.get_persona()
		console.log_line("[entity.real_name] · аватар [persona.avatar] · акцент [persona.accent]", "label")
		console.log_line(persona.tagline || "Подпись не задана. profile tagline \"Ваша подпись\" — изменить.")
		return
	if(length(words) != 3 || !(words[2] in list("name", "avatar", "accent", "tagline")) || !console.update_persona(list("[words[2]]" = words[3]), console.operator))
		console.log_line("Использование: profile <name|avatar|accent|tagline> <значение>. help profile — доступные аватары и акценты.", "bad")
		return
	console.log_line("Профиль обновлён.", "good")

/datum/netrun_cli_command/profile/detailed_help(datum/netrun_console/console)
	. = ..()
	var/list/avatars = list()
	for(var/list/option as anything in netrun_avatar_options())
		avatars += option["id"]
	var/list/accents = list()
	for(var/list/option as anything in netrun_accent_options())
		accents += option["id"]
	. += list("Аватары: [jointext(avatars, ", ")].", "Акценты: [jointext(accents, ", ")].", "Пример: profile tagline \"Тихий сигнал\". Профиль меняет только внешность вашего процесса, не его доступы.")

/datum/netrun_cli_command/profile/completions(datum/netrun_console/console, partial)
	return list("name", "avatar", "accent", "tagline")

// MARK: Связь

/datum/netrun_cli_command/chat
	id = "chat"
	args = "<текст>"
	desc = "Отправить сообщение в канал #noosphere."
	category = "Связь"

/datum/netrun_cli_command/chat/execute(datum/netrun_console/console, list/words, raw)
	var/message = length(words) > 1 ? copytext(raw, length(words[1]) + 2) : null
	if(!message)
		console.log_line("Пустое сообщение.", "bad")
		return
	console.chat_send(message)

// MARK: Экран

/datum/netrun_cli_command/clear
	id = "clear"
	desc = "Очистить экран терминала."
	category = "Экран"

/datum/netrun_cli_command/clear/execute(datum/netrun_console/console, list/words, raw)
	console.log.Cut()
