/**
 * # SStick_spikes - детектор и рекордер тик-спайков (резких скачков time dilation)
 *
 * Проблема: "Откл" (time dilation) считается SStime_track раз в 10 секунд как средняя
 * потеря тиков за окно, а профайлер BYOND агрегирует время за весь раунд. Одиночный
 * фриз сервера на 200-1000 мс не виден ни там, ни там - он размазывается по средним.
 *
 * Эта подсистема каждый тик замеряет реальное время (монотонные часы rust-g) и сравнивает
 * его с игровым. Если реального времени прошло заметно больше игрового - тик "растянулся",
 * это и есть спайк. На каждый спайк пишется событие с контекстом:
 *  - кольцевой буфер последних тиков (usage/cpu/map_cpu) - что происходило вокруг;
 *  - сырые "тяжёлые прогоны" подсистем МК за последние секунды (хук в RunQueue).
 *    ВАЖНО: это wall-time - столл ОС/BYOND во время слота подсистемы выглядит как её
 *    тяжёлый прогон. Прежде чем винить подсистему, сверяй с дампом профайлера: если под
 *    ней нет соответствующего проковского self/over времени - это был столл в её слоте;
 *  - недавние хардделы из кольца SSgarbage - одиночный дорогой del() объясняет спайки Garbage;
 *  - автоклассификация источника (подсистема МК / DM вне МК / SendMaps / внешний столл);
 *  - при активном захвате - JSON-снапшот профайлера (кумулятивный; окно спайка = дифф
 *    соседних дампов, числа в них монотонно растут).
 *
 * Как пользоваться (админ-вербы в категории Debug):
 *  - "Tick Spikes Report" - текущий отчёт со всеми пойманными спайками;
 *  - "Tick Spikes Capture" - включить сессию захвата с дампами профайлера на спайках;
 *  - "Simulate Tick Spike" - синтетический фриз заданной длины для проверки всей цепочки.
 *
 * Файлы за раунд: [папка логов]/tick_spikes.log и tick_spike_profile_N.json
 */

/// Размер кольцевого буфера пер-тиковой телеметрии (~30 сек при 20 fps)
#define TICK_SPIKES_HISTORY 600
/// Размер кольца сырых тяжёлых прогонов подсистем МК
#define TICK_SPIKES_HEAVY_HISTORY 128
/// Размер кольца медленных единиц работы вне МК (таймер-колбеки, отложенные вербы, Topic)
#define TICK_SPIKES_SLOW_WORK_HISTORY 64
/// Сколько последних тиков печатать в отчёте о событии
#define TICK_SPIKES_REPORT_WINDOW 20
/// За какое окно (в игровом времени) собирать тяжёлые прогоны в отчёт о событии
#define TICK_SPIKES_HEAVY_WINDOW (5 SECONDS)
/// Идентификатор монотонных часов rust-g
#define TICK_SPIKES_CLOCK "ss_tick_spikes"
/// Максимум событий, хранимых в памяти для отчёта
#define TICK_SPIKES_MAX_EVENTS 40
/// Минимальный дрифт (мс) для учёта в гистограмме
#define TICK_SPIKES_HISTOGRAM_FLOOR 25
// Верхние границы корзин гистограммы дрифтов (мс); нижняя граница первой - TICK_SPIKES_HISTOGRAM_FLOOR
#define TICK_SPIKES_HISTOGRAM_BUCKET_1 50
#define TICK_SPIKES_HISTOGRAM_BUCKET_2 100
#define TICK_SPIKES_HISTOGRAM_BUCKET_3 300
#define TICK_SPIKES_HISTOGRAM_BUCKET_4 1000
/// Сколько последних тиков считаются "тиками спайка" при классификации источника
#define TICK_SPIKES_CLASSIFY_WINDOW_TICKS 3
/// Порог cpu (%) в тиках спайка, с которого источник классифицируется как DM вне МК
#define TICK_SPIKES_CLASSIFY_CPU_THRESHOLD 70
/// Порог map_cpu (%) в тиках спайка, с которого источник классифицируется как SendMaps
#define TICK_SPIKES_CLASSIFY_MAP_CPU_THRESHOLD 50
/// На сколько тиков после нашего дампа профайлера спайки считаются самонаведёнными
#define TICK_SPIKES_SELF_INFLICTED_TICKS 2

// Классы источников спайка
#define TICK_SPIKE_CLASS_MC "подсистема МК"
#define TICK_SPIKE_CLASS_DM "DM вне МК (вербы/Topic/спящие проки)"
#define TICK_SPIKE_CLASS_SENDMAPS "SendMaps (рассылка карты клиентам)"
#define TICK_SPIKE_CLASS_EXTERNAL "внешний столл (диск/ОС/BYOND), DM почти не работал"
#define TICK_SPIKE_CLASS_SELF "дамп профайлера самой диагностики"

SUBSYSTEM_DEF(tick_spikes)
	name = "Tick Spikes"
	wait = 1
	priority = FIRE_PRIORITY_TICK_SPIKES
	flags = SS_TICKER | SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	/// Порог дрифта (мс реального времени сверх игрового за тик), с которого фиксируем событие
	var/spike_threshold_ms = 100
	/// Порог сырого прогона подсистемы МК (в % тика), с которого он попадает в кольцо тяжёлых прогонов
	var/heavy_run_threshold = 40
	/// Дрифт (мс), с которого события анонсируются админам
	var/announce_threshold_ms = 500
	/// Анонсировать ли крупные спайки в админ-чат. По умолчанию выключено: на хайпопе спайки
	/// постоянные и спамят, а информация нужна разработчикам в логе, не админам в раунде.
	/// Включается через VV на время целевой отладки.
	var/announce_to_admins = FALSE
	/// Минимум мс между анонсами в админ-чат
	var/announce_cooldown_ms = 30000

	// --- Пер-тиковый кольцевой буфер ---
	var/list/ring_world_time
	var/list/ring_drift
	var/list/ring_usage_at_fire
	var/list/ring_cpu
	var/list/ring_map_cpu
	var/ring_pos = 0
	var/samples_collected = 0

	// --- Кольцо тяжёлых прогонов подсистем (пишется хуком из Master/RunQueue) ---
	var/list/heavy_time
	var/list/heavy_name
	var/list/heavy_usage
	var/heavy_pos = 0

	// --- Последний завершённый прогон очереди МК (пишется тем же хуком из Master/RunQueue).
	// Master.last_type_processed в момент нашего fire() - всегда мы сами, поэтому свой учёт ---
	var/last_run_subsystem_name
	var/last_run_subsystem_time = 0

	// --- Кольцо медленных единиц работы вне слотов подсистем: таймер-колбеки (SStimer),
	// отложенные вербы (SSverb_manager), client/Topic. Раньше весь этот DM был анонимным -
	// спайк классифицировался как "DM вне МК" без имени виновника ---
	var/list/slow_work_time
	var/list/slow_work_kind
	var/list/slow_work_desc
	var/list/slow_work_cost
	var/slow_work_pos = 0
	/// Порог стоимости (мс синхронной части, до первого сна), с которого единица работы
	/// попадает в кольцо. Общий для всех точек замера, крутится через VV.
	var/slow_work_threshold_ms = 30

	// --- Состояние часов ---
	var/has_baseline = FALSE
	var/last_ms = 0
	var/last_world = 0

	// --- Статистика сессии ---
	var/session_spike_count = 0
	var/worst_drift_ms = 0
	var/worst_drift_at = 0
	var/total_spike_drift_ms = 0
	/// Гистограмма дрифтов: 5 корзин по границам TICK_SPIKES_HISTOGRAM_FLOOR / BUCKET_1..4, последняя - всё выше BUCKET_4
	var/list/drift_histogram

	/// Список текстовых блоков последних событий (для отчёта)
	var/list/spike_events

	// --- Сессия захвата с профайлером ---
	/// world.time, до которого активен захват (0 = выключен)
	var/capture_until = 0
	/// Запустили ли профайлер мы сами (чтобы не выключить чужой auto_profile)
	var/started_profiler = FALSE
	var/profile_dumps_done = 0
	var/last_profile_dump_ms = 0
	///монотонный номер для имён файлов дампов: НЕ сбрасывается на start_capture,
	///иначе авто-дамп и дамп новой сессии склеили бы два JSON в один файл
	var/profile_dump_seq = 0
	/// Минимум мс между дампами профайлера
	var/profile_dump_cooldown_ms = 15000
	/// world.time, до которого спайки считаются самонаведёнными (после нашего же дампа)
	var/self_inflicted_until = 0

	/// Минимум мс между ПОЛНЫМИ блоками событий в логе: на хайпопе спайки идут потоком,
	/// и полный контекст на каждый раздул бы лог. Промежуточные пишутся одной строкой.
	var/full_event_min_interval_ms = 3000
	/// Момент (мс часов rust-g) последнего полного блока
	var/last_full_event_ms = 0
	/// Сколько спайков записано кратко из-за рейт-лимита
	var/suppressed_event_count = 0

	/// Метка для следующего события (ставится вербом симуляции)
	var/next_spike_tag

	var/last_announce_ms = 0
	/// Путь к файлу лога событий
	var/log_path

	// --- Тестовые крутилки ---
	/// Не писать в файлы и не дёргать админ-чат/профайлер (для юнит-тестов)
	var/suppress_side_effects = FALSE
	/// Детектить спайки даже без клиентов на сервере (для юнит-тестов и локалки)
	var/ignore_empty_server = FALSE

/datum/controller/subsystem/tick_spikes/PreInit()
	reset_state()
#if DM_VERSION >= 515
	// Always-on SendMaps profiling: the proc profiler can't see render/maptick
	// cost at all, and SendMaps spikes used to be diagnosable only during an
	// admin-started capture session. The sendmaps profile is a small aggregate
	// table (negligible overhead), so keep it running from boot and auto-dump
	// it whenever a spike classifies as SendMaps (see try_dump_profile).
	world.Profile(PROFILE_START, type = "sendmaps")
#endif

/// Пересоздание МК (NEW_SS_GLOBAL): PreInit() нового инстанса всё равно
/// обнулит кольца и статистику, поэтому переносим только то, что он не трогает -
/// админские настройки, активную сессию захвата и монотонный номер дампов
/// (без него следующий дамп доклеился бы WRITE_FILE'ом в старый JSON-файл).
/datum/controller/subsystem/tick_spikes/Recover()
	spike_threshold_ms = SStick_spikes.spike_threshold_ms
	heavy_run_threshold = SStick_spikes.heavy_run_threshold
	announce_threshold_ms = SStick_spikes.announce_threshold_ms
	announce_to_admins = SStick_spikes.announce_to_admins
	announce_cooldown_ms = SStick_spikes.announce_cooldown_ms
	last_announce_ms = SStick_spikes.last_announce_ms
	capture_until = SStick_spikes.capture_until
	started_profiler = SStick_spikes.started_profiler
	profile_dumps_done = SStick_spikes.profile_dumps_done
	last_profile_dump_ms = SStick_spikes.last_profile_dump_ms
	profile_dump_seq = SStick_spikes.profile_dump_seq
	profile_dump_cooldown_ms = SStick_spikes.profile_dump_cooldown_ms
	self_inflicted_until = SStick_spikes.self_inflicted_until
	full_event_min_interval_ms = SStick_spikes.full_event_min_interval_ms
	log_path = SStick_spikes.log_path
	suppress_side_effects = SStick_spikes.suppress_side_effects
	ignore_empty_server = SStick_spikes.ignore_empty_server
	slow_work_threshold_ms = SStick_spikes.slow_work_threshold_ms

/// Полный сброс колец и статистики. Не трогает настройки порогов.
/datum/controller/subsystem/tick_spikes/proc/reset_state()
	ring_world_time = new /list(TICK_SPIKES_HISTORY)
	ring_drift = new /list(TICK_SPIKES_HISTORY)
	ring_usage_at_fire = new /list(TICK_SPIKES_HISTORY)
	ring_cpu = new /list(TICK_SPIKES_HISTORY)
	ring_map_cpu = new /list(TICK_SPIKES_HISTORY)
	ring_pos = 0
	samples_collected = 0
	heavy_time = new /list(TICK_SPIKES_HEAVY_HISTORY)
	heavy_name = new /list(TICK_SPIKES_HEAVY_HISTORY)
	heavy_usage = new /list(TICK_SPIKES_HEAVY_HISTORY)
	heavy_pos = 0
	slow_work_time = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_kind = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_desc = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_cost = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_pos = 0
	has_baseline = FALSE
	last_ms = 0
	last_world = 0
	session_spike_count = 0
	worst_drift_ms = 0
	worst_drift_at = 0
	total_spike_drift_ms = 0
	drift_histogram = list(0, 0, 0, 0, 0)
	spike_events = list()
	last_full_event_ms = 0
	suppressed_event_count = 0

/datum/controller/subsystem/tick_spikes/stat_entry(msg)
	msg = "спайков:[session_spike_count] худший:[round(worst_drift_ms)]мс[capture_until ? " ЗАХВАТ" : ""]"
	return ..()

/datum/controller/subsystem/tick_spikes/fire()
	sample_tick(rustg_time_milliseconds(TICK_SPIKES_CLOCK), world.time, TICK_USAGE, world.cpu, MAPTICK_LAST_INTERNAL_TICK_USAGE)
	if(capture_until && world.time > capture_until)
		stop_capture(automatic = TRUE)

/**
 * Обработка одного тика. Вынесена из fire() с явными аргументами,
 * чтобы юнит-тест мог скармливать синтетические последовательности.
 * Возвращает дрифт в мс (или null, если это был первый замер).
 */
/datum/controller/subsystem/tick_spikes/proc/sample_tick(now_ms, now_world, usage_at_fire, cpu, map_cpu)
	if(!has_baseline)
		has_baseline = TRUE
		last_ms = now_ms
		last_world = now_world
		return null

	var/real_delta = now_ms - last_ms
	var/world_delta = (now_world - last_world) * 100 // дс -> мс
	var/drift = real_delta - world_delta
	last_ms = now_ms
	last_world = now_world

	ring_pos = (ring_pos % TICK_SPIKES_HISTORY) + 1
	ring_world_time[ring_pos] = now_world
	ring_drift[ring_pos] = drift
	ring_usage_at_fire[ring_pos] = usage_at_fire
	ring_cpu[ring_pos] = cpu
	ring_map_cpu[ring_pos] = map_cpu
	samples_collected++

	// Пустой сервер (sleep_offline, ребут, ожидание) даёт гигантские ложные дрифты -
	// не пускать их ни в гистограмму, ни в события (кольцо выше оставляем: это контекст, не статистика)
	if(!length(GLOB.clients) && !ignore_empty_server)
		return drift

	if(drift >= TICK_SPIKES_HISTOGRAM_FLOOR)
		if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_1)
			drift_histogram[1]++
		else if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_2)
			drift_histogram[2]++
		else if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_3)
			drift_histogram[3]++
		else if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_4)
			drift_histogram[4]++
		else
			drift_histogram[5]++

	if(drift < spike_threshold_ms)
		return drift

	register_spike(drift, now_ms, now_world)
	return drift

/// Пишется из Master/RunQueue: сырой (неусреднённый) прогон подсистемы, съевший заметную долю тика
/datum/controller/subsystem/tick_spikes/proc/record_heavy_run(datum/controller/subsystem/heavy_subsystem, usage)
	heavy_pos = (heavy_pos % TICK_SPIKES_HEAVY_HISTORY) + 1
	heavy_time[heavy_pos] = world.time
	heavy_name[heavy_pos] = heavy_subsystem.name
	heavy_usage[heavy_pos] = usage

/// Собирает тяжёлые прогоны за окно [since_world, до текущего] в текстовые строки (хронологически)
/datum/controller/subsystem/tick_spikes/proc/collect_heavy_runs(since_world)
	var/list/lines = list()
	for(var/i in heavy_ring_chronological())
		var/run_time = heavy_time[i]
		if(isnull(run_time) || run_time < since_world)
			continue
		lines += "  [time_stamp_from_world(run_time)] (wt [run_time]) [heavy_name[i]]: [round(heavy_usage[i], 0.1)]% тика (~[round(heavy_usage[i] * world.tick_lag, 0.1)]мс)"
	return lines

/// Хардделы из кольца SSgarbage за окно [since_world, сейчас]: del() с полным поиском
/// ссылок по миру - на проде одиночный харддел давал спайки по 200-330мс
/datum/controller/subsystem/tick_spikes/proc/collect_recent_harddels(since_world)
	var/list/lines = list()
	if(isnull(SSgarbage?.recent_hard_deletes))
		return lines
	for(var/list/entry in SSgarbage.recent_hard_deletes)
		var/del_time = entry[1]
		if(del_time < since_world)
			continue
		lines += "  [time_stamp_from_world(del_time)] (wt [del_time]) [entry[2]]: [entry[3]]мс"
	return lines

/// Индексы кольца тяжёлых прогонов от старых к новым (кольцо пишется по кругу от heavy_pos)
/datum/controller/subsystem/tick_spikes/proc/heavy_ring_chronological()
	var/list/order = list()
	for(var/i in heavy_pos + 1 to TICK_SPIKES_HEAVY_HISTORY)
		order += i
	for(var/i in 1 to heavy_pos)
		order += i
	return order

/**
 * Запись медленной единицы работы вне слотов подсистем (пишут SStimer,
 * SSverb_manager и client/Topic при стоимости >= slow_work_threshold_ms).
 * kind - короткий тип ("таймер"/"верб"/"Topic"), desc - что именно исполнялось.
 */
/datum/controller/subsystem/tick_spikes/proc/record_slow_work(kind, desc, cost_ms)
	slow_work_pos = (slow_work_pos % TICK_SPIKES_SLOW_WORK_HISTORY) + 1
	slow_work_time[slow_work_pos] = world.time
	slow_work_kind[slow_work_pos] = kind
	slow_work_desc[slow_work_pos] = desc
	slow_work_cost[slow_work_pos] = cost_ms

/// Описание колбека для кольца медленной работы: тип объекта + прок.
/// Зовётся только для уже пойманных медленных вызовов - стоимость строк не важна.
/datum/controller/subsystem/tick_spikes/proc/callback_desc(datum/callback/callback)
	if(!istype(callback))
		return "не-колбек"
	var/object_part
	if(istext(callback.object)) //GLOBAL_PROC - магическая строка
		object_part = "GLOBAL_PROC"
	else if(isnull(callback.object))
		object_part = "null"
	else
		object_part = "[callback.object.type]"
	return "[object_part] -> [callback.delegate]"

/// Медленные единицы работы за окно [since_world, сейчас] в текстовые строки (хронологически)
/datum/controller/subsystem/tick_spikes/proc/collect_slow_work(since_world)
	var/list/lines = list()
	var/list/order = list()
	for(var/i in slow_work_pos + 1 to TICK_SPIKES_SLOW_WORK_HISTORY)
		order += i
	for(var/i in 1 to slow_work_pos)
		order += i
	for(var/i in order)
		var/work_time = slow_work_time[i]
		if(isnull(work_time) || work_time < since_world)
			continue
		lines += "  [time_stamp_from_world(work_time)] (wt [work_time]) [slow_work_kind[i]]: [slow_work_desc[i]] - [round(slow_work_cost[i], 0.1)]мс"
	return lines

/// Форматирует world.time в человекочитаемое станционное время
/datum/controller/subsystem/tick_spikes/proc/time_stamp_from_world(world_ds)
	return gameTimestamp("hh:mm:ss", world_ds)

/// Классификация источника спайка по телеметрии вокруг него.
/// Подсистему МК виним только если её тяжёлый прогон был прямо в тиках спайка:
/// фоновые прогоны (атмос и т.п.) из широкого 5-секундного окна - это контекст, а не виновник.
/datum/controller/subsystem/tick_spikes/proc/classify_spike(now_world, drift)
	if(world.time < self_inflicted_until)
		return TICK_SPIKE_CLASS_SELF
	var/tight_window_start = now_world - (TICK_SPIKES_CLASSIFY_WINDOW_TICKS * world.tick_lag)
	var/list/culprits = list()
	var/culprits_ms = 0
	for(var/i in heavy_ring_chronological())
		var/run_time = heavy_time[i]
		if(isnull(run_time) || run_time < tight_window_start)
			continue
		culprits += "[heavy_name[i]] ([round(heavy_usage[i], 0.1)]% тика)"
		culprits_ms += heavy_usage[i] * world.tick_lag
	if(length(culprits))
		. = "[TICK_SPIKE_CLASS_MC]: [culprits.Join(", ")]"
		// Названные прогоны могут не покрывать дрифт: тогда основная потеря вне МК
		if(drift && culprits_ms < drift * 0.5)
			. += " - объясняют лишь ~[round(culprits_ms)]мс из [round(drift)]мс, остальное вне МК"
		return .
	// Смотрим последние TICK_SPIKES_CLASSIFY_WINDOW_TICKS тика кольца: cpu отражает предыдущий тик
	var/max_cpu = 0
	var/max_map_cpu = 0
	for(var/offset in 0 to TICK_SPIKES_CLASSIFY_WINDOW_TICKS - 1)
		var/idx = ring_pos - offset
		if(idx < 1)
			idx += TICK_SPIKES_HISTORY
		max_cpu = max(max_cpu, ring_cpu[idx] || 0)
		max_map_cpu = max(max_map_cpu, ring_map_cpu[idx] || 0)
	if(max_cpu >= TICK_SPIKES_CLASSIFY_CPU_THRESHOLD)
		return TICK_SPIKE_CLASS_DM
	if(max_map_cpu >= TICK_SPIKES_CLASSIFY_MAP_CPU_THRESHOLD)
		return TICK_SPIKE_CLASS_SENDMAPS
	return TICK_SPIKE_CLASS_EXTERNAL

/// Фиксация события спайка: контекст, классификация, запись в лог, опциональный дамп профайлера
/datum/controller/subsystem/tick_spikes/proc/register_spike(drift, now_ms, now_world)
	session_spike_count++
	total_spike_drift_ms += drift
	if(drift > worst_drift_ms)
		worst_drift_ms = drift
		worst_drift_at = now_world

	var/tag_line = ""
	if(next_spike_tag)
		tag_line = " \[[next_spike_tag]]"
		next_spike_tag = null

	// Рейт-лимит полных блоков: статистика копится по всем спайкам, но полный контекст
	// пишется не чаще full_event_min_interval_ms, промежуточные - одной строкой
	if(last_full_event_ms && (now_ms - last_full_event_ms) < full_event_min_interval_ms)
		suppressed_event_count++
		write_to_log("СПАЙК #[session_spike_count][tag_line] (кратко) [time_stamp_from_world(now_world)] (wt [now_world]): дрифт [round(drift)]мс, [classify_spike(now_world, drift)]")
		return
	last_full_event_ms = now_ms

	var/list/heavy_lines = collect_heavy_runs(now_world - TICK_SPIKES_HEAVY_WINDOW)
	var/spike_class = classify_spike(now_world, drift)

	var/list/event = list()
	event += "=== СПАЙК #[session_spike_count][tag_line] [time_stamp_from_world(now_world)] (wt [now_world]) ==="
	event += "дрифт: [round(drift)]мс (порог [spike_threshold_ms]мс), тик [world.tick_lag * 100]мс"
	event += "вероятный источник: [spike_class]"
	event += "клиентов: [length(GLOB.clients)], TD тек/быстр/сред: [round(SStime_track.time_dilation_current, 0.1)]% / [round(SStime_track.time_dilation_avg_fast, 0.1)]% / [round(SStime_track.time_dilation_avg, 0.1)]%"
	event += "МК: итерация [Master.iteration], sleep_delta [round(Master.sleep_delta, 0.01)], ticklimit [round(Master.current_ticklimit, 0.1)], последний прогон очереди: [last_run_subsystem_name ? "[last_run_subsystem_name] (wt [last_run_subsystem_time])" : "нет"]"

	if(length(heavy_lines))
		event += "тяжёлые прогоны подсистем за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек (wall-time: столл во время слота подсистемы выглядит как её прогон, сверяй с профайлером):"
		event += heavy_lines
	else
		event += "тяжёлых прогонов подсистем МК (>=[heavy_run_threshold]% тика) за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек не было"

	var/list/harddel_lines = collect_recent_harddels(now_world - TICK_SPIKES_HEAVY_WINDOW)
	if(length(harddel_lines))
		event += "хардделы за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек (одиночный дорогой del() - типовой виновник спайков в слоте Garbage):"
		event += harddel_lines

	var/list/slow_work_lines = collect_slow_work(now_world - TICK_SPIKES_HEAVY_WINDOW)
	if(length(slow_work_lines))
		event += "медленные таймер-колбеки/вербы/Topic за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек (>=[slow_work_threshold_ms]мс синхронной части - именует DM вне МК):"
		event += slow_work_lines

	event += "последние тики (время | дрифт мс | usage% до МК | cpu% | map_cpu%):"
	var/window = min(TICK_SPIKES_REPORT_WINDOW, samples_collected)
	for(var/offset = window - 1, offset >= 0, offset--)
		var/idx = ring_pos - offset
		if(idx < 1)
			idx += TICK_SPIKES_HISTORY
		event += "  wt [ring_world_time[idx]] | [round(ring_drift[idx])] | [round(ring_usage_at_fire[idx], 0.1)] | [round(ring_cpu[idx], 0.1)] | [round(ring_map_cpu[idx], 0.1)]"

	var/profile_note = try_dump_profile(drift, now_ms, spike_class)
	if(profile_note)
		event += profile_note

	var/event_text = event.Join("\n")
	spike_events += event_text
	if(length(spike_events) > TICK_SPIKES_MAX_EVENTS)
		spike_events.Cut(1, 2)

	if(!suppress_side_effects)
		write_to_log("\n[event_text]\n")
		if(announce_to_admins && drift >= announce_threshold_ms && (!last_announce_ms || now_ms - last_announce_ms > announce_cooldown_ms))
			last_announce_ms = now_ms
			message_admins("Тик-спайк: [round(drift)]мс, источник: [spike_class]. Подробности: Debug -> Tick Spikes Report.")

/// Дамп окна профайлера на спайке (только при активном захвате). Возвращает строку для события или null.
/// Исключение: sendmaps-профиль работает всегда (см. PreInit), поэтому SendMaps-спайки
/// дампят его и БЕЗ сессии захвата - проковский профайлер их всё равно не объясняет.
/datum/controller/subsystem/tick_spikes/proc/try_dump_profile(drift, now_ms, spike_class)
	if(suppress_side_effects)
		return null
	if(!capture_until || world.time > capture_until)
#if DM_VERSION >= 515
		if(spike_class == TICK_SPIKE_CLASS_SENDMAPS && (now_ms - last_profile_dump_ms >= profile_dump_cooldown_ms))
			last_profile_dump_ms = now_ms
			profile_dumps_done++
			profile_dump_seq++
			self_inflicted_until = world.time + (TICK_SPIKES_SELF_INFLICTED_TICKS * world.tick_lag)
			var/auto_sendmaps_name = "tick_spike_sendmaps_[profile_dump_seq].json"
			WRITE_FILE(file("[GLOB.log_directory]/[auto_sendmaps_name]"), world.Profile(PROFILE_REFRESH, type = "sendmaps", format = "json"))
			return "sendmaps-профайл (авто, без захвата) записан в [auto_sendmaps_name]"
#endif
		return null
	if(spike_class == TICK_SPIKE_CLASS_SELF)
		return "дамп профайлера пропущен: спайк вызван предыдущим дампом"
	if(now_ms - last_profile_dump_ms < profile_dump_cooldown_ms)
		return "дамп профайлера пропущен: кулдаун"
#if DM_BUILD < 1506
	return "дамп профайлера недоступен на этой версии BYOND"
#else
	last_profile_dump_ms = now_ms
	profile_dumps_done++
	profile_dump_seq++
	// Наш собственный дамп растянет следующий тик - не считать его новым спайком
	self_inflicted_until = world.time + (TICK_SPIKES_SELF_INFLICTED_TICKS * world.tick_lag)
	var/file_name = "tick_spike_profile_[profile_dump_seq].json"
	// PROFILE_REFRESH возвращает данные, но НЕ обнуляет их: снапшот кумулятивный с момента
	// старта профайлера. Окно между спайками = дифф соседних дампов (числа монотонные).
	WRITE_FILE(file("[GLOB.log_directory]/[file_name]"), world.Profile(PROFILE_REFRESH, format = "json"))
	. = "профайлер: кумулятивный снапшот записан в [file_name] (окно = дифф с предыдущим дампом)"
#if DM_VERSION >= 515
	if(spike_class == TICK_SPIKE_CLASS_SENDMAPS)
		var/sendmaps_name = "tick_spike_sendmaps_[profile_dump_seq].json"
		WRITE_FILE(file("[GLOB.log_directory]/[sendmaps_name]"), world.Profile(PROFILE_REFRESH, type = "sendmaps", format = "json"))
		. += "; sendmaps-профайл в [sendmaps_name]"
#endif
#endif

/// Старт сессии захвата: включает профайлер и дампы его окон на спайках
/datum/controller/subsystem/tick_spikes/proc/start_capture(duration_ds, starter_key)
	capture_until = world.time + duration_ds
	profile_dumps_done = 0
	last_profile_dump_ms = 0
#if DM_BUILD >= 1506
	if(!CONFIG_GET(flag/auto_profile))
		SSprofiler.StartProfiling()
		started_profiler = TRUE
	// Намеренно НЕ обнуляем профайлер (PROFILE_RESTART): при включённом auto_profile это
	// сломало бы кумулятивный profiler.json от SSprofiler. Дампы диффятся оффлайн.
#endif
#if DM_VERSION >= 515
	world.Profile(PROFILE_START, type = "sendmaps")
#endif
	write_to_log("=== ЗАХВАТ ВКЛЮЧЁН [starter_key ? "([starter_key]) " : ""]на [duration_ds / 10] сек, до wt [capture_until] ===")

/// Остановка сессии захвата
/datum/controller/subsystem/tick_spikes/proc/stop_capture(automatic = FALSE, stopper_key)
	capture_until = 0
#if DM_BUILD >= 1506
	if(started_profiler && !CONFIG_GET(flag/auto_profile))
		SSprofiler.StopProfiling()
#endif
	// sendmaps-профиль НЕ останавливаем: он always-on с PreInit (нужен для
	// авто-дампов SendMaps-спайков вне сессий захвата)
	started_profiler = FALSE
	var/summary = "=== ЗАХВАТ ВЫКЛЮЧЕН [automatic ? "(по таймеру)" : "([stopper_key])"]: спайков за сессию [session_spike_count], дампов профайлера [profile_dumps_done] ==="
	write_to_log(summary)
	if(!suppress_side_effects)
		message_admins("Захват тик-спайков завершён: спайков [session_spike_count], худший [round(worst_drift_ms)]мс, дампов профайлера [profile_dumps_done]. Файлы в папке логов раунда.")

/// Итоговый текстовый отчёт для верба и для выгрузки мне
/datum/controller/subsystem/tick_spikes/proc/build_report()
	var/list/out = list()
	out += "===== SStick_spikes: отчёт ====="
	out += "время: [time_stamp_from_world(world.time)] (wt [world.time]), тик [world.tick_lag * 100]мс ([world.fps] fps)"
	out += "настройки: порог спайка [spike_threshold_ms]мс, порог тяжёлого прогона [heavy_run_threshold]% тика, анонс от [announce_threshold_ms]мс"
	out += "захват: [capture_until ? "АКТИВЕН до wt [capture_until]" : "выключен"], дампов профайлера: [profile_dumps_done]"
	out += "клиентов: [length(GLOB.clients)], TD тек/быстр/сред/медл: [round(SStime_track.time_dilation_current, 0.1)]% / [round(SStime_track.time_dilation_avg_fast, 0.1)]% / [round(SStime_track.time_dilation_avg, 0.1)]% / [round(SStime_track.time_dilation_avg_slow, 0.1)]%"
	out += "тиков замерено: [samples_collected]"
	out += "спайков: [session_spike_count] (из них кратко в логе: [suppressed_event_count]), худший [round(worst_drift_ms)]мс в [worst_drift_at ? time_stamp_from_world(worst_drift_at) : "-"], суммарно потеряно в спайках ~[round(total_spike_drift_ms)]мс"
	out += "гистограмма дрифтов (мс): [TICK_SPIKES_HISTOGRAM_FLOOR]-[TICK_SPIKES_HISTOGRAM_BUCKET_1]: [drift_histogram[1]] | [TICK_SPIKES_HISTOGRAM_BUCKET_1]-[TICK_SPIKES_HISTOGRAM_BUCKET_2]: [drift_histogram[2]] | [TICK_SPIKES_HISTOGRAM_BUCKET_2]-[TICK_SPIKES_HISTOGRAM_BUCKET_3]: [drift_histogram[3]] | [TICK_SPIKES_HISTOGRAM_BUCKET_3]-[TICK_SPIKES_HISTOGRAM_BUCKET_4]: [drift_histogram[4]] | [TICK_SPIKES_HISTOGRAM_BUCKET_4]+: [drift_histogram[5]]"
	out += "лог событий: [log_path ? log_path : "ещё не создан"]"
	if(length(spike_events))
		out += ""
		out += "----- события ([length(spike_events)] последних) -----"
		for(var/event_text in spike_events)
			out += ""
			out += event_text
	else
		out += "событий пока нет"
	return out.Join("\n")

/datum/controller/subsystem/tick_spikes/proc/write_to_log(text)
	if(suppress_side_effects)
		return
	if(!log_path)
		log_path = "[GLOB.log_directory]/tick_spikes.log"
	WRITE_LOG_NO_FORMAT(log_path, "[text]\n")

#undef TICK_SPIKES_HISTORY
#undef TICK_SPIKES_HEAVY_HISTORY
#undef TICK_SPIKES_SLOW_WORK_HISTORY
#undef TICK_SPIKES_REPORT_WINDOW
#undef TICK_SPIKES_HEAVY_WINDOW
#undef TICK_SPIKES_CLOCK
#undef TICK_SPIKES_MAX_EVENTS
#undef TICK_SPIKES_HISTOGRAM_FLOOR
#undef TICK_SPIKES_HISTOGRAM_BUCKET_1
#undef TICK_SPIKES_HISTOGRAM_BUCKET_2
#undef TICK_SPIKES_HISTOGRAM_BUCKET_3
#undef TICK_SPIKES_HISTOGRAM_BUCKET_4
#undef TICK_SPIKES_CLASSIFY_WINDOW_TICKS
#undef TICK_SPIKES_CLASSIFY_CPU_THRESHOLD
#undef TICK_SPIKES_CLASSIFY_MAP_CPU_THRESHOLD
#undef TICK_SPIKES_SELF_INFLICTED_TICKS
#undef TICK_SPIKE_CLASS_MC
#undef TICK_SPIKE_CLASS_DM
#undef TICK_SPIKE_CLASS_SENDMAPS
#undef TICK_SPIKE_CLASS_EXTERNAL
#undef TICK_SPIKE_CLASS_SELF
