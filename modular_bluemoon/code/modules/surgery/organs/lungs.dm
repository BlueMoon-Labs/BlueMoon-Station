//BIOAEGIS MODULES.
//LUNGS

/obj/item/organ/lungs/bioaegis
	name = "some lungs"
	desc = "Заготовка под легкие. Ничем не отличаются от обычных, кроме внешнего вида."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weaklungs"

	var/insert_message = ""

	var/heal_oxy = 0
	var/heal_fire = 0
	var/heal_stamina = 0

/obj/item/organ/lungs/bioaegis/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!. || !insert_message || !istype(organ_mob))
		return

	to_chat(organ_mob, insert_message)

/obj/item/organ/lungs/bioaegis/on_life(seconds, times_fired)
	. = ..()
	if(!. || !owner)
		return

	if(heal_oxy)
		owner.adjustOxyLoss(-heal_oxy, FALSE)
	if(heal_fire)
		owner.adjustFireLoss(-heal_fire, FALSE)
	if(heal_stamina)
		owner.adjustStaminaLoss(-heal_stamina, FALSE)

//TIER 1 LUNGS//
/obj/item/organ/lungs/bioaegis/t1
	name = "improved lungs"
	desc = "Довольно приличная копия легких. Более крепкая, чем обычные легкие, позволяет сделать вдох поглубже."
	icon_state = "weaklungs"
	maxHealth = 3.5 * STANDARD_ORGAN_THRESHOLD //Standard modifier is x3, but this is bs amount of health for an organ?
	safe_breath_min = 13
	safe_breath_max = 100
	smell_sensitivity = 1.5

	insert_message = span_notice("Вы чувствуете, как можете вдохнуть больше воздуха.")

//TIER 2 LUNGS//
/obj/item/organ/lungs/bioaegis/t2
	name = "changed lungs"
	desc = "Улучшенная версия версии легких. Крепче, позволяет дышать еще глубже и фильтровать часть токсичных газов!"
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	decay_factor = 0.8 * STANDARD_ORGAN_DECAY
	smell_sensitivity = 1.7
	safe_breath_min = 10
	safe_breath_max = 150
	gas_max = list(
		GAS_PLASMA = 30,
		GAS_CO2 = 30,
		GAS_METHYL_BROMIDE = 10
	)

	// Уровень импланта лечения
	heal_oxy = 0.4
	heal_fire = 0.4

	insert_message = span_notice("Вы чувствуете, как ваши легкие словно расправляются, пытаясь вдохнуть больше воздуха.")

///TIER 3 LUNGS//
/obj/item/organ/lungs/bioaegis/t3
	name = "exalted lungs"
	desc = "Вы <i>п р о ч у в с т в у е т е</i> воздух - эта версия легких прочнее, качественнее, способна фильтровать и выдерживать даже больше, чем кибернетический аналог!"
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

	heal_oxy = 1.5
	heal_fire = 0.8
	heal_stamina = 2.5

	insert_message = span_notice("Вы можете ощутить малейший запах в комнате...")

/obj/item/organ/lungs/bioaegis/t3/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!. || !istype(organ_mob))
		return
	SEND_SIGNAL(organ_mob, COMSIG_ADD_MOOD_EVENT, "super_lungs", /datum/mood_event/superlungs)

/obj/item/organ/lungs/bioaegis/t3/Remove(special)
	. = ..()
	var/mob/living/carbon/organ_mob = .
	if(!istype(organ_mob))
		return
	SEND_SIGNAL(organ_mob, COMSIG_CLEAR_MOOD_EVENT, "super_lungs")

/datum/mood_event/superlungs
	description = "<span class='synth'>Я знаю запах кислорода..Зачем мне это знание...? Это круто, наверное...</span>\n"
	mood_change = 1 //Less, but persistent mood buff. Hey, handsome, you deserve it.

//ANTAG LUNGS//
/obj/item/organ/lungs/bioaegis/t3/antag //antag organ that can be found in some shitty places or in antag uplink since why not?
	name = "biomorphed lungs"
	desc = "Разработка безумного гения... Или просто заядлого курильщика. Эти легкие поглощают столько кислорода, что вы будете чувствовать себя бодрым несколько суток подряд!"
	maxHealth = 6 * STANDARD_ORGAN_THRESHOLD
	healing_factor = 4 * STANDARD_ORGAN_HEALING
	decay_factor = 0.1 * STANDARD_ORGAN_DECAY
	smell_sensitivity = 2.5

	heal_oxy = 5
	heal_fire = 1.5
	heal_stamina = 7.5

	insert_message = span_notice("Ваш мозг почти взрывается от запахов вокруг...")
