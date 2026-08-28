/// Пробник цены подключения без самого клиента: клиент в тесте не создать, а вся
/// арифметика этапов, итоговой строки и контрольного замера живёт в датуме и проверяется
/// напрямую. Замер памяти на CI (Linux) доступен, на Windows - нет; тест принимает оба
/// случая, потому что строка обязана быть полезной и без мегабайт.
/datum/unit_test/client_connect_probe

/datum/unit_test/client_connect_probe/Run()
	var/serial_before = GLOB.client_connect_serial
	var/datum/client_connect_probe/probe = new("unit_test_probe")
	TEST_ASSERT_EQUAL(probe.serial, serial_before + 1, "Пробник обязан взять следующий порядковый номер подключения")

	probe.mark("prefs")
	probe.mark("Login")
	TEST_ASSERT_EQUAL(length(probe.stages), 2, "Две отметки - два этапа в строке")
	TEST_ASSERT(findtext(probe.stages[1], "prefs ") == 1, "Этап обязан начинаться со своего имени: [probe.stages[1]]")
	TEST_ASSERT(findtext(probe.stages[2], "Login ") == 1, "Этап обязан начинаться со своего имени: [probe.stages[2]]")

	var/summary = probe.summary_line(3)
	TEST_ASSERT(findtext(summary, "подключение unit_test_probe (вход №3)"), "В итоге нет ckey и номера входа: [summary]")
	TEST_ASSERT(findtext(summary, "этапы: prefs "), "В итоге нет списка этапов: [summary]")
	if(isnull(probe.start_vsz))
		TEST_ASSERT(findtext(summary, "память не меряется"), "Без /proc строка обязана честно сказать, что памяти нет: [summary]")
	else
		TEST_ASSERT(findtext(summary, "VmSize [probe.start_vsz] -> "), "С /proc в строке обязан быть VmSize до и после: [summary]")
		TEST_ASSERT_NOTNULL(probe.finished_vsz, "После summary_line() пробник обязан запомнить VmSize конца New()")

	// Контрольный замер считается от запомненного конца New(), а не от живого /proc -
	// подставляем числа руками и проверяем именно арифметику
	probe.finished_vsz = 3000
	var/alone = probe.followup_line(3084.3, probe.serial)
	TEST_ASSERT(findtext(alone, "+84.3 МБ"), "Дельта контрольного замера посчитана неверно: [alone]")
	TEST_ASSERT(findtext(alone, "других входов не было"), "Без чужих входов дельта обязана быть помечена как своя: [alone]")
	var/crowded = probe.followup_line(2999.5, probe.serial + 4)
	TEST_ASSERT(findtext(crowded, "-0.5 МБ"), "Отрицательная дельта обязана идти со знаком: [crowded]")
	TEST_ASSERT(findtext(crowded, "вошли ещё 4"), "Число других входов считается по разнице серийных номеров: [crowded]")

	TEST_ASSERT_EQUAL(format_mb_delta(0), "0 МБ", "Нулевая дельта без знака")
	TEST_ASSERT_EQUAL(format_mb_delta(12.04), "+12 МБ", "Округление до десятых и плюс у роста")
