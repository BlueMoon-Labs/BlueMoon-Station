/datum/interaction/lewd/unholy/piss_over
	description = "Обоссать с ног до головы."
	required_from_user = INTERACTION_REQUIRE_BOTTOMLESS
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = NONE
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "получает золотой дождь от"
	write_log_user = "нассал на"

/datum/interaction/lewd/unholy/piss_over/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	user.piss_over(target, is_hidden)

/datum/interaction/lewd/unholy/piss_mouth
	description = "Нассать в рот."
	max_distance = 1
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_BOTTOMLESS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	required_from_target_unexposed = NONE
	required_from_user_exposed = NONE
	required_from_user_unexposed = NONE
	write_log_user = "pissed in someone's mouth"
	write_log_target = "got their mouth filled with piss by"

/datum/interaction/lewd/unholy/piss_mouth/display_interaction(mob/living/carbon/user, mob/living/target)
	if(!istype(user))
		to_chat(user, span_warning("You're not a carbon entity."))
		return
	var/is_hidden = ..()
	user.piss_mouth(target, is_hidden)

