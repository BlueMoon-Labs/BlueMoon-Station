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

/datum/unit_test/heretic_hunt_return/Destroy()
	if(test_level && previous_traits)
		test_level.traits = previous_traits
	if(previous_sacrificed)
		GLOB.heretic_sacrificed_minds = previous_sacrificed
	return ..()

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
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/victim_mind = new
	allocated += victim_mind
	victim_mind.current = victim
	victim.mind = victim_mind
	heretic.set_hunt_target(victim_mind)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце должно привязаться к еретику.")
	TEST_ASSERT(!heart.bind(victim_mind), "Похищение сердца не передаёт чужую охоту.")
	var/list/selected = list()
	TEST_ASSERT(!heretic.select_hunt_atoms(user, list(victim, heart), selected), "Цель в сознании не принимается.")
	victim.Unconscious(30 SECONDS)
	victim.adjustBruteLoss(30)
	TEST_ASSERT(heretic.select_hunt_atoms(user, list(victim, heart), selected), "Назначенная цель без сознания и своё сердце подходят для обряда.")
	var/points_before = heretic.knowledge_points
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	TEST_ASSERT(rune.reserve_atoms(selected), "Настоящая руна резервирует сердце и жертву.")
	rune.ritual_user = user
	rune.ritual_interrupted = TRUE
	TEST_ASSERT(!heretic.complete_hunt_ritual(user, selected, run_loc_floor_bottom_left), "Отменённая руна не принимает душу, даже если компоненты остались рядом.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, points_before, "Прерванный обряд не выдаёт знания.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[victim_mind], "Прерванный обряд не оставляет посещение Мансуса.")
	rune.ritual_interrupted = FALSE
	TEST_ASSERT(heretic.complete_hunt_ritual(user, selected, run_loc_floor_bottom_left), "Ритуал должен принять назначенную душу.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, points_before + 2, "Жертва даёт два знания без наличия кодекса.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Счётчик жертв увеличивается один раз.")
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[victim_mind]
	TEST_ASSERT_NOTNULL(visit, "Обряд отправляет жертву в отдельное посещение Мансуса.")
	allocated += visit
	TEST_ASSERT(visit.contains(victim), "До возвращения жертва находится в комнате Мансуса.")
	rune.release_atoms()
	visit.finish()
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Жертва возвращается в безопасную точку.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Возвращённая жертва получает медицинское восстановление.")
	TEST_ASSERT(victim.stat != DEAD, "Обряд возвращает жертву живой.")
	heretic.set_hunt_target(victim_mind)
	TEST_ASSERT(!heretic.hunt_target_available(victim_mind), "Принесённую душу нельзя выбрать повторно.")
	TEST_ASSERT(!heretic.complete_hunt_ritual(user, selected, run_loc_floor_top_right), "Повторный ритуал не выдаёт знаний.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, points_before + 2, "Повтор души не увеличивает знания.")

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
		TEST_ASSERT(victim.anti_magic_check(chargecost = 0), "Проверка видит действующую защиту.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не расходует заряд.")
	TEST_ASSERT_EQUAL(reactions, 0, "Проверка не вызывает реакцию предмета.")
	TEST_ASSERT_EQUAL(charge_updates, 0, "Проверка не объявляет изменение зарядов.")
	TEST_ASSERT_EQUAL(length(protection.active_timers), timers_before, "Проверка не добавляет таймер истечения.")
	TEST_ASSERT(victim.anti_magic_check(), "Настоящая атака тоже блокируется.")
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
