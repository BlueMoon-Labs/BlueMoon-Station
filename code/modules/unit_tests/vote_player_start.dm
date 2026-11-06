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

/// Попытка начать голосование поверх идущего не меняет ему систему подсчёта и вес голосов, а окно объясняет отказ
/datum/unit_test/vote_refused_start_keeps_active_vote
	var/saved_started_time
	var/saved_vote_delay

/datum/unit_test/vote_refused_start_keeps_active_vote/Run()
	saved_started_time = SSvote.started_time
	saved_vote_delay = CONFIG_GET(number/vote_delay)
	TEST_ASSERT_NULL(SSvote.mode, "Перед тестом уже идёт голосование [SSvote.mode]")
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)

	SSvote.started_time = null
	TEST_ASSERT(SSvote.initiate_vote("transfer", "server", votesystem = APPROVAL_VOTING, vote_time = 1 MINUTES, UseVotePower = TRUE), "Голосование за окончание раунда не началось")
	TEST_ASSERT(!SSvote.initiate_vote("restart", VOTE_TEST_PLAYER_KEY), "Игрок начал второе голосование поверх идущего")
	TEST_ASSERT_EQUAL(SSvote.mode, "transfer", "Отказ сбил идущее голосование")
	TEST_ASSERT_EQUAL(SSvote.vote_system, APPROVAL_VOTING, "Отказ сменил идущему голосованию систему подсчёта")
	TEST_ASSERT(SSvote.use_vote_power, "Отказ снял идущему голосованию вес голосов")
	TEST_ASSERT_NOTNULL(SSvote.vote_start_block_reason(viewer), "Во время голосования окно не объясняет, почему нельзя начать новое")

	SSvote.reset()
	CONFIG_SET(number/vote_delay, 10 MINUTES)
	TEST_ASSERT_NOTNULL(SSvote.vote_start_block_reason(viewer), "Сразу после голосования игроку не показан кулдаун")
	TEST_ASSERT(!SSvote.initiate_vote("restart", VOTE_TEST_PLAYER_KEY), "Игрок начал голосование в кулдаун")
	SSvote.started_time = null
	TEST_ASSERT_NULL(SSvote.vote_start_block_reason(viewer), "Без голосования и кулдауна старт всё равно заблокирован")

/datum/unit_test/vote_refused_start_keeps_active_vote/Destroy()
	if(SSvote.mode)
		SSvote.reset()
	SSvote.use_vote_power = FALSE
	SSvote.started_time = saved_started_time
	if(!isnull(saved_vote_delay))
		CONFIG_SET(number/vote_delay, saved_vote_delay)
	return ..()

#undef VOTE_TEST_PLAYER_KEY
