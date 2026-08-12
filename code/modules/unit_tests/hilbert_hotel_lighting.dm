/// Прод-репорт (раунд 9748): свет в комнатах инфинити-дормов "секционный" при создании,
/// на остальной площади комнаты чёрный, хотя сами лампы (спрайты/оверлейный канал) светят.
/// Комнаты грузятся шаблоном на резервный z (в проде тот же z, что транзиты шаттлов),
/// уже помеченный lighting_initialized, причём блоки резерваций многократно
/// переиспользуются через Reserve/Release с CHANGETURF_SKIP (без переноса lighting-стейта).
/// Тест зеркалит сценарий с рециклингом и проверяет инварианты: у каждого динамического
/// турфа комнаты есть lighting_object, корнеры АКТИВНЫ и РАЗДЕЛЕНЫ с соседями (один
/// датум на стык - иначе свет рвётся на квадратные секции), лампы не запаркованы,
/// после дренажа очередей комната светится.
/datum/unit_test/hilbert_hotel_lighting
	priority = TEST_LONGER

/datum/unit_test/hilbert_hotel_lighting/proc/audit_room(area/hilbertshotel/room_area, cycle_tag)
	var/total_dynamic = 0
	var/missing_objects = 0
	var/inactive_corner_turfs = 0
	var/shared_corner_breaks = 0
	var/ghost_objects = 0
	var/lit_turfs = 0
	var/list/bad_desc = list()
	for(var/turf/T in room_area)
		// Призраки: на тайле не должно лежать НИ ОДНОГО lighting_object, кроме привязанного
		// к турфу. Утащенный в сток и высыпанный обратно оверлей прошлой эпохи рендерит
		// протухшую тьму на lighting-плейне поверх живого = "секционный" свет.
		for(var/atom/movable/lighting_object/stray in T)
			if(stray != T.lighting_object)
				ghost_objects++
				if(bad_desc.len < 12)
					bad_desc += "ghost:[T.type] ([T.x],[T.y],[T.z])"
		if(!IS_DYNAMIC_LIGHTING(T))
			continue
		total_dynamic++
		if(!T.lighting_object)
			missing_objects++
			if(bad_desc.len < 12)
				bad_desc += "no_obj:[T.type] ([T.x],[T.y],[T.z])"
			continue
		if(!T.lc_topright || !T.lc_topright.active || !T.lc_bottomleft || !T.lc_bottomleft.active)
			inactive_corner_turfs++
			if(bad_desc.len < 12)
				bad_desc += "inactive:[T.type] ([T.x],[T.y],[T.z])"
		// Шаринг корнеров: стык двух соседних динамических турфов обязан быть ОДНИМ датумом.
		// Приватные дубликаты дают плоскую позонную заливку с резкими швами ("секционный" свет).
		var/turf/east_neighbor = get_step(T, EAST)
		if(east_neighbor?.lighting_object && IS_DYNAMIC_LIGHTING(east_neighbor) && east_neighbor.loc == room_area)
			if(T.lc_topright != east_neighbor.lc_topleft || T.lc_bottomright != east_neighbor.lc_bottomleft)
				shared_corner_breaks++
				if(bad_desc.len < 12)
					bad_desc += "seam_E:[T.type] ([T.x],[T.y],[T.z])"
		var/turf/north_neighbor = get_step(T, NORTH)
		if(north_neighbor?.lighting_object && IS_DYNAMIC_LIGHTING(north_neighbor) && north_neighbor.loc == room_area)
			if(T.lc_topright != north_neighbor.lc_bottomright || T.lc_topleft != north_neighbor.lc_bottomleft)
				shared_corner_breaks++
				if(bad_desc.len < 12)
					bad_desc += "seam_N:[T.type] ([T.x],[T.y],[T.z])"
		if(T.luminosity)
			lit_turfs++

	var/lamps = 0
	var/lamps_with_source = 0
	var/lamps_parked = 0
	for(var/obj/machinery/light/L in room_area)
		lamps++
		if(L.light)
			lamps_with_source++
		if(L in GLOB.lighting_deferred_atoms)
			lamps_parked++

	var/diag = "[cycle_tag]: турфов=[total_dynamic], без объекта=[missing_objects], призраков=[ghost_objects], неактивные корнеры=[inactive_corner_turfs], швы шаринга=[shared_corner_breaks], светится=[lit_turfs], ламп=[lamps] (src=[lamps_with_source], park=[lamps_parked]); [bad_desc.Join("; ")]"

	TEST_ASSERT(total_dynamic, "в комнате нет динамических турфов - шаблон изменился? [diag]")
	TEST_ASSERT_EQUAL(missing_objects, 0, "у части турфов нет lighting_object: [diag]")
	TEST_ASSERT_EQUAL(ghost_objects, 0, "на тайлах комнаты лежат чужие lighting_object-призраки: [diag]")
	TEST_ASSERT_EQUAL(inactive_corner_turfs, 0, "у части турфов неактивные корнеры: [diag]")
	TEST_ASSERT_EQUAL(shared_corner_breaks, 0, "порван шаринг корнеров между соседями: [diag]")
	if(lamps)
		TEST_ASSERT_EQUAL(lamps_parked, 0, "источники ламп запаркованы на инициализированном z: [diag]")
		TEST_ASSERT(lamps_with_source, "ни у одной лампы нет light-датума: [diag]")
		TEST_ASSERT(lit_turfs, "после дренажа ни один турф комнаты не светится: [diag]")
	return TRUE

/datum/unit_test/hilbert_hotel_lighting/Run()
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	TEST_ASSERT(length(SShilbertshotel.hotel_map_list), "hotel_map_list пуст после prepare_rooms")
	if(!SShilbertshotel.storageTurf)
		SShilbertshotel.setup_storage_turf()

	// Прогрев: резервный z существует и помечен как прошедший фоновый инит (прод-состояние)
	var/datum/turf_reservation/warmup = SSmapping.RequestBlockReservation(3, 3)
	TEST_ASSERT_NOTNULL(warmup, "не удалось получить прогревочную резервацию")
	var/warm_z = warmup.bottom_left_coords[3]
	var/datum/space_level/warm_level = SSmapping.get_level(warm_z)
	var/old_warm_init = warm_level.lighting_initialized
	warm_level.lighting_initialized = TRUE

	var/turf/home = run_loc_floor_bottom_left
	var/obj/item/hilbertshotel/sphere = allocate(/obj/item/hilbertshotel, home)
	sphere.anchored = TRUE
	var/mob/living/carbon/human/guest = allocate(/mob/living/carbon/human, home)
	guest.mind_initialize()
	SShilbertshotel.user_data[guest.ckey] = list("room_number" = 7222, "template" = "Hotel Room", "status" = "idle")

	// Прод-условие: блок резервации многократно переработан (транзиты шаттлов на том же z
	// живут через Reserve/Release с CHANGETURF_SKIP). Гоняем два цикла транзитного размера
	// и отпускаем - комната ляжет на переиспользованные турфы со стёртым lighting-стейтом.
	var/datum/map_template/hilbertshotel/room_template = SShilbertshotel.hotel_map_list["Hotel Room"]
	var/list/recycled_coords
	for(var/cycle in 1 to 2)
		var/datum/turf_reservation/churn = SSmapping.RequestBlockReservation(room_template.width, room_template.height, warm_z, /datum/turf_reservation/transit)
		if(churn)
			recycled_coords = churn.bottom_left_coords.Copy()
			qdel(churn)

	// Цикл 1: свежая комната
	TEST_ASSERT(sphere.sendToNewRoom(7222, guest, "Hotel Room"), "sendToNewRoom (цикл 1) вернул FALSE")
	var/area/hilbertshotel/room_area = get_area(guest)
	TEST_ASSERT(istype(room_area), "гость не в области отеля (цикл 1), а в [room_area ? room_area.type : "null"]")
	var/turf/room_turf = get_turf(guest)
	var/overlap = recycled_coords && room_turf.z == recycled_coords[3] ? "resv_overlap([recycled_coords[1]],[recycled_coords[2]] vs [room_area.reservation ? room_area.reservation.bottom_left_coords[1] : "?"],[room_area.reservation ? room_area.reservation.bottom_left_coords[2] : "?"])" : "no_overlap_info"
	drain_lighting_queues_snapshot()
	audit_room(room_area, "цикл 1 ([overlap])")

	// Координаты блока комнаты - после консервации проверим, что освобождённые турфы чистые
	var/list/room_bl = room_area.reservation.bottom_left_coords.Copy()
	var/list/room_tr = room_area.reservation.top_right_coords.Copy()

	// Выход: комната консервируется, резервация освобождается
	sphere.MobTransfer(guest, home)
	TEST_ASSERT_NOTNULL(sphere.storedRooms["7222"], "комната не законсервировалась после выхода")

	// Сток не должен красть оверлеи света вместе с мебелью
	var/obj/item/abstracthotelstorage/storage_obj
	for(var/obj/item/abstracthotelstorage/S in SShilbertshotel.storageTurf)
		if(S.roomNumber == 7222 && S.parentSphere == sphere)
			storage_obj = S
			break
	TEST_ASSERT_NOTNULL(storage_obj, "сток-объект комнаты 7222 не найден на storageTurf")
	var/stolen_overlays = 0
	for(var/atom/movable/lighting_object/stray in storage_obj)
		stolen_overlays++
	TEST_ASSERT_EQUAL(stolen_overlays, 0, "storeRoom утащил [stolen_overlays] lighting_object в сток - при восстановлении они лягут на тайлы призраками устаревшей тьмы")

	// Освобождённый блок не должен хранить призрачные оверлеи под следующего жильца
	var/released_ghosts = 0
	for(var/turf/released as anything in block(locate(room_bl[1], room_bl[2], room_bl[3]), locate(room_tr[1], room_tr[2], room_tr[3])))
		for(var/atom/movable/lighting_object/stray in released)
			released_ghosts++
	TEST_ASSERT_EQUAL(released_ghosts, 0, "после освобождения резервации на блоке осталось [released_ghosts] lighting_object-призраков")

	// Цикл 2: восстановление на переработанный блок (второй прод-путь создания)
	TEST_ASSERT(sphere.tryStoredRoom(7222, guest), "tryStoredRoom (цикл 2) вернул FALSE")
	room_area = get_area(guest)
	TEST_ASSERT(istype(room_area), "гость не в области отеля (цикл 2), а в [room_area ? room_area.type : "null"]")
	drain_lighting_queues_snapshot()
	audit_room(room_area, "цикл 2 (restore)")

	// Вывод гостя до teardown
	sphere.MobTransfer(guest, home)
	warm_level.lighting_initialized = old_warm_init
	qdel(warmup)
