/// Гравген станции собран из частей, а консоли, доплер и тренажёры стоят рабочими подтипами, не абстрактной базой или пустой заглушкой.
/datum/unit_test/station_machines_not_abstract
	requires_full_map = TRUE

/datum/unit_test/station_machines_not_abstract/Run()
	for(var/obj/machinery/gravity_generator/main/generator as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/gravity_generator/main))
		if(!is_station_level(generator.z))
			continue
		TEST_ASSERT(generator.connected_parts(), "Гравген без частей на ([generator.x],[generator.y],[generator.z]): [length(generator.parts)] из 8")

	var/list/abstract_types = typecacheof(list(
		/obj/machinery/computer/upload,
		/obj/machinery/computer/bookmanagement,
		/obj/machinery/doppler_array,
		/obj/structure/weightmachine,
		/obj/structure/billboard,
		/obj/item/reagent_containers/cup/glass/coffee,
		/obj/item/gun/ballistic/shotgun/doublebarrel,
	), only_root_path = TRUE)
	var/list/abstract_found = list()
	for(var/obj/thing in world)
		if(abstract_types[thing.type])
			abstract_found += "[thing.type] ([thing.x],[thing.y],[thing.z])"
	TEST_ASSERT(!length(abstract_found), "Абстрактные типы на карте: [abstract_found.Join(", ")]")

/// На портированных картах есть снаряжение ролей BlueMoon и рабочие машины вместо tg-шных заглушек.
/datum/unit_test/ported_map_bluemoon_equipment
	requires_full_map = TRUE

/datum/unit_test/ported_map_bluemoon_equipment/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/required = list(
		/obj/structure/closet/secure_closet/blueshield = 0,
		/obj/machinery/vending/wardrobe/blueshield_wardrobe = 0,
		/obj/structure/closet/secure_closet/ntr = 0,
		/obj/structure/closet/secure_closet/bridgesec = 0,
		/obj/machinery/vending/wardrobe/bridgeofficer_wardrobe = 0,
		/obj/structure/closet/secure_closet/brigdoc = 0,
		/obj/machinery/vending/brigdoc_vendomat = 0,
		/obj/machinery/vending/wardrobe/cap_wardrobe = 0,
		/obj/structure/closet/secure_closet/hosnew = 0,
		/obj/machinery/computer/upload/ai = 0,
		/obj/machinery/computer/upload/borg = 0,
		/obj/machinery/doppler_array/research/science = 0,
		/obj/machinery/atmospherics/miner/nitrogen = 0,
		/obj/machinery/atmospherics/miner/oxygen = 0,
		/obj/machinery/atmospherics/miner/carbon_dioxide = 0,
		/obj/machinery/atmospherics/miner/toxins = 0,
		/obj/machinery/atmospherics/miner/n2o = 0,
		/obj/machinery/clonepod = 0,
		/obj/machinery/computer/cloning = 0,
		/obj/machinery/dna_scannernew = 0,
		/obj/machinery/sleeper = 0,
		/obj/machinery/plantgenes = 0,
		/obj/machinery/smartfridge/disks = 0,
		/obj/item/ai_module/reset = 0,
		/obj/item/ai_module/reset/purge = 0,
		/obj/item/ai_module/core/full/asimov = 0,
	)
	for(var/obj/thing in world)
		if(!isnull(required[thing.type]) && is_station_level(thing.z))
			required[thing.type]++
	var/list/missing = list()
	for(var/wanted_type in required)
		if(!required[wanted_type])
			missing += "[wanted_type]"
	TEST_ASSERT(!length(missing), "На станции нет: [missing.Join(", ")]")

	var/list/idle_timers = list()
	for(var/obj/machinery/door_timer/timer as anything in GLOB.celltimers_list)
		if(is_station_level(timer.z) && !length(timer.targets))
			idle_timers += "[timer.name] ([timer.x],[timer.y],[timer.z])"
	TEST_ASSERT(!length(idle_timers), "Таймеры камер без дверей: [idle_timers.Join(", ")]")

	for(var/chamber_type in list(/area/engineering/supermatter, /area/science/mixing/chamber))
		var/has_alarm = FALSE
		for(var/area/chamber as anything in GLOB.all_areas)
			if(chamber.type == chamber_type && length(chamber.airalarms))
				has_alarm = TRUE
				break
		TEST_ASSERT(has_alarm, "У камеры [chamber_type] нет своей алармы")

	var/area/freezer = GLOB.areas_by_type[/area/science/mixing/freezer]
	if(freezer)
		TEST_ASSERT(length(freezer.airalarms), "У камеры [freezer.type] нет своей алармы")

/// На портированных картах есть то, что несут основные карты: рефиллер медипенов, гражданский синди-гардероб, набор Авангарда у его точек старта, колорматы и кинк-вендоры.
/datum/unit_test/ported_map_bluemoon_kits
	requires_full_map = TRUE

/datum/unit_test/ported_map_bluemoon_kits/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/problems = list()
	var/list/minimum_counts = list(
		/obj/machinery/medipen_refiller = 1,
		/obj/machinery/vending/wardrobe/syndie_wardrobe/civil = 1,
		/obj/machinery/gear_painter = 2,
		/obj/machinery/vending/kink = 3,
	)
	for(var/machine_type in minimum_counts)
		var/found = 0
		for(var/obj/machinery/machine as anything in SSmachines.get_machines_by_type_and_subtypes(machine_type))
			if(is_station_level(machine.z))
				found++
		if(found < minimum_counts[machine_type])
			problems += "[machine_type]: [found] из [minimum_counts[machine_type]]"

	var/list/spawn_areas = GLOB.unit_test_start_landmark_areas[/obj/effect/landmark/start/expeditor]
	if(!length(spawn_areas))
		problems += "нет точек старта Авангарда"
	else
		var/list/kit_found = list(
			/obj/structure/closet/secure_closet/vanguard = FALSE,
			/obj/machinery/ammo_workbench = FALSE,
			/obj/machinery/vanguard/contraband = FALSE,
			/obj/machinery/computer/vanguard_control/contraband = FALSE,
			/obj/machinery/recharger = FALSE,
			/obj/machinery/bountyvend/plus = FALSE,
		)
		var/list/area_types = list()
		for(var/area/spawn_area as anything in spawn_areas)
			area_types += "[spawn_area.type]"
			for(var/obj/thing in spawn_area)
				for(var/kit_type in kit_found)
					if(istype(thing, kit_type))
						kit_found[kit_type] = TRUE
		var/list/kit_missing = list()
		for(var/kit_type in kit_found)
			if(!kit_found[kit_type])
				kit_missing += "[kit_type]"
		if(length(kit_missing))
			problems += "у точек старта Авангарда ([area_types.Join(", ")]) нет [kit_missing.Join(", ")]"
	TEST_ASSERT(!length(problems), "На станции не хватает: [problems.Join("; ")]")

/// В охране портированных карт есть операционная, как на Box, Meta и Delta: стол и консоль операций при нём.
/datum/unit_test/ported_map_security_surgery
	requires_full_map = TRUE

/datum/unit_test/ported_map_security_surgery/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	for(var/obj/machinery/computer/operating/console as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/operating))
		if(console.table && is_station_level(console.z) && istype(get_area(console), /area/security))
			return
	TEST_FAIL("В охране нет операционного стола с консолью операций")

/// Камеры портированных карт висят на стене: у tg dir камеры - сторона стены, у нас - сторона взгляда.
/datum/unit_test/ported_map_cameras_on_walls
	requires_full_map = TRUE

/datum/unit_test/ported_map_cameras_on_walls/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/mount_side = list("[NORTH]" = SOUTH, "[SOUTH]" = NORTH, "[EAST]" = WEST, "[WEST]" = EAST, "[SOUTHEAST]" = NORTH, "[SOUTHWEST]" = SOUTH, "[NORTHEAST]" = WEST, "[NORTHWEST]" = EAST)
	var/list/hanging = list()
	for(var/obj/machinery/camera/camera as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/camera))
		if(!is_station_level(camera.z) || camera.pixel_x || camera.pixel_y)
			continue
		var/turf/mount = get_step(camera, mount_side["[camera.dir]"])
		var/mounted = isclosedturf(mount)
		for(var/obj/support in mount)
			if(support.density || istype(support, /obj/machinery/door))
				mounted = TRUE
				break
		if(!mounted)
			hanging += "[camera.c_tag || camera.name] ([camera.x],[camera.y],[camera.z]) dir [camera.dir]"
	TEST_ASSERT(!length(hanging), "Камеры без стены за спиной: [hanging.Join(", ")]")

/// Внешний шлюз порта, выходящий в космос, безвоздушный туннель или наружу планеты, держит маленький вентилятор, как на родных картах.
/datum/unit_test/ported_map_external_airlocks_have_fans
	requires_full_map = TRUE

/datum/unit_test/ported_map_external_airlocks_have_fans/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/bare = list()
	for(var/obj/machinery/door/airlock/external/door as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/door/airlock/external))
		if(!is_station_level(door.z) || !door_faces_outside(door))
			continue
		if(!(locate(/obj/structure/fans/tiny) in door.loc))
			bare += "[door.name] ([door.x],[door.y],[door.z])"
	TEST_ASSERT(!length(bare), "Внешние шлюзы без маленького вентилятора: [bare.Join(", ")]")

/// Ставни и бронедвери портов, сами отделяющие станцию от космоса, стоят на маленьком вентиляторе; продувы инсинераторов и казни не в счёт.
/datum/unit_test/ported_map_space_shutters_have_fans
	requires_full_map = TRUE

/datum/unit_test/ported_map_space_shutters_have_fans/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/vent_doors = typecacheof(list(
		/obj/machinery/door/poddoor/incinerator_toxmix,
		/obj/machinery/door/poddoor/incinerator_atmos_main,
		/obj/machinery/door/poddoor/incinerator_atmos_aux,
	))
	var/list/vent_areas = typecacheof(list(/area/security/execution, /area/maintenance/disposal/incinerator))
	var/list/bare = list()
	for(var/obj/machinery/door/poddoor/door as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/door/poddoor))
		var/area/door_area = get_area(door)
		if(vent_doors[door.type] || vent_areas[door_area.type] || door_area.outdoors || !is_station_level(door.z))
			continue
		var/turf/open/door_turf = door.loc
		if(!istype(door_turf) || isspaceturf(door_turf) || door_turf.initial_gas_mix == AIRLESS_ATMOS)
			continue
		if((locate(/obj/structure/window) in door_turf) || (locate(/obj/structure/grille) in door_turf))
			continue
		if(door_faces_outside(door) && !(locate(/obj/structure/fans/tiny) in door.loc))
			bare += "[door.name] ([door.x],[door.y],[door.z])"
	TEST_ASSERT(!length(bare), "Ставни наружу без маленького вентилятора: [bare.Join(", ")]")

/datum/unit_test/proc/door_faces_outside(obj/machinery/door/door)
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(door, direction)
		if(!neighbor || (locate(/obj/structure/window) in neighbor) || (locate(/obj/structure/grille) in neighbor))
			continue
		var/area/neighbor_area = neighbor.loc
		if(isspaceturf(neighbor) || neighbor_area.outdoors || istype(neighbor_area, /area/space))
			return TRUE
		if(isopenturf(neighbor))
			var/turf/open/open_neighbor = neighbor
			if(open_neighbor.initial_gas_mix == AIRLESS_ATMOS)
				return TRUE
	return FALSE

/// Концы скамей и угловых диванов порта стоят как на родных картах: left на западе или юге, при dir 8 на севере.
/datum/unit_test/ported_map_seat_ends_match_natives
	requires_full_map = TRUE

/datum/unit_test/ported_map_seat_ends_match_natives/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/flipped = list()
	for(var/obj/structure/chair/seat in world)
		if(!is_station_level(seat.z))
			continue
		var/side
		if(istype(seat, /obj/structure/chair/pew/left) || istype(seat, /obj/structure/chair/sofa/corp/left))
			side = "left"
		else if(istype(seat, /obj/structure/chair/pew/right) || istype(seat, /obj/structure/chair/sofa/corp/right))
			side = "right"
		else
			continue
		var/family = istype(seat, /obj/structure/chair/pew) ? /obj/structure/chair/pew : /obj/structure/chair/sofa/corp
		var/plus_dir = (seat.dir & (NORTH|SOUTH)) ? EAST : NORTH
		var/at_plus = locate(family) in get_step(seat, plus_dir)
		var/at_minus = locate(family) in get_step(seat, REVERSE_DIR(plus_dir))
		if(!at_plus == !at_minus)
			continue
		var/is_plus_end = !at_plus
		var/wanted = (is_plus_end == (seat.dir == WEST)) ? "left" : "right"
		if(wanted != side)
			flipped += "[seat.type] ([seat.x],[seat.y],[seat.z]) dir [seat.dir]"
	TEST_ASSERT(!length(flipped), "Концы скамей перепутаны: [flipped.Join(", ")]")

/// Фабрикаторы робототехники синхронизируются с R&D: sync() ищет консоль в семи тайлах.
/datum/unit_test/robotics_fabricators_sync_research
	requires_full_map = TRUE

/datum/unit_test/robotics_fabricators_sync_research/Run()
	var/list/unsynced = list()
	for(var/obj/machinery/mecha_part_fabricator/fabricator as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/mecha_part_fabricator))
		if(!is_station_level(fabricator.z) || !istype(get_area(fabricator), /area/science/robotics))
			continue
		if(!fabricator.sync(ignore_timer = TRUE, is_silent = TRUE))
			unsynced += "([fabricator.x],[fabricator.y],[fabricator.z])"
	TEST_ASSERT(!length(unsynced), "Фабрикаторы робототехники без R&D-консоли рядом: [unsynced.Join(", ")]")

/// В науке портированных карт с начала раунда есть пластик для Problem Computer.
/datum/unit_test/ported_map_science_plastic
	requires_full_map = TRUE

/datum/unit_test/ported_map_science_plastic/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	for(var/obj/item/stack/sheet/plastic/sheet in world)
		if(is_station_level(sheet.z) && istype(get_area(sheet), /area/science))
			return
	TEST_FAIL("В науке нет стартового пластика")

/// Каждый станционный z получает свой номер в персистенсе мусора, в том числе этажи многоэтажной карты одним файлом.
/datum/unit_test/station_z_index_covers_station_levels
	requires_full_map = TRUE

/datum/unit_test/station_z_index_covers_station_levels/Run()
	var/list/seen_indexes = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/index = SSmapping.z_to_station_z_index["[station_z]"]
		TEST_ASSERT_NOTNULL(index, "Станционный z=[station_z] без номера в персистенсе: мусор этажа сохраняется без ключа и теряется")
		TEST_ASSERT(!seen_indexes["[index]"], "Номер [index] выдан двум станционным z")
		seen_indexes["[index]"] = TRUE

/// Шаттл прибытия встаёт в док карты: без него латеджойну некуда спавнить.
/datum/unit_test/arrivals_shuttle_docked
	requires_full_map = TRUE

/datum/unit_test/arrivals_shuttle_docked/Run()
	var/obj/docking_port/stationary/arrivals_dock
	for(var/obj/docking_port/stationary/dock as anything in SSshuttle.stationary)
		if(dock.shuttle_id == "arrivals_stationary")
			arrivals_dock = dock
			break
	if(!arrivals_dock)
		return
	TEST_ASSERT_NOTNULL(SSshuttle.arrivals, "Шаттл прибытия не встал в док ([arrivals_dock.x],[arrivals_dock.y],[arrivals_dock.z])")

/// Шлюзы станции у пристыкованного шаттла прибытия выходят в его двери, а не в стену.
/datum/unit_test/arrivals_airlocks_meet_shuttle_doors
	requires_full_map = TRUE

/datum/unit_test/arrivals_airlocks_meet_shuttle_doors/Run()
	var/obj/docking_port/mobile/shuttle = SSshuttle.arrivals
	var/obj/docking_port/stationary/dock = SSshuttle.getDock("arrivals_stationary")
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS) || !shuttle || !dock)
		return
	// Пустой шаттл прибытия курсирует, поэтому его клетки переносятся на док тем же поворотом, что и при стыковке.
	var/list/from_axes = port_axes(shuttle.dir)
	var/list/to_axes = port_axes(dock.dir)
	var/list/landing_to_shuttle = list()
	for(var/turf/shuttle_turf as anything in shuttle.return_turfs())
		var/dx = shuttle_turf.x - shuttle.x
		var/dy = shuttle_turf.y - shuttle.y
		var/along = dx * from_axes[1] + dy * from_axes[2]
		var/across = dy * from_axes[1] - dx * from_axes[2]
		var/turf/landing = locate(dock.x + along * to_axes[1] - across * to_axes[2], dock.y + along * to_axes[2] + across * to_axes[1], dock.z)
		landing_to_shuttle[landing] = shuttle_turf
	var/list/blocked = list()
	for(var/turf/landing as anything in landing_to_shuttle)
		if(!isclosedturf(landing_to_shuttle[landing]))
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/neighbour = get_step(landing, direction)
			if(neighbour && isnull(landing_to_shuttle[neighbour]) && (locate(/obj/machinery/door/airlock) in neighbour))
				blocked += "([neighbour.x],[neighbour.y],[neighbour.z])"
	TEST_ASSERT(!length(blocked), "Шлюзы станции упираются в стену шаттла прибытия: [blocked.Join(", ")]")

/// cos и sin поворота порта, как в /obj/docking_port/proc/return_coords().
/datum/unit_test/arrivals_airlocks_meet_shuttle_doors/proc/port_axes(port_dir)
	switch(port_dir)
		if(WEST)
			return list(0, 1)
		if(SOUTH)
			return list(-1, 0)
		if(EAST)
			return list(0, -1)
	return list(1, 0)

/// Паром ЦК и карго-шаттл помещаются в свои бухты на станции: оба грузятся на ЦК и прилетают позже.
/datum/unit_test/station_bays_fit_shuttles
	requires_full_map = TRUE

/datum/unit_test/station_bays_fit_shuttles/Run()
	for(var/list/pair in list(list("ferry", "ferry_home"), list("supply", "supply_home")))
		var/obj/docking_port/mobile/shuttle = SSshuttle.getShuttle(pair[1])
		var/obj/docking_port/stationary/bay = SSshuttle.getDock(pair[2])
		if(!shuttle || !bay)
			continue
		var/result = shuttle.canDock(bay)
		TEST_ASSERT(result == SHUTTLE_CAN_DOCK || result == SHUTTLE_ALREADY_DOCKED || result == SHUTTLE_SOMEONE_ELSE_DOCKED, "[shuttle] не помещается в бухту [pair[2]] ([bay.x],[bay.y],[bay.z]): [result]")

/// Грунт на станции портированных карт не планетарный: иначе он вечный источник газа и активный турф с роундстарта.
/datum/unit_test/ported_map_station_dirt_not_planetary
	requires_full_map = TRUE

/datum/unit_test/ported_map_station_dirt_not_planetary/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/planetary = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/floor/plating/dirt/dirt in block(locate(1, 1, station_z), locate(world.maxx, world.maxy, station_z)))
			var/area/dirt_area = dirt.loc
			if(dirt.planetary_atmos && !dirt_area.outdoors)
				planetary += "([dirt.x],[dirt.y],[dirt.z])"
	TEST_ASSERT(!length(planetary), "Планетарный грунт на станции: [planetary.Join(", ")]")

/// Генератор пещер заменил все заглушки genturf на станционных уровнях: зона без генератора оставляет их как есть.
/datum/unit_test/station_levels_no_genturf
	requires_full_map = TRUE

/datum/unit_test/station_levels_no_genturf/Run()
	var/list/leftover = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/genturf/placeholder in block(locate(1, 1, station_z), locate(world.maxx, world.maxy, station_z)))
			if(length(leftover) < 10)
				leftover += "([placeholder.x],[placeholder.y],[placeholder.z]) [placeholder.loc.type]"
			else
				break
	TEST_ASSERT(!length(leftover), "Заглушки genturf после генерации: [leftover.Join(", ")]")

/// Скамейки станции собраны из одной семьи: конец церковной скамьи рядом с серединой металлической - поломка конвертера карт.
/datum/unit_test/station_benches_one_family
	requires_full_map = TRUE

/datum/unit_test/station_benches_one_family/Run()
	var/list/mixed = list()
	for(var/obj/structure/chair/sofa/bench/bench in world)
		if(!is_station_level(bench.z))
			continue
		for(var/side in list(turn(bench.dir, 90), turn(bench.dir, -90)))
			var/obj/structure/chair/pew/pew = locate() in get_step(bench, side)
			if(pew?.dir == bench.dir)
				mixed += "([bench.x],[bench.y],[bench.z])"
	TEST_ASSERT(!length(mixed), "Скамейка из двух семей (bench и pew): [mixed.Join(", ")]")

/// Скала Трамстанции, как у tg, без своего питания, и гравитация в ней только от генератора станции.
/datum/unit_test/tramstation_asteroid_unpowered
	requires_full_map = TRUE

/datum/unit_test/tramstation_asteroid_unpowered/Run()
	if(SSmapping.config.map_name != "Tramstation")
		return
	var/area/asteroid/tramstation/rock = GLOB.areas_by_type[/area/asteroid/tramstation]
	TEST_ASSERT_NOTNULL(rock, "На Трамстанции нет зоны скалы")
	TEST_ASSERT(!rock.powered(LIGHT), "Свет в скале Трамстанции горит без APC")
	TEST_ASSERT(!rock.powered(EQUIP), "Оборудование в скале Трамстанции работает без APC")
	TEST_ASSERT(!rock.has_gravity, "Скала Трамстанции держит гравитацию сама, мимо генератора")

/// Канистры у портов криокапсул станции, прикрученные ключом, дают капсуле газ, на котором она работает.
/datum/unit_test/station_cryo_cells_have_gas
	requires_full_map = TRUE

/datum/unit_test/station_cryo_cells_have_gas/Run()
	var/list/dead_cells = list()
	for(var/obj/machinery/atmospherics/components/unary/cryo_cell/cell as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/atmospherics/components/unary/cryo_cell))
		if(!is_station_level(cell.z))
			continue
		var/datum/pipeline/net = cell.parents[1]
		if(net)
			net.ensure_built()
			for(var/obj/machinery/atmospherics/components/unary/portables_connector/port in net.other_atmosmch)
				var/obj/machinery/portable_atmospherics/canister/canister = locate() in port.loc
				canister?.connect(port)
			net.reconcile_air()
		var/was_on = cell.on
		cell.on = TRUE
		cell.process_atmos()
		if(!cell.on)
			dead_cells += "([cell.x],[cell.y],[cell.z])"
		cell.on = was_on
		cell.update_icon()
	TEST_ASSERT(!length(dead_cells), "Криокапсулы гаснут сразу после включения, на их сети нет нужного газа: [dead_cells.Join(", ")]")

/// Станционные зоны карты названы: зона без своего name подписывается в логах и на ПДА как «Space».
/datum/unit_test/station_areas_named
	requires_full_map = TRUE

/datum/unit_test/station_areas_named/Run()
	var/area/base_area = /area
	var/default_name = initial(base_area.name)
	var/list/unnamed = list()
	for(var/area/station_area as anything in GLOB.sortedAreas)
		if(istype(station_area, /area/space) || !is_station_level(station_area.z))
			continue
		if(station_area.name == default_name)
			unnamed += "[station_area.type]"
	TEST_ASSERT(!length(unnamed), "Станционные зоны без имени: [unnamed.Join(", ")]")

#define SUPERMATTER_COLLECTOR_RANGE 2
#define SUPERMATTER_MIN_COLLECTORS 6

/// У кристалла суперматерии станции стоят радколлекторы на сети с вводом СМЕСа: наш кристалл кормит их излучением, в тесла-катушки бьёт только при перегрузке.
/datum/unit_test/station_supermatter_has_rad_collectors
	requires_full_map = TRUE

/datum/unit_test/station_supermatter_has_rad_collectors/Run()
	for(var/obj/machinery/power/supermatter_crystal/engine/crystal as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/supermatter_crystal/engine))
		if(!is_station_level(crystal.z))
			continue
		var/wired = 0
		for(var/obj/machinery/power/rad_collector/collector as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/rad_collector))
			if(collector.z != crystal.z || get_dist(collector, crystal) > SUPERMATTER_COLLECTOR_RANGE)
				continue
			if(collector.anchored && collector.powernet && (locate(/obj/machinery/power/terminal) in collector.powernet.nodes))
				wired++
		TEST_ASSERT(wired >= SUPERMATTER_MIN_COLLECTORS, "У суперматерии ([crystal.x],[crystal.y],[crystal.z]) радколлекторов на сети СМЕСа: [wired] из [SUPERMATTER_MIN_COLLECTORS]")

#undef SUPERMATTER_COLLECTOR_RANGE
#undef SUPERMATTER_MIN_COLLECTORS

/// Трубы сантехники, проложенные картой под плиткой, не видны поверх пола.
/datum/unit_test/station_mapped_ducts_under_tiles_hidden
	requires_full_map = TRUE

/datum/unit_test/station_mapped_ducts_under_tiles_hidden/Run()
	var/visible_count = 0
	var/list/examples = list()
	for(var/obj/machinery/duct/duct as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/duct))
		var/turf/duct_turf = duct.loc
		if(!isturf(duct_turf) || !is_station_level(duct.z) || !(duct_turf.turf_flags & TURF_INTACT))
			continue
		if(duct.invisibility == INVISIBILITY_MAXIMUM)
			continue
		visible_count++
		if(length(examples) < 10)
			examples += "([duct.x],[duct.y],[duct.z])"
	TEST_ASSERT(!visible_count, "Трубы поверх плитки: [visible_count], например [examples.Join(", ")]")

/// Табло шаттлов на станции смотрят на шаттл, который есть: у tg прибытие зовётся "arrival", у нас "arrivals".
/datum/unit_test/station_shuttle_displays_known_shuttle
	requires_full_map = TRUE

/datum/unit_test/station_shuttle_displays_known_shuttle/Run()
	var/list/known_ids = list()
	for(var/obj/docking_port/mobile/port as anything in SSshuttle.mobile)
		known_ids[port.shuttle_id] = TRUE
	var/list/unknown = list()
	for(var/obj/machinery/status_display/shuttle/display as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/status_display/shuttle))
		if(display.shuttle_id && is_station_level(display.z) && !known_ids[display.shuttle_id])
			unknown += "[display.shuttle_id] ([display.x],[display.y],[display.z])"
	TEST_ASSERT(!length(unknown), "Табло шаттлов с неизвестным id: [unknown.Join(", ")]")

/// На портированных картах планетарный турф внутри станционной зоны не делит воздух со станционным полом: иначе он вечно студит комнату.
/datum/unit_test/ported_map_rooms_no_planetary_air
	requires_full_map = TRUE

/datum/unit_test/ported_map_rooms_no_planetary_air/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/sinks = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/planet_turf in block(locate(1, 1, station_z), locate(world.maxx, world.maxy, station_z)))
			var/area/planet_area = planet_turf.loc
			if(!planet_turf.planetary_atmos || planet_area.outdoors || istype(planet_area, /area/ruin))
				continue
			for(var/turf/open/neighbour as anything in planet_turf.atmos_adjacent_turfs)
				var/area/neighbour_area = neighbour.loc
				if(neighbour.initial_gas_mix == OPENTURF_DEFAULT_ATMOS && !neighbour.planetary_atmos && !neighbour_area.outdoors)
					sinks += "([planet_turf.x],[planet_turf.y],[planet_turf.z]) [planet_area.type]"
					break
	TEST_ASSERT(!length(sinks), "Планетарный воздух в станционной комнате: [sinks.Join(", ")]")

/// SMES с меньшим зарядом пустеют за минуты и стартовую нагрузку не держат.
#define STATION_SMES_STORAGE_CHARGE 1e6
/// Запас отдачи над нагрузкой APC, как у Meta на старте: потом просыпаются машины и заряжаются ячейки APC.
#define STATION_SMES_LOAD_MARGIN 1.2

/// На портированных картах заряженные SMES станции отдают в сеть, и на старте их отдача с запасом покрывает нагрузку APC той же сети.
/datum/unit_test/ported_map_smes_cover_apc_load
	requires_full_map = TRUE

/datum/unit_test/ported_map_smes_cover_apc_load/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/relays = SSmachines.get_machines_by_type(/obj/machinery/power/deck_relay)
	for(var/obj/machinery/power/deck_relay/relay as anything in relays)
		relay.find_relays()
	for(var/obj/machinery/power/deck_relay/relay as anything in relays)
		relay.refresh()

	var/list/problems = list()
	var/list/supply = list()
	for(var/obj/machinery/power/smes/smes as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/smes))
		if(!is_station_level(smes.z) || smes.charge < STATION_SMES_STORAGE_CHARGE)
			continue
		if(!smes.powernet)
			problems += "заряженный SMES без сети ([smes.x],[smes.y],[smes.z])"
		else if(smes.output_attempt)
			supply[smes.powernet] += smes.output_level
	var/list/demand = list()
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		var/datum/powernet/grid = apc.terminal?.powernet
		if(is_station_level(apc.z) && grid)
			demand[grid] += apc.lastused_total
	TEST_ASSERT(length(supply), "На станции нет заряженных SMES на сети")
	for(var/datum/powernet/grid as anything in supply)
		TEST_ASSERT(demand[grid], "APC сети SMES ещё не посчитали нагрузку")
		if(supply[grid] < demand[grid] * STATION_SMES_LOAD_MARGIN)
			problems += "отдача SMES [supply[grid] / 1000] кВт при нагрузке APC [round(demand[grid] / 1000)] кВт"
	TEST_ASSERT(!length(problems), "Питание станции на старте: [problems.Join("; ")]")

#undef STATION_SMES_STORAGE_CHARGE
#undef STATION_SMES_LOAD_MARGIN

/// Шлюз шаттла прибытия в доке выходит к шлюзу или полу станции: иначе латджойнеры выходят в космос.
/datum/unit_test/arrivals_shuttle_airlock_meets_station
	requires_full_map = TRUE

/datum/unit_test/arrivals_shuttle_airlock_meets_station/Run()
	var/obj/docking_port/mobile/arrivals/shuttle = SSshuttle.arrivals
	var/obj/docking_port/stationary/dock = SSshuttle.getDock("arrivals_stationary")
	if(!shuttle || !dock)
		return
	// Шаттл в простое мотается в транзит и обратно, поэтому его шлюзы проецируются на док.
	var/angle = SIMPLIFY_DEGREES(dir2angle(dock.dir) - dir2angle(shuttle.dir))
	var/list/docked_turfs = list()
	var/list/airlock_spots = list()
	for(var/turf/shuttle_turf as anything in shuttle.return_turfs())
		if(!shuttle.shuttle_areas[get_area(shuttle_turf)])
			continue
		var/dx = shuttle_turf.x - shuttle.x
		var/dy = shuttle_turf.y - shuttle.y
		var/turf/docked
		switch(angle)
			if(0)
				docked = locate(dock.x + dx, dock.y + dy, dock.z)
			if(90)
				docked = locate(dock.x + dy, dock.y - dx, dock.z)
			if(180)
				docked = locate(dock.x - dx, dock.y - dy, dock.z)
			if(270)
				docked = locate(dock.x - dy, dock.y + dx, dock.z)
		docked_turfs[docked] = TRUE
		if(locate(/obj/machinery/door/airlock) in shuttle_turf)
			airlock_spots += docked
	if(!length(airlock_spots))
		return
	for(var/turf/spot as anything in airlock_spots)
		for(var/direction in GLOB.cardinals)
			var/turf/outside = get_step(spot, direction)
			if(!outside || docked_turfs[outside])
				continue
			if(locate(/obj/machinery/door/airlock) in outside)
				return
			if(isopenturf(outside) && !isspaceturf(outside) && !isopenspaceturf(outside))
				return
	TEST_FAIL("Ни один шлюз шаттла прибытия в доке ([dock.x],[dock.y],[dock.z]) не выходит к шлюзу или полу станции")

/// Шахтёр с минимальным доступом доходит от своих точек старта до шахтёрского шаттла.
/datum/unit_test/shaft_miner_reaches_mining_shuttle
	requires_full_map = TRUE

/datum/unit_test/shaft_miner_reaches_mining_shuttle/Run()
	var/obj/docking_port/stationary/mining_dock = SSshuttle.getDock("mining_home")
	var/list/starts = GLOB.unit_test_start_landmark_turfs[/obj/effect/landmark/start/shaft_miner]
	if(!mining_dock || !length(starts))
		return
	var/datum/job/miner = SSjob.GetJob("Shaft Miner")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = miner.minimal_access.Copy()
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human)
	var/max_path_length = 200
	var/list/stranded = list()
	for(var/turf/start as anything in starts)
		if(start.z != mining_dock.z)
			continue
		walker.forceMove(start)
		if(!length(get_path_to(walker, mining_dock, max_path_length, 1, card)))
			stranded += "([start.x],[start.y],[start.z])"
	TEST_ASSERT(!length(stranded), "Шахтёр с минимальным доступом не доходит до шаттла ([mining_dock.x],[mining_dock.y],[mining_dock.z]) от точек старта: [stranded.Join(", ")]")

/// На портированных картах внутри станции нет живых враждебных мобов, кроме ручных питомцев и слабой фауны в техах и заброшенных комнатах.
/datum/unit_test/ported_map_no_hostile_mobs_inside
	requires_full_map = TRUE

/datum/unit_test/ported_map_no_hostile_mobs_inside/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/pets = typecacheof(list(
		/mob/living/simple_animal/hostile/carp/pet_carp,
		/mob/living/simple_animal/hostile/lizard,
		/mob/living/simple_animal/hostile/retaliate/goat,
		/mob/living/simple_animal/hostile/retaliate/goose,
		/mob/living/simple_animal/hostile/poison/giant_spider/pet_spider,
	))
	var/list/outside = typecacheof(list(/area/space, /area/lavaland, /area/icemoon, /area/ruin, /area/asteroid))
	var/list/fauna = list(/mob/living/simple_animal/hostile/syndicate/melee, /mob/living/simple_animal/hostile/poison/giant_spider/hunter)
	var/list/fauna_areas = typecacheof(list(
		/area/maintenance,
		/area/cargo/miningdock/abandoned,
		/area/medical/abandoned,
		/area/science/research/abandoned,
		/area/service/abandoned_gambling_den,
		/area/service/hydroponics/garden/abandoned,
		/area/service/kitchen/abandoned,
		/area/service/library/abandoned,
		/area/service/theater/abandoned,
	))
	var/list/found = list()
	for(var/mob/living/simple_animal/hostile/hostile_mob in GLOB.alive_mob_list)
		if(pets[hostile_mob.type] || !is_station_level(hostile_mob.z))
			continue
		var/area/mob_area = get_area(hostile_mob)
		if(outside[mob_area.type] || mob_area.outdoors)
			continue
		if((hostile_mob.type in fauna) && fauna_areas[mob_area.type])
			continue
		if(!hostile_mob.vision_range && !hostile_mob.aggro_vision_range && ("neutral" in hostile_mob.faction))
			continue
		found += "[hostile_mob.type] ([hostile_mob.x],[hostile_mob.y],[hostile_mob.z])"
	TEST_ASSERT(!length(found), "Живые враждебные мобы внутри станции: [found.Join(", ")]")

/// Карты, где у Navigate нет точек (или нет Research): долг родных карт и отладочные карты.
#define MAPS_WITHOUT_NAVIGATION list("Kilo Station", "Lambda Station", "OmegaStation", "Smol Station", "FestiveStation", "Runtime Station", "Minimal Runtime Station", "MultiZ Debug")

/// Navigate знает ключевые отделы станции, а на портированных картах к каждой точке можно подойти по полу станции.
/datum/unit_test/station_navigation_destinations
	requires_full_map = TRUE

/datum/unit_test/station_navigation_destinations/Run()
	if(SSmapping.config.map_name in MAPS_WITHOUT_NAVIGATION)
		return
	var/list/names = list()
	for(var/turf/destination as anything in GLOB.navigate_destinations)
		names[GLOB.navigate_destinations[destination]] = TRUE
	var/list/departments = list(list("Bridge"), list("Medical", "Medbay"), list("Research"), list("Engineering"), list("Cargo"), list("Bar"), list("Dormitories"), list("Arrival Shuttle Dock"), list("Escape Shuttle Dock", "Escape"))
	var/list/missing = list()
	for(var/list/alternatives as anything in departments)
		var/found = FALSE
		for(var/name in alternatives)
			if(names[name])
				found = TRUE
				break
		if(!found)
			missing += alternatives[1]
	TEST_ASSERT(!length(missing), "Navigate не знает отделов: [missing.Join(", ")]")
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/stranded = list()
	for(var/turf/destination as anything in GLOB.navigate_destinations)
		if(!is_station_level(destination.z) || !approachable(destination))
			stranded += "[GLOB.navigate_destinations[destination]] ([destination.x],[destination.y],[destination.z])"
	TEST_ASSERT(!length(stranded), "Точки навигации, к которым не подойти по полу станции: [stranded.Join(", ")]")

/// Путь Navigate кончается на клетке точки или рядом с ней: хоть одна из них - пол без плотных объектов, кроме дверей и перил.
/datum/unit_test/station_navigation_destinations/proc/approachable(turf/destination)
	var/list/spots = list(destination)
	for(var/direction in GLOB.cardinals)
		spots += get_step(destination, direction)
	for(var/turf/spot as anything in spots)
		if(!isfloorturf(spot))
			continue
		var/blocked = FALSE
		for(var/obj/thing in spot)
			if(thing.density && !istype(thing, /obj/machinery/door) && !istype(thing, /obj/structure/railing))
				blocked = TRUE
				break
		if(!blocked)
			return TRUE
	return FALSE

#undef MAPS_WITHOUT_NAVIGATION

/// Скрубберы ксенобиологии Void Raptor стоят на сети с выходом, а её вентиляция - на общей раздаче станции.
/datum/unit_test/voidraptor_xenobiology_air
	requires_full_map = TRUE

/datum/unit_test/voidraptor_xenobiology_air/Run()
	if(SSmapping.config.map_name != "Void Raptor")
		return
	var/list/problems = list()
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/atmospherics/components/unary/vent_scrubber))
		if(!istype(get_area(scrubber), /area/science/xenobiology))
			continue
		var/datum/pipeline/net = scrubber.parents[1]
		var/has_outlet = FALSE
		for(var/obj/machinery/atmospherics/components/device as anything in net?.other_atmosmch)
			if(!istype(device, /obj/machinery/atmospherics/components/unary/vent_scrubber))
				has_outlet = TRUE
				break
		if(!has_outlet)
			problems += "скруббер без выхода ([scrubber.x],[scrubber.y],[scrubber.z])"
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/vent as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/atmospherics/components/unary/vent_pump))
		if(!istype(get_area(vent), /area/science/xenobiology))
			continue
		var/datum/pipeline/net = vent.parents[1]
		var/on_station_distro = FALSE
		for(var/obj/machinery/atmospherics/components/unary/vent_pump/other in net?.other_atmosmch)
			var/area/other_area = get_area(other)
			if(!istype(other_area, /area/science/xenobiology) && !istype(other_area, /area/maintenance/department/science/xenobiology))
				on_station_distro = TRUE
				break
		if(!on_station_distro)
			problems += "вент вне общей раздачи ([vent.x],[vent.y],[vent.z])"
	TEST_ASSERT(!length(problems), "Ксенобиология: [problems.Join(", ")]")

/// В охране портированных карт есть автолат, печатающий патроны .45, как взломанные автолаты охраны на Box, Meta и Kilo.
/datum/unit_test/ported_map_security_prints_45
	requires_full_map = TRUE

/datum/unit_test/ported_map_security_prints_45/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	for(var/obj/machinery/autolathe/lathe as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/autolathe))
		if(is_station_level(lathe.z) && istype(get_area(lathe), /area/security) && lathe.stored_research.isDesignResearchedID("c45"))
			return
	TEST_FAIL("В охране нет автолата с патронами .45")
