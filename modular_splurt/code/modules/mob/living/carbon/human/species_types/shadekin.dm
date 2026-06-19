/datum/species/mammal/shadekin
	name = "Shadekin"
	id = SPECIES_SHADEKIN
	say_mod = "mars"
	eye_type = "shadekin"
	mutant_bodyparts = list("mcolor" = "FFFFFF", "mcolor2" = "FFFFFF", "mcolor3" = "FFFFFF", "mam_tail" = "Shadekin", "mam_ears" = "Shadekin", "deco_wings" = "None",
						"taur" = "None", "horns" = "None", "legs" = "Plantigrade", "meat_type" = "Mammalian") // BLUEMOON CHANES - убран хвост, добавленны ноги
	allowed_limb_ids = list("mammal","aquatic","avian","shadekin")
	override_bp_icon = DEFAULT_BODYPART_ICON_ORGANIC
	eye_type = "shadekin"

/datum/species/mammal/shadekin/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))

/datum/species/mammal/shadekin/on_species_loss(mob/living/carbon/human/C)
	. = ..()
	UnregisterSignal(C, COMSIG_MOB_SAY)

/datum/species/mammal/shadekin/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER
	speech_args[SPEECH_SPANS] |= SPAN_SHADEKINVOICE
