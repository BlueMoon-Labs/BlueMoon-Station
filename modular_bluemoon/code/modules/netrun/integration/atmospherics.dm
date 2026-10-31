/** Atmospheric services use the real machine control paths and their logs/wakeups. */
/obj/machinery/airalarm/Initialize(mapload, ndir, nbuild)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("atmos_lock", "reboot"), 3, list(ACCESS_ATMOSPHERICS))

/obj/machinery/airalarm/netrun_online(remote = TRUE)
	return ..() && buildstage == 2 && !shorted

/obj/machinery/airalarm/netrun_status()
	return list(
		"Режим: [get_mode_name(mode)]",
		"Панель: [locked ? "заблокирована" : "открыта"]",
		"Сетевое управление: [aidisabled || wires?.is_cut(WIRE_AI) ? "отключено проводом" : "подключено"]",
		"Уровень тревоги: [danger_level]",
	)

/datum/netrun_api/airalarm
	atom_type = /obj/machinery/airalarm
	interface_name = "AirAlarm"
	state_signals = list(COMSIG_UI_ACT, COMSIG_ATOM_UPDATED_ICON, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	actions = list(
		"alarm" = list("name" = "Подать тревогу", "access" = NETRUN_ACCESS_USER),
		"reset" = list("name" = "Снять тревогу", "desc" = "Снять атмосферную тревогу через штатный контроллер отсека.", "access" = NETRUN_ACCESS_ROOT),
	)

/// The game owns the mode catalog. New modes automatically get the same name,
/// danger indication and firmware condition as the physical air-alarm panel.
/datum/netrun_api/airalarm/New()
	..()
	actions = actions.Copy()
	for(var/mode_id in GLOB.air_alarm_modes)
		var/datum/air_alarm_mode/mode = GLOB.air_alarm_modes[mode_id]
		actions["mode_[mode_id]"] = list(
			"name" = mode.ui_name || mode.name,
			"desc" = mode.description,
			"danger" = mode.danger,
			"access" = mode.danger ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_USER,
			"native_action" = "mode",
			"fixed_params" = list("mode" = "[mode.id]"),
			"mode_id" = mode.id,
		)

/datum/netrun_api/airalarm/available(atom/target)
	if(!..())
		return FALSE
	var/obj/machinery/airalarm/alarm = target
	return alarm.buildstage == 2 && !alarm.shorted && !alarm.aidisabled && !alarm.wires?.is_cut(WIRE_AI)

/datum/netrun_api/airalarm/action_unavailable_reason(atom/target, action, datum/netrun_console/console, datum/component/netrun_node/node)
	. = ..()
	if(.)
		return
	var/obj/machinery/airalarm/alarm = target
	var/mob/user = console.operator
	if(!user)
		return "Не выбран оператор."
	if(alarm.locked && !(alarm.hasSiliconAccessInArea(user) || (user.silicon_privileges & PRIVILEGES_DRONE)))
		return "Панель заблокирована. Используйте ID у устройства или ROOT-команду блокировки."
	var/list/entry = actions[action]
	var/datum/air_alarm_mode/mode = get_air_alarm_mode(entry["mode_id"])
	if(mode?.emag_only && !(alarm.obj_flags & EMAGGED))
		return "Режим недоступен в штатной прошивке устройства."
	return null

/// A node ROOT grant can bypass this endpoint's software lock, never the cut
/// control/ID wires or another machine's ID checks.
/datum/netrun_command/atmos_lock
	id = "atmos_lock"
	name = "Блокировка панели"
	desc = "Переключить программную блокировку воздушной сигнализации."
	help = "ROOT открывает управление этой панелью; перерезанные провода управления или ID требуют ремонта на месте."
	access = NETRUN_ACCESS_ROOT
	icon = "lock"
	trace = 5

/datum/netrun_command/atmos_lock/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/airalarm/alarm = node.parent
	if(alarm.aidisabled || alarm.wires?.is_cut(WIRE_AI) || alarm.wires?.is_cut(WIRE_IDSCAN))
		console.log_line("Контроллер панели отключён проводом; требуется ремонт на месте.", "bad")
		return
	alarm.locked = !alarm.locked
	alarm.update_appearance()
	return "Панель [alarm.locked ? "заблокирована" : "разблокирована"]."

/obj/machinery/atmospherics/components/binary/pump/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 2, list(ACCESS_ATMOSPHERICS))

/obj/machinery/atmospherics/components/binary/pump/netrun_status()
	return list("Насос: [on ? "включён" : "выключен"]", "Давление выхода: [round(target_pressure, 0.1)] кПа")

/// Legacy atmos update_icon() bypasses /atom/update_icon and its normal signal.
/// Publish the same deferred service invalidation for UI, gestures and radio orders.
/obj/machinery/atmospherics/components/binary/pump/update_icon()
	. = ..()
	SEND_SIGNAL(src, COMSIG_NETRUN_SERVICE_STATE_CHANGED)

/obj/machinery/atmospherics/components/binary/volume_pump/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 2, list(ACCESS_ATMOSPHERICS))

/obj/machinery/atmospherics/components/binary/volume_pump/netrun_status()
	return list("Насос: [on ? "включён" : "выключен"]", "Расход: [round(transfer_rate, 0.1)] л/с")

/obj/machinery/atmospherics/components/binary/volume_pump/update_icon()
	. = ..()
	SEND_SIGNAL(src, COMSIG_NETRUN_SERVICE_STATE_CHANGED)

/// Wire pulses and their restoration timers can change control without changing
/// machine_stat or repainting an icon. Keep those entry points observable too.
/datum/wires/airalarm/on_pulse(wire)
	. = ..()
	if(!QDELETED(holder))
		SEND_SIGNAL(holder, COMSIG_NETRUN_SERVICE_STATE_CHANGED)

/datum/wires/airalarm/on_cut(wire, mend)
	. = ..()
	if(!QDELETED(holder))
		SEND_SIGNAL(holder, COMSIG_NETRUN_SERVICE_STATE_CHANGED)

/obj/machinery/airalarm/reset(wire)
	. = ..()
	SEND_SIGNAL(src, COMSIG_NETRUN_SERVICE_STATE_CHANGED)

/datum/netrun_api/atmos_pump
	interface_name = "AtmosPump"
	state_signals = list(COMSIG_UI_ACT, COMSIG_ATOM_UPDATED_ICON, COMSIG_NETRUN_SERVICE_STATE_CHANGED)

/datum/netrun_api/atmos_pump/available(atom/target)
	if(!..())
		return FALSE
	var/obj/machinery/atmospherics/components/pump = target
	return pump.anchored && !pump.panel_open

/datum/netrun_api/atmos_pump/pressure
	atom_type = /obj/machinery/atmospherics/components/binary/pump
	actions = list(
		"power" = list("name" = "Включить/выключить насос", "access" = NETRUN_ACCESS_USER),
		"pressure" = list("name" = "Задать давление", "desc" = "Изменить уставку штатного регулятора давления. Проверьте подключённую линию перед повышением давления.", "access" = NETRUN_ACCESS_USER, "danger" = TRUE, "params" = list(list("id" = "pressure", "name" = "Давление выхода, кПа", "type" = "number", "min" = 0, "max" = MAX_OUTPUT_PRESSURE, "native_text" = TRUE))),
	)

/datum/netrun_api/atmos_pump/volume
	atom_type = /obj/machinery/atmospherics/components/binary/volume_pump
	actions = list(
		"power" = list("name" = "Включить/выключить насос", "access" = NETRUN_ACCESS_USER),
		"rate" = list("name" = "Задать расход", "desc" = "Изменить расход штатного насоса. Ограничение выходного давления остаётся в механике насоса.", "access" = NETRUN_ACCESS_USER, "danger" = TRUE, "params" = list(list("id" = "rate", "name" = "Расход, л/с", "type" = "number", "min" = 0, "max" = MAX_TRANSFER_RATE, "native_text" = TRUE))),
	)
