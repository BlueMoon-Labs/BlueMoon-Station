/**
 * Заголовок перф-CSV и строка значений живут в разных концах time_track.dm и собираются
 * двумя литералами по сто с лишним элементов. Разъехавшись на один элемент, они дают файл,
 * в котором КАЖДАЯ величина сдвинута на соседнюю - и заметить это можно только вручную,
 * потому что числа остаются правдоподобными. Комментарий в time_track.dm про "дописывать в
 * хвост можно, вставлять нельзя" написан ровно про это.
 *
 * Тест держит инвариант: у заголовка и у строки одинаковая длина.
 */

/// Заголовок и строка перф-CSV обязаны иметь одинаковое число колонок.
/datum/unit_test/perf_log_header_matches_row/Run()
	var/list/header = SStime_track.perf_log_header()
	var/list/row = SStime_track.perf_log_row(null, null, 0)

	TEST_ASSERT_EQUAL(length(row), length(header), "Заголовок перф-CSV и строка значений разъехались - каждая величина в файле съедет на соседнюю колонку")

/// Заголовок обязан быть уникальным: две колонки с одним именем ломают любой разбор по
/// имени и означают, что при дописывании хвоста имя скопировали, а величину нет.
/datum/unit_test/perf_log_header_has_no_duplicates/Run()
	var/list/header = SStime_track.perf_log_header()
	var/list/seen = list()
	var/list/duplicates = list()
	for(var/column in header)
		if(seen[column])
			duplicates |= column
		seen[column] = TRUE

	TEST_ASSERT_EQUAL(length(duplicates), 0, "В заголовке перф-CSV повторяются колонки: [duplicates.Join(", ")]")

/// Без /proc (Windows) память не меряется, и строка обязана остаться той же ширины -
/// иначе CSV прода и CSV локального прогона нельзя сравнить одним и тем же разбором.
/datum/unit_test/perf_log_row_keeps_width_without_memory/Run()
	var/list/with_memory = SStime_track.perf_log_row(list("vsz" = 1, "rss" = 1, "peak_vsz" = 1, "peak_rss" = 1, "data" = 1, "rss_anon" = 1, "rss_file" = 1), list("available" = 1, "total" = 1), 0)
	var/list/without_memory = SStime_track.perf_log_row(null, null, 0)

	TEST_ASSERT_EQUAL(length(without_memory), length(with_memory), "Строка перф-CSV обязана быть одной ширины с замером памяти и без него")
