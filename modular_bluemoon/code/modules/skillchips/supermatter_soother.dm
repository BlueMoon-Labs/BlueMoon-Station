/obj/machinery/power/supermatter_crystal/proc/bluemoon_hallucination_gain(mob/living/carbon/human/l, distance_factor)
	var/hallucination_gain = power * hallucination_power * distance_factor
	if(HAS_TRAIT(l, TRAIT_SUPERMATTER_SOOTHER))
		hallucination_gain *= 0.25
	return hallucination_gain