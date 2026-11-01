/// The native mapped-atom pipeline must arm a console before its first UI/readiness callback.
/datum/unit_test/netrun_research_native_mapped_console_startup/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.network_id = "native-mapped-console-fixture"
	// Reproduce map loading: New defers initialization, then SSatoms performs
	// Initialize and its real LateInitialize batch behind the closed barrier.
	SSatoms.map_loader_begin()
	var/obj/machinery/computer/rdconsole/console = new(scene.source_spot)
	scene.owned += console
	console.network_id = server.network_id
	var/deferred = !(console.flags_1 & INITIALIZED_1)
	SSatoms.initialized = INITIALIZATION_INNEW_MAPLOAD
	SSatoms.InitializeAtoms(list(console))
	SSatoms.map_loader_stop()
	// Shared loader state is restored before assertions, including failure exits.
	TEST_ASSERT(deferred && (console.flags_1 & INITIALIZED_1), "The fixture must use native deferred mapped initialization, never a direct LateInitialize call")
	var/datum/component/techweb_holder/holder = console.GetComponent(/datum/component/techweb_holder)
	TEST_ASSERT_NOTNULL(holder, "Native mapped LateInitialize must create the console's real techweb holder")
	TEST_ASSERT(!holder.had_authority && !console.stored_research, "A closed native readiness barrier must defer initial authority binding")
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	TEST_ASSERT(!client.wants_snapshots && client.resync_timer, "A newly initialized mapped console must arm automatic binding without requesting a full database behind the closed barrier")
	// Simulate expiration of its existing watch before the bulk ready wave reaches
	// this client; no network_ready, binding signal or player interaction is used.
	deltimer(client.resync_timer)
	client.check_subscription()
	TEST_ASSERT_EQUAL(console.stored_research, server.stored_research, "The first native watch must bind a mapped console once real routes are ready")
	TEST_ASSERT(holder.had_authority, "Successful native selection must preserve the holder's authority-loss policy")
	var/deadline = world.time + 5 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_NOTNULL(console.netrun_research_cache, "The untouched mapped console must receive its actual startup presentation snapshot")

/// AUTO is a selector, never a blank player-facing network name.
/datum/unit_test/netrun_research_server_network_status/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	TEST_ASSERT_EQUAL(server.network_id, RND_NETWORK_AUTO, "The fixture must retain the real empty AUTO selector")
	var/network_line
	for(var/line in server.netrun_status())
		if(findtext(line, "Сеть РнД:"))
			network_line = line
	TEST_ASSERT(network_line && findtext(network_line, RND_NETWORK_STATION), "AUTO station servers must display the resolved scientific network, not an empty selector")
	var/datum/netrun_command/report = SSnetrun.get_command("rnd_report")
	TEST_ASSERT(findtext(report.execute(server.GetComponent(/datum/component/netrun_node)), server.netrun_research_network_label()), "The report and native card must use the same resolved network name")
	server.network_id = RND_NETWORK_SYNDICATE
	var/faction_named = FALSE
	for(var/line in server.netrun_status())
		if(findtext(line, "Сеть РнД:") && findtext(line, RND_NETWORK_SYNDICATE))
			faction_named = TRUE
	TEST_ASSERT(faction_named, "An explicit faction network must retain its configured identity in native status")

/// Startup maps join compatible physical servers and bind native clients asynchronously.
/datum/unit_test/netrun_research_automatic_startup/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	first.netrun_mapped_server = TRUE
	second.netrun_mapped_server = TRUE
	first.network_id = "startup-fixture"
	second.network_id = first.network_id
	var/datum/netrun_machine_service/research_server/service = second.get_netrun_machine_service("research.server")
	service.network_ready()
	TEST_ASSERT_NOTEQUAL(second.stored_research, first.stored_research, "Readiness must enqueue the join instead of merging databases inline")
	var/deadline = world.time + 5 SECONDS
	while(second.stored_research != first.stored_research && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(second.stored_research, first.stored_research, "Reachable mapped servers in the same configured network must join at readiness")
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	console.network_id = first.network_id
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	client.network_ready()
	TEST_ASSERT_EQUAL(console.stored_research, first.stored_research, "A startup console must bind without a manual techweb signal")
	deadline = world.time + 5 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_NOTNULL(console.netrun_research_cache, "Automatic binding must deliver the native console's real presentation snapshot")
	var/obj/machinery/rnd/server/independent = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	independent.network_id = first.network_id
	var/datum/netrun_machine_service/research_server/independent_service = independent.get_netrun_machine_service("research.server")
	independent_service.network_ready()
	TEST_ASSERT_NOTEQUAL(independent.stored_research, first.stored_research, "Newly constructed servers must remain independent until explicitly linked")

/// A nearby console cannot lend a fabricator an unreachable research authority.
/obj/machinery/mecha_part_fabricator/netrun_route_fixture
	var/network_id = "netrun-fabricator-route-fixture"

/datum/unit_test/netrun_research_fabricator_reachable_authority/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/unreachable = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/reachable = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	unreachable.network_id = "netrun-fabricator-route-fixture"
	reachable.network_id = unreachable.network_id
	unreachable.set_machine_stat(BROKEN)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, unreachable.stored_research)
	TEST_ASSERT_EQUAL(netrun_atom_techweb(console), unreachable.stored_research, "The nearby console must retain the intentionally unreachable binding")
	var/obj/machinery/mecha_part_fabricator/netrun_route_fixture/fabricator = scene.machine(/obj/machinery/mecha_part_fabricator/netrun_route_fixture, scene.source_spot)
	SSnetrun.ensure_topology()
	var/datum/netrun_machine_service/research_client/client = fabricator.get_netrun_machine_service("research.client")
	TEST_ASSERT(fabricator.sync(TRUE, TRUE), "A reachable authority must accept a real synchronization request")
	TEST_ASSERT_EQUAL(netrun_atom_techweb(fabricator), reachable.stored_research, "A nearby console must not override physical server selection")
	var/deadline = world.time + 5 SECONDS
	while(client.snapshot_binding != REF(reachable.stored_research) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(client.snapshot_binding, REF(reachable.stored_research), "The selected physical server must deliver a real snapshot")
	TEST_ASSERT_EQUAL(client.live_authority(), reachable.stored_research, "The synchronization must retain an online, reachable authority")

/// Point-producing clients bind automatically without becoming snapshot subscribers.
/datum/unit_test/netrun_research_producer_snapshot_demand/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/power/tesla_coil/coil = scene.machine(/obj/machinery/power/tesla_coil, scene.source_spot)
	var/datum/netrun_machine_service/research_client/client = coil.get_netrun_machine_service("research.client")
	var/datum/netrun_machine_service/research_server/authority = server.get_netrun_machine_service("research.server")
	client.network_ready()
	TEST_ASSERT_EQUAL(coil.linked_techweb, server.stored_research, "A native point producer must automatically bind to the reachable physical authority")
	TEST_ASSERT(!client.wants_snapshots, "Binding a Tesla coil must not opt it into full presentation replication")
	deltimer(client.resync_timer)
	client.check_subscription()
	TEST_ASSERT(!client.wants_snapshots && !client.snapshot_cache, "The ordinary binding timer must not create an unused producer cache")
	TEST_ASSERT_EQUAL(length(client.resolutions), 0, "Binding and revision maintenance must create no snapshot discovery request for a producer")
	TEST_ASSERT(!authority.subscribers[client.node.address], "A bound producer must not enter the server's publication fanout")
	TEST_ASSERT(client.request(), "An explicit read must still admit a real research snapshot")
	var/deadline = world.time + 5 SECONDS
	while(!client.snapshot_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_NOTNULL(client.snapshot_cache, "Explicit presentation demand must receive the actual server snapshot")
	TEST_ASSERT(client.wants_snapshots && authority.subscribers[client.node.address], "Only explicit reading may turn the producer into a snapshot subscriber")

/// An earlier mapped server can recover after its original readiness callback failed.
/datum/unit_test/netrun_research_startup_client_retry/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.set_machine_stat(BROKEN)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	client.network_ready()
	TEST_ASSERT(!console.stored_research && client.resync_timer && !client.wants_snapshots, "Unavailable startup must keep the automatic binding timer armed without inventing an authority or requesting a full database")
	server.set_machine_stat(0)
	deltimer(client.resync_timer)
	client.check_subscription()
	TEST_ASSERT_EQUAL(console.stored_research, server.stored_research, "The ordinary revision watch must bind a never-connected console after power recovery")
	var/deadline = world.time + 5 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_NOTNULL(console.netrun_research_cache, "Recovery must deliver a snapshot without opening the console or manually selecting a server")

/datum/unit_test/netrun_research_startup_power_recovery/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	first.netrun_mapped_server = TRUE
	second.netrun_mapped_server = TRUE
	first.network_id = "startup-power-fixture"
	second.network_id = first.network_id
	first.set_machine_stat(BROKEN)
	var/datum/netrun_machine_service/research_server/first_service = first.get_netrun_machine_service("research.server")
	var/datum/netrun_machine_service/research_server/second_service = second.get_netrun_machine_service("research.server")
	first_service.network_ready()
	second_service.network_ready()
	var/deadline = world.time + 5 SECONDS
	while((first_service.cluster_queued || second_service.cluster_queued) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(!first_service.cluster_queued && !second_service.cluster_queued, "A failed startup wave must drain instead of polling an unavailable server forever")
	TEST_ASSERT_NOTEQUAL(first.stored_research, second.stored_research, "An unavailable mapped server must not merge its database")
	first.set_machine_stat(0)
	TEST_ASSERT(first_service.cluster_queued, "Native power/stat restoration must enqueue the earlier server's fresh scan")
	deadline = world.time + 5 SECONDS
	while(first.stored_research != second.stored_research && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(first.stored_research, second.stored_research, "The earlier recovered server must be able to join a later mapped authority")
	TEST_ASSERT_EQUAL(length(first.stored_research.research_owner_refs), 2, "Recovered mapped servers must retain both physical owners")
	var/obj/machinery/rnd/server/temperature_peer = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	temperature_peer.netrun_mapped_server = TRUE
	temperature_peer.network_id = first.network_id
	temperature_peer.working = FALSE
	var/datum/netrun_machine_service/research_server/temperature_service = temperature_peer.get_netrun_machine_service("research.server")
	temperature_service.cluster_topology_changed()
	temperature_service.advance_cluster()
	TEST_ASSERT(!temperature_service.cluster_queued, "An unworking server must finish its unavailable startup wave")
	temperature_peer.process()
	TEST_ASSERT(temperature_peer.working && temperature_service.cluster_queued, "Native temperature recovery must detect its direct working assignment and queue startup immediately")
	deadline = world.time + 5 SECONDS
	while(temperature_peer.stored_research != first.stored_research && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(temperature_peer.stored_research, first.stored_research, "Temperature recovery must join the existing mapped authority without waiting for a node poll")

/// Late service initialization and repeated notifications share one resumable scan.
/datum/unit_test/netrun_research_startup_scan_bound/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	server.netrun_mapped_server = TRUE
	server.network_id = "startup-scan-source"
	for(var/i in 1 to 12)
		var/obj/machinery/rnd/server/other = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
		other.netrun_mapped_server = TRUE
		other.network_id = "startup-other-[i]"
	var/datum/netrun_machine_service/research_server/service = server.get_netrun_machine_service("research.server")
	// The common startup snapshot has already completed. A native lifecycle hook
	// must still admit this late mapped service without a new global bootstrap.
	service.host_initialized()
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/key = "research.cluster:[REF(service)]"
	var/datum/netrun_task/original = scheduler.by_key[key]
	TEST_ASSERT_NOTNULL(original, "A late mapped service must enqueue startup through its native initialization hook")
	for(var/i in 1 to 32)
		service.network_ready()
	TEST_ASSERT_EQUAL(scheduler.by_key[key], original, "Readiness storms must retain one common-worker task")
	TEST_ASSERT(!service.advance_cluster(), "One slice cannot scan all thirteen mapped candidates")
	TEST_ASSERT_EQUAL(service.cluster_cursor, 2, "The first slice must compare exactly one candidate")
	var/list/wave = service.cluster_candidates
	// Tasks are disposable. Only the service may own continuation progress.
	scheduler.cancel("research.cluster", service)
	var/datum/netrun_task/research_cluster/task = allocate(/datum/netrun_task/research_cluster, "research.cluster", "scan-fixture", NETRUN_TASK_BACKGROUND, service)
	task.execute(SSnetrun)
	TEST_ASSERT_EQUAL(service.cluster_candidates, wave, "A recreated continuation must reuse its service-owned candidate wave")
	TEST_ASSERT_EQUAL(service.cluster_cursor, 3, "A recreated continuation must advance by only one candidate")
	var/steps = 0
	while(service.cluster_queued && steps++ < 1000)
		var/before = service.cluster_cursor
		if(service.advance_cluster())
			break
		TEST_ASSERT(service.cluster_cursor <= before + 1, "Every continuation slice must perform at most one peer comparison")
	TEST_ASSERT(!service.cluster_queued, "A finite unmatched wave must drain its task and scan state")
	TEST_ASSERT_NULL(service.cluster_candidates, "Completed startup must release its candidate references")
	TEST_ASSERT_EQUAL(length(server.stored_research.research_owner_refs), 1, "Different configured networks must remain isolated throughout startup")
	service.network_ready()
	qdel(server)
	TEST_ASSERT_NULL(scheduler.by_key[key], "Physical server deletion must cancel its queued startup continuation")
	TEST_ASSERT_NULL(service.cluster_candidates, "Server deletion must release an unfinished candidate wave")
	TEST_ASSERT(!service.cluster_listening, "Server deletion must release its power and global topology listeners")

/// Research resolves the first eligible physical owner without changing the
/// unicast policy or requiring every cluster member to remain available.
/datum/unit_test/netrun_research_discovery_unicast/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, first.stored_research)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, first.stored_research)
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	var/datum/netrun_machine_service/research_server/first_service = first.get_netrun_machine_service("research.server")
	var/datum/netrun_machine_service/research_server/second_service = second.get_netrun_machine_service("research.server")
	TEST_ASSERT_EQUAL(client.discovery_target_limit("research.server"), 1, "Only one eligible physical owner may receive a research operation")
	TEST_ASSERT_EQUAL(client.discovery_target_limit("research.client"), 0, "Research unicast must not silently limit unrelated discovery")
	var/list/targets = client.resolve("research.server", REF(first.stored_research))
	TEST_ASSERT_EQUAL(length(targets), 1, "Synchronous research discovery must preserve unicast")
	TEST_ASSERT_EQUAL(targets[1], first_service, "Discovery must retain the existing registry selection order")
	first.set_machine_stat(BROKEN)
	targets = client.resolve("research.server", REF(second.stored_research))
	TEST_ASSERT_EQUAL(length(targets), 1, "An unavailable earlier owner must not prevent discovery of a live peer")
	TEST_ASSERT_EQUAL(targets[1], second_service, "Research discovery must fail over to the next eligible physical owner")
	var/list/selected = client.select_targets("research.server", list(first_service, second_service))
	TEST_ASSERT_EQUAL(length(selected), 1, "The public final-selection hook must remain compatible with complete candidate lists")
	TEST_ASSERT_EQUAL(selected[1], first_service, "Early stopping must not change the independent final-selection contract")

/// A closed startup or later map-loading barrier parks clustering until the
/// common readiness wave observes usable routes, rather than spinning tasks.
/datum/unit_test/netrun_research_cluster_readiness_parking/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	first.netrun_mapped_server = TRUE
	second.netrun_mapped_server = TRUE
	first.network_id = "parked-cluster-[REF(scene)]"
	second.network_id = first.network_id
	var/datum/netrun_machine_service/research_server/first_service = first.get_netrun_machine_service("research.server")
	var/datum/netrun_machine_service/research_server/second_service = second.get_netrun_machine_service("research.server")
	first_service.finish_cluster()
	second_service.finish_cluster()
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	scheduler.cancel("service_initialize", first_service)
	scheduler.cancel("service_initialize", second_service)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	SSatoms.map_loader_begin()
	first_service.queue_cluster()
	second_service.queue_cluster()
	first.set_machine_stat(BROKEN)
	first.set_machine_stat(0)
	var/finished_while_closed = first_service.advance_cluster()
	var/polling_while_closed = first_service.cluster_queued || second_service.cluster_queued || scheduler.by_key["research.cluster:[REF(first_service)]"] || scheduler.by_key["research.cluster:[REF(second_service)]"]
	var/datum/weakref/first_reference = transport.pending_ready_services[first_service.service_key()]
	var/datum/weakref/second_reference = transport.pending_ready_services[second_service.service_key()]
	var/parked = first_reference?.resolve() == first_service && second_reference?.resolve() == second_service
	SSatoms.map_loader_stop()
	transport.prepare_network()
	TEST_ASSERT(first_service.start_when_ready && second_service.start_when_ready, "Mapped research servers must participate in the common startup readiness wave")
	TEST_ASSERT(finished_while_closed && !polling_while_closed && parked, "Closed readiness must retain one demand per server without runnable cluster continuations")
	var/deadline = world.time + 5 SECONDS
	while(first.stored_research != second.stored_research && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(first.stored_research, second.stored_research, "Reopening readiness must resume parked clustering and retain native power recovery")
	TEST_ASSERT_EQUAL(length(first.stored_research.research_owner_refs), 2, "Resumed startup must preserve both physical research owners")

/// Already formed startup clusters must unite after a real relay recovers.
/datum/unit_test/netrun_research_startup_partition_recovery/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	var/area/remote_room = scene.room(/area/netrun_route_test)
	var/turf/remote_spot = scene.take(locate(80, 80, levels[1]), remote_room, TRUE)
	scene.machine(/obj/machinery/power/apc, scene.take(locate(81, 80, levels[1]), remote_room, TRUE))
	var/obj/machinery/ntnet_relay/local_relay = scene.machine(/obj/machinery/ntnet_relay, scene.source_spot)
	var/obj/machinery/ntnet_relay/remote_relay = scene.machine(/obj/machinery/ntnet_relay, scene.take(locate(82, 80, levels[1]), remote_room, TRUE))
	remote_relay.set_machine_stat(BROKEN)
	SSnetworks.station_network.setting_disabled = FALSE
	var/list/local_servers = list()
	var/list/remote_servers = list()
	for(var/i in 1 to 2)
		var/obj/machinery/rnd/server/local = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
		var/obj/machinery/rnd/server/remote = scene.machine(/obj/machinery/rnd/server, remote_spot)
		local.netrun_mapped_server = TRUE
		remote.netrun_mapped_server = TRUE
		local.network_id = "startup-partition-fixture"
		remote.network_id = local.network_id
		local_servers += local
		remote_servers += remote
	SSnetrun.ensure_topology()
	for(var/obj/machinery/rnd/server/member as anything in local_servers + remote_servers)
		var/datum/netrun_machine_service/research_server/service = member.get_netrun_machine_service("research.server")
		service.network_ready()
	var/obj/machinery/rnd/server/first_local = local_servers[1]
	var/obj/machinery/rnd/server/second_local = local_servers[2]
	var/obj/machinery/rnd/server/first_remote = remote_servers[1]
	var/obj/machinery/rnd/server/second_remote = remote_servers[2]
	var/deadline = world.time + 5 SECONDS
	while((first_local.stored_research != second_local.stored_research || first_remote.stored_research != second_remote.stored_research) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(first_local.stored_research, second_local.stored_research, "The local partition must first form its real two-owner startup cluster")
	TEST_ASSERT_EQUAL(first_remote.stored_research, second_remote.stored_research, "The remote partition must first form its real two-owner startup cluster")
	TEST_ASSERT_NOTEQUAL(first_local.stored_research, first_remote.stored_research, "A broken inter-sector relay must isolate the two configured clusters")
	TEST_ASSERT(local_relay.is_operational(), "The source relay must remain operational while the remote relay is unavailable")
	remote_relay.set_machine_stat(0)
	deadline = world.time + 5 SECONDS
	while(first_local.stored_research != first_remote.stored_research && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(first_local.stored_research, first_remote.stored_research, "Relay recovery must join previously formed startup clusters without manual rebind")
	TEST_ASSERT_EQUAL(length(first_local.stored_research.research_owner_refs), 4, "The recovered authority must retain all four physical owners")
	var/datum/techweb/authority = first_local.stored_research
	var/deadline_drain = world.time + 5 SECONDS
	var/pending = TRUE
	while(pending && world.time < deadline_drain)
		pending = FALSE
		for(var/obj/machinery/rnd/server/member as anything in local_servers + remote_servers)
			var/datum/netrun_machine_service/research_server/service = member.get_netrun_machine_service("research.server")
			pending = pending || service.cluster_queued
		if(pending)
			sleep(world.tick_lag)
	TEST_ASSERT(!pending, "Self-generated merge notifications must not keep startup waves running forever")
	TEST_ASSERT_EQUAL(first_local.stored_research, authority, "Draining startup waves must not repeatedly replace the merged authority")

/// The native global NTnet toggle changes no relay stat and emits no node signal.
/datum/unit_test/netrun_research_startup_backbone_recovery/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	var/area/remote_room = scene.room(/area/netrun_route_test)
	var/turf/remote_spot = scene.take(locate(80, 80, levels[1]), remote_room, TRUE)
	scene.machine(/obj/machinery/power/apc, scene.take(locate(81, 80, levels[1]), remote_room, TRUE))
	scene.machine(/obj/machinery/ntnet_relay, scene.source_spot)
	scene.machine(/obj/machinery/ntnet_relay, scene.take(locate(82, 80, levels[1]), remote_room, TRUE))
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, remote_spot)
	first.netrun_mapped_server = TRUE
	second.netrun_mapped_server = TRUE
	first.network_id = "startup-backbone-fixture"
	second.network_id = first.network_id
	SSnetworks.station_network.setting_disabled = TRUE
	SSnetrun.ensure_topology()
	var/datum/netrun_machine_service/research_server/first_service = first.get_netrun_machine_service("research.server")
	var/datum/netrun_machine_service/research_server/second_service = second.get_netrun_machine_service("research.server")
	first_service.network_ready()
	second_service.network_ready()
	var/deadline = world.time + 5 SECONDS
	while((first_service.cluster_queued || second_service.cluster_queued) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(!first_service.cluster_queued && !second_service.cluster_queued, "A disabled backbone must let the failed finite startup waves drain")
	TEST_ASSERT_NOTEQUAL(first.stored_research, second.stored_research, "Disabled NTnet must keep the two real sectors' mapped servers apart")
	SSnetworks.station_network.setting_disabled = FALSE
	// Use the native processing seam, without manually announcing topology or
	// re-running readiness. The hook only queues the domain continuation.
	first.process()
	TEST_ASSERT(first_service.cluster_queued, "Native server processing must detect a silent backbone setting change")
	TEST_ASSERT_NOTEQUAL(first.stored_research, second.stored_research, "The scalar-signature fallback must never merge synchronously inside machine processing")
	deadline = world.time + 5 SECONDS
	while(first.stored_research != second.stored_research && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(first.stored_research, second.stored_research, "Silent NTnet restoration must eventually unite reachable mapped authorities")

/datum/unit_test/netrun_research_prerequisite_chain/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	server.base_mining_income = list()
	server.stored_research.next_income = list()
	server.stored_research.research_points = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.source_spot)
	console.request_research_snapshot()
	var/deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache?.available_nodes["datatheory"], "The initial delivered console must offer Data Theory")
	TEST_ASSERT(console.research_node("datatheory", user), "The first research request must enter the wire")
	deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache?.researched_nodes["datatheory"] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache?.available_nodes["comptech"], "Researching Data Theory must make Computer Consoles actionable in the delivered UI")
	TEST_ASSERT_EQUAL(server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC], 8000, "The first research must debit exactly 2000 points")
	TEST_ASSERT(console.research_node("comptech", user), "The second research request must enter the wire")
	deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache?.researched_nodes["comptech"] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache?.researched_nodes["comptech"], "Computer Consoles must actually research through the network")
	TEST_ASSERT_EQUAL(server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC], 6000, "Both research operations must debit their own price once")

/// Servers sharing the default network selector must never replicate their memory.
/datum/unit_test/netrun_research_independent_servers/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	TEST_ASSERT(first.stored_research != second.stored_research, "Each physical server must own an independent authoritative techweb")
	first.stored_research.research_node_id("datatheory", TRUE, FALSE)
	TEST_ASSERT(!second.stored_research.researched_nodes["datatheory"], "Research on one server must not appear in another server")
	var/datum/techweb/old_web = first.stored_research
	qdel(first)
	TEST_ASSERT(QDELETED(old_web), "Destroying the physical owner must delete its authority")
	var/obj/machinery/rnd/server/replacement = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	TEST_ASSERT(!replacement.stored_research.researched_nodes["datatheory"], "A rebuilt server must start with baseline research")

/// Clients must lose access and cached presentation when the selected owner dies.
/datum/unit_test/netrun_research_owner_deleted/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	console.request_research_snapshot()
	var/deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache, "The console must receive a real snapshot before destruction")
	var/datum/techweb/old_web = server.stored_research
	qdel(server)
	TEST_ASSERT(QDELETED(old_web), "The destroyed server's data must not outlive the server")
	TEST_ASSERT(!netrun_atom_techweb(console) && !console.stored_research, "Destroying the server must clear both holder and native console binding")
	TEST_ASSERT(!console.netrun_research_cache, "The console must discard the destroyed server's presentation cache")
	TEST_ASSERT(!console.request_research_snapshot(), "A bound client must not silently recover the destroyed authority")

/// Redundancy is explicit; linked physical servers retain one authoritative pool.
/datum/unit_test/netrun_research_linked_servers/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	first.base_mining_income = list()
	second.base_mining_income = list()
	first.stored_research.research_points = list(TECHWEB_POINT_TYPE_GENERIC = 4000)
	second.stored_research.research_points = list(TECHWEB_POINT_TYPE_GENERIC = 3000)
	first.stored_research.next_income = list()
	second.stored_research.next_income = list()
	first.stored_research.research_node_id("datatheory", TRUE, FALSE)
	second.stored_research.add_design_by_id("mmi", TRUE)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, second.stored_research)
	var/datum/techweb/retired = second.stored_research
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, first.stored_research)
	TEST_ASSERT_EQUAL(second.stored_research, first.stored_research, "An explicit server binding must join the physical research pool")
	TEST_ASSERT(QDELETED(retired), "A merged authority must not retain an orphan database")
	var/datum/techweb/shared = first.stored_research
	TEST_ASSERT_EQUAL(length(shared.research_owner_refs), 2, "Only the two physical servers may own the research pool")
	TEST_ASSERT(shared.researched_nodes["datatheory"] && shared.researched_designs["mmi"], "Merging must preserve each server's existing technology and custom designs")
	TEST_ASSERT_EQUAL(shared.research_points[TECHWEB_POINT_TYPE_GENERIC], 7000, "Merging must preserve each independent balance once")
	TEST_ASSERT_EQUAL(console.stored_research, shared, "Clients of the merged server must be rebound to the surviving physical pool")
	TEST_ASSERT_EQUAL(netrun_atom_techweb(console), shared, "The native console and holder must agree after a merge")
	// Repeating the same explicit binding must not duplicate stored points.
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, shared)
	TEST_ASSERT_EQUAL(shared.research_points[TECHWEB_POINT_TYPE_GENERIC], 7000, "Repeating a cluster binding must not duplicate balances")
	console.request_research_snapshot()
	var/deadline = world.time + 5 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache, "The console must obtain a delivered snapshot from the shared physical servers")
	first.set_machine_stat(NOPOWER)
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	TEST_ASSERT_EQUAL(client.live_authority(), shared, "The second live physical server must authorize requests while the first is offline")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.source_spot)
	TEST_ASSERT(console.research_node("comptech", user), "A live backup must admit native console research")
	deadline = world.time + 5 SECONDS
	while(!shared.researched_nodes["comptech"] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(shared.researched_nodes["comptech"], "Native research must actually execute through the surviving live server")
	TEST_ASSERT_EQUAL(shared.research_points[TECHWEB_POINT_TYPE_GENERIC], 5000, "A clustered research request must debit exactly once")
	qdel(first)
	TEST_ASSERT(!QDELETED(shared), "Destroying one linked physical server must preserve redundant research")
	TEST_ASSERT_EQUAL(shared.research_owner_ref?.resolve(), second, "The remaining physical server must become the compatibility authority")
	TEST_ASSERT_EQUAL(console.stored_research, shared, "Deleting one owner must not revoke the surviving physical authority")
	qdel(second)
	TEST_ASSERT(QDELETED(shared), "Destroying the last physical server must destroy shared research")
	TEST_ASSERT(!console.stored_research && !netrun_atom_techweb(console) && !console.netrun_research_cache, "A client must not retain usable research after the last physical owner dies")
	for(var/key in SSresearch.rnd_networks)
		TEST_ASSERT(SSresearch.rnd_networks[key] != shared, "The global compatibility registry must not retain destroyed research")
	TEST_ASSERT(SSresearch.science_tech != shared, "The station alias must not retain destroyed research")

/// Restoring an old cluster owner cannot duplicate pushes or steal a reader back.
/datum/unit_test/netrun_research_failover_subscription/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, first.stored_research)
	first.base_mining_income = list()
	second.base_mining_income = list()
	first.stored_research.next_income = list()
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, first.stored_research)
	console.request_research_snapshot()
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	var/deadline = world.time + 5 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache, "Subscription failover needs a real initial snapshot")
	var/datum/netrun_machine_service/research_server/original = client.subscription_ref?.resolve()
	var/obj/machinery/rnd/server/original_host = original.host
	original_host.set_machine_stat(NOPOWER)
	TEST_ASSERT(client.request(), "The same authority must accept a new request through its surviving physical server")
	deadline = world.time + 5 SECONDS
	while(client.subscription_ref?.resolve() == original && world.time < deadline)
		sleep(world.tick_lag)
	var/datum/netrun_machine_service/research_server/current = client.subscription_ref?.resolve()
	TEST_ASSERT(current && current != original, "A delivered failover response must select the new subscription owner")
	original_host.set_machine_stat(0)
	original_host.working = TRUE
	var/list/designs_before = console.netrun_research_cache.researched_designs
	var/list/duplicate_data = original.snapshot()
	duplicate_data["generation"] = client.binding_generation
	var/datum/netrun_machine_message/research/duplicate = allocate(/datum/netrun_machine_message/research, duplicate_data)
	duplicate.source = original
	TEST_ASSERT(client.receive(duplicate), "An equal-revision delayed push may be acknowledged without rebuilding presentation")
	TEST_ASSERT_EQUAL(client.subscription_ref?.resolve(), current, "A delayed push from the restored owner must not steal the current subscription")
	TEST_ASSERT_EQUAL(console.netrun_research_cache.researched_designs, designs_before, "An equal-revision push must not copy recipes or refresh the native cache")
	// An equal-revision physical disk outcome is still a required transaction.
	console.t_disk = allocate(/obj/item/disk/tech_disk, console)
	first.stored_research.add_design_by_id("mmi", TRUE)
	var/list/disk_data = current.snapshot()
	disk_data["generation"] = client.binding_generation
	disk_data["requested_operation"] = "snapshot"
	var/datum/netrun_machine_message/research/updated = allocate(/datum/netrun_machine_message/research, disk_data)
	updated.source = current
	TEST_ASSERT(client.receive(updated), "The active owner must deliver the latest research state")
	disk_data["requested_operation"] = "download_disk"
	disk_data["disk"] = REF(console.t_disk)
	var/datum/netrun_machine_message/research/disk_result = allocate(/datum/netrun_machine_message/research, disk_data)
	disk_result.source = current
	TEST_ASSERT(client.receive(disk_result), "An equal-revision physical disk outcome must still be processed")
	TEST_ASSERT(console.t_disk.stored_research.researched_designs["mmi"], "Skipping duplicate telemetry must not discard disk writes")
	if(original.publish_timer)
		deltimer(original.publish_timer)
		original.publish_timer = null
	original.publish()
	original.publish_batch(SSnetrun)
	TEST_ASSERT(!original.subscribers[client.node.address], "The restored owner's next publication must prune a reader subscribed elsewhere")
	TEST_ASSERT(current.subscribers[client.node.address], "Pruning stale ownership must retain the active subscription")

/// A disabled owner must not produce points; both online linked servers contribute.
/datum/unit_test/netrun_research_linked_mining/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, first.stored_research)
	TEST_ASSERT_EQUAL(first.stored_research, second.stored_research, "The mining test must use two explicitly linked servers")
	var/datum/techweb/web = first.stored_research
	web.research_points = list()
	web.next_income = list()
	var/list/first_rate = first.mine()
	var/list/second_rate = second.mine()
	var/list/previous_servers = SSresearch.servers
	var/previous_last_income = SSresearch.last_income
	var/previous_multiserver = SSresearch.multiserver_calculation
	SSresearch.servers = list(first, second)
	SSresearch.multiserver_calculation = TRUE
	SSresearch.last_income = world.time - 1 SECONDS
	SSresearch.fire()
	var/combined = web.research_points[TECHWEB_POINT_TYPE_GENERIC]
	var/expected = (first_rate[TECHWEB_POINT_TYPE_GENERIC] + second_rate[TECHWEB_POINT_TYPE_GENERIC]) * SSresearch.calculate_server_coefficient(2)
	// Native set_machine_stat can leave working true; machine power still gates mining.
	first.set_machine_stat(NOPOWER)
	first.working = TRUE
	web.research_points = list()
	web.next_income = list()
	SSresearch.last_income = world.time - 1 SECONDS
	SSresearch.fire()
	var/offline = web.research_points[TECHWEB_POINT_TYPE_GENERIC]
	SSresearch.servers = previous_servers
	SSresearch.last_income = previous_last_income
	SSresearch.multiserver_calculation = previous_multiserver
	TEST_ASSERT_EQUAL(combined, expected, "Both linked servers must contribute their real mining rate once with the existing diminishing return")
	TEST_ASSERT_EQUAL(offline, second_rate[TECHWEB_POINT_TYPE_GENERIC] * SSresearch.calculate_server_coefficient(1), "An unpowered owner must contribute no points even if its working flag is stale")

/// Failed binding must not delete physical memory or accept a non-authoritative cache.
/datum/unit_test/netrun_research_cluster_binding_guard/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/first = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/second = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	var/datum/techweb/original = second.stored_research
	first.set_machine_stat(NOPOWER)
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, first.stored_research)
	TEST_ASSERT_EQUAL(second.stored_research, original, "A disconnected target cannot acquire another server's physical memory")
	var/datum/techweb/cache = allocate(/datum/techweb/netrun_snapshot)
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, cache)
	TEST_ASSERT_EQUAL(second.stored_research, original, "A disposable cache cannot become a physical research authority")
	SEND_SIGNAL(second, COMSIG_ATOM_SET_TECHWEB, null)
	TEST_ASSERT_EQUAL(second.stored_research, original, "Clearing a selector must not orphan the server's physical database")

/// An old reply cannot restore research after unbind/rebind to the same authority.
/datum/unit_test/netrun_research_stale_reply/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	console.request_research_snapshot()
	var/deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	var/datum/netrun_machine_service/research_server/service = server.get_netrun_machine_service("research.server")
	var/list/old_snapshot = service.snapshot()
	old_snapshot["generation"] = ("binding_generation" in client.vars) ? client.vars["binding_generation"] : 0
	var/datum/netrun_machine_message/research/stale = allocate(/datum/netrun_machine_message/research, old_snapshot)
	stale.source = service
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, null)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	TEST_ASSERT(!client.receive(stale), "A reply from before unbind/rebind must be rejected even when its authority matches")
	TEST_ASSERT(!console.netrun_research_cache, "Rejected old replies must not recreate presentation state")

/// A cached recipe must not spend resources when its physical server is offline.
/datum/unit_test/netrun_research_disconnected_fabrication/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/production/protolathe/lathe = scene.machine(/obj/machinery/rnd/production/protolathe, scene.source_spot)
	lathe.requires_console = FALSE
	SEND_SIGNAL(lathe, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	lathe.update_research()
	var/datum/netrun_machine_service/research_client/client = lathe.get_netrun_machine_service("research.client")
	var/deadline = world.time + 3 SECONDS
	while(client.snapshot_revision < 0 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(client.snapshot_revision >= 0, "The fabricator must receive cached recipes before the outage (server working=[server.working], stat=[server.machine_stat], binding=[netrun_atom_techweb(lathe) == server.stored_research], queued=[SSnetrun.get_machine_transport().queued_messages], queries=[length(client.resolutions)])")
	var/datum/design/design = SSresearch.techweb_design_by_id("micro_mani")
	var/datum/component/material_container/materials = lathe.materials.mat_container
	for(var/path in design.materials)
		materials.insert_amount_mat(design.materials[path] * 5, GET_MATERIAL_REF(path))
	var/before = materials.total_amount
	server.set_machine_stat(NOPOWER)
	TEST_ASSERT(!lathe.user_try_print_id("micro_mani", 1), "An offline authority must reject new cached fabrication")
	TEST_ASSERT_EQUAL(materials.total_amount, before, "Rejected fabrication must leave all materials intact")
	TEST_ASSERT(!lathe.busy, "Rejected fabrication must not start the machine")
	TEST_ASSERT(server.stored_research, "Power loss must retain the physical server's data")

/// A queued mechfab recipe also needs a fresh live-server authorization before spending.
/datum/unit_test/netrun_research_queued_fabrication_revoked/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.stored_research.add_design_by_id("mmi")
	var/obj/machinery/mecha_part_fabricator/fabricator = scene.machine(/obj/machinery/mecha_part_fabricator, scene.source_spot)
	SEND_SIGNAL(fabricator, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	fabricator.sync(TRUE, TRUE)
	var/datum/netrun_machine_service/research_client/client = fabricator.get_netrun_machine_service("research.client")
	var/deadline = world.time + 3 SECONDS
	while(client.snapshot_revision < 0 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(fabricator.stored_research.researched_designs["mmi"], "The queue test must start with a real delivered mechfab recipe")
	var/datum/design/design = SSresearch.techweb_design_by_id("mmi")
	var/datum/component/material_container/materials = fabricator.rmat.mat_container
	for(var/path in design.materials)
		materials.insert_amount_mat(design.materials[path] * 5, GET_MATERIAL_REF(path))
	var/before = materials.total_amount
	fabricator.queue += design
	server.set_machine_stat(NOPOWER)
	TEST_ASSERT(!fabricator.build_next_in_queue(), "A queued recipe must stop when its server loses power")
	TEST_ASSERT_EQUAL(length(fabricator.queue), 1, "A denied queued recipe must remain queued")
	TEST_ASSERT(!fabricator.being_built, "An offline queue must not start construction")
	TEST_ASSERT_EQUAL(materials.total_amount, before, "An offline queue must not consume materials")

/// Destruction between a design request and its response cannot start fabrication.
/datum/unit_test/netrun_research_pending_fabrication_deleted/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/production/protolathe/lathe = scene.machine(/obj/machinery/rnd/production/protolathe, scene.source_spot)
	lathe.requires_console = FALSE
	SEND_SIGNAL(lathe, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	lathe.update_research()
	var/datum/netrun_machine_service/research_client/client = lathe.get_netrun_machine_service("research.client")
	var/deadline = world.time + 3 SECONDS
	while(client.snapshot_revision < 0 && world.time < deadline)
		sleep(world.tick_lag)
	var/datum/design/design = SSresearch.techweb_design_by_id("micro_mani")
	var/datum/component/material_container/materials = lathe.materials.mat_container
	for(var/path in design.materials)
		materials.insert_amount_mat(design.materials[path] * 5, GET_MATERIAL_REF(path))
	var/before = materials.total_amount
	TEST_ASSERT(lathe.user_try_print_id("micro_mani", 1), "A reachable server must admit the initial design request")
	TEST_ASSERT_EQUAL(materials.total_amount, before, "Admitting a request must not consume materials before the server replies")
	qdel(server)
	sleep(1 SECONDS)
	TEST_ASSERT_EQUAL(materials.total_amount, before, "A deleted owner must revoke the pending print before resource consumption")
	TEST_ASSERT(!lathe.busy, "No pending print may start after its authority is destroyed")

/// An operating console may retain physical disk protocols but not disconnected server protocols.
/datum/unit_test/netrun_research_peripheral_revocation/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.stored_research.add_design_by_id("surgery_lobotomy")
	var/obj/machinery/computer/operating/console = scene.machine(/obj/machinery/computer/operating, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	console.sync_surgeries()
	var/deadline = world.time + 3 SECONDS
	while(!(/datum/surgery/advanced/lobotomy in console.advanced_surgeries) && world.time < deadline)
		console.sync_surgeries()
		sleep(world.tick_lag)
	TEST_ASSERT(/datum/surgery/advanced/lobotomy in console.advanced_surgeries, "An operating console must obtain a researched surgery through its server")
	server.set_machine_stat(NOPOWER)
	console.sync_surgeries()
	TEST_ASSERT(!(/datum/surgery/advanced/lobotomy in console.advanced_surgeries), "Server-provided surgical protocols must become unavailable while the authority is offline")

/// Only the external browser window is replaced: native refresh and transport stay real.
/datum/tgui/netrun_research_headless/process_status()
	status = UI_INTERACTIVE
	return FALSE

/datum/tgui/netrun_research_headless/send_update(custom_data, force)
	return

/// A packet-driven UI refresh must not generate another snapshot request forever.
/datum/unit_test/netrun_research_ui_refresh_drain/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	console.request_research_snapshot()
	var/deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache, "The drain test must begin after a real delivered research response")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.source_spot)
	var/datum/tgui/ui = allocate(/datum/tgui/netrun_research_headless, user, console, "Techweb")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/packets = length(transport.packets)
	var/queued = transport.queued_messages
	for(var/index in 1 to 20)
		console.ui_interact(user, ui)
	TEST_ASSERT_EQUAL(length(transport.packets), packets, "Refreshing an existing research UI must not create any new machine packets")
	TEST_ASSERT_EQUAL(transport.queued_messages, queued, "Refreshing an existing research UI must not queue new discovery work")

/datum/unit_test/netrun_research_ui_refresh_drain_mechfab/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/mecha_part_fabricator/fabricator = scene.machine(/obj/machinery/mecha_part_fabricator, scene.source_spot)
	SEND_SIGNAL(fabricator, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	fabricator.sync(TRUE, TRUE)
	var/datum/netrun_machine_service/research_client/client = fabricator.get_netrun_machine_service("research.client")
	var/deadline = world.time + 3 SECONDS
	while(client.snapshot_revision < 0 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(client.snapshot_revision >= 0, "The mechfab drain test needs a delivered research cache")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.source_spot)
	var/datum/tgui/ui = allocate(/datum/tgui/netrun_research_headless, user, fabricator, "ExosuitFabricator")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/packets = length(transport.packets)
	var/queued = transport.queued_messages
	for(var/index in 1 to 20)
		fabricator.ui_interact(user, ui)
	TEST_ASSERT_EQUAL(length(transport.packets), packets, "Refreshing an existing mechfab UI must not create any new machine packets")
	TEST_ASSERT_EQUAL(transport.queued_messages, queued, "A mechfab refresh must not queue discovery work")

/// A telemetry-only credit source must not receive a full research database or subscribe to pushes.
/datum/unit_test/netrun_research_credit_source_quiet/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/replica = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	SEND_SIGNAL(replica, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	server.base_mining_income = list()
	replica.base_mining_income = list()
	server.stored_research.research_points = list()
	server.stored_research.next_income = list()
	var/obj/machinery/power/tesla_coil/coil = scene.machine(/obj/machinery/power/tesla_coil, scene.source_spot)
	SEND_SIGNAL(coil, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	var/datum/netrun_machine_service/research_client/client = coil.get_netrun_machine_service("research.client")
	TEST_ASSERT(coil.netrun_research_request("credit", list("points" = list(TECHWEB_POINT_TYPE_GENERIC = 37))), "The real credit source must enter the research transport")
	var/deadline = world.time + 3 SECONDS
	while((server.stored_research.next_income[TECHWEB_POINT_TYPE_GENERIC] + server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC]) < 37 && world.time < deadline)
		sleep(world.tick_lag)
	sleep(0.5 SECONDS)
	TEST_ASSERT_EQUAL(server.stored_research.next_income[TECHWEB_POINT_TYPE_GENERIC] + server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC], 37, "Cold DNS discovery of two physical owners must credit the shared authority exactly once")
	TEST_ASSERT(!client.snapshot_cache, "A credit-only source must not download a complete research cache")
	var/datum/netrun_machine_service/research_server/service = server.get_netrun_machine_service("research.server")
	TEST_ASSERT(!service.subscribers[client.node.address], "A credit-only source must not subscribe to full database pushes")

/// A physical disk/action response is a transaction outcome, not replaceable telemetry.
/datum/unit_test/netrun_research_outcome_not_coalesced/Run()
	var/datum/netrun_machine_message/research/result = allocate(/datum/netrun_machine_message/research, list("operation" = "snapshot", "requested_operation" = "download_disk", "binding" = "test", "generation" = 1, "disk" = "physical disk"))
	TEST_ASSERT(!result.coalescing_key(), "Physical disk download responses must never be discarded as replaceable research state")

/// Exporting a new physical blueprint needs the live server, just like starting fabrication.
/datum/unit_test/netrun_research_offline_blueprint_export/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	console.request_research_snapshot()
	var/deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache?.researched_designs["micro_mani"], "The export test needs a delivered recipe before the outage")
	console.d_disk = allocate(/obj/item/disk/design_disk, console)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.source_spot)
	var/datum/tgui/ui = allocate(/datum/tgui/netrun_research_headless, user, console, "Techweb")
	ui.status = UI_INTERACTIVE
	server.set_machine_stat(NOPOWER)
	usr = user
	console.ui_act("writeDesign", list("slot" = "1", "selectedDesign" = "micro_mani"), ui)
	usr = null
	TEST_ASSERT(!console.d_disk.blueprints[1], "An offline server must not export a cached recipe onto a physical disk")

/// The asynchronous grant must start a legitimate build exactly once, not merely reject outages.
/datum/unit_test/netrun_research_connected_fabrication/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/production/protolathe/lathe = scene.machine(/obj/machinery/rnd/production/protolathe, scene.source_spot)
	lathe.requires_console = FALSE
	SEND_SIGNAL(lathe, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	lathe.update_research()
	var/datum/netrun_machine_service/research_client/client = lathe.get_netrun_machine_service("research.client")
	var/deadline = world.time + 3 SECONDS
	while(client.snapshot_revision < 0 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(client.snapshot_revision >= 0, "The connected print must begin with a real delivered recipe cache")
	var/datum/component/material_container/materials = lathe.materials.mat_container
	materials.insert_amount_mat(500, GET_MATERIAL_REF(/datum/material/iron))
	var/expected_cost = 100 * lathe.print_cost_coeff
	var/before = materials.total_amount
	TEST_ASSERT(lathe.user_try_print_id("micro_mani", 1), "A connected server must admit the legitimate fabrication request")
	TEST_ASSERT_EQUAL(materials.total_amount, before, "The client must wait for the actual design reply before spending")
	deadline = world.time + 3 SECONDS
	while(materials.total_amount == before && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(materials.total_amount, before - expected_cost, "A delivered grant must consume exactly one recipe's material cost")
	sleep(0.5 SECONDS)
	TEST_ASSERT_EQUAL(materials.total_amount, before - expected_cost, "Late/duplicate state updates must not print the granted item twice")

/// The native mechfab sync path cannot silently select another server after owner loss.
/datum/unit_test/netrun_research_mechfab_no_silent_failover/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/original = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/server/other = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	var/obj/machinery/mecha_part_fabricator/fabricator = scene.machine(/obj/machinery/mecha_part_fabricator, scene.source_spot)
	SEND_SIGNAL(fabricator, COMSIG_ATOM_SET_TECHWEB, original.stored_research)
	qdel(original)
	fabricator.sync(TRUE, TRUE)
	TEST_ASSERT(!netrun_atom_techweb(fabricator), "A lost owner must leave the mechfab disconnected until an explicit authority binding")
	TEST_ASSERT(other.stored_research, "The regression needs another reachable live server that must not be selected silently")

/// Empty income and re-adding an existing recipe cannot manufacture changed revisions forever.
/datum/unit_test/netrun_research_noop_publication/Run()
	var/datum/techweb/web = allocate(/datum/techweb)
	var/revision = web.netrun_research_revision
	web.add_point_list(list(), FALSE)
	TEST_ASSERT_EQUAL(web.netrun_research_revision, revision, "Empty income must not publish a changed research database")
	web.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = 0), FALSE)
	TEST_ASSERT_EQUAL(web.netrun_research_revision, revision, "Zero income must not publish a changed research database")
	web.add_design_by_id("micro_mani")
	TEST_ASSERT_EQUAL(web.netrun_research_revision, revision, "Re-adding a known starting recipe must not trigger database replication")

/// A large subscriber population must update in bounded common-worker slices and drain.
/datum/unit_test/netrun_research_fanout_drain/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.base_mining_income = list()
	server.stored_research.next_income = list()
	var/list/clients = list()
	for(var/index in 1 to 64)
		var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
		SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
		console.request_research_snapshot()
		clients += console.get_netrun_machine_service("research.client")
	var/deadline = world.time + 10 SECONDS
	var/ready = 0
	while(world.time < deadline)
		ready = 0
		for(var/datum/netrun_machine_service/research_client/client as anything in clients)
			if(client.snapshot_revision >= 0)
				ready++
		if(ready == length(clients))
			break
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(ready, 64, "All 64 real consoles must receive their first database through DNS and the transport")
	var/datum/netrun_machine_service/research_server/service = server.get_netrun_machine_service("research.server")
	TEST_ASSERT_EQUAL(length(service.subscribers), 64, "All real readers must hold a subscription before publication load begins")
	// Stop producers, then measure the finite publication and its real delivery queue.
	server.stored_research.add_point_type(TECHWEB_POINT_TYPE_GENERIC, 9, FALSE)
	var/revision = server.stored_research.netrun_research_revision
	if(service.publish_timer)
		deltimer(service.publish_timer)
		service.publish_timer = null
	var/started = REALTIMEOFDAY
	service.publish()
	TEST_ASSERT(service.publish_addresses && !service.publish_data, "The timer must enqueue publication without building or broadcasting the database")
	TEST_ASSERT(!service.publish_batch(SSnetrun), "One worker slice cannot finish a 64-reader publication")
	TEST_ASSERT_EQUAL(service.publish_cursor, 2, "One publication slice must visit at most one reader")
	var/pending = 0
	for(var/datum/netrun_machine_packet/packet as anything in SSnetrun.get_machine_transport().packets)
		if(packet.source == service)
			pending++
	TEST_ASSERT(pending <= 1, "The first slice must admit at most one research packet")
	deadline = world.time + 10 SECONDS
	while(world.time < deadline)
		ready = 0
		for(var/datum/netrun_machine_service/research_client/client as anything in clients)
			if(client.snapshot_revision == revision)
				ready++
		pending = 0
		for(var/datum/netrun_machine_packet/packet as anything in SSnetrun.get_machine_transport().packets)
			if(packet.source == service)
				pending++
		if(ready == length(clients) && !pending && !service.publish_addresses)
			break
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(ready, 64, "All 64 clients must receive the latest authoritative state")
	TEST_ASSERT_EQUAL(pending, 0, "The research publication's actual transport queue must drain after producers stop")
	TEST_ASSERT(!service.publish_addresses && !service.publish_data, "Completed publication must release its subscriber list and snapshot")
	TEST_ASSERT(!SSnetrun.get_task_scheduler().by_key["research.publish:[REF(service)]"], "Completed publication must release its common scheduler continuation")
	log_world("PERF: research fanout peers=64 batch=1 latest=[ready] pending=[pending] elapsed=[(REALTIMEOFDAY - started) * 100]ms")

/// Ordinary income changes balances without retransmitting or rebuilding recipes.
/datum/unit_test/netrun_research_compact_publication/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.base_mining_income = list()
	server.stored_research.next_income = list()
	var/obj/machinery/rnd/production/protolathe/lathe = scene.machine(/obj/machinery/rnd/production/protolathe, scene.source_spot)
	var/obj/machinery/mecha_part_fabricator/fabricator = scene.machine(/obj/machinery/mecha_part_fabricator, scene.source_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	var/list/clients = list()
	for(var/atom/host as anything in list(lathe, fabricator, console))
		SEND_SIGNAL(host, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
		var/datum/netrun_machine_service/research_client/client = host.get_netrun_machine_service("research.client")
		client.request()
		clients += client
	var/deadline = world.time + 5 SECONDS
	var/ready = 0
	while(world.time < deadline)
		ready = 0
		for(var/datum/netrun_machine_service/research_client/client as anything in clients)
			ready += client.snapshot_revision >= 0
		if(ready == length(clients))
			break
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(ready, 3, "Every native consumer must receive a real initial catalogue")
	var/list/lathe_designs = lathe.stored_research.researched_designs
	var/list/fabricator_designs = fabricator.stored_research.researched_designs
	var/list/console_designs = console.netrun_research_cache.researched_designs
	var/list/lathe_categories = lathe._ui_cached_designs.Copy()
	var/catalog_revision = server.stored_research.netrun_research_catalog_revision
	server.stored_research.add_point_type(TECHWEB_POINT_TYPE_GENERIC, 17, FALSE)
	TEST_ASSERT_EQUAL(server.stored_research.netrun_research_catalog_revision, catalog_revision, "Income must not invalidate the catalogue")
	var/datum/netrun_machine_service/research_server/service = server.get_netrun_machine_service("research.server")
	if(service.publish_timer)
		deltimer(service.publish_timer)
		service.publish_timer = null
	service.publish()
	while(service.publish_addresses)
		service.publish_batch(SSnetrun)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/delivered = 0
	for(var/datum/netrun_machine_packet/data/packet as anything in transport.packets.Copy())
		if(packet.source != service || !(packet.recipient in clients))
			continue
		TEST_ASSERT_EQUAL(packet.message.payload["operation"], "state", "Income fanout must use compact balance packets")
		TEST_ASSERT(!("researched_designs" in packet.message.payload) && !("researched_nodes" in packet.message.payload), "Balance packets must carry no recipe or node sets")
		packet.deliver()
		delivered++
	TEST_ASSERT_EQUAL(delivered, 3, "Every subscription must receive the new balance")
	for(var/datum/netrun_machine_service/research_client/client as anything in clients)
		TEST_ASSERT_EQUAL(client.snapshot_revision, server.stored_research.netrun_research_revision, "Compact delivery must advance the accepted revision")
	TEST_ASSERT_EQUAL(lathe.stored_research.researched_designs, lathe_designs, "Income must retain the lathe's recipe list")
	TEST_ASSERT_EQUAL(fabricator.stored_research.researched_designs, fabricator_designs, "Income must retain the mechfab's filtered recipe list")
	TEST_ASSERT_EQUAL(console.netrun_research_cache.researched_designs, console_designs, "Income must retain the console's catalogue")
	TEST_ASSERT(length(lathe_categories), "The lathe must have an initial static recipe presentation")
	TEST_ASSERT_EQUAL(lathe._ui_cached_designs[1], lathe_categories[1], "Income must retain the lathe's static presentation records")
	TEST_ASSERT_EQUAL(console.netrun_research_cache.research_points[TECHWEB_POINT_TYPE_GENERIC], server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC], "The visible balance must still update")
	TEST_ASSERT_NOTEQUAL(console.netrun_research_cache.research_points, server.stored_research.research_points, "A compact packet must not alias authoritative balances")
	var/list/full_data = service.snapshot()
	log_world("PERF: research balance full_chars=[length(json_encode(full_data))] state_chars=[length(json_encode(service.snapshot_state(full_data)))] peers=[delivered]")
	server.stored_research.add_design_by_id("mmi", TRUE)
	TEST_ASSERT(server.stored_research.netrun_research_catalog_revision > catalog_revision, "A new recipe must invalidate the catalogue")
	if(service.publish_timer)
		deltimer(service.publish_timer)
		service.publish_timer = null
	service.publish()
	while(service.publish_addresses)
		service.publish_batch(SSnetrun)
	delivered = 0
	for(var/datum/netrun_machine_packet/data/packet as anything in transport.packets.Copy())
		if(packet.source != service || !(packet.recipient in clients))
			continue
		TEST_ASSERT_EQUAL(packet.message.payload["operation"], "snapshot", "Structural changes must still carry the full catalogue")
		packet.deliver()
		delivered++
	TEST_ASSERT_EQUAL(delivered, 3, "Every subscriber must receive changed recipes")
	TEST_ASSERT(console.netrun_research_cache.researched_designs["mmi"], "Full delivery must apply the new design")
	TEST_ASSERT_NOTEQUAL(console.netrun_research_cache.researched_designs, console_designs, "A changed catalogue must replace the old recipe snapshot")

/// Out-of-order publication cannot discard newer replaceable research state,
/// either before service discovery or after admission to the physical transport.
/datum/unit_test/netrun_research_snapshot_coalescing_revision/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	for(var/operation in list("snapshot", "state"))
		var/list/data = list("operation" = operation, "binding" = "revision-fixture", "generation" = 1, "revision" = 12)
		var/queued_before = transport.queued_messages
		var/datum/netrun_machine_resolution/query = allocate(/datum/netrun_machine_resolution, scene.source, "transport.fixture", scene.target.service_tag())
		var/datum/netrun_machine_message/research/newer = new(data)
		TEST_ASSERT(query.enqueue(newer), "Discovery must admit the current research revision")
		data["revision"] = 11
		var/datum/netrun_machine_message/research/older = new(data)
		TEST_ASSERT(query.enqueue(older), "Superseded research state may be acknowledged without another delivery")
		TEST_ASSERT(QDELETED(older) && query.queued[1] == newer, "Older discovery state must not discard the newer admitted revision")
		TEST_ASSERT_EQUAL(transport.queued_messages, queued_before + 1, "Discarding stale state must not consume or release another message slot")
		data["revision"] = 13
		var/datum/netrun_machine_message/research/latest = new(data)
		query.enqueue(latest)
		TEST_ASSERT(QDELETED(newer) && query.queued[1] == latest, "A newer revision must still replace older queued telemetry")
		var/datum/netrun_machine_message/research/equal_revision = new(data)
		query.enqueue(equal_revision)
		TEST_ASSERT(QDELETED(latest) && query.queued[1] == equal_revision, "An equal revision must preserve ordinary latest-payload replacement")
		var/list/action_data = data.Copy()
		action_data["requested_operation"] = "download_disk"
		query.enqueue(new /datum/netrun_machine_message/research(action_data))
		action_data["revision"] = 1
		query.enqueue(new /datum/netrun_machine_message/research(action_data))
		TEST_ASSERT_EQUAL(length(query.queued), 3, "Version ordering must not coalesce or discard explicit action outcomes")
		qdel(query)
		TEST_ASSERT_EQUAL(transport.queued_messages, queued_before, "Resolution teardown must release all still-owned telemetry and action slots")
		data["revision"] = 12
		newer = new(data)
		TEST_ASSERT(scene.source.send_to(scene.target, newer), "The current wire revision must acquire a real route")
		var/datum/netrun_machine_packet/data/retained
		for(var/datum/netrun_machine_packet/data/packet as anything in transport.packets)
			if(packet.message == newer)
				retained = packet
		TEST_ASSERT_NOTNULL(retained, "The replacement test needs a live admitted data packet")
		data["revision"] = 11
		older = new(data)
		TEST_ASSERT(scene.source.send_to(scene.target, older), "Superseded wire state must not report a delivery failure")
		TEST_ASSERT(QDELETED(older) && retained.message == newer, "An older wire revision must not replace newer in-flight telemetry")
		data["revision"] = 13
		latest = new(data)
		scene.source.send_to(scene.target, latest)
		TEST_ASSERT(QDELETED(newer) && retained.message == latest, "A newer wire revision must reuse the same admitted packet")
		equal_revision = new(data)
		scene.source.send_to(scene.target, equal_revision)
		TEST_ASSERT(QDELETED(latest) && retained.message == equal_revision, "Equal wire revisions must retain the existing replaceable-state behavior")
		qdel(retained)

/// A partial update must not supersede a missing full catalogue or roll state back.
/datum/unit_test/netrun_research_compact_catalogue_recovery/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.base_mining_income = list()
	server.stored_research.next_income = list()
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	client.request()
	var/deadline = world.time + 5 SECONDS
	while(client.snapshot_revision < 0 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(client.snapshot_revision >= 0, "Recovery needs a delivered initial catalogue")
	var/accepted_revision = client.snapshot_revision
	var/datum/netrun_machine_service/research_server/service = server.get_netrun_machine_service("research.server")
	server.stored_research.add_design_by_id("mmi", TRUE)
	var/list/full = service.snapshot()
	full["generation"] = client.binding_generation
	TEST_ASSERT(service.send_to(client, new /datum/netrun_machine_message/research(full)), "Admit an undelivered catalogue update")
	server.stored_research.add_point_type(TECHWEB_POINT_TYPE_GENERIC, 23, FALSE)
	var/list/state = service.snapshot_state(service.snapshot())
	state["generation"] = client.binding_generation
	TEST_ASSERT(service.send_to(client, new /datum/netrun_machine_message/research(state)), "Admit the following balance update")
	var/datum/netrun_machine_packet/data/catalogue_packet
	var/datum/netrun_machine_packet/data/state_packet
	for(var/datum/netrun_machine_packet/data/packet as anything in SSnetrun.get_machine_transport().packets)
		if(packet.source != service || packet.recipient != client)
			continue
		if(packet.message.payload["operation"] == "snapshot")
			catalogue_packet = packet
		else if(packet.message.payload["operation"] == "state")
			state_packet = packet
	TEST_ASSERT(catalogue_packet && state_packet, "Compact coalescing must retain a full catalogue still in flight")
	state_packet.deliver()
	TEST_ASSERT_EQUAL(client.snapshot_revision, accepted_revision, "An unknown catalogue revision cannot advance accepted state")
	TEST_ASSERT(length(client.resolutions), "The rejected partial update must request an ordinary full repair")
	// Simulate loss of the full packet; the newly requested copy must repair it.
	qdel(catalogue_packet)
	deadline = world.time + 5 SECONDS
	while(client.snapshot_revision < server.stored_research.netrun_research_revision && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(client.snapshot_revision, server.stored_research.netrun_research_revision, "A lost catalogue must recover through actual discovery and delivery")
	TEST_ASSERT(console.netrun_research_cache.researched_designs["mmi"], "Repair must supply the missing recipe")
	var/list/designs = console.netrun_research_cache.researched_designs
	state["revision"] = accepted_revision
	var/datum/netrun_machine_message/research/stale = allocate(/datum/netrun_machine_message/research, state)
	stale.source = service
	TEST_ASSERT(client.receive(stale), "Stale state may be acknowledged without applying it")
	TEST_ASSERT_EQUAL(client.snapshot_revision, server.stored_research.netrun_research_revision, "Stale state must not roll back the revision")
	TEST_ASSERT_EQUAL(console.netrun_research_cache.researched_designs, designs, "Stale state must not touch the repaired catalogue")

/// Archaeology sends a real tool request; the artifact is consumed only by the receiving authority.
/datum/unit_test/netrun_research_artifact_request/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	server.base_mining_income = list()
	server.stored_research.research_points = list()
	server.stored_research.next_income = list()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.source_spot)
	var/obj/item/xenoarch/help/research/tool = allocate(/obj/item/xenoarch/help/research, user)
	var/obj/item/ancientartifact/useless/artifact = allocate(/obj/item/ancientartifact/useless, scene.source_spot)
	SEND_SIGNAL(tool, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	TEST_ASSERT(tool.netrun_research_request("artifact", list("artifact" = REF(artifact), "points" = 999999), user), "A real archaeology tool must submit its research to the selected physical server")
	TEST_ASSERT(tool.netrun_research_request("artifact", list("artifact" = REF(artifact)), user), "A duplicate in-flight request must still leave artifact identity verification to the server")
	TEST_ASSERT(!QDELETED(artifact), "Admitting the request must not consume the artifact before delivery")
	var/deadline = world.time + 3 SECONDS
	while(!QDELETED(artifact) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(QDELETED(artifact), "The delivered request must consume the researched artifact once")
	sleep(0.5 SECONDS)
	TEST_ASSERT_EQUAL(server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC] + server.stored_research.next_income[TECHWEB_POINT_TYPE_GENERIC], 4500, "The server must award the actual artifact's 4500 points exactly once")

/// Direct, addressed research discovery must not require a populated DNS cache.
/datum/unit_test/netrun_research_direct_route_without_dns_cache/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, server.stored_research)
	server.base_mining_income = list()
	server.stored_research.research_points = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	console.request_research_snapshot()
	var/deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache, "The addressed server must deliver a snapshot")
	TEST_ASSERT(!length(SSnetrun.get_machine_transport().by_id["dns"]), "The physical authority must work without a DNS service")
	TEST_ASSERT_EQUAL(client.live_authority(), server.stored_research, "A physical owner must authorize research without a DNS directory entry")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.source_spot)
	TEST_ASSERT(console.research_node("datatheory", user), "An addressed research mutation must enter the network without DNS")
	deadline = world.time + 3 SECONDS
	while(!server.stored_research.researched_nodes["datatheory"] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(server.stored_research.researched_nodes["datatheory"], "Research must complete after direct discovery")

/// A stolen balance can be transferred once, even after copying the data file.
/datum/unit_test/netrun_research_siphon_redeem_once/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/source = scene.machine(/obj/machinery/rnd/server, scene.source_spot)
	var/obj/machinery/rnd/server/destination = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	source.stored_research = allocate(/datum/techweb)
	destination.stored_research = allocate(/datum/techweb)
	source.stored_research.research_points = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
	destination.stored_research.research_points = list(TECHWEB_POINT_TYPE_GENERIC = 100)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, allocate(/obj/item))
	var/datum/netrun_command/siphon = SSnetrun.get_command("rnd_siphon")
	var/datum/netrun_command/restore = SSnetrun.get_command("rnd_restore")
	var/datum/component/netrun_node/source_node = netrun_find_node(source)
	var/datum/component/netrun_node/destination_node = netrun_find_node(destination)
	console.inventory.local_store.capacity = 0
	siphon.execute(source_node, console)
	TEST_ASSERT_EQUAL(source.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC], 10000, "A full disk cannot debit the research authority")
	console.inventory.local_store.capacity = 16
	siphon.execute(source_node, console)
	TEST_ASSERT_EQUAL(source.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC], 7500, "The actual stolen balance is removed once")
	var/datum/netrun_file/research_points/original = console.selected_local_file()
	TEST_ASSERT(istype(original), "Siphon produces a transferable redeemable report")
	var/datum/netrun_file/research_points/copy = original.copy()
	TEST_ASSERT_EQUAL(copy.payload, original.payload, "Copies share their authoritative consumable balance")
	TEST_ASSERT(console.store_file(copy), "The copied report uses ordinary storage")
	console.inventory.selected_file_uid = copy.uid
	var/datum/techweb/authority = destination.stored_research
	destination.stored_research = null
	restore.execute(destination_node, console)
	TEST_ASSERT(length(original.payload.points), "A missing destination does not consume the portable balance")
	destination.stored_research = authority
	restore.execute(destination_node, console)
	TEST_ASSERT_EQUAL(authority.research_points[TECHWEB_POINT_TYPE_GENERIC], 2600, "The destination receives the stolen points exactly once")
	console.inventory.selected_file_uid = original.uid
	restore.execute(destination_node, console)
	TEST_ASSERT_EQUAL(authority.research_points[TECHWEB_POINT_TYPE_GENERIC], 2600, "The original cannot redeem a balance already used by a copy")
	var/datum/netrun_file/research_points/later_copy = original.copy()
	TEST_ASSERT(console.store_file(later_copy), "A spent report remains an ordinary copyable file")
	console.inventory.selected_file_uid = later_copy.uid
	restore.execute(destination_node, console)
	TEST_ASSERT_EQUAL(authority.research_points[TECHWEB_POINT_TYPE_GENERIC], 2600, "Copying after redemption cannot revive the balance")
	var/datum/netrun_file/forged = new("rnd_fake.dat", NETRUN_FILE_TEXT, original.content, 2)
	TEST_ASSERT(console.store_file(forged), "A forged text report can exist as ordinary data")
	console.inventory.selected_file_uid = forged.uid
	restore.execute(destination_node, console)
	TEST_ASSERT_EQUAL(authority.research_points[TECHWEB_POINT_TYPE_GENERIC], 2600, "Text content and a .dat name cannot mint research points")
