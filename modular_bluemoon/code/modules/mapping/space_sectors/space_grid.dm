/// Ключ клетки: координаты бывают отрицательными, поэтому клетки лежат в assoc по строке.
#define SPACE_GRID_KEY(gx, gy, glayer) "[gx],[gy],[glayer]"

/// Сетка космоса: кто в какой клетке стоит и кто кому сосед. Ни турфов, ни загрузки - только топология.
/datum/space_grid
	/// "x,y,этаж" -> /datum/space_level
	var/list/cells = list()
	/// /datum/space_level -> list(x, y, этаж)
	var/list/placements = list()
	/// /datum/space_level -> /datum/space_sector, только у объявленных уровней.
	var/list/level_sectors = list()
	/// id сектора -> /datum/space_level
	var/list/sector_levels = list()
	/// Свободные клетки нулевого этажа по границе занятых.
	var/list/frontier = list()
	var/list/problems = list()

/datum/space_grid/Destroy()
	cells = null
	placements = null
	level_sectors = null
	sector_levels = null
	frontier = null
	problems = null
	return ..()

/datum/space_grid/proc/level_at(x, y, layer = 0)
	return cells[SPACE_GRID_KEY(x, y, layer)]

/datum/space_grid/proc/coords_of(datum/space_level/level)
	return placements[level]

/// Сажает уровень в клетку. FALSE, если клетка занята: занявший остаётся, претензия уходит в problems.
/datum/space_grid/proc/place(datum/space_level/level, x, y, layer = 0, datum/space_sector/sector)
	var/key = SPACE_GRID_KEY(x, y, layer)
	var/datum/space_level/taken = cells[key]
	if(taken)
		problems += "клетка ([x], [y], этаж [layer]) занята уровнем '[taken.name]' (z=[taken.z_value]), '[level.name]' (z=[level.z_value]) туда не влезет."
		return FALSE

	cells[key] = level
	placements[level] = list(x, y, layer)
	level.xi = x
	level.yi = y
	if(sector)
		level_sectors[level] = sector
		//Реестр по id держит базовый этаж сектора: явные связи и проверки идут по нему.
		if(!sector_levels[sector.id])
			sector_levels[sector.id] = level

	frontier -= key
	if(layer == 0)
		for(var/list/offset as anything in list(list(0, 1), list(0, -1), list(1, 0), list(-1, 0)))
			var/neighbour_key = SPACE_GRID_KEY(x + offset[1], y + offset[2], 0)
			if(cells[neighbour_key])
				continue
			frontier |= neighbour_key
	return TRUE

/// Уровень без объявленной клетки: случайное блуждание по свободной границе занятых.
/datum/space_grid/proc/place_floating(datum/space_level/level)
	if(!length(cells))
		return place(level, 0, 0, 0)

	//Нулевой этаж пуст, а верхние заняты - садимся правее самой правой занятой клетки.
	if(!length(frontier))
		var/max_x = 0
		for(var/datum/space_level/placed as anything in placements)
			var/list/spot = placements[placed]
			max_x = max(max_x, spot[1])
		return place(level, max_x + 1, 0, 0)

	var/key = pick(frontier)
	var/list/parts = splittext(key, ",")
	return place(level, text2num(parts[1]), text2num(parts[2]), text2num(parts[3]))

/// Соседство по координатам: каждая пара получает взаимные ссылки, пустые стороны остаются незаполненными.
/datum/space_grid/proc/link_horizontal()
	//Направление -> смещение клетки и обратная сторона.
	var/static/list/edges = list(
		TEXT_NORTH = list(0, 1, TEXT_SOUTH),
		TEXT_SOUTH = list(0, -1, TEXT_NORTH),
		TEXT_EAST = list(1, 0, TEXT_WEST),
		TEXT_WEST = list(-1, 0, TEXT_EAST),
	)

	for(var/datum/space_level/level as anything in placements)
		//У самозамкнутого уровня все стороны ведут в него самого, переписывать их нельзя.
		if(level.linkage != CROSSLINKED)
			continue
		var/list/spot = placements[level]
		for(var/edge in edges)
			var/list/rule = edges[edge]
			var/datum/space_level/neighbour = level_at(spot[1] + rule[1], spot[2] + rule[2], spot[3])
			if(!neighbour || neighbour.linkage != CROSSLINKED)
				continue
			level.neigbours[edge] = neighbour
			neighbour.neigbours[rule[3]] = level

/// Явные связи по id поверх координат. Обратную сторону сосед объявляет сам.
/datum/space_grid/proc/apply_explicit_links()
	for(var/datum/space_level/level as anything in level_sectors)
		var/datum/space_sector/sector = level_sectors[level]
		if(sector_levels[sector.id] != level)
			continue
		var/list/declared_links = sector.get_links()
		for(var/edge in declared_links)
			var/target_id = declared_links[edge]
			var/datum/space_level/target = sector_levels[target_id]
			if(!target)
				problems += "сектор '[sector.id]' ссылается на [space_grid_edge_name(edge)] на несуществующий сектор '[target_id]'."
				continue
			level.neigbours[edge] = target

/// Пары уровней, стоящих друг над другом: list(нижний, верхний).
/datum/space_grid/proc/vertical_pairs()
	. = list()
	for(var/datum/space_level/level as anything in placements)
		var/list/spot = placements[level]
		var/datum/space_level/above = level_at(spot[1], spot[2], spot[3] + 1)
		if(!above)
			continue
		. += list(list(level, above))

/// Полный отчёт: problems плюс проверки, осмысленные только на собранной сетке.
/datum/space_grid/proc/validate()
	. = problems.Copy()

	for(var/datum/space_level/level as anything in level_sectors)
		var/datum/space_sector/sector = level_sectors[level]
		if(!length(level.neigbours))
			. += "сектор '[sector.id]' изолирован: ни одного соседа ни по одной стороне. Нужен сосед по координатам, явная связь или ZTRAIT_LINKAGE = SELFLOOPING, чтобы края заворачивали на себя."
		if(sector_levels[sector.id] != level)
			continue
		var/list/declared_links = sector.get_links()
		for(var/edge in declared_links)
			var/target_id = declared_links[edge]
			var/datum/space_level/target = sector_levels[target_id]
			if(!target)
				continue
			var/opposite = "[turn(text2num(edge), 180)]"
			if(target.neigbours[opposite] != level)
				. += "связь '[sector.id]' -> '[target_id]' по [space_grid_edge_name(edge)] односторонняя: назад пути нет."

	for(var/datum/space_level/level as anything in placements)
		var/list/spot = placements[level]
		if(spot[3] <= 0)
			continue
		if(level_at(spot[1], spot[2], spot[3] - 1))
			continue
		. += "уровень '[level.name]' стоит на этаже [spot[3]] клетки ([spot[1]], [spot[2]]), а этажа [spot[3] - 1] под ним нет - стопка разорвана."

/// Текстовая карта сетки для дампа: таблица на этаж, в клетке номер z.
/datum/space_grid/proc/to_ascii()
	if(!length(placements))
		return list("Сетка пуста.")

	var/min_x = INFINITY
	var/max_x = -INFINITY
	var/min_y = INFINITY
	var/max_y = -INFINITY
	var/min_layer = INFINITY
	var/max_layer = -INFINITY
	for(var/datum/space_level/level as anything in placements)
		var/list/spot = placements[level]
		min_x = min(min_x, spot[1])
		max_x = max(max_x, spot[1])
		min_y = min(min_y, spot[2])
		max_y = max(max_y, spot[2])
		min_layer = min(min_layer, spot[3])
		max_layer = max(max_layer, spot[3])

	. = list()
	for(var/layer in min_layer to max_layer)
		. += "--- этаж [layer] (север сверху, в клетке номер z) ---"
		for(var/y in max_y to min_y step -1)
			var/list/row = list()
			for(var/x in min_x to max_x)
				var/datum/space_level/level = level_at(x, y, layer)
				row += level ? "[level.z_value]" : "."
			. += "y=[y]\t[row.Join("\t")]"
		. += "\tx=[min_x]..[max_x]"

	. += ""
	. += "--- уровни ---"
	for(var/datum/space_level/level as anything in placements)
		var/list/spot = placements[level]
		var/datum/space_sector/sector = level_sectors[level]
		var/list/edges = list()
		for(var/edge in level.neigbours)
			var/datum/space_level/neighbour = level.neigbours[edge]
			edges += "[space_grid_edge_name(edge)]->z[neighbour == level ? "сам" : neighbour.z_value]"
		. += "z=[level.z_value]\t([spot[1]], [spot[2]], этаж [spot[3]])\t[sector ? "сектор '[sector.id]'" : "без объявления"]\t[level.name]\t[length(edges) ? edges.Join(" ") : "соседей нет"]"

/// Имя стороны. Принимает и число, и строку: в neigbours числа сторон лежат строками.
/proc/space_grid_edge_name(edge)
	return dir2text_ru(isnum(edge) ? edge : text2num(edge)) || "сторона [edge]"

#undef SPACE_GRID_KEY
