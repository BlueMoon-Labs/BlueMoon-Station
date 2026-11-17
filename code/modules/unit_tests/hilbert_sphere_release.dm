/// Область комнаты живёт дольше резервации: удалённая сфера не должна оставаться в её parentSphere (warnfail сфер и гостей).
/datum/unit_test/hilbert_sphere_release
	priority = TEST_LONGER

/datum/unit_test/hilbert_sphere_release/Run()
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	if(!SShilbertshotel.storageTurf)
		SShilbertshotel.setup_storage_turf()
	var/turf/home = run_loc_floor_bottom_left
	var/obj/item/hilbertshotel/sphere = new(home)
	sphere.anchored = TRUE
	var/mob/living/carbon/human/guest = allocate(/mob/living/carbon/human, home)
	guest.mind_initialize()
	SShilbertshotel.user_data[guest.ckey] = list("room_number" = 6112, "template" = "Hotel Room", "status" = "idle")

	TEST_ASSERT(sphere.sendToNewRoom(6112, guest, "Hotel Room"), "sendToNewRoom вернул FALSE")
	var/area/hilbertshotel/room_area = get_area(guest)
	TEST_ASSERT(istype(room_area), "гость не попал в область отеля: [room_area?.type]")
	TEST_ASSERT_EQUAL(room_area.parentSphere, sphere, "область комнаты не привязана к сфере")

	guest.forceMove(home)
	qdel(sphere)
	TEST_ASSERT_NULL(room_area.parentSphere, "область комнаты держит удалённую сферу")
	SShilbertshotel.user_data -= guest.ckey
