#define VOTE_TEST_PLAYER_KEY "votetestplayer"

/// Голосования, которые игрок начинает сам, не закрываются в первый же тик и завершаются по таймеру
/datum/unit_test/vote_player_start
	var/saved_game_state
	var/saved_time_left
	var/saved_started_time
	var/saved_round_type
	var/saved_master_mode
	var/saved_midround_recorded

/datum/unit_test/vote_player_start/Run()
	saved_game_state = SSticker.current_state
	saved_time_left = SSticker.timeLeft
	saved_started_time = SSvote.started_time
	saved_round_type = GLOB.round_type
	saved_master_mode = GLOB.master_mode
	saved_midround_recorded = GLOB.midround_recorded
	GLOB.midround_recorded = TRUE
	TEST_ASSERT_NULL(SSvote.mode, "Перед тестом уже идёт голосование [SSvote.mode]")
	var/vote_period = CONFIG_GET(number/vote_period)

	SSvote.started_time = null
	var/started = SSvote.initiate_vote("restart", VOTE_TEST_PLAYER_KEY)
	TEST_ASSERT(started, "Игрок не смог начать голосование за рестарт")
	SSvote.fire()
	TEST_ASSERT_EQUAL(SSvote.mode, "restart", "Голосование за рестарт закрылось в первый же тик")
	TEST_ASSERT_EQUAL(round(SSvote.get_time_remaining() / 10), round(vote_period / 10), "Голосованию за рестарт посреди раунда показано неверное время")
	SSvote.end_time = world.time - 1
	SSvote.fire()
	TEST_ASSERT_NULL(SSvote.mode, "Голосование за рестарт не закрылось по истечении времени")

	SSvote.started_time = null
	started = SSvote.initiate_vote("roundtype", VOTE_TEST_PLAYER_KEY)
	SSvote.fire()
	TEST_ASSERT(!started, "Голосование за режим посреди раунда стартовало и [SSvote.mode ? "осталось висеть" : "сразу закрылось"], хотя на режим уже не влияет")
	TEST_ASSERT_NULL(SSvote.mode, "После отказа осталось голосование [SSvote.mode]")

	SSticker.current_state = GAME_STATE_PREGAME
	SSticker.timeLeft = ROUNDTYPE_VOTE_END_PENALTY - 1 SECONDS
	SSvote.started_time = null
	TEST_ASSERT(!SSvote.initiate_vote("roundtype", VOTE_TEST_PLAYER_KEY), "Голосование за режим стартовало, когда до начала раунда меньше [DisplayTimeText(ROUNDTYPE_VOTE_END_PENALTY)]")
	SSticker.timeLeft = -1
	TEST_ASSERT(!SSvote.initiate_vote("roundtype", VOTE_TEST_PLAYER_KEY), "Голосование за режим стартовало при отложенном начале раунда")
	TEST_ASSERT_NULL(SSvote.mode, "После отказа в лобби осталось голосование [SSvote.mode]")

	SSticker.timeLeft = vote_period + ROUNDTYPE_VOTE_END_PENALTY + 2 MINUTES
	started = SSvote.initiate_vote("roundtype", VOTE_TEST_PLAYER_KEY)
	TEST_ASSERT(started, "Игрок не смог начать голосование за режим в лобби")
	SSvote.fire()
	TEST_ASSERT_EQUAL(SSvote.mode, "roundtype", "Голосование за режим в лобби закрылось в первый же тик")
	TEST_ASSERT_EQUAL(round(SSvote.get_time_remaining() / 10), round(vote_period / 10), "Голосованию за режим показано время лобби вместо своего")
	GLOB.round_type = null
	SSvote.end_time = world.time - 1
	SSvote.fire()
	TEST_ASSERT_NULL(SSvote.mode, "Голосование за режим не закрылось по истечении времени")
	TEST_ASSERT_NOTNULL(GLOB.round_type, "Голосование за режим закрылось, но режим не выбран")

/datum/unit_test/vote_player_start/Destroy()
	if(SSvote.mode)
		SSvote.reset()
	if(!isnull(saved_game_state))
		SSticker.current_state = saved_game_state
		SSticker.timeLeft = saved_time_left
		SSvote.started_time = saved_started_time
		GLOB.round_type = saved_round_type
		GLOB.master_mode = saved_master_mode
		GLOB.midround_recorded = saved_midround_recorded
	return ..()

#undef VOTE_TEST_PLAYER_KEY
