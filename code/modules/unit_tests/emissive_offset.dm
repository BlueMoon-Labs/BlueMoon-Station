/// Смещение эмиссивов по этажам стопки и аудит плоскостей оверлеев.

#define EMISSIVE_OFFSET_TEST_ICON 'icons/effects/summon.dmi'
#define EMISSIVE_OFFSET_TEST_STATE "sword"

/// Турф самого нижнего этажа стопки для проб переезда; null в односложном мире.
/// Берётся внутри полосы перехода и на этаже без низа: угловой турф связанного уровня уносит прибывшего за край карты, а с открытого этажа он падает.
/proc/multiz_test_lower_turf()
	for(var/z in 1 to world.maxz)
		if(!GET_Z_PLANE_OFFSET(z) || (z <= length(SSmapping.z_level_below) && SSmapping.z_level_below[z]))
			continue
		return locate(TRANSITIONEDGE + 2, TRANSITIONEDGE + 2, z)
	return null

/// Эмиссив со spokesman'ом ложится на EMISSIVE_PLANE этажа носителя.
/datum/unit_test/emissive_offset_follows_spokesman

/datum/unit_test/emissive_offset_follows_spokesman/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: смещений нет.

	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")

	var/mutable_appearance/glow = emissive_appearance(EMISSIVE_OFFSET_TEST_ICON, EMISSIVE_OFFSET_TEST_STATE, offset_spokesman = lower)
	TEST_ASSERT_EQUAL(glow.plane, GET_NEW_PLANE(EMISSIVE_PLANE, GET_Z_PLANE_OFFSET(lower.z)), "Эмиссив с носителем на нижнем этаже обязан лежать на плоскости этого этажа")

	var/mutable_appearance/ground = emissive_appearance(EMISSIVE_OFFSET_TEST_ICON, EMISSIVE_OFFSET_TEST_STATE, offset_spokesman = run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(ground.plane, GET_NEW_PLANE(EMISSIVE_PLANE, GET_Z_PLANE_OFFSET(run_loc_floor_bottom_left.z)), "Эмиссив с носителем на своём этаже обязан лежать на плоскости этого этажа")

/// Свечение призванного клинка переезжает на этаж, куда переехал сам эффект.
/datum/unit_test/emissive_offset_summon_weapon_follows_floor

/datum/unit_test/emissive_offset_summon_weapon_follows_floor/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: смещений нет.

	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")

	var/datum/summon_weapon_host/sword/host = new(null, 1, 7)
	TEST_ASSERT_EQUAL(length(host.controlled), 1, "Хост должен был создать один клинок")
	var/datum/summon_weapon/weapon = host.controlled[1]
	var/atom/movable/effect = weapon.atom
	TEST_ASSERT_NOTNULL(effect, "У клинка нет эффекта")

	effect.forceMove(lower)
	TEST_ASSERT_EQUAL(effect.loc, lower, "Эффект должен был переехать на нижний этаж")

	var/expected = GET_NEW_PLANE(EMISSIVE_PLANE, GET_Z_PLANE_OFFSET(lower.z))
	var/found = FALSE
	for(var/mutable_appearance/overlay as anything in effect.overlays)
		if(PLANE_TO_TRUE(overlay.plane) != EMISSIVE_PLANE)
			continue
		found = TRUE
		TEST_ASSERT_EQUAL(overlay.plane, expected, "Свечение клинка осталось на плоскости этажа 0 после переезда на нижний этаж")
	TEST_ASSERT(found, "У эффекта клинка нет эмиссивного оверлея")

	qdel(host)

/// Аудит этажа молчит про оверлеи на плоскости своего этажа и ловит оверлей с плоскости чужого.
/datum/unit_test/emissive_offset_audit_sees_overlays

/datum/unit_test/emissive_offset_audit_sees_overlays/Run()
	var/obj/item/probe = allocate(/obj/item, run_loc_floor_bottom_left)
	var/offset = GET_Z_PLANE_OFFSET(run_loc_floor_bottom_left.z)

	var/mutable_appearance/mark = mutable_appearance(EMISSIVE_OFFSET_TEST_ICON, EMISSIVE_OFFSET_TEST_STATE)
	SET_PLANE_EXPLICIT(mark, GAME_PLANE, probe)
	probe.add_overlay(mark)
	probe.add_overlay(emissive_appearance(EMISSIVE_OFFSET_TEST_ICON, EMISSIVE_OFFSET_TEST_STATE, offset_spokesman = probe))

	var/list/samples = list()
	var/list/by_type = audit_z_level_planes(run_loc_floor_bottom_left.z, samples)
	TEST_ASSERT(!length(by_type), "Аудит пожаловался на оверлеи своего этажа:\n[samples.Join("\n")]")

	if(!SSmapping.max_plane_offset)
		return // Односложный мир: чужой плоскости не существует.

	var/mutable_appearance/stray = mutable_appearance(EMISSIVE_OFFSET_TEST_ICON, EMISSIVE_OFFSET_TEST_STATE)
	stray.plane = GET_NEW_PLANE(GAME_PLANE, offset ? 0 : 1)
	probe.add_overlay(stray)

	samples = list()
	by_type = audit_z_level_planes(run_loc_floor_bottom_left.z, samples)
	TEST_ASSERT_EQUAL(by_type["[probe.type] overlay"], 1, "Аудит не заметил оверлей с плоскости чужого этажа")
	TEST_ASSERT_EQUAL(length(by_type), 1, "Аудит пожаловался на что-то кроме подсаженного оверлея:\n[samples.Join("\n")]")

#undef EMISSIVE_OFFSET_TEST_ICON
#undef EMISSIVE_OFFSET_TEST_STATE
