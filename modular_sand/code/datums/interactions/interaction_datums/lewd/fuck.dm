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
			"долбится в киску <b>[partner]</b>, пуская в ход свой [shape_desc].",
			"глубоко вводит свой [shape_desc] во влагалище <b>[partner]</b>.",
			"с силой загоняет свой [shape_desc] в вагину <b>[partner]</b> и шлёпается своими [has_balls ? "яйцами" : "бедрами"].",
			"ритмично двигается, заставляя <b>[partner]</b> дрожать при каждом толчке.",
			"жадно насаживает <b>[partner]</b> на свой [shape_desc], теряя самообладание.")
	else
		message = pick(
			"медленно вводит свой [shape_desc] в лоно <b>[partner]</b>, наслаждаясь тёплотой.",
			"плотно прижимается к <b>[partner]</b> и аккуратно погружает свой [shape_desc].",
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

	if(prob(partner.get_lust() / partner.get_climax_threshold() * 50)) // 50%
		switch(partner.a_intent)
			if(INTENT_HELP)
				user.visible_message(
					pick(span_lewd("<b>[partner]</b> подрагивает от удовольствия."),
						span_lewd("<b>[partner]</b> стонет, выгибаясь навстречу."),
						span_lewd("<b>[partner]</b> слабо постанывает, чувствуя каждый толчок.")))
			if(INTENT_HARM)
				user.visible_message(
					pick(span_lewd("<b>[partner]</b> резко пихает <b>[user]</b>, с гневом на лице."),
						span_lewd("<b>[partner]</b> кусает <b>[user]</b> за плечо."),
						span_lewd("<b>[partner]</b> злится, пытаясь прекратить происходящее.")))
			else
				user.visible_message(
					pick(span_lewd("<b>[partner]</b> извивается в руках <b>[user]</b>, с трудом сдерживая стон."),
						span_lewd("<b>[partner]</b> ерзает под <b>[user]</b>, не сдерживая себя.")))

/datum/interaction/lewd/fuck/anal
	description = "Член. Проникнуть в задницу."
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
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

	if(prob(partner.get_lust() / partner.get_climax_threshold() * 50)) // 50%
		switch(partner.a_intent)
			if(INTENT_HELP)
				user.visible_message(
					pick(span_lewd("<b>[partner]</b> подрагивает от удовольствия."),
						span_lewd("<b>[partner]</b> стонет, выгибаясь навстречу."),
						span_lewd("<b>[partner]</b> слабо постанывает, чувствуя каждый толчок.")))
			if(INTENT_HARM)
				user.visible_message(
					pick(span_lewd("<b>[partner]</b> резко пихает <b>[user]</b>, с гневом на лице."),
						span_lewd("<b>[partner]</b> кусает <b>[user]</b> за плечо."),
						span_lewd("<b>[partner]</b> злится, пытаясь прекратить происходящее.")))
			else
				user.visible_message(
					pick(span_lewd("<b>[partner]</b> извивается в руках <b>[user]</b>, с трудом сдерживая стон."),
						span_lewd("<b>[partner]</b> ерзает под <b>[user]</b>, не сдерживая себя.")))

	// BLUEMOON EDIT START
	if(user.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
		user_strapon.attached_dildo.target_reaction(partner, user, 0, CUM_TARGET_ANUS, null, user.a_intent == INTENT_HARM)
	else
		partner.handle_post_sex(NORMAL_LUST, null, user, CUM_TARGET_ANUS) //SPLURT edit
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

/datum/interaction/lewd/double_penetration
	description = "Члены. Двойное проникновение"
	required_from_user = INTERACTION_REQUIRE_DOUBLE_PENIS
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA | INTERACTION_REQUIRE_ANUS
	write_log_user = "double penetrated"
	write_log_target = "was double penetrated by"
	additional_details = list(INTERACTION_MAY_CAUSE_PREGNANCY)
	interaction_sound = null

/datum/interaction/lewd/double_penetration/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/shape_desc = get_penis_shape_desc(user)

	if(user.is_fucking(partner, CUM_TARGET_VAGINA) && user.is_fucking(partner, CUM_TARGET_ANUS))
		message = pick(
			"одновременно долбится в киску и задницу <b>[partner]</b>, двигаясь мощно и ритмично.",
			"заполняет оба отверстия <b>[partner]</b> своими [shape_desc], доводя её до экстаза.",
			"плотно насаживает <b>[partner]</b> сразу на два члена, лишая её дыхания от удовольствия.",
			"ритмично двигается, заставляя <b>[partner]</b> дрожать при каждом двойном толчке.",
			"жадно проникает в оба отверстия <b>[partner]</b>, чувствуя каждое сжатие.")
	else
		message = pick(
			"аккуратно направляет оба своих [shape_desc] — один к вагине, другой к анусу <b>[partner]</b>.",
			"плотно прижимается к <b>[partner]</b> и начинает двойное проникновение.",
			"ловко совмещает движения, вводя оба члена одновременно в анус и киску <b>[partner]</b>.")
		user.set_is_fucking(partner, CUM_TARGET_VAGINA, user.getorganslot(ORGAN_SLOT_PENIS))
		user.set_is_fucking(partner, CUM_TARGET_ANUS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/champ1.ogg',
		'modular_sand/sound/interactions/bang3.ogg'), 70, 1, -1)

	user.visible_message(
		span_lewd("<b>\The [user]</b> [message]"),
		ignored_mobs = user.get_unconsenting()
	)

	// Эффекты возбуждения и оргазма
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_VAGINA, partner, ORGAN_SLOT_PENIS)
		user.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_ANUS, partner, ORGAN_SLOT_PENIS)

	partner.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_PENIS, user, ORGAN_SLOT_VAGINA)
	partner.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_PENIS, user, "anus")

	try_apply_knot(user, partner, CUM_TARGET_VAGINA)
	try_apply_knot(user, partner, CUM_TARGET_ANUS)

	if(prob(25))
		user.visible_message(span_love("<b>[partner]</b> выгибается от переполняющих ощущений, не выдерживая двойного проникновения!"))

/datum/interaction/lewd/double_vaginal
	description = "Члены. Двойное вагинальное проникновение"
	required_from_user = INTERACTION_REQUIRE_DOUBLE_PENIS
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	write_log_user = "double vaginal fucked"
	write_log_target = "was double vaginally fucked by"
	additional_details = list(INTERACTION_MAY_CAUSE_PREGNANCY)
	interaction_sound = null

/datum/interaction/lewd/double_vaginal/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/shape_desc = get_penis_shape_desc(user)

	if(user.is_fucking(partner, CUM_TARGET_VAGINA))
		message = pick(
			"заполняет киску <b>[partner]</b> обоими [shape_desc], двигаясь в унисон.",
			"жадно насаживает <b>[partner]</b> на два члена, растягивая её до предела.",
			"ритмично долбит киску <b>[partner]</b>, заставляя тело дрожать от переполняющего жара.",
			"заполняет влагалище <b>[partner]</b> каждым движением, не давая отдышаться.")
	else
		message = pick(
			"направляет оба [shape_desc] ко входу во влагалище <b>[partner]</b> и начинает проникновение.",
			"плотно прижимается к <b>[partner]</b> и медленно погружает оба члена внутрь.",
			"ловко вводит оба члена в киску <b>[partner]</b>, чувствуя её сжатие.")
		user.set_is_fucking(partner, CUM_TARGET_VAGINA, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/champ1.ogg',
		'modular_sand/sound/interactions/champ2.ogg'), 70, 1, -1)

	user.visible_message(
		span_lewd("<b>\The [user]</b> [message]"),
		ignored_mobs = user.get_unconsenting()
	)

	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_VAGINA, partner, ORGAN_SLOT_PENIS)
	partner.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_PENIS, user, ORGAN_SLOT_VAGINA)

	try_apply_knot(user, partner, CUM_TARGET_VAGINA)

	if(prob(25))
		user.visible_message(span_love("<b>[partner]</b> стонет, чувствуя, как оба члена растягивают её влагалище!"))

/datum/interaction/lewd/double_anal
	description = "Члены. Двойное анальное проникновение"
	required_from_user = INTERACTION_REQUIRE_DOUBLE_PENIS
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	write_log_user = "double anal fucked"
	write_log_target = "was double anally fucked by"
	interaction_sound = null

/datum/interaction/lewd/double_anal/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/shape_desc = get_penis_shape_desc(user)

	if(user.is_fucking(partner, CUM_TARGET_ANUS))
		message = pick(
			"грубо долбится в задницу <b>[partner]</b> обоими [shape_desc], не давая ей передохнуть.",
			"заполняет анальное колечко <b>[partner]</b> двумя членами, двигаясь в унисон.",
			"с силой насаживает <b>[partner]</b> на оба члена, заставляя зад активно трястись.",
			"входит глубоко и одновременно двумя членами в задницу <b>[partner]</b>, теряя контроль.")
	else
		message = pick(
			"аккуратно направляет оба [shape_desc] к анальному отверстию <b>[partner]</b>.",
			"растягивает анус <b>[partner]</b> кончиками обоих членов и начинает медленно входить.",
			"совмещает движения, проникая сразу двумя членами внутрь.")
		user.set_is_fucking(partner, CUM_TARGET_ANUS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/bang1.ogg',
		'modular_sand/sound/interactions/bang2.ogg'), 70, 1, -1)

	user.visible_message(
		span_lewd("<b>\The [user]</b> [message]"),
		ignored_mobs = user.get_unconsenting()
	)

	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_ANUS, partner, ORGAN_SLOT_PENIS)
	partner.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_PENIS, user, "anus")

	try_apply_knot(user, partner, CUM_TARGET_ANUS)

	if(prob(25))
		user.visible_message(span_love("<b>[partner]</b> вскрикивает, не выдерживая давления двух членов в заднице!"))

/datum/interaction/lewd/knot_fuck
	description = "Член. Проникнуть в Вагину с узлированием"
	required_from_user = INTERACTION_REQUIRE_KNOT
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	write_log_user = "knot fucked"
	write_log_target = "was knot fucked by"
	interaction_sound = null
	additional_details = list(INTERACTION_MAY_CAUSE_PREGNANCY)

/datum/interaction/lewd/knot_fuck/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/shape_desc = get_penis_shape_desc(user)

	if(user.is_fucking(partner, CUM_TARGET_VAGINA))
		message = pick(
			"ритмично долбится в киску <b>[partner]</b>, чувствуя, как узел начинает набухать.",
			"жадно насаживает <b>[partner]</b> на [shape_desc], чувствуя плотное сцепление.",
			"двигается мощно, заставляя узел застрять глубоко во влагалище <b>[partner]</b>.",
			"с силой вдавливает узел внутрь, запирая <b>[partner]</b> на своём члене.")
	else
		message = pick(
			"аккуратно вставляет свой [shape_desc] во влагалище <b>[partner]</b>.",
			"медленно прижимается, продвигая узел глубже внутрь <b>[partner]</b>.",
			"вводит [shape_desc], чувствуя, как узел плотно обхватывается мышцами <b>[partner]</b>.")
		user.set_is_fucking(partner, CUM_TARGET_VAGINA, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/champ1.ogg',
		'modular_sand/sound/interactions/champ2.ogg'), 70, 1, -1)

	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())

	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_VAGINA, partner, ORGAN_SLOT_PENIS)
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user, ORGAN_SLOT_VAGINA)

	//  ГАРАНТИРОВАННОЕ узлирование
		try_apply_knot(user, partner, CUM_TARGET_VAGINA, FALSE, TRUE)

/datum/interaction/lewd/knot_anal_fuck
	description = "Член. Анальное проникновение с узлированием."
	required_from_user = INTERACTION_REQUIRE_KNOT
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	write_log_user = "knot anal fucked"
	write_log_target = "was knot anal fucked by"
	interaction_sound = null

/datum/interaction/lewd/knot_anal_fuck/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/shape_desc = get_penis_shape_desc(user)

	if(user.is_fucking(partner, CUM_TARGET_ANUS))
		message = pick(
			"двигается мощно, заполняя задницу <b>[partner]</b> своим [shape_desc].",
			"глубоко вдавливает [shape_desc] в анус <b>[partner]</b>, чувствуя, как мышцы плотно сжимаются вокруг.",
			"плотно насаживает <b>[partner]</b> на свой [shape_desc], не оставляя ей ни малейшего шанса вырваться.",
			"вновь и вновь проникает в задницу <b>[partner]</b>, теряя контроль над движениями.")
	else
		message = pick(
			"направляет свой [shape_desc] к заднице <b>[partner]</b> и медленно входит.",
			"плотно прижимается и осторожно проникает в анус <b>[partner]</b>.",
			"чувствует, как мышцы ануса <b>[partner]</b> обхватывают его [shape_desc].")
		user.set_is_fucking(partner, CUM_TARGET_ANUS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/champ1.ogg',
		'modular_sand/sound/interactions/bang3.ogg'), 70, 1, -1)

	user.visible_message(span_lewd("<b>\\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())

	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_ANUS, partner, ORGAN_SLOT_PENIS)
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user, "anus")

		try_apply_knot(user, partner, CUM_TARGET_ANUS, FALSE, TRUE)

