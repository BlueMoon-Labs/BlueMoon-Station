// Глайд-полигон: четыре дорожки идут с ОДИНАКОВОЙ средней скоростью и
// различаются только ритмом - насколько интервал между шагами гуляет вокруг
// среднего.
//
// Так поставлено намеренно. Первый заход сравнивал дорожки с разной скоростью,
// и разница в темпе перебила всё остальное: наблюдатель оценивал, кто быстрее,
// а не кто ровнее. Здесь скорость одинакова у всех по построению, равенство
// средних проверяется юнит-тестом, и различить дорожки можно только по
// плавности.
//
// glide у всех считается одинаково и точно - на тот интервал, который реально
// предстоит. Замер показал, что расчёт glide на рваность не влияет, поэтому
// вводить его как переменную больше незачем.

/// Длина дорожки в тайлах до разворота.
#define GLIDE_POLYGON_LENGTH 12
/// Полигон убирает себя сам, чтобы не оставлять мусор в мире.
#define GLIDE_POLYGON_LIFETIME (3 MINUTES)

GLOBAL_DATUM(glide_polygon, /datum/glide_polygon)

/obj/effect/glide_lane
	name = "дорожка glide"
	anchored = TRUE
	density = FALSE
	/// Подпись над дорожкой.
	var/label = ""
	/// Ритм интервалов в целых тиках, зациклен.
	var/list/interval_pattern
	var/pattern_index = 1
	/// world.time, начиная с которого разрешён следующий шаг.
	var/next_step_time = 0
	var/step_dir = EAST
	var/steps_left = GLIDE_POLYGON_LENGTH

/obj/effect/glide_lane/proc/advance(now)
	if(now < next_step_time)
		return
	if(!length(interval_pattern))
		return

	var/ticks = interval_pattern[pattern_index]
	pattern_index = (pattern_index % length(interval_pattern)) + 1

	// Ритм задан в целых тиках и расписание считается от текущего момента,
	// поэтому дрейфу взяться неоткуда - интервал получится ровно заказанным.
	next_step_time = now + (ticks * world.tick_lag)
	// glide покрывает промежуток до следующего шага, а он известен точно.
	set_glide_size(movement_glide_for_ticks(ticks, world.icon_size))

	var/turf/destination = get_step(src, step_dir)
	if(!destination)
		return
	// forceMove, а не Move: дорожка не должна спотыкаться о стены и мебель,
	// иначе сравнивать будет нечего.
	forceMove(destination)

	steps_left--
	if(steps_left > 0)
		return
	steps_left = GLIDE_POLYGON_LENGTH
	step_dir = turn(step_dir, 180)

/datum/glide_polygon
	var/list/lanes
	var/expires_at = 0

/datum/glide_polygon/New(turf/origin, mob/model)
	. = ..()
	lanes = list()
	expires_at = world.time + GLIDE_POLYGON_LIFETIME

	var/list/patterns = movement_polygon_patterns()
	// Общий старт: все дорожки обязаны шагать в одной фазе.
	var/start_time = world.time + (MOVEMENT_POLYGON_PATTERN_TICKS * world.tick_lag)

	for(var/index in 1 to length(patterns))
		var/turf/lane_turf = locate(origin.x, origin.y + index, origin.z)
		if(!lane_turf)
			continue
		var/list/pattern = patterns[index]
		var/obj/effect/glide_lane/lane = new(lane_turf)
		if(model)
			lane.appearance = model.appearance
		lane.interval_pattern = pattern
		lane.label = pattern.Join("-")
		lane.next_step_time = start_time
		lane.maptext = "<font color='#ffffff'>[lane.label]</font>"
		lane.maptext_width = 96
		lane.maptext_x = -32
		lane.maptext_y = 32
		lanes += lane

	GLOB.glide_polygon = src

/datum/glide_polygon/Destroy()
	for(var/obj/effect/glide_lane/lane as anything in lanes)
		qdel(lane)
	lanes = null
	if(GLOB.glide_polygon == src)
		GLOB.glide_polygon = null
	return ..()

/datum/glide_polygon/proc/tick()
	if(world.time >= expires_at)
		qdel(src)
		return
	var/now = world.time
	for(var/obj/effect/glide_lane/lane as anything in lanes)
		lane.advance(now)

/client/proc/movement_glide_polygon()
	set name = "Глайд-полигон"
	set category = "Debug"
	set desc = "Четыре дорожки одной скорости с разной рваностью ритма"
	if(!check_rights(R_DEBUG))
		return
	if(GLOB.glide_polygon)
		qdel(GLOB.glide_polygon)
		to_chat(src, "<span class='notice'>Полигон убран.</span>")
		return

	var/turf/origin = get_turf(mob)
	if(!origin)
		return

	new /datum/glide_polygon(origin, mob)

	var/average_delay = MOVEMENT_POLYGON_PATTERN_TICKS * world.tick_lag
	to_chat(src, "<span class='notice'>Полигон запущен. Все дорожки идут с ОДНОЙ скоростью: [MOVEMENT_POLYGON_PATTERN_TICKS] тика на тайл в среднем, то есть [average_delay]ds на шаг.\n\n\
		Дорожки снизу вверх, подпись - ритм в тиках:\n\
		1. <b>4</b> - ровно, эталон\n\
		2. <b>3-4-4-4-5</b> - слабое гуляние\n\
		3. <b>3-3-4-5-5</b> - среднее\n\
		4. <b>2-4-4-4-6</b> - сильное\n\n\
		Скорость одинакова у всех, отличается только ритм - обогнать друг друга они не могут.\n\
		Вопрос один: с какой дорожки начинает быть заметна рваность.\n\n\
		Если рваной выглядит даже первая - причина не в ритме шагов, и искать надо в клиентском рендере.\n\
		Если все четыре выглядят одинаково - ритм тоже ни при чём.\n\n\
		Смотри сбоку, не сверху. Полигон уберётся сам через три минуты или по повторному нажатию верба.</span>")
