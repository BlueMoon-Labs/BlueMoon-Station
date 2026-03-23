/datum/interaction/lewd/crushhead
	description = "Убийственно. Сжать голову бёдрами."
	require_user_legs = REQUIRE_ANY
	require_user_num_legs = 2
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_EXTREME_CONTENT
	write_log_user = "trying to squeeze"
	write_log_target = "was squeezed by"
	additional_details = list(
		list(
			"info" = "Предпочтение ExtremeHarm и агрессивные намерения в критическом состоянии приведут к взрыву головы.",
			"icon" = "brain",
			"color" = "yellow"
		)
	)
	p13user_emote = PLUG13_EMOTE_FACE
	p13user_strength = PLUG13_STRENGTH_LOW
	p13user_duration = PLUG13_DURATION_SHORT

	p13target_emote = PLUG13_EMOTE_MASOCHISM

/datum/interaction/lewd/crushhead/display_interaction(mob/living/user, mob/living/partner)
	var/obj/item/bodypart/head/head = partner.get_bodypart(BODY_ZONE_HEAD)
	if(!head)
		to_chat(user,span_warning("У цели отсутствует голова!"))
		return
	var/message = "[pick("нежно прижимается к <b>[partner]</b>, обхватывая голову ляжками.",
					"отпускает голову <b>[partner]</b>, чтобы с новой силой сдавить её своими бедрами.",
					"нежно прижимает <b>[partner]</b> меж ножками и немного встряхивает своими наушниками.",
					"обхватывает <b>[partner]</b> своими бедрами и тихо постанывает.",
					"с шлепком закрывает своими бедрами лицо <b>[partner]</b> и впоследствии слабо сдавливает.")]"
	var/lust_amount = LOW_LUST // При уроне уже идет накопление LUST, так что много не требуется
	var/damage_amount = rand(1,3)

	if(user.a_intent == INTENT_HARM)
		lust_amount = NORMAL_LUST
		damage_amount = rand(6, 12)
		message = "[pick("прижимается к <b>[partner]</b>, своими бедрами, с силой сжимая голову.",
					"резко сдавливает ляжками <b>[partner]</b>, тем самым вызывая утробный стон жертвы.",
					"крепко прижимает <b>[partner]</b> к своему паху, сжимая голову с хрустом в шее.",
					"с силой закрепляется за <b>[partner]</b> своими ногами и хищно наблюдает.",
					"максимально грубым образом сдавливает голову <b>[partner]</b> до хруста в шее.")]"

		var/mob/living/carbon/human/H = partner
		if(istype(H) && partner?.client.prefs.extremeharm != "No" && user?.client.prefs.extremeharm != "No")
			if(prob(10))
				H.bleed(2)
			else if(prob(10))
				H.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(1,3))
				damage_amount += rand(3,6)
			
			// HeadStomp
			if(H.InFullCritical()) 
				H.visible_message(span_userdanger("Голова <b>[H]</b> лопается, разбрызгивая мозги по полу!"),span_userdanger("ААААА ГОЛОВ-"))
				playsound(get_turf(H), 'modular_bluemoon/sound/effects/squishy.ogg', 140, TRUE, -1)
				head.drop_limb()
				head.drop_organs()
				qdel(head)
				H.death(FALSE) // ИПЦ выкидывает мозг из себя, но не умирает и выглядит словно в ССД, так что оставлю это
				log_combat(user, H, "head stomped")
				new /obj/effect/gibspawner/generic(get_turf(H), H)
				return

		message = span_danger("<b>\The [user]</b> [message]")
	else
		message = span_lewd("<b>\The [user]</b> [message]")

	partner.apply_damage(damage_amount, BRUTE, BODY_ZONE_HEAD, partner.run_armor_check(BODY_ZONE_HEAD, MELEE))

	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

	user.visible_message(message = message, ignored_mobs = user.get_unconsenting())
	playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/squelch1.ogg', 50, 1, -1)
	if(HAS_TRAIT(partner, TRAIT_MASO))
		partner.handle_post_sex(lust_amount, null, user)

	var/const/basic_scream_chance = 25 // %
	if(prob(max(basic_scream_chance, ceil(partner.get_lust() / partner.get_climax_threshold()*100))))
		if(prob(30) && isclownjob(user))
			user.visible_message(span_lewd("<b>[user]</b> забавно хонкает!"))
		else
			partner.visible_message(span_lewd("<b>\The [partner]</b> [pick("дрожит от боли.",
					"тихо вскрикивает.",
					"выдыхает болезненный стон.",
					"звучно вздыхает от боли.",
					"сильно вздрагивает.",
					"вздрагивает, закатывая свои глаза.")]"))
