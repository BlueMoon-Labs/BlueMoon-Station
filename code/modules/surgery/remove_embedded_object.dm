/datum/surgery/embedded_removal
	name = "Удаление застрявших объектов"
	icon_state = "embeddedobject"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/remove_object)
	possible_locs = list(BODY_ZONE_R_ARM,BODY_ZONE_L_ARM,BODY_ZONE_R_LEG,BODY_ZONE_L_LEG,BODY_ZONE_CHEST,BODY_ZONE_HEAD,BODY_ZONE_PRECISE_GROIN)
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_EMERGENCY
	ignore_clothes = TRUE

/datum/surgery/embedded_removal/robot
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(/datum/surgery_step/mechanic_open, /datum/surgery_step/open_hatch, /datum/surgery_step/remove_object)

/datum/surgery/embedded_removal/get_target_bodypart(mob/living/patient, zone)
	if(zone == BODY_ZONE_PRECISE_GROIN && HAS_TRAIT(patient, TRAIT_NAGA_ANATOMY))
		return patient.get_bodypart(BODY_ZONE_L_LEG)
	return ..()

/datum/surgery/embedded_removal/New(surgery_target, surgery_location, surgery_bodypart)
	if(surgery_target)
		surgery_bodypart = get_target_bodypart(surgery_target, surgery_location)
	return ..()

/datum/surgery/embedded_removal/can_start(mob/user, mob/living/patient, obj/item/tool)
	. = ..()
	if(!.)
		return .
	// У обычного тела пах остаётся отдельным доступом без этой операции.
	if(user.zone_selected == BODY_ZONE_PRECISE_GROIN && !HAS_TRAIT(patient, TRAIT_NAGA_ANATOMY))
		return FALSE
	var/obj/item/bodypart/BP = get_target_bodypart(patient, user.zone_selected)
	if(!length(BP?.embedded_objects))
		. = FALSE

/datum/surgery_step/remove_object
	name = "Удалить застрявшие объекты"
	time = 32
	accept_hand = 1

/datum/surgery_step/remove_object/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/bodypart/L = surgery.operated_bodypart
	if(L)
		display_results(user, target, span_notice("Вы ищете застрявшие предметы в части тела [target]: [L.ru_name]..."),
			"[user] ищет застрявшие предметы в части тела [target]: [L.ru_name].",
			"[user] ищет что-то в части тела [target]: [L.ru_name].")
	else
		user.visible_message("[user] ищет часть тела [target]: [ru_parse_zone(target_zone)].", span_notice("Вы ищете часть тела [target]: [ru_parse_zone(target_zone)]..."))

/datum/surgery_step/remove_object/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/bodypart/L = surgery.operated_bodypart
	if(L)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/objects = 0
			for(var/obj/item/I in L.embedded_objects)
				objects++
				H.remove_embedded_object(I)

			if(objects > 0)
				display_results(user, target, span_notice("Вы извлекаете застрявшие предметы ([objects]) из части тела [H]: [L.ru_name]."),
					"[user] извлекает застрявшие предметы из части тела [H]: [L.ru_name].",
					"[user] извлекает застрявшие предметы из части тела [H]: [L.ru_name].")
			else
				to_chat(user, span_warning("В части тела [H] ([L.ru_name]) нет застрявших предметов!"))

	else
		to_chat(user, span_warning("Не удаётся найти часть тела [target] ([ru_parse_zone(target_zone)]) и застрявшие в ней предметы!"))
	return TRUE
