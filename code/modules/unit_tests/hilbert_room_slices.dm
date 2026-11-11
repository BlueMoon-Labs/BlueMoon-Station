/// Загрузка комнаты кусками ставит ту же комнату, что и обычная загрузка шаблона.
/datum/unit_test/hilbert_room_sliced_load_matches
	priority = TEST_LONGER

/datum/unit_test/hilbert_room_sliced_load_matches/proc/room_signature(turf/corner, width, height)
	var/list/signature = list()
	for(var/dx in 0 to width - 1)
		for(var/dy in 0 to height - 1)
			var/turf/T = locate(corner.x + dx, corner.y + dy, corner.z)
			var/list/types = list()
			// Предметы не сравниваются: лут в шаблонах случайный
			for(var/obj/thing in T)
				if(istype(thing, /obj/structure) || istype(thing, /obj/machinery))
					types += "[thing.type]"
			sortTim(types, GLOBAL_PROC_REF(cmp_text_asc))
			signature += "[dx],[dy]:[T.type]:[T.loc.type]:[jointext(types, "|")]"
	return signature

/datum/unit_test/hilbert_room_sliced_load_matches/proc/uninitialized_atoms(turf/corner, width, height)
	. = 0
	for(var/turf/T as anything in block(corner, locate(corner.x + width - 1, corner.y + height - 1, corner.z)))
		if(!(T.flags_1 & INITIALIZED_1))
			.++
		for(var/atom/movable/thing as anything in T)
			if(!(thing.flags_1 & INITIALIZED_1))
				.++

/datum/unit_test/hilbert_room_sliced_load_matches/Run()
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	var/datum/map_template/hilbertshotel/room_template = SShilbertshotel.hotel_map_list["Apartment-Prison"]
	TEST_ASSERT_NOTNULL(room_template, "шаблон Apartment-Prison не зарегистрирован")
	TEST_ASSERT_NOTNULL(room_template.cached_map, "разбор шаблона не сохранился с инициализации")

	var/datum/turf_reservation/plain_block = SSmapping.RequestBlockReservation(room_template.width, room_template.height)
	var/datum/turf_reservation/sliced_block = SSmapping.RequestBlockReservation(room_template.width, room_template.height)
	TEST_ASSERT(plain_block && sliced_block, "не хватило резерваций под две комнаты")
	var/turf/plain_corner = locate(plain_block.bottom_left_coords[1], plain_block.bottom_left_coords[2], plain_block.bottom_left_coords[3])
	var/turf/sliced_corner = locate(sliced_block.bottom_left_coords[1], sliced_block.bottom_left_coords[2], sliced_block.bottom_left_coords[3])

	var/datum/parsed_map/cached = room_template.cached_map
	TEST_ASSERT(room_template.load(plain_corner), "обычная загрузка шаблона не прошла")
	TEST_ASSERT(room_template.load_room(sliced_corner), "загрузка кусками не прошла")
	TEST_ASSERT(room_template.cached_map == cached, "загрузка разобрала шаблон заново")

	var/list/plain = room_signature(plain_corner, room_template.width, room_template.height)
	var/list/sliced = room_signature(sliced_corner, room_template.width, room_template.height)
	var/list/mismatches = list()
	for(var/i in 1 to length(plain))
		if(plain[i] != sliced[i] && length(mismatches) < 5)
			mismatches += "[plain[i]] != [sliced[i]]"
	TEST_ASSERT(!length(mismatches), "комнаты разошлись: [jointext(mismatches, "; ")]")
	TEST_ASSERT_EQUAL(uninitialized_atoms(sliced_corner, room_template.width, room_template.height), 0, "после загрузки кусками остались неинициализированные атомы")
	TEST_ASSERT(room_template.last_room_yields > 0, "загрузка комнаты ни разу не уступила тик")

	for(var/turf/T as anything in block(plain_corner, locate(plain_corner.x + room_template.width - 1, plain_corner.y + room_template.height - 1, plain_corner.z)) + block(sliced_corner, locate(sliced_corner.x + room_template.width - 1, sliced_corner.y + room_template.height - 1, sliced_corner.z)))
		for(var/atom/movable/thing as anything in T)
			if(!istype(thing, /atom/movable/lighting_object))
				qdel(thing)
	qdel(plain_block)
	qdel(sliced_block)

/// Заселение через сферу грузит комнату кусками и приводит гостя в неё.
/datum/unit_test/hilbert_checkin_yields_tick
	priority = TEST_LONGER

/datum/unit_test/hilbert_checkin_yields_tick/Run()
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	if(!SShilbertshotel.storageTurf)
		SShilbertshotel.setup_storage_turf()
	var/turf/home = run_loc_floor_bottom_left
	var/obj/item/hilbertshotel/sphere = allocate(/obj/item/hilbertshotel, home)
	sphere.anchored = TRUE
	var/mob/living/carbon/human/guest = allocate(/mob/living/carbon/human, home)
	guest.mind_initialize()
	SShilbertshotel.user_data[guest.ckey] = list("room_number" = 6121, "template" = "Apartment-Prison", "status" = "idle")
	var/datum/map_template/hilbertshotel/room_template = SShilbertshotel.hotel_map_list["Apartment-Prison"]
	room_template.last_room_yields = 0

	TEST_ASSERT(sphere.sendToNewRoom(6121, guest, "Apartment-Prison"), "sendToNewRoom вернул FALSE")
	TEST_ASSERT(room_template.last_room_yields > 0, "заселение грузило комнату одним куском")
	var/area/hilbertshotel/room_area = get_area(guest)
	TEST_ASSERT(istype(room_area), "гость не в комнате, а в [room_area?.type]")
	TEST_ASSERT_EQUAL(room_area.roomnumber, 6121, "гость не в своей комнате")
	TEST_ASSERT_EQUAL(room_area.roomType, "Apartment-Prison", "у комнаты не тот шаблон")
	var/datum/turf_reservation/room = sphere.activeRooms["6121"]
	var/turf/landing = locate(room.bottom_left_coords[1] + room_template.landingZoneRelativeX, room.bottom_left_coords[2] + room_template.landingZoneRelativeY, room.bottom_left_coords[3])
	TEST_ASSERT(get_turf(guest) == landing, "гость приземлился не на точку входа шаблона")

	sphere.MobTransfer(guest, home)

/// Сферу или гостя удалили, пока комната грузилась: никто никуда не уехал, номер и резервация свободны.
/datum/unit_test/hilbert_checkin_aborts_when_gone
	priority = TEST_LONGER
	var/datum/map_template/hilbertshotel/unit_test_sleepy/template
	var/load_finished = FALSE
	var/load_result

/datum/unit_test/hilbert_checkin_aborts_when_gone/Destroy()
	if(template)
		SShilbertshotel.hotel_map_list -= template.name
		template = null
	return ..()

/datum/unit_test/hilbert_checkin_aborts_when_gone/proc/check_in(obj/item/hilbertshotel/sphere, room_number, mob/guest)
	load_result = sphere.sendToNewRoom(room_number, guest, template.name)
	load_finished = TRUE

/// Запускает заселение и возвращается, когда оно уснуло посреди загрузки
/datum/unit_test/hilbert_checkin_aborts_when_gone/proc/start_check_in(obj/item/hilbertshotel/sphere, room_number, mob/guest)
	load_finished = FALSE
	load_result = null
	INVOKE_ASYNC(src, PROC_REF(check_in), sphere, room_number, guest)
	return !load_finished

/datum/unit_test/hilbert_checkin_aborts_when_gone/proc/wait_check_in()
	for(var/i in 1 to 300)
		if(load_finished)
			return TRUE
		sleep(1)
	return FALSE

/datum/unit_test/hilbert_checkin_aborts_when_gone/Run()
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	if(!SShilbertshotel.storageTurf)
		SShilbertshotel.setup_storage_turf()
	template = new
	SShilbertshotel.hotel_map_list[template.name] = template
	var/turf/home = run_loc_floor_bottom_left
	var/reservations_before = length(SSmapping.turf_reservations)

	var/obj/item/hilbertshotel/doomed_sphere = allocate(/obj/item/hilbertshotel, home)
	doomed_sphere.anchored = TRUE
	var/mob/living/carbon/human/guest = allocate(/mob/living/carbon/human, home)
	guest.mind_initialize()
	TEST_ASSERT(start_check_in(doomed_sphere, 6131, guest), "заселение не уснуло, удалить сферу посреди загрузки нечем")
	qdel(doomed_sphere)
	TEST_ASSERT(wait_check_in(), "заселение к удалённой сфере не закончилось")
	TEST_ASSERT(!load_result, "заселение к удалённой сфере прошло")
	TEST_ASSERT(get_turf(guest) == home, "гость уехал через удалённую сферу в [get_area(guest)]")
	TEST_ASSERT(!length(doomed_sphere.activeRooms), "удалённая сфера завела активную комнату")
	TEST_ASSERT(!length(doomed_sphere.linked_room_areas), "удалённая сфера снова привязала к себе комнату")
	TEST_ASSERT(!doomed_sphere.rooms_in_flight["6131"], "номер удалённой сферы остался занятым")
	TEST_ASSERT_EQUAL(length(SSmapping.turf_reservations), reservations_before, "резервация комнаты удалённой сферы не освобождена")

	var/obj/item/hilbertshotel/sphere = allocate(/obj/item/hilbertshotel, home)
	sphere.anchored = TRUE
	var/mob/living/carbon/human/doomed_guest = allocate(/mob/living/carbon/human, home)
	doomed_guest.mind_initialize()
	TEST_ASSERT(start_check_in(sphere, 6132, doomed_guest), "заселение не уснуло, удалить гостя посреди загрузки нечем")
	qdel(doomed_guest)
	TEST_ASSERT(wait_check_in(), "заселение удалённого гостя не закончилось")
	TEST_ASSERT(!load_result, "заселение удалённого гостя прошло")
	TEST_ASSERT(!length(sphere.activeRooms), "для удалённого гостя завелась активная комната")
	TEST_ASSERT(!length(sphere.mob_dorms), "удалённый гость записан во владельцы комнаты")
	TEST_ASSERT(!sphere.rooms_in_flight["6132"], "номер остался занятым после удаления гостя")
	TEST_ASSERT_EQUAL(length(SSmapping.turf_reservations), reservations_before, "резервация комнаты удалённого гостя не освобождена")

/// Комната отеля, загрузка которой сперва засыпает: окно, в котором сфера или гость успевают исчезнуть
/datum/map_template/hilbertshotel/unit_test_sleepy
	name = "Unit Test Sleepy Room"

/datum/map_template/hilbertshotel/unit_test_sleepy/load_room(turf/T)
	sleep(1)
	return ..()
