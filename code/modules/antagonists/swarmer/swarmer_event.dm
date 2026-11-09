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
	description = "Высаживает капсулу с ядром и оболочками свармеров в техтоннелях."

/datum/round_event/spawn_swarmer

/datum/round_event/spawn_swarmer/start()
	return launch_swarmer_pod(control, triggered_randomly ? control.cost : 0)

/proc/launch_swarmer_pod(datum/director_action/source_action, refund_cost)
	if(GLOB.active_swarmer_team)
		return FALSE

	// Те же картографические точки, что у события с фанклавами.
	var/list/landing_turfs = list()
	var/list/fallback_turfs = list()
	for(var/turf/open/floor/landing_turf in GLOB.xeno_spawn)
		if(!is_station_level(landing_turf.z) || landing_turf.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/datum/gas_mixture/air = landing_turf.return_air()
		var/oxygen = air?.get_moles(GAS_O2)
		var/temperature = air?.return_temperature()
		var/pressure = air?.return_pressure()
		if(oxygen < 16 || oxygen > 50 || air?.get_moles(GAS_PLASMA) || air?.get_moles(GAS_CO2) >= 10 || temperature <= 270 || temperature >= 360 || pressure <= 20 || pressure >= 550)
			fallback_turfs += landing_turf
		else
			landing_turfs += landing_turf
	if(!length(landing_turfs))
		landing_turfs = fallback_turfs
	if(!length(landing_turfs))
		message_admins("Для капсулы свармеров не нашлось подходящей точки высадки.")
		return MAP_ERROR

	var/datum/team/swarmer_team/team = new
	GLOB.active_swarmer_team = team
	var/obj/structure/closet/supplypod/swarmer/pod = new(null, team, source_action, refund_cost)
	new /obj/effect/pod_landingzone(pick(landing_turfs), pod)
	team.swarmer_core?.recruit_initial_swarmers()
	return SUCCESSFUL_SPAWN

/obj/structure/closet/supplypod/swarmer
	name = "Swarmer deploy pod"
	desc = "Капсула высадки роя свармеров."
	style = STYLE_SWARMER
	bluespace = TRUE
	delays = list(POD_TRANSIT = 3 SECONDS, POD_FALLING = 10 SECONDS, POD_OPENING = 3 SECONDS, POD_LEAVING = 3 SECONDS)
	specialised = TRUE
	explosionSize = list(0, 0, 0, 0)
	effectStealth = TRUE
	var/datum/team/swarmer_team/team

/obj/structure/closet/supplypod/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team, datum/director_action/source_action, refund_cost = 0)
	. = ..(mapload)
	if(!swarm_team)
		return
	team = swarm_team
	new /obj/structure/swarmer/core(src, team)
	for(var/direction in GLOB.alldirs)
		new /obj/structure/swarmer/blockade(src, team)
	for(var/index in 1 to 4)
		var/obj/effect/mob_spawn/swarmer/shell = new(src, team, TRUE)
		shell.director_source_action = source_action
		if(source_action)
			shell.director_intensity = source_action.intensity / 4
			shell.director_refund_cost = refund_cost / 4

/obj/structure/closet/supplypod/swarmer/preOpen()
	var/turf/landing_turf = get_turf(src)
	if(landing_turf && !QDELETED(team))
		swarmer_shield_around_turf(landing_turf, 2, 15 SECONDS, team)
	return ..()

/obj/structure/closet/supplypod/swarmer/setOpened()
	. = ..()
	var/turf/landing_turf = get_turf(src)
	if(QDELETED(team) || !landing_turf)
		return
	var/direction_index = 0
	for(var/obj/structure/swarmer/blockade/barricade in contents.Copy())
		var/turf/neighbor = get_step(landing_turf, GLOB.alldirs[++direction_index])
		if(istype(neighbor, /turf/open/floor) && !neighbor.is_blocked_turf(exclude_mobs = TRUE))
			barricade.forceMove(neighbor)
		else
			qdel(barricade)
	team = null

/obj/structure/closet/supplypod/swarmer/Destroy()
	QDEL_NULL(team)
	return ..()
