/datum/controller/subsystem/mapping
	/// id сектора -> /datum/space_sector, все наборы разом.
	var/list/space_sectors
	/// Имя набора -> список /datum/space_sector.
	var/list/space_sector_sets
	var/datum/space_grid/space_grid

/datum/controller/subsystem/mapping/proc/get_space_grid() as /datum/space_grid
	if(!space_grid)
		space_grid = new
	return space_grid

/// Грузит заказанный картой набор. Зовётся до того, как расплодятся случайные космо-уровни.
/datum/controller/subsystem/mapping/proc/load_space_sectors()
	build_space_sector_registry()

	var/set_name = config?.space_sector_set
	if(!set_name)
		return

	var/list/sectors = space_sector_sets[set_name]
	if(!length(sectors))
		INIT_ANNOUNCE("ВНИМАНИЕ: карта просит набор секторов '[set_name]', но ни одного сектора с таким sector_set в коде нет!")
		return

	var/start_time = REALTIMEOFDAY
	var/loaded = 0
	for(var/datum/space_sector/sector as anything in order_space_sectors(sectors))
		if(load_space_sector(sector))
			loaded++

	//Смещения по фактическим z: между этажами колонки могли вклиниться чужие уровни.
	link_z_level_pairs(get_space_grid().vertical_pairs())
	INIT_ANNOUNCE("Загружено секторов космоса: [loaded] из [length(sectors)] (набор '[set_name]') за [(REALTIMEOFDAY - start_time)/10]с.")

/// Снизу вверх по этажам: номера z раздаются в порядке загрузки.
/datum/controller/subsystem/mapping/proc/order_space_sectors(list/sectors)
	var/min_layer = INFINITY
	var/max_layer = -INFINITY
	for(var/datum/space_sector/sector as anything in sectors)
		min_layer = min(min_layer, sector.sector_layer)
		max_layer = max(max_layer, sector.sector_layer)

	. = list()
	for(var/layer in min_layer to max_layer)
		for(var/datum/space_sector/sector as anything in sectors)
			if(sector.sector_layer == layer)
				. += sector

/// Грузит один сектор. Карта из нескольких z занимает столько этажей подряд, начиная со своего.
/datum/controller/subsystem/mapping/proc/load_space_sector(datum/space_sector/sector)
	var/datum/space_grid/grid = get_space_grid()

	if(!sector.mappath)
		var/datum/space_level/level = add_new_zlevel(sector.name, sector.build_traits())
		grid.place(level, sector.sector_x, sector.sector_y, sector.sector_layer, sector)
		return TRUE

	//Свой набор трейтов на каждый этаж: общий список получил бы чужие вертикальные связки.
	var/datum/map_template/probe = new(sector.mappath, sector.name)
	var/depth = max(probe.zdepth, 1)
	qdel(probe)

	var/list/trait_sets = list()
	for(var/i in 1 to depth)
		trait_sets += list(sector.build_traits())

	var/split = findlasttext(sector.mappath, "/")
	//LoadGroup ждёт путь от _maps/, в декларации он от корня репозитория.
	var/map_dir = copytext(sector.mappath, length("_maps/") + 1, split)
	var/map_file = copytext(sector.mappath, split + 1)

	var/before = length(z_list)
	var/list/failed = list()
	LoadGroup(failed, sector.name, map_dir, map_file, trait_sets, sector.build_traits())
	if(length(failed))
		INIT_ANNOUNCE("ВНИМАНИЕ: сектор '[sector.id]' не загрузился: [failed.Join(", ")]")
		return FALSE

	var/created = length(z_list) - before
	if(created <= 0)
		INIT_ANNOUNCE("ВНИМАНИЕ: сектор '[sector.id]' не создал ни одного z-уровня.")
		return FALSE

	for(var/index in 1 to created)
		var/datum/space_level/level = z_list[before + index]
		grid.place(level, sector.sector_x, sector.sector_y, sector.sector_layer + index - 1, sector)
	return TRUE

/// Отдельный проход руин по секторам с собственным бюджетом. Зовётся из окна загрузки руин.
/datum/controller/subsystem/mapping/proc/seed_space_sector_ruins()
	var/datum/space_grid/grid = space_grid
	if(!grid)
		return

	for(var/datum/space_level/level as anything in grid.level_sectors)
		var/datum/space_sector/sector = grid.level_sectors[level]
		if(sector.ruin_budget <= 0)
			continue
		seedRuins(list(level.z_value), sector.ruin_budget, list(/area/space), space_ruins_templates)

/// Отчёт о собранной сетке в лог маппинга: раскладка целиком плюс список проблем.
/datum/controller/subsystem/mapping/proc/log_space_grid_report()
	var/datum/space_grid/grid = space_grid
	if(!grid)
		return

	for(var/line in grid.to_ascii())
		log_mapping("Сетка космоса: [line]")

	var/list/complaints = grid.validate()
	for(var/complaint in complaints)
		log_mapping("Сетка космоса: [complaint]")
		INIT_ANNOUNCE("ВНИМАНИЕ, сетка космоса: [complaint]")
