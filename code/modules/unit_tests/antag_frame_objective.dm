#define ANTAG_FRAME_TEST_TRIES 100

/datum/unit_test/proc/antag_frame_traitor_classes()
	return list(
		/datum/traitor_class/human,
		/datum/traitor_class/human/subterfuge,
		/datum/traitor_class/human/subterfuge/assassin,
	)

/// Сводит задания к одному исходу: "kill" важнее "frame", без заданий - "fail".
/datum/unit_test/proc/antag_frame_outcome(list/objectives)
	. = length(objectives) ? "other" : "fail"
	for(var/datum/objective/objective as anything in objectives)
		if(objective.target)
			TEST_ASSERT(objective.opt_in_valid(objective.target), "[objective.type] выбрало несогласную цель")
		if(istype(objective, /datum/objective/assassinate) || istype(objective, /datum/objective/destroy))
			return "kill"
		if(istype(objective, /datum/objective/frame))
			. = "frame"

/datum/unit_test/proc/antag_frame_forge_traitor(class_type, datum/mind/owner, seed)
	var/datum/antagonist/traitor/traitor = new
	traitor.owner = owner
	var/datum/traitor_class/human/traitor_class = GLOB.traitor_classes[class_type]
	rand_seed(seed)
	if(traitor_class.forge_single_objective(traitor))
		. = antag_frame_outcome(traitor.objectives)
	else
		. = "fail"
	QDEL_LIST(traitor.objectives)
	qdel(traitor)

/datum/unit_test/proc/antag_frame_forge_changeling(datum/mind/owner, seed)
	var/datum/antagonist/changeling/ling = new
	ling.owner = owner
	rand_seed(seed)
	ling.forge_objectives()
	. = antag_frame_outcome(ling.objectives)
	QDEL_LIST(ling.objectives)
	qdel(ling)

/// При целях только уровня "Цель без убийства" предатель и генокрад в Medium и Hard получают подставу, но не убийство.
/datum/unit_test/antag_frame_level_one_targets/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	var/datum/mind/owner = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/list/crew = list()
	for(var/crew_number in 1 to 3)
		crew += antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	world_state.set_crew(crew)

	for(var/round_type in list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD))
		GLOB.round_type = round_type
		for(var/class_type in antag_frame_traitor_classes())
			var/frames = 0
			for(var/seed in 1 to ANTAG_FRAME_TEST_TRIES)
				var/outcome = antag_frame_forge_traitor(class_type, owner, seed)
				TEST_ASSERT(outcome != "kill", "[round_type], [class_type]: убийство без согласной цели")
				frames += outcome == "frame"
			TEST_ASSERT(frames, "[round_type], [class_type]: подставы нет ни в одном из [ANTAG_FRAME_TEST_TRIES] заданий")

		var/ling_frames = 0
		for(var/seed in 1 to ANTAG_FRAME_TEST_TRIES)
			var/outcome = antag_frame_forge_changeling(owner, seed)
			TEST_ASSERT(outcome != "kill", "[round_type], генокрад: убийство без согласной цели")
			ling_frames += outcome == "frame"
		TEST_ASSERT(ling_frames, "[round_type], генокрад: подставы нет ни в одном из [ANTAG_FRAME_TEST_TRIES] наборов")

/// Одному предателю выпадает не больше одной подставы.
/datum/unit_test/antag_frame_one_per_traitor/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	var/datum/mind/owner = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/list/crew = list()
	for(var/crew_number in 1 to 3)
		crew += antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY)
	world_state.set_crew(crew)
	var/datum/antagonist/traitor/traitor = new
	allocated += traitor
	traitor.owner = owner
	rand_seed(ANTAG_FRAME_TEST_TRIES)
	for(var/class_type in antag_frame_traitor_classes())
		var/datum/traitor_class/human/traitor_class = GLOB.traitor_classes[class_type]
		for(var/objective_number in 1 to ANTAG_FRAME_TEST_TRIES)
			traitor_class.forge_single_objective(traitor)
		var/frames = 0
		for(var/datum/objective/frame/frame in traitor.objectives)
			frames++
		TEST_ASSERT_EQUAL(frames, 1, "[class_type]: подстав у одного предателя")
		QDEL_LIST(traitor.objectives)

/// Подстава не меняет долю убийств: при том же зерне убийство и провал выпадают одинаково, есть кого подставить или нет.
/datum/unit_test/antag_frame_kill_share/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	var/datum/game_mode/dynamic/mode = SSticker.mode
	mode.threat_level = 0
	var/datum/mind/owner = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/list/framable_crew = list()
	var/list/security_crew = list()
	for(var/crew_number in 1 to 3)
		framable_crew += antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
		security_crew += antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE, "Security Officer")

	for(var/class_type in antag_frame_traitor_classes())
		var/list/with_frame = list()
		world_state.set_crew(framable_crew)
		for(var/seed in 1 to ANTAG_FRAME_TEST_TRIES)
			with_frame += antag_frame_forge_traitor(class_type, owner, seed)
		world_state.set_crew(security_crew)
		for(var/seed in 1 to ANTAG_FRAME_TEST_TRIES)
			var/without_frame = antag_frame_forge_traitor(class_type, owner, seed)
			var/expected = with_frame[seed] == "frame" ? "other" : with_frame[seed]
			TEST_ASSERT_EQUAL(without_frame, expected, "[class_type], зерно [seed]")
		var/kills = 0
		for(var/outcome in with_frame)
			kills += outcome == "kill"
		TEST_ASSERT(kills > 0 && kills < ANTAG_FRAME_TEST_TRIES, "[class_type]: убийств [kills] из [ANTAG_FRAME_TEST_TRIES], сравнивать нечего")
		TEST_ASSERT("frame" in with_frame, "[class_type]: подстава не выпала, сравнивать нечего")

	var/list/ling_with_frame = list()
	world_state.set_crew(framable_crew)
	for(var/seed in 1 to ANTAG_FRAME_TEST_TRIES)
		ling_with_frame += antag_frame_forge_changeling(owner, seed)
	world_state.set_crew(security_crew)
	for(var/seed in 1 to ANTAG_FRAME_TEST_TRIES)
		var/without_frame = antag_frame_forge_changeling(owner, seed)
		TEST_ASSERT_EQUAL(without_frame == "kill", ling_with_frame[seed] == "kill", "генокрад, зерно [seed]")

#undef ANTAG_FRAME_TEST_TRIES
