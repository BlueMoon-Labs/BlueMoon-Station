/datum/surgery/gastrectomy
	name = "Gastrectomy"	//not to be confused with lobotomy
	desc = "Хирургическая процедура, для удаления доли пораженного некрозом желудка и дальнейшего заживления. Повторное проведение процедуры невозможно из-за значительного уменьшения доли желудка."
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/clamp_bleeders,
				 /datum/surgery_step/gastrectomy, /datum/surgery_step/close)
	possible_locs = list(BODY_ZONE_CHEST)
	requires_bodypart_type = BODYPART_ORGANIC
	special_surgery_traits = list(OPERATION_NEED_FULL_ANESTHETIC) // BLUEMOON ADD - операция требует, чтобы пациент находился без сознания
	icon_state = "stomach"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ORGAN

/datum/surgery/gastrectomy/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	. = ..()
	if(!.)
		return .
	var/obj/item/organ/stomach/L = target.getorganslot(ORGAN_SLOT_STOMACH)
	return (L && !L.operated && (L.organ_flags & ORGAN_FAILING))

/datum/surgery_step/gastrectomy
	name = "Удалить часть желудка"
	implements = list(TOOL_SCALPEL = 100, /obj/item/melee/transforming/energy/sword = 65, /obj/item/kitchen/knife = 45,
		/obj/item/shard = 35)
	time = 90
	preop_sound = 'sound/surgery/scalpel1.ogg'
	success_sound = 'sound/surgery/organ1.ogg'
	failure_sound = 'sound/surgery/organ2.ogg'

/datum/surgery_step/gastrectomy/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("Вы начинаете делать надрез на желудке [target]..."),
		"[user] начинает делать надрез на желудке [target].",
		"[user] начинает делать надрез внутри [target].")

/datum/surgery_step/gastrectomy/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/stomach/L = target.getorganslot(ORGAN_SLOT_STOMACH)
	if(L)
		L.operated = TRUE
	target.setOrganLoss(ORGAN_SLOT_STOMACH, 0)
	display_results(user, target, span_notice("Вы успешно удалили долю желудка [target] пораженную некрозом."),
		"Успешно удаляет часть желудка [target].",
			"")
	return TRUE

/datum/surgery_step/gastrectomy/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		display_results(user, target, span_warning("Вы облажались, не сумев удалить поврежденную долю желудка [H]!"),
			span_warning("[user] допускает ошибку при операции!"),
			span_warning("[user] допускает ошибку при операции!"))
		..()
		H.losebreath += 4
		H.adjustOrganLoss(ORGAN_SLOT_STOMACH, 10)
		var/obj/item/bodypart/BP = H.get_bodypart(target_zone)
		BP.take_damage(20, BRUTE, MELEE)
	return FALSE
