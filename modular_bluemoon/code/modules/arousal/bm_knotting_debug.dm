// BlueMoon: admin knotting diagnostics (v5)
// Active knot state in current BlueMoon is stored on /obj/item/organ/genital/penis.
// This file intentionally does not activate raw knot state or create its own timers.

// Diagnostic flag for one round's test window; no preference or disk persistence.
GLOBAL_VAR_INIT(knot_debug_ignore_prefs_until, 0)
GLOBAL_VAR_INIT(knot_debug_ignore_prefs_owner, null)

/client
	/// Temporary per-admin testing option; guarantees the roll, not anatomy validation.
	var/tmp/knot_debug_force_chance = FALSE

/client/proc/knot_debug_report_mood(mob/living/carbon/human/H)
	if(!H || QDELETED(H))
		return
	var/datum/component/mood/M = H.GetComponent(/datum/component/mood)
	if(!M)
		to_chat(src, "[H]: компонент настроения отсутствует.")
		return
	var/list/events = M.mood_events
	var/satisfied = !!(events && ("knotting_satisfied" in events))
	var/linked = !!(events && ("knotting_linked" in events))
	var/painful = !!(events && ("knotting_painful" in events))
	to_chat(src, "[H]: mood satisfied [satisfied], linked [linked], painful [painful].")

/client/proc/knot_debug_show_state(mob/living/carbon/human/H)
	if(!H || QDELETED(H))
		to_chat(src, span_warning("Нужен живой объект человека для проверки."))
		return
	var/obj/item/organ/genital/penis/P = H.active_knot
	if(!P || QDELETED(P))
		P = H.getorganslot(ORGAN_SLOT_PENIS)
	to_chat(src, span_notice("=== Knot debug: [H] ==="))
	to_chat(src, "Общий TEST bypass prefs = [knotting_debug_prefs_active()] (включил: [GLOB.knot_debug_ignore_prefs_owner]), force chance = [knot_debug_force_chance]")
	to_chat(src, "Преф sexknotting: [!!H.client?.prefs?.sexknotting], arousable: [!!H.client?.prefs?.arousable].")
	to_chat(src, "Эструс: [HAS_TRAIT(H, TRAIT_ESTROUS_ACTIVE)].")
	var/threshold = H.get_climax_threshold()
	to_chat(src, "Возбуждение: [H.get_lust()] / [threshold], процент: [threshold > 0 ? round(100 * H.get_lust() / threshold, 0.1) : 0] (для обычного узлирования требуется >= 65%).")
	if(!P || QDELETED(P))
		to_chat(src, span_warning("Нет узловатого органа и нет активной связи."))
		knot_debug_report_mood(H)
		return
	to_chat(src, "Орган: [P] (владелец [P.owner], shape [P.shape], knot_size [P.knot_size], strength [P.knot_strength]).")
	var/zones_text = islist(P.knot_zones) ? jointext(P.knot_zones, ", ") : "нет"
	to_chat(src, "Состояние: locked [P.knot_locked], zones [zones_text], primary [P.knot_state].")
	to_chat(src, "Партнёр: [P.knot_partner], active_knot owner [P.owner?.active_knot == P], partner [P.knot_partner?.active_knot == P].")
	to_chat(src, "Осталось секунд: [P.knot_until ? round(max(P.knot_until - world.time, 0) / (1 SECONDS), 0.1) : 0], hidden [P.knot_is_hidden].")
	to_chat(src, "Таймеры: arousal [!!P.knot_arousal_timer], release [!!P.knot_release_timer], distance [!!P.knot_distance_timer].")
	if(islist(P.knotted_genitals))
		for(var/obj/item/organ/genital/G in P.knotted_genitals)
			to_chat(src, "Занятый орган: [G] / owner [G?.owner] / is_knotted [G?.is_knotted].")
	else if(P.knotted_genital)
		to_chat(src, "Занятый орган (старое поле): [P.knotted_genital], is_knotted [P.knotted_genital.is_knotted].")
	if(P.knot_partner && ishuman(P.knot_partner))
		var/mob/living/carbon/human/partner = P.knot_partner
		to_chat(src, "Партнёр: sexknotting [partner.client?.prefs?.sexknotting], arousable [partner.client?.prefs?.arousable], эструс [HAS_TRAIT(partner, TRAIT_ESTROUS_ACTIVE)].")
		knot_debug_report_mood(partner)
	knot_debug_report_mood(H)

/client/proc/knot_debug_select_human(mob/living/carbon/human/exclude = null)
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in range(1, mob))
		if(!QDELETED(H) && H != exclude)
			candidates += H
	if(!length(candidates))
		to_chat(src, span_warning("Нужен другой человек в соседнем тайле (не далее 1)."))
		return null
	return input(mob, "Выбери персонажа:", "Knot Debug") as null|anything in candidates

/client/proc/knot_debug_select_zone()
	var/list/zones = list(
		"Влагалище" = CUM_TARGET_VAGINA,
		"Анус" = CUM_TARGET_ANUS,
		"Рот" = CUM_TARGET_MOUTH,
		"Глотка" = CUM_TARGET_THROAT
	)
	var/choice = input(mob, "Выбери зону:", "Knot Debug") as null|anything in zones
	return zones[choice]

/client/proc/knot_debug_preview(mob/living/carbon/human/pen_owner, mob/living/carbon/human/recipient, zone)
	if(QDELETED(pen_owner) || QDELETED(recipient) || !zone)
		return FALSE
	var/obj/item/organ/genital/penis/P = pen_owner.getorganslot(ORGAN_SLOT_PENIS)
	to_chat(src, span_notice("=== Предварительная проверка: [pen_owner] -> [recipient] / [zone] ==="))
	if(!P || QDELETED(P))
		to_chat(src, span_warning("У инициатора отсутствует нужный орган."))
		return FALSE
	to_chat(src, "Орган [P], форма [P.shape], knot_size [P.knot_size], уже связан [P.knot_locked].")
	to_chat(src, "Дистанция [get_dist(pen_owner, recipient)], Z-уровни [pen_owner.z] / [recipient.z].")
	to_chat(src, "Префы: [!!pen_owner.client?.prefs?.sexknotting] / [!!recipient.client?.prefs?.sexknotting].")
	to_chat(src, "Бонус эструса: [P.calculate_estrus_bonus(recipient)], шанс с учётом параметров: [P.calculate_knot_chance(pen_owner, recipient, zone)]%.")
	to_chat(src, "Совместимость зоны: [P.calculate_zone_modifier(recipient, zone) > -100].")
	var/threshold = pen_owner.get_climax_threshold()
	to_chat(src, "Возбуждение: [threshold > 0 ? round(pen_owner.get_lust() / threshold * 100, 0.1) : 0]% (обычный порог 65%).")
	if(P.knot_locked && P.knot_partner == recipient && P.knot_size >= 2)
		var/zone_summary = islist(P.knot_zones) ? jointext(P.knot_zones, ", ") : "нет"
		to_chat(src, "Двойной узел: текущие зоны [zone_summary].")
	return TRUE

/client/proc/knot_debug_test(mob/living/carbon/human/H, as_recipient = FALSE, force = FALSE, preview_only = FALSE)
	var/mob/living/carbon/human/other = knot_debug_select_human(H)
	if(!other)
		return
	var/mob/living/carbon/human/pen_owner = as_recipient ? other : H
	var/mob/living/carbon/human/recipient = as_recipient ? H : other
	var/zone = knot_debug_select_zone()
	if(!zone || !knot_debug_preview(pen_owner, recipient, zone) || preview_only)
		return
	var/obj/item/organ/genital/penis/P = pen_owner.getorganslot(ORGAN_SLOT_PENIS)
	var/before_locked = P.knot_locked
	var/before_zones = islist(P.knot_zones) ? length(P.knot_zones) : 0
	var/succeeded = try_apply_knot(pen_owner, recipient, zone, force_override = force, force_knot = force || knot_debug_force_chance)
	if(succeeded)
		to_chat(src, span_notice("УСПЕХ: проверка выполнена реальным try_apply_knot(), эффекты и таймеры созданы стандартным путём."))
	else
		to_chat(src, span_warning("Узлирование не произошло. См. диагностику условий выше; при обычном тесте также возможен неуспешный бросок вероятности."))
	if(P.knot_locked != before_locked || (islist(P.knot_zones) && length(P.knot_zones) != before_zones))
		knot_debug_show_state(pen_owner)

/client/proc/knot_debug_release(mob/living/carbon/human/H, forceful = FALSE)
	var/obj/item/organ/genital/penis/P = H.active_knot
	if(!P || QDELETED(P))
		P = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!P || !P.knot_locked)
		to_chat(src, span_warning("У персонажа нет активной связи."))
		return
	if(QDELETED(P.owner) || QDELETED(P.knot_partner))
		P.cleanup_knot_state(P.owner, P.knot_partner)
		to_chat(src, span_warning("Удалённый участник: выполнена техническая очистка без эффектов."))
		return
	P.release_knot(P.owner, P.knot_partner, P.knot_state, forceful)
	to_chat(src, span_notice("Связь завершена через release_knot()."))

/client/proc/knot_debug_resist(mob/living/carbon/human/H, from_partner = FALSE)
	var/obj/item/organ/genital/penis/P = H.active_knot
	if(!P || QDELETED(P) || !P.knot_locked)
		to_chat(src, span_warning("Нет активного узла."))
		return
	var/mob/living/actor = from_partner ? P.knot_partner : H
	if(actor != P.owner && actor != P.knot_partner)
		to_chat(src, span_warning("Персонаж не является участником этого узла."))
		return
	P.start_resist_attempt(actor)

/client/proc/knot_debug_check_distance(mob/living/carbon/human/H)
	var/obj/item/organ/genital/penis/P = H.active_knot
	if(!P || QDELETED(P) || !P.knot_locked)
		to_chat(src, span_warning("Нет активного узла."))
		return
	to_chat(src, span_notice("Проверка настоящего расстояния. Если дистанция превышена, игровая механика может причинить урон."))
	P.check_knot_distance_safe(P.owner)

/client/proc/force_knot()
	set name = "Force Knot"
	set category = "Debug.7) Testing"
	set desc = "Диагностика узлирования и временные переключатели ERP-тестов."
	if(!check_rights(R_DEBUG))
		return
	var/list/actions = list(
		"Глобальный TEST bypass префов (админы и тестовые мобы, 15 мин)" = "prefs",
		"Переключить гарантированный бросок узлирования" = "roll",
		"Сбросить оба тестовых режима" = "reset"
	)
	var/mob/living/carbon/human/H = mob
	if(istype(H))
		actions += list(
			"Посмотреть состояние и mood" = "state",
			"Проверить шанс на ближайшем партнёре (без создания узла)" = "preview",
			"Обычная попытка (с шансом и префами)" = "normal",
			"Принудительная попытка через всю механику" = "forced",
			"Проверка со стороны принимающего партнёра" = "receiver",
			"Аккуратное освобождение" = "release",
			"Силовой разрыв" = "break",
			"Resist от персонажа" = "resist_self",
			"Resist от партнёра" = "resist_partner",
			"Проверить дистанцию (может нанести урон)" = "distance"
		)
	var/choice = input(mob, "TEST bypass действует глобально только на админов/тестовых мобов, не затрагивая обычных игроков. Автоотключение через 15 минут.", "Knot Debug") as null|anything in actions
	if(!choice)
		return
	if(!check_rights(R_DEBUG))
		return
	switch(actions[choice])
		if("prefs")
			if(knotting_debug_prefs_active())
				GLOB.knot_debug_ignore_prefs_until = 0
				GLOB.knot_debug_ignore_prefs_owner = null
			else
				GLOB.knot_debug_ignore_prefs_until = world.time + 15 MINUTES
				GLOB.knot_debug_ignore_prefs_owner = ckey
			var/status = knotting_debug_prefs_active() ? "ON" : "OFF"
			log_admin("[key_name(src)] set global knot preference TEST bypass [status].")
			message_admins("[key_name(src)] set global knot preference TEST bypass [status] (staff/test dummies only).")
			to_chat(src, span_notice("Global TEST bypass sexknotting: [status]."))
		if("roll")
			knot_debug_force_chance = !knot_debug_force_chance
			to_chat(src, span_notice("Debug guarantee knot chance: [knot_debug_force_chance]."))
		if("reset")
			GLOB.knot_debug_ignore_prefs_until = 0
			GLOB.knot_debug_ignore_prefs_owner = null
			knot_debug_force_chance = FALSE
			log_admin("[key_name(src)] reset global knot preference TEST bypass.")
			message_admins("[key_name(src)] reset global knot preference TEST bypass.")
			to_chat(src, span_notice("Тестовый обход префов отключён глобально; локальный принудительный шанс тоже сброшен."))
		if("state")
			knot_debug_show_state(H)
		if("preview")
			knot_debug_test(H, preview_only = TRUE)
		if("normal")
			knot_debug_test(H)
		if("forced")
			knot_debug_test(H, force = TRUE)
		if("receiver")
			knot_debug_test(H, as_recipient = TRUE, force = TRUE)
		if("release")
			knot_debug_release(H)
		if("break")
			knot_debug_release(H, forceful = TRUE)
		if("resist_self")
			knot_debug_resist(H)
		if("resist_partner")
			knot_debug_resist(H, from_partner = TRUE)
		if("distance")
			knot_debug_check_distance(H)
