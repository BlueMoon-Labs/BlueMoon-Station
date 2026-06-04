/datum/interaction/lewd/bite
	description = "Убийственно. Искусать."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_MOUTH
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_EXTREME_CONTENT
	max_distance = 1
	write_log_user = "bite"
	write_log_target = "had their body bited by"

	p13user_emote = PLUG13_EMOTE_FACE
	p13user_strength = PLUG13_STRENGTH_LOW
	p13user_duration = PLUG13_DURATION_SHORT

	p13target_emote = PLUG13_EMOTE_MASOCHISM

/datum/interaction/lewd/bite/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/message
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 50
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	if(user.a_intent == INTENT_HARM)
		user.is_fucking(partner, CUM_TARGET_HAND)
		var/dam_zone = pick(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		var/obj/item/bodypart/affecting = partner.get_bodypart(ran_zone(dam_zone))
		partner.apply_damage(rand(3, 6), BRUTE, affecting, partner.run_armor_check(affecting, MELEE))
		message = "[pick("прижимается к <b>[partner]</b>, раскрывает рот и начинает кусаться.",
					"резко разрывает контакт своей челюсти с <b>[partner]</b>, тем самым образом отрывая кусок плоти.",
					"крепко прижимает <b>[partner]</b> к своему телу и одновременно с этим прижимается зубами.",
					"с силой закрепляется за <b>[partner]</b> своими ногтями и наносит укус за укусом.",
					"максимально грубым образом закусывает плоть <b>[partner]</b> до самой крови.")]"
	else
		var/dam_zone = pick(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		var/obj/item/bodypart/affecting = partner.get_bodypart(ran_zone(dam_zone))
		partner.apply_damage(rand(1, 3), BRUTE, affecting, partner.run_armor_check(affecting, MELEE))
		message = "[pick("нежно прижимается к <b>[partner]</b>, раскрывает рот и начинает кусаться.",
					"медленно разрывает контакт своей челюсти с <b>[partner]</b>, тем самым образом открывая свежую рану.",
					"нежно прижимает <b>[partner]</b> к своему телу и одновременно с этим прижимается зубами.",
					"обхватывает <b>[partner]</b> своими коготками и выставляет свою челюсть прямо на плечо.",
					"аккуратно закусывает плоть <b>[partner]</b> и впоследствии оставляет кровоподтёк.")]"
		var/client/cli = partner.client
		var/mob/living/carbon/C = partner
		if(cli && istype(C))
			if(cli.prefs.extremeharm != "No")
				if(prob(30))
					C.bleed(2)
					C.add_splatter_floor(get_turf(BLOOD_COLOR_HUMAN), TRUE)
					new/obj/effect/decal/cleanable/blood

	user.visible_message(message = span_lewd("[is_hidden ? (picked_hidden) : null]<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/squelch1.ogg', volume, 1, extrarange)
	var/lust_amount = NORMAL_LUST //если наша цель довести до пика, то не стоит это закрывать за кучей укусов
	if(HAS_TRAIT(partner, TRAIT_MASO))
		lust_amount *= 2
	partner.handle_post_sex(lust_amount, CUM_TARGET_HAND, user)

	if(prob(50 + partner.get_lust()))
		partner.visible_message("<span class='lewd'>[is_hidden ? (picked_hidden) : null]<b>\The [partner]</b> [pick("дрожит от боли.",
				"тихо вскрикивает.",
				"выдыхает болезненный стон.",
				"звучно вздыхает от боли.",
				"сильно вздрагивает.",
				"вздрагивает, закатывая свои глаза.")]</span>", vision_distance = distance)
