#define HK_FACTORY_BELT_ID "hk_factory_belt"
#define HK_FACTORY_VACANCY_CHECK (1 MINUTES)

GLOBAL_LIST_EMPTY(hk_assembly_lines)
GLOBAL_LIST_EMPTY(hk50_dormant_racks)
GLOBAL_LIST_EMPTY(hk_factory_turrets)
GLOBAL_LIST_EMPTY(hk_factory_sparkers)

/// Отбирает из списка то, что стоит в зоне factory: фабрика - это зона.
/proc/hk_factory_members(list/candidates, area/factory)
	. = list()
	if(isnull(factory))
		return
	for(var/atom/member as anything in candidates)
		if(get_area(member) == factory)
			. += member

/proc/hk_factory_lines(area/factory)
	return hk_factory_members(GLOB.hk_assembly_lines, factory)

/// Перепланировать сборку на всех конвейерах цеха: штат изменился.
/proc/hk_factory_reschedule(area/factory)
	for(var/obj/machinery/hk_assembly_line/line as anything in hk_factory_lines(factory))
		line.schedule_assembly()

/// Ленты цеха едут, только пока на фабрике кто-то есть и производство не остановлено.
/proc/hk_factory_update_belts(area/factory)
	var/area/ruin/space/has_grav/hk_factory/plant = factory
	var/running = istype(plant) && plant.awake && plant.production_active
	for(var/obj/machinery/conveyor/belt as anything in hk_factory_members(GLOB.conveyors_by_id[HK_FACTORY_BELT_ID], factory))
		belt.last_command = running ? CONVEYOR_FORWARD : CONVEYOR_OFF
		belt.update()

/area/ruin/space/has_grav/hk_factory
	name = "HK Droid Factory"
	icon_state = "red"
	shipambience = 'modular_bluemoon/sound/hk_droids/factory_hum.ogg'
	ambientsounds = list('sound/ambience/ambitech.ogg', 'sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')
	/// На фабрике есть живой игрок: крутятся ленты, искрят щиты, лязгают конвейеры.
	var/awake = FALSE
	var/production_active = TRUE
	var/ambush_sprung = FALSE
	var/ambush_timer
	var/ambience_timer
	var/vacancy_timer
	var/had_power = TRUE
	/// Питание пропало при людях в цехе: стража идёт к щитовой.
	var/protocol_active = FALSE
	var/turf/protocol_turf
	var/datum/weakref/protocol_culprit_ref

/area/ruin/space/has_grav/hk_factory/Entered(atom/movable/arrived, atom/old_loc)
	. = ..()
	if(awake || !isliving(arrived))
		return
	var/mob/living/visitor = arrived
	if(visitor.client)
		wake_up()

/area/ruin/space/has_grav/hk_factory/proc/wake_up()
	if(awake)
		return
	awake = TRUE
	refresh_machinery()
	ambience_timer = addtimer(CALLBACK(src, PROC_REF(ambience_tick)), rand(3 SECONDS, 8 SECONDS), TIMER_STOPPABLE)
	vacancy_timer = addtimer(CALLBACK(src, PROC_REF(check_vacancy)), HK_FACTORY_VACANCY_CHECK, TIMER_STOPPABLE)

/area/ruin/space/has_grav/hk_factory/proc/fall_asleep()
	awake = FALSE
	deltimer(ambience_timer)
	deltimer(vacancy_timer)
	ambience_timer = null
	vacancy_timer = null
	refresh_machinery()

/area/ruin/space/has_grav/hk_factory/proc/refresh_machinery()
	hk_factory_update_belts(src)
	for(var/obj/machinery/hk_assembly_line/line as anything in hk_factory_lines(src))
		line.refresh_activity()

/area/ruin/space/has_grav/hk_factory/proc/check_vacancy()
	vacancy_timer = null
	for(var/mob/living/visitor as anything in GLOB.player_list)
		if(isliving(visitor) && get_area(visitor) == src)
			vacancy_timer = addtimer(CALLBACK(src, PROC_REF(check_vacancy)), HK_FACTORY_VACANCY_CHECK, TIMER_STOPPABLE)
			return
	fall_asleep()

/// Искрит случайный разбитый щиток, рядом мигает свет.
/area/ruin/space/has_grav/hk_factory/proc/ambience_tick()
	ambience_timer = null
	if(!awake)
		return
	var/list/sparkers = hk_factory_members(GLOB.hk_factory_sparkers, src)
	if(length(sparkers))
		var/obj/effect/hk_factory_sparker/sparker = pick(sparkers)
		sparker.spark()
	ambience_timer = addtimer(CALLBACK(src, PROC_REF(ambience_tick)), rand(6 SECONDS, 15 SECONDS), TIMER_STOPPABLE)

/// Засада: спящие HK-50 цеха просыпаются один раз - стойки мигают и лязгают, свет дёргается, через HK_FACTORY_AMBUSH_WARNING дроиды сходят.
/area/ruin/space/has_grav/hk_factory/proc/spring_ambush(mob/living/intruder)
	if(ambush_sprung)
		return FALSE
	ambush_sprung = TRUE
	var/list/racks = hk_factory_members(GLOB.hk50_dormant_racks, src)
	if(!length(racks))
		return TRUE
	playsound(intruder || racks[1], 'sound/machines/Alarm.ogg', 60, FALSE, 4)
	for(var/obj/structure/hk50_rack/dormant/rack as anything in racks)
		rack.start_waking()
	for(var/obj/machinery/light/light in src)
		light.flicker(rand(3, 6))
	ambush_timer = addtimer(CALLBACK(src, PROC_REF(release_ambush), WEAKREF(intruder)), HK_FACTORY_AMBUSH_WARNING, TIMER_STOPPABLE)
	return TRUE

/// Стойки выпускают дроидов; засаду озвучивает один из них.
/area/ruin/space/has_grav/hk_factory/proc/release_ambush(datum/weakref/intruder_ref)
	ambush_timer = null
	var/mob/living/intruder = intruder_ref?.resolve()
	var/list/woken = list()
	for(var/obj/structure/hk50_rack/dormant/rack as anything in hk_factory_members(GLOB.hk50_dormant_racks, src))
		var/mob/living/simple_animal/hostile/hk50/droid = rack.wake(intruder)
		if(droid)
			woken += droid
	if(length(woken))
		var/mob/living/simple_animal/hostile/hk50/herald = woken[1]
		herald.hk50_say("Нарушитель в цехе. Мы здесь. Мы существуем, и нас становится больше.", forced = TRUE, voice = "hk50_numbers_grow")
	if(protocol_active)
		rally_guards(woken)
	return woken

/area/ruin/space/has_grav/hk_factory/power_change()
	. = ..()
	if(power_equip == had_power)
		return
	had_power = power_equip
	if(!power_equip && awake)
		INVOKE_ASYNC(src, PROC_REF(start_autonomous_protocol))

/// Цех обесточили при людях: стойки выпускают дроидов, вся стража идёт к щитовой.
/area/ruin/space/has_grav/hk_factory/proc/start_autonomous_protocol()
	if(protocol_active)
		return FALSE
	var/turf/rally = get_turf(hk_factory_apc(src))
	if(!rally)
		return FALSE
	protocol_active = TRUE
	protocol_turf = rally
	var/mob/living/culprit = hk_factory_culprit(src, rally)
	protocol_culprit_ref = WEAKREF(culprit)
	playsound(rally, 'sound/machines/Alarm.ogg', 70, FALSE, 10)
	for(var/mob/living/listener in GLOB.player_list)
		if(get_area(listener) == src)
			to_chat(listener, span_userdanger("Динамики цеха хрипят: «Питание потеряно. Автономный протокол защиты. Всем единицам - к щитовой»."))
	log_game("Фабрика HK: автономный протокол защиты[culprit ? ", ближе всех к щитовой [key_name(culprit)]" : ""], [AREACOORD(rally)].")
	spring_ambush(culprit)
	rally_guards()
	return TRUE

/// Отправить HK-50 цеха обыскивать щитовую.
/area/ruin/space/has_grav/hk_factory/proc/rally_guards(list/droids)
	if(!protocol_turf)
		return
	var/mob/living/culprit = protocol_culprit_ref?.resolve()
	for(var/mob/living/simple_animal/hostile/hk50/droid as anything in (droids || hk_factory_droids(src)))
		var/datum/ai_controller/controller = droid.ai_controller
		if(QDELETED(controller) || droid.stat == DEAD)
			continue
		if(controller.receive_combat_contact(culprit, protocol_turf, AI_CONTACT_ALLY))
			controller.blackboard[BB_AI_SEARCH_UNTIL] = world.time + HK_FACTORY_PROTOCOL_SEARCH_TIME

/// HK-50 фабрики в зоне, кроме чужих слуг.
/proc/hk_factory_droids(area/factory)
	. = list()
	for(var/mob/living/simple_animal/hostile/hk50/droid in GLOB.mob_living_list)
		if(droid.stat != DEAD && get_area(droid) == factory && !droid.GetComponent(/datum/component/hk50_servant))
			. += droid

/proc/hk_factory_apc(area/factory)
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		if(apc.area == factory)
			return apc

/// Ближайший к щитовой чужак в цехе: его стража и ищет.
/proc/hk_factory_culprit(area/factory, turf/rally)
	var/best_distance = INFINITY
	for(var/mob/living/suspect in GLOB.player_list)
		if(get_area(suspect) != factory || !hk_factory_is_intruder(suspect))
			continue
		var/distance = get_dist(suspect, rally)
		if(distance < best_distance)
			best_distance = distance
			. = suspect

/datum/map_template/ruin/space/hk_factory
	id = "hk_factory"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "hk_factory.dmm"
	name = "HK Droid Factory"
	description = "Заброшенный завод дроидов-ассасинов HK-50. Конвейеры так и не остановили: цех пополняет стражу, на полигоне и в ангаре лежат те, кто пришёл раньше."
	placement_weight = 3
	cost = 2

/obj/machinery/hk_assembly_line
	name = "HK-50 assembly line"
	desc = "Сборочная станина дроидов HK-50: манипулятор над каркасом сваривает корпус за корпусом, и готовый дроид сходит с ленты уже вооружённым."
	icon = 'modular_bluemoon/icons/obj/hk_droids/factory.dmi'
	icon_state = "assembly_line"
	base_icon_state = "assembly_line"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 500
	max_integrity = 300
	var/active = TRUE
	/// Живые HK-50 фабрики на учёте этого конвейера
	var/list/mob/living/simple_animal/hostile/hk50/droids = list()
	var/assembly_timer
	var/datum/looping_sound/hk_assembly_line/clank

/obj/machinery/hk_assembly_line/Initialize(mapload)
	. = ..()
	GLOB.hk_assembly_lines += src
	clank = new(src)
	refresh_activity()

/obj/machinery/hk_assembly_line/Destroy()
	GLOB.hk_assembly_lines -= src
	deltimer(assembly_timer)
	assembly_timer = null
	QDEL_NULL(clank)
	var/list/others = hk_factory_lines(get_area(src))
	var/obj/machinery/hk_assembly_line/heir = length(others) ? others[1] : null
	for(var/mob/living/simple_animal/hostile/hk50/droid as anything in droids)
		UnregisterSignal(droid, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		heir?.track(droid)
	droids.Cut()
	return ..()

/obj/machinery/hk_assembly_line/power_change()
	. = ..()
	refresh_activity()

/obj/machinery/hk_assembly_line/update_icon_state()
	icon_state = is_running() ? base_icon_state : "[base_icon_state]_off"
	return ..()

/obj/machinery/hk_assembly_line/examine(mob/user)
	. = ..()
	. += span_notice("Раз в [DisplayTimeText(HK_FACTORY_ASSEMBLY_DELAY)] выпускает нового HK-50, пока у фабрики меньше [HK_FACTORY_MAX_DROIDS] дроидов, считая спящих на стойках. Остановить его можно пультом управления фабрикой, отключив питание цеха или разломав станину. Отключение питания при людях в цехе поднимает всю стражу к щитовой.")
	if(machine_stat & NOPOWER)
		. += span_notice("Питания нет: конвейер стоит.")
	else if(!active)
		. += span_notice("Конвейер остановлен с пульта.")
	else if(factory_droid_count() >= HK_FACTORY_MAX_DROIDS)
		. += span_notice("У фабрики полный штат: сборка ждёт потерь.")
	else if(assembly_timer)
		. += span_warning("Следующий HK-50 сойдёт с ленты через [DisplayTimeText(timeleft(assembly_timer), 1)].")

/obj/machinery/hk_assembly_line/on_deconstruction()
	. = ..()
	do_sparks(5, TRUE, src)
	new /obj/item/stack/sheet/metal/five(loc)
	new /obj/effect/decal/cleanable/robot_debris(loc)

/obj/machinery/hk_assembly_line/proc/is_running()
	return active && !(machine_stat & (NOPOWER|BROKEN))

/obj/machinery/hk_assembly_line/proc/set_active(new_active)
	if(active == new_active)
		return
	active = new_active
	refresh_activity()

/// Привести таймер сборки, лязг и вид в соответствие с питанием, пультом и присутствием людей.
/obj/machinery/hk_assembly_line/proc/refresh_activity()
	update_appearance(UPDATE_ICON_STATE)
	var/area/ruin/space/has_grav/hk_factory/factory = get_area(src)
	if(is_running() && istype(factory) && factory.awake)
		clank?.start()
	else
		clank?.stop()
	if(is_running())
		schedule_assembly()
		return
	deltimer(assembly_timer)
	assembly_timer = null

/// HK-50 цеха: на учёте конвейеров и спящие на стойках.
/obj/machinery/hk_assembly_line/proc/factory_droid_count()
	var/area/factory = get_area(src)
	. = length(droids) + length(hk_factory_members(GLOB.hk50_dormant_racks, factory))
	for(var/obj/machinery/hk_assembly_line/line as anything in hk_factory_lines(factory))
		if(line != src)
			. += length(line.droids)

/obj/machinery/hk_assembly_line/proc/schedule_assembly()
	if(assembly_timer || !is_running() || QDELETED(src) || factory_droid_count() >= HK_FACTORY_MAX_DROIDS)
		return
	assembly_timer = addtimer(CALLBACK(src, PROC_REF(assembly_cycle)), HK_FACTORY_ASSEMBLY_DELAY, TIMER_STOPPABLE)

/obj/machinery/hk_assembly_line/proc/assembly_cycle()
	assembly_timer = null
	try_assemble()
	schedule_assembly()

/// Собрать HK-50 у выхода конвейера; null, если конвейер стоит или у фабрики полный штат.
/obj/machinery/hk_assembly_line/proc/try_assemble()
	if(!is_running() || factory_droid_count() >= HK_FACTORY_MAX_DROIDS)
		return null
	var/turf/exit = get_step(src, dir)
	if(isnull(exit) || exit.is_blocked_turf(TRUE))
		exit = get_turf(src)
	if(isnull(exit))
		return null
	var/mob/living/simple_animal/hostile/hk50/droid = new(exit)
	track(droid)
	playsound(src, 'sound/machines/piston/piston_raise.ogg', 50, TRUE)
	do_sparks(3, FALSE, src)
	droid.hk50_say("Мы здесь. Мы существуем, и нас становится больше.", voice = "hk50_numbers_grow")
	return droid

/obj/machinery/hk_assembly_line/proc/track(mob/living/simple_animal/hostile/hk50/droid)
	droid.factory_ref = WEAKREF(src)
	droid.spares_series = TRUE
	droids += droid
	RegisterSignal(droid, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(on_droid_lost))

/obj/machinery/hk_assembly_line/proc/on_droid_lost(mob/living/simple_animal/hostile/hk50/droid)
	SIGNAL_HANDLER
	UnregisterSignal(droid, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	droids -= droid
	schedule_assembly()
	hk_factory_reschedule(get_area(src))

/datum/looping_sound/hk_assembly_line
	mid_sounds = list('modular_bluemoon/sound/hk_droids/factory_clank.ogg' = 1)
	mid_length = 3.1 SECONDS
	volume = 30
	extra_range = -2
	falloff_distance = 2

/// Страж фабрики с карты: встаёт на учёт конвейера своего цеха.
/mob/living/simple_animal/hostile/hk50/factory_guard
	spares_series = TRUE

/mob/living/simple_animal/hostile/hk50/factory_guard/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/mob/living/simple_animal/hostile/hk50/factory_guard/LateInitialize()
	. = ..()
	var/list/lines = hk_factory_lines(get_area(src))
	if(length(lines))
		var/obj/machinery/hk_assembly_line/line = lines[1]
		line.track(src)

/// Патрульный страж: ходит по коридору от стены до стены.
/mob/living/simple_animal/hostile/hk50/factory_guard/patrol
	ai_profile_type = /datum/ai_controller/hostile_adapter/ranged_skirmisher/hk50_patrol

/mob/living/simple_animal/hostile/hk50/factory_guard/patrol/LateInitialize()
	. = ..()
	if(ai_controller)
		ai_controller.blackboard[BB_HK50_PATROL_ENDS] = hk50_patrol_ends(get_turf(src))

/// Концы самого длинного прохода через turf: по горизонтали или вертикали, в пределах зоны.
/proc/hk50_patrol_ends(turf/start)
	if(!start)
		return null
	var/list/ends
	var/longest = 0
	for(var/list/axis in list(list(WEST, EAST), list(SOUTH, NORTH)))
		var/turf/first = hk50_patrol_reach(start, axis[1])
		var/turf/second = hk50_patrol_reach(start, axis[2])
		var/span = get_dist(first, second)
		if(span > longest)
			longest = span
			ends = list(first, second)
	return ends

/proc/hk50_patrol_reach(turf/start, direction)
	var/area/home = get_area(start)
	var/turf/reached = start
	for(var/i in 1 to HK_FACTORY_PATROL_REACH)
		var/turf/next = get_step(reached, direction)
		if(!next || get_area(next) != home || next.is_blocked_turf(TRUE))
			break
		reached = next
	return reached

/datum/ai_controller/hostile_adapter/ranged_skirmisher/hk50_patrol
	idle_behavior = /datum/idle_behavior/idle_random_walk/hk50_patrol

/// Шаг патруля к текущему концу маршрута; сбитый с маршрута страж бродит сам.
/datum/idle_behavior/idle_random_walk/hk50_patrol
	walk_chance = 60

/datum/idle_behavior/idle_random_walk/hk50_patrol/pick_idle_direction(mob/living/living_pawn, datum/ai_controller/controller)
	var/list/ends = controller.blackboard[BB_HK50_PATROL_ENDS]
	var/turf/here = get_turf(living_pawn)
	if(length(ends) != 2 || !here)
		return ..()
	var/turf/first = ends[1]
	var/turf/second = ends[2]
	var/on_route = first.y == second.y ? (here.y == first.y && here.x >= min(first.x, second.x) && here.x <= max(first.x, second.x)) : (here.x == first.x && here.y >= min(first.y, second.y) && here.y <= max(first.y, second.y))
	if(!on_route)
		return ..()
	var/heading = controller.blackboard[BB_HK50_PATROL_HEADING] || 2
	if(here == ends[heading])
		heading = 3 - heading
		controller.blackboard[BB_HK50_PATROL_HEADING] = heading
	return get_dir(here, ends[heading])

/obj/machinery/conveyor/hk_factory
	id = HK_FACTORY_BELT_ID

/obj/machinery/computer/hk_factory_console
	name = "HK factory control console"
	desc = "Пульт сборочного цеха HK. Один рубильник останавливает или снова запускает конвейеры, ленты и турели цеха. Без питания из щитовой пульт мёртв."
	icon = 'modular_bluemoon/icons/obj/hk_droids/factory.dmi'
	icon_state = "factory_console"
	icon_keyboard = null
	icon_screen = null
	unique_icon = TRUE
	idle_power_usage = 200
	var/lines_active = TRUE

/obj/machinery/computer/hk_factory_console/update_icon_state()
	if(machine_stat & NOPOWER)
		icon_state = "factory_console_nopower"
	else
		icon_state = lines_active ? "factory_console" : "factory_console_off"
	return ..()

/obj/machinery/computer/hk_factory_console/update_overlays()
	. = ..()
	if(!(machine_stat & NOPOWER))
		. += emissive_appearance(icon, "factory_console_glow", offset_spokesman = src)

/obj/machinery/computer/hk_factory_console/examine(mob/user)
	. = ..()
	var/area/factory = get_area(src)
	var/lines = length(hk_factory_lines(factory))
	var/turrets = length(hk_factory_members(GLOB.hk_factory_turrets, factory))
	var/state = lines_active ? "работают" : "остановлены"
	. += span_notice("Конвейеров в цехе: [lines], турелей: [turrets], сейчас они [state]. Нажмите на пульт, чтобы переключить всё сразу.")

/obj/machinery/computer/hk_factory_console/interact(mob/user)
	. = ..()
	toggle_lines(user)

/// Переключить конвейеры, ленты и турели своего цеха.
/obj/machinery/computer/hk_factory_console/proc/toggle_lines(mob/user)
	lines_active = !lines_active
	var/area/factory = get_area(src)
	var/list/lines = hk_factory_lines(factory)
	for(var/obj/machinery/hk_assembly_line/line as anything in lines)
		line.set_active(lines_active)
	for(var/obj/machinery/porta_turret/syndicate/energy/hk_factory/turret as anything in hk_factory_members(GLOB.hk_factory_turrets, factory))
		turret.toggle_on(lines_active)
	var/area/ruin/space/has_grav/hk_factory/plant = factory
	if(istype(plant))
		plant.production_active = lines_active
		hk_factory_update_belts(plant)
	update_appearance(UPDATE_ICON_STATE)
	playsound(src, lines_active ? 'sound/machines/terminal_prompt_confirm.ogg' : 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
	if(isnull(user))
		return
	var/action = lines_active ? "запускает" : "останавливает"
	var/self_action = lines_active ? "запускаете" : "останавливаете"
	user.visible_message(span_notice("[user] [action] цех с пульта фабрики."), span_notice("Вы [self_action] цех: конвейеров [length(lines)], ленты и турели вместе с ними."))

#undef HK_FACTORY_BELT_ID
#undef HK_FACTORY_VACANCY_CHECK
