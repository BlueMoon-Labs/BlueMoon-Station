#define SAND_LESSON_DROUGHT 1
#define SAND_LESSON_STASIS 2
#define SAND_LESSON_ANCHOR 3
#define SAND_LESSON_REWIND 4
#define SAND_LESSON_DONE 5

/// Урок Песка на полигоне: захват в два шага и уход Откатом, каждый шаг засчитывается настоящим действием пути.
/datum/heretic_sand_lesson
	var/datum/antag_training_session/session
	var/datum/weakref/sand_ref
	var/datum/weakref/student_ref
	var/datum/weakref/target_ref
	var/stage = 0
	var/hint

/datum/heretic_sand_lesson/New(datum/antag_training_session/session, datum/eldritch_knowledge/base_sand/sand, mob/living/student, mob/living/target)
	src.session = session
	sand_ref = WEAKREF(sand)
	student_ref = WEAKREF(student)
	target_ref = WEAKREF(target)
	RegisterSignal(sand, COMSIG_HERETIC_SAND_EVENT, PROC_REF(on_event))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	for(var/knowledge_type in list(/datum/eldritch_knowledge/sand_grasp, /datum/eldritch_knowledge/spell/sand_stasis, /datum/eldritch_knowledge/sand_relic))
		if(!heretic.get_knowledge(knowledge_type))
			heretic.gain_knowledge(knowledge_type)
	heretic.sync_path_stage()
	give_relic(heretic, student)
	sand.combat_resource = sand.combat_resource_max
	sand.notify_resource_changed()
	set_stage(SAND_LESSON_DROUGHT)

/datum/heretic_sand_lesson/Destroy()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(sand)
		UnregisterSignal(sand, COMSIG_HERETIC_SAND_EVENT)
	session = null
	return ..()

/// Реликвия для Отката: новая, если её ещё нет, и в руку.
/datum/heretic_sand_lesson/proc/give_relic(datum/antagonist/heretic/heretic, mob/living/student)
	var/datum/eldritch_knowledge/sand_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/sand_relic)
	if(recipe.new_path_relic_available())
		recipe.on_finished_recipe(student, list(), get_turf(student))
	var/obj/item/heretic_path_relic/sand_relic/relic = recipe.new_path_relic_ref?.resolve()
	if(relic && !student.is_holding(relic))
		student.put_in_hands(relic)

/datum/heretic_sand_lesson/proc/finished()
	return stage >= SAND_LESSON_DONE

/datum/heretic_sand_lesson/proc/steps()
	. = list()
	var/list/names = list("Осыпь и Засуха", "Стазис", "Засечка", "Откат")
	for(var/index in 1 to length(names))
		. += list(list("name" = names[index], "done" = stage > index, "current" = stage == index))

/datum/heretic_sand_lesson/proc/say(message)
	var/mob/living/student = student_ref?.resolve()
	if(student)
		to_chat(student, span_eldritch("Урок Песка: [message]"))

/datum/heretic_sand_lesson/proc/set_stage(new_stage)
	var/changed = stage != new_stage
	stage = new_stage
	switch(stage)
		if(SAND_LESSON_DROUGHT)
			hint = "Шаг 1 из 4. Встаньте вплотную к мишени и примените Осыпь: удар насылает Засуху на [HERETIC_SAND_DROUGHT_DURATION / (1 SECONDS)] секунд, с мишени посыплется песок. Хватка Мансуса тоже насылает Засуху."
		if(SAND_LESSON_STASIS)
			hint = "Шаг 2 из 4. Сразу примените к мишени Стазис: песок сомкнётся за секунду, и время её остановится на [HERETIC_SAND_STASIS_DURATION / (1 SECONDS)] секунд. Стоящая цель может успеть шагнуть прочь, сбитая ударом часов или увязшая в Зыбуне - нет."
		if(SAND_LESSON_ANCHOR)
			hint = "Шаг 3 из 4. В намерении «Помощь» коснитесь Хваткой Мансуса свободного пола: встанет засечка, песочные часы, в которых песок течёт вверх."
		if(SAND_LESSON_REWIND)
			hint = "Шаг 4 из 4. Отойдите от засечки и сожмите в руке «Неперевёрнутые часы»: через [HERETIC_SAND_REWIND_TIME / (1 SECONDS)] секунды Откат вернёт вас к ней. Засечка этажом выше или ниже тоже годится, но Откат туда идёт [HERETIC_SAND_REWIND_FLOOR_TIME / (1 SECONDS)] секунд."
		if(SAND_LESSON_DONE)
			hint = "Урок пройден. Против Песка: разбить часы и засечки, уйти дальше [HERETIC_SAND_RECALL_RANGE] клеток или на другой этаж, растолкать застывшего за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды, нулевой жезл и святая вода; крепкая хватка не даёт начать Откат."
	if(changed)
		say(hint)
	session?.update_practice()

/datum/heretic_sand_lesson/proc/on_event(datum/source, event, atom/subject)
	SIGNAL_HANDLER
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(SAND_LESSON_DROUGHT)
			if(event == "drought" && subject == target)
				say("с мишени сыплется песок: она под Засухой, и Стазис возьмёт её даже стоящей.")
				set_stage(SAND_LESSON_STASIS)
		if(SAND_LESSON_STASIS)
			if(event == "stasis" && subject == target)
				say("мишень застыла. На станции застывшую цель охоты живое сердце уводит в изнанку.")
				set_stage(SAND_LESSON_ANCHOR)
		if(SAND_LESSON_ANCHOR)
			if(event == "anchor")
				set_stage(SAND_LESSON_REWIND)
		if(SAND_LESSON_REWIND)
			if(event == "rewind")
				say("Откат удался. На станции засечки ставят в разных отделах: так продвигается дело пути.")
				set_stage(SAND_LESSON_DONE)

#undef SAND_LESSON_DROUGHT
#undef SAND_LESSON_STASIS
#undef SAND_LESSON_ANCHOR
#undef SAND_LESSON_REWIND
#undef SAND_LESSON_DONE
