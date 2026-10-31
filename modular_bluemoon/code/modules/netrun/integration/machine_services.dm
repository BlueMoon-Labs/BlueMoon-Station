/// Engineering controls use the real SMES panel, including its part-dependent
/// power limits, EMP interlock and investigation log. No power is manufactured.
/obj/machinery/power/smes/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list("smes_status"), 2, list(ACCESS_ENGINE_EQUIP))

/obj/machinery/power/smes/netrun_online(remote = TRUE)
	return !(machine_stat & (BROKEN | EMPED)) && !QDELETED(terminal) && !is_emped

/obj/machinery/power/smes/netrun_status()
	return list("Заряд: [IS_FINITE(capacity) && capacity > 0 ? "[round(100 * charge / capacity, 0.1)]%" : "не ограничен"]", "Зарядка: [input_attempt ? "разрешена" : "отключена"], уставка [DisplayPower(input_level)]", "Выдача: [output_attempt ? "разрешена" : "отключена"], уставка [DisplayPower(output_level)]")

/datum/netrun_api/smes
	atom_type = /obj/machinery/power/smes
	interface_name = "Smes"
	actions = list(
		"tryinput" = list("name" = "Зарядка", "desc" = "Разрешить или отключить штатную зарядку накопителя.", "access" = NETRUN_ACCESS_USER),
		"input" = list("name" = "Мощность зарядки", "desc" = "Уставка в ваттах, ограниченная реальными деталями SMES.", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "target", "name" = "Мощность (Вт)", "type" = "number", "min" = 0, "max" = 10000000, "native_text" = TRUE))),
		"tryoutput" = list("name" = "Выдача энергии", "desc" = "Отключение выдачи может обесточить подключённую сеть.", "access" = NETRUN_ACCESS_ROOT, "danger" = TRUE),
		"output" = list("name" = "Мощность выдачи", "desc" = "Уставка в ваттах. Низкое значение может обесточить потребителей; предел задают детали SMES.", "access" = NETRUN_ACCESS_ROOT, "danger" = TRUE, "params" = list(list("id" = "target", "name" = "Мощность (Вт)", "type" = "number", "min" = 0, "max" = 10000000, "native_text" = TRUE))),
	)

/datum/netrun_api/smes/available(atom/target)
	if(!..())
		return FALSE
	var/obj/machinery/power/smes/storage = target
	return !QDELETED(storage.terminal) && !storage.panel_open

/datum/netrun_api/smes/action_unavailable_reason(atom/target, action, datum/netrun_console/console, datum/component/netrun_node/node)
	. = ..()
	if(.)
		return
	var/obj/machinery/power/smes/storage = target
	if(storage.is_emped)
		return "Контроллер SMES восстанавливается после ЭМИ."
	return null

/datum/netrun_command/smes_status
	id = "smes_status"
	name = "Диагностика SMES"
	desc = "Прочитать заряд, уставки, фактическую нагрузку и пределы накопителя."
	help = "Значения мощности указаны в ваттах; состояние читается из штатного контроллера без изменения каналов питания."
	access = NETRUN_ACCESS_GUEST
	trace = 0
	read_only = TRUE
	icon = "battery-half"

/datum/netrun_command/smes_status/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/power/smes/storage = node.parent
	return "[jointext(storage.netrun_status(), "\n")]\nДоступно на входе: [DisplayPower(storage.input_available)]. Фактическая выдача: [DisplayPower(storage.output_used)].\nПределы: вход [DisplayPower(storage.input_level_max)], выход [DisplayPower(storage.output_level_max)]."

/// The fire-alarm service respects the same physical button interlocks as a
/// person at the panel. ROOT never repairs or bypasses a severed control wire.
/obj/machinery/firealarm/Initialize(mapload, dir, building)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("fire_status"), 2, list(ACCESS_ATMOSPHERICS))

/obj/machinery/firealarm/netrun_online(remote = TRUE)
	return ..() && buildstage == 2

/obj/machinery/firealarm/netrun_status()
	return list("Пожарная тревога отсека: [myarea?.fire ? "поднята" : "нет"]", "Детектор: [detecting ? "включён" : "отключён"]", "Кнопка: [can_use_button() ? "доступна" : "недоступна: питание, панель или провода"]")

/datum/netrun_provider/firealarm
	atom_type = /obj/machinery/firealarm
	interface_name = "FireAlarm"
	state_signals = list(COMSIG_ATOM_UPDATED_ICON)
	actions = list(
		"alarm" = list("name" = "Подать пожарную тревогу", "desc" = "Штатная тревога закрывает противопожарные двери отсека.", "access" = NETRUN_ACCESS_USER),
		"reset" = list("name" = "Снять пожарную тревогу", "desc" = "Подтвердить состояние отсека и снять тревогу. Открытие противопожарных дверей при пожаре опасно.", "access" = NETRUN_ACCESS_ROOT, "danger" = TRUE),
	)

/datum/netrun_provider/firealarm/action_unavailable_reason(atom/target, action, datum/netrun_console/console, datum/component/netrun_node/node)
	. = ..()
	if(.)
		return
	var/obj/machinery/firealarm/alarm = target
	if(!alarm.can_use_button())
		return "Пожарная кнопка отключена: проверьте питание, панель и провода на месте."
	if(action == "alarm" && !COOLDOWN_FINISHED(alarm, last_alarm))
		return "Звуковой сигнал ещё воспроизводится."
	if(action == "alarm" && alarm.myarea?.fire)
		return "Пожарная тревога уже поднята."
	if(action == "reset" && !alarm.myarea?.fire && !alarm.alarm_active)
		return "В отсеке нет пожарной тревоги."
	return null

/datum/netrun_provider/firealarm/read_data(atom/target, datum/netrun_console/console, datum/component/netrun_node/node)
	var/obj/machinery/firealarm/alarm = target
	return list("alarm" = !!alarm.myarea?.fire, "detecting" = !!alarm.detecting, "button_available" = alarm.can_use_button(), "panel_open" = alarm.panel_open, "button_wire_cut" = alarm.button_wire_cut)

/datum/netrun_provider/firealarm/execute(atom/target, action, list/arguments, datum/netrun_console/console, datum/component/netrun_node/node)
	if(action_unavailable_reason(target, action, console, node))
		return FALSE
	var/obj/machinery/firealarm/alarm = target
	switch(action)
		if("alarm")
			alarm.alarm(console.operator)
			return alarm.alarm_active
		if("reset")
			alarm.reset(console.operator)
			return !alarm.alarm_active
	return FALSE

/datum/netrun_command/fire_status
	id = "fire_status"
	name = "Диагностика пожарной сигнализации"
	desc = "Прочитать тревогу отсека, состояние детектора и доступность кнопки."
	access = NETRUN_ACCESS_GUEST
	trace = 0
	read_only = TRUE
	icon = "fire-extinguisher"

/datum/netrun_command/fire_status/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/firealarm/alarm = node.parent
	return jointext(alarm.netrun_status(), "\n")

/// A radial-menu appliance has no native TGUI action adapter. Its explicit
/// provider invokes cook/eject while preserving every mechanical interlock.
/obj/machinery/microwave/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list("microwave_status"), 1, list(ACCESS_KITCHEN))

/obj/machinery/microwave/netrun_status()
	return list("Цикл: [operating ? "идёт" : "ожидание"]", "Загружено: [length(ingredients)] / [max_n_of_items]", "Загрязнение: [dirty], неисправность: [broken]", "Управление: [wire_disabled ? "отключено проводом" : "подключено"]")

/datum/netrun_provider/microwave
	atom_type = /obj/machinery/microwave
	interface_name = "Microwave"
	state_signals = list(COMSIG_ATOM_UPDATED_ICON)
	actions = list(
		"eject" = list("name" = "Выгрузить содержимое", "desc" = "Открыть дверцу и выгрузить вещи рядом с микроволновкой.", "access" = NETRUN_ACCESS_USER),
		"cook_food" = list("name" = "Приготовить еду", "desc" = "Запустить штатный цикл только для съедобных предметов без металлических материалов.", "access" = NETRUN_ACCESS_USER),
		"cook_any" = list("name" = "Запустить с любым содержимым", "desc" = "Нештатные предметы и металл могут испортить или взорвать печь; штатные риски сохраняются.", "access" = NETRUN_ACCESS_ROOT, "danger" = TRUE),
	)

/datum/netrun_provider/microwave/action_unavailable_reason(atom/target, action, datum/netrun_console/console, datum/component/netrun_node/node)
	. = ..()
	if(.)
		return
	var/obj/machinery/microwave/oven = target
	if(oven.operating || oven.panel_open || !oven.anchored)
		return "Печь работает, открыта для обслуживания или не закреплена."
	if(!length(oven.ingredients))
		return "Печь пуста."
	if(action != "eject")
		if(oven.wire_disabled || oven.broken || oven.dirty >= 5000)
			return "Нужен ремонт провода, самой печи или очистка на месте."
		if(action == "cook_food")
			for(var/atom/movable/ingredient as anything in oven.ingredients)
				if(!IS_EDIBLE(ingredient) || (ingredient.custom_materials?[SSmaterials.GetMaterialRef(/datum/material/iron)] || 0) > 0)
					return "Для несъедобных или металлических предметов требуется опасный запуск с ROOT."
	return null

/datum/netrun_provider/microwave/read_data(atom/target, datum/netrun_console/console, datum/component/netrun_node/node)
	var/obj/machinery/microwave/oven = target
	var/list/items = list()
	for(var/atom/movable/ingredient as anything in oven.ingredients)
		items += ingredient.name
	return list("operating" = oven.operating, "contents" = items, "capacity" = oven.max_n_of_items, "dirty" = oven.dirty, "broken" = oven.broken, "control_disabled" = oven.wire_disabled)

/datum/netrun_provider/microwave/execute(atom/target, action, list/arguments, datum/netrun_console/console, datum/component/netrun_node/node)
	if(action_unavailable_reason(target, action, console, node))
		return FALSE
	var/obj/machinery/microwave/oven = target
	if(action == "eject")
		oven.eject()
		return !length(oven.ingredients)
	if(action == "cook_food" || action == "cook_any")
		oven.cook(console.operator)
		return oven.operating
	return FALSE

/datum/netrun_command/microwave_status
	id = "microwave_status"
	name = "Диагностика кухонной печи"
	desc = "Прочитать ход цикла, загрузку, загрязнение и состояние провода управления."
	access = NETRUN_ACCESS_GUEST
	trace = 0
	read_only = TRUE
	icon = "utensils"

/datum/netrun_command/microwave_status/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/microwave/oven = node.parent
	return jointext(oven.netrun_status(), "\n")
