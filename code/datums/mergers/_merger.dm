/// Tracks one contiguous cluster of atoms of a supplied type set.
/datum/merger
	var/id
	var/list/merged_typecache
	var/attempt_merge_proc
	var/atom/origin
	///Assoc member -> connected cardinal directions.
	var/list/members = list()

/datum/merger/New(id, list/merged_typecache, atom/origin, attempt_merge_proc)
	src.id = id
	src.merged_typecache = merged_typecache
	src.origin = origin
	src.attempt_merge_proc = attempt_merge_proc
	Refresh()

/datum/merger/Destroy(force)
	for(var/atom/thing as anything in members.Copy())
		RemoveMember(thing)
	return ..()

/datum/merger/proc/RemoveMember(atom/thing, clean = TRUE)
	SEND_SIGNAL(thing, COMSIG_MERGER_REMOVING, src)
	UnregisterSignal(thing, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(thing, COMSIG_PARENT_QDELETING)
	if(thing.mergers)
		thing.mergers -= id
		if(clean && !length(thing.mergers))
			thing.mergers = null
	members -= thing
	if(origin == thing)
		origin = length(members) ? pick(members) : null

/datum/merger/proc/AddMember(atom/thing, connected_dir)
	SEND_SIGNAL(thing, COMSIG_MERGER_ADDING, src)
	RegisterSignal(thing, COMSIG_MOVABLE_MOVED, PROC_REF(QueueRefresh))
	RegisterSignal(thing, COMSIG_PARENT_QDELETING, PROC_REF(HandleMemberDel))
	if(!thing.mergers)
		thing.mergers = list()
	else if(thing.mergers[id])
		var/datum/merger/other_merger = thing.mergers[id]
		other_merger.RemoveMember(thing)
		if(!thing.mergers)
			thing.mergers = list()
	thing.mergers[id] = src
	members[thing] = connected_dir
	if(!origin)
		origin = thing

/datum/merger/proc/HandleMemberDel(atom/source)
	SIGNAL_HANDLER
	RemoveMember(source)
	QueueRefresh()

/datum/merger/proc/QueueRefresh()
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(Refresh)), 1, TIMER_UNIQUE)

/datum/merger/proc/Refresh()
	var/list/found_turfs = list()
	if(origin)
		check_turf(get_turf(origin), found_turfs, NONE)
	// C-style on purpose: check_turf appends to found_turfs mid-loop, and the
	// `in 1 to` form freezes its bound at entry, which would stop the flood
	// fill one hop from the origin.
	for(var/i = 1; i <= length(found_turfs); i++)
		var/turf/focus = found_turfs[i]
		var/list/focus_packet = found_turfs[focus]
		var/dirs_checked = focus_packet[MERGE_TURF_PACKET_DIR]
		for(var/direction in GLOB.cardinals)
			if(dirs_checked & direction)
				continue
			var/turf/location = get_step(focus, direction)
			if(!location)
				continue
			if(!check_turf(location, found_turfs, direction))
				if(QDELETED(src))
					return
				continue
			focus_packet[MERGE_TURF_PACKET_DIR] |= direction
	var/list/fresh_members = list()
	for(var/turf/location as anything in found_turfs)
		var/list/turf_packet = found_turfs[location]
		var/connected_dirs = turf_packet[MERGE_TURF_PACKET_DIR]
		for(var/atom/member as anything in turf_packet[MERGE_TURF_PACKET_ATOMS])
			fresh_members[member] = connected_dirs
	var/list/leaving_members = members - fresh_members
	for(var/atom/thing as anything in leaving_members)
		RemoveMember(thing)
	var/list/joining_members = fresh_members - members
	for(var/atom/thing as anything in joining_members)
		AddMember(thing, fresh_members[thing])
	for(var/atom/thing as anything in fresh_members)
		members[thing] = fresh_members[thing]
	SEND_SIGNAL(src, COMSIG_MERGER_REFRESH_COMPLETE, leaving_members, joining_members)
	if(!length(members))
		qdel(src)

/datum/merger/proc/check_turf(turf/location, list/found_turfs, asking_from)
	var/us_to_them = asking_from && turn(asking_from, 180)
	if(found_turfs[location])
		found_turfs[location][MERGE_TURF_PACKET_DIR] |= us_to_them
		return TRUE
	var/found_something = FALSE
	for(var/atom/movable/thing as anything in location)
		if(!merged_typecache[thing.type])
			continue
		if(attempt_merge_proc && !call(thing, attempt_merge_proc)(src, found_turfs))
			continue
		if(thing.mergers?[id] && thing.mergers[id] != src)
			var/datum/merger/existing = thing.mergers[id]
			qdel(src)
			existing.Refresh()
			return FALSE
		if(!found_turfs[location])
			found_turfs[location] = list(us_to_them, list())
		found_turfs[location][MERGE_TURF_PACKET_ATOMS] += thing
		found_something = TRUE
	return found_something
