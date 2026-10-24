/// На время теста подменяет экипаж, разумы, игроков, заключённых и режим раунда своими.
/datum/antag_opt_in_test_world
	var/list/saved_locked
	var/list/saved_minds
	var/list/saved_players
	var/list/saved_prisoners
	var/list/saved_joined
	var/list/saved_possible_items
	var/saved_round_type
	var/saved_command_min
	var/datum/game_mode/saved_mode
	var/list/datum/data/record/records = list()

/datum/antag_opt_in_test_world/New()
	saved_locked = GLOB.data_core.locked
	saved_minds = SSticker.minds
	saved_players = GLOB.player_list
	saved_prisoners = GLOB.roundstart_prisoners
	saved_joined = GLOB.joined_player_list
	saved_possible_items = GLOB.possible_items
	saved_round_type = GLOB.round_type
	saved_command_min = CONFIG_GET(number/antag_opt_in_command_min)
	saved_mode = SSticker.mode
	GLOB.data_core.locked = list()
	SSticker.minds = list()
	GLOB.player_list = list()
	GLOB.roundstart_prisoners = list()
	GLOB.possible_items = list(new /datum/objective_item/antag_opt_in_test)

/datum/antag_opt_in_test_world/Destroy()
	GLOB.data_core.locked = saved_locked
	SSticker.minds = saved_minds
	GLOB.player_list = saved_players
	GLOB.roundstart_prisoners = saved_prisoners
	GLOB.joined_player_list = saved_joined
	GLOB.possible_items = saved_possible_items
	GLOB.round_type = saved_round_type
	CONFIG_SET(number/antag_opt_in_command_min, saved_command_min)
	SSticker.mode = saved_mode
	QDEL_LIST(records)
	return ..()

/datum/antag_opt_in_test_world/proc/set_crew(list/datum/mind/crew)
	QDEL_LIST(records)
	GLOB.data_core.locked.Cut()
	SSticker.minds.Cut()
	GLOB.player_list.Cut()
	for(var/datum/mind/crew_mind as anything in crew)
		var/datum/data/record/record = new
		record.fields["mindref"] = crew_mind
		records += record
		GLOB.data_core.locked += record
		SSticker.minds += crew_mind
		GLOB.player_list += crew_mind.current

/// Хард-динамик на 24 игрока: генераторы доходят до заданий на убийство.
/datum/antag_opt_in_test_world/proc/set_hard_round(datum/unit_test/test)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_HARD
	GLOB.joined_player_list = list()
	for(var/player_number in 1 to 24)
		GLOB.joined_player_list += "antag_opt_in_test_[player_number]"
	var/datum/game_mode/dynamic/mode = new
	test.allocated += mode
	mode.threat_level = 120
	SSticker.mode = mode

/datum/objective_item/antag_opt_in_test
	name = "a test item"
	targetitem = /obj/item/bikehorn

/// Портрет жертвы культа строится из префов клиента, которого у тестового тела нет.
/mob/living/carbon/human/antag_opt_in_test/get_sac_image()
	return null

/datum/unit_test/proc/antag_opt_in_crew(level, role = "Assistant", body_type = /mob/living/carbon/human)
	var/mob/living/carbon/human/body = allocate(body_type, run_loc_floor_bottom_left)
	body.mind_initialize()
	body.mind.assigned_role = role
	body.mind.antag_opt_in_level = level
	return body.mind

/datum/unit_test/proc/antag_opt_in_objective(objective_type, datum/mind/owner)
	var/datum/objective/objective = new objective_type
	allocated += objective
	objective.owner = owner
	return objective

/datum/unit_test/proc/antag_opt_in_check_objectives(list/objectives, label)
	TEST_ASSERT(length(objectives), "[label]: генератор не выдал ни одного задания")
	for(var/datum/objective/objective as anything in objectives)
		TEST_ASSERT(!istype(objective, /datum/objective/assassinate), "[label]: выдано [objective.type] без согласной цели")
		if(istype(objective, /datum/objective/protect) || istype(objective, /datum/objective/maroon) || istype(objective, /datum/objective/escape/escape_with_identity) || istype(objective, /datum/objective/kidnap) || istype(objective, /datum/objective/frame) || istype(objective, /datum/objective/breakout) || istype(objective, /datum/objective/rescue_prisoner))
			TEST_ASSERT_NOTNULL(objective.target, "[label]: [objective.type] осталось без цели")
			TEST_ASSERT(objective.opt_in_valid(objective.target), "[label]: [objective.type] выбрало несогласную цель")

/// Итоговый уровень - максимум из настройки, порога работы и порога антаг-настроек на спавне.
/datum/unit_test/antag_opt_in_effective_level/Run()
	var/datum/mind/officer = allocate_mind()
	officer.assigned_role = "Security Officer"
	officer.antag_opt_in_level = ANTAG_OPT_IN_NOT_TARGET
	TEST_ASSERT_EQUAL(officer.get_effective_antag_opt_in_level(), ANTAG_OPT_IN_KILL, "СБ на своей работе не ниже \"Цель убийства\"")
	var/datum/mind/captain = allocate_mind()
	captain.assigned_role = "Captain"
	captain.antag_opt_in_level = ANTAG_OPT_IN_NOT_TARGET
	TEST_ASSERT_EQUAL(captain.get_effective_antag_opt_in_level(), ANTAG_OPT_IN_KILL, "Командование на своей работе не ниже \"Цель убийства\"")
	var/datum/mind/assistant = allocate_mind()
	assistant.assigned_role = "Assistant"
	assistant.antag_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	TEST_ASSERT_EQUAL(assistant.get_effective_antag_opt_in_level(), ANTAG_OPT_IN_TEMPORARY, "Ассистент без антаг-ролей получает свою настройку")
	var/datum/mind/unset = allocate_mind()
	unset.assigned_role = "Assistant"
	TEST_ASSERT_EQUAL(unset.get_effective_antag_opt_in_level(), CONFIG_GET(number/antag_opt_in_default_level), "Без настройки берётся значение из конфига")

	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.antag_opt_in_level = ANTAG_OPT_IN_NOT_TARGET
	prefs.toggles &= ~NO_ANTAG
	prefs.be_special = list(ROLE_TRAITOR = ANTAG_PRIORITY_HIGH)
	var/datum/mind/traitor_fan = allocate_mind()
	traitor_fan.assigned_role = "Assistant"
	traitor_fan.apply_antag_opt_in_prefs(prefs)
	TEST_ASSERT_EQUAL(traitor_fan.antag_opt_in_level, ANTAG_OPT_IN_NOT_TARGET, "Настройка персонажа переносится в разум")
	TEST_ASSERT_EQUAL(traitor_fan.get_effective_antag_opt_in_level(), ANTAG_OPT_IN_KILL, "Включённый предатель поднимает уровень до \"Цель убийства\"")
	prefs.be_special = list()
	TEST_ASSERT_EQUAL(traitor_fan.get_effective_antag_opt_in_level(), ANTAG_OPT_IN_KILL, "Порог антаг-настроек фиксируется на спавне")

	prefs.be_special = list(ROLE_ALIEN = ANTAG_PRIORITY_HIGH)
	var/datum/mind/ghost_fan = allocate_mind()
	ghost_fan.assigned_role = "Assistant"
	ghost_fan.apply_antag_opt_in_prefs(prefs)
	TEST_ASSERT_EQUAL(ghost_fan.get_effective_antag_opt_in_level(), ANTAG_OPT_IN_NOT_TARGET, "Роль только для призраков порог не поднимает")

	prefs.be_special = list(ROLE_TRAITOR = ANTAG_PRIORITY_HIGH)
	prefs.toggles |= NO_ANTAG
	var/datum/mind/no_antag = allocate_mind()
	no_antag.assigned_role = "Assistant"
	no_antag.apply_antag_opt_in_prefs(prefs)
	TEST_ASSERT_EQUAL(no_antag.get_effective_antag_opt_in_level(), ANTAG_OPT_IN_NOT_TARGET, "Выключенные антаги порог не поднимают")

/// Игрок, зашедший в тело мимо лобби (гост-роль, ОБР), приносит в новый разум свою настройку согласия.
/datum/unit_test/antag_opt_in_fresh_mind
	var/probe_ckey = "unittestoptinfreshmind"

/datum/unit_test/antag_opt_in_fresh_mind/Destroy()
	GLOB.preferences_datums -= probe_ckey
	return ..()

/datum/unit_test/antag_opt_in_fresh_mind/Run()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.antag_opt_in_level = ANTAG_OPT_IN_NOT_TARGET
	prefs.toggles &= ~NO_ANTAG
	prefs.be_special = list(ROLE_TRAITOR = ANTAG_PRIORITY_HIGH)
	GLOB.preferences_datums[probe_ckey] = prefs
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	body.ckey = probe_ckey
	body.mind_initialize()
	SSticker.minds -= body.mind
	TEST_ASSERT_EQUAL(body.mind.antag_opt_in_level, ANTAG_OPT_IN_NOT_TARGET, "Новый разум не получил уровень из настроек игрока")
	TEST_ASSERT_EQUAL(body.mind.get_effective_antag_opt_in_level(), CONFIG_GET(number/antag_opt_in_antag_enabled_min), "Включённый предатель не поднял порог нового разума")

/// Требуемый уровень каждого задания соответствует тому, что задание делает с целью.
/datum/unit_test/antag_opt_in_objective_levels/Run()
	var/list/expected = list(
		/datum/objective/assassinate = ANTAG_OPT_IN_ROUND_REMOVE,
		/datum/objective/maroon = ANTAG_OPT_IN_ROUND_REMOVE,
		/datum/objective/debrain = ANTAG_OPT_IN_ROUND_REMOVE,
		/datum/objective/sacrifice = ANTAG_OPT_IN_ROUND_REMOVE,
		/datum/objective/bloodsucker = ANTAG_OPT_IN_ROUND_REMOVE,
		/datum/objective/assassinate/once = ANTAG_OPT_IN_KILL,
		/datum/objective/assassinate/internal = ANTAG_OPT_IN_KILL,
		/datum/objective/mutiny = ANTAG_OPT_IN_KILL,
		/datum/objective/destroy = ANTAG_OPT_IN_KILL,
		/datum/objective/contract = ANTAG_OPT_IN_KILL,
		/datum/objective/overthrow/heads = ANTAG_OPT_IN_KILL,
		/datum/objective/overthrow/target = ANTAG_OPT_IN_KILL,
		/datum/objective/escape/escape_with_identity = ANTAG_OPT_IN_TEMPORARY,
		/datum/objective/kidnap = ANTAG_OPT_IN_TEMPORARY,
		/datum/objective/frame = ANTAG_OPT_IN_TEMPORARY,
		/datum/objective/breakout = ANTAG_OPT_IN_TEMPORARY,
		/datum/objective/rescue_prisoner = ANTAG_OPT_IN_TEMPORARY,
		/datum/objective/devil/buy_target = ANTAG_OPT_IN_TEMPORARY,
		/datum/objective/protect = ANTAG_OPT_IN_NOT_TARGET,
		/datum/objective/protect/nonhuman = ANTAG_OPT_IN_NOT_TARGET,
	)
	for(var/datum/objective/objective_type as anything in expected)
		TEST_ASSERT_EQUAL(initial(objective_type.required_opt_in_level), expected[objective_type], "Уровень задания [objective_type]")

/// Общий выбор цели и kidnap пропускают разумы ниже уровня задания.
/datum/unit_test/antag_opt_in_find_target/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	var/datum/mind/owner = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/killable = antag_opt_in_crew(ANTAG_OPT_IN_KILL)
	var/datum/mind/removable = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/temporary = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	var/datum/mind/not_target = antag_opt_in_crew(ANTAG_OPT_IN_NOT_TARGET)

	world_state.set_crew(list(owner, killable))
	var/datum/objective/assassinate/assassinate = antag_opt_in_objective(/datum/objective/assassinate, owner)
	TEST_ASSERT_NULL(assassinate.find_target(), "Уничтожение не выбирает уровень \"Цель убийства\"")
	world_state.set_crew(list(owner, killable, removable))
	TEST_ASSERT_EQUAL(assassinate.find_target(), removable, "Уничтожение выбирает уровень \"Цель любых заданий\"")

	world_state.set_crew(list(owner, not_target))
	var/datum/objective/kidnap/kidnap = antag_opt_in_objective(/datum/objective/kidnap, owner)
	TEST_ASSERT_NULL(kidnap.find_target(), "Похищение не выбирает \"Не цель заданий\"")
	world_state.set_crew(list(owner, not_target, temporary))
	TEST_ASSERT_EQUAL(kidnap.find_target(), temporary, "Похищение выбирает \"Цель без убийства\"")

	world_state.set_crew(list(owner, not_target))
	var/datum/objective/protect/protect = antag_opt_in_objective(/datum/objective/protect, owner)
	TEST_ASSERT_EQUAL(protect.find_target(), not_target, "Защита годится для любого уровня")

/// Каждый тип с общим выбором цели держит свой порог: ниже не выбирает, ровно на нём выбирает.
/datum/unit_test/antag_opt_in_find_target_levels/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	var/datum/mind/owner = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/list/objective_types = list(
		/datum/objective/assassinate,
		/datum/objective/assassinate/once,
		/datum/objective/assassinate/internal,
		/datum/objective/maroon,
		/datum/objective/debrain,
		/datum/objective/mutiny,
		/datum/objective/contract,
		/datum/objective/overthrow/target,
		/datum/objective/escape/escape_with_identity,
		/datum/objective/devil/buy_target,
	)
	for(var/datum/objective/objective_type as anything in objective_types)
		var/level = initial(objective_type.required_opt_in_level)
		var/datum/mind/below = antag_opt_in_crew(level - 1)
		var/datum/mind/enough = antag_opt_in_crew(level)
		var/datum/objective/objective = antag_opt_in_objective(objective_type, owner)
		world_state.set_crew(list(owner, below))
		objective.find_target()
		TEST_ASSERT_NULL(objective.target, "[objective_type] выбрало цель ниже своего уровня")
		world_state.set_crew(list(owner, below, enough))
		objective.find_target()
		TEST_ASSERT_EQUAL(objective.target, enough, "[objective_type] не выбрало цель своего уровня")

/// Выборки цели в обход find_target тоже учитывают согласие.
/datum/unit_test/antag_opt_in_bypass_selection/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	var/datum/mind/owner = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/not_target = antag_opt_in_crew(ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/temporary = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	var/datum/mind/killable = antag_opt_in_crew(ANTAG_OPT_IN_KILL)
	var/datum/mind/removable = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)

	world_state.set_crew(list(owner, killable))
	var/datum/objective/maroon/maroon = antag_opt_in_objective(/datum/objective/maroon, owner)
	TEST_ASSERT_NULL(maroon.find_target_by_role("Assistant"), "Выбор по роли не берёт \"Цель убийства\" для оставления")
	world_state.set_crew(list(owner, killable, removable))
	TEST_ASSERT_EQUAL(maroon.find_target_by_role("Assistant"), removable, "Выбор по роли берёт согласную цель")

	var/datum/mind/killer = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/antagonist/killer_datum = new
	allocated += killer_datum
	killer_datum.owner = killer
	var/datum/objective/assassinate/once/kill_objective = antag_opt_in_objective(/datum/objective/assassinate/once, killer)
	killer_datum.objectives += kill_objective
	kill_objective.target = temporary
	var/datum/objective/protect/protect = antag_opt_in_objective(/datum/objective/protect, owner)
	TEST_ASSERT_NULL(protect.find_kill_target(), "Защита не строится вокруг несогласной цели убийства")
	kill_objective.target = killable
	TEST_ASSERT_EQUAL(protect.find_kill_target(), killable, "Защита строится вокруг согласной цели убийства")
	killer_datum.objectives -= kill_objective

	var/datum/mind/prisoner_out = antag_opt_in_crew(ANTAG_OPT_IN_NOT_TARGET, "Prisoner")
	var/datum/mind/prisoner_in = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY, "Prisoner")
	world_state.set_crew(list(owner, prisoner_out))
	var/datum/objective/breakout/breakout = antag_opt_in_objective(/datum/objective/breakout, owner)
	TEST_ASSERT_NULL(breakout.find_target(), "Побег не выбирает \"Не цель заданий\"")
	world_state.set_crew(list(owner, prisoner_out, prisoner_in))
	TEST_ASSERT_EQUAL(breakout.find_target(), prisoner_in, "Побег выбирает согласного заключённого")

	GLOB.roundstart_prisoners = list(WEAKREF(prisoner_out.current))
	var/datum/objective/rescue_prisoner/rescue = antag_opt_in_objective(/datum/objective/rescue_prisoner, owner)
	TEST_ASSERT(!rescue.find_target(), "Спасение не выбирает \"Не цель заданий\"")
	TEST_ASSERT(!QDELETED(rescue), "Неудачный выбор цели не удаляет задание из-под генератора")
	GLOB.roundstart_prisoners += WEAKREF(prisoner_in.current)
	TEST_ASSERT_EQUAL(rescue.find_target(), prisoner_in, "Спасение выбирает согласного заключённого")
	TEST_ASSERT(findtext(rescue.explanation_text, prisoner_in.name), "Текст спасения называет цель")

	world_state.set_crew(list(owner, not_target))
	var/datum/objective/frame/frame = antag_opt_in_objective(/datum/objective/frame, owner)
	TEST_ASSERT_NULL(frame.find_target(), "Подстава не выбирает \"Не цель заданий\"")
	world_state.set_crew(list(owner, not_target, temporary))
	TEST_ASSERT_EQUAL(frame.find_target(), temporary, "Подстава выбирает \"Цель без убийства\"")

	world_state.set_crew(list(owner, killable))
	var/datum/objective/bloodsucker/lair/bloodsucker = antag_opt_in_objective(/datum/objective/bloodsucker/lair, owner)
	var/list/blood_targets = bloodsucker.return_possible_targets()
	TEST_ASSERT(!(killable in blood_targets), "Кровосос не выбирает цель ниже своего уровня")
	world_state.set_crew(list(owner, killable, removable))
	blood_targets = bloodsucker.return_possible_targets()
	TEST_ASSERT(removable in blood_targets, "Кровосос выбирает согласную цель")

	CONFIG_SET(number/antag_opt_in_command_min, ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/shy_captain = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY, "Captain")
	var/datum/mind/bold_captain = antag_opt_in_crew(ANTAG_OPT_IN_KILL, "Captain")
	world_state.set_crew(list(owner, shy_captain, bold_captain))
	var/datum/objective/overthrow/heads/heads = antag_opt_in_objective(/datum/objective/overthrow/heads, owner)
	heads.find_targets()
	TEST_ASSERT(!(shy_captain in heads.targets), "Переворот не берёт главу ниже своего уровня")
	TEST_ASSERT(bold_captain in heads.targets, "Переворот берёт согласного главу")

/// Жертва культа выбирается только из согласных на вывод из раунда.
/datum/unit_test/antag_opt_in_cult_sacrifice/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	var/datum/mind/killable = antag_opt_in_crew(ANTAG_OPT_IN_KILL, body_type = /mob/living/carbon/human/antag_opt_in_test)
	var/datum/mind/removable = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE, body_type = /mob/living/carbon/human/antag_opt_in_test)
	var/datum/team/cult/cult = new
	allocated += cult
	world_state.set_crew(list(killable))
	cult.sort_sacrifice()
	var/datum/objective/sacrifice/sacrifice = locate() in GLOB.objectives
	allocated += sacrifice
	TEST_ASSERT_NOTNULL(sacrifice, "Культ создал задание жертвы")
	TEST_ASSERT_NULL(sacrifice.target, "Жертва не выбирается из несогласных")
	TEST_ASSERT(sacrifice.sacced, "Без согласных культ переходит к следующей цели")
	allocated -= sacrifice
	qdel(sacrifice)
	world_state.set_crew(list(killable, removable))
	cult.sort_sacrifice()
	sacrifice = locate() in GLOB.objectives
	allocated += sacrifice
	TEST_ASSERT_EQUAL(sacrifice?.target, removable, "Жертва выбирается из согласных")

/// Охота не назначает "Не цель заданий", "Цель без убийства" принимает только живой; согласие на труп фиксируется при назначении.
/datum/unit_test/antag_opt_in_heretic_hunt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	var/datum/mind/not_target = antag_opt_in_crew(ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/temporary = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	var/datum/mind/killable = antag_opt_in_crew(ANTAG_OPT_IN_KILL)
	var/refusal = heretic.hunt_target_unavailable_reason(not_target, selecting = TRUE)
	TEST_ASSERT(findtext(refusal, "не согласен"), "Отказ по согласию назван прямо: [refusal]")
	var/temporary_reason = heretic.hunt_target_unavailable_reason(temporary, selecting = TRUE)
	TEST_ASSERT(!findtext(temporary_reason, "не согласен"), "\"Цель без убийства\" подходит для охоты живьём: [temporary_reason]")
	TEST_ASSERT_NULL(heretic.hunt_target_unavailable_reason(not_target), "Уже назначенная цель не снимается после смены настройки")

	heretic.set_hunt_target(temporary)
	TEST_ASSERT_NULL(heretic.hunt_target_unavailable_reason(temporary), "Живая \"Цель без убийства\" годится для обряда")
	temporary.current.death()
	TEST_ASSERT(findtext(heretic.hunt_target_unavailable_reason(temporary), "только живой"), "Труп \"Цели без убийства\" не принимается")

	heretic.set_hunt_target(killable)
	killable.antag_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	killable.current.death()
	TEST_ASSERT_NULL(heretic.hunt_target_unavailable_reason(killable), "Смена настройки после назначения не отбирает труп согласной на убийство цели")

/// Без согласных целей генераторы выдают задания без цели, а не пустые.
/datum/unit_test/antag_opt_in_generators/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	var/datum/mind/temporary = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	var/datum/mind/traitor_mind = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/ling_mind = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/brother_mind = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/malf_mind = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(list(temporary))

	var/datum/antagonist/traitor/traitor = new
	allocated += traitor
	traitor.owner = traitor_mind
	var/datum/traitor_class/human/human_class = GLOB.traitor_classes[/datum/traitor_class/human]
	TEST_ASSERT(!human_class.try_forge_assassinate_objective(traitor, SSticker.mode), "Убийство без согласной цели не выдаётся")
	TEST_ASSERT(!length(traitor.objectives), "Неудачное убийство не оставляет задание")
	for(var/objective_number in 1 to 3)
		var/forged = FALSE
		for(var/attempt in 1 to 100)
			forged = human_class.forge_single_objective(traitor)
			if(forged)
				break
		TEST_ASSERT(forged, "Генератор предателя нашёл задание без цели")
	antag_opt_in_check_objectives(traitor.objectives, "Предатель")

	var/datum/antagonist/changeling/ling = new
	allocated += ling
	ling.owner = ling_mind
	ling.forge_objectives()
	antag_opt_in_check_objectives(ling.objectives, "Генокрад")

	var/datum/antagonist/traitor/malf = new
	allocated += malf
	malf.owner = malf_mind
	var/datum/traitor_class/ai/ai_class = GLOB.traitor_classes[/datum/traitor_class/ai]
	ai_class.forge_objectives(malf)
	for(var/objective_number in 1 to 6)
		ai_class.forge_single_objective(malf)
	antag_opt_in_check_objectives(malf.objectives, "Малф")

	var/datum/team/brother_team/brothers = new
	allocated += brothers
	brothers.add_member(brother_mind)
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	for(var/oath_type in GLOB.blood_oath_types)
		var/datum/blood_oath/oath = allocate(oath_type)
		oath.prepare(brothers)
		if(!oath.target_mind)
			continue
		TEST_ASSERT(antag_opt_in_allows(oath.target_mind, oath.target_opt_in_level), "Братья: [oath_type] выбрала несогласную цель")
		TEST_ASSERT(!(oath.target_mind in brothers.members), "Братья: [oath_type] выбрала брата")

/// Уровень согласия переживает сохранение персонажа, мусор в сейве сбрасывается к значению по умолчанию.
/datum/unit_test/antag_opt_in_pref_saving
	var/datum/preferences/prefs

/datum/unit_test/antag_opt_in_pref_saving/Destroy()
	if(prefs)
		delete_save_files()
		qdel(prefs)
		prefs = null
	return ..()

/// Вместе с .sav удаляются и файлы JSON-хранилища, если оно есть в сборке.
/datum/unit_test/antag_opt_in_pref_saving/proc/delete_save_files()
	for(var/suffix in list("", ".json", ".json.recovery", ".json.import", ".json.d/"))
		fdel("[prefs.path][suffix]")

/datum/unit_test/antag_opt_in_pref_saving/Run()
	prefs = new
	prefs.load_path("unit_test_antag_opt_in")
	delete_save_files()
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "Корень настроек записан")
	prefs.antag_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "Персонаж записан")
	sleep(1)
	prefs.antag_opt_in_level = null
	TEST_ASSERT(prefs.load_character(null, TRUE), "Персонаж прочитан")
	TEST_ASSERT_EQUAL(prefs.antag_opt_in_level, ANTAG_OPT_IN_TEMPORARY, "Уровень согласия пережил сохранение")

	prefs.antag_opt_in_level = 7
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "Персонаж с мусором записан")
	sleep(1)
	TEST_ASSERT(prefs.load_character(null, TRUE), "Персонаж с мусором прочитан")
	TEST_ASSERT_NULL(prefs.antag_opt_in_level, "Мусорный уровень сброшен к значению по умолчанию")

	prefs.antag_objective_style = ANTAG_OBJECTIVE_STYLE_QUIET
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "Корень настроек со стилем заданий записан")
	sleep(1)
	prefs.antag_objective_style = ANTAG_OBJECTIVE_STYLE_NORMAL
	TEST_ASSERT(prefs.load_preferences(TRUE), "Корень настроек прочитан")
	TEST_ASSERT_EQUAL(prefs.antag_objective_style, ANTAG_OBJECTIVE_STYLE_QUIET, "Стиль заданий пережил сохранение")
	prefs.antag_objective_style = "garbage"
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "Корень настроек с мусорным стилем записан")
	sleep(1)
	TEST_ASSERT(prefs.load_preferences(TRUE), "Корень настроек с мусорным стилем прочитан")
	TEST_ASSERT_EQUAL(prefs.antag_objective_style, ANTAG_OBJECTIVE_STYLE_NORMAL, "Мусорный стиль сброшен к обычному")

/// Повторный выбор того же уровня в меню взаимодействий ничего не делает: ни лога, ни сохранения.
/datum/unit_test/antag_opt_in_menu_same_level/Run()
	var/datum/mind/crew_mind = antag_opt_in_crew(ANTAG_OPT_IN_KILL)
	var/set_level = /datum/component/interaction_menu_granter/proc/set_antag_opt_in_level
	TEST_ASSERT(call(set_level)(crew_mind.current, ANTAG_OPT_IN_NOT_TARGET), "Новый уровень из меню не применился")
	TEST_ASSERT_EQUAL(crew_mind.antag_opt_in_level, ANTAG_OPT_IN_NOT_TARGET, "Меню не записало уровень в разум")
	TEST_ASSERT(!call(set_level)(crew_mind.current, ANTAG_OPT_IN_NOT_TARGET), "Повторный выбор того же уровня снова записался")

/// Значок согласия показывает итоговый уровень и переезжает с разумом; еретик видит значки, пока остаётся еретиком.
/datum/unit_test/antag_opt_in_hud/Run()
	var/datum/mind/crew_mind = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	var/mob/living/carbon/human/old_body = crew_mind.current
	var/image/old_holder = old_body.hud_list[ANTAG_OPT_IN_HUD]
	var/set_level = /datum/component/interaction_menu_granter/proc/set_antag_opt_in_level
	call(set_level)(old_body, ANTAG_OPT_IN_KILL)
	TEST_ASSERT_EQUAL(old_holder.icon_state, "opt_in_[ANTAG_OPT_IN_KILL]", "Значок не сменился вместе с уровнем из меню")
	crew_mind.assigned_role = "Security Officer"
	call(set_level)(old_body, ANTAG_OPT_IN_NOT_TARGET)
	TEST_ASSERT_EQUAL(old_holder.icon_state, "opt_in_[ANTAG_OPT_IN_KILL]", "Значок СБ не учитывает порог работы")

	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	crew_mind.transfer_to(new_body)
	TEST_ASSERT(!old_holder.icon_state, "Тело без разума сохранило значок")
	var/image/new_holder = new_body.hud_list[ANTAG_OPT_IN_HUD]
	TEST_ASSERT_EQUAL(new_holder.icon_state, "opt_in_[ANTAG_OPT_IN_KILL]", "Значок не переехал в новое тело")

	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/heretic_body = heretic.owner.current
	var/datum/atom_hud/opt_in_hud = GLOB.huds[DATA_HUD_ANTAG_OPT_IN]
	heretic.apply_innate_effects(heretic_body)
	TEST_ASSERT(opt_in_hud.hudusers[heretic_body], "Еретик не видит значки согласия")
	heretic.remove_innate_effects(heretic_body)
	TEST_ASSERT(!opt_in_hud.hudusers[heretic_body], "Значки согласия остались у бывшего еретика")

/// Стиль "Без убийств" убирает убийства у предателя и генокрада, "Больше убийств" поднимает шанс в Харде и немного в Медиуме.
/datum/unit_test/antag_objective_style
	var/datum/preferences/style_prefs
	var/saved_medium_chaos

/datum/unit_test/antag_objective_style/Destroy()
	GLOB.preferences_datums -= "unittestobjectivestyle"
	QDEL_NULL(style_prefs)
	if(!isnull(saved_medium_chaos))
		CONFIG_SET(number/chaos_for_a_medium_dynamic, saved_medium_chaos)
	return ..()

/datum/unit_test/antag_objective_style/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	var/datum/game_mode/dynamic/mode = SSticker.mode
	mode.threat_level = 40
	var/datum/mind/victim = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(list(victim))
	var/datum/mind/antag_mind = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	antag_mind.key = "UnitTestObjectiveStyle"
	style_prefs = new
	GLOB.preferences_datums["unittestobjectivestyle"] = style_prefs
	var/datum/antagonist/traitor/traitor = new
	allocated += traitor
	traitor.owner = antag_mind
	var/datum/traitor_class/human/human_class = GLOB.traitor_classes[/datum/traitor_class/human]

	var/normal_prob = human_class.get_effective_assassin_prob(mode, antag_mind)
	TEST_ASSERT(normal_prob > 0 && normal_prob < 100, "В Харде без стиля шанс убийства должен быть между 0 и 100, а он [normal_prob]")
	style_prefs.antag_objective_style = ANTAG_OBJECTIVE_STYLE_VIOLENT
	TEST_ASSERT_EQUAL(human_class.get_effective_assassin_prob(mode, antag_mind), min(100, normal_prob * ANTAG_OBJECTIVE_VIOLENT_KILL_MULT), "\"Больше убийств\" не поднял шанс в Харде")
	GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
	saved_medium_chaos = CONFIG_GET(number/chaos_for_a_medium_dynamic)
	CONFIG_SET(number/chaos_for_a_medium_dynamic, 0)
	style_prefs.antag_objective_style = ANTAG_OBJECTIVE_STYLE_NORMAL
	var/medium_prob = human_class.get_effective_assassin_prob(mode, antag_mind)
	TEST_ASSERT(medium_prob > 0, "В Медиуме с хаосом выше порога у предателя нет шанса убийства")
	style_prefs.antag_objective_style = ANTAG_OBJECTIVE_STYLE_VIOLENT
	TEST_ASSERT_EQUAL(human_class.get_effective_assassin_prob(mode, antag_mind), medium_prob + ANTAG_OBJECTIVE_VIOLENT_SOFT_BONUS, "\"Больше убийств\" в Медиуме поднял шанс не на мягкую надбавку")
	GLOB.round_type = ROUNDTYPE_DYNAMIC_HARD

	style_prefs.antag_objective_style = ANTAG_OBJECTIVE_STYLE_QUIET
	TEST_ASSERT_EQUAL(human_class.get_effective_assassin_prob(mode, antag_mind), 0, "\"Без убийств\" оставил предателю шанс убийства")
	var/datum/antagonist/changeling/ling = new
	allocated += ling
	ling.owner = antag_mind
	ling.forge_objectives()
	for(var/datum/objective/objective as anything in ling.objectives)
		TEST_ASSERT(!istype(objective, /datum/objective/assassinate) && !istype(objective, /datum/objective/destroy), "Генокрад \"Без убийств\" получил [objective.type]")
	TEST_ASSERT(locate(/datum/objective/steal) in ling.objectives, "Генокрад \"Без убийств\" остался без кражи вместо убийства")

/// Сводка согласия для логов считает итоговые уровни, свой выбор и подъём порогом работы.
/datum/unit_test/antag_opt_in_distribution_log/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	var/datum/mind/shy = antag_opt_in_crew(ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/temporary = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	var/datum/mind/default_level = antag_opt_in_crew(null)
	var/datum/mind/officer = antag_opt_in_crew(ANTAG_OPT_IN_NOT_TARGET, "Security Officer")
	world_state.set_crew(list(shy, temporary, default_level, officer))
	var/expected = "экипаж 4; \"[antag_opt_in_level_name(ANTAG_OPT_IN_NOT_TARGET)]\" 1, \"[antag_opt_in_level_name(ANTAG_OPT_IN_TEMPORARY)]\" 1, \"[antag_opt_in_level_name(ANTAG_OPT_IN_KILL)]\" 1, \"[antag_opt_in_level_name(ANTAG_OPT_IN_ROUND_REMOVE)]\" 1; выбрали сами 3, подняты порогом 1"
	TEST_ASSERT_EQUAL(antag_opt_in_distribution_text(), expected, "Сводка согласия посчитана неверно")
