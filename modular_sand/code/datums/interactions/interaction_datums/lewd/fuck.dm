/datum/interaction/lewd/fuck
	description = "Член. Проникнуть в вагину."
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	write_log_user = "fucked"
	write_log_target = "was fucked by"
	interaction_sound = null
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_VAGINA
	additional_details = list(
		INTERACTION_MAY_CAUSE_PREGNANCY
	)

/datum/interaction/lewd/fuck/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//var/u_His = user.ru_ego()
	//var/genital_name = user.get_penetrating_genital_name() - Стал не нужным.
	//BLUEMOON ADD START
	//var/has_penis = user.has_penis() - Стал не нужным.
	var/has_balls = user.has_balls()
	var/shape_desc = get_penis_shape_desc(user) //  Описания каким органом ты трахаешь // BlueMoon Add
//BLUEMOON ADD END
	if(user.is_fucking(partner, CUM_TARGET_VAGINA))
		message = pick(
			"долбится в киску <b>[partner]</b>, пуская в ход свой [shape_desc] член.",
			"глубоко вводит свой [shape_desc] член во влагалище <b>[partner]</b>.",
			"с силой загоняет свой [shape_desc] член в вагину <b>[partner]</b> и шлёпается своими [has_balls ? "яйцами" : "бедрами"].",
			"ритмично двигается, заставляя <b>[partner]</b> дрожать при каждом толчке.",
			"жадно насаживает <b>[partner]</b> на свой [shape_desc] член, теряя самообладание.")
	else
		message = pick(
			"медленно вводит свой [shape_desc] член в лоно <b>[partner]</b>, наслаждаясь тёплотой.",
			"плотно прижимается к <b>[partner]</b> и аккуратно погружает свой [shape_desc] член.",
			"ловко находит нужный угол и начинает проникновение в киску <b>[partner]</b>.")
		user.set_is_fucking(partner, CUM_TARGET_VAGINA, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/champ1.ogg',
		'modular_sand/sound/interactions/champ2.ogg'), 70, 1, -1)

	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_VAGINA, partner, ORGAN_SLOT_PENIS)

	if(user.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
		user_strapon.attached_dildo.target_reaction(partner, user, 0, CUM_TARGET_VAGINA, CUM_TARGET_PENIS, user.a_intent == INTENT_HARM)
	else
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user, ORGAN_SLOT_VAGINA)
		try_apply_knot(user, partner, CUM_TARGET_VAGINA) // Проверка на узлирование.

	if(prob(5 + partner.get_lust()))
		if(partner.a_intent == INTENT_HELP)
			user.visible_message(
				pick(span_lewd("<b>[partner]</b> дрожит от удовольствия."),
					span_lewd("<b>[partner]</b> стонет, выгибаясь навстречу."),
					span_lewd("<b>[partner]</b> слабо постанывает, чувствуя каждый толчок."),
					span_lewd("<b>[partner]</b> прижимается к <b>[user]</b> всем телом, теряя дыхание.")))
		else if(partner.a_intent == INTENT_DISARM)
			user.visible_message(
				pick(span_lewd("<b>[partner]</b> извивается в руках <b>[user]</b>, с трудом сдерживая стон."),
					span_lewd("<b>[partner]</b> пытается вырваться, но лишь сильнее двигается навстречу."),
					span_lewd("<b>[partner]</b> ерзает под <b>[user]</b>, не зная, хочет ли остановиться или продолжить.")))
		else if(partner.a_intent == INTENT_HARM)
			user.visible_message(
				pick(span_lewd("<b>[partner]</b> резко отталкивает <b>[user]</b>, с гневом на лице."),
					span_lewd("<b>[partner]</b> кусает <b>[user]</b> за плечо."),
					span_lewd("<b>[partner]</b> злится, пытаясь прекратить происходящее.")))

/datum/interaction/lewd/fuck/anal
	description = "Член. Проникнуть в задницу."
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	p13user_emote = "front"
	p13target_emote = "back"
	p13target_emote = PLUG13_EMOTE_ANUS
	additional_details = null // no pregnancy

/datum/interaction/lewd/fuck/anal/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//var/u_His = user.ru_ego()
	//var/t_His = partner.ru_ego()
	//BLUEMOON ADD START
	//var/genital_name = user.get_penetrating_genital_name() - Стал не нужным.
	var/has_penis = user.has_penis()
	var/has_balls = user.has_balls()
	var/shape_desc = get_penis_shape_desc(user) //  Описания каким органом ты трахаешь // BlueMoon Add
	//BLUEMOON ADD END

	if(user.is_fucking(partner, CUM_TARGET_ANUS))
	//BLUEMOON EDIT START
		message = pick(
			"долбится в задницу <b>[partner]</b>.",
			"проникает в попку <b>[partner]</b>.",
			"глубоко вводит свой [shape_desc] в анальное колечко <b>[partner]</b>.",
			"с силой загоняет свой [has_penis ? shape_desc : "дилдо"] в анальное отверстие <b>[partner]</b> и шлёпается своими [has_balls ? "яйцами" : "бедрами"].") // BLUEMOON EDIT
	else
		message = pick(
			"грубо трахает \the <b>[partner]</b> в задницу с громким чавкающим звуком.",
			"хватает \the <b>[partner]</b> и начинает насаживать попкой на свой [has_penis ? shape_desc : "дилдо"].", // BLUEMOON EDIT
			"сильно вращает своими бёдрами и погружается внутрь сфинктера \the <b>[partner]</b>.")
	//BLUEMOON EDIT END
		user.set_is_fucking(partner, CUM_TARGET_ANUS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/bang1.ogg',
						'modular_sand/sound/interactions/bang2.ogg',
						'modular_sand/sound/interactions/bang3.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_ANUS, partner, ORGAN_SLOT_PENIS) //SPLURT edit
		try_apply_knot(user, partner, CUM_TARGET_ANUS) // Проверка на узлирование.

	if(prob(5 + partner.get_lust()))
		if(partner.a_intent == INTENT_HELP)
			user.visible_message(
				pick(span_lewd("<b>[partner]</b> дрожит от удовольствия."),
					span_lewd("<b>[partner]</b> стонет, выгибаясь навстречу."),
					span_lewd("<b>[partner]</b> слабо постанывает, чувствуя каждый толчок."),
					span_lewd("<b>[partner]</b> прижимается к <b>[user]</b> всем телом, теряя дыхание.")))
		else if(partner.a_intent == INTENT_DISARM)
			user.visible_message(
				pick(span_lewd("<b>[partner]</b> извивается в руках <b>[user]</b>, с трудом сдерживая стон."),
					span_lewd("<b>[partner]</b> пытается вырваться, но лишь сильнее двигается навстречу."),
					span_lewd("<b>[partner]</b> ерзает под <b>[user]</b>, не зная, хочет ли остановиться или продолжить.")))
		else if(partner.a_intent == INTENT_HARM)
			user.visible_message(
				pick(span_lewd("<b>[partner]</b> резко отталкивает <b>[user]</b>, с гневом на лице."),
					span_lewd("<b>[partner]</b> кусает <b>[user]</b> за плечо."),
					span_lewd("<b>[partner]</b> злится, пытаясь прекратить происходящее.")))

	// BLUEMOON EDIT START
	if(user.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
		user_strapon.attached_dildo.target_reaction(partner, user, 0, CUM_TARGET_ANUS, null, user.a_intent == INTENT_HARM)
	else
		partner.handle_post_sex(NORMAL_LUST, null, user, "anus") //SPLURT edit
		try_apply_knot(user, partner, CUM_TARGET_ANUS) // Проверка на узлирование.
	// BLUEMOON EDIT END

/datum/interaction/lewd/breastfuck
	description = "Член. Проникнуть между сисек."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_BREASTS
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_BREASTS
	p13target_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/breastfuck/display_interaction(mob/living/user, mob/living/partner) // BLUEMOON EDIT
	var/message
	var/genital_name = user.get_penetrating_genital_name()
	//BLUEMOON ADD START
	var/has_penis = user.has_penis()
	var/has_balls = user.has_balls()
	var/shape_desc = get_penis_shape_desc(user) //  Описания каким органом ты трахаешь // BlueMoon Add
	//BLUEMOON ADD END

	if(user.is_fucking(partner, CUM_TARGET_BREASTS))
	//BLUEMOON EDIT START
		message = pick(
			"продалбливается между титьками <b>[partner]</b>.",
			"проникает между сиськами <b>[partner]</b>.",
			"вводит свой [shape_desc] в пространство между грудью <b>[partner]</b>.",
			"с силой загоняет свой[has_penis ? shape_desc : "дилдо"] между сиськами <b>[partner]</b> и шлёпается своими [has_balls ? "яйцами" : "бедрами"] о грудь.") //BLUEMOON EDIT
	//BLUEMOON EDIT END
	else
		message = "игриво толкает <b>[partner]</b>, крепко хватается за грудь и сжимает ими свой [genital_name]."
		user.set_is_fucking(partner, CUM_TARGET_BREASTS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/bang1.ogg',
						'modular_sand/sound/interactions/bang2.ogg',
						'modular_sand/sound/interactions/bang3.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())

	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_BREASTS, partner, ORGAN_SLOT_PENIS) //SPLURT edit
	//BLUEMOON ADD START
	if(HAS_TRAIT(partner, TRAIT_NYMPHO))
		partner.handle_post_sex(LOW_LUST, null, user, CUM_TARGET_BREASTS)
	//BLUEMOON ADD END

/datum/interaction/lewd/footfuck
	description = "Член. Потереться о ботинок."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_FEET
	required_from_target_unexposed = INTERACTION_REQUIRE_FEET
	require_target_num_feet = 1
	p13user_emote = PLUG13_EMOTE_PENIS
	p13user_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/footfuck/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//var/genital_name = user.get_penetrating_genital_name() - Стал не нужным.
	var/has_penis = user.has_penis() // BLUEMOON ADD
	var/shape_desc = get_penis_shape_desc(user) //  Описания каким органом ты трахаешь // BlueMoon Add

	if(user.is_fucking(partner, CUM_TARGET_FEET))
	//BLUEMOON EDIT START
		message = pick("трётся своим [has_penis ? "членом" : "дилдо"] о ботинок <b>[partner]</b>.",
			"потирается своим [has_penis ? shape_desc : "дилдо"] о ботинок <b>[partner]</b>.",
			"[has_penis ? "мастурбирует" : "поглаживает дилдо"], в процессе потираясь о ботинок <b>[partner]</b>.")
	else
		message = pick("позиционирует свой [shape_desc] на ботинок <b>[partner]</b> и начинает потираться.",
			"выставляет свой [shape_desc] на ботинки ботинок <b>[partner]</b> и начинает тот стимулировать.",
			"держит свой [shape_desc] своими руками и наконец-то начинает тереться о ботинок <b>[partner]</b>.")
	//BLUEMOON EDIT END
		user.set_is_fucking(partner, CUM_TARGET_FEET, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/foot_dry3.ogg',
						'modular_sand/sound/interactions/foot_wet1.ogg',
						'modular_sand/sound/interactions/foot_wet2.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_FEET, partner, CUM_TARGET_PENIS) //SPLURT edit

/datum/interaction/lewd/footfuck/double
	description = "Член. Потереться о ботинки."
	require_target_num_feet = 2

/datum/interaction/lewd/footfuck/double/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//var/u_His = user.ru_ego()
	//var/genital_name = user.get_penetrating_genital_name() - Стал не нужным.
	var/has_penis = user.has_penis() // BLUEMOON ADD
	var/shape_desc = get_penis_shape_desc(user) // BlueMoon Add

	var/shoes = partner.get_shoes()

	if(user.is_fucking(partner, CUM_TARGET_FEET))
	//BLUEMOON EDIT START
		message = pick("трётся своим [has_penis ? "членом" : "дилдо"] о [shoes ? shoes : pick("ботинок", "ботинки")] <b>[partner]</b>.",
			"потирается своим [has_penis ? "членом" : "дилдо"] о [shoes ? shoes : pick("ботинок", "ботинки")] <b>[partner]</b>.",
			"мастурбирует, в процессе потираясь о [shoes ? shoes : pick("ботинок", "ботинки")] <b>[partner]</b>.")
	else
		message = pick("позиционирует свой [shape_desc] на [shoes ? shoes : pick("ботинок", "ботинки")] <b>[partner]</b> и начинает потираться.",
			"выставляет свой [shape_desc] на ботинки [shoes ? shoes : pick("ботинок", "ботинки")] <b>[partner]</b> и начинает тот стимулировать.",
			"держит свой [shape_desc] своими руками и наконец-то начинает тереться о [shoes ? shoes : pick("ботинок", "ботинки")] <b>[partner]</b>.")
	//BLUEMOON EDIT END
		user.set_is_fucking(partner, CUM_TARGET_FEET, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/foot_dry3.ogg',
						'modular_sand/sound/interactions/foot_wet1.ogg',
						'modular_sand/sound/interactions/foot_wet2.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_FEET, partner, CUM_TARGET_PENIS) //SPLURT edit

/datum/interaction/lewd/footfuck/vag
	description = "Вагина. Потереться о ботинок."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	required_from_target_exposed = INTERACTION_REQUIRE_FEET
	required_from_target_unexposed = INTERACTION_REQUIRE_FEET
	require_target_num_feet = 1
	p13user_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/footfuck/vag/display_interaction(mob/living/user, mob/living/partner)
	var/message

	if(user.is_fucking(partner, CUM_TARGET_FEET))
	//BLUEMOON EDIT START
		message = pick("трётся своей киской о ботинок <b>[partner]</b>.",
			"игриво потирается своим клитором о ботинок <b>[partner]</b> и довольно вздыхает.",
			"мастурбирает о ботинок <b>[partner]</b> и громко постанывает.")
	else
		message = pick("с силой держится за ножку своего партнёра и активно трётся своей вагиной о ботинок <b>[partner]</b>.",
			"замедляет свои движения на ботинке <b>[partner]</b>, засекает влагу на обуви и ехидно усмехается.",
			"выставляет вагину на ботинок <b>[partner]</b> и начинает ту стимулировать. Как же радуется!")
	//BLUEMOON EDIT END
		user.set_is_fucking(partner, CUM_TARGET_FEET, user.getorganslot(ORGAN_SLOT_VAGINA))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/foot_dry3.ogg',
						'modular_sand/sound/interactions/foot_wet1.ogg',
						'modular_sand/sound/interactions/foot_wet2.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	user.handle_post_sex(NORMAL_LUST, CUM_TARGET_FEET, partner, ORGAN_SLOT_VAGINA) //SPLURT edit
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)
