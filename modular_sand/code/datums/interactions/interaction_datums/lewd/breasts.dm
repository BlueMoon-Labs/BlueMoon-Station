/datum/interaction/lewd/do_breastfeed
	description = "Грудь. Покормить грудью."
	required_from_user_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	write_log_user = "breastfed"
	write_log_target = "was breastfed by"
	interaction_sound = null
	p13user_emote = PLUG13_EMOTE_BREASTS
	p13target_strength = PLUG13_STRENGTH_LOW
	additional_details = list(
		list(
			"info" = "Накормить цель реагентами из вашей груди, если таковые имеются",
			"icon" = "cow",
			"color" = "white"
		)
	)

/datum/interaction/lewd/do_breastfeed/display_interaction(mob/living/user, mob/living/target)
	var/message
	var/obj/item/organ/genital/breasts/milkers = user.getorganslot(ORGAN_SLOT_BREASTS)
	var/milktype = milkers?.fluid_id
	var/list/lines

	if(!milkers || !milktype)
		return

	if(milkers.climaxable(target, TRUE))
		var/datum/reagent/milk = find_reagent_object_from_type(milktype)

		var/milktext = milk.name

		lines = list(
			"прижимает свою грудь ко рту <b>[target]</b>, направляет свой сосок на язык и выплёскивает тёплое <b>'[lowertext(milktext)]'</b>.",
			"наполняет рот \the <b>[target]</b> тёплым и довольно сладким на первовкусие <b>'[lowertext(milktext)]'</b>, когда в свою очередь сжимает сиськи и тяжело дышит.",
			"позволяет большому количеству <b>'[lowertext(milktext)]'</b> орошить горло \the <b>[target]</b>!"
		)

		message = "<span class='lewd'>\The <b>[user]</b> [pick(lines)]</span>"
		user.visible_message(message, ignored_mobs = user.get_unconsenting())
		user.handle_post_sex(LOW_LUST, null, target, ORGAN_SLOT_BREASTS)
		playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/oral1.ogg',
							'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)

		target.reagents.add_reagent(milktype, rand(1,3 * milkers.get_lactation_amount_modifier()))
	else
		lines = list(
			"прижимает свою грудь ко рту <b>[target]</b>, позволяя пососать свой сосок",
			"прижимает рот <b>[target]</b> к своему соску, давая возможность обсосать его"
		)
		message = "<span class='lewd'>\The <b>[user]</b> [pick(lines)]</span>"
		user.visible_message(message, ignored_mobs = user.get_unconsenting())
		user.handle_post_sex(LOW_LUST, null, target, ORGAN_SLOT_BREASTS)
		playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/oral1.ogg',
							'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)

/datum/interaction/lewd/titgrope
	description = "Грудь. Сжать в ладони."
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_target_unexposed = INTERACTION_REQUIRE_BREASTS
	write_log_user = "groped"
	write_log_target = "was groped by"
	interaction_sound = null
	p13target_emote = PLUG13_EMOTE_BREASTS
	p13target_strength = PLUG13_STRENGTH_NORMAL

	additional_details = list(
		INTERACTION_FILLS_CONTAINERS
	)

/datum/interaction/lewd/titgrope/display_interaction(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/reagent_containers/liquid_container

	var/obj/item/cached_item = user.get_active_held_item()
	if(istype(cached_item, /obj/item/reagent_containers))
		liquid_container = cached_item
	else
		cached_item = user.pulling
		if(istype(cached_item, /obj/item/reagent_containers))
			liquid_container = cached_item

	if(liquid_container)
		var/obj/item/organ/genital/breasts/milkers = target.getorganslot(ORGAN_SLOT_BREASTS)
		var/milktype = milkers?.fluid_id

		if(milkers && milktype)
			if(milkers.climaxable(target, TRUE))
				liquid_container.reagents.add_reagent(milktype, rand(1,3 * milkers.get_lactation_amount_modifier()))
				user.visible_message(span_lewd("<b>\The [user]</b> выдавливает содержимое груди <b>[target]</b> в [liquid_container]."), ignored_mobs = user.get_unconsenting())
				target.handle_post_sex(LOW_LUST, null, user, ORGAN_SLOT_BREASTS)
				playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/squelch1.ogg', 50, 1, -1)
			else
				user.visible_message(span_lewd("<b>[user]</b> пытается выдоить содержимое груди <b>[target]</b> в [liquid_container], но ничего не выходит...."), ignored_mobs = user.get_unconsenting())
				target.handle_post_sex(LOW_LUST, null, user, ORGAN_SLOT_BREASTS)
				playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/champ_fingering.ogg', 50, 1, -1)

	else
		target.handle_post_sex(NORMAL_LUST, CUM_TARGET_HAND, user, CUM_TARGET_BREASTS)
		if(user.a_intent == INTENT_HARM)
			user.visible_message(
					pick(span_lewd("\The <b>[user]</b> грубо лапает грудь <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> хватается за грудь <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> сильно сжимает грудь <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> шлёпает грудь <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> грубо лапает сиськи <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> сильно сжимает сиськи <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> шлёпает сиськи <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> хватается за сиськи <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> дёргает сиськи <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> дёргает соски <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> грубо давит на соски <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> дёргает грудь <b>[target]</b>.")))
		else
			user.visible_message(
					pick(span_lewd("\The <b>[user]</b> аккуратно лапает грудь <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> обхватывает грудь <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> аккуратно сжимает грудь <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> обводит грудь <b>[target]</b> своими пальцами."),
						span_lewd("\The <b>[user]</b> бережно обжимает соски <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> деликатно сжимает сосок <b>[target]</b>."),
						span_lewd("\The <b>[user]</b> нежно ощупывает грудь <b>[target]</b>.")))
		if(prob(target.get_lust() / target.get_climax_threshold() * 50)) // 50%
			if(target.a_intent == INTENT_HELP)
				user.visible_message(
					pick(span_lewd("\The <b>[target]</b> дрожит от возбуждения."),
						span_lewd("\The <b>[target]</b> тихо постанывает."),
						span_lewd("\The <b>[target]</b> выдыхает довольный стон."),
						span_lewd("\The <b>[target]</b> тихонько вздрагивает."),
						span_lewd("\The <b>[target]</b> задыхается от возбуждения."),
						span_lewd("\The <b>[target]</b> возбуждённо урчит."),
						span_lewd("\The <b>[target]</b> возбуждённо мурлычет.")))
				target.handle_post_sex(LOW_LUST, null, user, ORGAN_SLOT_BREASTS)
			if(target.a_intent == INTENT_DISARM)
				if (target.restrained())
					user.visible_message(
						pick(span_lewd("\The <b>[target]</b> игриво извивается в попытке снять физические ограничения."),
							span_lewd("\The <b>[target]</b> хихикает, вырываясь из рук <b>[user]</b>."),
							span_lewd("\The <b>[target]</b> скользит в сторону от приближающегося <b>[user]</b>."),
							span_lewd("\The <b>[target]</b> с отсутствующим сопротивлением толкает обнажённую грудь вперёд в руки <b>[user]</b>.")))
				else
					user.visible_message(
						pick(span_lewd("\The <b>[target]</b> игриво извивается в попытке снять физические ограничения."),
							span_lewd("\The <b>[target]</b> хихикает, вырываясь из рук <b>[user]</b>."),
							span_lewd("\The <b>[target]</b> скользит в сторону от приближающегося <b>[user]</b>."),
							span_lewd("\The <b>[target]</b> с отсутствующим сопротивлением толкает обнажённую грудь вперёд в руки <b>[user]</b>.")))
				target.handle_post_sex(LOW_LUST, null, user, ORGAN_SLOT_BREASTS)
		if(target.a_intent == INTENT_GRAB)
			user.visible_message(
					pick(span_lewd("\The <b>[target]</b> крепко сжимает запястье <b>[user]</b>."),
					span_lewd("\The <b>[target]</b> впивается ногтями в руку <b>[user]</b>."),
					span_lewd("\The <b>[target]</b> хватает <b>[user]</b> за запястье пальцами.")))
		if(target.a_intent == INTENT_HARM)
			user.adjustBruteLoss(5)
			user.visible_message(
					pick(span_lewd("\The <b>[target]</b> грубо отталкивает <b>[user]</b>."),
					span_lewd("\The <b>[target]</b> сердито впивается в руку <b>[user]</b>."),
					span_lewd("\The <b>[target]</b> яростно борется с <b>[user]</b>."),
					span_lewd("\The <b>[target]</b> впивается в предплечье <b>[user]</b> роговыми пластинками."),
					span_lewd("\The <b>[target]</b> шлёпает <b>[user]</b> по руке.")))
