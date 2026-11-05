// Общий вывод описаний особенностей в осмотре.
/mob/common_trait_examine(anonymous = FALSE, mob/examiner = usr)
	. = ..()
	// Местоимения учитывают скрытый пол цели.
	var/t_He = anonymous ? "он" : ru_who(FALSE)
	var/t_his = anonymous ? "его" : ru_ego()

	// BLUEMOON ADDITION AHEAD
	switch(src.mob_weight)
		if(MOB_WEIGHT_HEAVY_SUPER)
			. += span_warning("Выглядит так, будто весит как машина.\n")
		if(MOB_WEIGHT_HEAVY)
			. += span_warning("Выглядит грузно. Тащить будет сложно.\n")
		if(MOB_WEIGHT_LIGHT)
			. += span_info("C виду весит весьма немного.\n")
	// BLUEMOON ADDITION END

	// BLUEMOON ADD START
	if(HAS_TRAIT_FROM(src, TRAIT_MUTE, ORGAN_TRAIT))
		. += span_warning("[capitalize(t_his)] рот варварски зашит! Выглядит жутко...\n")
	// BLUEMOON ADD END

	if(HAS_TRAIT(src, TRAIT_HYPNOTIC_GAZE))
		. += "[capitalize(t_his)] глаза необычайно сверкают...\n"
	if(HAS_TRAIT(src, TRAIT_JIGGLY_ASS))
		. += span_lewd("[capitalize(t_his)] заднице не помешает крепкий шлепок.\n")

	if(isliving(src))
		var/mob/living/target = src
		if(isliving(examiner))
			var/mob/living/viewer = examiner
			if((locate(/datum/quirk/sensitive_to_pheramones) in target.roundstart_quirks) && viewer.has_quirk(/datum/quirk/ur_pheromones))
				. += span_lewd("Вы чувствуете сладкий непонятный запах от [anonymous ? "него" : ru_nego()], ваш разум заполняет желание секса.\n")
			if(ishuman(viewer) && viewer != src)
				if((locate(/datum/quirk/dominant_aura) in target.roundstart_quirks) && viewer.has_quirk(/datum/quirk/well_trained))
					. += span_lewd("Вы испытываете сильный стыд от взгляда на [anonymous ? "него" : ru_na()] и отводите свой взгляд!\n")
				if((locate(/datum/quirk/ur_pheromones) in target.roundstart_quirks) && viewer.has_quirk(/datum/quirk/sensitive_to_pheramones))
					. += span_lewd("Вы испытываете сильное возбуждение при взгляде на [anonymous ? "него" : ru_na()] и краснеете!\n")

		// Тот же трейт выдаёт кровососущий метаболизм, у которого своё описание.
		if(HAS_TRAIT(src, TRAIT_BLOODFLEDGE) && (locate(/datum/quirk/bloodfledge) in target.roundstart_quirks) && ishuman(examiner) && !HAS_TRAIT(examiner, TRAIT_DUMB))
			var/fellow_bloodfledge = isbloodfledge(examiner)
			var/hunger_text
			switch(target.nutrition)
				if(NUTRITION_LEVEL_STARVING to NUTRITION_LEVEL_HUNGRY)
					hunger_text = fellow_bloodfledge ? "[capitalize(t_He)] испытывает голод по крови!" : "[capitalize(t_He)], похоже, чем-то встревожен[anonymous ? "" : ru_a()]."
				if(0 to NUTRITION_LEVEL_STARVING)
					hunger_text = fellow_bloodfledge ? "[capitalize(t_He)] отчаянно нуждается в крови!" : "[capitalize(t_He)] излучает ауру неистового голода!"
			if(length(hunger_text))
				if(fellow_bloodfledge)
					. += span_info("[capitalize(t_his)] голод позволяет вам легко распознать собрата — начинающего кровососа!\n")
				. += span_warning("[hunger_text]\n")

		if(HAS_TRAIT(src, TRAIT_NUDIST))
			var/datum/quirk/nudist/nudist = locate(/datum/quirk/nudist) in target.roundstart_quirks
			if(nudist)
				if(nudist.is_outfit_comfortable())
					. += "[capitalize(t_He)] в радостном состоянии из-за отсутствия на себе одежды.\n"
				else
					. += span_warning("[capitalize(t_He)] в раздражении из-за ношения на себе одежды.\n")

		if(HAS_TRAIT(src, TRAIT_BLUEMOON_SHOWER_NEED))
			var/datum/quirk/bluemoon_shower_need/shower = locate(/datum/quirk/bluemoon_shower_need) in target.roundstart_quirks
			if(shower?.is_visibly_dirty())
				var/cannot_smell = examiner && HAS_TRAIT(examiner, TRAIT_ANOSMIA)
				if(iscarbon(examiner))
					var/mob/living/carbon/viewer = examiner
					cannot_smell = cannot_smell || viewer.internal
				if(cannot_smell)
					. += span_notice("[capitalize(t_He)] давно не мы[anonymous ? "лся" : ru_sya()].\n")
				else
					. += span_redtext("[capitalize(t_He)] плохо пахнет.\n")

		if(ishuman(examiner) && examiner != src && HAS_TRAIT(examiner, TRAIT_ESTROUS_DETECT))
			var/datum/quirk/estrous_active/estrous = locate(/datum/quirk/estrous_active) in target.roundstart_quirks
			if(estrous)
				var/heat_type = anonymous && HAS_TRAIT(src, TRAIT_PREGNANT) ? "беремен" : estrous.heat_type
				. += span_love("<b>[capitalize(t_He)]</b> [heat_type].\n")

	if(ishuman(src))
		var/mob/living/carbon/human/target = src
		if(HAS_TRAIT(src, TRAIT_SHY))
			var/datum/quirk/quirk_shy/shy = locate(/datum/quirk/quirk_shy) in target.roundstart_quirks
			if(shy?.can_react_to_examine(examiner))
				if(target.is_chest_exposed() && target.is_groin_exposed())
					if(target.restrained())
						. += span_lewd("[capitalize(t_He)] заливается красными красками и трясётся!\n")
					else
						. += span_lewd("[capitalize(t_He)] заливается красными красками и пытается прикрыться руками!\n")
				else
					. += span_lewd("[capitalize(t_He)], заметив ваш взгляд, сильно краснеет и смущённо отворачивается!\n")
		if(target.has_peekable_skirt())
			. += span_purple("[capitalize(t_He)] одет[anonymous ? "" : ru_a()] в юбку! Наверное, под неё можно <b>подсмотреть</b>...\n")

	// Остальные особенности распознают эмпаты, дружелюбные персонажи и сама цель.
	if(!examiner || !(HAS_TRAIT(examiner, TRAIT_EMPATH) || HAS_TRAIT(examiner, TRAIT_FRIENDLY) || src == examiner))
		return

	// Check for Distant (no touch head!)
	if(HAS_TRAIT(src, TRAIT_DISTANT))
		. += span_warning("Вы понимаете, что [t_his] может беспокоить физическая близость и вам лучше соблюдать дистанцию.\n")
	// Check for Heatpat Slut (pls touch head!)
	if(HAS_TRAIT(src, TRAIT_HEADPAT_SLUT))
		. += span_info("Вы понимаете, что [t_He] ценит физическую привязанность больше, чем обычно.")

/mob/can_read(obj/O)
	// Check for D4C craving
	if(HAS_TRAIT(src, TRAIT_DUMB_CUM_CRAVE))
		// Warn user, then return
		to_chat(src, span_love("Вы пытаетесь прочитать [O], но вам приходит на ум только теплое семя.!"))
		return

	// Return normally
	. = ..()
