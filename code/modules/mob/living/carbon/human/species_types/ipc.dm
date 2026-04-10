/datum/species/ipc
	name = "I.P.C."
	id = SPECIES_IPC
	say_mod = "beeps"
	default_color = "00FF00"
	blacklisted = 0
	sexes = 0
	inherent_traits = list(TRAIT_EASYDISMEMBER,TRAIT_LIMBATTACHMENT,TRAIT_NO_PROCESS_FOOD, TRAIT_ROBOTIC_ORGANISM, TRAIT_RESISTLOWPRESSURE, TRAIT_NOBREATH, TRAIT_AUXILIARY_LUNGS, TRAIT_VIRUSIMMUNE, TRAIT_RESISTCOLD, TRAIT_NOTHIRST) // BLUEMOON ADD - добавлены TRAIT_VIRUSIMMUNE, TRAIT_RESISTCOLD, TRAIT_NOTHIRST
	species_traits = list(MUTCOLORS,NOEYES,NOTRANSSTING,HAS_FLESH,HAS_BONE,HAIR,ROBOTIC_LIMBS)
	hair_alpha = 255
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	mutant_bodyparts = list("ipc_screen" = "Blank", "deco_wings" = "None", "ipc_antenna" = "None", "mam_tail" = "None", "mam_ears" = "None", "horns" = "None")
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

	exotic_bloodtype = "HF" // BLUEMOON EDIT - было "S"
	exotic_blood_color = BLOOD_COLOR_OIL
	species_category = SPECIES_CATEGORY_ROBOT
	wings_icons = SPECIES_WINGS_ROBOT

	family_heirlooms = list(
		// Gives a broken powercell for flavor text!
		/obj/item/stock_parts/cell/family
	)

	var/datum/action/innate/monitor_change/screen
	var/datum/action/innate/ipc_designation/designation
	languagewhitelist = list("Encoded Audio Language") //Skyrat change - species language whitelist

/datum/species/ipc/on_species_gain(mob/living/carbon/human/C)
	if(isipcperson(C))
		if(!screen)
			screen = new
		screen.Grant(C)
		if(!designation)
			designation = new
		designation.Grant(C)
	..()

/datum/species/ipc/on_species_loss(mob/living/carbon/human/C)
	if(screen)
		screen.Remove(C)
	if(designation)
		designation.Remove(C)
	..()

/mob/living/carbon/human
	var/ipc_name_pending = FALSE

/datum/action/innate/monitor_change
	name = "Screen Change"
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "drone_vision"

/datum/action/innate/monitor_change/Activate()
	var/mob/living/carbon/human/H = owner
	var/new_ipc_screen = input(usr, "Choose your character's screen:", "Monitor Display") as null|anything in GLOB.ipc_screens_list
	if(!new_ipc_screen)
		return
	H.dna.features["ipc_screen"] = new_ipc_screen
	H.update_body()

/datum/action/innate/ipc_designation
	name = "Set Designation"
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "drone_vision"

/datum/action/innate/ipc_designation/Activate()
	var/mob/living/carbon/human/H = owner
	H.ipc_prompt_designation()

/mob/living/carbon/human/proc/ipc_prompt_designation(force = FALSE)
	if(!isipcperson(src))
		return FALSE
	if(!ipc_name_pending && !force)
		to_chat(src, "<span class='notice'>Your designation is already set.</span>")
		return FALSE

	var/default_name = ipc_name_pending ? "" : real_name
	var/new_name = reject_bad_name(stripped_input(src, "Choose your synthetic designation.", "Synthetic Designation", default_name, MAX_NAME_LEN), TRUE)
	if(!new_name)
		return FALSE

	fully_replace_character_name(real_name, new_name)
	if(dna)
		dna.real_name = new_name
	ipc_name_pending = FALSE
	to_chat(src, "<span class='notice'>Designation set to [new_name].</span>")
	return TRUE
