/// Регрессии по неподвижному стержню из прод-раунда 9837 (2026-07-30):
/// четыре /obj/effect/immovablerod/wizard ушли в warnfail, и вместе с ними
/// не собрались шесть человек и пять мозгов - стержень тянул за собой визарда.

/datum/unit_test/immovable_rod_destroy_releases_holders

/datum/unit_test/immovable_rod_destroy_releases_holders/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/finish = locate(start.x + 3, start.y, start.z)
	TEST_ASSERT_NOTNULL(finish, "Не нашлась целевая клетка для стержня")

	var/obj/effect/immovablerod/rod = new(start, finish)
	TEST_ASSERT(GLOB.poi_list.Find(rod), "Стержень не попал в poi_list")
	TEST_ASSERT_NOTNULL(SSaugury.doombringers[rod], "Стержень не зарегистрировался в SSaugury")

	qdel(rod)

	TEST_ASSERT(!GLOB.poi_list.Find(rod), "Destroy стержня не снял его с poi_list")
	TEST_ASSERT_NULL(SSaugury.doombringers[rod], "Destroy стержня не снял его с учёта SSaugury")
	TEST_ASSERT_NULL(rod.special_target, "Destroy стержня не отпустил цель наведения")
	TEST_ASSERT_NULL(rod.destination_turf, "Destroy стержня не отпустил точку назначения")

/// Форма стержня из спелла визарда возвращает мага в мир и перестаёт его держать.
/datum/unit_test/immovable_rod_wizard_form_releases_caster

/datum/unit_test/immovable_rod_wizard_form_releases_caster/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/finish = locate(start.x + 3, start.y, start.z)
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)

	var/obj/effect/immovablerod/wizard/rod = new(start, finish)
	rod.wizard = caster
	rod.start_turf = start
	caster.forceMove(rod)
	caster.mob_transforming = 1
	caster.status_flags |= GODMODE

	qdel(rod)

	TEST_ASSERT_NULL(rod.wizard, "Стержень продолжает держать визарда после Destroy")
	TEST_ASSERT_EQUAL(caster.loc, start, "Визарда не вернуло на клетку стержня")
	TEST_ASSERT_EQUAL(caster.mob_transforming, 0, "С визарда не снят флаг превращения")
	TEST_ASSERT(!(caster.status_flags & GODMODE), "С визарда не снят GODMODE")
