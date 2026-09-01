/datum/reagent/water
	hydration = 5

/datum/reagent/water/on_mob_life(mob/living/carbon/M)
	M.adjust_thirst(hydration)
	. = ..()

/datum/reagent/dragon_blood
	name = "Dragon blood"
	description = "Dragon blood, who woulda thought!"
	color = "#811b1e" // RGB (129, 27, 30)
	can_synth = FALSE
	taste_description = "ash"

/datum/reagent/dragon_blood/reaction_mob(mob/living/L, method=TOUCH, reac_volume, show_message = 1, touch_protection = 0, affected_bodypart)
	if(method==PATCH || method==INGEST || method==INJECT || (method == VAPOR && prob(min(reac_volume,100)*(1 - touch_protection))))
		L.ForceContractDisease(new /datum/disease/transformation/dragon(), FALSE, TRUE)
