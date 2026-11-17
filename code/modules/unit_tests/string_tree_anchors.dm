/// Одна новая строка дольше этого - перестройка дерева строк движка, а не работа, мкс.
#define STRING_TREE_STALL_US 100000

/// Час на полсуток от текущего, его меток в мире нет; сутки world.timeofday за 1500 секунд не кончаются.
/proc/string_tree_test_start()
	return ((text2num(time2text(world.timeofday, "hh", 0)) + 12) % 23) HOURS

/// 1500 удержанных строк подряд по секундам с start: list(стопоры, худший мс). print - скрытые отпечатки одного персонажа, date - SQLtime() с этой датой.
/proc/string_tree_held_stamps_stalls(start, format, print = FALSE, date)
	var/list/held = list()
	var/stalls = 0
	var/worst = 0
	for(var/second in 0 to 1499)
		rustg_time_reset("string_tree_test")
		var/stamp = time2text(start + second SECONDS, format)
		if(print)
			held += hidden_print_text("First", stamp, "Тест Отпечатков", "(gloves)", "stringtreetest")
		else if(date)
			held += "[date] [stamp]"
		else
			held += stamp
		var/spent = rustg_time_microseconds("string_tree_test")
		worst = max(worst, spent)
		if(spent > STRING_TREE_STALL_US)
			stalls++
	return list(stalls, round(worst / 1000))

/// Метки времени, которые держат логи мобов и SQLtime(), подряд по секундам не стопорят движок.
/datum/unit_test/string_tree_time_stamps_do_not_stall

/datum/unit_test/string_tree_time_stamps_do_not_stall/Run()
	// Мир мог встать до полуночи, а тест идти после.
	update_string_tree_sql_anchors()
	for(var/format in list("hh:mm:ss", "YYYY-MM-DD hh:mm:ss"))
		var/list/result = string_tree_held_stamps_stalls(string_tree_test_start(), format)
		TEST_ASSERT_EQUAL(result[1], 0, "1500 удержанных меток [format] подряд дали стопоры, худший [result[2]] мс")
	var/list/anchors = GLOB.string_tree_anchors
	TEST_ASSERT(copytext(time2text(world.timeofday, "hh:mm:ss"), 1, 6) in anchors, "минуты меток диагностики пинга нет в якорях")
	TEST_ASSERT(copytext(TIME_STAMP("hh:mm:ss", FALSE), 1, 6) in anchors, "минуты меток логов мобов нет в якорях")
	TEST_ASSERT(copytext(STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), 1, 6) in anchors, "минуты станционного времени нет в якорях")
	TEST_ASSERT(copytext(SQLtime(), 1, 17) in GLOB.string_tree_sql_anchors, "минуты SQLtime() нет в якорях")

/// На смене суток у SQLtime() новая дата: якоря строятся заново, и метки новых суток подряд не стопорят.
/datum/unit_test/string_tree_sql_anchors_follow_midnight

/datum/unit_test/string_tree_sql_anchors_follow_midnight/Run()
	var/list/before = GLOB.string_tree_sql_anchors
	var/last_timeofday = GLOB.rollovercheck_last_timeofday
	var/rollovers = GLOB.midnight_rollovers
	GLOB.rollovercheck_last_timeofday = world.timeofday + 1
	update_midnight_rollover()
	GLOB.midnight_rollovers = rollovers
	GLOB.rollovercheck_last_timeofday = last_timeofday
	TEST_ASSERT(GLOB.string_tree_sql_anchors != before, "смена суток не обновила якоря SQLtime()")
	TEST_ASSERT(copytext(SQLtime(), 1, 17) in GLOB.string_tree_sql_anchors, "минуты SQLtime() после смены суток нет в якорях")

	var/next_day = "2099-12-31"
	GLOB.string_tree_sql_anchors = build_string_tree_sql_anchors(next_day)
	var/list/result = string_tree_held_stamps_stalls(string_tree_test_start(), "hh:mm:ss", date = next_day)
	update_string_tree_sql_anchors()
	TEST_ASSERT_EQUAL(result[1], 0, "1500 меток SQLtime() новых суток подряд дали стопоры, худший [result[2]] мс")

/// Скрытые отпечатки одного персонажа на атомах, тронутых в разные секунды, не тянут ветку дерева строк.
/datum/unit_test/string_tree_hidden_prints_do_not_stall

/datum/unit_test/string_tree_hidden_prints_do_not_stall/Run()
	var/list/result = string_tree_held_stamps_stalls(string_tree_test_start(), "hh:mm:ss", print = TRUE)
	TEST_ASSERT_EQUAL(result[1], 0, "1500 скрытых отпечатков одного персонажа подряд дали стопоры, худший [result[2]] мс")

	var/mob/living/carbon/human/toucher = allocate(/mob/living/carbon/human)
	toucher.real_name = "Тест Отпечатков"
	toucher.key = "unit_test_hidden_print"
	var/obj/item/touched = allocate(/obj/item/pen)
	touched.add_hiddenprint(toucher)
	var/first = touched.fingerprintshidden[toucher.key]
	TEST_ASSERT(copytext(first, 1, 6) in GLOB.string_tree_anchors, "запись не начинается с минуты-якоря: [first]")
	TEST_ASSERT(findtext(first, "First: Тест Отпечатков. Ckey: [toucher.ckey]"), "в первой записи нет имени и ckey: [first]")
	touched.add_hiddenprint(toucher)
	touched.add_hiddenprint(toucher)
	var/both = touched.fingerprintshidden[toucher.key]
	TEST_ASSERT(findtext(both, first) == 1, "первая запись не сохранилась: [both]")
	TEST_ASSERT(findtext(both, " | ") && findtext(both, " | ") == findlasttext(both, " | "), "последнее касание не заменило прежнее: [both]")
	TEST_ASSERT(findtext(both, "Last: Тест Отпечатков. Ckey: [toucher.ckey]"), "нет последнего касания: [both]")
	toucher.key = null

/// Журналы рантаймов и GC-фейлов держат метку числом и показывают её как раньше.
/datum/unit_test/string_tree_error_viewer_stamps

/datum/unit_test/string_tree_error_viewer_stamps/Run()
	var/exception/thrown = new("string tree test", "code/test.dm", 7)
	var/datum/error_viewer/error_entry/entry = new(thrown)
	var/stamp = time2text(entry.logged_at, "hh:mm:ss")
	TEST_ASSERT(!findtext(entry.name, stamp), "метка в удерживаемом имени записи: [entry.name]")
	TEST_ASSERT_EQUAL(entry.display_name(), "<b>\[[stamp]]</b> Runtime in <b>code/test.dm</b>, line <b>7</b>: <b>string tree test</b>", "показ записи рантайма")
	var/datum/error_viewer/error_entry/skipped = new(thrown, null, 3)
	TEST_ASSERT_EQUAL(skipped.display_name(), "\[[time2text(skipped.logged_at, "hh:mm:ss")]] Skipped 3 runtimes in code/test.dm,7.", "показ пропущенных рантаймов")
	var/datum/error_viewer/error_source/source = new(thrown)
	TEST_ASSERT_EQUAL(source.display_name(), "<b>\[[time2text(source.logged_at, "hh:mm:ss")]]</b> [entry.name]", "показ источника рантайма")
	var/datum/gc_failure_viewer/gc_failure_entry/failure = new(null, /obj/item/pen, "\[0x0]", 0, 0)
	stamp = time2text(failure.logged_at, "hh:mm:ss")
	TEST_ASSERT(!findtext(failure.name, stamp), "метка в удерживаемом имени GC-фейла: [failure.name]")
	TEST_ASSERT_EQUAL(failure.display_name(), "<b>\[[stamp]]</b> GC failure: <b>/obj/item/pen</b> (\[0x0])", "показ GC-фейла")

#undef STRING_TREE_STALL_US
