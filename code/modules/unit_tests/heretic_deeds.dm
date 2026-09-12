/datum/unit_test/proc/allocate_deed_heretic(path_id = PATH_ASH)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	heretic.research_knowledge(path.knowledge[1], heretic.owner.current)
	return heretic

/// Выбор пути создаёт дело, а до выбора прогресс отвергается.
/datum/unit_test/heretic_deed_creation/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	TEST_ASSERT(!heretic.advance_deed("none", null, silent = TRUE), "Без пути дело не продвигается.")
	TEST_ASSERT_NULL(heretic.deed_data(), "Кодекс не показывает дело до выбора пути.")
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(ispath(path.deed_type, /datum/heretic_deed), "У пути [path_id] должно быть дело.")
	heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, heretic.owner.current)
	TEST_ASSERT(istype(heretic.deed, /datum/heretic_deed/ash), "Выбор пути создаёт дело этого пути.")
	TEST_ASSERT_EQUAL(heretic.deed.tier, 0, "Дело начинается с нулевой ступени.")
	var/list/data = heretic.deed_data()
	TEST_ASSERT_EQUAL(data["goal"], 2, "Первая ступень требует два действия.")
	TEST_ASSERT_EQUAL(data["max_tier"], HERETIC_DEED_TIERS, "Кодекс передаёт число ступеней.")

/// Ступени дела платят очками знаний, побочные очки идут со второй ступени.
/datum/unit_test/heretic_deed_rewards/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic()
	var/datum/heretic_deed/deed = heretic.deed
	var/points_before = heretic.knowledge_points
	var/side_before = heretic.side_knowledge_points
	var/index = 0
	for(var/tier_goal in deed.tier_goals)
		for(var/step in 1 to tier_goal)
			index++
			COOLDOWN_RESET(deed, progress_cooldown)
			TEST_ASSERT(heretic.advance_deed("key[index]", null), "Действие [index] засчитывается.")
	TEST_ASSERT_EQUAL(deed.tier, HERETIC_DEED_TIERS, "Все ступени пройдены.")
	TEST_ASSERT(deed.complete(), "Завершённое дело помечено выполненным.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, points_before + HERETIC_DEED_TIERS * HERETIC_DEED_KNOWLEDGE, "Каждая ступень даёт очко знаний.")
	TEST_ASSERT_EQUAL(heretic.side_knowledge_points, side_before + (HERETIC_DEED_TIERS - HERETIC_DEED_SIDE_TIER + 1) * HERETIC_DEED_SIDE_KNOWLEDGE, "Побочные очки начисляются со второй ступени.")
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(!heretic.advance_deed("extra", null, silent = TRUE), "После последней ступени дело не принимает действий.")
	TEST_ASSERT_EQUAL(heretic.deed_data()["goal"], 0, "Завершённое дело не показывает цели.")

/// Один ключ засчитывается один раз, а между действиями держится пауза.
/datum/unit_test/heretic_deed_dedup_and_cooldown/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic()
	var/datum/heretic_deed/deed = heretic.deed
	TEST_ASSERT(heretic.advance_deed("area_a", null), "Первое действие засчитано.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Прогресс вырос на единицу.")
	TEST_ASSERT(!heretic.advance_deed("area_b", null, silent = TRUE), "Пауза между действиями не даёт засчитать второе сразу.")
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(!heretic.advance_deed("area_a", null, silent = TRUE), "Повторный ключ не засчитывается.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Отказ не меняет прогресс.")
	TEST_ASSERT(heretic.advance_deed(null, null), "Действие без ключа проходит только по паузе.")
	TEST_ASSERT_EQUAL(deed.tier, 1, "Два действия закрывают первую ступень.")
	TEST_ASSERT_EQUAL(deed.progress, 0, "Прогресс обнуляется на новой ступени.")
	heretic.role_removed = TRUE
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(!heretic.advance_deed("area_c", null, silent = TRUE), "Снятая роль не продвигает дело.")

/// Действие оставляет след на полу и пополняет запас силы пути.
/datum/unit_test/heretic_deed_trace_and_resource/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	knowledge.combat_resource = 0
	var/turf/place = get_turf(user)
	TEST_ASSERT(heretic.advance_deed("area_a", place), "Действие засчитано.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in place
	TEST_ASSERT_NOTNULL(trace, "След появляется на указанной клетке.")
	allocated += trace
	TEST_ASSERT_EQUAL(trace.name, heretic.deed.trace_name, "След носит имя из дела.")
	TEST_ASSERT_EQUAL(trace.icon_state, "sigil_ash", "След использует печать пути.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Действие даёт единицу запаса силы.")
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book, user)
	var/list/data = book.ui_data(user)
	TEST_ASSERT_EQUAL(data["deed"]["progress"], 1, "Кодекс показывает прогресс дела.")
	TEST_ASSERT_EQUAL(data["hunt"]["deed_tiers"], HERETIC_DEED_TIERS, "Кодекс передаёт число ступеней в справку.")

/// Кровь, Луна и Космос не получают чужого ресурса от дела.
/datum/unit_test/heretic_deed_resource_exceptions/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	user.adjustBruteLoss(10)
	TEST_ASSERT(heretic.advance_deed("dna_a", null), "Действие Крови засчитано.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Дело не создаёт кровного долга.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 5, "Дело Крови лечит пять ушибов.")
	var/datum/antagonist/heretic/astronomer = allocate_deed_heretic(PATH_COSMIC)
	var/datum/eldritch_knowledge/base_cosmic/cosmic = astronomer.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	TEST_ASSERT(astronomer.advance_deed("area_a", null), "Действие Космоса засчитано.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 0, "Дело не зажигает звёзд.")

/// Стартовый запас силы позволяет применить способность пути до первого боя.
/datum/unit_test/heretic_starting_resource/Run()
	for(var/path_id in list(PATH_ASH, PATH_RUST, PATH_FLESH, PATH_VOID, PATH_BLADE, PATH_LOCK, PATH_GLASS))
		var/datum/antagonist/heretic/heretic = allocate_deed_heretic(path_id)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/datum/eldritch_knowledge/knowledge = heretic.get_knowledge(path.knowledge[1])
		TEST_ASSERT(knowledge.combat_resource >= 2, "Путь [path_id] начинает хотя бы с двумя единицами запаса.")
