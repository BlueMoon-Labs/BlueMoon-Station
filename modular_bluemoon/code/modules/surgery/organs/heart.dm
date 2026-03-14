//BIOAEGIS MODULES.
//HEART

/obj/item/organ/heart/bioaegis
	name = "some heart"
	desc = "Заготовка под сердце. Ничем не отличается от обычного, кроме внешнего вида."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weakheart"

	var/insert_message = ""

	var/unstoppable = FALSE

	var/heal_brute = 0
	var/heal_fire = 0
	var/heal_tox = 0
	var/heal_oxy = 0
	var/heal_stamina = 0

/obj/item/organ/heart/bioaegis/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!. || !insert_message || !istype(organ_mob))
		return

	to_chat(organ_mob, insert_message)

/obj/item/organ/heart/bioaegis/on_life()
	if(!beating && unstoppable && owner)
		if(owner.stat == CONSCIOUS || owner.stat == SOFT_CRIT)
			beating = TRUE
	. = ..()
	if(!. || !owner)
		return

	if(heal_brute)
		owner.adjustBruteLoss(-heal_brute, FALSE)
	if(heal_fire)
		owner.adjustFireLoss(-heal_fire, FALSE)
	if(heal_tox)
		owner.adjustToxLoss(-heal_tox, TRUE)
	if(heal_oxy)
		owner.adjustOxyLoss(-heal_oxy, FALSE)
	if(heal_stamina)
		owner.adjustStaminaLoss(-heal_stamina, FALSE)

/obj/item/organ/heart/bioaegis/Stop()
	if(unstoppable)
		return FALSE

	return ..()

//TIER 1 HEART//
/obj/item/organ/heart/bioaegis/t1
	name = "improved heart"
	desc = "Довольно приличная копия сердца. Более крепкое, чем обычное сердце... Но на этом все."
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD

	insert_message = span_notice("Как ни странно... Словно ничего не поменялось.")

//TIER 2 HEART//
/obj/item/organ/heart/bioaegis/t2
	name = "changed heart"
	desc = "Улучшенная версия версии сердца. Крепче, быстрее прокачивает кислород по крови и помогает заживлять ожоги!"
	maxHealth = 2.5 * STANDARD_ORGAN_THRESHOLD //Usual factor is 2x, so...
	healing_factor = 2.5 * STANDARD_ORGAN_HEALING //Heals itself a bit faster
	decay_factor = 0.8 * STANDARD_ORGAN_DECAY //Decays a bit longer

	// Уровень импланта лечения
	heal_brute = 0.4
	heal_oxy = 0.4 //It can pump blood rather well, so it can delay oxy damage to some degree.

	insert_message = span_notice("Вы ощущаете, словно ваше сердце стало немного больше.")

//TIER 3 HEART//
/obj/item/organ/heart/bioaegis/t3
	name = "exalted heart"
	desc = "Так называемое \"Cовершенство\" в делах сердечных. Крепкое, крупное, закачивает небольшое количество химикатов, чтобы залечить физические повреждения.\
	Прокачивает большой объем крови, сильно ускоряя снабжение кислородом и гормонами."
	icon_state = "exaltedheart"
	maxHealth = 3.5 * STANDARD_ORGAN_THRESHOLD
	healing_factor = 2.5 * STANDARD_ORGAN_HEALING //Heals itself way faster
	decay_factor = 0.5 * STANDARD_ORGAN_DECAY //Decays way longer than the usual one

	heal_brute = 0.8
	heal_fire = 0.4
	heal_oxy = 0.6
	heal_stamina = 1.5

	unstoppable = TRUE

	insert_message = span_notice("Ритм вашего нового сердца словно марш легионов.")

/obj/item/organ/heart/bioaegis/t3/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!. || !istype(organ_mob))
		return
	SEND_SIGNAL(organ_mob, COMSIG_ADD_MOOD_EVENT, "super_heart", /datum/mood_event/superheart)

/obj/item/organ/heart/bioaegis/t3/Remove(special)
	. = ..()
	var/mob/living/carbon/organ_mob = .
	if(!istype(organ_mob))
		return
	SEND_SIGNAL(organ_mob, COMSIG_CLEAR_MOOD_EVENT, "super_heart")

/datum/mood_event/superheart
	description = span_nicegreen("Выносливость нового сердца радует разум!\n")
	mood_change = 1 //Perma boost since you deserved it, handsome.

//ANTAG HEART//
/obj/item/organ/heart/bioaegis/t3/antag //antag organ that can be found in some shitty places or in antag uplink since why not?
	name = "biomorphed heart"
	desc = "Что-то прямиком из научно-фантастических фильмов о мерзостях! Очень странное, но обеспечивает такю регенерацию, что делает владельца сверхсуществом..."
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	healing_factor = 3.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.1 * STANDARD_ORGAN_DECAY

	heal_brute = 2
	heal_fire = 2
	heal_tox = 2
	heal_oxy = 2
	heal_stamina = 3

	unstoppable = TRUE

	insert_message = span_notice("Вы чувствуете... Нечто чуждое внутри, но дающее вам небывалое количество сил.")
