/datum/antag_training_program/creature/disease
	name = "Разумная болезнь"
	category = "Станционные угрозы"
	desc = "Камера болезни над станционным макетом: нулевой пациент из манекенов, заражение соседей кашлем и прикосновениями, адаптации за очки. Излечение последнего носителя возвращает вас в своё тело."
	icon = "virus"
	color = "green"
	learn = "Нулевой пациент|Заражение кашлем и прикосновениями|Адаптации за очки|Переход между носителями"
	difficulty = 3
	sector = "station"
	mob_type = /mob/camera/disease/training
	antag_type = /datum/antagonist/disease/training
	options = list("Очки адаптации", "Носители", "Сбросить адаптации")
	var/in_avatar = FALSE

/datum/antag_training_program/creature/disease/New()
	. = ..()
	var/mob/camera/disease/training/sample = mob_type
	option_hints = list(
		"Очки адаптации" = "Счёт станет [ANTAG_TRAINING_DISEASE_POINTS] из [ANTAG_TRAINING_DISEASE_POINTS], а задержка адаптации сбросится: доступны любые симптомы, включая самые дорогие. В раунде очко даёт каждый новый носитель, а между адаптациями проходит [initial(sample.adaptation_cooldown) / (1 SECONDS)] с.",
		"Носители" = "Рядом встанут манекены ([ANTAG_TRAINING_DISEASE_HOSTS] шт.). Щелчок по манекену делает его нулевым пациентом, остальные заражаются от него кашлем, чиханием и заражёнными предметами. Заразить можно только свои манекены: ни участников, ни чужие цели полигона, ни экипаж станции.",
		"Сбросить адаптации" = "Купленные симптомы снимутся с носителей и вернутся в список, а очки - на счёт. Добровольный кашель остаётся. В раунде адаптации не отменить.",
	)

/datum/antag_training_program/creature/disease/handle_choice(datum/antag_training_session/session, mob/user, option)
	if(..())
		return TRUE
	var/mob/camera/disease/training/camera = user
	if(!istype(camera) || camera != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в камере болезни. Раздел «Программы» в пульте перезапустит «[name]» новой болезнью."))
		return FALSE
	switch(option)
		if("Очки адаптации")
			camera.grant_points()
		if("Носители")
			return place_hosts(session, camera)
		if("Сбросить адаптации")
			return camera.reset_adaptations()
	return TRUE

/datum/antag_training_program/creature/disease/proc/place_hosts(datum/antag_training_session/session, mob/camera/disease/training/camera)
	var/datum/antag_training_arena/arena = session.arena
	var/zone_id = arena.match_zone(camera)
	if(!arena.zones[zone_id] || zone_id == "hub")
		zone_id = arena.zones["station"] ? "station" : "laboratory"
	if(world.time < session.next_supply_at)
		to_chat(camera, span_warning("Подождите несколько секунд перед следующими носителями."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	if(!arena.has_target_room(ANTAG_TRAINING_DISEASE_HOSTS))
		to_chat(camera, span_warning(arena.target_limit_refusal()))
		return FALSE
	var/turf/near = get_turf(camera)
	var/list/placed = list()
	for(var/index in 1 to ANTAG_TRAINING_DISEASE_HOSTS)
		var/mob/living/carbon/human/host = arena.spawn_creature("human", zone_id, FALSE, session, near)
		if(!host)
			break
		placed += host.real_name
		near ||= get_turf(host)
	if(!length(placed))
		to_chat(camera, span_warning("Рядом нет свободного места для носителей. Отойдите от стен и препятствий или перейдите на другую площадку."))
		return FALSE
	to_chat(camera, span_notice("Манекены для заражения ([length(placed)] шт.): [english_list(placed)]. Щёлкните по одному, чтобы выбрать нулевого пациента."))
	return TRUE

/// Последний носитель излечён: участник возвращается в своё тело, а не исчезает вместе с камерой.
/datum/antag_training_program/creature/disease/proc/return_to_avatar(datum/antag_training_session/session)
	if(rebuilding || QDELETED(session) || session.finished || session.resetting)
		return FALSE
	var/datum/antag_training_arena/arena = session.arena
	var/datum/mind/soul = session.avatar_mind
	if(QDELETED(arena) || arena.finished || arena.resetting || QDELETED(soul))
		return FALSE
	var/mob/camera/disease/training/camera = body_ref?.resolve()
	if(!camera || soul.current != camera)
		return FALSE
	in_avatar = TRUE
	var/returned = FALSE
	try
		returned = replace_body(session, arena.entry_turf)
	catch(var/exception/error)
		in_avatar = FALSE
		throw error
	if(!returned)
		in_avatar = FALSE
		return FALSE
	to_chat(session.current_body, span_notice("Последний носитель излечён: инфекция погибла, и вы вернулись в своё тело. Раздел «Программы» в пульте перезапустит «[name]» новой болезнью."))
	return TRUE

/// После излечения тело программы - кукла участника: replace_body() строит её, а не новую камеру.
/datum/antag_training_program/creature/disease/spawn_creature_body(datum/antag_training_session/session, turf/where)
	if(!in_avatar)
		return ..()
	var/datum/mind/soul = session.avatar_mind
	var/datum/antag_training_arena/arena = session.arena
	where ||= arena?.entry_turf
	if(QDELETED(soul) || QDELETED(arena) || arena.finished || !arena.owns_area(get_area(where)))
		return null
	var/mob/living/carbon/human/body = session.build_avatar_body(where)
	body.register_training_atom()
	if(body.training_origin?.resolve() != arena)
		qdel(body)
		return null
	var/mob/old_body = soul.current
	soul.transfer_to(body)
	if(soul.current != body)
		qdel(body)
		return null
	if(old_body?.ckey && !body.ckey)
		old_body.transfer_ckey(body, FALSE)
	session.avatar = body
	body_ref = WEAKREF(body)
	deltimer(session.recovery_timer)
	session.recovery_timer = null
	return body

/// Умершую куклу сеанс поднимает обычным восстановлением, удалённую программа строит заново - новой болезни без «Программ» нет.
/datum/antag_training_program/creature/disease/body_lost(datum/antag_training_session/session)
	if(in_avatar && !QDELETED(session.current_body))
		return FALSE
	return ..()

/mob/camera/disease/training
	name = "Training Disease"
	real_name = "Training Disease"
	template_type = /datum/disease/advance/sentient_disease/training

/mob/camera/disease/training/Initialize(mapload)
	. = ..()
	arm_freemove(ANTAG_TRAINING_DISEASE_FREEMOVE)

/// Ожидание нулевого пациента: тем же таймером оно и продлевается, когда манекенов не нашлось.
/mob/camera/disease/training/proc/arm_freemove(delay)
	if(!freemove)
		return FALSE
	deltimer(freemove_end_timerid)
	freemove_end = world.time + delay
	freemove_end_timerid = addtimer(CALLBACK(src, PROC_REF(infect_random_patient_zero)), delay, TIMER_STOPPABLE)
	return TRUE

/mob/camera/disease/training/proc/training_session()
	var/datum/antagonist/disease/training/role = mind?.has_antag_datum(/datum/antagonist/disease/training)
	return role?.training

/// Заразить можно только свой учебный манекен своего полигона: через эту проверку идут все пути заражения учебной болезни.
/mob/camera/disease/training/proc/can_infect_target(mob/living/target)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	var/datum/antag_training_session/session = training_session()
	if(QDELETED(target) || QDELETED(arena) || arena.finished || !session || session.arena != arena)
		return FALSE
	return (target in arena.targets) && target.training_owner?.resolve() == session

/mob/camera/disease/training/infect_random_patient_zero(del_on_fail = TRUE)
	if(!freemove)
		return FALSE
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/dummy in arena?.targets)
		if(dummy.stat != DEAD && can_infect_target(dummy) && dummy.CanContractDisease(disease_template))
			candidates += dummy
	shuffle_inplace(candidates)
	for(var/mob/living/carbon/human/dummy as anything in candidates)
		if(force_infect(dummy))
			return TRUE
	to_chat(src, span_warning("Свободных манекенов на полигоне нет, а экипаж станции учебной болезни недоступен. Создайте носителей в пульте («Моя роль» - «Носители»): ожидание продлено на [ANTAG_TRAINING_DISEASE_FREEMOVE / (1 SECONDS)] с."))
	arm_freemove(ANTAG_TRAINING_DISEASE_FREEMOVE)
	return FALSE

/mob/camera/disease/training/confirm_initial_infection(mob/living/carbon/human/host)
	if(!freemove)
		return
	if(!can_infect_target(host))
		to_chat(src, span_warning("Нулевым пациентом становится только ваш учебный манекен: чужие цели, участники и экипаж станции недоступны. Создайте носителей в пульте: «Моя роль» - «Носители»."))
		return
	if(!force_infect(host))
		to_chat(src, span_warning("[host.name] не заражается: манекен мёртв или уже невосприимчив. Выберите другого."))

/mob/camera/disease/training/on_last_host_cured()
	var/datum/antag_training_session/session = training_session()
	var/datum/antag_training_program/creature/disease/program = session?.program
	if(istype(program) && !session.finished && (session.resetting || session.arena?.resetting))
		addtimer(CALLBACK(src, PROC_REF(retry_return)), 1 SECONDS)
		return
	if(istype(program) && program.return_to_avatar(session))
		return
	return ..()

/mob/camera/disease/training/proc/retry_return()
	if(!length(disease_instances))
		on_last_host_cured()

/mob/camera/disease/training/proc/grant_points()
	total_points = max(total_points, ANTAG_TRAINING_DISEASE_POINTS)
	points = ANTAG_TRAINING_DISEASE_POINTS
	next_adaptation_time = 0
	to_chat(src, span_notice("Счёт адаптаций: [points] из [total_points], задержка сброшена.[freemove ? " Покупать адаптации можно после выбора нулевого пациента." : ""]"))
	refresh_adaptation_menu()
	return TRUE

/mob/camera/disease/training/proc/reset_adaptations()
	var/refunded = 0
	for(var/datum/disease_ability/ability as anything in purchased_abilities.Copy())
		if(ability.start_with)
			continue
		ability.Refund(src, TRUE, FALSE)
		refunded++
	if(!refunded)
		to_chat(src, span_warning("Купленных адаптаций нет."))
		return FALSE
	next_adaptation_time = 0
	to_chat(src, span_notice("Адаптации сброшены ([refunded] шт.): симптомы снялись с носителей, очки вернулись на счёт ([points] из [total_points])."))
	refresh_adaptation_menu()
	return TRUE

/mob/camera/disease/training/ui_data(mob/user)
	. = ..()
	for(var/list/entry as anything in .["abilities"])
		if(!(entry["path"] in GLOB.antag_training_disease_blocked))
			continue
		entry["can_buy"] = FALSE
		entry["short_desc"] = GLOB.antag_training_disease_blocked[entry["path"]]

/mob/camera/disease/training/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(action == "buy_ability" && usr == src)
		var/datum/disease_ability/ability = locate(params["ability"])
		var/refusal = ability && GLOB.antag_training_disease_blocked["[ability.type]"]
		if(refusal)
			to_chat(src, span_warning(refusal))
			return TRUE
	return ..()

/mob/camera/disease/training/Destroy()
	var/datum/atom_hud/disease_hud = GLOB.huds[DATA_HUD_SENTIENT_DISEASE]
	for(var/datum/disease/advance/sentient_disease/training/virus as anything in GLOB.sentient_disease_instances)
		if(virus.overmind != src)
			continue
		// Носителей лечим, а копии в предметах и реагентах только отвязываем: qdel оставил бы в них ссылку на удалённый датум.
		virus.overmind = null
		GLOB.sentient_disease_instances -= virus
		if(!QDELETED(virus) && virus.affected_mob)
			disease_hud.remove_from_hud(virus.affected_mob)
			virus.cure(FALSE)
	SSdisease.archive_diseases -= "[template_type]|[tag]"
	QDEL_NULL(disease_template)
	return ..()

/// Учебный вирус: заражает только манекены своего полигона и без живой камеры полигона - никого.
/datum/disease/advance/sentient_disease/training
	name = "Training Virus"
	desc = "Учебный вирус тренировочного полигона: вне полигона не приживается."

/datum/disease/advance/sentient_disease/training/try_infect(mob/living/infectee, make_copy = TRUE)
	if(!training_allows(infectee))
		return FALSE
	return ..()

/datum/disease/advance/sentient_disease/training/infect(mob/living/infectee, make_copy = TRUE)
	if(!training_allows(infectee))
		return
	return ..()

/datum/disease/advance/sentient_disease/training/proc/training_allows(mob/living/infectee)
	var/mob/camera/disease/training/camera = overmind
	return istype(camera) && camera.can_infect_target(infectee)

/datum/antagonist/disease/training
	name = "Учебная разумная болезнь"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training
	var/previous_special_role
	var/previous_assigned_role

/datum/antagonist/disease/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/disease/training/threat()
	return 0

/datum/antagonist/disease/training/on_gain()
	previous_special_role = owner.special_role
	previous_assigned_role = owner.assigned_role
	. = ..()
	for(var/datum/objective/objective as anything in objectives.Copy())
		objectives -= objective
		qdel(objective)

/datum/antagonist/disease/training/on_removal()
	owner.special_role = previous_special_role
	owner.assigned_role = previous_assigned_role
	return ..()

/datum/antagonist/disease/training/apply_innate_effects(mob/living/mob_override)
	return

/datum/antagonist/disease/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/disease/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/disease/training/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка разумной болезни. Вы - камера вируса: вас не видно, вас нельзя ударить, но и сами вы действуете только через носителей."),
		span_notice("Щелчок по учебному манекену делает его нулевым пациентом. Пока нулевого пациента нет, вы свободно летаете [ANTAG_TRAINING_DISEASE_FREEMOVE / (1 SECONDS)] с, потом болезнь сама выберет манекен; экипаж станции и другие участники вам недоступны."),
		span_notice("После первого носителя открывается «Меню адаптации»: симптомы за очки, добровольный кашель и чихание разносят заразу по соседям, «Secrete Infection» делает заразными предметы и пол под носителем."),
		span_notice("«Пульт полигона», раздел «Моя роль»: очки адаптации, [ANTAG_TRAINING_DISEASE_HOSTS] манекена-носителя рядом и сброс адаптаций. Излечение последнего носителя возвращает вас в своё тело, а выход с полигона лечит все манекены."),
	), "<br>")

/datum/antagonist/disease/training/Destroy()
	training = null
	return ..()

/// Адаптации, которые на полигоне закрыты: путь адаптации -> текст отказа.
GLOBAL_LIST_INIT(antag_training_disease_blocked, list(
	"[/datum/disease_ability/symptom/powerful/monkey_transform]" = "На полигоне недоступно: обращение носителя в обезьяну выдаёт манекену настоящую роль обезьяны раунда.",
))
