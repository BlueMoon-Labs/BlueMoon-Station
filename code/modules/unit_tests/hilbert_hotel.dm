/// Регрессия по прод-репорту (раунд 9726): повторный вход в комнату инфинити после её
/// консервации ломался, а сбои создания/восстановления молча отправляли игрока в пустой
/// резервный космос. Тест гоняет полный цикл: создание -> выход (консервация) ->
/// восстановление -> повторная консервация -> вход через promptAndCheckIn.
/datum/unit_test/hilbert_hotel_reentry
	priority = TEST_LONGER

/datum/unit_test/hilbert_hotel_reentry/proc/assert_sphere_at(obj/item/hilbertshotel/sphere, turf/expected, step_tag)
	var/turf/actual = get_turf(sphere)
	var/area/sphere_area = get_area(sphere)
	TEST_ASSERT(actual == expected, "[step_tag]: сфера уехала с [expected.x],[expected.y],[expected.z] на [actual ? "[actual.type] [actual.x],[actual.y],[actual.z] (область [sphere_area ? sphere_area.type : "null"], loc=[sphere.loc])" : "null"]")

/datum/unit_test/hilbert_hotel_reentry/proc/assert_in_room(mob/living/user, cycle_tag)
	var/turf/T = get_turf(user)
	TEST_ASSERT_NOTNULL(T, "[cycle_tag]: у моба нет турфа")
	var/area/A = get_area(user)
	TEST_ASSERT(istype(A, /area/hilbertshotel), "[cycle_tag]: моб не в области отеля, а в [A ? A.type : "null"] на [T.type] ([T.x],[T.y],[T.z])")
	TEST_ASSERT(!isspaceturf(T), "[cycle_tag]: моб стоит на космосе [T.type] ([T.x],[T.y],[T.z]) в области [A.type]")

/datum/unit_test/hilbert_hotel_reentry/proc/exit_room(obj/item/hilbertshotel/sphere, mob/living/guest, mob/living/partner, turf/home)
	sphere.MobTransfer(guest, home)
	if(get_area(partner) != get_area(guest))
		partner.forceMove(home) // партнёр без пуллинга мог остаться - выводим вручную, как выход через дверь

/datum/unit_test/hilbert_hotel_reentry/Run()
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	TEST_ASSERT(length(SShilbertshotel.hotel_map_list), "hotel_map_list пуст после prepare_rooms")
	TEST_ASSERT(SShilbertshotel.hotel_map_list["Apartment-Prison"], "шаблон Apartment-Prison не зарегистрирован")

	var/turf/home = run_loc_floor_bottom_left
	var/obj/item/hilbertshotel/sphere = allocate(/obj/item/hilbertshotel, home)
	// Станционные входы в инфинити - прикрученные ghostdojo-сферы; без якоря сфера
	// дрейфует в невесомости резервного z, пока загрузка шаблона спит в CHECK_TICK
	sphere.anchored = TRUE
	var/mob/living/carbon/human/guest = allocate(/mob/living/carbon/human, home)
	guest.mind_initialize()
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human, home)
	partner.mind_initialize()

	// user_data трогается в конце sendToNewRoom/tryStoredRoom по ckey
	SShilbertshotel.user_data[guest.ckey] = list("room_number" = 6111, "template" = "Apartment-Prison", "status" = "idle")

	if(!SShilbertshotel.storageTurf)
		SShilbertshotel.setup_storage_turf()
	TEST_ASSERT_NOTNULL(SShilbertshotel.storageTurf, "storageTurf не создался")

	// Создание комнаты: гость тащит партнёра пассивным грабом, как в репорте
	guest.start_pulling(partner, supress_message = TRUE)
	TEST_ASSERT(sphere.sendToNewRoom(6111, guest, "Apartment-Prison"), "sendToNewRoom вернул FALSE")
	assert_sphere_at(sphere, home, "после создания комнаты")
	assert_in_room(guest, "первый вход")
	TEST_ASSERT_NOTNULL(sphere.activeRooms["6111"], "комната не попала в activeRooms после создания")
	TEST_ASSERT(!length(sphere.rooms_in_flight), "rooms_in_flight не очистился после создания")

	var/area/hilbertshotel/room_area = get_area(guest)
	TEST_ASSERT_NOTNULL(room_area.reservation, "у области комнаты нет резервации")
	TEST_ASSERT_EQUAL(room_area.roomnumber, 6111, "линковка области: неверный номер комнаты")

	// Полный выход через хотел-дверь: комната консервируется
	exit_room(sphere, guest, partner, home)
	TEST_ASSERT_NOTNULL(sphere.storedRooms["6111"], "комната не законсервировалась после выхода последнего игрока")
	TEST_ASSERT(!sphere.activeRooms["6111"], "комната осталась в activeRooms после консервации")

	// Сток-объект должен лежать на storageTurf с полями для поиска
	var/obj/item/abstracthotelstorage/found_storage
	for(var/obj/item/abstracthotelstorage/S in SShilbertshotel.storageTurf)
		if(S.roomNumber == 6111 && S.parentSphere == sphere)
			found_storage = S
			break
	TEST_ASSERT_NOTNULL(found_storage, "сток-объект комнаты 6111 не найден на storageTurf")

	// Занятый номер отклоняет параллельный вход вместо создания комнаты-двойника
	TEST_ASSERT(sphere.room_op_begin(6111, null), "room_op_begin не взял свободный номер")
	TEST_ASSERT(!sphere.room_op_begin(6111, null), "room_op_begin взял номер повторно")
	TEST_ASSERT(!sphere.tryStoredRoom(6111, guest), "tryStoredRoom проигнорировал лок занятого номера")
	sphere.room_op_end(6111)

	// Повторный вход на тот же номер: комната восстанавливается со всеми вещами
	guest.start_pulling(partner, supress_message = TRUE)
	TEST_ASSERT(sphere.tryStoredRoom(6111, guest), "tryStoredRoom на консервированную комнату вернул FALSE")
	assert_sphere_at(sphere, home, "после восстановления комнаты")
	assert_in_room(guest, "повторный вход (восстановление)")
	assert_in_room(partner, "повторный вход партнёра (восстановление)")
	TEST_ASSERT_NOTNULL(sphere.activeRooms["6111"], "комната не вернулась в activeRooms")
	TEST_ASSERT(!sphere.storedRooms["6111"], "комната осталась в storedRooms после восстановления")
	TEST_ASSERT(!length(sphere.rooms_in_flight), "rooms_in_flight не очистился после восстановления")

	// Ещё один цикл выход/вход, теперь через полный promptAndCheckIn
	exit_room(sphere, guest, partner, home)
	TEST_ASSERT_NOTNULL(sphere.storedRooms["6111"], "вторая консервация не сработала")
	assert_sphere_at(sphere, home, "после второй консервации")
	TEST_ASSERT(sphere.promptAndCheckIn(guest, guest, 6111, "Apartment-Prison"), "promptAndCheckIn на второй цикл вернул FALSE")
	assert_in_room(guest, "третий вход")

	// Убираем мобов из комнаты до teardown, иначе qdel зоны с резервацией зашумит другие тесты
	exit_room(sphere, guest, partner, home)
