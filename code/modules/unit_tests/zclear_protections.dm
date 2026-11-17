/// Затирка z-уровня не должна удалять порты стыковки. Force-qdel мобильного порта навсегда
/// выкидывает шаттл из SSshuttle.mobile (в логах: «couldn't find shuttle with id: exploration»),
/// после чего экипаж остаётся на руине без шаттла.
/datum/unit_test/zclear_keeps_docking_ports/Run()
	var/turf/port_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/docking_port/stationary/port = allocate(/obj/docking_port/stationary, port_turf)
	SSzclear.delete_atom(port)
	TEST_ASSERT(!QDELETED(port), "delete_atom удалил порт стыковки")
	qdel(port, TRUE)
	TEST_ASSERT(QDELETED(port), "тестовый порт не удалился принудительно")

/// Предметы внутри сумки/ПДА/контейнера не должны удаляться по отдельности: они уезжают
/// вместе с мобом при random_teleport_atom. Раньше clear_turf_atoms вызывал delete_atom для
/// каждого вложенного предмета, и у игрока оставались только надетые вещи и то, что в руках.
/datum/unit_test/zclear_preserves_nested_inventory/Run()
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	var/obj/item/toy/plush/keepsake = allocate(/obj/item/toy/plush)
	crew.equip_to_slot_or_del(bag, ITEM_SLOT_BACK)
	keepsake.forceMove(bag)
	TEST_ASSERT_EQUAL(bag.loc, crew, "сумка не надета на моба")
	TEST_ASSERT_EQUAL(keepsake.loc, bag, "предмет не лежит в сумке")
	TEST_ASSERT(SSzclear.is_nested_in_mob(keepsake), "предмет в сумке не считается вложенным в моба")
	SSzclear.delete_atom(keepsake)
	SSzclear.delete_atom(bag)
	TEST_ASSERT(!QDELETED(keepsake), "delete_atom удалил предмет из сумки")
	TEST_ASSERT(!QDELETED(bag), "delete_atom удалил надетую сумку")
	TEST_ASSERT_EQUAL(keepsake.loc, bag, "предмет выпал из сумки")

/// Уровень, зарезервированный temp_keep_z() под прилетающий шаттл, нельзя затирать.
/datum/unit_test/zclear_reserved_level_is_in_use/Run()
	//Несуществующий z гарантирует, что сработает именно проверка docking_levels,
	//а не случайный моб/шаттл на тестовом уровне.
	var/z_level = world.maxz + 100
	SSzclear.docking_levels |= z_level
	TEST_ASSERT(SSzclear.is_z_level_in_use(z_level), "зарезервированный уровень считается свободным")
	SSzclear.docking_levels -= z_level
	TEST_ASSERT(!SSzclear.is_z_level_in_use(z_level), "освобождённый уровень всё ещё считается занятым")
