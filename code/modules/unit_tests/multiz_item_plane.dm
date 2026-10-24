/// Предмет, покинувший руки или наручники на нижнем этаже стопки, ложится на плоскость своего этажа, а не этажа 0.
/datum/unit_test/multiz_item_plane_after_unequip

/datum/unit_test/multiz_item_plane_after_unequip/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: смещений нет.

	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, lower)
	var/obj/item/probe = allocate(/obj/item/screwdriver, lower)
	var/expected = GET_NEW_PLANE(initial(probe.plane), GET_Z_PLANE_OFFSET(lower.z))
	TEST_ASSERT_EQUAL(probe.plane, expected, "Предмет на нижнем этаже обязан стоять на плоскости этого этажа ещё до рук")

	TEST_ASSERT(holder.put_in_hands(probe), "Не удалось вложить предмет в руки")
	holder.dropItemToGround(probe)
	TEST_ASSERT_EQUAL(probe.loc, lower, "Предмет должен был упасть под ноги")
	TEST_ASSERT_EQUAL(probe.plane, expected, "Выброшенный или брошенный из рук предмет остался на плоскости этажа 0")

	TEST_ASSERT(holder.put_in_hands(probe), "Не удалось снова вложить предмет в руки")
	probe.forceMove(lower)
	TEST_ASSERT_EQUAL(probe.plane, expected, "Предмет, вынутый из рук forceMove, остался на плоскости этажа 0")

	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, lower)
	holder.equip_to_slot(cuffs, ITEM_SLOT_HANDCUFFED)
	TEST_ASSERT_EQUAL(holder.handcuffed, cuffs, "Не удалось надеть наручники")
	holder.uncuff()
	TEST_ASSERT_EQUAL(cuffs.loc, lower, "Наручники должны были упасть под ноги")
	TEST_ASSERT_EQUAL(cuffs.plane, GET_NEW_PLANE(initial(cuffs.plane), GET_Z_PLANE_OFFSET(lower.z)), "Снятые наручники остались на плоскости этажа 0")

/// Вещь внутри носителя не пересчитывает этаж на каждом его переходе, а досчитывает, когда ляжет на пол.
/datum/unit_test/multiz_carried_item_plane_lazy

/datum/unit_test/multiz_carried_item_plane_lazy/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/upper = locate(80, 80, levels[2])
	var/turf/lower = locate(80, 80, levels[1])
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, upper)
	var/obj/item/screwdriver/probe = allocate(/obj/item/screwdriver, upper)
	probe.forceMove(carrier)

	carrier.forceMove(lower)
	TEST_ASSERT_EQUAL(carrier.plane, GET_NEW_PLANE(initial(carrier.plane), GET_Z_PLANE_OFFSET(lower.z)), "Носитель не перешёл на плоскость нового этажа")
	TEST_ASSERT(probe.plane_offset_stale, "Вещь внутри носителя пересчитала плоскость вместе с ним")

	probe.forceMove(lower)
	TEST_ASSERT(!probe.plane_offset_stale, "Вещь на полу осталась помеченной как отставшая")
	TEST_ASSERT_EQUAL(probe.plane, GET_NEW_PLANE(initial(probe.plane), GET_Z_PLANE_OFFSET(lower.z)), "Вещь, выложенная на пол нового этажа, осталась на плоскости старого")
