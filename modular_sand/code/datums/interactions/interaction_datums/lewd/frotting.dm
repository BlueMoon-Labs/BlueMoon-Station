/datum/interaction/lewd/frotting
	description = "Член. Потереться о член."
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	write_log_user = "frotted"
	write_log_target = "was frotted by"
	interaction_sound = null
	p13target_emote = PLUG13_EMOTE_PENIS
	p13user_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/frotting/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/distance = 7
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	var/message
	//var/t_His = user.ru_ego()
	var/genital_name = user.get_penetrating_genital_name()

	message = "потирает свой [genital_name] о [genital_name] <b>[partner]</b>."
	user.set_is_fucking(partner, CUM_TARGET_PENIS, user.getorganslot(ORGAN_SLOT_PENIS))
	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null]<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, partner, ORGAN_SLOT_PENIS) //SPLURT edit
	if(partner.can_penetrating_genital_cum())
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user, ORGAN_SLOT_PENIS) //SPLURT edit

/datum/interaction/lewd/tribadism
	description = "Вагина. Потереться о вагину."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	p13target_emote = PLUG13_EMOTE_VAGINA
	p13user_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/tribadism/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 70
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	var/message

	//var/u_His = user.ru_ego()

	if(partner.is_fucking(user, CUM_TARGET_VAGINA))
		message = "[pick("трётся своей киской с <b>[partner]</b>.",
			"с силой трёт своей киской о киску <b>[partner]</b>.",
			"вжимается в киску <b>[partner]</b> с чавкающим звуком.",
			"игриво развлекается с <b>[partner]</b>, обтираясь своей киской о киску партнёра.")]"
	else
		message = "грубо прижимает свою киску к киске <b>[partner]</b>."
		partner.set_is_fucking(user, CUM_TARGET_VAGINA, partner.getorganslot(ORGAN_SLOT_VAGINA))
	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/squelch1.ogg',
						'modular_sand/sound/interactions/squelch2.ogg',
						'modular_sand/sound/interactions/squelch3.ogg'), volume, 1, extrarange)
	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null]<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_VAGINA, user, ORGAN_SLOT_VAGINA) //SPLURT edit
	user.handle_post_sex(NORMAL_LUST, CUM_TARGET_VAGINA, partner, ORGAN_SLOT_VAGINA) //SPLURT edit
