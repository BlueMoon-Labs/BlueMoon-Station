// ═══════════════════════════════════════════════════
//  NtosSnake — Змейка для планшета
//  Классическая аркада. Управление через TGUI.
// ═══════════════════════════════════════════════════

#define SNAKE_GRID_W 20
#define SNAKE_GRID_H 15

#define SNAKE_DIR_UP    1
#define SNAKE_DIR_DOWN  2
#define SNAKE_DIR_LEFT  3
#define SNAKE_DIR_RIGHT 4

/datum/computer_file/program/snake
	filename = "ntsnake"
	filedesc = "Змейка"
	extended_desc = "Классическая аркада «Змейка». Собирайте еду, удлиняйтесь, не врезайтесь в стены и в себя!"
	requires_ntnet = FALSE
	size = 4
	tgui_id = "NtosSnake"
	program_icon = "worm"
	category = PROGRAM_CATEGORY_MISC
	available_on_ntnet = TRUE

	/// Текущее направление змейки
	var/current_dir = SNAKE_DIR_RIGHT
	/// Направление в очереди
	var/queued_dir = SNAKE_DIR_RIGHT
	/// Тело змейки: list(list("x"=X,"y"=Y)) — голова = body[body.len]
	var/list/body = list()
	/// Позиция еды list("x","y")
	var/list/food_pos = list()
	var/game_active = FALSE
	/// Пауза
	var/paused = FALSE
	/// Счёт
	var/score = 0
	/// Лучший счёт (за сессию)
	var/high_score = 0
	/// Причина смерти
	var/death_reason = ""
	/// Скорость (deciseconds между шагами)
	var/speed = 3
	/// ID таймера шага
	var/step_timer = null

/datum/computer_file/program/snake/kill_program(forced)
	game_active = FALSE
	stop_timer()
	. = ..()

/datum/computer_file/program/snake/proc/stop_timer()
	if(step_timer)
		deltimer(step_timer)
		step_timer = null

/datum/computer_file/program/snake/proc/schedule_step()
	stop_timer()
	if(game_active && !paused)
		step_timer = addtimer(CALLBACK(src, PROC_REF(on_tick)), speed, TIMER_STOPPABLE)
/datum/computer_file/program/snake/proc/start_game()
	body = list()
	var/start_x = round(SNAKE_GRID_W / 2)
	var/start_y = round(SNAKE_GRID_H / 2)
	body += list(list("x" = start_x - 2, "y" = start_y))
	body += list(list("x" = start_x - 1, "y" = start_y))
	body += list(list("x" = start_x, "y" = start_y))
	current_dir = SNAKE_DIR_RIGHT
	queued_dir = SNAKE_DIR_RIGHT
	score = 0
	death_reason = ""
	game_active = TRUE
	paused = FALSE
	speed = 3
	spawn_food()
	schedule_step()

/datum/computer_file/program/snake/proc/on_tick()
	step_timer = null
	if(!game_active || QDELETED(src))
		return
	if(!paused)
		step_game()
	SStgui.update_uis(src)
	schedule_step()

/datum/computer_file/program/snake/proc/spawn_food()
	var/list/free_cells = list()
	for(var/fx in 1 to SNAKE_GRID_W)
		for(var/fy in 1 to SNAKE_GRID_H)
			var/occupied = FALSE
			for(var/list/seg in body)
				if(seg["x"] == fx && seg["y"] == fy)
					occupied = TRUE
					break
			if(!occupied)
				free_cells += list(list("x" = fx, "y" = fy))
	if(!length(free_cells))
		game_over("Вы заполнили всё поле! Невероятно!")
		return
	food_pos = pick(free_cells)

/datum/computer_file/program/snake/proc/game_over(reason)
	game_active = FALSE
	stop_timer()
	death_reason = reason
	if(score > high_score)
		high_score = score
	if(computer)
		playsound(computer.loc, 'sound/arcade/lose.ogg', 50)

/datum/computer_file/program/snake/proc/step_game()
	if(!game_active || paused)
		return

	current_dir = queued_dir

	var/list/head = body[length(body)]
	var/nx = head["x"]
	var/ny = head["y"]
	switch(current_dir)
		if(SNAKE_DIR_UP)
			ny--
		if(SNAKE_DIR_DOWN)
			ny++
		if(SNAKE_DIR_LEFT)
			nx--
		if(SNAKE_DIR_RIGHT)
			nx++

	if(nx < 1 || nx > SNAKE_GRID_W || ny < 1 || ny > SNAKE_GRID_H)
		game_over("Врезались в стену!")
		return

	for(var/list/seg in body)
		if(seg["x"] == nx && seg["y"] == ny)
			game_over("Врезались в себя!")
			return

	var/list/new_head = list("x" = nx, "y" = ny)
	body += list(new_head)

	// Проверяем еду
	if(nx == food_pos["x"] && ny == food_pos["y"])
		score++
		if(computer)
			playsound(computer.loc, 'sound/arcade/mana.ogg', 30, TRUE)
		spawn_food()
		// Ускорение каждые 5 очков
		if(score % 5 == 0 && speed > 1)
			speed--
	else
		body.Cut(1, 2)

/datum/computer_file/program/snake/ui_data(mob/user)
	var/list/data = get_header_data()
	data["game_active"] = game_active
	data["paused"] = paused
	data["score"] = score
	data["high_score"] = high_score
	data["death_reason"] = death_reason
	data["grid_w"] = SNAKE_GRID_W
	data["grid_h"] = SNAKE_GRID_H
	data["body"] = body
	data["food"] = food_pos
	return data

/datum/computer_file/program/snake/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start")
			start_game()
			return TRUE
		if("pause")
			if(game_active)
				paused = !paused
				if(paused)
					stop_timer()
				else
					schedule_step()
			return TRUE
		if("dir")
			var/new_dir = text2num(params["dir"])
			if(!game_active || paused)
				return
			// Защита от разворота на 180°
			switch(new_dir)
				if(SNAKE_DIR_UP)
					if(current_dir != SNAKE_DIR_DOWN)
						queued_dir = new_dir
				if(SNAKE_DIR_DOWN)
					if(current_dir != SNAKE_DIR_UP)
						queued_dir = new_dir
				if(SNAKE_DIR_LEFT)
					if(current_dir != SNAKE_DIR_RIGHT)
						queued_dir = new_dir
				if(SNAKE_DIR_RIGHT)
					if(current_dir != SNAKE_DIR_LEFT)
						queued_dir = new_dir
			return TRUE

#undef SNAKE_GRID_W
#undef SNAKE_GRID_H
#undef SNAKE_DIR_UP
#undef SNAKE_DIR_DOWN
#undef SNAKE_DIR_LEFT
#undef SNAKE_DIR_RIGHT
