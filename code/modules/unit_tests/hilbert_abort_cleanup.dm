/// Сорванное заселение уносит мебель и мобов шаблона, а игроков на клетках резервации не трогает.
/datum/unit_test/hilbert_abort_cleanup

/datum/unit_test/hilbert_abort_cleanup/Run()
	var/obj/item/hilbertshotel/sphere = allocate(/obj/item/hilbertshotel, run_loc_floor_bottom_left)
	var/datum/turf_reservation/room = SSmapping.RequestBlockReservation(3, 3)
	TEST_ASSERT_NOTNULL(room, "резервация не выдана")
	var/turf/spot = room.reserved_turfs[1]
	var/obj/item/stack/sheet/metal/furniture = new(spot)
	var/mob/living/simple_animal/mouse/template_pet = new(spot)
	var/mob/living/carbon/human/player = allocate(/mob/living/carbon/human, spot)
	player.mind_initialize()
	TEST_ASSERT(sphere.room_op_begin(6141, null), "номер не взялся")

	sphere.abort_room_load(6141, room)
	TEST_ASSERT(QDELETED(furniture), "мебель шаблона осталась в освобождённой резервации")
	TEST_ASSERT(QDELETED(template_pet), "моб шаблона остался в освобождённой резервации")
	TEST_ASSERT(!QDELETED(player), "сорванное заселение удалило игрока")
	TEST_ASSERT(!sphere.rooms_in_flight["6141"], "номер остался занятым")
	player.forceMove(run_loc_floor_bottom_left)
