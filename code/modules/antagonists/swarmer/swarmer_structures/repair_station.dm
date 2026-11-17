#define SWARMER_REPAIR_STATION_HEAL 5

/obj/structure/swarmer/repair_station
	name = "swarmer repair station"
	desc = "Ремонтная станция \"Свармеров\"."
	icon_state = "repair_station"
	swarmer_examine = "Чтобы начать ремонт, встаньте на клетку закреплённой станции."
	max_integrity = 100
	density = FALSE
	var/datum/weakref/repair_target
	var/heal_per_tick = SWARMER_REPAIR_STATION_HEAL
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_EXITED = PROC_REF(on_exited),
	)
	var/static/list/target_signals = list(COMSIG_MOB_CLIENT_LOGOUT, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING)

/obj/structure/swarmer/repair_station/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	AddElement(/datum/element/connect_loc, loc_connections)
	RegisterSignals(src, list(COMSIG_MOVABLE_MOVED, COMSIG_OBJ_SETANCHORED), PROC_REF(on_station_changed))
	repair_swarmer_on_tile()

/obj/structure/swarmer/repair_station/Destroy(force)
	stop_repair()
	UnregisterSignal(src, list(COMSIG_MOVABLE_MOVED, COMSIG_OBJ_SETANCHORED))
	RemoveElement(/datum/element/connect_loc, loc_connections)
	return ..()

/obj/structure/swarmer/repair_station/emp_act(severity)
	. = ..()
	if(!QDELETED(src) && !(. & EMP_PROTECT_SELF) && severity <= 1)
		stop_repair()

/obj/structure/swarmer/repair_station/update_icon_state()
	icon_state = repair_target ? "[initial(icon_state)]_a" : initial(icon_state)

/obj/structure/swarmer/repair_station/update_overlays()
	. = ..()
	if(repair_target)
		. += image(icon = 'icons/effects/swarmer.dmi', icon_state = "repair_effect", layer = ABOVE_ALL_MOB_LAYER)

/obj/structure/swarmer/repair_station/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!repair_target && isswarmer(arrived))
		start_repair(arrived)

/obj/structure/swarmer/repair_station/proc/on_exited(datum/source, atom/movable/departed)
	SIGNAL_HANDLER
	if(repair_target)
		on_target_left(departed)

/obj/structure/swarmer/repair_station/proc/on_station_changed()
	SIGNAL_HANDLER
	stop_repair()
	repair_swarmer_on_tile()

/obj/structure/swarmer/repair_station/proc/on_target_left(datum/source)
	SIGNAL_HANDLER
	if(source != repair_target?.hard_resolve())
		return
	stop_repair()
	repair_swarmer_on_tile(source)

/obj/structure/swarmer/repair_station/proc/repair_swarmer_on_tile(mob/living/simple_animal/hostile/swarmer/excluded)
	if(QDELETED(src) || !anchored || !isturf(loc) || repair_target)
		return
	for(var/mob/living/simple_animal/hostile/swarmer/swarmer in loc)
		if(swarmer != excluded && start_repair(swarmer))
			return

/obj/structure/swarmer/repair_station/proc/can_repair_swarmer(mob/living/simple_animal/hostile/swarmer/swarmer)
	return !QDELETED(swarmer) && anchored && isturf(loc) && swarmer.loc == loc && swarmer.stat != DEAD \
		&& (!team || team == swarmer.team) && swarmer.health < swarmer.maxHealth

/obj/structure/swarmer/repair_station/proc/start_repair(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(repair_target || QDELETED(src) || !can_repair_swarmer(swarmer))
		return FALSE
	repair_target = WEAKREF(swarmer)
	RegisterSignals(swarmer, target_signals, PROC_REF(on_target_left))
	update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)
	START_PROCESSING(SSobj, src)
	return TRUE

/obj/structure/swarmer/repair_station/swarmer_disarm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!repair_target)
		return ..()

	swarmer.balloon_alert(swarmer, "занято, не починить!")

/obj/structure/swarmer/repair_station/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!repair_target)
		return ..()

	swarmer.balloon_alert(swarmer, "занято, не открепить!")

/obj/structure/swarmer/repair_station/swarmer_harm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!repair_target)
		return ..()

	swarmer.balloon_alert(swarmer, "занято, не уничтожить!")

/obj/structure/swarmer/repair_station/process(seconds_per_tick)
	if(!repair_target)
		return PROCESS_KILL
	var/mob/living/simple_animal/hostile/swarmer/swarmer = repair_target.resolve()
	if(can_repair_swarmer(swarmer))
		swarmer.adjustHealth(-heal_per_tick)
		if(repair_target?.resolve() != swarmer || swarmer.health < swarmer.maxHealth)
			return
	if(swarmer && swarmer.health >= swarmer.maxHealth)
		to_chat(swarmer, span_notice("Ремонт завершён."))
	stop_repair()
	repair_swarmer_on_tile()

/obj/structure/swarmer/repair_station/proc/stop_repair()
	if(!repair_target)
		return
	var/mob/living/simple_animal/hostile/swarmer/swarmer = repair_target.hard_resolve()
	if(swarmer)
		UnregisterSignal(swarmer, target_signals)
	repair_target = null
	STOP_PROCESSING(SSobj, src)
	if(!QDELETED(src))
		update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)

#undef SWARMER_REPAIR_STATION_HEAL
