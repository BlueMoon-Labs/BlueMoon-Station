GLOBAL_DATUM(active_swarmer_team, /datum/team/swarmer_team)

#define ANALYZER_SEND_LIMIT 2

/datum/team/swarmer_team
	name = "Свармеры"
	var/obj/structure/swarmer/core/swarmer_core
	var/metallic_resources = 0
	var/organic_resources = 0
	var/metal_modifier = 1
	var/unlimited_metal_modifier = 1
	var/datum/objective/swarmer_goal/swarmer_objective
	COOLDOWN_DECLARE(message_cooldown)
	var/list/swarmer_objects
	var/list/analyzer_mob_list
	var/list/mob/living/simple_animal/hostile/swarmer/bodies
	var/list/obj/effect/mob_spawn/swarmer/shells
	var/training = FALSE
	var/collapse_timer
	var/analyzer_status = "0/0"

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
	update_core_stats()

/datum/team/swarmer_team/proc/adjust_organic(amount)
	if(QDELETED(swarmer_core) || organic_resources + amount < 0)
		return FALSE
	organic_resources += amount
	if(amount)
		update_core_stats()
	if(!training)
		swarmer_core.on_organic_changed()
	return TRUE

/datum/team/swarmer_team/proc/add_structure(obj/structure_to_add)
	LAZYADDASSOCLIST(swarmer_objects, structure_to_add.type, structure_to_add.UID())
	if(structure_to_add.type == /obj/structure/swarmer/organic_analyzer)
		update_analyzer_stats()

/datum/team/swarmer_team/proc/remove_structure(obj/structure_to_remove)
	LAZYREMOVEASSOC(swarmer_objects, structure_to_remove.type, structure_to_remove.UID())
	if(structure_to_remove.type == /obj/structure/swarmer/organic_analyzer)
		update_analyzer_stats()

/datum/team/swarmer_team/Destroy(force, ...)
	if(GLOB.active_swarmer_team == src)
		GLOB.active_swarmer_team = null
	if(collapse_timer)
		deltimer(collapse_timer)
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
	metallic_resources = SWARMER_STARTING_METAL
	RegisterSignal(swarmer_core, COMSIG_SWARMER_CORE_DAMAGED, PROC_REF(on_core_integrity_changed))
	RegisterSignal(swarmer_core, COMSIG_MOVABLE_MOVED, PROC_REF(on_core_moved))
	update_core_arrows()
	update_core_stats()

/datum/team/swarmer_team/proc/on_core_destroy(obj/structure/swarmer/core/core)
	if(swarmer_core != core)
		return
	UnregisterSignal(swarmer_core, COMSIG_SWARMER_CORE_DAMAGED)
	UnregisterSignal(swarmer_core, COMSIG_MOVABLE_MOVED)
	swarmer_core = null
	update_core_arrows()
	if(GLOB.active_swarmer_team == src)
		GLOB.active_swarmer_team = null
	metallic_resources = 0
	organic_resources = 0
	update_core_stats()
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in shells?.Copy())
		qdel(shell)
	if(!QDELETED(src))
		collapse_timer = addtimer(CALLBACK(src, PROC_REF(start_swarmers_destroying)), 1, TIMER_STOPPABLE)

/datum/team/swarmer_team/proc/on_core_integrity_changed(datum/source)
	SIGNAL_HANDLER
	update_core_stats()
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

/datum/team/swarmer_team/proc/update_core_stats()
	for(var/mob/living/simple_animal/hostile/swarmer/body as anything in bodies)
		if(!body?.client)
			continue
		var/datum/hud/swarmer/swarmer_hud = body.hud_used
		if(istype(swarmer_hud))
			swarmer_hud.update_core_stats()

/datum/team/swarmer_team/proc/update_analyzer_stats()
	if(QDELETED(src))
		return

	var/list/analyzers = LAZYACCESS(swarmer_objects, /obj/structure/swarmer/organic_analyzer)
	var/free_analyzers = 0
	for(var/analyzer_uid in analyzers)
		var/obj/structure/swarmer/organic_analyzer/analyzer = locateUID(analyzer_uid)
		if(analyzer?.can_accept_occupant())
			free_analyzers++

	var/status = "[free_analyzers]/[length(analyzers)]"
	if(analyzer_status != status)
		analyzer_status = status
		update_core_stats()

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
	if(!origin || !is_station_level(origin.z))
		return null
	var/turf/core_turf = get_turf(swarmer_core)
	if(core_turf?.z != origin.z)
		core_turf = null
	var/core_radius = SWARMER_DISPERSE_CORE_RADIUS
	var/require_safe = TRUE
	var/turf/destination = pick_disperse_turf(target, origin, core_turf, core_radius, require_safe)
	if(!destination && core_turf)
		core_radius = SWARMER_DISPERSE_FALLBACK_CORE_RADIUS
		destination = pick_disperse_turf(target, origin, core_turf, core_radius, require_safe)
	if(!destination)
		core_radius = SWARMER_DISPERSE_CORE_RADIUS
		require_safe = FALSE
		destination = pick_disperse_turf(target, origin, core_turf, core_radius, require_safe)

	var/teleport_noise = GLOB.bluespace_teleport_noise
	if(!destination || !teleport_noise)
		return destination

	// Разброс сохраняет ограничения этапа, на котором нашли точку.
	var/list/landings = list(destination)
	for(var/turf/open/floor/landing in get_teleport_turfs(destination, teleport_noise))
		if(landing == destination || landing == origin || landing.density)
			continue
		if(core_turf && get_dist(core_turf, landing) <= core_radius)
			continue
		var/area/landing_area = landing.loc
		if(!landing_area.is_station_member())
			continue
		if(require_safe ? !is_safe_turf(landing) : landing.is_blocked_turf())
			continue
		if(target.training_move_allowed(landing))
			landings += landing
	return pick(landings)

/datum/team/swarmer_team/proc/pick_disperse_turf(mob/living/target, turf/origin, turf/core_turf, core_radius, require_safe)
	var/turf/destination
	var/best_roll = -1
	for(var/area/destination_area as anything in SSmapping.areas_in_z["[origin.z]"])
		if((destination_area.area_flags & NOTELEPORT) || !destination_area.is_station_member())
			continue
		for(var/turf/open/floor/candidate in destination_area)
			if(candidate.z != origin.z || candidate == origin || candidate.density)
				continue
			if(core_turf && get_dist(core_turf, candidate) <= core_radius)
				continue
			// Случайный приоритет позволяет проверять безопасность только у кандидатов, способных победить.
			var/roll = rand()
			if(roll <= best_roll || candidate.is_transition_turf())
				continue
			if(require_safe ? !is_safe_turf(candidate) : candidate.is_blocked_turf())
				continue
			if(!target.training_move_allowed(candidate))
				continue
			best_roll = roll
			destination = candidate
	return destination

/datum/team/swarmer_team/proc/teleport_disperse_target(mob/living/target, turf/destination)
	// Точка уже учитывает разброс, поэтому компенсируем его в общем проке телепортации.
	return do_teleport(target, destination, precision = -GLOB.bluespace_teleport_noise)

/datum/team/swarmer_team/proc/adjust_modifier(adjust_amount)
	unlimited_metal_modifier += adjust_amount
	metal_modifier = max(1, min(SWARMER_METAL_MODIFIER_LIMIT, unlimited_metal_modifier))

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

#undef ANALYZER_SEND_LIMIT

/datum/objective/swarmer_goal
	explanation_text = "Накопите органику и создайте мегасвармера."

/datum/objective/swarmer_goal/check_completion()
	return completed
