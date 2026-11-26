/datum/disease/anaphylaxis
	form = "Shock"
	name = "Anaphylaxis"
	desc = "Пациент переживает угрожающую жизни аллергическую реакцию и умрёт, если не лечить."
	max_stages = 3
	cure_text = "Эпинефрин"
	cures = list(/datum/reagent/medicine/epinephrine)
	cure_chance = 20
	agent = "Аллергия"
	viable_mobtypes = list(/mob/living/carbon/human)
	disease_flags = CURABLE
	severity = DISEASE_SEVERITY_DANGEROUS
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	spread_text = "Нет"
	visibility_flags = HIDDEN_PANDEMIC
	bypasses_immunity = TRUE
	stage_prob = 5

/datum/disease/anaphylaxis/stage_act()
	. = ..()
	if(!.)
		return

	if(HAS_TRAIT(affected_mob, TRAIT_TOXINLOVER))
		cure()
		return

	affected_mob.adjust_bodytemperature(-10 * stage, BODYTEMP_COLD_DAMAGE_LIMIT - 70)

	switch(stage)
		if(1)
			if(affected_mob.get_num_arms() >= 1 && prob(5))
				to_chat(affected_mob, span_warning("Вы чувствуете, как [affected_mob.get_num_arms() == 1 ? "ваша рука начинает дрожать" : "ваши руки начинают дрожать"]."))
				affected_mob.Jitter(40)
			if(affected_mob.get_num_supporting_limbs() >= 1 && prob(5))
				if(HAS_TRAIT(affected_mob, TRAIT_NAGA_ANATOMY))
					to_chat(affected_mob, span_warning("Ваш хвост начинает дрожать."))
				else
					to_chat(affected_mob, span_warning(affected_mob.get_num_legs() == 1 ? "Ваша нога начинает дрожать." : "Ваши ноги начинают дрожать."))
				affected_mob.Jitter(40)
			if(prob(2))
				affected_mob.Dizzy(50)
			if(prob(1))
				to_chat(affected_mob, span_danger("У вас чешется горло."))

		if(2)
			affected_mob.adjustToxLoss(0.33)

			if(affected_mob.get_num_arms() >= 1 && prob(5))
				to_chat(affected_mob, span_warning("Вы чувствуете, как [affected_mob.get_num_arms() == 1 ? "ваша рука сильно дрожит" : "ваши руки сильно дрожат"]."))
				affected_mob.Jitter(80)
				if(prob(20))
					affected_mob.drop_all_held_items()
			if(affected_mob.get_num_supporting_limbs() >= 1 && prob(5))
				if(HAS_TRAIT(affected_mob, TRAIT_NAGA_ANATOMY))
					to_chat(affected_mob, span_warning("Ваш хвост сильно дрожит."))
				else
					to_chat(affected_mob, span_warning(affected_mob.get_num_legs() == 1 ? "Ваша нога сильно дрожит." : "Ваши ноги сильно дрожат."))
				affected_mob.Jitter(80)
				if(prob(40) && affected_mob.getStaminaLoss() < 75)
					affected_mob.adjustStaminaLoss(15)
			if(affected_mob.getorganslot(ORGAN_SLOT_EYES) && prob(4))
				affected_mob.eye_blurry = max(affected_mob.eye_blurry, 40)
				to_chat(affected_mob, span_warning("Становится труднее видеть."))
			if(!HAS_TRAIT(affected_mob, TRAIT_NOBREATH) && prob(4))
				affected_mob.adjustOxyLoss(2)
				affected_mob.losebreath += 2
				to_chat(affected_mob, span_warning("Становится труднее дышать."))
			if(prob(2))
				affected_mob.Dizzy(50)
			if(prob(2))
				affected_mob.vomit(10, FALSE, TRUE, 0, TRUE, harm = TRUE)
				affected_mob.Stun(20)
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				to_chat(affected_mob, span_danger("У вас болит горло."))

		if(3)
			affected_mob.adjustToxLoss(3)
			affected_mob.adjustOxyLoss(1)
			affected_mob.Unconscious(30)
