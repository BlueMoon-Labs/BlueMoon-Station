/// Controls how many buckets should be kept, each representing a tick. (30 seconds worth)
#define BUCKET_LEN (world.fps * 1 * 30)
/// Тик колеса, в который ляжет сообщение. Округление вверх, как в SStimer: round() это floor,
/// и он сажает сообщение в бакет на полтика раньше срока.
#define BUCKET_TICK_FROM_HEAD(scheduled_destruction) (ROUND_UP((scheduled_destruction - SSrunechat.head_offset) / world.tick_lag))
/// Helper for getting the correct bucket for a given chatmessage
#define BUCKET_POS(scheduled_destruction) (((BUCKET_TICK_FROM_HEAD(scheduled_destruction) + 1) % BUCKET_LEN) || BUCKET_LEN)
/**
 * Влезает ли сообщение в окно бакетов.
 *
 * Здесь стоял BUCKET_LIMIT - тот самый расчёт по сырому world.time, который в SStimer уже
 * заменён на TIMER_FITS_BUCKETS. Он плавал внутри тика и расходился с BUCKET_POS: сообщение
 * признавалось влезающим, а раскладка отправляла его в слот ПОЗАДИ курсора. Такое сообщение
 * либо сметалось тем же проходом (рунчат гас, не начав жить), либо ждало полного оборота
 * колеса - лишних тридцать секунд на экране. Сравнивать надо тот же округлённый тик, каким
 * считается позиция.
 */
#define BUCKET_FITS(scheduled_destruction) (BUCKET_TICK_FROM_HEAD(scheduled_destruction) < BUCKET_LEN + SSrunechat.practical_offset - 1)

/**
 * # Runechat Subsystem
 *
 * Maintains a timer-like system to handle destruction of runechat messages. Much of this code is modeled
 * after or adapted from the timer subsystem.
 *
 * Note that this has the same structure for storing and queueing messages as the timer subsystem does
 * for handling timers: the bucket_list is a list of chatmessage datums, each of which are the head
 * of a circularly linked list. Any given index in bucket_list could be null, representing an empty bucket.
 */
SUBSYSTEM_DEF(runechat)
	name = "Runechat"
	flags = SS_TICKER | SS_NO_INIT
	wait = 1
	priority = FIRE_PRIORITY_RUNECHAT

	/// world.time of the first entry in the bucket list, effectively the 'start time' of the current buckets
	var/head_offset = 0
	/// Index of the first non-empty bucket
	var/practical_offset = 1
	/// world.tick_lag the bucket was designed for
	var/bucket_resolution = 0
	/// How many messages are in the buckets
	var/bucket_count = 0
	/// List of buckets, each bucket holds every message that has to be killed that byond tick
	var/list/bucket_list = list()
	/// Queue used for storing messages that are scheduled for deletion too far in the future for the buckets
	var/list/datum/chatmessage/second_queue = list()
	/// Сколько раз за раунд колесо пересобиралось с нуля.
	///
	/// Ровно тот же счётчик, что SStimer.bucket_reset_count, и заведён по той же причине:
	/// пересборка стоит полного прохода по колесу с сортировкой всех живых сообщений, а
	/// следа не оставляла никакого. Расходиться двум копиям одного колеса нельзя - и это
	/// касается приборов не меньше, чем самой раскладки: разбор молчаливой смерти процесса
	/// видел, сколько раз пересобиралось колесо таймеров, и не мог сказать, пересобиралось
	/// ли рядом второе такое же.
	var/static/runechat_bucket_reset_count = 0
	/// Сообщение, на котором fire() прервался по бюджету тика, чтобы продолжить с него.
	///
	/// Переменная подсистемы, а не статик внутри fire(): статик пережил бы пересборку
	/// колеса и указывал бы в старую раскладку, а сбросить его снаружи было бы нечем.
	/// У SStimer этой ловушки нет вовсе - его цикл каждый раз перечитывает голову слота.
	var/datum/chatmessage/resume_from

/datum/controller/subsystem/runechat/PreInit()
	bucket_list.len = BUCKET_LEN
	head_offset = world.time
	bucket_resolution = world.tick_lag

/datum/controller/subsystem/runechat/stat_entry(msg)
	msg = "ActMsgs:[bucket_count] SecQueue:[length(second_queue)] RST:[runechat_bucket_reset_count]"
	return msg

/datum/controller/subsystem/runechat/last_task()
	return "сообщений в бакетах [bucket_count], в second_queue [length(second_queue)], сбросов колеса [runechat_bucket_reset_count]"

/datum/controller/subsystem/runechat/fire(resumed = FALSE)
	// Store local references to datum vars as it is faster to access them this way
	var/list/bucket_list = src.bucket_list

	if (MC_TICK_CHECK)
		return


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
	// Store a reference to the 'working' chatmessage so that we can resume if the MC
	// has us stop mid-way through processing
	var/datum/chatmessage/cm = resumed ? resume_from : null

	// Пока подсистема стояла на паузе, курсор мог уехать из текущего слота: generate_image()
	// переназначает срок соседям по тайлу через enter_subsystem(), а тот делистит сообщение
	// и кладёт его в ДРУГОЙ бакет. Пойти по такому курсору - значит гасить чужой бакет, а
	// потом выбросить остаток текущего вместе со слотом: сообщениям не вызовут end_of_life(),
	// и они останутся в client.images навсегда. Слот записан в самом сообщении, сверить дёшево.
	if (cm && cm.runechat_bucket_pos != practical_offset)
		cm = null

	// Iterate through each bucket starting from the practical offset
	while (practical_offset <= BUCKET_LEN && head_offset + ((practical_offset - 1) * world.tick_lag) <= world.time)
		var/datum/chatmessage/bucket_head = bucket_list[practical_offset]
		if (!cm || !bucket_head || cm == bucket_head)
			bucket_head = bucket_list[practical_offset]
			cm = bucket_head

		while (cm)
			// If the chatmessage hasn't yet had its life ended then do that now
			var/datum/chatmessage/next = cm.next
			if (!cm.eol_complete)
				cm.end_of_life()
			else if (!QDELETED(cm)) // otherwise if we haven't deleted it yet, do so (this is after EOL completion)
				qdel(cm)

			if (MC_TICK_CHECK)
				// Продолжаем со СЛЕДУЮЩЕГО, а не с только что обработанного: обработанный уже
				// удалён, и ссылка на него из подсистемы была бы держателем hard delete.
				// Замкнувшееся на голову кольцо означает, что бакет пройден целиком.
				resume_from = (next == bucket_head) ? null : next
				return

			// Break once we've processed the entire bucket
			cm = next
			if (cm == bucket_head)
				break

		// Empty the bucket, check if anything in the secondary queue should be shifted to this bucket
		bucket_list[practical_offset++] = null
		var/i = 0
		for (i in 1 to length(second_queue))
			cm = second_queue[i]
			if (!BUCKET_FITS(cm.scheduled_destruction))
				i--
				break

			// Transfer the message into the bucket, performing necessary circular doubly-linked list operations
			bucket_count++
			var/bucket_pos = max(1, BUCKET_POS(cm.scheduled_destruction))
			var/datum/chatmessage/head = bucket_list[bucket_pos]
			cm.runechat_bucket_pos = bucket_pos
			if (!head)
				bucket_list[bucket_pos] = cm
				cm.in_runechat_queue = TRUE
				cm.in_runechat_second_queue = FALSE
				cm.next = null
				cm.prev = null
				continue

			if (!head.prev)
				head.prev = head
			cm.next = head
			cm.prev = head.prev
			cm.next.prev = cm
			cm.prev.next = cm
			cm.in_runechat_queue = TRUE
			cm.in_runechat_second_queue = FALSE
		if (i)
			second_queue.Cut(1, i + 1)
		cm = null
		resume_from = null

/datum/controller/subsystem/runechat/Recover()
	bucket_list |= SSrunechat.bucket_list
	second_queue |= SSrunechat.second_queue

/**
 * Пересборка колеса: всё, что уже разложено, раскладывается заново под новую разметку.
 *
 * Раньше здесь менялись только длина списка, head_offset и bucket_resolution - то есть
 * система координат колеса, - а сами сообщения оставались лежать в старых слотах. После
 * такой пересборки слот сообщения не имел никакого отношения к его сроку: часть сообщений
 * снималась не вовремя, часть - оставшаяся позади practical_offset - не снималась вообще
 * до следующего оборота, а при укорачивании списка (bucket_list.len = BUCKET_LEN на
 * меньшую длину) сообщения из отрезанных слотов пропадали вместе со слотами. Пропавшее
 * сообщение - это не только утечка датума: end_of_life() ему уже никто не вызовет, и
 * рунчат останется висеть над головой.
 *
 * Отдельно это стало обязательным после перехода на запомненную позицию в бакете:
 * runechat_bucket_pos пережил бы пересборку и указывал бы в чужой слот. Порядок действий
 * здесь тот же, что в SStimer.reset_buckets(), и расходиться им нельзя - это две копии
 * одного колеса.
 */
/datum/controller/subsystem/runechat/proc/reset_buckets()
	// Считаем и пишем ДО работы, как в SStimer.reset_buckets(): если сервер умрёт на самой
	// пересборке, единственным следом останется эта строка.
	runechat_bucket_reset_count++
	WARNING("Runechat buckets reset (#[runechat_bucket_reset_count]). \
		world.time: [world.time], head_offset: [head_offset], practical_offset: [practical_offset], \
		bucket_count: [bucket_count], second_queue: [length(second_queue)]")

	var/list/bucket_list = src.bucket_list
	var/list/allmessages = list()

	// Собираем всё, что лежит в колесе, обходя кольцо каждого бакета.
	for (var/datum/chatmessage/bucket_head as anything in bucket_list)
		if (!bucket_head)
			continue
		var/datum/chatmessage/bucket_node = bucket_head
		do
			allmessages += bucket_node
			bucket_node = bucket_node.next
		while (bucket_node && bucket_node != bucket_head)

	bucket_list.len = 0
	bucket_list.len = BUCKET_LEN

	practical_offset = 1
	bucket_count = 0
	head_offset = world.time
	bucket_resolution = world.tick_lag
	// Курсор возобновления указывает в СТАРУЮ раскладку: после перекладки сообщение
	// лежит в другом слоте, и продолжать с него нельзя.
	resume_from = null

	allmessages += second_queue
	second_queue = list()
	if (!length(allmessages))
		return

	sortTim(allmessages, GLOBAL_PROC_REF(cmp_chatmessage))

	// Если самое раннее сообщение уже просрочено, окно начинается с него: иначе его позиция
	// в колесе посчиталась бы от будущего head_offset и уехала бы в отрицательные.
	var/datum/chatmessage/earliest = allmessages[1]
	if (earliest.scheduled_destruction < head_offset)
		head_offset = earliest.scheduled_destruction

	var/new_bucket_count = 0
	var/i = 1
	for (i in 1 to length(allmessages))
		var/datum/chatmessage/cm = allmessages[i]
		if (!cm)
			continue
		cm.in_runechat_queue = FALSE
		cm.in_runechat_second_queue = FALSE
		cm.runechat_bucket_pos = BUCKET_POS_NONE
		cm.next = null
		cm.prev = null

		// Список отсортирован, так что первое не влезающее сообщение обрывает раскладку -
		// всё за ним тоже не влезает и уходит во вторичную очередь.
		if (!BUCKET_FITS(cm.scheduled_destruction))
			i--
			break

		new_bucket_count++
		var/bucket_pos = BUCKET_POS(cm.scheduled_destruction)
		var/datum/chatmessage/bucket_head = bucket_list[bucket_pos]
		cm.runechat_bucket_pos = bucket_pos
		cm.in_runechat_queue = TRUE
		if (!bucket_head)
			bucket_list[bucket_pos] = cm
			continue

		if (!bucket_head.prev)
			bucket_head.prev = bucket_head
		cm.next = bucket_head
		cm.prev = bucket_head.prev
		cm.next.prev = cm
		cm.prev.next = cm

	if (i)
		allmessages.Cut(1, i + 1)
	second_queue = allmessages
	for (var/datum/chatmessage/cm as anything in second_queue)
		cm.in_runechat_queue = TRUE
		cm.in_runechat_second_queue = TRUE
		cm.runechat_bucket_pos = BUCKET_POS_NONE
		cm.next = null
		cm.prev = null
	bucket_count = new_bucket_count

/**
 * Enters the runechat subsystem with this chatmessage, inserting it into the end-of-life queue
 *
 * This will also account for a chatmessage already being registered, and in which case
 * the position will be updated to remove it from the previous location if necessary
 *
 * Arguments:
 * * new_sched_destruction Optional, when provided is used to update an existing message with the new specified time
 */
/datum/chatmessage/proc/enter_subsystem(new_sched_destruction = 0)
	// Get local references from subsystem as they are faster to access than the datum references
	var/list/bucket_list = SSrunechat.bucket_list
	var/list/second_queue = SSrunechat.second_queue

	// When necessary, de-list the chatmessage from its previous position
	if (new_sched_destruction && in_runechat_queue)
		// Сообщение уезжает из своего слота - курсор возобновления на него смотреть больше
		// не должен. Тот же гард, что в leave_subsystem(): это второй и последний путь,
		// которым сообщение покидает бакет.
		if (SSrunechat.resume_from == src)
			SSrunechat.resume_from = null
		if (in_runechat_second_queue)
			second_queue -= src
		else
			SSrunechat.bucket_count--
			if (runechat_bucket_pos >= 1 && runechat_bucket_pos <= length(bucket_list) && bucket_list[runechat_bucket_pos] == src)
				bucket_list[runechat_bucket_pos] = next
			if (prev != next)
				prev?.next = next
				next?.prev = prev
			else
				prev?.next = null
				next?.prev = null
			prev = next = null
		runechat_bucket_pos = BUCKET_POS_NONE
		in_runechat_queue = FALSE
		in_runechat_second_queue = FALSE
		scheduled_destruction = new_sched_destruction
	else if (new_sched_destruction)
		scheduled_destruction = new_sched_destruction

	// Ensure the scheduled destruction time is properly bound to avoid missing a scheduled event
	scheduled_destruction = max(CEILING(scheduled_destruction, world.tick_lag), world.time + world.tick_lag)

	// Handle insertion into the secondary queue if the required time is outside our tracked amounts
	if (!BUCKET_FITS(scheduled_destruction))
		BINARY_INSERT(src, SSrunechat.second_queue, /datum/chatmessage, src, scheduled_destruction, COMPARE_KEY)
		runechat_bucket_pos = BUCKET_POS_NONE
		in_runechat_queue = TRUE
		in_runechat_second_queue = TRUE
		return

	// Get bucket position and a local reference to the datum var, it's faster to access this way
	var/bucket_pos = BUCKET_POS(scheduled_destruction)

	// Get the bucket head for that bucket, increment the bucket count
	var/datum/chatmessage/bucket_head = bucket_list[bucket_pos]
	runechat_bucket_pos = bucket_pos
	SSrunechat.bucket_count++

	// If there is no existing head of this bucket, we can set this message to be that head
	if (!bucket_head)
		bucket_list[bucket_pos] = src
		in_runechat_queue = TRUE
		in_runechat_second_queue = FALSE
		return

	// Otherwise it's a simple insertion into the circularly doubly-linked list
	if (!bucket_head.prev)
		bucket_head.prev = bucket_head
	next = bucket_head
	prev = bucket_head.prev
	next.prev = src
	prev.next = src
	in_runechat_queue = TRUE
	in_runechat_second_queue = FALSE


/**
 * Removes this chatmessage datum from the runechat subsystem
 */
/datum/chatmessage/proc/leave_subsystem()
	if(!in_runechat_queue)
		prev = next = null
		return

	// Курсор возобновления не должен пережить сообщение, на которое смотрит: подсистема
	// живёт весь раунд, и оставленная в ней ссылка на удалённое сообщение - это hard delete.
	if(SSrunechat.resume_from == src)
		SSrunechat.resume_from = null

	// Get local references to the subsystem's vars, faster than accessing on the datum
	var/list/bucket_list = SSrunechat.bucket_list
	var/list/second_queue = SSrunechat.second_queue

	if(in_runechat_second_queue)
		second_queue -= src
	else
		// Позиция записана при вставке, искать её не нужно - см. runechat_bucket_pos
		if (runechat_bucket_pos >= 1 && runechat_bucket_pos <= length(bucket_list) && bucket_list[runechat_bucket_pos] == src)
			bucket_list[runechat_bucket_pos] = next
		SSrunechat.bucket_count--

	// Remove the message from the bucket, ensuring to maintain
	// the integrity of the bucket's list if relevant
	if(prev != next)
		prev?.next = next
		next?.prev = prev
	else
		prev?.next = null
		next?.prev = null
	prev = next = null
	runechat_bucket_pos = BUCKET_POS_NONE
	in_runechat_queue = FALSE
	in_runechat_second_queue = FALSE

#undef BUCKET_LEN
#undef BUCKET_POS
#undef BUCKET_FITS
#undef BUCKET_TICK_FROM_HEAD
