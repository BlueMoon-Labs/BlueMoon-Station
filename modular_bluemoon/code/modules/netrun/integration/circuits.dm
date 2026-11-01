/// Сетевой мост использует штатные ID-доступы сборки; ключ ЛВС открывает только обнаружение.
/obj/item/integrated_circuit/input/netrun_link
	name = "network node uplink"
	desc = "Отправляет разрешённые команды узлам сети. Ключ ЛВС открывает обнаружение; права на управление проверяются отдельно."
	extended_desc = "Адрес узла в формате XXXX:XXXX, id команды (например door_open, apc_breaker, cam_toggle) и ключ ЛВС. \
		Ключ ЛВС не выдаёт права управления машиной. Для них отсканируйте подходящую ID-карту штатным ID card reader в этой сборке. \
		Результат выполнения - на первом выходе."
	icon_state = "signal"
	complexity = 6
	cooldown_per_use = 2 SECONDS
	inputs = list(
		"node address" = IC_PINTYPE_STRING,
		"command" = IC_PINTYPE_STRING,
		"network key" = IC_PINTYPE_STRING,
	)
	outputs = list(
		"result" = IC_PINTYPE_STRING,
		"node name" = IC_PINTYPE_STRING,
	)
	activators = list(
		"execute" = IC_PINTYPE_PULSE_IN,
		"on success" = IC_PINTYPE_PULSE_OUT,
		"on failure" = IC_PINTYPE_PULSE_OUT,
	)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_LONG_RANGE
	power_draw_per_use = 60
	var/datum/netrun_console/circuit/console

/obj/item/integrated_circuit/input/netrun_link/Initialize(mapload)
	. = ..()
	console = new(src, NETRUN_ORIGIN_CIRCUIT)

/obj/item/integrated_circuit/input/netrun_link/Destroy()
	QDEL_NULL(console)
	return ..()

/obj/item/integrated_circuit/input/netrun_link/do_work()
	var/datum/component/netrun_node/node = SSnetrun.find_node(get_pin_data(IC_INPUT, 1))
	var/command_id = lowertext(trim("[get_pin_data(IC_INPUT, 2)]"))
	console.inventory.local_store.clear()
	if(node?.network)
		var/key = "[get_pin_data(IC_INPUT, 3)]"
		if(length(key))
			console.inventory.local_store.insert(new /datum/netrun_file("key", NETRUN_FILE_KEY, uppertext(trim(key)), 1, node.network.id))
	console.log.Cut()
	var/success = node && console.run_command(node, command_id)
	var/list/last = length(console.log) ? console.log[length(console.log)] : null
	set_pin_data(IC_OUTPUT, 1, last ? last["text"] : "Узел не найден.")
	set_pin_data(IC_OUTPUT, 2, node ? node.get_name() : null)
	push_data()
	activate_pin(success ? 2 : 3)

/datum/netrun_console/circuit
	name = "сетевой мост"
	origin = NETRUN_ORIGIN_CIRCUIT
	initial_can_breach = FALSE
	initial_storage_capacity = 1 * NETRUN_STORAGE_SCALE

/datum/netrun_console/circuit/New(atom/host, origin)
	. = ..()
	SSnetrun.consoles -= src // схеме не нужна трассировка по таймеру

/datum/netrun_console/circuit/home_networks()
	. = list()
	var/datum/component/netrun_node/source = route_source()
	if(source?.network)
		. += source.network

/datum/netrun_console/circuit/is_home_network(datum/netrun_network/network, datum/netrun_path_tree/tree)
	var/datum/component/netrun_node/source = tree ? tree.source : route_source()
	return network && source?.network == network

/datum/netrun_console/circuit/user_access(fresh = FALSE)
	var/obj/item/integrated_circuit/chip = host
	if(!istype(chip) || QDELETED(chip))
		return list()
	var/obj/item/electronic_assembly/assembly = chip.assembly
	if(QDELETED(assembly) || !(chip in assembly.assembly_components))
		return list()
	// The native card reader populates this same card for assembly Bump()/pathfinding.
	var/obj/item/card/id/card = assembly.access_card
	if(QDELETED(card) || card.loc != assembly)
		return list()
	var/list/accesses = card.GetAccess()
	return accesses ? accesses.Copy() : list()

/datum/netrun_console/circuit/log_source()
	return "интегральная схема"

/datum/netrun_console/circuit/run_command(datum/component/netrun_node/node, command_id, input_nonce)
	// Схема работает только легально: без нужного доступа команда просто не выполняется
	var/datum/netrun_command/command = SSnetrun.get_command(command_id)
	if(command && node && legit_node_level(node) < command.access)
		log_line("Недостаточно прав: ключ ЛВС даёт только гостевой вход. Отсканируйте подходящую ID-карту считывателем этой сборки.", "bad")
		return FALSE
	next_command = 0
	return ..()

/datum/netrun_console/circuit/log_line(text, kind)
	log += list(list("text" = text, "kind" = kind))

/datum/netrun_console/circuit/add_trace(amount)
	return

/datum/netrun_console/circuit/latency_to(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return 0
