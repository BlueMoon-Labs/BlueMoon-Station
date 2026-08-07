/// Admin-triggered SSair performance recorder. Writes one JSON object per line
/// (JSONL) so a crashed or restarted round still leaves every sample on disk.
/// Cheap by design: the per-second sample only reads existing SSair counters;
/// the heavier world-walking breakdowns run every ATMOS_BENCH_DEEP_INTERVAL
/// under CHECK_TICK so the benchmark does not distort what it measures.
/// Testing-only tooling: TGS production builds compile without it.
#ifndef TGS

#define ATMOS_BENCH_SAMPLE_INTERVAL (1 SECONDS)
#define ATMOS_BENCH_DEEP_INTERVAL (30 SECONDS)
#define ATMOS_BENCH_TOP_AREAS 12
#define ATMOS_BENCH_TOP_TYPES 25
/// Most active turfs the per-second z histogram may read; larger lists are stride-sampled.
#define ATMOS_BENCH_Z_HOT_BUDGET 2000
/// Active-turf count past which the per-second z histogram is recorded at all.
#define ATMOS_BENCH_Z_HOT_THRESHOLD 500

GLOBAL_DATUM(atmos_benchmark_run, /datum/atmos_benchmark)
GLOBAL_PROTECT(atmos_benchmark_run)

/datum/admins/proc/atmos_benchmark()
	set category = "Debug.3) Fixing"
	set desc = "Records SSair performance metrics to a JSONL file for offline analysis."
	set name = "Atmos Benchmark"

	var/datum/atmos_benchmark/current = GLOB.atmos_benchmark_run
	if(current)
		var/remaining_minutes = round((current.end_at - world.time) / (1 MINUTES), 0.1)
		var/choice = alert(usr, "Бенчмарк уже идёт: [current.sample_count] сэмплов, осталось ~[remaining_minutes] мин.\nФайл: [current.file_path]", "Atmos Benchmark", "Продолжить", "Остановить и сохранить")
		if(choice == "Остановить и сохранить" && GLOB.atmos_benchmark_run == current)
			current.finish("stopped early by [key_name(usr)]")
		return

	var/minutes = input(usr, "Длительность бенчмарка в минутах", "Atmos Benchmark", 10) as null|num
	if(!minutes)
		return
	minutes = clamp(minutes, 1, 120)
	if(GLOB.atmos_benchmark_run) // someone else started one while we sat in input()
		to_chat(usr, span_warning("Бенчмарк уже запущен: [GLOB.atmos_benchmark_run.file_path]"))
		return
	var/datum/atmos_benchmark/bench = new(minutes MINUTES)
	GLOB.atmos_benchmark_run = bench
	bench.start()
	message_admins("Атмос-бенчмарк запущен [key_name_admin(usr)] на [minutes] мин. Файл: [bench.file_path]")
	log_admin("[key_name(usr)] started atmos benchmark for [minutes] minutes -> [bench.file_path]")

/datum/atmos_benchmark
	var/file_path
	var/duration
	var/started_at
	var/end_at
	var/sample_timer_id
	var/deep_timer_id
	var/sample_count = 0
	var/fires_at_start = 0
	var/finished = FALSE
	/// Running totals/high-water marks for the end-of-run summary, keyed by sample field.
	var/list/agg_sum = list()
	var/list/agg_max = list()
	/// Sample fields worth averaging in the summary record.
	var/static/list/summary_fields = list(
		"cost", "tu", "tks",
		"c_rb", "c_pn", "c_am", "c_at", "c_at_raw", "c_ao", "c_eq", "c_eg", "c_pp", "c_hp", "c_hs", "c_sc",
		"at", "eg", "hs", "hpd", "gm", "egt", "eqn",
		"td_c", "td_f", "cpu", "mcpu",
	)
	/// Human names for the phase cost fields, for the end-of-run admin digest.
	var/static/list/phase_names = list(
		"c_rb" = "rebuilds",
		"c_pn" = "pipenets",
		"c_am" = "machinery",
		"c_at" = "active turfs",
		"c_ao" = "atmos-sensitive atoms",
		"c_eq" = "equalize",
		"c_eg" = "excited groups",
		"c_pp" = "post process",
		"c_hp" = "high pressure",
		"c_hs" = "hotspots",
		"c_sc" = "superconduction",
	)

/datum/atmos_benchmark/New(duration)
	src.duration = duration
	file_path = "data/atmos_benchmark_[time2text(world.realtime, "YYYY-MM-DD_hh.mm.ss")].jsonl"

/datum/atmos_benchmark/Destroy()
	deltimer(sample_timer_id)
	deltimer(deep_timer_id)
	if(GLOB.atmos_benchmark_run == src)
		GLOB.atmos_benchmark_run = null
	return ..()

/datum/atmos_benchmark/proc/start()
	started_at = world.time
	end_at = world.time + duration
	fires_at_start = SSair.times_fired
	write_header()
	INVOKE_ASYNC(src, PROC_REF(write_static_census))
	sample_timer_id = addtimer(CALLBACK(src, PROC_REF(sample)), ATMOS_BENCH_SAMPLE_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)
	deep_timer_id = addtimer(CALLBACK(src, PROC_REF(deep_sample)), ATMOS_BENCH_DEEP_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)

/datum/atmos_benchmark/proc/write_record(list/record)
	rustg_file_append("[json_encode(record)]\n", file_path)

/datum/atmos_benchmark/proc/write_header()
	write_record(list(
		"rec" = "header",
		"version" = 1,
		"started" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"),
		"t" = world.time,
		"round_id" = GLOB.round_id,
		"map" = SSmapping.config?.map_name,
		"maxz" = world.maxz,
		"players" = length(GLOB.clients),
		"duration_ds" = duration,
		"sample_interval_ds" = ATMOS_BENCH_SAMPLE_INTERVAL,
		"deep_interval_ds" = ATMOS_BENCH_DEEP_INTERVAL,
		"ssair_wait" = SSair.wait,
		"equalize_enabled" = SSair.equalize_enabled,
		"heat_enabled" = SSair.heat_enabled,
		"atmos_speed" = SSair.atmos_speed,
		"atmos_speed_multiplier" = CONFIG_GET(number/atmos_speed_multiplier),
		"byond" = "[world.byond_version].[world.byond_build]",
		"active_turfs_now" = length(SSair.active_turfs),
		"doc" = list(
			"s" = "per-second sample; all c_* costs are MC_AVERAGE-smoothed ms per SSair fire",
			"t" = "world.time, deciseconds",
			"fired" = "SSair.times_fired",
			"state" = "subsystem state enum (1 idle, 2 queued, 3 running, 4 paused)",
			"cost" = "SSair rolling avg cost ms",
			"tu" = "SSair rolling avg % of tick used",
			"tks" = "avg MC ticks SSair needs to finish one run (backlog indicator)",
			"c_rb" = "pipenet rebuild queue ms",
			"c_pn" = "pipenet processing ms",
			"c_am" = "atmos machinery ms",
			"c_at" = "active turf share/react ms",
			"c_at_raw" = "same phase, unsmoothed: cost of the single last fire, so spike amplitude survives",
			"c_ao" = "opt-in atmos-sensitive atom processing ms",
			"c_eq" = "equalize (zone pressure) ms",
			"c_eg" = "excited group processing ms",
			"c_pp" = "turf sleep-check post process ms",
			"c_hp" = "high pressure delta movement ms",
			"c_hs" = "hotspot (fire) ms",
			"c_sc" = "turf superconduction ms",
			"at" = "active turfs",
			"ao" = "opt-in atmos-sensitive atoms",
			"eg" = "excited groups",
			"hs" = "hotspots",
			"pn" = "pipenets",
			"am" = "processing (awake) atmos machines",
			"ami" = "sleeping atmos machines waiting in the idle heartbeat queue",
			"hpd" = "turfs the high pressure phase moved things on last fire (the queue itself is drained by then)",
			"rbq" = "pipenets awaiting rebuild",
			"gm" = "alive gas mixtures",
			"gma" = "gas mixture high-water mark",
			"egt" = "turfs inside excited groups processed last fire",
			"eqn" = "turfs equalized last fire",
			"hpt" = "equalized turfs above 1 atm",
			"lpt" = "equalized turfs below 1 atm",
			"td_c" = "time dilation current %",
			"td_f" = "time dilation avg fast %",
			"td_a" = "time dilation avg %",
			"cpu" = "world.cpu",
			"mcpu" = "world.map_cpu",
			"cl" = "connected clients",
			"wt" = "SSair.wait now in deciseconds (> header ssair_wait means the lag valve slowed the cadence, < means the speed lever is up)",
			"adjq" = "SSadjacent_air queue length",
			"hbw" = "machines the idle heartbeat returned for a recheck on the last machinery pass (rotation share of c_am)",
			"pnu" = "pipenets flagged dirty (update=TRUE) at sample time - they reconcile next fire",
			"z_hot" = "z histogram of active turfs, recorded only when the active list exceeds [ATMOS_BENCH_Z_HOT_THRESHOLD]; stride-sampled and rescaled above [ATMOS_BENCH_Z_HOT_BUDGET] turfs",
			"mprof" = "separate record type: one fully-timed machinery pass per deep interval, per-type n/ms buckets plus powered state (np) and heartbeat wakes (hbw)",
		),
	))

/datum/atmos_benchmark/proc/sample()
	if(finished)
		return
	if(world.time >= end_at)
		finish("completed")
		return
	var/datum/controller/subsystem/air/air = SSair
	var/list/record = list(
		"rec" = "s",
		"t" = world.time,
		"fired" = air.times_fired,
		"state" = air.state,
		"cost" = round(air.cost, 0.01),
		"tu" = round(air.tick_usage, 0.01),
		"tks" = round(air.ticks, 0.01),
		"c_rb" = round(air.cost_rebuilds, 0.01),
		"c_pn" = round(air.cost_pipenets, 0.01),
		"c_am" = round(air.cost_atmos_machinery, 0.01),
		"c_at" = round(air.cost_turfs, 0.01),
		"c_at_raw" = round(air.cost_turfs_last, 0.01),
		"c_ao" = round(air.cost_atmos_atoms, 0.01),
		"c_eq" = round(air.cost_equalize, 0.01),
		"c_eg" = round(air.cost_groups, 0.01),
		"c_pp" = round(air.cost_post_process, 0.01),
		"c_hp" = round(air.cost_highpressure, 0.01),
		"c_hs" = round(air.cost_hotspots, 0.01),
		"c_sc" = round(air.cost_superconductivity, 0.01),
		"at" = length(air.active_turfs),
		"ao" = length(air.atom_process),
		"eg" = length(air.excited_groups),
		"hs" = length(air.hotspots),
		"pn" = length(air.networks),
		"am" = length(air.atmos_machinery),
		"ami" = air.idle_machine_count(),
		"hpd" = air.high_pressure_processed,
		"rbq" = length(air.pipenets_needing_rebuilt),
		"epq" = length(air.expansion_queue),
		"gm" = air.gas_mixes_count,
		"gma" = air.gas_mixes_allocated,
		"egt" = air.num_group_turfs_processed,
		"eqn" = air.num_equalize_processed,
		"hpt" = air.high_pressure_turfs,
		"lpt" = air.low_pressure_turfs,
		"td_c" = round(SStime_track.time_dilation_current, 0.01),
		"td_f" = round(SStime_track.time_dilation_avg_fast, 0.01),
		"td_a" = round(SStime_track.time_dilation_avg, 0.01),
		"cpu" = round(world.cpu, 0.1),
		"mcpu" = round(world.map_cpu, 0.1),
		"cl" = length(GLOB.clients),
		"wt" = air.wait,
		"adjq" = length(SSadjacent_air.queue),
		"hbw" = air.heartbeat_wakes_last,
		"pnu" = air.count_dirty_pipenets(),
	)
	// A profiled machinery pass armed by the previous deep sample: write it out
	// as its own record and free the slot for the next arming.
	if(air.benchmark_machinery_profile_result)
		var/list/machinery_profile = air.benchmark_machinery_profile_result
		air.benchmark_machinery_profile_result = null
		machinery_profile["rec"] = "mprof"
		machinery_profile["t"] = world.time
		machinery_profile["fired"] = air.times_fired
		write_record(machinery_profile)
	// An anomalously large active list deserves a cheap z histogram: the deep
	// walk samples a different phase of the fire cycle and can miss transient
	// mass wake-ups entirely (shuttle transits, adjacency wake loops). Those
	// wake-ups are also exactly when a full walk would stall this synchronous
	// timer callback, so past the budget the list is stride-sampled and the
	// buckets scaled back up to approximate true counts.
	var/active_count = length(air.active_turfs)
	if(active_count > ATMOS_BENCH_Z_HOT_THRESHOLD)
		var/list/z_hot = list()
		var/list/active_turfs = air.active_turfs
		var/stride = max(1, CEILING(active_count / ATMOS_BENCH_Z_HOT_BUDGET, 1))
		for(var/i in 1 to active_count step stride)
			var/turf/hot_turf = active_turfs[i]
			z_hot["[hot_turf.z]"] += stride
		record["z_hot"] = z_hot
	for(var/field in summary_fields)
		var/value = record[field]
		if(isnum(value))
			agg_sum[field] = (agg_sum[field] || 0) + value
			agg_max[field] = max(agg_max[field] || 0, value)
	sample_count++
	write_record(record)

/// World-walking breakdown of where the active turfs actually are. Runs off the
/// timer subsystem (InvokeAsync), so CHECK_TICK spreads the walk across ticks.
/datum/atmos_benchmark/proc/deep_sample()
	if(finished)
		return
	// Arm the per-type machinery timing: the next machinery pass runs profiled
	// and the next per-second sample writes it out as an mprof record.
	SSair.benchmark_machinery_profile_pending = TRUE
	var/walk_started = REALTIMEOFDAY
	var/list/z_counts = list()
	var/list/area_counts = list()
	var/list/area_sharing = list()
	var/list/area_planetary = list()
	var/list/area_space_adjacent = list()
	var/list/area_turf_types = list()
	var/list/area_share_sum = list()
	var/list/area_temp_min = list()
	var/list/area_temp_max = list()
	var/list/area_pressure_min = list()
	var/list/area_pressure_max = list()
	var/planetary_count = 0
	var/sharing_count = 0
	var/grouped_count = 0
	var/space_adjacent_count = 0
	var/list/snapshot = SSair.active_turfs.Copy()
	for(var/turf/open/active_turf as anything in snapshot)
		if(!istype(active_turf) || !active_turf.air)
			continue
		z_counts["[active_turf.z]"]++
		var/area/turf_area = active_turf.loc
		var/area_key = "[turf_area.type]"
		area_counts[area_key]++
		var/list/type_counts = area_turf_types[area_key]
		if(!type_counts)
			type_counts = list()
			area_turf_types[area_key] = type_counts
		type_counts["[active_turf.type]"]++
		if(active_turf.planetary_atmos)
			planetary_count++
			area_planetary[area_key]++
		if(active_turf.excited_group)
			grouped_count++
		var/last_share = active_turf.air.last_share
		if(last_share > MINIMUM_MOLES_DELTA_TO_MOVE)
			sharing_count++
			area_sharing[area_key]++
			area_share_sum[area_key] = (area_share_sum[area_key] || 0) + last_share
		for(var/turf/neighbor as anything in active_turf.atmos_adjacent_turfs)
			if(isspaceturf(neighbor))
				space_adjacent_count++
				area_space_adjacent[area_key]++
				break
		var/turf_temp = active_turf.air.return_temperature()
		var/turf_pressure = active_turf.air.return_pressure()
		area_temp_min[area_key] = isnull(area_temp_min[area_key]) ? turf_temp : min(area_temp_min[area_key], turf_temp)
		area_temp_max[area_key] = max(area_temp_max[area_key] || 0, turf_temp)
		area_pressure_min[area_key] = isnull(area_pressure_min[area_key]) ? turf_pressure : min(area_pressure_min[area_key], turf_pressure)
		area_pressure_max[area_key] = max(area_pressure_max[area_key] || 0, turf_pressure)
		CHECK_TICK

	sortTim(area_counts, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top_areas = list()
	for(var/area_key in area_counts)
		if(length(top_areas) >= ATMOS_BENCH_TOP_AREAS)
			break
		var/list/type_counts = area_turf_types[area_key]
		sortTim(type_counts, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
		var/list/top_types = list()
		for(var/type_key in type_counts)
			if(length(top_types) >= 3)
				break
			top_types[type_key] = type_counts[type_key]
		top_areas += list(list(
			"a" = area_key,
			"n" = area_counts[area_key],
			"sh" = area_sharing[area_key] || 0,
			"pl" = area_planetary[area_key] || 0,
			"sp" = area_space_adjacent[area_key] || 0,
			"sh_sum" = round(area_share_sum[area_key] || 0, 0.01),
			"t_min" = round(area_temp_min[area_key] || 0, 0.1),
			"t_max" = round(area_temp_max[area_key] || 0, 0.1),
			"p_min" = round(area_pressure_min[area_key] || 0, 0.1),
			"p_max" = round(area_pressure_max[area_key] || 0, 0.1),
			"types" = top_types,
		))

	var/eg_turfs = 0
	var/eg_max = 0
	var/eg_max_area
	for(var/datum/excited_group/group as anything in SSair.excited_groups.Copy())
		if(!group)
			continue
		var/group_size = length(group.turf_list)
		eg_turfs += group_size
		if(group_size > eg_max)
			eg_max = group_size
			var/turf/first_turf = group_size ? group.turf_list[1] : null
			var/area/group_area = first_turf ? get_area(first_turf) : null
			eg_max_area = group_area ? "[group_area.type]" : null
		CHECK_TICK

	var/list/hotspot_areas = list()
	for(var/obj/effect/hotspot/hotspot as anything in SSair.hotspots.Copy())
		if(!hotspot)
			continue
		var/area/hotspot_area = get_area(hotspot)
		hotspot_areas["[hotspot_area ? hotspot_area.type : "unknown"]"]++
		CHECK_TICK

	if(finished) // the run may have ended while the walk slept
		return
	write_record(list(
		"rec" = "deep",
		"t" = world.time,
		"at" = length(snapshot),
		"planetary" = planetary_count,
		"sharing" = sharing_count,
		"grouped" = grouped_count,
		"space_adjacent" = space_adjacent_count,
		"z" = z_counts,
		"areas" = top_areas,
		"eg_n" = length(SSair.excited_groups),
		"eg_turfs" = eg_turfs,
		"eg_max" = eg_max,
		"eg_max_area" = eg_max_area,
		"hs_areas" = hotspot_areas,
		"walk_ms" = (REALTIMEOFDAY - walk_started) * 100,
	))

/// One-time composition census: which machinery types are actually processing,
/// and how the pipenets are sized. Composition barely changes mid-round.
/datum/atmos_benchmark/proc/write_static_census()
	var/list/type_counts = list()
	var/total_machines = 0
	// Awake machines plus sleepers in the heartbeat queue. Machines that left
	// via PROCESS_KILL (settled canisters, empty connectors) are not counted.
	for(var/obj/machinery/machine as anything in (SSair.atmos_machinery.Copy() + SSair.idle_machine_list()))
		if(!machine)
			continue
		total_machines++
		type_counts["[machine.type]"]++
		CHECK_TICK
	sortTim(type_counts, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top_types = list()
	for(var/type_key in type_counts)
		if(length(top_types) >= ATMOS_BENCH_TOP_TYPES)
			break
		top_types[type_key] = type_counts[type_key]

	var/pipenet_members = 0
	var/pipenet_max = 0
	for(var/datum/pipeline/net as anything in SSair.networks.Copy())
		if(!net)
			continue
		var/member_count = length(net.members)
		pipenet_members += member_count
		pipenet_max = max(pipenet_max, member_count)
		CHECK_TICK

	if(finished)
		return
	write_record(list(
		"rec" = "census",
		"t" = world.time,
		"machines" = total_machines,
		"machine_types" = top_types,
		"pipenets" = length(SSair.networks),
		"pipenet_members" = pipenet_members,
		"pipenet_max" = pipenet_max,
	))

/datum/atmos_benchmark/proc/finish(reason = "completed")
	if(finished)
		return
	finished = TRUE
	deltimer(sample_timer_id)
	deltimer(deep_timer_id)
	// A profile armed by the last deep sample has no consumer anymore.
	SSair.benchmark_machinery_profile_pending = FALSE
	SSair.benchmark_machinery_profile_result = null
	var/list/averages = list()
	var/list/maximums = list()
	if(sample_count)
		for(var/field in agg_max)
			averages[field] = round(agg_sum[field] / sample_count, 0.01)
			maximums[field] = agg_max[field]
	write_record(list(
		"rec" = "summary",
		"t" = world.time,
		"reason" = reason,
		"samples" = sample_count,
		"fires" = SSair.times_fired - fires_at_start,
		"duration_ds" = world.time - started_at,
		"avg" = averages,
		"max" = maximums,
	))

	var/list/digest = list("Атмос-бенчмарк завершён ([reason]): [sample_count] сэмплов за [round((world.time - started_at) / (1 MINUTES), 0.1)] мин.")
	if(sample_count)
		digest += "SSair cost: avg [averages["cost"]] ms, max [maximums["cost"]] ms. Active turfs: avg [averages["at"]], max [maximums["at"]]. TD fast: avg [averages["td_f"]]%, max [maximums["td_f"]]%."
		var/list/phase_costs = list()
		for(var/field in phase_names)
			phase_costs[field] = averages[field] || 0
		sortTim(phase_costs, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
		var/list/top_phases = list()
		for(var/field in phase_costs)
			if(length(top_phases) >= 3)
				break
			top_phases += "[phase_names[field]] [phase_costs[field]] ms"
		digest += "Топ фаз по среднему: [top_phases.Join(", ")]."
	digest += "Файл: [file_path]"
	message_admins(digest.Join("<br>"))
	log_admin("Atmos benchmark finished ([reason]): [sample_count] samples -> [file_path]")
	if(GLOB.atmos_benchmark_run == src)
		GLOB.atmos_benchmark_run = null

#undef ATMOS_BENCH_SAMPLE_INTERVAL
#undef ATMOS_BENCH_DEEP_INTERVAL
#undef ATMOS_BENCH_TOP_AREAS
#undef ATMOS_BENCH_TOP_TYPES
#undef ATMOS_BENCH_Z_HOT_BUDGET
#undef ATMOS_BENCH_Z_HOT_THRESHOLD

#endif // ifndef TGS

// ============================================================================
// ATMOS_HEADLESS_BENCH: unattended atmos settling benchmark.
// Compile with `node tools/build/build.js dm -D ATMOS_HEADLESS_BENCH`, point
// data/next_map.json at the map under test and launch DreamDaemon with no
// clients (tools/atmos_bench/run_headless.sh does all of it). The world is
// kept awake, SSair fires without a round, one JSONL heartbeat per completed
// SSair cycle plus periodic deep snapshots go to data/atmos_headless_bench_*.jsonl,
// and after ATMOS_HEADLESS_BENCH_CYCLES cycles the server shuts itself down.
// Never define this for a production build: it force-starts atmos in the lobby
// and kills the world when done.
// ============================================================================
#ifdef ATMOS_HEADLESS_BENCH

#ifndef ATMOS_HEADLESS_BENCH_CYCLES
#define ATMOS_HEADLESS_BENCH_CYCLES 240
#endif
/// Deep per-turf snapshot every this many completed cycles.
#define ATMOS_HEADLESS_BENCH_SNAPSHOT_EVERY 15
#define ATMOS_HEADLESS_ROOM_WIDTH 50
#define ATMOS_HEADLESS_ROOM_HEIGHT 40
#define ATMOS_HEADLESS_ROOM_OUTER_WIDTH (ATMOS_HEADLESS_ROOM_WIDTH + 2)
#define ATMOS_HEADLESS_ROOM_OUTER_HEIGHT (ATMOS_HEADLESS_ROOM_HEIGHT + 2)
#define ATMOS_HEADLESS_ROOM_GAP 4
#define ATMOS_HEADLESS_ROOM_COUNT 4
#define ATMOS_HEADLESS_DEFAULT_BREACH_CYCLE 20

GLOBAL_VAR_INIT(atmos_headless_bench_path, "data/atmos_headless_bench_[time2text(world.realtime, "YYYY-MM-DD_hh.mm.ss")].jsonl")
GLOBAL_VAR_INIT(atmos_headless_bench_snapshot_running, FALSE)
GLOBAL_VAR_INIT(atmos_headless_bench_finished, FALSE)

/area/atmos_headless_bench
	name = "Atmos Headless Bench"
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	has_gravity = STANDARD_GRAVITY

/area/atmos_headless_bench/one
/area/atmos_headless_bench/two
/area/atmos_headless_bench/three
/area/atmos_headless_bench/four

/datum/controller/subsystem/air
	/// Completed finish-phase cycles since round start (bench cadence counter).
	var/headless_bench_cycles = 0
	/// Number of MC invocations used by the currently completing SSair fire.
	var/headless_bench_mc_slices = 1
	var/headless_bench_scenario_checked = FALSE
	var/headless_bench_scenario
	var/headless_bench_scenario_building = FALSE
	var/headless_bench_scenario_ready = FALSE
	var/headless_bench_breach_cycle = ATMOS_HEADLESS_DEFAULT_BREACH_CYCLE
	var/headless_bench_breach_count = 1
	var/headless_bench_firelocks = TRUE
	var/datum/turf_reservation/headless_bench_reservation
	var/list/turf/open/headless_bench_room_turfs = list()
	var/list/turf/headless_bench_breach_turfs = list()
	var/list/obj/machinery/door/firedoor/headless_bench_firedoors = list()
	var/list/area/headless_bench_areas = list()
	/// Buffered so benchmark logging does not inflate the excited-group phase it
	/// is supposed to measure.
	var/list/headless_bench_breakdown_records = list()

/// Reads the optional synthetic scenario parameters exactly once.
/datum/controller/subsystem/air/proc/atmos_headless_bench_configure()
	if(headless_bench_scenario_checked)
		return
	headless_bench_scenario_checked = TRUE
	// A/B-рычаг спящих рёбер: "atmos-bench-sleeping-edges=1" включает фичу на
	// весь прогон, любое другое значение/отсутствие - оставляет конфигный дефолт.
	if(world.params["atmos-bench-sleeping-edges"] == "1")
		sleeping_edges_enabled = TRUE
	headless_bench_scenario = world.params["atmos-bench-scenario"]
	if(!headless_bench_scenario)
		headless_bench_scenario_ready = TRUE
		return
	// The generic event cycle; the old breach-cycle spelling stays as an alias.
	headless_bench_breach_cycle = max(1, text2num(world.params["atmos-bench-event-cycle"]) || text2num(world.params["atmos-bench-breach-cycle"]) || ATMOS_HEADLESS_DEFAULT_BREACH_CYCLE)
	headless_bench_breach_count = clamp(text2num(world.params["atmos-bench-breaches"]) || 1, 1, ATMOS_HEADLESS_ROOM_COUNT)
	var/firelock_param = world.params["atmos-bench-firelocks"]
	headless_bench_firelocks = isnull(firelock_param) || firelock_param != "0"

/// Builds four independent 50x40 rooms on a reserved z-level. Each has a
/// central open firelock; disabling firelocks welds it open so the topology is
/// identical but pressure-stop cannot close it. The west hull wall is retained
/// as each room's deterministic breach point.
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_multi_breach()
	can_fire = FALSE
	var/reservation_width = ATMOS_HEADLESS_ROOM_OUTER_WIDTH * 2 + ATMOS_HEADLESS_ROOM_GAP
	var/reservation_height = ATMOS_HEADLESS_ROOM_OUTER_HEIGHT * 2 + ATMOS_HEADLESS_ROOM_GAP
	headless_bench_reservation = SSmapping.RequestBlockReservation(reservation_width, reservation_height)
	if(!headless_bench_reservation)
		log_world("ATMOS-BENCH: failed to reserve the multi-breach arena")
		GLOB.atmos_headless_bench_finished = TRUE
		can_fire = TRUE
		del(world)
		return

	var/list/area_types = list(
		/area/atmos_headless_bench/one,
		/area/atmos_headless_bench/two,
		/area/atmos_headless_bench/three,
		/area/atmos_headless_bench/four,
	)
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	for(var/room_index in 1 to ATMOS_HEADLESS_ROOM_COUNT)
		var/column = (room_index - 1) % 2
		var/row = round((room_index - 1) / 2)
		var/origin_x = base_x + column * (ATMOS_HEADLESS_ROOM_OUTER_WIDTH + ATMOS_HEADLESS_ROOM_GAP)
		var/origin_y = base_y + row * (ATMOS_HEADLESS_ROOM_OUTER_HEIGHT + ATMOS_HEADLESS_ROOM_GAP)
		var/divider_x = origin_x + round(ATMOS_HEADLESS_ROOM_OUTER_WIDTH / 2)
		var/door_y = origin_y + round(ATMOS_HEADLESS_ROOM_OUTER_HEIGHT / 2)
		var/room_area_type = area_types[room_index]
		var/area/room_area = new room_area_type
		room_area.name = "Atmos Headless Bench [room_index]"
		headless_bench_areas += room_area
		for(var/x in origin_x to origin_x + ATMOS_HEADLESS_ROOM_OUTER_WIDTH - 1)
			for(var/y in origin_y to origin_y + ATMOS_HEADLESS_ROOM_OUTER_HEIGHT - 1)
				var/turf/T = locate(x, y, base_z)
				var/area/old_area = T.loc
				room_area.contents += T
				T.change_area(old_area, room_area, skip_blend = TRUE)
				var/outer_wall = x == origin_x || x == origin_x + ATMOS_HEADLESS_ROOM_OUTER_WIDTH - 1 || y == origin_y || y == origin_y + ATMOS_HEADLESS_ROOM_OUTER_HEIGHT - 1
				var/divider_wall = x == divider_x && y != door_y
				if(outer_wall || divider_wall)
					T.ChangeTurf(/turf/closed/wall)
				else
					var/turf/open/floor/floor = T.ChangeTurf(/turf/open/floor/plasteel)
					headless_bench_room_turfs += floor
				CHECK_TICK
		room_area.reg_in_areas_in_z()
		var/turf/door_turf = locate(divider_x, door_y, base_z)
		var/obj/machinery/door/firedoor/firedoor = new(door_turf)
		if(!headless_bench_firelocks)
			// An open welded firelock preserves the exact same open adjacency but
			// ignores both firealert and emergency pressure-stop closure.
			firedoor.welded = TRUE
		firedoor.CalculateAffectingAreas()
		headless_bench_firedoors += firedoor
		new /obj/machinery/airalarm(locate(origin_x + ATMOS_HEADLESS_ROOM_WIDTH - 5, door_y, base_z))
		headless_bench_breach_turfs += locate(origin_x, door_y, base_z)

	// ChangeTurf's deferred adjacency queue is intentionally bypassed here so
	// every run starts from the same fully-connected room graph.
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		T.ImmediateCalculateAdjacentTurfs()
		add_to_active(T)
		CHECK_TICK
	headless_bench_scenario_ready = TRUE
	headless_bench_scenario_building = FALSE
	can_fire = TRUE
	var/list/record = list(
		"rec" = "event",
		"event" = "scenario_ready",
		"scenario" = headless_bench_scenario,
		"rooms" = ATMOS_HEADLESS_ROOM_COUNT,
		"room_turfs" = ATMOS_HEADLESS_ROOM_WIDTH * ATMOS_HEADLESS_ROOM_HEIGHT,
		"breaches" = headless_bench_breach_count,
		"breach_cycle" = headless_bench_breach_cycle,
		"firelocks" = headless_bench_firelocks,
		"seed" = Master.random_seed,
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)
	log_world("ATMOS-BENCH: multi-breach arena ready ([headless_bench_breach_count] breach(es), firelocks [headless_bench_firelocks ? "enabled" : "disabled"])")

/datum/controller/subsystem/air/proc/atmos_headless_bench_open_breaches()
	for(var/index in 1 to headless_bench_breach_count)
		var/turf/breach = headless_bench_breach_turfs[index]
		if(!breach)
			continue
		breach.ChangeTurf(/turf/open/space)
	var/list/record = list(
		"rec" = "event",
		"event" = "breach",
		"cyc" = headless_bench_cycles,
		"breaches" = headless_bench_breach_count,
		"firelocks" = headless_bench_firelocks,
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

/datum/controller/subsystem/air/proc/atmos_headless_bench_record_breakdown(members, duration, slices, completed)
	headless_bench_breakdown_records += list(list(
		"rec" = "breakdown",
		"cyc" = headless_bench_cycles,
		"members" = members,
		"duration_ds" = duration,
		"slices" = slices,
		"completed" = completed,
		"t" = world.time,
	))

/// Intra-phase profiler driver for the active turf pass.
///
/// The turf phase is the most expensive part of SSair and used to report one
/// number, so every optimisation guess about process_cell was blind. The
/// ATMOS_TPROF_* macros split it into named slots; this proc arms them for
/// exactly one cycle per snapshot interval and writes the harvest as a `tprof`
/// record. Arming for one cycle at a time is what keeps the instrumentation
/// from distorting the very curve the benchmark is measuring.
///
/// The "space" slot is nested inside "neighbors" and is therefore excluded
/// from the parts total; comparing that total against phase_ms shows how much
/// the stopwatches themselves cost. Overlay counters also pick up the
/// update_visuals calls that excited-group breakdown makes in the same cycle,
/// which is deliberate: those are part of the same per-cycle overlay budget.
/datum/controller/subsystem/air/proc/atmos_headless_bench_turf_profile(cycle)
	if(GLOB.atmos_tprof_active)
		GLOB.atmos_tprof_active = FALSE
		var/list/slots = list()
		var/parts_ms = 0
		for(var/slot in GLOB.atmos_tprof_ms)
			var/value = round(GLOB.atmos_tprof_ms[slot], 0.001)
			slots[slot] = value
			if(slot != "space")
				parts_ms += value
		var/list/record = list(
			"rec" = "tprof",
			"cyc" = cycle,
			"fired" = times_fired,
			"t" = world.time,
			"at" = length(active_turfs),
			"eg" = length(excited_groups),
			"slots" = slots,
			"counts" = GLOB.atmos_tprof_counts.Copy(),
			"parts_ms" = round(parts_ms, 0.001),
			"phase_ms" = round(cost_turfs_last, 0.001),
		)
		rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)
		GLOB.atmos_tprof_ms.Cut()
		GLOB.atmos_tprof_counts.Cut()
		return
	if(cycle % ATMOS_HEADLESS_BENCH_SNAPSHOT_EVERY != 0)
		return
	GLOB.atmos_tprof_ms.Cut()
	GLOB.atmos_tprof_counts.Cut()
	GLOB.atmos_tprof_active = TRUE

/// Cycle budget: world.params override (dd -params "atmos-bench-cycles=600") wins
/// over the compile-time default, so run length changes need no rebuild.
/datum/controller/subsystem/air/proc/atmos_headless_bench_target()
	var/static/target_cycles = 0
	if(!target_cycles)
		target_cycles = text2num(world.params["atmos-bench-cycles"]) || ATMOS_HEADLESS_BENCH_CYCLES
	return target_cycles

/// Called once per fully completed SSair cycle (end of finish_turf_processing).
/datum/controller/subsystem/air/proc/atmos_headless_bench_tick()
	if(GLOB.atmos_headless_bench_finished)
		return
	atmos_headless_bench_configure()
	if(headless_bench_scenario && !headless_bench_scenario_ready)
		if(!headless_bench_scenario_building)
			headless_bench_scenario_building = TRUE
			INVOKE_ASYNC(src, PROC_REF(atmos_headless_bench_build_scenario))
		return
	headless_bench_cycles++
	if(headless_bench_scenario)
		atmos_headless_bench_scenario_event(headless_bench_cycles)
	var/largest_group = 0
	var/scenario_largest_group = 0
	var/track_scenario_areas = length(headless_bench_areas) > 0
	for(var/datum/excited_group/group as anything in excited_groups)
		if(group)
			largest_group = max(largest_group, length(group.turf_list))
			if(track_scenario_areas && length(group.turf_list))
				var/area/group_area = get_area(group.turf_list[1])
				if(group_area in headless_bench_areas)
					scenario_largest_group = max(scenario_largest_group, length(group.turf_list))
	var/scenario_active_turfs = 0
	if(track_scenario_areas)
		for(var/turf/open/T as anything in active_turfs)
			if(get_area(T) in headless_bench_areas)
				scenario_active_turfs++
	var/closed_firedoors = 0
	for(var/obj/machinery/door/firedoor/firedoor as anything in headless_bench_firedoors)
		if(firedoor?.density)
			closed_firedoors++
	var/alarmed_areas = 0
	for(var/area/bench_area as anything in headless_bench_areas)
		if(bench_area?.fire)
			alarmed_areas++
	var/list/record = list(
		"rec" = "hb",
		"cyc" = headless_bench_cycles,
		"fired" = times_fired,
		"t" = world.time,
		"at" = length(active_turfs),
		"eg" = length(excited_groups),
		"hs" = length(hotspots),
		"cost" = round(cost, 0.01),
		"c_at" = round(cost_turfs, 0.01),
		// Unsmoothed twin of c_at: MC_AVERAGE hides the true spike amplitude.
		"c_at_raw" = round(cost_turfs_last, 0.01),
		"c_ao" = round(cost_atmos_atoms, 0.01),
		"c_eg" = round(cost_groups, 0.01),
		"c_dc" = round(cost_decompression, 0.01),
		"c_pp" = round(cost_post_process, 0.01),
		"c_hs" = round(cost_hotspots, 0.01),
		"c_sc" = round(cost_superconductivity, 0.01),
		"c_hp" = round(cost_highpressure, 0.01),
		"c_eq" = round(cost_equalize, 0.01),
		// Work done by the group and equalize phases, so their cost can be
		// normalised per unit of work instead of compared as raw wall-clock
		// between runs that saw different amounts of it.
		"egt" = num_group_turfs_processed,
		"eqn" = num_equalize_processed,
		"sct" = length(active_super_conductivity),
		"eqv" = equalize_valve_mode,
		"da" = num_decompression_areas,
		"largest_eg" = largest_group,
		"scenario_at" = track_scenario_areas ? scenario_active_turfs : null,
		"scenario_largest_eg" = track_scenario_areas ? scenario_largest_group : null,
		"mc" = headless_bench_mc_slices,
		"td_c" = round(SStime_track.time_dilation_current, 0.01),
		"scenario" = headless_bench_scenario,
		"doors_closed" = closed_firedoors,
		"doors_total" = length(headless_bench_firedoors),
		"alarms" = alarmed_areas,
		// Machinery visibility: the turf-only records hid a machinery-wake
		// regression once (breakdown wakes pinning vents awake), so A/B runs
		// must see the awake set and its cost too.
		"c_pn" = round(cost_pipenets, 0.01),
		"c_am" = round(cost_atmos_machinery, 0.01),
		"hpd" = high_pressure_processed,
		"am" = length(atmos_machinery),
		"ao" = length(atom_process),
		"ami" = idle_machine_count(),
		"hbw" = heartbeat_wakes_last,
		"pnu" = count_dirty_pipenets(),
	)
	var/encoded = json_encode(record)
	rustg_file_append("[encoded]\n", GLOB.atmos_headless_bench_path)
	// Per-type machinery timing armed by the previous snapshot.
	if(benchmark_machinery_profile_result)
		var/list/machinery_profile = benchmark_machinery_profile_result
		benchmark_machinery_profile_result = null
		machinery_profile["rec"] = "mprof"
		machinery_profile["t"] = world.time
		machinery_profile["fired"] = times_fired
		rustg_file_append("[json_encode(machinery_profile)]\n", GLOB.atmos_headless_bench_path)
	atmos_headless_bench_turf_profile(headless_bench_cycles)
	if(headless_bench_cycles >= atmos_headless_bench_target())
		GLOB.atmos_headless_bench_finished = TRUE
		INVOKE_ASYNC(src, PROC_REF(atmos_headless_bench_finish))
		return
	if(headless_bench_cycles % ATMOS_HEADLESS_BENCH_SNAPSHOT_EVERY == 0 && !GLOB.atmos_headless_bench_snapshot_running)
		GLOB.atmos_headless_bench_snapshot_running = TRUE
		INVOKE_ASYNC(src, PROC_REF(atmos_headless_bench_snapshot))

/// Per-turf walk: where the active set lives and whether planetary turfs sit at
/// their templates. CHECK_TICK spread, so it runs async off the timer.
/datum/controller/subsystem/air/proc/atmos_headless_bench_snapshot()
	// Arm the per-type machinery timing; the tick after the profiled pass
	// writes it out as an mprof record.
	benchmark_machinery_profile_pending = TRUE
	var/fired_now = times_fired
	var/cycle_now = headless_bench_cycles
	var/list/cooldown_hist = list()
	var/list/planet_compare_hist = list()
	var/list/type_hist = list()
	var/list/area_hist = list()
	// Perpetual-churner census: tiles that moved significant gas last cycle,
	// keyed by "type|self sky|neighbor profile" so pump classes (station-air
	// bridges between two skies, ruin floors, seam rings) are named directly.
	var/list/sharer_signatures = list()
	var/list/sharer_examples = list()
	var/temp_max = 0
	var/pressure_max = 0
	var/list/snapshot = active_turfs.Copy()
	for(var/turf/open/T as anything in snapshot)
		if(!istype(T) || !T.air)
			continue
		var/cd = T.atmos_cooldown
		var/cd_key = cd <= 0 ? "0" : (cd <= 4 ? "1-4" : (cd <= 16 ? "5-16" : "17+"))
		cooldown_hist[cd_key]++
		type_hist["[T.type]"]++
		area_hist["[T.loc?.type]"]++
		if(T.planetary_atmos)
			var/datum/gas_mixture/template = get_planetary_template(T)
			var/compare_result = template ? T.air.compare(template) : "no_template"
			planet_compare_hist[compare_result == "" ? "equal" : compare_result]++
		if(T.air.last_share > MINIMUM_MOLES_DELTA_TO_MOVE)
			var/same_sky = 0
			var/other_sky = 0
			var/non_planetary = 0
			for(var/turf/neighbor as anything in T.atmos_adjacent_turfs)
				var/turf/open/open_neighbor = neighbor
				if(!istype(open_neighbor))
					continue
				if(!open_neighbor.planetary_atmos)
					non_planetary++
				else if(open_neighbor.initial_gas_mix == T.initial_gas_mix)
					same_sky++
				else
					other_sky++
			var/self_key = T.planetary_atmos ? "sky" : "non"
			var/signature = "[T.type]|[self_key]|same=[same_sky] other=[other_sky] non=[non_planetary]"
			sharer_signatures[signature]++
			var/list/examples = sharer_examples[signature]
			if(!examples)
				examples = list()
				sharer_examples[signature] = examples
			if(length(examples) < 4)
				examples += "[T.x],[T.y],[T.z] ls=[round(T.air.last_share, 0.01)] t=[round(T.air.return_temperature(), 0.1)]"
		var/turf_temp = T.air.return_temperature()
		temp_max = max(temp_max, turf_temp)
		pressure_max = max(pressure_max, T.air.return_pressure())
		CHECK_TICK
	var/list/group_records = list()
	for(var/datum/excited_group/group as anything in excited_groups.Copy())
		if(!group)
			continue
		var/awake_count = 0
		for(var/turf/open/T as anything in group.turf_list)
			if(istype(T) && T.excited)
				awake_count++
		var/group_area_key = null
		if(length(group.turf_list))
			var/area/group_area = get_area(group.turf_list[1])
			group_area_key = group_area ? "[group_area.type]" : null
		group_records += list(list(
			"size" = length(group.turf_list),
			"awake" = awake_count,
			"bd_cd" = group.breakdown_cooldown,
			"dm_cd" = group.dismantle_cooldown,
			"bd_stage" = group.breakdown_stage,
			"bd_cursor" = group.breakdown_cursor,
			"area" = group_area_key,
		))
		CHECK_TICK
	sortTim(type_hist, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	sortTim(area_hist, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top_types = list()
	for(var/key in type_hist)
		if(length(top_types) >= 12)
			break
		top_types[key] = type_hist[key]
	var/list/top_areas = list()
	for(var/key in area_hist)
		if(length(top_areas) >= 12)
			break
		top_areas[key] = area_hist[key]
	sortTim(sharer_signatures, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top_sharers = list()
	for(var/signature in sharer_signatures)
		if(length(top_sharers) >= 20)
			break
		top_sharers += list(list(
			"sig" = signature,
			"n" = sharer_signatures[signature],
			"ex" = sharer_examples[signature],
		))
	var/list/record = list(
		"rec" = "snapshot",
		"cyc" = cycle_now,
		"fired" = fired_now,
		"t" = world.time,
		"at" = length(snapshot),
		"cooldown" = cooldown_hist,
		"planet_compare" = planet_compare_hist,
		"top_types" = top_types,
		"top_areas" = top_areas,
		"sharers" = top_sharers,
		"temp_max" = temp_max,
		"pressure_max" = pressure_max,
		"groups" = group_records,
	)
	var/encoded = json_encode(record)
	rustg_file_append("[encoded]\n", GLOB.atmos_headless_bench_path)
	GLOB.atmos_headless_bench_snapshot_running = FALSE

/// Gives an isolated operation profile for the new mechanics after the normal
/// SSair run. It cannot distort the cycle curves because it runs only after the
/// final snapshot. Permanent-cost paths (turf signals, atom processing,
/// pipenets and machinery) remain visible in every heartbeat above.
/datum/controller/subsystem/air/proc/atmos_headless_bench_feature_probe()
	var/iterations = 500
	var/list/costs = list()
	var/list/checks = list()
	var/timer
	var/turf/open/probe_turf = length(headless_bench_room_turfs) ? headless_bench_room_turfs[1] : null
	// Map-settling runs do not build the synthetic multi-breach arena. Borrow an
	// already-active open turf instead so feature checks remain live in both
	// benchmark modes; every temporary air change below is restored.
	if(!probe_turf)
		for(var/turf/open/candidate as anything in active_turfs)
			probe_turf = candidate
			break

	var/obj/machinery/atmospherics/components/binary/temperature_gate/gate = new(null)
	var/obj/machinery/atmospherics/components/binary/temperature_pump/temperature_pump = new(null)
	var/obj/machinery/atmospherics/components/binary/pressure_valve/pressure_valve = new(null)
	for(var/obj/machinery/atmospherics/components/component as anything in list(gate, temperature_pump, pressure_valve))
		stop_processing_machine(component)
		component.machine_stat &= ~(NOPOWER|BROKEN)
		component.set_is_operational(TRUE)
		component.atmos_idle_until = 0
		component.atmos_idle_streak = 0
		for(var/i in 1 to component.device_type)
			var/datum/pipeline/parent = new
			parent.air = new(200)
			parent.other_atmosmch += component
			parent.other_airs += component.airs[i]
			component.parents[i] = parent
	gate.on = TRUE
	gate.target_temperature = T20C + 50
	temperature_pump.on = TRUE
	temperature_pump.heat_transfer_rate = 50
	pressure_valve.on = TRUE
	pressure_valve.target_pressure = ONE_ATMOSPHERE
	timer = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		gate.airs[1].clear()
		gate.airs[2].clear()
		gate.airs[1].set_moles(GAS_O2, 40)
		gate.airs[1].set_temperature(T20C)
		gate.process_atmos()
		temperature_pump.airs[1].clear()
		temperature_pump.airs[2].clear()
		temperature_pump.airs[1].set_moles(GAS_N2, 30)
		temperature_pump.airs[2].set_moles(GAS_N2, 30)
		temperature_pump.airs[1].set_temperature(500)
		temperature_pump.airs[2].set_temperature(250)
		temperature_pump.process_atmos()
		pressure_valve.airs[1].clear()
		pressure_valve.airs[2].clear()
		pressure_valve.airs[1].set_moles(GAS_O2, 100)
		pressure_valve.airs[1].set_temperature(T20C)
		pressure_valve.process_atmos()
	costs["sensor_valves_ms"] = round(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), 0.001)
	checks["temperature_gate"] = gate.airs[2].total_moles() > 0
	checks["temperature_pump"] = temperature_pump.airs[1].return_temperature() < 500
	checks["pressure_valve"] = pressure_valve.airs[2].total_moles() > 0
	qdel(gate)
	qdel(temperature_pump)
	qdel(pressure_valve)

	var/obj/machinery/atmospherics/components/quaternary/omni_filter/omni_filter = new(null)
	var/obj/machinery/atmospherics/components/quaternary/omni_mixer/omni_mixer = new(null)
	for(var/obj/machinery/atmospherics/components/component as anything in list(omni_filter, omni_mixer))
		stop_processing_machine(component)
		component.machine_stat &= ~(NOPOWER|BROKEN)
		component.set_is_operational(TRUE)
		component.atmos_idle_until = 0
		component.atmos_idle_streak = 0
		for(var/i in 1 to QUATERNARY)
			component.nodes[i] = component
			var/datum/pipeline/parent = new
			parent.air = new(200)
			parent.other_atmosmch += component
			parent.other_airs += component.airs[i]
			component.parents[i] = parent
	omni_filter.on = TRUE
	omni_mixer.on = TRUE
	omni_mixer.target_pressure = ONE_ATMOSPHERE
	timer = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		for(var/port_index in 1 to QUATERNARY)
			omni_filter.airs[port_index].clear()
			omni_mixer.airs[port_index].clear()
		omni_filter.airs[1].set_moles(GAS_O2, 20)
		omni_filter.airs[1].set_moles(GAS_PLASMA, 10)
		omni_filter.process_atmos()
		omni_mixer.airs[1].set_moles(GAS_O2, 50)
		omni_mixer.airs[2].set_moles(GAS_N2, 50)
		omni_mixer.airs[3].set_moles(GAS_CO2, 50)
		for(var/port_index in 1 to 3)
			omni_mixer.airs[port_index].set_temperature(T20C)
		omni_mixer.process_atmos()
	costs["omni_devices_ms"] = round(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), 0.001)
	checks["omni_filter"] = omni_filter.airs[3].get_moles(GAS_PLASMA) > 9.9 && omni_filter.airs[2].get_moles(GAS_PLASMA) < 0.001
	checks["omni_mixer"] = omni_mixer.airs[4].get_moles(GAS_O2) > 0 && omni_mixer.airs[4].get_moles(GAS_N2) > 0 && omni_mixer.airs[4].get_moles(GAS_CO2) > 0
	qdel(omni_filter)
	qdel(omni_mixer)

	var/obj/machinery/portable_atmospherics/scrubber/pipe/pipe_scrubber = new(null)
	var/obj/machinery/atmospherics/components/unary/portables_connector/port = new(null)
	var/obj/item/tank/internals/emergency_oxygen/holding_tank = new(null)
	stop_processing_machine(pipe_scrubber)
	stop_processing_machine(port)
	var/datum/pipeline/port_parent = new
	port_parent.air = new(35)
	port_parent.other_atmosmch += port
	port_parent.other_airs += port.airs[1]
	port.parents[1] = port_parent
	pipe_scrubber.connected_port = port
	port.connected_device = pipe_scrubber
	pipe_scrubber.holding = holding_tank
	pipe_scrubber.on = TRUE
	timer = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		pipe_scrubber.air_contents.clear()
		holding_tank.air_contents.clear()
		pipe_scrubber.air_contents.set_moles(GAS_PLASMA, 10)
		pipe_scrubber.process_atmos()
	costs["pipe_scrubber_ms"] = round(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), 0.001)
	checks["pipe_scrubber"] = holding_tank.air_contents.get_moles(GAS_PLASMA) > 0
	pipe_scrubber.disconnect()
	qdel(pipe_scrubber)
	qdel(holding_tank)
	qdel(port)

	var/obj/item/clothing/under/probe_clothing = new(null)
	timer = TICK_USAGE_REAL
	for(var/i in 1 to iterations * 10)
		probe_clothing.plasma_contamination = 0
		probe_clothing.absorb_plasma(50)
	costs["plasma_clothing_ms"] = round(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), 0.001)
	checks["plasma_clothing"] = probe_clothing.plasma_contamination > 0
	qdel(probe_clothing)

	timer = TICK_USAGE_REAL
	for(var/i in 1 to iterations * 20)
		get_air_alarm_mode(1 + (i % 9))
	costs["air_alarm_mode_lookup_ms"] = round(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), 0.001)
	checks["air_alarm_modes"] = length(GLOB.air_alarm_modes) == 9
	checks["breathed_product"] = GLOB.gas_data.breath_reagents[GAS_H2O] == /datum/reagent/water
	checks["condensation_product"] = FALSE
	if(probe_turf)
		var/datum/gas_mixture/condensation_mix = new(CELL_VOLUME)
		condensation_mix.set_moles(GAS_H2O, 5)
		condensation_mix.set_moles(GAS_N2, 80)
		condensation_mix.set_temperature(T20C)
		var/water_vapor_before = condensation_mix.get_moles(GAS_H2O)
		var/condensation_result = condensation_mix.react(probe_turf)
		checks["condensation_product"] = (condensation_result & REACTING) && condensation_mix.get_moles(GAS_H2O) < water_vapor_before
		qdel(condensation_mix)

	// Every gas that can be seen must own a prebuilt overlay ladder: turf visuals
	// now pick the dominant gas's own sprite, with nothing to fall back on.
	var/visible_gas_types = 0
	var/complete_ladders = 0
	for(var/gas_id in GLOB.gas_data.visibility)
		if(!GLOB.gas_data.visibility[gas_id])
			continue
		visible_gas_types++
		var/list/ladder = GLOB.gas_data.overlays[gas_id]
		var/filled = 0
		if(islist(ladder) && length(ladder) == FACTOR_GAS_VISIBLE_MAX)
			for(var/i in 1 to FACTOR_GAS_VISIBLE_MAX)
				if(istype(ladder[i], /obj/effect/overlay/gas))
					filled++
		if(filled == FACTOR_GAS_VISIBLE_MAX)
			complete_ladders++
	checks["gas_overlay_ladders"] = visible_gas_types && complete_ladders == visible_gas_types

	if(probe_turf)
		var/turf/open/probe_neighbor = get_step(probe_turf, EAST)
		timer = TICK_USAGE_REAL
		for(var/i in 1 to iterations * 10)
			probe_turf.consider_pressure_difference(probe_neighbor, 100)
			probe_turf.pressure_vector_x = 0
			probe_turf.pressure_vector_y = 0
		costs["vector_wind_accumulation_ms"] = round(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), 0.001)
		checks["vector_wind"] = TRUE
		high_pressure_delta -= probe_turf
		probe_turf.high_pressure_queued = FALSE

	var/turf/firelock_turf = length(headless_bench_firedoors) ? get_turf(headless_bench_firedoors[1]) : null
	if(firelock_turf)
		timer = TICK_USAGE_REAL
		for(var/i in 1 to iterations)
			SEND_SIGNAL(firelock_turf, COMSIG_TURF_EXPOSE, firelock_turf.return_air(), T20C)
		costs["firelock_signal_ms"] = round(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), 0.001)
		checks["firelock_merger_signal"] = TRUE

	return list(
		"rec" = "features",
		"iterations" = iterations,
		"costs" = costs,
		"checks" = checks,
		"coverage" = list(
			"smart_pipes" = "topology-only; zero steady-state processing",
			"temperature_gate_pump_pressure_valve" = "sensor_valves_ms",
			"portable_pipe_scrubber" = "pipe_scrubber_ms",
			"bridge_pipe" = "topology-only; zero steady-state processing",
			"air_alarm_mode_datums" = "air_alarm_mode_lookup_ms",
			"firelock_signals_mergers_atmos_sensitive" = "heartbeat c_ao plus firelock_signal_ms",
			"pipe_leaks_bursts_auto_valves" = "rejected after gameplay review: extreme XFR networks must remain viable",
			"plasma_clothing" = "plasma_clothing_ms; no item processing list",
			"breathed_product" = "existing gas registry check",
			"condensation_product" = "live gas-to-turf reaction check",
			"omni_filter_mixer" = "omni_devices_ms",
			"vector_wind" = "SSair high-pressure phase plus vector_wind_accumulation_ms",
			"mixture_color_overlay" = "turf phase; dominant gas keeps its own sprite, no separate cache",
			"airlock_pump" = "rejected: needs dual waste and distribution map layers",
			"color_adapter" = "rejected: meaningful behavior requires global color-isolated pipenets and remapping",
		),
	)

/// Final snapshot, summary record, then kill the server so the runner script
/// can collect the file without babysitting the process.
/datum/controller/subsystem/air/proc/atmos_headless_bench_finish()
	// Wait out a snapshot that may still be walking, then take the final one.
	while(GLOB.atmos_headless_bench_snapshot_running)
		stoplag()
	GLOB.atmos_headless_bench_snapshot_running = TRUE
	atmos_headless_bench_snapshot()
	for(var/list/breakdown_record as anything in headless_bench_breakdown_records)
		rustg_file_append("[json_encode(breakdown_record)]\n", GLOB.atmos_headless_bench_path)
	var/list/feature_record = atmos_headless_bench_feature_probe()
	feature_record["t"] = world.time
	rustg_file_append("[json_encode(feature_record)]\n", GLOB.atmos_headless_bench_path)
	var/list/record = list(
		"rec" = "summary",
		"cycles" = headless_bench_cycles,
		"fired" = times_fired,
		"t" = world.time,
		"at" = length(active_turfs),
		"eg" = length(excited_groups),
		"map" = SSmapping.config?.map_name,
		"scenario" = headless_bench_scenario,
		"breaches" = headless_bench_scenario == "multi-breach" ? headless_bench_breach_count : null,
		"firelocks" = headless_bench_scenario == "multi-breach" ? headless_bench_firelocks : null,
		"seed" = Master.random_seed,
	)
	var/encoded = json_encode(record)
	rustg_file_append("[encoded]\n", GLOB.atmos_headless_bench_path)
	log_world("ATMOS-BENCH: finished [headless_bench_cycles] cycles on [SSmapping.config?.map_name], shutting down")
	sleep(1 SECONDS) // let the log flush
	del(world)

#undef ATMOS_HEADLESS_BENCH_SNAPSHOT_EVERY
#undef ATMOS_HEADLESS_ROOM_WIDTH
#undef ATMOS_HEADLESS_ROOM_HEIGHT
#undef ATMOS_HEADLESS_ROOM_OUTER_WIDTH
#undef ATMOS_HEADLESS_ROOM_OUTER_HEIGHT
#undef ATMOS_HEADLESS_ROOM_GAP
#undef ATMOS_HEADLESS_ROOM_COUNT
#undef ATMOS_HEADLESS_DEFAULT_BREACH_CYCLE

#endif // ifdef ATMOS_HEADLESS_BENCH
