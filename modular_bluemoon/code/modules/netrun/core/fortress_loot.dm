/// A preset is rewarded once per node, including after removal and reconstruction.
/datum/component/netrun_node
	var/fortress_loot_seeded = FALSE
	var/fortress_loot_released = FALSE

/datum/netrun_file
	/// Provenance of an original earned reward, not a second source of ownership.
	var/fortress_reward = FALSE

/datum/netrun_fortress
	var/datum/netrun_file_store/defeat_loot_store
	var/defeat_loot_name
	var/defeat_loot_waiting = FALSE
	var/defeat_loot_draining = FALSE

/// Hidden finite files have one owner and normal capacity before defeat, too.
/datum/netrun_fortress/proc/initialize_defeat_loot(datum/netrun_fortress_preset/preset)
	if(QDELETED(node) || node.fortress_loot_seeded || QDELETED(preset))
		return FALSE
	node.fortress_loot_seeded = TRUE
	defeat_loot_name = preset.name
	defeat_loot_store = new(src, preset.loot_capacity)
	seed_defeat_loot(NETRUN_FILE_PROGRAM, preset.loot_programs, preset.loot_program_count)
	seed_defeat_loot(NETRUN_FILE_DAEMON, preset.loot_daemons, preset.loot_daemon_count)
	return TRUE

/datum/netrun_fortress/proc/seed_defeat_loot(kind, list/choices, count)
	if(!length(choices) || count <= 0)
		return
	var/list/remaining = choices.Copy()
	var/slots = min(4 - length(defeat_loot_store.files), count)
	for(var/index = 1; index <= slots; index++)
		var/inserted = FALSE
		while(length(remaining) && !inserted)
			var/id = pick(remaining)
			remaining -= id
			var/datum/netrun_file/file = kind == NETRUN_FILE_PROGRAM ? netrun_program_file(id) : netrun_daemon_file(id)
			if(QDELETED(file))
				continue
			file.fortress_reward = TRUE
			inserted = !!defeat_loot_store.insert(file)
			if(!inserted)
				qdel(file)

/// Only the actual final combat defeat calls this. Administrative destruction
/// never reveals a reward, and a later repair cannot produce another batch.
/datum/netrun_fortress/proc/release_defeat_loot(datum/netrun_console/attacker)
	if(QDELETED(node) || node.fortress != src || QDELETED(defeat_loot_store))
		return FALSE
	if(!node.fortress_loot_released)
		if(!ruined())
			return FALSE
		node.fortress_loot_released = TRUE
		node.add_log("Защита крепости «[defeat_loot_name]» пала: открыт конечный запас трофеев.")
		attacker?.log_line("Крепость «[defeat_loot_name]» побеждена. Трофеи можно подобрать в её узле.", "good")
	drain_defeat_loot()
	return TRUE

/// A full debris cache never evicts somebody else's files to make room for loot.
/// Remaining earned files wait for a local storage fact, without a polling task.
/datum/netrun_fortress/proc/drain_defeat_loot(publish = TRUE)
	if(defeat_loot_draining || QDELETED(node) || !node.fortress_loot_released || QDELETED(defeat_loot_store))
		return FALSE
	defeat_loot_draining = TRUE
	var/moved = FALSE
	for(var/datum/netrun_file/file as anything in defeat_loot_store.files.Copy())
		if(length(node.salvage) >= NETRUN_MAX_SALVAGE_FILES)
			break
		if(!file.can_transfer(null, TRUE) || !defeat_loot_store.remove(file))
			continue
		if(node.leave_salvage(file, defeat_loot_name, FALSE))
			moved = TRUE
		else
			defeat_loot_store.insert(file, TRUE)
	if(length(defeat_loot_store.files) && !defeat_loot_waiting)
		defeat_loot_waiting = TRUE
		RegisterSignal(node, COMSIG_NETRUN_SALVAGE_CHANGED, PROC_REF(on_defeat_loot_space))
	else if(!length(defeat_loot_store.files) && defeat_loot_waiting)
		UnregisterSignal(node, COMSIG_NETRUN_SALVAGE_CHANGED)
		defeat_loot_waiting = FALSE
	if(moved && publish)
		node.refresh_salvage()
	defeat_loot_draining = FALSE
	return moved

/datum/netrun_fortress/proc/on_defeat_loot_space(datum/source, datum/component/netrun_node/changed)
	SIGNAL_HANDLER
	if(changed == node)
		drain_defeat_loot(FALSE)

/datum/netrun_fortress/proc/clear_defeat_loot()
	if(defeat_loot_waiting && node)
		UnregisterSignal(node, COMSIG_NETRUN_SALVAGE_CHANGED)
	defeat_loot_waiting = FALSE
	QDEL_NULL(defeat_loot_store)
	defeat_loot_name = null
