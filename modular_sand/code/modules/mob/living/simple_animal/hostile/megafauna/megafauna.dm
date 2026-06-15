/mob/living/simple_animal/hostile/megafauna
	var/peaceful = FALSE
	var/retaliated = FALSE
	var/retaliatedcooldowntime = 1 SECONDS
	var/retaliatedcooldown

/mob/living/simple_animal/hostile/megafauna/Found(atom/A)
	if(!peaceful)
		return
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

/mob/living/simple_animal/hostile/megafauna/ListTargets()
	var/list/see = ..()
	if(length(enemies))
		see &= enemies
	return see

/mob/living/simple_animal/hostile/megafauna/PickTarget(list/Targets)
	if(target && (target in Targets) && CanAttack(target))
		return target
	return ..()

/mob/living/simple_animal/hostile/megafauna/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	if(user)
		add_enemy(user)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/bullet_act(obj/item/projectile/P)
	if(P.firer)
		add_enemy(P.firer)
	. = ..()

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
