/**
 * Позиции кнопок действий: персист и цена записи.
 *
 * Раунд 10150 (5.5 часа, 30 онлайн) отдал 3817 ПОЛНЫХ записей префов на 20.2 секунды
 * синхронной заморозки процесса - львиную долю всех блокирующих вызовов раунда. Гнали
 * их save_position() и dump_save() кнопок действий: каждая перестановка кнопки звала
 * queue_save_pref, то есть ~124 WRITE_FILE подряд. Причём сохранять было нечего -
 * action_buttons_screen_locs в savefile не писалась и оттуда не читалась вовсе, это была
 * чисто оперативная переменная. Теперь ключ реально лежит на диске и уходит туда через
 * буфер склейки одним открытием файла.
 */

/**
 * Санитайзер обязан пропускать живые позиции и резать мусор с диска.
 */
/datum/unit_test/action_button_positions_sanitize

/datum/unit_test/action_button_positions_sanitize/Run()
	var/list/clean = sanitize_action_button_positions(list(
		"Toggle Light_1" = "WEST:6,NORTH:-6",
		"Rest_2" = SCRN_OBJ_IN_PALETTE,
		"Sprint_3" = SCRN_OBJ_IN_LIST,
	))
	TEST_ASSERT_EQUAL(length(clean), 3, "живые позиции кнопок не пережили чистку")
	TEST_ASSERT_EQUAL(clean["Toggle Light_1"], "WEST:6,NORTH:-6", "screen_loc потерялся при чистке")
	TEST_ASSERT_EQUAL(clean["Rest_2"], SCRN_OBJ_IN_PALETTE, "маркер палитры потерялся при чистке")

	// Мусор с диска: список может оказаться не списком, значение - не строкой.
	TEST_ASSERT_EQUAL(length(sanitize_action_button_positions(null)), 0, "null обязан дать пустой список, а не рантайм")
	TEST_ASSERT_EQUAL(length(sanitize_action_button_positions("не список")), 0, "строка вместо списка обязана дать пустой список")

	var/list/mixed = sanitize_action_button_positions(list(
		"Ok_1" = "SOUTH:1",
		"Number_2" = 42,
		"Empty_3" = "",
	))
	TEST_ASSERT_EQUAL(length(mixed), 1, "нестроковое и пустое значение обязаны выпасть, а живое - остаться")
	TEST_ASSERT_EQUAL(mixed["Ok_1"], "SOUTH:1", "живая запись выпала вместе с мусором")

	// Исходный список чистка не трогает: он ещё может быть тем самым списком префов.
	var/list/source = list("Keep_1" = "SOUTH:1", "Drop_2" = 42)
	sanitize_action_button_positions(source)
	TEST_ASSERT_EQUAL(length(source), 2, "чистка правит исходный список вместо того, чтобы вернуть новый")

/**
 * Потолок числа записей: savefile не должен расти без границы.
 */
/datum/unit_test/action_button_positions_cap

/datum/unit_test/action_button_positions_cap/Run()
	var/list/overflowing = list()
	for(var/i in 1 to ACTION_BUTTON_SAVED_POSITIONS_MAX + 25)
		overflowing["Button_[i]"] = "SOUTH:[i]"
	var/list/capped = sanitize_action_button_positions(overflowing)
	TEST_ASSERT_EQUAL(length(capped), ACTION_BUTTON_SAVED_POSITIONS_MAX, "число сохранённых позиций перешагнуло потолок")

	// Длинное значение режется, длинный ключ выбрасывается целиком: обрезанный ключ
	// load_position() не найдёт никогда, так что обрезка была бы молчаливой потерей.
	var/long_key = ""
	var/long_value = ""
	for(var/i in 1 to 200)
		long_key += "k"
		long_value += "v"
	var/list/trimmed = sanitize_action_button_positions(list("[long_key]" = long_value, "short" = long_value))
	TEST_ASSERT_EQUAL(length(trimmed), 1, "слишком длинный ключ должен выбрасываться, короткий - оставаться")
	TEST_ASSERT_EQUAL(length_char(trimmed["short"]), ACTION_BUTTON_SAVED_POSITION_LEN - 1, "значение не обрезано до потолка")

	// Потолки считаются в символах, не в байтах: кириллическое имя действия из 40 букв
	// весит 80 байт и байтовым copytext резалось бы посреди символа.
	var/cyrillic_key = ""
	var/cyrillic_value = ""
	for(var/i in 1 to 40)
		cyrillic_key += "ж"
		cyrillic_value += "ю"
	var/list/cyrillic = sanitize_action_button_positions(list("[cyrillic_key]" = cyrillic_value))
	TEST_ASSERT_EQUAL(cyrillic[cyrillic_key], cyrillic_value, "кириллические ключ и значение в пределах потолка должны сохраняться как есть")

/**
 * Поток перестановок кнопки обязан схлопываться в ОДНО открытие savefile.
 *
 * Ровно на этом раунд 10150 и терял 20 секунд: буфер склейки ключ не видел, потому что
 * кнопки ходили мимо него полным сейвом.
 */
/datum/unit_test/action_button_positions_coalesce

/datum/unit_test/action_button_positions_coalesce/Run()
	var/list/pending = list()
	var/list/positions = list()

	for(var/i in 1 to 40)
		positions["Toggle Light_1"] = "WEST:[i]"
		pref_pending_absorb(pending, "action_buttons_screen_locs", positions)

	TEST_ASSERT_EQUAL(length(pending), 1, "сорок перестановок кнопки дали больше одной записи в буфере")
	var/list/buffered = pending["action_buttons_screen_locs"]
	TEST_ASSERT_EQUAL(buffered["Toggle Light_1"], "WEST:40", "в буфере осела не последняя позиция кнопки")
