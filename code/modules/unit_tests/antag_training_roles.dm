/proc/antag_training_mode_snapshot()
	var/list/sizes = list(
		"traitors" = length(SSticker.mode.traitors),
		"wizards" = length(SSticker.mode.wizards),
		"apprentices" = length(SSticker.mode.apprentices),
		"bloodsuckers" = length(SSticker.mode.bloodsuckers),
		"vassals" = length(SSticker.mode.vassals),
		"devils" = length(SSticker.mode.devils),
		"all_devils" = length(GLOB.allDevils),
		"changeling_ids" = length(GLOB.possible_changeling_IDs),
		"gang_phones" = length(GLOB.gangster_cell_phones),
		"purchase_logs" = LAZYLEN(GLOB.uplink_purchase_logs_by_key),
	)
	var/list/entries = list()
	for(var/key in sizes)
		entries += "[key]=[sizes[key]]"
	return jointext(entries, ", ")

/// Аплинки и бомбы законно живут, пока жива роль: сверяются после снятия.
/proc/antag_training_world_snapshot()
	return "uplinks=[length(GLOB.uplinks)], nukes=[length(GLOB.nuke_list)]"

/// Каждая программа роли выдаёт учебный датум, не трогая команды, списки режима, угрозу и напоминания раунда, и чисто снимается.
/datum/unit_test/antag_training_roles_isolated/Run()
	TEST_ASSERT(length(subtypesof(/datum/antag_training_program/antag)), "Есть программы ролей.")
	TEST_ASSERT(length(subtypesof(/datum/antag_training_program/creature)), "Есть программы существ.")
	var/datum/antagonist/hk47/hunter_probe = allocate(/datum/antagonist/hk47)
	hunter_probe.discarded_before_gain = TRUE
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program/antag) + subtypesof(/datum/antag_training_program/creature))
		if(!antag_training_program_selectable(program_type))
			continue
		var/initial_teams = length(GLOB.antagonist_teams)
		var/initial_unlisted = length(GLOB.antag_training_unlisted_antagonists)
		var/mode_lists = antag_training_mode_snapshot()
		var/world_lists = antag_training_world_snapshot()
		var/datum/antag_training_session/session = allocate_training_session(program_type)
		TEST_ASSERT(session.prepare(), "[program_type]: полигон готов.")
		var/datum/antagonist/role
		if(istype(session.program, /datum/antag_training_program/creature))
			var/datum/antag_training_program/creature/creature_program = session.program
			role = creature_program.role(session)
			TEST_ASSERT(role && role.vars["training"] == session, "[program_type]: учебный датум привязан к сеансу через attach_training().")
			TEST_ASSERT(istype(session.current_body, creature_program.mob_type) && session.current_body.mind == session.avatar_mind, "[program_type]: разум участника в мобе роли.")
			TEST_ASSERT_EQUAL(session.current_body.training_origin?.resolve(), session.arena, "[program_type]: моб роли принадлежит полигону.")
			// Локал кадра живёт до конца Run(): иначе последняя программа ветки держится минутами и уходит в харддел.
			creature_program = null
		else
			var/datum/antag_training_program/antag/program = session.program
			role = program.role(session)
			program = null
		TEST_ASSERT_NOTNULL(role, "[program_type]: роль выдана.")
		TEST_ASSERT(role.soft_antag && !role.show_in_roundend && !role.show_in_antagpanel && !role.show_in_check_antagonists && !role.show_to_ghosts, "[program_type]: роль скрыта от раунда.")
		TEST_ASSERT(!role.prevent_roundtype_conversion && !role.replace_banned, "[program_type]: роль не держит режим и не зовёт замену.")
		TEST_ASSERT_EQUAL(role.threat(), 0, "[program_type]: роль не даёт угрозы.")
		TEST_ASSERT(!(role in GLOB.antagonists_to_remind), "[program_type]: без напоминаний раунда.")
		for(var/datum/antagonist/held as anything in session.avatar_mind.antag_datums)
			TEST_ASSERT(!(held in GLOB.antagonists), "[program_type]: [held.type] не виден обходам GLOB.antagonists.")
		var/list/round_minds = get_antag_minds(/datum/antagonist)
		TEST_ASSERT(!length(round_minds & (session.arena.target_minds + session.avatar_mind)), "[program_type]: get_antag_minds() не видит участника и учебные цели.")
		TEST_ASSERT(!hunter_probe.in_contract_zone(session.current_body), "[program_type]: участник вне зоны контрактов HK-47 раунда.")
		TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), initial_teams, "[program_type]: команды раунда не меняются.")
		TEST_ASSERT_EQUAL(antag_training_mode_snapshot(), mode_lists, "[program_type]: списки режима не меняются.")
		for(var/datum/objective/objective as anything in role.objectives)
			if(objective.target)
				TEST_ASSERT(objective.target in session.arena.target_minds, "[program_type]: цель [objective.type] - учебная.")
		var/list/console_programs = list()
		for(var/list/program_entry as anything in session.ui_static_data(session.current_body)["programs"])
			console_programs += program_entry["id"]
		TEST_ASSERT(("[program_type]" in console_programs) && !("[/datum/antag_training_program/antag]" in console_programs) && !("[/datum/antag_training_program/creature]" in console_programs), "[program_type]: пульт показывает программу, но не заготовки.")
		qdel(session)
		allocated -= session
		TEST_ASSERT(wait_for_qdeleted(role, 1 MINUTES), "[program_type]: роль снимается с сессией.")
		TEST_ASSERT_EQUAL(length(GLOB.antag_training_unlisted_antagonists), initial_unlisted, "[program_type]: после выхода снятых с GLOB.antagonists датумов не остаётся.")
		TEST_ASSERT_EQUAL(antag_training_mode_snapshot(), mode_lists, "[program_type]: после выхода списки режима прежние.")
		TEST_ASSERT_EQUAL(antag_training_world_snapshot(), world_lists, "[program_type]: после выхода аплинков и бомб роли не осталось.")

/// Каталог входа показывает программы ролей, но не их заготовку, и не запускает её.
/datum/unit_test/antag_training_roles_catalog/Run()
	var/mob/dead/observer/viewer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/obj/effect/antag_training_catalog_probe/entry = allocate(/obj/effect/antag_training_catalog_probe, run_loc_floor_bottom_left)
	var/datum/antag_training_catalog/catalog = new(viewer, entry)
	allocated += catalog
	var/list/catalog_programs = list()
	for(var/list/program_entry as anything in catalog.ui_static_data(viewer)["programs"])
		catalog_programs += program_entry["id"]
	TEST_ASSERT(!("[/datum/antag_training_program/antag]" in catalog_programs), "Заготовки программ ролей нет в каталоге.")
	TEST_ASSERT("[/datum/antag_training_program/antag/traitor]" in catalog_programs, "Предатель есть в каталоге.")
	TEST_ASSERT_NULL(start_antag_training(viewer, /datum/antag_training_program/antag, FALSE), "Вход не запускает заготовку.")
	var/datum/tgui/ui = allocate(/datum/tgui, viewer, catalog, "AntagTrainingCatalog")
	catalog.ui_act("start", list("program" = "[/datum/antag_training_program/antag]", "use_character" = FALSE), ui)
	TEST_ASSERT_NULL(entry.started, "Каталог не запускает заготовку.")

/// Приветствие учебной роли без клиента ждёт входа игрока, приходит один раз и снимается вместе с ролью.
/datum/unit_test/antag_training_greet_on_login/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	allocated += body.mind
	var/datum/antagonist/role = body.mind.add_antag_datum(/datum/antagonist/ghost_role/antag_training)
	var/list/greetings = list()
	antag_training_greet_on_login(role, CALLBACK(src, PROC_REF(count_greeting), greetings))
	TEST_ASSERT_EQUAL(length(greetings), 0, "Без клиента приветствие ждёт входа.")
	SEND_SIGNAL(body, COMSIG_MOB_CLIENT_LOGIN, null)
	TEST_ASSERT_EQUAL(length(greetings), 1, "Вход в тело показывает приветствие.")
	SEND_SIGNAL(body, COMSIG_MOB_CLIENT_LOGIN, null)
	TEST_ASSERT_EQUAL(length(greetings), 1, "Повторный вход приветствие не повторяет.")
	antag_training_greet_on_login(role, CALLBACK(src, PROC_REF(count_greeting), greetings))
	body.mind.remove_antag_datum(/datum/antagonist/ghost_role/antag_training)
	SEND_SIGNAL(body, COMSIG_MOB_CLIENT_LOGIN, null)
	TEST_ASSERT_EQUAL(length(greetings), 1, "Снятая роль приветствие не показывает.")

/datum/unit_test/antag_training_greet_on_login/proc/count_greeting(list/greetings)
	greetings += TRUE
