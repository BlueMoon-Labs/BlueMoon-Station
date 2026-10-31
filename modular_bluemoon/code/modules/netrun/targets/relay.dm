// MARK: Квантовое реле NTnet как узел
//
// Реле держит магистраль NTnet. Теперь его видно в сети и можно отключить с ROOT-доступом -
// это рубит беспроводной доступ всем, кто не сидит в своей ЛВС по проводу.

/obj/machinery/ntnet_relay/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_GATEWAY, list("relay_toggle", "reboot"), 4, list(ACCESS_NETWORK))

/obj/machinery/ntnet_relay/netrun_online(remote = TRUE)
	return is_operational()

/obj/machinery/ntnet_relay/netrun_status()
	. = list()
	. += "Магистраль: [is_operational() ? "работает" : "ОТКЛЮЧЕНА"]"
	. += "Буфер нагрузки: [dos_overload]/[dos_capacity]"
	if(dos_failure)
		. += "ВНИМАНИЕ: реле в режиме восстановления"

/datum/netrun_command/relay_toggle
	id = "relay_toggle"
	name = "Питание реле"
	desc = "Включить или выключить квантовое реле. Выключенное реле рвёт беспроводную сеть."
	access = NETRUN_ACCESS_ROOT
	icon = "satellite-dish"
	trace = 8
	danger = TRUE

/datum/netrun_command/relay_toggle/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/ntnet_relay/relay = node.parent
	relay.enabled = !relay.enabled
	relay.update_icon()
	SSnetworks.station_network.add_log("Quantum relay [relay.enabled ? "enabled" : "disabled"] via network command.")
	return "Реле [relay.enabled ? "включено" : "выключено"]."
