#define LEAD_LESSON_CASINGS 1
#define LEAD_LESSON_FINGER 2
#define LEAD_LESSON_SMELT 3
#define LEAD_LESSON_CURSE 4
#define LEAD_LESSON_NAMED 5
#define LEAD_LESSON_CATCH 6
#define LEAD_LESSON_RICOCHET 7
#define LEAD_LESSON_SCHOOL 8
#define LEAD_LESSON_DRUM 9
#define LEAD_LESSON_LAST_ROUND 10
#define LEAD_LESSON_DONE 11
#define LEAD_LESSON_DRILL_AIM (1 SECONDS)
#define LEAD_LESSON_DRILL_INTERVAL (3 SECONDS)
#define LEAD_LESSON_DRILL_DAMAGE 5
#define LEAD_LESSON_DRILL_DISTANCE 4
#define LEAD_LESSON_DISMISS (1 SECONDS)

/datum/eldritch_knowledge/base_lead/on_gain(mob/user)
	. = ..()
	var/datum/antag_training_session/session = GLOB.antag_training_sessions[user?.ckey]
	if(session?.current_body == user && !session.lead_lesson)
		to_chat(user, span_notice("Для Свинца на полигоне есть пошаговый урок: панель полигона, вкладка «Начать», раздел «2. Упражнение», кнопка «Урок Свинца»."))

/// Урок Свинца на полигоне: гильзы, Палец-ствол, Переплавка, заговор, Отдача и Пуля с именем, Ловля пули и Сглаз ствола против учебного стрелка, Рикошет, Школа стрельбы, барабан и Последний патрон; каждый шаг засчитывается настоящим действием пути.
/datum/heretic_lead_lesson
	var/datum/antag_training_session/session
	var/datum/weakref/lead_ref
	var/datum/weakref/student_ref
	var/datum/weakref/target_ref
	var/datum/weakref/gunner_ref
	var/list/datum/weakref/props = list()
	var/drill_timer
	var/stage = 0
	var/hint
	var/caught = FALSE
	var/hexed = FALSE

/datum/heretic_lead_lesson/New(datum/antag_training_session/session, datum/eldritch_knowledge/base_lead/lead, mob/living/student, mob/living/target)
	src.session = session
	lead_ref = WEAKREF(lead)
	student_ref = WEAKREF(student)
	target_ref = WEAKREF(target)
	RegisterSignal(lead, COMSIG_HERETIC_LEAD_EVENT, PROC_REF(on_event))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	for(var/knowledge_type in list(/datum/eldritch_knowledge/lead_grasp, /datum/eldritch_knowledge/spell/lead_named, /datum/eldritch_knowledge/lead_mark, /datum/eldritch_knowledge/lead_relic, /datum/eldritch_knowledge/spell/lead_catch, /datum/eldritch_knowledge/spell/lead_ricochet, /datum/eldritch_knowledge/lead_ear))
		if(!heretic.get_knowledge(knowledge_type))
			heretic.gain_knowledge(knowledge_type)
	heretic.sync_path_stage()
	give_revolver(heretic, student)
	lead.combat_resource = 0
	lead.bandolier = 0
	lead.notify_resource_changed()
	set_stage(LEAD_LESSON_CASINGS)

/datum/heretic_lead_lesson/Destroy()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(lead)
		UnregisterSignal(lead, COMSIG_HERETIC_LEAD_EVENT)
	deltimer(drill_timer)
	drill_timer = null
	dismiss_gunner()
	for(var/datum/weakref/prop_ref as anything in props)
		var/atom/movable/prop = prop_ref.resolve()
		if(prop)
			qdel(prop)
	props.Cut()
	session = null
	return ..()

/datum/heretic_lead_lesson/proc/give_revolver(datum/antagonist/heretic/heretic, mob/living/student)
	var/datum/eldritch_knowledge/lead_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lead_relic)
	if(recipe.new_path_relic_available())
		recipe.on_finished_recipe(student, list(), get_turf(student))
	var/obj/item/heretic_path_relic/lead_revolver/revolver = recipe.new_path_relic_ref?.resolve()
	if(revolver && !student.is_holding(revolver))
		student.put_in_hands(revolver)

/datum/heretic_lead_lesson/proc/finished()
	return stage >= LEAD_LESSON_DONE

/datum/heretic_lead_lesson/proc/steps()
	. = list()
	var/list/names = list("Гильзы", "Палец-ствол", "Переплавка", "Заговор ружья", "Пуля с именем", "Ловля и Сглаз", "Рикошет", "Школа стрельбы", "Барабан", "Последний патрон")
	for(var/index in 1 to length(names))
		. += list(list("name" = names[index], "done" = stage > index, "current" = stage == index))

/datum/heretic_lead_lesson/proc/say(message)
	var/mob/living/student = student_ref?.resolve()
	if(student)
		to_chat(student, span_eldritch("Урок Свинца: [message]"))

/datum/heretic_lead_lesson/proc/set_stage(new_stage)
	var/changed = stage != new_stage
	stage = new_stage
	switch(stage)
		if(LEAD_LESSON_CASINGS)
			hint = "Шаг 1 из 10. Рядом на полу лежат гильзы. Переключитесь на намерение «Помощь» и коснитесь их Хваткой Мансуса: каждая гильза даст единицу Свинца."
		if(LEAD_LESSON_FINGER)
			hint = "Шаг 2 из 10. Палец-ствол: возьмите Хватку, переключитесь на любое намерение, кроме «Помощи», и нажмите на цель издали, не дальше [HERETIC_LEAD_FINGER_RANGE] клеток: вплотную Хватка бьёт как обычно. Дробина на [HERETIC_LEAD_FINGER_DAMAGE] ушибов не оглушает, а у цели звякнет гильза: её, как любую, впитает Хватка в «Помощи»."
		if(LEAD_LESSON_SMELT)
			hint = "Шаг 3 из 10. Рядом лежит стопка железа. В намерении «Помощь» коснитесь её Хваткой и секунду не двигайтесь: [HERETIC_LEAD_SMELT_SHEETS] листов переплавятся в единицу Свинца, а заряд Хватки останется. Магазин с патронами даёт [HERETIC_LEAD_SMELT_MAGAZINE_LEAD] и заодно заговаривается."
		if(LEAD_LESSON_CURSE)
			hint = "Шаг 4 из 10. Рядом лежит ружьё. В намерении «Помощь» коснитесь его Хваткой: в руках экипажа заговорённое оружие [HERETIC_LEAD_CURSE_CHARGES] раза даст осечку."
		if(LEAD_LESSON_NAMED)
			hint = "Шаг 5 из 10. Примените «Пулю с именем» к цели: за [HERETIC_LEAD_NAMED_COST] Свинца медленная пуля сама доворачивает к цели не дальше [HERETIC_LEAD_NAMED_RANGE] клеток. Можно сначала ударить цель Хваткой вплотную не в «Помощи»: Отдача отбросит её и возьмёт на Пристрелку на [HERETIC_LEAD_ZEROED_TIME / (1 SECONDS)] секунд, а цель охоты под Пристрелкой Пуля с именем валит сразу."
		if(LEAD_LESSON_CATCH)
			hint = "Шаг 6 из 10. Учебный стрелок раз в [LEAD_LESSON_DRILL_INTERVAL / (1 SECONDS)] секунды целится в вас, и от него тянется красная линия. Увидев её, нажмите «Ловлю пули»: пойманная пуля не ранит и даёт Свинец. А «Сглаз ствола» на стрелке сорвёт его следующий выстрел осечкой. Шаг засчитают Ловля и Сглаз в любом порядке; учебные пули безвредны, даже непойманные."
		if(LEAD_LESSON_RICOCHET)
			hint = "Шаг 7 из 10. Попадите пулей Шестизарядника в стену, вещь или цель (или дробиной Пальца-ствола в цель) и не позже чем через [HERETIC_LEAD_RICOCHET_MEMORY / (1 SECONDS)] секунд нажмите «Рикошет»: вы окажетесь там, куда она ударила. Пуля над полом летит дальше и точку не ставит."
		if(LEAD_LESSON_SCHOOL)
			hint = "Шаг 8 из 10. Школа стрельбы: нажмите кнопку «Школа стрельбы» и выберите Стрелка, Охотника или Канонира. Выбор один раз и до сброса пути, работает сразу. Стрелок силён против толпы, Охотник - издали и ловушками, Канонир сразу получает Свинцовый дождь. Если Школа уже выбрана, шаг засчитается сам."
		if(LEAD_LESSON_DRUM)
			hint = "Шаг 9 из 10. Барабан: у каждой из шести камор своя пуля. Alt-клик по Шестизаряднику в руке открывает каморы - поставьте под курок Тяжёлую и попадите ею в цель: она валит с ног на [replacetext("[HERETIC_LEAD_HEAVY_KNOCKDOWN / (1 SECONDS)]", ".", ",")] секунды даже сквозь броню. Ctrl-клик крутит барабан на удачу: выпавшая пуля бьёт на [HERETIC_LEAD_LUCK_BONUS]% сильнее. Вплотную в намерении «Вред» Шестизарядник бьёт рукоятью: [HERETIC_LEAD_BUTT_DAMAGE] ушибов и единица Свинца."
		if(LEAD_LESSON_LAST_ROUND)
			hint = "Шаг 10 из 10. Барабан полон: Alt-кликом по Шестизаряднику взведите Шестую камору и выстрелите в цель. [replacetext("[HERETIC_LEAD_LAST_ROUND_AIM / (1 SECONDS)]", ".", ",")] секунды к ней тянется красная линия огня и на груди горит прицел - на станции это время укрыться за угол, лечь или закрыться щитом; затем Последний патрон на [HERETIC_LEAD_LAST_ROUND_DAMAGE] ушибов пробивает до [HERETIC_LEAD_LAST_ROUND_TARGETS] целей и забирает весь Свинец."
		if(LEAD_LESSON_DONE)
			hint = "Урок пройден. Против Свинца: лазеры и дубинки вместо пуль - они его не кормят и не ловятся, а дробину пальца держат щит и броня; детектив, капеллан и еретики видят патину на заговорённом оружии, нулевой жезл и святая вода снимают заговор и тяжесть; рядом с меченым лучше не стрелять; с 4 Свинца от еретика пахнет порохом, а от красной линии и прицела на груди надо уходить за угол. Против Школ: от кольца Мгновения расходятся и не палят все разом, растяжку находят осмотром клетки или Т-сканером и режут кусачками, Пороховую закладку заливают водой или пеной."
	if(changed)
		say(hint)
		INVOKE_ASYNC(src, PROC_REF(prepare_stage), stage)
	session?.update_practice()

/// Реквизит шага: гильзы, железо, ружьё, Свинец на выстрел, учебный стрелок.
/datum/heretic_lead_lesson/proc/prepare_stage(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!student || !lead || stage != for_stage)
		return
	switch(for_stage)
		if(LEAD_LESSON_CASINGS)
			var/turf/spot = free_spot_near(student)
			for(var/index in 1 to HERETIC_LEAD_CASINGS_PER_GRASP)
				props += WEAKREF(new /obj/item/ammo_casing/c38(spot))
		if(LEAD_LESSON_FINGER)
			refresh_grasp(student)
		if(LEAD_LESSON_SMELT)
			refresh_grasp(student)
			props += WEAKREF(new /obj/item/stack/sheet/metal(free_spot_near(student), HERETIC_LEAD_SMELT_SHEETS))
		if(LEAD_LESSON_CURSE)
			props += WEAKREF(new /obj/item/gun/ballistic/shotgun(free_spot_near(student)))
		if(LEAD_LESSON_NAMED)
			lead.combat_resource = max(lead.combat_resource, HERETIC_LEAD_NAMED_COST)
			lead.notify_resource_changed()
		if(LEAD_LESSON_CATCH)
			lead.combat_resource = max(lead.combat_resource, 1)
			lead.notify_resource_changed()
			call_gunner(student)
		if(LEAD_LESSON_RICOCHET)
			deltimer(drill_timer)
			drill_timer = null
			addtimer(CALLBACK(src, PROC_REF(dismiss_gunner)), LEAD_LESSON_DISMISS)
			lead.combat_resource = lead.combat_resource_max - 1
			lead.notify_resource_changed()
		if(LEAD_LESSON_SCHOOL)
			var/datum/heretic_lead_school/chosen = lead.school_datum()
			if(chosen)
				say("Школа уже выбрана. [chosen.lesson_text]")
				set_stage(LEAD_LESSON_DRUM)
		if(LEAD_LESSON_DRUM)
			lead.combat_resource = max(lead.combat_resource, HERETIC_LEAD_NAMED_COST)
			lead.notify_resource_changed()
		if(LEAD_LESSON_LAST_ROUND)
			lead.combat_resource = lead.combat_resource_max
			lead.notify_resource_changed()

/datum/heretic_lead_lesson/proc/free_spot_near(mob/living/student)
	for(var/turf/open/spot in orange(1, student))
		if(!spot.is_blocked_turf(exclude_mobs = TRUE))
			return spot
	return get_turf(student)

/// Клетка стрелка: в нескольких шагах по прямой, чтобы линия прицела была видна.
/datum/heretic_lead_lesson/proc/gunner_spot(mob/living/student)
	var/turf/origin = get_turf(student)
	for(var/direction in GLOB.cardinals)
		var/turf/spot = origin
		var/clear = TRUE
		for(var/step in 1 to LEAD_LESSON_DRILL_DISTANCE)
			spot = get_step(spot, direction)
			if(!isopenturf(spot) || spot.is_blocked_turf(exclude_mobs = TRUE))
				clear = FALSE
				break
		if(clear)
			return spot
	return free_spot_near(student)

/datum/heretic_lead_lesson/proc/call_gunner(mob/living/student)
	var/turf/spot = gunner_spot(student)
	var/mob/living/carbon/human/gunner
	if(session?.arena)
		gunner = session.arena.spawn_creature("human", session.arena.match_zone(student), FALSE, session, spot)
	else
		gunner = new(spot)
	if(!gunner)
		say("места для учебного стрелка на полигоне нет: удалите лишние цели и начните урок заново. Пока переходим к Рикошету.")
		set_stage(LEAD_LESSON_RICOCHET)
		return
	gunner.real_name = "Учебный стрелок"
	gunner.name = gunner.real_name
	gunner_ref = WEAKREF(gunner)
	var/obj/item/gun/ballistic/automatic/pistol/prop = new(get_turf(gunner))
	props += WEAKREF(prop)
	gunner.put_in_hands(prop)
	deltimer(drill_timer)
	drill_timer = addtimer(CALLBACK(src, PROC_REF(drill)), LEAD_LESSON_DRILL_AIM, TIMER_STOPPABLE)

/datum/heretic_lead_lesson/proc/dismiss_gunner()
	var/mob/living/gunner = gunner_ref?.resolve()
	gunner_ref = null
	if(gunner)
		QDEL_NULL(gunner.mind)
		qdel(gunner)

/// Стрелок прицеливается: красная линия на секунду, затем выстрел.
/datum/heretic_lead_lesson/proc/drill()
	drill_timer = null
	var/mob/living/student = student_ref?.resolve()
	var/mob/living/gunner = gunner_ref?.resolve()
	if(stage != LEAD_LESSON_CATCH || !student)
		return
	if(!gunner || gunner.stat != CONSCIOUS || !isturf(gunner.loc))
		say("учебный стрелок выбыл, на его место встаёт новый.")
		dismiss_gunner()
		call_gunner(student)
		return
	drill_timer = addtimer(CALLBACK(src, PROC_REF(drill)), LEAD_LESSON_DRILL_INTERVAL, TIMER_STOPPABLE)
	refresh_catch(student)
	gunner.Beam(student, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = LEAD_LESSON_DRILL_AIM)
	gunner.visible_message(span_warning("[gunner] целится в [student]!"))
	addtimer(CALLBACK(src, PROC_REF(drill_shot)), LEAD_LESSON_DRILL_AIM)

/// Шаги на Хватке идут подряд: на уроке её перезарядка не ждёт.
/datum/heretic_lead_lesson/proc/refresh_grasp(mob/living/student)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	var/datum/eldritch_knowledge/spell/basic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/proc_holder/spell/grasp = knowledge?.granted_spell
	if(grasp && grasp.charge_counter < grasp.charge_max)
		grasp.revert_cast(student)

/// Промахнувшийся с Ловлей не ждёт перезарядку: на уроке она возвращается к следующему прицелу.
/datum/heretic_lead_lesson/proc/refresh_catch(mob/living/student)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(student)
	var/datum/eldritch_knowledge/spell/lead_catch/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	var/obj/effect/proc_holder/spell/catch_spell = knowledge?.granted_spell
	if(catch_spell && catch_spell.charge_counter < catch_spell.charge_max && !student.has_status_effect(/datum/status_effect/heretic_lead_catch))
		catch_spell.revert_cast(student)

/datum/heretic_lead_lesson/proc/drill_shot()
	var/mob/living/student = student_ref?.resolve()
	var/mob/living/gunner = gunner_ref?.resolve()
	if(stage != LEAD_LESSON_CATCH || !student || !gunner || gunner.stat != CONSCIOUS || !isturf(gunner.loc))
		return null
	for(var/obj/item/gun/gun in gunner.held_items)
		var/datum/component/heretic_lead_curse/curse = gun.GetComponent(/datum/component/heretic_lead_curse)
		if(curse)
			qdel(curse)
			playsound(gunner, 'sound/weapons/empty.ogg', 40, TRUE)
			gunner.visible_message(span_warning("Пистолет [gunner] сухо щёлкает: осечка!"))
			return null
	var/obj/item/projectile/bullet/heretic_lead_drill/bullet = new(get_turf(gunner))
	bullet.firer = gunner
	bullet.fired_from = gunner
	bullet.preparePixelProjectile(student, gunner)
	if(QDELETED(bullet))
		return null
	bullet.fire()
	playsound(gunner, 'sound/weapons/Gunshot.ogg', 40, TRUE)
	return bullet

/datum/heretic_lead_lesson/proc/on_event(datum/source, event, atom/subject, value)
	SIGNAL_HANDLER
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(LEAD_LESSON_CASINGS)
			if(event == "casings")
				say("латунь растаяла в ладони. На станции гильзы остаются после любой перестрелки, а свои вы оставляете сами.")
				set_stage(LEAD_LESSON_FINGER)
		if(LEAD_LESSON_FINGER)
			if(event == "finger" && subject == target)
				say("дробина нашла цель. На станции её держат щит и броня, а вспышку у пальца и хлопок замечают все рядом.")
				set_stage(LEAD_LESSON_SMELT)
		if(LEAD_LESSON_SMELT)
			if(event == "smelt")
				say("железо ушло в Свинец. На станции металл лежит в инженерии, снабжении и на любой стройке.")
				set_stage(LEAD_LESSON_CURSE)
		if(LEAD_LESSON_CURSE)
			if(event == "curse")
				say("заговор лёг. На станции каждая осечка в руках экипажа в новом отделе продвигает дело пути.")
				set_stage(LEAD_LESSON_NAMED)
		if(LEAD_LESSON_NAMED)
			if(event == "named" && subject == target)
				var/mob/living/victim = subject
				var/zeroed_note = victim.has_status_effect(/datum/status_effect/heretic_lead_zeroed) ? " Цель была под Пристрелкой: будь она целью охоты, упала бы сразу." : ""
				say("пуля нашла цель: [HERETIC_LEAD_HEAVY_TIME / (1 SECONDS)] секунд тяжести, затем падение.[zeroed_note] На станции упавшую цель охоты живое сердце уводит в изнанку.")
				set_stage(LEAD_LESSON_CATCH)
		if(LEAD_LESSON_CATCH)
			if(event == "catch" && !caught)
				caught = TRUE
				say("пуля поймана: она не ранит и даёт Свинец. Лазеры и энергию так не поймать.[hexed ? "" : " Теперь наведите на стрелка «Сглаз ствола»."]")
			else if(event == "hex" && subject == gunner_ref?.resolve() && !hexed)
				hexed = TRUE
				say("сглаз лёг: следующий выстрел стрелка сорвётся осечкой. На станции так клинит огнестрел в руках врага в [HERETIC_LEAD_HEX_RANGE] клетках.[caught ? "" : " Теперь поймайте его пулю «Ловлей пули»."]")
			if(caught && hexed)
				set_stage(LEAD_LESSON_RICOCHET)
		if(LEAD_LESSON_RICOCHET)
			if(event == "ricochet")
				say("Рикошет удался. Точку ставит только удар вашей пули или дробины, и держится она [HERETIC_LEAD_RICOCHET_MEMORY / (1 SECONDS)] секунд.")
				set_stage(LEAD_LESSON_SCHOOL)
		if(LEAD_LESSON_SCHOOL)
			if(event == "school")
				var/datum/eldritch_knowledge/base_lead/lead = source
				var/datum/heretic_lead_school/chosen = lead.school_datum()
				say("Школа выбрана. [chosen?.lesson_text]")
				set_stage(LEAD_LESSON_DRUM)
		if(LEAD_LESSON_DRUM)
			if(event == "round_hit" && subject == target && value == /obj/item/projectile/bullet/heretic_lead/heavy)
				say("Тяжёлая пуля сбила цель. Стиль выстрела меняет «Использовать в руке»: прицельный выстрел после секунды без движения бьёт сильнее и пробивает броню, а веер выпускает все каморы за секунду.")
				set_stage(LEAD_LESSON_LAST_ROUND)
		if(LEAD_LESSON_LAST_ROUND)
			if(event == "last_round" && subject == target)
				say("Последний патрон ушёл. Пустой барабан за [HERETIC_LEAD_RELOAD_TIME / (1 SECONDS)] секунду дозаряжается из патронташа: туда ложится Свинец сверх полного барабана и по единице за выстрел в вашу сторону. Ещё Свинец дают попадания из Шестизарядника, удары клинком и рукоятью, гильзы и переплавка, а вне боя он сам копится до [HERETIC_LEAD_RESERVE_CAP]. Убитый Последним патроном человек сразу возвращает [HERETIC_LEAD_KILL_LEAD] Свинца.")
				set_stage(LEAD_LESSON_DONE)

/// Учебная пуля: урон у неё только в полёте, чтобы Ловля её брала, а непойманная лишь толкает.
/obj/item/projectile/bullet/heretic_lead_drill
	name = "training bullet"
	damage = LEAD_LESSON_DRILL_DAMAGE
	wound_bonus = CANT_WOUND
	shrapnel_type = null
	embedding = null

/obj/item/projectile/bullet/heretic_lead_drill/prehit_pierce(atom/target)
	. = ..()
	var/mob/living/victim = target
	if(!istype(victim) || !victim.has_status_effect(/datum/status_effect/heretic_lead_catch))
		damage = 0
		nodamage = TRUE

/obj/item/projectile/bullet/heretic_lead_drill/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	var/mob/living/victim = target
	if(nodamage && istype(victim))
		shake_camera(victim, 2, 1)
		to_chat(victim, span_warning("Учебная пуля щёлкает по вам без вреда. На станции это была бы рана: ловите пулю, пока видна красная линия."))

#undef LEAD_LESSON_CASINGS
#undef LEAD_LESSON_FINGER
#undef LEAD_LESSON_SMELT
#undef LEAD_LESSON_CURSE
#undef LEAD_LESSON_NAMED
#undef LEAD_LESSON_CATCH
#undef LEAD_LESSON_RICOCHET
#undef LEAD_LESSON_SCHOOL
#undef LEAD_LESSON_DRUM
#undef LEAD_LESSON_LAST_ROUND
#undef LEAD_LESSON_DONE
#undef LEAD_LESSON_DRILL_AIM
#undef LEAD_LESSON_DRILL_INTERVAL
#undef LEAD_LESSON_DRILL_DAMAGE
#undef LEAD_LESSON_DRILL_DISTANCE
#undef LEAD_LESSON_DISMISS
