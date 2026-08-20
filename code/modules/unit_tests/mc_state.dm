/// Куда пишут тесты, чтобы не топтать боевой data/mc_state.txt: его прямо сейчас переписывает петля МК.
#define MC_STATE_TEST_FILE "data/mc_state_unit_test.txt"
/// Сколько раз подряд собирается текст сводки в замере цены.
///
/// Тысяча, потому что REALTIMEOFDAY меряет децисекундами: сотня сборок по полсотни микросекунд
/// уложится в один отсчёт таймера, и замер покажет ноль при любой регрессии.
#define MC_STATE_COST_SAMPLES 1000
/// Сколько записей на диск делает замер цены записи.
///
/// На порядок меньше, чем сборок текста: запись дороже и на медленной файловой системе тысяча
/// записей встала бы в десяток секунд теста. Двухсот хватает, чтобы сгладить замер.
#define MC_STATE_WRITE_SAMPLES 200

/**
 * Сводка обязана собираться в одну структуру: первая строка - когда и на какой итерации,
 * вторая - кто отработал последним и с какой задачей.
 *
 * Разбирают её человеческими глазами по логу упавшего раунда, поэтому проверяются именно
 * опорные слова: по ним сводку узнают в тексте лога, где вокруг неё чужие строки.
 */
/datum/unit_test/mc_state_snapshot_shape/Run()
	var/snapshot = Master.state_snapshot_text()
	TEST_ASSERT_NOTNULL(snapshot, "Сводка чёрного ящика МК не собралась вообще")

	var/list/lines = splittext(snapshot, "\n")
	TEST_ASSERT(length(lines) >= 3, "В сводке [length(lines)] строк вместо трёх и больше: [snapshot]")
	TEST_ASSERT(findtext(lines[1], "итерация"), "В первой строке сводки нет итерации МК: [lines[1]]")
	TEST_ASSERT(findtext(lines[2], "последняя подсистема"), "Во второй строке сводки нет последней подсистемы: [lines[2]]")
	TEST_ASSERT(findtext(lines[3], "очередь МК"), "В третьей строке сводки нет очереди МК: [lines[3]]")

/**
 * last_task() зовётся из петли МК каждый тик и из Failsafe в момент подвисания мира, то есть
 * в двух местах, где падать нельзя категорически. Тест проходит по ВСЕМ подсистемам, потому что
 * ошибка тут - это не кривая строка в логе, а рантайм внутри Loop(), уводящий МК в Recover().
 *
 * Перевод строки внутри ответа сломал бы разбор сводки: строки в ней позиционные.
 */
/datum/unit_test/subsystem_last_task_shape/Run()
	var/reporting = 0
	for(var/datum/controller/subsystem/checked_subsystem as anything in Master.subsystems)
		var/task = checked_subsystem.last_task()
		TEST_ASSERT(istext(task), "[checked_subsystem.name].last_task() вернул не текст: [task]")
		TEST_ASSERT(!findtext(task, "\n"), "[checked_subsystem.name].last_task() вернул многострочный ответ: [task]")
		if(length(task))
			reporting++

	// Подсистемы, у которых задача осмысленна, перечислены в шапке чёрного ящика; если
	// переопределения перестанут находиться (опечатка в пути типа, потерянный файл), сводка
	// молча выродится в одни имена подсистем, и заметить это будет уже не по чему.
	TEST_ASSERT(reporting >= 5, "Задачу сообщают всего [reporting] подсистем: переопределения last_task() не подхватились")
	TEST_ASSERT(findtext(SSair.last_task(), "активных турфов"), "SSair.last_task() перестал описывать проход атмоса: [SSair.last_task()]")
	TEST_ASSERT(length(SSmapping.last_task()), "SSmapping.last_task() молчит: карта - первый подозреваемый при смерти об потолок памяти")

/**
 * Метка штатного завершения - единственное, что отличает "мир закрыли" от "мир умер".
 * Если её перестанет видно, каждый штатный рестарт будет отчитываться крахом, и на сводку
 * перестанут смотреть.
 */
/datum/unit_test/mc_state_clean_mark_hides_snapshot/Run()
	fdel(MC_STATE_TEST_FILE)

	TEST_ASSERT_NULL(mc_state_previous_snapshot(MC_STATE_TEST_FILE), "Несуществующий файл сводки прочитался как улика")

	TEST_ASSERT(Master.write_state_snapshot(MC_STATE_TEST_FILE), "Сводка не записалась на диск")
	var/recovered = mc_state_previous_snapshot(MC_STATE_TEST_FILE)
	TEST_ASSERT_NOTNULL(recovered, "Записанная сводка не прочиталась обратно")
	TEST_ASSERT(findtext(recovered, "итерация"), "Прочитанная сводка не похожа на сводку: [recovered]")

	TEST_ASSERT(mc_state_mark_clean("юнит-тест", MC_STATE_TEST_FILE), "Метка штатного завершения не записалась")
	TEST_ASSERT_NULL(mc_state_previous_snapshot(MC_STATE_TEST_FILE), "Сводка, помеченная штатным завершением, всё равно читается как улика")

	fdel(MC_STATE_TEST_FILE)

/**
 * Цена снимка и подстройка частоты под неё.
 *
 * Замер, ради которого тест и написан: rustg_file_write открывает и закрывает файл на каждый
 * вызов, и цена этого разъезжается на два порядка между платформами - на рабочей машине под
 * Windows одна запись стоила 8.2 мс, то есть 40% тика. Поэтому проверяется не абсолютная
 * цена (её значение платформенное и в пороге ему делать нечего), а инвариант подстройки:
 * средняя нагрузка от чёрного ящика держится в отведённом бюджете тика.
 *
 * Замеренные числа пишутся в лог: следующий, кто будет думать про частоту записи, начнёт с них.
 */
/datum/unit_test/mc_state_snapshot_interval_adapts/Run()
	var/text_started_at = REALTIMEOFDAY
	for(var/sample in 1 to MC_STATE_COST_SAMPLES)
		Master.state_snapshot_text()
	var/text_cost = REALTIMEOFDAY - text_started_at
	log_world("MC_STATE: сборка текста сводки - [text_cost] дс на [MC_STATE_COST_SAMPLES] снимков")
	TEST_ASSERT(text_cost <= 5, "Сборка сводки стоит [text_cost] дс на [MC_STATE_COST_SAMPLES] снимков - дороже порога в 5 дс")

	fdel(MC_STATE_TEST_FILE)
	var/write_started_at = REALTIMEOFDAY
	for(var/sample in 1 to MC_STATE_WRITE_SAMPLES)
		Master.write_state_snapshot(MC_STATE_TEST_FILE)
	var/write_cost = REALTIMEOFDAY - write_started_at
	fdel(MC_STATE_TEST_FILE)
	log_world("MC_STATE: запись сводки - [write_cost] дс на [MC_STATE_WRITE_SAMPLES] записей, замер подсистемы [round(Master.state_snapshot_cost, 0.01)]% тика, интервал [Master.state_snapshot_interval] тик(ов)")

	TEST_ASSERT(Master.state_snapshot_cost > 0, "Цена записи не замерилась: подстройке частоты не на что опереться")
	TEST_ASSERT(Master.state_snapshot_interval >= MC_STATE_MIN_INTERVAL, "Интервал записи [Master.state_snapshot_interval] меньше минимального")
	TEST_ASSERT(Master.state_snapshot_interval <= MC_STATE_MAX_INTERVAL, "Интервал записи [Master.state_snapshot_interval] больше максимального: слепота дольше отведённой")

	var/average_load = Master.state_snapshot_cost / Master.state_snapshot_interval
	TEST_ASSERT(average_load <= MC_STATE_TICK_BUDGET || Master.state_snapshot_interval == MC_STATE_MAX_INTERVAL,
		"Чёрный ящик занимает [round(average_load, 0.01)]% тика в среднем при бюджете [MC_STATE_TICK_BUDGET]%, а интервал ещё не упёрся в потолок")

#undef MC_STATE_TEST_FILE
#undef MC_STATE_COST_SAMPLES
#undef MC_STATE_WRITE_SAMPLES
