/**
 * Шаблон для зон и карт, которые не нужно создавать и грузить при старте мира,
 * но которые нужны при определённых условиях.
 *
 * Бэкпорт для виртуальных доменов битраннинга.
 */

/// Пока инициализируются атомы lazy-шаблона, корни модульных карт нужно ставить
/// в очередь, а не грузить асинхронно: иначе их ландмарки не успеют появиться
/// к моменту вызова load_map_items() у домена.
GLOBAL_VAR_INIT(lazy_template_atoms_initializing, FALSE)

/datum/lazy_template
	/// Резервации, созданные шаблоном; освобождаются при удалении датума.
	var/list/datum/turf_reservation/reservations = list()
	/// Если TRUE, каждая загрузка увеличивает индекс и грузит [map_name]_[index].
	var/uses_multiple_allocations = FALSE
	/// Ключ шаблона для кэша и отладки.
	var/key
	/// Каталог карт, который добавляется к имени файла.
	var/map_dir = "_maps/templates/lazy_templates"
	/// Имя файла карты без расширения.
	var/map_name
	/// Использовать PlaceOnTop вместо ChangeTurf.
	/// Старый загрузчик требует ChangeTurf для уже инициализированных резерваций.
	var/place_on_top = FALSE
	/// Тип запрашиваемой резервации турфов.
	var/turf_reservation_type = /datum/turf_reservation

/datum/lazy_template/New()
	reservations = list()
	..()

/datum/lazy_template/Destroy(force)
	if(!force)
		stack_trace("Something is trying to delete [type]")
		return QDEL_HINT_LETMELIVE

	QDEL_LIST(reservations)
	return ..()

/**
 * Загружает шаблон.
 * Возвращает резервацию, в которую была загружена карта.
 */
/datum/lazy_template/proc/lazy_load()
	RETURN_TYPE(/datum/turf_reservation)
	var/static/list/multiple_allocation_hash = list()

	var/load_path = "[map_dir]/[map_name].dmm"
	if(uses_multiple_allocations)
		var/times = multiple_allocation_hash[key] || 0
		times += 1
		multiple_allocation_hash[key] = times
		load_path = "[map_dir]/[map_name]_[times].dmm"

	if(!fexists(load_path))
		CRASH("lazy template [type] has an invalid load_path: '[load_path]', check directory and map name!")

	var/datum/parsed_map/parsed_template = load_map(
		file(load_path),
		measureOnly = TRUE,
	)
	if(isnull(parsed_template?.parsed_bounds))
		CRASH("Failed to cache lazy template for loading: '[key]'")

	var/list/bounds = parsed_template.parsed_bounds
	var/width = bounds[MAP_MAXX] - bounds[MAP_MINX] + 1
	var/height = bounds[MAP_MAXY] - bounds[MAP_MINY] + 1
	var/zdepth = bounds[MAP_MAXZ] - bounds[MAP_MINZ] + 1
	if(zdepth > 1)
		CRASH("lazy template [type] is [zdepth] z-levels tall, but this codebase can only reserve a single z-level per template!")

	var/datum/turf_reservation/reservation = SSmapping.RequestBlockReservation(
		width,
		height,
		null,
		turf_reservation_type,
	)
	if(!reservation)
		CRASH("Failed to reserve a block for lazy template: '[key]'")

	var/list/reserved_coords = reservation.bottom_left_coords
	var/turf/bottom_left = locate(reserved_coords[1], reserved_coords[2], reserved_coords[3])
	load_map(
		file(load_path),
		bottom_left.x,
		bottom_left.y,
		bottom_left.z,
		placeOnTop = place_on_top,
	)

	// Списки для общей загрузки.
	var/list/loaded_atom_movables = list()
	var/list/loaded_turfs = list()
	var/list/loaded_areas = list()
	var/list/obj/structure/cable/loaded_cables = list()
	var/list/obj/machinery/atmospherics/loaded_atmospherics = list()

	var/list/top_right_coords = reservation.top_right_coords
	var/turf/top_right = locate(top_right_coords[1], top_right_coords[2], top_right_coords[3])
	for(var/turf/turf as anything in block(bottom_left, top_right))
		loaded_turfs += turf
		loaded_areas |= get_area(turf)

		// Атом может находиться в contents нескольких турфов из-за размера и границ.
		for(var/thing in (turf.GetAllContents() - turf))
			if(istype(thing, /obj/structure/cable))
				loaded_cables += thing
			else if(istype(thing, /obj/machinery/atmospherics))
				loaded_atmospherics += thing
			loaded_atom_movables |= thing

	if(GLOB.map_modules_loaded)
		GLOB.lazy_template_atoms_initializing = TRUE

	SSatoms.InitializeAtoms(loaded_areas + loaded_atom_movables + loaded_turfs)

	if(GLOB.lazy_template_atoms_initializing)
		GLOB.lazy_template_atoms_initializing = FALSE
		// Грузим модули сейфхауса синхронно после инициализации атомов,
		// чтобы их ландмарки выхода и кэша успели зарегистрироваться.
		load_queued_map_modules()

	for(var/turf/turf as anything in reservation.reserved_turfs)
		if(QDELETED(turf))
			continue
		var/area/turf_area = get_area(turf)
		if(!turf_area)
			continue
		if(IS_DYNAMIC_LIGHTING(turf_area))
			turf.lighting_build_overlay()
		else
			turf.lighting_clear_overlay()
		turf.update_fullbright_overlay(turf_area)
		CHECK_TICK

	// Домены грузятся на зарезервированный z-уровень. Некоторые турфы
	// (например /turf/open/water) несут атмосферу Лаваленда и иначе
	// высосали бы воздух всего домена.
	for(var/turf/turf as anything in reservation.reserved_turfs)
		if(!istype(turf, /turf/open))
			continue
		var/turf/open/open_turf = turf
		var/area/turf_area = get_area(open_turf)
		if(!turf_area || !(turf_area.area_flags & VIRTUAL_AREA) || istype(turf_area, /area/space/virtual_domain))
			continue
		open_turf.planetary_atmos = FALSE
		open_turf.initial_gas_mix = OPENTURF_DEFAULT_ATMOS
		if(open_turf.air)
			open_turf.air.copy_from_turf(open_turf)
			open_turf.update_air_ref(AIR_REF_OPEN_TURF)

	connect_template_cables(loaded_cables)
	SSmachines.setup_template_powernets(loaded_cables)
	SSair.setup_template_machinery(loaded_atmospherics)

	reservations += reservation
	SEND_SIGNAL(src, COMSIG_LAZY_TEMPLATE_LOADED, loaded_atom_movables, loaded_turfs, loaded_areas)
	return reservation

/// Старый код кабелей обновляет иконку только при явных d1/d2.
/// Новые карты их не задают, оставляя кабели северными заглушками.
/// Восстанавливаем связи по соседним кабелям после загрузки шаблона.
/proc/connect_template_cables(list/cables)
	for(var/obj/structure/cable/cable as anything in cables)
		if(QDELETED(cable))
			continue
		// Чиним только нетронутые кабели карты. Узлы и кабели
		// с вручную заданными состояниями не трогаем.
		if(cable.d1 != 0 || cable.d2 != NORTH || cable.icon_state != "0-1")
			continue

		var/list/directions = list()
		for(var/direction in GLOB.cardinals)
			var/turf/neighbour = get_step(cable, direction)
			if(!neighbour)
				continue
			if(locate(/obj/structure/cable) in neighbour)
				directions += direction

		if(!length(directions))
			continue

		if(length(directions) == 1)
			cable.d1 = 0
			cable.d2 = directions[1]
		else
			cable.d1 = min(directions[1], directions[2])
			cable.d2 = max(directions[1], directions[2])

		cable.update_icon()
