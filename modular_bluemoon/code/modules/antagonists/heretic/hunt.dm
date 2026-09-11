GLOBAL_LIST_EMPTY(heretic_ritual_reservations)
GLOBAL_LIST_EMPTY(heretic_sacrificed_minds)

/datum/antagonist/heretic
	/// Душа цели сохраняется при клонировании и переселении в другое тело.
	var/datum/mind/hunt_target
	var/list/sacrificed_minds = list()
	var/influences_harvested = 0
	var/hunt_selection_open = FALSE
	COOLDOWN_DECLARE(hunt_refresh_cooldown)

/datum/antagonist/heretic/proc/clear_hunt()
	set_hunt_target(null)
	hunt_selection_open = FALSE
	sacrificed_minds.Cut()
	for(var/atom/ingredient in GLOB.heretic_ritual_reservations.Copy())
		var/obj/effect/eldritch/rune = GLOB.heretic_ritual_reservations[ingredient]
		if(rune?.ritual_user && rune.ritual_user.mind == owner)
			rune.ritual_interrupted = TRUE
			rune.release_atoms()

/datum/antagonist/heretic/proc/hunt_target_available(datum/mind/candidate, selecting = FALSE)
	if(QDELETED(candidate) || candidate == owner || (candidate in GLOB.heretic_sacrificed_minds))
		return FALSE
	var/mob/living/carbon/human/body = candidate.current
	if(!istype(body) || QDELETED(body) || body.stat == DEAD || IS_HERETIC(body) || IS_HERETIC_MONSTER(body) || candidate.is_ghost_role())
		return FALSE
	var/turf/body_turf = get_turf(body)
	if(!body_turf || !is_station_level(body_turf.z))
		return FALSE
	if(selecting && !body.client)
		return FALSE
	return TRUE

/datum/antagonist/heretic/proc/set_hunt_target(datum/mind/new_target)
	hunt_target = new_target
	sac_targetted.Cut()
	if(new_target?.current)
		GLOB.reality_smash_track.track_history_mind(new_target)
		sac_targetted += new_target.current.real_name
	refresh_book_ui()

/datum/antagonist/heretic/proc/ensure_hunt_target(mob/living/user, force_replace = FALSE)
	if(QDELETED(user) || user.mind != owner || !IS_HERETIC(user) || user.incapacitated() || hunt_selection_open)
		return FALSE
	if(hunt_target_available(hunt_target))
		if(!force_replace)
			return TRUE
		if(!COOLDOWN_FINISHED(src, hunt_refresh_cooldown))
			to_chat(user, span_warning("Сердце ещё помнит предыдущий зов. Сменить доступную цель можно раз в три минуты."))
			return FALSE
	var/datum/objective/crew_records = new
	var/list/candidates = list()
	for(var/datum/mind/candidate in crew_records.get_crewmember_minds())
		if(candidate != hunt_target && hunt_target_available(candidate, selecting = TRUE))
			candidates |= candidate
	qdel(crew_records)
	var/list/choices = list()
	while(length(candidates) && length(choices) < 3)
		var/datum/mind/candidate = pick_n_take(candidates)
		choices["[length(choices) + 1]. [candidate.current.real_name] — [candidate.assigned_role]"] = candidate
	if(!length(choices))
		to_chat(user, span_warning("Покровители не находят новой доступной цели на станции. Попробуйте позднее."))
		return FALSE
	hunt_selection_open = TRUE
	var/choice = tgui_input_list(user, "Кому предстоит увидеть Мансус? Цель можно принести без сознания: убивать её не требуется.", "Зов живого сердца", choices)
	hunt_selection_open = FALSE
	if(QDELETED(src) || QDELETED(user) || user.mind != owner || !IS_HERETIC(user) || user.incapacitated())
		return FALSE
	if(!choice)
		return FALSE
	var/datum/mind/chosen = choices[choice]
	if(!hunt_target_available(chosen, selecting = TRUE))
		return FALSE
	var/replacing_target = hunt_target_available(hunt_target)
	if(replacing_target)
		COOLDOWN_START(src, hunt_refresh_cooldown, 3 MINUTES)
	set_hunt_target(chosen)
	to_chat(user, span_notice("Сердце запомнило [chosen.current.real_name]. Принесите цель без сознания и своё живое сердце к руне, затем выберите «Обряд возвращения»."))
	return TRUE

/datum/antagonist/heretic/proc/select_hunt_atoms(mob/living/user, list/atoms, list/selected_atoms)
	if(user?.mind != owner || !hunt_target_available(hunt_target))
		return FALSE
	var/mob/living/carbon/human/victim = hunt_target.current
	if(!(victim in atoms) || victim.stat < UNCONSCIOUS)
		return FALSE
	for(var/obj/item/living_heart/heart in atoms)
		if(!heart.bind(owner))
			continue
		selected_atoms |= heart
		selected_atoms |= victim
		// Чужое сердце не может случайно выполнить требование рецепта.
		for(var/obj/item/living_heart/other_heart in atoms.Copy())
			if(other_heart != heart)
				atoms -= other_heart
		return TRUE
	return FALSE

/datum/antagonist/heretic/proc/complete_hunt_ritual(mob/living/user, list/selected_atoms, turf/ritual_turf)
	if(user?.mind != owner || !IS_HERETIC(user) || !hunt_target_available(hunt_target))
		return FALSE
	var/mob/living/carbon/human/victim = hunt_target.current
	var/turf/victim_turf = get_turf(victim)
	if(!ritual_turf || !(victim in selected_atoms) || victim.stat < UNCONSCIOUS || victim_turf?.z != ritual_turf.z || get_dist(victim, ritual_turf) > 1)
		return FALSE
	var/obj/item/living_heart/heart = locate() in selected_atoms
	if(!heart || heart.owner_mind != owner)
		return FALSE
	var/turf/return_turf = get_hunt_return_turf()
	if(!return_turf || !is_station_level(return_turf.z))
		to_chat(user, span_warning("Мансус не находит безопасного пути назад для жертвы. Ритуал прерван."))
		return FALSE
	var/datum/mind/soul = hunt_target
	var/datum/heretic_mansus_visit/visit = new
	if(!visit.prepare(victim, return_turf, ritual_turf))
		qdel(visit)
		to_chat(user, span_warning("Врата Мансуса не открылись. Подношение не принято."))
		return FALSE
	// Подготовка комнаты может уступить тик mapping: проверяем душу и обряд повторно.
	var/turf/user_turf = get_turf(user)
	var/turf/heart_turf = get_turf(heart)
	victim_turf = get_turf(victim)
	if(QDELETED(src) || QDELETED(user) || user.mind != owner || !IS_HERETIC(user) || user.incapacitated() || user_turf?.z != ritual_turf.z || get_dist(user, ritual_turf) > 1)
		qdel(visit)
		return FALSE
	if(hunt_target != soul || !hunt_target_available(soul) || victim.mind != soul || victim.stat < UNCONSCIOUS || victim_turf?.z != ritual_turf.z || get_dist(victim, ritual_turf) > 1)
		qdel(visit)
		return FALSE
	if(QDELETED(heart) || heart.owner_mind != owner || heart_turf?.z != ritual_turf.z || get_dist(heart, ritual_turf) > 1)
		qdel(visit)
		return FALSE
	var/datum/eldritch_knowledge/spell/basic/ritual = get_knowledge(/datum/eldritch_knowledge/spell/basic)
	if(!ritual?.ritual_still_valid(user, selected_atoms, ritual_turf))
		qdel(visit)
		return FALSE
	if(!visit.start())
		qdel(visit)
		return FALSE
	GLOB.heretic_sacrificed_minds |= soul
	sacrificed_minds |= soul
	actually_sacced += victim.real_name
	total_sacrifices++
	if(total_sacrifices >= HERETIC_THREAT_SACRIFICES)
		announce_threat()
	knowledge_points += 2
	side_knowledge_points++
	set_hunt_target(null)
	for(var/datum/antagonist/heretic/other_heretic in GLOB.antagonists)
		if(other_heretic.hunt_target == soul)
			other_heretic.set_hunt_target(null)
	user.log_message("принёс [key_name(victim)] в жертву Мансусу", LOG_ATTACK)
	to_chat(user, span_notice("Мансус принял подношение. Жертва пройдёт через Дом и вернётся на станцию меньше чем через минуту. Вы получили 2 очка знаний и 1 очко побочных знаний. Сердце готово выбрать следующую цель."))
	return TRUE

/datum/antagonist/heretic/proc/get_hunt_return_turf()
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return null
	return find_safe_turf(zlevels = station_levels, extended_safety_checks = TRUE, dense_atoms = FALSE)
