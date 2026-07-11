/datum/round_event_control/vox_scavengers
	name = "Vox Scavengers"
	typepath = /datum/round_event/vox_scavengers
	admin_only = TRUE
	max_occurrences = 1
	min_players = 30
	earliest_start = 15 MINUTES
	category = EVENT_CATEGORY_INVASION
	// Гост-команда со своего корабля: admin-only, но при форсе обязана считаться
	// антаг-нагрузкой гост-пула, а не MAJOR по дефолту категории INVASION (ср. devil).
	severity = DIRECTOR_SEVERITY_GHOST
	cost = 10
	intensity = 15
	description = "A vox scavengers heist."
	var/ship_template

/datum/round_event_control/vox_scavengers/preRunEvent(admin_window = TRUE)
	if (!SSmapping.empty_space)
		return EVENT_CANT_RUN

	return ..()

/datum/round_event/vox_scavengers/start()
	spawn_vox_scavengers()

/proc/spawn_vox_scavengers(ship_template)

	ship_template = /datum/map_template/shuttle/vox_raiders

	var/datum/map_template/shuttle/ship = new ship_template
	var/x = rand(TRANSITIONEDGE,world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE,world.maxy - TRANSITIONEDGE - ship.height)
	var/z = SSmapping.empty_space.z_value
	var/turf/T = locate(x,y,z)
	if(!T)
		CRASH("Skipjack found no turf to load in")

	if(!ship.load(T))
		CRASH("Loading Skipjack ship failed!")

	var/list/spawners_list = list()
	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/human/vox_scavenger/spawner in A)
			spawners_list += spawner

	var/list/candidates = pollGhostCandidates("Do you wish to be considered for Vox Scavengers?", ROLE_TRAITOR, minimum_required = spawners_list.len)

	for(var/obj/effect/mob_spawn/human/spawner in spawners_list)
		if(LAZYLEN(candidates))
			var/mob/our_candidate = pick_n_take(candidates)
			spawner.create(our_candidate.ckey)
			notify_ghosts("Skipjack has an object of interest: [our_candidate]!", source=our_candidate, action=NOTIFY_ORBIT, header="Something's Interesting!")
		else
			notify_ghosts("Skipjack ship has an object of interest: [spawner]!", source=spawner, action=NOTIFY_ORBIT, header="Something's Interesting!")

/// Dynamic ruleset additions
/datum/dynamic_ruleset/midround/vox_scavengers
	name = "Vox Scavengers"
	severity = DIRECTOR_SEVERITY_GHOST // событие поллит призраков, экипаж не тратится
	antag_flag = "Vox Scavengers"
	required_type = /mob/dead/observer
	enemy_roles = list("Security Officer", "Detective", "Head of Security","Bridge Officer", "Captain")
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT)
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 0
	weight = 3
	cost = 12
	intensity = 15
	requirements = list(101,101,101,40,30,20,10,10,10,10)
	repeatable = FALSE

/datum/dynamic_ruleset/midround/vox_scavengers/acceptable(population=0, threat=0)
	if (!SSmapping.empty_space)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/vox_scavengers/execute()
	spawn_vox_scavengers()
	return ..()

// name совпадает с /datum/round_event_control/vox_scavengers ("Vox Scavengers"), который этот
// рулсет сам же и запускает через spawn_vox_scavengers() - без суффикса они делили бы
// ключ конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/vox_scavengers/action_name()
	return "[name] (Ruleset)"
