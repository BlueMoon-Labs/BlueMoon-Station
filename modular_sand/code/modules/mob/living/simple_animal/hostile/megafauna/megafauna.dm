/mob/living/simple_animal/hostile/megafauna
	var/retaliated = FALSE
	var/retaliatedcooldowntime = 1 SECONDS
	var/retaliatedcooldown

// /mob/living/simple_animal/hostile/megafauna/Found(atom/A)
// 	if(isliving(A))
// 		var/mob/living/L = A
// 		if(!L.stat)
// 			return L
// 		else
// 			remove_enemy(L)
// 	else if(ismecha(A))
// 		var/obj/vehicle/sealed/mecha/M = A
// 		if(LAZYLEN(M.occupants))
// 			return A

// /mob/living/simple_animal/hostile/megafauna/ListTargets()
// 	if(!length(enemies))
// 		return list()
// 	var/list/see = ..()
// 	see &= enemies // Remove all entries that aren't in enemies
// 	return see

/mob/living/simple_animal/hostile/megafauna/proc/Retaliate()
	var/list/around = oview(src, vision_range)
	for(var/atom/movable/A in around)
		if(isliving(A))
			var/mob/living/M = A
			if((faction_check_mob(M) && attack_same) || (!faction_check_mob(M)) || (!ismegafauna(M)))
				add_enemy(M)
				if(!retaliated)
					src.visible_message("<span class='userdanger'>[src] seems pretty pissed off at [M]!</span>")
					retaliated = TRUE
					retaliatedcooldown = world.time + retaliatedcooldowntime
		else if(ismecha(A))
			var/obj/vehicle/sealed/mecha/M = A
			var/list/occupants = LAZYCOPY(M.occupants)
			if(occupants.len)
				add_enemy(M)
				for(var/mob/living/living in occupants)
					if(!living.client)
						continue
					add_enemy(living)
					if(!retaliated)
						visible_message("<span class='userdanger'>[src] seems pretty pissed off at [M]!</span>")
						retaliated = TRUE
						retaliatedcooldown = world.time + retaliatedcooldowntime

	for(var/mob/living/simple_animal/hostile/megafauna/H in around)
		if(faction_check_mob(H) && !attack_same && !H.attack_same)
			for(var/atom/movable/the_enemy in enemies)
				H.add_enemy(the_enemy)
	return FALSE

// /mob/living/simple_animal/hostile/megafauna/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
// 	. = ..()
// 	if(. > 0 && stat == CONSCIOUS)
// 		Retaliate()

// /mob/living/simple_animal/hostile/megafauna/Life()
// 	..()
// 	if(retaliated)
// 		if(retaliatedcooldown < world.time)
// 			retaliated = FALSE
