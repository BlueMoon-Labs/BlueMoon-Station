/datum/interaction/lewd/jack
	description = "Член. Подрочить себе."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	interaction_flags = INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	max_distance = 0
	write_log_user = "jerked off"
	write_log_target = null
	p13user_emote = PLUG13_EMOTE_PENIS

	additional_details = list(
		INTERACTION_FILLS_CONTAINERS
	)

/datum/interaction/lewd/jack/display_interaction(mob/living/user, mob/living/target, is_hidden)
	var/message
	//var/t_His = user.ru_ego()
	//var/genital_name = user.get_penetrating_genital_name()
	var/has_penis = user.has_penis() // BLUEMOON ADD

	var/obj/item/reagent_containers/liquid_container

	var/obj/item/cached_item = user.get_active_held_item()
	if(istype(cached_item, /obj/item/reagent_containers))
		liquid_container = cached_item
	else
		cached_item = user.pulling
		if(istype(cached_item, /obj/item/reagent_containers))
			liquid_container = cached_item
	var/dirty = user.wants_dirty_text()
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 70
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	if(user.is_fucking(user, CUM_TARGET_HAND, user.getorganslot(ORGAN_SLOT_PENIS)))
		//BLUEMOON EDIT START
		if(dirty)
			var/penis_word = has_penis ? "член" : "дилдо"
			message = replacetext(pick(GLOB.dirty_self_jack_cont_messages), "$PENIS", penis_word)
		else
			message = pick("хватается за свой [has_penis ? "член" : "дилдо"] и начинает его наяривать",
				"с усердием вздрачивает свой [has_penis ? "пенис" : "дилдо"]",
				"дёргает сво[has_penis ? "ё мясо" : "й дилдо"]",
				"наяривает",
				"активно теребит свой [has_penis ? "орган" : "дилдо"] не без помощи своих ладоней")
	else
		if(dirty)
			var/penis_word = has_penis ? "член" : "дилдо"
			message = replacetext(pick(GLOB.dirty_self_jack_first_messages), "$PENIS", penis_word)
		else
			message = pick("хватается за свой [has_penis ? "член" : "дилдо"] и начинает его наяривать",
				"активно теребит свой [has_penis ? "орган" : "дилдо"] не без помощи своих ладоней",
				"с усердием вздрачивает свой [has_penis ? "пенис" : "дилдо"]")
		//BLUEMOON EDIT END
		user.set_is_fucking(user, CUM_TARGET_HAND, user.getorganslot(ORGAN_SLOT_PENIS))
	if(liquid_container)
		message += " прямо в [liquid_container]"

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/bang1.ogg',
						'modular_sand/sound/interactions/bang2.ogg',
						'modular_sand/sound/interactions/bang3.ogg'), volume, 1, extrarange)
	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null]<b>[user]</b> [message]."), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_HAND, liquid_container ? liquid_container : user, ORGAN_SLOT_PENIS) //SPLURT edit
