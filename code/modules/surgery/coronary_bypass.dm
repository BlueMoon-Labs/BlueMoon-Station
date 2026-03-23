/datum/surgery/coronary_bypass
	name = "Coronary Bypass"
	desc = "Хирургическая процедура, при которой создаётся обходной путь для восстановления кровотока в артериях сердца. Способна исправить некроз, но необратимо изменяет сосуды сердца, не позволяя провести процедуру повторно."
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/saw, /datum/surgery_step/clamp_bleeders,
				 /datum/surgery_step/incise_heart, /datum/surgery_step/coronary_bypass, /datum/surgery_step/close)
	possible_locs = list(BODY_ZONE_CHEST)
	requires_bodypart_type = BODYPART_ORGANIC
	special_surgery_traits = list(OPERATION_NEED_FULL_ANESTHETIC) // BLUEMOON ADD - операция требует, чтобы пациент находился без сознания
	icon_state = "heart-off"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ORGAN

/datum/surgery/coronary_bypass/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	. = ..()
	if(!.)
		return .

	var/obj/item/organ/heart/H = target.getorganslot(ORGAN_SLOT_HEART)
	return (H && !H.operated && (H.organ_flags & ORGAN_FAILING))

//an incision but with greater bleed, and a 90% base success chance
/datum/surgery_step/incise_heart
	name = "Разрезать Сердце"
	implements = list(TOOL_SCALPEL = 90, /obj/item/melee/transforming/energy/sword = 45, /obj/item/kitchen/knife = 45,
		/obj/item/shard = 25)
	time = 16
	preop_sound = 'sound/surgery/scalpel1.ogg'
	success_sound = 'sound/surgery/scalpel2.ogg'
	failure_sound = 'sound/surgery/organ2.ogg'

/datum/surgery_step/incise_heart/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("Вы начинаете делать надрез на сердце [target]..."),
		"[user] начинает делать надрез на сердце [target].",
		"[user] начинает делать надрез внутри [target].")

/datum/surgery_step/incise_heart/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if (!(NOBLOOD in H.dna.species.species_traits))
			display_results(user, target, span_notice("Кровь скапливается вокруг разреза в сердце [target]."),
				"Кровь скапливается вокруг разреза в сердце [target].",
				"")
			var/obj/item/bodypart/BP = H.get_bodypart(target_zone)
			BP.generic_bleedstacks += 10
			H.adjustBruteLoss(10)
	return TRUE

/datum/surgery_step/incise_heart/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		display_results(user, target, span_warning("Вы облажались, прорезав сердце слишком глубоко!"),
			span_warning("[user] ошибается, вызывая фонтанчик крови, вырвавшийся из груди [H]!"),
			span_warning("[user] ошибается, вызывая фонтанчик крови, вырвавшийся из груди [H]!"))
		var/obj/item/bodypart/BP = H.get_bodypart(target_zone)
		BP.generic_bleedstacks += 10
		H.adjustOrganLoss(ORGAN_SLOT_HEART, 10)
	target.adjustBruteLoss(10)

/datum/surgery_step/coronary_bypass
	name = "Произвести Коронарное Шунтирование"
	implements = list(TOOL_HEMOSTAT = 100, TOOL_WIRECUTTER = 45, /obj/item/stack/packageWrap = 25, /obj/item/stack/cable_coil = 15)
	time = 90
	preop_sound = 'sound/surgery/hemostat1.ogg'
	success_sound = 'sound/surgery/hemostat1.ogg'
	failure_sound = 'sound/surgery/organ2.ogg'

/datum/surgery_step/coronary_bypass/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("Вы начинаете формировать обходной шунт на сердце [target]..."),
			"[user] начинает шунтировать сердце [target]!",
			"[user] начинает что-то делать в груди [target]!")

/datum/surgery_step/coronary_bypass/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/heart/H = target.getorganslot(ORGAN_SLOT_HEART)
	if(H)
		H.operated = TRUE
	target.setOrganLoss(ORGAN_SLOT_HEART, 0)
	display_results(user, target, span_notice("Вы успешно сформировали обходной шунт на сердце [target]."),
			"[user] заканчивает шунтировать сердце [target].",
			"[user] заканчивает что-то делать в груди [target].")
	return TRUE

/datum/surgery_step/coronary_bypass/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		display_results(user, target, span_warning("Вы допустили ошибку при формировании шунта и он оторвался, вместе с кусочком сердца!"),
			span_warning("[user] ошибается, вызывая фонтан крови, вырвавшийся из груди [H]!"),
			span_warning("[user] ошибается, вызывая фонтан крови, вырвавшийся из груди [H]!"))
		..()
		H.adjustOrganLoss(ORGAN_SLOT_HEART, 20)
		var/obj/item/bodypart/BP = H.get_bodypart(target_zone)
		BP.generic_bleedstacks += 30
		BP.take_damage(20, BRUTE, MELEE)
	return FALSE
