/// Ключ кэша конечностей несёт смещение этажа носителя: эмиссивы маркингов в наборе целят в EMISSIVE_PLANE того этажа, где набор собрали.
/datum/unit_test/carbon_limb_cache_offset

/datum/unit_test/carbon_limb_cache_offset/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	wearer.dna.features["allow_emissives"] = TRUE
	wearer.dna.features["mam_body_markings"] = list(list(CHEST, "Redpanda", list("#FFFFFF", "#FFFFFF", "#FFFFFF"), TRUE))
	wearer.update_body_parts()

	var/home_offset = LIMB_PLANE_OFFSET(wearer)
	var/list/home_planes = limb_emissive_planes(wearer)
	TEST_ASSERT_EQUAL(length(home_planes), 1, "Маркинг с эмиссивом должен дать ровно один эмиссивный оверлей в наборе конечностей")
	TEST_ASSERT_EQUAL(home_planes[1], GET_NEW_PLANE(EMISSIVE_PLANE, home_offset), "Эмиссив маркинга должен стоять на EMISSIVE_PLANE этажа носителя")

	var/home_key = wearer.generate_icon_render_key()
	TEST_ASSERT_EQUAL(home_key, wearer.generate_icon_render_key(home_offset), "Ключ по умолчанию обязан совпадать с ключом для смещения своего этажа")
	TEST_ASSERT_EQUAL(home_key, wearer.icon_render_key, "Ключ моба должен быть свежим после update_body_parts()")
	TEST_ASSERT(wearer.limb_icon_cache[home_key], "Набор конечностей должен лечь в кэш под ключом своего этажа")

	var/lower_key = wearer.generate_icon_render_key(home_offset + 1)
	TEST_ASSERT_NOTEQUAL(home_key, lower_key, "Ключ кэша конечностей обязан различать смещение плоскости носителя")
	TEST_ASSERT_NOTEQUAL(lower_key, wearer.generate_icon_render_key(home_offset + 2), "Разные нижние этажи должны давать разные ключи")

	var/lower_z = 0
	for(var/z_index in 1 to length(SSmapping.z_level_to_plane_offset))
		if(SSmapping.z_level_to_plane_offset[z_index])
			lower_z = z_index
			break
	if(!lower_z)
		log_test("\tНа карте нет стопки этажей, переезд носителя не проверяется")
		return

	var/turf/lower_floor = locate(1, 1, lower_z)
	TEST_ASSERT_NOTNULL(lower_floor, "У нижнего этажа [lower_z] нет турфа в углу карты")
	wearer.forceMove(lower_floor)

	var/lower_offset = GET_Z_PLANE_OFFSET(lower_z)
	TEST_ASSERT_EQUAL(wearer.icon_render_key, wearer.generate_icon_render_key(lower_offset), "После переезда на нижний этаж ключ моба должен нести смещение нового этажа")
	TEST_ASSERT_NOTEQUAL(wearer.icon_render_key, home_key, "Набор с верхнего этажа нельзя переиспользовать на нижнем")
	var/list/lower_planes = limb_emissive_planes(wearer)
	TEST_ASSERT_EQUAL(length(lower_planes), 1, "После переезда набор конечностей должен нести ровно один эмиссивный оверлей")
	TEST_ASSERT_EQUAL(lower_planes[1], GET_NEW_PLANE(EMISSIVE_PLANE, lower_offset), "Эмиссив маркинга должен переехать на EMISSIVE_PLANE нижнего этажа, а не остаться на плоскости этажа сборки")

/// Плоскости эмиссивных оверлеев в наборе конечностей носителя.
/datum/unit_test/carbon_limb_cache_offset/proc/limb_emissive_planes(mob/living/carbon/human/wearer)
	. = list()
	var/list/limbs = wearer.overlays_standing[BODYPARTS_LAYER]
	for(var/image/limb_overlay as anything in limbs)
		if(PLANE_TO_TRUE(limb_overlay.plane) == EMISSIVE_PLANE)
			. += limb_overlay.plane
