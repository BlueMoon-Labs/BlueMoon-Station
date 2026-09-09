/**
 * Ссылка слежения ведёт к ТОЙ САМОЙ цели, а не к тому, что заняло её слот.
 *
 * ЗАЧЕМ ТЕСТ. REF() в href - это индекс в таблице BYOND, и он переиспользуется сразу после
 * удаления атома, а ссылка (F) уезжает в чат текстом и живёт там до конца раунда. Проверки
 * по типу тут мало: она отсекает служебный хлам вроде объекта освещения, но НЕ отличает
 * исходную цель от другого моба, занявшего тот же слот, - обоим ismob() отвечает "да".
 * То же и в меню орбиты: список уезжает клиенту снимком в ui_static_data и через пару минут
 * половина строк указывает на удалённых, а "in GLOB.mob_list" подмену пропускает.
 *
 * Инвариант держит монотонный счётчик: значение не выдаётся дважды, поэтому совпадение
 * токена и есть доказательство идентичности. Сломать это молча легко - достаточно вернуть
 * в href голый REF или сбросить счётчик, - и снаружи ничего не изменится до первого
 * переиспользования слота на проде.
 */
/datum/unit_test/ghost_follow_link_identity/Run()
	var/obj/effect/landmark/first = allocate(/obj/effect/landmark)
	var/obj/effect/landmark/second = allocate(/obj/effect/landmark)

	var/first_token = first.get_follow_token()
	var/second_token = second.get_follow_token()
	TEST_ASSERT(first_token > 0, "токен цели слежения обязан быть ненулевым, получено [first_token]")
	TEST_ASSERT_NOTEQUAL(first_token, second_token, "двум разным целям выдан один токен [first_token] - счётчик перестал быть монотонным")
	TEST_ASSERT_EQUAL(first.get_follow_token(), first_token, "повторный запрос обязан отдавать тот же токен, а не выписывать новый")

	var/href_params = follow_href_params(first)
	TEST_ASSERT(findtext(href_params, "follow=[REF(first)]"), "в href слежения обязана быть ссылка на цель: [href_params]")
	TEST_ASSERT(findtext(href_params, "follow_token=[first_token]"), "в href слежения обязан быть токен идентичности: [href_params]")

	TEST_ASSERT_EQUAL(ghost_follow_resolve(REF(first), "[first_token]"), first, "свой токен обязан отдавать саму цель")
	// Ровно тот случай, ради которого всё и делалось: слот переиспользован, locate() отдаёт
	// живой и валидный по типу атом, но это УЖЕ НЕ ТА цель, для которой строилась ссылка.
	TEST_ASSERT_NULL(ghost_follow_resolve(REF(first), "[second_token]"), "чужой токен обязан отвергать цель, иначе слежение уходит к постороннему")
	TEST_ASSERT_NULL(ghost_follow_resolve(REF(first), "[first_token + 1000]"), "несуществующий токен обязан отвергать цель")

	// Ссылка без токена - это старая строка из чата, пережившая правку кода. Для неё
	// остаётся прежняя проверка по типу: не строже, но и не слабее, чем было.
	TEST_ASSERT_EQUAL(ghost_follow_resolve(REF(first), null), first, "ссылка без токена обязана падать на проверку по типу, а лендмарк её проходит")

	var/obj/effect/plain = allocate(/obj/effect)
	TEST_ASSERT_NULL(ghost_follow_resolve(REF(plain), null), "безтокенная ссылка на служебный движимый атом обязана отвергаться проверкой по типу")
	TEST_ASSERT_EQUAL(ghost_follow_resolve(REF(plain), "[plain.get_follow_token()]"), plain, "совпавший токен доказывает идентичность и снимает вопрос о типе")
