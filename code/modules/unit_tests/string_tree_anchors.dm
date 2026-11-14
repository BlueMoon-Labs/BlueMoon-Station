/// Одна новая строка дольше этого - перестройка дерева строк движка, а не работа, мкс.
#define STRING_TREE_STALL_US 100000

/// Метки времени, которые держат логи мобов и SQLtime(), подряд по секундам не стопорят движок; час - на полсуток от текущего, его меток в мире нет.
/datum/unit_test/string_tree_time_stamps_do_not_stall

/datum/unit_test/string_tree_time_stamps_do_not_stall/Run()
	var/start = ((text2num(time2text(world.timeofday, "hh")) + 12) % 24) HOURS
	for(var/format in list("hh:mm:ss", "YYYY-MM-DD hh:mm:ss"))
		var/list/held = list()
		var/stalls = 0
		var/worst = 0
		for(var/second in 0 to 1499)
			rustg_time_reset("string_tree_test")
			held += time2text(start + second SECONDS, format)
			var/spent = rustg_time_microseconds("string_tree_test")
			worst = max(worst, spent)
			if(spent > STRING_TREE_STALL_US)
				stalls++
		TEST_ASSERT_EQUAL(stalls, 0, "1500 удержанных меток [format] подряд дали стопоры, худший [round(worst / 1000)] мс")
	var/list/anchors = GLOB.string_tree_anchors
	TEST_ASSERT(copytext(time2text(world.timeofday, "hh:mm:ss"), 1, 6) in anchors, "минуты меток диагностики пинга нет в якорях")
	TEST_ASSERT(copytext(TIME_STAMP("hh:mm:ss", FALSE), 1, 6) in anchors, "минуты меток логов мобов нет в якорях")
	TEST_ASSERT(copytext(STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), 1, 6) in anchors, "минуты станционного времени нет в якорях")
	TEST_ASSERT(copytext(SQLtime(), 1, 17) in anchors, "минуты SQLtime() нет в якорях")

#undef STRING_TREE_STALL_US
