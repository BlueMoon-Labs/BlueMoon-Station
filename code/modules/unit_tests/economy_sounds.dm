/// Звуки экономики лежат в sound/economy, у кассы три варианта звона.
/datum/unit_test/economy_sound_files/Run()
	var/list/sound_names = list(
		"register_ching1", "register_ching2", "register_ching3", "register_drawer", "register_print", "coin_soft",
		"ticker_tick", "market_bell", "market_crash", "node_hum", "node_spinup", "node_overload",
		"locker_clunk", "locker_confirm", "skimmer_click", "news_jingle", "account_freeze",
	)
	for(var/sound_name in sound_names)
		TEST_ASSERT(fexists("sound/economy/[sound_name].ogg"), "Нет звука [sound_name]")
	TEST_ASSERT_EQUAL(length(GLOB.econ_register_chings), 3, "Вариантов звона кассы")
	for(var/ching in GLOB.econ_register_chings)
		TEST_ASSERT(fexists("[ching]"), "Нет звона кассы [ching]")
