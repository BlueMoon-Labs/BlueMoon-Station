// TRAIT_CLEANBOT_WHISPERER (skillchip "Janitor") - emagged cleanbots refuse to target a true leader of the cleaners.
/mob/living/simple_animal/bot/cleanbot/process_scan(atom/A)
	if(emagged == 2 && iscarbon(A) && HAS_TRAIT(A, TRAIT_CLEANBOT_WHISPERER))
		return null
	return ..()