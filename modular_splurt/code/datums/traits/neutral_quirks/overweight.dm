/datum/quirk/overweight
	name = "Лишний Вес"
	desc = "Вы обожаете еду и появляетесь на смене с лишним весом."
	value = 0
	flavor_quirk = TRUE
	gain_text = span_notice("Вы чувствуете себя толстым!")
	//no lose_text cause why would there be?

/datum/quirk/overweight/on_spawn()
	var/mob/living/M = quirk_holder
	M.set_nutrition(rand(NUTRITION_LEVEL_FAT + NUTRITION_LEVEL_START_MIN, NUTRITION_LEVEL_FAT + NUTRITION_LEVEL_START_MAX))
	M.overeatduration = 100
	ADD_TRAIT(M, TRAIT_FAT, OBESITY)
