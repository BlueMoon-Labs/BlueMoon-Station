#define GLASS_LESSON_PRISM 1
#define GLASS_LESSON_BEAM 2
#define GLASS_LESSON_MARK 3
#define GLASS_LESSON_TRAVEL 4
#define GLASS_LESSON_THEFT 5
#define GLASS_LESSON_SIDESTEP_DELAY (0.2 SECONDS)
#define GLASS_LESSON_PANE_DISTANCE 4

/datum/eldritch_knowledge/base_glass/on_gain(mob/user)
	. = ..()
	heretic_path_lesson_notice(user, "glass")

/// Урок Стекла: призма, следящий луч по уходящей мишени, раскол меткой, переход между стёклами и кража сквозь стекло.
/datum/heretic_path_lesson/glass
	path_id = PATH_GLASS
	base_type = /datum/eldritch_knowledge/base_glass
	title = "Урок Стекла"
	icon = "border-all"
	knowledge_types = list(/datum/eldritch_knowledge/glass_grasp, /datum/eldritch_knowledge/spell/glass_shards, /datum/eldritch_knowledge/glass_mark, /datum/eldritch_knowledge/glass_passage)
	step_names = list("Призма", "Следящий луч", "Раскол меткой", "Переход", "Кража сквозь стекло")
	var/list/datum/weakref/panes = list()
	var/sidestepped = FALSE

/datum/heretic_path_lesson/glass/setup(datum/antagonist/heretic/heretic, datum/eldritch_knowledge/base_glass/glass, mob/living/student, mob/living/target)
	var/obj/item/melee/sickly_blade/glass/blade = add_prop(new /obj/item/melee/sickly_blade/glass(get_turf(student)))
	student.put_in_hands(blade)
	refill(glass)

/datum/heretic_path_lesson/glass/proc/refill(datum/eldritch_knowledge/base_glass/glass)
	glass.combat_resource = glass.combat_resource_max
	glass.notify_resource_changed()

/datum/heretic_path_lesson/glass/stage_text(for_stage)
	switch(for_stage)
		if(GLASS_LESSON_PRISM)
			return "Нажмите «Поставить призму» и укажите свободную клетку в пяти шагах: за грань встанет призма, она стреляет вместе с вашим лучом. В намерении «Разоружить» та же кнопка зовётся «Поставить преграду» и ставит прозрачную стену - она держит людей и возвращает лазеры."
		if(GLASS_LESSON_BEAM)
			return "Нажмите значок граней и укажите мишень не дальше пяти клеток: через полсекунды луч ударит туда, где она стоит. Мишень на уроке шагнёт вбок - смотрите, как свет довернёт за ней."
		if(GLASS_LESSON_MARK)
			return "Коснитесь мишени Хваткой Мансуса: на ней трещина и Метка Стекла. Ударьте её стеклянным клинком - метка взорвётся и сразу расколет цель, она упадёт. Без метки раскалывает только [HERETIC_GLASS_SHATTER_STACKS]-я трещина."
		if(GLASS_LESSON_TRAVEL)
			return "Рядом встали два окна. Коснитесь каждого Хваткой: стекло станет вашим. Затем в «Помощи» коснитесь своего окна и выберите другое: переход стоит грань."
		if(GLASS_LESSON_THEFT)
			return "Мишень теперь ваша цель охоты и стоит у другого вашего окна. Встаньте вплотную к своему стеклу и в «Помощи» коснитесь его: выберите стекло с её именем. За [HERETIC_GLASS_THEFT_TIME / (1 SECONDS)] секунды её утянет в изнанку, если рядом с ней никого или она в трещинах."
	return "Урок пройден. Против Стекла: за углом луч не достанет, бег поперёк луча вдвое ослабляет удар; нулевой жезл снимает настройку со стекла и разбивает призмы; свежая трещина на стекле выдаёт переход; кражу видно [HERETIC_GLASS_THEFT_TIME / (1 SECONDS)] секунды - схватите цель или уведите её от стекла."

/datum/heretic_path_lesson/glass/prepare_stage(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_glass/glass = base_ref?.resolve()
	if(!student || !glass || stage != for_stage)
		return
	switch(for_stage)
		if(GLASS_LESSON_BEAM, GLASS_LESSON_MARK)
			refill(glass)
		if(GLASS_LESSON_TRAVEL)
			refill(glass)
			place_panes(student)
		if(GLASS_LESSON_THEFT)
			COOLDOWN_RESET(glass, theft_cooldown)
			place_target_by_pane(student)

/datum/heretic_path_lesson/glass/proc/place_panes(mob/living/student)
	var/turf/near = free_spot_near(student)
	var/turf/far
	for(var/distance in list(GLASS_LESSON_PANE_DISTANCE, GLASS_LESSON_PANE_DISTANCE - 1))
		far = spot_in_line(student, distance)
		if(far && far != near)
			break
		far = null
	if(!near || !far)
		say("для окон нет места: отойдите на свободный пол и начните урок заново.")
		return
	for(var/turf/spot in list(near, far))
		panes += WEAKREF(add_prop(new /obj/structure/window/fulltile(spot)))

/// Мишень встаёт у того из окон урока, что дальше от ученика.
/datum/heretic_path_lesson/glass/proc/place_target_by_pane(mob/living/student)
	var/mob/living/target = target_ref?.resolve()
	if(!target)
		return
	hunt_target(student, target)
	var/obj/structure/window/farthest
	for(var/datum/weakref/pane_ref as anything in panes)
		var/obj/structure/window/pane = pane_ref.resolve()
		if(pane && (!farthest || get_dist(student, pane) > get_dist(student, farthest)))
			farthest = pane
	var/turf/spot = farthest && free_spot_near(farthest, RANGE_TURFS(1, student))
	if(spot)
		target.forceMove(spot)

/datum/heretic_path_lesson/glass/proc/sidestep()
	var/mob/living/student = student_ref?.resolve()
	var/mob/living/target = target_ref?.resolve()
	if(stage != GLASS_LESSON_BEAM || !student || !target || !isturf(target.loc) || !(target.mobility_flags & MOBILITY_MOVE))
		return
	var/forward = get_dir(student, target)
	for(var/direction in list(turn(forward, 90), turn(forward, -90)))
		var/turf/aside = get_step(target, direction)
		if(isopenturf(aside) && !aside.is_blocked_turf(exclude_mobs = FALSE) && step(target, direction))
			target.visible_message(span_notice("[target] шагает вбок с линии луча."))
			return

/datum/heretic_path_lesson/glass/handle_event(event, atom/subject, value)
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(GLASS_LESSON_PRISM)
			if(event == "prism" || event == "barrier")
				advance(event == "prism" ? "призма стоит. Выстрел в свою призму пускает залп по её стрелкам - так бьют из-за угла." : "преграда стоит. Ваши лучи она пропускает, а чужие лазеры возвращает.")
		if(GLASS_LESSON_BEAM)
			if(event == "aim" && subject == target && !sidestepped)
				sidestepped = TRUE
				addtimer(CALLBACK(src, PROC_REF(sidestep)), GLASS_LESSON_SIDESTEP_DELAY)
			else if(event == "beam" && subject == target)
				advance(value ? "мишень ушла поперёк луча: свет довернул за ней, но лишь задел - урон вдвое меньше. От вашего луча целиком спасает только укрытие." : "луч попал. Свет доворачивает за живой целью: от него спасает укрытие, а бег поперёк вдвое ослабляет удар.")
		if(GLASS_LESSON_MARK)
			if(event == "mark" && subject == target)
				advance("метка взорвалась и расколола цель. После раскола на ней остаётся трещина: луч ослепит её, а Витраж запрёт.")
		if(GLASS_LESSON_TRAVEL)
			if(event == "attune")
				say("стекло настроено. Экипаж увидит в нём чужую комнату, а нулевой жезл снимет настройку. Если выше красным «Мансус уже видел это место» - это про дело пути: отдел для дела уже засчитан, а стекло всё равно ваше.")
			else if(event == "travel")
				advance("вы вышли у другого стекла. Следующий переход - через [HERETIC_GLASS_TRAVEL_COOLDOWN / (1 SECONDS)] секунд, а на обоих стёклах ещё полминуты видна свежая трещина.")
		if(GLASS_LESSON_THEFT)
			if(event == "theft" && subject == target)
				advance("цель в изнанке вместе с вами: проведите обряд живым сердцем или выйдите кнопкой изнанки. На станции так уводят цель охоты, оставшуюся одну у вашего окна.")

#undef GLASS_LESSON_PRISM
#undef GLASS_LESSON_BEAM
#undef GLASS_LESSON_MARK
#undef GLASS_LESSON_TRAVEL
#undef GLASS_LESSON_THEFT
#undef GLASS_LESSON_SIDESTEP_DELAY
#undef GLASS_LESSON_PANE_DISTANCE
