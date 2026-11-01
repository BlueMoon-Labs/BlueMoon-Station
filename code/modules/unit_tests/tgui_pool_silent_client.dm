/// Окно пула открывается, не дожидаясь ответа скина. Раунды 10545 и 10646: клиент молчал на winexists,
/// initialize() каждого окна пула спал с захваченным окном, и пул кончался ("Pool exhausted").
/datum/unit_test/tgui_pool_window_skips_skin_query
	var/list/initialized_windows = list()

/datum/unit_test/tgui_pool_window_skips_skin_query/proc/open_window(datum/tgui_window/window)
	window.initialize()
	initialized_windows += window

/datum/unit_test/tgui_pool_window_skips_skin_query/Run()
	var/datum/tgui_pool_test_client/owner = new
	var/list/pooled_windows = list()
	for(var/i in 1 to TGUI_WINDOW_HARD_LIMIT)
		var/datum/tgui_window/silent_skin/window = new(owner, TGUI_WINDOW_ID(i), TRUE)
		window.status = TGUI_WINDOW_LOADING
		pooled_windows += window
		INVOKE_ASYNC(src, PROC_REF(open_window), window)

	var/asked = 0
	for(var/datum/tgui_window/silent_skin/window as anything in pooled_windows)
		asked += window.asked
	TEST_ASSERT_EQUAL(asked, 0, "Окно пула спрашивает у скина тип контрола")
	TEST_ASSERT_EQUAL(length(initialized_windows), TGUI_WINDOW_HARD_LIMIT, "initialize() окна пула ждёт ответа клиента, держа окно занятым")
	for(var/datum/tgui_window/silent_skin/window as anything in pooled_windows)
		TEST_ASSERT(!window.is_browser, "Окно пула записано BROWSER-контролом скина")

	var/datum/tgui_window/silent_skin/panel = new(owner, "browseroutput")
	panel.answer = "BROWSER"
	INVOKE_ASYNC(src, PROC_REF(open_window), panel)
	sleep(world.tick_lag * 3)
	TEST_ASSERT_EQUAL(panel.asked, 1, "Окно скина не спросило свой тип")
	TEST_ASSERT(panel.is_browser, "Окно скина не узнало, что оно BROWSER")

	for(var/datum/tgui_window/silent_skin/window as anything in pooled_windows)
		window.answer = "MAIN"
	sleep(world.tick_lag * 3)
	owner.tgui_windows.Cut()
	initialized_windows.Cut()
	QDEL_LIST(pooled_windows)
	qdel(panel)
	qdel(owner)

/// Подменяет клиента: окнам нужен только его реестр.
/datum/tgui_pool_test_client
	var/list/tgui_windows = list()

/// Скин, который отвечает на вопрос о типе контрола, только когда тесту угодно.
/datum/tgui_window/silent_skin
	var/asked = 0
	var/answer

/datum/tgui_window/silent_skin/query_control_type()
	asked++
	UNTIL(answer)
	return answer
