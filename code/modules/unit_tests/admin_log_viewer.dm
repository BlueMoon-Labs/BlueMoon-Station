/// Тесты чистых хелперов просмотрщика логов: валидация сегментов пути,
/// обрезка страниц по границе строки, размер файла, поиск по содержимому,
/// живость каталога для пересборки архива.
/datum/unit_test/admin_log_viewer_helpers

/datum/unit_test/admin_log_viewer_helpers/Run()
	// Валидация сегментов
	TEST_ASSERT(admin_log_valid_segment("game.log"), "game.log должен быть валидным сегментом")
	TEST_ASSERT(admin_log_valid_segment("round-15.24.55"), "имя каталога раунда должно быть валидным")
	TEST_ASSERT(admin_log_valid_segment("perf-NULL-Box Station.csv"), "имя с пробелами должно быть валидным")
	TEST_ASSERT(!admin_log_valid_segment(".."), "две точки должны отклоняться")
	TEST_ASSERT(!admin_log_valid_segment("a/b"), "слэш должен отклоняться")
	TEST_ASSERT(!admin_log_valid_segment("a\\b"), "бэкслэш должен отклоняться")
	TEST_ASSERT(!admin_log_valid_segment(""), "пустой сегмент должен отклоняться")
	TEST_ASSERT(!admin_log_valid_segment(null), "null должен отклоняться")
	var/long_name = ""
	for(var/i in 1 to 26)
		long_name += "aaaaaaaaaa"
	TEST_ASSERT(!admin_log_valid_segment(long_name), "260 символов должны отклоняться")

	// Обрезка страницы по последнему \n (не конец файла)
	var/list/trimmed = admin_log_trim_page("line1\nline2\nli", 0, 17)
	TEST_ASSERT_EQUAL(trimmed[1], "line1\nline2\n", "страница должна обрезаться до последнего перевода строки")
	TEST_ASSERT_EQUAL(trimmed[2], 12, "конечное смещение должно указывать за последний включённый байт")
	// Конец файла не режется
	trimmed = admin_log_trim_page("line3", 12, 17)
	TEST_ASSERT_EQUAL(trimmed[1], "line3", "хвост файла не должен обрезаться")
	TEST_ASSERT_EQUAL(trimmed[2], 17, "конечное смещение хвоста - размер файла")
	// Кусок без переводов строк отдаётся как есть
	trimmed = admin_log_trim_page("abcdef", 0, 100)
	TEST_ASSERT_EQUAL(trimmed[1], "abcdef", "кусок без переводов строк не должен обрезаться")

	// Выравнивание начала страницы (сброс разрезанной строки)
	var/list/aligned = admin_log_align_page("e1\nline2\n", 3)
	TEST_ASSERT_EQUAL(aligned[1], "line2\n", "разрезанная первая строка должна отбрасываться")
	TEST_ASSERT_EQUAL(aligned[2], 6, "смещение должно сдвинуться на начало полной строки")
	aligned = admin_log_align_page("line1\nline2", 0)
	TEST_ASSERT_EQUAL(aligned[1], "line1\nline2", "начало файла не должно выравниваться")
	TEST_ASSERT_EQUAL(aligned[2], 0, "смещение начала файла должно остаться нулём")
	aligned = admin_log_align_page("XY\n", 5)
	TEST_ASSERT_EQUAL(aligned[1], "", "чанк из одного хвоста разрезанной строки должен опустеть")
	TEST_ASSERT_EQUAL(aligned[2], 8, "смещение должно перескочить перевод строки")

	// Размер файла в байтах (на созданном нами файле - в CI чужих файлов нет)
	var/tmp_path = "data/unit_test_admin_log_size.txt"
	rustg_file_write("0123456789", tmp_path)
	TEST_ASSERT_EQUAL(admin_log_file_size(tmp_path), 10, "размер файла должен быть в байтах")
	fdel(tmp_path)
	TEST_ASSERT_EQUAL(admin_log_file_size("data/there_is_no_such_file.txt"), -1, "несуществующий файл должен давать -1")

	// Чанковое чтение с диска
	var/chunk_path = "data/unit_test_admin_log_chunk.txt"
	rustg_file_write("aaaa\nbbbb\ncccc\n", chunk_path)
	TEST_ASSERT_EQUAL(read_admin_log_chunk(chunk_path, 0, 7), "aaaa\nbb", "чанк с нулевого смещения")
	TEST_ASSERT_EQUAL(read_admin_log_chunk(chunk_path, 5, 5), "bbbb\n", "чанк со смещения 5")
	fdel(chunk_path)

	// Регрессия: смещения >= 1e6 не должны превращаться в "1e+06" (6 значащих цифр BYOND)
	var/big_path = "data/unit_test_admin_log_big.txt"
	var/line_block = "0123456789\n"
	for(var/i in 1 to 7)
		line_block += line_block
	// line_block теперь 1408 байт; пишем его 800 раз = 1126400 байт
	var/big_content = ""
	for(var/i in 1 to 800)
		big_content += line_block
		CHECK_TICK
	rustg_file_write(big_content, big_path)
	TEST_ASSERT_EQUAL(admin_log_file_size(big_path), 1126400, "размер большого файла должен быть точным")
	TEST_ASSERT_EQUAL(read_admin_log_chunk(big_path, 1000000, 11), "123456789\n0", "чанк со смещения 1000000 должен читаться побайтово точно")
	fdel(big_path)

	// Фильтрация выбора для множественного скачивания
	var/sel_dir = "data/unit_test_admin_log_sel/"
	rustg_file_write("a", "[sel_dir]a.log")
	rustg_file_write("b", "[sel_dir]b.txt")
	rustg_file_write("c", "[sel_dir]sub/c.log")
	var/list/sel_raw = flist(sel_dir)
	var/list/picked = admin_log_filter_selection(list("a.log", "b.txt", "a.log", "missing.log", "sub", "../a.log", 42), sel_raw)
	TEST_ASSERT_EQUAL(length(picked), 2, "должны уцелеть только существующие файлы без дублей")
	TEST_ASSERT_EQUAL(picked[1], "a.log", "первый уцелевший - a.log")
	TEST_ASSERT_EQUAL(picked[2], "b.txt", "второй уцелевший - b.txt")
	TEST_ASSERT_NULL(admin_log_filter_selection(null, sel_raw), "не-список должен давать null")
	TEST_ASSERT_NULL(admin_log_filter_selection(list(), sel_raw), "пустой список должен давать null")
	var/list/too_many = list()
	for(var/i in 1 to 51)
		too_many += "f[i].log"
	TEST_ASSERT_NULL(admin_log_filter_selection(too_many, sel_raw), "список сверх капа должен давать null")
	fdel("[sel_dir]a.log")
	fdel("[sel_dir]b.txt")
	fdel("[sel_dir]sub/c.log")
	fdel("[sel_dir]sub/")
	fdel(sel_dir)

	// Живость каталога для архивации: живой = содержит каталог текущего раунда
	var/round_dir = "data/logs/2026/07/17/round-9876"
	TEST_ASSERT(admin_log_dir_is_live("data/logs/2026/07/17/round-9876/", round_dir), "каталог текущего раунда должен быть живым")
	TEST_ASSERT(admin_log_dir_is_live("data/logs/2026/07/17/", round_dir), "каталог дня с текущим раундом должен быть живым")
	TEST_ASSERT(admin_log_dir_is_live("data/logs/2026/07/", round_dir), "каталог месяца с текущим раундом должен быть живым")
	TEST_ASSERT(admin_log_dir_is_live("data/logs/", round_dir), "корень логов содержит текущий раунд и потому живой")
	TEST_ASSERT(!admin_log_dir_is_live("data/logs/2026/07/16/", round_dir), "каталог другого дня не должен быть живым")
	TEST_ASSERT(!admin_log_dir_is_live("data/logs/2026/07/17/round-9875/", round_dir), "каталог другого раунда не должен быть живым")
	TEST_ASSERT(!admin_log_dir_is_live("data/logs/2026/07/17/round-987/", round_dir), "частичное совпадение имени раунда должно отклоняться")
	TEST_ASSERT(admin_log_dir_is_live("data/logs/2026/07/17/round-9876/subdir/", round_dir), "подкаталог внутри текущего раунда растёт вместе с ним - живой")
	TEST_ASSERT(!admin_log_dir_is_live("data/logs/2026/07/17/round-98765/", round_dir), "раунд с именем-надстройкой не должен ложно совпадать")
	TEST_ASSERT(!admin_log_dir_is_live("data/logs/", null), "null вместо каталога раунда должен давать FALSE")
	TEST_ASSERT(!admin_log_dir_is_live(null, round_dir), "null вместо каталога должен давать FALSE")

	// Поиск по содержимому
	var/list/results = admin_log_search_content("alpha\nbeta ALPHA\ngamma", "alpha")
	TEST_ASSERT_EQUAL(length(results), 2, "поиск должен быть регистронезависимым и найти 2 совпадения")
	var/list/first = results[1]
	TEST_ASSERT_EQUAL(first["line"], 1, "первое совпадение - строка 1")
	TEST_ASSERT_EQUAL(first["offset"], 0, "смещение первой строки - 0")
	var/list/second = results[2]
	TEST_ASSERT_EQUAL(second["line"], 2, "второе совпадение - строка 2")
	TEST_ASSERT_EQUAL(second["offset"], 6, "смещение второй строки - 6")

	// Фактический размер страницы: фиксированные размеры как есть,
	// "весь файл" (0) упирается в кап и не проседает ниже минимума
	var/datum/admin_log_viewer/viewer = new(null)
	viewer.page_bytes = 256 * 1024
	viewer.file_size = 50 * 1024 * 1024
	TEST_ASSERT_EQUAL(viewer.effective_page_bytes(), 256 * 1024, "фиксированный размер страницы не зависит от размера файла")
	viewer.page_bytes = 0
	viewer.file_size = 5 * 1024 * 1024
	TEST_ASSERT_EQUAL(viewer.effective_page_bytes(), 5 * 1024 * 1024, "режим всего файла должен покрывать файл целиком")
	viewer.file_size = 50 * 1024 * 1024
	TEST_ASSERT_EQUAL(viewer.effective_page_bytes(), 8 * 1024 * 1024, "режим всего файла должен упираться в кап 8 МиБ")
	viewer.file_size = 0
	TEST_ASSERT_EQUAL(viewer.effective_page_bytes(), 256 * 1024, "пустой файл не должен давать нулевую страницу")
	qdel(viewer)
