/// 10782: пробуждение еретика выбрало игрока без ввода 10 минут.
/datum/unit_test/midround_conversion_skips_afk

/datum/unit_test/midround_conversion_skips_afk/Run()
	var/mob/living/carbon/human/candidate = allocate(/mob/living/carbon/human)
	candidate.mind_initialize()
	allocated += candidate.mind
	var/datum/client_interface/mock = new
	candidate.mock_client = mock
	var/datum/dynamic_ruleset/midround/crew_conversion/heretic/heretic_rule = allocate(/datum/dynamic_ruleset/midround/crew_conversion/heretic)
	var/datum/dynamic_ruleset/midround/crew_conversion/changeling/changeling_rule = allocate(/datum/dynamic_ruleset/midround/crew_conversion/changeling)
	var/active_heretic = heretic_rule.can_convert(candidate)
	mock.last_activity = world.time - CONFIG_GET(number/inactivity_period) - 1
	var/afk_heretic = heretic_rule.can_convert(candidate)
	var/afk_changeling = changeling_rule.can_convert(candidate)
	candidate.mock_client = null
	TEST_ASSERT(active_heretic, "Активный игрок подходит для пробуждения")
	TEST_ASSERT(!afk_heretic, "Отошедший от клавиатуры не получает пробуждение еретика")
	TEST_ASSERT(!afk_changeling, "Отошедший от клавиатуры не получает генокрада")

/// Отбор без фильтров клиента: мок-клиент не проходит проверку преференсов, проверяется только отсев по активности.
/datum/dynamic_ruleset/midround/test_afk_filter
	name = "Test Midround AFK Filter"
	weight = 0
	cost = 0
	requirements = list(0,0,0,0,0,0,0,0,0,0)
	required_round_type = null

/datum/dynamic_ruleset/midround/test_afk_filter/trim_list(list/L = list())
	return L.Copy()

/// 10782: AFK и отказавшийся отсеиваются и в отборе бита, и в повторной проверке перед выдачей роли.
/datum/unit_test/midround_pick_filters_skip_afk

/datum/unit_test/midround_pick_filters_skip_afk/proc/make_candidate()
	var/mob/living/carbon/human/candidate = allocate(/mob/living/carbon/human)
	candidate.mind_initialize()
	allocated += candidate.mind
	candidate.mock_client = new /datum/client_interface
	return candidate

/datum/unit_test/midround_pick_filters_skip_afk/Run()
	var/mob/living/carbon/human/active = make_candidate()
	var/mob/living/carbon/human/afk = make_candidate()
	var/mob/living/carbon/human/declined = make_candidate()
	afk.mock_client.last_activity = world.time - CONFIG_GET(number/inactivity_period) - 1
	declined.mind.declined_antag_role = TRUE
	var/datum/game_mode/dynamic/test_mode = allocate(/datum/game_mode/dynamic)
	test_mode.current_players[CURRENT_LIVING_PLAYERS] = list(active, afk, declined)
	var/datum/dynamic_ruleset/midround/test_afk_filter/rule = allocate(/datum/dynamic_ruleset/midround/test_afk_filter)
	rule.mode = test_mode
	rule.trim_candidates()
	var/list/picked = rule.living_players.Copy()
	rule.living_players = list(active, afk, declined)
	rule.prune_stale_living_players()
	var/list/pruned = rule.living_players.Copy()
	for(var/mob/living/carbon/human/candidate as anything in list(active, afk, declined))
		candidate.mock_client = null
	TEST_ASSERT_EQUAL(length(picked), 1, "Отбор бита оставляет только активного: [length(picked)]")
	TEST_ASSERT(active in picked, "Активный игрок проходит отбор бита")
	TEST_ASSERT_EQUAL(length(pruned), 1, "Проверка перед выдачей оставляет только активного: [length(pruned)]")
	TEST_ASSERT(active in pruned, "Активный игрок проходит проверку перед выдачей")

/// Страховка директора ждёт DIRECTOR_ANTAG_LOSS_GRACE: 10775 перевыдача через 14 с и 10776 оживление получали возврат.
/datum/unit_test/director_antag_loss_grace

/datum/unit_test/director_antag_loss_grace/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.reset_budgets(0)
		SSdirector.time_override = world.time + 1 MINUTES
		var/mob/living/carbon/human/revived = allocate(/mob/living/carbon/human)
		revived.mind_initialize()
		var/datum/antagonist/revived_marker = new
		revived_marker.silent = TRUE
		revived.mind.add_antag_datum(revived_marker)
		var/mob/living/carbon/human/regiven = allocate(/mob/living/carbon/human)
		regiven.mind_initialize()
		var/datum/antagonist/regiven_marker = new
		regiven_marker.silent = TRUE
		regiven.mind.add_antag_datum(regiven_marker)
		var/datum/dynamic_ruleset/midround/test_pool_isolation/rule = new
		rule.assigned = list(revived.mind, regiven.mind)
		rule.director_pending_cost = 10
		SSdirector.confirm_action_success(rule)

		revived.stat = DEAD
		regiven.mind.remove_antag_datum(regiven_marker.type)
		SSdirector.tally_ruleset_intensity(rule)
		SSdirector.time_override += DIRECTOR_ANTAG_LOSS_GRACE - 1
		revived.stat = CONSCIOUS
		var/datum/antagonist/second_marker = new
		second_marker.silent = TRUE
		regiven.mind.add_antag_datum(second_marker)
		SSdirector.tally_ruleset_intensity(rule)
		SSdirector.time_override += DIRECTOR_ANTAG_LOSS_GRACE
		SSdirector.tally_ruleset_intensity(rule)
		var/wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(wallets, 0, "Оживление и перевыдача роли в отсрочке не дают возврата")
		TEST_ASSERT_EQUAL(length(rule.director_loss_refund_values), 2, "Полисы вернувшихся ролей остаются открытыми")

		revived.stat = DEAD
		SSdirector.tally_ruleset_intensity(rule)
		SSdirector.time_override += DIRECTOR_ANTAG_LOSS_GRACE
		SSdirector.tally_ruleset_intensity(rule)
		wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(wallets, 0.1), 5, "Потеря, продержавшаяся отсрочку, возвращает свою долю")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Гост-роли ждут ту же отсрочку страховки: член команды, оживлённый за DIRECTOR_ANTAG_LOSS_GRACE, полис не закрывает.
/datum/unit_test/director_ghost_role_loss_grace

/datum/unit_test/director_ghost_role_loss_grace/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.reset_budgets(0)
		SSdirector.intensity_ledger = list()
		SSdirector.live_ghost_role_spawns = list()
		SSdirector.time_override = world.time + 1 MINUTES
		var/mob/living/carbon/human/raider = allocate(/mob/living/carbon/human)
		raider.mind_initialize()
		var/mob/living/carbon/human/drone = allocate(/mob/living/carbon/human)
		var/datum/director_action/test_stub/team = new
		team.severity = DIRECTOR_SEVERITY_GHOST
		team.cost = 10
		team.intensity = 10
		TEST_ASSERT(SSdirector.track_ghost_role_spawn(team, list(raider, drone), budget_backed = TRUE, log_execution = FALSE), "Команда переходит на живой трекинг")

		raider.stat = DEAD
		drone.stat = DEAD
		SSdirector.get_ghost_role_intensity()
		TEST_ASSERT_EQUAL(length(SSdirector.live_ghost_role_spawns), 1, "Запись с полисами в отсрочке не удаляется")
		SSdirector.time_override += DIRECTOR_ANTAG_LOSS_GRACE - 1
		raider.stat = CONSCIOUS
		drone.stat = CONSCIOUS
		SSdirector.get_ghost_role_intensity()
		SSdirector.time_override += DIRECTOR_ANTAG_LOSS_GRACE
		SSdirector.get_ghost_role_intensity()
		var/wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(wallets, 0, "Оживление в отсрочке не даёт возврата ни разуму, ни мобу без разума")

		raider.stat = DEAD
		SSdirector.get_ghost_role_intensity()
		SSdirector.time_override += DIRECTOR_ANTAG_LOSS_GRACE
		SSdirector.get_ghost_role_intensity()
		wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(wallets, 0.1), 5, "Потеря, продержавшаяся отсрочку, возвращает свою долю")
		TEST_ASSERT_EQUAL(length(SSdirector.live_ghost_role_spawns), 1, "Живой член команды держит запись")
		drone.stat = DEAD
		SSdirector.get_ghost_role_intensity()
		SSdirector.time_override += DIRECTOR_ANTAG_LOSS_GRACE
		SSdirector.get_ghost_role_intensity()
		TEST_ASSERT_EQUAL(length(SSdirector.live_ghost_role_spawns), 0, "Запись уходит, когда закрыт последний полис")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// 10667: «Heretics, scaled 1 times» при одном еретике съедало 9 бюджета старта, и трейторам уже не хватало.
/datum/unit_test/dynamic_roundstart_scale_limit

/datum/unit_test/dynamic_roundstart_scale_limit/Run()
	var/datum/game_mode/dynamic/test_mode = allocate(/datum/game_mode/dynamic)
	var/datum/dynamic_ruleset/roundstart/heretics/rule = allocate(/datum/dynamic_ruleset/roundstart/heretics)
	rule.mode = test_mode
	for(var/candidate_index in 1 to 5)
		var/mob/living/carbon/human/candidate = allocate(/mob/living/carbon/human)
		rule.candidates += candidate
	test_mode.roundstart_pop_ready = 30
	TEST_ASSERT_EQUAL(test_mode.roundstart_pick_cost(rule, 0), rule.cost, "Первый выбор стоит cost")
	TEST_ASSERT_NULL(test_mode.roundstart_pick_cost(rule, 1), "При 30 игроках второго еретика нет, и повтор не тратит бюджет")
	test_mode.roundstart_pop_ready = 60
	TEST_ASSERT_EQUAL(test_mode.roundstart_pick_cost(rule, 1), rule.scaling_cost, "При 60 игроках второй еретик стоит scaling_cost")
	TEST_ASSERT_EQUAL(test_mode.roundstart_pick_cost(rule, 2), rule.scaling_cost, "При 60 игроках третий еретик стоит scaling_cost")
	TEST_ASSERT_NULL(test_mode.roundstart_pick_cost(rule, 3), "Четвёртого еретика на 60 игроков нет")
	var/datum/dynamic_ruleset/roundstart/traitor/traitors = allocate(/datum/dynamic_ruleset/roundstart/traitor)
	traitors.mode = test_mode
	traitors.candidates += allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(test_mode.roundstart_pick_cost(traitors, 1), "Без кандидатов на следующий шаг трейторы не масштабируются")
	var/list/picked = list()
	picked[traitors] = 1
	picked[rule] = 1
	TEST_ASSERT_EQUAL(test_mode.roundstart_pick_cost(rule, 1, picked), rule.scaling_cost, "Пока антагов меньше четверти, повтор масштабируется")
	picked[traitors] = CEILING(test_mode.roundstart_pop_ready * DYNAMIC_SCALE_UP_ANTAG_FRACTION / traitors.get_antag_cap(test_mode.roundstart_pop_ready), 1)
	TEST_ASSERT_NULL(test_mode.roundstart_pick_cost(rule, 1, picked), "Когда антагов уже четверть, scale_up роль не добавит, и повтор не тратит бюджет")

/// 10814: жетон дал четвёртого еретика. Жетон держит тот же лимит, админ видит предупреждение.
/datum/unit_test/heretic_limit_token_and_admin
	var/datum/game_mode/saved_mode
	var/saved_game_state

/datum/unit_test/heretic_limit_token_and_admin/New()
	..()
	saved_mode = SSticker.mode
	saved_game_state = SSticker.current_state

/datum/unit_test/heretic_limit_token_and_admin/Destroy()
	SSticker.mode = saved_mode
	SSticker.current_state = saved_game_state
	return ..()

/datum/unit_test/heretic_limit_token_and_admin/Run()
	var/datum/game_mode/dynamic/test_mode = allocate(/datum/game_mode/dynamic)
	SSticker.mode = test_mode
	SSticker.current_state = GAME_STATE_PLAYING
	var/mob/living/admin = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(warn_admin_about_heretic_count(admin), "Без еретиков предупреждения нет")
	var/datum/antagonist/heretic/existing = allocate_heretic()
	var/warning = warn_admin_about_heretic_count(admin)
	TEST_ASSERT(findtext(warning, "уже 1"), "Админ видит число живых еретиков: [warning]")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	user.mind_initialize()
	allocated += user.mind
	user.job = "Scientist"
	var/obj/item/coin/antagtoken/metashop/heretic/token = allocate(/obj/item/coin/antagtoken/metashop/heretic, user)
	TEST_ASSERT(!token.try_activate(user), "Сверх лимита жетон не выдаёт роль")
	TEST_ASSERT(!QDELETED(token), "Отказ сохраняет жетон для возврата")
	TEST_ASSERT_NULL(IS_HERETIC(user), "Роль не выдана")
	var/refusal = token.activation_extra_block_reason(user)
	var/regex/digits = regex(@"[0-9]")
	TEST_ASSERT(refusal && !digits.Find(refusal), "Отказ не раскрывает чисел: [refusal]")
	TEST_ASSERT(!findtext(refusal, "еретик"), "Отказ не называет причину: [refusal]")

	existing.owner.current.stat = DEAD
	TEST_ASSERT(token.try_activate(user), "Когда место свободно, жетон выдаёт роль")
	var/datum/antagonist/heretic/granted = IS_HERETIC(user)
	TEST_ASSERT_NOTNULL(granted, "Роль выдана жетоном")
	TEST_ASSERT(granted.granted_by_token, "Роль помечена как купленная жетоном")
	TEST_ASSERT(granted.role_exit_data()["token_role"], "Кодекс знает, что отказ не вернёт М$")
