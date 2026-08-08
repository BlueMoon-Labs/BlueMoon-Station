/// A cost counter for resumable, repeating processes (Paradise port).
/// The MC's per-fire cost average hides the true length of a multi-tick pass:
/// a phase that sleeps across 8 ticks reports 8 small slices instead of one
/// real total. record_progress() accumulates slices until the pass finishes.
/datum/resumable_cost_counter
	var/last_complete_ms = 0
	var/ongoing_ms = 0

/// Updates the counter based on the time spent making progress and whether the task finished.
/datum/resumable_cost_counter/proc/record_progress(cost_ms, finished)
	if(finished)
		last_complete_ms = ongoing_ms + cost_ms
		ongoing_ms = 0
	else
		ongoing_ms += cost_ms

/// Display string: last completed pass total, or "<n>+" while an even longer pass is in progress.
/datum/resumable_cost_counter/proc/to_string()
	if(ongoing_ms > last_complete_ms)
		return "[round(ongoing_ms, 1)]+"
	return "[round(last_complete_ms, 1)]"

SUBSYSTEM_DEF(air)
	name = "Atmospherics"
	init_order = INIT_ORDER_AIR
	priority = FIRE_PRIORITY_AIR
	wait = 5
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/cached_cost = 0

	/// Wall-clock cost of one FULL pass through every SSair phase, accumulated
	/// across all the ticks the pass was resumed over. The MC cost column only
	/// shows per-fire slice averages, which systematically understate a pass
	/// that yields a lot.
	var/datum/resumable_cost_counter/cost_full = new()

	var/cost_turfs = 0
	/// Unsmoothed turf-phase cost of the last completed fire, in ms.
	var/cost_turfs_last = 0
	var/cost_groups = 0
	var/cost_highpressure = 0
	var/cost_deferred_airs
	var/cost_hotspots = 0
	var/cost_post_process = 0
	var/cost_superconductivity = 0
	var/cost_pipenets = 0
	var/cost_rebuilds = 0
	var/cost_atmos_machinery = 0
	var/cost_equalize = 0
	var/cost_decompression = 0
	var/cost_atmos_atoms = 0
	var/thread_wait_ticks = 0
	var/cur_thread_wait_ticks = 0

	var/low_pressure_turfs = 0
	var/high_pressure_turfs = 0
	/// Turfs the high pressure phase actually moved things on last fire.
	var/high_pressure_processed = 0

	///Активные турфы, у которых последний process_cell реально сдвинул газ.
	///Считается по ходу фазы турфов, публикуется в perf-лог: стоимость фазы без
	///этого числа не отличает работу от вращения осевших тайлов.
	var/sharing_turfs = 0

	var/num_group_turfs_processed = 0
	var/num_equalize_processed = 0
	var/num_decompression_areas = 0

	var/gas_mixes_count = 0
	var/gas_mixes_allocated = 0

	var/list/hotspots = list()
	///Turfs currently conducting heat through solids (superconduction). Only
	///populated while heat_enabled is set - consider_superconductivity gates it.
	var/list/active_super_conductivity = list()
	var/list/networks = list()
	///Сети, ждущие реконсиляции. Заполняется ТОЛЬКО через
	///[/datum/pipeline/proc/mark_dirty] - список и флаг `update` обязаны ходить
	///парой. Фаза пайпнетов забирает список целиком и обнуляет его; всё, что
	///испачкалось по ходу самой фазы (реакция в трубе, мостовая сеть за открытым
	///клапаном), попадает уже в следующий проход.
	var/list/datum/pipeline/dirty_networks = list()
	var/list/pipenets_needing_rebuilt = list()
	///Сколько машин из pipenets_needing_rebuilt разрешено разобрать за текущий
	///проход фазы ребилда: снапшот длины на входе в фазу. Дозаписанное во время
	///пауз ждёт следующего прохода - иначе непрерывный черн труб (обстрел, RPD)
	///держит SSair в первой фазе, и до симуляции очередь не доходит вовсе.
	var/rebuild_pass_quota = 0
	///Пакеты незавершённых BFS-обходов пайпнетов: list(сеть, граница,
	///посещённые), см. SSAIR_REBUILD_*. Фаза ребилда доедает их с уступкой
	///тика ВНУТРИ обхода - гигантская сеть строится за несколько фаеров,
	///а не одним куском.
	var/list/expansion_queue = list()
	var/list/obj/machinery/atmos_machinery = list()
	///Opt-in atoms maintained by /datum/element/atmos_sensitive.
	var/list/atom_process = list()
	///По одной очереди на ступень отката сердцебиения (см.
	///ATMOS_MACHINE_IDLE_BACKOFF_STEPS). Каждая - assoc "спящая атмос-машина ->
	///world.time её проверки". Машина, досидевшая серию холостых проходов, уходит
	///из atmos_machinery целиком и ждёт здесь. Внутри одной ступени период у всех
	///одинаковый, значит очередь FIFO и проверять надо только голову; ради этого
	///ступени и разведены по разным спискам.
	var/list/list/atmos_idle_queues = list(list(), list(), list(), list())
	///Machines the idle heartbeat returned to processing on the last machinery
	///pass. The heartbeat rotation is a standing share of the machinery phase,
	///so the benchmark records this to split rotation cost from real workers.
	var/heartbeat_wakes_last = 0
	///Benchmark hook: set TRUE to make the next full machinery pass run timed
	///per machine type (profile_machinery_pass). Clears itself; the result
	///lands in benchmark_machinery_profile_result until a sampler consumes it.
	var/benchmark_machinery_profile_pending = FALSE
	///Result of the last profiled machinery pass (see profile_machinery_pass).
	var/list/benchmark_machinery_profile_result
	var/list/pipe_init_dirs_cache = list()

	//atmos singletons
	var/list/gas_reactions = list()
	var/list/atmos_gen
	var/list/planetary = list()
	/// Base areas that saw a significant room-to-space pressure difference.
	/// Associative membership deduplicates every area until the decompression phase.
	var/list/area/decompression_areas = list()
	/// Base area -> world.time of its last handled decompression event. Gates
	/// requeueing so a draining breach fires one alarm sweep per cooldown, not
	/// one per SSair fire.
	var/list/decompression_handled_at = list()
	/// Base area -> номер фаера SSair первого замеченного вент-события. Тревога
	/// ставится только по перевзводу более поздним фаером в пределах
	/// DECOMPRESSION_PENDING_WINDOW_FIRES (см. queue_decompression_area);
	/// протухшие записи снимает уборка декомп-фазы.
	var/list/decompression_pending = list()
	/// Разобранные строки газа: сырая строка -> list(температура, list(газ -> моли)).
	/// См. [/datum/controller/subsystem/air/proc/get_parsed_gas_string].
	var/list/parsed_gas_strings = list()
	//Special functions lists
	var/list/turf/open/high_pressure_delta = list()


	var/list/currentrun = list()
	var/currentpart = SSAIR_REBUILD_PIPENETS

	var/map_loading = TRUE

	var/log_explosive_decompression = TRUE // If things get spammy, admemes can turn this off.

	// Max number of turfs to look for a space turf, and max number of turfs that will be decompressed.
	var/equalize_hard_turf_limit = 2000
	// Whether equalization is enabled. Can be disabled for performance reasons.
	var/equalize_enabled = FALSE
	// With equalize_enabled off, the equalize stage still engages as an adaptive
	// valve while any excited group exceeds EXCITED_GROUP_ZONE_EQUALIZE_THRESHOLD:
	// pure diffusion demonstrably cannot finish a differential that large (the
	// giant-hall bench never settles at ~140ms/fire). Recomputed per stage pass.
	var/equalize_valve_mode = FALSE
	// Sleeping edges (фича-флаг, CONFIG_GET(flag/atmos_sleeping_edges)): осевшие
	// одногрупповые пары турфов кэшируют ревизии смесей и пропускают
	// compare/share, пока оба конца не изменились. Включено по умолчанию
	// (giant-hall A/B нейтрален, осевшая комната -22%/турф-цикл); безопасно
	// переключать на живом мире - кэши инвалидируются ревизиями сами. FALSE
	// здесь - только до чтения конфига в Initialize.
	var/sleeping_edges_enabled = FALSE
	// Whether turf-to-turf heat exchanging should be enabled. Set from
	// CONFIG_GET(flag/atmos_heat_enabled) at init - never write it directly,
	// go through set_heat_enabled() so the pass list cannot outlive the flag.
	var/heat_enabled = FALSE
	// Operator speed lever, from CONFIG_GET(number/atmos_speed_multiplier).
	// This atmos has no share-step loop to scale: one process_cell per turf per
	// fire is the whole simulation step, so the only honest way to make gas move
	// faster is to fire more often. Write it through set_atmos_speed().
	var/atmos_speed = 1
	// Adaptive lag valve, below 1 while the server is dilating. Multiplies the
	// lever, so a fast server that starts lagging lands back near the compiled
	// cadence instead of at either extreme. Written by apply_lag_valve().
	var/lag_scale = 1
	// Adaptive saturation valve, below 1 while a full pass no longer fits in the
	// fire interval. Independent of lag_scale on purpose: time dilation is blind
	// to a saturated background subsystem (see ATMOS_SATURATION_ENGAGE_RATIO),
	// so the two valves watch different failure modes and the cadence takes
	// whichever is more conservative. Written by apply_saturation_valve().
	var/saturation_scale = 1
	/// Реальное (не процессорное) время последнего завершённого прохода,
	/// делённое на НОМИНАЛЬНЫЙ интервал. 1 означает, что проход ровно занял свой
	/// слот. Телеметрия и вход клапана одновременно.
	///
	/// Числитель обязан быть реальным временем. Раньше здесь стояла
	/// `cost_full.last_complete_ms` - сумма процессорных срезов, - и метрика
	/// занижала насыщение в пять с лишним раз: МК отдаёт фоновой подсистеме
	/// только долю остатка тика (около 17-18% по замерам раундов 9864/9865),
	/// поэтому проход, реально растянутый на девять тиков, показывал 0.25.
	/// Знаменатель обязан быть `initial(wait)`, а не текущим: текущий - это
	/// собственный выход клапана, и отсчёт от него делал порог отпускания ВЫШЕ
	/// порога срабатывания.
	var/saturation_ratio = 0
	/// world.time на начале прохода, который сейчас в полёте.
	var/pass_started_at = 0
	/// Реальная длительность последнего ЗАВЕРШЁННОГО прохода, в децисекундах.
	var/pass_wall_ds = 0
	/// Consecutive completed passes that agreed on the same valve direction.
	/// Signed: negative votes slow the cadence down, positive give a step back.
	var/saturation_votes = 0
	/// MC fires the pass currently in flight has been spread over.
	var/pass_fire_slices = 0
	/// The same for the last COMPLETED pass. 1 means the pass fit in one fire;
	/// anything larger is the subsystem running resumed, which is what "atmos
	/// above 100%" looks like from the inside.
	var/pass_fire_slices_last = 0

///Operator-facing speed lever. Values above 1 fire atmos more often; the
///cadence saturates one tick apart, so an absurd multiplier cannot spin the
///subsystem on a zero wait.
/datum/controller/subsystem/air/proc/set_atmos_speed(new_speed)
	atmos_speed = clamp(new_speed, ATMOS_SPEED_MULTIPLIER_MIN, ATMOS_SPEED_MULTIPLIER_MAX)
	apply_atmos_cadence()

///Adaptive valve: a dilating server gets slower atmos instead of a throttle
///that wrote a variable nobody read. Takes the dilation so the decision is
///testable without faking SStime_track.
/datum/controller/subsystem/air/proc/apply_lag_valve(dilation)
	var/new_scale = 1
	if(dilation > ATMOS_LAG_VALVE_SEVERE_DILATION)
		new_scale = ATMOS_LAG_VALVE_SEVERE_SCALE
	else if(dilation > ATMOS_LAG_VALVE_DILATION)
		new_scale = ATMOS_LAG_VALVE_SCALE
	if(new_scale == lag_scale)
		return
	lag_scale = new_scale
	apply_atmos_cadence()

///One step along the shared valve ladder (1 -> 0.75 -> 0.5 and back).
///`direction` below zero slows the cadence down, above zero gives a step back.
///The ladder deliberately stops at ATMOS_LAG_VALVE_SEVERE_SCALE: halving the
///cadence already halves how fast gas moves, and anything past that is a
///balance decision, not a throttle.
/datum/controller/subsystem/air/proc/step_valve_scale(scale, direction)
	if(direction < 0)
		if(scale > ATMOS_LAG_VALVE_SCALE)
			return ATMOS_LAG_VALVE_SCALE
		return ATMOS_LAG_VALVE_SEVERE_SCALE
	if(scale < ATMOS_LAG_VALVE_SCALE)
		return ATMOS_LAG_VALVE_SCALE
	return 1

///Saturation valve: the subsystem watches its own full-pass length instead of a
///server-wide symptom. `wall_ds` is how long one completed pass actually took in
///deciseconds, `cpu_ms` is what it spent on the processor. Both are passed in
///rather than read off state so the decision is testable without faking a pass.
///Returns TRUE when the cadence actually moved.
///
///Замедление каденса - рычаг с узкой областью применимости, и клапан обязан её
///знать. `next_fire = queued_time + wait` отсчитывается от НАЧАЛА прохода, так
///что проход длиннее `wait` доезжает до следующего запуска уже просроченным, и
///подсистема крутится непрерывно. В этом режиме правка `wait` не освобождает
///процессор вообще: в раунде 9864 клапан развёл интервал с 5 до 10 децисекунд, а
///доля атмоса выросла с 20% до 25%, потому что за вдвое более редкий проход
///накапливалось вдвое больше работы. Единственное, что менялось, - газ ехал
///вдвое медленнее, то есть инцидент растягивался.
///
///Отсюда правило: клапан трогает каденс, только пока новый интервал ДЛИННЕЕ
///прохода, - тогда между проходами появляется настоящий простой и другие
///подсистемы получают время. Как только проход перерастает самый медленный
///интервал, который клапану разрешено выставить, удерживать замедление - чистый
///убыток, и клапан отступает сам.
/datum/controller/subsystem/air/proc/apply_saturation_valve(wall_ds, cpu_ms)
	if(cpu_ms <= 0)
		return FALSE // прохода ещё не было, мерить нечего
	// Делим на каденс при НЕЙТРАЛЬНОМ клапане, а не на initial(wait): номинальный
	// слот задаёт ещё и рычаг оператора, и при atmos_speed = 4 он равен 1.25 дс,
	// а не пяти. Со старым знаменателем клапан занижал насыщение ровно во столько
	// раз, во сколько был ускорен атмос, и в раунде 9872 не сработал ни разу за
	// 97 замеров, где проход был втрое длиннее своего слота. Явная единица вместо
	// saturation_scale оставляет выход клапана за пределами его же входа.
	saturation_ratio = wall_ds / max(cadence_for_valve(1), world.tick_lag)
	var/vote = 0
	if(saturation_ratio > ATMOS_SATURATION_ENGAGE_RATIO)
		vote = -1
	else if(saturation_ratio < ATMOS_SATURATION_RELEASE_RATIO)
		vote = 1
	// Замедляться некуда: следующая ступень всё равно короче прохода, простоя не
	// возникнет. Голосуем за шаг назад, а не за бесполезное удержание.
	if(vote < 0 && wall_ds >= cadence_for_valve(step_valve_scale(saturation_scale, -1)))
		vote = 1
	if(!vote)
		// Полоса гистерезиса: каденс держим, а накопленный голос гасим на
		// единицу вместо обнуления. Обнуление означало, что нагрузка, качающаяся
		// вокруг порога, не накапливалась вообще никогда.
		if(saturation_votes > 0)
			saturation_votes--
		else if(saturation_votes < 0)
			saturation_votes++
		return FALSE
	if(saturation_votes * vote < 0)
		saturation_votes = 0
	saturation_votes += vote
	if(abs(saturation_votes) < ATMOS_SATURATION_VOTES)
		return FALSE
	saturation_votes = 0
	var/new_scale = step_valve_scale(saturation_scale, vote)
	if(new_scale == saturation_scale)
		return FALSE
	saturation_scale = new_scale
	apply_atmos_cadence()
	return TRUE

///Recomputes the fire interval from the lever and the valves. The MC reads wait
///when it schedules the next run, so a change lands within one cadence.
///The two valves are combined with min() rather than multiplied: they watch
///different failure modes, and compounding them would drag the cadence to the
///floor the moment both happened to be open at once.
/datum/controller/subsystem/air/proc/apply_atmos_cadence()
	wait = cadence_for_valve(min(lag_scale, saturation_scale))

///Интервал, который дало бы данное положение клапанов. Вынесен отдельно, потому
///что клапану насыщения нужно СПРОСИТЬ про ступень, на которую он ещё только
///собирается шагнуть, не двигая при этом каденс.
/datum/controller/subsystem/air/proc/cadence_for_valve(valve)
	// Потолок адаптивной части: клапаны замедляют газ не более чем вдвое от
	// текущей настроенной скорости. Лестница и так останавливается на 0.5, но
	// зажим держит это свойством кода, а не совпадением констант.
	var/clamped = max(1 / ATMOS_VALVE_SLOWEST_FACTOR, valve)
	var/scale = max(ATMOS_SPEED_MULTIPLIER_MIN, atmos_speed * clamped)
	return clamp(initial(wait) / scale, world.tick_lag, initial(wait) * ATMOS_CADENCE_SLOWEST_FACTOR)

///Проход дошёл до конца: закрываем счётчик процессорного времени и замеряем,
///сколько РЕАЛЬНОГО времени он занял. Клапан насыщения читает именно вторую
///величину, поэтому она обязана сниматься здесь, а не на следующем свежем
///запуске: между концом прохода и следующим запуском подсистема может простаивать,
///и этот простой в длину прохода не входит.
/datum/controller/subsystem/air/proc/finish_pass()
	cost_full.record_progress(0, TRUE)
	pass_wall_ds = max(0, world.time - pass_started_at)

///Затухание стоимости фазы, которая на этом проходе не выполнялась.
///`MC_AVERAGE(x, 0)` в 32-битных float BYOND до нуля не доходит: около
///2.8e-45 умножение на 0.8 округляется обратно в себя, и колонка навсегда
///застревает на денормале вместо честного нуля.
/datum/controller/subsystem/air/proc/decay_idle_cost(cost)
	var/decayed = MC_AVERAGE(cost, 0)
	return decayed < ATMOS_COST_ZERO_EPSILON ? 0 : decayed

/datum/controller/subsystem/air/stat_entry(msg)
	msg += "FC:[cost_full.to_string()]мс "
	msg += "SAT:[round(saturation_ratio, 0.01)]x/[saturation_scale]/[pass_fire_slices_last]сл/[round(pass_wall_ds, 0.1)]дс "
	msg += "C:{HP:[round(cost_highpressure,1)]|HS:[round(cost_hotspots,1)]|SC:[round(cost_superconductivity,1)]|PN:[round(cost_pipenets,1)]|AM:[round(cost_atmos_machinery,1)]|AO:[round(cost_atmos_atoms,1)]} TC:{AT:[round(cost_turfs,1)]|DC:[round(cost_decompression,1)]|EG:[round(cost_groups,1)]|EQ:[round(cost_equalize,1)]|PO:[round(cost_post_process,1)]}TH:[round(thread_wait_ticks,1)]|HS:[hotspots.len]|PN:[networks.len]|RBQ:[pipenets_needing_rebuilt.len]/[expansion_queue.len]|AO:[atom_process.len]|HP:[high_pressure_delta.len]|HT:[high_pressure_turfs]|LT:[low_pressure_turfs]|DA:[num_decompression_areas]|ET:[num_equalize_processed]|GT:[num_group_turfs_processed]|GA:[gas_mixes_count]|MG:[gas_mixes_allocated]"
	return ..()

/datum/controller/subsystem/air/Initialize(timeofday)
	map_loading = FALSE
	setup_allturfs()
	log_roundstart_active_turfs()
	setup_atmos_machinery()
	setup_pipenets()
	gas_reactions = init_gas_reactions()
	atmos_handbooks_init()
	auxtools_update_reactions()
	equalize_enabled = CONFIG_GET(flag/atmos_equalize_enabled)
	sleeping_edges_enabled = CONFIG_GET(flag/atmos_sleeping_edges)
	set_heat_enabled(CONFIG_GET(flag/atmos_heat_enabled))
	set_atmos_speed(CONFIG_GET(number/atmos_speed_multiplier))
	return ..()

/datum/controller/subsystem/air/proc/extools_update_ssair()


/datum/controller/subsystem/air/proc/add_reaction(datum/gas_reaction/r)
	gas_reactions += r
	sortTim(gas_reactions, GLOBAL_PROC_REF(cmp_gas_reaction))
	auxtools_update_reactions()

/proc/reset_all_air()
	SSair.can_fire = 0
	message_admins("Air reset begun.")
	for(var/turf/open/T in world)
		T.Initalize_Atmos(0)
		CHECK_TICK
	message_admins("Air reset done.")
	SSair.can_fire = 1

/proc/fix_corrupted_atmos()

/datum/admins/proc/fixcorruption()
	set category = "Debug.3) Fixing"
	set desc="Fixes air that has weird NaNs (-1.#IND and such). Hopefully."
	set name="Fix Infinite Air"
	fix_corrupted_atmos()

/datum/admins/proc/atmos_active_report()
	set category = "Debug.3) Fixing"
	set desc = "Breakdown of SSair active turfs by z-level and area, for hunting atmos churn."
	set name = "Atmos Active Turfs Report"

	var/list/z_counts = list()
	var/list/area_turfs = list()
	var/planetary_count = 0
	var/grouped_count = 0
	var/sharing_count = 0
	for(var/turf/open/active_turf as anything in SSair.active_turfs)
		if(!istype(active_turf))
			continue
		z_counts["z[active_turf.z]"]++
		var/area/turf_area = active_turf.loc
		var/area_key = "[turf_area.type]"
		var/list/bucket = area_turfs[area_key]
		if(!bucket)
			bucket = list()
			area_turfs[area_key] = bucket
		bucket += active_turf
		if(active_turf.planetary_atmos)
			planetary_count++
		if(active_turf.excited_group)
			grouped_count++
		if(active_turf.air?.last_share > MINIMUM_MOLES_DELTA_TO_MOVE)
			sharing_count++

	var/list/output = list("<b>SSair active turfs: [length(SSair.active_turfs)]</b> (excited groups: [length(SSair.excited_groups)], in groups: [grouped_count], planetary: [planetary_count], actively sharing: [sharing_count])")
	var/list/z_lines = list()
	for(var/z_key in z_counts)
		z_lines += "[z_key]: [z_counts[z_key]]"
	output += "By z-level: [z_lines.Join(", ")]"
	output += "Top areas (count, sharing, planetary, pressure span, temp span):"
	var/shown = 0
	while(shown < 15 && length(area_turfs))
		var/best_key
		var/best_count = 0
		for(var/area_key in area_turfs)
			if(length(area_turfs[area_key]) > best_count)
				best_count = length(area_turfs[area_key])
				best_key = area_key
		var/list/turfs = area_turfs[best_key]
		var/area_sharing = 0
		var/area_planetary = 0
		var/pressure_min = INFINITY
		var/pressure_max = 0
		var/temp_min = INFINITY
		var/temp_max = 0
		for(var/turf/open/area_turf as anything in turfs)
			if(!area_turf.air)
				continue
			if(area_turf.air.last_share > MINIMUM_MOLES_DELTA_TO_MOVE)
				area_sharing++
			if(area_turf.planetary_atmos)
				area_planetary++
			var/pressure = area_turf.air.return_pressure()
			pressure_min = min(pressure_min, pressure)
			pressure_max = max(pressure_max, pressure)
			var/turf_temp = area_turf.air.return_temperature()
			temp_min = min(temp_min, turf_temp)
			temp_max = max(temp_max, turf_temp)
		output += "  [best_count] ([area_sharing] sharing, [area_planetary] planetary, [round(pressure_min, 0.1)]-[round(pressure_max, 0.1)] kPa, [round(temp_min, 0.1)]-[round(temp_max, 0.1)] K) - [best_key]"
		area_turfs -= best_key
		shown++

	to_chat(usr, output.Join("<br>"))

/datum/admins/proc/atmos_heat_toggle()
	set category = "Debug.3) Fixing"
	set desc = "Turn heat conduction through walls, windows and conductive materials on or off for the rest of the round."
	set name = "Toggle Atmos Heat Conduction"

	var/new_state = !SSair.heat_enabled
	SSair.set_heat_enabled(new_state)
	var/message = "[key_name(usr)] turned atmos heat conduction [new_state ? "ON" : "OFF"]."
	log_admin(message)
	message_admins(message)
	to_chat(usr, "Heat conduction is now [new_state ? "enabled" : "disabled"]. Turfs in the conduction pass: [length(SSair.active_super_conductivity)].")

/datum/controller/subsystem/air/fire(resumed = 0)
	var/timer = TICK_USAGE_REAL
	#ifdef ATMOS_HEADLESS_BENCH
	if(resumed)
		headless_bench_mc_slices++
	else
		headless_bench_mc_slices = 1
	#endif

	if(resumed)
		pass_fire_slices++
	else
		// A fresh fire means the previous pass ended: publish how many MC slices
		// it needed and let both valves look at it.
		pass_fire_slices_last = pass_fire_slices
		pass_fire_slices = 1
		// Adaptive valve: a dilating server gets a slower atmos cadence, which is
		// the only lever this simulation actually has.
		if(SStime_track?.initialized)
			apply_lag_valve(SStime_track.time_dilation_avg_fast)
		// Saturation valve: the dilation counters above are structurally blind to
		// a background subsystem that yields politely at the tick limit and then
		// resumes on the next tick forever. The wall clock is not.
		apply_saturation_valve(pass_wall_ds, cost_full.last_complete_ms)
		pass_started_at = world.time

	thread_wait_ticks = MC_AVERAGE(thread_wait_ticks, cur_thread_wait_ticks)
	cur_thread_wait_ticks = 0

	gas_mixes_count = get_amt_gas_mixes()
	gas_mixes_allocated = get_max_gas_mixes()

	if(currentpart == SSAIR_REBUILD_PIPENETS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_rebuild_queue(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_rebuilds = MC_AVERAGE(cost_rebuilds, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_PIPENETS

	if(currentpart == SSAIR_PIPENETS || !resumed)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_pipenets(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_pipenets = MC_AVERAGE(cost_pipenets, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		currentpart = SSAIR_ATMOSMACHINERY

	if(currentpart == SSAIR_ATMOSMACHINERY)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_atmos_machinery(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		resumed = 0
		cost_atmos_machinery = MC_AVERAGE(cost_atmos_machinery, TICK_DELTA_TO_MS(cached_cost))
		currentpart = SSAIR_ACTIVETURFS

	if(currentpart == SSAIR_ACTIVETURFS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_turfs(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		// Unsmoothed cost of the turf phase for the fire that just finished.
		// MC_AVERAGE flattens spikes by roughly 5x, so the smoothed column cannot
		// answer "how bad was the worst single pass" - and that is the number a
		// profiler has to be checked against.
		cost_turfs_last = TICK_DELTA_TO_MS(cached_cost)
		cost_turfs = MC_AVERAGE(cost_turfs, cost_turfs_last)
		resumed = 0
		currentpart = SSAIR_DECOMPRESSION

	if(currentpart == SSAIR_DECOMPRESSION)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_decompression_areas(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		// The saturation valve reads cost_full as "how long is a whole pass", so
		// every phase has to report into it, cheap ones included.
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_decompression = MC_AVERAGE(cost_decompression, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		// The valve check keeps the stage reachable with the config flag off:
		// a giant excited group means diffusion alone will not finish the job.
		// Обход зоны в полёте держит стадию открытой сам по себе: он растянут на
		// несколько фаеров, и захлопнуть клапан под ним значило бы бросить зону
		// полусведённой, а его состояние - висеть со ссылками на две тысячи
		// турфов до конца раунда.
		if(equalize_enabled || zone_walk?.stage || has_zone_equalize_candidate())
			currentpart = SSAIR_EQUALIZE
		else
			// Skipping the stage still has to be reported as costing nothing.
			// Leaving the average untouched froze it at whatever the last real
			// pass cost - a round that equalized once at the four-minute mark
			// then showed a flat 1.8ms of phantom equalize work for five hours.
			cost_equalize = decay_idle_cost(cost_equalize)
			num_equalize_processed = 0
			currentpart = SSAIR_EXCITEDGROUPS

	if(currentpart == SSAIR_EQUALIZE)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_turf_equalize(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_equalize = MC_AVERAGE(cost_equalize, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		currentpart = SSAIR_EXCITEDGROUPS

	if(currentpart == SSAIR_EXCITEDGROUPS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_excited_groups(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_groups = MC_AVERAGE(cost_groups, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		currentpart = SSAIR_FINALIZE_TURFS

	if(currentpart == SSAIR_FINALIZE_TURFS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		finish_turf_processing(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_post_process = MC_AVERAGE(cost_post_process, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		currentpart = SSAIR_ATOMS

	if(currentpart == SSAIR_ATOMS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_atmos_atoms(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_atmos_atoms = MC_AVERAGE(cost_atmos_atoms, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_HIGHPRESSURE

	if(currentpart == SSAIR_HIGHPRESSURE)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_high_pressure_delta(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_highpressure = MC_AVERAGE(cost_highpressure, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		currentpart = SSAIR_HOTSPOTS

	if(currentpart == SSAIR_HOTSPOTS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_hotspots(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_hotspots = MC_AVERAGE(cost_hotspots, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		if(!heat_enabled)
			// Same reason as the skipped equalize stage above: a stage that did
			// not run costs nothing, and saying so is the only way the column
			// ever comes back down after the admin switch goes off.
			cost_superconductivity = decay_idle_cost(cost_superconductivity)
			finish_pass()
		currentpart = heat_enabled ? SSAIR_TURF_CONDUCTION : SSAIR_REBUILD_PIPENETS

	// Heat through solids. Nothing registers below MINIMUM_TEMPERATURE_START_SUPERCONDUCTION,
	// so a station at room temperature skips this stage with an empty list.
	if(currentpart == SSAIR_TURF_CONDUCTION)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		if(process_turf_heat(TICK_REMAINING_MS))
			pause()
		// accumulate across resumes: a multi-tick conduction pass must average
		// its full cost, not just the final (usually tiny) slice
		cached_cost += TICK_USAGE_REAL - timer
		cost_full.record_progress(TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer), FALSE)
		if(state != SS_RUNNING)
			return
		cost_superconductivity = MC_AVERAGE(cost_superconductivity, TICK_DELTA_TO_MS(cached_cost))
		resumed = 0
		finish_pass()
		currentpart = SSAIR_REBUILD_PIPENETS

/datum/controller/subsystem/air/proc/process_rebuild_queue(resumed = FALSE)
	if(!resumed)
		rebuild_pass_quota = length(pipenets_needing_rebuilt)
	// Пакеты расширения доедаются по живому списку: build_network() машины
	// рождает пакет, и его надо доесть раньше следующей машины, иначе пакеты
	// множатся без предела, а сети стоят недостроенными. Машины же ограничены
	// квотой прохода: дозаписи во время пауз копятся в живой список, и без
	// квоты фаза кончалась бы только с полным осушением обеих очередей.
	while((rebuild_pass_quota > 0 && length(pipenets_needing_rebuilt)) || length(expansion_queue))
		while(rebuild_pass_quota > 0 && length(pipenets_needing_rebuilt) && !length(expansion_queue))
			var/obj/machinery/atmospherics/machine = pipenets_needing_rebuilt[length(pipenets_needing_rebuilt)]
			pipenets_needing_rebuilt.len--
			rebuild_pass_quota--
			if(machine)
				machine.rebuild_queued = FALSE
				if(!QDELETED(machine))
					machine.build_network()
			if(MC_TICK_CHECK)
				return
		while(length(expansion_queue))
			var/list/packet = expansion_queue[length(expansion_queue)]
			var/datum/pipeline/net = packet[SSAIR_REBUILD_PIPELINE]
			if(QDELETED(net))
				expansion_queue.len--
				continue
			if(!expand_pipeline(net, packet[SSAIR_REBUILD_BORDER], packet[SSAIR_REBUILD_SEEN]))
				// Кончился бюджет тика посреди обхода: MC_TICK_CHECK внутри уже
				// поставил подсистему на паузу, состояние осталось в пакете.
				return
			net.finish_building()
			expansion_queue.len--
			if(MC_TICK_CHECK)
				return

///Шаг BFS-обхода пайпнета, общий для очереди расширения и блокирующего
///построения. Живёт на подсистеме, а не на сети: MC_TICK_CHECK читает
///src.state. Возвращает TRUE, когда граница исчерпана; FALSE - тик кончился
///(только при yield), обход продолжится со следующего фаера с того же места.
/datum/controller/subsystem/air/proc/expand_pipeline(datum/pipeline/net, list/border, list/seen_members, yield = TRUE)
	while(length(border))
		var/obj/machinery/atmospherics/borderline = border[length(border)]
		border.len--
		if(QDELETED(borderline))
			continue

		var/list/result = borderline.pipeline_expansion(net)
		if(!length(result))
			continue

		// Implicit-typed `for X in list` filters nulls AND non-atmos entries —
		// /obj/machinery/atmospherics/components/pipeline_expansion returns
		// `list(nodes[…])` and that slot is null on disconnected components.
		// Skipping the filter (e.g. via `as anything`) reaches setPipenet on
		// null and crashes during SSair pipenet setup.
		for(var/obj/machinery/atmospherics/P in result)
			if(istype(P, /obj/machinery/atmospherics/pipe))
				var/obj/machinery/atmospherics/pipe/item = P
				// O(1) membership probe replacing the O(M) members.Find call
				// that made the BFS quadratic on large pipenets.
				if(seen_members[item])
					continue
				seen_members[item] = TRUE

				if(item.parent)
					var/static/pipenetwarnings = 10
					if(pipenetwarnings > 0)
						log_mapping("build_pipeline(): [item.type] added to a pipenet while still having one. (pipes leading to the same spot stacking in one turf) Nearby: ([item.x], [item.y], [item.z]).")
						pipenetwarnings -= 1
						if(pipenetwarnings == 0)
							log_mapping("build_pipeline(): further messages about pipenets will be suppressed")
				net.track_member(item)
				border += item

				net.air.set_volume(net.air.return_volume() + item.volume)
				item.parent = net

				if(item.air_temporary)
					net.air.merge(item.air_temporary)
					QDEL_NULL(item.air_temporary)
			else
				P.setPipenet(net, borderline)
				net.addMachineryMember(P)
		if(yield && MC_TICK_CHECK)
			return FALSE
	return TRUE

///Ставит недостроенную сеть в очередь расширения фазы ребилда.
/datum/controller/subsystem/air/proc/add_to_expansion(datum/pipeline/net, obj/machinery/atmospherics/base, list/seen_members)
	var/list/packet = new /list(SSAIR_REBUILD_SEEN)
	packet[SSAIR_REBUILD_PIPELINE] = net
	packet[SSAIR_REBUILD_BORDER] = list(base)
	packet[SSAIR_REBUILD_SEEN] = seen_members
	expansion_queue += list(packet)

///Снимает пакет сети с очереди расширения (Destroy недостроенной сети).
/datum/controller/subsystem/air/proc/remove_from_expansion(datum/pipeline/net)
	for(var/list/packet in expansion_queue)
		if(packet[SSAIR_REBUILD_PIPELINE] == net)
			expansion_queue -= list(packet)
			return

///Синхронно доедает обход одной сети, минуя бюджет тика. Единственный
///клиент - /datum/pipeline/proc/ensure_built.
/datum/controller/subsystem/air/proc/finish_expansion_blocking(datum/pipeline/net)
	for(var/list/packet in expansion_queue)
		if(packet[SSAIR_REBUILD_PIPELINE] != net)
			continue
		expansion_queue -= list(packet)
		expand_pipeline(net, packet[SSAIR_REBUILD_BORDER], packet[SSAIR_REBUILD_SEEN], yield = FALSE)
		net.finish_building()
		return
	// Сеть числится строящейся, а пакета нет: инвариант "building ⟺ пакет в
	// очереди" сломан. Флаг всё равно надо снять, иначе сеть навсегда выпадет
	// из сведения - process() так и будет гонять её по кругу.
	stack_trace("finish_expansion_blocking(): building pipeline [net]([REF(net)]) has no expansion packet")
	net.finish_building()

/datum/controller/subsystem/air/proc/process_pipenets(resumed = 0)
	if (!resumed)
		// Забираем список целиком и сразу отдаём mark_dirty() чистый: сеть,
		// испачкавшаяся во время самой фазы, обязана попасть в СЛЕДУЮЩИЙ проход,
		// а не быть потерянной вместе со снимком.
		src.currentrun = dirty_networks
		dirty_networks = list()
		// Реестр сетей раньше подчищался от нулей побочным эффектом: фаза шла по
		// нему целиком и выкидывала пустые слоты по дороге. Грязный список по
		// нему больше не ходит, поэтому редкая уборка своим ходом - жёсткое
		// удаление (не qdel) сети оставляет нуль, а он живёт в реестре вечно и
		// врёт колонке air_network_count.
		if(!(times_fired % PIPENET_REGISTRY_SWEEP_INTERVAL))
			listclearnulls(networks)
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/datum/pipeline/net = currentrun[currentrun.len]
		currentrun.len--
		if(net)
			net.process()
		else
			networks.Remove(net)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/add_to_rebuild_queue(obj/machinery/atmospherics/atmos_machine)
	// Флаг вместо `in`-скана: взрыв сыплет сотни добавлений за тик, и линейный
	// поиск по очереди делал их квадратными.
	if(istype(atmos_machine) && !atmos_machine.rebuild_queued)
		pipenets_needing_rebuilt += atmos_machine
		atmos_machine.rebuild_queued = TRUE

/datum/controller/subsystem/air/proc/process_atmos_machinery(resumed = 0)
	var/seconds = wait * 0.1
	if (!resumed)
		heartbeat_wakes_last = wake_expired_idle_machines()
		if(benchmark_machinery_profile_pending)
			// The profiled pass IS this fire's machinery pass: same machines,
			// same semantics, just timed per type. One deliberately unyielding
			// fire per deep interval while a benchmark runs.
			benchmark_machinery_profile_pending = FALSE
			benchmark_machinery_profile_result = profile_machinery_pass(seconds)
			return
		src.currentrun = atmos_machinery.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/obj/machinery/M = currentrun[currentrun.len]
		currentrun.len--
		if(!M)
			atmos_machinery -= M
		else if(M.process_atmos(seconds) == PROCESS_KILL)
			stop_processing_machine(M, popped_from_currentrun = TRUE)
		if(MC_TICK_CHECK)
			return

///Returns sleeping machines whose heartbeat deadline expired to the processing
///list for one full recheck (a no-op pass puts them straight back to sleep).
///Returns how many machines it woke, so the benchmark can attribute the
///standing rotation share of the machinery phase.
///
///Один проход по каждой ступени отката. Внутри ступени очередь остаётся строго
///FIFO - все её записи ждали ОДИН И ТОТ ЖЕ период, - поэтому проверять по-прежнему
///достаточно голову. Единая очередь с разными периодами это свойство теряет: одна
///запись с двухминутным дедлайном во главе заперла бы за собой всех, кому пора.
/datum/controller/subsystem/air/proc/wake_expired_idle_machines()
	var/woken = 0
	for(var/list/tier_queue as anything in atmos_idle_queues)
		var/expired = 0
		for(var/i in 1 to tier_queue.len)
			var/obj/machinery/atmospherics/machine = tier_queue[i]
			if(!machine)
				// Hard deletion nulls list entries in place; drop the slot.
				expired = i
				continue
			if(tier_queue[machine] > world.time)
				break
			expired = i
			machine.atmos_idle_queued = FALSE
			machine.atmos_idle_tier = 0
			if(QDELETED(machine) || machine.atmos_processing)
				continue
			start_processing_machine(machine)
			woken++
		if(expired)
			tier_queue.Cut(1, expired + 1)
	return woken

///Сколько машин сейчас спит на сердцебиении, по всем ступеням отката.
/datum/controller/subsystem/air/proc/idle_machine_count()
	var/count = 0
	for(var/list/tier_queue as anything in atmos_idle_queues)
		count += length(tier_queue)
	return count

///Плоский список спящих машин. Только для диагностики и бенчмарков - горячие
///пути обязаны ходить по ступеням, а не собирать копию всей карты.
/datum/controller/subsystem/air/proc/idle_machine_list()
	var/list/machines = list()
	for(var/list/tier_queue as anything in atmos_idle_queues)
		for(var/obj/machinery/atmospherics/machine as anything in tier_queue)
			machines += machine
	return machines

///Спит ли машина на сердцебиении. Спрашивает сами очереди, а не флаг на машине:
///расхождение этих двух источников - ровно тот дефект, который проверки ищут.
/datum/controller/subsystem/air/proc/idle_machine_queued(obj/machinery/atmospherics/machine)
	for(var/list/tier_queue as anything in atmos_idle_queues)
		if(!isnull(tier_queue[machine]))
			return TRUE
	return FALSE

///One fully-timed machinery pass bucketed by machine type, standing in for a
///normal pass when the benchmark armed benchmark_machinery_profile_pending.
///Keeps normal semantics (PROCESS_KILL leaves the list, stale nulls dropped)
///but runs the whole list without MC yields so the per-type numbers describe
///one coherent fire. Returns list(n, np, ms, hbw, types = type -> (n, ms)).
/datum/controller/subsystem/air/proc/profile_machinery_pass(seconds)
	var/list/type_buckets = list()
	var/total_ms = 0
	var/machine_count = 0
	var/nopower_count = 0
	for(var/obj/machinery/M as anything in atmos_machinery.Copy())
		if(!M)
			atmos_machinery -= M
			continue
		machine_count++
		if(M.machine_stat & NOPOWER)
			nopower_count++
		var/type_key = "[M.type]"
		var/list/bucket = type_buckets[type_key]
		if(!bucket)
			bucket = list("n" = 0, "ms" = 0)
			type_buckets[type_key] = bucket
		var/timer = TICK_USAGE_REAL
		var/process_result = M.process_atmos(seconds)
		var/spent_ms = TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer)
		bucket["n"] += 1
		bucket["ms"] += spent_ms
		total_ms += spent_ms
		if(process_result == PROCESS_KILL)
			stop_processing_machine(M)
	for(var/type_key in type_buckets)
		var/list/bucket = type_buckets[type_key]
		bucket["ms"] = round(bucket["ms"], 0.001)
	return list(
		"n" = machine_count,
		"np" = nopower_count,
		"ms" = round(total_ms, 0.01),
		"hbw" = heartbeat_wakes_last,
		"types" = type_buckets,
	)

///Pipenets whose update flag is set right now - each reconciles on its next
///process(). Benchmark decomposition helper for cost_pipenets.
/datum/controller/subsystem/air/proc/count_dirty_pipenets()
	var/count = 0
	for(var/datum/pipeline/net as anything in networks)
		if(net?.update)
			count++
	return count

///Сети с поднятым `update`, которых нет ни в очереди, ни в текущем прогоне фазы.
///Инвариант обязан держать ноль: такая сеть не обсчитается никогда, то есть газ
///в ней встанет намертво. Диагностика для бенчмарка и юнит-теста - это цена
///перехода фазы пайпнетов с обхода всех сетей на грязный список.
/datum/controller/subsystem/air/proc/count_orphan_dirty_pipenets()
	// Множество членства строится один раз: наивная проверка `in` по двум
	// спискам превратила бы диагностику в квадрат по числу сетей.
	var/list/queued = list()
	for(var/datum/pipeline/net as anything in dirty_networks)
		queued[net] = TRUE
	if(currentpart == SSAIR_PIPENETS)
		for(var/datum/pipeline/net as anything in currentrun)
			queued[net] = TRUE
	var/count = 0
	for(var/datum/pipeline/net as anything in networks)
		if(net?.update && !queued[net])
			count++
	return count

/datum/controller/subsystem/air/proc/process_hotspots(resumed = 0)
	if (!resumed)
		src.currentrun = hotspots.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/obj/effect/hotspot/H = currentrun[currentrun.len]
		currentrun.len--
		if (H)
			H.process()
		else
			hotspots -= H
		if(MC_TICK_CHECK)
			return


/datum/controller/subsystem/air/proc/process_high_pressure_delta(resumed = 0)
	// The phase consumes the list as it goes, so by the time any sampler runs
	// the length is always zero and the recorded queue size was meaningless.
	// Capture the real workload here instead.
	if(!resumed)
		high_pressure_processed = length(high_pressure_delta)
	while (high_pressure_delta.len)
		var/turf/open/T = high_pressure_delta[high_pressure_delta.len]
		high_pressure_delta.len--
		// ChangeTurf подменяет турф под уже стоящей в очереди записью, и на её
		// месте оказывается стена. high_pressure_movements() объявлен только на
		// /turf/open, поэтому вызов падал "undefined proc" - разгерметизация
		// рядом со снесённой стеной ловила это на ровном месте. Сама запись
		// после подмены бессмысленна: двигать нечего, вектор чистить не у чего.
		if(!istype(T))
			continue
		T.high_pressure_queued = FALSE
		T.high_pressure_movements()
		T.pressure_difference = 0
		T.pressure_vector_x = 0
		T.pressure_vector_y = 0
		T.pressure_direction = NONE
		T.pressure_specific_target = null
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_atmos_atoms(resumed = FALSE)
	if(!resumed)
		src.currentrun = atom_process.Copy()
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/atom/target = currentrun[currentrun.len]
		currentrun.len--
		if(target)
			target.process_exposure()
		else
			atom_process -= target
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_turf_equalize(resumed = 0)
	if(process_turf_equalize_auxtools(TICK_REMAINING_MS))
		pause()

/datum/controller/subsystem/air/proc/process_decompression_areas(resumed = 0)
	if(process_decompression_areas_auxtools(resumed))
		pause()

/datum/controller/subsystem/air/proc/process_turfs(resumed = 0)
	if(process_turfs_auxtools(TICK_REMAINING_MS))
		pause()

/datum/controller/subsystem/air/proc/process_excited_groups(resumed = 0)
	if(process_excited_groups_auxtools(TICK_REMAINING_MS))
		pause()

/datum/controller/subsystem/air/proc/finish_turf_processing(resumed = 0)
	if(finish_turf_processing_auxtools(TICK_REMAINING_MS))
		pause()
	#ifdef ATMOS_HEADLESS_BENCH
	else
		atmos_headless_bench_tick()
	#endif

/datum/controller/subsystem/air/proc/equalize_turfs(resumed = 0)
	if(equalize_turfs_auxtools(TICK_REMAINING_MS))
		pause()

/datum/controller/subsystem/air/proc/post_process_turfs(resumed = 0)
	if(post_process_turfs_auxtools(TICK_REMAINING_MS))
		pause()

/datum/controller/subsystem/air/proc/equalize_turfs_auxtools()
/datum/controller/subsystem/air/proc/post_process_turfs_auxtools()
///Superconduction pass: every listed turf conducts with its solid borders and
///drops off the list once it cools below the sustain threshold. Returns TRUE
///when out of tick budget so the SSAIR_TURF_CONDUCTION stage pauses.
/datum/controller/subsystem/air/proc/process_turf_heat(remaining)
	if(!length(currentrun))
		currentrun = active_super_conductivity.Copy()
	var/list/currentrun_copy = currentrun
	while(currentrun_copy.len)
		var/turf/conducting_turf = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(istype(conducting_turf))
			conducting_turf.super_conduct()
		// Only pause while there is work left: this phase re-Copies the pass list
		// whenever currentrun is empty, so pausing on the last turf would conduct
		// the whole list a second time on the next fire.
		if(currentrun_copy.len && world.tick_usage > Master.current_ticklimit)
			return TRUE
	// Shared currentrun slot: do not leak turf entries into the next stage.
	currentrun = list()
	return FALSE

///Single funnel for the superconduction switch: config at init, admin verb at
///runtime. Turning it off has to be clean - a populated pass list pins its
///turfs for the rest of the round, and a conduction run caught mid-resume would
///keep conducting after the flag went down.
/datum/controller/subsystem/air/proc/set_heat_enabled(new_state)
	new_state = !!new_state
	if(heat_enabled == new_state)
		return
	heat_enabled = new_state
	if(new_state)
		return
	active_super_conductivity.Cut()
	if(is_in_conduction_phase())
		currentrun = list()
		currentpart = SSAIR_REBUILD_PIPENETS

///Whether the subsystem is parked in the conduction stage right now.
/datum/controller/subsystem/air/proc/is_in_conduction_phase()
	return currentpart == SSAIR_TURF_CONDUCTION

// Тот же гейт, что у самих тестов: dreamchecker собирает их под SPACEMAN_DMM
// без UNIT_TESTS, и под одним #ifdef UNIT_TESTS этот прок для него не
// существовал - линтер падал на вызове из atmos_superconduction.dm.
#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
///Test scaffolding: the stage constants are undef'd at the end of this file, so
///a test cannot park the subsystem in the conduction stage on its own.
/datum/controller/subsystem/air/proc/enter_conduction_phase_for_test()
	currentpart = SSAIR_TURF_CONDUCTION
	currentrun = active_super_conductivity.Copy()

///Test scaffolding: делает дедлайн сердцебиения уже наступившим. Очередь ступени
///FIFO по дедлайну, поэтому "наступил" означает ещё и "в голове" - машины живой
///станции с будущими дедлайнами стоят впереди.
/datum/controller/subsystem/air/proc/expire_idle_machine_for_test(obj/machinery/atmospherics/machine)
	for(var/list/tier_queue as anything in atmos_idle_queues)
		if(isnull(tier_queue[machine]))
			continue
		tier_queue.Remove(machine)
		tier_queue.Insert(1, machine)
		tier_queue[machine] = world.time - 1
		return TRUE
	return FALSE
#endif

/datum/controller/subsystem/air/StartLoadingMap()
	map_loading = TRUE

/datum/controller/subsystem/air/StopLoadingMap()
	map_loading = FALSE

/datum/controller/subsystem/air/proc/setup_allturfs()
	var/list/turfs_to_init = block(locate(1, 1, 1), locate(world.maxx, world.maxy, world.maxz))
	var/times_fired = ++src.times_fired

	// Clear active turfs - faster than removing every single turf in the world
	// one-by-one, and Initalize_Atmos only ever adds `src` back in.

	for(var/thing as anything in turfs_to_init)
		var/turf/T = thing
		if (T.blocks_air)
			continue
		T.Initalize_Atmos(times_fired)
		CHECK_TICK

	// Роундстартовое обнаружение замапленных градиентов у планетарных границ.
	// Класть в очередь КАЖДЫЙ планетарный турф (как делал update_air_ref до
	// оптимизации) нельзя: 93.5k записей, из которых живых полторы тысячи, и
	// весь холостой хвост разгребался ровно на спавне игроков. Но и не класть
	// никого - значит заморозить устье пещеры или замапленный пролом до первого
	// постороннего тычка. Здесь воздух каждого турфа только что собран из его же
	// initial_gas_mix, поэтому градиент существует ровно там, где строки смеси
	// соседей различаются, - сами смеси сравнивать не нужно. Небо-к-небу (98%
	// планетарных пар) отсеивается одним сравнением строк.
	for(var/thing as anything in turfs_to_init)
		var/turf/open/planetary_turf = thing
		if(!istype(planetary_turf) || !planetary_turf.planetary_atmos || planetary_turf.blocks_air || !planetary_turf.air)
			continue
		for(var/turf/open/neighbor as anything in planetary_turf.atmos_adjacent_turfs)
			if(neighbor.initial_gas_mix == planetary_turf.initial_gas_mix)
				continue
			// Смена ссылки газ не двигала: цикл на сверку нужен, окно отдыха - нет.
			add_to_active(planetary_turf, FALSE, reset_stall = FALSE)
			break
		CHECK_TICK

/// Максимум построчных записей роундстартовых активных турфов в mapping-лог:
/// свежая большая карта держит ~5k стартовых активов, и полный список без капа
/// раздувает лог; хвост срезается с явной пометкой.
#define ROUNDSTART_ACTIVE_TURF_LOG_CAP 3000

/// Роундстартовый снимок активных турфов (адаптация tg d43ebd042dd): заполняет
/// GLOB.active_turfs_startlist - его читают админ-вербы "Show roundstart AT
/// list/markers" - и пишет каждый турф с координатами и зоной в mapping-лог.
/// Активный турф на старте - это замапленный градиент (пара соседей с разными
/// initial_gas_mix, дыра в обшивке, планетарная граница): каждая такая пара -
/// постоянная фоновая работа SSair до конца раунда, снимаемая правкой карты.
/datum/controller/subsystem/air/proc/log_roundstart_active_turfs()
	GLOB.active_turfs_startlist = active_turfs.Copy()
// В CI лог только шумит: тестовые карты намеренно держат активные градиенты
// (та же уступка, что у tg), а читать mapping-лог там некому.
#ifndef UNIT_TESTS
	if(!length(active_turfs))
		log_mapping("Roundstart active turfs: none.")
		return
	var/list/z_tally = list()
	var/logged = 0
	for(var/turf/open/active_turf as anything in active_turfs)
		if(!istype(active_turf))
			continue
		z_tally["z[active_turf.z]"]++
		if(logged >= ROUNDSTART_ACTIVE_TURF_LOG_CAP)
			continue
		logged++
		var/area/turf_area = active_turf.loc
		log_mapping("ACTIVE TURF: [active_turf] ([active_turf.x],[active_turf.y],[active_turf.z]) in [turf_area.type][active_turf.planetary_atmos ? " (planetary)" : ""]")
		CHECK_TICK
	log_mapping("Roundstart active turfs: [length(active_turfs)] total[logged < length(active_turfs) ? ", first [logged] listed (cap [ROUNDSTART_ACTIVE_TURF_LOG_CAP])" : ""]. By z-level: [json_encode(z_tally)]. Use \"Mapping -> Show roundstart AT list/markers\" in-round; every listed turf is a mapped-in gradient fixable on the map.")
#endif

#undef ROUNDSTART_ACTIVE_TURF_LOG_CAP

/datum/controller/subsystem/air/proc/setup_atmos_machinery()
	for (var/obj/machinery/atmospherics/AM in atmos_machinery)
		AM.atmosinit()
		CHECK_TICK

//this can't be done with setup_atmos_machinery() because
//	all atmos machinery has to initalize before the first
//	pipenet can be built.
/datum/controller/subsystem/air/proc/setup_pipenets()
	for (var/obj/machinery/atmospherics/AM in atmos_machinery)
		AM.build_network(blocking = TRUE)
		CHECK_TICK

/datum/controller/subsystem/air/proc/setup_template_machinery(list/atmos_machines)
	if(!initialized) // yogs - fixes randomized bars
		return // yogs
	for(var/A as anything in atmos_machines)
		var/obj/machinery/atmospherics/AM = A
		AM.atmosinit()
		CHECK_TICK

	for(var/A as anything in atmos_machines)
		var/obj/machinery/atmospherics/AM = A
		// Блокирующее построение: код загрузки шаблонов (шаттлы, руины, комнаты
		// Хилберта) ждёт рабочие сети сразу за этим циклом, а бюджет тика здесь
		// и так растянут через CHECK_TICK.
		AM.build_network(blocking = TRUE)
		CHECK_TICK

/datum/controller/subsystem/air/proc/get_init_dirs(type, dir)
	if(!pipe_init_dirs_cache[type])
		pipe_init_dirs_cache[type] = list()

	if(!pipe_init_dirs_cache[type]["[dir]"])
		var/obj/machinery/atmospherics/temp = new type(null, FALSE, dir)
		pipe_init_dirs_cache[type]["[dir]"] = temp.GetInitDirections()
		qdel(temp)

	return pipe_init_dirs_cache[type]["[dir]"]

/datum/controller/subsystem/air/proc/generate_atmos()
	atmos_gen = list()
	// Строки генераторов теперь другие, разобранные значения протухли.
	parsed_gas_strings = list()
	for(var/T in subtypesof(/datum/atmosphere))
		var/datum/atmosphere/atmostype = T
		atmos_gen[initial(atmostype.id)] = new atmostype

/**
 * Разбор строки газа с кэшем по самой строке.
 *
 * Карта раздаёт всего пару десятков уникальных initial_gas_mix, а
 * parse_gas_string зовётся один раз на каждый открытый турф - это сотни тысяч
 * прогонов params2list/text2num за старт мира на одних и тех же строках.
 * Строки генераторов (atmos_gen) фиксируются один раз за раунд в
 * /datum/atmosphere/New, так что соответствие "строка -> смесь" стабильно.
 *
 * Возвращает list(GAS_STRING_TEMP = температура или null, GAS_STRING_MOLES = list(газ -> моли)).
 * Список общий на всех вызывающих - менять его нельзя, только читать.
 */
/datum/controller/subsystem/air/proc/get_parsed_gas_string(gas_string)
	if(!gas_string)
		gas_string = "" // пустая смесь, заодно не индексируем список по null
	var/list/cached = parsed_gas_strings[gas_string]
	if(cached)
		return cached

	var/list/gas = params2list(preprocess_gas_string(gas_string))
	var/temperature = null
	if(gas["TEMP"])
		temperature = text2num(gas["TEMP"])
		gas -= "TEMP"
		if(!isnum(temperature) || temperature < TCMB)
			temperature = TCMB
	var/list/moles = list()
	for(var/id in gas)
		moles[id] = text2num(gas[id])

	cached = list(GAS_STRING_TEMP = temperature, GAS_STRING_MOLES = moles)
	if(length(parsed_gas_strings) < GAS_STRING_CACHE_LIMIT)
		parsed_gas_strings[gas_string] = cached
	return cached

/datum/controller/subsystem/air/proc/preprocess_gas_string(gas_string)
	if(!atmos_gen)
		generate_atmos()
	if(!atmos_gen[gas_string])
		return gas_string
	var/datum/atmosphere/mix = atmos_gen[gas_string]
	return mix.gas_string

/datum/controller/subsystem/air/proc/start_processing_machine(obj/machinery/machine)
	if(machine.atmos_processing || QDELETED(machine))
		return
	machine.atmos_processing = TRUE
	atmos_machinery += machine

///popped_from_currentrun skips the O(n) currentrun scan when the caller knows the
///machine was already popped this fire (PROCESS_KILL returns, atmos_consider_idle).
/datum/controller/subsystem/air/proc/stop_processing_machine(obj/machinery/machine, popped_from_currentrun = FALSE)
	if(!machine.atmos_processing)
		return
	machine.atmos_processing = FALSE
	atmos_machinery -= machine
	if(!popped_from_currentrun)
		currentrun -= machine

///Drops a machine that just finished its idle streak out of the per-fire loop;
///the heartbeat queue (or any event wake) returns it later. `tier` - ступень
///отката, 1-based; зажимается по фактическому числу очередей, чтобы рассинхрон
///константы и инициализатора списка деградировал в короткий сон, а не в рантайм.
/datum/controller/subsystem/air/proc/sleep_processing_machine(obj/machinery/atmospherics/machine, tier = 1)
	stop_processing_machine(machine, popped_from_currentrun = TRUE)
	if(machine.atmos_idle_queued)
		// Запись уже стоит. Дедлайн у неё не позже нашего (ступень могла только
		// вырасти), значит проверка придёт раньше срока - это безобидно, а
		// перестановка записи стоила бы дороже. Единственный путь, оставлявший
		// запись при бодрствующей машине - atmos_wake - теперь снимает её сам.
		return
	tier = clamp(tier, 1, length(atmos_idle_queues))
	machine.atmos_idle_queued = TRUE
	machine.atmos_idle_tier = tier
	var/list/tier_queue = atmos_idle_queues[tier]
	tier_queue[machine] = machine.atmos_idle_until

///Removes a machine from the heartbeat queue (Destroy: the queue holds a strong ref).
/datum/controller/subsystem/air/proc/dequeue_idle_machine(obj/machinery/atmospherics/machine)
	var/tier = machine.atmos_idle_tier
	machine.atmos_idle_queued = FALSE
	machine.atmos_idle_tier = 0
	// Ранний выход по одному лишь флагу опасен: соврал бы флаг - и запись
	// осталась бы держать хардреф на удалённую машину. Но и безусловный `-=`
	// не выход, он линейно проходит всю очередь, а Destroy зовётся для КАЖДОЙ
	// атмос-машины - трубы и активные устройства платили бы за пустой поиск.
	// Поэтому спрашиваем саму очередь: ассоциативный доступ - хеш-лукап, он
	// O(1) и протухнуть не умеет. Флаг остаётся вторым условием на случай
	// обратного рассинхрона (запись без ассоциативного значения).
	if(tier >= 1 && tier <= length(atmos_idle_queues))
		var/list/tier_queue = atmos_idle_queues[tier]
		if(!isnull(tier_queue[machine]))
			tier_queue -= machine
			return
	// Ступень или флаг на машине разошлись с реальностью. Обход идёт и при
	// was_queued == FALSE: флаг и очередь умеют расходиться в обе стороны, а
	// ранний выход по одному лишь флагу оставил бы запись держать хардреф на
	// удалённую машину. Ступеней всего четыре, каждая проверка - тот же
	// хеш-лукап, так что честный обход дешевле оставленного хардрефа.
	for(var/list/tier_queue as anything in atmos_idle_queues)
		if(!isnull(tier_queue[machine]))
			tier_queue -= machine
			return

#undef SSAIR_PIPENETS
#undef SSAIR_ATMOSMACHINERY
#undef SSAIR_EXCITEDGROUPS
#undef SSAIR_HIGHPRESSURE
#undef SSAIR_HOTSPOTS
#undef SSAIR_TURF_CONDUCTION
#undef SSAIR_REBUILD_PIPENETS
#undef SSAIR_EQUALIZE
#undef SSAIR_ACTIVETURFS
#undef SSAIR_TURF_POST_PROCESS
#undef SSAIR_FINALIZE_TURFS
#undef SSAIR_ATMOSMACHINERY_AIR
#undef SSAIR_DECOMPRESSION
#undef SSAIR_ATOMS
