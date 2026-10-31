/// Useful archives are prepared once per physical server, after authored preloads.
/// No population pass searches for servers or refills an emptied disk.
/datum/controller/subsystem/netrun
	var/server_content_enabled = NETRUN_AUTONOMOUS_CONTENT
	var/list/datum/netrun_server_content_profile/server_content_profiles

/atom/proc/netrun_server_content_profile()
	return null

/obj/machinery/netrun_server/netrun_server_content_profile()
	return "data"

/obj/machinery/netrun_server/stash/netrun_server_content_profile()
	return "stash"

/obj/machinery/rnd/server/netrun_server_content_profile()
	return "research"

/obj/machinery/telecomms/server/netrun_server_content_profile()
	return "telecomms"

/// Shared definitions contain weighted file pools, never a carrier's seed state.
/// A new server archive needs a profile subtype and its carrier's string hook.
/datum/netrun_server_content_profile
	var/id
	var/list/programs = list("patch" = 3, "barrier" = 2, "strike" = 1)
	var/list/daemons = list("buffer" = 3, "extend" = 2, "scrub" = 2)
	var/list/advanced_daemons = list("ghostlink" = 3, "analyst" = 2, "breachkit" = 1)
	/// Null requires a vault; a value also admits an authored hardened archive.
	var/advanced_security

/datum/netrun_server_content_profile/proc/allows_advanced(datum/component/netrun_node/node)
	return (!isnull(advanced_security) && node.base_security >= advanced_security) || node.fortress?.intact_count(NETRUN_FORT_VAULT)

/datum/netrun_server_content_profile/proc/populate(datum/component/netrun_server_archive/archive, datum/component/netrun_node/node)
	// Admission removes authored and selected IDs from a pool. Never mutate a registry definition.
	archive.insert_from_pool(node.file_store, NETRUN_FILE_PROGRAM, programs.Copy())
	archive.insert_from_pool(node.file_store, NETRUN_FILE_DAEMON, daemons.Copy())
	if(allows_advanced(node))
		archive.insert_from_pool(node.file_store, NETRUN_FILE_DAEMON, advanced_daemons.Copy())

/datum/netrun_server_content_profile/data
	id = "data"

/datum/netrun_server_content_profile/research
	id = "research"
	programs = list("patch" = 4, "barrier" = 2)
	daemons = list("buffer" = 3, "extend" = 2, "icepick" = 1)

/datum/netrun_server_content_profile/telecomms
	id = "telecomms"
	programs = list("barrier" = 3, "patch" = 2)
	daemons = list("mapper" = 3, "scrub" = 2, "overclock" = 1)

/datum/netrun_server_content_profile/stash
	id = "stash"
	programs = list("barrier" = 2, "patch" = 2, "strike" = 2)
	daemons = list("icepick" = 2, "cloak" = 2, "mapper" = 2, "scrub" = 1)
	advanced_security = 4

/datum/controller/subsystem/netrun/proc/get_server_content_profile(id)
	RETURN_TYPE(/datum/netrun_server_content_profile)
	if(!server_content_profiles)
		server_content_profiles = list()
		for(var/datum/netrun_server_content_profile/path as anything in subtypesof(/datum/netrun_server_content_profile))
			var/profile_id = initial(path.id)
			if(profile_id)
				server_content_profiles[profile_id] = new path
	return istext(id) ? server_content_profiles[lowertext(trim(id))] : null

/// Node registration calls this once; the component survives replacement of its node.
/atom/proc/ensure_netrun_server_content(datum/component/netrun_node/node)
	if(!SSnetrun.server_content_enabled || node?.node_type != NETRUN_NODE_SERVER)
		return
	var/profile = netrun_server_content_profile()
	if(!SSnetrun.get_server_content_profile(profile))
		return
	var/datum/component/netrun_server_archive/archive = LoadComponent(/datum/component/netrun_server_archive, profile)
	if(!archive.seeded)
		SSnetrun.get_task_scheduler().enqueue("server.content", archive, NETRUN_TASK_BACKGROUND)

/datum/component/netrun_server_archive
	/// Disk deletion and node replacement do not create another set of rewards.
	var/seeded = FALSE
	var/profile
	var/inserted = 0

/datum/component/netrun_server_archive/Initialize(profile)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	src.profile = profile

/datum/component/netrun_server_archive/Destroy()
	SSnetrun.task_scheduler?.cancel("server.content", src)
	return ..()

/datum/component/netrun_server_archive/proc/seed()
	if(seeded || QDELETED(parent))
		return FALSE
	var/atom/host = parent
	var/datum/component/netrun_node/node = host.GetComponent(/datum/component/netrun_node)
	if(QDELETED(node) || node.node_type != NETRUN_NODE_SERVER || QDELETED(node.file_store))
		return FALSE
	var/datum/netrun_server_content_profile/definition = SSnetrun.get_server_content_profile(profile)
	if(!definition)
		return FALSE
	// Commit before modifying storage: storage signals cannot start a second seed.
	seeded = TRUE
	// Advanced tools stay behind an authored hardened archive or an existing vault.
	// This adds files, never access, security overrides or an automatically built fortress.
	definition.populate(src, node)
	return TRUE

/// Each category contributes at most one file; authored copies are never duplicated.
/datum/component/netrun_server_archive/proc/insert_from_pool(datum/netrun_file_store/store, kind, list/pool)
	for(var/datum/netrun_file/existing as anything in store.files)
		if(existing.kind == kind)
			pool -= existing.content
	while(length(pool))
		var/id = pickweight(pool)
		pool -= id
		var/datum/netrun_file/file = kind == NETRUN_FILE_PROGRAM ? netrun_program_file(id) : netrun_daemon_file(id)
		if(QDELETED(file))
			continue
		if(store.insert(file))
			inserted++
			return TRUE
		qdel(file)
	return FALSE

/datum/netrun_task/server_content
	kind = "server.content"

/datum/netrun_task/server_content/execute(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/component/netrun_server_archive/archive = target()
	return !QDELETED(archive) && archive.seed()
