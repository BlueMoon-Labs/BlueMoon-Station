/// Старый output получает копию чата, только пока игрок не видит сообщения в панели: панели нет, она грузится, упала или замолчала.
/datum/unit_test/chat_legacy_output
	var/datum/tgui_panel/legacy_output_test/panel

/datum/unit_test/chat_legacy_output/proc/ready_panel()
	panel = new
	panel.window.on_message("ready", list(), list())
	return panel

/// Получатель с готовой панелью и живым DS-путём.
/datum/unit_test/chat_legacy_output/proc/ready_target()
	var/datum/legacy_chat_test_client/target = new
	target.tgui_panel = ready_panel()
	target.ping_reply_at = world.time
	target.last_activity = world.time
	return target

/datum/unit_test/chat_legacy_output/proc/captured()
	var/list/htmls = list()
	for(var/list/entry as anything in GLOB.unit_test_legacy_chat_capture)
		htmls += entry[2]
	return htmls.Join(",")

/datum/unit_test/chat_legacy_output/Destroy()
	GLOB.unit_test_legacy_chat_capture = null
	if(panel)
		panel.window.unsubscribe(panel)
		QDEL_NULL(panel)
	return ..()

/datum/unit_test/chat_legacy_output/Run()
	TEST_ASSERT(chat_needs_legacy_output(FALSE, null, TRUE), "без панели чат идёт в старый output")
	panel = new
	TEST_ASSERT(chat_needs_legacy_output(FALSE, panel, TRUE), "панель ещё не загрузилась")
	panel.window.on_message("ready", list(), list())
	TEST_ASSERT(!chat_needs_legacy_output(FALSE, panel, TRUE), "готовая панель - без копии в старый output")
	TEST_ASSERT(chat_needs_legacy_output(TRUE, panel, TRUE), "игрок выбрал старый чат")

/datum/unit_test/chat_legacy_output/reload/Run()
	ready_panel()
	panel.initialize(force = TRUE)
	TEST_ASSERT(chat_needs_legacy_output(FALSE, panel, TRUE), "перезагрузка панели - копия сразу, ещё до новой страницы")
	sleep(world.tick_lag * 2)
	panel.window.on_message("ping", list("index" = 1), list())
	TEST_ASSERT(chat_needs_legacy_output(FALSE, panel, TRUE), "ответ прежней страницы не отменяет копию")
	panel.window.on_message("ready", list(), list())
	TEST_ASSERT(!chat_needs_legacy_output(FALSE, panel, TRUE), "новая страница готова")

/datum/unit_test/chat_legacy_output/silent/Run()
	ready_panel()
	panel.last_message_at = world.time - TGUI_PANEL_SILENT_LIMIT - 1
	TEST_ASSERT(chat_needs_legacy_output(FALSE, panel, TRUE), "панель молчит, а DS-путь отвечает - похоже, панель мертва")
	TEST_ASSERT(!chat_needs_legacy_output(FALSE, panel, FALSE), "молчат оба пути - очередь у клиента, копия её только удлинит")
	panel.window.on_message("ping", list("index" = 2), list())
	TEST_ASSERT(!chat_needs_legacy_output(FALSE, panel, TRUE), "панель снова на связи")

/datum/unit_test/chat_legacy_output/fatal/Run()
	ready_panel()
	panel.window.on_message("log", list(), list("fatal" = 1))
	TEST_ASSERT(chat_needs_legacy_output(FALSE, panel, TRUE), "панель упала с ошибкой")

/// Ушедшее только в панель проигрывается в старый output при переходе на него, по порядку и один раз.
/datum/unit_test/chat_legacy_output/replay/Run()
	var/datum/legacy_chat_test_client/target = ready_target()
	GLOB.unit_test_legacy_chat_capture = list()
	for(var/i in 1 to 3)
		legacy_chat_output(target, list(list("html" = "m[i]")))
	TEST_ASSERT_EQUAL(captured(), "", "панель работает - копий нет")
	target.chat_fix_pending++
	legacy_chat_replay(target)
	TEST_ASSERT_EQUAL(captured(), "m1,m2,m3", "открыт Fix chat - всё, что ушло только в панель, по порядку")
	legacy_chat_output(target, list(list("html" = "m4")))
	legacy_chat_replay(target)
	TEST_ASSERT_EQUAL(captured(), "m1,m2,m3,m4", "дальше идёт копия, повтор ничего не дублирует")
	target.chat_fix_pending--

	GLOB.unit_test_legacy_chat_capture = list()
	for(var/i in 1 to CHAT_LEGACY_REPLAY_LIMIT + 5)
		legacy_chat_output(target, list(list("html" = "o[i]")))
	target.use_legacy_chat = TRUE
	legacy_chat_output(target, list(list("text" = "after")), "after")
	var/list/sent = splittext(captured(), ",")
	TEST_ASSERT_EQUAL(length(sent), CHAT_LEGACY_REPLAY_LIMIT + 1, "не больше лимита плюс новое сообщение")
	TEST_ASSERT_EQUAL(sent[1], "o6", "старейшие сверх лимита выпали")
	TEST_ASSERT_EQUAL(sent[CHAT_LEGACY_REPLAY_LIMIT], "o[CHAT_LEGACY_REPLAY_LIMIT + 5]", "последнее из кольца перед новым")
	TEST_ASSERT_EQUAL(sent[length(sent)], "after", "новое сообщение после повтора")
	qdel(target)

/// SSchat шлёт копию в старый output, только когда она нужна, а без неё копит сообщения для повтора.
/datum/unit_test/chat_legacy_output/subsystem/Run()
	var/datum/legacy_chat_test_client/target = ready_target()
	GLOB.unit_test_legacy_chat_capture = list()
	TEST_ASSERT(deliver(target, list(list("html" = "p1"), list("html" = "p2"))), "SSchat разобрал пачку")
	TEST_ASSERT_EQUAL(captured(), "", "панель работает - копии нет")
	TEST_ASSERT_EQUAL(target.chat_replay_count, 2, "пачка ушла в кольцо повтора")
	target.use_legacy_chat = TRUE
	TEST_ASSERT(deliver(target, list(list("html" = "p3"))), "SSchat разобрал вторую пачку")
	TEST_ASSERT_EQUAL(captured(), "p1,p2,p3", "старый чат - повтор и копия")
	qdel(target)

/// Под потоком чата молчание панели - очередь у клиента: копия её только удлинит, повтор покроет Fix chat.
/datum/unit_test/chat_legacy_output/flood/Run()
	var/datum/legacy_chat_test_client/target = ready_target()
	panel.last_message_at = world.time - TGUI_PANEL_SILENT_LIMIT - 1
	GLOB.unit_test_legacy_chat_capture = list()
	legacy_chat_output(target, list(list("html" = "s1")))
	TEST_ASSERT_EQUAL(captured(), "s1", "панель молчит, DS-путь отвечает, потока нет - копия")
	target.ping_diag = new /datum/ping_diagnostics("tester")
	target.ping_diag.note_chat(PING_DIAG_FLOOD_RATE * PING_DIAG_FLOOD_WINDOW_DS / (1 SECONDS), REALTIMEOFDAY)
	legacy_chat_output(target, list(list("html" = "s2")))
	TEST_ASSERT_EQUAL(captured(), "s1", "под потоком чата копия не включается")
	TEST_ASSERT_EQUAL(target.chat_replay_count, 1, "сообщение ушло в кольцо повтора")
	QDEL_NULL(target.ping_diag)
	qdel(target)

/// Неактивному DS-пинги не шлются: его молчание панели судится как раньше, без DS-пути.
/datum/unit_test/chat_legacy_output/afk/Run()
	TEST_ASSERT(ping_skips_inactive(world.time - 5 MINUTES), "5 минут без ввода - пинги не шлются")
	TEST_ASSERT(!ping_skips_inactive(world.time - 5 MINUTES + 1), "активному пинги идут")
	var/datum/legacy_chat_test_client/target = ready_target()
	panel.last_message_at = world.time - TGUI_PANEL_SILENT_LIMIT - 1
	target.ping_reply_at = world.time - TGUI_PANEL_SILENT_LIMIT - 1
	GLOB.unit_test_legacy_chat_capture = list()
	legacy_chat_output(target, list(list("html" = "a1")))
	TEST_ASSERT_EQUAL(captured(), "", "активный, молчат оба пути - очередь у клиента, без копии")
	target.last_activity = world.time - 5 MINUTES
	legacy_chat_output(target, list(list("html" = "a2")))
	TEST_ASSERT_EQUAL(captured(), "a1,a2", "неактивный и панель молчит - копия с повтором")
	qdel(target)

/datum/unit_test/chat_legacy_output/subsystem/proc/deliver(target, list/payload)
	SSchat.payload_by_client[target] = payload
	var/deadline = world.time + 5 SECONDS
	UNTIL(!(target in SSchat.payload_by_client) || world.time > deadline)
	return !(target in SSchat.payload_by_client)

/// Поля /client, которые читают SSchat.fire и legacy_chat_output.
/datum/legacy_chat_test_client
	var/mob/mob
	var/datum/tgui_panel/tgui_panel
	var/datum/ping_diagnostics/ping_diag
	var/use_legacy_chat = FALSE
	var/chat_fix_pending = 0
	var/ping_reply_at = 0
	var/last_activity = 0
	var/list/chat_replay
	var/chat_replay_next = 1
	var/chat_replay_count = 0

/datum/tgui_panel/legacy_output_test

/datum/tgui_panel/legacy_output_test/New()
	window = new /datum/tgui_window/legacy_output_test
	window.subscribe(src, PROC_REF(on_message))

/datum/tgui_window/legacy_output_test

/datum/tgui_window/legacy_output_test/New()
	id = "legacy-output-test"

/datum/tgui_window/legacy_output_test/send_message(type, payload, force)
	return
