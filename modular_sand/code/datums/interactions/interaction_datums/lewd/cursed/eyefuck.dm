/datum/interaction/lewd/eyefuck
	description = "Убийственно. Изнасиловать в глаз."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_EYES
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_EXTREME_CONTENT
	write_log_user = "eyefucked"
	write_log_target = "had their eye fucked by"
	additional_details = list(
		list(
			"info" = "При включенном предпочтении вызывает легкое кровотечение, повреждение глаз и мозга",
			"icon" = "eye",
			"color" = "white"
		)
	)

/datum/interaction/lewd/eyefuck/eyesocketfuck
	description = "Убийственно. Изнасиловать в глазницу."
	required_from_target_exposed = INTERACTION_REQUIRE_EYESOCKETS
	write_log_user = "eyesocketfucked"
	write_log_target = "had their eyesocket fucked by"

/datum/interaction/lewd/eyefuck/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/message
	//var/u_His = user.ru_ego()
	//var/genital_name = user.get_penetrating_genital_name()
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 50
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	if(user.is_fucking(partner, CUM_TARGET_EYES))
		message = "[pick(
			"крепко обхватывает голову \the <b>[partner]</b> и начинает долбиться в глаз.",
			"яростно долбится в череп \the <b>[partner]</b> и довольно стонет.",
			"раз за разом толкается в образованную дыру в глазу \the <b>[partner]</b>.",
			"заходит своим влажным органом по самые яйца в череп \the <b>[partner]</b> снова и снова.")]"
		var/client/cli = partner.client
		var/mob/living/carbon/C = partner
		if(cli && istype(C))
			if(cli.prefs.extremeharm != "No")
				if(prob(15))
					C.bleed(5)
					C.add_splatter_floor(get_turf(BLOOD_COLOR_HUMAN), TRUE)
					new/obj/effect/decal/cleanable/blood
				if(prob(25))
					C.adjustOrganLoss(ORGAN_SLOT_EYES, rand(10,20))
					C.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(7,15))
					partner.adjustBruteLoss(rand(6,12))
	else
		message = "с силой загоняет свой орган глубоко в глаз \the <b>[partner]</b> и громко вздыхает."
		user.set_is_fucking(partner, CUM_TARGET_EYES, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/champ1.ogg',
												'modular_sand/sound/interactions/champ2.ogg'), volume, 1, extrarange)
	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null]<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting(interaction_flags), vision_distance = distance)
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_EYES, partner, ORGAN_SLOT_PENIS) //SPLURT edit
	partner.handle_post_sex(LOW_LUST, null, user)
