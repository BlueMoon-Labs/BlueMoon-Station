
/*--------------------------------------------------
-------------------MOB STUFF----------------------
--------------------------------------------------
*/
//I'm sorry, lewd should not have mob procs such as life() and such in it. //NO SHIT IT SHOULDNT I REMOVED THEM

/proc/playlewdinteractionsound(turf/turf_source, soundin, vol as num, vary, extrarange as num, frequency, falloff_exponent = SOUND_FALLOFF_EXPONENT, channel = 0, pressure_affected = TRUE, sound/S, envwet = -10000, envdry = 0, manual_x, manual_y, list/ignored_mobs)
	if(!turf_source || !soundin)
		return
	var/sound/sound_to_play = sound(get_sfx(soundin))
	var/max_distance = SOUND_RANGE + extrarange
	var/falloff_distance = 3 // Full volume within 3 tiles (lewd sounds are close-range)
	channel = channel || SSsounds.random_available_channel()
	var/list/hearing_mobs
	for(var/mob/H in get_hearers_in_view(max_distance, turf_source))
		if(!H.client || !(H.client.prefs.toggles & LEWD_VERB_SOUNDS))
			continue
		LAZYADD(hearing_mobs, H)
	if(ignored_mobs?.len)
		LAZYREMOVE(hearing_mobs, ignored_mobs)
	for(var/mob/H in hearing_mobs)
		H.playsound_local(turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, sound_to_play, max_distance, falloff_distance)

/mob/living
	var/has_penis = FALSE
	var/has_balls = FALSE
	var/has_vagina = FALSE
	var/has_anus = TRUE
	var/has_butt = FALSE
	var/anus_always_accessible = FALSE
	var/has_breasts = FALSE
	var/anus_exposed = FALSE
	var/last_partner
	var/last_orifice
	var/obj/item/organ/last_genital
	var/lastmoan
	var/sexual_potency = 15
	var/lust_tolerance = 100
	var/lastlusttime = 0
	var/lust = 0
	var/multiorgasms = 1
	COOLDOWN_DECLARE(refractory_period)
	COOLDOWN_DECLARE(last_interaction_time)
	var/datum/interaction/lewd/last_lewd_datum	//Recording our last lewd datum allows us to do stuff like custom cum messages.
												//Yes i feel like an idiot writing this.
	var/cleartimer //Timer for clearing the "last_lewd_datum". This prevents some oddities.

/mob/living/proc/clear_lewd_datum()
	last_partner = null
	last_orifice = null
	last_genital = null
	last_lewd_datum = null

/mob/living/Initialize(mapload)
	. = ..()
	sexual_potency = rand(10,25)
	lust_tolerance = rand(25,200)

/mob/living/proc/get_lust_tolerance()
	. = lust_tolerance
	if(has_dna())
		var/mob/living/carbon/user = src
		if(user.dna.features["lust_tolerance"])
			. = user.dna.features["lust_tolerance"]

/mob/living/proc/get_sexual_potency()
	. = sexual_potency
	if(has_dna())
		var/mob/living/carbon/user = src
		if(user.dna.features["sexual_potency"])
			. = user.dna.features["sexual_potency"]

/mob/living/proc/add_lust(add)
	var/cur = get_lust() //GetLust handles per-time lust loss
	if((cur + add) < 0) //in case we retract lust
		lust = 0
	else
		lust = cur + add


/mob/living/proc/get_lust()
	var/curtime = world.time
	var/dif = (curtime - lastlusttime) / 10 //how much lust would we lose over time
	if((lust - dif) < 0)
		lust = 0
	else
		lust = lust - dif

	lastlusttime = world.time
	return lust

/mob/living/proc/set_lust(num)
	lust = num
	lastlusttime = world.time

/mob/living/proc/toggle_anus_always_accessible(accessibility)
	anus_always_accessible = isnull(accessibility) ? !anus_always_accessible : accessibility

/mob/living/proc/has_genital(slot)
	var/mob/living/carbon/C = src
	if(istype(C))
		var/obj/item/organ/genital/genital = C.getorganslot(slot)
		if(genital)
			if(genital.is_exposed() || genital.always_accessible)
				return HAS_EXPOSED_GENITAL
			else
				return HAS_UNEXPOSED_GENITAL
	return FALSE

/mob/living/proc/has_penis()
	var/mob/living/carbon/C = src
	if(has_penis && !istype(C))
		return TRUE
	return has_genital(ORGAN_SLOT_PENIS)

/mob/living/proc/has_strapon()
	var/mob/living/carbon/C = src
	if(istype(C))
		var/obj/item/clothing/underwear/briefs/strapon/strapon = C.get_strapon()
		if(strapon)
			if(strapon.is_exposed())
				return HAS_EXPOSED_GENITAL
			else
				return HAS_UNEXPOSED_GENITAL
	return FALSE

/mob/living/proc/get_strapon()
	for(var/obj/item/clothing/cloth in get_equipped_items())
		if(istype(cloth, /obj/item/clothing/underwear/briefs/strapon))
			return cloth

	return null

/mob/living/proc/can_penetrating_genital_cum()
	return has_penis()

/mob/living/proc/get_penetrating_genital_name(long = FALSE)
	return has_penis() ? (long ? pick(GLOB.dick_nouns) : pick("член", "пенис")) : "страпон"

/mob/living/proc/has_balls()
	var/mob/living/carbon/C = src
	if(has_balls && !istype(C))
		return TRUE
	return has_genital(ORGAN_SLOT_TESTICLES)

/mob/living/proc/has_vagina()
	var/mob/living/carbon/C = src
	if(has_vagina && !istype(C))
		return TRUE
	return has_genital(ORGAN_SLOT_VAGINA)

/mob/living/proc/has_breasts()
	var/mob/living/carbon/C = src
	if(has_breasts && !istype(C))
		return TRUE
	return has_genital(ORGAN_SLOT_BREASTS)

/mob/living/proc/has_butt()
	var/mob/living/carbon/C = src
	if(has_butt && !istype(C))
		return TRUE
	return has_genital(ORGAN_SLOT_BUTT)

/mob/living/proc/has_anus()
	if(has_anus && !iscarbon(src))
		return TRUE
	if (has_anus && anus_always_accessible)
		return HAS_EXPOSED_GENITAL
	switch(anus_exposed)
		if(-1)
			return HAS_UNEXPOSED_GENITAL
		if(1)
			return HAS_EXPOSED_GENITAL
		else
			if(is_bottomless())
				return HAS_EXPOSED_GENITAL
			else
				return HAS_UNEXPOSED_GENITAL

/mob/living/proc/has_hand()
	if(iscarbon(src))
		var/mob/living/carbon/C = src
		var/handcount = 0
		var/covered = 0
		for(var/obj/item/bodypart/l_arm/L in C.bodyparts)
			handcount++
		for(var/obj/item/bodypart/r_arm/R in C.bodyparts)
			handcount++
		if(!handcount)
			return FALSE
		if(C.get_item_by_slot(ITEM_SLOT_HANDS))
			var/obj/item/clothing/gloves/G = C.get_item_by_slot(ITEM_SLOT_HANDS)
			covered = G.body_parts_covered
		if(covered & HANDS)
			return HAS_UNEXPOSED_GENITAL
		else
			return HAS_EXPOSED_GENITAL
	return FALSE

/mob/living/proc/has_feet()
	if(iscarbon(src))
		var/mob/living/carbon/C = src
		var/feetcount = 0
		var/covered = 0
		for(var/obj/item/bodypart/l_leg/L in C.bodyparts)
			feetcount++
		for(var/obj/item/bodypart/r_leg/R in C.bodyparts)
			feetcount++
		if(!feetcount)
			return FALSE
		if(!C.is_barefoot())
			covered = TRUE
		if(covered)
			return HAS_UNEXPOSED_GENITAL
		else
			return HAS_EXPOSED_GENITAL
	return FALSE

/mob/living/proc/get_num_feet()
	return 0

/mob/living/carbon/get_num_feet()
	. = ..()
	for(var/obj/item/bodypart/l_leg/L in bodyparts)
		.++
	for(var/obj/item/bodypart/r_leg/R in bodyparts)
		.++

//weird procs go here
//please check for existance separately
/mob/living/proc/has_ears()
	var/mob/living/carbon/C = src
	if(istype(C))
		if(C.get_item_by_slot(ITEM_SLOT_EARS_LEFT) || C.get_item_by_slot(ITEM_SLOT_EARS_RIGHT))
			return HAS_UNEXPOSED_GENITAL
		else
			return HAS_EXPOSED_GENITAL
	return FALSE

/mob/living/proc/has_eyes()
	var/mob/living/carbon/C = src
	if(istype(C))
		if(C.get_item_by_slot(ITEM_SLOT_EYES))
			return HAS_UNEXPOSED_GENITAL
		else
			return HAS_EXPOSED_GENITAL
	return FALSE

///Are we wearing something that covers our chest?
/mob/living/proc/is_topless()
	for(var/slot in GLOB.slots)
		var/item_slot = GLOB.slot2slot[slot]
		if(!item_slot) // Safety
			continue
		var/obj/item/clothing = get_item_by_slot(item_slot)
		if(!clothing) // Don't have this slot or not wearing anything in it
			continue
		if(clothing.body_parts_covered & CHEST)
			return FALSE
	// If didn't stop before, then we're topless
	return TRUE

///Are we wearing something that covers our groin?
/mob/living/proc/is_bottomless()
	for(var/slot in GLOB.slots)
		var/item_slot = GLOB.slot2slot[slot]
		if(!item_slot) // Safety
			continue
		var/obj/item/clothing = get_item_by_slot(item_slot)
		if(!clothing) // Don't have this slot or not wearing anything in it
			continue
		if(clothing.body_parts_covered & GROIN)
			return FALSE
	// If didn't stop before, then we're bottomless
	return TRUE

///Are we wearing something that covers our shoes?
/mob/living/proc/is_barefoot()
	for(var/slot in GLOB.slots)
		var/item_slot = GLOB.slot2slot[slot]
		if(!item_slot) // Safety
			continue
		var/obj/item/clothing = get_item_by_slot(item_slot)
		if(!clothing) // Don't have this slot or not wearing anything in it
			continue
		if(clothing.body_parts_covered & FEET)
			return FALSE
	// If didn't stop before, then we're barefoot
	return TRUE

/mob/living/proc/moan()
	if(is_muzzled() || (mind?.miming))
		var/message_to_display = pick("mime%S% a pleasured moan","moan%S% in silence")
		visible_message(span_lewd("<b>\The [src]</b> [replacetext(message_to_display, "%S%", "s")]."),
			span_lewd("You [replacetext(message_to_display, "%S%", "")]."))
		return
	var/message_to_display = pick("стонет%S%", "постанывает%S% от удовольствия")
	visible_message(span_lewd("<b>\The [src]</b> [replacetext(message_to_display, "%S%", "")]."),
		span_lewd("Вы [replacetext(message_to_display, "%S%", "е")]."),
		span_lewd("Вы слышите наполненный удовольствием стон."),
		ignored_mobs = get_unconsenting(), omni = TRUE)

	// Get reference of the list we're using based on gender.
	var/list/moans
	if (gender == FEMALE || (gender == PLURAL && isfeminine(src)))
	// BLUEMOON EDIT START
		if(lust/get_climax_threshold() < 0.55 && last_climax + min(8 MINUTES, world.time) <= world.time)
			moans = GLOB.lewd_softmoans_female
		else
			moans = GLOB.lewd_moans_female
	// BLUEMOON EDIT END
	else
		moans = GLOB.lewd_moans_male

	// Pick a sound from the list.
	var/sound = pick(moans)

	// If the sound is repeated, get a new from a list without it.
	if (lastmoan == sound)
		sound = pick(LAZYCOPY(moans) - lastmoan)

	if(isalien(src))
		sound = 'sound/voice/hiss6.ogg'

	playlewdinteractionsound(loc, sound, 80, 0, 0)
	lastmoan = sound

/mob/living/proc/cum(mob/living/partner, target_orifice, cum_inside = FALSE, anonymous = FALSE)
	if(HAS_TRAIT(src, TRAIT_NEVERBONER))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_MOB_PRE_CAME, target_orifice, partner))
		return FALSE
	var/message
	var/cumin = cum_inside // SPLURT EDIT - defaults to argument `cum_inside` rather than FALSE
	var/partner_carbon_check = FALSE
	var/obj/item/organ/genital/target_gen = null
	var/mob/living/carbon/c_partner = null

	// Do not display to those people as well
	var/list/mob/obscure_to

	//Carbon checks
	if(iscarbon(partner))
		c_partner = partner
		partner_carbon_check = TRUE

	var/partner_name
	if(anonymous)
		partner_name = "<b>НЕИЗВЕСТНЫЙ</b>"
	else
		partner_name = "<b>[partner]</b>"

	if(src != partner)
		if(ismob(partner))
			// BLEMOON ADD START
			var/list/partner_has_portal = list(
				"mouth" = ishuman(partner) && istype(partner:wear_mask, /obj/item/clothing/underwear/briefs/panties/portalpanties),
				"groin" = ishuman(partner) && istype(partner:w_underwear, /obj/item/clothing/underwear/briefs/panties/portalpanties)
			)
			// BLUEMOON ADD END
			if(!last_genital)
				if(has_penis())
					if(!istype(partner))
						target_orifice = null
					switch(target_orifice)
						if(CUM_TARGET_MOUTH)
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
								message = "кончает прямо в ротик [partner_name]."
								cumin = TRUE
							else
								message = "кончает на лицо [partner_name] семенем."
						if(CUM_TARGET_THROAT)
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
								message = "входит глубоко в глотку [partner_name] и кончает."
								cumin = TRUE
							else
								message = "кончает на лицо [partner_name] семенем."
						if(CUM_TARGET_VAGINA)
							var/has_vagina = partner.has_vagina()
							if(has_vagina == TRUE || (has_vagina == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
								if(partner_carbon_check)
									target_gen = c_partner.getorganslot(ORGAN_SLOT_VAGINA)
								message = "кончает в киску [partner_name] семенем."
								cumin = TRUE
							else
								message = "кончает на живот [partner_name] семенем."
						if(CUM_TARGET_ANUS)
							var/has_anus = partner.has_anus()
							if(has_anus == TRUE || (has_anus == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
								message = "кончает в попку <b>[partner_name]</b> семенем."
								cumin = TRUE
							else
								message = "кончает на спину [partner_name] семенем."
						if(CUM_TARGET_HAND)
							if(partner.has_hand())
								message = "кончает на руку <b>[partner_name]</b> семенем."
							else
								message = "кончает на [partner_name]."
						// BLUEMOON ADD START
						if(CUM_TARGET_ARMPIT)
							if(partner.has_hand())
								message = "кончает в подмышку <b>[partner_name]</b>."
							else
								message = "кончает на [partner_name]."
						// BLUEMOON ADD END
						if(CUM_TARGET_BREASTS) //BLUEMOON EDIT добавлено взаимодействие с боргами
							// BLUEMOON EDIT START - я НЕ ПРЕДСТАВЛЯЮ, чего эти гиганты мысли добивались тут, используя
							// не инициализированные переменные.
							var/mob/living/carbon/human/sex
							var/mob/living/silicon/robot/silicon_sex
							if (istype(sex))
								for(var/obj/item/organ/genital/G in sex.internal_organs)
									var/datum/reagents/fluid_source = G.climaxable(partner)
									if(!fluid_source)
										continue
									sex.do_climax(fluid_source, src, G, TRUE, FALSE)
							else
								silicon_sex = src
								silicon_sex.do_climax_silicon(silicon_sex, src, TRUE) // BLUEMOON EDIT END

							if(partner.has_breasts(REQUIRE_EXPOSED))
								message = "кончает на грудь [partner_name]."
							else
								message = "кончает на грудину и торс [partner_name]."
						if(NUTS_TO_FACE)
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
								message = "энергично засовывает свои яйца в рот партнёра перед тем, как выпустить густое, липкое семя в глаза и волосы [partner_name]."
						if(THIGH_SMOTHERING) //BLUEMOON EDIT добавлено взаимодействие с боргами
							// BLUEMOON EDIT START - я НЕ ПРЕДСТАВЛЯЮ, чего эти гиганты мысли добивались тут, используя
							// не инициализированные переменные.
							var/mob/living/carbon/human/sex = src
							var/mob/living/silicon/robot/silicon_sex
							if (istype(sex))
								for(var/obj/item/organ/genital/G in sex.internal_organs)
									var/datum/reagents/fluid_source = G.climaxable(partner)
									if(!fluid_source)
										continue
									sex.do_climax(fluid_source, src, G, TRUE, FALSE)
							else
								silicon_sex = src
								silicon_sex.do_climax_silicon(silicon_sex, src, TRUE) // BLUEMOON EDIT END
							// BLEUMOON EDIT START
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"]))
								message = "фиксирует ноги вокруг головы [partner_name] с особой силой, проталкивая член в глотку и удерживает так, пока он изливается"
								cumin = TRUE
							else
								message = "держит [partner_name] между бёдрами, пока член пульсирует, изливаясь в лицо и волосы жертвы."
							// BLEUMOON EDIT END

						if(CUM_TARGET_FEET)
							if(!last_lewd_datum.require_target_num_feet)
								if(partner.has_feet())
									message = "кончает на [partner.has_feet() == 1 ? pick("стопу", "ножку") : pick("стопу", "ножку")] [partner_name]."
								else
									message = "кончает под себя!"
							else
								if(partner.has_feet())
									message = "кончает на [last_lewd_datum.require_target_num_feet == 1 ? pick("стопу", "ножку") : pick("стопы", "ножки")] [partner_name]."
								else
									message = "кончает под себя!"
						//weird shit goes here
						if(CUM_TARGET_EARS)
							if(partner.has_ears())
								message = "кончает в \the ухо [partner_name] сквиртом!"
							else
								message = "кончает в \the ушную раковину [partner_name] сквиртом!"
							cumin = TRUE
						if(CUM_TARGET_EYES)
							if(partner.has_eyes())
								message = "кончает на глаз [partner_name] сквиртом!"
							else
								message = "кончает в \the глазницу [partner_name] сквиртом!"
							cumin = TRUE
						//
						if(CUM_TARGET_PENIS)
							var/has_penis = partner.has_penis()
							if(has_penis == TRUE || (has_penis == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
								message = "кончает на [partner_name]."
							else
								message = "кончает под себя!"
						// BLUEMOON ADD START хвостики!
						if(CUM_TARGET_TAIL)
							message = "кончает на хвост <b>[partner]</b>!"
						// BLUEMOON ADD END
						else
							message = "кончает под себя!"
				else if(has_vagina())
					if(!istype(partner))
						target_orifice = null

					switch(target_orifice)
						if(CUM_TARGET_MOUTH)
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
								message = "сквиртит прямо в рот [partner_name]." // BLUEMOON EDIT
								cumin = TRUE
							else
								message = "обливает лицо [partner_name] сквиртом!"
						if(CUM_TARGET_THROAT)
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
								message = "трется своей киской о рот [partner_name] и кончает."
								cumin = TRUE
							else
								message = "обливает лицо [partner_name] сквиртом!"
						if(CUM_TARGET_VAGINA)
							var/has_vagina = partner.has_vagina()
							if(has_vagina == TRUE || (has_vagina == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
								message = "обливает киску [partner_name] сквиртом!"
								cumin = TRUE
							else
								message = "обливает живот [partner_name] сквиртом!"
						if(CUM_TARGET_ANUS)
							var/has_anus = partner.has_anus()
							if(has_anus == TRUE || (has_anus == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
								message = "обливает попку [partner_name] сквиртом!"
								cumin = TRUE
							else
								message = "обливает спину [partner_name] сквиртом!"
						if(CUM_TARGET_HAND)
							if(partner.has_hand(REQUIRE_ANY))
								message = "обливает руку [partner_name] сквиртом!"
							else
								message = "обливает [partner_name]."
						// BLUEMOON ADD START
						if(CUM_TARGET_ARMPIT)
							if(partner.has_hand())
								message = "кончает в подмышку <b>[partner_name]</b>."
							else
								message = "кончает на [partner_name]."
						// BLUEMOON ADD END
						if(CUM_TARGET_BREASTS)
							var/has_breasts = partner.has_breasts()
							if(has_breasts == TRUE || has_breasts == HAS_EXPOSED_GENITAL)
								message = "обливает грудь [partner_name] сквиртом!"
							else
								message = "обливает грудину и торс [partner_name] сквиртом!"
						if(NUTS_TO_FACE)
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
								message = "энергично засовывает свои яйца в рот партнёра перед тем, как выпустить густое, липкое семя в глаза и волосы [partner_name]."
						if(THIGH_SMOTHERING)
							// BLEUMOON EDIT START
							if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"]))
								message = "фиксирует ноги вокруг головы [partner_name] с особой силой, прижимая киску ко рту и удерживает так, пока она изливается"
								cumin = TRUE
							else
								message = "держит [partner_name] между бёдрами, пока киска пульсирует, изливаясь в лицо и волосы жертвы."
							// BLEUMOON EDIT END
						if(CUM_TARGET_FEET)
							if(!last_lewd_datum.require_target_num_feet)
								if(partner.has_feet())
									message = "обливает [partner.has_feet() == 1 ? pick("стопу", "ножку") : pick("стопу", "ножку")] [partner_name]."
								else
									message = "обливает пространство под собой сквиртом!"
							else
								if(partner.has_feet())
									message = "обливает [last_lewd_datum.require_target_num_feet == 1 ? pick("стопу", "ножку") : pick("стопы", "ножки")] [partner_name]."
								else
									message = "обливает пространство под собой сквиртом!"
						//weird shit goes here
						if(CUM_TARGET_EARS)
							if(partner.has_ears())
								message = "обливает ухо [partner_name] сквиртом!"
							else
								message = "обливает ушную раковину [partner_name] сквиртом!"
							cumin = TRUE
						if(CUM_TARGET_EYES)
							if(partner.has_eyes())
								message = "обливает глаз [partner_name] сквиртом!"
							else
								message = "обливает глазницу [partner_name] сквиртом!"
							cumin = TRUE
						//
						if(CUM_TARGET_PENIS)
							var/has_penis = partner.has_penis()
							//BLUEMOON EDIT START
							var/has_strapon = partner.has_strapon() //BLUEMOON ADD
							if(has_penis == TRUE || has_penis == HAS_EXPOSED_GENITAL || has_strapon == HAS_EXPOSED_GENITAL || partner_has_portal["groin"]) // BLUEMOON EDIT
								message = "обливает [partner.get_penetrating_genital_name()] [partner_name] сквиртом"
							//BLUEMOON EDIT END
							else
								message = "обливает пространство под собой сквиртом!"
						// BLUEMOON ADD START хвостики!
						if(CUM_TARGET_TAIL)
							message = "обливает хвост <b>[partner] сквиртом</b>!"
						// BLUEMOON ADD END
						else
							message = "обливает пространство под собой сквиртом!"

				else
					message = pick("orgasms violently!", "twists in orgasm.")
			else
				switch(last_genital.type)
					if(/obj/item/organ/genital/penis)
						if(!istype(partner))
							target_orifice = null

						switch(target_orifice)
							if(CUM_TARGET_MOUTH)
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
									message = "кончает прямо в рот [partner_name]."
									cumin = TRUE
								else
									message = "кончает на лицо [partner_name] семенем."
							if(CUM_TARGET_THROAT)
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
									message = "входит глубоко в глотку [partner_name] и кончает."
									cumin = TRUE
								else
									message = "кончает на лицо [partner_name] семенем."
							if(CUM_TARGET_VAGINA)
								var/has_vagina = partner.has_vagina()
								if(has_vagina == TRUE || (has_vagina == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
									if(partner_carbon_check)
										target_gen = c_partner.getorganslot(ORGAN_SLOT_VAGINA)
									message = "кончает в киску [partner_name] семенем."
									cumin = TRUE
								else
									message = "кончает на живот [partner_name] семенем."
							if(CUM_TARGET_ANUS)
								var/has_anus = partner.has_anus()
								if(has_anus == TRUE || (has_anus == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
									message = "кончает в попку [partner_name] семенем."
									cumin = TRUE
								else
									message = "кончает на спину [partner_name] семенем."
							if(CUM_TARGET_HAND)
								if(partner.has_hand())
									message = "кончает на руку [partner_name] семенем."
								else
									message = "кончает на [partner_name]."
							// BLUEMOON ADD START
							if(CUM_TARGET_ARMPIT)
								if(partner.has_hand())
									message = "кончает в подмышку <b>[partner_name]</b>."
								else
									message = "кончает на [partner_name]."
							// BLUEMOON ADD END
							if(CUM_TARGET_BREASTS) //BLUEMOON EDIT добавлено взаимодействие с боргами
								// BLUEMOON EDIT START - я НЕ ПРЕДСТАВЛЯЮ, чего эти гиганты мысли добивались тут, используя
								// не инициализированные переменные.
								var/mob/living/carbon/human/sex = src
								var/mob/living/silicon/robot/silicon_sex
								if (istype(sex))
									for(var/obj/item/organ/genital/G in sex.internal_organs)
										var/datum/reagents/fluid_source = G.climaxable(partner)
										if(!fluid_source)
											continue
										sex.do_climax(fluid_source, src, G, TRUE, FALSE)
								else
									silicon_sex = src
									silicon_sex.do_climax_silicon(silicon_sex, src, TRUE) // BLUEMOON EDIT END

								if(partner.is_topless() && partner.has_breasts())
									message = "кончает на грудь [partner_name]."
								else
									message = "кончает на грудину и торс [partner_name]."
							if(NUTS_TO_FACE)
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
									message = "энергично засовывает свои яйца в рот партнёра перед тем, как выпустить густое, липкое семя в глаза и волосы [partner_name]."
							if(THIGH_SMOTHERING) //BLUEMOON EDIT добавлено взаимодействие с боргами
								// BLUEMOON EDIT START - я НЕ ПРЕДСТАВЛЯЮ, чего эти гиганты мысли добивались тут, используя
								// не инициализированные переменные.
								var/mob/living/carbon/human/sex = src
								var/mob/living/silicon/robot/silicon_sex
								if (istype(sex))
									for(var/obj/item/organ/genital/G in sex.internal_organs)
										var/datum/reagents/fluid_source = G.climaxable(partner)
										if(!fluid_source)
											continue
										sex.do_climax(fluid_source, src, G, TRUE, FALSE)
								else
									silicon_sex = src
									silicon_sex.do_climax_silicon(silicon_sex, src, TRUE) // BLUEMOON EDIT END

								// BLEUMOON EDIT START
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"]))
									message = "фиксирует ноги вокруг головы [partner_name] с особой силой, проталкивая член в глотку и удерживает так, пока он изливается"
									cumin = TRUE
								else
									message = "держит [partner_name] между бёдрами, пока член пульсирует, изливаясь в лицо и волосы жертвы."
								// BLEUMOON EDIT END
							if(CUM_TARGET_FEET)
								if(!last_lewd_datum || !last_lewd_datum.require_target_num_feet)
									if(partner.has_feet())
										message = "кончает на [partner.has_feet() == 1 ? pick("стопу", "ножку") : pick("стопу", "ножку")] [partner_name]."
									else
										message = "кончает под себя!"
								else
									if(partner.has_feet())
										message = "кончает на [last_lewd_datum.require_target_num_feet == 1 ? pick("стопу", "ножку") : pick("стопы", "ножки")] [partner_name]."
									else
										message = "кончает под себя!"
							//weird shit goes here
							if(CUM_TARGET_EARS)
								if(partner.has_ears())
									message = "кончает в \the ухо [partner_name] сквиртом!"
								else
									message = "кончает в \the ушную раковину [partner_name] сквиртом!"
								cumin = TRUE
							if(CUM_TARGET_EYES)
								if(partner.has_eyes())
									message = "кончает на глаз [partner_name] сквиртом!"
								else
									message = "кончает в \the глазницу [partner_name] сквиртом!"
								cumin = TRUE
							//
							if(CUM_TARGET_PENIS)
								var/has_penis = partner.has_penis()
								if(has_penis == TRUE || has_penis == HAS_EXPOSED_GENITAL || partner_has_portal["groin"]) // BLUEMOON EDIT
									message = "кончает на [partner_name]."
								else
									message = "кончает под себя!"
							// BLUEMOON ADD START хвостики!
							if(CUM_TARGET_TAIL)
								message = "кончает на хвост <b>[partner]</b>!"
							// BLUEMOON ADD END
							else
								message = "кончает под себя!"
					if(/obj/item/organ/genital/vagina)
						if(!istype(partner))
							target_orifice = null

						switch(target_orifice)
							if(CUM_TARGET_MOUTH)
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
									message = "сквиртит прямо в ротик [partner_name]." // BLUEMOON EDIT
									cumin = TRUE
								else
									message = "обливает лицо [partner_name] сквиртом!"
							if(CUM_TARGET_THROAT)
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
									message = "трется своей киской о рот [partner_name] и кончает."
									cumin = TRUE
								else
									message = "обливает лицо [partner_name] сквиртом!"
							if(CUM_TARGET_VAGINA)
								var/has_vagina = partner.has_vagina()
								if(has_vagina == TRUE || (has_vagina == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
									message = "обливает киску [partner_name] сквиртом!"
									cumin = TRUE
								else
									message = "обливает живот [partner_name] сквиртом!"
							if(CUM_TARGET_ANUS)
								var/has_anus = partner.has_anus()
								if(has_anus == TRUE || (has_anus == HAS_EXPOSED_GENITAL || partner_has_portal["groin"])) // BLUEMOON EDIT
									message = "обливает попку [partner_name] сквиртом!"
									cumin = TRUE
								else
									message = "обливает спину [partner_name] сквиртом!"
							if(CUM_TARGET_HAND)
								if(partner.has_hand())
									message = "обливает руку [partner_name] сквиртом!"
								else
									message = "обливает [partner_name] сквиртом!"
							// BLUEMOON ADD START
							if(CUM_TARGET_ARMPIT)
								if(partner.has_hand())
									message = "кончает в подмышку <b>[partner_name]</b>."
								else
									message = "кончает на [partner_name]."
							// BLUEMOON ADD END
							if(CUM_TARGET_BREASTS)
								var/has_breasts = partner.has_breasts()
								if(has_breasts == TRUE || has_breasts == HAS_EXPOSED_GENITAL)
									message = "обливает грудь [partner_name] сквиртом!"
								else
									message = "обливает грудь и шейку [partner_name] сквиртом!"
							if(NUTS_TO_FACE)
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"])) // BLUEMOON EDIT
									message = "энергично засовывает свои яйца в рот партнёра перед тем, как выпустить густое, липкое семя в глаза и волосы [partner_name]."

							if(THIGH_SMOTHERING)
								// BLEUMOON EDIT START
								if(partner.has_mouth() && (partner.mouth_is_free() || partner_has_portal["mouth"]))
									message = "фиксирует ноги вокруг головы [partner_name] с особой силой, прижимая киску ко рту и удерживает так, пока она изливается"
									cumin = TRUE
								else
									message = "держит [partner_name] между бёдрами, пока киска пульсирует, изливаясь в лицо и волосы жертвы."
								// BLEUMOON EDIT END
							if(CUM_TARGET_FEET)
								if(!last_lewd_datum || !last_lewd_datum.require_target_num_feet)
									if(partner.has_feet())
										message = "обливает [partner.has_feet() == 1 ? pick("стопу", "ножку") : pick("стопу", "ножку")] [partner_name]."
									else
										message = "обливает пространство под собой сквиртом!"
								else
									if(partner.has_feet())
										message = "обливает [last_lewd_datum.require_target_num_feet == 1 ? pick("стопу", "ножку") : pick("стопы", "ножки")] [partner_name]."
									else
										message = "обливает пространство под собой сквиртом!"
							//weird shit goes here
							if(CUM_TARGET_EARS)
								if(partner.has_ears())
									message = "обливает ухо [partner_name] сквиртом!"
								else
									message = "обливает ушную раковину [partner_name] сквиртом!"
								cumin = TRUE
							if(CUM_TARGET_EYES)
								if(partner.has_eyes())
									message = "обливает глаз [partner_name] сквиртом!"
								else
									message = "обливает глазницу [partner_name] сквиртом!"
								cumin = TRUE
							//
							if(CUM_TARGET_PENIS)
								var/has_penis = partner.has_penis()
								//BLUEMOON EDIT START
								var/has_strapon = partner.has_strapon() //BLUEMOON ADD
								if(has_penis == TRUE || has_penis == HAS_EXPOSED_GENITAL || has_strapon == HAS_EXPOSED_GENITAL || partner_has_portal["groin"]) // BLUEMOON EDIT
									message = "обливает [partner.get_penetrating_genital_name()] [partner_name] сквиртом"
								//BLUEMOON EDIT END
								else
									message = "обливает пространство под собой сквиртом!"
							// BLUEMOON ADD START хвостики!
							if(CUM_TARGET_TAIL)
								message = "обливает хвост <b>[partner] сквиртом</b>!"
							// BLUEMOON ADD END
							else
								message = "обливает пространство под собой сквиртом!"
					else
						message = pick("оргазмирует!", "трясётся в оргазме.", "дрожит от оргазма!")
		else if(istype(partner, /obj/item/reagent_containers))
			var/did_anything = TRUE
			switch(last_genital.type)
				if(/obj/item/organ/genital/penis)
					message = "кончает в [partner_name]!"
				if(/obj/item/organ/genital/vagina)
					message = "обливает [partner_name] горячим сквиртом!"
				else
					did_anything = FALSE
			if(did_anything)
				LAZYADD(obscure_to, src)
	if(partner_carbon_check && cumin)
		switch(target_orifice)
			if(CUM_TARGET_VAGINA)
				target_gen = c_partner.getorganslot(ORGAN_SLOT_VAGINA)
			if(CUM_TARGET_ANUS)
				target_gen = c_partner.getorganslot(ORGAN_SLOT_ANUS)
			if(CUM_TARGET_BREASTS)
				target_gen = c_partner.getorganslot(ORGAN_SLOT_BREASTS)
			if(CUM_TARGET_PENIS)
				target_gen = c_partner.getorganslot(ORGAN_SLOT_PENIS)
			if(CUM_TARGET_MOUTH)	//Why wasn't it here?! - Gardelin0
				target_gen = c_partner.getorganslot(ORGAN_SLOT_STOMACH)
	if(gender == MALE || (gender == PLURAL && ismasculine(src)))
		playlewdinteractionsound(loc, pick('modular_sand/sound/interactions/final_m1.ogg',
							'modular_sand/sound/interactions/final_m2.ogg',
							'modular_sand/sound/interactions/final_m3.ogg',
							'modular_sand/sound/interactions/final_m4.ogg',
							'modular_sand/sound/interactions/final_m5.ogg'), 90, 1, 0)
	else if(gender != MALE || (gender == PLURAL && isfeminine(src)))
		playlewdinteractionsound(loc, pick('modular_sand/sound/interactions/final_f1.ogg',
							'modular_sand/sound/interactions/final_f2.ogg',
							'modular_sand/sound/interactions/final_f3.ogg'), 70, 1, 0)
	// BLUEMOON ADD хвостики!
	if(target_orifice == CUM_TARGET_TAIL && src == partner)
		message = "кончает на собственный хвост!"
	// BLUEMOON ADD END
	if(!message)
		message = pick("оргазмирует!", "трясётся в оргазме.", "дрожит от оргазма!", "кончает на себя!")
	visible_message(message = span_userlove("<b>\The [src]</b> [message]"), ignored_mobs = get_unconsenting(ignored_mobs = obscure_to))
	multiorgasms += 1

	COOLDOWN_START(src, refractory_period, (rand(300, 900) - get_sexual_potency()))//sex cooldown
	if(get_sexual_potency() == -1 || multiorgasms < get_sexual_potency()) //Splurt EDIT: Ignore multi-orgasms check if sexual potency is -1
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			if(!partner)
				H.mob_climax(TRUE, "masturbation", "none")
			else if(istype(partner, /obj/item/reagent_containers))
				H.mob_fill_container(last_genital, partner, 0)
			else
				H.mob_climax(TRUE, "sex", partner, !cumin, target_gen, anonymous)
		if(iscyborg(src)) //BLUEMOON ADD добавлено взаимодействие с боргами
			var/mob/living/silicon/robot/R = src
			if(!partner)
				R.mob_climax_silicon(TRUE, "masturbation", "none")
			else if(istype(partner, /obj/item/reagent_containers))
				R.mob_fill_container_silicon(R, partner, 0)
			else
				R.mob_climax_silicon(TRUE, "sex", partner, !cumin, target_gen, anonymous)
	set_lust(0)

	SEND_SIGNAL(src, COMSIG_MOB_POST_CAME, target_orifice, partner, cumin, last_genital)

	return TRUE

/mob/living/proc/is_fucking(mob/living/partner, orifice, obj/item/organ/genital/genepool, datum/interaction/lewd/lewd_datum)
	var/failed = FALSE
	if(partner)
		if(partner != last_partner)
			failed++
	if(orifice)
		if(orifice != last_orifice)
			failed++
	if(genepool)
		if(genepool != last_genital)
			failed++
	if(lewd_datum)
		if(lewd_datum != last_lewd_datum)
			failed++
	if(failed)
		return FALSE
	return TRUE

//BLUEMOON EDIT START
/mob/living/proc/set_is_fucking(mob/living/partner, orifice, genepool, sub_set = FALSE)
	last_partner = partner
	last_orifice = orifice
	if(istext(genepool))
		last_genital = getorganslot(genepool)
	else
		last_genital = genepool
	if(!sub_set && partner && partner != src)
		var/partner_orifice = istext(genepool) ? genepool : last_genital?.name
		if(!partner.is_fucking(src, partner_orifice, getorganslot(orifice == CUM_TARGET_URETHRA ? CUM_TARGET_PENIS : orifice), last_lewd_datum))
			partner.last_lewd_datum = last_lewd_datum
			partner.set_is_fucking(src, partner_orifice, partner.getorganslot(orifice == CUM_TARGET_URETHRA ? CUM_TARGET_PENIS : orifice), sub_set = TRUE)
	if(!last_lewd_datum) // Fleshlight and other not panel set_is_fucking clear timer
		if(cleartimer)
			deltimer(cleartimer)
		cleartimer = addtimer(CALLBACK(src, TYPE_PROC_REF(/mob/living, clear_lewd_datum)), 300, TIMER_STOPPABLE)
//BLUEMOON EDIT END

/mob/living/proc/get_shoes(singular = FALSE)
	var/obj/A = get_item_by_slot(ITEM_SLOT_FEET)
	if(A)
		var/txt = A.name
		if(findtext (A.name,"the"))
			txt = copytext(A.name, 5, length(A.name)+1)
			if(singular)
				txt = copytext(A.name, 5, length(A.name))
			return txt
		else
			if(singular)
				txt = copytext(A.name, 1, length(A.name))
			return txt

///Handles the sex, if cumming returns true.
/mob/living/proc/handle_post_sex(amount, orifice, mob/living/partner, organ = null, cum_inside = FALSE, anonymous = FALSE)
	if(stat != CONSCIOUS)
		return FALSE

	var/datum/preferences/prefs = client?.prefs
	var/use_arousal_multiplier = NULL_COALESCE(prefs?.use_arousal_multiplier, FALSE)
	var/arousal_multiplier = NULL_COALESCE(prefs?.arousal_multiplier, 100)
	var/use_moaning_multiplier = NULL_COALESCE(prefs?.use_moaning_multiplier, FALSE)
	var/moaning_multiplier = NULL_COALESCE(prefs?.moaning_multiplier, 25)

	if(amount)
		if (use_arousal_multiplier)
			add_lust(amount * (arousal_multiplier/100))
		else
			add_lust(amount)
	if (amount > 0 && use_moaning_multiplier && prob(moaning_multiplier)) // BLUEMOON EDIT
		moan()

	// Below is an overengineered bezier curve based chance of moaning.
	/// The current lust (arousal) amount.
	var/lust = get_lust()
	/// The lust tolerance as defined in preferences.
	//var/lust_tolerance = get_lust_tolerance() // BLUEMOON EDIT commeted, check proc get_lust_tolerance()
	/// The arousal limit upon which you climax.
	var/climax = get_climax_threshold() // BLUEMOON EDIT
	/// Threshold where you start moaning.
	var/threshold = climax/2
	///Calculation of 't' in bezier quadratic curve. It's a 0 to 1 version of threshold to climax.
	var/t = percentage_between(lust, threshold, climax, FALSE)
	// The Y axis value of the point in the bezier curve.
	var/bezier = 2 * (1 - t) * t * 13.8 + ((t*t) * 100)
	/// Probability chance resulting from bezier curve.
	var/chance = clamp(round(bezier),0,100)
	// BLUEMOON ADD START || More moan for simple
	if(amount> 0 && isnull(prefs))
		chance = max(30, chance)
	// BLUEMOON ADD END

	if (lust >= threshold)
		if(prob(30))
			to_chat(src, "<b>Вам трудно удержаться от оргазма!</b>")

		// BLUEMOON EDIT START
		if (!use_moaning_multiplier && amount > 0 && prob(chance))
			moan()
		// BLUEMOON EDIT END

		if (lust > climax)
			if (cum(partner, orifice, cum_inside, anonymous)) //SPLURT EDIT - extra argument `cum_inside` and `anonymous`
				return TRUE
	return FALSE

/mob/living/proc/get_unconsenting(interaction_flags, list/ignored_mobs)
	var/list/nope = list()
	nope += ignored_mobs
	for(var/mob/M in range(7, src))
		if(M.client)
			var/client/cli = M.client
			if(!(cli.prefs.toggles & VERB_CONSENT)) //Note: This probably could do with a specific preference
				nope += M
			else if(interaction_flags & INTERACTION_FLAG_EXTREME_CONTENT && (cli.prefs.extremepref == "No"))
				nope += M
		else
			nope += M
	return nope

// BLUEMOON ADD START
/mob/living/proc/get_climax_threshold()
	/// The lust tolerance as defined in preferences.
	var/lust_tolerance = get_lust_tolerance()

	/// The arousal limit upon which you climax.
	return lust_tolerance * 3
// BLUEMOON ADD END
