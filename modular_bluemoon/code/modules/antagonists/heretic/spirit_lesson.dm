#define SPIRIT_LESSON_SEVER 1
#define SPIRIT_LESSON_PULL 2
#define SPIRIT_LESSON_REAP 3
#define SPIRIT_LESSON_SEIZE 4
#define SPIRIT_LESSON_RESCUE 5
#define SPIRIT_LESSON_OBOL 6
#define SPIRIT_LESSON_DONE 7

/// Урок Духа на полигоне: шесть шагов по порядку, каждый засчитывается настоящим действием пути.
/datum/heretic_spirit_lesson
	var/datum/antag_training_session/session
	var/datum/weakref/spirit_ref
	var/datum/weakref/student_ref
	var/datum/weakref/target_ref
	var/datum/weakref/helper_ref
	var/datum/weakref/corpse_ref
	var/stage = 0
	var/hint

/datum/heretic_spirit_lesson/New(datum/antag_training_session/session, datum/eldritch_knowledge/base_spirit/spirit, mob/living/student, mob/living/target)
	src.session = session
	spirit_ref = WEAKREF(spirit)
	student_ref = WEAKREF(student)
	target_ref = WEAKREF(target)
	RegisterSignal(spirit, COMSIG_HERETIC_SPIRIT_EVENT, PROC_REF(on_event))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	for(var/knowledge_type in list(/datum/eldritch_knowledge/spirit_grasp, /datum/eldritch_knowledge/spell/spirit_hold, /datum/eldritch_knowledge/spell/spirit_reap))
		if(!heretic.get_knowledge(knowledge_type))
			heretic.gain_knowledge(knowledge_type)
	spirit.combat_resource = spirit.combat_resource_max
	spirit.notify_resource_changed()
	set_stage(SPIRIT_LESSON_SEVER)

/datum/heretic_spirit_lesson/Destroy()
	var/datum/eldritch_knowledge/base_spirit/spirit = spirit_ref?.resolve()
	if(spirit)
		UnregisterSignal(spirit, COMSIG_HERETIC_SPIRIT_EVENT)
	for(var/datum/weakref/extra_ref as anything in list(helper_ref, corpse_ref))
		var/mob/living/extra = extra_ref?.resolve()
		if(extra)
			QDEL_NULL(extra.mind)
			qdel(extra)
	session = null
	return ..()

/datum/heretic_spirit_lesson/proc/finished()
	return stage >= SPIRIT_LESSON_DONE

/datum/heretic_spirit_lesson/proc/steps()
	. = list()
	var/list/names = list("Разлучение", "Притянуть душу", "Жатва", "Душа в руке", "Спасение пустого тела", "Обол на глаза")
	for(var/index in 1 to length(names))
		. += list(list("name" = names[index], "done" = stage > index, "current" = stage == index))

/datum/heretic_spirit_lesson/proc/say(message)
	var/mob/living/student = student_ref?.resolve()
	if(student)
		to_chat(student, span_eldritch("Урок Духа: [message]"))

/datum/heretic_spirit_lesson/proc/set_stage(new_stage)
	var/changed = stage != new_stage
	stage = new_stage
	switch(stage)
		if(SPIRIT_LESSON_SEVER)
			hint = "Шаг 1 из 6. Примените Разлучение к мишени: её душа останется на месте, а к телу протянется нить."
		if(SPIRIT_LESSON_PULL)
			hint = "Шаг 2 из 6. Отойдите от души на 2-5 клеток и примените «Притянуть душу» по силуэту или телу: через секунду душа сдвинется к вам. Вдали от души тело слабеет."
		if(SPIRIT_LESSON_REAP)
			hint = "Шаг 3 из 6. Примените Жатву к мишени и подождите 2 секунды: второй удар придёт по нити. Вдали от души он сильнее."
		if(SPIRIT_LESSON_SEIZE)
			hint = "Шаг 4 из 6. Отделите душу мишени, встаньте вплотную к силуэту и примените по нему «Притянуть душу» со свободной рукой: душа окажется у вас в руке."
		if(SPIRIT_LESSON_RESCUE)
			hint = "Шаг 5 из 6. Так экипаж спасает пустое тело: помощник трясёт его 2 секунды. Ударьте помощника, чтобы сорвать спасение, или посмотрите, как душа вернётся."
			if(changed)
				INVOKE_ASYNC(src, PROC_REF(call_helper))
		if(SPIRIT_LESSON_OBOL)
			hint = "Шаг 6 из 6. В намерении «Помощь» коснитесь Хваткой Мансуса учебного трупа: на глаза лягут монеты, и вы узнаете его последний миг."
			if(changed)
				INVOKE_ASYNC(src, PROC_REF(call_corpse))
		if(SPIRIT_LESSON_DONE)
			hint = "Урок пройден. Против Духа: коснуться своей души или вернуться на её клетку, разбить душу, нулевой жезл, растолкать пустое тело за 2 секунды."
	if(changed)
		say(hint)
	session?.update_practice()

/datum/heretic_spirit_lesson/proc/on_event(datum/source, event, atom/subject)
	SIGNAL_HANDLER
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(SPIRIT_LESSON_SEVER)
			if(event == "separate" && subject == target)
				say("душа мишени осталась на месте. Пока тело рядом с ней, нить провисает.")
				set_stage(SPIRIT_LESSON_PULL)
		if(SPIRIT_LESSON_PULL)
			if(event == "pull" && subject == target)
				say("душа оттащена от тела: связь натянулась.")
				set_stage(SPIRIT_LESSON_REAP)
		if(SPIRIT_LESSON_REAP)
			if(event == "reap_hit" && subject == target)
				say("второй удар Жатвы прошёл по нити.")
				set_stage(SPIRIT_LESSON_SEIZE)
		if(SPIRIT_LESSON_SEIZE)
			if(event == "seize" && subject == target)
				say("душа у вас в руке, тело пусто. На станции щелчок душой по телу цели охоты уводит его в изнанку.")
				set_stage(SPIRIT_LESSON_RESCUE)
		if(SPIRIT_LESSON_RESCUE)
			if(event == "released" && subject == target)
				say("душа вернулась в тело.")
				set_stage(SPIRIT_LESSON_OBOL)
		if(SPIRIT_LESSON_OBOL)
			if(event == "obol")
				say("монеты легли на глаза. Призрак настоящего игрока под оболом мог бы шептать вам и указывать живых.")
				set_stage(SPIRIT_LESSON_DONE)

/// Помощник подходит к пустому телу и трясёт его, как сделал бы экипаж.
/datum/heretic_spirit_lesson/proc/call_helper()
	var/mob/living/target = target_ref?.resolve()
	if(!target || !session?.arena)
		set_stage(SPIRIT_LESSON_OBOL)
		return
	var/mob/living/carbon/human/helper = session.arena.spawn_creature("human", session.arena.match_zone(target), FALSE, session)
	if(!helper)
		say("места для помощника на полигоне нет: удалите лишние цели.")
		set_stage(SPIRIT_LESSON_OBOL)
		return
	helper.real_name = "Помощник"
	helper.name = helper.real_name
	helper_ref = WEAKREF(helper)
	for(var/turf/spot in orange(1, target))
		if(!spot.is_blocked_turf(exclude_mobs = FALSE))
			helper.forceMove(spot)
			break
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_capture_shake), helper, target)

/// Учебный труп для обола рядом с учеником; без полигона годится любой труп.
/datum/heretic_spirit_lesson/proc/call_corpse()
	var/mob/living/student = student_ref?.resolve()
	if(!student || !session?.arena)
		return
	var/mob/living/corpse = session.arena.spawn_creature("corpse", session.arena.match_zone(student), FALSE, session, get_turf(student))
	if(corpse)
		corpse_ref = WEAKREF(corpse)
	else
		say("места для трупа на полигоне нет: удалите лишние цели или призовите «Тело для ритуала».")

#undef SPIRIT_LESSON_SEVER
#undef SPIRIT_LESSON_PULL
#undef SPIRIT_LESSON_REAP
#undef SPIRIT_LESSON_SEIZE
#undef SPIRIT_LESSON_RESCUE
#undef SPIRIT_LESSON_OBOL
#undef SPIRIT_LESSON_DONE
