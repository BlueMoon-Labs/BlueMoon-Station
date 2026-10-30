/// Сервер зовёт панель записать историю чата, только пока игрок без ввода, и не чаще раза в CHAT_HISTORY_SAVE_EVERY.
/datum/unit_test/chat_history_save_offer
	var/datum/tgui_panel/history_save_test/panel
	var/datum/legacy_chat_test_client/player

/datum/unit_test/chat_history_save_offer/Destroy()
	if(panel)
		panel.window.unsubscribe(panel)
		panel.client = null
		QDEL_NULL(panel)
	QDEL_NULL(player)
	return ..()

/datum/unit_test/chat_history_save_offer/Run()
	panel = new
	player = new
	player.tgui_panel = panel
	var/datum/tgui_window/history_save_test/window = panel.window
	panel.client = player
	player.last_activity = world.time - CHAT_HISTORY_SAVE_IDLE
	TEST_ASSERT(!panel.offer_history_save(), "панель ещё не загрузилась")
	panel.client = null
	window.on_message("ready", list(), list())
	panel.client = player
	TEST_ASSERT_EQUAL(length(window.sent), 0, "до готовности панели ничего не отправлено")

	player.last_activity = world.time - CHAT_HISTORY_SAVE_IDLE + 1
	TEST_ASSERT(!panel.offer_history_save(), "игрок только что что-то нажал")
	player.last_activity = world.time - CHAT_HISTORY_SAVE_IDLE
	TEST_ASSERT(panel.offer_history_save(), "игрок без ввода - пора писать")
	TEST_ASSERT_EQUAL(window.sent.Join(","), "chat/saveIdle", "панели ушёл сигнал записи")
	TEST_ASSERT(!panel.offer_history_save(), "второй раз в ту же минуту не зовём")
	TEST_ASSERT_EQUAL(panel.next_history_save_offer, world.time + CHAT_HISTORY_SAVE_EVERY, "следующий сигнал через минуту")

	panel.next_history_save_offer = world.time
	panel.reloading = TRUE
	TEST_ASSERT(!panel.offer_history_save(), "страница панели грузится заново")
	panel.reloading = FALSE
	TEST_ASSERT(panel.offer_history_save(), "минута прошла - снова зовём")
	TEST_ASSERT_EQUAL(length(window.sent), 2, "второй сигнал отправлен")

	panel.next_history_save_offer = world.time
	window.fatally_errored = TRUE
	TEST_ASSERT(!panel.offer_history_save(), "панель упала с ошибкой")
	window.fatally_errored = FALSE
	panel.client = null
	TEST_ASSERT(!panel.offer_history_save(), "без клиента сигнала нет")

/datum/tgui_panel/history_save_test

/datum/tgui_panel/history_save_test/New()
	window = new /datum/tgui_window/history_save_test
	window.subscribe(src, PROC_REF(on_message))

/datum/tgui_window/history_save_test
	var/list/sent = list()

/datum/tgui_window/history_save_test/New()
	id = "history-save-test"

/datum/tgui_window/history_save_test/send_message(type, payload, force)
	sent += type
