/datum/interaction/lewd/oral
	description = "Вагина. Вылизать."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	write_log_user = "gave head to"
	write_log_target = "was given head by"
	interaction_sound = null
	additional_details = list(
		INTERACTION_MAY_CONTAIN_DRINK
	)
	var/fucktarget = "vagina"
	p13user_emote = PLUG13_EMOTE_MOUTH
	p13target_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/oral/blowjob
	description = "Член. Отсосать."
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	fucktarget = "penis"
	p13user_emote = PLUG13_EMOTE_MOUTH
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/oral/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/obj/item/organ/genital/genital = null
	var/lust_increase = NORMAL_LUST
	var/has_penis = partner.has_penis() // BLUEMOON ADD

	if(partner.is_fucking(user, CUM_TARGET_MOUTH))
		if(prob(partner.get_sexual_potency()))
			user.adjustOxyLoss(1)
			switch(fucktarget)
				if("vagina")
					message = "становится всё проворней и проворней в случае с киской \the <b>[partner]</b>."
					lust_increase += 5
				if("penis")
					message = "становится всё проворней и проворней в случае с [has_penis ? "членом" : "дилдо"] \the <b>[partner]</b>." // BLUEMOON EDIT
					lust_increase += 5
		else
			var/improv = FALSE
			switch(fucktarget)
				if("vagina")
					if(partner.has_vagina())
						message = pick(
							"вылизывает киску \the <b>[partner]</b> и громко чавкает.",
							"проводит своим язычком вдоль половых губ \the <b>[partner]</b> и заостряет своё внимание на клиторе.",
							"обводит щель \the <b>[partner]</b> своим горячим язычком.",
							"толкается своим языком к киске \the <b>[partner]</b> и проводит его кончик к самому клитору.",
							"медленно делает круги своим язычком, увлажняя киску \the <b>[partner]</b>.",
							"целует нежные лепестки \the <b>[partner]</b> и миловидно улыбается.",
							"пробует \the <b>[partner]</b> на вкус, шутливо касаясь нежных лепестков зубами.",
						)
					else
						improv = TRUE
				if("penis")
				//BLUEMOON EDIT START
					if(has_penis || partner.has_strapon())
						message = pick(
							"довольно отсасывает [has_penis ? "мясо" : "дилдо"] \the <b>[partner]</b>, крепко удерживая [has_penis ? "орган" : "его"] рукой.",
							"нежно проводит своим язычком вдоль всего [has_penis ? "органа" : "дилдо"] \the <b>[partner]</b>.",
							"обводит [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> своим горячим язычком.",
							"обхватывает головку [has_penis ? "члена" : "дилдо"] \the <b>[partner]</b> своими губками и с нежностью производит круговые движения язычком.",
							"медленно погружает [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> в своё горло вплоть до тугого вздоха и резко вытаскивает его, громко вдыхая",
							"ласково целует [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> и миловидно улыбается.",
							"с силой обхватывает [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> и пару раз бьёт им себя по рту.",
				//BLUEMOON EDIT END
						)
					else
						improv = TRUE
			if(improv)
				// get confused about how to do the sex
				message = pick(
					"облизывает \the <b>[partner]</b>.",
					"выглядит немного неуверенно в том, куда лизать \the <b>[partner]</b>.",
					"трётся своим язычком в промежности \the <b>[partner]</b> и оставляет после себя слюни.",
					"целует бедро \the <b>[partner]</b> в лёгкой улыбке.",
					"старательно водит своими губами вдоль промежности \the <b>[partner]</b>.",
				)
	else
		var/improv = FALSE
		switch(fucktarget)
			if("vagina")
				if(partner.has_vagina())
					message = pick(
						"довольно облизывается и зарывается своим лицом в киску \the <b>[partner]</b>.",
						"прижимается своим мокрым и достаточно тёплым носиком к промежности \the <b>[partner]</b>.",
						"обнаруживает себя между бёдрами \the <b>[partner]</b> и раз за разом пытается сделать партнёру хорошо.",
						"держится на коленях перед \the <b>[partner]</b> и работает своим язычком.",
						"с силой хватается за ножки \the <b>[partner]</b> и разводит их в стороны.",
						"погружает своё лицо между бёдрами \the <b>[partner]</b> и активно облизывается, проявляя всё больше влаги.",
					)
				else
					improv = TRUE
			if("penis")
			//BLUEMOON EDIT START
				if(has_penis || partner.has_strapon())
					message = pick(
						"довольно отсасывает [has_penis ? "мясо" : "дилдо"] \the <b>[partner]</b>, крепко удерживая [has_penis ? "орган" : "его"] рукой.",
						"нежно проводит своим язычком вдоль всего [has_penis ? "органа" : "дилдо"] \the <b>[partner]</b>.",
						"обводит [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> своим горячим язычком.",
						"обхватывает головку [has_penis ? "члена" : "дилдо"] \the <b>[partner]</b> своими губками и с нежностью производит круговые движения язычком.",
						"медленно погружает [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> в своё горло вплоть до тугого вздоха и резко вытаскивает его, громко вдыхая",
						"ласково целует [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> и миловидно улыбается.",
						"с силой обхватывает [has_penis ? "орган" : "дилдо"] \the <b>[partner]</b> и пару раз бьёт им себя по рту.",
			//BLUEMOON EDIT END
					)
				else
					improv = TRUE
		if(improv)
			message = pick(
				"облизывает \the <b>[partner]</b>.",
				"целует бедро \the <b>[partner]</b> в лёгкой улыбке.",
				"трётся своим язычком в промежности \the <b>[partner]</b> и оставляет после себя слюни.",
				"бросает короткий и довольно озадаченный взгляд между бёдрами \the <b>[partner]</b>.",
				"выглядит немного неуверенно в том, куда лизать \the <b>[partner]</b>. Как же быть в отсутствии гениталий?",
				"хлопает глазами при взгляде в промежность \the <b>[partner]</b> и ожидает, что здесь будет член, киска... или что-то в этом роде.",
			)
			genital = null
		else
			switch(fucktarget)
				if("vagina")
					genital = partner.getorganslot(ORGAN_SLOT_VAGINA)
				if("penis")
					genital = partner.getorganslot(ORGAN_SLOT_PENIS)
		partner.set_is_fucking(user, CUM_TARGET_MOUTH, genital)
		try_apply_knot(partner, user, CUM_TARGET_MOUTH)

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/bj1.ogg',
									'modular_sand/sound/interactions/bj2.ogg',
									'modular_sand/sound/interactions/bj3.ogg',
									'modular_sand/sound/interactions/bj4.ogg',
									'modular_sand/sound/interactions/bj5.ogg',
									'modular_sand/sound/interactions/bj6.ogg',
									'modular_sand/sound/interactions/bj7.ogg',
									'modular_sand/sound/interactions/bj8.ogg',
									'modular_sand/sound/interactions/bj9.ogg',
									'modular_sand/sound/interactions/bj10.ogg',
									'modular_sand/sound/interactions/bj11.ogg'), 50, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
//BLUEMOON EDIT START
//SPLURT EDIT START
	if(fucktarget == "penis" && partner.can_penetrating_genital_cum())
		partner.handle_post_sex(lust_increase, CUM_TARGET_MOUTH, user, ORGAN_SLOT_PENIS)
	else if(fucktarget == "vagina" && partner.has_vagina())
		partner.handle_post_sex(lust_increase, CUM_TARGET_MOUTH, user, ORGAN_SLOT_VAGINA)

	if(fucktarget == "penis")
		if(!(has_penis) && partner.has_strapon())
			var/obj/item/clothing/underwear/briefs/strapon/user_strapon = partner.get_strapon()
			user_strapon.attached_dildo.target_reaction(user, partner, 1, CUM_TARGET_MOUTH, null, partner.a_intent == INTENT_HARM)
		else
			user.handle_post_sex(LOW_LUST, null, partner, CUM_TARGET_THROAT)
//SPLURT EDIT END
//BLUEMOON EDIT END
