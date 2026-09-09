/obj/item/clothing/suit/space/space_ninja/proc/get_status_readout(mob/living/carbon/human/ninja)
	RETURN_TYPE(/list)
	. = list()
	if(!istype(ninja))
		return
	. += ""
	. += "SpiderOS: [s_initialized ? "Active" : "Offline"]"
	if(cell)
		. += "Energy: [DisplayEnergy(cell.charge)]"
	if(!s_initialized)
		return
	. += "Fingerprints: [md5(ninja.dna.uni_identity)]"
	. += "DNA: [ninja.dna.unique_enzymes]"
	. += "Health: [ninja.stat > 1 ? "Dead" : "[ninja.health]%"]"
	. += "Nutrition: [ninja.nutrition]"
	. += "Oxygen Loss: [ninja.getOxyLoss()]"
	. += "Toxins: [ninja.getToxLoss()]"
	. += "Burns: [ninja.getFireLoss()]"
	. += "Brute: [ninja.getBruteLoss()]"
	. += "Body Temperature: [round(ninja.bodytemperature - T0C, 0.1)] C"
	if(length(ninja.diseases))
		. += "Viruses:"
		for(var/datum/disease/ninja_disease in ninja.diseases)
			. += "* [ninja_disease.name] ([ninja_disease.stage]/[ninja_disease.max_stages])"
	if(ninja.reagents.reagent_list.len)
		. += "Reagents:"
		for(var/datum/reagent/ninja_reagent in ninja.reagents.reagent_list)
			. += "- [ninja_reagent.volume]u [ninja_reagent.name][ninja_reagent.overdosed ? " (OD)" : ""]"
	else
		. += "Reagents: none"
	if(ninja.reagents.addiction_list.len)
		. += "Addictions:"
		for(var/datum/reagent/ninja_reagent in ninja.reagents.addiction_list)
			. += "- [ninja_reagent.name] stage [ninja_reagent.addiction_stage]/5"
	else
		. += "Addictions: none"
	. += "Adrenaline Boost: [a_boost ? "Ready" : "Empty"]"
