/// Команда, которую узел принимает по сети. Экземпляры - синглтоны в SSnetrun.commands
/datum/netrun_command
	var/id
	var/name = "команда"
	var/desc = ""
	/// Дополнительная справка команды; общие правила выводятся автоматически.
	var/help = ""
	/// Минимальный уровень доступа
	var/access = NETRUN_ACCESS_USER
	/// Трассировка за нелегальный вызов (умножается на защиту узла)
	var/trace = 6
	/// Иконка FontAwesome для кнопки
	var/icon = "terminal"
	/// Подсветить как опасную
	var/danger = FALSE
	/// Работает даже когда узел офлайн (например, диагностика)
	var/works_offline = FALSE
	/// Выполняется без задержки маршрута (ping сам измеряет задержку)
	var/ignores_latency = FALSE
	/// Diagnostic execution does not mutate the target's native state. Its logs and
	/// operator UI still update, without an extra native power/binding reconciliation.
	var/read_only = FALSE
	/// Interface section that renders this command instead of the generic list (e.g. "fortress").
	var/group
	/// Optional executable requirement, shared by cards and late delivery checks.
	var/required_daemon

/datum/netrun_command/proc/visible_to(datum/netrun_console/console)
	return !required_daemon || !!console.daemon_capability(required_daemon)

/// Выполнить команду. Возвращает текст результата или null при неудаче (причину пишет в консоль сам)
/datum/netrun_command/proc/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg, datum/netrun_request/request)
	return

/// Неизменяемые параметры конкретного пакета, отдельные от текущего выбора интерфейса.
/datum/netrun_request
	parent_type = /datum/netrun_delivery
	var/file_uid

/datum/netrun_request/New(file_uid)
	src.file_uid = file_uid

/// Подпись кнопки - команды органов добавляют имя органа
/datum/netrun_command/proc/display_name(datum/component/netrun_node/node, arg)
	return name

/datum/netrun_command/proc/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	var/level = console.node_level(node)
	var/legit = console.legit_node_level(node)
	var/reachable = console.can_route(node)
	var/online = works_offline || node.is_online(node != console.connection.jack)
	var/reason
	if(console.is_locked())
		reason = "Сетевой клиент заблокирован."
	else if(required_daemon && !console.daemon_capability(required_daemon))
		reason = "Нужна программа [required_daemon].exe."
	else if(!reachable)
		reason = "Нет действующего маршрута к узлу."
	else if(!online)
		reason = "Узел не отвечает."
	else if(level < access)
		reason = "Недостаточно прав: нужен [netrun_access_name(access)]."
	return list(
		"id" = full_id || id,
		"name" = display_name(node, netrun_command_arg(full_id)),
		"desc" = desc,
		"help" = help_text(node, console, full_id),
		"details" = help,
		"latency_ms" = ignores_latency ? 0 : console.latency_to(node) * 100,
		"works_offline" = works_offline,
		"unavailable_reason" = reason,
		"icon" = icon,
		"danger" = danger,
		"access" = access,
		"allowed" = !reason,
		"illegal" = legit < access,
		"trace" = legit < access ? round(trace * node.get_security() * console.effective_trace_mult()) : 0,
		"group" = group,
	)

/datum/netrun_command/proc/help_text(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	var/list/lines = list("[full_id || id] — [name]", desc, "Доступ: [netrun_access_name(access)].")
	if(length(help))
		lines += help
	if(node && console)
		lines += "Трассировка без авторизации: +[round(trace * node.get_security() * console.effective_trace_mult(), 0.1)]%."
		lines += ignores_latency ? "Выполняется без задержки маршрута." : "Доставка запроса: ~[console.latency_to(node) * 100] мс; маршрут и доступ проверяются при доставке."
	lines += works_offline ? "Допускается запрос к отключённому узлу." : "Требуется работающий узел."
	return jointext(lines, "\n")

/datum/netrun_command/node_log
	id = "node_log"
	read_only = TRUE
	name = "Журнал узла"
	desc = "Прочитать последние сетевые события этой машины."
	help = "Журнал следует за устройством при смене отсека. Содержит подключения, запросы, файловые операции и события защиты."
	access = NETRUN_ACCESS_USER
	trace = 2
	icon = "list"
	works_offline = TRUE

/datum/netrun_command/node_log/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	return length(node.logs) ? jointext(node.logs, "\n") : "Журнал пуст."

/datum/netrun_command/packet_log
	id = "packet_log"
	read_only = TRUE
	name = "Журнал пакетов"
	desc = "Отправка, пересылка, получение и отказы сетевых пакетов этого узла."
	help = "Последние 100 записей: время, ID, этап, адреса, служба и заголовки. SEND — отправка, FORWARD — пересылка, RECEIVE — получение, ACCEPT — принятие, REJECT/DROP — отказ. В карточке узла доступны заголовки последних 20 записей. Для содержимого нужен ROOT и расшифровка; общий буфер хранит 256 пакетов, до 4096 символов каждого."
	access = NETRUN_ACCESS_USER
	trace = 0
	icon = "list"
	works_offline = TRUE

/datum/netrun_command/packet_log/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	return node.packet_log_text()

/datum/netrun_command/packet_decrypt
	id = "packet_decrypt"
	read_only = TRUE
	name = "Расшифровать пакет"
	desc = "Прочитать содержимое захваченного пакета из журнала узла."
	help = "Выберите пакет в карточке узла. Нужен ROOT; маршрут и права перепроверяются при доставке. Большие и сложные пакеты показаны ограниченным фрагментом."
	access = NETRUN_ACCESS_ROOT
	trace = 4
	icon = "unlock"
	works_offline = TRUE

/datum/netrun_command/packet_decrypt/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	if(!arg)
		var/mob/sender = console.operator
		var/list/ids = list()
		for(var/list/entry as anything in node.packet_logs)
			ids |= entry["id"]
		arg = tgui_input_list(console.operator, "Выберите пакет", "Расшифровка", ids)
		// Native input yields; recheck the current operator, route and permissions.
		if(QDELETED(node) || QDELETED(console) || sender != console.operator || console.is_locked() || !console.can_route(node) || console.node_level(node) < NETRUN_ACCESS_ROOT)
			return
	return arg ? node.decode_packet(arg) : "Пакет не выбран."

/datum/netrun_command/firmware
	id = "firmware"
	name = "Обход ограничений"
	desc = "Запустить отдельный сложный взлом защиты прошивки устройства."
	help = "Нужны ROOT, icepick.exe и второй Breach Protocol повышенной сложности. Только собранный демон ROOT применяет штатный emag_act машины; доступ ROOT сам по себе ограничений не снимает. Неудача оставляет следы."
	access = NETRUN_ACCESS_ROOT
	trace = 0
	icon = "microchip"
	danger = TRUE

/datum/netrun_command/firmware/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	if(!console.daemon_capability("firmware"))
		return "Для атаки прошивки нужен icepick.exe в памяти."
	if(!console.start_breach("firmware", node.address))
		return "Нельзя начать взлом прошивки: проверьте соединение и активный взлом."
	return "Запущен подбор защиты прошивки."

// MARK: Общие команды

/datum/netrun_command/scan
	id = "scan"
	read_only = TRUE
	name = "Сканировать"
	desc = "Снять состояние узла."
	access = NETRUN_ACCESS_GUEST
	trace = 0
	icon = "magnifying-glass"
	works_offline = TRUE

/datum/netrun_command/scan/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	node.observe_location(TRUE)
	node.queue_presentation(NETRUN_CHANGED_STATE)
	var/atom/A = node.parent
	var/list/lines = list("[node.get_name()] [node.address] — [node.is_online() ? "в сети" : "НЕ ОТВЕЧАЕТ"], защита [node.get_security()]")
	lines += A.netrun_status()
	if(length(node.entities) && console.node_level(node) >= NETRUN_ACCESS_USER)
		lines += "Обнаружены резидентные процессы: [length(node.entities)]"
	if(LAZYLEN(node.netrun_ice))
		lines += "ВНИМАНИЕ: активные процессы защиты (ICE): [LAZYLEN(node.netrun_ice)]"
	return jointext(lines, "\n")

/datum/netrun_command/ping
	id = "ping"
	read_only = TRUE
	name = "Ping"
	desc = "Измерить задержку маршрута до узла."
	access = NETRUN_ACCESS_GUEST
	trace = 0
	icon = "stopwatch"
	works_offline = TRUE
	ignores_latency = TRUE

/datum/netrun_command/ping/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	if(!console.can_route(node))
		return "[node.address]: нет маршрута."
	var/datum/netrun_route/route = console.route_to(node)
	var/lat = route.latency
	var/route_name = route.name
	console.map_view.start_ping(route.hops)
	var/hops = max(0, length(route.hops) - 1)
	qdel(route)
	if(lat <= 0)
		return "[node.address]: 0мс ([route_name])"
	// Ответ приходит после того, как пакет дойдёт и вернётся
	addtimer(CALLBACK(console, TYPE_PROC_REF(/datum/netrun_console, ping_reply), node.address, lat, route_name), lat * 2)
	return "[node.address]: пакет отправлен, [hops] прыжков…"

/datum/netrun_command/traceroute
	id = "traceroute"
	read_only = TRUE
	name = "Трассировка маршрута"
	desc = "Показать маршрут и задержку до узла по реальному графу сети."
	access = NETRUN_ACCESS_GUEST
	trace = 0
	icon = "route"
	works_offline = TRUE
	ignores_latency = TRUE

/datum/netrun_command/traceroute/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	if(!console.can_route(node))
		return "[node.address]: нет маршрута."
	var/datum/netrun_route/route = console.route_to(node)
	var/list/lines = list("Маршрут до [node.get_name()] [node.address] — задержка ~[route.latency * 100] мс:")
	var/step = 0
	for(var/address in route.hops)
		var/datum/component/netrun_node/hop = SSnetrun.find_node(address["ref"])
		lines += "  [step++]. [hop ? "[hop.get_name()] " : ""][address["ref"]]"
	qdel(route)
	return jointext(lines, "\n")

/datum/netrun_command/siphon
	id = "siphon"
	name = "Слить файлы"
	desc = "Скопировать все читаемые файлы узла в локальную память одним запросом."
	help = "Нужен siphon.exe в памяти. Копирует столько файлов, сколько влезает в свободную память; остальные пропускаются."
	access = NETRUN_ACCESS_USER
	trace = 4
	icon = "download"

/datum/netrun_command/siphon/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	if(.["allowed"] && console.node_level(node) < (node.fortress?.file_access_level(console) || 0))
		.["allowed"] = FALSE
		.["unavailable_reason"] = "Хранилище крепости требует доступа ROOT."

/datum/netrun_command/siphon/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	if(console.node_level(node) < max(NETRUN_ACCESS_USER, node.fortress?.file_access_level(console) || 0))
		console.log_line("Хранилище крепости требует доступа ROOT.", "bad")
		return null
	if(!console.daemon_capability("siphon"))
		return "Для массового слива нужен siphon.exe в памяти."
	if(!node.file_store || !length(node.file_store.files))
		return "На узле нет доступных файлов."
	var/got = 0
	for(var/datum/netrun_file/file as anything in node.file_store.files.Copy())
		var/datum/netrun_file/duplicate = file.copy()
		if(console.store_file(duplicate))
			got++
		else
			qdel(duplicate)
	return got ? "Слито файлов в память: [got]." : "Нет места в памяти для файлов узла."

/datum/netrun_command/spoof_log
	id = "spoof_log"
	name = "Затереть журнал"
	desc = "Стереть журнал сетевых событий этого узла, скрыв следы активности."
	access = NETRUN_ACCESS_ROOT
	trace = 5
	icon = "eraser"
	danger = TRUE

/datum/netrun_command/spoof_log/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	node.logs.Cut()
	node.add_log("Журнал очищен.")
	return "Журнал узла затёрт."

/datum/netrun_command/reboot
	id = "reboot"
	name = "Перезагрузить"
	desc = "Отправить узел в перезагрузку на 20 секунд."
	access = NETRUN_ACCESS_ROOT
	trace = 4
	icon = "power-off"
	danger = TRUE

/datum/netrun_command/reboot/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	node.offline_until = world.time + 20 SECONDS
	return "Узел уходит в перезагрузку."

/datum/netrun_command/purge
	id = "purge"
	name = "Очистка"
	desc = "Вычистить резидентные процессы из памяти узла. Бьёт по сетевым сущностям внутри."
	access = NETRUN_ACCESS_ROOT
	trace = 3
	icon = "broom"
	danger = TRUE

/datum/netrun_command/purge/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	if(!LAZYLEN(node.entities))
		return "Посторонних процессов не найдено."
	var/hit = 0
	for(var/mob/camera/netrun_entity/entity as anything in node.entities.Copy())
		if(entity.console == console)
			continue
		hit++
		entity.take_integrity(45, "очистка памяти узла")
		if(!QDELETED(entity) && entity.host_node == node)
			entity.eject_from_node()
	if(!hit)
		return "Посторонних процессов не найдено."
	return "Очистка выполнена: вычищено процессов - [hit]."

/datum/netrun_command/issue_key
	id = "issue_key"
	name = "Выпустить ключ ЛВС"
	desc = "Записать ключ гостевого входа и перемещения сущности внутри ЛВС."
	help = "Ключ открывает обнаружение и переходы по соседним узлам этой ЛВС. Управление машинами по-прежнему требует подходящих ID-доступов или взлома конкретного узла."
	access = NETRUN_ACCESS_ROOT
	trace = 5
	icon = "key"

/datum/netrun_command/issue_key/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/datum/netrun_network/network = node.network
	if(!network)
		return
	var/datum/netrun_file/key = new("[network.id].key", NETRUN_FILE_KEY, network.passcode, 1, network.id)
	if(!console.store_file(key))
		qdel(key)
		console.log_line("Нет места в локальном хранилище.", "bad")
		return
	return "Ключ [network.short_name] записан в локальное хранилище."
