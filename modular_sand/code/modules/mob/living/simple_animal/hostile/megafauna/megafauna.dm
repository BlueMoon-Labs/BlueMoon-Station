/mob/living/simple_animal/hostile/megafauna
	var/peaceful = FALSE
	var/retaliated = FALSE
	var/retaliatedcooldowntime = 1 SECONDS
	var/retaliatedcooldown
	/// Broad discovery is supplementary to the direct attacker grudge. Damage
	/// bursts and allied bosses share one spatial scan. Direct attackers are
	/// recorded immediately, so rescanning every nearby mob once per second only
	/// amplifies sustained-AOE load without improving reaction time.
	var/next_retaliation_scan = 0

/mob/living/simple_animal/hostile/megafauna/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	if(user)
		add_enemy(user)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/bullet_act(obj/item/projectile/P)
	if(P.firer)
		add_enemy(P.firer)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/proc/Retaliate()
	if(world.time < next_retaliation_scan)
		return FALSE
	next_retaliation_scan = world.time + 5 SECONDS

	var/list/atom/movable/discovered_enemies = list()
	var/list/mob/living/simple_animal/hostile/megafauna/nearby_allies = list()
	var/atom/movable/retaliation_target
	// Sweep at the base perception radius, not the combat-inflated vision_range:
	// Aggro() widens vision to 40 tiles, and recruiting every visible mob from
	// three screens away turned bystanders into permanent enemies. Direct
	// attackers are flagged at any distance by attacked_by()/bullet_act().
	var/retaliation_range = initial(vision_range)
	// oview() materialized every visible object. The AI target channel limits
	// this to living candidates; exact distance and LOS retain its boundary.
	for(var/mob/living/nearby_mob as anything in SSspatial_grid.orthogonal_range_search(src, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, retaliation_range))
		if(nearby_mob == src || QDELETED(nearby_mob) || get_dist(src, nearby_mob) > retaliation_range)
			continue
		AI_METRIC_INC(los_checks)
		if(!can_see(src, nearby_mob, retaliation_range))
			continue
		var/same_faction = faction_check_mob(nearby_mob)
		if(!same_faction || attack_same)
			discovered_enemies += nearby_mob
			if(!retaliation_target)
				retaliation_target = nearby_mob
		if(same_faction && !attack_same && ismegafauna(nearby_mob))
			var/mob/living/simple_animal/hostile/megafauna/megafauna_ally = nearby_mob
			if(!megafauna_ally.attack_same)
				nearby_allies += megafauna_ally

	// Mechas are not living AI targets, but their global registry is normally
	// empty or tiny. Only client occupants retain the old personal grudge.
	for(var/obj/vehicle/sealed/mecha/nearby_mecha as anything in GLOB.mechas_list)
		if(QDELETED(nearby_mecha) || nearby_mecha.z != z || !LAZYLEN(nearby_mecha.occupants) || get_dist(src, nearby_mecha) > retaliation_range)
			continue
		AI_METRIC_INC(los_checks)
		if(!can_see(src, nearby_mecha, retaliation_range))
			continue
		discovered_enemies += nearby_mecha
		for(var/mob/living/occupant as anything in nearby_mecha.occupants)
			if(!occupant.client)
				continue
			discovered_enemies |= occupant
			if(!retaliation_target)
				retaliation_target = nearby_mecha

	add_enemies(discovered_enemies)
	if(retaliation_target && !retaliated)
		visible_message("<span class='userdanger'>[src] seems pretty pissed off at [retaliation_target]!</span>")
		retaliated = TRUE
		retaliatedcooldown = world.time + retaliatedcooldowntime

	for(var/mob/living/simple_animal/hostile/megafauna/megafauna_ally as anything in nearby_allies)
		megafauna_ally.add_enemies(enemies)
		megafauna_ally.next_retaliation_scan = max(megafauna_ally.next_retaliation_scan, next_retaliation_scan)
	return FALSE

/mob/living/simple_animal/hostile/megafauna/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	var/atom/prior_target = target
	. = ..()
	if(. > 0 && stat == CONSCIOUS)
		if(peaceful)
			peaceful = FALSE
		Retaliate()
		if(prior_target && (prior_target in enemies) && CanAttack(prior_target))
			GiveTarget(prior_target)

/mob/living/simple_animal/hostile/megafauna/Life()
	..()
	if(!peaceful && retaliated)
		if(retaliatedcooldown < world.time)
			retaliated = FALSE

/mob/living/simple_animal/hostile/megafauna/ex_act(severity, target, origin)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			adjustBruteLoss(200)
		if(EXPLODE_HEAVY)
			adjustBruteLoss(80)
		if(EXPLODE_LIGHT)
			adjustBruteLoss(40)

/mob/living/simple_animal/hostile/megafauna/wave_ex_act(power, datum/wave_explosion/explosion, dir)
	adjustBruteLoss(EXPLOSION_POWER_STANDARD_SCALE_MOB_DAMAGE(power, explosion.mob_damage_mod) / 3)
