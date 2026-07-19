//Used to process objects.

/// Проход подсистемы дороже этого (мс синхронной работы за цикл) = страйк перерасхода.
#define PROCESSING_PROFILE_STRIKE_MS 50
/// Столько страйков подряд включают профилирование следующего прохода.
#define PROCESSING_PROFILE_STRIKES_TO_ARM 3
/// Пауза между профилированными проходами, чтобы замер сам не стал нагрузкой.
#define PROCESSING_PROFILE_COOLDOWN (5 MINUTES)
/// Сколько самых дорогих типов попадает в дамп.
#define PROCESSING_PROFILE_TOP_N 8

SUBSYSTEM_DEF(processing)
	name = "Processing"
	priority = FIRE_PRIORITY_PROCESS
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING|SS_NO_INIT
	wait = 1 SECONDS

	var/stat_tag = "P" //Used for logging
	var/list/processing = list()
	var/list/currentrun = list()

	/// Адаптивный профиль перерасхода: страйки дорогих проходов подряд.
	var/profile_strikes = 0
	/// TRUE = следующий полный проход замеряет стоимость каждого process() по типам.
	var/profile_armed = FALSE
	/// world.time, до которого профилирование не перевзводится.
	var/profile_cooldown_until = 0
	/// Синхронная стоимость текущего прохода (копится через yield'ы MC_TICK_CHECK).
	var/current_pass_cost_ms = 0
	/// Аккумуляторы профилированного прохода: тип -> суммарно мс / число вызовов / максимум мс.
	var/list/profile_cost_by_type
	var/list/profile_count_by_type
	var/list/profile_max_by_type

/datum/controller/subsystem/processing/stat_entry(msg)
	msg = "[stat_tag]:[length(processing)]"
	return ..()

/datum/controller/subsystem/processing/fire(resumed = FALSE)
	var/slice_start_usage = TICK_USAGE
	if (!resumed)
		currentrun = processing.Copy()
		current_pass_cost_ms = 0
	//cache for sanic speed (lists are references anyways)
	var/list/current_run = currentrun
	var/profiling = profile_armed
	var/seconds_per_tick = wait * 0.1

	while(current_run.len)
		var/datum/thing = current_run[current_run.len]
		current_run.len--
		if(QDELETED(thing))
			processing -= thing
		else if(profiling)
			var/item_type = thing.type
			var/item_start_usage = TICK_USAGE
			if(thing.process(seconds_per_tick) == PROCESS_KILL)
				// fully stop so that a future START_PROCESSING will work
				STOP_PROCESSING(src, thing)
			profile_note(item_type, max(0, TICK_DELTA_TO_MS(TICK_USAGE - item_start_usage)))
		else if(thing.process(seconds_per_tick) == PROCESS_KILL)
			// fully stop so that a future START_PROCESSING will work
			STOP_PROCESSING(src, thing)
		if (MC_TICK_CHECK)
			current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
			return

	current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
	on_pass_finished()

/// Учёт одного замера профилированного прохода.
/datum/controller/subsystem/processing/proc/profile_note(item_type, cost_ms)
	profile_cost_by_type[item_type] += cost_ms
	profile_count_by_type[item_type] += 1
	if(cost_ms > profile_max_by_type[item_type])
		profile_max_by_type[item_type] = cost_ms

/**
 * Конец полного прохода: решаем, взводить ли профилирование, или дампить готовый профиль.
 * Логика самонаводящаяся: PROCESSING_PROFILE_STRIKES_TO_ARM дорогих проходов подряд ->
 * один проход с позамерным учётом по типам -> дамп топа в tick_spikes.log + game.log ->
 * кулдаун. В спокойном состоянии стоит ровно одно сравнение на проход.
 */
/datum/controller/subsystem/processing/proc/on_pass_finished()
	var/pass_cost = current_pass_cost_ms
	current_pass_cost_ms = 0

	if(profile_armed)
		profile_armed = FALSE
		dump_expensive_pass_profile(pass_cost)
		profile_cost_by_type = null
		profile_count_by_type = null
		profile_max_by_type = null
		profile_cooldown_until = world.time + PROCESSING_PROFILE_COOLDOWN
		profile_strikes = 0
		return

	if(pass_cost < PROCESSING_PROFILE_STRIKE_MS)
		profile_strikes = 0
		return
	if(world.time < profile_cooldown_until)
		return
	profile_strikes++
	if(profile_strikes < PROCESSING_PROFILE_STRIKES_TO_ARM)
		return
	profile_armed = TRUE
	profile_cost_by_type = list()
	profile_count_by_type = list()
	profile_max_by_type = list()

/// Дамп профиля дорогого прохода: топ типов по суммарной стоимости.
/datum/controller/subsystem/processing/proc/dump_expensive_pass_profile(pass_cost)
	var/list/types_by_cost = list()
	for(var/item_type in profile_cost_by_type)
		types_by_cost[item_type] = profile_cost_by_type[item_type]
	sortTim(types_by_cost, GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)

	var/list/out = list()
	out += "=== SS[name]: профиль дорогого прохода - [round(pass_cost, 0.1)]мс, [length(processing)] объектов ([time_stamp_from_world_safe(world.time)], wt [world.time]) ==="
	var/shown = 0
	var/shown_cost = 0
	for(var/item_type in types_by_cost)
		if(shown >= PROCESSING_PROFILE_TOP_N)
			break
		shown++
		var/type_cost = profile_cost_by_type[item_type]
		shown_cost += type_cost
		out += "  [item_type] - [round(type_cost, 0.1)]мс суммарно, [profile_count_by_type[item_type]] вызовов, макс [round(profile_max_by_type[item_type], 0.1)]мс"
	var/rest = length(types_by_cost) - shown
	if(rest > 0)
		out += "  (ещё [rest] типов, суммарно [round(pass_cost - shown_cost, 0.1)]мс с учётом накладных)"

	var/digest = out.Join("\n")
	if(SStick_spikes)
		SStick_spikes.write_to_log(digest)
	// Однострочник в game.log, чтобы виновник был виден прямо в архиве раунда.
	if(length(types_by_cost))
		var/top_type = types_by_cost[1]
		log_game("PROCESSING HEAVY: SS[name] проход [round(pass_cost, 0.1)]мс, топ: [top_type] ([round(types_by_cost[top_type], 0.1)]мс). Полный профиль в tick_spikes.log")

/// gameTimestamp, но безопасный до старта тикера.
/proc/time_stamp_from_world_safe(world_ds)
	return SSticker ? gameTimestamp("hh:mm:ss", world_ds) : "wt [world_ds]"

/**
 * This proc is called on a datum on every "cycle" if it is being processed by a subsystem. The time between each cycle is determined by the subsystem's "wait" setting.
 * You can start and stop processing a datum using the START_PROCESSING and STOP_PROCESSING defines.
 *
 * Since the wait setting of a subsystem can be changed at any time, it is important that any rate-of-change that you implement in this proc is multiplied by the delta_time that is sent as a parameter,
 * Additionally, any "prob" you use in this proc should instead use the DT_PROB define to make sure that the final probability per second stays the same even if the subsystem's wait is altered.
 * Examples where this must be considered:
 * - Implementing a cooldown timer, use `mytimer -= delta_time`, not `mytimer -= 1`. This way, `mytimer` will always have the unit of seconds
 * - Damaging a mob, do `L.adjustFireLoss(20 * delta_time)`, not `L.adjustFireLoss(20)`. This way, the damage per second stays constant even if the wait of the subsystem is changed
 * - Probability of something happening, do `if(DT_PROB(25, delta_time))`, not `if(prob(25))`. This way, if the subsystem wait is e.g. lowered, there won't be a higher chance of this event happening per second
 *
 * If you override this do not call parent, as it will return PROCESS_KILL. This is done to prevent objects that dont override process() from staying in the processing list
 */
/datum/proc/process(delta_time)
	set waitfor = FALSE
	return PROCESS_KILL

#undef PROCESSING_PROFILE_STRIKE_MS
#undef PROCESSING_PROFILE_STRIKES_TO_ARM
#undef PROCESSING_PROFILE_COOLDOWN
#undef PROCESSING_PROFILE_TOP_N
