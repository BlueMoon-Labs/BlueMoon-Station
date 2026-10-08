/// Серия режимов применяется только при онлайне не ниже порога и вне ночного окна, окно может идти через полночь
/datum/unit_test/roundtype_rotation_applies
	requires_full_map = FALSE
	var/list/saved_config

/datum/unit_test/roundtype_rotation_applies/Run()
	saved_config = list(
		"min_players" = CONFIG_GET(number/roundtype_rotation_min_players),
		"night_start" = CONFIG_GET(number/roundtype_rotation_night_start_hour),
		"night_end" = CONFIG_GET(number/roundtype_rotation_night_end_hour),
	)
	CONFIG_SET(number/roundtype_rotation_min_players, 60)
	CONFIG_SET(number/roundtype_rotation_night_start_hour, 22)
	CONFIG_SET(number/roundtype_rotation_night_end_hour, 9)

	TEST_ASSERT(!SSvote.roundtype_rotation_applies(59, 15), "Серия применилась при онлайне 59 из 60")
	TEST_ASSERT(SSvote.roundtype_rotation_applies(60, 15), "Серия не применилась при онлайне ровно 60 днём")
	TEST_ASSERT(!SSvote.roundtype_rotation_applies(80, 22), "Серия применилась в 22, на начале ночного окна")
	TEST_ASSERT(!SSvote.roundtype_rotation_applies(80, 23), "Серия применилась в 23")
	TEST_ASSERT(!SSvote.roundtype_rotation_applies(80, 0), "Серия применилась в полночь")
	TEST_ASSERT(!SSvote.roundtype_rotation_applies(80, 8), "Серия применилась в 8, до конца ночного окна")
	TEST_ASSERT(SSvote.roundtype_rotation_applies(80, 9), "Серия не применилась в 9, когда ночь уже кончилась")
	TEST_ASSERT(SSvote.roundtype_rotation_applies(80, 21), "Серия не применилась в 21, до начала ночи")

	CONFIG_SET(number/roundtype_rotation_night_start_hour, 1)
	CONFIG_SET(number/roundtype_rotation_night_end_hour, 7)
	TEST_ASSERT(!SSvote.roundtype_rotation_applies(80, 3), "Серия применилась внутри окна 1-7")
	TEST_ASSERT(SSvote.roundtype_rotation_applies(80, 0), "Серия не применилась в 0 при окне 1-7")
	TEST_ASSERT(SSvote.roundtype_rotation_applies(80, 7), "Серия не применилась в 7 при окне 1-7")

/datum/unit_test/roundtype_rotation_applies/Destroy()
	if(saved_config)
		CONFIG_SET(number/roundtype_rotation_min_players, saved_config["min_players"])
		CONFIG_SET(number/roundtype_rotation_night_start_hour, saved_config["night_start"])
		CONFIG_SET(number/roundtype_rotation_night_end_hour, saved_config["night_end"])
	return ..()

/// check_combo() видит две одинаковые группы в начале истории режимов
/datum/unit_test/roundtype_rotation_combo
	requires_full_map = FALSE
	var/list/saved_round_types

/datum/unit_test/roundtype_rotation_combo/Run()
	saved_round_types = SSpersistence.saved_round_types

	SSpersistence.saved_round_types = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_EXTENDED)
	TEST_ASSERT_EQUAL(SSvote.check_combo(), ROUNDTYPE_ROTATION_HEAVY, "Medium и Hard подряд не дали тяжёлую серию")

	SSpersistence.saved_round_types = list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_DYNAMIC_HARD)
	TEST_ASSERT_EQUAL(SSvote.check_combo(), ROUNDTYPE_ROTATION_LIGHT, "Extended и Light подряд не дали лёгкую серию")

	SSpersistence.saved_round_types = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_HARD)
	TEST_ASSERT(!SSvote.check_combo(), "Серия нашлась там, где группы чередуются")

/datum/unit_test/roundtype_rotation_combo/Destroy()
	SSpersistence.saved_round_types = saved_round_types
	return ..()

/// Без серии или вне полноценного раунда бюллетень полный, в полноценном раунде серия оставляет только другую группу
/datum/unit_test/roundtype_rotation_ballot
	requires_full_map = FALSE

/datum/unit_test/roundtype_rotation_ballot/Run()
	var/list/ballot = SSvote.roundtype_ballot_choices(ROUNDTYPE_ROTATION_HEAVY, FALSE)
	TEST_ASSERT_EQUAL(length(ballot), 2, "Тяжёлая серия сузила бюллетень в неполноценном раунде: [jointext(ballot, ", ")]")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC in ballot, "В неполноценном раунде из бюллетеня пропал [ROUNDTYPE_DYNAMIC]: [jointext(ballot, ", ")]")

	ballot = SSvote.roundtype_ballot_choices(FALSE, TRUE)
	TEST_ASSERT_EQUAL(length(ballot), 2, "Без серии бюллетень сузился: [jointext(ballot, ", ")]")

	ballot = SSvote.roundtype_ballot_choices(ROUNDTYPE_ROTATION_HEAVY, TRUE)
	TEST_ASSERT_EQUAL(length(ballot), 1, "Тяжёлая серия в полноценном раунде не сузила бюллетень: [jointext(ballot, ", ")]")
	TEST_ASSERT_EQUAL(SSvote.get_roundtype_rotation_group(ballot[1]), ROUNDTYPE_ROTATION_LIGHT, "После тяжёлой серии в бюллетене остался [ballot[1]]")

	ballot = SSvote.roundtype_ballot_choices(ROUNDTYPE_ROTATION_LIGHT, TRUE)
	TEST_ASSERT_EQUAL(jointext(ballot, ", "), ROUNDTYPE_DYNAMIC, "После лёгкой серии в бюллетене не один динамик")

/// Неполноценный раунд не двигает историю режимов, полноценный ставит свой тип первым
/datum/unit_test/roundtype_rotation_history
	requires_full_map = FALSE
	var/list/saved_round_types

/datum/unit_test/roundtype_rotation_history/Run()
	saved_round_types = SSpersistence.saved_round_types
	SSpersistence.saved_round_types = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_EXTENDED)

	SSpersistence.RecordRecentRoundType(ROUNDTYPE_DYNAMIC_HARD, FALSE)
	TEST_ASSERT_EQUAL(jointext(SSpersistence.saved_round_types, ","), "[ROUNDTYPE_DYNAMIC_MEDIUM],[ROUNDTYPE_DYNAMIC_HARD],[ROUNDTYPE_EXTENDED]", "Неполноценный раунд записался в историю режимов")

	var/list/original = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_EXTENDED)
	var/list/shifted = SSpersistence.next_recent_round_types(original, ROUNDTYPE_DYNAMIC_LIGHT)
	TEST_ASSERT_EQUAL(jointext(shifted, ","), "[ROUNDTYPE_DYNAMIC_LIGHT],[ROUNDTYPE_DYNAMIC_MEDIUM],[ROUNDTYPE_DYNAMIC_HARD]", "Полноценный раунд не встал первым в историю")
	TEST_ASSERT_EQUAL(jointext(original, ","), "[ROUNDTYPE_DYNAMIC_MEDIUM],[ROUNDTYPE_DYNAMIC_HARD],[ROUNDTYPE_EXTENDED]", "Расчёт новой истории испортил исходный список")

	shifted = SSpersistence.next_recent_round_types(list(), ROUNDTYPE_EXTENDED)
	TEST_ASSERT_EQUAL(jointext(shifted, ","), "[ROUNDTYPE_EXTENDED],,", "Пустая история не дополнилась до трёх записей")

/datum/unit_test/roundtype_rotation_history/Destroy()
	SSpersistence.saved_round_types = saved_round_types
	return ..()

/// Голосование без голосов в полноценном раунде после серии берёт режим из другой группы
/datum/unit_test/roundtype_rotation_no_votes
	requires_full_map = FALSE
	var/list/saved_round_types
	var/saved_counts_for_rotation

/datum/unit_test/roundtype_rotation_no_votes/Run()
	saved_round_types = SSpersistence.saved_round_types
	saved_counts_for_rotation = GLOB.round_counts_for_rotation
	GLOB.round_counts_for_rotation = TRUE

	SSpersistence.saved_round_types = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_EXTENDED)
	var/picked = SSvote.pick_roundtype_without_votes()
	TEST_ASSERT_EQUAL(SSvote.get_roundtype_rotation_group(picked), ROUNDTYPE_ROTATION_LIGHT, "После тяжёлой серии без голосов выбран [picked]")

	SSpersistence.saved_round_types = list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_DYNAMIC_MEDIUM)
	picked = SSvote.pick_roundtype_without_votes()
	TEST_ASSERT_EQUAL(SSvote.get_roundtype_rotation_group(picked), ROUNDTYPE_ROTATION_HEAVY, "После лёгкой серии без голосов выбран [picked]")

/datum/unit_test/roundtype_rotation_no_votes/Destroy()
	SSpersistence.saved_round_types = saved_round_types
	GLOB.round_counts_for_rotation = saved_counts_for_rotation
	return ..()
