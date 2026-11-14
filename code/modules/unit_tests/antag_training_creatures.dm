/datum/unit_test/proc/antag_training_wait_new_body(datum/antag_training_session/session, mob/living/old_body, description)
	var/list/budget = new_wait_budget(10 SECONDS, description)
	while(!session.finished && (session.current_body == old_body || QDELETED(session.current_body)) && wait_budget_tick(budget))
		continue
	return session.current_body != old_body && !QDELETED(session.current_body)

/// Программа-существо переносит разум в моба роли со скрытым учебным датумом, пересоздаёт его после удаления и смерти, а выход в призрака закрывает сеанс как обычно.
/datum/unit_test/antag_training_creature_body/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/morph)
	TEST_ASSERT(session.prepare(), "Полигон готовит морфа.")
	var/datum/antag_training_program/creature/morph/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/simple_animal/hostile/morph/body = session.current_body
	TEST_ASSERT(istype(body), "Тело сеанса - морф.")
	TEST_ASSERT_EQUAL(body.mind, session.avatar_mind, "Разум участника в морфе.")
	TEST_ASSERT_EQUAL(body.training_origin?.resolve(), arena, "Морф принадлежит полигону.")
	TEST_ASSERT_NULL(session.avatar, "Кукла-человек не остаётся на полигоне.")
	TEST_ASSERT(!body.can_have_ai && body.AIStatus == AI_OFF, "Без игрока морф не действует сам.")
	var/datum/antagonist/morph/training/role = program.role(session)
	TEST_ASSERT(istype(role) && role.training == session, "Морф получает учебный датум сеанса.")
	TEST_ASSERT(role.soft_antag && !role.show_in_roundend && !role.show_in_antagpanel && !role.show_in_check_antagonists && !role.show_to_ghosts && !role.ui_name, "Учебный морф скрыт от раунда.")
	TEST_ASSERT_EQUAL(role.threat(), 0, "Учебный морф не даёт угрозы.")
	var/list/console_programs = list()
	for(var/list/program_entry as anything in session.ui_static_data(body)["programs"])
		console_programs += program_entry["id"]
	TEST_ASSERT(!("[/datum/antag_training_program/creature]" in console_programs), "Заготовки программ существ нет в пульте.")
	TEST_ASSERT(!session.restart(/datum/antag_training_program/creature), "Смена программы не принимает заготовку.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	observer.real_name = "Creature Observer"
	TEST_ASSERT(session.connect(observer), "Призрак входит в морфа.")
	TEST_ASSERT_EQUAL(body.real_name, initial(body.real_name), "Вход не переименовывает морфа именем призрака.")
	TEST_ASSERT(locate(/datum/action/antag_training_controls) in body.actions, "У морфа есть пульт полигона.")

	qdel(body)
	TEST_ASSERT(!session.finished, "Удаление морфа не завершает сеанс.")
	var/mob/living/simple_animal/hostile/morph/rebuilt = session.current_body
	TEST_ASSERT(istype(rebuilt) && !QDELETED(rebuilt), "Вместо удалённого появляется новый морф.")
	TEST_ASSERT_EQUAL(rebuilt.mind, session.avatar_mind, "Новый морф получает тот же разум.")
	TEST_ASSERT_EQUAL(program.role(session), role, "Учебный датум переходит в новое тело.")
	TEST_ASSERT_EQUAL(get_turf(rebuilt), arena.entry_turf, "Новый морф появляется в центре.")
	TEST_ASSERT(locate(/datum/action/antag_training_controls) in rebuilt.actions, "Пульт переходит в новое тело.")

	rebuilt.forceMove(arena.zones["melee"]["spawn"])
	rebuilt.adjustHealth(rebuilt.maxHealth / 2)
	rebuilt.death()
	TEST_ASSERT_EQUAL(session.defeats, 1, "Смерть морфа учитывается в счётчике.")
	TEST_ASSERT(antag_training_wait_new_body(session, rebuilt, "морф после смерти"), "После смерти появляется новый морф.")
	var/mob/living/simple_animal/hostile/morph/revived = session.current_body
	TEST_ASSERT(QDELETED(rebuilt), "Труп прежнего морфа убран.")
	TEST_ASSERT(istype(revived) && revived.stat == CONSCIOUS && revived.mind == session.avatar_mind, "Новый морф жив и с разумом участника.")
	TEST_ASSERT(abs(revived.health - revived.maxHealth) < 0.1, "Новый морф с полным здоровьем.")
	TEST_ASSERT_EQUAL(get_turf(revived), arena.entry_turf, "Морф после смерти появляется в центре.")

	revived.ghostize(TRUE, voluntary = TRUE)
	TEST_ASSERT(wait_for_qdeleted(session, 5 SECONDS), "Выход в призрака завершает сеанс.")
	var/mob/dead/observer/returned
	for(var/mob/dead/observer/ghost in run_loc_floor_bottom_left)
		if(ghost != observer && ghost.real_name == observer.real_name)
			returned = ghost
	allocated += returned
	TEST_ASSERT_NOTNULL(returned, "Игрок возвращается прежним призраком.")

/// Морф копирует выданный предмет Shift+кликом, съедает учебный труп атакой, а съеденный манекен остаётся в общем лимите целей.
/// Учебный морф не глотает вещи из набора другого участника.
/datum/unit_test/antag_training_morph_others/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/morph)
	TEST_ASSERT(session.prepare(), "Полигон готовит морфа.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(arena), "Второй участник входит на тот же полигон.")
	var/mob/living/simple_animal/hostile/morph/body = session.current_body
	var/mob/living/carbon/human/stranger = other.current_body
	body.forceMove(arena.zones["melee"]["spawn"])
	var/obj/item/restraints/handcuffs/kit_item = stranger.l_store
	TEST_ASSERT(istype(kit_item) && kit_item.training_kit_owner?.resolve() == other, "Наручники из набора второго участника помечены его сеансом.")
	stranger.transferItemToLoc(kit_item, get_step(body, EAST), TRUE)
	GLOB.unit_test_chat_capture = list()
	INVOKE_ASYNC(body, TYPE_PROC_REF(/mob, ClickOn), kit_item)
	var/list/budget = new_wait_budget(5 SECONDS, "морф пробует съесть чужой предмет")
	while(kit_item.loc != body && !antag_training_chat_heard(body, "другого участника") && wait_budget_tick(budget))
		continue
	var/refused = antag_training_chat_heard(body, "другого участника")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(refused && kit_item.loc != body, "Предмет набора другого участника морф не глотает.")

/datum/unit_test/antag_training_morph/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/morph)
	TEST_ASSERT(session.prepare(), "Полигон готовит морфа.")
	var/datum/antag_training_program/creature/morph/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/simple_animal/hostile/morph/body = session.current_body
	body.forceMove(arena.zones["melee"]["spawn"])
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")

	antag_training_console_act(session, console, "program_option", list("option" = "Предметы для копии"))
	var/list/forms = list()
	for(var/obj/item/thing in range(1, body))
		if(thing.type in program.form_types)
			forms += thing
	TEST_ASSERT_EQUAL(length(forms), length(program.form_types), "Вокруг морфа лежат все предметы для копии.")
	var/obj/item/storage/toolbox/mechanical/toolbox = locate() in forms
	TEST_ASSERT_EQUAL(toolbox?.training_owner?.resolve(), session, "Выданные предметы принадлежат участнику.")
	body.ShiftClickOn(toolbox)
	TEST_ASSERT(body.morphed && body.form == toolbox, "Shift+клик копирует облик предмета.")
	TEST_ASSERT_EQUAL(body.icon_state, toolbox.icon_state, "Морф выглядит как ящик с инструментами.")
	body.ShiftClickOn(body)
	TEST_ASSERT(body.morphed, "Сразу после копии облик не меняется.")
	antag_training_console_act(session, console, "program_option", list("option" = "Полное здоровье и маскировка"))
	TEST_ASSERT_EQUAL(body.morph_time, 0, "Кнопка сбрасывает задержку облика.")
	body.ShiftClickOn(body)
	TEST_ASSERT(!body.morphed, "После сброса морф возвращает свой облик.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для засады"))
	var/mob/living/carbon/human/prey
	for(var/mob/living/carbon/human/candidate in arena.targets)
		if(candidate.training_owner?.resolve() == session)
			prey = candidate
	TEST_ASSERT_NOTNULL(prey, "Цель для засады создана и принадлежит участнику.")
	TEST_ASSERT_EQUAL(arena.match_zone(prey), "melee", "Цель для засады встаёт в секторе морфа.")
	QDEL_NULL(prey.mind)
	qdel(prey)

	antag_training_console_act(session, console, "spawn", list("id" = "corpse", "zone" = "melee"))
	var/mob/living/carbon/human/corpse
	for(var/mob/living/carbon/human/candidate in arena.targets)
		if(candidate.stat == DEAD)
			corpse = candidate
	TEST_ASSERT_NOTNULL(corpse, "Учебный труп создан.")
	corpse.forceMove(get_step(body, EAST))
	var/health_cap = body.maxHealth
	var/targets_before = length(arena.targets)
	INVOKE_ASYNC(body, TYPE_PROC_REF(/mob, ClickOn), corpse)
	var/list/budget = new_wait_budget(10 SECONDS, "морф съедает труп")
	while(corpse.loc != body && wait_budget_tick(budget))
		continue
	TEST_ASSERT_EQUAL(corpse.loc, body, "Атака по трупу съедает его.")
	TEST_ASSERT(body.maxHealth > health_cap, "Съеденный труп прибавляет здоровья.")
	TEST_ASSERT(corpse in arena.targets, "Съеденный манекен остаётся учебной целью.")
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before, "Съеденный манекен не освобождает лимит.")

	var/turf/spot = arena.zones["melee"]["target"]
	while(arena.has_target_room())
		TEST_ASSERT(arena.claim_target(new /obj/item/pen(spot), session), "Свободное место в лимите принимает цель.")
	TEST_ASSERT_EQUAL(length(arena.targets), ANTAG_TRAINING_TARGET_LIMIT, "Лимит заполнен вместе со съеденным манекеном.")
	var/obj/item/pen/extra = new(spot)
	TEST_ASSERT(!arena.claim_target(extra, session), "Сверх лимита цель не принимается.")
	TEST_ASSERT(!(extra in arena.targets), "Отклонённая цель не учтена.")
	qdel(extra)
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для засады"))
	TEST_ASSERT_EQUAL(length(arena.targets), ANTAG_TRAINING_TARGET_LIMIT, "Цель для засады сверх лимита не создаётся.")
	var/list/data = session.ui_data(body)
	TEST_ASSERT_EQUAL(length(data["targets"]), ANTAG_TRAINING_TARGET_LIMIT, "Пульт показывает все цели, включая предметы.")
	var/obj/item/pen/claimed = locate() in spot
	TEST_ASSERT_EQUAL(claimed?.training_owner?.resolve(), session, "Учтённая цель помечена сеансом.")
	qdel(claimed)
	TEST_ASSERT(!(claimed in arena.targets) && arena.has_target_room(), "Удаление снимает цель с учёта сразу.")
	// visible_message поедания оставил труп в кэше последнего view(), который в тихом мире держит его после очистки.
	pass(view(0, run_loc_floor_bottom_left))

/// Тело роли, которое гибнет сразу после появления, пересоздаётся ограниченное число раз, затем сеанс завершается прежним путём.
/datum/unit_test/antag_training_creature_rapid_loss/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/morph)
	TEST_ASSERT(session.prepare(), "Полигон готовит морфа.")
	var/rebuilt = 0
	for(var/attempt in 1 to 10)
		var/mob/living/simple_animal/hostile/morph/body = session.current_body
		body.del_on_death = TRUE
		body.death()
		if(session.finished || session.current_body == body)
			break
		rebuilt++
	TEST_ASSERT_EQUAL(rebuilt, ANTAG_TRAINING_CREATURE_RAPID_LIMIT, "Быстрые потери пересоздают тело ровно до предела.")
	TEST_ASSERT(wait_for_qdeleted(session, 5 SECONDS), "После серии быстрых потерь сеанс завершается.")
