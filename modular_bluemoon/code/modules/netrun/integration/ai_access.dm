/// Station AIs are clients of their real core node, rather than a camera's or an APC's identity.
/mob/living/silicon/ai
	var/datum/netrun_console/ai/netrun_console
	var/datum/action/innate/ai_netrun/network_action

/mob/living/silicon/ai/proc/initialize_netrun_access()
	if(netrun_console)
		return
	netrun_console = new(src, NETRUN_ORIGIN_AI)
	AddComponent(/datum/component/netrun_access_device, netrun_console, NETRUN_NODE_AI, 5)
	network_action = new
	network_action.Grant(src)
	add_verb(src, /mob/living/silicon/ai/proc/open_netrun_network)

/mob/living/silicon/ai/proc/destroy_netrun_access()
	QDEL_NULL(netrun_console)
	QDEL_NULL(network_action)
	remove_verb(src, /mob/living/silicon/ai/proc/open_netrun_network)

/// control_disabled is also the native intelliCard wireless-port switch.
/// Check actual power as well as the restoration state: power loss need not wait for Life().
/mob/living/silicon/ai/proc/netrun_control_available()
	return !QDELETED(src) && stat == CONSCIOUS && !control_disabled && !incapacitated() && !lacks_power()

/mob/living/silicon/ai/proc/open_netrun_network()
	set category = "AI Commands"
	set name = "Access Network"
	set desc = "Открыть сетевую карту, управление машинами и журнал пакетов ядра ИИ."

	if(!netrun_control_available())
		to_chat(src, span_warning("Сетевой клиент недоступен: проверьте питание ядра и беспроводное управление."))
		return FALSE
	netrun_console?.ui_interact(src)
	return !!netrun_console

/mob/living/silicon/ai/netrun_owner_access(datum/netrun_console/console)
	return netrun_console_owner(console) == src ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/datum/action/innate/ai_netrun
	name = "Сеть"
	desc = "Открыть сетевую карту и штатное управление подключёнными машинами."
	button_icon_state = "camera_jump"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	background_icon_state = "bg_tech_blue"

/datum/action/innate/ai_netrun/Trigger()
	var/mob/living/silicon/ai/ai = owner
	if(istype(ai))
		return ai.open_netrun_network()
	return FALSE

/datum/netrun_console/ai
	name = "сетевой клиент ИИ"
	tgui_title = "Сеть ИИ"
	initial_storage_capacity = 12 * NETRUN_STORAGE_SCALE

/datum/netrun_console/ai/New(atom/host, origin)
	. = ..()
	operator = host
	state_override = GLOB.conscious_state
	// The core is an ordinary wired endpoint in its own LAN. The AI eye is never a route source.
	connection.wireless = FALSE

/datum/netrun_console/ai/proc/available_to(mob/user = operator)
	var/mob/living/silicon/ai/ai = host
	return istype(ai) && user == ai && ai.netrun_control_available()

/datum/netrun_console/ai/ui_status(mob/user, datum/ui_state/state)
	if(!available_to(user))
		return UI_CLOSE
	return ..()

/datum/netrun_console/ai/ui_interact(mob/user, datum/tgui/ui)
	if(!available_to(user))
		return
	return ..()

/datum/netrun_console/ai/ui_data(mob/user, datum/ui_source)
	if(!available_to(user || operator))
		return list()
	return ..()

/datum/netrun_console/ai/ui_static_data(mob/user)
	if(!available_to(user || operator))
		return list()
	return ..()

/datum/netrun_console/ai/handle_ui_action(action, list/params, datum/tgui/ui, input_nonce)
	if(!available_to(ui?.user))
		return FALSE
	return ..()

/datum/netrun_console/ai/user_access(fresh = FALSE)
	if(!available_to())
		return list()
	// Keep the ordinary silicon credentials and each target's native authorization checks.
	return ..()

/datum/netrun_console/ai/physical_route_source()
	if(!available_to())
		return
	return refresh_route_node(host.GetComponent(/datum/component/netrun_node))

/datum/netrun_console/ai/can_route(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	// Queued packets and callers supplying a cached tree must also recheck the AI at delivery.
	return available_to() && ..()

/datum/netrun_console/ai/has_uplink()
	return available_to() && ..()

/datum/netrun_console/ai/view_denial(datum/component/netrun_node/node)
	if(!available_to())
		return "Управление ИИ недоступно."
	return ..()

/mob/living/silicon/ai/netrun_view_denial(datum/component/netrun_node/node)
	if(istype(node?.parent, /obj/machinery/camera))
		return netrun_camera_access_error(node.parent)
	return ..()

/// Camera networks still delimit native AI vision; a routable camera is not automatically visible.
/mob/living/silicon/ai/proc/netrun_camera_access_error(obj/machinery/camera/camera)
	if(!netrun_control_available())
		return "Управление ИИ недоступно."
	if(!isturf(loc))
		return "Для обзора камер ИИ должен находиться в ядре."
	if(QDELETED(camera) || !get_turf(camera) || !camera.can_use() || !camera.netrun_online())
		return "Камера не передаёт изображение."
	var/list/ai_networks = islist(network) ? network : list(network)
	if(!length(ai_networks & camera.network))
		return "Камера не входит в выбранную камерную сеть ИИ."
	return null

/datum/netrun_command/cam_ai_jump
	id = "cam_ai_jump"
	name = "Перейти к камере (ИИ)"
	desc = "Переместить глаз ИИ к работающей камере его выбранной камерной сети."
	help = "Доступно только ИИ. Сетевой маршрут не отменяет ограничения камерной сети или отключение беспроводного управления."
	access = NETRUN_ACCESS_USER
	icon = "eye"
	trace = 0

/datum/netrun_command/cam_ai_jump/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	var/mob/living/silicon/ai/ai = netrun_console_owner(console)
	if(!istype(ai) || ai.netrun_camera_access_error(node.parent))
		.["allowed"] = FALSE

/datum/netrun_command/cam_ai_jump/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/mob/living/silicon/ai/ai = netrun_console_owner(console)
	if(!istype(ai))
		console.log_line("Переход к камере доступен только ИИ.", "bad")
		return
	var/obj/machinery/camera/camera = node.parent
	var/reason = ai.netrun_camera_access_error(camera)
	if(reason)
		console.log_line(reason, "bad")
		return
	if(!ai.switchCamera(camera))
		console.log_line("Глаз ИИ не смог подключиться к камере.", "bad")
		return
	return "Глаз ИИ подключён к камере [node.get_name()]."
