//BIOAEGIS MODULES.
//LIVER

/obj/item/organ/liver/bioaegis
	name = "some liver"
	desc = "Заготовка под печень. Ничем не отличается от обычной, кроме внешнего вида."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weakliver"
	var/healTox = 0
	var/healFire = 0
	var/healStamina = 0

/obj/item/organ/liver/bioaegis/on_life()
	. = ..()
	if(!. || !owner) //can't process reagents with a failing liver
		return
	owner.adjustToxLoss(-healTox, TRUE) //Doesn't kill slimes. Yes.
	owner.adjustFireLoss(-healFire, FALSE)
	owner.adjustStaminaLoss(-healStamina, FALSE)

//TIER 1 LIVER//
/obj/item/organ/liver/bioaegis/t1
	name = "improved liver"
	desc = "Довольно приличная копия базовой печени. Более прочная, чем базовая печень... Но на этом все."
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 2 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.4 * LIVER_DEFAULT_TOX_LETHALITY
	filterToxinsAmount = 1.5

/obj/item/organ/liver/bioaegis/t1/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Что-то неприятно упёрлось внутри живота...</span>\n")

//TIER 2 LIVER//
/obj/item/organ/liver/bioaegis/t2
	name = "changed liver"
	desc = "Улучшенная версия базовой версии печени. Прочнее, выводит больше токсинов и помогает заживлять ожоги!"
	alcohol_tolerance = 0.001
	maxHealth = 2.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 5 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.4 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 1.5 * STANDARD_ORGAN_HEALING //Heals itself a bit faster
	decay_factor = 0.8 * STANDARD_ORGAN_DECAY //Decays a bit longer
	filterToxinsAmount = 2

	healTox = 0.25
	healFire = 0.25

/obj/item/organ/liver/bioaegis/t2/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Вы ощущаете, словно ваша кровь стала чище.</span>\n")

///TIER 3 LIVER//
/obj/item/organ/liver/bioaegis/t3
	name = "exalted liver"
	icon_state = "exaltedliver"
	desc = "Кое-что, что могло бы пригодиться алкоголику. Эта версия печени прочнее, качественнее, способна фильтровать и выдерживать больше, даже чем кибернетический аналог!"
	alcohol_tolerance = 0.0005 //At this point just drink everything.
	maxHealth = 3.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 7 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.2 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 2.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.5 * STANDARD_ORGAN_DECAY
	filterToxinsAmount = 3

	healTox = 1.5
	healFire = 0.35

/obj/item/organ/liver/bioaegis/t3/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Вы можете заметить, словно ваша кожа стала светлее...</span>\n") //This is a *very precise* superior version of liver - you wouldn't feel anything.
	SEND_SIGNAL(organ_mob, COMSIG_ADD_MOOD_EVENT, "super liver", /datum/mood_event/superliver)

/datum/mood_event/superliver
	description = "<span class='nicegreen'>Алкоголизм мне не помеха!</span>\n"
	mood_change = 1 //Less, but persistent mood buff. Hey, handsome, you deserve it.

//ANTAG LIVER//
/obj/item/organ/liver/bioaegis/t3/antag //antag organ that can be found in some shitty places or in antag uplink since why not?
	name = "biomorphed liver"
	desc = "Очень секретное оружие против алкоголизма или безопасность NT в отношении химикатов!"
	icon_state = "exaltedliver"
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 9 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.1 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 3.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.1 * STANDARD_ORGAN_DECAY
	filterToxinsAmount = 5

	healTox = -5
	healFire = -2
	healStamina = -5
