/datum/surgery/blood_oath_scar
	name = "Excise oath scar"
	desc = "Иссечение шрама кровной клятвы с ладони. Вместе со шрамом рвётся и сама клятва."
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/excise_oath_scar, /datum/surgery_step/close)
	target_mobtypes = list(/mob/living/carbon/human)
	possible_locs = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM)
	is_healing = FALSE
	radial_priority = SURGERY_RADIAL_PRIORITY_OTHER_FIRST

/datum/surgery/blood_oath_scar/can_start(mob/user, mob/living/patient, obj/item/tool)
	return HAS_TRAIT(patient, TRAIT_BLOOD_OATH_SCAR) && ..()

/datum/surgery/blood_oath_scar/mechanic
	name = "Prosthesis oath scar excision"
	desc = "Иссечение шрама кровной клятвы с механической ладони: протеза или руки КПБ. Вместе со шрамом рвётся и сама клятва."
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(/datum/surgery_step/mechanic_open, /datum/surgery_step/open_hatch, /datum/surgery_step/excise_oath_scar, /datum/surgery_step/mechanic_close)

/datum/surgery_step/excise_oath_scar
	name = "Иссечь Шрам Клятвы"
	implements = list(TOOL_SCALPEL = 100, /obj/item/kitchen/knife = 50, /obj/item/shard = 25)
	time = BROTHER_SCAR_EXCISE_TIME
	preop_sound = 'sound/surgery/scalpel1.ogg'
	success_sound = 'sound/surgery/scalpel2.ogg'

/datum/surgery_step/excise_oath_scar/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("Вы начинаете иссекать шрам с ладони [target]..."),
		span_notice("[user] начинает иссекать шрам с ладони [target]."),
		span_notice("[user] склоняется над рукой [target]."))

/datum/surgery_step/excise_oath_scar/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("Вы иссекаете шрам с ладони [target]."),
		span_notice("[user] иссекает шрам с ладони [target]."),
		span_notice("[user] заканчивает работу над рукой [target]."))
	var/datum/antagonist/brother/brother = target.mind?.has_antag_datum(/datum/antagonist/brother)
	if(brother?.team)
		log_combat(user, target, "severed the blood oath of", addition = "surgery")
		if(brother.team.sever(target.mind, "операция [key_name(user)]", BROTHER_SEVER_SURGERY))
			target.AddComponent(/datum/component/blood_oath_seam, FALSE)
	return TRUE
