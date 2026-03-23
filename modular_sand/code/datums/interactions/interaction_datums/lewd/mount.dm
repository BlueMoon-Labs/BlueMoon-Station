/datum/interaction/lewd/mount
	description = "Вагина. Женская доминация."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	p13user_emote = PLUG13_EMOTE_VAGINA
	p13target_emote = PLUG13_EMOTE_PENIS
	additional_details = list(
		INTERACTION_MAY_CAUSE_PREGNANCY
	)

/datum/interaction/lewd/mount/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//var/u_His = user.ru_ego()
	var/genital_name = partner.get_penetrating_genital_name()

	if(partner.is_fucking(user, CUM_TARGET_VAGINA))
		message = "[pick("использует [genital_name] <b>[partner]</b> по прямому назначению и тихо стонет.",
			"с силой загоняет [genital_name] <b>[partner]</b> в свою собственную киску и довольно облизывается.")]"
	else
		message = "резко всовывает [genital_name] <b>[partner]</b> в своё влагалище и удовлетворённо выдыхает."
		partner.set_is_fucking(user, CUM_TARGET_VAGINA, partner.getorganslot(ORGAN_SLOT_PENIS))
		try_apply_knot(partner, user, CUM_TARGET_VAGINA) // Проверка на узлирование (mount)
	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/bang1.ogg',
						'modular_sand/sound/interactions/bang2.ogg',
						'modular_sand/sound/interactions/bang3.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(partner.can_penetrating_genital_cum())
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_VAGINA, user, ORGAN_SLOT_PENIS) //SPLURT edit
	// BLUEMOON EDIT START
	if(partner.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/partner_strapon = partner.get_strapon()
		partner_strapon.attached_dildo.target_reaction(user, partner, 0, CUM_TARGET_VAGINA, CUM_TARGET_PENIS, FALSE)
	else
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, partner, ORGAN_SLOT_VAGINA)
	// BLUEMOON EDIT END

/datum/interaction/lewd/mountass
	description = "Попа. Женская Доминация."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	p13user_emote = PLUG13_EMOTE_ANUS
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/mountass/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//.var/u_His = user.ru_ego()
	var/genital_name = partner.get_penetrating_genital_name()

	if(partner.is_fucking(user, CUM_TARGET_ANUS))
		message = "[pick("использует [genital_name] <b>[partner]</b> по прямому назначению и тихо стонет.",
			"с силой загоняет [genital_name] <b>[partner]</b> в своё анальное колечко и довольно облизывается.")]"
	else
		message = "резко всовывает [genital_name] <b>[partner]</b> в своё анальное кольцо и удовлетворённо выдыхает."
		partner.set_is_fucking(user, CUM_TARGET_ANUS, partner.getorganslot(ORGAN_SLOT_PENIS))
		try_apply_knot(partner, user, CUM_TARGET_ANUS) // Проверка на узлирование (mountass)
	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/bang1.ogg',
						'modular_sand/sound/interactions/bang2.ogg',
						'modular_sand/sound/interactions/bang3.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(partner.can_penetrating_genital_cum())
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_ANUS, user, ORGAN_SLOT_PENIS) //SPLURT edit
	// BLUEMOON EDIT START
	if(partner.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/partner_strapon = partner.get_strapon()
		partner_strapon.attached_dildo.target_reaction(user, partner, 0, CUM_TARGET_ANUS, null, FALSE)
	else
		user.handle_post_sex(NORMAL_LUST, null, partner, CUM_TARGET_ANUS)
	// BLUEMOON EDIT END

/datum/interaction/lewd/mountface
	description = "Попа. Потереться о лицо."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	p13user_emote = PLUG13_EMOTE_ANUS
	p13target_emote = PLUG13_EMOTE_FACE
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/mountface/display_interaction(mob/living/user, mob/living/partner)
	var/message

	//var/u_His = user.ru_ego()

	if(user.is_fucking(partner, GRINDING_FACE_WITH_ANUS))
		message = "[pick("втирает свою задницу в лицо <b>[partner]</b> и ехидно ухмыляется.",
			"потирается своей задницей о лицо <b>[partner]</b> и тихо усмехается.")]"
	else
		message = "[pick(
			"хватается за голову <b>[partner]</b> и с силой вжимает её между своих ягодиц.",
			"присаживается своей задницей прямо на лицо <b>[partner]</b> и начинает тереться о физиономию.")]"
		user.set_is_fucking(partner, GRINDING_FACE_WITH_ANUS, null)

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/squelch1.ogg',
						'modular_sand/sound/interactions/squelch2.ogg',
						'modular_sand/sound/interactions/squelch3.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	user.handle_post_sex(LOW_LUST, null, partner)

/datum/interaction/lewd/thighs
	description = "Член. Придушить."
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	interaction_sound = null
	write_log_user = "thigh-trapped (penis)"
	write_log_target = "was smothered (penis) by"
	var/fucktarget = "penis"
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/thighs/vagina
	description = "Вагина. Придушить."
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	write_log_user = "thigh-trapped (vagina)"
	write_log_target = "was smothered (vagina) by"
	fucktarget = "vagina"
	p13target_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/thighs/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/obj/item/organ/genital/genital = null
	//var/lust_increase = 1 // BLUEMOON EDIT commented

	//var/u_His = user.ru_ego()
	//var/t_His = partner.ru_ego()
	//var/t_Him = partner.ru_na()
	//var/t_Hes = partner.ru_who()

	if(user.is_fucking(partner, THIGH_SMOTHERING) || user.is_fucking(partner, CUM_TARGET_MOUTH))
		var/improv = FALSE
		switch(fucktarget)
			if("vagina")
				if(user.has_vagina())
					message = pick(list(
						"давит лицо <b>[partner]</b> между своих бёдер и полностью блокирует обзор.",
						"трётся об лицо <b>[partner]</b>, размазывая влагу со своей киски по нему."))
				else
					improv = TRUE
			if("penis")
				if(user.has_penis() || user.has_strapon())
					var/genital_name = user.get_penetrating_genital_name()
					message = pick(list("давит лицо <b>[partner]</b> между своих бёдер и полностью блокирует обзор.",
						"прижимает [genital_name] прямо к лицу <b>[partner]</b> и крепко сжимает свои бёдра, хитро улыбаясь.",
						"просовывает [genital_name] в беспомощный рот <b>[partner]</b> и надёжно фиксирует лицо между своими бёдрами."))
				else
					improv = TRUE
		if(improv)
			message = "трется своим пахом вверх и вниз по лицу <b>[partner]</b>."
	else
		var/improv = FALSE
		switch(fucktarget)
			if("vagina")
				if(user.has_vagina())
					message = pick(list(
						"похотливо облизывается и поправляет своё положение на личике <b>[partner]</b>, после чего пару раз сжимает свои бёдра, потирая влажную щель о ротик и носик <b>[partner]</b>.",
						"обхватывает голову <b>[partner]</b> и с усилием вжимает в свой бутон."))
				else
					improv = TRUE
			if("penis")
				if(user.has_penis() || user.has_strapon())
					message = pick(list(
						"похотливо облизывается и поправляет своё положение на личике <b>[partner]</b>, после чего пару раз сжимает свои бёдра, [user.has_penis() ? "выделяя немного предэякулята на лицо <b>[partner]</b>." : "шлепая дилдо по лицу <b>[partner]</b>."]", // BLUEMOON EDIT откуда предэякулят у страпона Bruh
						"обхватывает голову <b>[partner]</b> и с усилием вжимает в свою промежность, в процессе растирая свои гениталии о личико <b>[partner]</b>."))
				else
					improv = TRUE
		if(improv)
			message = "ловко смыкает ноги вокруг головы <b>[partner]</b> и с силой начинает душить."
		else
			switch(fucktarget)
			// BLUEMOON EDIT START
				if("vagina")
					genital = partner.getorganslot(ORGAN_SLOT_VAGINA)
					user.set_is_fucking(partner, THIGH_SMOTHERING, genital)
				if("penis")
					genital = partner.getorganslot(ORGAN_SLOT_PENIS)
					user.set_is_fucking(partner, CUM_TARGET_MOUTH, genital)
			// BLUEMOON EDIT END

	var/file = pick('modular_sand/sound/interactions/bj10.ogg',
					'modular_sand/sound/interactions/bj3.ogg',
					'modular_sand/sound/interactions/foot_wet1.ogg',
					'modular_sand/sound/interactions/foot_dry3.ogg')
	playlewdinteractionsound(get_turf(user), file, 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	// BLUEMOON EDIT START
	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/oral1.ogg',
						'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)
	if(fucktarget == "penis")
		if(user.has_strapon())
			var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
			user_strapon.attached_dildo.target_reaction(partner, user, 1, CUM_TARGET_MOUTH, null, user.a_intent == INTENT_HARM)
		else
			user.handle_post_sex(NORMAL_LUST, THIGH_SMOTHERING, partner, genital)
			partner.handle_post_sex(LOW_LUST, null, user, CUM_TARGET_MOUTH)
	else
		user.handle_post_sex(NORMAL_LUST, THIGH_SMOTHERING, partner, genital) //SPLURT edit
	// BLUEMOON EDIT END
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)
