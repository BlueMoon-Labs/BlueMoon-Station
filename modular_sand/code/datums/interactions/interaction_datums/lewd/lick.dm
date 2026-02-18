/datum/interaction/lewd/rimjob
	description = "Попа. Вылизать."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	p13target_emote = PLUG13_EMOTE_ANUS

/datum/interaction/lewd/rimjob/display_interaction(mob/living/user, mob/living/partner)
	user.visible_message("<span class='lewd'><b>[user]</b> вылизывает попку <b>[partner]</b>.</span>", ignored_mobs = user.get_unconsenting())
	playlewdinteractionsound(get_turf(user), pick('modular_bluemoon/sound/interactions/sfx/oral1.ogg',
						'modular_bluemoon/sound/interactions/sfx/oral2.ogg'), 100, 1, -1)
	partner.handle_post_sex(NORMAL_LUST, null, user, "anus") //SPLURT edit
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

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

	if(shoes)
		message = "осторожно облизывает '[shoes]' <b>[partner]</b>."
	else
		message = "облизывает <b>[partner]</b> [partner.has_feet() == 1 ? "ножку" : "ножки"]."

	playlewdinteractionsound(get_turf(user), pick('modular_bluemoon/sound/interactions/sfx/oral1.ogg',
						'modular_bluemoon/sound/interactions/sfx/oral2.ogg'), 100, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	user.handle_post_sex(LOW_LUST, null, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)
