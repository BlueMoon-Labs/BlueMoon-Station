#define COMSIG_HERETIC_PATH_LESSON_EVENT "heretic_path_lesson_event"

/// id упражнения полигона -> тип урока пути.
GLOBAL_LIST_INIT(heretic_path_lessons, list(
	"glass" = /datum/heretic_path_lesson/glass,
	"tide" = /datum/heretic_path_lesson/tide,
	"dusk" = /datum/heretic_path_lesson/dusk,
	"wax" = /datum/heretic_path_lesson/wax,
	"blood" = /datum/heretic_path_lesson/blood,
))

/// Действие пути, которое может засчитать шаг урока на полигоне; без урока сигнал никто не слушает.
/datum/eldritch_knowledge/proc/lesson_event(event, atom/subject, value)
	SEND_SIGNAL(src, COMSIG_HERETIC_PATH_LESSON_EVENT, event, subject, value)

/// Подсказка о уроке при выборе пути прямо на полигоне.
/proc/heretic_path_lesson_notice(mob/user, lesson_id)
	var/datum/antag_training_session/session = GLOB.antag_training_sessions[user?.ckey]
	var/datum/heretic_path_lesson/lesson_type = GLOB.heretic_path_lessons[lesson_id]
	if(session?.current_body == user && !session.path_lesson && lesson_type)
		to_chat(user, span_notice("Для этого пути на полигоне есть пошаговый урок: панель полигона, вкладка «Начать», раздел «2. Упражнение», кнопка «[initial(lesson_type.title)]»."))

/// Ступень пути догоняет ступени, изученные подряд: уроки полигона выдают знания мимо исследования, и следующая ступень не должна упираться в них.
/datum/antagonist/heretic/proc/sync_path_stage()
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(!path)
		return
	while(path_stage < length(path.knowledge) && researched_knowledge[path.knowledge[path_stage + 1]])
		path_stage++
	refresh_evolution()

/datum/antag_training_session
	var/datum/heretic_path_lesson/path_lesson

/// Базовое знание пути урока, если участник идёт этим путём.
/datum/antag_training_session/proc/path_lesson_knowledge(lesson_id)
	var/datum/heretic_path_lesson/lesson_type = GLOB.heretic_path_lessons[lesson_id]
	var/datum/antagonist/heretic/heretic = IS_HERETIC(current_body)
	if(!lesson_type || heretic?.selected_path != initial(lesson_type.path_id))
		return null
	return heretic.get_knowledge(initial(lesson_type.base_type))

/// Кнопка урока пути участника на панели полигона.
/datum/antag_training_session/proc/path_lesson_data()
	for(var/lesson_id in GLOB.heretic_path_lessons)
		if(path_lesson_knowledge(lesson_id))
			var/datum/heretic_path_lesson/lesson_type = GLOB.heretic_path_lessons[lesson_id]
			return list("id" = lesson_id, "name" = initial(lesson_type.title), "icon" = initial(lesson_type.icon))
	return null

/// Пошаговый урок пути на полигоне: каждый шаг засчитывает настоящее действие пути, о котором знание сообщает через lesson_event().
/datum/heretic_path_lesson
	var/path_id
	var/datum/eldritch_knowledge/base_type
	var/title
	var/icon
	var/list/knowledge_types = list()
	var/list/step_names = list()
	var/datum/antag_training_session/session
	var/datum/weakref/base_ref
	var/datum/weakref/student_ref
	var/datum/weakref/target_ref
	var/list/datum/weakref/props = list()
	var/stage = 0
	var/hint

/datum/heretic_path_lesson/New(datum/antag_training_session/session, datum/eldritch_knowledge/base, mob/living/student, mob/living/target)
	src.session = session
	base_ref = WEAKREF(base)
	student_ref = WEAKREF(student)
	target_ref = WEAKREF(target)
	RegisterSignal(base, COMSIG_HERETIC_PATH_LESSON_EVENT, PROC_REF(on_event))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	for(var/knowledge_type in knowledge_types)
		if(!heretic.get_knowledge(knowledge_type))
			heretic.gain_knowledge(knowledge_type)
	heretic.sync_path_stage()
	setup(heretic, base, student, target)
	set_stage(1)

/datum/heretic_path_lesson/Destroy()
	var/datum/eldritch_knowledge/base = base_ref?.resolve()
	if(base)
		UnregisterSignal(base, COMSIG_HERETIC_PATH_LESSON_EVENT)
	for(var/datum/weakref/prop_ref as anything in props)
		var/atom/movable/prop = prop_ref.resolve()
		if(ismob(prop))
			var/mob/extra = prop
			QDEL_NULL(extra.mind)
		if(prop)
			qdel(prop)
	props.Cut()
	session = null
	return ..()

/// Снаряжение урока при старте: знания уже открыты.
/datum/heretic_path_lesson/proc/setup(datum/antagonist/heretic/heretic, datum/eldritch_knowledge/base, mob/living/student, mob/living/target)
	return

/datum/heretic_path_lesson/proc/finished()
	return stage > length(step_names)

/datum/heretic_path_lesson/proc/steps()
	. = list()
	for(var/index in 1 to length(step_names))
		. += list(list("name" = step_names[index], "done" = stage > index, "current" = stage == index))

/datum/heretic_path_lesson/proc/say(message)
	var/mob/living/student = student_ref?.resolve()
	if(student)
		to_chat(student, span_eldritch("[title]: [message]"))

/// Текст шага; за последним шагом - итог урока с ответом экипажа.
/datum/heretic_path_lesson/proc/stage_text(for_stage)
	return null

/datum/heretic_path_lesson/proc/set_stage(new_stage)
	var/changed = stage != new_stage
	stage = new_stage
	hint = finished() ? stage_text(stage) : "Шаг [stage] из [length(step_names)]. [stage_text(stage)]"
	if(changed)
		say(hint)
		INVOKE_ASYNC(src, PROC_REF(prepare_stage), stage)
	session?.update_practice()

/datum/heretic_path_lesson/proc/advance(message)
	if(message)
		say(message)
	set_stage(stage + 1)

/// Реквизит шага; stage мог смениться, пока шла подготовка.
/datum/heretic_path_lesson/proc/prepare_stage(for_stage)
	return

/datum/heretic_path_lesson/proc/on_event(datum/source, event, atom/subject, value)
	SIGNAL_HANDLER
	if(!finished())
		handle_event(event, subject, value)

/datum/heretic_path_lesson/proc/handle_event(event, atom/subject, value)
	return

/// Реквизит уходит вместе с уроком; урок, закрытый во время подготовки шага, свой реквизит не оставляет.
/datum/heretic_path_lesson/proc/add_prop(atom/movable/prop)
	if(QDELETED(src))
		if(ismob(prop))
			var/mob/extra = prop
			QDEL_NULL(extra.mind)
		qdel(prop)
		return null
	props += WEAKREF(prop)
	return prop

/datum/heretic_path_lesson/proc/drop_prop(atom/movable/prop)
	if(!prop)
		return
	props -= prop.weak_reference
	if(ismob(prop))
		var/mob/extra = prop
		QDEL_NULL(extra.mind)
	qdel(prop)

/datum/heretic_path_lesson/proc/free_spot_near(atom/center, list/exclude)
	for(var/turf/open/spot in orange(1, center))
		if(!(spot in exclude) && !spot.is_blocked_turf(exclude_mobs = FALSE))
			return spot
	return null

/// Клетка в distance шагах по прямой от center, куда ведёт открытый проход; null, если такой нет.
/datum/heretic_path_lesson/proc/spot_in_line(atom/center, distance)
	var/turf/origin = get_turf(center)
	for(var/direction in GLOB.cardinals)
		var/turf/spot = origin
		var/clear = TRUE
		for(var/step in 1 to distance)
			spot = get_step(spot, direction)
			if(!isopenturf(spot) || spot.is_blocked_turf(exclude_mobs = FALSE))
				clear = FALSE
				break
		if(clear)
			return spot
	return null

/// Учебная мишень становится целью охоты: на полигоне её выбирает урок.
/datum/heretic_path_lesson/proc/hunt_target(mob/living/student, mob/living/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	if(!heretic || !target?.mind || target.client || heretic.hunt_target == target.mind || !heretic.hunt_target_available(target.mind))
		return heretic?.hunt_target && heretic.hunt_target == target?.mind
	heretic.set_hunt_target(target.mind)
	return TRUE

/// Второй учебный человек рядом с учеником; на полигоне он занимает место в общем пределе целей.
/datum/heretic_path_lesson/proc/call_extra(mob/living/student, turf/spot, extra_name)
	var/mob/living/carbon/human/extra
	if(session?.arena)
		extra = session.arena.spawn_creature("human", session.arena.match_zone(student), FALSE, session, spot)
	else if(spot)
		extra = new(spot)
	if(!extra)
		say("места для учебного человека на полигоне нет: удалите лишние цели и начните урок заново.")
		return null
	extra.real_name = extra_name
	extra.name = extra_name
	add_prop(extra)
	return extra

#undef COMSIG_HERETIC_PATH_LESSON_EVENT
