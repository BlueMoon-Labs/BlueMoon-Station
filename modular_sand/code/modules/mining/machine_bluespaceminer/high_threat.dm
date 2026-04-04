#define BSM_HIGH_WEIGHT_ANOMALY 10
#define BSM_HIGH_WEIGHT_TEAR 10
#define BSM_HIGH_WEIGHT_PORTAL 10
#define BSM_HIGH_WEIGHT_SPAWNER 10
#define BSM_HIGH_WEIGHT_METEOR 5
#define BSM_HIGH_WEIGHT_CORE_EXPLOSION 15
#define BSM_HIGH_WEIGHT_RARE_ITEM 1

#define BSM_HIGH_THREAT_METEOR "bsm_high_threat_aimed_meteor"
#define BSM_HIGH_THREAT_CORE_EXPLOSION "bsm_high_threat_core_explosion"
#define BSM_HIGH_THREAT_SUPERMATTER_SWORD "bsm_high_threat_supermatter_sword"
#define BSM_HIGH_THREAT_PLASMA_RIFLE "bsm_high_threat_plasma_rifle"
#define BSM_HIGH_THREAT_TEAR "bsm_high_threat_dimensional_tear"

/proc/bsm_get_high_threat_pool()
	var/static/list/pool
	if(pool)
		return pool
	pool = list()
	for(var/anom_type in subtypesof(/datum/round_event_control/anomaly))
		pool[anom_type] = BSM_HIGH_WEIGHT_ANOMALY
	pool[/datum/round_event_control/anomaly/tear] = BSM_HIGH_WEIGHT_TEAR
	var/static/list/portal_storms = list(
		/datum/round_event_control/portal_storm_inteq,
		/datum/round_event_control/portal_storm_narsie,
		/datum/round_event_control/portal_storm_clown,
		/datum/round_event_control/portal_storm_necros,
		/datum/round_event_control/portal_storm_funclaws,
		/datum/round_event_control/portal_storm_clock,
	)
	for(var/path in portal_storms)
		pool[path] = BSM_HIGH_WEIGHT_PORTAL
	for(var/spawner_path in subtypesof(/datum/round_event_control/spawners))
		pool[spawner_path] = BSM_HIGH_WEIGHT_SPAWNER
	pool[BSM_HIGH_THREAT_METEOR] = BSM_HIGH_WEIGHT_METEOR
	pool[BSM_HIGH_THREAT_CORE_EXPLOSION] = BSM_HIGH_WEIGHT_CORE_EXPLOSION
	pool[BSM_HIGH_THREAT_SUPERMATTER_SWORD] = BSM_HIGH_WEIGHT_RARE_ITEM
	pool[BSM_HIGH_THREAT_PLASMA_RIFLE] = BSM_HIGH_WEIGHT_RARE_ITEM
	return pool

/proc/bsm_spawn_rare_weapon_from_instability(obj/machinery/mineral/bluespace_miner/machine, obj/item/spawn_type)
	if(QDELETED(machine) || !spawn_type)
		return
	var/turf/drop = get_turf(machine)
	if(!drop)
		return
	playsound(machine, 'sound/effects/bamf.ogg', 72, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	do_sparks(4, TRUE, machine)
	var/obj/item/loot = new spawn_type(drop)
	loot.forceMove(drop)
	machine.visible_message(span_bolddanger("Реальность рвётся — из-под [machine] вылетает [loot]!"))

/proc/bsm_spawn_meteor_at_miner(obj/machinery/mineral/bluespace_miner/machine)
	if(QDELETED(machine))
		return
	var/turf/target = get_turf(machine)
	if(!target)
		return
	var/z = target.z
	var/startSide = pick(GLOB.cardinals)
	var/turf/pickedstart = spaceDebrisStartLoc(startSide, z)
	if(!pickedstart)
		return
	var/directionstring = "из неизвестного направления"
	switch(startSide)
		if(NORTH)
			directionstring = "с северной стороны"
		if(SOUTH)
			directionstring = "с южной стороны"
		if(EAST)
			directionstring = "с восточной стороны"
		if(WEST)
			directionstring = "с западной стороны"
	var/area/impact_area = get_area(target)
	var/area_name = impact_area?.name || "неизвестный сектор"
	priority_announce(
		"Крупный метеорит зафиксирован на курсе столкновения с [station_name()] — подход [directionstring]. Сенсоры связывают объект с нестабильностью блюспейс-майнеров; ожидаемая зона поражения: [area_name]. Инженерному отделу: подготовить ремонтные бригады.",
		"ВНИМАНИЕ: МЕТЕОРЫ",
		"meteors",
		has_important_message = TRUE,
	)
	new /obj/effect/meteor/tunguska/bsm_cataclysm(pickedstart, machine)

/proc/bsm_catastrophic_miner_explosion(obj/machinery/mineral/bluespace_miner/machine)
	if(QDELETED(machine))
		return
	var/turf/T = get_turf(machine)
	if(!T)
		return
	var/area/impact_area = get_area(T)
	var/area_name = impact_area?.name || "неизвестный сектор"
	priority_announce(
		"Каскадное блюспейс-разрушение в [area_name]. Силовой контур блюспейс-майнера [station_name()] теряет стабильность — ожидается детонация. Эвакуируйте персонал из зоны и готовьте инженерный ответ.",
		"ВНИМАНИЕ: КРИТИЧЕСКИЙ СБОЙ БЛЮСПЕЙС-МАЙНЕРА",
		'sound/machines/nuke/confirm_beep.ogg',
		has_important_message = TRUE,
	)
	machine.balloon_alert_to_viewers("КАТАСТРОФИЧЕСКИЙ СБОЙ СИЛОВОГО КОНТУРА!")
	playsound(T, 'sound/machines/nuke/confirm_beep.ogg', 65, TRUE, 1)
	do_sparks(3, TRUE, machine)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(bsm_explosion_miner_finish), machine), 2 SECONDS)

/proc/bsm_explosion_miner_finish(obj/machinery/mineral/bluespace_miner/machine)
	if(QDELETED(machine))
		return
	var/turf/T = get_turf(machine)
	if(!T)
		qdel(machine)
		return
	explosion(T, 2, 4, 5, 8)
	if(!QDELETED(machine))
		qdel(machine)

/proc/bsm_balloon_anomaly_from_miner(obj/machinery/mineral/bluespace_miner/machine)
	if(QDELETED(machine))
		return
	machine.balloon_alert_to_viewers(pick(
		"аномалия из разлома!",
		"искажение поля!",
		"блюспейс трещит!",
	))
/proc/bsm_fire_high_threat_pick(obj/machinery/mineral/bluespace_miner/machine, picked)
	if(picked == BSM_HIGH_THREAT_METEOR)
		bsm_spawn_meteor_at_miner(machine)
		bsm_log_instability(machine, "high", "aimed meteor at miner")
		return
	if(picked == BSM_HIGH_THREAT_CORE_EXPLOSION)
		bsm_catastrophic_miner_explosion(machine)
		bsm_log_instability(machine, "high", "catastrophic miner explosion")
		return
	if(picked == BSM_HIGH_THREAT_SUPERMATTER_SWORD)
		bsm_spawn_rare_weapon_from_instability(machine, /obj/item/melee/supermatter_sword)
		bsm_log_instability(machine, "high", "spawned supermatter sword")
		return
	if(picked == BSM_HIGH_THREAT_PLASMA_RIFLE)
		bsm_spawn_rare_weapon_from_instability(machine, /obj/item/gun/energy/pulse/destroyer)
		bsm_log_instability(machine, "high", "spawned pulse destroyer")
		return
	if(picked == BSM_HIGH_THREAT_TEAR)
		var/datum/round_event_control/anomaly/tear/tear_control = new()
		var/datum/round_event/anomaly/tear/tear_ev = tear_control.runEvent(FALSE, increase_occurrences = FALSE)
		if(!tear_ev)
			return
		var/turf/near_turf = get_safe_random_turf_near(machine)
		tear_ev.spawn_location = near_turf
		bsm_balloon_anomaly_from_miner(machine)
		bsm_log_instability(machine, "high", "dimensional tear /datum/round_event/anomaly/tear")
		return
	var/datum/round_event_control/event_control = new picked()
	var/datum/round_event/running_event = event_control.runEvent(FALSE, increase_occurrences = FALSE)
	if(!running_event)
		return
	var/turf/near_turf = get_safe_random_turf_near(machine)
	if(istype(running_event, /datum/round_event/anomaly))
		var/datum/round_event/anomaly/anomaly_ev = running_event
		anomaly_ev.spawn_location = near_turf
		bsm_balloon_anomaly_from_miner(machine)
		bsm_log_instability(machine, "high", "anomaly event [event_control.type] (running [running_event.type])")
	else if(istype(running_event, /datum/round_event/spawners))
		var/datum/round_event/spawners/spawner_ev = running_event
		spawner_ev.spawn_location = near_turf
		bsm_log_instability(machine, "high", "spawners event [event_control.type] (running [running_event.type])")
	else if(istype(running_event, /datum/round_event/portal_storm))
		var/datum/round_event/portal_storm/ps_ev = running_event
		ps_ev.anchor_turf = near_turf
		bsm_log_instability(machine, "high", "portal storm [event_control.type] (running [running_event.type])")
	else
		bsm_log_instability(machine, "high", "round event [event_control.type] (running [running_event.type], unhandled branch)")
