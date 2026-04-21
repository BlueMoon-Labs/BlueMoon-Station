/datum/bsm_instability_effect

/datum/bsm_instability_effect/proc/trigger(obj/machinery/mineral/bluespace_miner/machine)
	return

/datum/bsm_instability_effect/proc/play_bluespace_sparks(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/T = get_turf(machine)
	if(!T)
		return
	playsound(T, 'sound/effects/sparks4.ogg', 100, 1)
	var/datum/effect_system/spark_spread/quantum/sparks = new
	sparks.set_up(10, 1, T)
	sparks.attach(T)
	sparks.start()
