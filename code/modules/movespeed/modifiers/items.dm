// Старые модификаторы джетпака (/datum/movespeed_modifier/jetpack и
// /datum/movespeed_modifier/jetpack/fullspeed) удалены: скорость полёта
// считается в /mob/living/carbon/movement_delay() из конфига
// (RUN_DELAY / WALK_DELAY) по флагу jetpack.full_speed.

/datum/movespeed_modifier/die_of_fate
	multiplicative_slowdown = 1
