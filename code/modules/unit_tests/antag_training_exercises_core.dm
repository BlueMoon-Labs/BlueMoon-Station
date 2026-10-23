/datum/unit_test/proc/start_training_drill(datum/antag_training_session/session, datum/tgui/ui, exercise_id)
	antag_training_console_act(session, ui, "exercise_start", list("id" = exercise_id))
	var/list/budget = new_wait_budget(10 SECONDS, "подготовка упражнения [exercise_id]")
	while(session.preparing && wait_budget_tick(budget))
		continue
	return session.exercise_run

/datum/unit_test/proc/enter_training_sector(datum/antag_training_session/session, datum/tgui/ui, sector_id)
	var/datum/antag_training_sector/sector = session.arena.sectors[sector_id]
	antag_training_console_act(session, ui, "sector_enter", list("id" = sector_id))
	var/list/budget = new_wait_budget(30 SECONDS, "участник в секторе [sector_id]")
	while(!(sector.state == ANTAG_TRAINING_SECTOR_READY && session.arena.inside_bounds(get_turf(session.current_body), sector.bounds)) && wait_budget_tick(budget))
		continue
	return sector

/datum/unit_test/proc/wait_for_drill_step(datum/antag_training_exercise_run/run, step_index, max_wait = 5 SECONDS)
	var/list/budget = new_wait_budget(max_wait, "шаг [step_index] упражнения [run.exercise.id]")
	while(!run.ended && run.step_index < step_index && wait_budget_tick(budget))
		continue
	return run.step_index >= step_index

/datum/unit_test/proc/drill_hold(mob/living/carbon/human/user, obj/item/thing)
	user.drop_all_held_items()
	user.put_in_active_hand(thing)
	return user.is_holding(thing)

/datum/antag_training_exercise/unit_test_lost_in_setup
	id = "unit_test_lost_in_setup"
	name = "Учебный пропавший реквизит"
	desc = "Реквизит пропадает ещё при подготовке."
	sector = "melee"
	time_limit = 1 MINUTES
	steps = list(/datum/antag_training_exercise_step/unit_test_walk)

/datum/antag_training_exercise/unit_test_lost_in_setup/setup(datum/antag_training_session/session)
	var/obj/item/pen/pen = new(get_turf(session.current_body))
	session.exercise_run.add_prop(pen)
	qdel(pen)
	return TRUE

/// Прогон, проваленный ещё при подготовке, не начинается: шаг не подписан, таймер ограничения не заведён.
/datum/unit_test/antag_training_exercise_ended_in_setup/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "unit_test_lost_in_setup")
	TEST_ASSERT_NOTNULL(run, "Прогон остаётся в пульте с итогом.")
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "реквизит"), "Пропавший реквизит проваливает прогон.")
	TEST_ASSERT_EQUAL(run.step_index, 0, "Шаги проваленного прогона не начинаются.")
	TEST_ASSERT_NULL(run.limit_timer, "Таймер ограничения не заводится.")
	TEST_ASSERT_EQUAL(run.elapsed(), 0, "Время проваленного при подготовке прогона - ноль.")

/datum/antag_training_exercise/drill/unit_test_target_guard
	id = "unit_test_target_guard"
	name = "Учебная охрана цели"
	desc = "Цель стоит рядом, шаг ничего не просит."
	sector = "melee"
	steps = list(/datum/antag_training_exercise_step/drill/unit_test_wait)

/datum/antag_training_exercise/drill/unit_test_target_guard/setup(datum/antag_training_session/session)
	prepare_target(session, "human", get_turf(session.current_body))
	return TRUE

/datum/antag_training_exercise/drill/unit_test_target_guard/may_die
	id = "unit_test_target_may_die"
	steps = list(/datum/antag_training_exercise_step/drill/unit_test_wait/may_die)

/datum/antag_training_exercise_step/drill/unit_test_wait
	name = "Ждите"
	hint = "Шаг ничего не просит."

/datum/antag_training_exercise_step/drill/unit_test_wait/may_die
	target_death = null

/// Гибель цели проваливает любой шаг упражнения с целью, даже без своей причины, а шаг, разрешающий её смерть, продолжается.
/datum/unit_test/antag_training_exercise_target_death_rule/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "unit_test_target_guard")
	var/mob/living/carbon/human/target = run?.find_prop(/mob/living/carbon/human)
	TEST_ASSERT(target && run.step_index == 1, "Упражнение ставит цель и ждёт на первом шаге.")
	target.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "учебная цель погибла"), "Гибель цели проваливает шаг без своей причины: [run.result_text]")

	run = start_training_drill(session, ui, "unit_test_target_may_die")
	target = run?.find_prop(/mob/living/carbon/human)
	TEST_ASSERT(target && run.step_index == 1, "Второе упражнение ставит цель.")
	target.death()
	TEST_ASSERT(!run.ended, "Шаг, разрешающий смерть цели, продолжается: [run.result_text]")

/// «Обезвредь и закуй»: бегущая цель в зоне ближнего боя, пульт её не сбивает и не сковывает, толчок дубинкой и наручники в любом порядке засчитываются; гибель цели проваливает повтор.
/datum/unit_test/antag_training_exercise_melee_cuffs/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "melee_cuffs")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в зоне ближнего боя.")
	var/mob/living/carbon/human/target = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(target, "Упражнение создаёт бегущую цель.")
	TEST_ASSERT(target in session.arena.targets, "Цель учтена в лимите целей полигона.")
	TEST_ASSERT(session.arena.inside_bounds(get_turf(target), session.arena.zones["melee"]["bounds"]), "Цель бегает в зоне ближнего боя.")
	TEST_ASSERT_NULL(run.find_prop(/obj/item/restraints/handcuffs), "Свои наручники в кармане есть: упражнение их не выдаёт.")

	antag_training_console_act(session, ui, "target_condition", list("id" = REF(target), "condition" = "knockdown"))
	antag_training_console_act(session, ui, "target_condition", list("id" = REF(target), "condition" = "cuffs"))
	TEST_ASSERT(target.body_position != LYING_DOWN && !target.handcuffed && run.step_index == 1, "Пульт не сбивает и не сковывает цель упражнения.")
	TEST_ASSERT(findtext(session.last_feedback, "цель упражнения"), "Пульт объясняет отказ: [session.last_feedback]")

	var/obj/item/melee/baton/loaded/baton = allocate(/obj/item/melee/baton/loaded, get_turf(user))
	TEST_ASSERT(drill_hold(user, baton), "Участник держит дубинку.")
	baton.attack_self(user)
	TEST_ASSERT(baton.turned_on, "Дубинка включена.")
	user.forceMove(get_step(target, EAST))
	baton.alt_pre_attack(target, user)
	TEST_ASSERT_EQUAL(target.body_position, LYING_DOWN, "Толчок дубинкой валит цель.")
	TEST_ASSERT_EQUAL(run.step_index, 2, "Падение цели засчитано.")

	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, get_turf(user))
	TEST_ASSERT(drill_hold(user, cuffs), "Участник держит наручники.")
	cuffs.attack(target, user)
	TEST_ASSERT_EQUAL(target.handcuffed, cuffs, "Наручники надеты.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE), "Наручники завершают упражнение.")
	TEST_ASSERT(run.success, "Упражнение выполнено: [run.result_text]")

	run = start_training_drill(session, ui, "melee_cuffs")
	target = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(target, "Повтор создаёт новую цель.")
	var/obj/item/restraints/handcuffs/early = allocate(/obj/item/restraints/handcuffs, get_turf(user))
	TEST_ASSERT(drill_hold(user, early), "Участник держит наручники.")
	early.apply_cuffs(target, user)
	TEST_ASSERT_EQUAL(target.handcuffed, early, "Цель закована до падения.")
	TEST_ASSERT_EQUAL(run.step_index, 1, "Наручники до падения не засчитывают первый шаг.")
	var/obj/item/melee/baton/loaded/second_baton = allocate(/obj/item/melee/baton/loaded, get_turf(user))
	TEST_ASSERT(drill_hold(user, second_baton), "Участник держит вторую дубинку.")
	second_baton.attack_self(user)
	user.forceMove(get_step(target, EAST))
	second_baton.alt_pre_attack(target, user)
	TEST_ASSERT_EQUAL(target.body_position, LYING_DOWN, "Толчок валит закованную цель.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE) && run.success, "Закованная заранее цель засчитывается сразу после падения: [run.result_text]")

	for(var/obj/item/restraints/handcuffs/own in user.GetAllContents())
		qdel(own)
	run = start_training_drill(session, ui, "melee_cuffs")
	target = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(target, "Повтор создаёт новую цель.")
	var/obj/item/restraints/handcuffs/spare = run.find_prop(/obj/item/restraints/handcuffs)
	TEST_ASSERT(spare && get_turf(spare) == get_turf(user), "Без своих наручников упражнение кладёт пару у ног.")
	target.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "цель погибла"), "Гибель цели проваливает упражнение.")

/// «Три мишени»: три мишени в тире и учебный лазер в руках; попадание засчитывается только по порядку, третье завершает упражнение.
/datum/unit_test/antag_training_exercise_range_targets/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "range"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "range_targets")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в тире.")
	var/list/targets = list()
	for(var/number in 1 to 3)
		var/obj/item/target/antag_training/target = run.find_prop(/obj/item/target/antag_training, number)
		TEST_ASSERT_NOTNULL(target, "Мишень [number] стоит в тире.")
		TEST_ASSERT(session.arena.inside_bounds(get_turf(target), session.arena.zones["range"]["bounds"]), "Мишень [number] в зоне тира.")
		targets += target
	TEST_ASSERT(get_dist(user, targets[1]) < get_dist(user, targets[2]) && get_dist(user, targets[2]) < get_dist(user, targets[3]), "Мишени стоят от ближней к дальней.")
	var/obj/item/gun/energy/laser/practice/gun = locate() in user.held_items
	TEST_ASSERT_NOTNULL(gun, "Без оружия в руках выдаётся учебный лазер.")

	var/obj/item/target/antag_training/far = targets[3]
	drill_shoot(gun, far, user)
	TEST_ASSERT(length(far.overlays), "Выстрел попадает в дальнюю мишень.")
	TEST_ASSERT_EQUAL(run.step_index, 1, "Дальняя мишень раньше ближней не засчитывается.")
	for(var/number in 1 to 3)
		drill_shoot(gun, targets[number], user)
		TEST_ASSERT(wait_for_drill_step(run, number + 1), "Попадание в мишень [number] засчитано.")
	TEST_ASSERT(run.ended && run.success, "Три попадания завершают упражнение: [run.result_text]")

/datum/unit_test/proc/drill_shoot(obj/item/gun/gun, atom/target, mob/living/user)
	var/list/budget = new_wait_budget(5 SECONDS, "перезарядка [gun.type]")
	while(gun.on_cooldown() && wait_budget_tick(budget))
		continue
	var/hits = length(target.overlays)
	gun.process_fire(target, user)
	budget = new_wait_budget(5 SECONDS, "попадание в [target]")
	while(length(target.overlays) == hits && wait_budget_tick(budget))
		continue

/// «Стабилизируй пациента»: пациент в крите, пульт его не лечит, осмотр и швы в любом порядке выводят его из крита; смерть пациента проваливает повтор.
/datum/unit_test/antag_training_exercise_lab_patient/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	user.a_intent = INTENT_HELP
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "laboratory"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "lab_patient")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в лаборатории.")
	var/mob/living/carbon/human/patient = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(patient, "Упражнение создаёт пациента.")
	TEST_ASSERT(patient.stat != DEAD && patient.health <= patient.crit_threshold, "Пациент жив и в крите: здоровье [patient.health].")
	user.forceMove(get_step(patient, EAST))
	antag_training_console_act(session, ui, "target_heal", list("id" = REF(patient)))
	TEST_ASSERT(patient.health <= patient.crit_threshold, "Пульт не лечит пациента упражнения.")
	TEST_ASSERT(findtext(session.last_feedback, "цель упражнения"), "Пульт объясняет отказ: [session.last_feedback]")

	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer, get_turf(user))
	TEST_ASSERT(drill_hold(user, analyzer), "Участник держит анализатор.")
	analyzer.melee_attack_chain(user, patient)
	TEST_ASSERT_EQUAL(run.step_index, 2, "Осмотр анализатором засчитан.")

	var/obj/item/stack/medical/suture/suture = allocate(/obj/item/stack/medical/suture, get_turf(user))
	TEST_ASSERT(drill_hold(user, suture), "Участник держит швы.")
	user.zone_selected = BODY_ZONE_CHEST
	suture.melee_attack_chain(user, patient)
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 10 SECONDS), "Лечение завершает упражнение.")
	TEST_ASSERT(run.success && patient.health > patient.crit_threshold, "Пациент выведен из крита: [run.result_text]")

	run = start_training_drill(session, ui, "lab_patient")
	patient = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(patient, "Повтор создаёт нового пациента.")
	user.forceMove(get_step(patient, EAST))
	TEST_ASSERT(drill_hold(user, suture), "Участник держит швы до осмотра.")
	suture.melee_attack_chain(user, patient)
	var/list/budget = new_wait_budget(10 SECONDS, "лечение до осмотра")
	while(patient.health <= patient.crit_threshold && wait_budget_tick(budget))
		continue
	TEST_ASSERT(patient.health > patient.crit_threshold && run.step_index == 1, "Пациент вылечен до осмотра.")
	TEST_ASSERT(drill_hold(user, analyzer), "Участник держит анализатор.")
	analyzer.melee_attack_chain(user, patient)
	TEST_ASSERT(wait_for_var(run, "ended", TRUE) && run.success, "Вылеченный до осмотра пациент засчитывается сразу после осмотра: [run.result_text]")

	run = start_training_drill(session, ui, "lab_patient")
	patient = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(patient, "Повтор создаёт нового пациента.")
	patient.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "пациент умер"), "Смерть пациента проваливает упражнение.")

/// «Реанимация»: мёртвый пациент с ушибами выше порога, учебный срок идёт таймером прогона, анализатор в реквизите; пульт его не лечит, лечебный шов опускает ушибы ниже порога, разряд дефибриллятора оживляет, швы выводят из крита; погибший мозг проваливает повтор.
/datum/unit_test/antag_training_exercise_lab_revive/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	user.a_intent = INTENT_HELP
	user.zone_selected = BODY_ZONE_CHEST
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "laboratory"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "lab_revive")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в лаборатории.")
	var/mob/living/carbon/human/patient = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(patient, "Упражнение создаёт пациента.")
	TEST_ASSERT(patient.stat == DEAD && patient.getBruteLoss() >= MAX_REVIVE_BRUTE_DAMAGE && patient.getOxyLoss() > 0, "Пациент мёртв, ушибы выше порога дефибриллятора, есть удушье.")
	var/obj/item/defibrillator/defib = run.find_prop(/obj/item/defibrillator)
	TEST_ASSERT(defib && run.find_prop(/obj/item/stack/medical/suture/medicated) && run.find_prop(/obj/item/reagent_containers/hypospray/medipen/salbutamol), "У ног лежат дефибриллятор, лечебные швы и сальбутамол.")
	var/obj/item/healthanalyzer/analyzer = run.find_prop(/obj/item/healthanalyzer)
	TEST_ASSERT(analyzer && get_turf(analyzer) == get_turf(user), "Анализатор, который обещает подсказка, лежит у ног.")
	TEST_ASSERT(run.limit_timer && findtext(run.exercise.score_rule(), "На всё упражнение"), "Учебный срок «Реанимации» - срок прогона, а не гибель мозга.")
	TEST_ASSERT(findtext(run.exercise.desc, "учебный срок") && findtext(run.exercise.desc, "В раунде"), "Описание отличает учебный срок от раунда: [run.exercise.desc]")
	antag_training_console_act(session, ui, "target_heal", list("id" = REF(patient)))
	TEST_ASSERT_EQUAL(patient.stat, DEAD, "Пульт не оживляет пациента упражнения.")

	user.forceMove(get_step(patient, EAST))
	var/obj/item/stack/medical/suture/medicated/one/stitch = allocate(/obj/item/stack/medical/suture/medicated/one, get_turf(user))
	TEST_ASSERT(drill_hold(user, stitch), "Участник держит лечебный шов.")
	stitch.melee_attack_chain(user, patient)
	TEST_ASSERT(wait_for_drill_step(run, 2, 10 SECONDS), "Ушибы ниже порога дефибриллятора: [patient.getBruteLoss()].")
	TEST_ASSERT_EQUAL(patient.stat, DEAD, "Швы не оживляют.")

	user.drop_all_held_items()
	if(user.back)
		user.dropItemToGround(user.back)
	TEST_ASSERT(user.equip_to_slot_if_possible(defib, ITEM_SLOT_BACK), "Дефибриллятор на спине.")
	usr = user
	defib.attack_hand(user)
	usr = null
	var/obj/item/shockpaddles/paddles = defib.paddles
	TEST_ASSERT(paddles in user.held_items, "Лопасти в руках.")
	paddles.attack_self(user)
	TEST_ASSERT(paddles.wielded, "Лопасти в обеих руках.")
	paddles.melee_attack_chain(user, patient)
	TEST_ASSERT(wait_for_drill_step(run, 3, 15 SECONDS), "Разряд засчитан: [run.result_text || "шаг [run.step_index]"].")
	TEST_ASSERT(patient.stat != DEAD && patient.health <= patient.crit_threshold, "Ожил, но в крите: здоровье [patient.health].")

	paddles.attack_self(user)
	var/obj/item/stack/medical/suture/sutures = allocate(/obj/item/stack/medical/suture, get_turf(user))
	TEST_ASSERT(drill_hold(user, sutures), "Участник держит швы.")
	sutures.melee_attack_chain(user, patient)
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 30 SECONDS), "Лечение завершает упражнение.")
	TEST_ASSERT(run.success && patient.health > patient.crit_threshold, "Пациент выведен из крита: [run.result_text]")

	run = start_training_drill(session, ui, "lab_revive")
	patient = run?.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(patient, "Повтор создаёт нового пациента.")
	patient.adjustOrganLoss(ORGAN_SLOT_BRAIN, BRAIN_DAMAGE_DEATH)
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 5 SECONDS), "Погибший мозг заканчивает упражнение.")
	TEST_ASSERT(!run.success && findtext(run.result_text, "мозг погиб"), "Провал называет причину: [run.result_text]")
