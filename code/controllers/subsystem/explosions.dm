SUBSYSTEM_DEF(explosions)
	name = "Explosions"
	wait = 1
	flags = SS_TICKER
	priority = FIRE_PRIORITY_EXPLOSIONS
	var/static/list/datum/wave_explosion/wave_explosions = list()
	var/static/list/datum/wave_explosion/active_wave_explosions = list()
	var/static/list/datum/wave_explosion/currentrun = list()

/datum/controller/subsystem/explosions/last_task()
	return "взрывов в проходе [length(currentrun)] из [length(active_wave_explosions)]"

/datum/controller/subsystem/explosions/fire(resumed)
	if(!resumed)
		currentrun = active_wave_explosions.Copy()
	var/datum/wave_explosion/E
	for(var/i in currentrun)
		if(MC_TICK_CHECK)
			return
		E = i
		if(E.tick())
			currentrun -= E
