GLOBAL_DATUM(active_swarmer_team, /datum/team/swarmer_team)

#define METAL_MODIFIER_LIMIT 3
#define ANALYZER_SEND_LIMIT 2

/datum/team/swarmer_team
	name = "Свармеры"
	var/obj/structure/swarmer/core/swarmer_core
	var/metallic_resources = 0
	var/organic_resources = 0
	var/metal_modifier = 1
	var/unlimited_metal_modifier = 1
	var/datum/objective/swarmer_goal/swarmer_objective
	var/mega_swarmer_announcement_made = FALSE
	COOLDOWN_DECLARE(message_cooldown)
	var/list/swarmer_objects
	var/list/analyzer_mob_list
	var/list/mob/living/simple_animal/hostile/swarmer/bodies
	var/list/obj/effect/mob_spawn/swarmer/shells
	var/training = FALSE
	var/collapse_timer
	var/gamma_timer

/datum/team/swarmer_team/New(list/starting_members)
	..()
	swarmer_objective = new
	objectives += swarmer_objective

/datum/team/swarmer_team/proc/adjust_metal(amount, use_modifier = FALSE)
	if(QDELETED(swarmer_core))
		return FALSE
	if(use_modifier)
		amount *= metal_modifier
	if(metallic_resources + amount < 0)
		return FALSE
	set_metal(metallic_resources + amount)
	return TRUE

/datum/team/swarmer_team/proc/set_metal(amount)
	if(metallic_resources == amount)
		return
	metallic_resources = amount
	for(var/mob/living/simple_animal/hostile/swarmer/body as anything in bodies)
		if(!body?.client)
			continue
		var/datum/hud/swarmer/swarmer_hud = body.hud_used
		if(istype(swarmer_hud))
			swarmer_hud.update_core_metal()

/datum/team/swarmer_team/proc/adjust_organic(amount)
	if(QDELETED(swarmer_core) || organic_resources + amount < 0)
		return FALSE
	organic_resources += amount
	if(!training)
		swarmer_core.on_organic_changed()
	return TRUE

/datum/team/swarmer_team/proc/add_structure(obj/structure_to_add)
	LAZYADDASSOCLIST(swarmer_objects, structure_to_add.type, structure_to_add.UID())

/datum/team/swarmer_team/proc/remove_structure(obj/structure_to_remove)
	LAZYREMOVEASSOC(swarmer_objects, structure_to_remove.type, structure_to_remove.UID())

/datum/team/swarmer_team/Destroy(force, ...)
	if(GLOB.active_swarmer_team == src)
		GLOB.active_swarmer_team = null
	if(collapse_timer)
		deltimer(collapse_timer)
	if(gamma_timer)
		deltimer(gamma_timer)
	if(swarmer_core)
		UnregisterSignal(swarmer_core, list(COMSIG_SWARMER_CORE_DAMAGED, COMSIG_MOVABLE_MOVED))
		QDEL_NULL(swarmer_core)
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in shells?.Copy())
		qdel(shell)
	for(var/mob/living/simple_animal/hostile/swarmer/body as anything in bodies?.Copy())
		qdel(body)
	for(var/structure_type in swarmer_objects?.Copy())
		var/list/structure_uids = swarmer_objects[structure_type]
		for(var/uid in structure_uids?.Copy())
			qdel(locateUID(uid))
	bodies = null
	shells = null
	swarmer_objects = null
	analyzer_mob_list = null
	objectives -= swarmer_objective
	QDEL_NULL(swarmer_objective)
	return ..()

/datum/team/swarmer_team/proc/on_core_init(obj/structure/swarmer/core/core)
	swarmer_core = core
	set_metal(SWARMER_STARTING_METAL)
	RegisterSignal(swarmer_core, COMSIG_SWARMER_CORE_DAMAGED, PROC_REF(on_core_integrity_changed))
	RegisterSignal(swarmer_core, COMSIG_MOVABLE_MOVED, PROC_REF(on_core_moved))
	update_core_arrows()

/datum/team/swarmer_team/proc/on_core_destroy(obj/structure/swarmer/core/core)
	if(swarmer_core != core)
		return
	UnregisterSignal(swarmer_core, COMSIG_SWARMER_CORE_DAMAGED)
	UnregisterSignal(swarmer_core, COMSIG_MOVABLE_MOVED)
	swarmer_core = null
	update_core_arrows()
	if(GLOB.active_swarmer_team == src)
		GLOB.active_swarmer_team = null
	set_metal(0)
	organic_resources = 0
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in shells?.Copy())
		qdel(shell)
	if(!QDELETED(src))
		collapse_timer = addtimer(CALLBACK(src, PROC_REF(start_swarmers_destroying)), 1, TIMER_STOPPABLE)

/datum/team/swarmer_team/proc/on_core_integrity_changed(datum/source)
	SIGNAL_HANDLER
	if(!COOLDOWN_FINISHED(src, message_cooldown))
		return

	COOLDOWN_START(src, message_cooldown, 3 SECONDS)
	var/area/core_area = get_area(swarmer_core)
	var/locname = initial(core_area.name)
	for(var/datum/mind/swarmer_mind as anything in members)
		var/mob/living/target = swarmer_mind?.current
		if(!target)
			continue
		target.balloon_alert(target, "повреждение ядра!")
		to_chat(target, span_boldnotice("Внимание: Обнаружено повреждение ядра! Местоположение: [locname]."))

/datum/team/swarmer_team/proc/on_core_moved(datum/source, atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	SIGNAL_HANDLER
	update_core_arrows()
	if(istype(old_loc, /obj/structure/closet/supplypod/swarmer))
		return
	var/area/core_area = get_area(swarmer_core)
	var/locname = initial(core_area.name)
	for(var/datum/mind/swarmer_mind as anything in members)
		var/mob/living/target = swarmer_mind?.current
		if(!target)
			continue
		target.balloon_alert(target, "перемещение ядра!")
		to_chat(target, span_boldnotice("Внимание: Обнаружено перемещение ядра! Новое местоположение: [locname]."))

/datum/team/swarmer_team/proc/update_core_arrows()
	for(var/mob/living/simple_animal/hostile/swarmer/body as anything in bodies)
		var/datum/hud/swarmer/swarmer_hud = body?.hud_used
		if(istype(swarmer_hud))
			swarmer_hud.update_core_arrow()

/datum/team/swarmer_team/proc/try_process_organic(obj/item/item)
	if(!LAZYACCESS(swarmer_objects, /obj/structure/swarmer/organic_processer))
		return SWARMER_PROCESS_NONE

	for(var/processer_uid in swarmer_objects[/obj/structure/swarmer/organic_processer])
		var/obj/structure/swarmer/organic_processer/processer = locateUID(processer_uid)
		if(processer?.try_load_item(item))
			return SWARMER_PROCESS_FOUND

	return SWARMER_PROCESS_BUSY
/datum/team/swarmer_team/proc/try_analyze_mob(mob/living/target)
	if(!LAZYACCESS(swarmer_objects, /obj/structure/swarmer/organic_analyzer))
		return SWARMER_ANALYZE_NONE

	var/gib_on_end = FALSE
	var/target_uid = target.UID()
	if(LAZYACCESS(analyzer_mob_list, target_uid) >= ANALYZER_SEND_LIMIT)
		gib_on_end = TRUE

	for(var/analyzer_uid in swarmer_objects[/obj/structure/swarmer/organic_analyzer])
		var/obj/structure/swarmer/organic_analyzer/analyzer = locateUID(analyzer_uid)
		if(analyzer?.try_load_mob(target, gib_on_end))
			LAZYADDASSOC(analyzer_mob_list, target_uid, 1)
			return SWARMER_ANALYZE_FOUND

	return SWARMER_ANALYZE_BUSY

/datum/team/swarmer_team/proc/find_disperse_turf(mob/living/target)
	var/turf/origin = get_turf(target)
	if(!origin)
		return null
	var/turf/core_turf = get_turf(swarmer_core) || origin
	var/area/core_area = get_area(core_turf)
	var/teleport_noise = GLOB.bluespace_teleport_noise
	var/turf/farthest
	var/max_distance_squared = -1
	for(var/area/destination_area as anything in SSmapping.areas_in_z["[origin.z]"])
		if(destination_area == core_area || istype(destination_area, /area/space) || (destination_area.area_flags & NOTELEPORT))
			continue
		for(var/turf/open/floor/candidate in destination_area)
			if(candidate.z != origin.z || candidate == origin || candidate.density)
				continue
			var/dx = candidate.x - core_turf.x
			var/dy = candidate.y - core_turf.y
			var/distance_squared = dx * dx + dy * dy
			if(distance_squared <= max_distance_squared || !is_safe_turf(candidate) || !target.training_move_allowed(candidate))
				continue
			if(teleport_noise)
				var/overlaps_core = FALSE
				for(var/turf/landing as anything in get_teleport_turfs(candidate, teleport_noise))
					if(landing.loc == core_area)
						overlaps_core = TRUE
						break
				if(overlaps_core)
					continue
			max_distance_squared = distance_squared
			farthest = candidate
	return farthest

/datum/team/swarmer_team/proc/adjust_modifier(adjust_amount)
	unlimited_metal_modifier += adjust_amount
	metal_modifier = max(1, min(METAL_MODIFIER_LIMIT, unlimited_metal_modifier))

/datum/team/swarmer_team/proc/get_metal_modifier_limit()
	return METAL_MODIFIER_LIMIT

/datum/team/swarmer_team/proc/on_mega_swarmer_spawn(mob/living/simple_animal/hostile/swarmer/mega/swarmer)
	if(mega_swarmer_announcement_made)
		return
	mega_swarmer_announcement_made = TRUE
	swarmer_objective.completed = TRUE
	priority_announce("Обнаружено появление мегасвармера на борту станции [station_name()]. Остановите его, пока рой не захватил станцию.", "Обнаружен мегасвармер")
	gamma_timer = addtimer(CALLBACK(SSsecurity_level, TYPE_PROC_REF(/datum/controller/subsystem/security_level, set_level), SEC_LEVEL_GAMMA), 5 SECONDS, TIMER_STOPPABLE)

/datum/team/swarmer_team/proc/start_swarmers_destroying()
	collapse_timer = null
	if(length(bodies))
		var/mob/swarmer = bodies[1]
		explosion(swarmer, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 2)
		if(!QDELETED(swarmer))
			qdel(swarmer)
		collapse_timer = addtimer(CALLBACK(src, PROC_REF(start_swarmers_destroying)), 1, TIMER_STOPPABLE)
		return

	destroy_swarmer_objects()

/datum/team/swarmer_team/proc/destroy_swarmer_objects()
	collapse_timer = null
	if(!LAZYLEN(swarmer_objects))
		return

	var/obj_type = swarmer_objects[1]
	var/list/obj_uids = swarmer_objects[obj_type]
	var/obj_uid = obj_uids[1]
	var/obj/obj = locateUID(obj_uid)
	if(obj)
		explosion(obj, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 2)
		if(!QDELETED(obj))
			qdel(obj)

	LAZYREMOVEASSOC(swarmer_objects, obj_type, obj_uid)
	collapse_timer = addtimer(CALLBACK(src, PROC_REF(destroy_swarmer_objects)), 1, TIMER_STOPPABLE)

/datum/team/swarmer_team/proc/get_transport_hub_list(obj/structure/swarmer/transport_hub/hub_to_ignore)
	if(!LAZYACCESS(swarmer_objects, /obj/structure/swarmer/transport_hub))
		return

	var/list/potential_hubs = list()
	var/list/hub_names = list()
	var/list/duplicate_hub_count = list()
	for(var/hub_uid in swarmer_objects[/obj/structure/swarmer/transport_hub])
		var/obj/structure/swarmer/transport_hub/hub = locateUID(hub_uid)
		if(QDELETED(hub) || !hub.enabled || !hub.anchored)
			continue

		var/resultkey = hub.listkey
		if(resultkey in hub_names)
			duplicate_hub_count[resultkey]++
			resultkey = "[resultkey] ([duplicate_hub_count[resultkey]])"
		else
			hub_names += resultkey
			duplicate_hub_count[resultkey] = 1

		if(hub != hub_to_ignore)
			potential_hubs[resultkey] = hub

	return potential_hubs

/datum/team/swarmer_team/proc/check_objs_of_type_in_range(turf/target_turf, range, obj_type, check_unanchored = TRUE)
	if(!LAZYACCESS(swarmer_objects, obj_type))
		return TRUE

	. = TRUE
	var/list/same_obj_uids = swarmer_objects[obj_type]
	for(var/obj_uid in same_obj_uids)
		var/obj/obj = locateUID(obj_uid)
		if(QDELETED(obj))
			continue

		if(check_unanchored && !obj.anchored)
			continue

		if(obj.z == target_turf.z && get_dist(target_turf, obj) <= range)
			return FALSE

/datum/team/swarmer_team/proc/on_nanobot_fabricator_init(obj/structure/swarmer/nanobot_fabricator/fabricator)
	return

#undef METAL_MODIFIER_LIMIT
#undef ANALYZER_SEND_LIMIT

/datum/objective/swarmer_goal
	explanation_text = "Накопите органику и создайте мегасвармера."

/datum/objective/swarmer_goal/check_completion()
	return completed
