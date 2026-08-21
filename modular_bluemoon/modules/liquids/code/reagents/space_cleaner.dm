/datum/reagent/space_cleaner/reaction_turf(turf/T, reac_volume)
	. = ..()
	if(reac_volume >= 1 && istype(T) && T.liquids && !T.liquids.immutable)
		T.liquids.liquid_simple_delete_flat(reac_volume * 0.5)
