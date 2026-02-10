/datum/interaction/lewd/grindface
	description = "Ножки. Потереть лицо."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_FEET
	required_from_user_unexposed = INTERACTION_REQUIRE_FEET
	require_user_num_feet = 1
	required_from_target = INTERACTION_REQUIRE_MOUTH
	p13target_emote = PLUG13_EMOTE_FACE
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/grindface/display_interaction(mob/living/user, mob/living/partner)
	var/message

	var/shoes = user.get_shoes()

	if(user.is_fucking(partner, GRINDING_FACE_WITH_FEET))
		if(shoes)
			message = "[pick(list("трёт своими ногами лицо <b>[partner]</b>.",
				"вжимает в лицо <b>[partner]</b> подошву своей обуви и ехидно посмеивается.",
				"вытирает грязь со своей обуви о лицо <b>[partner]</b> и широко ухмыляется."))]</span>"
		else
			message = "[pick(list("трёт своими ножками о лицо <b>[partner]</b>.",
				"коварно прикрывает своей босой ножкой рот и нос <b>[partner]</b> в широкой ухмылке.",
				"аккуратно проводит своей босой ножкой вдоль губ <b>[partner]</b> и клонит свою голову в бок."))]</span>"

	else if(user.is_fucking(partner, GRINDING_MOUTH_WITH_FEET))
		if(shoes)
			message = "[pick(list("вытягивает носок своей обуви изо рта <b>[partner]</b> и проводит подошвой по лицу партнёра.",
				"медленно убирает носок своей обуви изо рта <b>[partner]</b> и прижимает влажную подошву к лицу партнёра"))]</span>"
		else
			message = "[pick(list("вытаскивает свои босые ноги изо рта <b>[partner]</b> и проводит ими по лицу своего партнёра.",
				"медленно уобирает свои влажные босые ноги изо рта <b>[partner]</b> и проводит ими по лицу своего партнёра"))]</span>"

		user.set_is_fucking(partner, GRINDING_FACE_WITH_FEET, null)

	else
		if(shoes)
			message = "[pick(list("укладывает подошву своей обуви поверх лица <b>[partner]</b>.",
				"кладёт свою обувь на лицо <b>[partner]</b> и с силой на него давит в ехидной улыбке.",
				"грубо надавливает на лицо своей обувью <b>[partner]</b> и, облизываясь, начинает ей растирать."))]</span>"
		else
			message = "[pick(list("укладывает свою босую ножку поверх лица <b>[partner]</b>.",
				"расслабленно укладыват свои босые ножки на лицо <b>[partner]</b> и начинает душить партнёра в ухмылке.",
				"располагает свои босые ножки поверх лица <b>[partner]</b>"))]</span>"

		user.set_is_fucking(partner, GRINDING_FACE_WITH_FEET, null)

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/foot_dry2.ogg',
						'modular_sand/sound/interactions/foot_dry3.ogg',
						'modular_sand/sound/interactions/foot_dry4.ogg'), 70, 1, -1)
	user.visible_message(message = span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	partner.handle_post_sex(LOW_LUST, null, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

/datum/interaction/lewd/grindmouth
	description = "Ножки. Углубиться в ротик."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_FEET
	required_from_user_unexposed = INTERACTION_REQUIRE_FEET
	require_user_num_feet = 1
	required_from_target = INTERACTION_REQUIRE_MOUTH
	p13target_emote = PLUG13_EMOTE_FACE
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/grindmouth/display_interaction(mob/living/user, mob/living/partner)
	var/message

	//var/u_His = user.ru_ego()
	var/t_His = partner.ru_ego()
	var/t_Him = partner.ru_na()
	var/t_He = partner.ru_who()
	//var/t_S = partner.p_s()

	var/shoes = user.get_shoes()

	if(user.is_fucking(partner, GRINDING_MOUTH_WITH_FEET))
		if(shoes)
			message = "[pick(list("грубо проталкивает свои [shoes] глубже в рот <b>[partner]</b>.",
				"резко вставляет ещё дюйм своих [shoes] в ротик <b>[partner]</b>.",
				"прижимает своим весом проходит глубже в рот <b>[partner]</b> своими [shoes]."))]</span>"
		else
			message = "[pick(list("ёрзает своими ножками глубоко во рту <b>[partner]</b>.",
				"проталкивает свои ступни внутрь ротика <b>[partner]</b>, заставляя [t_Him] давиться.",
				"небрежно отплалировывает свои ноги на языке <b>[partner]</b>."))]</span>"

	else if(user.is_fucking(partner, GRINDING_FACE_WITH_FEET))
		if(shoes)
			message = "[pick(list("решает устремить свои [shoes] внутрь рта <b>[partner]</b>.",
				"надавливает своими [shoes] на губы <b>[partner]</b> и проталкивает их внутрь."))]</span>"
		else
			message = "[pick(list("приоткрывает ротик <b>[partner]</b>'s своими ступнями и вставляет свою ножку внутрь.",
				"ещё сильнее давит своими ножками, вставляя их в рот <b>[partner]</b>."))]</span>"

		user.set_is_fucking(partner, GRINDING_MOUTH_WITH_FEET, null)

	else
		if(shoes)
			message = "[pick(list("заканчивает последние приготовления и одним движением вставляет свои [shoes] в ротик <b>[partner]</b>.",
				"трётся своими [shoes] об рот <b>[partner]</b> перед тем как вставить их внутрь."))]</span>"
		else
			message = "[pick(list("трёт своими грязными ступнями по лицу <b>[partner]</b> перед тем как вставить их в [t_His] рот.",
				"вставляет свои ножки в рот <b>[partner]</b>.",
				"закрывает носик и ротик <b>[partner]</b> своей ножкой, пока [t_He] не начнёт вздыхать от недостатка воздуха, а после, вставляет обе ножки в рот <b>[partner]</b>, до того как [t_He] сможет откликнуться."))]</span>"
		user.set_is_fucking(partner, GRINDING_MOUTH_WITH_FEET, null)

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_wet1.ogg',
						'modular_sand/sound/interactions/foot_wet2.ogg',
						'modular_sand/sound/interactions/foot_wet3.ogg'), 70, 1, -1)
	user.visible_message(message = span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	partner.handle_post_sex(LOW_LUST, null, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

/datum/interaction/lewd/footjob
	description = "Ножки. Подрочить одной ногой."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_FEET
	required_from_user_unexposed = INTERACTION_REQUIRE_FEET
	require_user_num_feet = 1
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	p13target_emote = PLUG13_EMOTE_PENIS
	p13target_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/footjob/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//var/u_His = user.ru_ego()
	var/shoes = user.get_shoes(TRUE)
	var/genital_name = partner.get_penetrating_genital_name()

	if(partner.is_fucking(src, CUM_TARGET_FEET))
		message = "[pick("дрочит [genital_name] <b>[partner]</b> своими [shoes ? shoes : pick("ножками", "ступнями")].",
			"ласкает своими [shoes ? shoes : pick("ножками", "ногами", "ступнями")] промежность <b>[partner]</b>.",
			"работает [shoes ? shoes : pick("ножками", "ступнями")], двигая оные вверх-вниз по члену <b>[partner]</b>.")]"
	else
		message = "[pick("[shoes ? "занимает своими '[shoes]' позицию на" :"занимает своими ножками позицию на"] \the <b>[partner]</b>'s [genital_name].",
			"начинает играться с пенисом <b>[partner]</b> своими [shoes ? shoes :"ногами"].")]"
		partner.set_is_fucking(user, CUM_TARGET_FEET, partner.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/foot_dry3.ogg',
						'modular_sand/sound/interactions/foot_wet1.ogg',
						'modular_sand/sound/interactions/foot_wet2.ogg'), 70, 1, -1)
	user.visible_message(message = span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(partner.can_penetrating_genital_cum())
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_FEET, user, ORGAN_SLOT_PENIS) //SPLURT edit

/datum/interaction/lewd/footjob/double
	description = "Ножки. Подрочить двумя ногами."
	require_user_num_feet = 2
	p13target_strength = PLUG13_STRENGTH_NORMAL_PLUS

/datum/interaction/lewd/footjob/double/display_interaction(mob/living/user, mob/living/partner)
	var/message
	//var/u_His = user.ru_ego()
	var/shoes = user.get_shoes()
	var/genital_name = partner.get_penetrating_genital_name()

	if(partner.is_fucking(user, CUM_TARGET_FEET))
		message = "[pick("дрочит <b>[partner]</b> своими [shoes ? shoes : pick("ножками", "ступнями")].",
			"ласкает своими [shoes ? shoes : pick("ножками", "ступнями")] промежность <b>[partner]</b>.",
			"ласкает [shoes ? "своими [shoes]" : "всей своей ножкой"] <b>[partner]</b>'s [genital_name].",
			"работает [shoes ? shoes : pick("ножками", "ступнями")] вверх-вниз по <b>[partner]</b>'s [genital_name].")]"
	else
		message = "[pick("[shoes ? "окутывает своими [shoes]" : "окутывает своими [pick("ножками", "ступнями")]"] <b>[partner]</b>'s [genital_name].",
			"начинает играться с <b>[partner]</b>'s [genital_name], своими [shoes ? shoes :"ногами"].")]"
		partner.set_is_fucking(user, CUM_TARGET_FEET, partner.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/foot_dry3.ogg',
						'modular_sand/sound/interactions/foot_wet1.ogg',
						'modular_sand/sound/interactions/foot_wet2.ogg'), 70, 1, -1)
	user.visible_message(message = span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(partner.can_penetrating_genital_cum())
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_FEET, user, ORGAN_SLOT_PENIS) //SPLURT edit

/datum/interaction/lewd/footjob/vagina
	description = "Ножка. Потереть киску."
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	p13target_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/footjob/vagina/display_interaction(mob/living/user, mob/living/partner)
	var/message

	//var/u_His = user.ru_ego()

	var/shoes = user.get_shoes(TRUE)

	if(partner.is_fucking(user, CUM_TARGET_FEET))
		message = "[pick("трёт клитор <b>[partner]</b> своими [shoes ? shoes : pick("ножками", "ступнями")].",
			"трёт своими [shoes ? shoes : pick("ножками", "ногами", "ступнями")] непристойности <b>[partner]</b>.",
			"растирает своими [shoes ? shoes : pick("ножками", "ногами", "ступнями")] вагину <b>[partner]</b>.",
			"трёт свою ногу об вагину <b>[partner]</b>.")]"
	else
		message = "[pick("[shoes ? "занимает своими [shoes] позицию на" :"занимает своими ножками позицию на"] вагине <b>[partner]</b>.",
			"начинает играться с киской <b>[partner]</b> своими '[shoes ? shoes : "ногами"]'.")]"
		partner.set_is_fucking(user, CUM_TARGET_FEET, partner.getorganslot(ORGAN_SLOT_VAGINA))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/foot_dry3.ogg',
						'modular_sand/sound/interactions/foot_wet1.ogg',
						'modular_sand/sound/interactions/foot_wet2.ogg'), 70, 1, -1)
	user.visible_message(message = span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_FEET, user, ORGAN_SLOT_VAGINA) //SPLURT edit
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)
