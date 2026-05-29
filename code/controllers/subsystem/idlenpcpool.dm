SUBSYSTEM_DEF(idlenpcpool)
	name = "Idling NPC Pool"
	flags = SS_POST_FIRE_TIMING|SS_BACKGROUND|SS_NO_INIT
	priority = FIRE_PRIORITY_IDLE_NPC
	wait = 60
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/currentrun = list()
	var/static/list/idle_mobs_by_zlevel[][]

/datum/controller/subsystem/idlenpcpool/stat_entry(msg)
	var/list/idlelist = GLOB.simple_animals[AI_IDLE]
	var/list/zlist = GLOB.simple_animals[AI_Z_OFF]
	msg = "IdleNPCS:[length(idlelist)]|Z:[length(zlist)]"
	return ..()

/datum/controller/subsystem/idlenpcpool/proc/MaxZChanged()
	if (!islist(idle_mobs_by_zlevel))
		idle_mobs_by_zlevel = new /list(world.maxz,0)
	while (SSidlenpcpool.idle_mobs_by_zlevel.len < world.maxz)
		SSidlenpcpool.idle_mobs_by_zlevel.len++
		SSidlenpcpool.idle_mobs_by_zlevel[idle_mobs_by_zlevel.len] = list()

/datum/controller/subsystem/idlenpcpool/fire(resumed = FALSE)

	if (!resumed)
		var/list/idlelist = GLOB.simple_animals[AI_IDLE]
		src.currentrun = idlelist.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	var/list/clients_by_z = SSmobs.clients_by_zlevel

	while(currentrun.len)
		var/mob/living/simple_animal/SA = currentrun[currentrun.len]
		--currentrun.len
		if (QDELETED(SA))
			GLOB.simple_animals[AI_IDLE] -= SA
			log_world("Found a null in simple_animals list!")
			continue

		if(SA.ckey)
			continue

		// Layer 1: Z-level check — no players on this z-level, deep sleep
		var/turf/mob_turf = get_turf(SA)
		if(!mob_turf)
			continue
		if(!length(clients_by_z[mob_turf.z]))
			SA.toggle_ai(AI_Z_OFF)
			continue

		// Layer 2: Proximity check — no player within range, skip entirely
		if(!SA.has_nearby_player())
			continue

		// Layer 3: Dead mob skip
		if(SA.stat == DEAD)
			continue

		SA.handle_automated_movement()
		SA.consider_wakeup()

		if (MC_TICK_CHECK)
			return
