#define MOVESPEED_ID_STOMP     "STEPPY"

/datum/movespeed_modifier/stomp
	id = MOVESPEED_ID_STOMP
	movetypes = GROUND
	multiplicative_slowdown = 10
	flags = IGNORE_NOSLOW

/mob/living/proc/apply_stomp_slowdown(duration = 3)
	add_movespeed_modifier(/datum/movespeed_modifier/stomp, TRUE)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, remove_movespeed_modifier), MOVESPEED_ID_STOMP, TRUE), duration)
