/datum/surgery/advanced/viral_bonding
	name = "Viral Bonding"
	desc = "Хирургическая процедура, которая устанавливает симбиотические отношения между вирусом и его носителем. Пациенту необходимо ввести спейсациллин, вирусную пищу и формальдегид."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/viral_bond,
				/datum/surgery_step/close)

	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST)
	is_healing = FALSE // BLUEMOON ADD
	icon = 'icons/mob/actions/actions_minor_antag.dmi'
	icon_state = "disease_menu"

/datum/surgery/advanced/viral_bonding/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!..())
		return FALSE
	if(!LAZYLEN(target.diseases))
		return FALSE
	return TRUE
/datum/surgery_step/viral_bond
	name = "Закрепить Вирусную Связь"
	implements = list(TOOL_CAUTERY  = 100, TOOL_WELDER = 50, /obj/item = 30) // 30% success with any hot item.
	time = 100
	chems_needed = list(/datum/reagent/medicine/spaceacillin, /datum/reagent/consumable/virus_food, /datum/reagent/toxin/formaldehyde)

/datum/surgery_step/viral_bond/tool_check(mob/user, obj/item/tool)
	if(implement_type == TOOL_WELDER || implement_type == /obj/item)
		return tool.get_temperature()
	return TRUE

/datum/surgery_step/viral_bond/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You start heating [target]'s bone marrow with [tool]...</span>",
		"[user] starts heating [target]'s bone marrow with [tool]...",
		"[user] starts heating something in [target]'s chest with [tool]...")

/datum/surgery_step/viral_bond/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>[target]'s bone marrow begins pulsing slowly. The viral bonding is complete.</span>",
		"[target]'s bone marrow begins pulsing slowly.",
		"[user] finishes the operation.")
	for(var/X in target.diseases)
		var/datum/disease/D = X
		D.carrier = TRUE
	return TRUE
