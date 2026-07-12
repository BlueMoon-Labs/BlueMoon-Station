/// Admin-triggered SSmachines performance recorder. Writes one JSON object per line
/// (JSONL) so a crashed or restarted round still leaves every sample on disk.
/// Cheap by design: the per-second sample only reads existing SSmachines counters;
/// the per-machine-type cost breakdown is fed by the fire() instrumentation in
/// code/controllers/subsystem/machines.dm and flushed every MACHINES_BENCH_DEEP_INTERVAL
/// together with a processing-list census (walked under CHECK_TICK).
/// Testing-only tooling: production builds compile without it.
#ifdef TESTING

#define MACHINES_BENCH_SAMPLE_INTERVAL (1 SECONDS)
#define MACHINES_BENCH_DEEP_INTERVAL (30 SECONDS)
#define MACHINES_BENCH_TOP_TYPES 60

GLOBAL_DATUM(machines_benchmark_run, /datum/machines_benchmark)
GLOBAL_PROTECT(machines_benchmark_run)

/datum/admins/proc/machines_benchmark()
	set category = "Debug.3) Fixing"
	set desc = "Records SSmachines performance metrics to a JSONL file for offline analysis."
	set name = "Machines Benchmark"

	var/datum/machines_benchmark/current = GLOB.machines_benchmark_run
	if(current)
		var/remaining_minutes = round((current.end_at - world.time) / (1 MINUTES), 0.1)
		var/choice = alert(usr, "Бенчмарк уже идёт: [current.sample_count] сэмплов, осталось ~[remaining_minutes] мин.\nФайл: [current.file_path]", "Machines Benchmark", "Продолжить", "Остановить и сохранить")
		if(choice == "Остановить и сохранить" && GLOB.machines_benchmark_run == current)
			current.finish("stopped early by [key_name(usr)]")
		return

	var/minutes = input(usr, "Длительность бенчмарка в минутах", "Machines Benchmark", 10) as null|num
	if(!minutes)
		return
	minutes = clamp(minutes, 1, 120)
	if(GLOB.machines_benchmark_run) // someone else started one while we sat in input()
		to_chat(usr, span_warning("Бенчмарк уже запущен: [GLOB.machines_benchmark_run.file_path]"))
		return
	var/datum/machines_benchmark/bench = new(minutes MINUTES)
	GLOB.machines_benchmark_run = bench
	bench.start()
	message_admins("Бенчмарк машинерии запущен [key_name_admin(usr)] на [minutes] мин. Файл: [bench.file_path]")
	log_admin("[key_name(usr)] started machines benchmark for [minutes] minutes -> [bench.file_path]")

/datum/machines_benchmark
	var/file_path
	var/duration
	var/started_at
	var/end_at
	var/sample_timer_id
	var/deep_timer_id
	var/sample_count = 0
	var/fires_at_start = 0
	var/finished = FALSE
	/// ms of SSmachines fire() time per machine type, monotonic since start (fed by fire() instrumentation).
	var/list/type_cost_ms = list()
	/// process() calls per machine type, monotonic since start.
	var/list/type_calls = list()
	/// Running totals/high-water marks for the end-of-run summary, keyed by sample field.
	var/list/agg_sum = list()
	var/list/agg_max = list()
	/// Sample fields worth averaging in the summary record.
	var/static/list/summary_fields = list(
		"cost", "tu", "tks", "pm", "slp",
		"td_c", "td_f", "cpu", "mcpu",
	)

/datum/machines_benchmark/New(duration)
	src.duration = duration
	file_path = "data/machines_benchmark_[time2text(world.realtime, "YYYY-MM-DD_hh.mm.ss")].jsonl"

/datum/machines_benchmark/Destroy()
	deltimer(sample_timer_id)
	deltimer(deep_timer_id)
	if(GLOB.machines_benchmark_run == src)
		GLOB.machines_benchmark_run = null
	return ..()

/datum/machines_benchmark/proc/start()
	started_at = world.time
	end_at = world.time + duration
	fires_at_start = SSmachines.times_fired
	write_header()
	INVOKE_ASYNC(src, PROC_REF(deep_sample)) // capture the starting composition right away
	sample_timer_id = addtimer(CALLBACK(src, PROC_REF(sample)), MACHINES_BENCH_SAMPLE_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)
	deep_timer_id = addtimer(CALLBACK(src, PROC_REF(deep_sample)), MACHINES_BENCH_DEEP_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)

/// Called from SSmachines/fire() for every processed machine while a run is live.
/// tick_delta is in percent-of-tick; negative deltas (tick rollover mid-measurement) are dropped.
/datum/machines_benchmark/proc/record_machine_cost(machine_type, tick_delta)
	if(tick_delta <= 0)
		return
	type_cost_ms[machine_type] += TICK_DELTA_TO_MS(tick_delta)
	type_calls[machine_type] += 1

/datum/machines_benchmark/proc/write_record(list/record)
	rustg_file_append("[json_encode(record)]\n", file_path)

/datum/machines_benchmark/proc/write_header()
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
		"sample_interval_ds" = MACHINES_BENCH_SAMPLE_INTERVAL,
		"deep_interval_ds" = MACHINES_BENCH_DEEP_INTERVAL,
		"ssmachines_wait" = SSmachines.wait,
		"byond" = "[world.byond_version].[world.byond_build]",
		"machines_total" = SSmachines.get_machine_count(),
		"machine_types_total" = SSmachines.get_machine_type_count(),
		"processing_now" = length(SSmachines.processing),
		"sleeping_now" = SSmachines.sleeping_machines,
		"doc" = list(
			"s" = "per-second sample; cost/tu are MC_AVERAGE-smoothed per SSmachines fire",
			"t" = "world.time, deciseconds",
			"fired" = "SSmachines.times_fired",
			"state" = "subsystem state enum (1 idle, 2 queued, 3 running, 4 paused)",
			"cost" = "SSmachines rolling avg cost ms",
			"tu" = "SSmachines rolling avg % of tick used",
			"tks" = "avg MC ticks SSmachines needs to finish one run (backlog indicator)",
			"pm" = "machines on the processing list",
			"slp" = "machines parked in machine_sleep()",
			"pn" = "powernets",
			"td_c" = "time dilation current %",
			"td_f" = "time dilation avg fast %",
			"cpu" = "world.cpu",
			"mcpu" = "world.map_cpu",
			"cl" = "connected clients",
			"deep.census" = "processing-list composition by type at walk time (top [MACHINES_BENCH_TOP_TYPES])",
			"deep.cost_ms" = "fire() ms per machine type, monotonic since run start; diff consecutive deeps for windows",
			"deep.calls" = "process() calls per machine type, monotonic since run start",
		),
	))

/datum/machines_benchmark/proc/sample()
	if(finished)
		return
	if(world.time >= end_at)
		finish("completed")
		return
	var/datum/controller/subsystem/machines/machines = SSmachines
	var/list/record = list(
		"rec" = "s",
		"t" = world.time,
		"fired" = machines.times_fired,
		"state" = machines.state,
		"cost" = round(machines.cost, 0.01),
		"tu" = round(machines.tick_usage, 0.01),
		"tks" = round(machines.ticks, 0.01),
		"pm" = length(machines.processing),
		"slp" = machines.sleeping_machines,
		"pn" = length(machines.powernets),
		"td_c" = round(SStime_track.time_dilation_current, 0.01),
		"td_f" = round(SStime_track.time_dilation_avg_fast, 0.01),
		"cpu" = round(world.cpu, 0.1),
		"mcpu" = round(world.map_cpu, 0.1),
		"cl" = length(GLOB.clients),
	)
	for(var/field in summary_fields)
		var/value = record[field]
		if(isnum(value))
			agg_sum[field] = (agg_sum[field] || 0) + value
			agg_max[field] = max(agg_max[field] || 0, value)
	sample_count++
	write_record(record)

/// Census of the processing list plus a flush of the per-type cost accumulators.
/// Runs off the timer subsystem (InvokeAsync at start), so CHECK_TICK spreads the walk.
/datum/machines_benchmark/proc/deep_sample()
	if(finished)
		return
	var/walk_started = REALTIMEOFDAY
	var/list/census = list()
	var/list/snapshot = SSmachines.processing.Copy()
	for(var/obj/machinery/machine as anything in snapshot)
		if(!machine)
			continue
		census["[machine.type]"]++
		CHECK_TICK
	sortTim(census, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top_census = list()
	for(var/type_key in census)
		if(length(top_census) >= MACHINES_BENCH_TOP_TYPES)
			break
		top_census[type_key] = census[type_key]

	// snapshot the accumulators; stringify typepath keys and round for JSON
	var/list/cost_out = list()
	var/list/calls_out = list()
	for(var/machine_type in type_cost_ms)
		cost_out["[machine_type]"] = round(type_cost_ms[machine_type], 0.01)
	for(var/machine_type in type_calls)
		calls_out["[machine_type]"] = type_calls[machine_type]
	sortTim(cost_out, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)

	if(finished) // the run may have ended while the walk slept
		return
	write_record(list(
		"rec" = "deep",
		"t" = world.time,
		"pm" = length(snapshot),
		"pm_types" = length(census),
		"slp" = SSmachines.sleeping_machines,
		"machines_total" = SSmachines.get_machine_count(),
		"census" = top_census,
		"cost_ms" = cost_out,
		"calls" = calls_out,
		"walk_ms" = (REALTIMEOFDAY - walk_started) * 100,
	))

/datum/machines_benchmark/proc/finish(reason = "completed")
	if(finished)
		return
	finished = TRUE
	deltimer(sample_timer_id)
	deltimer(deep_timer_id)
	var/list/averages = list()
	var/list/maximums = list()
	if(sample_count)
		for(var/field in agg_max)
			averages[field] = round(agg_sum[field] / sample_count, 0.01)
			maximums[field] = agg_max[field]

	var/list/cost_final = list()
	for(var/machine_type in type_cost_ms)
		cost_final["[machine_type]"] = round(type_cost_ms[machine_type], 0.01)
	sortTim(cost_final, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)

	write_record(list(
		"rec" = "summary",
		"t" = world.time,
		"reason" = reason,
		"samples" = sample_count,
		"fires" = SSmachines.times_fired - fires_at_start,
		"duration_ds" = world.time - started_at,
		"avg" = averages,
		"max" = maximums,
		"cost_ms" = cost_final,
	))

	var/list/digest = list("Бенчмарк машинерии завершён ([reason]): [sample_count] сэмплов за [round((world.time - started_at) / (1 MINUTES), 0.1)] мин.")
	if(sample_count)
		digest += "SSmachines cost: avg [averages["cost"]] ms, max [maximums["cost"]] ms. Processing: avg [averages["pm"]], спящих: avg [averages["slp"]]."
		var/list/top_types = list()
		for(var/type_key in cost_final)
			if(length(top_types) >= 8)
				break
			top_types += "[type_key] [cost_final[type_key]] ms"
		if(length(top_types))
			digest += "Топ типов по суммарному fire()-времени: [top_types.Join(", ")]."
	digest += "Файл: [file_path]"
	message_admins(digest.Join("<br>"))
	log_admin("Machines benchmark finished ([reason]): [sample_count] samples -> [file_path]")
	if(GLOB.machines_benchmark_run == src)
		GLOB.machines_benchmark_run = null

#undef MACHINES_BENCH_SAMPLE_INTERVAL
#undef MACHINES_BENCH_DEEP_INTERVAL
#undef MACHINES_BENCH_TOP_TYPES

#endif // ifdef TESTING
