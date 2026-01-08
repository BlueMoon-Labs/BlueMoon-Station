/datum/interaction/lewd/titgrope_self
	description = "Грудь. Сжать свои соски."
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_user_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_user_unexposed = INTERACTION_REQUIRE_BREASTS
	interaction_flags = INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	interaction_sound = null
	max_distance = 0
	write_log_user = "groped own breasts"
	write_log_target = null

	additional_details = list(
		INTERACTION_FILLS_CONTAINERS
	)

	p13user_emote = PLUG13_EMOTE_BREASTS
	p13user_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/titgrope_self/display_interaction(mob/living/user)
	var/message

	var/obj/item/reagent_containers/liquid_container

	var/obj/item/cached_item = user.get_active_held_item()
	if(istype(cached_item, /obj/item/reagent_containers))
		liquid_container = cached_item
	else
		cached_item = user.pulling
		if(istype(cached_item, /obj/item/reagent_containers))
			liquid_container = cached_item

	if(user.a_intent == INTENT_HARM)
		message = pick("с силой сжимает свои собственные сиськи",
					"резко хватается за свои сиськи",
					"крепко сжимает свою грудь",
					"шлёпает по своим сиськам",
					"максимально грубо сжимает свои титьки")
		playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/bang1.ogg', 50, 1, -1)
	else
		message = pick("нежно ощупывает свою грудь",
					"мягко хватается за свою грудь",
					"сжимает собственную грудь",
					"проводит несколькими пальцами вдоль своей груди",
					"деликатно сжимает свой сосок",
					"возбуждённо проводит пальцем вдоль своей груди")
		playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/champ_fingering.ogg', 50, 1, -1)
	if(prob(user.get_lust() / user.get_climax_threshold() * 50)) // 50%
		user.visible_message("<span class='lewd'><b>\The [user]</b> [pick("дрожит от возбуждения",
				"тихо стонет",
				"выдыхает тихий довольный стон",
				"мурлыкает и звучно вздыхает",
				"тихонько вздрагивает",
				"вздрагивает, хватаясь за причинное место")]</span>")
		playlewdinteractionsound(get_turf(user), pick(GLOB.lewd_softmoans_female), 70, 1, -1)

	if(liquid_container)
		message += " прямо в [liquid_container]"

		var/obj/item/organ/genital/breasts/milkers = user.getorganslot(ORGAN_SLOT_BREASTS)
		var/milktype = milkers?.fluid_id
		if(milkers.climaxable(user, TRUE))
			if(milkers && milktype)
				liquid_container.reagents.add_reagent(milktype, rand(1,3 * milkers.get_lactation_amount_modifier()))
				playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/squelch1.ogg', 50, 1, -1)
		else
			message += ", но дойка не дает результатов..."
			playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/squelch3.ogg', 50, 1, -1)

	user.visible_message(message = span_lewd("<b>\The [user]</b> [message]."), ignored_mobs = user.get_unconsenting())
	user.handle_post_sex(LOW_LUST, null, user, ORGAN_SLOT_BREASTS) //SPLURT edit

/datum/interaction/lewd/self_nipsuck
	description = "Грудь. Пососать свои соски."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_exposed = INTERACTION_REQUIRE_BREASTS
	interaction_flags = INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	interaction_sound = null
	max_distance = 0
	write_log_user = "sucked their own nips"
	write_log_target = null
	p13user_emote = PLUG13_EMOTE_BREASTS
	additional_details = list(
		INTERACTION_MAY_CONTAIN_DRINK
	)

/datum/interaction/lewd/self_nipsuck/display_interaction(mob/living/user, mob/living/target)
	var/message
	var/obj/item/organ/genital/breasts/milkers = user.getorganslot(ORGAN_SLOT_BREASTS)
	var/milktype = milkers?.fluid_id
	var/list/lines

	if(!milkers || !milktype)
		return

	if(milkers.climaxable(user, TRUE))
		var/datum/reagent/milk = find_reagent_object_from_type(milktype)

		var/milktext = milk.name

		if(milkers && milktype)
			user.reagents.add_reagent(milktype, rand(1,3 * milkers.get_lactation_amount_modifier()) * user.get_fluid_mod(milkers))
			lines = list(
				"подносит соски своих собственных ёмкостей для молока ко рту и начинает их посасывать.",
				"делает большой глоток свежего <b>'[lowertext(milktext)]'</b> и громко выдыхает после такого.",
				"хватается губами за свой сосок и полностью заполняет свою ротовую полость <b>'[lowertext(milktext)]'</b>."
			)

	else
		lines = list(
			"подносит соски своих собственных ёмкостей для молока ко рту и начинает их посасывать.",
			"подносит свои груди ко рту и громко обсасывает соски."
		)
	message = "<span class='lewd'>\The <b>[user]</b> [pick(lines)]</span>"
	user.visible_message(message, ignored_mobs = user.get_unconsenting())
	user.handle_post_sex(LOW_LUST, null, user, ORGAN_SLOT_BREASTS)
	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/oral1.ogg',
						'modular_sand/sound/interactions/oral2.ogg'), 70, 1, -1)
