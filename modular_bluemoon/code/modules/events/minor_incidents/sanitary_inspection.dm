#define SANITARY_INSPECTION_DELAY (10 MINUTES)
/// Раннер событий шагает раз в две секунды.
#define SANITARY_INSPECTION_EVENT_STEP (2 SECONDS)
#define SANITARY_INSPECTION_REWARD 400
#define SANITARY_INSPECTION_JANITOR_BONUS 100
#define SANITARY_INSPECTION_JANITOR_ROLE "Janitor"
/// Наибольший средний балл грязи на отсек для оценок 5, 4, 3 и 2; выше - оценка 1.
#define SANITARY_GRADE_5_LIMIT 1
#define SANITARY_GRADE_4_LIMIT 3
#define SANITARY_GRADE_3_LIMIT 6
#define SANITARY_GRADE_2_LIMIT 12
#define SANITARY_INSPECTION_MAX_STOPS 8
#define SANITARY_INSPECTION_MAX_MARKS 6
#define SANITARY_INSPECTION_SCAN_TIME (6 SECONDS)
/// Влетев в отсек, дрон пролетает ещё пару клеток и только потом зависает.
#define SANITARY_INSPECTION_SETTLE_TIME (1 SECONDS)
/// Не долетел за это время - перелетает напрямую.
#define SANITARY_INSPECTION_TRAVEL_TIMEOUT (20 SECONDS)
#define SANITARY_INSPECTION_STEP_DELAY 4
#define SANITARY_INSPECTION_REPATH_DELAY (2 SECONDS)
#define SANITARY_INSPECTION_MAX_PATH 60
#define SANITARY_BLOOD "blood"
#define SANITARY_VOMIT "vomit"
#define SANITARY_LITTER "litter"
#define SANITARY_TRASH "trash"

/datum/round_event_control/sanitary_inspection
	name = "Sanitary Inspection"
	typepath = /datum/round_event/sanitary_inspection
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	min_players = 10
	min_staffing = list(DIRECTOR_DEPT_MEDICAL = 1)
	severity = DIRECTOR_SEVERITY_MINOR
	category = EVENT_CATEGORY_JANITORIAL
	family = "sanitary_inspection"
	var/list/inspected_area_types = list(/area/medical, /area/command/heads_quarters/cmo)
	var/list/skipped_area_types = list(/area/medical/abandoned, /area/medical/morgue)

/datum/round_event_control/sanitary_inspection/New()
	. = ..()
	description = "ЦК объявляет санитарную проверку медбея: через [SANITARY_INSPECTION_DELAY / (1 MINUTES)] минут дрон-инспектор облетает до [SANITARY_INSPECTION_MAX_STOPS] отсеков и считает кровь, рвоту и мусор. Оценка 5 (в среднем не больше [SANITARY_GRADE_5_LIMIT] балла грязи на отсек) - [SANITARY_INSPECTION_REWARD] кредитов медотделу и по [SANITARY_INSPECTION_JANITOR_BONUS] уборщикам, оценка 4 (до [SANITARY_GRADE_4_LIMIT] баллов) - половина. Нападение игрока на дрона снижает оценку на балл."

/// Маршрут дрона: приёмная первой, остальные отсеки медбея вразброс.
/datum/round_event_control/sanitary_inspection/proc/get_route(first_only = FALSE)
	var/list/entrances = list()
	var/list/rooms = list()
	for(var/area/location as anything in minor_crew_station_areas(inspected_area_types, skipped_area_types))
		if(!length(minor_crew_area_floors(location, first_only = TRUE, require_air = FALSE)))
			continue
		if(first_only)
			return list(location)
		if(istype(location, /area/medical/medbay/lobby) || istype(location, /area/medical/medbay/front_office))
			entrances += location
		else
			rooms += location
	var/list/route = shuffle(entrances) + shuffle(rooms)
	if(length(route) > SANITARY_INSPECTION_MAX_STOPS)
		route.Cut(SANITARY_INSPECTION_MAX_STOPS + 1)
	return route

/datum/round_event_control/sanitary_inspection/director_preflight()
	var/ready = length(get_route(first_only = TRUE)) > 0
	director_preflight_detail = ready ? "Медбей на станции есть." : "На станции нет медбея для проверки."
	director_preflight_failure = ready ? null : director_preflight_detail
	return ready

/datum/round_event/sanitary_inspection
	announce_when = 1
	end_when = SANITARY_INSPECTION_DELAY / SANITARY_INSPECTION_EVENT_STEP
	fakeable = FALSE

/datum/round_event/sanitary_inspection/start()
	log_game("DIRECTOR: [control?.name], санитарная проверка медбея назначена через [SANITARY_INSPECTION_DELAY / (1 MINUTES)] минут.")

/datum/round_event/sanitary_inspection/announce(fake)
	priority_announce("Через [SANITARY_INSPECTION_DELAY / (1 MINUTES)] минут медицинский отдел посетит санитарный дрон-инспектор. Он облетит до [SANITARY_INSPECTION_MAX_STOPS] отсеков, пересчитает пятна крови, рвоту (два балла) и мусор и оставит акт. Оценка 5 - в среднем не больше [SANITARY_GRADE_5_LIMIT] балла грязи на отсек: медотделу [SANITARY_INSPECTION_REWARD] кредитов, уборщикам по [SANITARY_INSPECTION_JANITOR_BONUS]. Оценка 4 - до [SANITARY_GRADE_4_LIMIT] баллов на отсек: половина премии. За нападение на инспектора оценка снижается на балл.", "Санитарная служба NanoTrasen")

/datum/round_event/sanitary_inspection/end()
	dispatch_drone()

/datum/round_event/sanitary_inspection/proc/dispatch_drone(list/route)
	if(!route)
		var/datum/round_event_control/sanitary_inspection/inspection = control
		route = inspection?.get_route()
	if(!length(route))
		log_game("DIRECTOR: [control?.name], медбей не найден, проверка отменена.")
		return null
	var/list/entry = minor_crew_area_floors(route[1], require_air = FALSE)
	if(!length(entry))
		log_game("DIRECTOR: [control?.name], в первом отсеке маршрута нет пола, проверка отменена.")
		return null
	var/mob/living/simple_animal/sanitary_drone/drone = new(pick(entry))
	drone.begin_inspection(route)
	var/area/first_stop = route[1]
	log_game("DIRECTOR: [control?.name], дрон SI-[drone.serial] вылетел: отсеков в маршруте [length(route)], первый - [first_stop.name].")
	return drone

/// Небоевой летающий инспектор: облетает отсеки, считает грязь, печатает акт и улетает.
/mob/living/simple_animal/sanitary_drone
	name = "sanitary inspection drone"
	desc = "Летающий дрон санитарной службы ЦК. Облетает медбей, считает кровь, рвоту и мусор и печатает акт с оценкой. Нападение на инспектора снижает оценку на балл."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/sanitary_inspection.dmi'
	icon_state = "drone"
	icon_living = "drone"
	gender = NEUTER
	health = 40
	maxHealth = 40
	density = FALSE
	move_resist = MOVE_FORCE_OVERPOWERING
	movement_type = FLYING
	mob_size = MOB_SIZE_SMALL
	mob_biotypes = MOB_ROBOTIC
	pass_flags = PASSTABLE | PASSMOB
	AIStatus = AI_OFF
	can_have_ai = FALSE
	wander = FALSE
	stop_automated_movement = TRUE
	speak_emote = list("пищит")
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	unsuitable_atmos_damage = 0
	del_on_death = TRUE
	deathmessage = "рассыпается искрами и обрывками бланков."
	gold_core_spawnable = NO_SPAWN
	var/list/route
	var/stop_index = 0
	/// Пары list(название отсека, list(категория = число)) в порядке облёта.
	var/list/findings = list()
	var/aggression = FALSE
	var/aggressor_name
	var/finished = FALSE
	/// Сколько кредитов получил медотдел.
	var/reward_paid = 0
	var/janitor_bonus = 0
	var/janitors_paid = 0
	var/serial
	var/stop_timer
	var/static/list/chirp_sounds = list(
		'modular_bluemoon/sound/minor_incidents/sanitary_inspection_chirp1.ogg',
		'modular_bluemoon/sound/minor_incidents/sanitary_inspection_chirp2.ogg',
		'modular_bluemoon/sound/minor_incidents/sanitary_inspection_chirp3.ogg',
	)

/mob/living/simple_animal/sanitary_drone/Initialize(mapload)
	. = ..()
	serial = rand(100, 999)
	access_card = new /obj/item/card/id(src)
	access_card.access = list(ACCESS_MEDICAL, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_MORGUE, ACCESS_CHEMISTRY, ACCESS_VIROLOGY, ACCESS_SURGERY, ACCESS_CMO, ACCESS_PSYCH)

/mob/living/simple_animal/sanitary_drone/Destroy()
	if(!finished)
		finished = TRUE
		log_game("DIRECTOR: Sanitary Inspection, дрон SI-[serial] удалён до конца проверки, осмотрено отсеков: [length(findings)].")
	stop_travel()
	QDEL_NULL(access_card)
	route = null
	return ..()

/mob/living/simple_animal/sanitary_drone/examine(mob/user)
	. = ..()
	if(!finished && length(route))
		. += span_notice("На табло: осмотрено отсеков [length(findings)] из [length(route)].")
	if(aggression)
		. += span_warning("В журнале отмечено нападение на инспектора.")

/mob/living/simple_animal/sanitary_drone/proc/chirp()
	playsound(src, pick(chirp_sounds), 35, TRUE, SILENCED_SOUND_EXTRARANGE)

/mob/living/simple_animal/sanitary_drone/proc/begin_inspection(list/new_route)
	route = new_route.Copy()
	pixel_y = base_pixel_y + 24
	alpha = 0
	animate(src, pixel_y = base_pixel_y, alpha = 255, time = 1 SECONDS, easing = SINE_EASING | EASE_OUT)
	chirp()
	say("Санитарная инспекция ЦК. Сохраняйте спокойствие и чистоту.")
	stop_timer = addtimer(CALLBACK(src, PROC_REF(next_stop)), 2 SECONDS, TIMER_STOPPABLE | TIMER_DELETE_ME)

/mob/living/simple_animal/sanitary_drone/proc/next_stop()
	if(finished)
		return
	stop_index++
	if(stop_index > length(route))
		finish_inspection()
		return
	var/area/location = route[stop_index]
	var/list/floors = minor_crew_area_floors(location, require_air = FALSE)
	if(get_area(src) == location || !length(floors))
		arrive()
		return
	travel_to(pick(floors))

/// Летит по коридорам и через двери медбея, а не прыгает сквозь стены.
/mob/living/simple_animal/sanitary_drone/proc/travel_to(turf/destination)
	RegisterSignal(src, COMSIG_ENTER_AREA, PROC_REF(on_enter_area))
	SSmove_manager.jps_move(src, destination, SANITARY_INSPECTION_STEP_DELAY, SANITARY_INSPECTION_TRAVEL_TIMEOUT, SANITARY_INSPECTION_REPATH_DELAY, SANITARY_INSPECTION_MAX_PATH, 0, access_card)
	stop_timer = addtimer(CALLBACK(src, PROC_REF(travel_timed_out)), SANITARY_INSPECTION_TRAVEL_TIMEOUT, TIMER_STOPPABLE | TIMER_DELETE_ME)

/mob/living/simple_animal/sanitary_drone/proc/on_enter_area(datum/source, area/entered)
	SIGNAL_HANDLER
	if(finished || stop_index < 1 || stop_index > length(route) || entered != route[stop_index])
		return
	UnregisterSignal(src, COMSIG_ENTER_AREA)
	deltimer(stop_timer)
	stop_timer = addtimer(CALLBACK(src, PROC_REF(arrive)), SANITARY_INSPECTION_SETTLE_TIME, TIMER_STOPPABLE | TIMER_DELETE_ME)

/mob/living/simple_animal/sanitary_drone/proc/travel_timed_out()
	stop_timer = null
	if(finished)
		return
	var/list/floors = minor_crew_area_floors(route[stop_index], require_air = FALSE)
	if(length(floors))
		hop_to(pick(floors))
	arrive()

/mob/living/simple_animal/sanitary_drone/proc/stop_travel()
	deltimer(stop_timer)
	stop_timer = null
	UnregisterSignal(src, COMSIG_ENTER_AREA)
	SSmove_manager.stop_looping(src)

/mob/living/simple_animal/sanitary_drone/proc/arrive()
	if(finished)
		return
	stop_travel()
	inspect_area(route[stop_index])
	stop_timer = addtimer(CALLBACK(src, PROC_REF(next_stop)), SANITARY_INSPECTION_SCAN_TIME, TIMER_STOPPABLE | TIMER_DELETE_ME)

/mob/living/simple_animal/sanitary_drone/proc/hop_to(turf/destination)
	if(destination == loc)
		return
	forceMove(destination)
	alpha = 0
	animate(src, alpha = 255, time = 4)

/mob/living/simple_animal/sanitary_drone/proc/inspect_area(area/location)
	var/list/dirty_turfs = list()
	var/list/counts = count_dirt(location, dirty_turfs)
	findings += list(list(location.name, counts))
	flick("drone_scan", src)
	chirp()
	for(var/turf/dirty as anything in dirty_turfs)
		new /obj/effect/temp_visual/sanitary_mark(dirty)
	return counts

/mob/living/simple_animal/sanitary_drone/proc/dirt_category(atom/movable/thing)
	if(istype(thing, /obj/effect/decal/cleanable/vomit))
		return SANITARY_VOMIT
	if(istype(thing, /obj/effect/decal/cleanable/blood) || istype(thing, /obj/effect/decal/cleanable/trail_holder))
		return SANITARY_BLOOD
	if(istype(thing, /obj/effect/decal/cleanable))
		return SANITARY_LITTER
	if(istype(thing, /obj/item/trash) || istype(thing, /obj/item/cigbutt) || istype(thing, /obj/item/shard))
		return SANITARY_TRASH
	return null

/// Грязь на полу отсека по категориям; первые грязные клетки попадают в dirty_turfs для отметок.
/mob/living/simple_animal/sanitary_drone/proc/count_dirt(area/location, list/dirty_turfs)
	var/list/counts = list(SANITARY_BLOOD = 0, SANITARY_VOMIT = 0, SANITARY_LITTER = 0, SANITARY_TRASH = 0)
	for(var/turf/open/floor in location)
		var/dirty = FALSE
		for(var/atom/movable/thing as anything in floor)
			var/category = dirt_category(thing)
			if(!category)
				continue
			counts[category]++
			dirty = TRUE
		if(dirty && dirty_turfs && length(dirty_turfs) < SANITARY_INSPECTION_MAX_MARKS)
			dirty_turfs += floor
	return counts

/// Рвота весит вдвое: её не спишешь на работу хирурга.
/mob/living/simple_animal/sanitary_drone/proc/area_points(list/counts)
	return counts[SANITARY_BLOOD] + counts[SANITARY_VOMIT] * 2 + counts[SANITARY_LITTER] + counts[SANITARY_TRASH]

/mob/living/simple_animal/sanitary_drone/proc/dirt_points()
	var/points = 0
	for(var/list/finding as anything in findings)
		points += area_points(finding[2])
	return points

/// Оценка по среднему баллу грязи на осмотренный отсек; нападение на инспектора снижает её на балл.
/mob/living/simple_animal/sanitary_drone/proc/grade_for(points, area_count)
	var/average = points / max(1, area_count)
	var/grade = 1
	if(average <= SANITARY_GRADE_5_LIMIT)
		grade = 5
	else if(average <= SANITARY_GRADE_4_LIMIT)
		grade = 4
	else if(average <= SANITARY_GRADE_3_LIMIT)
		grade = 3
	else if(average <= SANITARY_GRADE_2_LIMIT)
		grade = 2
	if(aggression)
		grade = max(1, grade - 1)
	return grade

/// Полная сумма за пятёрку, половина за четвёрку.
/mob/living/simple_animal/sanitary_drone/proc/payout_for(grade, full_amount)
	switch(grade)
		if(5)
			return full_amount
		if(4)
			return round(full_amount / 2)
	return 0

/mob/living/simple_animal/sanitary_drone/proc/finish_inspection()
	if(finished)
		return
	finished = TRUE
	stop_travel()
	var/points = dirt_points()
	var/grade = grade_for(points, length(findings))
	pay_reward(grade)
	pay_janitors(grade)
	print_report(points, grade)
	say("Проверка завершена, оценка [grade]. Акт оставлен на полу.")
	log_game("DIRECTOR: Sanitary Inspection, дрон SI-[serial]: отсеков [length(findings)], баллов грязи [points], оценка [grade][aggression ? " (снижена за нападение)" : ""], медотделу [reward_paid] кр., уборщикам [janitors_paid] x [janitor_bonus] кр.")
	depart()

/mob/living/simple_animal/sanitary_drone/proc/pay_reward(grade)
	if(reward_paid)
		return FALSE
	var/amount = payout_for(grade, SANITARY_INSPECTION_REWARD)
	if(amount && minor_crew_pay_department(ACCOUNT_MED, amount, "ЦК: премия за санитарную проверку"))
		reward_paid = amount
	return reward_paid

/mob/living/simple_animal/sanitary_drone/proc/pay_janitors(grade)
	janitor_bonus = payout_for(grade, SANITARY_INSPECTION_JANITOR_BONUS)
	if(!janitor_bonus)
		return 0
	for(var/mob/living/carbon/human/janitor as anything in GLOB.human_list)
		if(janitor.stat == DEAD || janitor.mind?.assigned_role != SANITARY_INSPECTION_JANITOR_ROLE)
			continue
		if(minor_crew_pay_person(janitor, janitor_bonus, "премия санитарной службы за чистоту медбея"))
			janitors_paid++
	return janitors_paid

/// Срыв засчитывается только за удар живого игрока: пожар, взрыв или моб без игрока - не агрессия.
/mob/living/simple_animal/sanitary_drone/proc/note_aggression(mob/attacker)
	if(finished || aggression || !is_player_attacker(attacker))
		return FALSE
	aggression = TRUE
	aggressor_name = attacker.name
	chirp()
	say("Зафиксировано нападение на инспектора. Оценка медотдела будет снижена на балл.")
	log_game("DIRECTOR: Sanitary Inspection, [key_name(attacker)] напал на дрона SI-[serial], оценка снижена на балл.")
	return TRUE

/mob/living/simple_animal/sanitary_drone/proc/is_player_attacker(mob/attacker)
	return ismob(attacker) && attacker != src && !!attacker.client

/mob/living/simple_animal/sanitary_drone/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(I.force)
		note_aggression(user)

/mob/living/simple_animal/sanitary_drone/on_attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(. && M.a_intent == INTENT_HARM)
		note_aggression(M)

/mob/living/simple_animal/sanitary_drone/attack_animal(mob/living/simple_animal/M)
	. = ..()
	if(.)
		note_aggression(M)

/mob/living/simple_animal/sanitary_drone/bullet_act(obj/item/projectile/Proj, def_zone, piercing_hit = FALSE)
	. = ..()
	if(Proj.damage > 0 && !Proj.nodamage)
		note_aggression(Proj.firer)

/mob/living/simple_animal/sanitary_drone/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	. = ..()
	var/obj/item/thrown = AM
	if(istype(thrown) && thrown.throwforce)
		note_aggression(throwingdatum?.thrower)

/mob/living/simple_animal/sanitary_drone/death(gibbed)
	if(!finished)
		interrupt()
	return ..()

/// Дрон уничтожен посреди облёта: акт без оценки, премии нет.
/mob/living/simple_animal/sanitary_drone/proc/interrupt()
	finished = TRUE
	stop_travel()
	print_report(dirt_points(), 0)
	log_game("DIRECTOR: Sanitary Inspection, дрон SI-[serial] уничтожен до конца проверки, осмотрено отсеков [length(findings)][aggression ? ", до этого на него напали" : ""], награды нет.")

/mob/living/simple_animal/sanitary_drone/proc/depart()
	animate(src, pixel_y = base_pixel_y + 24, alpha = 0, time = 1 SECONDS, easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(vanish)), 1 SECONDS, TIMER_DELETE_ME)

/mob/living/simple_animal/sanitary_drone/proc/vanish()
	qdel(src)

/mob/living/simple_animal/sanitary_drone/proc/grade_text(grade)
	switch(grade)
		if(5)
			return "5 - образцовая чистота"
		if(4)
			return "4 - удовлетворительно"
		if(3)
			return "3 - на грани"
		if(2)
			return "2 - антисанитария"
	return "1 - санитарная катастрофа"

/mob/living/simple_animal/sanitary_drone/proc/grade_comment(grade)
	switch(grade)
		if(5)
			return "Замечаний нет. Чище, чем в операционной ЦК."
		if(4)
			return "Отдельные загрязнения. Рекомендована дополнительная уборка."
		if(3)
			return "Загрязнения в нескольких отсеках. Рекомендована генеральная уборка до конца смены."
		if(2)
			return "Санитарный режим не соблюдается. Рекомендовано пересмотреть график уборки."
	return "Санитарный режим не соблюдается. Инспектор запросил надбавку за вредность."

/// grade 0 - проверка прервана, оценка не ставится.
/mob/living/simple_animal/sanitary_drone/proc/compose_report(points, grade)
	var/list/lines = list("<center><b>АКТ САНИТАРНОЙ ПРОВЕРКИ</b><br>Санитарная служба NanoTrasen<br>Объект: медицинский отдел станции [station_name()]<br>Инспектор: дрон SI-[serial]</center><hr>")
	var/list/totals = list(SANITARY_BLOOD = 0, SANITARY_VOMIT = 0, SANITARY_LITTER = 0, SANITARY_TRASH = 0)
	for(var/list/finding as anything in findings)
		var/list/counts = finding[2]
		var/list/found = list()
		if(counts[SANITARY_BLOOD])
			found += "кровь - [counts[SANITARY_BLOOD]]"
		if(counts[SANITARY_VOMIT])
			found += "рвота - [counts[SANITARY_VOMIT]]"
		if(counts[SANITARY_LITTER])
			found += "грязь - [counts[SANITARY_LITTER]]"
		if(counts[SANITARY_TRASH])
			found += "мусор - [counts[SANITARY_TRASH]]"
		for(var/category in totals)
			totals[category] += counts[category]
		lines += "<b>[finding[1]]:</b> [length(found) ? "[jointext(found, ", ")] ([area_points(counts)] б.)" : "чисто"]<br>"
	if(!length(findings))
		lines += "Проверка прервана до осмотра первого отсека.<br>"
	lines += "<hr>Итого: кровь - [totals[SANITARY_BLOOD]], рвота - [totals[SANITARY_VOMIT]] (по два балла), грязь - [totals[SANITARY_LITTER]], мусор и осколки - [totals[SANITARY_TRASH]].<br>"
	if(aggression)
		lines += "Зафиксировано нападение на инспектора[aggressor_name ? " ([aggressor_name])" : ""], оценка снижена на балл.<br>"
	if(!grade)
		lines += "<b>Проверка прервана: инспектор уничтожен.</b> Оценка не выставляется, премия не начисляется."
		return jointext(lines, "")
	var/area_count = max(1, length(findings))
	lines += "<b>Баллы грязи:</b> [points], в среднем [round(points / area_count, 0.1)] на отсек. <b>Оценка:</b> [grade_text(grade)].<br><i>[grade_comment(grade)]</i><br>"
	if(reward_paid)
		lines += "Премия медотделу: [reward_paid] кредитов."
	else
		lines += "Премия медотделу не начисляется: нужна оценка 4 и выше, то есть в среднем не больше [SANITARY_GRADE_4_LIMIT] баллов грязи на отсек."
	if(janitors_paid)
		lines += "<br>Премия уборщикам: по [janitor_bonus] кредитов."
	return jointext(lines, "")

/mob/living/simple_animal/sanitary_drone/proc/print_report(points, grade)
	var/obj/item/paper/sanitary_report/report = new(drop_location())
	report.add_raw_text(compose_report(points, grade))
	report.update_appearance()
	playsound(src, 'sound/goonstation/machines/printer_thermal.ogg', 40, TRUE, SILENCED_SOUND_EXTRARANGE)
	visible_message(span_notice("[src] с треском выпускает из щели длинную ленту акта и роняет её на пол."))
	return report

/obj/item/paper/sanitary_report
	name = "paper - 'Sanitary inspection report'"
	desc = "Акт санитарной проверки медбея с оценкой и списком замечаний."

/// Красная отметка на грязной клетке, пока дрон сканирует отсек.
/obj/effect/temp_visual/sanitary_mark
	icon = 'modular_bluemoon/icons/effects/minor_incidents/sanitary_inspection.dmi'
	icon_state = "dirt_mark"
	randomdir = FALSE
	duration = 2 SECONDS

#undef SANITARY_INSPECTION_DELAY
#undef SANITARY_INSPECTION_EVENT_STEP
#undef SANITARY_INSPECTION_REWARD
#undef SANITARY_INSPECTION_JANITOR_BONUS
#undef SANITARY_INSPECTION_JANITOR_ROLE
#undef SANITARY_GRADE_5_LIMIT
#undef SANITARY_GRADE_4_LIMIT
#undef SANITARY_GRADE_3_LIMIT
#undef SANITARY_GRADE_2_LIMIT
#undef SANITARY_INSPECTION_MAX_STOPS
#undef SANITARY_INSPECTION_MAX_MARKS
#undef SANITARY_INSPECTION_SCAN_TIME
#undef SANITARY_INSPECTION_SETTLE_TIME
#undef SANITARY_INSPECTION_TRAVEL_TIMEOUT
#undef SANITARY_INSPECTION_STEP_DELAY
#undef SANITARY_INSPECTION_REPATH_DELAY
#undef SANITARY_INSPECTION_MAX_PATH
#undef SANITARY_BLOOD
#undef SANITARY_VOMIT
#undef SANITARY_LITTER
#undef SANITARY_TRASH
