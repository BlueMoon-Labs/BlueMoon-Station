/// TRUE, если chaplain может читать над target обряд разрыва клятвы
/proc/brother_sever_rite_possible(mob/living/chaplain, mob/living/carbon/human/target)
	if(!ishuman(target) || chaplain == target || !chaplain?.mind?.isholy)
		return FALSE
	if(!target.mind?.has_antag_datum(/datum/antagonist/brother))
		return FALSE
	if(chaplain.incapacitated() || !chaplain.Adjacent(target))
		return FALSE
	return target.restrained(TRUE) || target.body_position == LYING_DOWN || target.IsParalyzed()

/// Обряд священника: снимает кровную клятву со связанного или лежащего брата
/proc/brother_sever_rite(mob/living/chaplain, mob/living/carbon/human/target, instant = FALSE)
	if(!brother_sever_rite_possible(chaplain, target) || LAZYFIND(chaplain.do_afters, target))
		return FALSE
	var/datum/mind/target_mind = target.mind
	if(!instant)
		chaplain.visible_message(span_warning("[chaplain] склоняется над [target] и начинает читать обряд."),
			span_notice("Вы начинаете обряд разрыва клятвы. Не прерывайтесь [DisplayTimeText(BROTHER_SEVER_RITE_TIME)]."),
			target = target, target_message = span_userdanger("[chaplain] читает над вами обряд, и шрам на ладони начинает жечь!"))
		var/datum/antagonist/brother/alarmed_brother = target_mind.has_antag_datum(/datum/antagonist/brother)
		var/datum/team/brother_team/alarmed_team = alarmed_brother?.team
		alarmed_team?.rite_alarm(target)
		var/finished = do_after(chaplain, BROTHER_SEVER_RITE_TIME, target, extra_checks = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(brother_sever_rite_possible), chaplain, target))
		if(!QDELETED(alarmed_team))
			alarmed_team.end_rite_alarm(target_mind)
		if(!finished)
			if(!QDELETED(chaplain))
				to_chat(chaplain, span_warning("Обряд прерван."))
			return FALSE
	var/datum/antagonist/brother/brother = target.mind?.has_antag_datum(/datum/antagonist/brother)
	if(!brother?.team)
		return FALSE
	target.visible_message(span_warning("Что-то невидимое, тянувшееся от ладони [target], с сухим треском рвётся."))
	log_combat(chaplain, target, "severed the blood oath of", addition = "rite")
	if(!brother.team.sever(target.mind, "обряд священника [key_name(chaplain)]", BROTHER_SEVER_RITE))
		return FALSE
	target.AddComponent(/datum/component/blood_oath_seam, TRUE)
	return TRUE

/// Над братом target начали обряд: незаглушённые братья чувствуют, где это
/datum/team/brother_team/proc/rite_alarm(mob/living/target)
	var/datum/mind/target_mind = target?.mind
	var/datum/antagonist/brother/target_brother = target_mind?.has_antag_datum(/datum/antagonist/brother)
	if(target_brother?.team != src || target_brother.is_muted())
		return FALSE
	end_rite_alarm(target_mind)
	. = FALSE
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/mob/living/body = brother.owner.current
		if(brother == target_brother || (brother.owner in departed_minds) || brother.is_muted() || !isliving(body) || body.stat == DEAD)
			continue
		body.apply_status_effect(/datum/status_effect/brother_sense/rite, target_mind)
		to_chat(body, span_boldwarning("Нить натянулась: над [target_mind.name] читают обряд. Где: [blood_bond_direction_text(get_turf(body), get_turf(target)) || "не понять"]."))
		. = TRUE

/// Обряд над target_mind окончен или сорван: тревога гаснет
/datum/team/brother_team/proc/end_rite_alarm(datum/mind/target_mind)
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/mob/living/body = brother.owner.current
		if(!isliving(body))
			continue
		for(var/datum/status_effect/brother_sense/rite/alarm as anything in body.has_status_effect_list(/datum/status_effect/brother_sense/rite))
			if(alarm.tracked == target_mind)
				qdel(alarm)

/datum/status_effect/brother_sense/rite
	id = "brother_rite"
	duration = BROTHER_SEVER_RITE_TIME
	tick_interval = BROTHER_SENSE_INTERVAL

/datum/status_effect/brother_sense/rite/on_apply()
	. = ..()
	if(. && linked_alert)
		animate(linked_alert, alpha = 90, time = 0.4 SECONDS, loop = -1, flags = ANIMATION_PARALLEL)
		animate(alpha = 255, time = 0.4 SECONDS)

/datum/status_effect/brother_sense/rite/tick()
	refresh()

/datum/status_effect/brother_sense/rite/refresh()
	if(!linked_alert || !tracked)
		return
	linked_alert.name = "Нить натянулась"
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(tracked.current)
	linked_alert.desc = "Над [tracked.name] читают обряд разрыва клятвы. Где: [blood_bond_direction_text(here, there) || "не понять"]."
	point_alert(here, there)

/// TRUE, если хотя бы одна рука тела живая, не протез и не рука КПБ
/proc/blood_oath_palm_organic(mob/living/body)
	if(!iscarbon(body))
		return FALSE
	var/mob/living/carbon/carbon_body = body
	for(var/obj/item/bodypart/part as anything in carbon_body.bodyparts)
		if((part.body_zone == BODY_ZONE_L_ARM || part.body_zone == BODY_ZONE_R_ARM) && part.is_organic_limb(FALSE))
			return TRUE
	return FALSE

/// Строка анализатора здоровья о ладони или null
/proc/blood_oath_palm_scan(mob/living/scanned)
	if(!blood_oath_palm_organic(scanned))
		return null
	if(HAS_TRAIT(scanned, TRAIT_BLOOD_OATH_SCAR))
		return "Рубец на ладони: след глубокого пореза."
	var/datum/component/blood_oath_seam/seam = scanned.GetComponent(/datum/component/blood_oath_seam)
	if(seam)
		return "Рубец на ладони иссечён, на его месте свежий [seam.burned ? "ожог" : "шов"]."
	return null

/// Свежий след на ладони после разрыва клятвы; заживает сам
/datum/component/blood_oath_seam
	/// Обряд оставляет ожог, операция - шов
	var/burned = FALSE
	var/heal_timer

/datum/component/blood_oath_seam/Initialize(burned = FALSE)
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE
	src.burned = burned
	heal_timer = addtimer(CALLBACK(src, PROC_REF(heal)), BROTHER_FRESH_SEAM_DURATION, TIMER_STOPPABLE)

/datum/component/blood_oath_seam/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/blood_oath_seam/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

/datum/component/blood_oath_seam/proc/heal()
	qdel(src)

/datum/component/blood_oath_seam/proc/on_examine(mob/living/carbon/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!blood_oath_palm_organic(source) || source.get_item_by_slot(ITEM_SLOT_GLOVES) || (ITEM_SLOT_GLOVES in source.check_obscured_slots()))
		return
	examine_list += span_warning("Поперёк [source.ru_ego()] ладони - свежий [burned ? "ожог" : "шов"].")

/obj/item/storage/book/bible/examine(mob/user)
	. = ..()
	if(user.mind?.isholy)
		. += span_notice("Если поперёк ладони связанного или лежащего человека тянется шрам кровной клятвы, обряд разорвёт её: ударьте его книгой и не прерывайтесь [DisplayTimeText(BROTHER_SEVER_RITE_TIME)].")
