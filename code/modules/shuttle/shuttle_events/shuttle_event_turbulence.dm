/// Buckle up or get knocked down — runs during emergency shuttle hyperspace flight
/datum/shuttle_event/turbulence
	name = "Turbulence"
	event_probability = 50
	activation_fraction = 0.1
	var/minimum_interval = 20 SECONDS
	var/maximum_interval = 50 SECONDS
	COOLDOWN_DECLARE(turbulence_cooldown)
	var/warning_interval = 2 SECONDS

/datum/shuttle_event/turbulence/activate()
	. = ..()
	minor_announce("Внимание: участок субпространственной турбулентности. Пристегнитесь и оставайтесь на местах до полной остановки шаттла.",
		title = "Эвакуационный шаттл", alert = TRUE)
	COOLDOWN_START(src, turbulence_cooldown, rand(5 SECONDS, 20 SECONDS))

/datum/shuttle_event/turbulence/event_process()
	. = ..()
	if(!.)
		return
	if(!COOLDOWN_FINISHED(src, turbulence_cooldown))
		return
	COOLDOWN_START(src, turbulence_cooldown, rand(minimum_interval, maximum_interval))
	shake()
	addtimer(CALLBACK(src, PROC_REF(knock_down)), warning_interval, TIMER_DELETE_ME)

/datum/shuttle_event/turbulence/proc/shake()
	var/list/mobs = mobs_in_evac_shuttle(port)
	for(var/mob/living/mob as anything in mobs)
		var/shake_intensity = mob.buckled ? 0.25 : 1
		if(mob.client)
			shake_camera(mob, 3 SECONDS, shake_intensity)

/datum/shuttle_event/turbulence/proc/knock_down()
	if(!port || !SSshuttle.emergency || SSshuttle.emergency.mode != SHUTTLE_ESCAPE)
		return
	var/list/mobs = mobs_in_evac_shuttle(port)
	for(var/mob/living/mob as anything in mobs)
		if(mob.buckled)
			continue
		mob.Paralyze(3 SECONDS, ignore_canstun = TRUE)

/proc/mobs_in_evac_shuttle(obj/docking_port/mobile/port)
	RETURN_TYPE(/list)
	. = list()
	if(!port?.shuttle_areas)
		return
	for(var/mob/living/mob as anything in GLOB.mob_living_list)
		var/area/A = get_area(mob)
		if(!A || !port.shuttle_areas[A])
			continue
		. += mob

/// Turbulence variant: no stun — random throws from experimental mega-engine dodge thrusters.
/datum/shuttle_event/turbulence/evasive_maneuvers
	name = "Evasive Maneuvers"
	event_probability = 50

/datum/shuttle_event/turbulence/evasive_maneuvers/activate()
	minor_announce("Внимание: участок субпространственной турбулентности. Пристегнитесь и оставайтесь на местах до полной остановки шаттла. ШАТТЛ ИСПОЛЬЗУЕТ ЭКСПЕРИМЕНТАЛЬНУЮ СИСТЕМУ УВОРОТОВ.",
		title = "Эвакуационный шаттл", alert = TRUE)
	COOLDOWN_START(src, turbulence_cooldown, rand(5 SECONDS, 20 SECONDS))

/datum/shuttle_event/turbulence/evasive_maneuvers/knock_down()
	if(!port || !SSshuttle.emergency || SSshuttle.emergency.mode != SHUTTLE_ESCAPE)
		return
	var/list/mobs = mobs_in_evac_shuttle(port)
	for(var/mob/living/mob as anything in mobs)
		if(mob.buckled)
			continue
		var/turf/here = get_turf(mob)
		if(!here)
			continue
		var/direction = pick(GLOB.cardinals)
		var/turf/throw_target = get_step(here, direction)
		if(!throw_target || !throw_target.CanPass(mob, get_dir(here, throw_target)))
			throw_target = get_step(here, turn(direction, 180))
		if(!throw_target)
			continue
		mob.visible_message(span_warning("[mob] отлетает в сторону от резкого манёвра шаттла!"), span_userdanger("Резкий манёвр шаттла выбрасывает вас в сторону!"))
		mob.safe_throw_at(throw_target, rand(2, 5), rand(1, 3))
