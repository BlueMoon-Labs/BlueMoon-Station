/datum/species/spectrebot
	name = "BDR-01 Spectre"
	id = SPECIES_SPECBOT
	override_bp_icon = 'modular_splurt/icons/mob/spectre_bot_parts_grayscale.dmi'
	say_mod = "beeps"
	default_color = "00FF00"
	blacklisted = 0
	sexes = 0
	inherent_traits = list(TRAIT_EASYDISMEMBER,TRAIT_LIMBATTACHMENT,TRAIT_NO_PROCESS_FOOD, TRAIT_ROBOTIC_ORGANISM, TRAIT_RESISTLOWPRESSURE, TRAIT_NOBREATH, TRAIT_AUXILIARY_LUNGS, TRAIT_VIRUSIMMUNE, TRAIT_RESISTCOLD, TRAIT_NOTHIRST) // BLUEMOON ADD - добавлены TRAIT_VIRUSIMMUNE, TRAIT_RESISTCOLD, TRAIT_NOTHIRST
	species_traits = list(MUTCOLORS,EYECOLOR,NOTRANSSTING,HAS_FLESH,HAS_BONE,HAIR,ROBOTIC_LIMBS)
	hair_alpha = 210
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	mutant_bodyparts = list( "deco_wings" = "None")
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/ipc
	gib_types = list(/obj/effect/gibspawner/ipc, /obj/effect/gibspawner/ipc/bodypartless)

// BLUEMOON ADD START
	punchdamagelow = 5 // больше среднего урона с руки, чем у людей
	minimal_damage_threshold = 5 // слабый удар кулаком не наносит повреждений - по сути, баллон и более половины ударов кулаком всё ещё сильнее
// BLUEMOON ADD END

	coldmod = 0.5
	heatmod = 1.2
	cold_offset = SYNTH_COLD_OFFSET	//Can handle pretty cold environments, but it's still a slightly bad idea if you enter a room thats full of near-absolute-zero gas
	blacklisted_quirks = list(/datum/quirk/coldblooded, /datum/quirk/bloodfledge) // BLUEMOON ADD - добавлен квирк кровопийцы в исключение, т.к. кровь мешает питанию через энергию
	balance_point_values = TRUE

	//Just robo looking parts.
	mutant_heart = /obj/item/organ/heart/ipc
	mutantlungs = /obj/item/organ/lungs/ipc
	mutantliver = /obj/item/organ/liver/ipc
	mutantstomach = /obj/item/organ/stomach/ipc
	mutanteyes = /obj/item/organ/eyes/spectre
	mutantears = /obj/item/organ/ears/ipc
	mutanttongue = /obj/item/organ/tongue/robot/ipc
	mutant_brain = /obj/item/organ/brain/ipc
	mutantappendix = null // BLUEMOON REMOVAL - у синтетиков нет аппендикса

	//special cybernetic organ for getting power from apcs
	mutant_organs = list(/obj/item/organ/cyberimp/arm/power_cord)

	exotic_bloodtype = "HF" // BLUEMOON EDIT - было "S"
	exotic_blood_color = BLOOD_COLOR_OIL
	species_category = SPECIES_CATEGORY_ROBOT
	wings_icons = SPECIES_WINGS_ROBOT

	languagewhitelist = list("Encoded Audio Language")

	eye_type = "spectre"

/datum/species/spectrebot/on_species_gain(mob/living/carbon/C, datum/species/old_species, pref_load)
	var/datum/component/neural_interface/interface = C.LoadComponent(/datum/component/neural_interface)
	interface?.AddSource("SPECIES")
	. = ..()

/datum/species/spectrebot/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	var/datum/component/neural_interface/interface = C.LoadComponent(/datum/component/neural_interface)
	interface?.RemoveSource("SPECIES")
	. = ..()
