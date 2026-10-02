/// empty() удаляет содержимое турфа вместе с вложенным, оставляет ориентиры и меняет тип турфа.
/datum/unit_test/turf_empty_spares_ignored_atoms/Run()
	var/turf/spot = run_loc_floor_bottom_left
	var/obj/item/storage/box/box = allocate(/obj/item/storage/box, spot)
	var/obj/item/pen/nested = allocate(/obj/item/pen, box)
	var/obj/effect/landmark/landmark = allocate(/obj/effect/landmark, spot)

	spot.empty(/turf/open/floor/plating)
	TEST_ASSERT(QDELETED(box), "Коробка пережила empty()")
	TEST_ASSERT(QDELETED(nested), "Вложенный предмет пережил empty()")
	TEST_ASSERT(!QDELETED(landmark) && landmark.loc == spot, "Ориентир удалён или сдвинут")
	TEST_ASSERT(istype(spot, /turf/open/floor/plating), "Турф с содержимым не заменён")

	var/turf/bare = run_loc_floor_top_right
	bare.empty(/turf/open/floor/plating)
	TEST_ASSERT(istype(bare, /turf/open/floor/plating), "Пустой турф не заменён")

/// empty() оставляет турфу его объект света: без него динамически освещённый турф после замены остаётся чёрным.
/datum/unit_test/turf_empty_keeps_lighting_object/Run()
	var/turf/spot = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/overlay = ensure_lighting_object(spot)

	spot.empty(FALSE)
	TEST_ASSERT(!QDELETED(overlay), "empty() без замены турфа удалил объект света")
	TEST_ASSERT_EQUAL(spot.lighting_object, overlay, "Турф потерял объект света")

	spot.empty(/turf/open/floor/plating)
	TEST_ASSERT(!QDELETED(overlay), "empty() с заменой турфа удалил объект света")
	TEST_ASSERT_EQUAL(spot.lighting_object, overlay, "Объект света не перешёл на новый турф")
	TEST_ASSERT(overlay in spot.vis_contents, "Объект света не в vis_contents нового турфа")
