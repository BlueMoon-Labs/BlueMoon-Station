#define HERETIC_MANSUS_ROOM_SIZE 33
#define HERETIC_MANSUS_GRID 4
#define HERETIC_MANSUS_CELL 7
#define HERETIC_MANSUS_CELL_STRIDE 8
#define HERETIC_MANSUS_EXTRA_EDGES 3

/// Комнаты 7x7, строки с севера на юг. Середины краёв всегда проходимы: там проёмы в соседние комнаты.
GLOBAL_LIST_INIT(heretic_mansus_templates, list(
	list(
		"...+...",
		".#.+.#.",
		"...+...",
		"+++++++",
		".n.+.V.",
		".#.+.#.",
		"...+...",
	),
	list(
		"...+...",
		".S+++S.",
		".+OOO+.",
		"++OOO++",
		".+OOO+.",
		".V+++n.",
		"...+...",
	),
	list(
		"...+...",
		".#.#.#.",
		".......",
		"+.#V#.+",
		".......",
		".#.#.#.",
		"n..+...",
	),
	list(
		"...+...",
		".###.#.",
		".#n..#.",
		"+..#..+",
		".#..V#.",
		".#.###.",
		"...+...",
	),
	list(
		"OO.+.OO",
		"O..+..O",
		"..S.S..",
		"++..V++",
		"..n....",
		"O.....O",
		"OO.+.OO",
	),
	list(
		".S.+.S.",
		".......",
		".S.n.S.",
		"+++++++",
		".S...S.",
		"..V....",
		".S.+.S.",
	),
	list(
		"#..+..#",
		".#...#.",
		"..#.#..",
		"+..V..+",
		"..#.#..",
		".#.n.#.",
		"#..+..#",
	),
	list(
		"...+...",
		".##.##.",
		".#...#.",
		"+..V..+",
		".#.n.#.",
		".##.##.",
		"...+...",
	),
	list(
		"OOO+OOO",
		"OO.+.OO",
		"O..+..O",
		"+++*+++",
		"O..+..O",
		"OO.n.OO",
		"OOO+OOO",
	),
	list(
		"n..+..n",
		".......",
		"..#.#..",
		"+.....+",
		"..#V#..",
		".......",
		"...+...",
	),
))

/// Ледяные комнаты: из любого проёма можно доскользить до осколка `*` и до любого другого проёма.
GLOBAL_LIST_INIT(heretic_mansus_ice_templates, list(
	list(
		"ii#iiii",
		"iiiiiii",
		"iii#iii",
		"i#iiiii",
		"#i#ii*i",
		"iiiiiii",
		"iiii#ii",
	),
	list(
		"iiiiiii",
		"i*ii#ii",
		"#iiii#i",
		"iiiii#i",
		"iii#ii#",
		"ii#iiii",
		"iiii#ii",
	),
	list(
		"#iii#ii",
		"ii*#iii",
		"iiiiiii",
		"iiii#ii",
		"i#iiii#",
		"iii#iii",
		"ii#iiii",
	),
	list(
		"iiiiiii",
		"i*iiiii",
		"ii#iii#",
		"iiii#ii",
		"iiiiiii",
		"iii##ii",
		"i#ii#ii",
	),
))

GLOBAL_LIST_INIT(heretic_mansus_gate_template, list(
	".......",
	"...G...",
	".......",
	"...D...",
	".......",
	".V...V.",
	"...+...",
))

GLOBAL_LIST_INIT(heretic_mansus_entry_template, list(
	".......",
	".S...S.",
	".......",
	"+..E..+",
	".......",
	".V...V.",
	".......",
))

/// Схема Дома 33x33: остовное дерево комнат 4x4, лишние проёмы и затворы, места осколков.
/datum/heretic_mansus_plan
	var/list/rows
	var/gate_cell
	var/entry_cell
	var/list/shard_cells = list()
	var/list/ice_cells = list()
	/// Ключи "x,y" (1..33, строки с севера) клеток льда, включая осколок на льду.
	var/list/ice_spots = list()
	/// Ключ "меньшая-большая ячейка" -> "open", "a" или "b".
	var/list/doors = list()

/datum/heretic_mansus_plan/proc/cell_index(column, row)
	return (row - 1) * HERETIC_MANSUS_GRID + column

/datum/heretic_mansus_plan/proc/cell_column(cell)
	return ((cell - 1) % HERETIC_MANSUS_GRID) + 1

/datum/heretic_mansus_plan/proc/cell_row(cell)
	return round((cell - 1) / HERETIC_MANSUS_GRID) + 1

/// Ячейка, которой принадлежит клетка раскладки; стены и проёмы не принадлежат ни одной.
/datum/heretic_mansus_plan/proc/cell_at(column, row)
	if((column - 1) % HERETIC_MANSUS_CELL_STRIDE == 0 || (row - 1) % HERETIC_MANSUS_CELL_STRIDE == 0)
		return null
	return cell_index(round((column - 2) / HERETIC_MANSUS_CELL_STRIDE) + 1, round((row - 2) / HERETIC_MANSUS_CELL_STRIDE) + 1)

/datum/heretic_mansus_plan/proc/cell_neighbors(cell)
	. = list()
	var/column = cell_column(cell)
	var/row = cell_row(cell)
	if(row > 1)
		. += cell - HERETIC_MANSUS_GRID
	if(row < HERETIC_MANSUS_GRID)
		. += cell + HERETIC_MANSUS_GRID
	if(column > 1)
		. += cell - 1
	if(column < HERETIC_MANSUS_GRID)
		. += cell + 1

/datum/heretic_mansus_plan/proc/door_key(first, second)
	return "[min(first, second)]-[max(first, second)]"

/// Расстояния в комнатах от ячейки по постоянным проёмам.
/datum/heretic_mansus_plan/proc/cell_distances(start)
	var/list/distances = list("[start]" = 0)
	var/list/frontier = list(start)
	var/index = 1
	while(index <= length(frontier))
		var/current = frontier[index++]
		for(var/neighbor in cell_neighbors(current))
			if(doors[door_key(current, neighbor)] != "open" || !isnull(distances["[neighbor]"]))
				continue
			distances["[neighbor]"] = distances["[current]"] + 1
			frontier += neighbor
	return distances

/datum/heretic_mansus_plan/proc/generate(ice_wanted = 0)
	var/cells_total = HERETIC_MANSUS_GRID * HERETIC_MANSUS_GRID
	gate_cell = cell_index(rand(2, 3), 1)
	entry_cell = cell_index(rand(2, 3), HERETIC_MANSUS_GRID)
	var/list/visited = list("[gate_cell]" = TRUE)
	var/list/stack = list(gate_cell)
	while(length(stack))
		var/current = stack[length(stack)]
		var/list/options = list()
		for(var/neighbor in cell_neighbors(current))
			if(!visited["[neighbor]"])
				options += neighbor
		if(!length(options))
			stack.len--
			continue
		var/next = pick(options)
		visited["[next]"] = TRUE
		doors[door_key(current, next)] = "open"
		stack += next
	var/list/spare = list()
	for(var/cell in 1 to cells_total)
		for(var/neighbor in cell_neighbors(cell))
			if(neighbor > cell && !doors[door_key(cell, neighbor)])
				spare += door_key(cell, neighbor)
	spare = shuffle(spare)
	var/list/extra_kinds = list("a", "b", "open")
	for(var/index in 1 to min(HERETIC_MANSUS_EXTRA_EDGES, length(spare)))
		doors[spare[index]] = extra_kinds[index]
	choose_shards()
	var/list/candidates = list()
	for(var/cell in 1 to cells_total)
		if(cell != gate_cell && cell != entry_cell && cell != shard_cells[1])
			candidates += cell
	var/list/ice_order = list(shard_cells[2], shard_cells[3]) + shuffle(candidates - shard_cells)
	for(var/index in 1 to min(ice_wanted, length(ice_order)))
		ice_cells += ice_order[index]
	build_rows()

/datum/heretic_mansus_plan/proc/choose_shards()
	var/list/gate_distances = cell_distances(gate_cell)
	var/list/near = list()
	for(var/neighbor in cell_neighbors(gate_cell))
		if(doors[door_key(gate_cell, neighbor)] == "open" && neighbor != entry_cell)
			near += neighbor
	var/first = pick(near)
	var/list/candidates = list()
	for(var/cell in 1 to HERETIC_MANSUS_GRID * HERETIC_MANSUS_GRID)
		if(cell != gate_cell && cell != entry_cell && cell != first)
			candidates += cell
	candidates = shuffle(candidates)
	var/far
	for(var/cell in candidates)
		if(!far || gate_distances["[cell]"] > gate_distances["[far]"])
			far = cell
	var/list/far_distances = cell_distances(far)
	var/other
	for(var/cell in candidates)
		if(cell == far)
			continue
		if(!other || gate_distances["[cell]"] + far_distances["[cell]"] > gate_distances["[other]"] + far_distances["[other]"])
			other = cell
	shard_cells = list(first, far, other)

/datum/heretic_mansus_plan/proc/rotate_template(list/template)
	. = list()
	for(var/row in 1 to HERETIC_MANSUS_CELL)
		var/line = ""
		for(var/column in 1 to HERETIC_MANSUS_CELL)
			var/source = template[HERETIC_MANSUS_CELL + 1 - column]
			line += copytext(source, row, row + 1)
		. += line

/datum/heretic_mansus_plan/proc/random_variant(list/template)
	var/list/variant = template.Copy()
	for(var/turn in 1 to rand(0, 3))
		variant = rotate_template(variant)
	if(prob(50))
		var/list/mirrored = list()
		for(var/line in variant)
			mirrored += reverse_text(line)
		variant = mirrored
	return variant

/datum/heretic_mansus_plan/proc/build_rows()
	var/list/grid = list()
	for(var/row in 1 to HERETIC_MANSUS_ROOM_SIZE)
		var/list/line = list()
		for(var/column in 1 to HERETIC_MANSUS_ROOM_SIZE)
			line += "#"
		grid += list(line)
	for(var/cell in 1 to HERETIC_MANSUS_GRID * HERETIC_MANSUS_GRID)
		var/list/template
		var/ice = (cell in ice_cells)
		if(cell == gate_cell)
			template = GLOB.heretic_mansus_gate_template
		else if(cell == entry_cell)
			template = GLOB.heretic_mansus_entry_template
		else
			template = random_variant(pick(ice ? GLOB.heretic_mansus_ice_templates : GLOB.heretic_mansus_templates))
		var/left = 2 + (cell_column(cell) - 1) * HERETIC_MANSUS_CELL_STRIDE
		var/top = 2 + (cell_row(cell) - 1) * HERETIC_MANSUS_CELL_STRIDE
		var/shard_index = shard_cells.Find(cell)
		var/list/shard_spots = list()
		for(var/row in 1 to HERETIC_MANSUS_CELL)
			for(var/column in 1 to HERETIC_MANSUS_CELL)
				var/tile = copytext(template[row], column, column + 1)
				if(tile == "*" || (shard_index && !ice && (tile == "." || tile == "+") && !near_cell_edge(column, row)))
					shard_spots += list(list(column, row, tile == "*"))
				if(tile == "*")
					tile = ice ? "i" : "."
				grid[top + row - 1][left + column - 1] = tile
		if(!shard_index || !length(shard_spots))
			continue
		var/list/spot = shard_spots[1]
		if(!spot[3])
			spot = pick(shard_spots)
		grid[top + spot[2] - 1][left + spot[1] - 1] = "[shard_index]"
		if(ice)
			ice_spots["[left + spot[1] - 1],[top + spot[2] - 1]"] = TRUE
	for(var/key in doors)
		var/list/pair = splittext(key, "-")
		var/first = text2num(pair[1])
		var/second = text2num(pair[2])
		var/kind = doors[key]
		var/tile = kind == "open" ? "+" : kind
		if(second == first + 1)
			grid[3 + (cell_row(first) - 1) * HERETIC_MANSUS_CELL_STRIDE + 2][1 + cell_column(first) * HERETIC_MANSUS_CELL_STRIDE] = tile
		else
			grid[1 + cell_row(first) * HERETIC_MANSUS_CELL_STRIDE][3 + (cell_column(first) - 1) * HERETIC_MANSUS_CELL_STRIDE + 2] = tile
	rows = list()
	for(var/list/line as anything in grid)
		rows += jointext(line, "")

/// Осколок не кладётся в проём и на клетку сразу за ним.
/datum/heretic_mansus_plan/proc/near_cell_edge(column, row)
	var/middle = (HERETIC_MANSUS_CELL + 1) / 2
	return (column == middle && (row <= 2 || row >= HERETIC_MANSUS_CELL - 1)) || (row == middle && (column <= 2 || column >= HERETIC_MANSUS_CELL - 1))

/// Восстанавливает схему по готовой раскладке: врата, вход, проёмы, осколки и лёд.
/datum/heretic_mansus_plan/proc/parse(list/source_rows)
	rows = source_rows.Copy()
	doors = list()
	shard_cells = list(null, null, null)
	ice_cells = list()
	ice_spots = list()
	var/list/shard_spots = list(null, null, null)
	for(var/row in 1 to HERETIC_MANSUS_ROOM_SIZE)
		for(var/column in 1 to HERETIC_MANSUS_ROOM_SIZE)
			var/tile = copytext(rows[row], column, column + 1)
			if(tile == "#" || tile == "O")
				continue
			var/cell = cell_at(column, row)
			if(cell)
				switch(tile)
					if("G")
						gate_cell = cell
					if("E")
						entry_cell = cell
					if("i")
						ice_cells |= cell
					if("1", "2", "3")
						shard_cells[text2num(tile)] = cell
						shard_spots[text2num(tile)] = "[column],[row]"
				continue
			var/kind = (tile == "a" || tile == "b") ? tile : "open"
			if((column - 1) % HERETIC_MANSUS_CELL_STRIDE == 0)
				doors[door_key(cell_at(column - 1, row), cell_at(column + 1, row))] = kind
			else
				doors[door_key(cell_at(column, row - 1), cell_at(column, row + 1))] = kind
	for(var/index in 1 to length(shard_cells))
		if(shard_cells[index] in ice_cells)
			ice_spots[shard_spots[index]] = TRUE
