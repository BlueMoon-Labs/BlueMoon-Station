/datum/surgery/blood_filter
	name = "Filter blood"
	desc = "Процедура, направленная на очистку крови пациента от посторонних веществ."
	possible_locs = list(BODY_ZONE_CHEST)
	icon_state = "bloodfilter"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ADDITIONAL
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/incise,
		/datum/surgery_step/filter_blood,
		/datum/surgery_step/close,
	)

/datum/surgery/blood_filter/can_start(mob/user, mob/living/carbon/target)
	if(HAS_TRAIT(target, TRAIT_HUSK)) //You can filter the blood of a dead person just not husked
		return FALSE
	return ..()

/datum/surgery_step/filter_blood/initiate(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)
	display_results(
		user,
		target,
		span_notice("Вы начинаете фильтровать кровь [target]..."),
		span_notice("[user] использует [tool] дли фильтрации крови [target]."),
		span_notice("[user] что-то делает [tool] в груди [target]."),
	)
	if(!..())
		return
	while(has_filterable_chems(target, tool))
		if(!..())
			break

/**
 * Checks if the mob contains chems we can filter
 *
 * If the blood filter's whitelist is empty this checks if the mob contains any chems
 * If the whitelist contains chems it checks if any chems in the mob match chems in the whitelist
 *
 * Arguments:
 * * target - The mob to check the chems of
 * * bloodfilter - The blood filter to check the whitelist of
 */
/datum/surgery_step/filter_blood/proc/has_filterable_chems(mob/living/carbon/target, obj/item/blood_filter/bloodfilter)
	if(!length(target.reagents?.reagent_list))
		bloodfilter.audible_message(span_notice("[bloodfilter] пищит, оповещая, что в крови [target] не обнаружено реагентов."))
		playsound(bloodfilter, 'sound/machines/ping.ogg', 75, TRUE, falloff_exponent = 12, falloff_distance = 1)
		return FALSE

	if(!length(bloodfilter.whitelist))
		return TRUE

	for(var/datum/reagent/chem in target.reagents.reagent_list)
		if(chem.type in bloodfilter.whitelist)
			return TRUE

	return FALSE

/datum/surgery_step/filter_blood
	name = "Фильтруйте кровь"
	implements = list(TOOL_BLOODFILTER = 95)
	repeatable = TRUE
	time = 2.5 SECONDS
	success_sound = 'sound/machines/card_slide.ogg'

/datum/surgery_step/filter_blood/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	var/obj/item/blood_filter/bloodfilter = tool
	if(target.reagents?.total_volume)
		for(var/datum/reagent/chem in target.reagents.reagent_list)
			if(!length(bloodfilter.whitelist) || !(chem.type in bloodfilter.whitelist))
				target.reagents.remove_reagent(chem.type, 10, TRUE)
	display_results(
		user,
		target,
		span_notice("\The [tool] завершает цикл фильтрации крови [target]."),
		span_notice("\The [tool] шумит пока фильрует кровь [target]."),
		span_notice("Из [tool] слышен звук работающей помпы."),
	)

	if(locate(/obj/item/healthanalyzer) in user.held_items)
		chemscan(user, target)

	return ..()

/datum/surgery_step/filter_blood/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	display_results(
		user,
		target,
		span_warning("Вы напортачили, травмировав грудь [target]!"),
		span_warning("[user] напортачил, травмировав грудь [target]!"),
		span_warning("[user] ошибается при операции!"),
	)
	target.adjustBruteLoss(10)
