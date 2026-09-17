/// Нарисованный .dmm в фиксированной клетке сетки космоса. Формат декларации - README.md рядом.
/datum/space_sector
	/// Тип, равный собственному abstract_type, в реестр не попадает.
	var/abstract_type = /datum/space_sector
	var/id
	var/sector_set
	var/name = "Безымянный сектор"
	/// Полный путь к .dmm от корня репозитория. null - пустой уровень без карты.
	var/mappath
	/// Клетка на сетке. Ось X растёт на восток, Y - на север, начало произвольно.
	var/sector_x = 0
	var/sector_y = 0
	/// Этаж стопки: одинаковые x/y и соседние этажи сцепляются ZTRAIT_UP/ZTRAIT_DOWN.
	var/sector_layer = 0
	var/list/traits
	/// Бюджет случайных руин: 0 - не сеять, -1 - отдать общему проходу, больше нуля - отдельным проходом.
	var/ruin_budget = 0
	/// Явная связь по краю: id соседа, перебивает соседство по координатам. Взаимность не подразумевается.
	/// Четыре поля, а не список: сторона света ключом list() быть не может.
	var/link_north
	var/link_south
	var/link_east
	var/link_west

/// Набор трейтов уровня. Список обязан быть свежим: связки дописывают в него ZTRAIT_UP/ZTRAIT_DOWN.
/datum/space_sector/proc/build_traits()
	var/list/built = ZTRAITS_SPACE
	built[ZTRAIT_SPACE_RUINS] = (ruin_budget == -1)
	for(var/trait in traits)
		built[trait] = traits[trait]
	return built

/datum/space_sector/proc/get_links()
	. = list()
	if(link_north)
		.[TEXT_NORTH] = link_north
	if(link_south)
		.[TEXT_SOUTH] = link_south
	if(link_east)
		.[TEXT_EAST] = link_east
	if(link_west)
		.[TEXT_WEST] = link_west

/// Список претензий к декларации; пустой означает, что сектор пригоден к загрузке.
/datum/space_sector/proc/validate()
	. = list()
	if(!id)
		. += "[type]: не задан id."
	if(!sector_set)
		. += "[type]: не задан sector_set, сектор не попадёт ни в одну карту."
	if(!isnum(sector_x) || !isnum(sector_y) || !isnum(sector_layer))
		. += "[type] ([id]): координаты обязаны быть числами."
	if(mappath)
		if(copytext(mappath, 1, length("_maps/") + 1) != "_maps/")
			. += "[type] ([id]): путь карты обязан начинаться с _maps/, а не '[mappath]'."
		else if(!fexists(mappath))
			. += "[type] ([id]): файла карты [mappath] нет на диске."
	if(!isnull(traits) && !islist(traits))
		. += "[type] ([id]): traits обязан быть списком."
	if(!isnum(ruin_budget))
		. += "[type] ([id]): ruin_budget обязан быть числом."
	var/list/declared_links = get_links()
	for(var/edge in declared_links)
		if(!istext(declared_links[edge]))
			. += "[type] ([id]): связь на [space_grid_edge_name(edge)] обязана быть id соседнего сектора строкой."

/// Реестр секторов: id -> декларация, набор -> список деклараций. Собирается один раз за раунд.
/datum/controller/subsystem/mapping/proc/build_space_sector_registry()
	if(space_sectors)
		return
	space_sectors = list()
	space_sector_sets = list()
	var/list/complaints = list()

	for(var/datum/space_sector/sector_type as anything in subtypesof(/datum/space_sector))
		var/datum/space_sector/sector = new sector_type
		if(sector.abstract_type == sector.type)
			qdel(sector)
			continue

		var/list/sector_complaints = sector.validate()
		if(length(sector_complaints))
			complaints += sector_complaints
			qdel(sector)
			continue

		if(space_sectors[sector.id])
			var/datum/space_sector/taken = space_sectors[sector.id]
			complaints += "[sector.type]: id '[sector.id]' уже занят типом [taken.type]."
			qdel(sector)
			continue

		space_sectors[sector.id] = sector
		LAZYADD(space_sector_sets[sector.sector_set], sector)

	for(var/complaint in complaints)
		log_mapping("Секторы космоса: [complaint]")
		stack_trace("Секторы космоса: [complaint]")
