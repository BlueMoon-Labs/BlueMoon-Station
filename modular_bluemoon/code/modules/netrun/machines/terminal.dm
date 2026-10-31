/proc/netrun_manual_text()
	return {"СЕТЕВОЙ ТЕРМИНАЛ — КРАТКАЯ СПРАВКА

ЛВС объединяет APC одного отдела и сектора. Устройство подключено к одному APC своей области;
APC одной группы этажей связаны между собой. Между удалёнными секторами путь проходит
через работающие квантовые ретрансляторы с обеих сторон. Отключение промежуточного узла
разрывает маршрут. На карте показаны реальные координаты, узлы и связи; задержка зависит от длины кабелей.

УРОВНИ ДОСТУПА: НЕТ, ГОСТЬ, ПОЛЬЗОВАТЕЛЬ, ROOT.
Ваш ID-карта даёт легальный доступ: к ЛВС своего отдела и к машинам, которые она открывает.
Доступ сетевого администратора (Network Access) или капитана даёт ROOT.

КЛЮЧИ ЛВС выпускаются командой «Выпустить ключ ЛВС»: они открывают сеть для обнаружения
и перемещения по её узлам. Для управления устройством нужны его отдельный взлом
или подходящие учётные данные. Храните ключи как пароли.

ТРАССИРОВКА: система защиты отслеживает действия без авторизации. Если к вам подключается
кто-то посторонний — смотрите журнал сети, перезагружайте узлы и выполняйте «Очистку».

ПОИСК И КАРТА: результат поиска открывает нужный сектор и этаж. Кнопка «Мой узел»
возвращает обзор к точке подключения. WASD выбирает узлы при фокусе карты;
сущность переходит к соседу через Shift+WASD. Автопроход можно остановить кнопкой
«Стоп» в строке состояния; ручной переход также отменяет маршрут.

АТАКИ ICE: предупреждение и время до атаки видны в постоянной строке статуса.
Откройте «Бой», прервите подготовку противника или отмените взлом и уйдите.
Файлы, карта и другие страницы доступны во время взлома; чтение журнала
не прокручивается вниз, пока вы просматриваете старые сообщения.

АТМОСФЕРА: сетевые насосы и воздушные сигнализации управляются со страницы устройства.
Для управления нужны права машины. Ключ ЛВС сам по себе этих прав не даёт.
Недоступное действие показывает причину: блокировка панели, провода или прошивка.

Командная строка: help."}

// MARK: Сетевой терминал

/obj/machinery/computer/netrun_terminal
	name = "network terminal"
	desc = "Проводной терминал локальной сети. Показывает топологию, узлы и журналы; с нужным доступом - управляет ими."
	icon_screen = "comm_logs"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/netrun_terminal
	light_color = "#4a9eff"
	var/datum/netrun_console/console

/obj/machinery/computer/netrun_terminal/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	console = new(src, NETRUN_ORIGIN_TERMINAL)
	console.connection.wireless = FALSE
	console.inventory.local_store.capacity = 12 * NETRUN_STORAGE_SCALE
	console.tgui_title = "Сетевой терминал"
	console.store_file(new /datum/netrun_file("readme.txt", NETRUN_FILE_TEXT, netrun_manual_text()))
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list("purge", "issue_key"), 2, list(ACCESS_NETWORK), 12 * NETRUN_STORAGE_SCALE)

/obj/machinery/computer/netrun_terminal/Destroy()
	QDEL_NULL(console)
	return ..()

/obj/machinery/computer/netrun_terminal/ui_interact(mob/user, datum/tgui/ui)
	if(!is_operational())
		return
	console.ui_interact(user, ui)

/obj/machinery/computer/netrun_terminal/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/netrun_shard))
		console.insert_shard(I, user)
		return TRUE
	return ..()

/obj/machinery/computer/netrun_terminal/netrun_traced(datum/netrun_console/traced)
	playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
	say("Сеанс прерван системой защиты сети.")

/obj/item/circuitboard/computer/netrun_terminal
	name = "Network Terminal (Computer Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/computer/netrun_terminal

// MARK: Сервер данных

/obj/machinery/netrun_server
	name = "data server"
	desc = "Стойка хранения данных локальной сети. В ней хранят журналы, ключи и всё, что не должно попасть в чужие руки."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 200
	circuit = /obj/item/circuitboard/machine/netrun_server
	/// Файлы, которые лежат на сервере с самого начала (имя = текст)
	var/list/preload_files
	/// Демоны, лежащие на сервере с самого начала (список id)
	var/list/preload_daemons
	/// Доступ, нужный для легального пользователя (по умолчанию - сетевой администратор)
	var/list/server_access = list(ACCESS_NETWORK)
	/// Защита узла сервера
	var/server_security = 2

/obj/machinery/netrun_server/Initialize(mapload)
	. = ..()
	var/capacity = 80 * NETRUN_STORAGE_SCALE
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		capacity += bin.rating * 10 * NETRUN_STORAGE_SCALE
	var/datum/component/netrun_node/node = AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, list("purge", "issue_key", "reboot"), server_security, server_access, capacity)
	for(var/file_name in preload_files)
		if(file_name == "readme.txt")
			var/documented = FALSE
			for(var/datum/netrun_file/manual/manual as anything in node.file_store.files)
				if(istype(manual) && manual.name == file_name)
					documented = TRUE
					break
			if(documented)
				// The firmware manual includes the exact authored preload as machine notes.
				continue
		node.file_store.insert(new /datum/netrun_file(file_name, NETRUN_FILE_TEXT, preload_files[file_name]), TRUE)
	for(var/daemon_id in preload_daemons)
		var/datum/netrun_file/daemon_file = netrun_daemon_file(daemon_id)
		if(daemon_file)
			node.file_store.insert(daemon_file, TRUE)

/obj/machinery/netrun_server/netrun_status()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	. = list("Хранилище: [node.used_storage()] / [node.file_store.capacity]")

/obj/machinery/netrun_server/examine(mob/user)
	. = ..()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(node)
		. += span_notice("Сетевой адрес: [node.address][node.network ? " ([node.network.short_name])" : ""].")

/obj/machinery/netrun_server/attackby(obj/item/I, mob/living/user, params)
	if(default_deconstruction_screwdriver(user, "server", "server", I))
		return TRUE
	if(default_deconstruction_crowbar(I))
		return TRUE
	return ..()

/obj/item/circuitboard/machine/netrun_server
	name = "Data Server (Machine Board)"
	icon_state = "science"
	build_path = /obj/machinery/netrun_server
	req_components = list(
		/obj/item/stack/cable_coil = 2,
		/obj/item/stock_parts/matter_bin = 2,
		/obj/item/stock_parts/subspace/filter = 1)

// MARK: Уникальные серверы-тайники вне станции
//
// Размещаются мапперами в руинах/обломках на внешних Z-уровнях. Их ЛВС изолирована -
// подключиться можно только оказавшись там физически (деком/имплантом/сущностью).
// Внутри - добываемые демоны и данные. Хорошо защищены.

/obj/machinery/netrun_server/stash
	name = "abandoned data cache"
	desc = "Запылённая стойка данных неизвестного происхождения. Индикаторы ещё теплятся."
	icon_state = "server"
	server_security = 4
	server_access = list(ACCESS_SYNDICATE)

/obj/machinery/netrun_server/stash/breach_suite
	name = "breach tools archive"
	desc = "Стойка со скрытым архивом сетевых инструментов. Кто-то собирал её с умыслом."
	preload_daemons = list("buffer", "icepick", "cloak", "autobreach")
	preload_files = list("readme.txt" = "Инструменты для работы с чужими сетями. Буфер, анализатор защиты, маскировка следов. Используй с умом.")

/obj/machinery/netrun_server/stash/recon
	name = "signals cache"
	desc = "Архив средств сетевой разведки."
	server_security = 4
	preload_daemons = list("mapper", "overclock", "scrub")
	preload_files = list("ops.txt" = "Разведка топологии, разгон стека, заметание следов. Полевой набор.")

/obj/machinery/netrun_server/stash/blackbox
	name = "black archive"
	desc = "Хорошо защищённая стойка. Снаружи ни одной маркировки."
	server_security = 5
	preload_daemons = list("skeleton", "icepick")
	preload_files = list("warning.txt" = "Внутри - армейская отмычка. Одноразовый рывок до корня. Не для любителей.")
