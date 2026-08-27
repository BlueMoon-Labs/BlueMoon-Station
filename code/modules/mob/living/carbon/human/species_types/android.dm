/datum/species/android
	name = "Android"
	id = SPECIES_ANDROID
	say_mod = "states"
	species_traits = list(NOBLOOD,NOGENITALS,NOAROUSAL,ROBOTIC_LIMBS)
	inherent_traits = list(TRAIT_RESISTHEAT,TRAIT_NOBREATH,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_RADIMMUNE,TRAIT_NOFIRE,TRAIT_PIERCEIMMUNE,TRAIT_NOHUNGER,TRAIT_NOTHIRST,TRAIT_LIMBATTACHMENT, TRAIT_ROBOTIC_ORGANISM, TRAIT_VIRUSIMMUNE) // BLUEMOON CHANGES - убрана защита от холода, добавлена защита от вирусов
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	meat = null
	gib_types = /obj/effect/gibspawner/robot
	damage_overlay_type = "synth"
	mutanttongue = /obj/item/organ/tongue/robot
	species_language_holder = /datum/language_holder/synthetic
	limbs_id = SPECIES_SYNTH
	species_category = SPECIES_CATEGORY_ROBOT
	wings_icons = SPECIES_WINGS_ROBOT

/datum/species/android/on_species_gain(mob/living/carbon/C, datum/species/old_species, pref_load)
	var/datum/component/neural_interface/interface = C.LoadComponent(/datum/component/neural_interface)
	interface?.AddSource("SPECIES")
	. = ..()

/datum/species/android/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	var/datum/component/neural_interface/interface = C.LoadComponent(/datum/component/neural_interface)
	interface?.RemoveSource("SPECIES")
	. = ..()
