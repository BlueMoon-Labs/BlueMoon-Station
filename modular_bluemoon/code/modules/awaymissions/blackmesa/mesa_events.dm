// =============================================================================
// FORWARD DECLARATIONS
// =============================================================================
/datum/ai_director/zombie_mission

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

/obj/effect/landmark/awaymission/blackmesa/portal_spawn
	name = "Portal Storm Spawn Landmark"

/datum/round_event_control/blackmesa
	name = "Black Mesa: Base"
	typepath = /datum/round_event/blackmesa
	description = "Base control for Black Mesa events."
	weight = 0
	max_occurrences = 0
	category = EVENT_CATEGORY_INVASION
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

/datum/round_event/blackmesa/setup()
	. = ..()
	// Check if ihategordon is even loaded
	var/list/mission_areas = get_areas(/area/awaymission/ihategordon, TRUE)
	if(!mission_areas.len)
		return EVENT_CANCELLED

/datum/round_event/blackmesa/proc/get_mesa_areas()
	var/list/source_areas = get_areas(/area/awaymission/ihategordon, TRUE)
	var/list/areas = list()

	for(var/area/A in source_areas)
		if(!A || !A.contents.len)
			continue
		var/valid = TRUE
		for(var/EA in excluded_areas)
			if(ispath(A.type, EA))
				valid = FALSE
				break
		if(valid)
			areas += A
	return areas

/datum/round_event/blackmesa/proc/get_random_mesa_turf()
	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return null
	var/list/turfs = list()
	for(var/area/A in areas)
		turfs += get_area_turfs(A)
	if(!turfs.len)
		return null
	for(var/i in 1 to 30)
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

/datum/round_event/blackmesa/power_outage/start()
	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return

	SSblackmesa_events.mesa_announce("Внимание! Зафиксирован критический сбой в энергосети Сектора H. Ожидаемое время восстановления: 60 секунд.", "Power Grid Failure", 'modular_bluemoon/sound/ambience/mesa/lightoff.ogg')

	for(var/area/A in areas)
		A.power_light = FALSE
		A.power_equip = FALSE
		A.power_environ = FALSE
		A.lightswitch = FALSE
		A.power_change()
		addtimer(CALLBACK(src, .proc/restore_power, A), 600)

	addtimer(CALLBACK(src, .proc/announce_restoration), 600)

/datum/round_event/blackmesa/power_outage/proc/announce_restoration()
	SSblackmesa_events.mesa_announce("Внимание! Энергоснабжение Сектора H восстановлено. Все системы функционируют в штатном режиме.", "Power Restored", 'modular_bluemoon/sound/ambience/mesa/BMAS1.ogg')

/datum/round_event/blackmesa/power_outage/proc/restore_power(area/A)
	if(!A)
		return
	A.power_light = TRUE
	A.power_equip = TRUE
	A.power_environ = TRUE
	A.lightswitch = TRUE
	A.power_change()

// Event 2: Sandstorm (Cosmetic)
/datum/round_event_control/blackmesa/sandstorm
	name = "Black Mesa: Sandstorm"
	typepath = /datum/round_event/blackmesa/sandstorm
	weight = 3
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 0

/datum/round_event/blackmesa/sandstorm/start()
	var/turf/T = get_random_mesa_turf()
	if(!T)
		return

	SSweather.run_weather(/datum/weather/ash_storm/mesa_sandstorm, list(T.z))

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
	var/lockdown_duration = 0

/datum/round_event/blackmesa/lockdown/start()
	lockdown_duration = rand(300, 600)
	SSblackmesa_events.mesa_announce("ВНИМАНИЕ! АКТИВИРОВАНА СИСТЕМА АВАРИЙНОЙ БЛОКИРОВКИ! Все двери заблокированы на время экстренной ситуации!", "LOCKDOWN ACTIVATED", 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg')

	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return

	for(var/area/A in areas)
		var/list/turfs = get_area_turfs(A)
		if(!turfs.len)
			continue
		for(var/turf/T in turfs)
			for(var/obj/machinery/door/D in T.contents)
				if(!D.locked)
					D.locked = TRUE
					D.update_icon()
					locked_doors += D

	addtimer(CALLBACK(src, PROC_REF(end_lockdown)), lockdown_duration)

/datum/round_event/blackmesa/lockdown/proc/end_lockdown()
	for(var/obj/machinery/door/D in locked_doors)
		if(!QDELETED(D))
			D.locked = FALSE
			D.update_icon()

	locked_doors.Cut()
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

	var/list/alive_players = D.get_alive_players_in_mission()
	if(!alive_players || !alive_players.len)
		return

	var/threat_level = D.calculate_threat_level(alive_players.len)
	if(threat_level <= 0)
		return

	D.spawn_zombie_wave(threat_level, alive_players)
	D.last_wave_time = world.time
	D.current_wave_number++

