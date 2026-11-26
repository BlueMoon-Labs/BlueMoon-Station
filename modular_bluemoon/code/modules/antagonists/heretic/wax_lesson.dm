#define WAX_LESSON_PUPPET 1
#define WAX_LESSON_SLEEP 2
#define WAX_LESSON_IMPRINT 3
#define WAX_LESSON_SHELL 4
#define WAX_LESSON_WALL_DISTANCE 3

/datum/eldritch_knowledge/base_wax/on_gain(mob/user)
	. = ..()
	heretic_path_lesson_notice(user, "wax")

/// Урок Воска: кукла по отпечаткам, Сон по кукле сквозь стену, печать и Снятие оттиска, погребальная оболочка.
/datum/heretic_path_lesson/wax
	path_id = PATH_WAX
	base_type = /datum/eldritch_knowledge/base_wax
	title = "Урок Воска"
	icon = "fire-flame-simple"
	knowledge_types = list(/datum/eldritch_knowledge/wax_grasp, /datum/eldritch_knowledge/spell/wax_imprint, /datum/eldritch_knowledge/spell/wax_puppet_sleep, /datum/eldritch_knowledge/spell/wax_shell)
	step_names = list("Кукла по отпечаткам", "Сон по кукле", "Печать и оттиск", "Погребальная оболочка")
	var/list/datum/weakref/walls = list()

/datum/heretic_path_lesson/wax/setup(datum/antagonist/heretic/heretic, datum/eldritch_knowledge/base_wax/wax, mob/living/student, mob/living/target)
	refill(wax)

/datum/heretic_path_lesson/wax/proc/refill(datum/eldritch_knowledge/base_wax/wax)
	wax.combat_resource = wax.combat_resource_max
	wax.notify_resource_changed()

/datum/heretic_path_lesson/wax/stage_text(for_stage)
	switch(for_stage)
		if(WAX_LESSON_PUPPET)
			return "Рядом лежит ручка мишени с её отпечатками. Переключитесь на «Помощь» и коснитесь ручки Хваткой Мансуса: воск слепит куклу. Если на вещи несколько чужих отпечатков, выберите в меню, чью. Годятся и ID-карта, и КПК."
		if(WAX_LESSON_SLEEP)
			return "Мишень стоит за стеной и стала вашей целью охоты. Нажмите «Растопить куклу» и держите куклу в руке [HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд: стены не мешают, если цель не дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток. Цель охоты уснёт на [HERETIC_WAX_PUPPET_SLEEP_TIME / (1 SECONDS)] секунд, любой другой лишь задремлет."
		if(WAX_LESSON_IMPRINT)
			return "Стена ушла. Коснитесь мишени Хваткой: на ней восковая печать. Затем примените к ней «Снятие оттиска»: с печатью удар сильнее, а рядом с вами встанет крепкий двойник - удары клинка по нему переходят на цель."
		if(WAX_LESSON_SHELL)
			return "Нажмите «Погребальную оболочку»: она примет удары, пули и броски, у ног загорится свеча. Разбитая свеча или нулевой жезл снимут оболочку."
	return "Урок пройден. Против Воска: куклу губят огонь и нулевой жезл, по бирке видно, чья она; жар гасят вода, жезл или уход дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток; спящего будит жезл или его можно растолкать; свечу оболочки разбейте, жезл проходит сквозь неё."

/datum/heretic_path_lesson/wax/prepare_stage(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_wax/wax = base_ref?.resolve()
	var/mob/living/target = target_ref?.resolve()
	if(!student || !wax || !target || stage != for_stage)
		return
	switch(for_stage)
		if(WAX_LESSON_PUPPET)
			var/turf/spot = free_spot_near(student) || get_turf(student)
			var/obj/item/pen/pen = add_prop(new /obj/item/pen(spot))
			pen.add_fingerprint(target, TRUE)
		if(WAX_LESSON_SLEEP)
			hunt_target(student, target)
			if(!raise_wall(student, target))
				say("для стены нет места: отойдите на свободный пол и начните урок заново.")
		if(WAX_LESSON_IMPRINT)
			for(var/datum/weakref/wall_ref as anything in walls)
				drop_prop(wall_ref.resolve())
			walls.Cut()
			refill(wax)
		if(WAX_LESSON_SHELL)
			refill(wax)

/// Мишень встаёт в нескольких шагах от ученика, между ними - стена из трёх блоков.
/datum/heretic_path_lesson/wax/proc/raise_wall(mob/living/student, mob/living/target)
	var/turf/origin = get_turf(student)
	for(var/direction in GLOB.cardinals)
		var/list/turf/line = list()
		var/turf/spot = origin
		for(var/step in 1 to WAX_LESSON_WALL_DISTANCE)
			spot = get_step(spot, direction)
			if(!isopenturf(spot) || spot.is_blocked_turf(exclude_mobs = FALSE))
				break
			line += spot
		if(length(line) < WAX_LESSON_WALL_DISTANCE)
			continue
		target.forceMove(line[WAX_LESSON_WALL_DISTANCE])
		var/turf/middle = line[WAX_LESSON_WALL_DISTANCE - 1]
		for(var/turf/place in list(middle, get_step(middle, turn(direction, 90)), get_step(middle, turn(direction, -90))))
			if(isopenturf(place) && !place.is_blocked_turf(exclude_mobs = FALSE))
				walls += WEAKREF(add_prop(new /obj/structure/falsewall(place)))
		return TRUE
	return FALSE

/datum/heretic_path_lesson/wax/handle_event(event, atom/subject, value)
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(WAX_LESSON_PUPPET)
			if(event == "puppet" && subject == target)
				advance("кукла у вас. Используйте её в руке - уколете по зоне прицела, а цель почувствует, в какой стороне кукла. Держится не больше [HERETIC_WAX_PUPPET_LIMIT] кукол.")
		if(WAX_LESSON_SLEEP)
			if(event == "sleep" && subject == target)
				advance("мишень спит. Пока длится сон, кукла в руке утянет цель охоты в изнанку, а к пробуждению треснет.")
		if(WAX_LESSON_IMPRINT)
			if(event == "imprint" && subject == target)
				if(value)
					advance("печать усилила оттиск. Взрыв Метки Воска снимает такой оттиск бесплатно.")
				else
					say("оттиск снят без печати: двойник слабее. Коснитесь мишени Хваткой и снимите оттиск ещё раз.")
		if(WAX_LESSON_SHELL)
			if(event == "shell")
				advance("оболочка на вас. В «Разоружении» «Снять печать» выбросит её веером, а канделябр переплавит принятые удары в лечение.")

#undef WAX_LESSON_PUPPET
#undef WAX_LESSON_SLEEP
#undef WAX_LESSON_IMPRINT
#undef WAX_LESSON_SHELL
#undef WAX_LESSON_WALL_DISTANCE
