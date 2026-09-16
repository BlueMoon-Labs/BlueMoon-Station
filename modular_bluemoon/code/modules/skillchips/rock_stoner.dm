/mob/living/simple_animal/hostile/mining_drone/CanAttack(atom/the_target)
	if(isliving(the_target) && HAS_TRAIT(the_target, TRAIT_ROCK_STONER))
		return FALSE
	return ..()