#define DANCE_LESSON_HITS 1
#define DANCE_LESSON_SQUARE 2
#define DANCE_LESSON_SWITCH 3
#define DANCE_LESSON_INVITE 4
#define DANCE_LESSON_RESCUE 5
#define DANCE_LESSON_DONE 6
#define DANCE_LESSON_HITS_NEEDED 3

/// Урок Пляски на полигоне: пять шагов по порядку, каждая ошибка объясняется сразу.
/datum/heretic_dance_lesson
	var/datum/antag_training_session/session
	var/datum/weakref/dance_ref
	var/datum/weakref/student_ref
	var/datum/weakref/target_ref
	var/datum/weakref/helper_ref
	var/stage = 0
	var/hits = 0
	var/infected = FALSE
	var/image/next_step
	var/hint

/datum/heretic_dance_lesson/New(datum/antag_training_session/session, datum/eldritch_knowledge/base_dance/dance, mob/living/student, mob/living/target)
	src.session = session
	dance_ref = WEAKREF(dance)
	student_ref = WEAKREF(student)
	target_ref = WEAKREF(target)
	RegisterSignal(dance, COMSIG_HERETIC_DANCE_EVENT, PROC_REF(on_event))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	for(var/knowledge_type in list(/datum/eldritch_knowledge/dance_grasp, /datum/eldritch_knowledge/spell/dance_invite))
		if(!heretic.get_knowledge(knowledge_type))
			heretic.gain_knowledge(knowledge_type)
	set_stage(DANCE_LESSON_HITS)

/datum/heretic_dance_lesson/Destroy()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(dance)
		UnregisterSignal(dance, COMSIG_HERETIC_DANCE_EVENT)
	hide_next_step()
	var/mob/living/helper = helper_ref?.resolve()
	if(helper)
		QDEL_NULL(helper.mind)
		qdel(helper)
	session = null
	return ..()

/datum/heretic_dance_lesson/proc/finished()
	return stage >= DANCE_LESSON_DONE

/datum/heretic_dance_lesson/proc/steps()
	. = list()
	var/list/names = list("Три удара в долю", "Квадрат Вальса", "Смена стиля", "Заражение и Приглашение", "Спасение партнёра")
	for(var/index in 1 to length(names))
		. += list(list("name" = names[index], "done" = stage > index, "current" = stage == index))

/datum/heretic_dance_lesson/proc/say(message)
	var/mob/living/student = student_ref?.resolve()
	if(student)
		to_chat(student, span_eldritch("Урок Пляски: [message]"))

/datum/heretic_dance_lesson/proc/set_stage(new_stage)
	var/changed = stage != new_stage
	stage = new_stage
	if(changed)
		hide_next_step()
	switch(stage)
		if(DANCE_LESSON_HITS)
			hint = "Шаг 1 из 5. Встаньте вплотную к мишени и ударьте её [DANCE_LESSON_HITS_NEEDED] раза в долю: бейте, когда барабан справа вспыхивает. Засчитано: [hits] из [DANCE_LESSON_HITS_NEEDED]."
		if(DANCE_LESSON_SQUARE)
			hint = "Шаг 2 из 5. Квадрат Вальса: стоя вплотную к мишени, шагните вперёд, вправо, назад и влево, каждый шаг в свою долю. Первый шаг - в любую сторону, дальше медный след покажет, куда шагнуть."
		if(DANCE_LESSON_SWITCH)
			hint = "Шаг 3 из 5. Нажмите на барабан и выберите Танго. Попадёте в сильную долю - связка сохранит Такт и удвоит акцент; мимо - Танго вступит на следующей сильной доле."
		if(DANCE_LESSON_INVITE)
			hint = "Шаг 4 из 5. Хваткой Мансуса в намерении «Помощь» коснитесь мишени, чтобы заразить её мелодией. Затем отойдите на 3-7 клеток и позовите её Приглашением: она придёт к вам шаг в долю."
		if(DANCE_LESSON_RESCUE)
			hint = "Шаг 5 из 5. Так экипаж спасает партнёра: помощник трясёт его 2 секунды. Ударьте помощника, чтобы сорвать спасение, или посмотрите, как рвётся танец."
			if(changed)
				INVOKE_ASYNC(src, PROC_REF(call_helper))
		if(DANCE_LESSON_DONE)
			hint = "Урок пройден. Танец срывают: растолкать за 2 секунды, схватить, повалить, пристегнуть, наушники-заглушки, нулевой жезл, святая вода."
	if(changed)
		say(hint)
	session?.update_practice()

/datum/heretic_dance_lesson/proc/on_event(datum/source, event, atom/subject, value)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_dance/dance = source
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(DANCE_LESSON_HITS)
			if(event != "strike" || subject != target)
				return
			if(value == HERETIC_DANCE_MISS)
				say("мимо: удар [dance.last_timing_early ? "раньше" : "позже"] доли. Барабан вспыхивает на каждой доле, крупнее - на сильной; бейте ровно на вспышку.")
				return
			hits++
			if(hits >= DANCE_LESSON_HITS_NEEDED)
				say("[value == HERETIC_DANCE_PERFECT ? "точно" : "в долю"]! Такт растёт быстрее, когда удар в долю.")
				set_stage(DANCE_LESSON_SQUARE)
				return
			say("[value == HERETIC_DANCE_PERFECT ? "точно" : "в долю"], засчитано [hits] из [DANCE_LESSON_HITS_NEEDED].")
			set_stage(DANCE_LESSON_HITS)
		if(DANCE_LESSON_SQUARE)
			switch(event)
				if("step")
					show_next_step(dance)
				if("figure_lost")
					hide_next_step()
					say("фигура сбилась: [value]. Начните квадрат заново, по шагу в каждую долю.")
				if("figure")
					if(dance.style_id != HERETIC_DANCE_STYLE_WALTZ)
						return
					if(value)
						say("квадрат собран: мишень повторяет ваши шаги.")
						set_stage(DANCE_LESSON_SWITCH)
					else
						say("квадрат собран, но вплотную к вам нет мишени. Встаньте рядом с ней и повторите.")
				if("figure_cooldown")
					say("квадрат собран, но фигура ещё остывает: подождите [value] долей.")
		if(DANCE_LESSON_SWITCH)
			switch(event)
				if("switch_queued")
					say("стиль выбран мимо сильной доли и ждёт её. Такт не пропадёт.")
				if("switch")
					switch(value)
						if("linked")
							say("связка в сильную долю: Такт сохранён, следующий акцент удвоен.")
						if("queued")
							say("стиль дождался сильной доли: Такт сохранён.")
						else
							say("смена сразу мимо сильной доли разделила Такт пополам.")
					set_stage(DANCE_LESSON_INVITE)
		if(DANCE_LESSON_INVITE)
			switch(event)
				if("infect")
					if(subject == target && !infected)
						infected = TRUE
						say("мишень слышит мелодию: над ней нота, видная только вам. Теперь отойдите на 3-7 клеток и примените Приглашение.")
				if("invite_stopped")
					if(subject == target)
						say("приглашение сорвалось: [value].")
				if("partner")
					if(subject == target)
						say("мишень дошла до вас и стала партнёром на 4 секунды.")
						set_stage(DANCE_LESSON_RESCUE)
		if(DANCE_LESSON_RESCUE)
			if(event == "rescued" && subject == target)
				say("партнёра растолкали: лента порвалась, музыка оборвалась.")
				set_stage(DANCE_LESSON_DONE)

/// Медный след на клетке, куда нужен следующий шаг квадрата; виден только ученику.
/datum/eldritch_knowledge/base_dance/proc/next_figure_dir()
	var/datum/heretic_dance_style/style = current_style()
	var/progress = figure_progress()
	if(!progress || progress >= length(style.figure))
		return null
	var/first = figure_steps[length(figure_steps) - progress + 1]
	return turn(first, style.figure[progress + 1])

/datum/heretic_dance_lesson/proc/show_next_step(datum/eldritch_knowledge/base_dance/dance)
	hide_next_step()
	var/mob/living/student = student_ref?.resolve()
	var/direction = dance.next_figure_dir()
	if(!student?.client || !direction)
		return
	var/turf/spot = get_step(student, direction)
	if(!spot)
		return
	next_step = image('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', spot, "dance_next_step", ABOVE_OPEN_TURF_LAYER, direction)
	student.client.images += next_step

/datum/heretic_dance_lesson/proc/hide_next_step()
	if(!next_step)
		return
	var/mob/living/student = student_ref?.resolve()
	student?.client?.images -= next_step
	next_step = null

/// Помощник подходит к партнёру и трясёт его, как сделал бы экипаж.
/datum/heretic_dance_lesson/proc/call_helper()
	var/mob/living/target = target_ref?.resolve()
	if(!target || !session?.arena)
		set_stage(DANCE_LESSON_DONE)
		return
	var/zone_id = session.arena.match_zone(target)
	var/mob/living/carbon/human/helper = session.arena.spawn_creature("human", zone_id, FALSE, session)
	if(!helper)
		say("места для помощника на полигоне нет: удалите лишние цели.")
		set_stage(DANCE_LESSON_DONE)
		return
	helper.real_name = "Помощник"
	helper.name = helper.real_name
	helper_ref = WEAKREF(helper)
	for(var/turf/spot in orange(1, target))
		if(!spot.is_blocked_turf(exclude_mobs = FALSE))
			helper.forceMove(spot)
			break
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_capture_shake), helper, target)
	addtimer(CALLBACK(src, PROC_REF(rescue_timeout)), HERETIC_DANCE_PARTNER_TIME + 1 SECONDS)

/datum/heretic_dance_lesson/proc/rescue_timeout()
	if(stage != DANCE_LESSON_RESCUE)
		return
	say("вы удержали партнёра: удар по помощнику срывает спасение.")
	set_stage(DANCE_LESSON_DONE)

#undef DANCE_LESSON_HITS
#undef DANCE_LESSON_SQUARE
#undef DANCE_LESSON_SWITCH
#undef DANCE_LESSON_INVITE
#undef DANCE_LESSON_RESCUE
#undef DANCE_LESSON_DONE
#undef DANCE_LESSON_HITS_NEEDED
