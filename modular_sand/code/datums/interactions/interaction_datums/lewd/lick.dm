/datum/interaction/lewd/rimjob
	description = "Попа. Вылизать."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	p13target_emote = PLUG13_EMOTE_ANUS

/datum/interaction/lewd/rimjob/display_interaction(mob/living/user, mob/living/partner)
	var/is_hidden = ..()
	var/distance = 7
	var/volume = 50
	if(is_hidden)
		distance = 1
		volume = sound_quiet_volume
	var/picked_hidden = pick(hidden_additional)
	user.visible_message("<span class='lewd'>[is_hidden ? (picked_hidden) : null] <b>[user]</b> вылизывает попку <b>[partner]</b>.</span>", ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/champ_fingering.ogg', volume, 1, -1)
	partner.handle_post_sex(NORMAL_LUST, null, user, "anus") //SPLURT edit

/datum/interaction/lewd/lickfeet
	description = "Ножка. Вылизать."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_target_exposed = INTERACTION_REQUIRE_FEET
	required_from_target_unexposed = INTERACTION_REQUIRE_FEET
	require_target_num_feet = 1

/datum/interaction/lewd/lickfeet/display_interaction(mob/living/user, mob/living/partner)
	var/message

	var/shoes = partner.get_shoes()
	var/is_hidden = ..()
	var/distance = 7
	var/volume = 50
	if(is_hidden)
		distance = 1
		volume = sound_quiet_volume
	var/picked_hidden = pick(hidden_additional)
	if(shoes)
		message = "осторожно облизывает '[shoes]' <b>[partner]</b>."
	else
		message = "облизывает <b>[partner]</b> [partner.has_feet() == 1 ? "ножку" : "ножки"]."

	playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/champ_fingering.ogg', volume, 1, -1)
	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null] <b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	user.handle_post_sex(LOW_LUST, null, user)
