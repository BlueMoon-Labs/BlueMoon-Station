#define HAMMER_LESSON_WIELD 1
#define HAMMER_LESSON_HIT 2
#define HAMMER_LESSON_CRUSH 3
#define HAMMER_LESSON_NAIL 4
#define HAMMER_LESSON_PRY 5
#define HAMMER_LESSON_RAM 6
#define HAMMER_LESSON_QUENCH 7
#define HAMMER_LESSON_BRAND 8
#define HAMMER_LESSON_HELPER_DELAY (2 SECONDS)
#define HAMMER_LESSON_KEEP_DOWN (2 SECONDS)

/// Урок Молота: две руки, Накал, Замах и Сокрушающий удар, Вбить в пол и лом напарника, Таран, вода и Клеймо кузни.
/datum/heretic_path_lesson/hammer
	path_id = PATH_HAMMER
	base_type = /datum/eldritch_knowledge/base_hammer
	title = "Урок Молота"
	icon = "hammer"
	knowledge_types = list(/datum/eldritch_knowledge/spell/hammer_ram, /datum/eldritch_knowledge/hammer_nail)
	step_names = list("Две руки", "Накал", "Сокрушающий удар", "Вбить в пол", "Лом напарника", "Таран", "Вода", "Клеймо кузни")
	var/datum/weakref/helper_ref

/datum/heretic_path_lesson/hammer/setup(datum/antagonist/heretic/heretic, datum/eldritch_knowledge/base_hammer/hammer, mob/living/student, mob/living/target)
	if(!heretic_hammer_held(student))
		var/obj/item/melee/sickly_blade/hammer/weapon = add_prop(new /obj/item/melee/sickly_blade/hammer(get_turf(student)))
		student.put_in_hands(weapon)
	refill(hammer)

/datum/heretic_path_lesson/hammer/proc/refill(datum/eldritch_knowledge/base_hammer/hammer)
	hammer.quenched_until = 0
	hammer.combat_resource = hammer.combat_resource_max
	COOLDOWN_RESET(hammer, free_ram)
	hammer.notify_resource_changed()

/datum/heretic_path_lesson/hammer/stage_text(for_stage)
	switch(for_stage)
		if(HAMMER_LESSON_WIELD)
			return "Возьмите Молот изнанки в руку и активируйте его, чтобы взять в две руки. Одной рукой он бьёт на [HERETIC_HAMMER_FORCE] без силы пути, в двух - на [HERETIC_HAMMER_WIELDED_FORCE], с пробоем брони и отбросом. Побег теперь на кнопке «Расколоть молот»."
		if(HAMMER_LESSON_HIT)
			return "Ударьте мишень Молотом в двух руках. Каждый удар по живому даёт единицу Накала, не чаще раза в секунду, и отбрасывает цель на клетку, а на станции удар по врагу ещё и лечит вас на [HERETIC_HAMMER_FORGE_HEAL]. Одной рукой Молот бьёт слабее, без отброса и копит Накал вдвое реже. Без ударов Накал стынет: единица за [HERETIC_HAMMER_COOL_TIME / (1 SECONDS)] секунд."
		if(HAMMER_LESSON_CRUSH)
			return "Нажмите «Замах»: секунду Молот над головой, и следующий удар за [HERETIC_HAMMER_SWING_WINDOW / (1 SECONDS)] секунды будет Сокрушающим - +[HERETIC_HAMMER_CRUSH_DAMAGE] урона и полёт на [HERETIC_HAMMER_CRUSH_THROW] клетки. Отбейте мишень в стену: удар о стену валит её с ног."
		if(HAMMER_LESSON_NAIL)
			return "Мишень лежит. Переключитесь в намерение «Схватить» и ударьте её Молотом в двух руках: за [HERETIC_HAMMER_NAIL_COST] Накала она вбита в пол на [HERETIC_HAMMER_NAIL_TIME / (1 SECONDS)] секунд. На станции вбитую цель охоты сердце уводит в изнанку."
		if(HAMMER_LESSON_PRY)
			return "Рядом встал учебный техник с ломом. Посмотрите, как экипаж выдёргивает вбитого: [HERETIC_HAMMER_NAIL_PRY_TIME / (1 SECONDS)] секунды работы ломом, растолкать можно и за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)]."
		if(HAMMER_LESSON_RAM)
			return "Нажмите «Таран» и укажите в сторону мишени или окна: рывок до [HERETIC_HAMMER_RAM_RANGE] клеток сносит окно или стол, рушит стену до балки, валит первого врага. Раз в [HERETIC_HAMMER_RAM_FREE_COOLDOWN / (1 SECONDS)] секунд Таран даром, иначе [HERETIC_HAMMER_RAM_COST] Накала. Он рвёт даже крепкую хватку."
		if(HAMMER_LESSON_QUENCH)
			return "Учебный техник окатит вас водой из огнетушителя. Посмотрите, что вода делает с Накалом."
		if(HAMMER_LESSON_BRAND)
			return "Переключитесь в намерение «Помощь» и ударьте Молотом по обычной стене: выбьется Клеймо кузни. Мимо пройдёт член экипажа - клеймо загудит, и на станции его отдел пойдёт в дело."
	return "Урок пройден. Против Молота: вода и пена - огнетушитель, ведро, шланг, душ - гасят Накал в ноль и [HERETIC_HAMMER_QUENCH_TIME / (1 SECONDS)] секунды не дают копить; Замах и Сотрясение видны заранее - отходите, когда Молот поднят над головой; вбитого выдёргивают ломом за [HERETIC_HAMMER_NAIL_PRY_TIME / (1 SECONDS)] секунды или расталкивают; клейма стирают сварка и нулевой жезл; для Хватки ему надо отпустить Молот, а одной рукой он бьёт слабее и не отбрасывает."

/datum/heretic_path_lesson/hammer/prepare_stage(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_hammer/hammer = base_ref?.resolve()
	var/mob/living/target = target_ref?.resolve()
	if(!student || !hammer || stage != for_stage)
		return
	refill(hammer)
	switch(for_stage)
		if(HAMMER_LESSON_NAIL)
			if(target)
				keep_down(for_stage)
		if(HAMMER_LESSON_PRY)
			var/mob/living/carbon/human/helper = ready_helper(student)
			if(helper)
				addtimer(CALLBACK(src, PROC_REF(pry), for_stage), HAMMER_LESSON_HELPER_DELAY)
		if(HAMMER_LESSON_QUENCH)
			if(ready_helper(student))
				addtimer(CALLBACK(src, PROC_REF(douse), for_stage), HAMMER_LESSON_HELPER_DELAY)

/// Мишень шага «Вбить в пол» не встаёт, пока шаг не засчитан.
/datum/heretic_path_lesson/hammer/proc/keep_down(for_stage)
	var/mob/living/target = target_ref?.resolve()
	if(stage != for_stage || !target || target.stat == DEAD)
		return
	target.Knockdown(HAMMER_LESSON_KEEP_DOWN * 2)
	addtimer(CALLBACK(src, PROC_REF(keep_down), for_stage), HAMMER_LESSON_KEEP_DOWN)

/datum/heretic_path_lesson/hammer/proc/ready_helper(mob/living/student)
	var/mob/living/carbon/human/helper = helper_ref?.resolve()
	if(helper)
		return helper
	var/mob/living/target = target_ref?.resolve()
	var/turf/spot = free_spot_near(target || student) || free_spot_near(student)
	if(!spot)
		say("учебному технику негде встать: освободите клетку рядом с мишенью или с собой, и шаг продолжится.")
		addtimer(CALLBACK(src, PROC_REF(prepare_stage), stage), HAMMER_LESSON_HELPER_DELAY * 2)
		return null
	helper = call_extra(student, spot, "Учебный техник")
	if(helper)
		helper_ref = WEAKREF(helper)
	return helper

/datum/heretic_path_lesson/hammer/proc/pry(for_stage)
	var/mob/living/carbon/human/helper = helper_ref?.resolve()
	var/mob/living/target = target_ref?.resolve()
	if(stage != for_stage || !helper || !target)
		return
	var/datum/status_effect/heretic_hammer_nailed/nail = target.has_status_effect(/datum/status_effect/heretic_hammer_nailed)
	if(!nail)
		advance("мишень уже не вбита. Экипаж выдёргивает вбитого ломом за [HERETIC_HAMMER_NAIL_PRY_TIME / (1 SECONDS)] секунды.")
		return
	var/obj/item/crowbar/tool = locate(/obj/item/crowbar) in helper.held_items
	if(!tool)
		tool = add_prop(new /obj/item/crowbar(get_turf(helper)))
		helper.put_in_hands(tool)
	if(!nail.pry(helper, tool) && stage == for_stage && !QDELETED(nail))
		say("технику помешали выдернуть мишень, он попробует снова.")
		addtimer(CALLBACK(src, PROC_REF(pry), for_stage), HAMMER_LESSON_HELPER_DELAY)

/datum/heretic_path_lesson/hammer/proc/douse(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/mob/living/helper = helper_ref?.resolve()
	if(stage != for_stage || !student || !helper)
		return
	helper.visible_message(span_warning("[helper] окатывает [student] водой из огнетушителя!"))
	var/datum/reagents/water = new(10)
	water.add_reagent(/datum/reagent/water, 10)
	water.reaction(student, TOUCH)
	qdel(water)

/datum/heretic_path_lesson/hammer/handle_event(event, atom/subject, value)
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(HAMMER_LESSON_WIELD)
			if(event == "wield")
				advance("Молот в двух руках. Для Хватки Мансуса его придётся отпустить: свободная рука нужна ей.")
		if(HAMMER_LESSON_HIT)
			if(event == "hit" && subject == target)
				advance("Накал растёт. Он копится только от ударов в двух руках и от Хватки - по [HERETIC_HAMMER_GRASP_HEAT] за каждую.")
		if(HAMMER_LESSON_CRUSH)
			if(event == "crush" && subject == target)
				advance("Сокрушающий удар! Врезавшись в стену, преграду или другого, цель падает на [HERETIC_HAMMER_SLAM_KNOCKDOWN / (1 SECONDS)] секунды.")
		if(HAMMER_LESSON_NAIL)
			if(event == "nail" && subject == target)
				advance("мишень вбита в пол: она не встанет и не уйдёт, а тащить её можете только вы.")
		if(HAMMER_LESSON_PRY)
			if(event == "nail_free" && subject == target)
				advance("мишень свободна: [value]. Держите экипаж с ломами подальше от вбитого.")
			else if(event == "nail_end" && subject == target)
				advance("срок вбивки вышел, и мишень освободилась сама. Экипаж выдёргивает вбитого ломом за [HERETIC_HAMMER_NAIL_PRY_TIME / (1 SECONDS)] секунды.")
		if(HAMMER_LESSON_RAM)
			if(event == "ram")
				advance("Таран прошёл. Это ваш уход: он рвёт хватку и проламывает путь, а до вознесения его не пускают наручники и оглушение.")
		if(HAMMER_LESSON_QUENCH)
			if(event == "quench")
				advance("Накал погас: было [value], стало 0, и [HERETIC_HAMMER_QUENCH_TIME / (1 SECONDS)] секунды он не копится. Огнетушитель - главный ответ экипажа на Молот.")
		if(HAMMER_LESSON_BRAND)
			if(event == "brand")
				advance("клеймо выбито. Держится до [HERETIC_HAMMER_BRAND_LIMIT] клейм, новое вытесняет старейшее; сварка или нулевой жезл стирают их.")

#undef HAMMER_LESSON_WIELD
#undef HAMMER_LESSON_HIT
#undef HAMMER_LESSON_CRUSH
#undef HAMMER_LESSON_NAIL
#undef HAMMER_LESSON_PRY
#undef HAMMER_LESSON_RAM
#undef HAMMER_LESSON_QUENCH
#undef HAMMER_LESSON_BRAND
#undef HAMMER_LESSON_HELPER_DELAY
#undef HAMMER_LESSON_KEEP_DOWN
