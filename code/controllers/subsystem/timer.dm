/// Controls how many buckets should be kept, each representing a tick. (1 minutes worth)
#define BUCKET_LEN (world.fps*1*60)
/// Helper for getting the correct bucket for a given timer.
/// Округление вверх, а не round(): round() сажал таймер в бакет на полтика раньше срока.
#define BUCKET_POS(timer) (((ROUND_UP((timer.timeToRun - SStimer.head_offset) / world.tick_lag)+1) % BUCKET_LEN)||BUCKET_LEN)
/// Верхняя граница окна бакетов в СЫРОМ времени. Для решения "бакет или second_queue"
/// не годится - сравнивать надо округлённый тик, см. TIMER_FITS_BUCKETS ниже..
/// Считается от head_offset и practical_offset (граница окна бакетов), а не от world.time:
/// старая формула плавала внутри тика и роняла таймеры в "Invalid timer state".
#define TIMER_MAX (SStimer.head_offset + TICKS2DS(BUCKET_LEN + SStimer.practical_offset - 1))
/// Тик колеса, в который ляжет таймер - ТО ЖЕ округление вверх, что и в BUCKET_POS.
#define TIMER_TICK_FROM_HEAD(timer) (ROUND_UP((timer.timeToRun - SStimer.head_offset) / world.tick_lag))
/**
 * Влезает ли таймер в окно колеса бакетов.
 *
 * Сравнивать обязательно ОКРУГЛЁННЫЙ тик, а не сырое время. TIMER_MAX смотрел на сырое,
 * BUCKET_POS раскладывал по ROUND_UP, и на этом расхождении срок ровно в BUCKET_LEN
 * заворачивался РОВНО в текущий курсор - тот же проход колеса тут же его и сметал.
 * Замер: fps=20, head_offset=600.16, курсор=1146 - таймер на 600 дс срабатывал через 0.5 дс.
 * Наружу это вылезало как самоуничтожение tgui_alert с таймаутом от минуты и как бонус
 * стерилизина (ровно 600 дс), гаснущий раньше первого шага операции.
 */
#define TIMER_FITS_BUCKETS(timer) (TIMER_TICK_FROM_HEAD(timer) < BUCKET_LEN + SStimer.practical_offset - 1)
/// Max float with integer precision
#define TIMER_ID_MAX (2**24)
/// Запас (в тиках) до срока таймера, ближе которого перенос из second_queue нельзя откладывать
/// по бюджету тика: недонесённый близкий таймер останется позади practical_offset и словит
/// "Invalid timer state" с полным пересозданием бакетов.
#define TIMER_TRANSFER_STRAND_MARGIN 30
/// Диагностика пакетных addtimer: столько создания за один тик считается бурстом и логируется
/// (в перф-логах видны пакеты ~2500 addtimer одним тиком, источник из профайлера не виден)
#define TIMER_BURST_LOG_THRESHOLD 500

/**
 * # Timer Subsystem
 *
 * Handles creation, callbacks, and destruction of timed events.
 *
 * It is important to understand the buckets used in the timer subsystem are just a series of circular doubly-linked
 * lists. The object at a given index in bucket_list is a /datum/timedevent, the head of a circular list, which has prev
 * and next references for the respective elements in that bucket's circular list.
 */
SUBSYSTEM_DEF(timer)
	name = "Timer"
	wait = 1 // SS_TICKER subsystem, so wait is in ticks
	init_order = INIT_ORDER_TIMER
	priority = FIRE_PRIORITY_TIMER
	flags = SS_TICKER|SS_NO_INIT

	/// Queue used for storing timers that do not fit into the current buckets
	var/list/datum/timedevent/second_queue = list()
	/// A hashlist dictionary used for storing unique timers
	var/list/hashes = list()
	/// world.time of the first entry in the bucket list, effectively the 'start time' of the current buckets
	var/head_offset = 0
	/// Index of the wrap around pivot for buckets. buckets before this are later running buckets wrapped around from the end of the bucket list.
	var/practical_offset = 1
	/// world.tick_lag the bucket was designed for
	var/bucket_resolution = 0
	/// How many timers are in the buckets
	var/bucket_count = 0
	/// List of buckets, each bucket holds every timer that has to run that byond tick
	var/list/bucket_list = list()
	/// List of all active timers associated to their timer ID (for easy lookup)
	var/list/timer_id_dict = list()
	/// Special timers that run in real-time, not BYOND time; these are more expensive to run and maintain
	var/list/clienttime_timers = list()
	/// Contains the last time that a timer's callback was invoked, or the last tick the SS fired if no timers are being processed
	var/last_invoke_tick = 0
	/// Contains the last time that a warning was issued for not invoking callbacks
	var/static/last_invoke_warning = 0
	/// Boolean operator controlling if the timer SS will automatically reset buckets if it fails to invoke callbacks for an extended period of time
	var/static/bucket_auto_reset = TRUE
	/// Сколько раз за раунд колесо бакетов пересобиралось с нуля.
	///
	/// Норма - РОВНО ОДИН, и он приходится на старт: колесо создаётся в PreInit, а fps из
	/// конфига применяется после инициализации подсистем (master.dm), и смена fps честно
	/// пересобирает колесо через world.on_tickrate_change(). Всё сверх этой единицы -
	/// аварийные выходы: минуту с лишним не сработал ни один таймер, или проход наткнулся
	/// на таймер с невозможным сроком. Каждая пересборка стоит полного прохода по бакетам
	/// с сортировкой, и до этого счётчика событие не оставляло в логах ни следа: в
	/// стат-панели видно население колеса, но не то, что колесо под ним уже трижды
	/// пересобрали. Колонка timer_bucket_resets в perf-логе - отсюда.
	///
	/// static, как и три соседа по блоку, и по той же причине: Recover() создаёт НОВЫЙ
	/// экземпляр подсистемы и переносит в него только списки, а сам тут же зовёт
	/// reset_buckets(). Обычная переменная обнулилась бы ровно в тот момент, когда счётчик
	/// нужнее всего, и раунд, переживший падение МК, отчитался бы одной пересборкой.
	///
	/// За границу раунда счётчик при этом НЕ переносится: world.Reboot() переинициализирует
	/// таблицу глобальных переменных мира, а static живёт именно в ней. Доказательство лежит
	/// в самой кодбазе - GLOB.restart_counter приходится гонять через файл
	/// (RESTART_COUNTER_PATH, code/game/world.dm), потому что иначе он ребут не переживает.
	var/static/bucket_reset_count = 0
	/// Дампить ли содержимое колеса при аварийном сбросе бакетов. По умолчанию выключено:
	/// дамп собирает список строк по всем бакетам и по всей second_queue без единого
	/// тик-чека, то есть срабатывает ровно в тот момент, когда сервер и так плох.
	/// Включать варедитом, когда ловишь "Invalid timer state".
	var/static/log_timers_on_bucket_reset = FALSE

/datum/controller/subsystem/timer/PreInit()
	bucket_list.len = BUCKET_LEN
	head_offset = world.time
	bucket_resolution = world.tick_lag

/datum/controller/subsystem/timer/stat_entry(msg)
	msg = "B:[bucket_count] P:[length(second_queue)] H:[length(hashes)] C:[length(clienttime_timers)] S:[length(timer_id_dict)] RST:[bucket_reset_count]"
	return ..()

/datum/controller/subsystem/timer/last_task()
	return "колесо: курсор [practical_offset] из [BUCKET_LEN], таймеров в бакетах [bucket_count], в second_queue [length(second_queue)], сбросов колеса [bucket_reset_count]"

/**
 * Сбрасывает в лог мира состояние колеса таймеров.
 * full = FALSE пишет только шапку: полный проход по бакетам и second_queue стоит дорого,
 * а зовётся он в момент аварийного сброса, когда подсистема уже захлебнулась.
 */
/datum/controller/subsystem/timer/proc/dump_timer_buckets(full = TRUE)
	var/list/to_log = list("Timer bucket reset. world.time: [world.time], head_offset: [head_offset], practical_offset: [practical_offset]")
	if (full)
		for (var/i in 1 to length(bucket_list))
			var/datum/timedevent/bucket_head = bucket_list[i]
			if (!bucket_head)
				continue

			to_log += "Active timers at index [i]:"
			var/datum/timedevent/bucket_node = bucket_head
			var/anti_loop_check = 1
			do
				to_log += get_timer_debug_string(bucket_node)
				bucket_node = bucket_node.next
				anti_loop_check--
			while(bucket_node && bucket_node != bucket_head && anti_loop_check)

		to_log += "Active timers in the second_queue queue:"
		for(var/I in second_queue)
			to_log += get_timer_debug_string(I)

	// Dump all the logged data to the world log
	log_world(to_log.Join("\n"))

/datum/controller/subsystem/timer/fire(resumed = FALSE)
	// Store local references to datum vars as it is faster to access them
	var/lit = last_invoke_tick
	var/list/bucket_list = src.bucket_list
	var/last_check = world.time - TICKS2DS(BUCKET_LEN * 1.5)

	// If there are no timers being tracked, then consider now to be the last invoked time
	if(!bucket_count)
		last_invoke_tick = world.time

	// Check that we have invoked a callback in the last 1.5 minutes of BYOND time,
	// and throw a warning and reset buckets if this is true
	if(lit && lit < last_check && head_offset < last_check && last_invoke_warning < last_check)
		last_invoke_warning = world.time
		var/msg = "No regular timers processed in the last [BUCKET_LEN * 1.5] ticks[bucket_auto_reset ? ", resetting buckets" : ""]!"
		message_admins(msg)
		WARNING(msg)
		if(bucket_auto_reset)
			bucket_resolution = 0
		dump_timer_buckets(log_timers_on_bucket_reset)

	// Process client-time timers
	var/static/next_clienttime_timer_index = 0
	if (next_clienttime_timer_index)
		clienttime_timers.Cut(1, min(next_clienttime_timer_index + 1, length(clienttime_timers) + 1))
		next_clienttime_timer_index = 0
	next_clienttime_timer_index = 1
	while (next_clienttime_timer_index <= length(clienttime_timers))
		if (MC_TICK_CHECK)
			next_clienttime_timer_index--
			break
		var/datum/timedevent/ctime_timer = clienttime_timers[next_clienttime_timer_index]
		if (ctime_timer.timeToRun > REALTIMEOFDAY)
			next_clienttime_timer_index--
			break

		var/datum/callback/callBack = ctime_timer.callBack
		if (!callBack)
			if (ctime_timer.spent || QDELETED(ctime_timer))
				next_clienttime_timer_index++
				continue
			CRASH("Invalid timer: [get_timer_debug_string(ctime_timer)] world.time: [world.time], \
				head_offset: [head_offset], practical_offset: [practical_offset], REALTIMEOFDAY: [REALTIMEOFDAY]")

		ctime_timer.spent = REALTIMEOFDAY
		var/invoke_started = TICK_USAGE
		callBack.InvokeAsync()
		var/invoke_cost_ms = TICK_DELTA_TO_MS(TICK_USAGE - invoke_started)
		if(SStick_spikes && invoke_cost_ms >= SStick_spikes.slow_work_threshold_ms)
			SStick_spikes.record_slow_work("таймер (clienttime)", SStick_spikes.callback_desc(callBack), invoke_cost_ms)

		var/pre_len = length(clienttime_timers)
		if(ctime_timer.flags & TIMER_LOOP)
			// Колбек мог удалить собственный таймер. Обычный путь этого не даёт (datum/Destroy
			// пропускает спущенные таймеры), но TIMER_DELETE_ME снимает и спущенные - именно
			// с ним заведён зацикленный звук, см. _looping_sound.dm. Возврат удалённого
			// таймера в очередь означает запись без колбека, то есть "Invalid timer" на
			// следующем проходе и пересборку всего колеса.
			if(!QDELETED(ctime_timer))
				ctime_timer.spent = 0
				ctime_timer.timeToRun = REALTIMEOFDAY + ctime_timer.wait
				BINARY_INSERT(ctime_timer, clienttime_timers, /datum/timedevent, ctime_timer, timeToRun, COMPARE_KEY)
		else
			qdel(ctime_timer)
		// If list shrank (qdel removed element), stay at same index; otherwise advance
		if(length(clienttime_timers) >= pre_len)
			next_clienttime_timer_index++

	// Remove invoked client-time timers
	if (next_clienttime_timer_index)
		clienttime_timers.Cut(1, min(next_clienttime_timer_index + 1, length(clienttime_timers) + 1))
		next_clienttime_timer_index = 0

	// Раньше здесь стоял ранний return по бюджету тика. Он означал, что на любом
	// перегруженном тике бакетное колесо не крутилось ВООБЩЕ, и обычные таймеры сползали
	// в следующий бакет пачкой. Колесо обязано делать хотя бы один шаг: внутренние
	// MC_TICK_CHECK ниже уже прерывают его после первого же колбека.

	// Check for when we need to loop the buckets, this occurs when
	// the head_offset is approaching BUCKET_LEN ticks in the past
	if (practical_offset > BUCKET_LEN)
		head_offset += TICKS2DS(BUCKET_LEN)
		practical_offset = 1
		resumed = FALSE

	// Check for when we have to reset buckets, typically from auto-reset
	if ((length(bucket_list) != BUCKET_LEN) || (world.tick_lag != bucket_resolution))
		reset_buckets()
		bucket_list = src.bucket_list
		resumed = FALSE


	// Iterate through each bucket starting from the practical offset
	while (practical_offset <= BUCKET_LEN && head_offset + ((practical_offset - 1) * world.tick_lag) <= world.time)
		var/datum/timedevent/timer
		while ((timer = bucket_list[practical_offset]))
			var/datum/callback/callBack = timer.callBack
			if (!callBack)
				if (!timer.spent && !QDELETED(timer))
					// Живой таймер без колбека - колесо действительно битое, спасает только пересборка.
					bucket_resolution = null // force bucket recreation
					CRASH("Invalid timer: [get_timer_debug_string(timer)] world.time: [world.time], \
						head_offset: [head_offset], practical_offset: [practical_offset]")
				// А вот спущенный или уже удалённый таймер в голове бакета - это одна потерянная
				// запись, а не битое колесо, и полная пересборка за неё несоразмерна: она стоит
				// прохода по всем бакетам с сортировкой всех таймеров мира. Соседний клиентский
				// цикл такую запись просто пропускает; здесь снимаем её обычным путём ниже.
				// Заодно bucket_reset_count начинает считать настоящие аварии, а не чужие qdel.
				stack_trace("Spent timer left in bucket head: [get_timer_debug_string(timer)] world.time: [world.time], \
					head_offset: [head_offset], practical_offset: [practical_offset]")

			// Голову бакета снимает сам eject по записанной позиции. Страховка на случай,
			// если позиция всё-таки разошлась со слотом: внешний while достаёт голову заново,
			// и неснятая голова означала бы вечный цикл внутри тика, то есть повисший мир.
			// Дешевле одного сравнения, а стоимость промаха - весь сервер.
			var/datum/timedevent/next_in_bucket = timer.next
			timer.bucketEject() //pop the timer off of the bucket list.
			if (bucket_list[practical_offset] == timer)
				// Кольцо из самого себя тоже разрываем: иначе слот снова укажет на этот таймер.
				bucket_list[practical_offset] = (next_in_bucket == timer) ? null : next_in_bucket
				stack_trace("Timer bucket head survived its own eject at [practical_offset]: [get_timer_debug_string(timer)]")

			// Invoke callback if possible. Колбек в условии не для красоты: выше сюда теперь
			// доходит и запись без колбека (спущенная или удалённая), и без этой проверки
			// путь "spent пуст, а колбека уже нет" кончился бы обращением к null.
			if (callBack && !timer.spent)
				timer.spent = world.time
				// Замер синхронной части колбека (до первого сна): дорогой таймер-колбек
				// раньше был неотличим от анонимного "DM вне МК" в логе тик-спайков
				var/invoke_started = TICK_USAGE
				callBack.InvokeAsync()
				var/invoke_cost_ms = TICK_DELTA_TO_MS(TICK_USAGE - invoke_started)
				if(SStick_spikes && invoke_cost_ms >= SStick_spikes.slow_work_threshold_ms)
					SStick_spikes.record_slow_work("таймер", SStick_spikes.callback_desc(callBack), invoke_cost_ms)
				last_invoke_tick = world.time

			// Возвращается в очередь только живой зацикленный таймер с колбеком. Удалённый
			// внутри собственного колбека (datum/Destroy пропускает спущенные таймеры, но
			// TIMER_DELETE_ME снимает и их - с ним заведён зацикленный звук, см.
			// _looping_sound.dm) уже снят с колеса, и возврат положил бы в бакет запись без
			// колбека: то самое "Invalid timer" на следующем проходе. Всё остальное уходит
			// в qdel - в том числе спущенный безколбечный таймер, который иначе остался бы
			// висеть в timer_id_dict до конца раунда.
			if (timer.flags & TIMER_LOOP && timer.callBack && !QDELETED(timer)) // Prepare looping timers to re-enter the queue
				timer.spent = 0
				timer.timeToRun = world.time + timer.wait
				timer.bucketJoin()
			else if (!QDELETED(timer))
				qdel(timer)

			if (MC_TICK_CHECK)
				break

		if (!bucket_list[practical_offset])
			// Empty the bucket, check if anything in the secondary queue should be shifted to this bucket
			bucket_list[practical_offset++] = null
			// Дальше пустые бакеты проматываются ПАЧКОЙ, а не по одному за прогон.
			//
			// Хвостовой MC_TICK_CHECK прерывает проход после первого же бакета, как только
			// тик исчерпан, а под нагрузкой МК зовёт подсистему заметно реже раза в тик:
			// sleep_delta растёт, и одна итерация петли приходится на десятки тиков. Колесо
			// в этих условиях идёт медленнее реального времени и, отстав однажды, не
			// догоняет уже никогда. Замер на multiz_debug в CI: мир прошёл 1934 дс, курсор
			// колеса - 30 дс, полтора процента скорости. Дальше отставание только росло
			// (659 -> 1765 -> 2564 дс), TIMER_FITS_BUCKETS переставал пускать в колесо всё
			// новое, second_queue пухла (73 -> 115), и ни один обычный таймер за раунд уже
			// не срабатывал: тесты, ждущие отложку, выпадали по потолку ожидания.
			//
			// Пустой бакет работы не несёт - чтение слота и инкремент. Уступать ради них
			// целый прогон подсистемы незачем, а вот возможность догнать мир это возвращает.
			practical_offset = skip_empty_buckets(bucket_list, practical_offset, min(BUCKET_LEN, round((world.time - head_offset) / world.tick_lag) + 1))
			var/i = 0
			for (i in 1 to length(second_queue))
				timer = second_queue[i]
				if (!TIMER_FITS_BUCKETS(timer))
					i--
					break

				// Check for timers that are scheduled to run in the past
				if (timer.timeToRun < head_offset)
					bucket_resolution = null // force bucket recreation
					stack_trace("[i] Invalid timer state: Timer in long run queue with a time to run less then head_offset. \
						[get_timer_debug_string(timer)] world.time: [world.time], head_offset: [head_offset], practical_offset: [practical_offset]")
					break

				// Check for timers that are not capable of being scheduled to run without rebuilding buckets
				if (timer.timeToRun < head_offset + TICKS2DS(practical_offset - 1))
					bucket_resolution = null // force bucket recreation
					stack_trace("[i] Invalid timer state: Timer in long run queue that would require a backtrack to transfer to \
						short run queue. [get_timer_debug_string(timer)] world.time: [world.time], head_offset: [head_offset], practical_offset: [practical_offset]")
					break

				// Волна переноса без лимита душит тик: тысячи таймеров, поставленных разом на
				// роундстарте, доезжают до бакетного окна одной пачкой (~200мс одним прогоном).
				// Прерываемся по бюджету тика, но только пока следующий таймер не близок к сроку -
				// близкие обязаны попасть в бакет сейчас, см. TIMER_TRANSFER_STRAND_MARGIN.
				if (timer.timeToRun > world.time + TICKS2DS(TIMER_TRANSFER_STRAND_MARGIN) && MC_TICK_CHECK)
					i--
					break

				timer.bucketJoin()
			if (i)
				second_queue.Cut(1, i+1)
		if (MC_TICK_CHECK)
			break

/**
 * Проматывает курсор через подряд идущие ПУСТЫЕ бакеты, чьё время уже наступило.
 *
 * Возвращает позицию первого бакета, ради которого стоит остановиться: непустого или
 * ещё не наступившего. Отдельным проком - чтобы поведение проверялось юнит-тестом на
 * синтетическом колесе, без правки боевого SStimer.
 *
 * last_due - последний наступивший бакет, уже прижатый к длине колеса вызывающим.
 */
/datum/controller/subsystem/timer/proc/skip_empty_buckets(list/bucket_list, position, last_due)
	while (position <= last_due && !bucket_list[position])
		position++
	return position

/**
 * Generates a string with details about the timed event for debugging purposes
 */
/datum/controller/subsystem/timer/proc/get_timer_debug_string(datum/timedevent/TE)
	if(!TE)
		return "Timer: NULL"
	. = "Timer: [TE.id] ([REF(TE)]), TTR: [TE.timeToRun], wait:[TE.wait], flags:[TE.flags]"
	. += ", Prev: [TE.prev ? REF(TE.prev) : "NULL"], Next: [TE.next ? REF(TE.next) : "NULL"]"
	if(TE.callBack)
		. += ", callBack: [TE.callBack.object == GLOBAL_PROC ? "GLOBAL_PROC" : TE.callBack.object?.type]->[TE.callBack.delegate]"
	if(TE.source)
		. += ", source: [TE.source]"
	if(TE.spent)
		. += ", SPENT([TE.spent])"
	if(QDELETED(TE))
		. += ", QDELETED"
	if(!TE.callBack)
		. += ", NO CALLBACK"

/**
 * Destroys the existing buckets and creates new buckets from the existing timed events
 */
/datum/controller/subsystem/timer/proc/reset_buckets()
	// Считаем и пишем ДО работы: пересборка идёт полным проходом по колесу с сортировкой,
	// и если сервер умрёт на ней самой, единственным следом останется эта строка.
	bucket_reset_count++
	WARNING("Timer buckets reset (#[bucket_reset_count]), this may cause timers to lag. \
		world.time: [world.time], head_offset: [head_offset], practical_offset: [practical_offset], \
		bucket_count: [bucket_count], second_queue: [length(second_queue)]")

	var/list/bucket_list = src.bucket_list // Store local reference to datum var, this is faster
	var/list/alltimers = list()

	// Get all timers currently in the buckets
	for (var/bucket_head in bucket_list)
		if (!bucket_head) // if bucket is empty for this tick
			continue
		var/datum/timedevent/bucket_node = bucket_head
		do
			alltimers += bucket_node
			bucket_node = bucket_node.next
		while(bucket_node && bucket_node != bucket_head)

	// Empty the list by zeroing and re-assigning the length
	bucket_list.len = 0
	bucket_list.len = BUCKET_LEN

	// Reset values for the subsystem to their initial values
	practical_offset = 1
	bucket_count = 0
	head_offset = world.time
	bucket_resolution = world.tick_lag

	// Add all timed events from the secondary queue as well
	alltimers += second_queue

	// If there are no timers being tracked by the subsystem,
	// there is no need to do any further rebuilding
	if (!length(alltimers))
		return

	// Sort all timers by time to run
	sortTim(alltimers, GLOBAL_PROC_REF(cmp_timer))

	// Get the earliest timer, and if the TTR is earlier than the current world.time,
	// then set the head offset appropriately to be the earliest time tracked by the
	// current set of buckets
	var/datum/timedevent/head = alltimers[1]
	if (head.timeToRun < head_offset)
		head_offset = head.timeToRun

	// Iterate through each timed event and insert it into an appropriate bucket,
	// up unto the point that we can no longer insert into buckets as the TTR
	// is outside the range we are tracking, then insert the remainder into the
	// secondary queue
	var/new_bucket_count
	var/i = 1
	for (i in 1 to length(alltimers))
		var/datum/timedevent/timer = alltimers[i]
		if (!timer)
			continue
		timer.in_timer_bucket_queue = FALSE
		timer.in_timer_second_queue = FALSE
		timer.in_timer_clienttime_queue = FALSE
		timer.bucket_pos = BUCKET_POS_NONE
		timer.next = null
		timer.prev = null

		// Check that the TTR is within the range covered by buckets, when exceeded we've finished
		if (!TIMER_FITS_BUCKETS(timer))
			i--
			break

		// Check that timer has a valid callback and hasn't been invoked
		if (!timer.callBack || timer.spent)
			WARNING("Invalid timer: [get_timer_debug_string(timer)] world.time: [world.time], \
				head_offset: [head_offset], practical_offset: [practical_offset]")
			if (timer.callBack)
				qdel(timer)
			continue

		// Insert the timer into the bucket, and perform necessary circular doubly-linked list operations
		new_bucket_count++
		var/bucket_pos = BUCKET_POS(timer)
		var/datum/timedevent/bucket_head = bucket_list[bucket_pos]
		timer.bucket_pos = bucket_pos
		timer.in_timer_bucket_queue = TRUE
		if (!bucket_head)
			bucket_list[bucket_pos] = timer
			continue
		if (!bucket_head.prev)
			bucket_head.prev = bucket_head
		timer.next = bucket_head
		timer.prev = bucket_head.prev
		timer.next.prev = timer
		timer.prev.next = timer

	// Cut the timers that are tracked by the buckets from the secondary queue
	if (i)
		alltimers.Cut(1, i + 1)
	second_queue = alltimers
	for (var/datum/timedevent/timer in second_queue)
		timer.in_timer_bucket_queue = FALSE
		timer.in_timer_second_queue = TRUE
		timer.in_timer_clienttime_queue = FALSE
		timer.bucket_pos = BUCKET_POS_NONE
		timer.next = null
		timer.prev = null
	bucket_count = new_bucket_count


/datum/controller/subsystem/timer/Recover()
	second_queue |= SStimer.second_queue
	hashes |= SStimer.hashes
	timer_id_dict |= SStimer.timer_id_dict
	bucket_list |= SStimer.bucket_list

/**
 * # Timed Event
 *
 * This is the actual timer, it contains the callback and necessary data to maintain
 * the timer.
 *
 * See the documentation for the timer subsystem for an explanation of the buckets referenced
 * below in next and prev
 */
/datum/timedevent
	/// ID used for timers when the TIMER_STOPPABLE flag is present
	var/id
	/// The callback to invoke after the timer completes
	var/datum/callback/callBack
	/// The time at which the callback should be invoked at
	var/timeToRun
	/// The length of the timer
	var/wait
	/// Unique hash generated when TIMER_UNIQUE flag is present
	var/hash
	/// The source of the timedevent, whatever called addtimer
	var/source
	/// Flags associated with the timer, see _DEFINES/subsystems.dm
	var/flags
	/// Time at which the timer was invoked or destroyed
	var/spent = 0
	// Отладочного имени у таймера больше нет. Раньше здесь лежал var/name, который
	// bucketJoin собирал интерполяцией с \ref на КАЖДЫЙ созданный таймер - самая горячая
	// аллокация в игре и та самая строка, на которую в раундах 10003 и 10005 (17.08.2026)
	// пришёлся сырой дамп BYOND при молчаливой смерти процесса. Всё, что в ней было -
	// id, timeToRun, wait и flags - и так лежит полями рядом, поэтому описание собирает
	// get_timer_debug_string() из живых значений и только когда оно кому-то понадобилось.
	// Апстрим tg ушёл от этой строки по той же причине ("string generation is a bitch").
	/// Next timed event in the bucket
	var/datum/timedevent/next
	/// Previous timed event in the bucket
	var/datum/timedevent/prev
	/// TRUE while this timer is stored in SStimer.bucket_list
	var/in_timer_bucket_queue = FALSE
	/// Индекс бакета, в который таймер положили при вставке. BUCKET_POS_NONE, если он не в колесе.
	///
	/// Пересчитать его по BUCKET_POS() нельзя: позиция считается от head_offset, а head_offset
	/// прыгает вперёд на целое колесо каждый раз, когда курсор доходит до конца. Таймер при
	/// этом остаётся лежать в СВОЁМ слоте, и BUCKET_POS начинает показывать на чужой. Раньше
	/// bucketEject() расходился с этим сканом bucket_list.Find(src) по всем 1200 слотам -
	/// скан, который для любого не-головы всегда возвращает ноль, а для головы возвращает то,
	/// что и так записано здесь.
	var/bucket_pos = BUCKET_POS_NONE
	/// TRUE while this timer is stored in SStimer.second_queue
	var/in_timer_second_queue = FALSE
	/// TRUE while this timer is stored in SStimer.clienttime_timers
	var/in_timer_clienttime_queue = FALSE

/datum/timedevent/New(datum/callback/callBack, wait, flags, hash, source)
	var/static/nextid = 1
	id = TIMER_ID_NULL
	src.callBack = callBack
	src.wait = wait
	src.flags = flags
	src.hash = hash
	src.source = source

	// Determine time at which the timer's callback should be invoked
	timeToRun = (flags & TIMER_CLIENT_TIME ? REALTIMEOFDAY : world.time) + wait

	// Include the timer in the hash table if the timer is unique
	if (flags & TIMER_UNIQUE)
		SStimer.hashes[hash] = src

	// Generate ID for the timer if the timer is stoppable, include in the timer id dictionary
	if (flags & TIMER_STOPPABLE)
		id = num2text(nextid, 100)
		if (nextid >= SHORT_REAL_LIMIT)
			nextid += min(1, 2 ** round(nextid / SHORT_REAL_LIMIT))
		else
			nextid++
		SStimer.timer_id_dict[id] = src

	if ((timeToRun < world.time || timeToRun < SStimer.head_offset) && !(flags & TIMER_CLIENT_TIME))
		CRASH("Invalid timer state: Timer created that would require a backtrack to run (addtimer would never let this happen): [SStimer.get_timer_debug_string(src)]")

	if (callBack.object != GLOBAL_PROC && !QDESTROYING(callBack.object))
		LAZYADD(callBack.object.active_timers, src)

	bucketJoin()

/datum/timedevent/Destroy()
	..()

	if (flags & TIMER_UNIQUE && hash)
		SStimer.hashes -= hash

	var/datum/cb_object = callBack?.object
	if (cb_object && cb_object != GLOBAL_PROC)
		var/list/timers = cb_object.active_timers
		if (timers)
			timers -= src
			if (!length(timers))
				cb_object.active_timers = null

	if(callBack)
		callBack.object = null
		callBack.arguments = null
		callBack = null

	if (flags & TIMER_STOPPABLE)
		SStimer.timer_id_dict -= id

	if (flags & TIMER_CLIENT_TIME)
		if (!spent)
			spent = world.time
		if (in_timer_clienttime_queue)
			SStimer.clienttime_timers -= src
		in_timer_clienttime_queue = FALSE
		in_timer_bucket_queue = FALSE
		in_timer_second_queue = FALSE
		bucket_pos = BUCKET_POS_NONE
		next = null
		prev = null
		return QDEL_HINT_IWILLGC

	if (!spent)
		spent = world.time
	// Спущенный таймер тоже проходит через bucketEject(). Раньше здесь чинились только
	// соседи по цепочке, а слот в bucket_list оставался смотреть на удаляемый таймер -
	// и следующий проход колеса находил в голове бакета таймер без колбека, то есть ровно
	// "Invalid timer". Для уже выброшенного таймера eject стоит одной проверки флага.
	bucketEject()
	in_timer_bucket_queue = FALSE
	in_timer_second_queue = FALSE
	in_timer_clienttime_queue = FALSE
	next = null
	prev = null
	return QDEL_HINT_IWILLGC

/**
 * Removes this timed event from any relevant buckets, or the secondary queue
 */
/datum/timedevent/proc/bucketEject()
	if (in_timer_second_queue)
		SStimer.second_queue -= src
		in_timer_second_queue = FALSE
		in_timer_bucket_queue = FALSE
		in_timer_clienttime_queue = FALSE
		prev = null
		next = null
		return

	if (!in_timer_bucket_queue)
		in_timer_second_queue = FALSE
		in_timer_clienttime_queue = FALSE
		// Соседей по цепочке чиним и здесь. Таймер вне колеса ссылок иметь не должен, но
		// раньше эту страховку держал Destroy() отдельной веткой для спущенных таймеров,
		// и терять её при переносе ветки сюда незачем.
		if(prev != next)
			prev?.next = next
			next?.prev = prev
		else
			prev?.next = null
			next?.prev = null
		prev = null
		next = null
		return

	// Позиция записана при вставке, искать её не нужно: если таймер был головой бакета,
	// голову перенимает следующий за ним (у одиночки next пуст, и слот обнуляется).
	// Не-голова из bucket_list не видна вообще, и трогать список для неё не надо.
	var/list/bucket_list = SStimer.bucket_list
	if(bucket_pos >= 1 && bucket_pos <= length(bucket_list) && bucket_list[bucket_pos] == src)
		bucket_list[bucket_pos] = next
	bucket_pos = BUCKET_POS_NONE
	SStimer.bucket_count--

	// Remove the timed event from the bucket, ensuring to maintain
	// the integrity of the bucket's list if relevant.
	// Через ?. обе ветки: у полукольца (одна ссылка есть, вторая пуста) prev != next, и
	// прямое обращение падало рантаймом на null.next ровно в момент, когда список уже битый.
	if(prev != next)
		prev?.next = next
		next?.prev = prev
	else
		prev?.next = null
		next?.prev = null
	in_timer_bucket_queue = FALSE
	in_timer_second_queue = FALSE
	in_timer_clienttime_queue = FALSE
	prev = next = null

/**
 * Attempts to add this timed event to a bucket, will enter the secondary queue
 * if there are no appropriate buckets at this time.
 *
 * Secondary queueing of timed events will occur when the timespan covered by the existing
 * buckets is exceeded by the time at which this timed event is scheduled to be invoked.
 * If the timed event is tracking client time, it will be added to a special bucket.
 */
/datum/timedevent/proc/bucketJoin()
	// Здесь была сборка отладочного имени интерполяцией. Её больше нет: описание таймера
	// строит get_timer_debug_string() по требованию, см. комментарий на месте var/name.

	// Check if this timed event should be diverted to the client time bucket, or the secondary queue
	in_timer_bucket_queue = FALSE
	in_timer_second_queue = FALSE
	in_timer_clienttime_queue = FALSE
	var/list/L
	if (flags & TIMER_CLIENT_TIME)
		L = SStimer.clienttime_timers
		in_timer_clienttime_queue = TRUE
	else if (!TIMER_FITS_BUCKETS(src))
		L = SStimer.second_queue
		in_timer_second_queue = TRUE
	if(L)
		next = null
		prev = null
		bucket_pos = BUCKET_POS_NONE
		BINARY_INSERT(src, L, /datum/timedevent, src, timeToRun, COMPARE_KEY)
		return

	// Get a local reference to the bucket list, this is faster than referencing the datum
	var/list/bucket_list = SStimer.bucket_list

	// Find the correct bucket for this timed event
	bucket_pos = BUCKET_POS(src)
	var/datum/timedevent/bucket_head = bucket_list[bucket_pos]
	in_timer_bucket_queue = TRUE
	SStimer.bucket_count++

	// If there is no timed event at this position, then the bucket is 'empty'
	// and we can just set this event to that position
	if (!bucket_head)
		bucket_list[bucket_pos] = src
		next = null
		prev = null
		return

	// Otherwise, we merely add this timed event into the bucket, which is a
	// circularly doubly-linked list
	if (!bucket_head.prev)
		bucket_head.prev = bucket_head
	next = bucket_head
	prev = bucket_head.prev
	next.prev = src
	prev.next = src

/**
 * Returns a string of the type of the callback for this timer
 */
/datum/timedevent/proc/getcallingtype()
	. = "ERROR"
	if (!callBack)
		return
	if (callBack.object == GLOBAL_PROC)
		. = "GLOBAL_PROC"
	else if (callBack.object)
		. = "[callBack.object.type]"

/**
 * Create a new timer and insert it in the queue.
 * You should not call this directly, and should instead use the addtimer macro, which includes source information.
 *
 * Arguments:
 * * callback the callback to call on timer finish
 * * wait deciseconds to run the timer for
 * * flags flags for this timer, see: code\__DEFINES\subsystems.dm
 */
/proc/_addtimer(datum/callback/callback, wait = 0, flags = 0, file, line)
	if (!callback)
		CRASH("addtimer called without a callback")

	if (wait < 0)
		stack_trace("addtimer called with a negative wait. Converting to [world.tick_lag]")

	if (callback.object != GLOBAL_PROC && QDELETED(callback.object) && !QDESTROYING(callback.object))
		stack_trace("addtimer called with a callback assigned to a qdeleted object. In the future such timers will not \
			be supported and may refuse to run or run with a 0 wait")

	wait = max(CEILING(wait, world.tick_lag), world.tick_lag)

	if(wait >= INFINITY)
		CRASH("Attempted to create timer with INFINITY delay")

	// Generate hash if relevant for timed events with the TIMER_UNIQUE flag
	var/hash
	if (flags & TIMER_UNIQUE)
		var/list/hashlist = list(callback.object, "([REF(callback.object)])", callback.delegate, flags & TIMER_CLIENT_TIME)
		if(!(flags & TIMER_NO_HASH_WAIT))
			hashlist += wait
		hashlist += callback.arguments
		hash = hashlist.Join("|||||||")

		var/datum/timedevent/hash_timer = SStimer.hashes[hash]
		if(hash_timer)
			if (hash_timer.spent) // it's pending deletion, pretend it doesn't exist.
				hash_timer.hash = null // but keep it from accidentally deleting us
			else
				if (flags & TIMER_OVERRIDE)
					hash_timer.hash = null // no need having it delete it's hash if we are going to replace it
					qdel(hash_timer)
				else
					if (hash_timer.flags & TIMER_STOPPABLE)
						. = hash_timer.id
					return
	else if(flags & TIMER_OVERRIDE)
		stack_trace("TIMER_OVERRIDE used without TIMER_UNIQUE")

	// Детектор пакетных addtimer: тысячи таймеров одним тиком душат тик на bucketJoin,
	// а создатель не виден в профайлере (кост размазан). Логируем пример колбека бурста.
	var/static/burst_world_time = 0
	var/static/burst_count = 0
	if(world.time != burst_world_time)
		burst_world_time = world.time
		burst_count = 0
	burst_count++
	if(burst_count == TIMER_BURST_LOG_THRESHOLD || burst_count == TIMER_BURST_LOG_THRESHOLD * 4)
		log_game("TIMER BURST: [burst_count]+ addtimer за один тик (wt [world.time]). Пример колбека: [callback.object == GLOBAL_PROC ? "GLOBAL_PROC" : "[callback.object] ([callback.object?.type])"] proc [callback.delegate], wait [wait][file ? ", источник [file]:[line]" : ""]")

	var/datum/timedevent/timer = new(callback, wait, flags, hash, file && "[file]:[line]")
	return timer.id

/**
 * Delete a timer
 *
 * Arguments:
 * * id a timerid or a /datum/timedevent
 */
/proc/deltimer(id)
	if (!id)
		return FALSE
	if (id == TIMER_ID_NULL)
		CRASH("Tried to delete a null timerid. Use TIMER_STOPPABLE flag")
	if (istype(id, /datum/timedevent))
		qdel(id)
		return TRUE
	//id is string
	var/datum/timedevent/timer = SStimer.timer_id_dict[id]
	if (timer && !timer.spent)
		qdel(timer)
		return TRUE
	return FALSE

/**
 * Get the remaining deciseconds on a timer
 *
 * Arguments:
 * * id a timerid or a /datum/timedevent
 */
/proc/timeleft(id)
	if (!id)
		return null
	if (id == TIMER_ID_NULL)
		CRASH("Tried to get timeleft of a null timerid. Use TIMER_STOPPABLE flag")
	if (istype(id, /datum/timedevent))
		var/datum/timedevent/timer = id
		return timer.timeToRun - world.time
	//id is string
	var/datum/timedevent/timer = SStimer.timer_id_dict[id]
	return (timer && !timer.spent) ? timer.timeToRun - world.time : null

#undef BUCKET_LEN
#undef BUCKET_POS
#undef TIMER_MAX
#undef TIMER_TICK_FROM_HEAD
#undef TIMER_FITS_BUCKETS
#undef TIMER_ID_MAX
#undef TIMER_TRANSFER_STRAND_MARGIN
#undef TIMER_BURST_LOG_THRESHOLD
