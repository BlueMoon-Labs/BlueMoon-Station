// PORT: tgstation@14140a6355d1 code/controllers/subsystem/unplanned_controllers.dm
// Фоновое "брождение" активных контроллеров без текущего плана: у tg таких
// подсистем две (ON и IDLE), у нас одна - спящие контроллеры не обрабатываются.
/// Handles making mobs perform lightweight "idle" behaviors such as wandering around when they have nothing planned
SUBSYSTEM_DEF(unplanned_controllers)
	name = "Unplanned AI Controllers"
	flags = SS_POST_FIRE_TIMING|SS_BACKGROUND|SS_NO_INIT
	priority = FIRE_PRIORITY_IDLE_NPC
	wait = 0.25 SECONDS
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/currentrun = list()

/datum/controller/subsystem/unplanned_controllers/stat_entry(msg)
	msg = "Idle:[length(GLOB.unplanned_controllers)]"
	return ..()

/datum/controller/subsystem/unplanned_controllers/fire(resumed)
	if(!resumed)
		src.currentrun = GLOB.unplanned_controllers.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(length(currentrun))
		var/datum/ai_controller/unplanned = currentrun[currentrun.len]
		currentrun.len--
		if(!QDELETED(unplanned) && unplanned.idle_behavior)
			unplanned.idle_behavior.perform_idle_behavior(wait * 0.1, unplanned)
		if(MC_TICK_CHECK)
			return
