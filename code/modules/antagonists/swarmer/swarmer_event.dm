/datum/round_event_control/spawn_swarmer
	name = "Spawn Swarmer Shell"
	typepath = /datum/round_event/spawn_swarmer
	min_players = 30
	max_occurrences = 1
	weight = 8
	earliest_start = 30 MINUTES
	category = EVENT_CATEGORY_INVASION
	severity = DIRECTOR_SEVERITY_GHOST
	cost = 10
	intensity = 15
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM)
	family = "swarmers"
	description = "Высаживает капсулу с ядром и оболочками свармеров на станции."
	admin_setup = list(/datum/event_admin_setup/swarmer_landing)

/datum/round_event/spawn_swarmer
	var/turf/landing_turf

/datum/round_event/spawn_swarmer/start()
	return launch_swarmer_pod(control, triggered_randomly ? control.cost : 0, landing_turf)

/datum/event_admin_setup/swarmer_landing
	var/turf/landing_turf

/datum/event_admin_setup/swarmer_landing/prompt_admins()
	var/selection = select_swarmer_pod_landing(usr)
	if(selection == ADMIN_CANCEL_EVENT)
		return ADMIN_CANCEL_EVENT
	landing_turf = selection

/datum/event_admin_setup/swarmer_landing/apply_to_event(datum/round_event/spawn_swarmer/event)
	event.landing_turf = landing_turf
	landing_turf = null

/proc/select_swarmer_pod_landing(mob/admin)
	switch(tgui_alert(admin, "Куда сбросить капсулу свармеров?", "Высадка свармеров", list("Текущая клетка", "Случайная точка", "Отмена")))
		if("Текущая клетка")
			var/turf/landing_turf = get_turf(admin)
			if(is_swarmer_pod_landing_turf(landing_turf))
				return landing_turf
			to_chat(admin, span_warning("Для высадки выберите свободную клетку пола на станции."))
		if("Случайная точка")
			return null
	return ADMIN_CANCEL_EVENT

/proc/is_swarmer_pod_landing_turf(turf/landing_turf)
	return isfloorturf(landing_turf) && is_station_level(landing_turf.z) && !landing_turf.is_blocked_turf(exclude_mobs = TRUE)

/proc/launch_swarmer_pod(datum/director_action/source_action, refund_cost, turf/landing_turf)
	if(GLOB.active_swarmer_team)
		return FALSE

	if(landing_turf && !is_swarmer_pod_landing_turf(landing_turf))
		message_admins("Выбранная точка высадки свармеров больше недоступна.")
		return MAP_ERROR
	if(!landing_turf)
		landing_turf = pick_swarmer_pod_landing_turf()
	if(!landing_turf)
		message_admins("Для капсулы свармеров не нашлось подходящей точки высадки.")
		return MAP_ERROR

	var/datum/team/swarmer_team/team = new
	GLOB.active_swarmer_team = team
	var/obj/structure/closet/supplypod/swarmer/pod = new(null, team, source_action, refund_cost)
	new /obj/effect/pod_landingzone(landing_turf, pod)
	team.swarmer_core?.recruit_initial_swarmers()
	return SUCCESSFUL_SPAWN

/proc/pick_swarmer_pod_landing_turf()
	var/list/landing_turfs = list()
	var/list/fallback_turfs = list()
	for(var/turf/open/floor/landing_turf in GLOB.blobstart)
		if(!is_swarmer_pod_landing_turf(landing_turf))
			continue
		var/datum/gas_mixture/air = landing_turf.return_air()
		var/oxygen = air?.get_moles(GAS_O2)
		var/temperature = air?.return_temperature()
		var/pressure = air?.return_pressure()
		if(oxygen < SWARMER_POD_MIN_OXYGEN || oxygen > SWARMER_POD_MAX_OXYGEN || air?.get_moles(GAS_PLASMA) || air?.get_moles(GAS_CO2) >= SWARMER_POD_MAX_CO2 || temperature <= SWARMER_POD_MIN_TEMPERATURE || temperature >= SWARMER_POD_MAX_TEMPERATURE || pressure <= SWARMER_POD_MIN_PRESSURE || pressure >= SWARMER_POD_MAX_PRESSURE)
			fallback_turfs += landing_turf
		else
			landing_turfs += landing_turf
	if(length(landing_turfs))
		return pick(landing_turfs)
	if(length(fallback_turfs))
		return pick(fallback_turfs)

/obj/structure/closet/supplypod/swarmer
	name = "Swarmer deploy pod"
	desc = "Капсула высадки роя свармеров."
	style = STYLE_SWARMER
	bluespace = TRUE
	delays = list(POD_TRANSIT = 3 SECONDS, POD_FALLING = 10 SECONDS, POD_OPENING = 2 SECONDS, POD_LEAVING = 3 SECONDS)
	specialised = TRUE
	explosionSize = list(0, 0, 0, 0)
	effectStealth = TRUE
	var/datum/team/swarmer_team/team
	var/landing_shield_timer

/obj/structure/closet/supplypod/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team, datum/director_action/source_action, refund_cost = 0)
	. = ..(mapload)
	if(!swarm_team)
		return
	team = swarm_team
	new /obj/structure/swarmer/core(src, team)
	for(var/direction in GLOB.alldirs)
		new /obj/structure/swarmer/blockade(src, team)
	for(var/index in 1 to SWARMER_POD_SHELL_COUNT)
		var/obj/effect/mob_spawn/swarmer/shell = new(src, team, TRUE)
		shell.director_source_action = source_action
		if(source_action)
			shell.director_intensity = source_action.intensity / SWARMER_POD_SHELL_COUNT
			shell.director_refund_cost = refund_cost / SWARMER_POD_SHELL_COUNT

/obj/structure/closet/supplypod/swarmer/preOpen()
	var/turf/landing_turf = get_turf(src)
	if(landing_turf)
		for(var/mob/living/victim in range(SWARMER_POD_IMPACT_RADIUS, landing_turf))
			if(QDELETED(victim) || !isturf(victim.loc))
				continue
			victim.adjustBruteLoss(SWARMER_POD_IMPACT_DAMAGE)
			if(QDELETED(victim) || !isturf(victim.loc))
				continue
			var/direction = get_dir(landing_turf, victim) || pick(GLOB.alldirs)
			var/turf/destination = get_ranged_target_turf(victim, direction, SWARMER_POD_KNOCKBACK_RANGE)
			if(destination != victim.loc)
				qdel(victim.force_moving)
				new /datum/forced_movement(victim, destination, 3)
		if(!QDELETED(team))
			// Даём волне отбросить мобов за границу щита до его появления.
			landing_shield_timer = addtimer(CALLBACK(src, PROC_REF(deploy_landing_shield)), 1 SECONDS, TIMER_STOPPABLE)
	return ..()

/obj/structure/closet/supplypod/swarmer/proc/deploy_landing_shield()
	landing_shield_timer = null
	var/turf/landing_turf = get_turf(src)
	if(landing_turf && !QDELETED(team))
		swarmer_shield_around_turf(landing_turf, 2, 15 SECONDS, team)

/obj/structure/closet/supplypod/swarmer/setOpened()
	. = ..()
	var/turf/landing_turf = get_turf(src)
	if(QDELETED(team) || !landing_turf)
		return
	var/direction_index = 0
	for(var/obj/structure/swarmer/blockade/barricade in contents.Copy())
		var/turf/neighbor = get_step(landing_turf, GLOB.alldirs[++direction_index])
		if(neighbor)
			barricade.forceMove(neighbor)
		else
			qdel(barricade)
	team = null

/obj/structure/closet/supplypod/swarmer/Destroy()
	if(landing_shield_timer)
		deltimer(landing_shield_timer)
		landing_shield_timer = null
	QDEL_NULL(team)
	return ..()
