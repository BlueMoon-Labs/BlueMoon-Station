#define MATH_REWARD_EASY  1
#define MATH_REWARD_MEDIUM  2.5
#define MATH_REWARD_HARD  5

#define MATH_MULTIPLIER_SCIENCE  750
#define MATH_MULTIPLIER_CARGO  500

// Мини-игры

#define MINIGAME_MATH "math"
#define MINIGAME_WIRES "wires"
#define MINIGAME_SIGNAL "signal"

/obj/item/computermath
	icon = 'modular_sand/icons/obj/computermath.dmi'
	verb_say = "beeps"
	var/charge_count
	// Стейты
	var/current_screen = "menu" // "menu", "game", "result"
	var/current_game = null
	var/current_difficulty = null // "Easy", "Medium", "Hard"
	var/reward_type = null // "Science", "Cargo"
	// Дата
	var/game_question = null
	var/list/game_solution = null // Лист мульти-ответов.
	var/list/game_data = null
	var/last_result = null // "correct", "incorrect"
	var/last_points = 0
	var/last_message = ""

/obj/item/computermath/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/computermath/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/computermath/proc/check_charges()
	return FALSE

/obj/item/computermath/proc/consume_charges()
	return FALSE

/obj/item/computermath/proc/get_charges()
	return 0

/obj/item/computermath/proc/get_max_charges()
	return 0

// ТГУИ

/obj/item/computermath/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ProblemComputer")
		ui.open()

/obj/item/computermath/ui_data(mob/user)
	var/list/data = list()
	data["screen"] = current_screen
	data["currentGame"] = current_game
	data["difficulty"] = current_difficulty
	data["rewardType"] = reward_type
	data["charges"] = get_charges()
	data["maxCharges"] = get_max_charges()
	data["lastResult"] = last_result
	data["lastPoints"] = last_points
	data["lastMessage"] = last_message

	// Костыль
	if(current_screen == "game" && game_data)
		data["gameData"] = game_data

	return data

/obj/item/computermath/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_game")
			var/game = params["game"]
			if(game in list(MINIGAME_MATH, MINIGAME_WIRES, MINIGAME_SIGNAL))
				current_game = game
				current_screen = "game"
				current_difficulty = params["difficulty"]
				if(!(current_difficulty in list("Easy", "Medium", "Hard")))
					current_difficulty = "Easy"
				if(!check_charges())
					current_screen = "menu"
					current_game = null
					say("Нет доступных задач. Попробуйте позже.")
					playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)
					return TRUE
				generate_game()
			. = TRUE

		if("submit_answer")
			if(current_screen != "game" || !current_game)
				return TRUE
			var/correct = check_answer(params)
			// Всегда обновляем last_result чтобы TGUI показывал верный/неверный
			if(correct)
				last_result = "correct"
			else
				last_result = "incorrect"
			if(consume_charges())
				handle_reward(usr, reward_type, correct, current_difficulty)
			else
				last_points = 0
				if(correct)
					last_message = "Ответ верный, но заряды закончились — награда не выдана."
				else
					last_message = "Ответ неверный, заряды закончились."
				say("Ошибка: задачи закончились во время решения.")
				playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)
			current_screen = "result"
			. = TRUE

		if("back_to_menu")
			current_screen = "menu"
			current_game = null
			current_difficulty = null
			game_question = null
			game_solution = null
			game_data = null
			last_result = null
			. = TRUE

		if("play_again")
			if(!check_charges())
				current_screen = "menu"
				current_game = null
				say("Нет доступных задач. Попробуйте позже.")
				playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)
				return TRUE
			generate_game()
			current_screen = "game"
			last_result = null
			. = TRUE

// Основные генерации
/obj/item/computermath/proc/generate_game()
	game_data = list()
	game_solution = list()
	switch(current_game)
		if(MINIGAME_MATH)
			generate_math()
		if(MINIGAME_WIRES)
			generate_wires()
		if(MINIGAME_SIGNAL)
			generate_signal()

// Математика
/obj/item/computermath/proc/math_floor(x)
	var/r = round(x)
	if(r > x)
		return r - 1
	return r

/obj/item/computermath/proc/fmt_num(var/n)
	if(n < 0)
		return "([n])"
	return "[n]"

/obj/item/computermath/proc/generate_math()
	var/operator
	switch(current_difficulty)
		if("Easy")
			operator = pick("add", "subtract", "multiply")
		if("Medium")
			operator = pick("division", "exponent", "easy algebra")
		if("Hard")
			operator = pick("2nd polynomial", "algebra", "line intersection")

	var/question
	var/solution
	var/solution2 = null

	switch(operator)
		if("add")
			var/addnum_1 = rand(1, 500)
			var/addnum_2 = rand(1, 500)
			question = "Чему равно [addnum_1] + [addnum_2]?"
			solution = addnum_1 + addnum_2
		if("subtract")
			var/subnum_1 = rand(-100, 100)
			var/subnum_2 = rand(-100, 200)
			question = "Чему равно [fmt_num(subnum_1)] - [fmt_num(subnum_2)]?"
			solution = subnum_1 - subnum_2
		if("multiply")
			var/multnum_1 = rand(-50, 50)
			var/multnum_2 = rand(-250, 500)
			question = "Чему равно [fmt_num(multnum_1)] * [fmt_num(multnum_2)]?"
			solution = multnum_1 * multnum_2
		if("division")
			var/divnum_2 = rand(3, 12)
			var/divnum_1 = rand(-50, 50) * divnum_2
			question = "Чему равно [fmt_num(divnum_1)] / [fmt_num(divnum_2)]? Ответ округлите вниз."
			solution = math_floor(divnum_1 / divnum_2)
		if("exponent")
			var/expnum_1 = rand(-50, 50)
			var/expnum_2 = pick(list(2, 3, 1/2))
			if(expnum_2 == 1/2)
				question = "Чему равно sqrt([abs(expnum_1)])? Ответ округлите вниз."
				solution = math_floor(sqrt(abs(expnum_1)))
			else
				question = "Чему равно [fmt_num(expnum_1)]^[expnum_2]? Ответ округлите вниз."
				solution = math_floor(expnum_1 ** expnum_2)
		if("easy algebra")
			var/num_a = rand(1, 5)
			var/num_b = rand(-5, 10)
			var/num_c = rand(-10, 10)
			question = "[num_a]x + [fmt_num(num_b)] = [fmt_num(num_c)]. Найдите x. Округлите вниз."
			solution = math_floor((num_c - num_b) / num_a)
		if("algebra")
			if(prob(50))
				var/alg_a = rand(-100, 100)
				var/alg_b = rand(-5, 5)
				if(alg_b == 0)
					alg_b = 12
				var/alg_c = rand(1, 10)
				question = "[fmt_num(alg_a)]/([fmt_num(alg_b)]x) = [fmt_num(alg_c)]. Найдите x. Округлите вниз."
				solution = math_floor(alg_a / (alg_b * alg_c))
			else
				var/alg2_a = rand(-50, 50)
				var/alg2_b = rand(1, 5)
				var/alg2_c = rand(1, 10)
				question = "([fmt_num(alg2_a)]-x)/[alg2_b] = x/[alg2_c]. Найдите x. Округлите вниз."
				solution = math_floor((alg2_a * alg2_c) / (alg2_b + alg2_c))
		if("2nd polynomial")
			var/poly_a = rand(1, 2)
			var/poly_b = rand(-5, 5)
			var/poly_c = rand(-25, 25)
			var/discriminant = poly_b**2 - 4 * poly_a * poly_c
			if(discriminant >= 0)
				solution = math_floor((-poly_b + sqrt(discriminant)) / (2 * poly_a))
				solution2 = math_floor((-poly_b - sqrt(discriminant)) / (2 * poly_a))
			else
				solution = 0
				solution2 = 0
			question = "[poly_a]x^2 + [fmt_num(poly_b)]x + [fmt_num(poly_c)] = 0. Найдите x (любое вещественное решение). 0 если нет решений. Округлите вниз."
		if("line intersection")
			var/line_a = rand(-5, 5)
			var/line_b = rand(-5, 5)
			var/line_c = rand(-5, 5)
			var/line_d = rand(-5, 5)
			var/x_int
			var/y_int
			if(line_a - line_c != 0)
				x_int = math_floor((line_d - line_b) / (line_a - line_c))
				y_int = math_floor(line_a * (line_d - line_b) / (line_a - line_c) + line_b)
			else
				x_int = 0
				y_int = 0
			var/expected_var
			if(prob(50))
				solution = x_int
				expected_var = "x"
			else
				solution = y_int
				expected_var = "y"
			question = "Прямые y=[fmt_num(line_a)]x+[fmt_num(line_b)] и y=[fmt_num(line_c)]x+[fmt_num(line_d)]. Найдите [expected_var]-координату пересечения. 0 если нет. Округлите вниз."

	game_data["question"] = question
	game_solution = list("[solution]")
	if(solution2 != null)
		game_solution += "[solution2]"

// Соединение линий
/obj/item/computermath/proc/generate_wires()
	var/num_pairs
	var/grid_size
	switch(current_difficulty)
		if("Easy")
			num_pairs = 3
			grid_size = 4
		if("Medium")
			num_pairs = 4
			grid_size = 5
		if("Hard")
			num_pairs = 5
			grid_size = 6

	var/list/colors = list("red", "blue", "green", "yellow", "purple", "orange", "cyan")
	var/list/pairs = list()
	var/list/used_positions = list()
	for(var/i in 1 to num_pairs)
		var/color = pick_n_take(colors)
		var/list/pos1 = generate_unique_pos(grid_size, used_positions)
		used_positions += list(pos1)
		var/list/pos2 = generate_unique_pos(grid_size, used_positions)
		used_positions += list(pos2)
		pairs += list(list(
			"color" = color,
			"id" = i,
			"start" = list("x" = pos1[1], "y" = pos1[2]),
			"end" = list("x" = pos2[1], "y" = pos2[2])
		))

	game_data["gridSize"] = grid_size
	game_data["pairs"] = pairs
	game_solution = list("wire_valid")

/obj/item/computermath/proc/generate_unique_pos(grid_size, list/used)
	var/attempts = 0
	while(attempts < 100)
		var/x = rand(0, grid_size - 1)
		var/y = rand(0, grid_size - 1)
		var/pos_key = "[x],[y]"
		var/found = FALSE
		for(var/list/p in used)
			var/px = p[1]
			var/py = p[2]
			if("[px],[py]" == pos_key)
				found = TRUE
				break
		if(!found)
			return list(x, y)
		attempts++
	return list(0, 0)

// Декод сигнала игра
/obj/item/computermath/proc/generate_signal()
	var/list/sequence = list()
	var/answer
	var/hint

	switch(current_difficulty)
		if("Easy")
			// Simple arithmetic progression
			var/ap_start = rand(1, 20)
			var/ap_step = rand(2, 8)
			for(var/i in 0 to 4)
				sequence += ap_start + ap_step * i
			answer = ap_start + ap_step * 5
			hint = "Арифметическая прогрессия"
		if("Medium")
			var/med_type = rand(1, 3)
			switch(med_type)
				if(1) // Геометрическая прогрессия
					var/gp_start = rand(1, 5)
					var/gp_ratio = rand(2, 4)
					for(var/i in 0 to 4)
						sequence += gp_start * (gp_ratio ** i)
					answer = gp_start * (gp_ratio ** 5)
					hint = "Геометрическая прогрессия"
				if(2) // Альтернативный мультиплай
					var/alt_val = rand(1, 5)
					var/alt_add = rand(1, 5)
					var/alt_mult = rand(2, 3)
					for(var/i in 0 to 5)
						sequence += alt_val
						if(i % 2 == 0)
							alt_val += alt_add
						else
							alt_val *= alt_mult
					answer = alt_val
					hint = "Чередование операций"
				if(3) // Последовательность Фибоначчи Бля впервые мне понадобилась вышка
					var/fib_a = rand(1, 5)
					var/fib_b = rand(1, 5)
					sequence += fib_a
					sequence += fib_b
					for(var/i in 1 to 4)
						var/fib_c = fib_a + fib_b
						sequence += fib_c
						fib_a = fib_b
						fib_b = fib_c
					answer = fib_a + fib_b
					hint = "Последовательность Фибоначчи"
		if("Hard")
			var/hard_type = rand(1, 3)
			switch(hard_type)
				if(1) // Квадрат
					var/sq_offset = rand(-5, 5)
					for(var/i in 1 to 5)
						sequence += i * i + sq_offset
					answer = 36 + sq_offset
					hint = "Квадратичная зависимость"
				if(2) // КУбы
					for(var/i in 1 to 5)
						sequence += i ** 3
					answer = 6 ** 3
					hint = "Кубическая зависимость"
				if(3) // Треугольные
					for(var/i in 1 to 5)
						sequence += (i * (i + 1)) / 2
					answer = (6 * 7) / 2
					hint = "Треугольные числа"

	game_data["sequence"] = sequence
	game_data["hint"] = hint
	game_solution = list("[answer]")

// Проверка ответов
/obj/item/computermath/proc/check_answer(list/params)
	var/user_answer
	switch(current_game)
		if(MINIGAME_MATH)
			if(!length(game_solution))
				return FALSE
			user_answer = params["answer"]
			if(!isnum(user_answer))
				user_answer = text2num(user_answer)
			if(isnull(user_answer))
				return FALSE
			user_answer = math_floor(user_answer)
			for(var/sol in game_solution)
				if(user_answer == text2num(sol))
					return TRUE
			return FALSE

		if(MINIGAME_WIRES)
			var/list/connections = params["connections"]
			if(!islist(connections))
				return FALSE
			var/list/wire_pairs = game_data["pairs"]
			if(length(connections) != length(wire_pairs))
				return FALSE
			for(var/list/pair in wire_pairs)
				var/pair_id = "[pair["id"]]"
				var/found = FALSE
				for(var/list/conn in connections)
					if("[conn["id"]]" == pair_id)
						found = TRUE
						break
				if(!found)
					return FALSE
			return TRUE

		if(MINIGAME_SIGNAL)
			if(!length(game_solution))
				return FALSE
			user_answer = params["answer"]
			if(!isnum(user_answer))
				user_answer = text2num(user_answer)
			if(isnull(user_answer))
				return FALSE
			return (math_floor(user_answer) == text2num(game_solution[1]))

	return FALSE

// Математика
/obj/item/computermath/proc/handle_reward(mob/user, var/reward_type, var/correct, var/difficulty)
	var/mob/living/LM = user
	var/points_awarded
	switch(difficulty)
		if("Easy")
			points_awarded = MATH_REWARD_EASY
		if("Medium")
			points_awarded = MATH_REWARD_MEDIUM
		if("Hard")
			points_awarded = MATH_REWARD_HARD
	switch(reward_type)
		if("Cargo")
			points_awarded *= MATH_MULTIPLIER_CARGO
		if("Science")
			points_awarded *= MATH_MULTIPLIER_SCIENCE

	if(!correct)
		var/points_lost = points_awarded / 4
		last_result = "incorrect"
		last_points = points_lost
		switch(reward_type)
			if("Science")
				last_message = "Исследовательские данные были повреждены. Утеряно [points_lost] очков исследования."
				SSresearch.science_tech.remove_point_list(list(TECHWEB_POINT_TYPE_GENERIC = points_lost))
			if("Cargo")
				last_message = "Бюрократическая ошибка. Списано [points_lost] очков карго."
				var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
				if(D)
					D.adjust_money(-points_lost)
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, 1)
		if(difficulty == "Easy")
			to_chat(user, span_warning("Вы чувствуете грусть, провалив такую простую задачу..."))
			SEND_SIGNAL(LM, COMSIG_ADD_MOOD_EVENT, "failed_easy", /datum/mood_event/failed_easy)
		return

	last_result = "correct"
	last_points = points_awarded
	switch(reward_type)
		if("Science")
			last_message = "Данные корректны! Начислено [points_awarded] очков исследования."
			SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = points_awarded))
		if("Cargo")
			last_message = "Данные корректны! Начислено [points_awarded] очков карго."
			var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if(D)
				D.adjust_money(points_awarded)
	say("Задача решена верно! Начислено [points_awarded] очков.")
	playsound(src, 'sound/machines/chime.ogg', 30, 1)

// Subtypes
/obj/item/computermath/default
	name = "Problem Computer"
	desc = "Проблемный компьютер. Зарабатывайте очки, решая мини-игры. Необходимо назначить отдел."
	icon_state = "defaulttab"

	var/static/radial_cargo = image(icon = 'modular_sand/icons/obj/computermath.dmi', icon_state = "cargotab")
	var/static/radial_science = image(icon = 'modular_sand/icons/obj/computermath.dmi', icon_state = "sciencetab")
	var/static/list/radial_options = list("cargo" = radial_cargo, "science" = radial_science)

/obj/item/computermath/default/attack_self(mob/user)
	var/choice = show_radial_menu(user, src, radial_options)
	switch(choice)
		if("cargo")
			var/obj/item/computermath/cargo/CT = new /obj/item/computermath/cargo(drop_location())
			qdel(src)
			user.put_in_active_hand(CT)
		if("science")
			var/obj/item/computermath/science/ST = new /obj/item/computermath/science(drop_location())
			qdel(src)
			user.put_in_active_hand(ST)

/obj/item/computermath/cargo
	name = "Cargo Problem Computer"
	desc = "Проблемный компьютер карго-отдела. Решайте мини-игры для получения очков."
	icon_state = "cargotab"
	reward_type = "Cargo"

/obj/item/computermath/cargo/attack_self(mob/user)
	ui_interact(user)

/obj/item/computermath/cargo/process()
	var/old_charge_count = charge_count
	charge_count = SSshuttle.problem_computer_charges
	if(charge_count > old_charge_count)
		say("Для решения стали доступны новые задачи! На данный момент доступно [charge_count] задач.")

/obj/item/computermath/cargo/check_charges()
	if(SSshuttle.problem_computer_charges > 0)
		return TRUE
	return FALSE

/obj/item/computermath/cargo/consume_charges()
	if(SSshuttle.problem_computer_charges > 0)
		SSshuttle.problem_computer_charges -= 1
		return TRUE
	return FALSE

/obj/item/computermath/cargo/get_charges()
	return SSshuttle.problem_computer_charges

/obj/item/computermath/cargo/get_max_charges()
	return SSshuttle.problem_computer_max_charges

/obj/item/computermath/science
	name = "Science Problem Computer"
	desc = "Проблемный компьютер научного отдела. Решайте мини-игры для получения очков."
	icon_state = "sciencetab"
	reward_type = "Science"

/obj/item/computermath/science/attack_self(mob/user)
	ui_interact(user)

/obj/item/computermath/science/process()
	var/old_charge_count = charge_count
	charge_count = SSresearch.problem_computer_charges
	if(charge_count > old_charge_count)
		say("Для решения стали доступны новые задачи! На данный момент доступно [charge_count] задач.")

/obj/item/computermath/science/check_charges()
	if(SSresearch.problem_computer_charges > 0)
		return TRUE
	return FALSE

/obj/item/computermath/science/consume_charges()
	if(SSresearch.problem_computer_charges > 0)
		SSresearch.problem_computer_charges -= 1
		return TRUE
	return FALSE

/obj/item/computermath/science/get_charges()
	return SSresearch.problem_computer_charges

/obj/item/computermath/science/get_max_charges()
	return SSresearch.problem_computer_max_charges
