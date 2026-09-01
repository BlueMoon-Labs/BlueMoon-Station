/**
 * Чёрный ящик мастер-контроллера: чем мир был занят в свой последний момент.
 *
 * Мир умирает молча. Процесс DreamDaemon исчезает, лог обрывается на середине строки, и
 * единственной уликой остаётся отсутствие пометки в data/GracefulEnding.json на следующем
 * старте (SSpersistence.CheckGracefulEnding). Чем именно был занят мир в этот момент, из
 * логов не восстанавливается: перф-CSV пишется раз в десять секунд, стек умершего процесса
 * не сохраняется нигде, а буфер логов гибнет вместе с процессом.
 *
 * Поэтому сводка пишется мимо логов: rustg_file_write открывает файл, пишет и закрывает его
 * на каждом вызове, так что на диске всегда лежит состояние последнего прохода петли МК.
 *
 * Штатное завершение затирает сводку меткой MC_STATE_CLEAN_MARK. Значит, сводка, пережившая
 * перезапуск, - это всегда обрыв не по своей воле, и на старте она целиком уходит в лог
 * раунда (mc_state_report_previous()).
 *
 * Подсистемы дополняют сводку через last_task(), см. code/controllers/subsystem.dm.
 * Настройки (путь, метка, частота записи) лежат в code/__DEFINES/MC.dm: master.dm подключается
 * раньше этого файла и обязан их видеть.
 */

/datum/controller/master
	/// Медленная половина сводки: обновляется раз в десять секунд из SStime_track, пишется как есть.
	var/state_snapshot_context
	/// Отметка о происшествии, после которого мир может не дожить до следующей записи.
	/// Взводится один раз и не снимается: сводку читают ПОСЛЕ смерти, и снятая отметка
	/// означала бы, что улику стёрли своими руками.
	var/state_snapshot_note
	/// Подсистема, которая инициализируется прямо сейчас. Вне Initialize() всегда null.
	var/datum/controller/subsystem/initializing_subsystem
	/// Сколько записей сводки упало подряд. Обнуляется удачной записью.
	var/state_snapshot_failures = 0
	/// Через сколько проходов петли МК пишется сводка. Подбирается под замер цены записи.
	var/state_snapshot_interval = MC_STATE_MIN_INTERVAL
	/// С какой итерации петли МК разрешена следующая запись. Двигается только на УДАВШЕЙСЯ:
	/// отложенная из-за плотного тика запись повторяется на следующем проходе, а не через интервал.
	var/state_snapshot_next_iteration = 0
	/// Выше какой занятости тика запись откладывается. Переменная, а не дефайн прямо в проверке,
	/// только ради юнит-теста: занятость тика извне не задать, а поведение гарда проверить надо.
	var/state_snapshot_skip_above = MC_STATE_TICK_SKIP_ABOVE
	/// Сглаженная цена одной записи в процентах тика.
	var/state_snapshot_cost = 0
	/// Интервал, о котором последний раз написали в лог. Чтобы не писать на каждый шаг подстройки.
	var/state_snapshot_logged_interval = 0
	/// Запись сводки прекращена: файл на диске - улика, и перезаписывать его больше нельзя.
	var/state_snapshot_frozen = FALSE

/// Сводка прошлого запуска, если тот оборвался не по своей воле. Читается один раз на старте.
GLOBAL_VAR(mc_state_previous_summary)
/// Причина, по которой мир уходит на ребут не по своей воле. Взводится один раз, снимать нечем.
GLOBAL_VAR(mc_state_death_cause)

/**
 * Собирает сводку целиком. Ввода-вывода не делает - это отдельно проверяется тестом,
 * потому что дорожает сводка именно здесь, а зовётся она каждый тик.
 */
/datum/controller/master/proc/state_snapshot_text()
	var/list/lines = list("[SQLtime()] | итерация [iteration] | мир [world.time]дс | runlevel [current_runlevel] | тик [world.tick_usage]%")

	// До петли МК подсистемы ещё ни разу не запускались, и спрашивать у них last_task()
	// незачем: половина списков, которые он читает, до Initialize() ещё не создана.
	var/datum/controller/subsystem/last_fired = last_type_processed
	if(initializing_subsystem)
		lines += "инициализируется подсистема: [initializing_subsystem.name]"
	else if(istype(last_fired))
		var/task = last_fired.last_task()
		if(length(task) > MC_STATE_TASK_MAX_LEN)
			// Именно copytext_char: задачи пишутся кириллицей, а байтовый copytext режет посреди символа.
			task = "[copytext_char(task, 1, MC_STATE_TASK_MAX_LEN)]..."
		lines += "последняя подсистема: [last_fired.name] [last_fired.state_letter()] | задача: [task || "не сообщает"]"
	else
		// last_type_processed переживает SoftReset и может держать строку вместо подсистемы.
		lines += "последняя подсистема: [last_type_processed || "ни одной"]"

	var/list/queued = list()
	var/datum/controller/subsystem/queue_node = queue_head
	while(queue_node && length(queued) < MC_STATE_QUEUE_PREVIEW)
		queued += queue_node.name
		queue_node = queue_node.queue_next
	lines += "очередь МК: [length(queued) ? queued.Join(", ") : "пуста"][queue_node ? " и дальше" : ""]"

	lines += "снимок: раз в [state_snapshot_interval] тик(ов), цена записи [round(state_snapshot_cost, 0.01)]% тика"

	if(state_snapshot_context)
		lines += state_snapshot_context

	if(state_snapshot_note)
		lines += state_snapshot_note

	return lines.Join("\n")

/**
 * Переписывает сводку на диске. Возвращает TRUE, если вызов записи не упал.
 *
 * Именно "не упал", а не "записалось": rust-g сообщает об ошибке файловой системы возвратом,
 * а не исключением, и что он возвращает в случае успеха, в дефайнах не описано - остальные
 * вызовы rustg_file_write в репозитории результат тоже не проверяют. Сквозная проверка
 * "записали - прочитали" живёт в юнит-тесте mc_state_clean_mark_hides_snapshot.
 *
 * Зовётся из петли МК, поэтому падать наружу ей нельзя: рантайм внутри Loop() уводит
 * мастер-контроллер в Recover(), то есть диагностика убивала бы ровно то, что диагностирует.
 *
 * force - писать, не глядя на занятость тика. Это путь Failsafe и смерти мира: там сводка
 * и есть единственная цель вызова, а тик всё равно уже потерян.
 */
/datum/controller/master/proc/write_state_snapshot(path = MC_STATE_SNAPSHOT_FILE, force = FALSE)
	if(state_snapshot_frozen || state_snapshot_failures >= MC_STATE_FAILURE_LIMIT)
		return FALSE
	// Подстройка интервала держит СРЕДНЮЮ цену в бюджете, но не трогает выброс: одна
	// запись стоит столько, сколько стоит. В проде 23.08 это доходило до 121% тика
	// (раунд 10087) и до 80% (10091) - и оба раза ровно в шторме логинов, то есть прибор
	// добивал тик именно тогда, когда миру было тяжелее всего. Отсюда гард: в уже плотный
	// тик запись не лезет, а откладывается до следующего прохода петли. Свежесть сводки
	// при этом теряется на считанные тики, зато перегруженный тик не получает добавки.
	if(!force && TICK_USAGE > state_snapshot_skip_above)
		return FALSE
	var/write_started_at = TICK_USAGE
	try
		rustg_file_write(state_snapshot_text(), path)
	catch(var/exception/write_error)
		state_snapshot_failures++
		if(state_snapshot_failures >= MC_STATE_FAILURE_LIMIT)
			log_world("MC: чёрный ящик выключен после [MC_STATE_FAILURE_LIMIT] неудачных записей подряд. Последняя ошибка: [write_error]")
		return FALSE
	state_snapshot_failures = 0
	// Отрицательная дельта значит, что запись пришлась на границу тика: такой замер бесполезен.
	var/write_cost = TICK_USAGE - write_started_at
	if(write_cost >= 0)
		state_snapshot_cost = state_snapshot_cost ? MC_AVERAGE(state_snapshot_cost, write_cost) : write_cost
		adjust_state_snapshot_interval()
	return TRUE

/**
 * Подбирает частоту записи под её цену, чтобы средняя нагрузка держалась в MC_STATE_TICK_BUDGET.
 *
 * Запись раз в N тиков стоит в среднем cost/N процентов тика, отсюда N = цена / бюджет.
 * На Linux это единица (запись дешевле бюджета), на медленной файловой системе - десятки
 * тиков; хуже слепоты в MC_STATE_MAX_INTERVAL тиков не станет ни при каких замерах.
 */
/datum/controller/master/proc/adjust_state_snapshot_interval()
	var/wanted = clamp(CEILING(state_snapshot_cost / MC_STATE_TICK_BUDGET, 1), MC_STATE_MIN_INTERVAL, MC_STATE_MAX_INTERVAL)
	if(wanted == state_snapshot_interval)
		return
	state_snapshot_interval = wanted
	// Порог на логирование: интервал ползает на доли при каждом замере, и без него строка
	// уходила бы в лог десятки раз за раунд.
	if(state_snapshot_logged_interval && wanted < state_snapshot_logged_interval * MC_STATE_INTERVAL_LOG_FACTOR && wanted * MC_STATE_INTERVAL_LOG_FACTOR > state_snapshot_logged_interval)
		return
	state_snapshot_logged_interval = wanted
	log_world("MC: чёрный ящик пишется раз в [wanted] тик(ов), одна запись стоит [round(state_snapshot_cost, 0.01)]% тика")

/**
 * Кто стоял в момент, когда Failsafe заметил остановку МК.
 *
 * Отличается от сводки тем, что годится в чат админам: одна фраза без переводов строки.
 */
/datum/controller/master/proc/stuck_subsystem_note()
	var/datum/controller/subsystem/stuck = last_type_processed
	if(!istype(stuck))
		return "Последней подсистемы МК не помнит."
	var/task = stuck.last_task()
	return "Последней запускалась [stuck.name] [stuck.state_letter()][task ? ", задача: [task]" : ""]."

/**
 * Дописывает в чёрный ящик причину аварийного обрыва и запрещает трогать файл дальше.
 *
 * Дописывает, а не переписывает: сводку в этот момент собирать не на что - память кончилась
 * именно поэтому, - зато на диске уже лежит снимок последнего прохода петли МК. Одна короткая
 * строка поверх него стоит дешевле любой пересборки, а чтение сводки её не путает: метку
 * штатного завершения mc_state_previous_snapshot() ищет строго в начале файла.
 *
 * Взведённая причина закрывает mc_state_mark_clean(): дальше по пути обрыва лежит обычный
 * /world/Reboot, и без гарда он затёр бы улику меткой штатного завершения.
 */
/proc/mc_state_note_death(cause, path = MC_STATE_SNAPSHOT_FILE)
	if(GLOB)
		GLOB.mc_state_death_cause = cause
	if(Master)
		Master.state_snapshot_frozen = TRUE
	try
		rustg_file_append("\nПРИЧИНА ОБРЫВА: [cause]", path)
	catch(var/exception/write_error)
		log_world("MC: не удалось дописать причину обрыва в чёрный ящик: [write_error]")
		return FALSE
	return TRUE

/// Затирает сводку меткой штатного завершения, чтобы следующий старт не принял её за улику.
/proc/mc_state_mark_clean(reason, path = MC_STATE_SNAPSHOT_FILE)
	// Обрыв не по своей воле уже записан в файл, и метка штатного завершения его затрёт.
	if(GLOB?.mc_state_death_cause)
		return FALSE
	try
		rustg_file_write("[MC_STATE_CLEAN_MARK] | [SQLtime()] | [reason || "причина не указана"]", path)
	catch(var/exception/write_error)
		log_world("MC: не удалось пометить чёрный ящик штатным завершением: [write_error]")
		return FALSE
	return TRUE

/// Сводка прошлого запуска, если он оборвался не по своей воле, иначе null.
/proc/mc_state_previous_snapshot(path = MC_STATE_SNAPSHOT_FILE)
	if(!fexists(path))
		return null
	var/snapshot = trim(file2text(path))
	if(!snapshot)
		return null
	if(findtextEx(snapshot, MC_STATE_CLEAN_MARK) == 1)
		return null
	return snapshot

/// Выкладывает сводку прошлого запуска в лог раунда и запоминает её в GLOB. Зовётся один раз, из world/New перед Master.Initialize().
/proc/mc_state_report_previous(path = MC_STATE_SNAPSHOT_FILE)
	var/snapshot = mc_state_previous_snapshot(path)
	if(!snapshot)
		return null
	GLOB.mc_state_previous_summary = snapshot
	log_world("Прошлый запуск мира оборвался, не пометив завершение. Чёрный ящик МК на момент обрыва:\n[snapshot]")
	return snapshot
