#define HERETIC_STATION_TURF_ATTEMPTS 30
#define HERETIC_HUNT_CHOICES 3

GLOBAL_LIST_EMPTY(heretic_ritual_reservations)
GLOBAL_LIST_EMPTY(heretic_sacrificed_minds)

/obj/effect/proc_holder/spell/self/heretic_summon/heart
	desc = "Призывает или прячет своё живое сердце. Если оно потеряно, стойте неподвижно 5 секунд, чтобы вернуть его; уничтоженное сердце восстановится. Сердце в чужих руках или рюкзаке и сердце действующего обряда вернуть нельзя."
	var/recovery_in_progress = FALSE

/obj/effect/proc_holder/spell/self/heretic_summon/heart/can_cast(mob/user, skipcharge, silent)
	return heretic_check(user, !recovery_in_progress, silent, "Возвращение сердца уже началось. Стойте неподвижно до его завершения.") && ..()

/obj/effect/proc_holder/spell/self/heretic_summon/heart/can_summon_item(obj/item/item, mob/user)
	if(!..())
		return FALSE
	var/obj/item/living_heart/heart = item
	return heart.bind(user.mind)

/obj/effect/proc_holder/spell/self/heretic_summon/heart/recover_missing_item(mob/living/user, datum/antagonist/heretic/heretic)
	if(recovery_in_progress)
		return TRUE
	if(!recovery_allowed(user, heretic))
		revert_cast(user)
		return TRUE
	recovery_in_progress = TRUE
	to_chat(user, span_notice("Вы зовёте потерянное сердце. Не двигайтесь 5 секунд."))
	var/completed = do_after(user, 5 SECONDS, target = user)
	if(QDELETED(src))
		return TRUE
	recovery_in_progress = FALSE
	if(!completed || !recovery_allowed(user, heretic))
		revert_cast(user)
		return TRUE
	var/obj/item/living_heart/heart
	for(var/obj/item/living_heart/candidate as anything in GLOB.living_heart_cache)
		if(!QDELETED(candidate) && candidate.owner_mind == heretic.owner)
			heart = candidate
			break
	if(!heart)
		heart = new(null)
		heart.bind(heretic.owner)
	hide_item(heart, heretic)
	if(summon_item(heart, user))
		heretic.summon_items -= heart
		to_chat(user, span_notice("Живое сердце вернулось. Цель охоты сохранена."))
	else
		to_chat(user, span_notice("Сердце ждёт за завесой. Освободите руку и призовите его снова."))
	log_game("[key_name(user)] восстанавливает потерянное живое сердце в [AREACOORD(user)].")
	return TRUE

/obj/effect/proc_holder/spell/self/heretic_summon/heart/proc/recovery_allowed(mob/living/user, datum/antagonist/heretic/heretic)
	if(QDELETED(user) || QDELETED(heretic) || heretic.role_removed || IS_HERETIC(user) != heretic || heretic.owner?.current != user || user.incapacitated() || !(src in user.mind.spell_list))
		return FALSE
	for(var/obj/item/living_heart/heart as anything in GLOB.living_heart_cache)
		if(QDELETED(heart) || heart.owner_mind != heretic.owner)
			continue
		var/atom/movable/holder = get_atom_on_turf(heart, /mob)
		if(GLOB.heretic_ritual_reservations[heart] || (ismob(holder) && holder != user))
			to_chat(user, span_warning("Сердце удерживает чужая рука или действующий обряд. Сначала освободите его."))
			return FALSE
	return TRUE

/datum/status_effect/incapacitating/paralyzed/heretic_ritual
	status_type = STATUS_EFFECT_MULTIPLE
	duration = -1
	tick_interval = -1

/datum/antagonist/heretic
	/// Душа цели сохраняется при клонировании и переселении в другое тело.
	var/datum/mind/hunt_target
	var/list/hunt_candidates = list()
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
	return !hunt_target_unavailable_reason(candidate, selecting)

/datum/antagonist/heretic/proc/hunt_target_unavailable_reason(datum/mind/candidate, selecting = FALSE)
	if(QDELETED(candidate))
		return "Цель охоты не назначена или её душа больше недоступна. Выберите новую цель через живое сердце."
	if(candidate == owner)
		return "Собственная душа не подходит для подношения."
	if(candidate in GLOB.heretic_sacrificed_minds)
		return "Эта душа уже принята Мансусом. Выберите новую цель через живое сердце."
	var/mob/living/carbon/human/body = candidate.current
	if(QDELETED(body) || !istype(body))
		return "У назначенной души нет подходящего человеческого тела."
	if(body.mind != candidate)
		return "Связь назначенной души с телом нарушена. Повторите попытку после завершения смены тела."
	if(IS_HERETIC(body) || IS_HERETIC_MONSTER(body))
		return "Назначенная цель сама служит Мансусу и не подходит для подношения."
	if(candidate.is_ghost_role())
		return "Назначенная душа перешла в роль вне экипажа станции. Выберите новую цель."
	var/turf/body_turf = get_turf(body)
	if(!body_turf || !is_station_level(body_turf.z))
		return "Тело назначенной цели находится вне станции. Верните его на станцию или выберите другую цель."
	if(selecting && body.stat == DEAD)
		return "Погибшего нельзя назначить новой целью. Труп уже назначенной цели принимается."
	if(selecting && !body.client)
		return "Для нового назначения нужен игрок в теле цели. Уже назначенная цель сохраняется после выхода в призрака."
	return null

/datum/antagonist/heretic/proc/set_hunt_target(datum/mind/new_target)
	hunt_target = new_target
	hunt_candidates.Cut()
	if(new_target?.current)
		if(!simulated)
			GLOB.reality_smash_track.track_history_mind(new_target)
		sac_targetted[REF(new_target)] = new_target.current.real_name
		log_game("[key_name(owner)] получает цель охоты: [key_name(new_target)].")
	refresh_book_ui()

/datum/antagonist/heretic/proc/hunt_target_ready(mob/living/carbon/human/victim)
	if(!istype(victim) || QDELETED(victim))
		return FALSE
	return victim.stat >= SOFT_CRIT || victim.handcuffed || victim.body_position == LYING_DOWN || victim.IsStun() || victim.IsParalyzed()

/datum/antagonist/heretic/proc/prepare_hunt_choices()
	var/datum/objective/crew_records = new
	var/list/available_candidates = list()
	for(var/datum/mind/candidate in crew_records.get_crewmember_minds())
		if(candidate != hunt_target && hunt_target_available(candidate, selecting = TRUE))
			available_candidates |= candidate
	qdel(crew_records)
	for(var/datum/weakref/candidate_ref as anything in hunt_candidates.Copy())
		var/datum/mind/candidate = candidate_ref.resolve()
		if(!(candidate in available_candidates))
			hunt_candidates -= candidate_ref
		else
			available_candidates -= candidate
	while(length(available_candidates) && length(hunt_candidates) < HERETIC_HUNT_CHOICES)
		var/datum/mind/candidate = pick_n_take(available_candidates)
		hunt_candidates += WEAKREF(candidate)
	var/list/choices = list()
	for(var/datum/weakref/candidate_ref as anything in hunt_candidates)
		var/datum/mind/candidate = candidate_ref.resolve()
		choices["[length(choices) + 1]. [candidate.current.real_name] — [candidate.assigned_role]"] = candidate_ref
	return choices

/datum/antagonist/heretic/proc/prompt_hunt_target(mob/living/user, list/choices)
	return tgui_input_list(user, "Кому предстоит увидеть Мансус? Живую цель достаточно связать, оглушить или сбить с ног рядом с руной. Цель в крите принимается без наручников.", "Зов живого сердца", choices)

/datum/antagonist/heretic/proc/ensure_hunt_target(mob/living/user, force_replace = FALSE)
	if(role_removed || QDELETED(user) || user.mind != owner || !IS_HERETIC(user) || user.incapacitated() || hunt_selection_open)
		return FALSE
	if(hunt_target_available(hunt_target))
		if(!force_replace)
			return TRUE
		if(!COOLDOWN_FINISHED(src, hunt_refresh_cooldown))
			to_chat(user, span_warning("Сердце ещё помнит предыдущий зов. Сменить доступную цель можно раз в три минуты."))
			return FALSE
	var/list/choices = prepare_hunt_choices()
	if(!length(choices))
		to_chat(user, span_warning("Покровители не находят новой доступной цели на станции. Попробуйте позднее."))
		return FALSE
	hunt_selection_open = TRUE
	var/choice = prompt_hunt_target(user, choices)
	hunt_selection_open = FALSE
	if(QDELETED(src) || role_removed || QDELETED(user) || user.mind != owner || !IS_HERETIC(user) || user.incapacitated())
		return FALSE
	if(!choice)
		return FALSE
	var/datum/weakref/chosen_ref = choices[choice]
	var/datum/mind/chosen = chosen_ref?.resolve()
	if(!(chosen_ref in hunt_candidates) || !hunt_target_available(chosen, selecting = TRUE))
		return FALSE
	var/replacing_target = hunt_target_available(hunt_target)
	if(replacing_target)
		COOLDOWN_START(src, hunt_refresh_cooldown, 3 MINUTES)
	set_hunt_target(chosen)
	to_chat(user, span_notice("Сердце запомнило [chosen.current.real_name]. Доставьте живую цель к руне: подойдут наручники, оглушение, положение лёжа или потеря сознания. Цель в крите принимается без наручников, даже если ещё стоит. Если цель погибнет, её труп тоже примут, но лишь за 1 очко знаний без побочного. Положите рядом своё живое сердце и выберите «Обряд возвращения»."))
	return TRUE

/datum/antagonist/heretic/proc/select_hunt_atoms(mob/living/user, list/atoms, list/selected_atoms)
	if(user?.mind != owner || !hunt_target_available(hunt_target))
		return FALSE
	var/mob/living/carbon/human/victim = hunt_target.current
	if(!(victim in atoms) || !hunt_target_ready(victim))
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
	if(!ritual_turf || !(victim in selected_atoms) || !hunt_target_ready(victim) || victim_turf?.z != ritual_turf.z || get_dist(victim, ritual_turf) > 1)
		return FALSE
	var/obj/item/living_heart/heart = locate() in selected_atoms
	if(!heart || heart.owner_mind != owner)
		return FALSE
	var/datum/mind/soul = hunt_target
	var/corpse_sacrifice = victim.stat == DEAD
	var/datum/heretic_mansus_visit/visit
	if(!corpse_sacrifice && !simulated)
		var/turf/return_turf = get_hunt_return_turf()
		if(!return_turf || !is_station_level(return_turf.z))
			to_chat(user, span_warning("Мансус не находит безопасного пути назад для жертвы. Ритуал прерван."))
			return FALSE
		visit = new
		if(!visit.prepare(victim, return_turf, ritual_turf, selected_path))
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
	if(hunt_target != soul || !hunt_target_available(soul) || victim.mind != soul || !hunt_target_ready(victim) || (victim.stat == DEAD) != corpse_sacrifice || victim_turf?.z != ritual_turf.z || get_dist(victim, ritual_turf) > 1)
		qdel(visit)
		return FALSE
	if(QDELETED(heart) || heart.owner_mind != owner || heart_turf?.z != ritual_turf.z || get_dist(heart, ritual_turf) > 1)
		qdel(visit)
		return FALSE
	var/datum/eldritch_knowledge/spell/basic/ritual = get_knowledge(/datum/eldritch_knowledge/spell/basic)
	if(!ritual?.ritual_still_valid(user, selected_atoms, ritual_turf))
		qdel(visit)
		return FALSE
	if(visit && !visit.start())
		qdel(visit)
		return FALSE
	if(!simulated)
		GLOB.heretic_sacrificed_minds |= soul
	sacrificed_minds |= soul
	sac_targetted -= REF(soul)
	actually_sacced += victim.real_name
	total_sacrifices++
	log_game("[key_name(owner)] приносит в жертву [key_name(victim)] ([corpse_sacrifice ? "труп" : "живьём"], всего [total_sacrifices]) в [AREACOORD(ritual_turf)].")
	if(total_sacrifices >= HERETIC_THREAT_SACRIFICES)
		announce_threat()
	knowledge_points += corpse_sacrifice ? HERETIC_DEAD_SACRIFICE_KNOWLEDGE : HERETIC_LIVE_SACRIFICE_KNOWLEDGE
	if(!corpse_sacrifice)
		side_knowledge_points += HERETIC_LIVE_SACRIFICE_SIDE_KNOWLEDGE
	set_hunt_target(null)
	for(var/datum/antagonist/heretic/other_heretic in GLOB.antagonists)
		if(!simulated && other_heretic.hunt_target == soul)
			other_heretic.set_hunt_target(null)
			to_chat(other_heretic.owner, span_warning("Назначенная вам душа уже принята Мансусом. Живое сердце готово выбрать новую цель."))
	if(simulated)
		to_chat(user, span_notice("Учебное подношение принято. Очки начислены по обычным правилам; манекен остаётся на полигоне."))
	else if(corpse_sacrifice)
		user.log_message("принёс труп [key_name(victim)] в жертву Мансусу", LOG_ATTACK)
		to_chat(user, span_notice("Мансус принял угасшую душу. Жертвоприношение засчитано: вы получили 1 очко знаний без побочного. Тело остаётся на месте; его ещё можно реанимировать. Сердце готово выбрать следующую цель."))
	else
		user.log_message("принёс [key_name(victim)] в жертву Мансусу", LOG_ATTACK)
		to_chat(user, span_notice("Мансус принял подношение. Жертва пройдёт испытание Дома памяти: ей нужно доставить к вратам шесть осколков, избегая тени и разломов. Через две с половиной минуты Дом отпустит её сам. Вы получили 2 очка знаний и 1 очко побочных знаний. Сердце готово выбрать следующую цель."))
	return TRUE

/datum/antagonist/heretic/proc/get_hunt_return_turf()
	return find_heretic_station_turf()

/proc/find_heretic_station_turf(for_escape = FALSE)
	if(!length(GLOB.the_station_areas))
		return null
	for(var/attempt in 1 to HERETIC_STATION_TURF_ATTEMPTS)
		var/turf/destination = get_safe_random_station_turf()
		var/area/destination_area = get_area(destination)
		if(!destination || !is_station_level(destination.z) || destination_area.area_flags & NOTELEPORT || !is_safe_turf(destination))
			continue
		if(for_escape && (istype(destination_area, /area/security) || istype(destination_area, /area/command) || istype(destination_area, /area/ai_monitored)))
			continue
		return destination
	return null

#undef HERETIC_STATION_TURF_ATTEMPTS
#undef HERETIC_HUNT_CHOICES
