#define ANTAG_TRAINING_PATIENT_BRUTE 110
#define ANTAG_TRAINING_PATIENT_BURN 20
#define ANTAG_TRAINING_RANGE_TARGETS 3
/// На сколько клеток ближняя и средняя мишени смещены от линии огня, чтобы не закрывать дальнюю.
#define ANTAG_TRAINING_RANGE_TARGET_SHIFT 3
/// Ушибы груди мёртвого пациента «Реанимации»: на пару стежков выше порога дефибриллятора.
#define ANTAG_TRAINING_REVIVE_BRUTE 190
#define ANTAG_TRAINING_REVIVE_OXY 40
/// Учебный срок «Реанимации»: в раунде мёртвого можно оживить намного дольше.
#define ANTAG_TRAINING_REVIVE_TIME_LIMIT (3 MINUTES)

/datum/antag_training_exercise/drill/cuffs
	id = "melee_cuffs"
	name = "Обезвредь и закуй"
	desc = "Учебная цель бегает челноком по площадке. Сбейте её с ног и наденьте наручники, не убивая."
	sector = "melee"
	par_time = 45 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/knockdown, /datum/antag_training_exercise_step/drill/cuff)

/datum/antag_training_exercise/drill/cuffs/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	var/mob/living/body = session.current_body
	if(!(locate(/obj/item/restraints/handcuffs) in body.GetAllContents()))
		session.exercise_run.add_prop(new /obj/item/restraints/handcuffs(get_turf(body)), FALSE)
	prepare_target(session, "runner", session.arena.zones[sector]["target"])
	return TRUE

/datum/antag_training_exercise_step/drill/knockdown
	name = "Сбейте цель с ног"
	hint = "Догоните цель. Электродубинка правой кнопкой мыши, выстрел дизейблера или бола валят её на пол: всё это выдаёт пульт на вкладке «Снаряжение»."
	target_death = "цель погибла, а её нужно было обезвредить"

/datum/antag_training_exercise_step/drill/knockdown/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(on_position))

/datum/antag_training_exercise_step/drill/knockdown/proc/on_position(mob/living/source)
	SIGNAL_HANDLER
	if(source.stat != DEAD && source.body_position == LYING_DOWN)
		complete()

/datum/antag_training_exercise_step/drill/cuff
	name = "Наденьте наручники"
	hint = "Пока цель лежит, нажмите на неё наручниками и не отходите, пока они не защёлкнутся. Наручники лежат в кармане учебной формы, а если своих нет, упражнение кладёт пару у ваших ног."
	target_death = "цель погибла, а её нужно было обезвредить"
	var/check_timer

/datum/antag_training_exercise_step/drill/cuff/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	queue_check()

/// Цель могли заковать ещё до этого шага: состояние проверяется и при подключении, со следующего тика.
/datum/antag_training_exercise_step/drill/cuff/proc/queue_check()
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(check_cuffs)), 0, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/drill/cuff/detach()
	deltimer(check_timer)
	check_timer = null
	return ..()

/// Наручники входят в цель раньше, чем она запоминает их как надетые: проверка - со следующего тика.
/datum/antag_training_exercise_step/drill/cuff/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(istype(arrived, /obj/item/restraints/handcuffs))
		queue_check()

/datum/antag_training_exercise_step/drill/cuff/proc/check_cuffs()
	check_timer = null
	var/mob/living/carbon/target = exercise_target()
	if(istype(target) && target.handcuffed && target.stat != DEAD)
		complete()

/obj/item/target/antag_training
	name = "training target"
	desc = "Мишень упражнения на стойке. Засчитывается попадание, когда целятся в саму мишень."
	density = TRUE
	anchored = TRUE

/obj/item/target/antag_training/bullet_act(obj/item/projectile/hitting_projectile, def_zone, piercing_hit = FALSE)
	. = ..()
	if(. == BULLET_ACT_HIT && !QDELETED(src))
		SEND_SIGNAL(src, COMSIG_ATOM_BULLET_ACT, hitting_projectile, def_zone)

/datum/antag_training_exercise/drill/targets
	id = "range_targets"
	name = "Три мишени"
	desc = "Мишени на ближней, средней и дальней дистанции. Поразите их по порядку, пока не вышло время. Без оружия в руках выдаётся учебный лазер."
	sector = "range"
	difficulty = 1
	par_time = 15 SECONDS
	time_limit = 45 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/target_hit, /datum/antag_training_exercise_step/drill/target_hit/middle, /datum/antag_training_exercise_step/drill/target_hit/far)

/datum/antag_training_exercise/drill/targets/setup(datum/antag_training_session/session)
	var/list/zone = session.arena.zones[sector]
	var/turf/firing_line = zone["spawn"]
	var/turf/far_end = zone["target"]
	var/datum/antag_training_exercise_run/run = session.exercise_run
	var/list/offsets = list(ANTAG_TRAINING_RANGE_TARGET_SHIFT, -ANTAG_TRAINING_RANGE_TARGET_SHIFT, 0)
	for(var/number in 1 to ANTAG_TRAINING_RANGE_TARGETS)
		var/turf/wanted = locate(firing_line.x + round((far_end.x - firing_line.x) * number / ANTAG_TRAINING_RANGE_TARGETS), far_end.y + offsets[number], far_end.z)
		var/turf/spot = session.arena.free_spot(wanted, zone["bounds"])
		if(!spot || !run.add_prop(new /obj/item/target/antag_training(spot)))
			return FALSE
	var/mob/living/body = session.current_body
	if(!(locate(/obj/item/gun) in body.held_items))
		var/obj/item/gun/energy/laser/practice/gun = new(get_turf(body))
		run.add_prop(gun, FALSE)
		INVOKE_ASYNC(body, TYPE_PROC_REF(/mob, put_in_hands), gun)
	return TRUE

/datum/antag_training_exercise_step/drill/target_hit
	name = "Поразите ближнюю мишень"
	hint = "Нажмите на саму мишень с оружием в руке: выстрел в пол рядом не засчитывается. Мишени поражаются по порядку, от ближней к дальней."
	var/target_number = 1

/datum/antag_training_exercise_step/drill/target_hit/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/obj/item/target/antag_training/target = owner.find_prop(/obj/item/target/antag_training, target_number)
	if(target)
		RegisterSignal(target, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_hit))

/datum/antag_training_exercise_step/drill/target_hit/proc/on_hit(datum/source, obj/item/projectile/hitting_projectile)
	SIGNAL_HANDLER
	if(hitting_projectile.firer == participant())
		complete()

/datum/antag_training_exercise_step/drill/target_hit/middle
	name = "Поразите среднюю мишень"
	hint = "Средняя мишень стоит дальше ближней, по другую сторону линии огня. Целитесь в саму мишень."
	target_number = 2

/datum/antag_training_exercise_step/drill/target_hit/far
	name = "Поразите дальнюю мишень"
	hint = "Дальняя мишень стоит у конца тира, напротив входа в зону. Целитесь в саму мишень, а не в пол рядом."
	target_number = 3

/datum/antag_training_exercise/drill/patient
	id = "lab_patient"
	name = "Стабилизируй пациента"
	desc = "Учебный пациент без сознания, его здоровье ниже нуля. Осмотрите его анализатором и выведите из крита, пока он не умер."
	sector = "laboratory"
	difficulty = 2
	par_time = 1 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/scan, /datum/antag_training_exercise_step/drill/stabilize)

/datum/antag_training_exercise/drill/patient/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	prepare_target(session, "human", session.arena.zones[sector]["target"])
	return TRUE

/datum/antag_training_exercise/drill/patient/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	target.apply_damage(ANTAG_TRAINING_PATIENT_BRUTE, BRUTE, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
	target.apply_damage(ANTAG_TRAINING_PATIENT_BURN, BURN, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)

/datum/antag_training_exercise_step/drill/scan
	name = "Осмотрите пациента анализатором"
	hint = "Нажмите медицинским анализатором на пациента: он покажет урон по типам. Анализатор и аптечка - в комплекте «Первая помощь» на вкладке «Начать»."
	target_death = "пациент умер"

/datum/antag_training_exercise_step/drill/scan/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))

/datum/antag_training_exercise_step/drill/scan/proc/on_attackby(datum/source, obj/item/tool, mob/user)
	SIGNAL_HANDLER
	if(istype(tool, /obj/item/healthanalyzer) && user == participant())
		complete()

/datum/antag_training_exercise_step/drill/stabilize
	name = "Выведите пациента из крита"
	hint = "Почти весь урон - ушибы: зашейте их швами из аптечки, ожоги снимает регенеративная сетка. Пока здоровье ниже нуля, пациент задыхается: медипен из аптечки выиграет время."
	target_death = "пациент умер"
	var/check_timer

/datum/antag_training_exercise_step/drill/stabilize/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_health))
	// Пациента могли вылечить до осмотра: после этого урон не меняется и сигнала здоровья не будет.
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(on_health), target), 0, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/drill/stabilize/detach()
	deltimer(check_timer)
	check_timer = null
	return ..()

/datum/antag_training_exercise_step/drill/stabilize/proc/on_health(mob/living/carbon/source)
	SIGNAL_HANDLER
	if(!QDELETED(source) && source.stat != DEAD && source.health > source.crit_threshold)
		complete()

/datum/antag_training_exercise/drill/revive
	id = "lab_revive"
	name = "Реанимация"
	sector = "laboratory"
	program = /datum/antag_training_program/free
	difficulty = 3
	par_time = 90 SECONDS
	time_limit = ANTAG_TRAINING_REVIVE_TIME_LIMIT
	steps = list(/datum/antag_training_exercise_step/drill/checked/revive/wounds, /datum/antag_training_exercise_step/drill/checked/revive/shock, /datum/antag_training_exercise_step/drill/checked/revive/stabilize)

/datum/antag_training_exercise/drill/revive/New()
	. = ..()
	var/obj/item/defibrillator/defib = /obj/item/defibrillator
	var/obj/item/organ/heart/heart = /obj/item/organ/heart
	var/obj/item/organ/brain/brain = /obj/item/organ/brain
	// Орган мёртвого теряет maxHealth * decay_factor / 2 в секунду.
	desc = "Учебный пациент мёртв: тяжёлые ушибы груди и удушье. Зашейте ушибы ниже порога дефибриллятора ([MAX_REVIVE_BRUTE_DAMAGE]), запустите сердце дефибриллятором и выведите пациента из крита. На всё упражнение [ANTAG_TRAINING_REVIVE_TIME_LIMIT / (1 MINUTES)] мин - это учебный срок. В раунде времени больше, но разряд позже [DEFIB_TIME_LOSS * initial(defib.timedeath) / (1 SECONDS)] с после смерти оставляет повреждение мозга почти до тяжёлого и риск травм мозга, сердце мёртвого отказывает примерно за [round(2 / initial(heart.decay_factor) / 60)] мин, а мозг сгнивает примерно за [round(2 / initial(brain.decay_factor) / 60)] мин - такого уже не оживить. Лечебные швы, медипен сальбутамола и анализатор здоровья кладутся у ваших ног, дефибриллятор - если своего нет."

/datum/antag_training_exercise/drill/revive/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	var/mob/living/body = session.current_body
	var/turf/spot = get_turf(body)
	var/datum/antag_training_exercise_run/run = session.exercise_run
	run.add_prop(new /obj/item/stack/medical/suture/medicated(spot), FALSE)
	run.add_prop(new /obj/item/reagent_containers/hypospray/medipen/salbutamol(spot), FALSE)
	run.add_prop(new /obj/item/healthanalyzer(spot), FALSE)
	if(!(locate(/obj/item/defibrillator) in body.GetAllContents()))
		run.add_prop(new /obj/item/defibrillator/loaded(spot), FALSE)
	prepare_target(session, "human", session.arena.zones[sector]["target"])
	return TRUE

/datum/antag_training_exercise/drill/revive/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	target.apply_damage(ANTAG_TRAINING_REVIVE_BRUTE, BRUTE, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
	target.adjustOxyLoss(ANTAG_TRAINING_REVIVE_OXY)
	if(target.stat != DEAD)
		target.death()

/// Мёртвое тело перестало поддаваться дефибриллятору: погиб мозг или отказало сердце.
/datum/antag_training_exercise_step/drill/checked/revive/check()
	var/mob/living/carbon/target = exercise_target()
	if(!istype(target))
		return FALSE
	if(target.stat == DEAD && !target.can_revive(ignore_timelimit = TRUE, maximum_brute_dam = INFINITY, maximum_fire_dam = INFINITY))
		var/obj/item/organ/brain/brain = target.getorgan(/obj/item/organ/brain)
		run.finish(FALSE, (!brain || brain.brain_death || (brain.organ_flags & ORGAN_FAILING)) ? "мозг погиб: такого пациента дефибриллятор не оживит" : "тело больше не поддаётся дефибриллятору")
		return FALSE
	return reached(target)

/datum/antag_training_exercise_step/drill/checked/revive/proc/reached(mob/living/carbon/target)
	return FALSE

/datum/antag_training_exercise_step/drill/checked/revive/wounds
	name = "Зашейте ушибы ниже порога дефибриллятора"
	target_death = null
	hint = "Тело с тяжёлыми ушибами дефибриллятор не оживит. Нажмите лечебными швами (medicated suture) на грудь пациента: обычные швы мёртвых не лечат."

/datum/antag_training_exercise_step/drill/checked/revive/wounds/New()
	. = ..()
	hint = "Тело с ушибами от [MAX_REVIVE_BRUTE_DAMAGE] и выше дефибриллятор не оживит. Возьмите лечебные швы (medicated suture) у ваших ног, выберите грудь и нажмите ими на пациента: на мёртвом они шьют слабее, обычные швы мёртвых не лечат вовсе. Анализатор покажет, сколько ушибов осталось."

/datum/antag_training_exercise_step/drill/checked/revive/wounds/reached(mob/living/carbon/target)
	return target.getBruteLoss() < MAX_REVIVE_BRUTE_DAMAGE && target.getFireLoss() < MAX_REVIVE_FIRE_DAMAGE

/datum/antag_training_exercise_step/drill/checked/revive/shock
	name = "Запустите сердце дефибриллятором"
	target_death = null
	hint = "Наденьте дефибриллятор на спину, кнопкой на панели действий достаньте лопасти и возьмите их в обе руки (Z). Выберите грудь и на намерении помощи (help) нажмите лопастями на пациента, стойте рядом пять секунд. Не ожил - прочитайте, что пищит дефибриллятор, и повторите после перезарядки."

/datum/antag_training_exercise_step/drill/checked/revive/shock/reached(mob/living/carbon/target)
	return target.stat != DEAD

/datum/antag_training_exercise_step/drill/checked/revive/stabilize
	name = "Выведите пациента из крита"
	hint = "Дефибриллятор оставляет пациента в крите, и он снова задыхается. Уколите его медипеном сальбутамола (снимает удушье) и дошейте ушибы швами: здоровье должно подняться выше нуля."
	target_death = "пациент снова умер"

/datum/antag_training_exercise_step/drill/checked/revive/stabilize/reached(mob/living/carbon/target)
	return target.stat != DEAD && target.health > target.crit_threshold

#undef ANTAG_TRAINING_PATIENT_BRUTE
#undef ANTAG_TRAINING_PATIENT_BURN
#undef ANTAG_TRAINING_RANGE_TARGETS
#undef ANTAG_TRAINING_RANGE_TARGET_SHIFT
#undef ANTAG_TRAINING_REVIVE_BRUTE
#undef ANTAG_TRAINING_REVIVE_OXY
#undef ANTAG_TRAINING_REVIVE_TIME_LIMIT
