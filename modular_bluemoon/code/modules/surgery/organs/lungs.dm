//BIOAEGIS MODULES.
//LUNGS

//TIER 1 LUNGS//
/obj/item/organ/lungs/tier1
	name = "improved liver"
	desc = "A somewhat decent replica of baseline lungs. Tougher than the baseline liver."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weaklungs"
	maxHealth = 3.5 * STANDARD_ORGAN_THRESHOLD //Standard modifier is x3, but this is bs amount of health for an organ?
	safe_breath_min = 13
	safe_breath_max = 100
	smell_sensitivity = 1.5

/obj/item/organ/lungs/tier1/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Что-то неприятно упёрлось внутри живота...</span>\n")

//TIER 2 LUNGS//
/obj/item/organ/lungs/tier2
	name = "changed lungs"
	icon_state = "weaklungs"
	desc = "An improved version of baseline lungs. Better than the baseline counterpart."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weaklungs"
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	smell_sensitivity = 1.7
	gas_max = list(
		GAS_PLASMA = 30,
		GAS_CO2 = 30,
		GAS_METHYL_BROMIDE = 10
	)

/obj/item/organ/lungs/tier2/on_life()
	owner.adjustToxLoss(-0.25, TRUE) //Doesn't kill slimes. Yes.
	owner.adjustFireLoss(-0.25, FALSE)

/obj/item/organ/lungs/tier2/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Вы ощущаете, словно ваша кровь стала чище.</span>\n")

///TIER 3 LUNGS//
/obj/item/organ/lungs/tier3
	name = "exalted lungs"
	icon_state = "exaltedlungs"
	desc = "You will s e n s e the air - this version of lungs is stronger, better, capable to filter and withstand even more than a cybernetic counterpart!"
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "exaltedlungs"
	safe_breath_min = 3
	safe_breath_max = 250
	maxHealth = 5.5 * STANDARD_ORGAN_THRESHOLD
	healing_factor = 3.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.5 * STANDARD_ORGAN_DECAY
	gas_max = list(
		GAS_PLASMA = 50,
		GAS_CO2 = 50,
		GAS_METHYL_BROMIDE = 50,
		GAS_METHANE = 50,
		GAS_MIASMA = 50
	)
	SA_para_min = 30
	SA_sleep_min = 50
	BZ_brain_damage_min = 30
	smell_sensitivity = 2

	cold_level_1_threshold = 200
	cold_level_2_threshold = 140
	cold_level_3_threshold = 100

/obj/item/organ/lungs/tier3/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Вы можете ощутить малейший запах в комнате...</span>\n") //This is a *very precise* superior version of liver - you wouldn't feel anything.
	SEND_SIGNAL(organ_mob, COMSIG_ADD_MOOD_EVENT, "super lungs", /datum/mood_event/superlungs)

/datum/mood_event/superlungs
	description = "<span class='synth'>Я знаю запах кислорода..Зачем мне это знание...? Это круто, наверное...</span>\n"
	mood_change = 1 //Less, but persistent mood buff. Hey, handsome, you deserve it.

/obj/item/organ/lungs/tier3/on_life()
	owner.adjustOxyLoss(-1.5, FALSE)
	owner.adjustFireLoss(-0,8, FALSE)
	owner.adjustStaminaLoss(-2.5, 0)

//ANTAG LUNGS//
/obj/item/organ/lungs/tier3/antag //antag organ that can be found in some shitty places or in antag uplink since why not?
	name = "biomorphed lungs"
	icon_state = "exaltedlungs"
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	healing_factor = 3.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.1 * STANDARD_ORGAN_DECAY

/obj/item/organ/lungs/tier3/antag/on_life()
	owner.adjustOxyLoss(-5, FALSE)
	owner.adjustFireLoss(-1.5, FALSE)
	owner.adjustStaminaLoss(-7.5, 0)

/obj/item/autosurgeon/syndicate/inteq/biomorphedlungs
	uses = 1
	starting_organ = /obj/item/organ/lungs/tier3/antag

/datum/uplink_item/implants/biomorphedlungs
	name = "Biomorphed Lungs"
	desc = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленное восстановление от изнурения и частичную защиту от атмосферных угроз для дыхания."
	item = /obj/item/autosurgeon/syndicate/inteq/biomorphedlungs
	cost = 5
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)
