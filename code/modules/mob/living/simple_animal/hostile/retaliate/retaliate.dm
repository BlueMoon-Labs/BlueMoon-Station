/mob/living/simple_animal/hostile/retaliate
	name = "НЕ БЕЙ МЕНЯ"

/mob/living/simple_animal/hostile/retaliate/Found(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		if((L in enemies) && !L.stat)
			return L
		if(L.stat)
			remove_enemy(L)
	else if(ismecha(A))
		var/obj/vehicle/sealed/mecha/M = A
		if((A in enemies) && LAZYLEN(M.occupants))
			return A

/mob/living/simple_animal/hostile/retaliate/ListTargets()
	if(!length(enemies))
		return list()
	var/list/see = ..()
	see &= enemies
	return see

/mob/living/simple_animal/hostile/retaliate/PickTarget(list/Targets)
	if(target && (target in Targets) && CanAttack(target))
		return target
	return ..()

/mob/living/simple_animal/hostile/retaliate/proc/Retaliate()
	var/list/around = oview(src, vision_range)

	for(var/atom/movable/A in around)
		if(A == src)
			continue
		if(isliving(A))
			var/mob/living/M = A
			if((faction_check_mob(M) && attack_same) || !faction_check_mob(M))
				add_enemy(M)
		else if(ismecha(A))
			var/obj/vehicle/sealed/mecha/M = A
			if(LAZYLEN(M.occupants))
				add_enemy(M)
				for(var/mob/living/occupant as anything in M.occupants)
					add_enemy(occupant)

	for(var/mob/living/simple_animal/hostile/retaliate/H in around)
		if(faction_check_mob(H) && !attack_same && !H.attack_same)
			for(var/atom/movable/the_enemy in enemies)
				H.add_enemy(the_enemy)
	return FALSE

/mob/living/simple_animal/hostile/retaliate/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	var/atom/prior_target = target
	. = ..()
	if(. > 0 && stat == CONSCIOUS)
		Retaliate()
		if(prior_target && (prior_target in enemies) && CanAttack(prior_target))
			GiveTarget(prior_target)
