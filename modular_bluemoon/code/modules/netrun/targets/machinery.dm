// MARK: APC

/obj/machinery/power/apc
	/// Physical sector isolation is independent of the power channels and battery.
	var/netrun_isolated = FALSE

/obj/machinery/power/apc/proc/set_netrun_isolated(value)
	if(netrun_isolated == !!value)
		return FALSE
	netrun_isolated = !!value
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	node?.notify_changed(NETRUN_CHANGED_STATE)
	SEND_SIGNAL(src, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	SStgui.update_uis(src)
	return TRUE

/obj/machinery/power/apc/Initialize(mapload, ndir, building = FALSE)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_APC, list("apc_breaker", "apc_lighting", "apc_equipment", "apc_environ", "apc_overload"), 2, list(ACCESS_ENGINE_EQUIP))

/obj/machinery/power/apc/netrun_online(remote = TRUE)
	return !netrun_isolated && !(machine_stat & (BROKEN | EMPED)) && !failure_timer

/obj/machinery/power/apc/netrun_status()
	. = list()
	. += "Рубильник: [operating ? "включён" : "выключен"]"
	. += "Ячейка: [cell ? "[round(cell.percent())]%" : "отсутствует"]"
	. += "Каналы: свет [lighting >= 2 ? "вкл" : "выкл"], оборудование [equipment >= 2 ? "вкл" : "выкл"], среда [environ >= 2 ? "вкл" : "выкл"]"

/datum/netrun_command/apc_breaker
	id = "apc_breaker"
	name = "Рубильник"
	desc = "Включить или выключить главный рубильник APC."
	help = "Управляет питанием всего отсека. Неисправный или восстанавливающийся APC может не принять переключение; отдельные каналы управляются своими командами."
	icon = "power-off"
	trace = 6

/datum/netrun_command/apc_breaker/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/power/apc/apc = node.parent
	apc.toggle_breaker(console.operator)
	return "Рубильник [apc.operating ? "включён" : "выключен"]."

/datum/netrun_command/apc_lighting
	id = "apc_lighting"
	name = "Канал света"
	desc = "Переключить питание освещения в отсеке этого APC."
	help = "Работающий канал переводится в режим «выключен», отключённый — в режим «включён». Повторный вызов переключает состояние обратно."
	icon = "lightbulb"
	trace = 3
	var/channel = "lighting"

/datum/netrun_command/apc_lighting/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/power/apc/apc = node.parent
	var/current = apc.vars[channel]
	var/new_value = apc.setsubsystem(current >= 2 ? 1 : 3)
	apc.vars[channel] = new_value
	apc.update()
	apc.update_appearance()
	return "Канал «[name]»: [new_value >= 2 ? "включён" : "выключен"]."

/datum/netrun_command/apc_lighting/equipment
	id = "apc_equipment"
	name = "Канал оборудования"
	desc = "Переключить питание оборудования в отсеке этого APC."
	icon = "plug"
	trace = 4
	channel = "equipment"

/datum/netrun_command/apc_lighting/environ
	id = "apc_environ"
	name = "Канал среды"
	desc = "Переключить питание систем среды в отсеке этого APC."
	icon = "wind"
	trace = 5
	channel = "environ"

/datum/netrun_command/apc_overload
	id = "apc_overload"
	name = "Перегрузить свет"
	desc = "Пустить скачок по осветительной сети отсека."
	access = NETRUN_ACCESS_ROOT
	icon = "burst"
	trace = 7
	danger = TRUE

/datum/netrun_command/apc_overload/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/power/apc/apc = node.parent
	if(!apc.cell || apc.cell.charge <= 0)
		console.log_line("Недостаточно заряда.", "bad")
		return
	apc.overload_lighting()
	return "Скачок отправлен в осветительную сеть."

// MARK: Камеры

/obj/machinery/camera/Initialize(mapload, obj/structure/camera_assembly/CA)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_CAMERA, list("cam_toggle", "cam_loop", "cam_ai_jump"), 1, list(ACCESS_SECURITY))

/obj/machinery/camera/netrun_online(remote = TRUE)
	return !(machine_stat & (BROKEN | EMPED))

/obj/machinery/camera/netrun_status()
	. = list()
	. += "Сеть: [english_list(network)]"
	. += "Состояние: [status ? "ведёт запись" : "отключена"]"

/datum/netrun_command/cam_toggle
	id = "cam_toggle"
	name = "Вкл/выкл"
	desc = "Включить или выключить запись выбранной камеры."
	help = "Выключенная камера перестаёт давать изображение. Состояние записи видно в карточке; повторный вызов переключает её обратно."
	icon = "video"
	trace = 4

/datum/netrun_command/cam_toggle/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/camera/camera = node.parent
	camera.toggle_cam(null, FALSE)
	return "Камера [camera.status ? "включена" : "отключена"]."

/datum/netrun_command/cam_loop
	id = "cam_loop"
	name = "Закольцевать"
	desc = "Тихо подменить поток записью на минуту: камера выпадает из сети наблюдения без тревоги."
	access = NETRUN_ACCESS_ROOT
	icon = "repeat"
	trace = 5

/datum/netrun_command/cam_loop/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/camera/camera = node.parent
	if(!camera.status)
		console.log_line("Камера уже не ведёт запись.", "bad")
		return
	camera.status = FALSE
	GLOB.cameranet.removeCamera(camera)
	GLOB.cameranet.updateChunk(camera.x, camera.y, camera.z)
	addtimer(CALLBACK(camera, TYPE_PROC_REF(/obj/machinery/camera, netrun_unloop)), 1 MINUTES)
	return "Поток закольцован на минуту."

/obj/machinery/camera/proc/netrun_unloop()
	if(status || (machine_stat & BROKEN))
		return
	status = TRUE
	if(can_use())
		GLOB.cameranet.addCamera(src)
		GLOB.cameranet.updateChunk(x, y, z)

// MARK: Панели управления турелями

/obj/machinery/turretid/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_TURRET, list("turret_toggle", "turret_lethal", "reboot"), 2, list(ACCESS_SECURITY))

/obj/machinery/turretid/netrun_status()
	. = list()
	. += "Турели: [enabled ? "активны" : "отключены"], режим: [lethal ? "летальный" : "оглушение"]"
	. += "Подключено турелей: [length(turrets)]"

/datum/netrun_command/turret_toggle
	id = "turret_toggle"
	name = "Вкл/выкл турели"
	desc = "Включить или выключить все турели, связанные с выбранной панелью."
	help = "Изменяет общий переключатель панели. Настройка передаётся подключённым турелям; выбранный режим огня при этом сохраняется."
	icon = "crosshairs"
	trace = 7

/datum/netrun_command/turret_toggle/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/turretid/panel = node.parent
	panel.toggle_on(console.operator)
	return "Турели [panel.enabled ? "активны" : "отключены"]."

/datum/netrun_command/turret_lethal
	id = "turret_lethal"
	name = "Режим огня"
	desc = "Переключить связанные турели между оглушающим и летальным режимами."
	help = "Изменяет режим всех турелей этой панели. Команда сама не включает питание; перед вызовом проверьте текущее состояние и режим в карточке."
	access = NETRUN_ACCESS_ROOT
	icon = "skull"
	trace = 9
	danger = TRUE

/datum/netrun_command/turret_lethal/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/turretid/panel = node.parent
	panel.toggle_lethal(console.operator)
	return "Режим огня: [panel.lethal ? "летальный" : "оглушение"]."

// MARK: Торгоматы

/obj/machinery/vending/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_VENDOR, list("vend_eject", "vend_free", "vend_shoot"), 1, list(ACCESS_CARGO))

/obj/machinery/vending/netrun_status()
	. = list()
	. += "Проверка ID: [scan_id ? "включена" : "отключена"]"
	if(shoot_inventory)
		. += "ВНИМАНИЕ: сбой механизма выдачи"

/datum/netrun_command/vend_eject
	id = "vend_eject"
	name = "Выбросить товар"
	desc = "Заставить торгомат бросить один товар своим механизмом выдачи."
	help = "Это сбой механизма, без выбора конкретного товара. Если автомат не находит подходящий товар или цель, выдача не происходит. Для обычной покупки выбранного товара используйте интерфейс устройства."
	icon = "box-open"
	trace = 3

/datum/netrun_command/vend_eject/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/vending/vendor = node.parent
	if(!vendor.throw_item())
		console.log_line("Механизм выдачи не нашёл, куда бросить товар.", "bad")
		return
	return "Товар выброшен."

/datum/netrun_command/vend_free
	id = "vend_free"
	name = "Проверка ID"
	desc = "Переключить проверку ID-карты при покупке."
	access = NETRUN_ACCESS_ROOT
	icon = "id-card"
	trace = 4

/datum/netrun_command/vend_free/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/vending/vendor = node.parent
	vendor.scan_id = !vendor.scan_id
	return "Проверка ID [vendor.scan_id ? "включена" : "отключена"]."

/datum/netrun_command/vend_shoot
	id = "vend_shoot"
	name = "Сбой выдачи"
	desc = "Заставить торгомат швыряться товаром в прохожих."
	access = NETRUN_ACCESS_ROOT
	icon = "bomb"
	trace = 5
	danger = TRUE

/datum/netrun_command/vend_shoot/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/vending/vendor = node.parent
	vendor.shoot_inventory = !vendor.shoot_inventory
	return "Механизм выдачи [vendor.shoot_inventory ? "сбоит" : "в норме"]."
