/datum/interaction/lewd/nipsuck
	description = "Грудь. Пососать соски."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_target_exposed = INTERACTION_REQUIRE_BREASTS
	write_log_user = "sucked nipples"
	write_log_target = "had their nipples sucked by"
	interaction_sound = null
	p13target_emote = PLUG13_EMOTE_BREASTS
	additional_details = list(
		INTERACTION_MAY_CONTAIN_DRINK
	)

/datum/interaction/lewd/nipsuck/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/user_message
	var/amount_high = 2

	switch(user.a_intent)
		if(INTENT_HELP, INTENT_DISARM)
			user_message = pick(span_lewd("<b>[user]</b> осторожно обсасывает [pick("сосок", "соски")] <b>[target]</b>"),
							span_lewd("<b>[user]</b> аккуратно хватается ртом за [pick("сосок", "соски")] <b>[target]</b>"),
							span_lewd("<b>[user]</b> лижет [pick("сосок", "соски")] <b>[target]</b>"),
							span_lewd("<b>[user]</b> облизывает [pick("сосок", "соски")] <b>[target]</b>"))
			target.handle_post_sex(LOW_LUST, null, user, ORGAN_SLOT_BREASTS) //BLUEMOON ADD
		if(INTENT_HARM)
			amount_high = 3 // aggressive sucking has higher rewards
			user_message = pick(span_lewd("<b>[user]</b> кусает [pick("сосок", "соски")] <b>[target]</b>"),
							span_lewd("<b>[user]</b> грубо всасывает [pick("сосок", "соски")] <b>[target]</b>"),
							span_lewd("<b>[user]</b> грубо обсасывает [pick("сосок", "соски")] <b>[target]</b>"))
			//BLUEMOON ADD START
			if(HAS_TRAIT(target,TRAIT_MASO))
				target.handle_post_sex(NORMAL_LUST, null, user, ORGAN_SLOT_BREASTS)
			else
				target.handle_post_sex(max(LOW_LUST-2,0), null, user, ORGAN_SLOT_BREASTS) //Без мазохима, меньше удовольствия
			//BLUEMOON ADD END
		if(INTENT_GRAB)
			amount_high = 3 // aggressive sucking has higher rewards
			user_message = pick(span_lewd("<b>[user]</b> активно сосёт [pick("сосок", "соски")] <b>[target]</b>"),
							span_lewd("<b>[user]</b> с силой втягивает в свой рот [pick("сосок", "соски")] <b>[target]</b>"),
							span_lewd("<b>[user]</b> крепко держит грудь <b>[target]</b> и обсасывает [pick("сосок", "соски")]"))
			target.handle_post_sex(LOW_LUST*1.5, null, user, ORGAN_SLOT_BREASTS) //BLUEMOON ADD
	user.visible_message(user_message)
	var/has_breasts = target.has_breasts()
	if(has_breasts == TRUE || has_breasts == HAS_EXPOSED_GENITAL)
		var/obj/item/organ/genital/breasts/B = target.getorganslot(ORGAN_SLOT_BREASTS)
		var/modifier = B?.get_lactation_amount_modifier() || 1
		if(B?.fluid_id)
			var/milktype = B?.fluid_id
			var/datum/reagent/milk = find_reagent_object_from_type(milktype)
			var/milktext = milk.name //So you know what are you drinking. - Gardelin0
			user.reagents.add_reagent(B.fluid_id, rand(1,amount_high * modifier) * user.get_fluid_mod(B))
			user_message += ", вытягивая <b>'[lowertext(milktext)]'</b>."

	if(prob(target.get_lust() / target.get_climax_threshold() * 50)) // 50%
		switch(target.a_intent)
			if(INTENT_HELP)
				if(!target.has_breasts())
					user.visible_message(
						pick(span_lewd("<b>[target]</b> дрожит от возбуждения."),
							span_lewd("<b>[target]</b> тихо стонет."),
							span_lewd("<b>[target]</b> довольно постанывает."),
							span_lewd("<b>[target]</b> задыхается в удовольствии."),
							span_lewd("<b>[target]</b> тихонько вздрагивает.")))
				else
					user.visible_message(
						pick(span_lewd("<b>[target]</b> дрожит от возбуждения."),
							span_lewd("<b>[target]</b> тихо стонет."),
							span_lewd("<b>[target]</b> довольно постанывает."),
							span_lewd("<b>[target]</b> задыхается в удовольствии."),
							span_lewd("<b>[target]</b> тихонько вздрагивает.")))
				if(target.get_lust() < 5)
					target.handle_post_sex(5, CUM_TARGET_MOUTH, user, ORGAN_SLOT_BREASTS) //SPLURT edit
			if(INTENT_DISARM)
				if (target.restrained())
					if(!target.has_breasts())
						user.visible_message(
							pick(span_lewd("<b>[target]</b> игриво извивается, будучи в физических ограничениях."),
								span_lewd("<b>[target]</b> игриво вырывается из захвата <b>[user]</b>."),
								span_lewd("<b>[target]</b> игриво отводит грудь от <b>[user]</b>."),
								span_lewd("<b>[target]</b> с отсутствующим сопротивлением толкается ближе к <b>[user]</b>.")))
					else
						user.visible_message(
							pick(span_lewd("<b>[target]</b> игриво извивается, будучи в физических ограничениях."),
								span_lewd("<b>[target]</b> игриво вырывается из захвата <b>[user]</b>."),
								span_lewd("<b>[target]</b> игриво отводит грудь от <b>[user]</b>."),
								span_lewd("<b>[target]</b> с отсутствующим сопротивлением толкается ближе к <b>[user]</b>.")))
				else
					if(!target.has_breasts())
						user.visible_message(
							pick(span_lewd("<b>[target]</b> игриво извивается."),
								span_lewd("<b>[target]</b> игриво вырывается из захвата <b>[user]</b>."),
								span_lewd("<b>[target]</b> игриво отводит грудь от <b>[user]</b>."),
								span_lewd("<b>[target]</b> с отсутствующим сопротивлением толкается ближе к <b>[user]</b>.")))
					else
						user.visible_message(
							pick(span_lewd("<b>[target]</b> игриво извивается."),
								span_lewd("<b>[target]</b> игриво вырывается из захвата <b>[user]</b>."),
								span_lewd("<b>[target]</b> игриво отводит грудь от <b>[user]</b>"),
								span_lewd("<b>[target]</b> с отсутствующим сопротивлением толкается ближе к <b>[user]</b>")))
				if(target.get_lust() < 10)
					target.handle_post_sex(NORMAL_LUST, CUM_TARGET_MOUTH, user, ORGAN_SLOT_BREASTS) //SPLURT edit
			if(INTENT_GRAB)
				user.visible_message(
						pick(span_lewd("<b>[target]</b> крепко сжимает запястье <b>[user]</b>."),
						span_lewd("<b>[target]</b> впивается ногтями в кожный покров <b>[user]</b>."),
						span_lewd("<b>[target]</b> мешает всяческой деятельности <b>[user]</b>.")))
			if(INTENT_HARM)
				user.adjustBruteLoss(rand(1, 4))
				user.visible_message(
						pick(span_lewd("<b>[target]</b> грубо отталкивает <b>[user]</b>."),
						span_lewd("<b>[target]</b> сердито впивается в руку <b>[user]</b>."),
						span_lewd("<b>[target]</b> сопротивляется всяческой деятельности <b>[user]</b>."),
						span_lewd("<b>[target]</b> демонстративно щёлкает своей челюстью перед <b>[user]</b>."),
						span_lewd("<b>[target]</b> царапает <b>[user]</b>."),
						span_lewd("<b>[target]</b> шлёпает <b>[user]</b>.")))
	target.dir = get_dir(target, user)
	user.dir = get_dir(user, target)
	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/oral1.ogg',
						'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)
	return
