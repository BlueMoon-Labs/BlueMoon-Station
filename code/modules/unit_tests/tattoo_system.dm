/// Тесты системы татуировок
/// Покрывает: хранение, persistence, загрузку, отображение, escape/unescape

// Литеральные значения для defines из modular_bluemoon (недоступны по порядку компиляции)
#define TEST_TATTOO_FIELD_SEP "^"
#define TEST_TATTOO_RECORD_SEP "~"
#define TEST_TATTOO_VERSION 1
#define TEST_TDATA_VAR 1
#define TEST_TDATA_NAME_PREP 2
#define TEST_TDATA_NAME_NOM 3
#define TEST_TDATA_ORGAN 4
#define TEST_TDATA_COVERED 5

// ===== Базовое хранение на bodypart =====

/// Тест: обычная татуировка на стандартной зоне тела
/datum/unit_test/tattoo_basic_bodyzone

/datum/unit_test/tattoo_basic_bodyzone/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_NOTNULL(r_arm, "Human should have a right arm bodypart")

	var/test_text = "<span style='color:#1A1A1A'>\[T]Test tattoo</span>"
	r_arm.tattoo_text = test_text
	TEST_ASSERT_EQUAL(r_arm.tattoo_text, test_text, "Tattoo text should be stored on bodypart")

/// Тест: интимная татуировка через set_tattoo_text_for_zone
/datum/unit_test/tattoo_intimate_zone_storage

/datum/unit_test/tattoo_intimate_zone_storage/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(chest, "Human should have a chest bodypart")

	var/test_text = "<span style='color:#FF0000'>\[T]Belly tat</span>"
	set_tattoo_text_for_zone(chest, TATTOO_ZONE_BELLY, test_text)
	var/result = get_tattoo_text_for_zone(chest, TATTOO_ZONE_BELLY)
	TEST_ASSERT_EQUAL(result, test_text, "Intimate zone tattoo should be stored and retrieved via helpers")

/// Тест: get/set для всех интимных зон через GLOB.tattoo_zone_data
/datum/unit_test/tattoo_all_intimate_zones

/datum/unit_test/tattoo_all_intimate_zones/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)

	for(var/zone in GLOB.tattoo_zone_data)
		var/test_text = "test_[zone]"
		set_tattoo_text_for_zone(chest, zone, test_text)
		var/result = get_tattoo_text_for_zone(chest, zone)
		TEST_ASSERT_EQUAL(result, test_text, "Zone [zone] should store and retrieve tattoo text")

	// Убедимся что каждая зона независима
	for(var/zone in GLOB.tattoo_zone_data)
		var/result = get_tattoo_text_for_zone(chest, zone)
		TEST_ASSERT_EQUAL(result, "test_[zone]", "Zone [zone] should retain its value independently from other zones")

// ===== Escape/Unescape =====

/// Тест: экранирование спецсимволов в тексте татуировки
/datum/unit_test/tattoo_escape_unescape

/datum/unit_test/tattoo_escape_unescape/Run()
	var/original = "Test^with~separators"
	var/escaped = escape_tattoo_text(original)
	TEST_ASSERT_NOTEQUAL(escaped, original, "Escaped text should differ from original when it contains separators")
	TEST_ASSERT(!findtext(escaped, TEST_TATTOO_FIELD_SEP), "Escaped text should not contain field separator ^")
	TEST_ASSERT(!findtext(escaped, TEST_TATTOO_RECORD_SEP), "Escaped text should not contain record separator ~")

	var/unescaped = unescape_tattoo_text(escaped)
	TEST_ASSERT_EQUAL(unescaped, original, "Unescape should restore original text exactly")

/// Тест: текст без спецсимволов не меняется при escape
/datum/unit_test/tattoo_escape_no_change

/datum/unit_test/tattoo_escape_no_change/Run()
	var/original = "Simple tattoo text with <span> tags"
	var/escaped = escape_tattoo_text(original)
	TEST_ASSERT_EQUAL(escaped, original, "Text without separators should not change after escaping")

// ===== Формат сохранения (format_tattoos / load_tattoo) =====

/// Тест: format_tattoos сериализует обычные и интимные татуировки
/datum/unit_test/tattoo_format_tattoos

/datum/unit_test/tattoo_format_tattoos/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	// Обычная татуировка на руке
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	r_arm.tattoo_text = "<span style='color:#1A1A1A'>\[T]Arm tat</span>"

	// Интимная татуировка на животе
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	set_tattoo_text_for_zone(chest, TATTOO_ZONE_BELLY, "<span style='color:#FF0000'>\[D]Belly desc</span>")

	var/result = H.format_tattoos()
	TEST_ASSERT(findtext(result, BODY_ZONE_R_ARM), "Formatted string should contain right arm zone")
	TEST_ASSERT(findtext(result, TATTOO_ZONE_BELLY), "Formatted string should contain belly zone")
	TEST_ASSERT(findtext(result, "Arm tat"), "Formatted string should contain arm tattoo text")
	TEST_ASSERT(findtext(result, "Belly desc"), "Formatted string should contain belly tattoo text")

/// Тест: load_tattoo загружает обычную зону
/datum/unit_test/tattoo_load_standard_zone

/datum/unit_test/tattoo_load_standard_zone/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/tattoo_text = "<span style='color:#1A1A1A'>\[T]Loaded tattoo</span>"
	var/escaped = escape_tattoo_text(tattoo_text)
	var/tattoo_line = "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][BODY_ZONE_L_ARM][TEST_TATTOO_FIELD_SEP][escaped]"

	var/success = H.load_tattoo(tattoo_line)
	TEST_ASSERT(success, "load_tattoo should return TRUE for valid tattoo line")

	var/obj/item/bodypart/l_arm = H.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_EQUAL(l_arm.tattoo_text, tattoo_text, "Loaded tattoo text should match original")

/// Тест: load_tattoo загружает интимную зону
/datum/unit_test/tattoo_load_intimate_zone

/datum/unit_test/tattoo_load_intimate_zone/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/tattoo_text = "<span style='color:#FF0000'>\[D]Intimate tattoo</span>"
	var/escaped = escape_tattoo_text(tattoo_text)
	var/tattoo_line = "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][TATTOO_ZONE_FOREHEAD][TEST_TATTOO_FIELD_SEP][escaped]"

	var/success = H.load_tattoo(tattoo_line)
	TEST_ASSERT(success, "load_tattoo should return TRUE for intimate zone tattoo")

	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	var/result = get_tattoo_text_for_zone(chest, TATTOO_ZONE_FOREHEAD)
	TEST_ASSERT_EQUAL(result, tattoo_text, "Intimate zone tattoo should load correctly")

/// Тест: load_tattoo отклоняет невалидный формат
/datum/unit_test/tattoo_load_invalid_format

/datum/unit_test/tattoo_load_invalid_format/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	// Неправильное количество полей
	TEST_ASSERT(!H.load_tattoo("1^head"), "load_tattoo should reject line with wrong field count")

	// Версия 0 (невалидная)
	TEST_ASSERT(!H.load_tattoo("0^head^text"), "load_tattoo should reject version 0")

	// Пустая строка
	TEST_ASSERT(!H.load_tattoo(""), "load_tattoo should reject empty string")

/// Тест: load_tattoo отклоняет несуществующую зону тела
/datum/unit_test/tattoo_load_missing_bodypart

/datum/unit_test/tattoo_load_missing_bodypart/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	// Удаляем руку
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	r_arm.drop_limb()
	qdel(r_arm)

	var/tattoo_line = "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][BODY_ZONE_R_ARM][TEST_TATTOO_FIELD_SEP]test"
	TEST_ASSERT(!H.load_tattoo(tattoo_line), "load_tattoo should return FALSE for missing bodypart")

// ===== Полный цикл save/load (format + load) =====

/// Тест: round-trip сериализация и десериализация татуировок
/datum/unit_test/tattoo_roundtrip

/datum/unit_test/tattoo_roundtrip/Run()
	var/mob/living/carbon/human/H1 = allocate(/mob/living/carbon/human)

	// Устанавливаем разнообразные татуировки
	var/head_tat = "<span style='color:#1A1A1A'>\[T]Head tat</span>"
	var/chest_tat = "<span style='color:#FF0000'>\[D]Chest desc</span>"
	var/belly_tat = "<span style='color:#00FF00'>\[T]Belly</span>"
	var/forehead_tat = "<span style='color:#0000FF'>\[D]Forehead</span>"

	var/obj/item/bodypart/head = H1.get_bodypart(BODY_ZONE_HEAD)
	head.tattoo_text = head_tat

	var/obj/item/bodypart/chest = H1.get_bodypart(BODY_ZONE_CHEST)
	chest.tattoo_text = chest_tat
	set_tattoo_text_for_zone(chest, TATTOO_ZONE_BELLY, belly_tat)
	set_tattoo_text_for_zone(chest, TATTOO_ZONE_FOREHEAD, forehead_tat)

	// Сериализуем
	var/formatted = H1.format_tattoos()
	TEST_ASSERT(length(formatted) > 0, "format_tattoos should produce non-empty string")

	// Загружаем на другого человека
	var/mob/living/carbon/human/H2 = allocate(/mob/living/carbon/human)
	for(var/tattoo_line in splittext(formatted, TEST_TATTOO_RECORD_SEP))
		if(!length(tattoo_line))
			continue
		H2.load_tattoo(tattoo_line)

	// Проверяем
	var/obj/item/bodypart/h2_head = H2.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_EQUAL(h2_head.tattoo_text, head_tat, "Head tattoo should survive round-trip")

	var/obj/item/bodypart/h2_chest = H2.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(h2_chest.tattoo_text, chest_tat, "Chest tattoo should survive round-trip")
	TEST_ASSERT_EQUAL(get_tattoo_text_for_zone(h2_chest, TATTOO_ZONE_BELLY), belly_tat, "Belly tattoo should survive round-trip")
	TEST_ASSERT_EQUAL(get_tattoo_text_for_zone(h2_chest, TATTOO_ZONE_FOREHEAD), forehead_tat, "Forehead tattoo should survive round-trip")

/// Тест: round-trip со спецсимволами в тексте
/datum/unit_test/tattoo_roundtrip_special_chars

/datum/unit_test/tattoo_roundtrip_special_chars/Run()
	var/mob/living/carbon/human/H1 = allocate(/mob/living/carbon/human)

	var/special_text = "<span style='color:#1A1A1A'>\[T]Text^with~special</span>"
	var/obj/item/bodypart/r_arm = H1.get_bodypart(BODY_ZONE_R_ARM)
	r_arm.tattoo_text = special_text

	var/formatted = H1.format_tattoos()

	var/mob/living/carbon/human/H2 = allocate(/mob/living/carbon/human)
	for(var/tattoo_line in splittext(formatted, TEST_TATTOO_RECORD_SEP))
		if(!length(tattoo_line))
			continue
		H2.load_tattoo(tattoo_line)

	var/obj/item/bodypart/h2_arm = H2.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_EQUAL(h2_arm.tattoo_text, special_text, "Special characters ^ and ~ should survive round-trip")

// ===== apply_tattoos_to_human =====

/// Тест: apply_tattoos_to_human загружает татуировки из preferences
/datum/unit_test/tattoo_apply_from_prefs

/datum/unit_test/tattoo_apply_from_prefs/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/datum/preferences/P = new
	P.persistent_tattoos = TRUE
	var/tattoo_text = "<span style='color:#1A1A1A'>\[T]Pref tattoo</span>"
	P.tattoos_string = "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][BODY_ZONE_HEAD][TEST_TATTOO_FIELD_SEP][escape_tattoo_text(tattoo_text)][TEST_TATTOO_RECORD_SEP]"

	P.apply_tattoos_to_human(H)

	var/obj/item/bodypart/head = H.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_EQUAL(head.tattoo_text, tattoo_text, "apply_tattoos_to_human should load tattoos from preferences")

/// Тест: apply_tattoos_to_human НЕ грузит при persistent_tattoos = FALSE
/datum/unit_test/tattoo_apply_disabled

/datum/unit_test/tattoo_apply_disabled/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/datum/preferences/P = new
	P.persistent_tattoos = FALSE
	P.tattoos_string = "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][BODY_ZONE_HEAD][TEST_TATTOO_FIELD_SEP]test[TEST_TATTOO_RECORD_SEP]"

	P.apply_tattoos_to_human(H)

	var/obj/item/bodypart/head = H.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_EQUAL(head.tattoo_text, "", "Tattoos should NOT be applied when persistent_tattoos is FALSE")

/// Тест: apply_tattoos_to_human с пустым tattoos_string
/datum/unit_test/tattoo_apply_empty_string

/datum/unit_test/tattoo_apply_empty_string/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/datum/preferences/P = new
	P.persistent_tattoos = TRUE
	P.tattoos_string = ""

	P.apply_tattoos_to_human(H)

	// Не должно крашнуться и не должно быть татуировок
	var/obj/item/bodypart/head = H.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_EQUAL(head.tattoo_text, "", "Empty tattoos_string should result in no tattoos")

/// Тест: apply_tattoos_to_human загружает несколько татуировок на разные зоны
/datum/unit_test/tattoo_apply_multiple_zones

/datum/unit_test/tattoo_apply_multiple_zones/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/datum/preferences/P = new
	P.persistent_tattoos = TRUE

	var/arm_text = "<span style='color:#FF0000'>\[T]Arm</span>"
	var/belly_text = "<span style='color:#00FF00'>\[D]Belly</span>"
	var/head_text = "<span style='color:#0000FF'>\[T]Head</span>"

	P.tattoos_string = "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][BODY_ZONE_R_ARM][TEST_TATTOO_FIELD_SEP][escape_tattoo_text(arm_text)][TEST_TATTOO_RECORD_SEP]"
	P.tattoos_string += "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][TATTOO_ZONE_BELLY][TEST_TATTOO_FIELD_SEP][escape_tattoo_text(belly_text)][TEST_TATTOO_RECORD_SEP]"
	P.tattoos_string += "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][BODY_ZONE_HEAD][TEST_TATTOO_FIELD_SEP][escape_tattoo_text(head_text)][TEST_TATTOO_RECORD_SEP]"

	P.apply_tattoos_to_human(H)

	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_EQUAL(r_arm.tattoo_text, arm_text, "Arm tattoo should be applied")

	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(get_tattoo_text_for_zone(chest, TATTOO_ZONE_BELLY), belly_text, "Belly tattoo should be applied")

	var/obj/item/bodypart/head = H.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_EQUAL(head.tattoo_text, head_text, "Head tattoo should be applied")

// ===== Татуировки и regenerate_limbs =====

/// Тест: regenerate_limbs НЕ заменяет существующие части тела (и их татуировки)
/datum/unit_test/tattoo_survive_regenerate_limbs

/datum/unit_test/tattoo_survive_regenerate_limbs/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/arm_tat = "<span style='color:#1A1A1A'>\[T]Survivor</span>"
	var/belly_tat = "<span style='color:#FF0000'>\[D]Belly survivor</span>"

	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	r_arm.tattoo_text = arm_tat

	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	set_tattoo_text_for_zone(chest, TATTOO_ZONE_BELLY, belly_tat)

	// regenerate_limbs пропускает существующие конечности
	H.regenerate_limbs()

	var/obj/item/bodypart/r_arm_after = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_EQUAL(r_arm_after.tattoo_text, arm_tat, "Tattoo should survive regenerate_limbs on existing bodypart")

	var/obj/item/bodypart/chest_after = H.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(get_tattoo_text_for_zone(chest_after, TATTOO_ZONE_BELLY), belly_tat, "Intimate tattoo should survive regenerate_limbs")

/// Тест: удалённая конечность теряет татуировку, новая — чистая
/datum/unit_test/tattoo_lost_on_dismember

/datum/unit_test/tattoo_lost_on_dismember/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	r_arm.tattoo_text = "<span style='color:#1A1A1A'>\[T]Doomed</span>"

	// Отрываем и удаляем руку
	r_arm.drop_limb()
	qdel(r_arm)

	// Регенерируем
	H.regenerate_limbs()

	var/obj/item/bodypart/new_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_NOTNULL(new_arm, "New arm should be regenerated")
	TEST_ASSERT_EQUAL(new_arm.tattoo_text, "", "Regenerated arm should have no tattoos")

// ===== Отображение (examine) =====

/// Тест: parse_tattoos_for_display корректно парсит стили [T] и [D]
/datum/unit_test/tattoo_parse_display_styles

/datum/unit_test/tattoo_parse_display_styles/Run()
	// Стиль [T] - текст (в кавычках)
	var/list/result_t = parse_tattoos_for_display("<span style='color:#FF0000'>\[T]Надпись</span>")
	TEST_ASSERT_EQUAL(length(result_t), 1, "Should parse one tattoo entry")
	TEST_ASSERT(findtext(result_t[1], "\""), "Text style should wrap in quotes")

	// Стиль [D] - описание (без кавычек)
	var/list/result_d = parse_tattoos_for_display("<span style='color:#FF0000'>\[D]Описание</span>")
	TEST_ASSERT_EQUAL(length(result_d), 1, "Should parse one tattoo entry")
	TEST_ASSERT(!findtext(result_d[1], "\""), "Description style should NOT wrap in quotes")

/// Тест: parse_tattoos_for_display обрабатывает несколько татуировок (разделитель "; ")
/datum/unit_test/tattoo_parse_multiple

/datum/unit_test/tattoo_parse_multiple/Run()
	var/raw = "<span style='color:#FF0000'>\[T]First</span>; <span style='color:#00FF00'>\[D]Second</span>"
	var/list/result = parse_tattoos_for_display(raw)
	TEST_ASSERT_EQUAL(length(result), 2, "Should parse two separate tattoos from '; ' delimiter")

/// Тест: parse_tattoos_for_display с пустой строкой
/datum/unit_test/tattoo_parse_empty

/datum/unit_test/tattoo_parse_empty/Run()
	var/list/result = parse_tattoos_for_display("")
	TEST_ASSERT_EQUAL(length(result), 0, "Empty string should produce empty list")

// ===== Хелперы зон =====

/// Тест: is_intimate_tattoo_zone корректно определяет типы зон
/datum/unit_test/tattoo_zone_helpers

/datum/unit_test/tattoo_zone_helpers/Run()
	// Интимные зоны
	TEST_ASSERT(is_intimate_tattoo_zone(TATTOO_ZONE_BELLY), "TATTOO_ZONE_BELLY should be intimate")
	TEST_ASSERT(is_intimate_tattoo_zone(TATTOO_ZONE_GROIN), "TATTOO_ZONE_GROIN should be intimate")
	TEST_ASSERT(is_intimate_tattoo_zone(TATTOO_ZONE_FOREHEAD), "TATTOO_ZONE_FOREHEAD should be intimate")

	// Стандартные зоны тела — НЕ интимные
	TEST_ASSERT(!is_intimate_tattoo_zone(BODY_ZONE_HEAD), "BODY_ZONE_HEAD should NOT be intimate")
	TEST_ASSERT(!is_intimate_tattoo_zone(BODY_ZONE_R_ARM), "BODY_ZONE_R_ARM should NOT be intimate")

/// Тест: zone_to_intimate_zone маппит зоны корректно
/datum/unit_test/tattoo_zone_mapping

/datum/unit_test/tattoo_zone_mapping/Run()
	TEST_ASSERT_EQUAL(zone_to_intimate_zone(BODY_ZONE_PRECISE_GROIN), TATTOO_ZONE_GROIN, "BODY_ZONE_PRECISE_GROIN should map to TATTOO_ZONE_GROIN")
	TEST_ASSERT_EQUAL(zone_to_intimate_zone(TATTOO_ZONE_BELLY), TATTOO_ZONE_BELLY, "TATTOO_ZONE_BELLY should map to itself")
	TEST_ASSERT_NULL(zone_to_intimate_zone(BODY_ZONE_HEAD), "BODY_ZONE_HEAD should return null (not intimate)")

/// Тест: tattoo_zone_to_body_covered возвращает правильные флаги
/datum/unit_test/tattoo_zone_coverage_flags

/datum/unit_test/tattoo_zone_coverage_flags/Run()
	TEST_ASSERT_EQUAL(tattoo_zone_to_body_covered(BODY_ZONE_HEAD), HEAD, "HEAD zone should map to HEAD flag")
	TEST_ASSERT_EQUAL(tattoo_zone_to_body_covered(BODY_ZONE_CHEST), CHEST, "CHEST zone should map to CHEST flag")
	TEST_ASSERT_EQUAL(tattoo_zone_to_body_covered(TATTOO_ZONE_GROIN), GROIN, "GROIN tattoo zone should map to GROIN flag")
	TEST_ASSERT_EQUAL(tattoo_zone_to_body_covered(TATTOO_ZONE_LIPS), TATTOO_COVERED_MOUTH, "LIPS zone should map to TATTOO_COVERED_MOUTH")
	TEST_ASSERT_EQUAL(tattoo_zone_to_body_covered(TATTOO_ZONE_CHEEKS), TATTOO_COVERED_FACE, "CHEEKS zone should map to TATTOO_COVERED_FACE")
	TEST_ASSERT_EQUAL(tattoo_zone_to_body_covered(TATTOO_ZONE_TAIL), TATTOO_COVERED_TAIL, "TAIL zone should map to TATTOO_COVERED_TAIL")

// ===== Сценарий: tattoo after copy_to (наш фикс) =====

/// Тест: татуировки, применённые ПОСЛЕ regenerate_limbs, сохраняются
/// Воспроизводит сценарий фикса: apply_tattoos_to_human вызывается после copy_to
/datum/unit_test/tattoo_after_regenerate_limbs

/datum/unit_test/tattoo_after_regenerate_limbs/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	// Симулируем что copy_to делает regenerate_limbs
	H.regenerate_limbs()

	// Теперь применяем татуировки (как в нашем фиксе — после copy_to)
	var/datum/preferences/P = new
	P.persistent_tattoos = TRUE

	var/arm_text = "<span style='color:#FF0000'>\[T]Post-regen</span>"
	var/belly_text = "<span style='color:#00FF00'>\[D]Post-regen belly</span>"
	P.tattoos_string = "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][BODY_ZONE_R_ARM][TEST_TATTOO_FIELD_SEP][escape_tattoo_text(arm_text)][TEST_TATTOO_RECORD_SEP]"
	P.tattoos_string += "[TEST_TATTOO_VERSION][TEST_TATTOO_FIELD_SEP][TATTOO_ZONE_BELLY][TEST_TATTOO_FIELD_SEP][escape_tattoo_text(belly_text)][TEST_TATTOO_RECORD_SEP]"

	P.apply_tattoos_to_human(H)

	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_EQUAL(r_arm.tattoo_text, arm_text, "Tattoo applied after regenerate_limbs should persist")

	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(get_tattoo_text_for_zone(chest, TATTOO_ZONE_BELLY), belly_text, "Intimate tattoo applied after regenerate_limbs should persist")

/// Тест: татуировки, применённые ДО regenerate_limbs с dismember, теряются (старый баг)
/// Демонстрирует проблему, которую фикс решает для протезов
/datum/unit_test/tattoo_lost_before_limb_replace

/datum/unit_test/tattoo_lost_before_limb_replace/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	// Применяем татуировку
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	r_arm.tattoo_text = "<span style='color:#FF0000'>\[T]Will be lost</span>"

	// Симулируем замену конечности (как при установке протеза в copy_to)
	var/obj/item/bodypart/old_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	old_arm.drop_limb()
	qdel(old_arm)
	H.regenerate_limbs()

	// Новая рука не должна иметь татуировку
	var/obj/item/bodypart/new_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_NOTNULL(new_arm, "New arm should exist after regeneration")
	TEST_ASSERT_EQUAL(new_arm.tattoo_text, "", "Tattoo should be lost when limb is replaced")

// ===== GLOB.tattoo_zone_data целостность =====

/// Тест: GLOB.tattoo_zone_data содержит все необходимые данные для каждой зоны
/datum/unit_test/tattoo_zone_data_integrity

/datum/unit_test/tattoo_zone_data_integrity/Run()
	TEST_ASSERT(length(GLOB.tattoo_zone_data) > 0, "tattoo_zone_data should not be empty")

	for(var/zone in GLOB.tattoo_zone_data)
		var/list/data = GLOB.tattoo_zone_data[zone]
		TEST_ASSERT(islist(data), "Zone [zone] data should be a list")
		TEST_ASSERT(length(data) >= 5, "Zone [zone] should have at least 5 data entries")
		TEST_ASSERT(length(data[TEST_TDATA_VAR]) > 0, "Zone [zone] should have a variable name")
		TEST_ASSERT(length(data[TEST_TDATA_NAME_PREP]) > 0, "Zone [zone] should have a prepositional name")
		TEST_ASSERT(length(data[TEST_TDATA_NAME_NOM]) > 0, "Zone [zone] should have a nominative name")
		// TATTOO_DATA_ORGAN может быть null (не все зоны привязаны к органам)
		// TATTOO_DATA_COVERED должен быть задан
		TEST_ASSERT_NOTNULL(data[TEST_TDATA_COVERED], "Zone [zone] should have a coverage flag")

#undef TEST_TATTOO_FIELD_SEP
#undef TEST_TATTOO_RECORD_SEP
#undef TEST_TATTOO_VERSION
#undef TEST_TDATA_VAR
#undef TEST_TDATA_NAME_PREP
#undef TEST_TDATA_NAME_NOM
#undef TEST_TDATA_ORGAN
#undef TEST_TDATA_COVERED
