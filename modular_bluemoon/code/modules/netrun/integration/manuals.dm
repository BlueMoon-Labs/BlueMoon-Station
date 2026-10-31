/// Built-in documentation is firmware: it reserves no writable payload capacity.
/// Downloading it produces an ordinary text file charged to the destination disk.
/datum/netrun_file/manual
	var/datum/weakref/node_ref
	var/cached_name
	var/cached_node_type
	var/datum/netrun_provider/cached_provider
	var/list/cached_actions
	var/list/cached_commands
	var/list/cached_access
	var/list/cached_services
	var/cached_notes

/datum/netrun_file/manual/New(datum/component/netrun_node/node)
	node_ref = WEAKREF(node)
	..("readme.txt", NETRUN_FILE_TEXT, "")
	size = 0
	refresh_text()

/datum/netrun_file/manual/Destroy()
	node_ref = null
	cached_provider = null
	cached_actions = null
	cached_commands = null
	cached_access = null
	cached_services = null
	return ..()

/datum/netrun_file/manual/proc/refresh_text()
	var/datum/component/netrun_node/node = node_ref?.resolve()
	var/atom/host = node?.parent
	if(QDELETED(host))
		return
	var/list/commands = node.all_command_ids()
	var/datum/netrun_provider/provider = SSnetrun.get_provider(host)
	var/notes = host.netrun_manual_notes()
	if(cached_name == host.name && cached_node_type == node.node_type && cached_provider == provider && cached_actions == provider?.actions && cached_notes == notes && netrun_snapshot_equal(cached_commands, commands) && netrun_snapshot_equal(cached_access, node.required_access) && netrun_snapshot_equal(cached_services, host.netrun_machine_services))
		return
	cached_name = host.name
	cached_node_type = node.node_type
	cached_provider = provider
	cached_actions = provider?.actions
	cached_commands = commands
	cached_access = node.required_access?.Copy()
	cached_services = host.netrun_machine_services?.Copy()
	cached_notes = notes
	content = host.netrun_machine_manual_text(node, commands, provider)

/datum/netrun_file/manual/copy()
	refresh_text()
	return ..()

/datum/netrun_file/manual/ui_entry(selected_uid)
	refresh_text()
	return ..()

/datum/netrun_file/manual/show(mob/user)
	refresh_text()
	return ..()

/// Component registration calls this after native service registration.
/atom/proc/ensure_netrun_manual(datum/component/netrun_node/node)
	if(!node?.file_store)
		return
	for(var/datum/netrun_file/file as anything in node.file_store.files)
		if(file.name == "readme.txt")
			return
	node.file_store.insert(new /datum/netrun_file/manual(node), TRUE)

/// The hook describes purpose; capabilities themselves come from live published contracts.
/atom/proc/netrun_manual_role(datum/component/netrun_node/node)
	switch(node.node_type)
		if(NETRUN_NODE_APC)
			return "Контроллер питания APC питает свою область и подключает её машины к ЛВС. Проверьте заряд и каналы питания; отключение APC может оборвать маршруты устройств области."
		if(NETRUN_NODE_AIRLOCK)
			return "Шлюз управляет проходом между помещениями. Проверьте питание, болты и замок перед открытием; права сети не обходят штатные провода и ограничения двери."
		if(NETRUN_NODE_CAMERA, NETRUN_NODE_OPTIC)
			return "Узел камер и оптики даёт изображение места установки. Откройте окно устройства и включите «Смотреть»; фотография сохраняется отдельным файлом, когда эта команда опубликована."
		if(NETRUN_NODE_TURRET)
			return "Турель защищает область. В окне устройства сначала проверьте питание и правила выбора целей; опасные режимы требуют ROOT и сохраняют штатные ограничения турели."
		if(NETRUN_NODE_VENDOR)
			return "Торговый автомат хранит и выдаёт товары. Выберите товар в окне устройства; штатная оплата, наличие товара и ограничения автомата проверяются при доставке запроса."
		if(NETRUN_NODE_ATMOS)
			return "Узел атмосферы управляет газами или контролирует воздух области. Сначала проверьте давление и состояние машины, затем задайте режим или уставку в окне устройства. Вентиляция и скрубберы регистрируются у воздушной сигнализации своей области."
		if(NETRUN_NODE_TERMINAL)
			return "Терминал или модульный компьютер запускает программы и предоставляет доступ к сети. Откройте карту, выберите узел и его окно; файлы, команды и журналы доступны через соответствующие страницы. Командная строка: help."
		if(NETRUN_NODE_SERVER)
			return "Сервер хранит файлы или обслуживает опубликованные ниже машинные запросы. Для работы нужны питание и путь к серверу. Выбирайте файлы на странице узла; передача расходует место на диске получателя."
		if(NETRUN_NODE_GATEWAY)
			return "Сетевой ретранслятор соединяет инфраструктуру. Проверьте питание и рабочий режим; квантовый маршрут требует исправных NTnet-реле с обеих сторон."
		if(NETRUN_NODE_INTERCOM)
			return "Интерком передаёт речь и позволяет процессу слышать помещение. Включайте микрофон или динамик в окне устройства; эфир зависит от частоты и работающих телекоммуникаций."
		if(NETRUN_NODE_IMPLANT)
			return "Узел кибернетики представляет носителя или установленный имплант. Команды адресуются конкретному органу; владелец управляет своим устройством через штатные действия. Разрыв погружения нейролинка возвращает разум в тело с повреждением мозга."
		if(NETRUN_NODE_NEURAL)
			return "Нейроинтерфейс выводит сообщения, данные и метки на дисплей носителя. Выберите текстовый файл для передачи данных; управляйте только опубликованными модулями интерфейса."
		if(NETRUN_NODE_DECK)
			return "Кибердека — переносной сетевой клиент. Держите её при себе, подключите короткий кабель к соседней машине или используйте беспроводной доступ; загрузите инструменты в память либо вставьте шард."
		if(NETRUN_NODE_BORG, NETRUN_NODE_AI, NETRUN_NODE_PAI)
			return "Узел синтетического разума предоставляет его опубликованные сетевые функции. Учитывайте собственные права разума и его штатные ограничения; общий ключ ЛВС не заменяет управление носителем."
		if(NETRUN_NODE_MODSUIT)
			return "Контроллер MOD управляет костюмом и установленными модулями. Проверьте питание и развёртывание, затем выберите служебный модуль. Опасные переключения сохраняют проверку владельца или установленного ИИ."
		if(NETRUN_NODE_CIRCUIT)
			return "Программируемая схема обменивается сетевыми запросами через установленные компоненты. Проверьте питание и настройки компонентов; допустимые операции опубликованы ниже."
	return "Адресуемый узел машины. Проверьте её состояние и используйте только опубликованные ниже команды и сервисы."

/atom/proc/netrun_manual_notes()
	return null

/obj/machinery/netrun_server/netrun_manual_notes()
	return preload_files?["readme.txt"]

/obj/machinery/netrun_server/dns/netrun_manual_role(datum/component/netrun_node/node)
	return "Информационный сервер хранит файлы и может содержать сетевые процессы. Обнаружение машинных служб встроено в сеть APC; отдельный сервер адресов не требуется. Подключение к APC даёт физический маршрут, а операции по-прежнему требуют прав на целевой машине."

/obj/machinery/rnd/server/netrun_manual_role(datum/component/netrun_node/node)
	return "Исследовательские серверы хранят технологии и очки своей научной сети; консоли и производственные машины только запрашивают их. Раундстартовые серверы одной настроенной сети объединяются после готовности маршрутов APC. Построенный вручную сервер начинает отдельную сеть. Для ручного объединения очистите буфер мультитула, сохраните в него сеть первого сервера и примените к другому серверу с подходящим ID-доступом и рабочим сетевым маршрутом. Объединённые серверы совместно хранят исследования и каждый вырабатывает очки. Потеря питания останавливает запросы, но сохраняет память. Уничтожение одного сервера сохраняет данные на остальных объединённых серверах; уничтожение последнего теряет исследования этой сети."

/obj/machinery/computer/rdconsole/netrun_manual_role(datum/component/netrun_node/node)
	return "Научная консоль запрашивает технологии и исследования у выбранного исследовательского сервера. Дождитесь ответа, выберите доступную технологию и исследуйте её; очки списываются на сервере после проверки зависимостей. Консоль не является резервной копией исследований."

/obj/machinery/rnd/production/netrun_manual_role(datum/component/netrun_node/node)
	return "Производственная машина получает доступные чертежи от выбранного исследовательского сервера. Загрузите материалы, дождитесь ответа сети и выберите чертёж с количеством. Нет связи с сервером — нет нового производства по сохранённому списку."

/obj/machinery/airalarm/netrun_manual_role(datum/component/netrun_node/node)
	return "Воздушная сигнализация контролирует атмосферу своей области. Откройте окно устройства, проверьте состав и давление, выберите режим, затем настройте зарегистрированные вентиляции и скрубберы. Блокировка панели и провода ограничивают сетевое управление."

/obj/machinery/telecomms/netrun_manual_role(datum/component/netrun_node/node)
	return "Машина телекоммуникаций обрабатывает сигналы связи. Согласуйте частоты, уровни и связи штатной панели; отключённая машина не передаёт сигналы. Телекоммуникационное реле может передавать связь, но не открывает общий путь для научных и атмосферных запросов."

/// Schemas contain public usage information only, never live ui_data or payload bodies.
/datum/netrun_provider/proc/manual_instructions()
	var/list/lines = list()
	if(interface_name)
		lines += "Интерфейс: [interface_name]. Откройте окно устройства, заполните параметры действия и отправьте запрос."
	for(var/action in actions)
		var/list/schema = actions[action]
		lines += "- [schema["name"] || action] ([action]), [netrun_neural_access_name(action_access(action))]: [schema["desc"] || "Штатное действие устройства."]"
		for(var/list/parameter as anything in schema["params"])
			lines += "  Параметр [parameter["id"]]: [parameter["name"] || parameter["id"]] ([parameter["type"] || "text"])."
	return lines

/atom/proc/netrun_machine_manual_text(datum/component/netrun_node/node, list/commands, datum/netrun_provider/provider)
	var/list/lines = list("README — [name]", "", netrun_manual_role(node), "", "ПОДКЛЮЧЕНИЕ И ДОСТУП", \
		"Машина подключается к APC своей области. Путь к удалённому сектору должен проходить через работающую инфраструктуру; состояние связи видно на карте и в журнале запросов.", \
		"ID с подходящим доступом даёт легальные права машины. ПОЛЬЗОВАТЕЛЬ читает файлы и выполняет разрешённые действия; ROOT нужен для административных операций. Ключ ЛВС открывает обнаружение сети, но не подменяет доступ к машине.", \
		"Выберите узел на карте и откройте окно устройства. Отправка запроса не означает выполнение: дождитесь результата в журнале. Питание, провода, блокировки и права повторно проверяются при доставке.")
	lines += "ОПЕРАЦИИ И ПАКЕТЫ: вкладка операций показывает этап доставки и ответ команды. В карточке узла доступен журнал заголовков; ROOT позволяет расшифровать выбранный пакет. Общий буфер хранит последние 256 пакетов, до 4096 символов каждого; старые записи и большие пакеты могут не содержать полного тела."
	if(length(node.required_access))
		var/list/access_names = list()
		for(var/access in node.required_access)
			access_names += get_access_desc(access) || "[access]"
		lines += "Подходящий ID-доступ: [jointext(access_names, ", ")]."
	lines += list("", "КОМАНДЫ ЭТОГО УЗЛА")
	for(var/id in commands || node.all_command_ids())
		var/datum/netrun_command/command = SSnetrun.get_command(id)
		if(command)
			lines += "- [id] — [command.name] ([netrun_neural_access_name(command.access)]): [command.desc]"
	provider = provider || SSnetrun.get_provider(src)
	if(provider)
		lines += list("", "ШТАТНОЕ ОКНО УСТРОЙСТВА")
		lines += provider.manual_instructions()
	if(length(netrun_machine_services))
		lines += list("", "МАШИННЫЕ СЕРВИСЫ")
		for(var/id in netrun_machine_services)
			lines += "- [id]: клиенты находят службу в сети APC и обращаются по действующему физическому маршруту; результат и отказ доставки показываются в интерфейсе клиента."
	var/notes = netrun_manual_notes()
	if(length(notes))
		lines += list("", "ЗАМЕТКИ МАШИНЫ", notes)
	return jointext(lines, "\n")
