/datum/species/mammal
	name = "Anthropomorph"
	id = SPECIES_MAMMAL
	default_color = "4B4B4B"
	species_traits = list(MUTCOLORS,EYECOLOR,LIPS,HAIR,FACEHAIR,HORNCOLOR,WINGCOLOR,HAS_FLESH,HAS_BONE)
	inherent_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_BEAST
	mutant_bodyparts = list("mcolor" = "FFFFFF","mcolor2" = "FFFFFF","mcolor3" = "FFFFFF", "mam_snouts" = "Husky", "mam_tail" = "Husky", "mam_ears" = "Husky", "deco_wings" = "None",
						 "mam_body_markings" = list(), "taur" = "None", "horns" = "None", "legs" = "Plantigrade", "meat_type" = "Mammalian")
	attack_verb = "claw"
	attack_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/mammal
	liked_food = MEAT | FRIED
	disliked_food = TOXIC

	tail_type = "mam_tail"
	wagging_type = "mam_waggingtail"
	ass_image = 'icons/ass/assfluffy.png'
	species_category = SPECIES_CATEGORY_FURRY

	allowed_limb_ids = list("mammal","aquatic","avian","sergal")

/datum/species/mammal/synthetic
	name = "Synthetic Anthropomorph"
	id = SPECIES_MAMMAL_SYNTHETIC

	species_traits = list(MUTCOLORS,NOTRANSSTING,EYECOLOR,LIPS,HAIR,FACEHAIR,ROBOTIC_LIMBS,HAS_FLESH,HAS_BONE,WINGCOLOR,HORNCOLOR)
	inherent_traits = list(TRAIT_EASYDISMEMBER,TRAIT_LIMBATTACHMENT,TRAIT_NO_PROCESS_FOOD, TRAIT_ROBOTIC_ORGANISM, TRAIT_RESISTLOWPRESSURE, TRAIT_NOBREATH, TRAIT_AUXILIARY_LUNGS, TRAIT_VIRUSIMMUNE, TRAIT_RESISTCOLD, TRAIT_NOTHIRST) // BLUEMOON ADD - добавлены TRAIT_VIRUSIMMUNE, TRAIT_RESISTCOLD, TRAIT_NOTHIRST
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID|MOB_BEAST
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
	mutanteyes = /obj/item/organ/eyes/ipc
	mutantears = /obj/item/organ/ears/ipc
	mutanttongue = /obj/item/organ/tongue/robot/ipc
	mutant_brain = /obj/item/organ/brain/ipc
	mutantappendix = null // BLUEMOON REMOVAL - у синтетиков нет аппендикса

	//special cybernetic organ for getting power from apcs
	mutant_organs = list(/obj/item/organ/cyberimp/arm/power_cord)


	attack_verb = "claw"
	attack_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'

	exotic_bloodtype = "HF" // BLUEMOON EDIT - было "S"
	exotic_blood_color = BLOOD_COLOR_OIL
	allowed_limb_ids = list("mammal","aquatic","avian","sergal")
	species_category = SPECIES_CATEGORY_ROBOT
	wings_icons = SPECIES_WINGS_ROBOT
