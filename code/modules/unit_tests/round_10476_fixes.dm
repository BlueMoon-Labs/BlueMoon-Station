/// Выстрел из двух тяжёлых револьверов доводит отдачу до конца: оба револьвера падают из рук.
/datum/unit_test/dual_heavy_revolvers_drop_both/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/gun/ballistic/revolver/Exorcist/main = allocate(/obj/item/gun/ballistic/revolver/Exorcist)
	var/obj/item/gun/ballistic/revolver/Dies_Irae/offhand = allocate(/obj/item/gun/ballistic/revolver/Dies_Irae)
	user.put_in_active_hand(main)
	user.put_in_inactive_hand(offhand)
	TEST_ASSERT(main.chambered, "test premise: в основном револьвере должен быть патрон")

	main.process_fire(run_loc_floor_top_right, user)

	TEST_ASSERT_NULL(user.get_active_held_item(), "Основной револьвер остался в руке после вывиха")
	TEST_ASSERT_NULL(user.get_inactive_held_item(), "Второй револьвер остался в руке после вывиха")

/// Орган в мобе, ушедшем в nullspace (крио), не падает на проверке холода.
/datum/unit_test/organ_in_nullspace_mob_is_cold/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/organ/regenerative_core/legion/core = allocate(/obj/item/organ/regenerative_core/legion)
	core.forceMove(holder)
	holder.moveToNullspace()

	TEST_ASSERT(!core.is_cold(), "Орган без окружающего воздуха не должен считаться замороженным")

/// Метадоллары, слившиеся при создании в соседнюю пачку, не ставят таймер на удалённую пачку.
/datum/unit_test/metadollar_merge_on_spawn/Run()
	var/obj/item/stack/metadollar/first = allocate(/obj/item/stack/metadollar, run_loc_floor_bottom_left, 5)
	var/obj/item/stack/metadollar/second = new(run_loc_floor_bottom_left, 3)

	TEST_ASSERT(QDELETED(second), "test premise: вторая пачка должна влиться в первую")
	TEST_ASSERT_EQUAL(first.amount, 8, "Сумма пачки после слияния")

/// Владелец комнаты отеля, удалённый после выхода из неё, не держится списком комнат сферы.
/datum/unit_test/hilbert_hotel_deleted_owner_released
	priority = TEST_LONGER

/datum/unit_test/hilbert_hotel_deleted_owner_released/Run()
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	if(!SShilbertshotel.storageTurf)
		SShilbertshotel.setup_storage_turf()
	var/turf/home = run_loc_floor_bottom_left
	var/obj/item/hilbertshotel/sphere = allocate(/obj/item/hilbertshotel, home)
	sphere.anchored = TRUE
	var/mob/living/carbon/human/guest = new(home)
	guest.mind_initialize()
	SShilbertshotel.user_data[guest.ckey] = list("room_number" = 6116, "template" = "Hotel Room", "status" = "idle")
	TEST_ASSERT(sphere.sendToNewRoom(6116, guest, "Hotel Room"), "sendToNewRoom вернул FALSE")
	TEST_ASSERT(length(sphere.mob_dorms[guest]), "test premise: комната не записалась за владельцем")
	sphere.MobTransfer(guest, home)

	qdel(guest)
	TEST_ASSERT_NULL(sphere.mob_dorms[guest], "Удалённый владелец остался в mob_dorms")
	for(var/i in 1 to 20)
		if(!EXTERNAL_REFCOUNT(guest))
			break
		sleep(1)
	TEST_ASSERT_EQUAL(EXTERNAL_REFCOUNT(guest), 0, "Удалённый владелец комнаты не собирается")
