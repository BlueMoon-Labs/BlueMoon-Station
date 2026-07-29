// Зонд шагов: слушает реальные шаги игрока и считает, сколько тиков персонаж
// простоял на месте, доехав до тайла раньше, чем ему разрешили следующий шаг.
//
// Прибор, а не эксперимент: им отвечают на очередное "движение рваное" - что
// именно рвётся, где и по чьей вине. Боевой код о нём не знает, зонд только
// подписывается на сигнал шага и читает счётчики расписания - убрать зонд
// можно вместе с его файлами, и движение этого не заметит.

/// ckey -> /datum/movement_probe
GLOBAL_LIST_EMPTY(movement_probes)

/datum/movement_probe
	/// Ключ владельца в GLOB.movement_probes.
	var/probe_ckey
	/// Моб, на котором висит подписка.
	var/mob/watched
	/// world.time предыдущего шага.
	var/last_step_time
	/// Записи вида ticks / glide / delay / diagonal.
	var/list/samples

/datum/movement_probe/New(client/new_owner)
	. = ..()
	probe_ckey = new_owner.ckey
	samples = list()
	GLOB.movement_probes[probe_ckey] = src
	watch(new_owner.mob)

/datum/movement_probe/Destroy()
	unwatch()
	GLOB.movement_probes -= probe_ckey
	return ..()

/datum/movement_probe/proc/watch(mob/target)
	unwatch()
	if(!target)
		return
	watched = target
	RegisterSignal(watched, COMSIG_MOB_CLIENT_MOVE, PROC_REF(on_client_move))
	RegisterSignal(watched, COMSIG_PARENT_QDELETING, PROC_REF(on_watched_deleted))

/datum/movement_probe/proc/unwatch()
	if(!watched)
		return
	UnregisterSignal(watched, list(COMSIG_MOB_CLIENT_MOVE, COMSIG_PARENT_QDELETING))
	watched = null

/datum/movement_probe/proc/on_watched_deleted(datum/source)
	SIGNAL_HANDLER
	unwatch()

/datum/movement_probe/proc/on_client_move(mob/source, client/user, direction, atom/new_loc, atom/old_loc, add_delay, base_delay)
	SIGNAL_HANDLER
	if(length(samples) >= MOVEMENT_PROBE_MAX_SAMPLES)
		return
	var/ticks = movement_probe_tick_delta(world.time, last_step_time, world.tick_lag)
	last_step_time = world.time
	samples += list(list(
		"ticks" = ticks,
		"time" = world.time,
		"glide" = source.glide_size,
		"delay" = add_delay,
		// Базовая цена, до диагонали. По ней и только по ней видно настоящую
		// смену скорости: итоговая меняется на каждом повороте.
		"base" = base_delay,
		"diagonal" = ((direction & (direction - 1)) ? TRUE : FALSE),
		// Сигнал шлётся и на несостоявшийся шаг: гейты /client/Move() пройдены,
		// а Move() упёрся. Такой шаг тратит слот и выставляет glide впустую.
		"moved" = (source.loc != old_loc),
		// Настоящее время рядом с серверным: по их расхождению видно, проседал
		// ли сервер в паузе или шёл вровень.
		"realtime" = REALTIMEOFDAY,
		// Момент нажатия зажатой клавиши движения. Отличает потерянный ввод от
		// паузы, которую игрок сделал сам.
		"key_time" = movement_probe_movement_key_time(user?.keys_held, user?.movement_keys),
	))

/// Отчёт по записи. Простой считается парами: glide, выставленный на шаге N,
/// управляет промежутком между шагом N и шагом N+1 - а не тем, что был до него.
/datum/movement_probe/proc/report()
	if(length(samples) < 2)
		return "Зонд записал [length(samples)] шаг(ов) - этого мало, побегай подольше."

	var/list/intervals = list()
	var/list/diagonal_intervals = list()
	var/list/reasons = list()
	var/list/outliers = list()
	var/idle_total = 0
	var/idle_worst = 0
	var/undershoot_worst = 0
	var/undershoot_visible = 0
	var/undershoot_jump_worst = 0
	var/undershoot_jump_visible = 0
	var/previous_undershoot = null
	var/counted = 0

	for(var/index in 1 to length(samples) - 1)
		var/list/current_step = samples[index]
		var/list/next_step = samples[index + 1]
		var/ticks = next_step["ticks"]
		// Пауза между забегами: игрок отпустил клавиши и постоял. Серия
		// прервалась, и сравнивать недоезд через неё не с чем.
		if(ticks <= 0 || ticks > MOVEMENT_PROBE_SERIES_GAP)
			previous_undershoot = null
			continue
		counted++
		intervals += ticks
		if(current_step["diagonal"])
			diagonal_intervals += ticks

		// glide, выставленный на шаге N, покрывает промежуток до шага N+1.
		var/idle = movement_probe_idle_ticks(current_step["glide"], world.icon_size, ticks)
		idle_total += idle
		if(idle > idle_worst)
			idle_worst = idle
		var/undershoot = movement_probe_undershoot_pixels(current_step["glide"], world.icon_size, ticks)
		if(undershoot > undershoot_worst)
			undershoot_worst = undershoot
		if(undershoot >= MOVEMENT_PROBE_UNDERSHOOT_PIXELS)
			undershoot_visible++
		// Скачок считается только внутри непрерывной серии: первый шаг сравнивать
		// не с чем, и ноль вместо сравнения дал бы фальшивый скачок в полтайла.
		var/undershoot_jump = isnull(previous_undershoot) ? 0 : movement_probe_undershoot_jump(undershoot, previous_undershoot)
		previous_undershoot = undershoot
		if(undershoot_jump > undershoot_jump_worst)
			undershoot_jump_worst = undershoot_jump
		if(undershoot_jump >= MOVEMENT_PROBE_UNDERSHOOT_JUMP_PIXELS)
			undershoot_jump_visible++

		var/nominal = current_step["delay"] / world.tick_lag
		var/reason = movement_probe_classify(ticks, nominal, (next_step["base"] != current_step["base"]), current_step["moved"])
		reasons += reason
		if(!movement_probe_is_outlier(undershoot_jump, ticks, nominal))
			continue
		var/real_delta = next_step["realtime"] - current_step["realtime"]
		var/dilation = movement_probe_dilation(ticks * world.tick_lag, real_delta)
		var/key_held = movement_probe_key_held_through(next_step["key_time"], current_step["time"])
		outliers += list(list(
			"ticks" = ticks,
			"nominal" = nominal,
			"reason" = reason,
			"idle" = idle,
			"jump" = undershoot_jump,
			"real_delta" = real_delta,
			"source" = movement_probe_stall_source(dilation, key_held),
		))

	if(!counted)
		return "Зонд записал [length(samples)] шаг(ов), но ни одной непрерывной серии - похоже, ты шёл рывками, а не бежал."

	var/idle_average = idle_total / counted
	var/list/out = list()
	out += "=== Зонд шагов: [counted] шагов в сериях (из [length(samples)] записанных) ==="
	out += "tick_lag [world.tick_lag] ([world.fps] fps), icon_size [world.icon_size]"
	out += ""
	out += "Интервалы между шагами, тиков: [movement_probe_histogram_line(movement_probe_histogram(intervals), "тик(ов)")]"
	if(length(diagonal_intervals))
		out += "  из них по диагонали:        [movement_probe_histogram_line(movement_probe_histogram(diagonal_intervals), "тик(ов)")]"
	out += ""
	out += "Средний простой:  [round(idle_average, 0.01)] тика = [round(idle_average * world.tick_lag * 100, 1)] мс на шаг"
	out += "Худший простой:   [round(idle_worst, 0.01)] тика = [round(idle_worst * world.tick_lag * 100, 1)] мс"
	// Уровень недоезда сам по себе глазу недоступен: при LONG_GLIDE спрайт не
	// прыгает, а едет из той точки, где стоит, поэтому постоянный недоезд - это
	// просто сдвиг картинки на пиксель. Видно скачок между соседними шагами, и
	// главная строка тут - именно он.
	out += "Скачок недоезда: худший [round(undershoot_jump_worst, 0.1)] px из [world.icon_size], больше [MOVEMENT_PROBE_UNDERSHOOT_JUMP_PIXELS] px - [undershoot_jump_visible] шагов из [counted]"
	out += "  уровень (сам по себе не виден): [undershoot_visible] шагов больше пикселя, худший [round(undershoot_worst, 0.1)] px"
	out += ""
	// У причин единицы измерения нет: "норма" не измеряется в тиках.
	out += "Причины интервалов: [movement_probe_histogram_line(movement_probe_histogram(reasons), null)]"
	out += ""
	out += outlier_lines(outliers)
	out += ""
	out += corrector_line()
	return out.Join("\n")

/// Самые заметные выбросы, от длинного к короткому.
/datum/movement_probe/proc/outlier_lines(list/outliers)
	if(!length(outliers))
		return "Выбросов нет: каждый интервал объясняется номиналом скорости."
	sortTim(outliers, GLOBAL_PROC_REF(cmp_probe_outlier_desc))
	var/list/out = list("Выбросы, худшие [min(length(outliers), 8)] из [length(outliers)]:")
	for(var/index in 1 to min(length(outliers), 8))
		var/list/outlier = outliers[index]
		var/line = "  [outlier["ticks"]] тик(ов) против номинала [round(outlier["nominal"], 0.01)] - [outlier["reason"]], простой [round(outlier["idle"] * world.tick_lag * 100, 1)] мс, скачок [round(outlier["jump"], 0.1)] px"
		// У паузы важно, отставал ли сервер: это разные диагнозы, и по одному
		// числу тиков их не различить.
		if(outlier["reason"] == MOVEMENT_PROBE_STALL)
			line += ", по часам [round(outlier["real_delta"] * 100, 1)] мс, [outlier["source"]]"
		out += line
	return out.Join("\n")

/// Как часто скорость менялась прямо посреди шага и удавалось ли это учесть.
/datum/movement_probe/proc/corrector_line()
	if(!GLOB.movement_reschedule_checks)
		return "Смена скорости на ходу: ни разу за раунд - перебазировать расписание было нечего."
	return "Смена скорости на ходу: [GLOB.movement_reschedule_checks] раз, расписание подтянуто [GLOB.movement_reschedule_applied] раз (остальные - замедление, оно расписание не трогает)."

/proc/cmp_probe_outlier_desc(list/first, list/second)
	return second["ticks"] - first["ticks"]

/client/proc/movement_probe_toggle()
	set name = "Зонд шагов"
	set category = "Debug"
	set desc = "Записывает интервалы между шагами и простой из-за glide_size"
	if(!check_rights(R_DEBUG))
		return
	var/datum/movement_probe/probe = GLOB.movement_probes[ckey]
	if(probe)
		to_chat(src, "<pre>[probe.report()]</pre>")
		qdel(probe)
		return
	new /datum/movement_probe(src)
	to_chat(src, "<span class='notice'>Зонд шагов включён. Побегай секунд тридцать - по прямой и по диагонали - и нажми верб ещё раз.</span>")
