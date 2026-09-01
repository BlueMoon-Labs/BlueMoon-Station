//Выбранный игроком тип фобии ломался дважды подряд правками одной и той же строки
//санитайзера, поэтому поведение зафиксировано тестом.

/// Санитайзер обязан пропускать валидный выбор, отбрасывать исчезнувший из пула
/// и не трогать ничего, пока пул ещё не собран: клиенты подключаются раньше, чем
/// инициализируется SStraumas, а стёртый на загрузке выбор уезжает на диск
/// первым же save_character.
/datum/unit_test/phobia_pref_sanitize/Run()
	TEST_ASSERT(length(SStraumas.phobia_types), "SStraumas не собрал пул типов фобий")
	var/valid_type = SStraumas.phobia_types[1]

	TEST_ASSERT_EQUAL(SStraumas.sanitize_phobia_type(valid_type), valid_type, "Санитайзер выбросил валидный тип фобии")
	TEST_ASSERT_NULL(SStraumas.sanitize_phobia_type("совершенно точно не тип фобии"), "Санитайзер оставил тип фобии, которого нет в пуле")
	TEST_ASSERT_NULL(SStraumas.sanitize_phobia_type(null), "Санитайзер выдумал тип фобии на месте \"случайной\"")

	//пул пуст ровно так же, как до инициализации подсистемы
	var/list/saved_types = SStraumas.phobia_types
	SStraumas.phobia_types = null
	var/kept_type = SStraumas.sanitize_phobia_type(valid_type)
	SStraumas.phobia_types = saved_types
	TEST_ASSERT_EQUAL(kept_type, valid_type, "Санитайзер стёр выбор игрока, сверившись с ещё не собранным пулом")

/// Выдача фобии: выбор игрока имеет приоритет, случайная берётся только когда выбора нет
/// или он протух.
/datum/unit_test/phobia_pick_respects_preference/Run()
	TEST_ASSERT(length(SStraumas.phobia_types), "SStraumas не собрал пул типов фобий")
	var/valid_type = SStraumas.phobia_types[length(SStraumas.phobia_types)]

	TEST_ASSERT_EQUAL(SStraumas.pick_phobia_type(valid_type), valid_type, "Выбранная игроком фобия подменилась случайной")
	TEST_ASSERT(SStraumas.pick_phobia_type(null) in SStraumas.phobia_types, "Случайная фобия взялась не из пула")
	TEST_ASSERT(SStraumas.pick_phobia_type("совершенно точно не тип фобии") in SStraumas.phobia_types, "Протухший выбор доехал до выдачи как есть")
