/// Дальше этого задержанный не замечает погоню и стоит на месте.
#define ANTAG_TRAINING_FLEE_RANGE 5
/// Ближе этого к участнику убегающая цель не встаёт.
#define ANTAG_TRAINING_FLEE_START_GAP 3

/// Должность службы безопасности из раздевалки хаба: у неё ID с доступом в пост охраны макета.
/proc/antag_training_security_role(datum/antag_training_session/session)
	var/datum/antag_training_role/crew/crew_role = session.role
	if(!istype(crew_role))
		return FALSE
	var/datum/job/job = SSjob.GetJob(crew_role.job_title)
	return !!(job?.departments & DEPARTMENT_BITFLAG_SECURITY)

/// Упражнения поста охраны станционного макета для должностей СБ.
/datum/antag_training_exercise/drill/security
	sector = "station"
	program = /datum/antag_training_program/free

/datum/antag_training_exercise/drill/security/available(datum/antag_training_session/session)
	return ..() && antag_training_security_role(session)

/datum/antag_training_exercise/drill/security/unavailable_reason(datum/antag_training_session/session)
	var/datum/antag_training_program/needed = program
	return "нужны программа «[initial(needed.name)]» и должность службы безопасности"

/datum/antag_training_exercise/drill/security/proc/post_turfs(datum/antag_training_session/session)
	var/datum/antag_training_sector/station = session.arena.sectors[sector]
	var/turf/mark = station?.landmark_turf("brig")
	return mark ? antag_training_room_turfs(mark, station) : null

/// Бегущая мишень, которая уходит от участника в пределах своей комнаты.
/datum/antag_training_runner/fleeing
	var/datum/weakref/chaser_ref
	var/list/room

/datum/antag_training_runner/fleeing/New(mob/living/carbon/human/target, datum/antag_training_arena/training, list/zone_bounds, mob/living/chaser, list/turf/allowed)
	chaser_ref = WEAKREF(chaser)
	room = list()
	for(var/turf/tile as anything in allowed)
		room[tile] = TRUE
	return ..(target, training, zone_bounds)

/datum/antag_training_runner/fleeing/process()
	if(world.time < next_step_at || !can_run())
		return
	var/mob/living/chaser = chaser_ref?.resolve()
	if(!chaser || chaser.z != runner.z || get_dist(chaser, runner) > ANTAG_TRAINING_FLEE_RANGE)
		return
	next_step_at = world.time + ANTAG_TRAINING_RUNNER_STEP
	var/turf/best
	var/best_distance = get_dist(chaser, runner)
	for(var/direction in GLOB.alldirs)
		var/turf/next = get_step(runner, direction)
		if(!room[next] || next.is_blocked_turf(exclude_mobs = FALSE))
			continue
		var/distance = get_dist(chaser, next)
		if(distance > best_distance)
			best = next
			best_distance = distance
	if(best)
		runner.set_glide_size(DELAY_TO_GLIDE_SIZE(ANTAG_TRAINING_RUNNER_STEP))
		runner.Move(best, get_dir(runner, best))

/datum/antag_training_runner/fleeing/Destroy()
	room = null
	return ..()

/datum/antag_training_exercise/drill/security/detain
	id = "security_detain"
	name = "Задержание"
	desc = "В зале прибытия станционного макета нарушитель: он убегает, когда вы рядом. Сбейте его с ног, наденьте наручники и доведите до поста охраны с маяком. Нарушитель нужен живым."
	difficulty = 2
	par_time = 75 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/knockdown/detain, /datum/antag_training_exercise_step/drill/cuff/detain, /datum/antag_training_exercise_step/drill/to_post)

/datum/antag_training_exercise/drill/security/detain/setup(datum/antag_training_session/session)
	var/datum/antag_training_sector/station = session.arena.sectors[sector]
	var/turf/mark = station?.landmark_turf("brig")
	var/list/hall = station && antag_training_room_turfs(station.spawn_turf(), station)
	if(!mark || !length(post_turfs(session)) || !length(hall))
		return "в макете нет зала прибытия или поста охраны, сбросьте сектор"
	if(!target_slot_free(session))
		return FALSE
	var/datum/antag_training_exercise_run/run = session.exercise_run
	var/mob/living/body = session.current_body
	if(!(locate(/obj/item/restraints/handcuffs) in body.GetAllContents()))
		run.add_prop(new /obj/item/restraints/handcuffs(get_turf(body)), FALSE)
	// Пояс офицера пуст: без своей дубинки упражнение кладёт её рядом, как запасные наручники.
	if(!(locate(/obj/item/melee/baton) in body.GetAllContents()))
		run.add_prop(new /obj/item/melee/baton/loaded(get_turf(body)), FALSE)
	run.add_prop(new /obj/effect/antag_training_beacon(mark))
	var/list/spots = list()
	for(var/turf/tile as anything in hall)
		if(!tile.is_blocked_turf(exclude_mobs = FALSE) && get_dist(tile, body) >= ANTAG_TRAINING_FLEE_START_GAP)
			spots += tile
	prepare_target(session, "human", length(spots) ? pick(spots) : station.spawn_turf())
	return TRUE

/datum/antag_training_exercise/drill/security/detain/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	var/datum/antag_training_sector/station = run.session.arena.sectors[sector]
	new /datum/antag_training_runner/fleeing(target, run.session.arena, station.bounds, run.session.current_body, antag_training_room_turfs(get_turf(target), station))

/datum/antag_training_exercise_step/drill/knockdown/detain
	name = "Сбейте нарушителя с ног"
	hint = "Загоните нарушителя в угол зала и сбейте с ног дубинкой, дизейблером или болой."
	target_death = "задержание, а не убийство: нарушитель погиб"
	var/check_timer

/datum/antag_training_exercise_step/drill/knockdown/detain/New()
	. = ..()
	hint = "Нарушитель убегает, когда вы в [ANTAG_TRAINING_FLEE_RANGE] клетках от него или ближе: загоните его в угол зала. Толчок электродубинкой (правая кнопка мыши), выстрел дизейблера или бола валят его, засчитывается и оглушение. Дубинку, если своей нет, упражнение кладёт у ваших ног, дизейблер и болу выдаёт пульт на вкладке «Снаряжение». Флешбанг из коробки «Security standart kit» в рюкзаке тоже валит с ног - бросайте его подальше от себя. Ручной флешер только ошеломляет и с ног не сбивает."

/datum/antag_training_exercise_step/drill/knockdown/detain/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignals(target, list(COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_LIVING_STATUS_PARALYZE), PROC_REF(queue_check))

/datum/antag_training_exercise_step/drill/knockdown/detain/detach()
	deltimer(check_timer)
	check_timer = null
	return ..()

/// Сигналы оглушения приходят до того, как оно легло на цель: проверка - со следующего тика.
/datum/antag_training_exercise_step/drill/knockdown/detain/proc/queue_check()
	SIGNAL_HANDLER
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(check_stun)), 0, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/drill/knockdown/detain/proc/check_stun()
	check_timer = null
	var/mob/living/target = exercise_target()
	if(target && target.stat != DEAD && (target.body_position == LYING_DOWN || target.IsStun() || target.IsParalyzed() || target.IsKnockdown()))
		complete()

/datum/antag_training_exercise_step/drill/cuff/detain
	hint = "Пока нарушитель лежит, нажмите на него наручниками и не отходите, пока они не защёлкнутся. Две пары наручников лежат в коробке «Security standart kit» в рюкзаке, а если своих нет, упражнение кладёт пару у ваших ног."
	target_death = "задержание, а не убийство: нарушитель погиб"

/datum/antag_training_exercise_step/drill/to_post
	name = "Доставьте задержанного в пост охраны"
	hint = "Ctrl+клик по задержанному - тащить его за собой. Пост охраны - за дверью «Security Post» из зала прибытия, её открывает ваша ID-карта. Засчитывается, когда закованный задержанный внутри поста, у маяка или где угодно в комнате."
	target_death = "задержание, а не убийство: нарушитель погиб"
	var/list/post
	var/check_timer

/datum/antag_training_exercise_step/drill/to_post/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	post = list()
	var/datum/antag_training_exercise/drill/security/exercise = owner.exercise
	for(var/turf/tile as anything in exercise.post_turfs(owner.session))
		post[tile] = TRUE
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(check_post))
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(check_post)), 0, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/drill/to_post/detach()
	deltimer(check_timer)
	check_timer = null
	return ..()

/datum/antag_training_exercise_step/drill/to_post/Destroy()
	post = null
	return ..()

/datum/antag_training_exercise_step/drill/to_post/proc/check_post()
	SIGNAL_HANDLER
	check_timer = null
	var/mob/living/carbon/target = exercise_target()
	if(istype(target) && target.handcuffed && target.stat != DEAD && post?[get_turf(target)])
		complete()

/datum/antag_training_exercise/drill/security/search
	id = "security_search"
	name = "Обыск и конфискация"
	desc = "В посту охраны станционного макета стоит задержанный с запрещённым ножом в кармане. Обыщите его, изымите нож и уберите в шкаф улик."
	difficulty = 1
	par_time = 45 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/seize, /datum/antag_training_exercise_step/drill/evidence)

/datum/antag_training_exercise/drill/security/search/setup(datum/antag_training_session/session)
	var/list/room = post_turfs(session)
	var/list/spots = list()
	for(var/turf/tile as anything in room)
		if(!tile.is_blocked_turf(exclude_mobs = FALSE))
			spots += tile
	if(length(spots) < 2)
		return "в макете нет свободного места в посту охраны, сбросьте сектор"
	if(!target_slot_free(session))
		return FALSE
	var/turf/locker_spot = pick_n_take(spots)
	var/obj/structure/closet/secure_closet/evidence/locker = new(locker_spot)
	locker.locked = FALSE
	locker.update_icon()
	session.exercise_run.add_prop(locker)
	prepare_target(session, "human", pick(spots))
	return TRUE

/datum/antag_training_exercise/drill/security/search/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	var/obj/item/switchblade/knife = run.add_prop(new /obj/item/switchblade(get_turf(target)))
	if(!target.equip_to_slot_if_possible(knife, ITEM_SLOT_RPOCKET, disable_warning = TRUE))
		run.finish(FALSE, "нож не поместился в карман задержанного, попробуйте ещё раз")

/datum/antag_training_exercise_step/drill/seize
	name = "Изымите нож у задержанного"
	hint = "Перетащите задержанного мышью на себя: откроется окно обыска. Нож лежит в правом кармане, нажмите на карман и не отходите, пока вещь не окажется у вас в руке."
	target_death = "обыск, а не расправа: задержанный погиб"

/datum/antag_training_exercise_step/drill/seize/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/obj/item/switchblade/knife = owner.find_prop(/obj/item/switchblade)
	if(knife)
		RegisterSignal(knife, COMSIG_MOVABLE_MOVED, PROC_REF(on_knife_moved))

/datum/antag_training_exercise_step/drill/seize/proc/on_knife_moved(obj/item/source)
	SIGNAL_HANDLER
	var/mob/living/target = exercise_target()
	if(target && get(source.loc, /mob/living) != target)
		complete()

/datum/antag_training_exercise_step/drill/evidence
	name = "Уберите нож в шкаф улик"
	hint = "Шкаф улик стоит в посту охраны и не заперт. Откройте его рукой, нажмите на него ножом, чтобы положить внутрь, и закройте."
	target_death = "обыск, а не расправа: задержанный погиб"

/datum/antag_training_exercise_step/drill/evidence/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/obj/structure/closet/locker = owner.find_prop(/obj/structure/closet/secure_closet/evidence)
	if(!locker)
		return
	RegisterSignal(locker, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	var/obj/item/switchblade/knife = owner.find_prop(/obj/item/switchblade)
	if(knife?.loc == locker)
		addtimer(CALLBACK(src, PROC_REF(complete)), 0)

/datum/antag_training_exercise_step/drill/evidence/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(arrived == run?.find_prop(/obj/item/switchblade))
		complete()

#undef ANTAG_TRAINING_FLEE_RANGE
#undef ANTAG_TRAINING_FLEE_START_GAP
