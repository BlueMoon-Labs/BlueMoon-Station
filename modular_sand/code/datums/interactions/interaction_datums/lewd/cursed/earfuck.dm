/datum/interaction/lewd/earfuck
	description = "Убийственно. Изнасиловать в ухо."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_EARS
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_EXTREME_CONTENT
	write_log_user = "earfucked"
	write_log_target = "had their ear fucked by"
	additional_details = list(
		list(
			"info" = "При включенном предпочтении вызывает легкое кровотечение, повреждение ушей и мозга",
			"icon" = "ear-deaf",
			"color" = "white"
		)
	)

/datum/interaction/lewd/earfuck/earsocketfuck
	description = "Убийственно. Изнасиловать в ушную раковину."
	required_from_target_exposed = INTERACTION_REQUIRE_EARSOCKETS
	write_log_user = "earsocket fucked"
	write_log_target = "had their earsocket fucked by"

/datum/interaction/lewd/earfuck/display_interaction(mob/living/user, mob/living/partner)
	var/message
	var/is_hidden = ..()
	var/distance = 7
	var/volume = 50
	if(is_hidden)
		distance = 1
		volume = sound_quiet_volume
	var/picked_hidden = pick(hidden_additional)
	if(user.is_fucking(partner, CUM_TARGET_EARS))
		message = "[pick(
			"долбится в ушную раковину \the <b>[partner]</b>.",
			"резко и довольно глубоко вводит свой орган в череп \the <b>[partner]</b>",
			"раз за разом толкается в ушную раковину \the <b>[partner]</b>.",
			"заходит своим влажным органом по самые яйца в череп \the <b>[partner]</b> снова и снова.")]"
		var/client/cli = partner.client
		var/mob/living/carbon/C = partner
		if(cli && istype(C))
			if(cli.prefs.extremeharm != "No")
				if(prob(15))
					C.bleed(5)
					C.add_splatter_floor(get_turf(BLOOD_COLOR_HUMAN), TRUE)
					new/obj/effect/decal/cleanable/blood
				if(prob(45))
					C.adjustOrganLoss(ORGAN_SLOT_EARS, rand(10,20))
					C.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(7,15))
					C.adjustBruteLoss(rand(6,12))
	else
		message = "с силой загоняет свой орган внутрь ушной раковины \the <b>[partner]</b> и громко вздыхает."
		user.set_is_fucking(partner, CUM_TARGET_EARS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/champ1.ogg',
												'modular_sand/sound/interactions/champ2.ogg'), volume, 1, -1)
	user.visible_message(message = span_lewd("[is_hidden ? (picked_hidden) : null] <b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting(interaction_flags), vision_distance = distance)
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_EARS, partner, ORGAN_SLOT_PENIS) //SPLURT edit
	partner.handle_post_sex(LOW_LUST, null, user)
