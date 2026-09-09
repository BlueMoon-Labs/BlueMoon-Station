/**
 * Пул тайных сатчелов копится между раундами: за раунд из него забирается РОВНО ОДНА
 * запись (LoadSatchels), а дописывается столько, сколько игроки спрятали. На проде
 * (раунд 10119) в нём лежало 17 752 записи - это ~4 МБ живых assoc-списков плюс
 * json_encode одной непрерывной строкой на каждом закрытии раунда.
 *
 * Тесты держат кап: в файл уезжают только САМЫЕ СВЕЖИЕ SECRET_SATCHEL_POOL_CAP записей.
 */

/// Пул длиннее капа обрезается ровно до капа.
/datum/unit_test/secret_satchel_pool_capped/Run()
	var/list/pool = list()
	for(var/i in 1 to SECRET_SATCHEL_POOL_CAP + 50)
		pool += list(list("x" = i, "y" = i, "saved_obj" = "/obj/item/stack/sheet/iron"))

	var/list/trimmed = trim_satchel_pool(pool)

	TEST_ASSERT_EQUAL(length(trimmed), SECRET_SATCHEL_POOL_CAP, "Пул на [SECRET_SATCHEL_POOL_CAP + 50] записей обязан обрезаться до капа")

/// Обрезка выбрасывает СТАРЫЕ записи, а не новые: свежие сатчелы игроки прячут в этом
/// раунде, и потерять надо самые древние.
/datum/unit_test/secret_satchel_pool_keeps_newest/Run()
	var/list/pool = list()
	for(var/i in 1 to SECRET_SATCHEL_POOL_CAP + 50)
		pool += list(list("x" = i, "y" = i, "saved_obj" = "/obj/item/stack/sheet/iron"))

	var/list/trimmed = trim_satchel_pool(pool)
	var/list/first_kept = trimmed[1]
	var/list/last_kept = trimmed[length(trimmed)]

	TEST_ASSERT_EQUAL(last_kept["x"], SECRET_SATCHEL_POOL_CAP + 50, "Последняя запись пула обязана пережить обрезку")
	TEST_ASSERT_EQUAL(first_kept["x"], 51, "Обрезка обязана снять первые 50 записей, а не последние")

/// Пул короче капа не трогаем вовсе - иначе на свежей карте пул схлопнется в ноль.
/datum/unit_test/secret_satchel_pool_under_cap_untouched/Run()
	var/list/pool = list(
		list("x" = 1, "y" = 1, "saved_obj" = "/obj/item/stack/sheet/iron"),
		list("x" = 2, "y" = 2, "saved_obj" = "/obj/item/stack/sheet/glass"),
	)

	var/list/trimmed = trim_satchel_pool(pool)
	var/list/second = trimmed[2]

	TEST_ASSERT_EQUAL(length(trimmed), 2, "Короткий пул обрезаться не должен")
	TEST_ASSERT_EQUAL(second["saved_obj"], "/obj/item/stack/sheet/glass", "Короткий пул обязан сохранить порядок и содержимое")

/// json_decode на файле без ключа "data" отдаёт null - обрезка обязана это пережить и
/// вернуть пустой список, а не уронить SaveGamePersistence на закрытии раунда.
/datum/unit_test/secret_satchel_pool_null_safe/Run()
	var/list/trimmed = trim_satchel_pool(null)

	TEST_ASSERT_NOTNULL(trimmed, "Обрезка null-пула обязана вернуть список, а не null")
	TEST_ASSERT_EQUAL(length(trimmed), 0, "Обрезка null-пула обязана вернуть пустой список")

/// Битый файл отдаёт под ключом "data" что угодно, и чаще всего строку. У строки в DM есть
/// и length(), и Copy() - без явной проверки типа обрезка молча вернула бы кусок текста,
/// который дальше поехал бы в пул сатчелов.
/datum/unit_test/secret_satchel_pool_rejects_non_list/Run()
	var/list/from_text = trim_satchel_pool("не список, а строка из битого json")
	var/list/from_number = trim_satchel_pool(42)

	TEST_ASSERT_EQUAL(length(from_text), 0, "Строка вместо пула обязана дать пустой список")
	TEST_ASSERT_EQUAL(length(from_number), 0, "Число вместо пула обязано дать пустой список")
