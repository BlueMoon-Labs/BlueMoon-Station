#define DUSK_LESSON_FORM 1
#define DUSK_LESSON_LAMP 2
#define DUSK_LESSON_BEAM 3
#define DUSK_LESSON_STEP 4
#define DUSK_LESSON_STRIKE 5
#define DUSK_LESSON_GRIP 6
#define DUSK_LESSON_DRAG 7
#define DUSK_LESSON_COVENANT 8
#define DUSK_LESSON_GLARE 9
#define DUSK_LESSON_HOLY 10
#define DUSK_LESSON_SPLASH_DELAY (2 SECONDS)

/datum/eldritch_knowledge/base_dusk/on_gain(mob/user)
	. = ..()
	heretic_path_lesson_notice(user, "dusk")

/// Длительность для подсказок в винительном падеже: «1 секунду», «0,8 секунды», «5 секунд».
/proc/heretic_dusk_seconds(time)
	var/seconds = round(time / (1 SECONDS), 0.1)
	return "[replacetext("[seconds]", ".", ",")] [ru_plural(seconds, "секунду", "секунды", "секунд")]"

/// Урок Сумрака по ступеням пути: облики, лампа и её луч, Шаг в тень с Ударом из тени, Хватка тени и добивание, учебный Завет, Лик ангела по мишени в очках и святая вода учебного капеллана.
/datum/heretic_path_lesson/dusk
	path_id = PATH_DUSK
	base_type = /datum/eldritch_knowledge/base_dusk
	title = "Урок Сумрака"
	icon = "feather-alt"
	knowledge_types = list(/datum/eldritch_knowledge/spell/dusk_step, /datum/eldritch_knowledge/spell/dusk_grip, /datum/eldritch_knowledge/spell/dusk_covenant, /datum/eldritch_knowledge/dusk_grasp, /datum/eldritch_knowledge/dusk_mark, /datum/eldritch_knowledge/spell/dusk_glare)
	step_names = list("Два облика", "Заговор лампы", "Луч лампы", "Шаг в тень", "Удар из тени", "Хватка тени", "Утянуть в тень", "Завет", "Лик ангела", "Святая вода")
	var/datum/weakref/lamp_ref
	var/datum/weakref/chaplain_ref

/datum/heretic_path_lesson/dusk/setup(datum/antagonist/heretic/heretic, datum/eldritch_knowledge/base_dusk/dusk, mob/living/student, mob/living/target)
	var/obj/item/melee/sickly_blade/dusk/blade = add_prop(new /obj/item/melee/sickly_blade/dusk(get_turf(student)))
	student.put_in_hands(blade)
	refill(dusk)

/datum/heretic_path_lesson/dusk/proc/refill(datum/eldritch_knowledge/base_dusk/dusk)
	dusk.combat_resource = dusk.combat_resource_max
	dusk.fill_charges("step")
	dusk.fill_charges("descent")
	dusk.notify_resource_changed()

/datum/heretic_path_lesson/dusk/proc/glare_seconds()
	var/datum/eldritch_knowledge/base_dusk/dusk = base_ref?.resolve()
	return dusk ? dusk.glare_blind() : HERETIC_DUSK_GLARE_BLIND

/datum/heretic_path_lesson/dusk/proc/grip_seconds(short = FALSE)
	var/datum/eldritch_knowledge/base_dusk/dusk = base_ref?.resolve()
	return dusk ? dusk.grip_time(short) : (short ? HERETIC_DUSK_GRIP_LIT_TIME : HERETIC_DUSK_GRIP_TIME)

/datum/heretic_path_lesson/dusk/stage_text(for_stage)
	switch(for_stage)
		if(DUSK_LESSON_FORM)
			return "Нажмите «Смена облика». Лик копит Сумрак на освещённой клетке, а его взгляд и луч бьют только перед собой; Крыло копит Сумрак в тени, видит в темноте, хватает чужие тени, а спереди его закрывают крылья. Облик виден на значке Сумрака: буква Л или К горит ярко, пока Сумрак копится."
		if(DUSK_LESSON_LAMP)
			return "Рядом встала лампа. В намерении «Помощь» коснитесь её Хваткой Мансуса: лампа запомнит вас и будет мигать, когда мимо пройдёт член экипажа."
		if(DUSK_LESSON_BEAM)
			return "Вернитесь в Лик и нажмите «Луч лампы», указав на мишень: Лик сам повернётся к ней, а ваша лампа ударит её светом на [HERETIC_DUSK_BEAM_DAMAGE] ожогов. Луч достаёт только того, кого видит заговорённая лампа не дальше [HERETIC_DUSK_BEAM_RANGE] клеток."
		if(DUSK_LESSON_STEP)
			return "Смените облик на Крыло и нажмите «Шаг в тень», указав на мишень: вы встанете за ней, на клетку с дальней от вас стороны. На мишени выжженная тень, как от удара Лика в спину, поэтому Шаг ведёт к ней и на ярком свету полигона. Заряды Шага - буква Ш на значке Сумрака."
		if(DUSK_LESSON_STRIKE)
			return "Ещё раз шагните за мишень и ударьте её Пером падшего не позже чем через [heretic_dusk_seconds(HERETIC_DUSK_STRIKE_WINDOW)]: это Удар из тени, +[HERETIC_DUSK_STRIKE_DAMAGE] урона и замедление. Пока удар готов, фон значка Сумрака багровый. Тот же удар открывает и смена облика."
		if(DUSK_LESSON_GRIP)
			return "В облике Крыла нажмите «Хватка тени» и укажите на мишень: под ней вспухнет тень и прибьёт её к полу. В тени, в затмении и по выжженной или отнятой тени Хватка держит [heretic_dusk_seconds(grip_seconds())], на свету - [heretic_dusk_seconds(grip_seconds(TRUE))]. Если цель успеет уйти дальше [HERETIC_DUSK_GRIP_RANGE] клеток, Сумрак вернётся."
		if(DUSK_LESSON_DRAG)
			return "Подойдите вплотную к прибитой мишени и ударьте её Пером в намерении «Схватить»: за [heretic_dusk_seconds(HERETIC_DUSK_DRAG_TIME)] тень утянет её - [HERETIC_DUSK_DRAG_DAMAGE] ушибов мишени, вам +[HERETIC_DUSK_DRAG_HEAL] здоровья. Свет в лицо, второе попадание по вам или одно от [HERETIC_DUSK_DRAG_BREAK_DAMAGE] урона и «растолкать» срывают добивание. Если Хватка спадёт, прибейте мишень снова."
		if(DUSK_LESSON_COVENANT)
			return "Нажмите кнопку «Завет» и выберите любой из трёх: Нимб - свет и контроль, Крыло - убийца из тени, Скверна - заражение. В раунде Завет выбирают один раз и до конца раунда, а на полигоне путь можно подготовить заново и попробовать другой."
		if(DUSK_LESSON_GLARE)
			return "На мишень надели тёмные очки. В Лике нажмите «Лик ангела» и укажите в её сторону: смотрящие на вас слепнут на [heretic_dusk_seconds(glare_seconds())], но очки и сварочные маски держат свет."
		if(DUSK_LESSON_HOLY)
			return "Рядом встал учебный капеллан. Он плеснёт на вас святой водой: посмотрите, что святое делает с падшим."
	return "Урок пройден. Против Сумрака: святая вода, нулевой жезл, Библия капеллана и часовня жгут его в любом облике; святую воду наливают в часовне, варят химик и бармен. Без капеллана: от Лика - тёмные очки и сварочные маски, заходите сбоку и сзади; Крыло прикрыто только спереди - бейте и стреляйте в спину, держитесь группой спиной к стене, чтобы Шагу некуда было ступить; во тьме Крыло выдают отблески глаз, а луч фонаря в лицо даже издалека или вспышка на время отнимают у него тёмное зрение. Хватку тени растолкают за 2 секунды, святая вода, нулевой жезл и Библия капеллана рвут её сразу, а добивание из тени срывают свет в лицо Крылу, два удара по нему или один сильный. Вспышку нимба при смене облика держат тёмные очки, лазер в лицо Лик пьёт - стреляйте сбоку, пришитую ударом Пера тень рвёт свет, брошенное Перо сбивает нулевой жезл или Библия в руке. Против Заветов: свет Нимба вдвое слабее для тёмных очков, Крылу фонарь в лицо вплотную сбивает Шаг, скверну снимают огонь, очиститель и святая вода."

/datum/heretic_path_lesson/dusk/prepare_stage(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_dusk/dusk = base_ref?.resolve()
	var/mob/living/carbon/human/target = target_ref?.resolve()
	if(!student || !dusk || stage != for_stage)
		return
	refill(dusk)
	switch(for_stage)
		if(DUSK_LESSON_LAMP)
			place_lamp(student)
		if(DUSK_LESSON_BEAM)
			place_target_by_lamp(student)
		if(DUSK_LESSON_STEP, DUSK_LESSON_STRIKE, DUSK_LESSON_GRIP, DUSK_LESSON_DRAG)
			target?.apply_status_effect(/datum/status_effect/heretic_dusk_burnt, dusk)
			if(for_stage == DUSK_LESSON_GRIP || for_stage == DUSK_LESSON_DRAG)
				ready_grip(student)
		if(DUSK_LESSON_COVENANT)
			var/datum/heretic_dusk_covenant/chosen = dusk.covenant_datum()
			if(chosen)
				advance("[chosen.name] уже принесён. Сменить его на полигоне можно, подготовив путь заново.")
		if(DUSK_LESSON_GLARE)
			if(istype(target) && !target.glasses)
				var/obj/item/clothing/glasses/sunglasses/shades = add_prop(new /obj/item/clothing/glasses/sunglasses(get_turf(target)))
				target.equip_to_slot_or_del(shades, ITEM_SLOT_EYES)
			face_student(student)
		if(DUSK_LESSON_HOLY)
			var/turf/spot = free_spot_near(student)
			var/mob/living/carbon/human/chaplain = spot && call_extra(student, spot, "Учебный капеллан")
			if(chaplain)
				chaplain_ref = WEAKREF(chaplain)
				addtimer(CALLBACK(src, PROC_REF(splash), for_stage), DUSK_LESSON_SPLASH_DELAY)

/// На шагах Хватки она готова сразу: перезарядка с прошлой попытки не держит урок.
/datum/heretic_path_lesson/dusk/proc/ready_grip(mob/living/student)
	var/obj/effect/proc_holder/spell/pointed/heretic_dusk/grip/power = locate() in student.mind?.spell_list
	if(power)
		power.charge_counter = power.charge_max
		power.recharging = FALSE
		power.action?.UpdateButtons()

/datum/heretic_path_lesson/dusk/proc/place_lamp(mob/living/student)
	var/turf/spot = spot_in_line(student, 2) || free_spot_near(student)
	if(!spot)
		say("для лампы нет места: отойдите на свободный пол и начните урок заново.")
		return
	var/obj/machinery/light/small/lamp = add_prop(new /obj/machinery/light/small(spot))
	lamp_ref = WEAKREF(lamp)

/// Мишень встаёт в двух клетках от лампы, лицом к ученику.
/datum/heretic_path_lesson/dusk/proc/place_target_by_lamp(mob/living/student)
	var/mob/living/target = target_ref?.resolve()
	var/obj/machinery/light/lamp = lamp_ref?.resolve()
	if(!target || !lamp)
		return
	var/turf/spot = free_spot_near(lamp, RANGE_TURFS(1, student))
	if(spot)
		target.forceMove(spot)
	face_student(student)

/datum/heretic_path_lesson/dusk/proc/face_student(mob/living/student)
	var/mob/living/target = target_ref?.resolve()
	if(target && student)
		target.setDir(get_dir(target, student))

/datum/heretic_path_lesson/dusk/proc/splash(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/mob/living/chaplain = chaplain_ref?.resolve()
	if(stage != for_stage || !student || !chaplain)
		return
	chaplain.visible_message(span_warning("[chaplain] плещет на [student] святой водой!"))
	var/datum/reagents/holy = new(10)
	holy.add_reagent(/datum/reagent/water/holywater, 10)
	holy.reaction(student, TOUCH)
	qdel(holy)

/datum/heretic_path_lesson/dusk/handle_event(event, atom/subject, value)
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(DUSK_LESSON_FORM)
			if(event == "form")
				advance(value == HERETIC_DUSK_FORM_WING ? "вы раскрыли Крыло. Сумрак копится в нём в тени, тьма видна вам холодными сумерками, а Хватка тени и Шаг в тень работают только в Крыле. Во тьме экипаж видит отблеск ваших глаз, а луч фонаря в лицо или вспышка гасят ваше тёмное зрение на [heretic_dusk_seconds(HERETIC_DUSK_SIGHT_SNUFF)]." : "вы обратили к миру Лик. На свету он быстрее и копит Сумрак.")
		if(DUSK_LESSON_LAMP)
			if(event == "lamp" && subject == lamp_ref?.resolve())
				advance("лампа помнит вас. На станции она мигнёт на прохожем члене экипажа - это дело пути, а экипаж видит на плафоне копоть в форме пера.")
		if(DUSK_LESSON_BEAM)
			if(event == "beam" && subject == target)
				advance("луч попал. Лик сам поворачивается к цели, а бьёт её ваша лампа: от луча уходят дальше [HERETIC_DUSK_BEAM_RANGE] клеток от заговорённых ламп или за стену.")
		if(DUSK_LESSON_STEP)
			if(event == "step" && subject == target)
				advance("вы за мишенью. Шаг ведёт только в чужую тень: к человеку, к отнятой тени или к своей лампе. Стена или товарищ за целью не пустят вас.")
		if(DUSK_LESSON_STRIKE)
			if(event == "strike" && subject == target)
				advance("Удар из тени: мишень замедлена. Связывайте Шаг и удар, а второй заряд оставляйте на отход.")
		if(DUSK_LESSON_GRIP)
			if(event == "grip" && subject == target)
				advance("мишень прибита. На станции прибитую цель охоты сердце уводит в изнанку, если вы стоите рядом; растолкать её можно за [heretic_dusk_seconds(HERETIC_CAPTURE_SHAKE_TIME)], а святая вода, нулевой жезл и Библия капеллана рвут Хватку сразу.")
		if(DUSK_LESSON_DRAG)
			if(event == "drag" && subject == target)
				advance("тень утянула мишень. Это главный захват Крыла: прибить Хваткой, подойти и утянуть, пока никто не посветил вам в лицо.")
		if(DUSK_LESSON_COVENANT)
			if(event == "covenant")
				var/datum/heretic_dusk_covenant/chosen = GLOB.heretic_dusk_covenants[value]
				advance("[chosen?.name] принесён: облик мутации перерос, часть приёмов сменилась. Что он меняет - в кодексе, в записи четвёртой ступени.")
		if(DUSK_LESSON_GLARE)
			if(event == "glare")
				advance(value ? "мишень ослепла: очки слетели или она смотрела мимо. Без очков взгляд Лика слепит на [heretic_dusk_seconds(glare_seconds())]." : "мишень в очках не ослепла. Тёмные очки и сварочные маски - честный ответ экипажа на Лик.")
		if(DUSK_LESSON_HOLY)
			if(event == "holy")
				var/burn = round(value)
				advance("святая вода обожгла вас на [burn] [ru_plural(burn, "ожог", "ожога", "ожогов")], сорвала облик и на [heretic_dusk_seconds(HERETIC_DUSK_HOLY_FORM_LOCK)] заперла его смену, а Сумрак [heretic_dusk_seconds(HERETIC_DUSK_HOLY_SILENCE)] не копился.")

#undef DUSK_LESSON_FORM
#undef DUSK_LESSON_LAMP
#undef DUSK_LESSON_BEAM
#undef DUSK_LESSON_STEP
#undef DUSK_LESSON_STRIKE
#undef DUSK_LESSON_GRIP
#undef DUSK_LESSON_DRAG
#undef DUSK_LESSON_COVENANT
#undef DUSK_LESSON_GLARE
#undef DUSK_LESSON_HOLY
#undef DUSK_LESSON_SPLASH_DELAY
