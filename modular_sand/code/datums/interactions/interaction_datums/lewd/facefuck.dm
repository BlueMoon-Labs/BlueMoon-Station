/datum/interaction/lewd/facefuck
	description = "Член. Вытрахать в рот."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	var/fucktarget = "penis"
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_FACE

/datum/interaction/lewd/facefuck/vag
	description = "Вагина. Потереться об рот."
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	required_from_target = INTERACTION_REQUIRE_MOUTH
	fucktarget = "vagina"

/datum/interaction/lewd/facefuck/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/obj/item/organ/genital/genital = null
	var/retaliation_message = FALSE
	var/has_penis = user.has_penis() //BLUEMOON ADD

	if(user.is_fucking(partner, CUM_TARGET_MOUTH))
		var/improv = FALSE
		switch(fucktarget)
			if("vagina")
				if(user.has_vagina())
					message = pick(
						"втирает свою вагину в лицо \the <b>[partner]</b> и громко вздыхает.",
						"сжимает затылок \the <b>[partner]</b> усилием своих ладоней и начинает тереться о лицо своей киской",
						"прижимает свою киску к языку \the <b>[partner]</b> и тихо постанывает.",
						"скользит ротиком \the <b>[partner]</b> в своей промежности и быстро дышит через нос.",
						"нежно и довольно добродушно смотрит в глаза \the <b>[partner]</b>, когда вдруг его личико накрывается пиздой.",
						"ехидно ухмыляется и покачивает своими бёдрами перед лицом \the <b>[partner]</b>, после чего вжимается в лицо партнёра своей промежностью.",
						)
					if(partner.a_intent == INTENT_HARM)
						partner.adjustBruteLoss(2)
						retaliation_message = pick(
							"испытывает глубокое недовольство от того, что находится там.",
							"изо всех сил пытается вырваться из-под бедер \the [user].",
						)
				else
					improv = TRUE
			if("penis")
				// BLUEMOON EDIT START
				if(has_penis || user.has_strapon())
					partner.snap_choker(partner, ITEM_SLOT_NECK)	//Snap my choker!~ - Gardelin0
					message = pick(
						"грубо трахает \the <b>[partner]</b> в рот с громким чавкающим звуком.",
						"с силой загоняет сво[has_penis ? "и гениталии" : "й дилдо"] в самую глотку \the <b>[partner]</b>.",
						"надавливает на дальнюю часть язычка \the <b>[partner]</b> до тех пор, пока не услышит тугой звук от Рвотного Рефлекса.",
						"хватается за волосы \the <b>[partner]</b> и начинает тянуть к основанию своего [has_penis ? "органа" : "дилдо"].",
						"смотрит в глаза \the <b>[partner]</b>, когда [has_penis ? "член" : "дилдо"] прижимается к ожидающему язычку.",
				// BLUEMOON EDIT END
						"сильно вращает своими бёдрами и погружается в рот \the <b>[partner]</b>.",
						)
					if(partner.a_intent == INTENT_HARM)
						partner.adjustBruteLoss(2)
						retaliation_message = pick(
							"смотрит вверх из-под колен \the [user] и раз за разом пытается вывернуться в попытке выбраться.",
							"пытается вырваться из-под ног \the [user].",
						)
				else
					improv = TRUE
		if(improv)
			message = pick(
				"трётся о лицо \the <b>[partner]</b>.",
				"чувствует лицо \the <b>[partner]</b> между своими ножками.",
				"толкается против языка \the <b>[partner]</b>.",
				"хватает \the <b>[partner]</b> за волосы и начинает тянуть к своей собственной промежности",
				"беспомощно смотрит в глаза \the <b>[partner]</b> и вынужденно держится между бёдрами.",
				"с силой прижимает свои бёдра к лицу \the <b>[partner]</b>.",
				)
			if(partner.a_intent == INTENT_HARM)
				partner.adjustBruteLoss(2)
				retaliation_message = pick(
					"смотрит вверх из-под колен \the [user] и раз за разом пытается вывернуться в попытке выбраться.",
					"пытается вырваться из-под ног \the [user].",
				)
	else
		var/improv = FALSE
		switch(fucktarget)
			if("vagina")
				if(user.has_vagina())
					message = "втирает свою вагину в лицо \the <b>[partner]</b> и громко вздыхает."
				else
					improv = TRUE
			if("penis")
				if(has_penis || user.has_strapon())
					partner.snap_choker(partner, ITEM_SLOT_NECK)	//Snap my choker!~ - Gardelin0
					if(user.is_fucking(partner, CUM_TARGET_THROAT))
					// BLUEMOON EDIT START
						message = "вытягивает свой [has_penis ? "орган" : "дилдо"] из горла \the <b>[partner]</b>."
					else
						message = "засовывает сво[has_penis ? "и гениталии" : "й дилдо"] в рот \the <b>[partner]</b>."
					// BLUEMOON EDIT END
				else
					improv = TRUE
		if(improv)
			message = "суёт свою промежность в лицо \the <b>[partner]</b>."
		else
			switch(fucktarget)
				if("vagina")
					genital = partner.getorganslot(ORGAN_SLOT_VAGINA)
				if("penis")
					genital = partner.getorganslot(ORGAN_SLOT_PENIS)
		user.set_is_fucking(partner, CUM_TARGET_MOUTH, genital)
		try_apply_knot(user, partner, CUM_TARGET_MOUTH) // Проверка на узлирование.

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/oral1.ogg',
						'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(retaliation_message)
		user.visible_message("<font color=red><b>\The <b>[partner]</b></b> [retaliation_message]</span>", ignored_mobs = user.get_unconsenting())
	if(fucktarget != "penis" || user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_MOUTH, partner, genital) //SPLURT edit
	// BLUEMOON ADD START
	if(fucktarget == "penis")
		if(user.has_strapon())
			var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
			user_strapon.attached_dildo.target_reaction(partner, user, 1, CUM_TARGET_MOUTH, null, user.a_intent == INTENT_HARM)
		else
			partner.handle_post_sex(LOW_LUST, null, user, CUM_TARGET_MOUTH)
	// BLUEMOON ADD END

/datum/interaction/lewd/throatfuck
	description = "Член. Вытрахать в глотку | Убийственно."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_FACE
	p13user_duration = PLUG13_DURATION_MEDIUM
	p13target_duration = PLUG13_DURATION_MEDIUM
	p13user_strength = PLUG13_STRENGTH_DEFAULT_PLUS
	p13target_strength = PLUG13_STRENGTH_DEFAULT_PLUS

	additional_details = list(
		list(
			"info" = "Вызывает кислородную недостаточность",
			"icon" = "lungs",
			"color" = "blue"
		)
	)

	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_EXTREME_CONTENT //What I a person doesn't want to get killed? - Gardelin0

/datum/interaction/lewd/throatfuck/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/obj/item/organ/genital/genital = null
	var/retaliation_message = FALSE
	//BLUEMOON ADD START
	var/has_penis = user.has_penis()
	var/has_balls = user.has_balls()
	//BLUEMOON ADD END

	if(user.is_fucking(partner, CUM_TARGET_THROAT))
		message = "[pick(
		//BLUEMOON EDIT START
			"жёстко засовывает свой крепкий [has_penis ? "орган" : "дилдо"] в горло <b>[partner]</b> и тем самым образом своего партнёра затыкает.",
			"душит <b>[partner]</b>, снова и снова засовывая свой [has_penis ? "влажный орган" : "крепкий дилдо"] по самые [has_balls ? "яйца" : "бедра"].",
			"молотит рот <b>[partner]</b> с чавкающим звуком и раз за разом приземляется своими [has_balls ? "яйцами" : "бедрами"] аккурат в лицо.")]"
		//BLUEMOON EDIT END
		if(prob(10))
			partner.emote("cough")
			//if(prob(1) && istype(partner)) BLUEMOON DELETE не имеет смысла, сколько смотри modular_splurt\code\datums\interactions\lewd\lewd_datums.dm
			//	partner.adjustOxyLoss(rand(2,3)) да-да, оно даёт и так 6 окси урона, шанс в 1 процент ради ещё 2-3 окси урона не имеет смысла
		if(partner.a_intent == INTENT_HARM)
			partner.adjustBruteLoss(rand(3,6))
			retaliation_message = pick(
				"смотрит вверх из-под колен \the [user] и раз за разом пытается вывернуться в попытке выбраться.",
				"пытается вырваться из-под ног \the [user].",
			)
	else if(user.is_fucking(partner, CUM_TARGET_MOUTH))
		message = "проникает глубже в рот \the <b>[partner]</b> и углубляется вниз по самому горлу."
		var/check = user.getorganslot(ORGAN_SLOT_PENIS)
		if(check)
			genital = check
		user.set_is_fucking(partner, CUM_TARGET_THROAT, genital)
	else
		message = "загоняет сво[has_penis ? "и гениталии" : "й дилдо"] глубоко в рот \the <b>[partner]</b> и углубляется вниз по самому горлу." // BLUEMOON EDIT
		var/check = user.getorganslot(ORGAN_SLOT_PENIS)
		if(check)
			genital = check
		user.set_is_fucking(partner, CUM_TARGET_THROAT, genital)
		try_apply_knot(user, partner, CUM_TARGET_THROAT) // Проверка на узлирование.

	partner.snap_choker(partner, ITEM_SLOT_NECK)	//Snap my choker!~ - Gardelin0
	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/oral1.ogg',
						'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)
	user.visible_message(message = span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(retaliation_message)
		user.visible_message(message = "<font color=red><b>\The <b>[partner]</b></b> [retaliation_message]</span>", ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_THROAT, partner, genital)
	// BLUEMOON ADD START
	if(user.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
		user_strapon.attached_dildo.target_reaction(partner, user, 1, CUM_TARGET_THROAT)
	else
		partner.handle_post_sex(LOW_LUST, null, user, CUM_TARGET_THROAT)
	// BLUEMOON ADD END

/datum/interaction/lewd/double_oral
	description = "Члены. Двойное оральное проникновение"
	required_from_user = INTERACTION_REQUIRE_DOUBLE_PENIS
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_MOUTH
	write_log_user = "double oral fucked"
	write_log_target = "was double oral fucked by"
	interaction_sound = 'modular_sand/sound/interactions/oral1.ogg'

/datum/interaction/lewd/double_oral/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/shape_desc = get_penis_shape_desc(user)

	if(user.is_fucking(partner, CUM_TARGET_MOUTH))
		message = pick(
			"заполняет рот <b>[partner]</b> обоими [shape_desc], заставляя её задыхаться от напора.",
			"вводит оба члена глубоко в глотку <b>[partner]</b>, не давая ей возможности отдышаться.",
			"грубо трахает рот <b>[partner]</b> двумя членами, теряя контроль над движениями.",
			"плотно насаживает <b>[partner]</b> на оба члена, наполняя её рот до предела.",
			"двигается мощно и уверенно, заставляя <b>[partner]</b> захлёбываться стонами и слезами наслаждения.")
	else
		message = pick(
			"направляет оба [shape_desc] к губам <b>[partner]</b>, заставляя её послушно открыть рот.",
			"медленно вставляет оба члена в рот <b>[partner]</b>, чувствуя, как её губы растягиваются.",
			"плотно берёт <b>[partner]</b> за голову и начинает мягко насаживать на оба [shape_desc].")
		user.set_is_fucking(partner, CUM_TARGET_MOUTH, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/oral1.ogg',
		'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)

	user.visible_message(
		span_lewd("<b>\The [user]</b> [message]"),
		ignored_mobs = user.get_unconsenting()
	)

	// Эффекты возбуждения и оргазма
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_MOUTH, partner, ORGAN_SLOT_PENIS)

	partner.handle_post_sex(NORMAL_LUST * 2, CUM_TARGET_PENIS, user, "mouth")

	try_apply_knot(user, partner, CUM_TARGET_MOUTH)

	if(prob(25))
		user.visible_message(span_love("<b>[partner]</b> захлёбывается стонами, когда оба члена глубоко в её рту!"))

/datum/interaction/lewd/knot_oral
	description = "Член. Глубокий минет с узлом."
	required_from_user = INTERACTION_REQUIRE_KNOT
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_MOUTH
	write_log_user = "knot oral fucked"
	write_log_target = "was knot oral fucked by"
	interaction_sound = 'modular_sand/sound/interactions/champ2.ogg'

/datum/interaction/lewd/knot_oral/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/shape_desc = get_penis_shape_desc(user)

	if(user.is_fucking(partner, CUM_TARGET_MOUTH))
		message = pick(
			"вжимается глубже, двигаясь ритмично в рот <b>[partner]</b>.",
			"направляет [shape_desc] глубже, ощущая, как губы <b>[partner]</b> плотно охватывают основание.",
			"двигается настойчиво, наполняя рот <b>[partner]</b> каждым толчком.",
			"удерживает <b>[partner]</b> за голову, двигаясь всё глубже, пока узел не упирается в губы.")
	else
		message = pick(
			"вводит свой [shape_desc] в рот <b>[partner]</b> и начинает двигаться медленно.",
			"прижимается к губам <b>[partner]</b>, мягко продвигая [shape_desc] внутрь.",
			"чувствует тепло рта <b>[partner]</b> и медленно начинает двигаться.")
		user.set_is_fucking(partner, CUM_TARGET_MOUTH, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick(
		'modular_sand/sound/interactions/champ1.ogg',
		'modular_sand/sound/interactions/champ2.ogg'), 70, 1, -1)

	user.visible_message(span_lewd("<b>\\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())

	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_MOUTH, partner, ORGAN_SLOT_PENIS)
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user, "mouth")

	// гарантированное узлирование, но с проверкой префов
		try_apply_knot(user, partner, CUM_TARGET_MOUTH, FALSE, TRUE)
