/// Тигель создаётся пустым, сам набирает доли до полного и после варки наполняется заново.
/datum/unit_test/heretic_crucible_refill/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/structure/eldritch_crucible/crucible = allocate(/obj/structure/eldritch_crucible)
	TEST_ASSERT_EQUAL(crucible.current_mass, 0, "Новый тигель пуст.")
	TEST_ASSERT_NOTNULL(crucible.refill_timer, "Пустой тигель ждёт пополнения.")
	TEST_ASSERT_NULL(crucible.brew(user, /obj/item/eldritch_potion/wounded), "Неполный тигель не варит.")
	for(var/refill_step in 1 to crucible.max_mass)
		deltimer(crucible.refill_timer)
		crucible.refill()
	TEST_ASSERT_EQUAL(crucible.current_mass, crucible.max_mass, "Пополнение доводит тигель до полного.")
	TEST_ASSERT_NULL(crucible.refill_timer, "Полный тигель не ждёт пополнения.")
	TEST_ASSERT_EQUAL(crucible.icon_state, "crucible_3", "Полный тигель показывает полный стейт.")
	var/obj/item/eldritch_potion/potion = crucible.brew(user, /obj/item/eldritch_potion/wounded)
	TEST_ASSERT_NOTNULL(potion, "Полный тигель варит зелье.")
	allocated += potion
	TEST_ASSERT_EQUAL(crucible.current_mass, 0, "Варка забирает всю массу.")
	TEST_ASSERT_NOTNULL(crucible.refill_timer, "После варки тигель снова наполняется.")
	TEST_ASSERT_EQUAL(crucible.icon_state, "crucible_0", "Пустой тигель показывает пустой стейт.")

/// Тигель ест органы и конечности, но не мозг и не голову с мозгом.
/datum/unit_test/heretic_crucible_feeding/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/structure/eldritch_crucible/crucible = allocate(/obj/structure/eldritch_crucible)
	var/obj/item/organ/brain/brain = allocate(/obj/item/organ/brain)
	crucible.attacked_by(brain, user)
	TEST_ASSERT(!QDELETED(brain), "Мозг не попадает в тигель.")
	TEST_ASSERT_EQUAL(crucible.current_mass, 0, "Отказ не добавляет массу.")
	var/obj/item/bodypart/head/head = allocate(/obj/item/bodypart/head)
	brain.forceMove(head)
	head.brain = brain
	crucible.attacked_by(head, user)
	TEST_ASSERT(!QDELETED(head), "Голова с мозгом не попадает в тигель.")
	TEST_ASSERT(!QDELETED(brain), "Мозг в голове уцелел.")
	head.brain = null
	brain.forceMove(run_loc_floor_bottom_left)
	crucible.attacked_by(head, user)
	TEST_ASSERT(QDELETED(head), "Голова без мозга уходит в тигель.")
	TEST_ASSERT_EQUAL(crucible.current_mass, 1, "Часть тела добавляет долю.")
	var/obj/item/organ/liver/liver = allocate(/obj/item/organ/liver)
	crucible.attacked_by(liver, user)
	TEST_ASSERT(QDELETED(liver), "Печень уходит в тигель.")
	TEST_ASSERT_EQUAL(crucible.current_mass, 2, "Орган добавляет долю.")

/// Повторный обряд переносит единственный тигель еретика вместе с содержимым.
/datum/unit_test/heretic_crucible_ritual/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/crucible)
	var/datum/eldritch_knowledge/crucible/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/crucible)
	var/turf/first_spot = run_loc_floor_bottom_left
	var/turf/second_spot = get_step(first_spot, NORTHEAST)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), first_spot), "Обряд создаёт тигель.")
	var/obj/structure/eldritch_crucible/first = locate() in first_spot
	TEST_ASSERT_NOTNULL(first, "Тигель появился на руне.")
	allocated += first
	TEST_ASSERT_EQUAL(first.current_mass, 0, "Тигель из обряда пуст.")
	first.set_mass(2)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), second_spot), "Повторный обряд проходит.")
	var/obj/structure/eldritch_crucible/second = locate() in second_spot
	TEST_ASSERT_NOTNULL(second, "Тигель появился на новом месте.")
	allocated += second
	TEST_ASSERT(QDELETED(first), "Прежний тигель исчезает.")
	TEST_ASSERT_EQUAL(second.current_mass, 2, "Содержимое переходит в новый тигель.")
