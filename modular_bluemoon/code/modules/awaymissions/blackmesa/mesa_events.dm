// =============================================================================
// FORWARD DECLARATIONS
// =============================================================================
/datum/ai_director/zombie_mission

/obj/effect/landmark/awaymission

/obj/effect/landmark/awaymission/blackmesa
	name = "Black Mesa Landmark"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"

/obj/effect/landmark/awaymission/blackmesa/blackops_spawn
	name = "Black Ops Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/hecu_spawn
	name = "HECU Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/hecu_ghost_spawn
	name = "HECU Ghost Squad Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/hecu_machinegunner_spawn
	name = "HECU Machinegunner Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/hecu_sniper_spawn
	name = "HECU Sniper Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/portal_spawn
	name = "Portal Storm Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/hecu_role_spawn
	name = "HECU role spawn landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER
	var/spawner_type

/obj/effect/landmark/awaymission/blackmesa/hecu_role_spawn/hecu
	name = "HECU grunt spawn landmark"
	spawner_type = /obj/effect/mob_spawn/human/black_mesa/hecu

/obj/effect/landmark/awaymission/blackmesa/hecu_role_spawn/breacher
	name = "HECU breacher spawn landmark"
	spawner_type = /obj/effect/mob_spawn/human/black_mesa/hecu/breacher

/obj/effect/landmark/awaymission/blackmesa/hecu_role_spawn/medic
	name = "HECU medic spawn landmark"
	spawner_type = /obj/effect/mob_spawn/human/black_mesa/hecu/medic

/obj/effect/landmark/awaymission/blackmesa/hecu_role_spawn/engineer
	name = "HECU engineer spawn landmark"
	spawner_type = /obj/effect/mob_spawn/human/black_mesa/hecu/engineer

/obj/effect/landmark/awaymission/blackmesa/hecu_role_spawn/leader
	name = "HECU leader spawn landmark"
	spawner_type = /obj/effect/mob_spawn/human/black_mesa/hecu/leader

// Лендмарки для карты: место особого пилона (испытание), выход из комплекса
// и точка в другой части комплекса - оба односторонние, без пути обратно.
/obj/effect/landmark/awaymission/blackmesa/nihilanth_pylon_site
	name = "Nihilanth Pylon Site Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER
	/// ID испытания, с которым связан этот лендмарк. Совпадает с site_id
	/// пилона /obj/structure/xen_pylon/nihilanth. null = авто-привязка по z.
	var/site_id = null
	/// Лендмарк исчерпан: связанный пилон уничтожен, точка больше не активна.
	var/site_used = FALSE

/obj/effect/landmark/awaymission/blackmesa/nihilanth_pylon_site/Initialize(mapload)
	. = ..()
	GLOB.nihilanth_sites += src
	GLOB.nihilanth_site_ids[src] = site_id

/obj/effect/landmark/awaymission/blackmesa/nihilanth_pylon_site/Destroy()
	GLOB.nihilanth_sites -= src
	GLOB.nihilanth_site_ids -= src
	GLOB.nihilanth_site_used -= src
	..()

/obj/effect/landmark/awaymission/blackmesa/nihilanth_exit
	name = "Nihilanth Exit Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/nihilanth_complex
	name = "Nihilanth Complex Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/datum/antagonist/ghost_role/mesa_hecu_war
	name = "HECU War Reinforcements"

/datum/antagonist/ghost_role/mesa_hecu_war/on_gain()
	. = ..()
	var/datum/objective/custom/objective = new("Уничтожить экспедиторов и учёных Чёрной Мезы, находившихся в Секторе H в момент объявления войны.")
	objective.owner = owner
	objectives += objective
	owner.announce_objectives()
	if(SSblackmesa_events && owner?.current)
		SSblackmesa_events.mesa_ghost_role_reminder(owner.current)

/datum/antagonist/ghost_role/mesa_blackops_assault
	name = "Black Ops Sector H Assault"

/datum/antagonist/ghost_role/mesa_blackops_assault/on_gain()
	. = ..()
	var/datum/objective/custom/objective = new("Убить всех находящихся в гейте Сектора H.")
	objective.owner = owner
	objectives += objective
	owner.announce_objectives()
	if(SSblackmesa_events && owner?.current)
		SSblackmesa_events.mesa_ghost_role_reminder(owner.current)

/datum/round_event_control/blackmesa
	name = "Black Mesa: Base"
	typepath = /datum/round_event/blackmesa
	description = "Base control for Black Mesa events."
	weight = 0
	max_occurrences = 0
	category = EVENT_CATEGORY_INVASION
	// Мезовые ивенты крутит только SSblackmesa_events и только при живых игроках в гейте.
	// severity=FLAVOR обнуляет cost/intensity/linger в New(), а директор вообще не регистрирует
	// эти контроли (register_event_actions их пропускает) - они не едят бюджет, не висят
	// в intensity_ledger и не попадают в угрозу SSactivity.
	severity = DIRECTOR_SEVERITY_FLAVOR
	var/min_difficulty_level = 0 // Minimum difficulty level required for this event

/datum/round_event/blackmesa
	var/list/excluded_areas = list(
		/area/awaymission/ihategordon/hecu_abandoned_camp,
		/area/awaymission/ihategordon/rocks,
		/area/awaymission/ihategordon/outsideofmesa,
		/area/awaymission/ihategordon/secret_rooms,
		/area/awaymission/ihategordon/tram_tunnel,
		/area/awaymission/ihategordon/entrance
	)
	// Состав ihategordon-area статичен на раунд. get_areas() сканирует все
	// area станции и вызывался на каждый ивент - давал ~50мс на старте.
	var/static/list/cached_source_areas = null
	var/static/list/cached_valid_areas = null

/datum/round_event/blackmesa/proc/get_source_areas() as /list
	if(isnull(cached_source_areas) || !cached_source_areas.len) {
		var/list/fresh = get_areas(/area/awaymission/ihategordon, TRUE)
		if(fresh.len)
			cached_source_areas = fresh
		else
			return list()
	}
	return cached_source_areas

/datum/round_event/blackmesa/setup()
	. = ..()
	// Check if ihategordon is even loaded
	if(!get_source_areas().len)
		return EVENT_CANCELLED

/datum/round_event/blackmesa/proc/get_mesa_areas()
	if(cached_valid_areas)
		return cached_valid_areas.Copy()
	var/list/areas = list()

	for(var/area/A in get_source_areas())
		if(!A || QDELETED(A) || !A.contents.len)
			continue
		var/valid = TRUE
		for(var/EA in excluded_areas)
			if(ispath(A.type, EA))
				valid = FALSE
				break
		if(valid)
			areas += A
	if(areas.len)
		cached_valid_areas = areas
	return areas.Copy()

/datum/round_event/blackmesa/proc/get_random_mesa_turf()
	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return null
	// Pick a random area first, then a random turf inside it - avoids
	// concatenating every turf of every Mesa area into one giant list.
	for(var/i in 1 to 10)
		var/area/A = pick(areas)
		var/list/turfs = get_area_turfs(A)
		if(!turfs.len)
			continue
		for(var/j in 1 to 10)
			var/turf/T = pick(turfs)
			if(T && istype(T, /turf/open) && !is_blocked_turf(T))
				return T
	return null

/datum/round_event/blackmesa/proc/get_player_mesa_turf(ignore_hecu = FALSE, radius_min = 5, radius_max = 12)
	var/list/valid_players = list()
	var/list/valid_areas = get_mesa_areas()

	for(var/mob/living/L in GLOB.player_list)
		if(!L.client || L.stat == DEAD)
			continue
		var/area/A = get_area(L)
		if(!(A in valid_areas))
			continue
		if(ignore_hecu && (FACTION_HECU in L.faction))
			continue
		valid_players += L

	if(!valid_players.len)
		return get_random_mesa_turf()

	for(var/i in 1 to 10)
		var/mob/living/target = pick(valid_players)
		var/turf/center = get_turf(target)
		var/list/nearby_turfs = RANGE_TURFS(rand(radius_min, radius_max), center)
		if(!nearby_turfs.len)
			continue
		var/turf/T = pick(nearby_turfs)
		if(T && istype(T, /turf/open) && !is_blocked_turf(T) && (get_area(T) in valid_areas))
			return T

	return get_random_mesa_turf()

/datum/round_event/blackmesa/proc/get_safe_spawn_turf(turf/T)
	if(!T)
		return null
	if(istype(T, /turf/open) && !is_blocked_turf(T))
		return T
	for(var/dir in GLOB.alldirs)
		var/turf/neighbor = get_step(T, dir)
		if(neighbor && istype(neighbor, /turf/open) && !is_blocked_turf(neighbor))
			return neighbor
	return null

// Event 1: Power Outage
/datum/round_event_control/blackmesa/power_outage
	name = "Black Mesa: Power Outage"
	typepath = /datum/round_event/blackmesa/power_outage
	description = "Causes a temporary power failure in Sector H."
	weight = 5
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 1

/datum/round_event/blackmesa/power_outage
	var/list/pending_areas = list()
	var/list/restore_areas = list()
	var/list/outage_lights = list()
	/// Состояние каждой зоны ДО сбоя: assoc area -> list(power_light,
	/// power_equip, power_environ, lightswitch). 4 bool'а на зону -
	/// память и тики не растут, зоны у нас считаются штуками.
	var/outage_state = alist()

/datum/round_event/blackmesa/power_outage/start()
	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return

	if(SSblackmesa_events)
		SSblackmesa_events.mesa_announce("Внимание! Зафиксирован критический сбой в энергосети Сектора H. Ожидаемое время восстановления: 60 секунд.", "Power Grid Failure", 'modular_bluemoon/sound/ambience/mesa/lightoff.ogg')

	// Гасим по одной зоне за тик: power_change() рассылает COMSIG_AREA_POWER_CHANGE
	// всем машинам области, и все области Сектора H разом - это 60+ мс в одном тике.
	pending_areas = areas
	restore_areas = areas.Copy()
	// Запоминаем исходные флаги питания/выключателя каждой зоны - после
	// сбоя возвращаем именно их, а не безусловные TRUE.
	for(var/area/A in areas)
		outage_state[A] = list(A.power_light, A.power_equip, A.power_environ, A.lightswitch)
	collect_outage_lights(areas)
	power_outage_step()

	addtimer(CALLBACK(src, PROC_REF(announce_restoration)), 600)

/datum/round_event/blackmesa/power_outage/proc/power_outage_step()
	if(!pending_areas.len)
		return
	var/area/A = pending_areas[1]
	pending_areas -= A
	A.power_light = FALSE
	A.power_equip = FALSE
	A.power_environ = FALSE
	A.lightswitch = FALSE
	A.power_change()
	if(pending_areas.len)
		addtimer(CALLBACK(src, PROC_REF(power_outage_step)), 1)
	else
		addtimer(CALLBACK(src, PROC_REF(restore_power_step)), 600)

/datum/round_event/blackmesa/power_outage/proc/restore_power_step()
	if(!restore_areas.len)
		return
	var/area/A = restore_areas[1]
	restore_areas -= A
	var/list/saved = outage_state[A]
	if(islist(saved) && length(saved) >= 4 && !QDELETED(A))
		// Возвращаем ровно то, что было до сбоя: зона с выключенным светом
		// или ручным lightswitch=FALSE остаётся в своём состоянии.
		A.power_light = saved[1]
		A.power_equip = saved[2]
		A.power_environ = saved[3]
		A.lightswitch = saved[4]
		A.power_change()
	outage_state -= A
	if(restore_areas.len)
		addtimer(CALLBACK(src, PROC_REF(restore_power_step)), 1)
	else
		restore_all_light_charges()

/datum/round_event/blackmesa/power_outage/proc/announce_restoration()
	if(SSblackmesa_events)
		SSblackmesa_events.mesa_announce("Внимание! Энергоснабжение Сектора H восстановлено. Все системы функционируют в штатном режиме.", "Power Restored", 'modular_bluemoon/sound/ambience/mesa/BMAS1.ogg')

// Светильники собираем одним проходом по machines_by_type - только
// /obj/machinery/light и подтипы, вместо скана всех 35к машин станции в GLOB.machines.
/datum/round_event/blackmesa/power_outage/proc/collect_outage_lights(list/areas)
	var/lookup = alist()
	for(var/area/A in areas)
		lookup[A] = TRUE
	// Дешёвый отсев по z до get_area(): свет station-wide, а миссия на своих z.
	var/zones = SSblackmesa_events ? SSblackmesa_events.mesa_mission_zset() : null
	for(var/obj/machinery/light/L in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/light))
		if(QDELETED(L) || !L.cell || !L.cell.maxcharge)
			continue
		if(zones && !(L.cell.z in zones))
			continue
		var/area/LA = get_area(L)
		if(LA && lookup[LA])
			outage_lights += L

/datum/round_event/blackmesa/power_outage/proc/restore_all_light_charges()
	for(var/obj/machinery/light/L as anything in outage_lights)
		if(!QDELETED(L) && L.cell && L.cell.maxcharge)
			L.cell.charge = L.cell.maxcharge
	outage_lights.Cut()

// Event 9: Lockdown
/datum/round_event_control/blackmesa/lockdown
	name = "Black Mesa: Lockdown"
	typepath = /datum/round_event/blackmesa/lockdown
	description = "Triggers a facility lockdown, bolting all doors."
	weight = 4
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 2

/datum/round_event/blackmesa/lockdown
	var/list/locked_doors = list()
	var/list/pending_doors = list()
	var/lockdown_duration = 0

/datum/round_event/blackmesa/lockdown/start()
	lockdown_duration = rand(300, 600)
	if(SSblackmesa_events)
		SSblackmesa_events.mesa_announce("ВНИМАНИЕ! АКТИВИРОВАНА СИСТЕМА АВАРИЙНОЙ БЛОКИРОВКИ! Все двери заблокированы на время экстренной ситуации!", "LOCKDOWN ACTIVATED", 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg')

	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return

	// Шлюзы берём из SSmachines по типу: один проход по machines_by_type
	// вместо скана GLOB.machines + GLOB.airlocks (десятки тысяч машин станции).
	// /obj/machinery/door/poddoor - не подтип airlock, "поддвери" в выборку
	// не попадают и не трогаются.
	var/lookup = alist()
	for(var/area/A in areas)
		lookup[A] = TRUE
	var/zones = SSblackmesa_events ? SSblackmesa_events.mesa_mission_zset() : null
	for(var/obj/machinery/door/airlock/D in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/door/airlock))
		if(QDELETED(D) || D.locked)
			continue
		var/turf/DT = get_turf(D)
		if(zones && DT && !(DT.z in zones))
			continue
		var/area/A = get_area(D)
		if(A && lookup[A])
			pending_doors += D

	bolt_doors_step()
	addtimer(CALLBACK(src, PROC_REF(end_lockdown)), lockdown_duration)

// Болтим пачками по таймеру, как spawn_wave_step у зомби-директора - не вешаем
// update_icon() сотен дверей в один тик.
/datum/round_event/blackmesa/lockdown/proc/bolt_doors_step()
	if(!pending_doors.len)
		return
	var/batch = min(rand(10, 20), pending_doors.len)
	for(var/i in 1 to batch)
		var/obj/machinery/door/airlock/D = pending_doors[1]
		pending_doors -= D
		if(QDELETED(D) || D.locked)
			continue
		D.locked = TRUE
		D.update_icon()
		locked_doors += D
	if(pending_doors.len)
		addtimer(CALLBACK(src, PROC_REF(bolt_doors_step)), 1)

/datum/round_event/blackmesa/lockdown/proc/end_lockdown()
	// Если локдаун кончился раньше, чем долетела очередь болтов - не даём
	// запоздавшим шагам закрыть двери после "Lockdown Ended".
	pending_doors.Cut()
	for(var/obj/machinery/door/D in locked_doors)
		if(!QDELETED(D))
			D.locked = FALSE
			D.update_icon()

	locked_doors.Cut()
	if(SSblackmesa_events)
		SSblackmesa_events.mesa_announce("Система аварийной блокировки отключена. Все двери разблокированы.", "Lockdown Ended", 'modular_bluemoon/sound/ambience/mesa/BMAS1.ogg')

// Event 11: Zombie Horde
/datum/round_event_control/blackmesa/zombie_horde
	name = "Black Mesa: Zombie Horde"
	typepath = /datum/round_event/blackmesa/zombie_horde
	description = "Triggers a zombie horde wave through the AI Director."
	weight = 8
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 0

/datum/round_event/blackmesa/zombie_horde
	start_when = 1
	end_when = 2

/datum/round_event/blackmesa/zombie_horde/start()
	if(!src)
		return
	if(!GLOB.zombie_director)
		return

	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		return

	D.trigger_horde()
