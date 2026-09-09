/**
 * Отпускание удалённых мобов AI-контроллерами и опознание держателя в warnfail.
 *
 * Прод-раунд 10146 (48 минут): 62 дорогих харддела на 8.0 секунды суммарно, из
 * них 25 /mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion и 10
 * /mob/living/simple_animal/hostile/clockwork/clocktank/weak, каждый по ~110 мс.
 * В dd.log у брудов ровно "внешних ссылок: 1" (14 отказов сборки) либо "2" (13
 * отказов) и НИ ОДНОЙ улики в warnfail-контексте: не в loc, без живых таймеров,
 * без неснятых подписок, не в vis_contents, не бакнут. То есть держатель -
 * обычная переменная или список, и он один и тот же во всех случаях.
 *
 * Новое по сравнению с разбором 9823/9824: по attack.log видно, что дрались эти
 * мобы ДРУГ С ДРУГОМ (легионы против клокворк-танков на лаваленде, элиты NT под
 * огнём турелей InteQ), а не только с игроками. Значит первый подозреваемый -
 * структуры контроллера ПРОТИВНИКА: каждый удар прогоняет RetaliateAgainst() ->
 * note_attacker(), а тот кладёт обидчика сразу в несколько ключей блэкборда
 * (BB_AI_LAST_ATTACKER, BB_AI_GRUDGE_LIST, BB_AI_CURRENT_TARGET, при потере LOS
 * ещё и BB_AI_CONTACT_TARGET).
 *
 * Первые два теста фиксируют, что этот путь чист: sig_remove_from_blackboard()
 * снимает ВСЕ ключи серии и вычищает вложенный список обид. Проверено на живой
 * сборке и отдельным зондом BYOND 516.1687: вопреки распространённому в
 * кодбазе поверью, for(var/x in L) с удалением ТЕКУЩЕГО элемента индекс НЕ
 * проматывает - из list("k1".."k5") с одинаковым значением обход посещает все
 * пять ключей и не оставляет ни одного. Поверье верно только для правки ДРУГИХ
 * элементов списка.
 *
 * Третий тест проверяет добавленную улику: раз блэкборд чист, а держателя всё
 * ещё не назвали, warnfail обязан сам сообщать, если утёкший моб лежит в
 * блэкборде живого контроллера - иначе следующий разбор снова уйдёт в перебор
 * гипотез по коду.
 *
 * Контроллер собирается базовым /datum/ai_controller: у него нет ни сабтри, ни
 * idle-поведения, поэтому сам он в блэкборд не пишет, и порядок ключей задают
 * сами тесты. Сплошность серии проверяется по длине блэкборда.
 */

/// Пустой контроллер поверх пауна: паун нужен, чтобы post_blackboard_key_set()
/// шёл штатным путём, а не ранним выходом по пустому pawn.
/datum/unit_test/proc/blackboard_release_controller(mob/living/pawn)
	return new /datum/ai_controller(pawn)

/// Серия прямых ключей на одну цель - форма note_attacker() + RetaliateAgainst().
/// После qdel цели в блэкборде не должно остаться ни одного из них.
/datum/unit_test/ai_blackboard_releases_deleted_target/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/quarry = allocate(/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/controller = blackboard_release_controller(hunter)
	var/baseline_keys = length(controller.blackboard)
	var/list/target_keys = list(
		BB_AI_CURRENT_TARGET,
		BB_AI_LAST_ATTACKER,
		BB_AI_CONTACT_TARGET,
		BB_AI_MOB_BLOCKED_TARGET,
		BB_AI_CONGESTED_TARGET,
	)
	for(var/key in target_keys)
		controller.set_blackboard_key(key, quarry)
	TEST_ASSERT_EQUAL(length(controller.blackboard), baseline_keys + length(target_keys), "Между ключами цели вклинились чужие - серия не сплошная, тест проверял бы не то")

	allocated -= quarry
	qdel(quarry)

	var/list/leftovers = list()
	for(var/key in controller.blackboard)
		if(controller.blackboard[key] == quarry)
			leftovers += key
	TEST_ASSERT(!length(leftovers), "Из серии в [length(target_keys)] ключей уцелело [length(leftovers)]: [leftovers.Join(", ")]")

	qdel(controller)

/// Список обид лежит ВЛОЖЕННЫМ списком, и обидчик там - ключ, а не значение.
/// Ровно эту пару ключей ставит note_attacker().
/datum/unit_test/ai_grudge_list_releases_dead_attacker/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/clockwork/clocktank/weak/attacker = allocate(/mob/living/simple_animal/hostile/clockwork/clocktank/weak, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/controller = blackboard_release_controller(victim)
	controller.set_blackboard_key(BB_AI_LAST_ATTACKER, attacker)
	controller.set_blackboard_key_assoc_lazylist(BB_AI_GRUDGE_LIST, attacker, world.time)

	var/list/grudges = controller.blackboard[BB_AI_GRUDGE_LIST]
	TEST_ASSERT_NOTNULL(grudges, "Sanity: список обид не создан")
	TEST_ASSERT_NOTNULL(grudges[attacker], "Sanity: обидчик не попал в список обид")

	allocated -= attacker
	qdel(attacker)

	TEST_ASSERT_NULL(controller.blackboard[BB_AI_LAST_ATTACKER], "Удалённый обидчик остался в BB_AI_LAST_ATTACKER")
	TEST_ASSERT(!(attacker in grudges), "Удалённый обидчик остался ключом списка обид - вложенный список пропустили при обходе блэкборда")

	qdel(controller)

/// Улика warnfail: если утёкшего моба держит блэкборд ЖИВОГО контроллера,
/// строка отказа сборки обязана назвать этот контроллер и ключ. Иначе такой
/// держатель не виден вообще ничем: полный ref-скан датумов до блэкборда
/// доходит на четвёртой минуте, а warnfail наступает на второй.
/datum/unit_test/warnfail_context_names_ai_blackboard_holder/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/quarry = allocate(/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/controller = blackboard_release_controller(hunter)
	var/clean_context = SSgarbage.build_warnfail_context(quarry)
	TEST_ASSERT(!findtext(clean_context, "блэкборд"), "Проб нашёл держателя там, где блэкборд пуст: [clean_context]")

	//прямая запись в обход сеттера: нам нужен именно НЕснятый ключ, а сеттер
	//подписался бы на qdel и снял его сам
	controller.blackboard[BB_AI_CURRENT_TARGET] = quarry
	var/dirty_context = SSgarbage.build_warnfail_context(quarry)
	TEST_ASSERT(findtext(dirty_context, "блэкборд"), "Улика о держателе-блэкборде не попала в контекст warnfail: [dirty_context]")
	TEST_ASSERT(findtext(dirty_context, BB_AI_CURRENT_TARGET), "В улике нет имени ключа-держателя: [dirty_context]")

	controller.blackboard[BB_AI_CURRENT_TARGET] = null
	qdel(controller)
