/// Write ping diagnostics every 60 seconds under normal conditions.
#define PING_PERF_LOG_EVERY_TICKS 120
/// Always flush diagnostics early when RTT spikes above this threshold.
#define PING_PERF_SPIKE_RTT_MS 20
/// Always flush diagnostics early when raw glide jitter is unusually high.
#define PING_PERF_SPIKE_JITTER_PCT 8
/// Always flush diagnostics early on visible tick dilation spikes.
#define PING_PERF_SPIKE_TIDI_PCT 5

SUBSYSTEM_DEF(time_track)
	name = "Time Tracking"
	wait = 5
	flags = SS_NO_TICK_CHECK
	init_order = INIT_ORDER_TIMETRACK
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/time_dilation_current = 0

	var/time_dilation_avg_fast = 0
	var/time_dilation_avg = 0
	var/time_dilation_avg_slow = 0

	var/first_run = TRUE

	/// Last realtime value used for per-fire raw multiplier tracking.
	var/last_raw_realtime = 0
	/// Last byond world.time used for per-fire raw multiplier tracking.
	var/last_raw_byond_time = 0

	var/last_tick_realtime = 0
	var/last_tick_byond_time = 0
	var/last_tick_tickcount = 0

	var/raw_multiplier_last = 1
	var/raw_multiplier_jitter_abs_last = 0
	var/raw_multiplier_jitter_abs_avg = 0
	var/raw_multiplier_jitter_abs_max_window = 0
	var/glide_size_multiplier_current = 1
	/// Сглаженное состояние множителя glide, до снапа к единице. Хранится
	/// отдельно от опубликованного: снап в обратной связи съел бы любую
	/// просадку мельче десяти процентов. См. movement_glide_publish().
	var/glide_size_multiplier_smoothed = 1

	var/ping_samples = 0
	var/ping_rtt_last_avg = 0
	/// Медиана последних RTT по миру. Среднее тянет вверх любой одиночный клиент с плохим
	/// каналом, поэтому "типичный пинг" читать надо отсюда.
	var/ping_rtt_last_median = 0
	var/ping_rtt_last_max = 0
	/// Максимум серверной доли пинга, накопленный между строками CSV.
	/// rtt_last_max читают как задержку сервера, а это максимум по худшему клиенту
	/// мира: на проде rtt_last_max/tick_last_max = 1.005, то есть многосекундные
	/// хвосты там целиком чужая сеть. Эта колонка - про нас и только про нас.
	var/ping_server_max_window = 0
	var/ping_rtt_avg_avg = 0
	var/ping_tick_last_avg = 0
	var/ping_tick_last_max = 0
	var/ping_server_last_avg = 0
	var/ping_server_last_max = 0
	var/ping_server_avg_avg = 0

/datum/controller/subsystem/time_track/Initialize(start_timeofday)
	. = ..()
	GLOB.perf_log = "[GLOB.log_directory]/perf-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.config?.map_name].csv"
	GLOB.ping_perf_log = "[GLOB.log_directory]/ping-perf-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.config?.map_name].csv"
	// Про колонку num_timers: это НЕ население колеса таймеров, а только те таймеры,
	// у кого выставлен TIMER_STOPPABLE - timer_id_dict заполняется исключительно для
	// них (см. /datum/timedevent/New в timer.dm). Мудлеты, барки, flick_overlay и
	// амбиент в неё не попадают вообще. Колонку не убираем, по ней сравнивают с
	// историей прошлых раундов, но реальное население смотреть надо в соседних:
	// timer_buckets (bucket_count), timer_second_queue, timer_clienttime, timer_hashes.
	log_perf(
		list(
			"time",
			"players",
			"tidi",
			"tidi_fastavg",
			"tidi_avg",
			"tidi_slowavg",
			"maptick",
			"num_timers",
			"timer_buckets",
			"timer_second_queue",
			"timer_clienttime",
			"timer_hashes",
			"air_turf_cost",
			// Несглаженная стоимость фазы турфов последнего прохода. Раньше здесь
			// стоял auxmos-овский огрызок turf_process_time() - прок без тела,
			// то есть null, то есть пустая строка во всех строках всех логов.
			"air_turf_cost_last",
			"air_equalize_cost",
			"air_post_process_cost",
			"air_eg_cost",
			"air_highpressure_cost",
			"air_hotspots_cost",
			"air_heat_spread_cost",
			"air_pipenets_cost",
			"air_rebuilds_cost",
			"air_amt_gas_mixes",
			"air_alloc_gas_mixes",
			"air_hotspot_count",
			"air_network_count",
			// Сколько турфов фаза высокого давления реально обработала. Длина
			// самой очереди тут бесполезна: фаза съедает список по ходу, и любой
			// сэмплер видит либо ноль, либо случайный срез середины прохода.
			"air_highpressure_processed",
			// Главная величина фазы турфов: её стоимость - это ровно
			// "сколько активных турфов" на "сколько стоит process_cell".
			// Без неё разбор раунда не отличает подорожавшую клетку от
			// разросшегося фронта.
			"air_active_turfs",
			"air_excited_groups",
			"air_superconduct_turfs",
			"air_machinery_count",
			"air_atom_process_count",
			// Вход и выход клапана насыщения. Тайм-дилатация к фоновой
			// подсистеме слепа (MC_TICK_CHECK уступает ровно по бюджету тика,
			// и МК держит свои 20 fps, сколько бы SSair ни ел), поэтому
			// "нагрузка атмоса" - это длина полного прохода, делённая на
			// интервал, в который она обязана была уложиться.
			// air_pass_ms - процессорное время прохода, air_pass_wall_ms - реальное.
			// Они расходятся в пять с лишним раз, потому что МК отдаёт фоновой
			// подсистеме лишь долю остатка тика. Перегрузка живёт во второй
			// величине, и клапан подключён именно к ней.
			"air_pass_ms",
			"air_pass_wall_ms",
			"air_saturation_ratio",
			"air_saturation_scale",
			"air_pass_fire_slices",
			"air_wait",
			// Фаза машинерии не логировалась вообще, а это вторая по размеру
			// статья прохода: разбор раунда 9868 видел её только как разницу
			// между air_pass_ms и суммой остальных колонок (до 11 мс на проход).
			// Вместе с ней сюда же две другие немые фазы.
			"air_machinery_cost",
			"air_decompression_cost",
			"air_atoms_cost",
			// Машины, спящие на сердцебиении, и сети, ждущие сведения. Обе
			// величины - вход в решение "ротация или работа", и обе были видны
			// только из админской верхи.
			"air_machinery_idle",
			"air_dirty_pipenets",
			// Инвариант грязного списка: сеть с поднятым update, потерянная мимо
			// очереди, больше не обсчитается никогда. Обязан быть нулём.
			"air_orphan_dirty_pipenets",
			// Сколько активных турфов реально сдвинули газ. Главная колонка фазы:
			// 307 из 2980 в раунде 9868.
			"air_sharing_turfs",
		)
	)
	log_ping_perf(
		list(
			"time",
			"players",
			"ping_samples",
			"rtt_last_avg",
			"rtt_last_median",
			"rtt_last_max",
			"rtt_avg_avg",
			"tick_last_avg",
			"tick_last_max",
			"server_last_avg",
			"server_last_max",
			"server_avg_avg",
			"server_maint_cleanup_last_ms",
			"server_maint_cleanup_avg_ms",
			"server_maint_cleanup_target",
			"time_dilation_current",
			"maptick",
			"raw_multiplier_last",
			"raw_jitter_abs_last",
			"raw_jitter_abs_avg",
			"raw_jitter_abs_max_window",
			"server_max_window",
			"glide_size_multiplier_current",
		)
	)

/// Сэмпл старше этого считается протухшим и в сводку по миру не идёт.
#define PING_SAMPLE_STALE_AFTER (90 SECONDS)

/datum/controller/subsystem/time_track/proc/update_ping_metrics()
	ping_samples = 0
	ping_rtt_last_avg = 0
	ping_rtt_last_median = 0
	ping_rtt_last_max = 0
	ping_rtt_avg_avg = 0
	ping_tick_last_avg = 0
	ping_tick_last_max = 0
	ping_server_last_avg = 0
	ping_server_last_max = 0
	ping_server_avg_avg = 0

	var/rtt_last_total = 0
	var/rtt_avg_total = 0
	var/tick_last_total = 0
	var/server_last_total = 0
	var/server_avg_total = 0
	var/list/rtt_last_samples = list()

	for(var/client/C as anything in GLOB.clients)
		if(!C || !C.connection_time || (world.time - C.connection_time < 25))
			continue
		// У подвисшего клиента ping-значения остаются последними навсегда, а max() по всем
		// клиентам залипал на них до конца раунда: в прод-логах rtt_last_max держался
		// десятками секунд и повторял одно и то же число в подряд идущих сэмплах.
		if(C.lastping_at && (world.time - C.lastping_at > PING_SAMPLE_STALE_AFTER))
			continue

		var/rtt_last = C.lastping_rtt_raw
		var/rtt_avg = C.avgping_rtt_raw
		var/tick_last = C.lastping_tick
		var/server_last = C.lastping_server
		var/server_avg = C.avgping_server
		if(!rtt_last && C.lastping_rtt)
			rtt_last = C.lastping_rtt
		if(!rtt_avg && C.avgping_rtt)
			rtt_avg = C.avgping_rtt

		// Compatibility fallback for clients that only have legacy ping values populated.
		if(!rtt_last && !rtt_avg && !tick_last && !server_last && !server_avg)
			rtt_last = C.lastping
			rtt_avg = C.avgping
			tick_last = C.lastping
			server_last = 0
			server_avg = 0

		if(!rtt_last && !rtt_avg && !tick_last && !server_last && !server_avg)
			continue

		ping_samples++
		rtt_last_samples += rtt_last
		rtt_last_total += rtt_last
		rtt_avg_total += rtt_avg
		tick_last_total += tick_last
		server_last_total += server_last
		server_avg_total += server_avg

		ping_rtt_last_max = max(ping_rtt_last_max, rtt_last)
		ping_tick_last_max = max(ping_tick_last_max, tick_last)
		ping_server_last_max = max(ping_server_last_max, server_last)
		// Копится через окно, а не сбрасывается каждый вызов: сэмплы приходят чаще,
		// чем пишется CSV, и мгновенный срез терял большую часть значений.
		ping_server_max_window = max(ping_server_max_window, server_last)

	if(!ping_samples)
		return

	ping_rtt_last_avg = rtt_last_total / ping_samples
	// Медиана рядом со средним: один клиент на спутниковом канале сдвигает арифметическое
	// среднее по миру на десятки миллисекунд, и именно это читалось как "у сервера пинг 50мс".
	sortTim(rtt_last_samples, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/median_index = round((length(rtt_last_samples) + 1) * 0.5)
	ping_rtt_last_median = rtt_last_samples[clamp(median_index, 1, length(rtt_last_samples))]
	ping_rtt_avg_avg = rtt_avg_total / ping_samples
	ping_tick_last_avg = tick_last_total / ping_samples
	ping_server_last_avg = server_last_total / ping_samples
	ping_server_avg_avg = server_avg_total / ping_samples

/datum/controller/subsystem/time_track/fire()

	var/current_realtime = REALTIMEOFDAY
	var/current_byondtime = world.time
	var/current_tickcount = world.time/world.tick_lag

	var/raw_multiplier = 1
	if(last_raw_realtime && last_raw_byond_time)
		var/raw_realtime_delta = current_realtime - last_raw_realtime
		if(raw_realtime_delta > 0)
			raw_multiplier = (current_byondtime - last_raw_byond_time) / raw_realtime_delta
	last_raw_realtime = current_realtime
	last_raw_byond_time = current_byondtime

	raw_multiplier_last = raw_multiplier
	raw_multiplier_jitter_abs_last = abs(raw_multiplier - 1) * 100
	raw_multiplier_jitter_abs_avg = raw_multiplier_jitter_abs_avg ? MC_AVERAGE(raw_multiplier_jitter_abs_avg, raw_multiplier_jitter_abs_last) : raw_multiplier_jitter_abs_last
	raw_multiplier_jitter_abs_max_window = max(raw_multiplier_jitter_abs_max_window, raw_multiplier_jitter_abs_last)

	var/candidate = clamp(raw_multiplier, 0.75, 1.25)
	// Серверное время может только отставать от настоящего, никогда не
	// опережать, поэтому raw_multiplier систематически сидит чуть ниже единицы.
	// Без достаточно широкой мёртвой зоны множитель никогда не становится ровно
	// единицей, и выровненный по тику glide превращается обратно в дробный.
	if(abs(candidate - 1) < MOVEMENT_GLIDE_DILATION_DEADBAND)
		candidate = 1
	if(time_dilation_avg_fast < 3)
		candidate = clamp(candidate, 0.9, 1.1)
	// Smooth the multiplier to prevent jerky visual glide transitions during load spikes.
	//
	// Сглаживается сырое состояние, а наружу уходит снапнутое: подмешивать
	// снапнутое обратно нельзя, иначе просадка мельче десяти процентов никогда
	// не накопится. См. movement_glide_publish().
	glide_size_multiplier_smoothed = MC_AVERAGE(glide_size_multiplier_smoothed, candidate)
	GLOB.glide_size_multiplier = movement_glide_publish(glide_size_multiplier_smoothed)
	glide_size_multiplier_current = GLOB.glide_size_multiplier

	if(times_fired % 20)	// everything else is once every 10 seconds (wait=5 * 20 = 100ds)
		return

	if (!first_run)
		var/tick_drift = max(0, (((current_realtime - last_tick_realtime) - (current_byondtime - last_tick_byond_time)) / world.tick_lag))
		var/tickcount_delta = current_tickcount - last_tick_tickcount
		if(tickcount_delta > 0)
			time_dilation_current = tick_drift / tickcount_delta * 100

		time_dilation_avg_fast = MC_AVERAGE_FAST(time_dilation_avg_fast, time_dilation_current)
		time_dilation_avg = MC_AVERAGE(time_dilation_avg, time_dilation_avg_fast)
		time_dilation_avg_slow = MC_AVERAGE_SLOW(time_dilation_avg_slow, time_dilation_avg)
	else
		first_run = FALSE
	last_tick_realtime = current_realtime
	last_tick_byond_time = current_byondtime
	last_tick_tickcount = current_tickcount
	update_ping_metrics()
	SSblackbox.record_feedback("associative", "time_dilation_current", 1, list("[SQLtime()]" = list("current" = "[time_dilation_current]", "avg_fast" = "[time_dilation_avg_fast]", "avg" = "[time_dilation_avg]", "avg_slow" = "[time_dilation_avg_slow]")))
	log_perf(
		list(
			world.time,
			length(GLOB.clients),
			time_dilation_current,
			time_dilation_avg_fast,
			time_dilation_avg,
			time_dilation_avg_slow,
			MAPTICK_LAST_INTERNAL_TICK_USAGE,
			length(SStimer.timer_id_dict),
			SStimer.bucket_count,
			length(SStimer.second_queue),
			length(SStimer.clienttime_timers),
			length(SStimer.hashes),
			SSair.cost_turfs,
			SSair.cost_turfs_last,
			SSair.cost_equalize,
			SSair.cost_post_process,
			SSair.cost_groups,
			SSair.cost_highpressure,
			SSair.cost_hotspots,
			SSair.cost_superconductivity,
			SSair.cost_pipenets,
			SSair.cost_rebuilds,
			SSair.get_amt_gas_mixes(),
			SSair.get_max_gas_mixes(),
			length(SSair.hotspots),
			length(SSair.networks),
			SSair.high_pressure_processed,
			length(SSair.active_turfs),
			length(SSair.excited_groups),
			length(SSair.active_super_conductivity),
			length(SSair.atmos_machinery),
			length(SSair.atom_process),
			SSair.cost_full.last_complete_ms,
			SSair.pass_wall_ds * 100,
			SSair.saturation_ratio,
			SSair.saturation_scale,
			SSair.pass_fire_slices_last,
			SSair.wait,
			SSair.cost_atmos_machinery,
			SSair.cost_decompression,
			SSair.cost_atmos_atoms,
			SSair.idle_machine_count(),
			length(SSair.dirty_networks),
			SSair.count_orphan_dirty_pipenets(),
			SSair.sharing_turfs
		)
	)
	var/should_log_ping_perf = ping_samples && (
		(times_fired % PING_PERF_LOG_EVERY_TICKS == 0) || \
		(ping_rtt_last_max >= PING_PERF_SPIKE_RTT_MS) || \
		(raw_multiplier_jitter_abs_max_window >= PING_PERF_SPIKE_JITTER_PCT) || \
		(time_dilation_current >= PING_PERF_SPIKE_TIDI_PCT)
	)
	if(should_log_ping_perf)
		log_ping_perf(
			list(
				world.time,
				length(GLOB.clients),
				ping_samples,
				ping_rtt_last_avg,
				ping_rtt_last_median,
				ping_rtt_last_max,
				ping_rtt_avg_avg,
				ping_tick_last_avg,
				ping_tick_last_max,
				ping_server_last_avg,
				ping_server_last_max,
				ping_server_avg_avg,
				SSserver_maint.cleanup_last_ms,
				SSserver_maint.cleanup_avg_ms,
				SSserver_maint.cleanup_target_last,
				time_dilation_current,
				MAPTICK_LAST_INTERNAL_TICK_USAGE,
				raw_multiplier_last,
				raw_multiplier_jitter_abs_last,
				raw_multiplier_jitter_abs_avg,
				raw_multiplier_jitter_abs_max_window,
				ping_server_max_window,
				glide_size_multiplier_current,
			)
		)
		raw_multiplier_jitter_abs_max_window = 0
		ping_server_max_window = 0

#undef PING_PERF_LOG_EVERY_TICKS
#undef PING_PERF_SPIKE_RTT_MS
#undef PING_PERF_SPIKE_JITTER_PCT
#undef PING_PERF_SPIKE_TIDI_PCT
