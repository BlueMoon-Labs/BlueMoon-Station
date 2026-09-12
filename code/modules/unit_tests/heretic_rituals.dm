/// Клинок Пустоты требует холодного воздуха или своего действующего поля до конца обряда.
/datum/unit_test/heretic_void_blade_recipe
	var/turf/open/floor/ritual_floor
	var/original_temperature

/datum/unit_test/heretic_void_blade_recipe/Destroy()
	if(ritual_floor && !isnull(original_temperature))
		ritual_floor.air.set_temperature(original_temperature)
	return ..()

/datum/unit_test/heretic_void_blade_recipe/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	var/datum/eldritch_knowledge/base_void/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	ritual_floor = get_turf(user)
	original_temperature = ritual_floor.GetTemperature()
	ritual_floor.air.set_temperature(T0C + 20)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, ritual_floor)
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, ritual_floor)
	TEST_ASSERT(!rune.do_ritual(user, recipe), "Тёплый воздух без поля не подходит.")
	TEST_ASSERT(!QDELETED(knife), "Отказ сохраняет нож.")
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "20 °C"), "Отказ показывает температуру на руне.")
	recipe.ritual_time = 0
	ritual_floor.air.set_temperature(T0C)
	TEST_ASSERT(recipe.recipe_snowflake_check(list(), ritual_floor, list(), user), "Нулевая температура подходит без поля.")
	ritual_floor.air.set_temperature(T0C - 270)
	TEST_ASSERT(rune.do_ritual(user, recipe), "После охлаждения воздуха та же руна должна изготовить клинок без перерисовки.")
	TEST_ASSERT(QDELETED(knife), "Крафт после охлаждения расходует исходный нож.")
	var/obj/item/melee/sickly_blade/void/cold_blade = locate() in ritual_floor
	TEST_ASSERT_NOTNULL(cold_blade, "На старой руне появился клинок.")
	qdel(cold_blade)
	knife = allocate(/obj/item/kitchen/knife/combat, ritual_floor)
	ritual_floor.air.set_temperature(T0C + 20)
	TEST_ASSERT(!rune.do_ritual(user, recipe), "После нагрева та же руна вновь отклоняет крафт без поля.")
	TEST_ASSERT(!QDELETED(knife), "Нагрев не расходует следующий нож.")
	var/obj/effect/heretic_combat_zone/void/winter = allocate(/obj/effect/heretic_combat_zone/void, ritual_floor, heretic.owner)
	STOP_PROCESSING(SSprocessing, winter)
	winter.refresh_boundary(list(ritual_floor))
	recipe.combat_zone = winter
	var/datum/antagonist/heretic/other = allocate_heretic()
	TEST_ASSERT(!recipe.recipe_snowflake_check(list(), ritual_floor, list(), other.owner.current), "Чужое поле не заменяет холод.")
	winter.refresh_boundary(list())
	TEST_ASSERT(!recipe.recipe_snowflake_check(list(), ritual_floor, list(), user), "Клетка за границей поля не подходит.")
	winter.refresh_boundary(list(ritual_floor))
	TEST_ASSERT(rune.reserve_atoms(list(knife)), "Нож резервируется для проверки канала.")
	rune.ritual_user = user
	TEST_ASSERT(rune.ritual_valid(user, recipe), "Своё поле разрешает обряд в тёплом воздухе.")
	qdel(winter)
	TEST_ASSERT(!rune.ritual_valid(user, recipe), "Исчезновение поля прерывает обряд.")
	rune.release_atoms()
	winter = allocate(/obj/effect/heretic_combat_zone/void, ritual_floor, heretic.owner)
	STOP_PROCESSING(SSprocessing, winter)
	winter.refresh_boundary(list(ritual_floor))
	recipe.combat_zone = winter
	recipe.ritual_time = 0
	TEST_ASSERT(rune.do_ritual(user, recipe), "Своё поле позволяет изготовить клинок.")
	var/obj/item/melee/sickly_blade/void/blade = locate() in ritual_floor
	TEST_ASSERT_NOTNULL(blade, "Обряд создаёт клинок Пустоты.")
	allocated += blade
	TEST_ASSERT(QDELETED(knife), "Успешный обряд расходует нож.")
	for(var/knife_type in list(/obj/item/kitchen/knife/butcher, /obj/item/kitchen/knife/shiv))
		var/obj/item/kitchen/knife/variant = allocate(knife_type, ritual_floor)
		var/list/selected = list()
		TEST_ASSERT(rune.select_recipe_atoms(recipe, list(variant), selected, list(), user), "Рецепт должен принимать [knife_type].")
		TEST_ASSERT(variant in selected, "Подходящий вариант выбран компонентом.")

/// Рецепт брони открывается со второй ступени и расходует готовый стол рядом с руной и выложенный противогаз.
/datum/unit_test/heretic_armor_recipe/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.knowledge_points = 10
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user), "Первый обет должен изучаться.")
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/armor, user), "До второй ступени броня закрыта.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/ashen_grasp, user), "Вторая ступень должна изучаться.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/armor, user), "Со второй ступени доступна броня.")
	var/turf/center = get_step(run_loc_floor_bottom_left, NORTHEAST)
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(user.put_in_hands(book), "Для рисования нужно держать книгу.")
	var/obj/structure/table/table = allocate(/obj/structure/table, get_step(center, NORTH))
	TEST_ASSERT(book.can_draw_rune(center, user), "Готовый стол в области 3×3 не мешает рисованию.")
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, center)
	var/obj/item/clothing/mask/gas/mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(user.put_in_hands(mask), "Противогаз должен помещаться во вторую руку.")
	var/datum/eldritch_knowledge/armor/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/armor)
	recipe.ritual_time = 0
	TEST_ASSERT(!rune.do_ritual(user, recipe), "Предмет в руке не считается компонентом.")
	TEST_ASSERT(!QDELETED(table), "Неудачный обряд сохраняет стол.")
	user.dropItemToGround(mask)
	mask.forceMove(center)
	TEST_ASSERT(rune.do_ritual(user, recipe), "Стол рядом с центром и выложенный противогаз должны создать броню.")
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robe = locate() in center
	TEST_ASSERT_NOTNULL(robe, "На руне должна появиться мантия.")
	allocated += robe
	TEST_ASSERT(QDELETED(table) && QDELETED(mask), "Рецепт расходует целый стол и противогаз.")

/// Один предмет не закрывает два требования, а общий тип не отбирает специализированный компонент.
/datum/unit_test/heretic_recipe_matching/Run()
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, run_loc_floor_bottom_left)
	var/obj/item/pen/pen = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	var/list/usage = list()
	TEST_ASSERT(!rune.match_recipe_requirements(list(/obj/item/kitchen/knife, /obj/item/kitchen/knife), 1, list(knife), usage), "Один нож не должен заменять два ножа.")
	TEST_ASSERT_EQUAL(length(usage), 0, "Неудачный подбор не должен оставлять расход компонентов.")
	TEST_ASSERT(rune.match_recipe_requirements(list(/obj/item, /obj/item/kitchen/knife), 1, list(knife, pen), usage), "Общее требование должно использовать ручку и оставить нож для второго требования.")
	TEST_ASSERT_EQUAL(usage[knife], 1, "Нож расходуется ровно один раз.")
	TEST_ASSERT_EQUAL(usage[pen], 1, "Ручка закрывает общее требование предмета.")

/datum/unit_test/heretic_recipe_stack_units/Run()
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/obj/item/stack/sheet/metal/metal = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 5)
	var/list/usage = list()
	TEST_ASSERT(rune.match_recipe_requirements(list(/obj/item/stack/sheet/metal, /obj/item/stack/sheet/metal), 1, list(metal), usage), "Два листа можно получить из одной стопки.")
	TEST_ASSERT_EQUAL(usage[metal], 2, "Рецепт требует два листа, а не всю стопку.")
	TEST_ASSERT_EQUAL(metal.amount, 5, "Подбор компонентов ничего не расходует.")
	usage.Cut()
	TEST_ASSERT(!rune.match_recipe_requirements(list(/obj/item/stack/sheet/metal, /obj/item/stack/sheet/metal, /obj/item/stack/sheet/metal, /obj/item/stack/sheet/metal, /obj/item/stack/sheet/metal, /obj/item/stack/sheet/metal), 1, list(metal), usage), "Пяти листов недостаточно для шести требований.")
	TEST_ASSERT_EQUAL(metal.amount, 5, "Неудачный подбор сохраняет стопку.")

/datum/unit_test/heretic_ritual_stack_commit/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/obj/item/stack/sheet/metal/metal = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 5)
	var/datum/eldritch_knowledge/recipe = allocate(/datum/eldritch_knowledge)
	recipe.required_atoms = list(/obj/item/stack/sheet/metal, /obj/item/stack/sheet/metal)
	recipe.ritual_time = 0
	heretic.researched_knowledge[recipe.type] = recipe
	TEST_ASSERT(!rune.do_ritual(user, recipe), "Обряд без результата должен завершиться неудачей.")
	TEST_ASSERT_EQUAL(metal.amount, 5, "Неуспешный callback сохраняет все листы.")
	recipe.result_atoms = list(/obj/item/pen)
	TEST_ASSERT(rune.do_ritual(user, recipe), "Полный обряд с доступными листами должен завершиться.")
	TEST_ASSERT(!QDELETED(metal), "Частичный расход не удаляет всю стопку.")
	TEST_ASSERT_EQUAL(metal.amount, 3, "Успешный обряд расходует ровно два листа.")
	TEST_ASSERT_NULL(GLOB.heretic_ritual_reservations[metal], "Успешный обряд освобождает оставшуюся стопку.")
	var/obj/item/pen/result = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(result, "Обряд должен создать результат.")
	allocated += result

/datum/unit_test/heretic_ritual_reservation/Run()
	var/obj/effect/eldritch/first_rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/obj/effect/eldritch/second_rune = allocate(/obj/effect/eldritch/big, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/pen/ingredient = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	TEST_ASSERT(first_rune.reserve_atoms(list(ingredient)), "Первая руна должна занять свободный компонент.")
	TEST_ASSERT(!second_rune.reserve_atoms(list(ingredient)), "Вторая руна не должна повторно использовать занятый компонент.")
	ingredient.forceMove(get_step(run_loc_floor_bottom_left, NORTH))
	ingredient.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(first_rune.ritual_interrupted, "Перенос компонента туда и обратно должен прерывать обряд.")
	first_rune.release_atoms()
	TEST_ASSERT_NULL(GLOB.heretic_ritual_reservations[ingredient], "Отмена обряда освобождает компонент.")
	TEST_ASSERT(second_rune.reserve_atoms(list(ingredient)), "После отмены компонент доступен другой руне.")
	qdel(second_rune)
	TEST_ASSERT_NULL(GLOB.heretic_ritual_reservations[ingredient], "Удаление руны должно освобождать компоненты.")

/datum/unit_test/heretic_final_body_selection/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/list/friendly_fixture = make_blade_fixture()
	var/mob/living/friendly_body = friendly_fixture["user"]
	friendly_body.death()
	var/list/atoms = list(friendly_body)
	var/list/expected = list()
	for(var/index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.death()
		atoms += body
		expected += body
	var/mob/living/carbon/human/extra_body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	extra_body.death()
	atoms += extra_body
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	finale.required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	var/list/selected = list()
	TEST_ASSERT(rune.select_recipe_atoms(finale, atoms, selected, list(), user), "Три допустимых трупа позволяют подготовить финальный обряд.")
	TEST_ASSERT_EQUAL(length(selected), HERETIC_ASCENSION_BODIES, "Обряд выбирает ровно три тела.")
	TEST_ASSERT(!(friendly_body in selected), "Тело еретика первым в списке не должно попасть в компоненты.")
	TEST_ASSERT(!(extra_body in selected), "Четвёртый допустимый труп не должен расходоваться.")
	TEST_ASSERT_EQUAL(length(selected & expected), HERETIC_ASCENSION_BODIES, "Matcher сохраняет тройку, выбранную проверкой вознесения.")

/datum/unit_test/heretic_influence_personal_limit/Run()
	var/list/first_fixture = make_blade_fixture()
	var/mob/living/first_user = first_fixture["user"]
	var/datum/antagonist/heretic/first_heretic = first_fixture["heretic"]
	var/obj/item/forbidden_book/first_book = allocate(/obj/item/forbidden_book, first_user)
	var/list/second_fixture = make_blade_fixture()
	var/mob/living/second_user = second_fixture["user"]
	var/obj/item/forbidden_book/second_book = allocate(/obj/item/forbidden_book, second_user)
	var/obj/effect/reality_smash/influence = allocate(/obj/effect/reality_smash, run_loc_floor_bottom_left)
	TEST_ASSERT(influence.can_harvest(first_user, first_book), "Неисследованный разлом доступен еретику с кодексом.")
	influence.harvested_minds |= first_user.mind
	TEST_ASSERT(!influence.can_harvest(first_user, first_book), "Тот же еретик не исследует разлом повторно.")
	TEST_ASSERT(influence.can_harvest(second_user, second_book), "Другой еретик сохраняет собственное исследование разлома.")
	influence.harvested_minds.Cut()
	first_heretic.influences_harvested = HERETIC_INFLUENCE_LIMIT
	TEST_ASSERT(!influence.can_harvest(first_user, first_book), "Лимит шести знаний действует и на новый разлом.")
	TEST_ASSERT(!influence.can_harvest(second_user, first_book), "Чужой кодекс, находящийся у другого персонажа, нельзя использовать удалённо.")

/datum/unit_test/heretic_history_mind_cleanup/Run()
	var/datum/mind/mind = new
	allocated += mind
	var/datum/reality_smash_tracker/tracker = allocate(/datum/reality_smash_tracker)
	var/obj/effect/reality_smash/influence = allocate(/obj/effect/reality_smash, run_loc_floor_bottom_left, tracker)
	tracker.track_history_mind(mind)
	tracker.harvest_counts[mind] = HERETIC_INFLUENCE_LIMIT
	influence.harvested_minds |= mind
	GLOB.heretic_sacrificed_minds |= mind
	tracker.RemoveMind(mind)
	TEST_ASSERT(mind in tracker.history_minds, "Снятие роли сохраняет историю до удаления разума.")
	qdel(mind)
	TEST_ASSERT(!(mind in tracker.history_minds), "Удаление разума освобождает watcher истории.")
	TEST_ASSERT_NULL(tracker.harvest_counts[mind], "История количества разломов не удерживает удалённый разум.")
	TEST_ASSERT(!(mind in influence.harvested_minds), "Разлом освобождает запись об удалённом исследователе.")
	TEST_ASSERT(!(mind in GLOB.heretic_sacrificed_minds), "Список душ освобождает удалённый разум.")

/// Для возвращения используем известную безопасную клетку тестовой станции.
/datum/antagonist/heretic/ritual_fixture
	var/turf/test_return_turf

/datum/antagonist/heretic/ritual_fixture/get_hunt_return_turf()
	return test_return_turf

/datum/unit_test/heretic_hunt_return
	var/datum/space_level/test_level
	var/list/previous_traits
	var/list/previous_sacrificed
	var/capture_with_cuffs = FALSE
	var/sacrifice_corpse = FALSE
	var/dies_during_ritual = FALSE

/// Связанная живая цель проходит полный канал и возвращается из Мансуса.
/datum/unit_test/heretic_hunt_return/restrained
	capture_with_cuffs = TRUE

/// Труп назначенной цели даёт меньшую награду, остаётся на месте и не приносится повторно после реанимации.
/datum/unit_test/heretic_hunt_return/corpse
	sacrifice_corpse = TRUE

/// Смерть во время канала уменьшает награду и не отправляет труп в Мансус.
/datum/unit_test/heretic_hunt_return/dies_during_ritual
	dies_during_ritual = TRUE

/datum/unit_test/heretic_hunt_return/Destroy()
	if(test_level && previous_traits)
		test_level.traits = previous_traits
	if(previous_sacrificed)
		GLOB.heretic_sacrificed_minds = previous_sacrificed
	return ..()

/// Отказ подношения различает отсутствие цели, сопротивление и чужое сердце, не исключая назначенный труп.
/datum/unit_test/heretic_hunt_return/failure_reasons/Run()
	test_level = SSmapping.get_level(run_loc_floor_bottom_left.z)
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	var/datum/eldritch_knowledge/spell/basic/recipe = allocate(/datum/eldritch_knowledge/spell/basic)
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "Выберите новую цель"), "Без назначения нужно выбрать цель.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "на руне или рядом"), "Отдалённую цель нужно доставить к руне.")
	victim.forceMove(get_turf(rune))
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "ещё сопротивляется"), "Свободную цель нужно обезвредить.")
	victim.death()
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, get_turf(rune))
	heart.owner_mind = soul
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "Чужое сердце"), "Для назначенного трупа отказ указывает на чужое сердце.")
	heart.owner_mind = heretic.owner
	TEST_ASSERT(rune.select_recipe_atoms(recipe, rune.collect_ritual_atoms(user), list(), list(), user), "Труп со своим сердцем подходит для подношения.")

/datum/unit_test/heretic_hunt_return/Run()
	test_level = SSmapping.get_level(run_loc_floor_bottom_left.z)
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	previous_sacrificed = GLOB.heretic_sacrificed_minds.Copy()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = new
	allocated += user_mind
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/ritual_fixture/heretic = allocate(/datum/antagonist/heretic/ritual_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.test_return_turf = run_loc_floor_top_right
	var/datum/antagonist/heretic/other_heretic = allocate_heretic()
	heretic.set_hunt_target(other_heretic.owner)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/victim_mind = new
	allocated += victim_mind
	victim_mind.current = victim
	victim.mind = victim_mind
	heretic.set_hunt_target(victim_mind)
	other_heretic.set_hunt_target(victim_mind)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце должно привязаться к еретику.")
	TEST_ASSERT(!heart.bind(victim_mind), "Похищение сердца не передаёт чужую охоту.")
	var/list/selected = list()
	TEST_ASSERT(!heretic.select_hunt_atoms(user, list(victim, heart), selected), "Свободная стоящая цель не принимается.")
	if(capture_with_cuffs)
		victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
		victim.update_handcuffed()
	else
		victim.Unconscious(30 SECONDS)
	victim.adjustBruteLoss(30)
	var/obj/item/pen/belonging = allocate(/obj/item/pen, victim)
	if(sacrifice_corpse)
		victim.death()
		TEST_ASSERT(heretic.hunt_target_available(victim_mind), "Смерть сохраняет уже назначенную цель доступной.")
		TEST_ASSERT(!heretic.hunt_target_available(victim_mind, selecting = TRUE), "Мёртвое тело не назначается новой целью.")
		var/mob/living/carbon/human/unassigned = allocate(/mob/living/carbon/human)
		unassigned.death()
		TEST_ASSERT(!heretic.select_hunt_atoms(user, list(unassigned, heart), list()), "Случайный труп не заменяет назначенную цель.")
		var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book, user)
		var/list/book_data = book.ui_data(user)
		var/list/hunt_data = book_data["hunt"]
		TEST_ASSERT(findtext(hunt_data["target_status"], "Цель погибла."), "Кодекс сообщает о доступном трупе, а не требует новую цель.")
	TEST_ASSERT(heretic.select_hunt_atoms(user, list(victim, heart), selected), "Обезвреженная назначенная цель и своё сердце подходят для обряда.")
	var/points_before = heretic.knowledge_points
	var/side_points_before = heretic.side_knowledge_points
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	TEST_ASSERT(rune.reserve_atoms(selected), "Настоящая руна резервирует сердце и жертву.")
	rune.ritual_user = user
	rune.ritual_interrupted = TRUE
	TEST_ASSERT(!heretic.complete_hunt_ritual(user, selected, run_loc_floor_bottom_left), "Отменённая руна не принимает душу, даже если компоненты остались рядом.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, points_before, "Прерванный обряд не выдаёт знания.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[victim_mind], "Прерванный обряд не оставляет посещение Мансуса.")
	rune.release_atoms()
	var/expect_corpse = sacrifice_corpse || dies_during_ritual
	if(expect_corpse)
		heretic.test_return_turf = null
	if(dies_during_ritual)
		addtimer(CALLBACK(victim, TYPE_PROC_REF(/mob/living, death)), 2 SECONDS)
	TEST_ASSERT(rune.do_ritual(user, heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)), "Полный канал должен принять назначенную душу.")
	var/expected_points = points_before + (expect_corpse ? 1 : 2)
	TEST_ASSERT_EQUAL(heretic.knowledge_points, expected_points, "Живая цель даёт два знания, труп — одно.")
	TEST_ASSERT_EQUAL(heretic.side_knowledge_points, side_points_before + (expect_corpse ? 0 : 1), "Побочное знание выдаётся только за живую цель.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Счётчик жертв увеличивается один раз.")
	TEST_ASSERT_NULL(heretic.sac_targetted[REF(victim_mind)], "Принесённая душа удалена из невыполненных назначений.")
	TEST_ASSERT_EQUAL(length(heretic.sac_targetted), 1, "Предыдущая непринесённая цель остаётся в истории.")
	TEST_ASSERT_NULL(other_heretic.hunt_target, "Общая душа освобождает охоту другого еретика.")
	TEST_ASSERT(other_heretic.sac_targetted[REF(victim_mind)], "Чужое жертвоприношение не стирает собственное невыполненное назначение.")
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[victim_mind]
	if(expect_corpse)
		TEST_ASSERT_NULL(visit, "Принятие трупа не создаёт посещения Мансуса.")
		TEST_ASSERT(!QDELETED(victim) && victim.stat == DEAD, "Обряд сохраняет труп для реанимации.")
		TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_bottom_left, "Тело остаётся на месте обряда.")
		TEST_ASSERT_EQUAL(victim.getBruteLoss(), 30, "Принятие трупа не лечит его повреждения.")
	else
		TEST_ASSERT_NOTNULL(visit, "Обряд отправляет жертву в отдельное посещение Мансуса.")
		allocated += visit
		TEST_ASSERT(visit.contains(victim), "До возвращения жертва находится в комнате Мансуса.")
		visit.finish()
		TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Жертва возвращается в безопасную точку.")
		TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Возвращённая жертва получает медицинское восстановление.")
		TEST_ASSERT(victim.stat != DEAD, "Обряд возвращает жертву живой.")
	TEST_ASSERT_EQUAL(belonging.loc, victim, "Обряд сохраняет имущество в теле жертвы.")
	TEST_ASSERT(!victim.IsParalyzed(), "Удержание руны не остаётся после обряда.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/grouped/stasis), "Стазис руны не остаётся после обряда.")
	if(expect_corpse)
		victim.revive(full_heal = TRUE)
	heretic.set_hunt_target(victim_mind)
	TEST_ASSERT(!heretic.hunt_target_available(victim_mind), "Принесённую душу нельзя выбрать повторно.")
	TEST_ASSERT(!heretic.complete_hunt_ritual(user, selected, run_loc_floor_top_right), "Повторный ритуал не выдаёт знаний.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, expected_points, "Повтор души не увеличивает знания.")

/// Неудачные заклинания возвращают заряд, а удалённый домен освобождает ссылку владельца.
/datum/unit_test/heretic_spell_failure_refunds/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	for(var/spell_type in list(/obj/effect/proc_holder/spell/pointed/blood_siphon, /obj/effect/proc_holder/spell/pointed/cleave, /obj/effect/proc_holder/spell/pointed/void_blink, /obj/effect/proc_holder/spell/pointed/boogie_woogie))
		var/obj/effect/proc_holder/spell/spell = allocate(spell_type)
		spell.charge_counter = 0
		spell.cast(list(), user)
		TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "[spell.type]: пустая цель возвращает заряд.")
	var/obj/effect/proc_holder/spell/aoe_turf/domain_expansion/domain_spell = allocate(/obj/effect/proc_holder/spell/aoe_turf/domain_expansion)
	domain_spell.cast(list(), user)
	TEST_ASSERT_NOTNULL(domain_spell.active_domain, "Успешное сосредоточение создаёт домен.")
	qdel(domain_spell.active_domain)
	TEST_ASSERT_NULL(domain_spell.active_domain, "Удалённый домен не удерживается заклинанием.")

/// Прицеливание не расходует защиту цели до применения заклинания.
/datum/unit_test/heretic_targeting_preserves_antimagic/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/obj/effect/proc_holder/spell/pointed/boogie_woogie/spell = allocate(/obj/effect/proc_holder/spell/pointed/boogie_woogie)
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Незащищённая жертва подходит для обмена.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	for(var/attempt in 1 to 3)
		TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Защищённая цель отклоняется при прицеливании.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Повторный выбор цели не истощает её защиту.")

/// Отказ перечисляет недостающие единицы и не считает занятые компоненты свободными.
/datum/unit_test/heretic_ritual_missing_components/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big)
	var/obj/effect/eldritch/other_rune = allocate(/obj/effect/eldritch/big)
	var/datum/eldritch_knowledge/recipe = allocate(/datum/eldritch_knowledge)
	recipe.required_atoms = list(/obj/item/pen, /obj/item/pen)
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "×2"), "Отказ указывает обе недостающие ручки.")
	var/obj/item/pen/pen = allocate(/obj/item/pen)
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "×1"), "Свободная ручка уменьшает нехватку до одной.")
	TEST_ASSERT(other_rune.reserve_atoms(list(pen)), "Другая руна резервирует компонент.")
	TEST_ASSERT(findtext(rune.recipe_failure_reason(recipe, user), "×2"), "Занятая ручка не маскирует нехватку компонентов.")

/// Проверка защиты не вызывает реакции предмета и не меняет таймеры зарядов.
/datum/unit_test/heretic_antimagic_probe
	var/reactions = 0
	var/charge_updates = 0

/datum/unit_test/heretic_antimagic_probe/proc/on_reaction()
	reactions++

/datum/unit_test/heretic_antimagic_probe/proc/on_charge_change()
	charge_updates++

/datum/unit_test/heretic_antimagic_probe/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5, TRUE, CALLBACK(src, PROC_REF(on_reaction)), null, 5 MINUTES, CALLBACK(src, PROC_REF(on_charge_change)))
	var/timers_before = length(protection.active_timers)
	TEST_ASSERT(timers_before > 0, "У защиты должен быть настоящий таймер истечения заряда.")
	for(var/check_index in 1 to 3)
		TEST_ASSERT(victim.check_magic_resistance(chargecost = 0), "Проверка видит действующую защиту.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не расходует заряд.")
	TEST_ASSERT_EQUAL(reactions, 0, "Проверка не вызывает реакцию предмета.")
	TEST_ASSERT_EQUAL(charge_updates, 0, "Проверка не объявляет изменение зарядов.")
	TEST_ASSERT_EQUAL(length(protection.active_timers), timers_before, "Проверка не добавляет таймер истечения.")
	TEST_ASSERT(victim.check_magic_resistance(), "Настоящая атака тоже блокируется.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Настоящая атака расходует один заряд.")
	TEST_ASSERT_EQUAL(reactions, 1, "Настоящая атака вызывает реакцию.")
	TEST_ASSERT_EQUAL(charge_updates, 1, "Изменение заряда сообщается один раз.")

/// Стазис обряда прекращает биологическую жизнь и снимается при прерывании, сохраняя чужой источник.
/datum/unit_test/heretic_hunt_channel_stasis/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/mind/soul = new
	allocated += soul
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	victim.adjustBruteLoss(150)
	TEST_ASSERT(victim.stat != DEAD, "Подготовленная цель ещё жива.")
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big)
	var/datum/eldritch_knowledge/spell/basic/ritual = allocate(/datum/eldritch_knowledge/spell/basic)
	TEST_ASSERT(rune.reserve_atoms(list(victim)), "Жертва резервируется руной.")
	rune.apply_hunt_stasis(ritual, user)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/grouped/stasis), "Цель в крите получает стазис.")
	TEST_ASSERT(SEND_SIGNAL(victim, COMSIG_LIVING_LIFE, 1) & COMPONENT_INTERRUPT_LIFE_BIOLOGICAL, "Стазис останавливает кровотечение и обмен веществ через обработчик жизни.")
	victim.forceMove(get_step(victim, EAST))
	TEST_ASSERT(rune.ritual_interrupted, "Перемещение жертвы прерывает канал.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/grouped/stasis), "Прерванный канал сразу снимает свой стазис.")
	rune.release_atoms()
	TEST_ASSERT(rune.reserve_atoms(list(victim)), "Освобождённая жертва доступна для нового канала.")
	victim.apply_status_effect(/datum/status_effect/grouped/stasis, "independent_stasis")
	rune.apply_hunt_stasis(ritual, user)
	qdel(rune)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/grouped/stasis), "Удаление руны сохраняет независимый стазис.")
	victim.remove_status_effect(/datum/status_effect/grouped/stasis, "independent_stasis")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/grouped/stasis), "После удаления независимого источника стазис не остаётся.")

/// Руна принимает обезвреженную цель и снимает только собственное удержание при спасении.
/datum/unit_test/heretic_hunt_capture_states/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	TEST_ASSERT(!heretic.hunt_target_ready(victim), "Свободная стоящая цель не подходит.")
	victim.Stun(5 SECONDS)
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Оглушение позволяет начать обряд без ранений.")
	victim.SetStun(0)
	victim.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Реальное сбивание с ног хваткой позволяет начать обряд.")
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big)
	var/datum/eldritch_knowledge/spell/basic/ritual = allocate(/datum/eldritch_knowledge/spell/basic)
	TEST_ASSERT(rune.reserve_atoms(list(victim)), "Цель резервируется руной.")
	rune.apply_hunt_stasis(ritual, user)
	victim.set_resting(FALSE)
	TEST_ASSERT(victim.IsParalyzed() && !(victim.mobility_flags & MOBILITY_MOVE), "Попытка встать не снимает удержание канала.")
	victim.forceMove(get_step(victim, EAST))
	TEST_ASSERT(rune.ritual_interrupted && !victim.IsParalyzed(), "Перемещение спасателем сразу снимает удержание.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/grouped/stasis), "Спасение возобновляет биологическую жизнь.")
	rune.release_atoms()
	victim.Paralyze(30 SECONDS)
	var/datum/status_effect/original_paralysis = victim.IsParalyzed()
	var/original_expiry = original_paralysis.duration
	TEST_ASSERT(rune.reserve_atoms(list(victim)), "Цель повторно резервируется после освобождения.")
	rune.apply_hunt_stasis(ritual, user)
	TEST_ASSERT(!QDELETED(original_paralysis), "Обряд не заменяет существующий паралич.")
	qdel(rune)
	TEST_ASSERT_EQUAL(victim.IsParalyzed(), original_paralysis, "Удаление руны сохраняет чужой паралич.")
	TEST_ASSERT_EQUAL(original_paralysis.duration, original_expiry, "Обряд не продлевает чужой паралич.")
	victim.death()
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Труп подходит для обряда с уменьшенной наградой.")

/area/heretic_station_return_fixture
	area_flags = VALID_TERRITORY
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/// Возвращение выбирает безопасный станционный пол и отклоняет непригодные помещения.
/datum/unit_test/heretic_station_return_locations
	var/list/previous_areas
	var/list/previous_level_traits
	var/datum/space_level/test_level
	var/area/original_area
	var/turf/destination

/datum/unit_test/heretic_station_return_locations/Destroy()
	if(previous_areas)
		GLOB.the_station_areas = previous_areas
	if(previous_level_traits)
		test_level.traits = previous_level_traits
	if(original_area && destination)
		original_area.contents += destination
	return ..()

/datum/unit_test/heretic_station_return_locations/Run()
	previous_areas = GLOB.the_station_areas
	test_level = SSmapping.get_level(run_loc_floor_top_right.z)
	previous_level_traits = test_level.traits
	test_level.traits = previous_level_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	destination = run_loc_floor_top_right
	original_area = get_area(destination)
	var/area/heretic_station_return_fixture/station_area = new
	allocated += station_area
	station_area.contents += destination
	GLOB.sortedAreas |= station_area
	GLOB.the_station_areas = list(station_area.type)
	TEST_ASSERT_EQUAL(length(get_area_turfs(station_area)), 1, "В тестовой станционной области ровно одно место прибытия.")
	TEST_ASSERT(is_safe_turf(destination), "Выбранный пол имеет пригодную атмосферу и свободен.")
	TEST_ASSERT_EQUAL(find_heretic_station_turf(), destination, "Телепортация выбирает зарегистрированную часть станции.")
	station_area.area_flags |= NOTELEPORT
	TEST_ASSERT_NULL(find_heretic_station_turf(), "Запрет телепортации не игнорируется после неудачных попыток.")
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/turf/origin = get_turf(user)
	var/obj/item/melee/sickly_blade/blade = allocate(/obj/item/melee/sickly_blade, user)
	user.put_in_hands(blade)
	blade.attack_self(user)
	TEST_ASSERT(!QDELETED(blade), "Неудачная телепортация сохраняет клинок.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Без безопасного места владелец остаётся на месте.")
	station_area.area_flags &= ~NOTELEPORT
	var/obj/structure/table/obstacle = allocate(/obj/structure/table, destination)
	TEST_ASSERT_EQUAL(obstacle.loc, destination, "Препятствие находится на проверяемом полу.")
	TEST_ASSERT(obstacle.density, "Стол блокирует место прибытия.")
	TEST_ASSERT(!is_safe_turf(destination), "Проверка безопасности замечает стол.")
	TEST_ASSERT_NULL(find_heretic_station_turf(), "Занятый пол не подходит для возвращения.")
	qdel(obstacle)
	test_level.traits -= ZTRAIT_STATION
	TEST_ASSERT_NULL(find_heretic_station_turf(), "Одного имени области недостаточно вне станции.")
	test_level.traits[ZTRAIT_STATION] = TRUE
	blade.attack_self(user)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Клинок переносит владельца в подходящую часть станции.")
	TEST_ASSERT(QDELETED(blade), "Успешная телепортация расходует клинок.")

/datum/antagonist/heretic/hunt_selection_fixture
	var/list/prompt_choices = list()
	var/prompt_choice = 0
	var/prompt_count = 0
	var/clear_during_prompt = FALSE

/datum/antagonist/heretic/hunt_selection_fixture/hunt_target_available(datum/mind/candidate, selecting = FALSE)
	return ..(candidate, FALSE) && (!selecting || candidate.current.stat != DEAD)

/datum/antagonist/heretic/hunt_selection_fixture/prompt_hunt_target(mob/living/user, list/choices)
	prompt_count++
	prompt_choices = choices.Copy()
	if(clear_during_prompt)
		clear_hunt()
	return prompt_choice ? choices[prompt_choice] : null

/// Отмена сохраняет предложения; выбывшие кандидаты заменяются, а подтверждение соблюдает смену цели и перезарядку.
/datum/unit_test/heretic_hunt_selection_persistence
	var/list/previous_records
	var/list/previous_traits
	var/datum/space_level/test_level

/datum/unit_test/heretic_hunt_selection_persistence/Destroy()
	if(previous_records)
		GLOB.data_core.locked = previous_records
	if(previous_traits)
		test_level.traits = previous_traits
	return ..()

/datum/unit_test/heretic_hunt_selection_persistence/Run()
	previous_records = GLOB.data_core.locked
	GLOB.data_core.locked = list()
	test_level = SSmapping.get_level(run_loc_floor_bottom_left.z)
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/hunt_selection_fixture/heretic = allocate(/datum/antagonist/heretic/hunt_selection_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	for(var/index in 1 to 6)
		var/mob/living/carbon/human/candidate_body = allocate(/mob/living/carbon/human)
		candidate_body.real_name = "Тестовая цель [index]"
		var/datum/mind/candidate = allocate_mind()
		candidate.current = candidate_body
		candidate.assigned_role = "Assistant"
		candidate_body.mind = candidate
		var/datum/data/record/record = allocate(/datum/data/record)
		record.fields["mindref"] = candidate
		GLOB.data_core.locked += record
	var/obj/item/living_heart/first_heart = allocate(/obj/item/living_heart, user)
	first_heart.attack_self(user)
	TEST_ASSERT_EQUAL(heretic.prompt_count, 1, "Сердце открыло выбор цели.")
	TEST_ASSERT_NULL(heretic.hunt_target, "Закрытие окна не назначает цель.")
	TEST_ASSERT(!heretic.hunt_selection_open, "Закрытие освобождает окно выбора.")
	var/list/first_choices = heretic.prompt_choices.Copy()
	TEST_ASSERT_EQUAL(length(first_choices), 3, "Предложены три разных кандидата.")
	var/obj/item/living_heart/second_heart = allocate(/obj/item/living_heart, user)
	for(var/attempt in 1 to 3)
		second_heart.attack_self(user)
		TEST_ASSERT_EQUAL(length(heretic.prompt_choices), 3, "Повторное открытие сохраняет три предложения.")
		for(var/index in 1 to 3)
			TEST_ASSERT_EQUAL(heretic.prompt_choices[index], first_choices[index], "Имена и порядок предложений не меняются после отмены или смены сердца.")
	var/datum/weakref/dead_ref = heretic.hunt_candidates[1]
	var/datum/mind/dead_candidate = dead_ref.resolve()
	var/mob/living/dead_body = dead_candidate.current
	var/list/remaining = heretic.hunt_candidates.Copy(2)
	dead_body.death()
	TEST_ASSERT(!heretic.ensure_hunt_target(user, force_replace = TRUE), "Повторная отмена не выбирает замену автоматически.")
	TEST_ASSERT_EQUAL(length(heretic.hunt_candidates), 3, "Выбывший кандидат заменён.")
	TEST_ASSERT(!(dead_ref in heretic.hunt_candidates), "Погибший кандидат больше не предлагается новой целью.")
	TEST_ASSERT_EQUAL(length(remaining & heretic.hunt_candidates), 2, "Остальные два предложения сохранены.")
	var/datum/weakref/deleted_ref = heretic.hunt_candidates[3]
	qdel(deleted_ref.resolve())
	TEST_ASSERT_NULL(deleted_ref.resolve(), "Удалённый разум не удерживается предложениями.")
	heretic.ensure_hunt_target(user)
	TEST_ASSERT_EQUAL(length(heretic.hunt_candidates), 3, "Удалённый разум заменяется доступным кандидатом.")
	TEST_ASSERT_EQUAL(length(remaining & heretic.hunt_candidates), 2, "Удаление одного разума не меняет оставшуюся пару.")
	var/datum/weakref/chosen_ref = heretic.hunt_candidates[1]
	heretic.prompt_choice = 1
	TEST_ASSERT(heretic.ensure_hunt_target(user), "Подтверждённое предложение назначает цель.")
	TEST_ASSERT_EQUAL(heretic.hunt_target, chosen_ref.resolve(), "Выбрана именно показанная душа.")
	TEST_ASSERT_EQUAL(length(heretic.hunt_candidates), 0, "Подтверждение завершает текущий набор предложений.")
	heretic.prompt_choice = 0
	TEST_ASSERT(!heretic.ensure_hunt_target(user, force_replace = TRUE), "Отмена смены цели оставляет прежнее назначение.")
	TEST_ASSERT_EQUAL(heretic.hunt_target, chosen_ref.resolve(), "Прежняя цель сохранена после отмены замены.")
	TEST_ASSERT(!(chosen_ref in heretic.hunt_candidates), "Текущая цель не предлагается как замена самой себе.")
	TEST_ASSERT(COOLDOWN_FINISHED(heretic, hunt_refresh_cooldown), "Отмена не запускает перезарядку смены цели.")
	heretic.prompt_choice = 1
	TEST_ASSERT(heretic.ensure_hunt_target(user, force_replace = TRUE), "Подтверждение меняет действующую цель.")
	TEST_ASSERT(!COOLDOWN_FINISHED(heretic, hunt_refresh_cooldown), "Подтверждённая замена запускает перезарядку.")
	var/prompts_before = heretic.prompt_count
	TEST_ASSERT(!heretic.ensure_hunt_target(user, force_replace = TRUE), "Перезарядка запрещает следующую замену.")
	TEST_ASSERT_EQUAL(heretic.prompt_count, prompts_before, "При перезарядке новое окно не открывается.")
	heretic.set_hunt_target(null)
	heretic.clear_during_prompt = TRUE
	TEST_ASSERT(!heretic.ensure_hunt_target(user), "Ответ из окна сброшенной охоты отклоняется.")
	TEST_ASSERT_NULL(heretic.hunt_target, "Устаревший ответ не восстанавливает назначение после сброса.")
	TEST_ASSERT_EQUAL(length(heretic.hunt_candidates), 0, "Сброс охоты очищает сохранённые предложения.")
