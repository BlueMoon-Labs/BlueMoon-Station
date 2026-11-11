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
