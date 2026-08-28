/**
 * Заглушка сообщения для проверок колеса рунчата.
 *
 * Настоящий /datum/chatmessage в тесте не создать: его New() требует моба с клиентом, иначе
 * оставляет stack_trace и удаляет себя. Колесу же клиент не нужен вовсе - оно работает со
 * сроком, позицией и связями. Заглушка обходит New() и даёт ровно то, чем колесо оперирует.
 */
/datum/chatmessage/unit_test_stub

/datum/chatmessage/unit_test_stub/New()
	return

/datum/chatmessage/unit_test_stub/end_of_life(fadetime = CHAT_MESSAGE_EOL_FADE)
	// Заглушка обязана уметь умирать сама. Настоящий end_of_life() первой же строкой
	// зовёт animate(message, ...), а message у заглушки пуст - это ЖЁСТКИЙ рантайм, и
	// валит он не свой тест, а тот, что шёл следом, вместе со всем clean_run.lk.
	// Дожить до прохода подсистемы заглушка может: провалившаяся проверка возвращает
	// управление прямо из Run(), не добравшись до уборки.
	eol_complete = scheduled_destruction + fadetime
	qdel(src)

/**
 * Пересборка колеса рунчата раскладывает сообщения заново, а не бросает их в старых слотах.
 *
 * SSrunechat - вторая копия колеса SStimer, и пересборка была единственным местом, где копии
 * расходились: reset_buckets() менял систему координат колеса (длину, head_offset,
 * bucket_resolution), а сами сообщения оставались лежать где лежали. После такой пересборки
 * слот сообщения не имел отношения к его сроку, а при укорачивании списка сообщения из
 * отрезанных слотов пропадали вместе со слотами - без end_of_life(), то есть навсегда
 * оставаясь на экране.
 *
 * Проверяется то, что отличает пересборку от простой смены координат: курсор колеса вернулся
 * в начало, а позиция сообщения пересчитана под НОВЫЙ head_offset. Простое "сообщение всё ещё
 * лежит в своём слоте" здесь не годится: при неизменной длине колеса оно остаётся истинным и
 * без всякой перекладки.
 */
/datum/unit_test/runechat_bucket_reset_requeues

/datum/unit_test/runechat_bucket_reset_requeues/Run()
	var/datum/chatmessage/unit_test_stub/message = new
	// Под присмотр фреймворка: QDEL_LIST(allocated) в /datum/unit_test/Destroy() зовётся
	// безусловно, а хвост Run() при упавшей проверке не выполняется вовсе - и заглушка
	// осталась бы лежать в БОЕВОМ колесе рунчата до ближайшего прохода подсистемы.
	allocated += message
	message.scheduled_destruction = world.time + 3 SECONDS
	message.enter_subsystem()

	TEST_ASSERT(message.in_runechat_queue, "Премиса: сообщение обязано попасть в подсистему")
	TEST_ASSERT(!message.in_runechat_second_queue, "Премиса: срок в три секунды обязан влезать в тридцатисекундное окно колеса")
	TEST_ASSERT(message.runechat_bucket_pos >= 1, "Премиса: у сообщения в колесе обязана быть записана позиция")

	SSrunechat.reset_buckets()

	TEST_ASSERT(message.in_runechat_queue, "Пересборка колеса потеряла живое сообщение")
	TEST_ASSERT(message.runechat_bucket_pos >= 1, "После пересборки сообщение осталось без записанной позиции в бакете")
	TEST_ASSERT(SSrunechat.bucket_list[message.runechat_bucket_pos] == message || message.prev || message.next,
		"После пересборки сообщение не лежит ни головой бакета, ни в его цепочке")
	TEST_ASSERT_EQUAL(SSrunechat.practical_offset, 1, "Пересборка не вернула курсор колеса в начало, а координаты сменила")

	// Та же арифметика, что в BUCKET_POS: макросы рунчата сняты в конце своего файла, и
	// повторить их здесь - единственный способ проверить, что позиция считана от нового
	// head_offset, а не осталась от старого.
	var/bucket_len = length(SSrunechat.bucket_list)
	var/ticks_from_head = ROUND_UP((message.scheduled_destruction - SSrunechat.head_offset) / world.tick_lag)
	var/expected_pos = ((ticks_from_head + 1) % bucket_len) || bucket_len
	TEST_ASSERT_EQUAL(message.runechat_bucket_pos, expected_pos, "После пересборки позиция сообщения не соответствует новому head_offset")

	// Снимаем с колеса сразу, а удаление оставляем фреймворку - см. allocated выше.
	message.leave_subsystem()

/**
 * Раскладка по бакетам: что влезает в окно колеса, а что уходит во вторичную очередь.
 *
 * Ветка переписала у рунчата обе формулы размещения - BUCKET_POS перешёл с round() на
 * ROUND_UP, а граница окна с сырого world.time на округлённый тик (BUCKET_FITS). Чинили
 * ими один и тот же отказ: сообщение признавалось влезающим, а раскладка сажала его в слот
 * ПОЗАДИ курсора - и тот же проход колеса его тут же и сметал, то есть рунчат гас, не
 * показавшись, либо ждал полного оборота и висел лишние тридцать секунд.
 *
 * У точно такой же правки в SStimer есть два прицельных теста (long_timers_do_not_fire_early
 * и timer_boundary_probe), у рунчата не было ни одного: оба его теста проверяли пересборку.
 *
 * Инвариант тут один и он точный: тик сообщения не может оказаться позади курсора. Курсор
 * стоит на practical_offset и обслуживает тик practical_offset - 1 от head_offset, значит
 * всё, что легло раньше, снимется раньше срока. Для честно завернувшегося за оборот
 * сообщения тик заведомо больше длины колеса, так что проверка ему не мешает.
 */
/datum/unit_test/runechat_bucket_placement

/datum/unit_test/runechat_bucket_placement/Run()
	// Окно колеса - тридцать секунд (BUCKET_LEN = world.fps * 30 тиков). Срок за ним обязан
	// уйти во вторичную очередь и не получить позиции в колесе вовсе.
	var/datum/chatmessage/unit_test_stub/distant = new
	allocated += distant
	distant.scheduled_destruction = world.time + 40 SECONDS
	distant.enter_subsystem()
	TEST_ASSERT(distant.in_runechat_queue, "Премиса: сообщение обязано попасть в подсистему")
	TEST_ASSERT(distant.in_runechat_second_queue, "Срок за окном колеса не ушёл во вторичную очередь")
	TEST_ASSERT_EQUAL(distant.runechat_bucket_pos, BUCKET_POS_NONE, "Сообщение вторичной очереди получило позицию в колесе")
	TEST_ASSERT(distant in SSrunechat.second_queue, "Сообщение за окном колеса не попало в second_queue")
	distant.leave_subsystem()

	// Сроки внутри окна, включая самый край. Каждый обязан лечь в колесо и НЕ позади курсора.
	var/bucket_len = length(SSrunechat.bucket_list)
	var/list/probes = list("5s" = 5 SECONDS, "20s" = 20 SECONDS, "29s" = 29 SECONDS)
	for(var/label in probes)
		var/datum/chatmessage/unit_test_stub/probe = new
		allocated += probe
		probe.scheduled_destruction = world.time + probes[label]
		probe.enter_subsystem()

		TEST_ASSERT(!probe.in_runechat_second_queue, "Срок [label] обязан влезать в тридцатисекундное окно колеса")
		TEST_ASSERT(probe.runechat_bucket_pos >= 1 && probe.runechat_bucket_pos <= bucket_len,
			"Срок [label] получил позицию вне колеса: [probe.runechat_bucket_pos] при длине [bucket_len]")

		// Макросы рунчата сняты в конце своего файла, повторяем арифметику здесь.
		var/ticks_from_head = ROUND_UP((probe.scheduled_destruction - SSrunechat.head_offset) / world.tick_lag)
		var/expected_pos = ((ticks_from_head + 1) % bucket_len) || bucket_len
		TEST_ASSERT_EQUAL(probe.runechat_bucket_pos, expected_pos, "Срок [label] разошёлся с собственной формулой позиции")
		TEST_ASSERT(ticks_from_head >= SSrunechat.practical_offset - 1,
			"Срок [label] лёг позади курсора колеса: тик [ticks_from_head] при курсоре [SSrunechat.practical_offset] - тот же проход его и сметёт")

		probe.leave_subsystem()

/**
 * Пересборка колеса переживает ПРОСРОЧЕННОЕ сообщение.
 *
 * Одна строка reset_buckets() - откат head_offset к самому раннему сроку - держит на себе
 * всю раскладку: BUCKET_POS считает тик от head_offset, у просроченного сообщения этот тик
 * отрицателен, остаток от деления в DM берёт знак делимого, а `|| BUCKET_LEN` отрицательное
 * не перехватывает, потому что оно истинно. Без отката раскладка обратилась бы к bucket_list
 * по отрицательному индексу, то есть рантаймом посреди пересборки колеса. Клампа `max(1, ...)`
 * здесь, в отличие от fire(), нет и быть не должно: он бы спрятал ошибку, а не починил её.
 *
 * Сценарий не выдуманный: пересборка случается по смене tick_lag, а просроченные сообщения
 * в колесе лежат всегда - между наступлением срока и проходом колеса, который их снимет.
 */
/datum/unit_test/runechat_bucket_reset_handles_overdue

/datum/unit_test/runechat_bucket_reset_handles_overdue/Run()
	var/datum/chatmessage/unit_test_stub/message = new
	allocated += message
	message.scheduled_destruction = world.time + 3 SECONDS
	message.enter_subsystem()
	TEST_ASSERT(message.in_runechat_queue, "Премиса: сообщение обязано попасть в подсистему")

	// Состариваем срок в обход клампа enter_subsystem(). Ровно так выглядит сообщение,
	// дожившее до пересборки: срок прошёл, а снять его колесо ещё не успело.
	message.scheduled_destruction = world.time - 5 SECONDS

	SSrunechat.reset_buckets()

	TEST_ASSERT(SSrunechat.head_offset <= message.scheduled_destruction,
		"Окно колеса не откатилось к просроченному сообщению: head_offset [SSrunechat.head_offset] против срока [message.scheduled_destruction]")
	TEST_ASSERT(message.runechat_bucket_pos >= 1,
		"Просроченное сообщение получило позицию вне колеса: [message.runechat_bucket_pos]")
	TEST_ASSERT(message.runechat_bucket_pos <= length(SSrunechat.bucket_list),
		"Позиция просроченного сообщения вышла за длину колеса: [message.runechat_bucket_pos] при длине [length(SSrunechat.bucket_list)]")
	TEST_ASSERT(SSrunechat.bucket_list[message.runechat_bucket_pos] == message || message.prev || message.next,
		"Просроченное сообщение не лежит ни головой бакета, ни в его цепочке")

	message.leave_subsystem()

/datum/unit_test/runechat_bucket_reset_handles_overdue/Destroy()
	// Сначала родитель: он снимает заглушку с колеса через QDEL_LIST(allocated).
	. = ..()
	// Окно колеса мы отодвинули на пять секунд в прошлое. Возвращаем его на место в любом
	// случае, в том числе после упавшей проверки: иначе первый же проход подсистемы будет
	// догонять настоящее время сотней пустых бакетов.
	SSrunechat.reset_buckets()

/**
 * Курсор возобновления не переживает переезд сообщения в другой бакет.
 *
 * fire() прерывается по бюджету тика посреди бакета и запоминает сообщение, с которого
 * продолжит. До следующего прохода сообщение может из этого бакета уехать: generate_image()
 * переназначает срок соседям по тайлу, а enter_subsystem() с новым сроком делистит сообщение
 * и кладёт его в другой слот. Курсор, переживший переезд, уводит проход в ЧУЖОЙ бакет -
 * тот гасится досрочно, а остаток текущего выбрасывается вместе со слотом: сообщениям не
 * вызовут end_of_life(), и они остаются в client.images до конца сессии.
 *
 * leave_subsystem() этот курсор снимает с рождения, enter_subsystem() - второй и последний
 * путь, которым сообщение покидает бакет.
 */
/datum/unit_test/runechat_resume_cursor_drops_moved_message

/datum/unit_test/runechat_resume_cursor_drops_moved_message/Run()
	var/datum/chatmessage/unit_test_stub/message = new
	allocated += message
	message.scheduled_destruction = world.time + 3 SECONDS
	message.enter_subsystem()
	TEST_ASSERT(message.in_runechat_queue, "Премиса: сообщение обязано попасть в подсистему")
	var/first_pos = message.runechat_bucket_pos

	var/datum/chatmessage/cached_resume = SSrunechat.resume_from
	SSrunechat.resume_from = message
	// Ровно этот вызов делает generate_image() соседям по тайлу.
	message.enter_subsystem(world.time + 10 SECONDS)
	var/resume_after = SSrunechat.resume_from
	var/second_pos = message.runechat_bucket_pos

	// Состояние боевой подсистемы возвращается ДО проверок: упавший TEST_ASSERT выходит из
	// прока, и ссылка на заглушку осталась бы курсором живого колеса.
	SSrunechat.resume_from = cached_resume
	message.leave_subsystem()

	TEST_ASSERT_NOTEQUAL(second_pos, first_pos, "Премиса: новый срок обязан переложить сообщение в другой бакет")
	TEST_ASSERT_NULL(resume_after, "Курсор возобновления пережил переезд сообщения в другой бакет")
