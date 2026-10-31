/// Observations never replace live routing or delivery coordinates. An offline
/// mobile endpoint retains the last position it actually announced.
/datum/component/netrun_node
	var/turf/last_known_turf
	var/last_known_sector
	var/last_known_network
	var/last_known_apc
	var/last_seen_at = 0

/datum/component/netrun_node/proc/observe_location(force = FALSE)
	if(!force && last_known_turf && !is_online())
		return last_known_turf
	if(force && pending_physical_update)
		join_network()
	var/turf/current = physical_turf()
	if(force || current != last_known_turf || binding_sector != last_known_sector || network?.id != last_known_network || bound_apc?.address != last_known_apc)
		last_seen_at = world.time
	last_known_turf = current
	last_known_sector = binding_sector
	last_known_network = network?.id
	last_known_apc = bound_apc?.address
	return last_known_turf

/// Only a delivered diagnostic request may refresh an offline observation.
/datum/netrun_command/probe
	id = "probe_location"
	name = "Обновить местоположение"
	desc = "Отправить диагностический запрос и обновить последнее известное положение узла."
	access = NETRUN_ACCESS_GUEST
	trace = 0
	read_only = TRUE
	works_offline = TRUE
	icon = "location-dot"

/datum/netrun_command/probe/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/turf/position = node.observe_location(TRUE)
	node.queue_presentation(NETRUN_CHANGED_STATE)
	if(!position)
		return "[node.address]: положение недоступно."
	return "[node.address]: последнее положение [position.x], [position.y], Z[position.z]. [node.is_online() ? "Узел отвечает." : "Узел отключён; рабочие команды недоступны."]"
