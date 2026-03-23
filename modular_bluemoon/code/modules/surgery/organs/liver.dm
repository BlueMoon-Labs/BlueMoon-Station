//BIOAEGIS MODULES.
//LIVER

/obj/item/organ/liver/bioaegis
	name = "some liver"
	desc = "Заготовка под печень. Ничем не отличается от обычной, кроме внешнего вида."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weakliver"

	var/insert_message = ""

	var/heal_tox = 0
	var/heal_fire = 0
	var/heal_stamina = 0

/obj/item/organ/liver/bioaegis/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!. || !insert_message || !istype(organ_mob))
		return

	to_chat(organ_mob, insert_message)

/obj/item/organ/liver/bioaegis/on_life()
	. = ..()
	if(!. || !owner) //can't process reagents with a failing liver
		return

	if(heal_tox)
		owner.adjustToxLoss(-heal_tox, TRUE) //Doesn't kill slimes. Yes.
	if(heal_fire)
		owner.adjustFireLoss(-heal_fire, FALSE)
	if(heal_stamina)
		owner.adjustStaminaLoss(-heal_stamina, FALSE)

//TIER 1 LIVER//
/obj/item/organ/liver/bioaegis/t1
	name = "improved liver"
	desc = "Довольно приличная копия печени. Более стойкая, чем обычная печень... Но на этом все."
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 2 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.4 * LIVER_DEFAULT_TOX_LETHALITY
	filterToxinsAmount = 1.5

	insert_message = span_notice("Печень... Кажется стала чуть больше?")

//TIER 2 LIVER//
/obj/item/organ/liver/bioaegis/t2
	name = "changed liver"
	desc = "Улучшенная версия версии печени. Крепче, выводит больше токсинов и помогает заживлять ожоги!"
	alcohol_tolerance = 0.001
	maxHealth = 2.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 5 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.4 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 1.5 * STANDARD_ORGAN_HEALING //Heals itself a bit faster
	decay_factor = 0.8 * STANDARD_ORGAN_DECAY //Decays a bit longer
	filterToxinsAmount = 2

	// Уровень импланта лечения
	heal_tox = 0.4
	heal_fire = 0.4

	insert_message = span_notice("Вы ощущаете, словно ваша кровь стала чище.")

///TIER 3 LIVER//
/obj/item/organ/liver/bioaegis/t3
	name = "exalted liver"
	icon_state = "exaltedliver"
	desc = "Кое-что, что могло бы пригодиться алкоголику. Эта версия печени крепче, качественнее, способна фильтровать и выдерживать больше, даже чем кибернетический аналог!"
	alcohol_tolerance = 0.0005 //At this point just drink everything.
	maxHealth = 3.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 7 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.2 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 2.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.5 * STANDARD_ORGAN_DECAY
	filterToxinsAmount = 3

	heal_tox = 1.5
	heal_fire = 0.6

	insert_message = span_notice("Вы можете заметить, словно ваша кожа стала светлее...") //This is a *very precise* superior version of liver - you wouldn't feel anything.

/obj/item/organ/liver/bioaegis/t3/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!. || !istype(organ_mob))
		return
	SEND_SIGNAL(organ_mob, COMSIG_ADD_MOOD_EVENT, "super_liver", /datum/mood_event/superliver)

/obj/item/organ/liver/bioaegis/t3/Remove(special)
	. = ..()
	var/mob/living/carbon/organ_mob = .
	if(!istype(organ_mob))
		return
	SEND_SIGNAL(organ_mob, COMSIG_CLEAR_MOOD_EVENT, "super_liver")

/datum/mood_event/superliver
	description = span_nicegreen("Алкоголизм мне не помеха!\n")
	mood_change = 1 //Less, but persistent mood buff. Hey, handsome, you deserve it.

//ANTAG LIVER//
/obj/item/organ/liver/bioaegis/t3/antag //antag organ that can be found in some shitty places or in antag uplink since why not?
	name = "biomorphed liver"
	desc = "Очень секретное оружие против алкоголизма или безопасность в отношении химикатов!"
	icon_state = "exaltedliver"
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 9 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.1 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 3.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.1 * STANDARD_ORGAN_DECAY
	filterToxinsAmount = 5

	heal_tox = 5
	heal_fire = 2
	heal_stamina = 5

	insert_message = span_notice("Вы чувствуете... Нечто чуждое внутри, но ваш организм словно очищается от всех токсинов..")
