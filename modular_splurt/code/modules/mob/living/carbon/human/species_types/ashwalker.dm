/datum/species/lizard/ashwalker/eastern
	name = "Eastern Ash Walker"
	id = SPECIES_ASHWALKER_EAST
	burnmod = 0.9
	brutemod = 0.9

/datum/species/lizard/ashwalker/western
	name = "Western Ash Walker"
	id = SPECIES_ASHWALKER_WEST
	species_traits = list(MUTCOLORS,EYECOLOR,LIPS)
	inherent_traits = list()
	burnmod = 0.95
	brutemod = 0.95

/datum/species/lizard/ashwalker/western/on_species_gain(mob/living/carbon/human/C, datum/species/old_species)
	C.gender = FEMALE
	if(C.dna?.features)
		C.dna.features["body_model"] = FEMALE
	return ..()

/// Selectable in character prefs (generate_selectable_species); station jobs blocked via qualifies_for_rank.
/datum/species/lizard/ashwalker/eastern/check_roundstart_eligible()
	return TRUE

/datum/species/lizard/ashwalker/eastern/qualifies_for_rank(rank, list/features)
	return FALSE

/datum/species/lizard/ashwalker/western/check_roundstart_eligible()
	return TRUE

/datum/species/lizard/ashwalker/western/qualifies_for_rank(rank, list/features)
	return FALSE
