// ═══════════════════════════════════════════════════
//  NtosMinesweeper — Сапёр для планшета
//  Классический сапёр с тремя уровнями сложности.
// ═══════════════════════════════════════════════════

// Состояния клетки
#define MINE_HIDDEN   0  // Скрытая
#define MINE_REVEALED 1  // Открытая
#define MINE_FLAGGED  2  // Флажок

/datum/computer_file/program/minesweeper
	filename = "ntsweeper"
	filedesc = "Сапёр"
	extended_desc = "Классический «Сапёр». Найдите все мины, не подорвавшись! Три уровня сложности."
	requires_ntnet = FALSE
	size = 4
	tgui_id = "NtosMinesweeper"
	program_icon = "bomb"
	category = PROGRAM_CATEGORY_MISC
	available_on_ntnet = TRUE

	/// Ширина поля
	var/grid_w = 9
	/// Высота поля
	var/grid_h = 9
	/// Кол-во мин
	var/mine_count = 10
	/// Название сложности
	var/difficulty = "easy"

	/// Сетка мин: grid_data[y][x] = число мин вокруг, -1 = мина
	var/list/grid_data = list()
	/// Состояние клеток: cell_state[y][x] = MINE_HIDDEN / MINE_REVEALED / MINE_FLAGGED
	var/list/cell_state = list()

	/// Игра идёт?
	var/game_active = FALSE
	/// Первый ход? (мины генерируются после первого клика)
	var/first_click = TRUE
	/// Победа?
	var/game_won = FALSE
	/// Время старта
	var/start_time = 0
	/// Время окончания
	var/end_time = 0
	/// Поставлено флагов
	var/flags_placed = 0

/datum/computer_file/program/minesweeper/proc/start_game(diff)
	switch(diff)
		if("easy")
			grid_w = 9
			grid_h = 9
			mine_count = 10
			difficulty = "easy"
		if("medium")
			grid_w = 16
			grid_h = 16
			mine_count = 40
			difficulty = "medium"
		if("hard")
			grid_w = 20
			grid_h = 14
			mine_count = 60
			difficulty = "hard"
		else
			grid_w = 9
			grid_h = 9
			mine_count = 10
			difficulty = "easy"

	// Инициализация пустого поля
	grid_data = list()
	cell_state = list()
	for(var/y in 1 to grid_h)
		var/list/row_data = list()
		var/list/row_state = list()
		for(var/x in 1 to grid_w)
			row_data += 0
			row_state += MINE_HIDDEN
		grid_data += list(row_data)
		cell_state += list(row_state)

	game_active = TRUE
	first_click = TRUE
	game_won = FALSE
	flags_placed = 0
	start_time = world.time
	end_time = 0

/datum/computer_file/program/minesweeper/proc/place_mines(safe_x, safe_y)
	// Расставляем мины, оставляя зону 3x3 вокруг первого клика безопасной
	var/placed = 0
	while(placed < mine_count)
		var/mx = rand(1, grid_w)
		var/my = rand(1, grid_h)
		if(abs(mx - safe_x) <= 1 && abs(my - safe_y) <= 1)
			continue
		if(grid_data[my][mx] == -1)
			continue
		grid_data[my][mx] = -1
		placed++

	// Вычисляем числа
	for(var/y in 1 to grid_h)
		for(var/x in 1 to grid_w)
			if(grid_data[y][x] == -1)
				continue
			var/count = 0
			for(var/dy in -1 to 1)
				for(var/dx in -1 to 1)
					if(dx == 0 && dy == 0)
						continue
					var/nx = x + dx
					var/ny = y + dy
					if(nx >= 1 && nx <= grid_w && ny >= 1 && ny <= grid_h)
						if(grid_data[ny][nx] == -1)
							count++
			grid_data[y][x] = count

/datum/computer_file/program/minesweeper/proc/reveal_cell(x, y)
	if(x < 1 || x > grid_w || y < 1 || y > grid_h)
		return
	if(cell_state[y][x] != MINE_HIDDEN)
		return

	cell_state[y][x] = MINE_REVEALED

	// Если мина — проигрыш
	if(grid_data[y][x] == -1)
		game_over_lose()
		return

	if(grid_data[y][x] == 0)
		for(var/dy in -1 to 1)
			for(var/dx in -1 to 1)
				if(dx == 0 && dy == 0)
					continue
				reveal_cell(x + dx, y + dy)

	// Проверяем победу
	check_win()

/datum/computer_file/program/minesweeper/proc/chord_reveal(x, y)
	if(cell_state[y][x] != MINE_REVEALED)
		return
	var/value = grid_data[y][x]
	if(value <= 0)
		return

	var/flag_count = 0
	for(var/dy in -1 to 1)
		for(var/dx in -1 to 1)
			if(dx == 0 && dy == 0)
				continue
			var/nx = x + dx
			var/ny = y + dy
			if(nx >= 1 && nx <= grid_w && ny >= 1 && ny <= grid_h)
				if(cell_state[ny][nx] == MINE_FLAGGED)
					flag_count++

	if(flag_count == value)
		for(var/dy in -1 to 1)
			for(var/dx in -1 to 1)
				if(dx == 0 && dy == 0)
					continue
				var/nx = x + dx
				var/ny = y + dy
				if(nx >= 1 && nx <= grid_w && ny >= 1 && ny <= grid_h)
					if(cell_state[ny][nx] == MINE_HIDDEN)
						reveal_cell(nx, ny)

/datum/computer_file/program/minesweeper/proc/check_win()
	for(var/y in 1 to grid_h)
		for(var/x in 1 to grid_w)
			if(grid_data[y][x] != -1 && cell_state[y][x] != MINE_REVEALED)
				return // Ещё есть скрытые безопасные клетки
	game_won = TRUE
	game_active = FALSE
	end_time = world.time
	playsound(computer.loc, 'sound/arcade/win.ogg', 50)

/datum/computer_file/program/minesweeper/proc/game_over_lose()
	game_active = FALSE
	game_won = FALSE
	end_time = world.time
	// Показываем все мины
	for(var/y in 1 to grid_h)
		for(var/x in 1 to grid_w)
			if(grid_data[y][x] == -1)
				cell_state[y][x] = MINE_REVEALED
	playsound(computer.loc, 'sound/arcade/lose.ogg', 50)

/datum/computer_file/program/minesweeper/ui_data(mob/user)
	var/list/data = get_header_data()
	data["game_active"] = game_active
	data["game_won"] = game_won
	data["first_click"] = first_click
	data["grid_w"] = grid_w
	data["grid_h"] = grid_h
	data["mine_count"] = mine_count
	data["flags_placed"] = flags_placed
	data["difficulty"] = difficulty

	// Время
	if(game_active)
		data["elapsed"] = round((world.time - start_time) / 10)
	else if(end_time > 0)
		data["elapsed"] = round((end_time - start_time) / 10)
	else
		data["elapsed"] = 0

	// Сериализуем поле — отправляем только видимое
	var/list/rows = list()
	for(var/y in 1 to grid_h)
		var/list/row = list()
		for(var/x in 1 to grid_w)
			var/st = cell_state[y][x]
			if(st == MINE_REVEALED)
				row += grid_data[y][x]
			else if(st == MINE_FLAGGED)
				row += "F"
			else
				row += "H" // Hidden
		rows += list(row)
	data["grid"] = rows
	return data

/datum/computer_file/program/minesweeper/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start")
			var/diff = params["difficulty"] || "easy"
			start_game(diff)
			return TRUE
		if("reveal")
			if(!game_active)
				return
			var/cx = text2num(params["x"])
			var/cy = text2num(params["y"])
			if(!cx || !cy)
				return
			if(cx < 1 || cx > grid_w || cy < 1 || cy > grid_h)
				return
			// Первый клик — генерируем мины
			if(first_click)
				place_mines(cx, cy)
				first_click = FALSE
			reveal_cell(cx, cy)
			return TRUE
		if("flag")
			if(!game_active)
				return
			var/cx = text2num(params["x"])
			var/cy = text2num(params["y"])
			if(!cx || !cy)
				return
			if(cx < 1 || cx > grid_w || cy < 1 || cy > grid_h)
				return
			var/st = cell_state[cy][cx]
			if(st == MINE_HIDDEN)
				cell_state[cy][cx] = MINE_FLAGGED
				flags_placed++
			else if(st == MINE_FLAGGED)
				cell_state[cy][cx] = MINE_HIDDEN
				flags_placed--
			return TRUE
		if("chord")
			if(!game_active)
				return
			var/cx = text2num(params["x"])
			var/cy = text2num(params["y"])
			if(!cx || !cy)
				return
			if(cx < 1 || cx > grid_w || cy < 1 || cy > grid_h)
				return
			chord_reveal(cx, cy)
			return TRUE

#undef MINE_HIDDEN
#undef MINE_REVEALED
#undef MINE_FLAGGED
