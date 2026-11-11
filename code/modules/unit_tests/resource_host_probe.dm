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
