// TRAIT_ROCK_STONER (skillchip "Miner") - mining drones know their fellow rock-stoners and refuse to attack them.
/mob/living/simple_animal/hostile/mining_drone/CanAttack(atom/the_target)
	if(isliving(the_target) && HAS_TRAIT(the_target, TRAIT_ROCK_STONER))
		return FALSE
	return ..()