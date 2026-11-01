// Публикации штатных интерфейсов. Новый тип машины подключается одним адаптером,
// не требует новых switch в консоли или TGUI. Собственные проверки ui_act сохраняются.

/datum/netrun_api/turret
	atom_type = /obj/machinery/porta_turret
	interface_name = "PortableTurret"
	allow_emag = TRUE
	actions = list(
		"power" = list("name" = "Питание", "desc" = "Включить или выключить закреплённую турель.", "access" = NETRUN_ACCESS_ROOT),
		"authweapon" = list("name" = "Проверка оружия", "access" = NETRUN_ACCESS_ROOT),
		"shootcriminals" = list("name" = "Проверка розыска", "access" = NETRUN_ACCESS_ROOT),
		"shootall" = list("name" = "Огонь по всем", "danger" = TRUE, "access" = NETRUN_ACCESS_ROOT),
		"checkxenos" = list("name" = "Проверка аномалий", "access" = NETRUN_ACCESS_ROOT),
		"checkloyal" = list("name" = "Проверка импланта защиты", "access" = NETRUN_ACCESS_ROOT),
		"shootborgs" = list("name" = "Проверка киборгов", "access" = NETRUN_ACCESS_ROOT),
		"shootheads" = list("name" = "Исключение глав", "access" = NETRUN_ACCESS_ROOT),
	)

/datum/netrun_api/vendor
	atom_type = /obj/machinery/vending
	interface_name = "Vending"
	allow_emag = TRUE
	actions = list(
		"vend" = list("name" = "Выдать товар", "desc" = "Выдача выбранного товара с обычной оплатой и проверками автомата. Идентификатор товара — ref из данных устройства.", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "ref", "name" = "Товар (ref)", "type" = "text"))),
	)

/datum/netrun_api/research
	atom_type = /obj/machinery/computer/rdconsole
	interface_name = "Techweb"
	allow_emag = TRUE
	actions = list(
		"researchNode" = list("name" = "Исследовать технологию", "desc" = "Обычное исследование с затратой очков и проверкой зависимостей.", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "node_id", "name" = "Код технологии", "type" = "text"))),
		"linkmachines" = list("name" = "Найти машины рядом", "access" = NETRUN_ACCESS_USER),
		"toggleLock" = list("name" = "Блокировка консоли", "desc" = "Использует штатную проверку ID самой консоли.", "access" = NETRUN_ACCESS_ROOT),
		"ejectDisk" = list("name" = "Извлечь диск", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "type", "name" = "Тип (tech/design)", "type" = "text"))),
	)

/datum/netrun_api/fabricator
	atom_type = /obj/machinery/rnd/production
	interface_name = "Fabricator"
	allow_emag = TRUE
	actions = list(
		"build" = list("name" = "Изготовить", "desc" = "Штатное производство с проверкой исследований, материалов и ограничений машины.", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "id", "name" = "Код чертежа", "type" = "text"), list("id" = "amount", "name" = "Количество", "type" = "number", "min" = 1, "max" = 60))),
	)

// APC/AiAirlock используют специализированные сетевые команды: их штатные ui_act
// требуют физического/силиконного контекста. Здесь публикуется только атака прошивки.
/datum/netrun_api/airlock
	atom_type = /obj/machinery/door/airlock
	allow_emag = TRUE

/datum/netrun_api/apc
	atom_type = /obj/machinery/power/apc
	allow_emag = TRUE

/datum/netrun_api/bot
	atom_type = /mob/living/simple_animal/bot
	allow_emag = TRUE

// Собственный адаптер переносной турели: панель turretid остаётся отдельным узлом.
/obj/machinery/porta_turret/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_TURRET, list("reboot"), 3, list(ACCESS_SECURITY))

/obj/machinery/porta_turret/netrun_status()
	return list("Питание: [on ? "включено" : "выключено"]", "Панель: [locked ? "заблокирована" : "открыта"]")
