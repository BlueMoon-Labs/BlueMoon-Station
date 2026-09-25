#define HERETIC_STATION_TURF_ATTEMPTS 30
#define HERETIC_HUNT_CHOICES 3

GLOBAL_LIST_EMPTY(heretic_ritual_reservations)
GLOBAL_LIST_EMPTY(heretic_sacrificed_minds)

/obj/effect/proc_holder/spell/self/heretic_summon/heart
	desc = "Призывает или прячет своё живое сердце. Потерянное сердце возвращается, если 5 секунд стоять на месте."
	summary = "Достаёт или прячет живое сердце."
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
			to_chat(user, span_warning("Сердце сейчас в чужой руке или в идущем обряде. Сначала освободите его."))
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
	var/datum/weakref/watched_hunt_body
	var/hunt_assigned_at = 0
	var/hunt_stale_hinted = FALSE
	COOLDOWN_DECLARE(hunt_refresh_cooldown)
	COOLDOWN_DECLARE(hunt_downed_alert_cooldown)
	COOLDOWN_DECLARE(hunt_claim_hint_cooldown)

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
		return "У назначенной души нет подходящего человеческого тела. Выберите новую цель через живое сердце или кодекс: ждать перезарядки не нужно."
	if(body.mind != candidate)
		return "Связь назначенной души с телом нарушена. Повторите попытку после завершения смены тела."
	if(IS_HERETIC(body) || IS_HERETIC_MONSTER(body))
		return "Назначенная цель сама служит Мансусу и не подходит для подношения. Выберите новую цель через живое сердце или кодекс: ждать перезарядки не нужно."
	if(candidate.is_ghost_role())
		return "Назначенная душа перешла в роль вне экипажа станции. Выберите новую цель."
	var/turf/body_turf = heretic_pocket_anchor(get_turf(body))
	if(!body_turf || !is_station_level(body_turf.z))
		return "Тело назначенной цели находится вне станции. Верните его на станцию или выберите другую цель."
	if(selecting && body.stat == DEAD)
		return "Погибшего нельзя назначить новой целью. Труп уже назначенной цели принимается."
	if(selecting && !body.client)
		return "Для нового назначения нужен игрок в теле цели. Уже назначенная цель сохраняется после выхода в призрака."
	return null

/datum/antagonist/heretic/proc/set_hunt_target(datum/mind/new_target)
	if(hunt_target)
		UnregisterSignal(hunt_target, COMSIG_MIND_TRANSFER)
	unwatch_hunt_body()
	hunt_target = new_target
	hunt_candidates.Cut()
	hunt_assigned_at = world.time
	hunt_stale_hinted = FALSE
	if(new_target)
		RegisterSignal(new_target, COMSIG_MIND_TRANSFER, PROC_REF(on_hunt_target_transferred))
		watch_hunt_body(new_target.current)
	if(new_target?.current)
		if(!simulated)
			GLOB.reality_smash_track.track_history_mind(new_target)
		sac_targetted[REF(new_target)] = new_target.current.real_name
		log_game("[key_name(owner)] получает цель охоты: [key_name(new_target)].")
	refresh_book_ui()

/datum/antagonist/heretic/proc/watch_hunt_body(mob/living/body)
	unwatch_hunt_body()
	if(QDELETED(body))
		return
	watched_hunt_body = WEAKREF(body)
	RegisterSignal(body, COMSIG_MOB_STATCHANGE, PROC_REF(on_hunt_body_stat_change))

/datum/antagonist/heretic/proc/unwatch_hunt_body()
	var/mob/living/body = watched_hunt_body?.resolve()
	if(body)
		UnregisterSignal(body, COMSIG_MOB_STATCHANGE)
	watched_hunt_body = null

/datum/antagonist/heretic/proc/on_hunt_target_transferred(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	watch_hunt_body(new_character)

/datum/antagonist/heretic/proc/on_hunt_body_stat_change(mob/living/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(role_removed || new_stat < SOFT_CRIT || old_stat >= SOFT_CRIT || source.mind != hunt_target)
		return
	var/mob/living/user = owner?.current
	if(!user || user.stat == DEAD)
		return
	var/turf/user_turf = get_turf(user)
	var/turf/body_turf = get_turf(source)
	if(!user_turf || !body_turf || user_turf.z != body_turf.z || get_dist(user_turf, body_turf) > HERETIC_HUNT_DOWNED_ALERT_RANGE)
		return
	if(!COOLDOWN_FINISHED(src, hunt_downed_alert_cooldown))
		return
	COOLDOWN_START(src, hunt_downed_alert_cooldown, HERETIC_HUNT_DOWNED_ALERT_COOLDOWN)
	SEND_SOUND(user, sound('modular_bluemoon/sound/heretic/heart_track.ogg', volume = 50))
	source.balloon_alert(user, new_stat == DEAD ? "цель погибла" : "цель повержена")
	if(new_stat == DEAD)
		to_chat(user, span_boldwarning("Цель охоты [source.real_name] погибла. Труп ещё примут, но лишь за 1 очко знаний без побочного: коснитесь его живым сердцем или принесите на руну."))
	else
		to_chat(user, span_boldnotice("Цель охоты [source.real_name] повержена. Коснитесь её живым сердцем: круг проступит прямо под телом, обряд займёт [DisplayTimeText(heart_rite_time(source), 1)]. Можно и перенести её на руну. Если у пути есть дверь, сердце предложит увести цель в изнанку. Живая жертва даёт 2 очка знаний и 1 побочное."))

/// Длина обряда сердцем на месте цели: с Течением часа и скоростью действий еретика.
/datum/antagonist/heretic/proc/heart_rite_time(atom/place)
	var/datum/eldritch_knowledge/spell/basic/ritual = get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/mob/living/user = owner?.current
	var/base_time = ritual?.ritual_time
	if(isnull(base_time))
		var/datum/eldritch_knowledge/spell/basic/ritual_type = /datum/eldritch_knowledge/spell/basic
		base_time = initial(ritual_type.ritual_time)
	return base_time * heretic_ritual_speed_multiplier(user, place) * (user ? user.cached_multiplicative_actions_slowdown : 1)

/datum/antagonist/heretic/proc/claim_is_crew_player(mob/living/carbon/human/victim)
	if(!victim.client)
		return FALSE
	var/datum/objective/crew_records = new
	. = (victim.mind in crew_records.get_crewmember_minds())
	qdel(crew_records)

/datum/antagonist/heretic/proc/claim_refusal_reason(mob/living/carbon/human/victim)
	if(!istype(victim))
		return "Сердце принимает только людей."
	var/datum/mind/soul = victim.mind
	if(!soul)
		return "В этом теле нет души, которую мог бы принять Мансус."
	var/reason = hunt_target_unavailable_reason(soul)
	if(reason)
		return reason
	if(victim.stat == DEAD)
		return "Мёртвого сердце не принимает: новой целью может стать только живой."
	if(!hunt_target_ready(victim))
		return "Цель ещё сопротивляется. Сердце принимает поверженного: в крите, без сознания, связанного, оглушённого или сбитого с ног. Добровольно лёгший или уснувший не считается."
	if(!claim_is_crew_player(victim))
		return "Сердце принимает только членов экипажа станции с игроком в теле."
	return null

/// Поверженный член экипажа становится целью охоты от касания живым сердцем.
/datum/antagonist/heretic/proc/claim_hunt_target(mob/living/user, mob/living/carbon/human/victim)
	if(role_removed || QDELETED(user) || user.mind != owner || user.incapacitated() || hunt_selection_open || QDELETED(victim))
		return FALSE
	if(victim.mind && victim.mind == hunt_target)
		to_chat(user, span_notice("Сердце уже бьётся в такт этой душе. Обезвредьте цель и коснитесь её сердцем или перенесите на руну."))
		return FALSE
	var/reason = claim_refusal_reason(victim)
	if(reason)
		victim.balloon_alert(user, "сердце молчит")
		to_chat(user, span_warning(reason))
		return FALSE
	if(!COOLDOWN_FINISHED(src, hunt_refresh_cooldown))
		to_chat(user, span_warning("Сердце ещё помнит прошлый зов. Сменить цель можно через [DisplayTimeText(COOLDOWN_TIMELEFT(src, hunt_refresh_cooldown))]."))
		return FALSE
	COOLDOWN_START(src, hunt_refresh_cooldown, HERETIC_HUNT_REFRESH_COOLDOWN)
	set_hunt_target(victim.mind)
	playsound(user, 'modular_bluemoon/sound/heretic/heart_track.ogg', 40, FALSE, extrarange = SILENCED_SOUND_EXTRARANGE)
	victim.balloon_alert(user, "новая цель")
	to_chat(user, span_boldnotice("Сердце принимает [victim.real_name]. Коснитесь цели сердцем ещё раз, чтобы провести обряд прямо здесь, или перенесите её на руну. Следующая смена цели - через [DisplayTimeText(HERETIC_HUNT_REFRESH_COOLDOWN)]."))
	return TRUE

/obj/effect/eldritch/big/heart_rite
	name = "Mansus circle"
	desc = "Круг знаков проступил прямо под телом. Смола ещё шевелится."

/// Обряд возвращения без начерченной руны: круг проступает под поверженной целью, канал тот же, что на руне.
/datum/antagonist/heretic/proc/begin_heart_rite(mob/living/user, mob/living/carbon/human/victim, obj/item/living_heart/heart)
	if(role_removed || QDELETED(user) || user.mind != owner || user.incapacitated() || QDELETED(victim) || QDELETED(heart) || !user.is_holding(heart))
		return FALSE
	var/datum/eldritch_knowledge/spell/basic/ritual = get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/reason = heretic_containment_reason(user) || heart_rite_refusal_reason(victim, ritual)
	if(reason)
		victim.balloon_alert(user, "сердце молчит")
		to_chat(user, span_warning(reason))
		return FALSE
	var/turf/rite_turf = get_turf(victim)
	if(!user.transferItemToLoc(heart, rite_turf))
		return FALSE
	var/obj/effect/eldritch/big/heart_rite/circle = new(rite_turf)
	circle.is_in_use = TRUE
	user.visible_message(span_danger("[user] опускает бьющееся сердце на [victim], и под телом проступает круг знаков!"), span_notice("Вы опускаете живое сердце на [victim]. Мансус чертит круг прямо под телом."))
	log_game("[key_name(user)] проводит обряд живым сердцем над [key_name(victim)] в [AREACOORD(rite_turf)].")
	. = circle.do_ritual(user, ritual)
	if(!QDELETED(heart) && isturf(heart.loc) && !user.incapacitated() && user.Adjacent(heart))
		user.put_in_hands(heart)
	if(!QDELETED(circle))
		qdel(circle)

/datum/antagonist/heretic/proc/heart_rite_refusal_reason(mob/living/carbon/human/victim, datum/eldritch_knowledge/spell/basic/ritual)
	if(!ritual)
		return "Обряд возвращения не изучен."
	var/reason = hunt_target_unavailable_reason(hunt_target)
	if(reason)
		return reason
	if(victim.mind != hunt_target)
		return "Обряд сердцем проводится только над назначенной целью охоты."
	if(!hunt_target_ready(victim))
		return "Цель ещё сопротивляется: свяжите её наручниками, оглушите или сбейте с ног. Цель в крите принимается без наручников."
	var/turf/rite_turf = get_turf(victim)
	if(!isturf(victim.loc) || !isopenturf(rite_turf) || isspaceturf(rite_turf))
		return "Под целью нужен пол: в шкафу или в космосе круг не проступит."
	if(GLOB.heretic_ritual_reservations[victim])
		return "Над целью уже идёт другой обряд."
	return null

/datum/antagonist/heretic/proc/hint_hunt_claim(mob/living/user, mob/living/victim)
	if(!ishuman(victim) || victim.stat == DEAD || !COOLDOWN_FINISHED(src, hunt_claim_hint_cooldown) || !hunt_target_ready(victim))
		return
	if(victim.mind && victim.mind == hunt_target)
		COOLDOWN_START(src, hunt_claim_hint_cooldown, HERETIC_HUNT_CLAIM_HINT_COOLDOWN)
		to_chat(user, span_notice("Цель охоты обезврежена. Коснитесь её живым сердцем, чтобы провести обряд прямо здесь, или несите на руну."))
		return
	if(claim_refusal_reason(victim))
		return
	COOLDOWN_START(src, hunt_claim_hint_cooldown, HERETIC_HUNT_CLAIM_HINT_COOLDOWN)
	if(COOLDOWN_FINISHED(src, hunt_refresh_cooldown))
		to_chat(user, span_notice("[victim.real_name] повержен. Коснитесь его живым сердцем, чтобы сделать новой целью охоты."))
	else
		to_chat(user, span_notice("[victim.real_name] повержен. Сердце сможет принять его целью через [DisplayTimeText(COOLDOWN_TIMELEFT(src, hunt_refresh_cooldown))]."))

/mob/living
	var/knocked_to_floor = FALSE
	/// До этого момента сон считается добровольным: глагол сна или эмоция обморока.
	var/voluntary_sleep_until = 0

/mob/living/KnockToFloor(disarm_items = FALSE, silent = TRUE, updating = TRUE)
	. = ..()
	if(resting)
		knocked_to_floor = TRUE

/mob/living/set_resting(new_resting, silent = FALSE, updating = TRUE)
	. = ..()
	if(!resting)
		knocked_to_floor = FALSE

/datum/antagonist/heretic/proc/hunt_target_ready(mob/living/carbon/human/victim)
	if(!istype(victim) || QDELETED(victim))
		return FALSE
	if(victim.stat == DEAD || victim.handcuffed || victim.IsStun() || victim.IsParalyzed() || victim.IsUnconscious() || heretic_capture_downed(victim) || (victim.IsSleeping() && world.time >= victim.voluntary_sleep_until))
		return TRUE
	// Сон по своей воле тоже даёт UNCONSCIOUS, поэтому в нём считается только настоящий крит.
	return victim.stat >= SOFT_CRIT && victim.health <= victim.crit_threshold

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
	for(var/list/role_group in list(GLOB.command_positions, GLOB.security_positions))
		if(length(hunt_candidates) >= HERETIC_HUNT_CHOICES || hunt_candidates_include_role(role_group))
			continue
		var/list/role_candidates = list()
		for(var/datum/mind/candidate as anything in available_candidates)
			if(candidate.assigned_role in role_group)
				role_candidates += candidate
		if(!length(role_candidates))
			continue
		var/datum/mind/role_pick = pick(role_candidates)
		available_candidates -= role_pick
		hunt_candidates += WEAKREF(role_pick)
	while(length(available_candidates) && length(hunt_candidates) < HERETIC_HUNT_CHOICES)
		var/datum/mind/candidate = pick_n_take(available_candidates)
		hunt_candidates += WEAKREF(candidate)
	var/list/choices = list()
	for(var/datum/weakref/candidate_ref as anything in hunt_candidates)
		var/datum/mind/candidate = candidate_ref.resolve()
		choices["[length(choices) + 1]. [candidate.current.real_name] - [candidate.assigned_role]"] = candidate_ref
	return choices

/datum/antagonist/heretic/proc/hunt_candidates_include_role(list/role_group)
	for(var/datum/weakref/candidate_ref as anything in hunt_candidates)
		var/datum/mind/candidate = candidate_ref.resolve()
		if(candidate?.assigned_role in role_group)
			return TRUE
	return FALSE

/datum/antagonist/heretic/proc/prompt_hunt_target(mob/living/user, list/choices)
	return tgui_input_list(user, "Кому предстоит увидеть Мансус? Живую цель достаточно связать, оглушить или сбить с ног, а затем коснуться живым сердцем. Цель в крите принимается без наручников.", "Зов живого сердца", choices)

/// Строка под поиском цели: ссылка на смену или время до неё.
/datum/antagonist/heretic/proc/retarget_hint(obj/item/living_heart/heart)
	if(!COOLDOWN_FINISHED(src, hunt_refresh_cooldown))
		return "Сменить цель можно через [DisplayTimeText(COOLDOWN_TIMELEFT(src, hunt_refresh_cooldown))]."
	return "<a href='byond://?src=[REF(heart)];retarget=1'>Сменить цель</a> (или Alt+ЛКМ по сердцу, или кнопка в кодексе)."

/datum/antagonist/heretic/proc/ensure_hunt_target(mob/living/user, force_replace = FALSE)
	if(role_removed || QDELETED(user) || user.mind != owner || !IS_HERETIC(user) || user.incapacitated() || hunt_selection_open)
		return FALSE
	if(hunt_target_available(hunt_target))
		if(!force_replace)
			return TRUE
		if(!COOLDOWN_FINISHED(src, hunt_refresh_cooldown))
			to_chat(user, span_warning("Сердце ещё помнит предыдущий зов. Сменить доступную цель можно через [DisplayTimeText(COOLDOWN_TIMELEFT(src, hunt_refresh_cooldown))]."))
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
		COOLDOWN_START(src, hunt_refresh_cooldown, HERETIC_HUNT_REFRESH_COOLDOWN)
	set_hunt_target(chosen)
	to_chat(user, span_notice("Сердце запомнило [chosen.current.real_name]. Обезвредьте цель: подойдут наручники, оглушение, сбивание с ног или потеря сознания. Добровольно лёгший или уснувший не считается. Цель в крите принимается без наручников, даже если ещё стоит. Затем коснитесь её живым сердцем, и круг проступит прямо под телом, или положите сердце рядом с ней на руне и выберите «Обряд возвращения». Если цель погибнет, её труп тоже примут, но лишь за 1 очко знаний без побочного."))
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
		if(!visit.prepare(victim, return_turf, heretic_pocket_anchor(ritual_turf), selected_path))
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
		to_chat(user, span_notice("Мансус принял подношение. Жертва пройдёт испытание Дома памяти: в лабиринте комнат, где действует особое правило вашего пути, ей нужно доставить три осколка на печать перед вратами, избегая тени и разломов. Через три минуты Дом отпустит её сам. Вы получили 2 очка знаний и 1 очко побочных знаний. Сердце готово выбрать следующую цель."))
	return TRUE

/datum/antagonist/heretic/proc/get_hunt_return_turf()
	return find_heretic_hallway_turf() || find_heretic_station_turf(for_escape = TRUE) || find_heretic_station_turf()

/proc/find_heretic_hallway_turf()
	var/list/hallways = list()
	for(var/area/hallway/hallway in GLOB.sortedAreas)
		if(!(hallway.area_flags & NOTELEPORT) && (hallway.type in GLOB.the_station_areas))
			hallways += hallway
	while(length(hallways))
		var/list/floors = get_area_turfs(pick_n_take(hallways))
		for(var/attempt in 1 to HERETIC_STATION_TURF_ATTEMPTS)
			if(!length(floors))
				break
			var/turf/destination = pick_n_take(floors)
			if(isopenturf(destination) && is_station_level(destination.z) && is_safe_turf(destination))
				return destination
	return null

/proc/is_heretic_escape_area(area/destination_area)
	var/static/list/escape_area_blacklist = typecacheof(list(
		/area/security,
		/area/command,
		/area/ai_monitored,
		/area/maintenance/prison,
		/area/maintenance/department/security,
	))
	return destination_area && !(destination_area.area_flags & NOTELEPORT) && !is_type_in_typecache(destination_area, escape_area_blacklist)

/proc/find_heretic_station_turf(for_escape = FALSE)
	if(!length(GLOB.the_station_areas))
		return null
	for(var/attempt in 1 to HERETIC_STATION_TURF_ATTEMPTS)
		var/turf/destination = get_safe_random_station_turf()
		var/area/destination_area = get_area(destination)
		if(!destination || !is_station_level(destination.z) || destination_area.area_flags & NOTELEPORT || !is_safe_turf(destination))
			continue
		if(for_escape && !is_heretic_escape_area(destination_area))
			continue
		return destination
	return null

/// После неудачной случайной выборки проверяем оставшиеся зоны без повторений.
/proc/find_heretic_escape_fallback(turf/origin)
	if(!origin)
		return null
	var/on_station = is_station_level(origin.z)
	var/list/areas = GLOB.sortedAreas.Copy()
	while(length(areas))
		CHECK_TICK
		var/area/destination_area = pick_n_take(areas)
		if(!is_heretic_escape_area(destination_area))
			continue
		if(on_station && (!(destination_area.type in GLOB.the_station_areas) || !(destination_area.area_flags & VALID_TERRITORY)))
			continue
		var/list/turfs = list()
		for(var/turf/open/floor/floor in destination_area)
			CHECK_TICK
			if(on_station ? is_station_level(floor.z) : floor.z == origin.z)
				turfs += floor
		while(length(turfs))
			CHECK_TICK
			var/turf/destination = pick_n_take(turfs)
			if(destination == origin || destination.density || destination.is_transition_turf() || (on_station && !is_station_level(destination.z)))
				continue
			if(is_heretic_escape_area(get_area(destination)) && is_safe_turf(destination))
				return destination
	return null

#undef HERETIC_STATION_TURF_ATTEMPTS
#undef HERETIC_HUNT_CHOICES
