
//////////////////////////////////////////////////////////////////////////////////////////
					// MEDICINE REAGENTS
//////////////////////////////////////////////////////////////////////////////////////

// where all the reagents related to medicine go.

/datum/reagent/medicine
	name = "Medicine"
	taste_description = "bitterness"
	value = REAGENT_VALUE_VERY_COMMON //Low prices, spess medical companies are cheapstakes and products are taxed honk...

/datum/reagent/medicine/on_mob_life(mob/living/carbon/M)
	current_cycle++
	holder.remove_reagent(type, metabolization_rate / M.metabolism_efficiency) //medicine reagents stay longer if you have a better metabolism

/datum/reagent/medicine/leporazine
	name = "Leporazine"
	description = "Leporazine will effectively regulate a patient's body temperature, ensuring it never leaves safe levels."
	pH = 8.4
	color = "#82b8aa"
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/leporazine/on_mob_life(mob/living/carbon/M)
	if(M.bodytemperature > BODYTEMP_NORMAL)
		M.adjust_bodytemperature(-40 * TEMPERATURE_DAMAGE_COEFFICIENT, BODYTEMP_NORMAL)
	else if(M.bodytemperature < (BODYTEMP_NORMAL + 1))
		M.adjust_bodytemperature(40 * TEMPERATURE_DAMAGE_COEFFICIENT, 0, BODYTEMP_NORMAL)
	..()

/datum/reagent/medicine/adminordrazine //An OP chemical for admins
	name = "Adminordrazine"
	description = "It's magic. We don't have to explain it."
	color = "#ffffff"
	chemical_flags = REAGENT_ALL_PROCESS
	can_synth = FALSE
	taste_description = "badmins"
	value = REAGENT_VALUE_GLORIOUS

// The best stuff there is. For testing/debugging.
/datum/reagent/medicine/adminordrazine/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	if(chems.has_reagent(type, 1))
		mytray.adjustWater(round(chems.get_reagent_amount(type) * 1))
		mytray.adjustHealth(round(chems.get_reagent_amount(type) * 1))
		mytray.adjustPests(-rand(1,5))
		mytray.adjustWeeds(-rand(1,5))
	if(chems.has_reagent(type, 3))
		switch(rand(100))
			if(66  to 100)
				mytray.mutatespecie()
			if(33	to 65)
				mytray.mutateweed()
			if(1   to 32)
				mytray.mutatepest(user)
			else if(prob(20))
				mytray.visible_message("<span class='warning'>Nothing happens...</span>")

/datum/reagent/medicine/adminordrazine/on_mob_life(mob/living/carbon/M)
	M.reagents.remove_all_type(/datum/reagent/toxin, 5*REM, 0, 1)
	M.setCloneLoss(0, 0)
	M.setOxyLoss(0, 0)
	M.radiation = 0
	M.heal_bodypart_damage(5,5)
	M.adjustToxLoss(-5, 0, TRUE)
	M.hallucination = 0
	M.setOrganLoss(ORGAN_SLOT_BRAIN, 0)
	REMOVE_TRAITS_NOT_IN(M, list(SPECIES_TRAIT, ROUNDSTART_TRAIT, ORGAN_TRAIT))
	M.set_blurriness(0)
	M.set_blindness(0)
	M.SetAllImmobility(0, 0)
	M.SetUnconscious(0, 0)
	M.silent = FALSE
	M.dizziness = 0
	M.disgust = 0
	M.drowsyness = 0
	M.stuttering = 0
	M.slurring = 0
	M.confused = 0
	M.SetSleeping(0, 0)
	M.jitteriness = 0
	M.cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)
	if(M.blood_volume < (BLOOD_VOLUME_NORMAL*M.blood_ratio))
		M.blood_volume = (BLOOD_VOLUME_NORMAL*M.blood_ratio)

	for(var/organ in M.internal_organs)
		var/obj/item/organ/O = organ
		O.setOrganDamage(0)

	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(D.severity == DISEASE_SEVERITY_POSITIVE)
			continue
		D.cure()
	..()
	. = 1

/datum/reagent/medicine/adminordrazine/quantum_heal
	name = "Quantum Medicine"
	description = "Rare and experimental particles, that apparently swap the user's body with one from an alternate dimension where it's completely healthy."
	taste_description = "science"

/datum/reagent/medicine/synaptizine
	name = "Synaptizine"
	description = "Increases resistance to stuns as well as reducing drowsiness and hallucinations."
	color = "#FF00FF"
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 4

/datum/reagent/medicine/synaptizine/on_mob_life(mob/living/carbon/M)
	M.drowsyness = max(M.drowsyness-5, 0)
	M.AdjustAllImmobility(-20, 0)
	M.AdjustUnconscious(-20, 0)
	if(holder.has_reagent(/datum/reagent/toxin/mindbreaker))
		holder.remove_reagent(/datum/reagent/toxin/mindbreaker, 5)
	M.hallucination = max(0, M.hallucination - 10)
	if(prob(30))
		M.adjustToxLoss(1, 0)
		. = 1
	..()

/datum/reagent/medicine/synaphydramine
	name = "Diphen-Synaptizine"
	description = "Reduces drowsiness, hallucinations, and Histamine from body."
	color = "#EC536D" // rgb: 236, 83, 109
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 5.2
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/synaphydramine/on_mob_life(mob/living/carbon/M)
	M.drowsyness = max(M.drowsyness-5, 0)
	if(holder.has_reagent(/datum/reagent/toxin/mindbreaker))
		holder.remove_reagent(/datum/reagent/toxin/mindbreaker, 5)
	if(holder.has_reagent(/datum/reagent/toxin/histamine))
		holder.remove_reagent(/datum/reagent/toxin/histamine, 5)
	M.hallucination = max(0, M.hallucination - 10)
	if(prob(30))
		M.adjustToxLoss(1, 0)
		. = 1
	..()

/datum/reagent/medicine/inacusiate
	name = "Inacusiate"
	description = "Instantly restores all hearing to the patient, but does not cure deafness."
	color = "#6600FF" // rgb: 100, 165, 255
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 2
	value = 10

/datum/reagent/medicine/inacusiate/on_mob_life(mob/living/carbon/M)
	M.restoreEars()
	..()

/datum/reagent/medicine/cryoxadone
	name = "Cryoxadone"
	description = "A chemical mixture with almost magical healing powers. Its main limitation is that the patient's body temperature must be under 270K for it to metabolise correctly."
	color = "#0000C8"
	taste_description = "sludge"
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 11
	value = REAGENT_VALUE_COMMON

// Healing
/datum/reagent/medicine/cryoxadone/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	mytray.adjustHealth(round(chems.get_reagent_amount(type) * 3))
	mytray.adjustToxic(-round(chems.get_reagent_amount(type) * 3))

/datum/reagent/medicine/cryoxadone/on_mob_life(mob/living/carbon/M)
	var/power = -0.00003 * (M.bodytemperature ** 2) + 3
	if(M.bodytemperature < T0C && M.IsSleeping()) // BLUEMOON ADD now target is required to be asleep for healing process
		M.adjustOxyLoss(-4 * power, 0)
		M.adjustBruteLoss(-power, 0) // Cryo cell heal already 1-2
		M.adjustFireLoss(-2 * power, 0)
		M.adjustToxLoss(-2 * power, 0, TRUE) //heals TOXINLOVERs
		M.adjustCloneLoss(-power, 0)
		/*
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, -power*REM) //additional heal for brain
		for(var/organ in M.internal_organs)
			var/obj/item/organ/O = organ
			if (!(O.organ_flags & ORGAN_FAILING)) //Check for organ failure
				O.applyOrganDamage(-1 * power) //Use reverse damage for heal
		*/
		for(var/datum/wound/wound in M.all_wounds)
			if(wound.wound_type != WOUND_BURN || !wound?.limb.is_organic_limb())
				continue
			wound.on_xadone(power)
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC) //fixes common causes for disfiguration
		. = 1
	metabolization_rate = REAGENTS_METABOLISM * (0.00001 * (M.bodytemperature ** 2) + 0.5)
	..()

/datum/reagent/medicine/clonexadone
	name = "Clonexadone"
	description = "A chemical that derives from Cryoxadone. It specializes in healing clone damage, but nothing else. Requires very cold temperatures to properly metabolize, and metabolizes quicker than cryoxadone."
	color = "#0000C8"
	taste_description = "muscle"
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 13
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/clonexadone/on_mob_life(mob/living/carbon/M)
	if(M.bodytemperature < T0C)
		M.adjustCloneLoss(0.00006 * (M.bodytemperature ** 2) - 6, 0)
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
		. = 1
	metabolization_rate = REAGENTS_METABOLISM * (0.000015 * (M.bodytemperature ** 2) + 0.75)
	..()

/datum/reagent/medicine/pyroxadone
	name = "Pyroxadone"
	description = "A mixture of cryoxadone and slime jelly, that apparently inverses the requirement for its activation."
	color = "#f7832a"
	taste_description = "spicy jelly"
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 12
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/medicine/pyroxadone/on_mob_life(mob/living/carbon/M)
	if(M.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
		var/power = 0
		switch(M.bodytemperature)
			if(BODYTEMP_HEAT_DAMAGE_LIMIT to 400)
				power = 2
			if(400 to 460)
				power = 3
			else
				power = 5
		if(M.on_fire)
			power *= 2

		M.adjustOxyLoss(-2 * power, 0)
		M.adjustBruteLoss(-power, 0)
		M.adjustFireLoss(-1.5 * power, 0)
		M.adjustToxLoss(-power, 0, TRUE)
		M.adjustCloneLoss(-power, 0)
		for(var/i in M.all_wounds)
			var/datum/wound/iter_wound = i
			iter_wound.on_xadone(power)
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
		. = 1
	..()

/datum/reagent/medicine/rezadone
	name = "Rezadone"
	description = "A powder derived from fish toxin, Rezadone can effectively treat genetic damage as well as restoring minor wounds. Overdose will cause intense nausea and minor toxin damage."
	reagent_state = SOLID
	color = "#669900" // rgb: 102, 153, 0
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	overdose_threshold = 30
	taste_description = "fish"
	pH = 12.2
	value = REAGENT_VALUE_RARE

/datum/reagent/medicine/rezadone/on_mob_life(mob/living/carbon/M)
	M.setCloneLoss(0) //Rezadone is almost never used in favor of cryoxadone. Hopefully this will change that.
	M.heal_bodypart_damage(1,1)
	REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
	..()
	. = 1

/datum/reagent/medicine/rezadone/overdose_process(mob/living/M)
	M.adjustToxLoss(1, 0)
	M.Dizzy(5)
	M.Jitter(5)
	..()
	. = 1

/datum/reagent/medicine/rezadone/reaction_mob(mob/living/M, method=TOUCH, reac_volume, affected_bodypart)
	. = ..()
	if(iscarbon(M))
		var/mob/living/carbon/patient = M
		var/vol = reac_volume + M.reagents.get_reagent_amount(/datum/reagent/medicine/rezadone)
		if(vol >= 5 && HAS_TRAIT_FROM(patient, TRAIT_HUSK, "burn") && patient.getFireLoss() < THRESHOLD_UNHUSK) //One carp yields 12u rezadone.
			patient.cure_husk("burn")
			patient.visible_message("<span class='nicegreen'>[patient]'s body rapidly absorbs moisture from the enviroment, taking on a more healthy appearance.")

/datum/reagent/medicine/spaceacillin
	name = "Spaceacillin"
	description = "Spaceacillin will prevent a patient from conventionally spreading any diseases they are currently infected with. Also reduces infection in serious burns."
	color = "#f2f2f2"
	metabolization_rate = 0.1 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 8.1

//Goon Chems. Ported mainly from Goonstation. Easily mixable (or not so easily) and provide a variety of effects.
/datum/reagent/medicine/silver_sulfadiazine
	name = "Silver Sulfadiazine"
	description = "If used in touch-based applications, immediately restores burn wounds as well as restoring more over time. It is mildly poisonous taken orally or by injection. If overdosed, deals brute and minor liver damage."
	reagent_state = LIQUID
	pH = 7.2
	color = "#ffeac9"
	metabolization_rate = 5 * REAGENTS_METABOLISM
	overdose_threshold = 50

/datum/reagent/medicine/silver_sulfadiazine/reaction_obj(obj/O, reac_volume)
	if(istype(O, /obj/item/stack/medical/gauze/adv))
		var/obj/item/stack/medical/gauze/G = O
		reac_volume = min((reac_volume / 5), G.amount)
		new /obj/item/stack/medical/mesh/five(get_turf(G), reac_volume)
		G.use(reac_volume)

/datum/reagent/medicine/silver_sulfadiazine/reaction_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1, affected_bodypart = BODY_ZONE_CHEST)
	if(M.stat == DEAD)
		return ..()

	if(isanimal(M))
		M.adjustFireLoss(-reac_volume * 0.75) // Невозможно как-либо передать  симплмобу, кроме обливанием. Потому без бонуса пластыря.
		to_chat(M, span_danger("Вы ощущаете, как ваши ожоги затягиваются! Жжётся адски!"))
		return ..()

	if(!iscarbon(M))
		return ..()

	var/reac_strength = reac_volume
	var/mob/living/carbon/human/H = M
	var/obj/item/bodypart/aff_bodypart = affected_bodypart
	// Проверка на одежду
	if(ishuman(M))
		if(method == TOUCH && aff_bodypart)
			var/obj/item/clothing/protecting_clothing
			protecting_clothing = get_bodypart_protecting_clothing_by_coverage(H, aff_bodypart)
			if(protecting_clothing)
				if(protecting_clothing.clothing_flags & THICKMATERIAL) // РИГ? ЕВА? Бронежилет СБ? Не подействует.
					M.visible_message(span_danger("[H] был[H.ru_a()] чем-то облит[H.ru_a()], но оно стекло вниз по [protecting_clothing.name]!"), \
								span_danger("Меня чем-то облили, но оно стекло вниз по [protecting_clothing.name]!"))
					playsound(src.loc, 'modular_bluemoon/krashly/sound/items/watersplash.ogg', 40, 1)
					return ..()
				else
					reac_strength = reac_strength * 0.6 // Защита любой одеждой снижает эффективность препарата

		switch(method)
			// Отравление не-касательным применением
			if(INGEST, VAPOR, INJECT)
				M.adjustToxLoss(reac_volume * pick(0.4, 0.5, 0.6))
				if(show_message)
					to_chat(M, span_warning("Вы ощущаете себя не очень хорошо..."))
			// Эффекты самого лекарства. Лечение бёрна.
			if(TOUCH, PATCH)
				if(!M.getFireLoss())
					return ..()
				if(method == TOUCH) // Пластыри справятся лучше
					reac_strength *= 0.75
				if(ishuman(M))
					if(!aff_bodypart || !aff_bodypart.burn_dam)
						return ..()
					else
						aff_bodypart.heal_damage(burn = reac_strength)
				else // Обезьяна? Ксенос?
					M.adjustFireLoss(-reac_strength)
				if(show_message) // Крики и прочий флавор-эффект.
					if(!HAS_TRAIT(M, TRAIT_MASO))
						to_chat(M, span_danger("Вы ощущаете, как ваши ожоги затягиваются! Жжётся адски!"))
						if((!HAS_TRAIT(M, TRAIT_PAINKILLER) || !HAS_TRAIT(M, TRAIT_BLUEMOON_HIGH_PAIN_THRESHOLD)) && reac_volume >= 10 && prob(50))
							M.emote("scream")
							M.Jitter(reac_strength / 4)
						else
							M.emote("me", EMOTE_VISIBLE, "стискивает зубы от боли.")
					else
						to_chat(M, span_lewd("Вы ощущаете, как ваши ожоги затягиваются! Жжётся адски!~"))
						M.handle_post_sex(rand(LOW_LUST, reac_strength), null, null)
						if(reac_volume >= 10)
							M.emote("scream")
						else
							M.emote("moan")
				// Общие эффекты
				M.blur_eyes(reac_strength / 2)
				shake_camera(M, 5, 2)
				if(!HAS_TRAIT(M, TRAIT_MASO))
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "painful_medicine", /datum/mood_event/painful_medicine)
				else
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "maso_medicine", /datum/mood_event/maso_medicine)
	..()

/datum/reagent/medicine/silver_sulfadiazine/on_mob_life(mob/living/carbon/M)
	M.adjustFireLoss(-2*REM, 0)
	..()
	. = 1

/datum/reagent/medicine/silver_sulfadiazine/overdose_start(mob/living/M)
	metabolization_rate = 15 * REAGENTS_METABOLISM
	..()
	. = 1

/datum/reagent/medicine/silver_sulfadiazine/overdose_process(mob/living/M)
	M.adjustFireLoss(2*REM, 0)
	var/obj/item/organ/liver/L = M.getorganslot(ORGAN_SLOT_LIVER)
	if(L)
		L.applyOrganDamage(1)
	..()
	. = 1

/datum/reagent/medicine/oxandrolone
	name = "Oxandrolone"
	description = "Stimulates the healing of severe burns. Extremely rapidly heals severe burns and slowly heals minor ones. Overdose will worsen existing burns."
	reagent_state = LIQUID
	color = "#f7ffa5"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 25
	pH = 10.7
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/oxandrolone/on_mob_life(mob/living/carbon/M)
	if(M.getFireLoss() > 25)
		M.adjustFireLoss(-4*REM, 0) //Twice as effective as silver sulfadiazine for severe burns
	else
		M.adjustFireLoss(-0.5*REM, 0) //But only a quarter as effective for more minor ones
	..()
	. = 1

/datum/reagent/medicine/oxandrolone/overdose_process(mob/living/M)
	if(M.getFireLoss()) //It only makes existing burns worse
		M.adjustFireLoss(4.5*REM, 0) // it's going to be healing either 4 or 0.5
		. = 1
	..()

/datum/reagent/medicine/styptic_powder
	name = "Styptic Powder"
	description = "If used in touch-based applications, immediately restores bruising as well as restoring more over time. It is poisonous if taken orally or by injection. If overdosed, deals brute and minor liver damage."
	reagent_state = LIQUID
	color = "#FF9696"
	pH = 6.7
	metabolization_rate = 5 * REAGENTS_METABOLISM
	overdose_threshold = 50

/datum/reagent/medicine/styptic_powder/reaction_mob(mob/living/M, method, reac_volume, show_message = 1, touch_protection = 0, affected_bodypart)
	if(M.stat == DEAD)
		return ..()

	if(isanimal(M))
		M.adjustBruteLoss(-reac_volume * 0.75) // Невозможно как-либо передать  симплмобу, кроме обливанием. Потому без бонуса пластыря.
		to_chat(M, span_danger("Вы ощущаете, как ваши ушибы затягиваются! Жжётся адски!"))
		return ..()

	if(!iscarbon(M))
		return ..()

	var/reac_strength = reac_volume
	var/mob/living/carbon/human/H = M
	var/obj/item/bodypart/aff_bodypart = affected_bodypart
	// Проверка на одежду
	if(ishuman(M))
		if(method == TOUCH && aff_bodypart)
			var/obj/item/clothing/protecting_clothing
			protecting_clothing = get_bodypart_protecting_clothing_by_coverage(H, aff_bodypart)
			if(protecting_clothing)
				if(protecting_clothing.clothing_flags & THICKMATERIAL) // РИГ? ЕВА? Бронежилет СБ? Не подействует.
					M.visible_message(span_danger("[H] был[H.ru_a()] чем-то облит[H.ru_a()], но оно стекло вниз по [protecting_clothing.name]!"), \
								span_danger("Меня чем-то облили, но оно стекло вниз по [protecting_clothing.name]!"))
					playsound(src.loc, 'modular_bluemoon/krashly/sound/items/watersplash.ogg', 40, 1)
					return ..()
				else
					reac_strength = reac_strength * 0.6 // Защита любой одеждой снижает эффективность препарата

		switch(method)
			// Отравление не-касательным применением
			if(INGEST, VAPOR, INJECT)
				M.adjustToxLoss(reac_volume * pick(0.4, 0.5, 0.6))
				if(show_message)
					to_chat(M, span_warning("Вы ощущаете себя не очень хорошо..."))
			// Лечение брута
			if(TOUCH, PATCH)
				if(!M.getBruteLoss())
					return ..()
				if(method == TOUCH) // Пластыри справятся лучш
					reac_strength *= 0.75
				if(ishuman(M))
					if(!aff_bodypart || !aff_bodypart.brute_dam)
						return ..()
					else
						aff_bodypart.heal_damage(brute = reac_strength)
				else // Обезьяна? Ксенос?
					M.adjustBruteLoss(-reac_strength)
				if(show_message) // Крики и прочий флавор-эффект.
					if(!HAS_TRAIT(M, TRAIT_MASO))
						to_chat(M, span_danger("Вы ощущаете, как ваши ушибы затягиваются! Жжётся адски!"))
						if((!HAS_TRAIT(M, TRAIT_PAINKILLER) || !HAS_TRAIT(M, TRAIT_BLUEMOON_HIGH_PAIN_THRESHOLD)) && reac_volume >= 10 && prob(50))
							M.emote("scream")
							M.Jitter(reac_strength / 4)
						else
							M.emote("me", EMOTE_VISIBLE, "стискивает зубы от боли.")
					else
						to_chat(M, span_lewd("Вы ощущаете, как ваши ушибы затягиваются! Жжётся адски!~"))
						M.handle_post_sex(rand(LOW_LUST, reac_strength), null, null)
						if(reac_volume >= 10)
							M.emote("scream")
						else
							M.emote("moan")
				// Общие эффекты
				M.Dizzy(reac_strength / 4)
				shake_camera(M, 5, 2)
				if(!HAS_TRAIT(M, TRAIT_MASO))
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "painful_medicine", /datum/mood_event/painful_medicine)
				else
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "maso_medicine", /datum/mood_event/maso_medicine)
	..()

/datum/reagent/medicine/styptic_powder/reaction_obj(obj/O, reac_volume)
	if(istype(O, /obj/item/stack/medical/gauze/adv))
		var/obj/item/stack/medical/gauze/G = O
		reac_volume = min((reac_volume / 5), G.amount)
		new /obj/item/stack/medical/suture/five(get_turf(G), reac_volume)
		G.use(reac_volume)

/datum/reagent/medicine/styptic_powder/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-2*REM, 0)
	..()
	. = 1

/datum/reagent/medicine/styptic_powder/overdose_start(mob/living/M)
	metabolization_rate = 15 * REAGENTS_METABOLISM
	..()
	. = 1

/datum/reagent/medicine/styptic_powder/overdose_process(mob/living/M)
	M.adjustBruteLoss(2*REM, 0)
	var/obj/item/organ/liver/L = M.getorganslot(ORGAN_SLOT_LIVER)
	if(L)
		L.applyOrganDamage(1)
	..()
	. = 1

/datum/reagent/medicine/salglu_solution
	name = "Saline-Glucose Solution"
	description = "Has a 33% chance per metabolism cycle to heal brute and burn damage. Can be used as a temporary blood substitute, as well as slowly speeding blood regeneration."
	reagent_state = LIQUID
	color = "#DCDCDC"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)SS
	overdose_threshold = 60
	boiling_point = T0C+100
	gas = GAS_H2O
	taste_description = "sweetness and salt"
	var/extra_regen = 0.25 // in addition to acting as temporary blood, also add this much to their actual blood per tick
	var/last_added = 0
	var/maximum_reachable = BLOOD_VOLUME_NORMAL - 10	//So that normal blood regeneration can continue with salglu active
	pH = 5.5

/datum/reagent/medicine/salglu_solution/on_mob_life(mob/living/carbon/human/M)
	if(prob(33))
		M.adjustBruteLoss(-0.5*REM, 0)
		M.adjustFireLoss(-0.5*REM, 0)
		. = TRUE
	if((HAS_TRAIT(M, TRAIT_NOMARROW)))
		return ..()
	if(last_added)
		M.adjust_integration_blood(-last_added, TRUE)
		last_added = 0
	if(M.functional_blood() < maximum_reachable) //Can only up to double your effective blood level.
		var/new_blood_level = min(volume * 5, maximum_reachable)
		last_added = new_blood_level
		M.adjust_integration_blood(new_blood_level + (extra_regen * REM))
	if(prob(33))
		M.adjustBruteLoss(-0.5*REM, 0)
		M.adjustFireLoss(-0.5*REM, 0)
		. = TRUE
	..()

/datum/reagent/medicine/salglu_solution/on_mob_delete(mob/living/carbon/human/M)
	if(last_added)
		M.adjust_integration_blood(-last_added, TRUE)
	..()

/datum/reagent/medicine/salglu_solution/overdose_process(mob/living/M)
	if(prob(3))
		to_chat(M, "<span class = 'warning'>You feel salty.</span>")
		holder.add_reagent(/datum/reagent/consumable/sodiumchloride, 1)
		holder.remove_reagent(/datum/reagent/medicine/salglu_solution, 0.5)
	else if(prob(3))
		to_chat(M, "<span class = 'warning'>You feel sweet.</span>")
		holder.add_reagent(/datum/reagent/consumable/sugar, 1)
		holder.remove_reagent(/datum/reagent/medicine/salglu_solution, 0.5)
	if(prob(33))
		M.adjustBruteLoss(0.5*REM, 0)
		M.adjustFireLoss(0.5*REM, 0)
		. = TRUE
	..()

/datum/reagent/medicine/mine_salve
	name = "Miner's Salve"
	description = "A powerful painkiller. Restores bruising and burns in addition to making the patient believe they are fully healed. Also great for treating severe burn wounds in a pinch."
	reagent_state = LIQUID
	color = "#6D6374"
	metabolization_rate = 0.4 * REAGENTS_METABOLISM
	pH = 2.6
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/mine_salve/on_mob_life(mob/living/carbon/C)
	C.hal_screwyhud = SCREWYHUD_HEALTHY
	C.adjustBruteLoss(-0.25*REM, 0)
	C.adjustFireLoss(-0.25*REM, 0)
	C.adjustStaminaLoss(-0.5*REM, 0)
	..()
	return TRUE

/datum/reagent/medicine/mine_salve/reaction_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1, affected_bodypart)
	if(iscarbon(M) && M.stat != DEAD)
		if(method in list(INGEST, VAPOR, INJECT))
			M.adjust_nutrition(-5)
			if(show_message)
				to_chat(M, "<span class='warning'>Your stomach feels empty and cramps!</span>")
		else
			/* BLUEMOON REMOVAL START - шанс на операцию за обезболивающее перенесен
			var/mob/living/carbon/C = M
			for(var/s in C.surgeries)
				var/datum/surgery/S = s
				S.success_multiplier = max(0.1, S.success_multiplier)
				// +10% success propability on each step, useful while operating in less-than-perfect conditions
			/ BLUEMOON REMOVAL END */
			if(show_message)
				to_chat(M, "<span class='danger'>You feel your injuries fade away to nothing!</span>" )
	..()

/datum/reagent/medicine/mine_salve/on_mob_end_metabolize(mob/living/M)
	if(iscarbon(M))
		var/mob/living/carbon/N = M
		N.hal_screwyhud = SCREWYHUD_NONE
		REMOVE_TRAIT(M, TRAIT_PAINKILLER, PAINKILLER_MINERSSALVE) //SKYRAT EDIT, Painkiller.
	..()

/datum/reagent/medicine/synthflesh
	name = "Synthflesh"
	description = "Has a 100% chance of healing large amounts of brute and burn damage very quickly. It toxic to the body if it gets into wounds. One unit of the chemical will heal one point of damage. Touch application only." // BLUEMOON EDIT
	reagent_state = LIQUID
	color = "#FFEBEB"
	pH = 11.5
	metabolization_rate = 5 * REAGENTS_METABOLISM
	overdose_threshold = 40
	value = REAGENT_VALUE_COMMON
	var/toxic = TRUE // BLUEMOON ADD

/datum/reagent/medicine/synthflesh/reaction_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1, affected_bodypart)
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		if(M.stat == DEAD)
			show_message = 0
		if(method in list(INGEST, VAPOR))
			C.losebreath++
			C.emote("cough")
			to_chat(M, "<span class='danger'>You feel your throat closing up!</span>")
		else if(method == INJECT)
			return
		else if(method in list(PATCH, TOUCH))
			var/total_damage = 0
			// BLUEMOON ADD START
			if(toxic)
				total_damage = M.getFireLoss() + M.getBruteLoss()
			// BLUEMOON ADD END
			M.adjustBruteLoss(-1 * reac_volume)
			M.adjustFireLoss(-1 * reac_volume)
			// BLUEMOON ADD START
			if(toxic)
				M.adjustToxLoss(0.75 * total_damage - M.getFireLoss() - M.getBruteLoss()) // cured damage multiplied by the coefficient apply as toxins
			// BLUEMOON ADD END
			for(var/i in C.all_wounds)
				var/datum/wound/iter_wound = i
				iter_wound.on_synthflesh(reac_volume)
			if(show_message)
				to_chat(M, "<span class='danger'>You feel your burns and bruises healing! It stings like hell!</span>")
			SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "painful_medicine", /datum/mood_event/painful_medicine)
			var/vol = reac_volume + M.reagents.get_reagent_amount(/datum/reagent/medicine/synthflesh)
			// 100 synthflesh at least. Corpses dont metabolize.
			if(vol >= 100)
				for(var/i in C.all_scars)
					qdel(i)

				//Has to be at less than THRESHOLD_UNHUSK burn damage before unhusking.
				if(HAS_TRAIT_FROM(M, TRAIT_HUSK, "burn") && M.getFireLoss() < THRESHOLD_UNHUSK)
					M.cure_husk("burn")
					M.visible_message("<span class='nicegreen'>Most of [M]'s burnt off or charred flesh has been restored.")
	..()

/datum/reagent/medicine/synthflesh/overdose_start(mob/living/M)
	metabolization_rate = 15 * REAGENTS_METABOLISM

// BLUEMOON ADD START
/datum/reagent/medicine/synthflesh/neo
	name = "Neosynth"
	description = "An advanced nanosynthetic biomaterial capable of instantly repairing damaged tissues in direct contact with the skin. Uses intelligent nanoparticles to assess the type of injury and adaptive regeneration. It does not require metabolism, it is activated by touch. It was developed as the final stage in the evolution of synthetic flesh."
	color = "#6fe0ff"
	value = REAGENT_VALUE_UNCOMMON
	toxic = FALSE
	taste_description = "sparkles"
// BLUEMOON ADD END

/datum/reagent/medicine/charcoal
	name = "Charcoal"
	description = "Heals toxin damage as well as slowly removing any other chemicals the patient has in their bloodstream."
	reagent_state = LIQUID
	color = "#000000"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	taste_description = "ash"
	pH = 5

/datum/reagent/medicine/charcoal/on_mob_life(mob/living/carbon/M)
	M.adjustToxLoss(-2*REM, 0)
	. = 1
	for(var/A in M.reagents.reagent_list)
		var/datum/reagent/R = A
		if(R != src)
			M.reagents.remove_reagent(R.type,1)
	..()

/datum/reagent/medicine/omnizine
	name = "Omnizine"
	description = "Slowly heals all damage types. Overdose will cause damage in all types instead."
	reagent_state = LIQUID
	color = "#DCDCDC"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	pH = 2
	value = REAGENT_VALUE_UNCOMMON
	var/healing = 0.5

/datum/reagent/medicine/omnizine/on_mob_life(mob/living/carbon/M)
	M.adjustToxLoss(-healing*REM, 0)
	M.adjustOxyLoss(-healing*REM, 0)
	M.adjustBruteLoss(-healing*REM, 0)
	M.adjustFireLoss(-healing*REM, 0)
	..()
	. = 1

/datum/reagent/medicine/omnizine/overdose_process(mob/living/M)
	M.adjustToxLoss(1.5*REM, 0)
	M.adjustOxyLoss(1.5*REM, 0)
	M.adjustBruteLoss(1.5*REM, 0)
	M.adjustFireLoss(1.5*REM, 0)
	..()
	. = 1

/datum/reagent/medicine/omnizine/protozine
	name = "Protozine"
	description = "A less environmentally friendly and somewhat weaker variant of omnizine."
	color = "#d8c7b7"
	healing = 0.2

/datum/reagent/medicine/calomel
	name = "Calomel"
	description = "Quickly purges the body of all chemicals. Toxin damage is dealt if the patient is in good condition."
	reagent_state = LIQUID
	color = "#19C832"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	taste_description = "acid"
	pH = 1.5

/datum/reagent/medicine/calomel/on_mob_life(mob/living/carbon/M)
	for(var/A in M.reagents.reagent_list)
		var/datum/reagent/R = A
		if(R != src)
			M.reagents.remove_reagent(R.type,2.5)
	if(M.health > 20)
		M.adjustToxLoss(2.5*REM, 0)
		. = 1
	..()

/datum/reagent/medicine/potass_iodide
	name = "Potassium Iodide"
	description = "Efficiently restores low radiation damage."
	reagent_state = LIQUID
	color = "#14FF3C"
	metabolization_rate = 2 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 12 //It's a reducing agent

/datum/reagent/medicine/potass_iodide/on_mob_life(mob/living/carbon/M)
	if(M.radiation > 0)
		M.radiation -= min(M.radiation, 8)
	..()

/datum/reagent/medicine/prussian_blue
	name = "Prussian Blue"
	description = "Efficiently restores heavy radiation damage."
	reagent_state = LIQUID
	color = "#003153" // RGB 0, 49, 83
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 8.9
	value = REAGENT_VALUE_COMMON //uncraftable

/datum/reagent/medicine/prussian_blue/on_mob_life(mob/living/carbon/M)
	if(M.radiation > 0)
		M.radiation -= min(M.radiation, 20)
	..()

/datum/reagent/medicine/pen_acid
	name = "Pentetic Acid"
	description = "Reduces massive amounts of radiation and toxin damage while purging other chemicals from the body."
	reagent_state = LIQUID
	color = "#E6FFF0"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 1 //One of the best buffers, NEVERMIND!
	value = REAGENT_VALUE_UNCOMMON
	var/healtoxinlover = FALSE

/datum/reagent/medicine/pen_acid/on_mob_life(mob/living/carbon/M)
	M.radiation -= max(M.radiation-RAD_MOB_SAFE, 0)/50
	M.adjustToxLoss(-2*REM, 0, healtoxinlover)
	for(var/A in M.reagents.reagent_list)
		var/datum/reagent/R = A
		if(R != src)
			M.reagents.remove_reagent(R.type,2)
	..()
	. = 1

/datum/reagent/medicine/pen_acid/pen_jelly
	name = "Pentetic Jelly"
	description = "Reduces massive amounts of radiation and toxin damage while purging other chemicals from the body. Slimepeople friendly!"
	color = "#91D865"
	healtoxinlover = TRUE
	pH = 12//invert
	value = REAGENT_VALUE_RARE

/datum/reagent/medicine/sal_acid
	name = "Salicylic Acid"
	description = "Stimulates the healing of severe bruises. Extremely rapidly heals severe bruising and slowly heals minor ones. Overdose will worsen existing bruising."
	reagent_state = LIQUID
	color = "#D2D2D2"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 25
	pH = 2.1
	value = REAGENT_VALUE_COMMON


/datum/reagent/medicine/sal_acid/on_mob_life(mob/living/carbon/M)
	if(M.getBruteLoss() > 25)
		M.adjustBruteLoss(-4*REM, 0) //Twice as effective as styptic powder for severe bruising
	else
		M.adjustBruteLoss(-0.5*REM, 0) //But only a quarter as effective for more minor ones
	..()
	. = 1

/datum/reagent/medicine/sal_acid/overdose_process(mob/living/M)
	if(M.getBruteLoss()) //It only makes existing bruises worse
		M.adjustBruteLoss(4.5*REM, 0) // it's going to be healing either 4 or 0.5
		. = 1
	..()

/datum/reagent/medicine/salbutamol
	name = "Salbutamol"
	description = "Rapidly restores breathing deprivation as well as preventing more of it to an extent. Causes jittering."
	reagent_state = LIQUID
	color = "#00FFFF"
	boiling_point = 300
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	pH = 2

/datum/reagent/medicine/salbutamol/on_mob_life(mob/living/carbon/M)
	M.adjustOxyLoss(-3*REM, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2
	M.Jitter(5)
	..()
	. = 1

/datum/reagent/medicine/perfluorodecalin
	name = "Perfluorodecalin"
	description = "Extremely rapidly restores breathing deprivation, but inhibits speech. May also heal small amounts of bruising and burns."
	reagent_state = LIQUID
	color = "#FF6464"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	pH = 11

/datum/reagent/medicine/perfluorodecalin/on_mob_life(mob/living/carbon/human/M)
	M.adjustOxyLoss(-12*REM, 0)
	M.silent = max(M.silent, 5)
	if(prob(33))
		M.adjustBruteLoss(-0.5*REM, 0)
		M.adjustFireLoss(-0.5*REM, 0)
	..()
	return TRUE

/datum/reagent/medicine/ephedrine
	name = "Ephedrine"
	description = "Increases stun resistance. Overdose deals toxin damage and inhibits breathing."
	reagent_state = LIQUID
	color = "#D2FFFA"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 45
	addiction_threshold = 30
	pH = 12

/datum/reagent/medicine/ephedrine/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/ephedrine)
	ADD_TRAIT(L, TRAIT_TASED_RESISTANCE, type)

/datum/reagent/medicine/ephedrine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/ephedrine)
	REMOVE_TRAIT(L, TRAIT_TASED_RESISTANCE, type)
	..()

/datum/reagent/medicine/ephedrine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(7.5, delta_time) && iscarbon(M))
		var/obj/item/Iactive = M.get_active_held_item()
		if(Iactive && M.dropItemToGround(Iactive))
			to_chat(M, span_notice("Your hands spaz out and you drop what you were holding!"))
			M.Jitter(10)
	if(DT_PROB(5, delta_time) && iscarbon(M))
		var/obj/item/Isecond = M.get_inactive_held_item()
		if(Isecond && M.dropItemToGround(Isecond))
			to_chat(M, span_notice("Your hands spaz out and you drop what you were holding!"))
			M.Jitter(10)

	M.AdjustAllImmobility(-20 * REM * delta_time)
	M.adjustStaminaLoss(-1 * REM * delta_time, FALSE)
	..()
	return TRUE

/datum/reagent/medicine/ephedrine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(1, delta_time) && iscarbon(M))
		var/datum/disease/D = new /datum/disease/heart_failure
		M.ForceContractDisease(D)
		to_chat(M, span_userdanger("You're pretty sure you just felt your heart stop for a second there.."))
		M.playsound_local(M, 'sound/effects/singlebeat.ogg', 100, 0)

	if(DT_PROB(3.5, delta_time))
		to_chat(M, span_notice("[pick("Your head pounds.", "You feel a tight pain in your chest.", "You find it hard to stay still.", "You feel your heart practically beating out of your chest.")]"))

	if(DT_PROB(18, delta_time))
		M.adjustToxLoss(1, 0)
		M.losebreath++
		. = TRUE
	return TRUE

/datum/reagent/medicine/ephedrine/addiction_act_stage1(mob/living/M)
	if(prob(33))
		M.adjustToxLoss(2*REM, 0)
		M.losebreath += 2
		. = 1
	..()

/datum/reagent/medicine/ephedrine/addiction_act_stage2(mob/living/M)
	if(prob(33))
		M.adjustToxLoss(3*REM, 0)
		M.losebreath += 3
		. = 1
	..()

/datum/reagent/medicine/ephedrine/addiction_act_stage3(mob/living/M)
	if(prob(33))
		M.adjustToxLoss(4*REM, 0)
		M.losebreath += 4
		. = 1
	..()

/datum/reagent/medicine/ephedrine/addiction_act_stage4(mob/living/M)
	if(prob(33))
		M.adjustToxLoss(5*REM, 0)
		M.losebreath += 5
		. = 1
	..()

/datum/reagent/medicine/diphenhydramine
	name = "Diphenhydramine"
	description = "Rapidly purges the body of Histamine and reduces jitteriness. Slight chance of causing drowsiness."
	reagent_state = LIQUID
	color = "#64FFE6"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	pH = 11.5
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/diphenhydramine/on_mob_life(mob/living/carbon/M)
	if(prob(10))
		M.drowsyness += 1
	M.jitteriness -= 1
	M.reagents.remove_reagent(/datum/reagent/toxin/histamine,3)
	..()

/datum/reagent/medicine/morphine
	name = "Morphine"
	description = "A painkiller that allows the patient to move at full speed even in bulky objects. Causes drowsiness and eventually unconsciousness in high doses. Overdose will cause a variety of effects, ranging from minor to lethal."
	reagent_state = LIQUID
	color = "#A9FBFB"
	metabolization_rate = 0.1
	overdose_threshold = 20
	addiction_threshold = 25
	pH = 8.96

/datum/reagent/medicine/morphine/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_PAINKILLER, PAINKILLER_MORPHINE) //SKYRAT EDIT, Painkiller.
	L.throw_alert("painkiller", /atom/movable/screen/alert/painkiller) // BLUEMOON ADD
	L.add_movespeed_mod_immunities(type, list(/datum/movespeed_modifier/damage_slowdown, /datum/movespeed_modifier/damage_slowdown_flying, /datum/movespeed_modifier/monkey_health_speedmod))

/datum/reagent/medicine/morphine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_mod_immunities(type, list(/datum/movespeed_modifier/damage_slowdown, /datum/movespeed_modifier/damage_slowdown_flying, /datum/movespeed_modifier/monkey_health_speedmod))
	REMOVE_TRAIT(L, TRAIT_PAINKILLER, PAINKILLER_MORPHINE) //SKYRAT EDIT, Painkiller.
	L.clear_alert("painkiller", /atom/movable/screen/alert/painkiller) // BLUEMOON ADD
	..()

/datum/reagent/medicine/morphine/on_mob_life(mob/living/carbon/M)
	..()

/datum/reagent/medicine/morphine/overdose_process(mob/living/M)
	switch(current_cycle)
		if(12)
			to_chat(M, "<span class='warning'>Вы чувствуете себя устало...</span>" )
		if(24 to 48)
			M.drowsyness += 1
		if(96 to INFINITY)
			M.Sleeping(100, 0) // BLUEMOON EDIT - было 40, сделал 100. Морфин по итогу не накладывает сон и человек просыпается быстро.
			. = 1
	if(prob(33))
		M.drop_all_held_items()
		M.Dizzy(2)
		M.Jitter(2)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage1(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Jitter(2)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage2(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(1*REM, 0)
		. = 1
		M.Dizzy(3)
		M.Jitter(3)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage3(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(2*REM, 0)
		. = 1
		M.Dizzy(4)
		M.Jitter(4)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage4(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(3*REM, 0)
		. = 1
		M.Dizzy(5)
		M.Jitter(5)
	..()

/datum/reagent/medicine/oculine
	name = "Oculine"
	description = "Quickly restores eye damage, cures nearsightedness, and has a chance to restore vision to the blind."
	reagent_state = LIQUID
	color = "#FFFFFF"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	taste_description = "dull toxin"
	pH = 10

/datum/reagent/medicine/oculine/on_mob_life(mob/living/carbon/M)
	var/obj/item/organ/eyes/eyes = M.getorganslot(ORGAN_SLOT_EYES)
	if (!eyes)
		return
	eyes.applyOrganDamage(-2)
	if(HAS_TRAIT_FROM(M, TRAIT_BLIND, EYE_DAMAGE))
		if(prob(20))
			to_chat(M, "<span class='warning'>Your vision slowly returns...</span>")
			M.cure_blind(EYE_DAMAGE)
			M.cure_nearsighted(EYE_DAMAGE)
			M.blur_eyes(35)

	else if(HAS_TRAIT_FROM(M, TRAIT_NEARSIGHT, EYE_DAMAGE))
		to_chat(M, "<span class='warning'>The blackness in your peripheral vision fades.</span>")
		M.cure_nearsighted(EYE_DAMAGE)
		M.blur_eyes(10)
	else if(M.eye_blind || M.eye_blurry)
		M.set_blindness(0)
		M.set_blurriness(0)
	..()

/datum/reagent/medicine/atropine
	name = "Atropine"
	description = "If a patient is in critical condition, rapidly heals all damage types as well as regulating oxygen in the body. Excellent for stabilizing wounded patients."
	reagent_state = LIQUID
	color = "#000000"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 35
	pH = 12
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/medicine/atropine/on_mob_life(mob/living/carbon/M)
	if(M.health < 0)
		M.adjustToxLoss(-2*REM, 0)
		M.adjustBruteLoss(-2*REM, 0)
		M.adjustFireLoss(-2*REM, 0)
		M.adjustOxyLoss(-5*REM, 0)
		. = 1
	M.losebreath = 0
	if(prob(20))
		M.Dizzy(5)
		M.Jitter(5)
	..()

/datum/reagent/medicine/atropine/overdose_process(mob/living/M)
	M.adjustToxLoss(0.5*REM, 0)
	. = 1
	M.Dizzy(1)
	M.Jitter(1)
	..()

/datum/reagent/medicine/epinephrine
	name = "Epinephrine"
	description = "Minor boost to stun resistance. Slowly heals damage if a patient is in critical condition, as well as regulating oxygen loss. Overdose causes weakness and toxin damage."
	reagent_state = LIQUID
	color = "#D2FFFA"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	pH = 10.2

/datum/reagent/medicine/epinephrine/on_mob_life(mob/living/carbon/M)
	if(M.health < 0)
		M.adjustToxLoss(-0.5*REM, 0)
		M.adjustBruteLoss(-0.5*REM, 0)
		M.adjustFireLoss(-0.5*REM, 0)
	if(M.oxyloss > 35)
		M.setOxyLoss(35, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2
	if(M.losebreath < 0)
		M.losebreath = 0
	M.adjustStaminaLoss(-0.5*REM, 0)
	. = 1
	if(prob(20))
		M.AdjustAllImmobility(-20, 0)
		M.AdjustUnconscious(-20, 0)
	..()

/datum/reagent/medicine/epinephrine/overdose_process(mob/living/M)
	if(prob(33))
		M.adjustStaminaLoss(2.5*REM, 0)
		M.adjustToxLoss(1*REM, 0)
		M.losebreath++
		. = 1
	..()

/datum/reagent/medicine/strange_reagent
	name = "Strange Reagent"
	description = "A miracle drug capable of bringing the dead back to life. Only functions when applied by patch or spray, if the target has less than 100 brute and burn damage (independent of one another) and hasn't been husked. Causes slight damage to the living."
	reagent_state = LIQUID
	color = "#A0E85E"
	metabolization_rate = 1.25 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	taste_description = "magnets"
	pH = 0.5
	value = REAGENT_VALUE_RARE
	/// The amount of damage a single unit of this will heal
	var/healing_per_reagent_unit = 5
	/// The ratio of the excess reagent used to contribute to excess healing
	var/excess_healing_ratio = 0.8
	/// Do we instantly revive
	var/instant = FALSE
	/// The maximum amount of damage we can revive from, as a ratio of max health
	var/max_revive_damage_ratio = 2

/datum/reagent/medicine/strange_reagent/instant
	name = "Stranger Reagent"
	instant = TRUE
	chemical_flags = NONE

/datum/reagent/medicine/strange_reagent/New()
	. = ..()
	description = replacetext(description, "%MAXHEALTHRATIO%", "[max_revive_damage_ratio * 100]%")
	if(instant)
		description += " It appears to be pulsing with a warm pink light."

// FEED ME SEYMOUR
/datum/reagent/medicine/strange_reagent/on_hydroponics_apply(obj/machinery/hydroponics/mytray, mob/user)
	mytray.spawnplant()

/// Calculates the amount of reagent to at a bare minimum make the target not dead
/datum/reagent/medicine/strange_reagent/proc/calculate_amount_needed_to_revive(mob/living/benefactor)
	var/their_health = benefactor.getMaxHealth() - (benefactor.getBruteLoss() + benefactor.getFireLoss())
	if(their_health > 0)
		return 1

	return round(-their_health / healing_per_reagent_unit, DAMAGE_PRECISION)

/// Calculates the amount of reagent that will be needed to both revive and full heal the target. Looks at healing_per_reagent_unit and excess_healing_ratio
/datum/reagent/medicine/strange_reagent/proc/calculate_amount_needed_to_full_heal(mob/living/benefactor)
	var/their_health = benefactor.getBruteLoss() + benefactor.getFireLoss()
	var/max_health = benefactor.getMaxHealth()
	if(their_health >= max_health)
		return 1

	var/amount_needed_to_revive = calculate_amount_needed_to_revive(benefactor)
	var/expected_amount_to_full_heal = round(max_health / healing_per_reagent_unit, DAMAGE_PRECISION) / excess_healing_ratio
	return amount_needed_to_revive + expected_amount_to_full_heal

/datum/reagent/medicine/strange_reagent/reaction_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, affected_bodypart)
	if(exposed_mob.stat != DEAD || !(exposed_mob.mob_biotypes & MOB_ORGANIC))
		return ..()

	if(exposed_mob.suiciding) //they are never coming back
		exposed_mob.visible_message(span_warning("Тело [exposed_mob] не реагирует..."))
		return

	if(iscarbon(exposed_mob) && !(methods & INGEST)) //simplemobs can still be splashed
		return ..()

	if(HAS_TRAIT(exposed_mob, TRAIT_HUSK))
		exposed_mob.visible_message(span_warning("Тело [exposed_mob] выпустило кучу дыма..."))
		var/datum/effect_system/smoke_spread/bad/smoke = new
		smoke.set_up(8, exposed_mob.loc)
		smoke.start()
		return

	if((exposed_mob.getBruteLoss() + exposed_mob.getFireLoss()) > (exposed_mob.getMaxHealth() * max_revive_damage_ratio))
		if(IS_CHANGELING(exposed_mob) || iszombie(exposed_mob))
			return
		var/num = rand(0, 1)
		switch(num)
			if(0)
				addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living, do_jitter_animation), 1 SECONDS), 4 SECONDS)
				addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living, gib), FALSE, TRUE, TRUE), 2 SECONDS)
			if(1)
				addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living, do_jitter_animation), 1 SECONDS), 4 SECONDS)
				addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living/carbon/human, cluwneify)), 2 SECONDS)
		return

	var/needed_to_revive = calculate_amount_needed_to_revive(exposed_mob)
	if(reac_volume < needed_to_revive)
		exposed_mob.visible_message(span_warning("Тело [exposed_mob] немного конвульсирует, а затем снова замирает.."))
		exposed_mob.do_jitter_animation(10)
		return

	exposed_mob.visible_message(span_warning("Тело [exposed_mob] начинает дёргаться!"))
	exposed_mob.notify_ghost_cloning(source = exposed_mob)
	exposed_mob.do_jitter_animation(10)

	// we factor in healing needed when determing if we do anything
	var/healing = needed_to_revive * healing_per_reagent_unit
	// but excessive healing is penalized, to reward doctors who use the perfect amount
	reac_volume -= needed_to_revive
	healing += (reac_volume * healing_per_reagent_unit) * excess_healing_ratio

	// during unit tests, we want it to happen immediately
	if(instant)
		exposed_mob.do_strange_reagent_revival(healing)
	else
		// jitter immediately, after four seconds, and after eight seconds
		addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living, do_jitter_animation), 1 SECONDS), 4 SECONDS)
		addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living, do_strange_reagent_revival), healing), 7 SECONDS)
		addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living, do_jitter_animation), 1 SECONDS), 8 SECONDS)

	if(exposed_mob.revive())
		exposed_mob.grab_ghost()
		// BLUEMOON EDIT START - изменение памяти после смерти
		exposed_mob.mind?.forget_death(DEATH_FORGETFULNESS_REASON_STRANGE_REAGENT)
		exposed_mob.mind?.revival_handle_memory("strange reagent")
		// BLUEMOON EDIT END

	return ..()

/datum/reagent/medicine/strange_reagent/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()

	var/damage_at_random = rand(0, 250)/100 //0 to 2.5
	var/need_mob_update
	need_mob_update = affected_mob.adjustBruteLoss(damage_at_random * REM * seconds_per_tick, updating_health = FALSE)
	need_mob_update += affected_mob.adjustFireLoss(damage_at_random * REM * seconds_per_tick, updating_health = FALSE)

	. = 1

/datum/reagent/medicine/mannitol
	name = "Mannitol"
	description = "Efficiently restores brain damage."
	color = "#DCDCFF"
	taste_description = "sweetness"
	pH = 10.4
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)

/datum/reagent/medicine/mannitol/on_mob_life(mob/living/carbon/C)
	C.adjustOrganLoss(ORGAN_SLOT_BRAIN, -2*REM)
	if(prob(10))
		C.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)
	..()

/datum/reagent/medicine/neurine
	name = "Neurine"
	description = "Reacts with neural tissue, helping reform damaged connections. Can cure minor traumas."
	color = "#EEFF8F"
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)

/datum/reagent/medicine/neurine/reaction_mob(mob/living/M, method=TOUCH, reac_volume, affected_bodypart)
	if(!(method == INJECT))
		return
	var/obj/item/organ/brain/B = M.getorganslot(ORGAN_SLOT_BRAIN)
	if(!B || (!(B.organ_flags & ORGAN_FAILING)))
		return
	B.applyOrganDamage(-20)
	if(prob(80))
		B.gain_trauma_type(BRAIN_TRAUMA_MILD)
	else if(prob(50))
		B.gain_trauma_type(BRAIN_TRAUMA_SEVERE)
	else
		B.gain_trauma_type(BRAIN_TRAUMA_SPECIAL)

/datum/reagent/medicine/neurine/reaction_obj(obj/O, reac_volume)
	if(istype(O, /obj/item/dullahan_head))
		var/obj/item/dullahan_head/head = O
		if(head.B)
			head.B.applyOrganDamage(-20)
		if(head.owner)
			head.owner.cure_trauma_type(resilience = TRAUMA_RESILIENCE_SURGERY)

/datum/reagent/medicine/neurine/on_mob_life(mob/living/carbon/C)
	if(holder.has_reagent(/datum/reagent/consumable/ethanol/neurotoxin))
		holder.remove_reagent(/datum/reagent/consumable/ethanol/neurotoxin, 5)
	if(prob(15))
		C.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)
	..()

/datum/reagent/medicine/mutadone
	name = "Mutadone"
	description = "Removes jitteriness and restores genetic defects."
	color = "#5096C8"
	taste_description = "acid"
	pH = 2
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)

/datum/reagent/medicine/mutadone/on_mob_life(mob/living/carbon/M)
	M.jitteriness = 0
	if(M.has_dna())
		M.dna.remove_all_mutations(mutadone = TRUE)
	if(!QDELETED(M)) //We were a monkey, now a human
		..()

/datum/reagent/medicine/antihol
	name = "Antihol"
	description = "Purges alcoholic substance from the patient's body and eliminates its side effects."
	color = "#00B4C8"
	taste_description = "raw egg"
	pH = 4

/datum/reagent/medicine/antihol/on_mob_life(mob/living/carbon/M)
	M.dizziness = 0
	M.drowsyness = 0
	M.slurring = 0
	M.confused = 0
	M.reagents.remove_all_type(/datum/reagent/consumable/ethanol, 3*REM, 0, 1)
	M.adjustToxLoss(-0.2*REM, 0)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.drunkenness = max(H.drunkenness - 10, 0)
	..()
	. = 1

/datum/reagent/medicine/stimulants
	name = "Stimulants"
	description = "Increases stun resistance and movement speed in addition to restoring minor damage and weakness. Overdose causes weakness and toxin damage."
	color = "#78008C"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 60
	pH = 8.7
	can_synth = FALSE //BLUEMOON CHANGE ролькоприколы остаются у ролек
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	value = REAGENT_VALUE_GLORIOUS

/datum/reagent/medicine/stimulants/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/stimulants)
	ADD_TRAIT(L, TRAIT_TASED_RESISTANCE, type)

/datum/reagent/medicine/stimulants/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/stimulants)
	REMOVE_TRAIT(L, TRAIT_TASED_RESISTANCE, type)
	..()

/datum/reagent/medicine/stimulants/on_mob_life(mob/living/carbon/M)
	if(M.health < 50 && M.health > 0)
		M.adjustOxyLoss(-1 * REM, FALSE)
		M.adjustToxLoss(-1 * REM, FALSE)
		M.adjustBruteLoss(-1 * REM, FALSE)
		M.adjustFireLoss(-1 * REM, FALSE)
	M.AdjustAllImmobility(-80, FALSE)
	M.AdjustParalyzed(-40, FALSE)
	M.AdjustKnockdown(-40, FALSE)
	M.AdjustImmobilized(-40, FALSE)
	M.adjustStaminaLoss(-40*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/stimulants/overdose_process(mob/living/M)
	if(prob(33))
		M.adjustStaminaLoss(2.5*REM, FALSE)
		M.adjustToxLoss(1*REM, FALSE)
		M.losebreath++
		. = 1
	..()

/datum/reagent/medicine/insulin
	name = "Insulin"
	description = "Increases sugar depletion rates."
	reagent_state = LIQUID
	color = "#FFFFF0"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	pH = 6.7

/datum/reagent/medicine/insulin/on_mob_life(mob/living/carbon/M)
	if(M.AdjustSleeping(-20, FALSE))
		. = 1
	M.reagents.remove_reagent(/datum/reagent/consumable/sugar, 3)
	..()

//Trek Chems, used primarily by medibots. Only heals a specific damage type, but is very efficient.
/datum/reagent/medicine/bicaridine
	name = "Bicaridine"
	description = "Restores bruising. Overdose causes it instead."
	reagent_state = LIQUID
	color = "#fc2626"
	overdose_threshold = 30
	pH = 5

/datum/reagent/medicine/bicaridine/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-2*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/bicaridine/overdose_process(mob/living/M)
	M.adjustBruteLoss(4*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/dexalin
	name = "Dexalin"
	description = "Restores oxygen loss. Overdose causes it instead."
	reagent_state = LIQUID
	color = "#13d2f0"
	overdose_threshold = 30
	pH = 9.7

/datum/reagent/medicine/dexalin/on_mob_life(mob/living/carbon/M)
	M.adjustOxyLoss(-2*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/dexalin/overdose_process(mob/living/M)
	M.adjustOxyLoss(4*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/kelotane
	name = "Kelotane"
	description = "Restores fire damage. Overdose causes it instead."
	reagent_state = LIQUID
	color = "#ffc400"
	overdose_threshold = 30
	pH = 9

/datum/reagent/medicine/kelotane/on_mob_life(mob/living/carbon/M)
	M.adjustFireLoss(-2*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/kelotane/overdose_process(mob/living/M)
	M.adjustFireLoss(4*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/antitoxin
	name = "Anti-Toxin"
	description = "Heals toxin damage and removes toxins in the bloodstream. Overdose causes toxin damage."
	reagent_state = LIQUID
	color = "#6aff00"
	overdose_threshold = 30
	taste_description = "a roll of gauze"
	pH = 10

/datum/reagent/medicine/antitoxin/on_mob_life(mob/living/carbon/M)
	M.adjustToxLoss(-2*REM, FALSE)
	for(var/datum/reagent/toxin/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type,1)
	..()
	. = 1

/datum/reagent/medicine/antitoxin/overdose_process(mob/living/M)
	M.adjustToxLoss(4*REM, FALSE) // End result is 2 toxin loss taken, because it heals 2 and then removes 4.
	..()
	. = 1

// Antitoxin binds plants pretty well. So the tox goes significantly down
/datum/reagent/medicine/antitoxin/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	mytray.adjustToxic(-round(chems.get_reagent_amount(type) * 2))

/datum/reagent/medicine/inaprovaline
	name = "Inaprovaline"
	description = "Stabilizes the breathing of patients. Good for those in critical condition."
	reagent_state = LIQUID
	pH = 8.5
	color = "#5dc1f0"

/datum/reagent/medicine/inaprovaline/on_mob_life(mob/living/carbon/M)
	if(M.losebreath >= 5)
		M.losebreath -= 5
	..()

/datum/reagent/medicine/tricordrazine
	name = "Tricordrazine"
	description = "Has a high chance to heal all types of damage. Overdose instead causes it."
	reagent_state = LIQUID
	color = "#e650c0"
	overdose_threshold = 30
	taste_description = "grossness"

/datum/reagent/medicine/tricordrazine/on_mob_life(mob/living/carbon/M)
	if(prob(80))
		M.adjustBruteLoss(-1*REM, FALSE)
		M.adjustFireLoss(-1*REM, FALSE)
		M.adjustOxyLoss(-1*REM, FALSE)
		M.adjustToxLoss(-1*REM, FALSE)
		. = 1
	..()

/datum/reagent/medicine/tricordrazine/overdose_process(mob/living/M)
	M.adjustToxLoss(2*REM, FALSE)
	M.adjustOxyLoss(2*REM, FALSE)
	M.adjustBruteLoss(2*REM, FALSE)
	M.adjustFireLoss(2*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/regen_jelly
	name = "Regenerative Jelly"
	description = "Gradually regenerates all types of damage, without harming slime anatomy."
	reagent_state = LIQUID
	color = "#91D865"
	taste_description = "jelly"
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/regen_jelly/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-1.5*REM, FALSE)
	M.adjustFireLoss(-1.5*REM, FALSE)
	M.adjustOxyLoss(-1.5*REM, FALSE)
	M.adjustToxLoss(-1.5*REM, 0, TRUE) //heals TOXINLOVERs
	. = 1
	..()

/datum/reagent/medicine/syndicate_nanites //Used exclusively by Syndicate medical cyborgs
	name = "Restorative Nanites"
	description = "Miniature medical robots that swiftly restore bodily damage."
	reagent_state = SOLID
	color = "#555555"
	pH = 11
	chemical_flags = REAGENT_ALL_PROCESS
	value = REAGENT_VALUE_EXCEPTIONAL
	can_synth = FALSE //BLUEMOON CHANGE ролькоприколы остаются у ролек

/datum/reagent/medicine/syndicate_nanites/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-5*REM, FALSE) //A ton of healing - this is a 50 telecrystal investment.
	M.adjustFireLoss(-5*REM, FALSE)
	M.adjustOxyLoss(-15, FALSE)
	M.adjustToxLoss(-5*REM, FALSE)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, -15*REM)
	M.adjustCloneLoss(-3*REM, FALSE)
	M.adjustStaminaLoss(-25*REM,FALSE)
	if(M.blood_volume < (BLOOD_VOLUME_NORMAL*M.blood_ratio))
		M.adjust_integration_blood(40) // blood fall out man bad
	..()
	. = 1

/datum/reagent/medicine/lesser_syndicate_nanites // the one in the injector
	name = "Regenerative Nanites"
	description = "Miniature medical robots that restore damage and get operatives back in the fight."
	reagent_state = SOLID
	color = "#555555"
	pH = 11
	chemical_flags = REAGENT_ALL_PROCESS
	value = REAGENT_VALUE_VERY_RARE
	can_synth = FALSE //BLUEMOON CHANGE ролькоприколы остаются у ролек

/datum/reagent/medicine/lesser_syndicate_nanites/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-4*REM, FALSE)
	M.adjustFireLoss(-4*REM, FALSE)
	M.adjustOxyLoss(-10*REM, FALSE)
	M.adjustToxLoss(-4*REM, FALSE)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, -10*REM)
	M.adjustCloneLoss(-3*REM, FALSE)
	M.adjustStaminaLoss(-8*REM,FALSE)
	if(M.blood_volume < (BLOOD_VOLUME_NORMAL*M.blood_ratio))
		M.adjust_integration_blood(3)
	..()
	. = 1

/datum/reagent/medicine/neo_jelly
	name = "Neo Jelly"
	description = "Gradually regenerates all types of damage, without harming slime anatomy. Can overdose."
	reagent_state = LIQUID
	metabolization_rate = 1 * REAGENTS_METABOLISM
	color = "#91D865"
	overdose_threshold = 30
	taste_description = "jelly"
	pH = 11.8
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/medicine/neo_jelly/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-1.5*REM, FALSE)
	M.adjustFireLoss(-1.5*REM, FALSE)
	M.adjustOxyLoss(-1.5*REM, FALSE)
	M.adjustToxLoss(-1.5*REM, 0, TRUE) //heals TOXINLOVERs
	. = 1
	..()

/datum/reagent/medicine/neo_jelly/overdose_process(mob/living/M)
	M.adjustOxyLoss(2.6*REM, FALSE)
	M.adjustBruteLoss(3.5*REM, FALSE)
	M.adjustFireLoss(3.5*REM, FALSE)
	..()
	. = 1

/datum/reagent/medicine/earthsblood //Created by ambrosia gaia plants
	name = "Earthsblood"
	description = "Ichor from an extremely powerful plant. Great for restoring wounds, but it's a little heavy on the brain."
	color = rgb(255, 175, 0)
	overdose_threshold = 25
	pH = 11
	value = REAGENT_VALUE_COMMON //not any higher. Ambrosia is a milestone for hydroponics already.


//Earthsblood is still a wonderdrug. Just... don't expect to be able to mutate something that makes plants so healthy.
/datum/reagent/medicine/earthsblood/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	if(chems.has_reagent(src.type, 1))
		mytray.adjustHealth(round(chems.get_reagent_amount(src.type) * 1))
		mytray.adjustPests(-rand(1,3))
		mytray.adjustWeeds (-rand(1,3))
		if(myseed)
			myseed.adjust_instability(-round(chems.get_reagent_amount(src.type) * 1.3))
			myseed.adjust_potency(round(chems.get_reagent_amount(src.type) *1))
			myseed.adjust_yield(round(chems.get_reagent_amount(src.type) * 1))
			myseed.adjust_endurance(round(chems.get_reagent_amount(src.type) * 0.5))
			myseed.adjust_production(-round(chems.get_reagent_amount(src.type) * 0.5))

/datum/reagent/medicine/earthsblood/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-3 * REM, FALSE)
	M.adjustFireLoss(-3 * REM, FALSE)
	M.adjustOxyLoss(-15 * REM, FALSE)
	M.adjustToxLoss(-3 * REM, FALSE, TRUE) //Heals TOXINLOVERS
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2 * REM, 150) //This does, after all, come from ambrosia, and the most powerful ambrosia in existence, at that!
	M.adjustCloneLoss(-1 * REM, FALSE)
	M.adjustStaminaLoss(-1 * REM, FALSE)
	M.jitteriness = min(max(0, M.jitteriness + 3), 30)
	M.druggy = min(max(0, M.druggy + 10), 15) //See above
	..()
	. = 1

/datum/reagent/medicine/earthsblood/overdose_process(mob/living/M)
	M.hallucination = min(max(0, M.hallucination + 5), 60)
	M.adjustToxLoss(8 * REM, FALSE, TRUE) //Hurts TOXINLOVERS
	..()
	. = 1

/datum/reagent/medicine/haloperidol
	name = "Haloperidol"
	description = "Increases depletion rates for most stimulating/hallucinogenic drugs. Reduces druggy effects and jitteriness. Severe stamina regeneration penalty, causes drowsiness. Small chance of brain damage."
	reagent_state = LIQUID
	color = "#27870a"
	metabolization_rate = 0.4 * REAGENTS_METABOLISM
	pH = 4.3
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/medicine/haloperidol/on_mob_life(mob/living/carbon/M)
	for(var/datum/reagent/drug/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type,5)
	M.drowsyness += 2
	if(M.jitteriness >= 3)
		M.jitteriness -= 3
	if (M.hallucination >= 5)
		M.hallucination -= 5
	if(prob(20))
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1*REM, 50)
	M.adjustStaminaLoss(2.5*REM, 0)
	..()
	return TRUE

/datum/reagent/medicine/lavaland_extract
	name = "Lavaland Extract"
	description = "An extract of lavaland atmospheric and mineral elements. Heals the user in small doses, but is extremely toxic otherwise."
	color = "#a1a1a1"
	overdose_threshold = 3 //To prevent people stacking massive amounts of a very strong healing reagent
	can_synth = FALSE
	pH = 14
	value = REAGENT_VALUE_AMAZING

/datum/reagent/medicine/lavaland_extract/on_mob_life(mob/living/carbon/M)
	M.heal_bodypart_damage(5,5)
	..()
	return TRUE

/datum/reagent/medicine/lavaland_extract/overdose_process(mob/living/M)
	M.adjustBruteLoss(3*REM, 0)
	M.adjustFireLoss(3*REM, 0)
	M.adjustToxLoss(3*REM, 0)
	..()
	return TRUE

//used for changeling's adrenaline power
/datum/reagent/medicine/changelingadrenaline
	name = "Changeling Adrenaline"
	description = "Reduces the duration of unconciousness, knockdown and stuns. Restores stamina, but deals toxin damage when overdosed."
	color = "#C1151D"
	overdose_threshold = 30
	value = REAGENT_VALUE_VERY_RARE
	can_synth = FALSE //BLUEMOON CHANGE ролькоприколы остаются у ролек
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)

/datum/reagent/medicine/changelingadrenaline/on_mob_life(mob/living/carbon/metabolizer, delta_time, times_fired)
	..()
	metabolizer.AdjustAllImmobility(-20 * REM * delta_time)
	metabolizer.adjustStaminaLoss(-30 * REM * delta_time, 0)
	metabolizer.Jitter(10 * REM * delta_time)
	metabolizer.Dizzy(10 * REM * delta_time)
	return TRUE

/datum/reagent/medicine/changelingadrenaline/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	ADD_TRAIT(L, TRAIT_TASED_RESISTANCE, type)
	L.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/changelingadrenaline/on_mob_end_metabolize(mob/living/L)
	..()
	REMOVE_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	REMOVE_TRAIT(L, TRAIT_TASED_RESISTANCE, type)
	L.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	L.Dizzy(0)
	L.Jitter(0)

/datum/reagent/medicine/changelingadrenaline/overdose_process(mob/living/metabolizer, delta_time, times_fired)
	metabolizer.adjustToxLoss(1 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/changelinghaste
	name = "Changeling Haste"
	description = "Drastically increases movement speed."
	color = "#AE151D"
	metabolization_rate = 2.5 * REAGENTS_METABOLISM
	can_synth = FALSE //BLUEMOON CHANGE ролькоприколы остаются у ролек
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)

/datum/reagent/medicine/changelinghaste/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/changelinghaste)

/datum/reagent/medicine/changelinghaste/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/changelinghaste)
	..()

/datum/reagent/medicine/corazone
	// Heart attack code will not do damage if corazone is present
	// because it's SPACE MAGIC ASPIRIN
	name = "Corazone"
	description = "A medication used to treat pain, fever, and inflammation, along with heart attacks."
	color = "#F5F5F5"
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	self_consuming = TRUE
	pH = 12.5

/datum/reagent/medicine/corazone/on_mob_metabolize(mob/living/M)
	..()
	ADD_TRAIT(M, TRAIT_STABLEHEART, type)
	ADD_TRAIT(M, TRAIT_STABLELIVER, type)

/datum/reagent/medicine/corazone/on_mob_end_metabolize(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_STABLEHEART, type)
	REMOVE_TRAIT(M, TRAIT_STABLELIVER, type)
	..()

/datum/reagent/medicine/muscle_stimulant
	name = "Muscle Stimulant"
	description = "A potent chemical that allows someone under its influence to be at full physical ability even when under massive amounts of pain."
	value = REAGENT_VALUE_RARE
	can_synth = FALSE //BLUEMOON CHANGE смешной картофел только имеет право иметь такой реагент (hot potato)

/datum/reagent/medicine/muscle_stimulant/on_mob_metabolize(mob/living/M)
	. = ..()
	M.add_movespeed_mod_immunities(type, list(/datum/movespeed_modifier/damage_slowdown, /datum/movespeed_modifier/damage_slowdown_flying, /datum/movespeed_modifier/monkey_health_speedmod))

/datum/reagent/medicine/muscle_stimulant/on_mob_end_metabolize(mob/living/M)
	. = ..()
	M.remove_movespeed_mod_immunities(type, list(/datum/movespeed_modifier/damage_slowdown, /datum/movespeed_modifier/damage_slowdown_flying, /datum/movespeed_modifier/monkey_health_speedmod))

/datum/reagent/medicine/modafinil
	name = "Modafinil"
	description = "Long-lasting sleep suppressant that very slightly reduces stun and knockdown times. Overdosing has horrendous side effects and deals lethal oxygen damage, will knock you unconscious if not dealt with."
	reagent_state = LIQUID
	color = "#BEF7D8" // palish blue white
	metabolization_rate = 0.1 * REAGENTS_METABOLISM
	overdose_threshold = 20 // with the random effects this might be awesome or might kill you at less than 10u (extensively tested)
	taste_description = "salt" // it actually does taste salty
	value = REAGENT_VALUE_RARE
	var/overdose_progress = 0 // to track overdose progress
	pH = 7.89

/datum/reagent/medicine/modafinil/on_mob_metabolize(mob/living/M)
	ADD_TRAIT(M, TRAIT_SLEEPIMMUNE, type)
	..()

/datum/reagent/medicine/modafinil/on_mob_end_metabolize(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_SLEEPIMMUNE, type)
	..()

/datum/reagent/medicine/modafinil/on_mob_life(mob/living/carbon/M)
	if(!overdosed) // We do not want any effects on OD
		overdose_threshold = overdose_threshold + rand(-10,10)/10 // for extra fun
		M.AdjustAllImmobility(-5, 0)
		M.AdjustUnconscious(-5, 0)
		M.adjustStaminaLoss(-1*REM, 0)
		M.Jitter(1)
		metabolization_rate = 0.01 * REAGENTS_METABOLISM * rand(5,20) // randomizes metabolism between 0.02 and 0.08 per tick
		. = TRUE
	..()

/datum/reagent/medicine/modafinil/overdose_start(mob/living/M)
	to_chat(M, "<span class='userdanger'>You feel awfully out of breath and jittery!</span>")
	metabolization_rate = 0.025 * REAGENTS_METABOLISM // sets metabolism to 0.01 per tick on overdose

/datum/reagent/medicine/modafinil/overdose_process(mob/living/M)
	overdose_progress++
	switch(overdose_progress)
		if(1 to 40)
			M.jitteriness = min(M.jitteriness+1, 10)
			M.stuttering = min(M.stuttering+1, 10)
			M.Dizzy(5)
			if(prob(50))
				M.losebreath++
		if(41 to 80)
			M.adjustOxyLoss(0.1*REM, 0)
			M.adjustStaminaLoss(0.1*REM, 0)
			M.jitteriness = min(M.jitteriness+1, 20)
			M.stuttering = min(M.stuttering+1, 20)
			M.Dizzy(10)
			if(prob(50))
				M.losebreath++
			if(prob(20))
				to_chat(M, "You have a sudden fit!")
				M.emote("moan")
				M.DefaultCombatKnockdown(20, 1, 0) // you should be in a bad spot at this point unless epipen has been used
		if(81)
			to_chat(M, "You feel too exhausted to continue!") // at this point you will eventually die unless you get charcoal
			M.adjustOxyLoss(0.1*REM, 0)
			M.adjustStaminaLoss(0.1*REM, 0)
		if(82 to INFINITY)
			M.Sleeping(100, 0, TRUE)
			M.adjustOxyLoss(1.5*REM, 0)
			M.adjustStaminaLoss(1.5*REM, 0)
	..()
	return TRUE

/datum/reagent/medicine/psicodine
	name = "Psicodine"
	description = "Suppresses anxiety and other various forms of mental distress. Overdose causes hallucinations and minor toxin damage."
	reagent_state = LIQUID
	color = "#07E79E"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	overdose_threshold = 30
	pH = 9.12
	value = REAGENT_VALUE_COMMON

/datum/reagent/medicine/psicodine/on_mob_add(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_FEARLESS, type)

/datum/reagent/medicine/psicodine/on_mob_delete(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_FEARLESS, type)
	..()

/datum/reagent/medicine/psicodine/on_mob_life(mob/living/carbon/M)
	M.jitteriness = max(0, M.jitteriness-6)
	M.dizziness = max(0, M.dizziness-6)
	M.confused = max(0, M.confused-6)
	M.disgust = max(0, M.disgust-6)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	if(mood.sanity <= SANITY_NEUTRAL) // only take effect if in negative sanity and then...
		mood.setSanity(min(mood.sanity+5, SANITY_NEUTRAL)) // set minimum to prevent unwanted spiking over neutral
	..()
	. = 1

/datum/reagent/medicine/psicodine/overdose_process(mob/living/M)
	M.hallucination = min(max(0, M.hallucination + 5), 60)
	M.adjustToxLoss(1, 0)
	..()
	. = 1

/datum/reagent/medicine/silibinin
	name = "Silibinin"
	description = "A thistle derrived hepatoprotective flavolignan mixture that help reverse damage to the liver."
	reagent_state = SOLID
	color = "#FFFFD0"
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/medicine/silibinin/on_mob_life(mob/living/carbon/M)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, -2)//Add a chance to cure liver trauma once implemented.
	..()
	. = 1

/datum/reagent/medicine/polypyr  //This is intended to be an ingredient in advanced chems.
	name = "Polypyrylium Oligomers"
	description = "A purple mixture of short polyelectrolyte chains not easily synthesized in the laboratory. It is valued as an intermediate in the synthesis of the cutting edge pharmaceuticals."
	reagent_state = SOLID
	color = "#9423FF"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	overdose_threshold = 50
	taste_description = "numbing bitterness"
	value = REAGENT_VALUE_RARE

/datum/reagent/medicine/polypyr/on_mob_life(mob/living/carbon/M) //I wanted a collection of small positive effects, this is as hard to obtain as coniine after all.
	M.adjustOrganLoss(ORGAN_SLOT_LUNGS, -0.25)
	M.adjustBruteLoss(-0.35, 0)
	..()
	. = 1

/datum/reagent/medicine/polypyr/reaction_mob(mob/living/M, method=TOUCH, reac_volume, affected_bodypart)
	if(method == TOUCH || method == VAPOR)
		if(M && ishuman(M) && reac_volume >= 0.5)
			var/mob/living/carbon/human/H = M
			H.hair_color = "92f"
			H.facial_hair_color = "92f"
			H.update_hair()

/datum/reagent/medicine/polypyr/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_LUNGS, 0.5)
	..()
	. = 1

/datum/reagent/medicine/liquid_wisdom
	name = "liquid wisdom"
	description = "the physical representation of wisdom, in liquid form"
	taste_mult = 4
	can_synth = FALSE
	overdose_threshold = 30
	chemical_flags = REAGENT_ALL_PROCESS
	value = REAGENT_VALUE_UNCOMMON // while it's 'rare', it can be milked from the wisdom cow

/datum/reagent/medicine/liquid_wisdom/on_mob_life(mob/living/carbon/C) //slightly stronger mannitol, from the wisdom cow
	C.adjustOrganLoss(ORGAN_SLOT_BRAIN, -3*REM)
	if(prob(20))
		C.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)
	if(prob(3))
		to_chat(C, "[pick(GLOB.wisdoms)]") //give them a random wisdom
	..()

// helps bleeding wounds clot faster
/datum/reagent/medicine/coagulant
	name = "Sanguirite"
	description = "A proprietary coagulant used to help bleeding wounds clot faster."
	reagent_state = LIQUID
	color = "#bb2424"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
//	chemical_flags = REAGENT_ALL_PROCESS (BLUEMOON REMOVAL - роботы не должны получать эффекты реагента)
	overdose_threshold = 20
	/// How much base clotting we do per bleeding wound, multiplied by the below number for each bleeding wound
	var/clot_rate = 0.25
	/// If we have multiple bleeding wounds, we count the number of bleeding wounds, then multiply the clot rate by this^(n) before applying it to each cut, so more cuts = less clotting per cut (though still more total clotting)
	var/clot_coeff_per_wound = 0.9

/datum/reagent/medicine/coagulant/on_mob_life(mob/living/carbon/M)
	. = ..()
	if(!M.blood_volume || !M.all_wounds)
		return

	var/effective_clot_rate = clot_rate

	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		if(iter_wound.blood_flow)
			effective_clot_rate *= clot_coeff_per_wound

	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		iter_wound.blood_flow = max(0, iter_wound.blood_flow - effective_clot_rate)

/datum/reagent/medicine/coagulant/overdose_process(mob/living/M)
	. = ..()
	if(!M.blood_volume)
		return

	if(prob(15))
		M.losebreath += rand(2,4)
		M.adjustOxyLoss(rand(1,3))
		if(prob(30))
			to_chat(M, "<span class='danger'>You can feel your blood clotting up in your veins!</span>")
		else if(prob(10))
			to_chat(M, "<span class='userdanger'>You feel like your blood has stopped moving!</span>")
		if(prob(50))
			var/obj/item/organ/lungs/our_lungs = M.getorganslot(ORGAN_SLOT_LUNGS)
			our_lungs.applyOrganDamage(1)
		else
			var/obj/item/organ/heart/our_heart = M.getorganslot(ORGAN_SLOT_HEART)
			our_heart.applyOrganDamage(1)

// can be synthesized on station rather than bought. made by grinding a banana peel, heating it up, then mixing the banana peel powder with salglu
/datum/reagent/medicine/coagulant/weak
	name = "Synthi-Sanguirite"
	description = "A synthetic coagulant used to help bleeding wounds clot faster. Not quite as effective as name brand Sanguirite, especially on patients with lots of cuts."
	clot_coeff_per_wound = 0.8

//Sloowly heals system corruption in robotic organisms. Causes mild toxins damage in nonrobots.
// BLUEMOON EDITED - усилен эффект, добавлено оповещение о передозировке, увеличен порог передозировки
/datum/reagent/medicine/system_cleaner
	name = "System Cleaner"
	description = "A reagent with special properties causing it to slowly reduce corruption in robots. Mildly toxic for organics."
	reagent_state = LIQUID
	color = "#D7C9C6"
	metabolization_rate = 3 * REAGENTS_METABOLISM
	chemical_flags = REAGENT_ALL_PROCESS
	overdose_threshold = 50

/datum/reagent/medicine/system_cleaner/on_mob_life(mob/living/carbon/M)
	. = ..()
	if(HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM))
		M.adjustToxLoss(-0.8 * 2 * REM, toxins_type = TOX_SYSCORRUPT)
	else
		M.adjustToxLoss(0.5 * 2 * REM)
	. = 1

/datum/reagent/medicine/system_cleaner/overdose_start(mob/living/M)
	. = ..()
	if(istype(M, /mob/living/carbon/human) && isrobotic(M))
		var/mob/living/carbon/human/H = M
		to_chat(H, span_boldwarning("Ош$бка систе%ммы обраббббботкI реаг^нтов - отк*люччение модулR очист%ки..."))
		H.Dizzy(20)
		H.emote("buzz")

/datum/reagent/medicine/system_cleaner/overdose_process(mob/living/carbon/M)
	. = ..()
	if(HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM))
		if(current_cycle % 10 == 0)
			to_chat(M, span_warning("П&вреждение ддр%йверов оч$стки - обрат}тесь к сист#мному админист@ратору..."))
		M.adjustToxLoss(1.6 * 2 * REM, toxins_type = TOX_SYSCORRUPT) //inverts its positive effect on overdose, for organics it's just more toxic
	else
		M.adjustToxLoss(0.5 * 2 * REM)
	. = 1

/datum/reagent/medicine/limb_regrowth
	name = "Carcinisoprojection Jelly"
	description = "Also known as \"limb regrowth jelly\", this crabby looking xenobiological jelly will rapidly regrow any missing limbs someone has at the cost of some of their blood. Do not overdose."
	taste_description = "salty slime"
	color = "#EF5428" //like cooked crab!
	reagent_state = LIQUID
	overdose_threshold = 65 //it takes more than one bluespace syringe to overdose someone with this given how nasty the OD is.
	value = REAGENT_VALUE_RARE

/datum/reagent/medicine/limb_regrowth/reaction_mob(mob/living/carbon/C, method=TOUCH, reac_volume, affected_bodypart)
	. = ..()
	if(!.)
		return
	if(method == TOUCH) //as funny as it would be to have this hurled at someone, nah.
		return
	var/vol = reac_volume + C.reagents.get_reagent_amount(/datum/reagent/medicine/limb_regrowth)
	if(vol < 5) //need at least 5 units.
		return
	var/list/limbs_to_heal = C.get_missing_limbs(exclude_head = TRUE)
	if(limbs_to_heal.len < 1) //nothing happens if they already got all limbs.
		return
	if(HAS_TRAIT(C, TRAIT_ROBOTIC_ORGANISM)) //sorry synths, consider a visit to the roboticist. dunno how to justify regrowing robolimbs.
		return
	else if(ishuman(C) && !(HAS_BONE in C.dna?.species?.species_traits)) //boneless have little trouble with the limb chemical.
		C.visible_message("<span class='notice'>[C] suddenly regrows \his limbs!</span>",
		"<span class='notice'>You suddenly regrow your limbs, sensation and all!</span>")
	else //boneful beings get to scream.
		C.visible_message("<span class='warning'>[C]'s body lets off a grotesque squelching, bone crunching sound as \his limbs grow back rapidly!</span>",
			"<span class='danger'>Your body emits a grotesque squelching, bone crunching sound as your limbs grow back rapidly! \
				With the sensation of your regained limbs, also comes pain!</span>",
			"<span class='italics'>You hear a grotsque squelching noise and the sound of crunching bones.</span>")
		playsound(C, 'sound/magic/demon_consume.ogg', 50, 1)
		SEND_SIGNAL(C, COMSIG_ADD_MOOD_EVENT, "painful_limb_regrowth", /datum/mood_event/painful_limb_regrowth)
		C.emote("scream")
	C.regenerate_limbs(excluded_limbs = list(BODY_ZONE_HEAD)) //would be a little funky for dullahans if they suddenly sprouted a head.
	C.blood_volume = max(C.blood_volume - 30*limbs_to_heal.len,0)
	//lose blood for each limb that was regained.
	//10 units less expensive than slime limb regrowth, but doesn't check for low blood like the ability, so it could be dangerous.
	to_chat(C,"<span class='warning'>You feel like this ordeal of your limbs regrowing has made you a little paler... as well as made you feel a little thirsty.</span>")
	//hint at the blood loss. (paler is a common symptom depicted in-game of low blood, but dehydration is another symptom of low blood.)


/datum/reagent/medicine/limb_regrowth/overdose_start(mob/living/M)
	M.ForceContractDisease(new /datum/disease/crabcancer, FALSE, TRUE) //it is now, time for crab.
	..()
	. = 1
