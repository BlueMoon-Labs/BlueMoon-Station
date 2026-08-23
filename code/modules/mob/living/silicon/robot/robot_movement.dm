/mob/living/silicon/robot/Process_Spacemove(movement_dir = 0)
	if(ionpulse())
		return TRUE
	return ..()

/mob/living/silicon/robot/mob_negates_gravity()
	return magpulse

/mob/living/silicon/robot/mob_has_gravity()
	return ..() || mob_negates_gravity()

/mob/living/silicon/robot/experience_pressure_difference(pressure_difference, direction)
	if(!magpulse)
		return ..()

/mob/living/silicon/robot/Move(NewLoc, direct)
	. = ..()
	if(. && (combat_flags & COMBAT_FLAG_SPRINT_ACTIVE) && !(movement_type & FLYING) && CHECK_ALL_MOBILITY(src, MOBILITY_STAND | MOBILITY_MOVE))
		if(!(cell?.use(15))) //BLUEMOON EDIT Снижение потребления энергии за спринт силиконам со стандартных 25 до 15
			default_toggle_sprint(TRUE)

/mob/living/silicon/robot/movement_delay()
	. = ..()
	if(!resting && !(combat_flags & COMBAT_FLAG_SPRINT_ACTIVE))
		. += 0.5 //BLUEMOON EDIT Снижение модификатора скорости спринта со стандартных 1 до 0.5
	. += vtec_disabled? 0 : vtec
