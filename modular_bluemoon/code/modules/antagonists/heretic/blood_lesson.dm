#define BLOOD_LESSON_BIND 1
#define BLOOD_LESSON_MARK 2
#define BLOOD_LESSON_COLLECT 3
#define BLOOD_LESSON_SNARE 4
#define BLOOD_LESSON_FULL_DEBT 20
#define BLOOD_LESSON_HOLD_INTERVAL (3 SECONDS)

/datum/eldritch_knowledge/base_blood/on_gain(mob/user)
	. = ..()
	heretic_path_lesson_notice(user, "blood")

/// Урок Крови: связь, Метка Крови как вторая связь, взыскание по намерению и путы.
/datum/heretic_path_lesson/blood
	path_id = PATH_BLOOD
	base_type = /datum/eldritch_knowledge/base_blood
	title = "Урок Крови"
	icon = "droplet"
	knowledge_types = list(/datum/eldritch_knowledge/blood_grasp, /datum/eldritch_knowledge/blood_mark)
	step_names = list("Связь", "Метка Крови", "Взыскание по намерению", "Путы")
	var/datum/weakref/second_ref
	var/hold_timer

/datum/heretic_path_lesson/blood/stage_text(for_stage)
	switch(for_stage)
		if(BLOOD_LESSON_BIND)
			return "Нажмите значок «Кровный долг» и укажите мишень не дальше [HERETIC_BLOOD_RANGE] клеток без преград: ляжет связь и 10 долга. Удар клинком и Хватка тоже связывают."
		if(BLOOD_LESSON_MARK)
			return "Связь занята мишенью. Рядом встал второй должник: коснитесь его Хваткой Мансуса - Метка Крови даст вторую связь, но она не продлевается и гаснет сама."
		if(BLOOD_LESSON_COLLECT)
			return "Долг мишени полон. Подпись значка долга меняется с намерением - взгляните на неё. В «Разоружении» нажмите значок и укажите мишень: через секунду взыщется часть долга, остаток останется в связи. Держите её в [HERETIC_BLOOD_RANGE] клетках без преград."
		if(BLOOD_LESSON_SNARE)
			return "В «Захвате» нажмите значок и укажите мишень: [HERETIC_BLOOD_TETHER_COST] долга уйдут в путы, и [HERETIC_BLOOD_TETHER_DURATION / (1 SECONDS)] секунды она не отойдёт от вас."
	return "Урок пройден. Против Крови: взыскание видно за секунду - уйдите за преграду или дальше [HERETIC_BLOOD_RANGE] клеток, и связь порвётся через [HERETIC_BLOOD_CONTACT_GRACE / (1 SECONDS)] секунды без контакта; помеченную кровь снимают швабра, космочист и нулевой жезл; антимагия гасит связь."

/datum/heretic_path_lesson/blood/prepare_stage(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = base_ref?.resolve()
	if(!student || !blood || stage != for_stage)
		return
	switch(for_stage)
		if(BLOOD_LESSON_MARK)
			var/turf/spot = free_spot_near(student)
			if(!spot)
				say("для второго должника нет места: отойдите на свободный пол и начните урок заново.")
				return
			var/mob/living/second = call_extra(student, spot, "Второй должник")
			second_ref = WEAKREF(second)
			keep_target()
		if(BLOOD_LESSON_COLLECT)
			drop_prop(second_ref?.resolve())
			second_ref = null
			fill_debt(blood, BLOOD_LESSON_FULL_DEBT)
		if(BLOOD_LESSON_SNARE)
			fill_debt(blood, HERETIC_BLOOD_TETHER_COST)

/datum/heretic_path_lesson/blood/Destroy()
	deltimer(hold_timer)
	hold_timer = null
	return ..()

/// Пока идёт шаг Метки, связь мишени продлевается: ученик может ждать перезарядку Хватки сколько нужно.
/datum/heretic_path_lesson/blood/proc/keep_target()
	hold_timer = null
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = base_ref?.resolve()
	if(QDELETED(src) || stage != BLOOD_LESSON_MARK || !student || !blood)
		return
	hold_target(student, blood)
	hold_timer = addtimer(CALLBACK(src, PROC_REF(keep_target)), BLOOD_LESSON_HOLD_INTERVAL, TIMER_STOPPABLE)

/// Метка Крови встаёт только при занятой связи: на этом шаге связь мишени не должна истечь, пока ученик идёт ко второму.
/datum/heretic_path_lesson/blood/proc/hold_target(mob/living/student, datum/eldritch_knowledge/base_blood/blood)
	var/mob/living/target = target_ref?.resolve()
	if(!target || !student || !blood)
		return
	var/datum/status_effect/heretic_blood_seal/seal = target.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal?.blood_ref?.resolve() == blood)
		blood.add_debt(seal, 0, renew = TRUE)
	else if(!seal)
		blood.bind(student, target)

/// Хватка по второму легла обычной связью, потому что связь мишени истекла: снять её и связать мишень заново.
/datum/heretic_path_lesson/blood/proc/redo_mark(mob/living/second)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = base_ref?.resolve()
	if(stage != BLOOD_LESSON_MARK || !student || !blood)
		return
	second?.remove_status_effect(/datum/status_effect/heretic_blood_seal)
	hold_target(student, blood)
	say("связь с мишенью истекла, поэтому Хватка легла обычной связью - Метка встаёт только сверх занятой связи. Мишень снова связана: коснитесь второго должника ещё раз.")

/// Долг мишени не ниже amount: на уроке шаг не ждёт ударов клинком.
/datum/heretic_path_lesson/blood/proc/fill_debt(datum/eldritch_knowledge/base_blood/blood, amount)
	var/mob/living/target = target_ref?.resolve()
	var/datum/status_effect/heretic_blood_seal/seal = target?.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(!seal || seal.blood_ref?.resolve() != blood || seal.debt >= amount)
		return
	blood.add_debt(seal, amount - seal.debt, renew = TRUE)

/datum/heretic_path_lesson/blood/handle_event(event, atom/subject, value)
	var/mob/living/target = target_ref?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = base_ref?.resolve()
	switch(stage)
		if(BLOOD_LESSON_BIND)
			if(event == "bind" && subject == target)
				advance("связь легла. Пока цель в [HERETIC_BLOOD_RANGE] клетках без преград, удары клинка копят на ней долг.")
		if(BLOOD_LESSON_MARK)
			if(event == "bind" && subject == second_ref?.resolve())
				if(value)
					advance("Метка Крови горит на втором должнике. Второй противник не ждёт, пока освободится первая связь.")
				else
					INVOKE_ASYNC(src, PROC_REF(redo_mark), subject)
		if(BLOOD_LESSON_COLLECT, BLOOD_LESSON_SNARE)
			if(event == "bind" && subject == target)
				INVOKE_ASYNC(src, PROC_REF(fill_debt), blood, stage == BLOOD_LESSON_COLLECT ? BLOOD_LESSON_FULL_DEBT : HERETIC_BLOOD_TETHER_COST)
			else if(stage == BLOOD_LESSON_COLLECT && event == "collect" && subject == target)
				if(value > 0)
					advance("взыскана часть долга, остаток держит связь. «Вред» и «Помощь» взыскивают всё разом, а взыскание возвращает вам четверть урона.")
				else
					say("взыскан весь долг: так бьют «Вред» и «Помощь». Свяжите мишень заново и взыщите в «Разоружении».")
			else if(stage == BLOOD_LESSON_SNARE && event == "snare" && subject == target)
				advance("путы держат. На свежей крови или скользком следе взыскание ещё и прибьёт должника шипом.")

#undef BLOOD_LESSON_BIND
#undef BLOOD_LESSON_MARK
#undef BLOOD_LESSON_COLLECT
#undef BLOOD_LESSON_SNARE
#undef BLOOD_LESSON_FULL_DEBT
#undef BLOOD_LESSON_HOLD_INTERVAL
