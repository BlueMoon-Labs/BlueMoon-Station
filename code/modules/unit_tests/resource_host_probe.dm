/// Вердикт пробы адресов ресурсов: мёртвый, подменённый страницей или чужой архив не должен проходить как "ок".
/datum/unit_test/resource_host_probe_verdict

/datum/unit_test/resource_host_probe_verdict/Run()
	var/local_rsc = 650 * 1024 * 1024
	var/verdict = resource_probe_verdict(list("error" = "нет ответа за 20 с"), TRUE, local_rsc)
	TEST_ASSERT(findtext(verdict, "НЕДОСТУПЕН"), "таймаут прошёл как живой адрес: [verdict]")

	verdict = resource_probe_verdict(list("code" = 404, "length" = 162, "type" = "text/html"), TRUE, local_rsc)
	TEST_ASSERT(findtext(verdict, "НЕДОСТУПЕН"), "404 прошёл как живой адрес: [verdict]")

	verdict = resource_probe_verdict(list("code" = 200, "length" = 30000, "type" = "text/html; charset=UTF-8"), TRUE, local_rsc)
	TEST_ASSERT(findtext(verdict, "HTML"), "страница вики после редиректа прошла как архив: [verdict]")

	verdict = resource_probe_verdict(list("code" = 200, "length" = 40 * 1024 * 1024, "type" = "application/zip"), TRUE, local_rsc)
	TEST_ASSERT(findtext(verdict, "МАЛ"), "архив в 16 раз меньше .rsc прошёл как ок: [verdict]")

	verdict = resource_probe_verdict(list("code" = 200, "length" = 529 * 1024 * 1024, "type" = "application/zip", "modified" = "Fri, 06 Nov 2026 17:23:10 GMT"), TRUE, local_rsc)
	TEST_ASSERT(findtext(verdict, "ок (") == 1, "живой архив не прошёл: [verdict]")
	TEST_ASSERT(findtext(verdict, "06 Nov 2026"), "в строке нет даты архива: [verdict]")

	// CDN отдаёт страницы и скрипты: text/html для ассета не ошибка, размер с .rsc не сравнивается.
	verdict = resource_probe_verdict(list("code" = 200, "length" = 30000, "type" = "text/html"), FALSE, 0)
	TEST_ASSERT(findtext(verdict, "ок (") == 1, "живой ассет CDN не прошёл: [verdict]")
	TEST_ASSERT(resource_probe_verdict_ok(verdict), "живой адрес попал в плохие: [verdict]")
	TEST_ASSERT(!resource_probe_verdict_ok(resource_probe_verdict(list("code" = 404), TRUE, local_rsc)), "404 не попал в плохие адреса")

/// Сообщение о плохих адресах ресурсов ждёт старта раунда и отписывается, отдав его админам.
/datum/unit_test/resource_host_probe_report_waits_round_start

/datum/unit_test/resource_host_probe_report_waits_round_start/Run()
	var/datum/resource_probe_report/report = new("unit_test: адрес не отвечает")
	TEST_ASSERT(report.signal_procs?[SSticker]?[COMSIG_TICKER_ROUND_STARTING], "сообщение не подписалось на старт раунда")
	report.on_round_starting(SSticker)
	TEST_ASSERT(QDELETED(report), "сообщение осталось жить после старта раунда")
	TEST_ASSERT(!report.signal_procs?[SSticker], "сообщение не отписалось от тикера")

/// Заголовки чужого хоста доходят до админов текстом, а не разметкой.
/datum/unit_test/resource_host_probe_admin_message_encoded

/datum/unit_test/resource_host_probe_admin_message_encoded/Run()
	var/verdict = resource_probe_verdict(list("code" = 404, "type" = "text/html<b>x</b>", "modified" = "<script>y</script>"), TRUE, 0)
	TEST_ASSERT(findtext(verdict, "<b>"), "в лог вердикт идёт не сырым: [verdict]")
	GLOB.unit_test_admin_messages = list()
	var/datum/resource_probe_report/report = new(resource_probe_admin_message(list("архив http://unit.test - [verdict]")))
	report.on_round_starting(SSticker)
	var/list/sent = GLOB.unit_test_admin_messages
	GLOB.unit_test_admin_messages = null
	TEST_ASSERT(length(sent) == 1, "админам ушло [length(sent)] сообщений вместо одного")
	var/message = sent[1]
	TEST_ASSERT(!findtext(message, "<b>") && !findtext(message, "<script>"), "разметка хоста дошла до админов: [message]")
	TEST_ASSERT(findtext(message, "&lt;b&gt;x&lt;/b&gt;"), "заголовок хоста пропал из сообщения: [message]")
