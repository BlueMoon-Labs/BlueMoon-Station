/**
 * Личная музыкальная шкатулка: длительность трека снимается с файла, повтор переключается,
 * причина серой кнопки загрузки уходит в интерфейс.
 *
 * Раньше song_length у любого залитого трека был захардкожен в 20 минут: после конца
 * короткого трека шкатулка ещё четверть часа "играла" тишину, а повтор перезапускал
 * музыку только по истечении этих 20 минут. Кнопка повтора при этом не имела обработчика
 * действия вовсе, а задизейбленная кнопка загрузки не объясняла причину отказа.
 */
/datum/unit_test/personal_music_box
	requires_full_map = FALSE
	/// Файлы, выложенные тестом на диск; сносятся в Destroy() даже если тест упал.
	var/list/staged_files = list()

/datum/unit_test/personal_music_box/Destroy()
	for(var/path in staged_files)
		fdel(path)
	staged_files.Cut()
	return ..()

/// Выкладывает ресурс из .rsc на диск и отдаёт путь к нему.
/// rust-g читает файлы с диска и в .rsc не заглядывает, а tools/deploy.sh каталог sound/
/// в деплой не кладёт - в CI мир стартует из ci_test/, где "sound/machines/ping.ogg"
/// просто нет, и путь из репозитория даёт длину 0. Заливка трека в игре меряет ровно
/// такой же свежескопированный файл (fcopy в GLOB.log_directory), так что тест повторяет
/// боевой путь один в один.
/datum/unit_test/personal_music_box/proc/stage_file(resource, filename)
	var/path = "[GLOB.log_directory || "data/logs"]/unit_test_music_box_[filename]"
	fdel(path)
	fcopy(resource, path)
	staged_files += path
	return path

/datum/unit_test/personal_music_box/Run()
	var/obj/item/personal_music_box/box = allocate(/obj/item/personal_music_box)
	var/datum/component/jukebox/personal_music_box/jukebox = box.get_jukebox_component()
	TEST_ASSERT_NOTNULL(jukebox, "У шкатулки нет компонента джукбокса")

	// Единицы длины: rustg_sound_length обязан отдавать децисекунды.
	// ping.ogg = 0.494 с, ambigen1.ogg = 14.877 с (замерено ffprobe).
	var/ping_path = stage_file('sound/machines/ping.ogg', "ping.ogg")
	TEST_ASSERT(fexists(ping_path), "ping.ogg не лёг на диск - мерить нечего")
	var/ping_length = box.get_audio_track_length(ping_path)
	TEST_ASSERT(ping_length >= 3 && ping_length <= 7, \
		"ping.ogg (0.49 с) дал длину [ping_length] дс вместо ~5: длина не в децисекундах либо файл не прочитан")
	var/ambience_path = stage_file('sound/ambience/ambigen1.ogg', "ambigen1.ogg")
	var/ambience_length = box.get_audio_track_length(ambience_path)
	TEST_ASSERT(ambience_length >= 130 && ambience_length <= 170, \
		"ambigen1.ogg (14.9 с) дал длину [ambience_length] дс вместо ~149")

	// Не-аудио файл не проходит проверку.
	var/text_path = "[GLOB.log_directory || "data/logs"]/unit_test_music_box_not_audio.txt"
	fdel(text_path)
	text2file("это не аудио", text_path)
	staged_files += text_path
	TEST_ASSERT_EQUAL(box.get_audio_track_length(text_path), 0, \
		"текстовый файл прошёл проверку длины аудио")

	// Длина ложится в custom_track; нераспознанная длина падает в потолок 20 минут.
	jukebox.set_custom_track(ambience_path, "тест", ambience_length)
	TEST_ASSERT_NOTNULL(jukebox.custom_track, "set_custom_track не создал трек")
	TEST_ASSERT_EQUAL(jukebox.custom_track.song_length, ambience_length, \
		"song_length трека не совпал с переданной длиной")
	jukebox.set_custom_track(ambience_path, "тест", 0)
	TEST_ASSERT_EQUAL(jukebox.custom_track.song_length, 20 MINUTES, \
		"нулевая длина обязана падать в потолок 20 минут")

	// Переключатель повтора работает и на играющем треке правит очередь сразу.
	TEST_ASSERT(jukebox.repeat, "Повтор у личной шкатулки по умолчанию включён")
	TEST_ASSERT(box.toggle_repeat(), "toggle_repeat не отработал")
	TEST_ASSERT(!jukebox.repeat, "Повтор не выключился")
	jukebox.active = TRUE
	box.toggle_repeat()
	TEST_ASSERT(jukebox.repeat, "Повтор не включился обратно")
	TEST_ASSERT(jukebox.custom_track in jukebox.queuedplaylist, \
		"Включение повтора на играющем треке не поставило трек в очередь")
	box.toggle_repeat()
	TEST_ASSERT(!(jukebox.custom_track in jukebox.queuedplaylist), \
		"Выключение повтора не сняло трек из очереди")
	jukebox.active = FALSE

	// Причина серой кнопки загрузки видна интерфейсу.
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/list/data = box.ui_data(user)
	TEST_ASSERT_NOTNULL(data["upload_block_reason"], \
		"Шкатулка не в руках - причина отказа в загрузке обязана уйти в интерфейс")
	TEST_ASSERT_EQUAL(data["upload_block_reason"], box.get_upload_block_reason(user), \
		"ui_data отдал не ту причину отказа, что даёт get_upload_block_reason")

	jukebox.set_volume(0)
	data = box.ui_data(user)
	TEST_ASSERT_EQUAL(data["volume"], 0, "Нулевая громкость ушла в интерфейс не нулём")

	TEST_ASSERT_EQUAL(get_personal_music_box_track_name("C:\\music\\<Песня>.ogg"), "Песня", \
		"Из названия трека не вычищены < и > или не срезан путь с расширением")
	var/long_name = get_personal_music_box_track_name("[repeat_string(100, "ж")].ogg")
	TEST_ASSERT_EQUAL(length_char(long_name), 64, "Длинное название трека не обрезано до 64 символов")
	TEST_ASSERT_EQUAL(long_name, repeat_string(64, "ж"), "Кириллица в названии порвана при обрезке")
	TEST_ASSERT_EQUAL(get_personal_music_box_track_name(".ogg"), "Свой трек", "Пустое название не заменено заглушкой")

/// Библиотека шкатулки: лимит загрузок считается по ней, выбор залитого трека не тратит ни загрузку, ни кулдаун.
/datum/unit_test/personal_music_box_library
	requires_full_map = FALSE
	var/list/staged_files = list()
	var/test_ckey = "unittestmusicboxlibrary"

/datum/unit_test/personal_music_box_library/Destroy()
	GLOB.personal_music_boxes_library -= test_ckey
	GLOB.personal_music_boxes_last_player_upload -= test_ckey
	for(var/path in staged_files)
		fdel(path)
	staged_files.Cut()
	return ..()

/datum/unit_test/personal_music_box_library/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.ckey = test_ckey
	var/obj/item/personal_music_box/box = allocate(/obj/item/personal_music_box)
	TEST_ASSERT(user.put_in_hands(box), "Шкатулка не легла в руки")
	var/datum/component/jukebox/personal_music_box/jukebox = box.get_jukebox_component()

	var/first_path = "[GLOB.log_directory || "data/logs"]/unit_test_music_box_library_1.ogg"
	var/second_path = "[GLOB.log_directory || "data/logs"]/unit_test_music_box_library_2.ogg"
	for(var/path in list(first_path, second_path))
		fdel(path)
		fcopy('sound/machines/ping.ogg', path)
		staged_files += path
	var/list/library = list(
		list("path" = first_path, "name" = "первый", "length" = 5, "duration" = "5 секунд"),
		list("path" = second_path, "name" = "второй", "length" = 7, "duration" = "7 секунд"),
	)
	GLOB.personal_music_boxes_library[test_ckey] = library

	TEST_ASSERT(box.select_library_track(user, 2), "Выбор второго трека из библиотеки не сработал")
	TEST_ASSERT_EQUAL(box.curfile_path, second_path, "В шкатулку встал не тот файл")
	TEST_ASSERT_EQUAL(box.song_name, "второй", "В шкатулку встало не то название")
	TEST_ASSERT_EQUAL(jukebox.custom_track?.song_length, 7, "Длина трека из библиотеки не дошла до компонента")
	TEST_ASSERT_NULL(GLOB.personal_music_boxes_last_player_upload[test_ckey], "Выбор из библиотеки запустил кулдаун загрузки")

	TEST_ASSERT(!box.select_library_track(user, 3), "Выбор за пределами библиотеки прошёл")
	TEST_ASSERT(!box.select_library_track(user, 1.5), "Дробный индекс прошёл")
	TEST_ASSERT(!box.select_library_track(user, null), "Пустой индекс прошёл")

	var/list/data = box.ui_data(user)
	var/list/library_data = data["library"]
	TEST_ASSERT_EQUAL(length(library_data), 2, "Интерфейс получил не всю библиотеку")
	var/list/first_entry_data = library_data[1]
	var/list/second_entry_data = library_data[2]
	TEST_ASSERT(!first_entry_data["current"] && second_entry_data["current"], "Интерфейс неверно отметил текущий трек")

	jukebox.active = TRUE
	TEST_ASSERT(!box.select_library_track(user, 1), "Трек сменился на играющей шкатулке")
	jukebox.active = FALSE

	fdel(first_path)
	TEST_ASSERT(!box.select_library_track(user, 1), "Выбран трек, файла которого нет на диске")
	TEST_ASSERT_EQUAL(box.curfile_path, second_path, "Отказ в выборе всё равно сменил трек")

	var/limit = data["uploads_max"]
	TEST_ASSERT(limit > 3, "Лимит загрузок за раунд снова урезан до трёх")
	while(length(library) < limit - 1)
		library += list(list("path" = second_path, "name" = "дубль", "length" = 7, "duration" = "7 секунд"))
	TEST_ASSERT(!findtext(box.get_upload_block_reason(user), "лимит"), "Лимит сработал раньше [limit] загрузок")
	library += list(list("path" = second_path, "name" = "дубль", "length" = 7, "duration" = "7 секунд"))
	TEST_ASSERT(findtext(box.get_upload_block_reason(user), "лимит"), "После [limit] загрузок лимит не сработал")
