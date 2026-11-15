/// "decrease pressure penalty" вдвое уменьшает штраф давления за каждый установленный модуль,
/// а "shotgun blast" превращает один выстрел в три снаряда. Вместе они дают КА, который убивает
/// обычного сотрудника станции с одного выстрела, поэтому модули несовместимы:
/// ни один из них не должен вставать в КА, где уже стоит другой - в любом порядке установки.
/datum/unit_test/ka_modkit_pressure_and_shotgun_conflict/Run()
	var/obj/item/gun/energy/kinetic_accelerator/ka = allocate(/obj/item/gun/energy/kinetic_accelerator)
	var/obj/item/borg/upgrade/modkit/indoors/indoors = allocate(/obj/item/borg/upgrade/modkit/indoors)
	var/obj/item/borg/upgrade/modkit/shotgun/shotgun = allocate(/obj/item/borg/upgrade/modkit/shotgun)

	TEST_ASSERT(indoors.install(ka, null, FALSE), "Модуль давления должен вставать в пустой КА")
	TEST_ASSERT(!shotgun.install(ka, null, FALSE), "Модуль дробовика не должен вставать в КА с модулем давления")
	TEST_ASSERT_EQUAL(ka.modkits.len, 1, "В КА должен остаться только модуль давления")
	TEST_ASSERT_EQUAL(ka.modkits[1], indoors, "Установленным должен остаться модуль давления")

	var/obj/item/gun/energy/kinetic_accelerator/other_ka = allocate(/obj/item/gun/energy/kinetic_accelerator)
	var/obj/item/borg/upgrade/modkit/shotgun/other_shotgun = allocate(/obj/item/borg/upgrade/modkit/shotgun)
	var/obj/item/borg/upgrade/modkit/indoors/other_indoors = allocate(/obj/item/borg/upgrade/modkit/indoors)

	TEST_ASSERT(other_shotgun.install(other_ka, null, FALSE), "Модуль дробовика должен вставать в пустой КА")
	TEST_ASSERT(!other_indoors.install(other_ka, null, FALSE), "Модуль давления не должен вставать в КА с модулем дробовика")
	TEST_ASSERT_EQUAL(other_ka.modkits.len, 1, "В КА должен остаться только модуль дробовика")
	TEST_ASSERT_EQUAL(other_ka.modkits[1], other_shotgun, "Установленным должен остаться модуль дробовика")
