/// Нагрузка подсистемы на тик: цена прохода, размазанная по интервалу.
/datum/unit_test/mc_subsystem_tick_load/Run()
	TEST_ASSERT_EQUAL(mc_subsystem_tick_load(40, 20, 1, FALSE, 0.5), 1, "Проход в 40% тика раз в 2 с (40 тиков) - это 1% каждого тика")
	TEST_ASSERT_EQUAL(mc_subsystem_tick_load(10, 2, 1, TRUE, 0.5), 5, "У тикера wait в тиках, а не в децисекундах")
	TEST_ASSERT_EQUAL(mc_subsystem_tick_load(30, 1, 6, FALSE, 0.5), 5, "Проход длиннее интервала делится на свои тики, а не на интервал")
	TEST_ASSERT_EQUAL(mc_subsystem_tick_load(8, 0.1, 1, FALSE, 0.5), 8, "Интервал короче тика не раздувает нагрузку сверх цены прохода")

/// Данные MC-вкладки собираются без рантаймов: строка на каждую подсистему, ключи сводки на месте.
/datum/unit_test/statpanel_mc_payload/Run()
	SSstatpanels.generate_mc_data()
	var/list/server_info = json_decode(url_decode(SSstatpanels.mc_data_encoded))
	TEST_ASSERT(islist(server_info), "Сводка MC-вкладки не разбирается как JSON")
	for(var/key in list("mc_load", "maptick", "tick_limit_running", "mc_iteration", "mc_queue", "history", "key_ss"))
		TEST_ASSERT(!isnull(server_info[key]), "В сводке MC-вкладки нет ключа [key]")
	TEST_ASSERT(server_info["mc_load"] >= 0, "Нагрузка МК отрицательная: [server_info["mc_load"]]")

	var/list/rows = json_decode(url_decode(SSstatpanels.mc_ss_data_encoded))
	TEST_ASSERT_EQUAL(length(rows), length(Master.subsystems), "Строк подсистем не столько, сколько подсистем у МК")
	for(var/list/row as anything in rows)
		TEST_ASSERT_EQUAL(length(row), 21, "Строка подсистемы [row[1]] не той длины, которую ждёт statbrowser")

/// История спарклайнов держит только последние 60 замеров.
/datum/unit_test/statpanel_mc_history_cap/Run()
	for(var/i in 1 to 100)
		SSstatpanels.push_mc_history("zz_test_series", i)
	var/list/series = SSstatpanels.mc_history["zz_test_series"]
	SSstatpanels.mc_history -= "zz_test_series"
	TEST_ASSERT_EQUAL(length(series), 60, "История растёт сверх предела")
	TEST_ASSERT_EQUAL(series[1], 41, "Из истории выпадают не самые старые замеры")
	TEST_ASSERT_EQUAL(series[60], 100, "Последний замер не в конце истории")
