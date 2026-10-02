/// Нейтрализатор запечатывает след разлома в кристалл, ложный след и еретик кристалла не дают.
/datum/unit_test/heretic_veil_crystal_neutralize/Run()
	var/mob/living/carbon/human/scientist = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/effect/broken_illusion/trace = allocate(/obj/effect/broken_illusion, run_loc_floor_bottom_left)
	var/obj/item/anomaly_neutralizer/neutralizer = allocate(/obj/item/anomaly_neutralizer, run_loc_floor_bottom_left)
	TEST_ASSERT(trace.finish_neutralize(scientist, neutralizer), "Нейтрализация следа завершается.")
	TEST_ASSERT(QDELETED(trace), "След исчезает после нейтрализации.")
	TEST_ASSERT(QDELETED(neutralizer), "Нейтрализатор одноразовый.")
	var/obj/item/heretic_veil_crystal/crystal = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(crystal, "Настоящий след оставляет кристалл.")
	TEST_ASSERT(scientist.has_status_effect(/datum/status_effect/heretic_rift_exposure), "Нейтрализация считается касанием завесы.")
	TEST_ASSERT_EQUAL(scientist.getBruteLoss(), 0, "Первое касание только предупреждает.")
	qdel(crystal)

	var/obj/effect/broken_illusion/second = allocate(/obj/effect/broken_illusion, run_loc_floor_bottom_left)
	second.finish_neutralize(scientist, allocate(/obj/item/anomaly_neutralizer, run_loc_floor_bottom_left))
	TEST_ASSERT_EQUAL(scientist.getBruteLoss(), 20, "Повторная нейтрализация под воздействием ранит.")
	crystal = locate() in run_loc_floor_bottom_left
	qdel(crystal)

	var/obj/effect/broken_illusion/decoy = allocate(/obj/effect/broken_illusion, run_loc_floor_bottom_left)
	decoy.fake = TRUE
	decoy.finish_neutralize(scientist, allocate(/obj/item/anomaly_neutralizer, run_loc_floor_bottom_left))
	TEST_ASSERT_NULL(locate(/obj/item/heretic_veil_crystal) in run_loc_floor_bottom_left, "Ложный след кристалла не даёт.")

	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/obj/effect/broken_illusion/own = allocate(/obj/effect/broken_illusion, run_loc_floor_bottom_left)
	var/obj/item/anomaly_neutralizer/heretic_neutralizer = allocate(/obj/item/anomaly_neutralizer, run_loc_floor_bottom_left)
	TEST_ASSERT(!own.neutralize(heretic.owner.current, heretic_neutralizer), "Еретик не запечатывает завесу.")
	TEST_ASSERT(!QDELETED(own) && !QDELETED(heretic_neutralizer), "Отказ ничего не тратит.")
	var/list/points = SSresearch.techweb_point_items[/obj/item/heretic_veil_crystal]
	TEST_ASSERT_EQUAL(points?[TECHWEB_POINT_TYPE_GENERIC], HERETIC_VEIL_CRYSTAL_POINTS, "Кристалл разбирается на очки.")
	qdel(heretic)

/// Кристалл лечит только еретика и не складывается.
/datum/unit_test/heretic_veil_crystal_buff/Run()
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/heretic_veil_crystal/crystal = allocate(/obj/item/heretic_veil_crystal, run_loc_floor_bottom_left)
	crystal.attack_self(crew)
	TEST_ASSERT(!QDELETED(crystal), "Для экипажа кристалл не расходуется.")
	TEST_ASSERT(!crew.has_status_effect(/datum/status_effect/heretic_veil_crystal), "Экипаж не получает силу кристалла.")

	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	crystal.attack_self(user)
	TEST_ASSERT(QDELETED(crystal), "Еретик расходует кристалл.")
	var/datum/status_effect/heretic_veil_crystal/effect = user.has_status_effect(/datum/status_effect/heretic_veil_crystal)
	TEST_ASSERT_NOTNULL(effect, "Еретик получает силу кристалла.")
	var/obj/item/heretic_veil_crystal/spare = allocate(/obj/item/heretic_veil_crystal, run_loc_floor_bottom_left)
	spare.attack_self(user)
	TEST_ASSERT(!QDELETED(spare), "Второй кристалл не тратится, пока действует первый.")
	user.adjustBruteLoss(20)
	user.adjustStaminaLoss(30)
	var/stamina_before = user.getStaminaLoss()
	effect.tick()
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 16, "Сила кристалла затягивает раны.")
	TEST_ASSERT(user.getStaminaLoss() < stamina_before, "Сила кристалла возвращает выносливость.")
	qdel(heretic)
