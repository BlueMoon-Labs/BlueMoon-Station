/// Консоль экипажа на верхнем этаже связки видит датчики костюма с нижнего.
/datum/unit_test/multiz_crew_monitor_covers_stack

/datum/unit_test/multiz_crew_monitor_covers_stack/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: связок нет.

	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")
	var/turf/upper = GET_TURF_ABOVE(lower)
	TEST_ASSERT_NOTNULL(upper, "Над нижним этажом стопки нет этажа")

	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, lower)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(patient.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Пациенту не надеть комбинезон")
	uniform.sensor_mode = SENSOR_COORDS

	GLOB.crewmonitor.data_by_z -= "[upper.z]"
	var/found = FALSE
	for(var/list/entry as anything in GLOB.crewmonitor.update_data(upper.z))
		if(entry["name"] == patient.name)
			found = TRUE
			break
	TEST_ASSERT(found, "Консоль на z[upper.z] не видит датчики пациента на z[lower.z]")
