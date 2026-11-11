/// Всё, что ближе этого, считаем нулевой целью рыбы
#define FISH_TARGET_MIN_DISTANCE 6
/// Трение для прыжков рыбы, чтобы она постепенно замедлялась
#define FISH_FRICTION_MULT 0.9
/// По нему решаем, может ли рыба прыгнуть в выбранном направлении
#define FISH_SHORT_JUMP_MIN_DISTANCE 100
/// Предел дистанции короткого прыжка
#define FISH_SHORT_JUMP_MAX_DISTANCE 200

/// Движение рыбы - это простые датумы. Мини-игра рыбалки создаёт их и по ним понимает, как рыба себя ведёт.
/datum/fish_movement
	/// Мини-игра, которая породила этот датум
	var/datum/fishing_challenge/master
	/// Сколько раз уже дёрнули move_fish()
	var/times_fired = 0
	/// Шанс обычного прыжка рыбы, потом умножается на сложность
	var/short_jump_chance = 2.25
	/// Шанс длинного прыжка рыбы, потом умножается на сложность
	var/long_jump_chance = 0.0625
	/// Потолок скорости для короткого прыжка
	var/short_jump_velocity_limit = 400
	/// Потолок скорости для длинного прыжка
	var/long_jump_velocity_limit = 200
	/// Текущий потолок скорости
	var/current_velocity_limit
	/// Базовая скорость рыбы. От неё зависят дистанция прыжков и скорость падения.
	var/fish_idle_velocity = 0
	/// Куда на шкале стремится рыба
	var/target_position
	/// Если true, рыба может прыгнуть и перебить заданную цель
	var/can_interrupt_move = TRUE
	/// Текущая скорость рыбы
	var/fish_velocity = 0

/datum/fish_movement/New(datum/fishing_challenge/master)
	src.master = master

/**
 * Процедура подгоняет параметры движения под сложность мини-игры.
 * Вычисления выглядят мудрёно, но по сути дают плавный рост шанса
 * прыжка при вероятности выше 1%, чтобы на пике сложности он
 * всё равно дошёл до 100%.
 */
/datum/fish_movement/proc/adjust_to_difficulty()
	var/square_angle_rad = TORADIANS(90)
	var/zero_one_difficulty = master.difficulty/100
	if(short_jump_chance > 1)
		short_jump_chance = (zero_one_difficulty**(square_angle_rad-TORADIANS(arctan(short_jump_chance * 1/square_angle_rad))))*100
	else
		short_jump_chance *= master.difficulty
	if(long_jump_chance > 1)
		long_jump_chance = (zero_one_difficulty**(square_angle_rad-TORADIANS(arctan(long_jump_chance * 1/square_angle_rad))))*100
	else
		long_jump_chance *= master.difficulty

/datum/fish_movement/proc/reset_difficulty_values()
	short_jump_chance = initial(short_jump_chance)
	long_jump_chance = initial(long_jump_chance)

/// Главная процедура. Мини-игра зовёт её каждый тик SSfishing в фазе 'active'.
/datum/fish_movement/proc/move_fish(seconds_per_tick)
	times_fired++
	/**
	 * Шанс прыжка проверяем каждый нечётный тик, то есть раз в децисекунду.
	 * Каждый тик нельзя, иначе рыба запрыгает чаще задуманного. И делить
	 * шанс пополам под тик тоже нельзя, иначе максимум просядет
	 * со 100% до 75%.
	 */
	var/can_roll = times_fired % 2

	var/long_chance = long_jump_chance * seconds_per_tick * (1/seconds_per_tick)
	var/short_chance = short_jump_chance * seconds_per_tick * (1/seconds_per_tick)

	// Цель есть, но мы уже близко. Значит, считаем её достигнутой
	if(abs(target_position - master.fish_position) < FISH_TARGET_MIN_DISTANCE)
		target_position = null

	// Новая цель длинного прыжка может перебить любую другую
	if(can_roll && (can_interrupt_move || isnull(target_position)) && prob(long_chance))
		/**
		 * Уходим на 0.75-1.0 доступной шкалы в выбранную сторону,
		 * причём охотнее туда, где больше места
		 */
		var/distance_from_top = FISHING_MINIGAME_AREA - master.fish_position - master.fish_height
		var/distance_from_bottom = master.fish_position
		var/top_chance
		if(distance_from_top < FISH_SHORT_JUMP_MIN_DISTANCE)
			top_chance = 0
		else
			top_chance = (distance_from_top/max(distance_from_bottom, 1)) * 100
		var/new_target = master.fish_position
		if(prob(top_chance))
			new_target += distance_from_top * rand(75, 100)/100
		else
			new_target -= distance_from_bottom * rand(75, 100)/100
		target_position = round(new_target)
		current_velocity_limit = long_jump_velocity_limit

	// Идём к цели
	if(!isnull(target_position))
		var/distance = target_position - master.fish_position
		// грубо 5 при сложности 15, 10 при 30, 30 при 100
		var/acceleration_mult = get_acceleration(seconds_per_tick)
		var/target_acceleration = distance * acceleration_mult * seconds_per_tick

		if(fish_idle_velocity)
			var/idle_velocity = fish_idle_velocity
			var/abs_idle_vel = abs(idle_velocity)
			// Проследим, чтобы скорость покоя не застопорила рыбу намертво.
			// Сперва смотрим, не смотрят ли две силы в разные стороны
			if((idle_velocity / abs_idle_vel) != (target_acceleration / abs(target_acceleration)))
				// Дальше берём отношение модуля скорости покоя к половинному множителю ускорения.
				var/halved_ratio = (acceleration_mult * 0.5) / abs_idle_vel
				/**
				 * Если скорость покоя больше половины ускорения, гасим ускорение
				 * степенями, по чуть-чуть за каждую лишнюю единицу скорости покоя.
				 * Так ускорение никогда не станет нулём, но крайние значения будут его грызть.
				 */
				if(halved_ratio < 1)
					var/power = min(halved_ratio + 0.5, 1)
					target_acceleration *= 1 - (halved_ratio^power)
				/**
				 * Иначе просто прибавляем скорость покоя к целевой скорости.
				 * Она точно противоположного знака и по модулю от 0.ε до 0.5
				 */
				else
					target_acceleration += idle_velocity

		fish_velocity = fish_velocity * FISH_FRICTION_MULT + target_acceleration

	else if(can_roll && prob(short_chance))
		var/distance_from_top = FISHING_MINIGAME_AREA - master.fish_position - master.fish_height
		var/distance_from_bottom = master.fish_position
		var/jump_length
		if(distance_from_top >= FISH_SHORT_JUMP_MIN_DISTANCE)
			jump_length = rand(FISH_SHORT_JUMP_MIN_DISTANCE, FISH_SHORT_JUMP_MAX_DISTANCE)
		if(distance_from_bottom >= FISH_SHORT_JUMP_MIN_DISTANCE && (!jump_length || prob(50)))
			jump_length = -rand(FISH_SHORT_JUMP_MIN_DISTANCE, FISH_SHORT_JUMP_MAX_DISTANCE)
		target_position = clamp(master.fish_position + jump_length, 0, FISHING_MINIGAME_AREA - master.fish_height)
		current_velocity_limit = short_jump_velocity_limit

	fish_velocity = clamp(fish_velocity, -current_velocity_limit, current_velocity_limit)
	set_fish_position(seconds_per_tick)

/// Возвращает ускорение рыбы в мини-игре.
/datum/fish_movement/proc/get_acceleration(seconds_per_tick)
	return 0.3 * master.difficulty + 0.5

/// Зовётся в конце move_fish(), чтобы сдвинуть рыбу в мини-игре рыбалки.
/datum/fish_movement/proc/set_fish_position(seconds_per_tick)
	master.fish_position = clamp(master.fish_position + fish_velocity * seconds_per_tick, 0, FISHING_MINIGAME_AREA - master.fish_height)

/// Обычный датум движения. Рыба делает только медленные непрерывные длинные прыжки
/datum/fish_movement/slow
	short_jump_chance = 0
	long_jump_chance = 1.5
	long_jump_velocity_limit = 150
	can_interrupt_move = FALSE

/// Обычный датум движения, но короткий прыжок выпадает втрое чаще.
/datum/fish_movement/zippy
	short_jump_chance = parent_type::short_jump_chance * 3

/// Датум движения, который разгоняется, пока ускорение и скорость не удвоятся от стартовых.
/datum/fish_movement/accelerando
	/// Сколько скорости прыжка прибавляется за тик
	var/short_jump_vel_add
	/// Сколько скорости длинного прыжка прибавляется за тик
	var/long_jump_vel_add
	/// Сколько секунд до полной скорости.
	var/accel_time_cap = 30

/datum/fish_movement/accelerando/move_fish(seconds_per_tick)
	var/seconds_elapsed = (times_fired * seconds_per_tick)
	if(seconds_elapsed >= accel_time_cap)
		return ..()
	if(!times_fired) // Первый тик, запоминаем стартовые скорости прыжка
		short_jump_vel_add = short_jump_velocity_limit/accel_time_cap
		long_jump_vel_add = long_jump_velocity_limit/accel_time_cap
		return ..()

	if(current_velocity_limit)
		var/vel_add = current_velocity_limit == short_jump_velocity_limit ? short_jump_vel_add : long_jump_vel_add
		current_velocity_limit += round(vel_add * seconds_per_tick, 0.01)

	short_jump_velocity_limit += round(short_jump_vel_add * seconds_per_tick, 0.01)
	long_jump_velocity_limit += round(long_jump_vel_add * seconds_per_tick, 0.01)
	return ..()

/datum/fish_movement/accelerando/get_acceleration(seconds_per_tick)
	var/acceleration = ..()
	return acceleration + min(acceleration, acceleration * times_fired * seconds_per_tick / accel_time_cap)

/datum/fish_movement/accelerando/set_fish_position(seconds_per_tick)
	fish_velocity = round(fish_velocity)
	return ..()

/// Датум движения, который двигает рыбу дважды в секунду.
/datum/fish_movement/choppy
	/// Тут держим теоретическую позицию рыбы, она ещё пригодится
	var/faux_position = 0

/datum/fish_movement/choppy/set_fish_position(seconds_per_tick)
	faux_position = clamp(faux_position + fish_velocity * seconds_per_tick, 0, FISHING_MINIGAME_AREA - master.fish_height)
	if(!((times_fired * SSfishing.wait) % (0.5 SECONDS)))
		master.fish_position = faux_position

/// Датум движения. Рыба слабо толкается вверх, а у самого верха мини-игры получает толчок вниз посильнее.
/datum/fish_movement/plunger
	/// Рыба идёт ко дну области мини-игры или уже должна всплывать?
	var/is_plunging = TRUE
	/// Скорость покоя, которую добавляем при погружении
	var/plunging_speed = -22

/datum/fish_movement/plunger/adjust_to_difficulty()
	. = ..()
	// Подкручиваем скорость бегства, вплоть до пятикратной стартовой.
	plunging_speed += round(plunging_speed * master.difficulty * 0.03)
	fish_idle_velocity += plunging_speed // так её можно спокойно вычесть, если рыба стартует у дна.

/datum/fish_movement/plunger/reset_difficulty_values()
	. = ..()
	if(is_plunging)
		fish_idle_velocity -= plunging_speed
	plunging_speed = initial(plunging_speed)

/datum/fish_movement/plunger/move_fish(seconds_per_tick)
	var/fish_area = FISHING_MINIGAME_AREA - master.fish_height
	if(is_plunging)
		if(target_position > master.fish_position) // погружению ничего не должно мешать.
			target_position = null
		var/dist_bot_percent = master.fish_position/fish_area
		if(dist_bot_percent <= 0.04)
			fish_idle_velocity -= plunging_speed
			is_plunging = FALSE
	else
		var/dist_top_percent = (fish_area - master.fish_position)/fish_area
		if(dist_top_percent <= 0.04)
			fish_idle_velocity += plunging_speed
			is_plunging = TRUE

	return ..()


#undef FISH_TARGET_MIN_DISTANCE
#undef FISH_FRICTION_MULT
#undef FISH_SHORT_JUMP_MIN_DISTANCE
#undef FISH_SHORT_JUMP_MAX_DISTANCE
