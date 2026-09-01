/mob/living/simple_animal/hostile/retaliate
	name = "НЕ БЕЙ МЕНЯ"
	/// Broad ally/enemy discovery is supplementary to RetaliateAgainst(), which
	/// records the actual attacker on every direct hit. Coalesce sustained damage
	/// so it cannot raycast the entire nearby AI_TARGETS bucket every second.
	var/next_retaliation_scan = 0

/mob/living/simple_animal/hostile/retaliate/proc/Retaliate()
	if(world.time < next_retaliation_scan)
		return FALSE
	next_retaliation_scan = world.time + 5 SECONDS

	var/list/atom/movable/discovered_enemies = list()
	var/list/mob/living/simple_animal/hostile/retaliate/nearby_allies = list()
	// oview() materializes every visible atom, including thousands of unrelated
	// objects. AI_TARGETS gives us living candidates from nearby grid cells;
	// distance and LOS below preserve the old oview boundary.
	for(var/mob/living/nearby_mob as anything in SSspatial_grid.orthogonal_range_search(src, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, vision_range))
		if(nearby_mob == src || QDELETED(nearby_mob) || get_dist(src, nearby_mob) > vision_range)
			continue
		AI_METRIC_INC(los_checks)
		if(!can_see(src, nearby_mob, vision_range))
			continue
		var/same_faction = faction_check_mob(nearby_mob)
		if((same_faction && attack_same) || !same_faction)
			discovered_enemies += nearby_mob
		if(same_faction && !attack_same && istype(nearby_mob, /mob/living/simple_animal/hostile/retaliate))
			var/mob/living/simple_animal/hostile/retaliate/retaliate_ally = nearby_mob
			if(!retaliate_ally.attack_same)
				nearby_allies += retaliate_ally

	// Mechas are not living AI_TARGETS, but they already have a maintained
	// global registry. Usually this loop is empty or only a handful of entries.
	for(var/obj/vehicle/sealed/mecha/nearby_mecha as anything in GLOB.mechas_list)
		if(QDELETED(nearby_mecha) || nearby_mecha.z != z || !LAZYLEN(nearby_mecha.occupants) || get_dist(src, nearby_mecha) > vision_range)
			continue
		AI_METRIC_INC(los_checks)
		if(!can_see(src, nearby_mecha, vision_range))
			continue
		discovered_enemies += nearby_mecha
		discovered_enemies |= nearby_mecha.occupants

	add_enemies(discovered_enemies)
	for(var/mob/living/simple_animal/hostile/retaliate/retaliate_ally as anything in nearby_allies)
		retaliate_ally.add_enemies(enemies)
		// One member already performed the group scan for this damage burst.
		retaliate_ally.next_retaliation_scan = max(retaliate_ally.next_retaliation_scan, next_retaliation_scan)
	return FALSE

/mob/living/simple_animal/hostile/retaliate/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	var/atom/prior_target = target
	. = ..()
	if(. > 0 && stat == CONSCIOUS)
		Retaliate()
		if(prior_target && (prior_target in enemies) && CanAttack(prior_target))
			GiveTarget(prior_target)
