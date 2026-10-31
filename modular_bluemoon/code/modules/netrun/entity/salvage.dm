/// Only nonempty debris caches are indexed; collectors never need an all-node poll.
/datum/controller/subsystem/netrun
	var/list/salvage_nodes = list()
	var/list/recycling_servers = list()

/datum/netrun_file
	/// Collection policy only: players can recover fresh debris immediately.
	var/salvage_recycle_after = 0

/// Ownership passes from the caller to this bounded cache only on success.
/// Identity, rather than executable kind, distinguishes independently owned files.
/datum/component/netrun_node/proc/leave_salvage(datum/netrun_file/file, source_name, notify = TRUE)
	if(QDELETED(src) || QDELETED(file) || !file.can_transfer(null, TRUE))
		return FALSE
	if(file in salvage)
		return TRUE
	while(length(salvage) >= NETRUN_MAX_SALVAGE_FILES)
		var/datum/netrun_file/expired = salvage[1]
		salvage.Cut(1, 2)
		qdel(expired)
	file.salvage_recycle_after = world.time + NETRUN_SALVAGE_RECYCLE_GRACE
	salvage += file
	add_log("В обломках процесса[source_name ? " [source_name]" : ""] остался файл: [file.name].")
	if(notify)
		refresh_salvage()
	return TRUE

/// One semantic fact wakes interested collectors and updates shared presentation.
/datum/component/netrun_node/proc/refresh_salvage()
	for(var/datum/netrun_file/file as anything in salvage.Copy())
		if(QDELETED(file))
			salvage -= file
	// Earned fortress caches may fill newly freed slots before the shared index
	// and presentation are published. Local listeners must not recursively publish.
	SEND_SIGNAL(src, COMSIG_NETRUN_SALVAGE_CHANGED, src)
	if(!QDELETED(src) && length(salvage))
		SSnetrun.salvage_nodes[address] = src
	else
		SSnetrun.salvage_nodes -= address
	notify_changed(NETRUN_CHANGED_DETAILS)
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_SALVAGE_CHANGED, src)
