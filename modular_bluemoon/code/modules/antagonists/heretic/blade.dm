#define HERETIC_BLADE_LIMIT 3
#define HERETIC_BLADE_LUNGE_KNOCKDOWN (1.5 SECONDS)
#define HERETIC_BLADE_FEINT_WINDUP (0.6 SECONDS)
#define HERETIC_BLADE_FEINT_WINDOW (3 SECONDS)
#define HERETIC_BLADE_FEINT_COOLDOWN (8 SECONDS)
#define HERETIC_BLADE_FEINT_DAMAGE 10
#define HERETIC_BLADE_FEINT_RANGE 3
#define HERETIC_BLADE_IDLE_TEMPO_DELAY (8 SECONDS)
#define HERETIC_BLADE_IDLE_TEMPO_CAP 1
#define HERETIC_BLADE_REGROW_VOLUME 30
#define HERETIC_BLADE_OATH_CAPTURE "blade_oath"
#define HERETIC_BLADE_THROAT_CAPTURE "blade_throat"
#define HERETIC_BLADE_THROAT_CHECK (0.2 SECONDS)
#define HERETIC_BLADE_DUEL_WON "won"
#define HERETIC_BLADE_DUEL_LOST "lost"
#define HERETIC_BLADE_DUEL_DRAW "draw"
#define HERETIC_BLADE_CHALLENGE_ACCEPT "Принять"
#define HERETIC_BLADE_CHALLENGE_DECLINE "Отказаться"
#define HERETIC_BLADE_SURRENDER "Сдаться"
#define HERETIC_BLADE_KEEP_FIGHTING "Продолжить"

/obj/item/melee/sickly_blade/duelist
	name = "dark blade"
	desc = "Тонкий тёмный клинок. Его отражение отстаёт от движения руки на долю секунды."
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	icon_state = "dark_blade"
	item_state = "dark_blade"
	mark_type = /datum/status_effect/eldritch/blade
	route = PATH_BLADE
	block_chance = 0
	var/datum/mind/bound_mind

/datum/eldritch_knowledge/base_blade
	name = "Принцип поединка"
	summary = "Вызов на дуэль в изнанке, стойка «Выжидание» с ответом и до трёх тёмных клинков из ножа и листа стали."
	details = list(
		"«Вызов»: человек не дальше 5 клеток, оба 10 секунд без урона, ответ - 20 секунд; только там, где откроется изнанка.",
		"Принявший уходит с вами в изнанку на 60 секунд: упавший, сдавшийся или вырвавшийся проиграл, ничья - оба у входа.",
		"Победа - клятва на 12 секунд, растолкать - 2 секунды; цель охоты - к обряду там же, иначе вы выходите, он у входа.",
		"Хватка или заклинание, кроме Выжидания и призыва сердца или кодекса, - поражение, даже если соперник лежит.",
		"Поражение обнуляет Темп, закрывает вызовы на 5 минут, роняет клинок, и 5 минут на вашей шее виден порез-знак.",
		"Отказ или молчание ничего не дают, но этого человека снова можно вызвать только через 5 минут.",
		"Выжидание: 2 секунды и 3 блока, ответ на 18 ушибов; пули и лазеры спереди в секторе 90 градусов уходят вбок.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Между взмахом и раной есть мгновение. Отныне оно принадлежит мне."
	route = PATH_BLADE
	cost = 0
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/melee/sickly_blade/duelist)
	combat_resource_name = "Темп"
	resource_rules = list(
		"Начальный запас 2 из 3; удар тёмным клинком даёт 1 Темп не чаще раза в 4 секунды.",
		"Парирование, взрыв метки и шаг дела дают по 1 Темпу.",
		"Если Темп пуст и 8 секунд не было ударов клинком и парирований, возвращается 1 Темп.",
		"Выпад, финт и танец стоят по 1 Темпу, ответ после парирования бесплатен.",
		"Проигранная дуэль обнуляет Темп.",
	)
	combat_resource = 2
	combat_resource_max = 3
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_blade/parry
	var/list/created_blades = list()
	var/datum/weakref/riposte_target
	var/riposte_until = 0
	var/riposte_ready_at = 0
	var/feint_opening = FALSE
	var/datum/weakref/feint_knowledge_ref
	COOLDOWN_DECLARE(feint_cooldown)
	COOLDOWN_DECLARE(idle_tempo)
	var/datum/status_effect/heretic_parry/active_parry
	var/datum/status_effect/heretic_blade_opening/opening_effect
	var/next_strike_tempo = 0
	var/ascension_active = FALSE
	var/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge/challenge_spell
	var/datum/weakref/challenger_ref
	var/datum/weakref/challenged_ref
	var/challenge_serial = 0
	var/challenge_timer
	var/challenge_failure
	/// Ключ вызванного -> момент, с которого его снова можно вызвать.
	var/list/challenge_repeat = list()
	COOLDOWN_DECLARE(challenge_lockout)
	var/datum/heretic_blade_duel/active_duel
	var/datum/weakref/last_riposte_victim
	var/last_riposte_at = 0
	/// Цель -> момент, с которого её снова можно обезоружить.
	var/list/disarm_ready_at = list()
	var/datum/status_effect/heretic_blade_throat/throat_hold
	var/throat_failure

/datum/eldritch_knowledge/base_blade/on_body_gain(mob/living/user)
	grant_combat_power(user)
	if(user?.mind && QDELETED(challenge_spell))
		challenge_spell = new
		user.mind.AddSpell(challenge_spell)

/datum/eldritch_knowledge/base_blade/on_life(mob/user)
	if(combat_resource >= HERETIC_BLADE_IDLE_TEMPO_CAP || !COOLDOWN_FINISHED(src, idle_tempo) || user.stat != CONSCIOUS)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(heretic?.get_knowledge(type) != src)
		return
	gain_combat_resource(HERETIC_BLADE_IDLE_TEMPO_CAP - combat_resource)
	COOLDOWN_START(src, idle_tempo, HERETIC_BLADE_IDLE_TEMPO_DELAY)

/datum/eldritch_knowledge/base_blade/on_body_lose(mob/living/user)
	remove_combat_power()
	QDEL_NULL(challenge_spell)
	clear_challenge()
	QDEL_NULL(active_parry)
	QDEL_NULL(opening_effect)
	QDEL_NULL(throat_hold)
	user?.remove_status_effect(/datum/status_effect/heretic_blade_dance)
	riposte_target = null
	riposte_until = 0
	riposte_ready_at = 0
	feint_opening = FALSE
	feint_knowledge_ref = null
	last_riposte_victim = null

/datum/eldritch_knowledge/base_blade/Destroy()
	QDEL_NULL(challenge_spell)
	clear_challenge()
	QDEL_NULL(active_parry)
	QDEL_NULL(opening_effect)
	QDEL_NULL(throat_hold)
	created_blades.Cut()
	challenge_repeat.Cut()
	disarm_ready_at.Cut()
	riposte_target = null
	feint_knowledge_ref = null
	last_riposte_victim = null
	return ..()

/datum/eldritch_knowledge/base_blade/combat_resource_state()
	var/mob/living/target = challenged_ref?.resolve()
	if(target)
		return "Вызов ждёт ответа: [target.name]."
	if(active_duel)
		return "Идёт дуэль с [active_duel.rival?.name]."
	if(!COOLDOWN_FINISHED(src, challenge_lockout))
		return "Вызов закрыт после поражения ещё на [heretic_capture_seconds_left(challenge_lockout)] с."
	return "Вызов готов."

/datum/eldritch_knowledge/base_blade/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(active_duel && user == active_duel.champion && isliving(target))
		active_duel.finish(HERETIC_BLADE_DUEL_LOST, "Хватка в честном поединке")
	return FALSE

/datum/eldritch_knowledge/base_blade/pocket_door(mob/living/user, mob/living/victim)
	if(!throat_door_holds(user, victim))
		return null
	return list("name" = "разрезом", "text" = "Тёмный клинок у горла [victim] вспарывает сам воздух.", "time" = HERETIC_BLADE_THROAT_DOOR_TIME, "check" = CALLBACK(src, PROC_REF(throat_door_holds), user, victim))

/// Цель стоит под своим Клинком у горла этого еретика.
/datum/eldritch_knowledge/base_blade/proc/throat_door_holds(mob/living/user, mob/living/victim)
	return !QDELETED(throat_hold) && throat_hold.owner == victim && throat_hold.holder == user

/datum/eldritch_knowledge/base_blade/pocket_exits(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/turf/slash = slash_exit(heretic?.pocket?.entry_turf)
	if(!slash)
		return null
	return list("Разрез: в [HERETIC_BLADE_SLASH_MIN]-[HERETIC_BLADE_SLASH_MAX] клетках от входа" = slash)

/// Случайный безопасный пол станции в HERETIC_BLADE_SLASH_MIN-HERETIC_BLADE_SLASH_MAX клетках от входа, не в охране и не в командовании.
/datum/eldritch_knowledge/base_blade/proc/slash_exit(turf/entry)
	if(!entry)
		return null
	var/list/candidates = list()
	for(var/turf/open/floor/spot in RANGE_TURFS(HERETIC_BLADE_SLASH_MAX, entry))
		if(get_dist(spot, entry) >= HERETIC_BLADE_SLASH_MIN && is_safe_turf(spot) && heretic_pocket_landable(spot) && heretic_pocket_exit_allowed(spot) && is_heretic_escape_area(get_area(spot)))
			candidates += spot
	return length(candidates) ? pick(candidates) : null

/datum/eldritch_knowledge/base_blade/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	for(var/datum/weakref/blade_ref in created_blades.Copy())
		if(!blade_ref.resolve())
			created_blades -= blade_ref
	if(length(created_blades) >= HERETIC_BLADE_LIMIT)
		to_chat(user, span_warning("У вас уже есть три тёмных клинка. Потерянный клинок можно вернуть изученным зовом."))
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_blade/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!recipe_snowflake_check(atoms, loc, list(), user))
		return FALSE
	var/obj/item/melee/sickly_blade/duelist/blade = new(loc)
	blade.bound_mind = user.mind
	created_blades += WEAKREF(blade)
	return TRUE

/datum/eldritch_knowledge/base_blade/proc/held_blade(mob/living/user)
	if(!user?.mind || user.incapacitated())
		return null
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	if(heretic?.get_knowledge(type) != src)
		return null
	for(var/obj/item/melee/sickly_blade/duelist/blade in user.held_items)
		if(blade.bound_mind == user.mind)
			return blade
	return null

/// Хватка Мансуса во второй руке не мешает стойкам клинка.
/datum/eldritch_knowledge/base_blade/proc/offhand_free(mob/living/user)
	return ascension_active || length(user.get_empty_held_indexes()) || (locate(/obj/item/melee/touch_attack/mansus_fist) in user.held_items)

/datum/eldritch_knowledge/base_blade/proc/begin_parry(mob/living/user)
	if(!held_blade(user) || !offhand_free(user) || !QDELETED(active_parry))
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	var/upgraded = heretic.get_knowledge(/datum/eldritch_knowledge/blade_guard)
	var/window = upgraded ? 3 SECONDS : 2 SECONDS
	active_parry = user.apply_status_effect(/datum/status_effect/heretic_parry, src, window, upgraded ? 4 : 3)
	if(active_parry)
		user.visible_message(span_warning("[user] поднимает тёмный клинок, выжидая чужой удар."), span_notice("Выжидание включено: блоков — [active_parry.blocks_left], длительность — [window / (1 SECONDS)] сек."))
	return !!active_parry

/datum/eldritch_knowledge/base_blade/proc/record_parry(mob/living/user, mob/living/attacker)
	gain_combat_resource()
	COOLDOWN_START(src, idle_tempo, HERETIC_BLADE_IDLE_TEMPO_DELAY)
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/blade_guard/guard = heretic?.get_knowledge(/datum/eldritch_knowledge/blade_guard)
	if(guard)
		user.adjustStaminaLoss(-guard.passive_values[guard.passive_level])
	if(!heretic_can_affect(user, attacker, chargecost = 0))
		return
	riposte_target = WEAKREF(attacker)
	riposte_until = world.time + 5 SECONDS
	riposte_ready_at = 0
	feint_opening = FALSE
	feint_knowledge_ref = null
	QDEL_NULL(opening_effect)
	opening_effect = attacker.apply_status_effect(/datum/status_effect/heretic_blade_opening, src)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(user), "eye_flash", "#b4ceff", 6, get_dir(user, attacker))
	to_chat(user, span_notice("Удар отбит! Следующее попадание по [attacker] в течение пяти секунд станет ответным ударом."))

/datum/eldritch_knowledge/base_blade/proc/feint(mob/living/user, mob/living/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/blade_guard/guard = heretic?.get_knowledge(/datum/eldritch_knowledge/blade_guard)
	if(!held_blade(user) || QDELETED(guard) || !offhand_free(user) || !QDELETED(active_parry) || !COOLDOWN_FINISHED(src, feint_cooldown))
		return FALSE
	if(world.time < riposte_until || !valid_feint_target(user, target) || !spend_combat_resource())
		return FALSE
	feint_opening = TRUE
	feint_knowledge_ref = WEAKREF(guard)
	riposte_target = WEAKREF(target)
	riposte_ready_at = world.time + HERETIC_BLADE_FEINT_WINDUP
	riposte_until = riposte_ready_at + HERETIC_BLADE_FEINT_WINDOW
	QDEL_NULL(opening_effect)
	opening_effect = target.apply_status_effect(/datum/status_effect/heretic_blade_opening, src, TRUE)
	COOLDOWN_START(src, feint_cooldown, HERETIC_BLADE_FEINT_COOLDOWN)
	user.do_attack_animation(target, used_item = held_blade(user))
	user.visible_message(span_warning("[user] обманным движением клинка раскрывает защиту [target]!"))
	playsound(target, 'sound/weapons/rapierhit.ogg', 35, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_blade/proc/clear_feint(datum/eldritch_knowledge/blade_guard/guard)
	if(!feint_opening || (guard && feint_knowledge_ref != guard.weak_reference))
		return
	feint_opening = FALSE
	feint_knowledge_ref = null
	riposte_target = null
	riposte_ready_at = 0
	riposte_until = 0
	QDEL_NULL(opening_effect)

/datum/eldritch_knowledge/base_blade/proc/valid_feint_target(mob/living/user, mob/living/target)
	if(!isturf(user?.loc) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0) || !(target in view(HERETIC_BLADE_FEINT_RANGE, user)))
		return FALSE
	for(var/turf/place as anything in get_line(user, target))
		if(place.is_blocked_turf(exclude_mobs = TRUE))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_blade/on_eldritch_blade(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(!proximity_flag || !held_blade(user) || !heretic_can_affect(user, target, chargecost = 0))
		return
	COOLDOWN_START(src, idle_tempo, HERETIC_BLADE_IDLE_TEMPO_DELAY)
	if(world.time >= next_strike_tempo)
		gain_combat_resource()
		next_strike_tempo = world.time + 4 SECONDS
	try_riposte(target, user)

/datum/eldritch_knowledge/base_blade/on_eldritch_blade_damage(mob/living/target, mob/living/user, strike_damage)
	if(!ascension_active || !held_blade(user))
		return
	var/stolen = round(strike_damage * HERETIC_BLADE_LIFESTEAL)
	heretic_heal_damage(user, stolen)
	if(stolen > 0)
		heretic_vfx_stream(target, user, /particles/heretic_ascension/blade/lifesteal)

/datum/eldritch_knowledge/base_blade/proc/try_riposte(mob/living/target, mob/living/user)
	if(!held_blade(user) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(feint_opening && (!feint_knowledge_ref?.resolve() || heretic.get_knowledge(/datum/eldritch_knowledge/blade_guard) != feint_knowledge_ref.resolve()))
		clear_feint()
		return FALSE
	if(world.time < riposte_ready_at || world.time >= riposte_until || riposte_target?.resolve() != target)
		return FALSE
	var/from_feint = feint_opening
	feint_opening = FALSE
	feint_knowledge_ref = null
	riposte_target = null
	riposte_until = 0
	riposte_ready_at = 0
	QDEL_NULL(opening_effect)
	var/mob/living/victim = target
	var/bonus = from_feint ? HERETIC_BLADE_FEINT_DAMAGE : 18
	if(ascension_active && !from_feint)
		bonus += 12
	victim.adjustBruteLoss(bonus)
	if(!from_feint)
		victim.adjustStaminaLoss(15)
	if(!from_feint && heretic.get_knowledge(/datum/eldritch_knowledge/blade_riposte))
		victim.Knockdown(0.6 SECONDS)
	if(!from_feint && user.has_status_effect(/datum/status_effect/heretic_blade_dance))
		heretic_heal_damage(user, 5)
		gain_combat_resource()
	if(!from_feint)
		last_riposte_victim = WEAKREF(victim)
		last_riposte_at = world.time
		disarm(user, victim)
	new /obj/effect/temp_visual/dir_setting/heretic_slash(get_turf(user), get_dir(user, victim), TRUE)
	playsound(victim, 'sound/weapons/rapierhit.ogg', 55, TRUE)
	user.visible_message(span_danger("[user] отвечает точным выпадом по [victim]!"))
	return TRUE

/datum/status_effect/heretic_parry
	id = "heretic_parry"
	duration = 2 SECONDS
	tick_interval = 0.2 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/heretic_parry
	status_type = STATUS_EFFECT_REPLACE
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/knowledge_ref
	var/expires_at
	var/blocks_left = 1
	var/stance_ready = TRUE
	var/mutable_appearance/stance_overlay

/datum/status_effect/heretic_parry/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blade/knowledge, window, blocks)
	knowledge_ref = WEAKREF(knowledge)
	duration = window
	expires_at = world.time + window
	blocks_left = blocks
	. = ..()
	if(.)
		update_stance_feedback()

/datum/status_effect/heretic_parry/tick()
	if(world.time >= expires_at)
		qdel(src)
		return
	update_stance_feedback()

/datum/status_effect/heretic_parry/proc/update_stance_feedback()
	var/datum/eldritch_knowledge/base_blade/knowledge = knowledge_ref?.resolve()
	var/reason
	if(owner.incapacitated())
		reason = "Вы не можете действовать."
	else if(!knowledge?.held_blade(owner))
		reason = "Возьмите свой клинок в руку."
	else if(!knowledge.offhand_free(owner))
		reason = "Освободите вторую руку."
	if(reason && stance_ready)
		to_chat(owner, span_warning("Выжидание не действует! [reason]"))
	else if(!reason && !stance_ready)
		to_chat(owner, span_notice("Выжидание снова действует."))
	stance_ready = !reason
	if(linked_alert)
		var/remaining = CEILING(max(0, expires_at - world.time) / (1 SECONDS), 1)
		linked_alert.name = stance_ready ? "Выжидание: активно" : "Выжидание: не действует"
		linked_alert.desc = "Осталось блоков: [blocks_left]; времени: [remaining] сек. [reason || "Держите свой клинок в руке и оставьте вторую руку свободной."]"
		linked_alert.color = stance_ready ? "#b6c9f4" : "#ff7766"
		linked_alert.maptext = MAPTEXT("<div style='text-align:center;font-size:8px;background-color:#17111d'>[stance_ready ? blocks_left : "!"]<br>[remaining]с</div>")
	return stance_ready

/atom/movable/screen/alert/status_effect/heretic_parry
	name = "Выжидание"
	desc = "Свой клинок и свободная вторая рука позволяют отражать атаки."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blade_parry"
	maptext_width = 32
	maptext_height = 24

/datum/status_effect/heretic_parry/on_apply()
	. = ..()
	if(!.)
		return FALSE
	RegisterSignal(owner, COMSIG_LIVING_RUN_BLOCK, PROC_REF(parry_attack))
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(keep_stance_overlay))
	stance_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_feedback.dmi', "ring_leader_effect", ABOVE_MOB_LAYER)
	stance_overlay.color = "#b6c9f4"
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_parry/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_ATOM_UPDATE_OVERLAYS))
	owner.update_icon()
	stance_overlay = null
	var/datum/eldritch_knowledge/base_blade/knowledge = knowledge_ref?.resolve()
	if(knowledge?.active_parry == src)
		knowledge.active_parry = null
		if(!QDELETED(owner) && (world.time >= expires_at || !blocks_left))
			to_chat(owner, span_notice("Выжидание окончено: [blocks_left ? "время вышло" : "все блоки израсходованы"]."))
	return ..()

/datum/status_effect/heretic_parry/proc/keep_stance_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(stance_overlay)
		overlays += stance_overlay

/datum/status_effect/heretic_parry/be_replaced()
	on_remove()
	return ..()

/// Видимый просвет в защите сообщает самой цели, что следующий ответ особенно опасен.
/datum/status_effect/heretic_blade_opening
	id = "heretic_blade_opening"
	duration = 5 SECONDS
	tick_interval = -1
	alert_type = null
	status_type = STATUS_EFFECT_MULTIPLE
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/knowledge_ref
	var/mutable_appearance/opening_overlay
	var/from_feint = FALSE

/datum/status_effect/heretic_blade_opening/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blade/knowledge, feint = FALSE)
	knowledge_ref = WEAKREF(knowledge)
	from_feint = feint
	if(from_feint)
		duration = HERETIC_BLADE_FEINT_WINDUP + HERETIC_BLADE_FEINT_WINDOW
	return ..()

/datum/status_effect/heretic_blade_opening/on_apply()
	. = ..()
	if(!.)
		return FALSE
	opening_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_alerts.dmi', "sigil_blade", ABOVE_MOB_LAYER)
	opening_overlay.transform = matrix() * 0.6
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(keep_opening_overlay))
	owner.update_icon()
	to_chat(owner, span_userdanger((from_feint ? "Противник проводит финт: через 0,6 секунды его следующий удар получит усиление на три секунды. Разорвите дистанцию!" : "Ваш удар отбит: пять секунд противник может ответить усиленным выпадом. Разорвите дистанцию!")))
	return TRUE

/datum/status_effect/heretic_blade_opening/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_icon()
	opening_overlay = null
	var/datum/eldritch_knowledge/base_blade/knowledge = knowledge_ref?.resolve()
	if(knowledge?.opening_effect == src)
		knowledge.opening_effect = null
	knowledge_ref = null
	return ..()

/datum/status_effect/heretic_blade_opening/proc/keep_opening_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(opening_overlay)
		overlays += opening_overlay

/// Общий фильтр стойки и орбиты: какие атаки вообще можно отбить клинком.
/proc/heretic_blade_blockable(real_attack, damage, attack_type, list/return_list)
	if(!real_attack || (attack_type & ATTACK_TYPE_PARRY_COUNTERATTACK) || !(attack_type & (ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED | ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_THROWN)))
		return FALSE
	if((attack_type & ATTACK_TYPE_UNARMED) && !(attack_type & ATTACK_TYPE_MELEE) && damage <= 0)
		return FALSE
	return damage > 0 || (attack_type & (ATTACK_TYPE_UNARMED | ATTACK_TYPE_PROJECTILE)) || return_list?[BLOCK_CONTEXT_DAMAGE] > 0

/// Удар без указанного нападающего приписывается мобу, который сам и есть атакующий объект.
/proc/heretic_blade_aggressor(atom/object, mob/attacker)
	return attacker || (ismob(object) ? object : null)

/// Стойка и орбита решают одинаково, так что атаку берёт ровно один из них.
/datum/status_effect/heretic_parry/proc/would_parry(mob/living/source, attack_type, mob/attacker)
	if(world.time >= expires_at || blocks_left <= 0 || !update_stance_feedback())
		return FALSE
	if(ismob(attacker) && (attacker == source || IS_HERETIC(attacker) || IS_HERETIC_MONSTER(attacker)))
		return FALSE
	return (attack_type & (ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_THROWN)) || source.Adjacent(attacker)

/datum/status_effect/heretic_parry/proc/parry_attack(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(!heretic_blade_blockable(real_attack, damage, attack_type, return_list))
		return BLOCK_NONE
	var/mob/aggressor = heretic_blade_aggressor(object, attacker)
	if(!would_parry(source, attack_type, aggressor))
		return BLOCK_NONE
	var/datum/eldritch_knowledge/base_blade/knowledge = knowledge_ref?.resolve()
	blocks_left--
	knowledge.record_parry(source, aggressor)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(source)
	heretic?.advance_combat_deed(aggressor, PATH_BLADE)
	playsound(source, 'modular_bluemoon/sound/heretic/parry.ogg', 60, TRUE)
	. = BLOCK_SUCCESS
	if((attack_type & ATTACK_TYPE_PROJECTILE) && heretic_blade_deflectable(source, object))
		heretic_blade_deflect(source, object)
		. |= BLOCK_REDIRECTED
	if(!blocks_left)
		qdel(src)
	else
		update_stance_feedback()

/// Отбить пулю: снаряд в лицо, в секторе HERETIC_BLADE_DEFLECT_ARC, уходит вбок; остальные стойка просто гасит.
/proc/heretic_blade_deflectable(mob/living/source, atom/object)
	if(!istype(object, /obj/item/projectile))
		return FALSE
	var/obj/item/projectile/projectile = object
	if(projectile.hitscan)
		return FALSE
	var/incoming = SIMPLIFY_DEGREES(projectile.Angle + 180)
	return abs(MODULUS(incoming - dir2angle(source.dir) + 180, 360) - 180) <= HERETIC_BLADE_DEFLECT_ARC / 2

/proc/heretic_blade_deflect(mob/living/source, obj/item/projectile/projectile)
	projectile.ignore_source_check = TRUE
	projectile.setAngle(SIMPLIFY_DEGREES(projectile.Angle + pick(-HERETIC_BLADE_DEFLECT_TURN, HERETIC_BLADE_DEFLECT_TURN)))
	source.visible_message(span_warning("[source] отбивает [projectile] тёмным клинком в сторону!"), span_notice("Вы отбиваете [projectile] в сторону."))

/datum/eldritch_knowledge/blade_disarm
	name = "Обезоруживание"
	summary = "Ответный удар и взрыв метки выбивают предмет из активной руки цели."
	details = list(
		"Оружие, щит или дубинка отлетают на 2 клетки в сторону от вас; стена остановит их раньше.",
		"Одну цель можно обезоружить раз в 6 секунд, приросший к руке предмет не выпадет.",
		"Цель с пустой рукой после вашего ответа 3 секунды годится для Клинка у горла.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Я различаю в толпе лишь одно движение."
	route = PATH_BLADE
	cost = 1

/datum/eldritch_knowledge/blade_disarm/on_mark_detonated(mob/living/user, mob/living/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/blade = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	blade?.disarm(user, target)

/datum/eldritch_knowledge/spell/blade_lunge
	name = "Шаг между ударами"
	summary = "Выпад: за 1 Темп рывок к врагу до 5 клеток по свободному пути."
	details = list(
		"Удар выпада: 20 ушибов, 20 урона выносливости и падение на 1,5 секунды.",
		"По только что парированному врагу выпад проводит ещё и ответный удар.",
		"Стены, столы и закрытые двери на пути отменяют выпад, Темп и перезарядка остаются.",
		"Промах по полу рядом с врагом наводит выпад на него. Перезарядка 10 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	route = PATH_BLADE
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_lunge

/datum/eldritch_knowledge/blade_mark
	name = "Метка поединка"
	summary = "Хватка ставит метку Клинка на 15 секунд, удар тёмным клинком её взрывает."
	details = list(
		"Взрыв отнимает у цели 25 выносливости и даёт вам 1 Темп.",
		"С Обезоруживанием взрыв ещё и выбивает предмет из руки цели.",
	)
	role = HERETIC_ROLE_MARK
	route = PATH_BLADE
	cost = 2

/datum/eldritch_knowledge/blade_mark/on_mansus_grasp(atom/target, mob/living/user, proximity_flag)
	if(!proximity_flag || !heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/blade)
	return TRUE

/datum/status_effect/eldritch/blade
	id = "blade_mark"
	mark_name = "Метка Клинка"
	mark_alert_state = "sigil_blade"
	effect_sprite = "emark5"
	detonation_sound = 'sound/weapons/rapierhit.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_path_feedback/blade_mark

/datum/status_effect/eldritch/blade/on_effect()
	owner.adjustStaminaLoss(25)
	return ..()

/datum/eldritch_knowledge/blade_guard
	parent_type = /datum/eldritch_knowledge/spell
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_feint
	name = "Неподвижная грань"
	summary = "Выжидание дольше и крепче, открывается Финт, а вилка и два прута дают камертон."
	details = list(
		"Выжидание длится 3 секунды и держит 4 блока, парирование возвращает от 10 выносливости.",
		"Финт за 1 Темп раскрывает врага в 3 клетках: через 0,6 секунды 3 секунды на удар с +10 ушибами.",
		"Финту нужны свой клинок и пустая вторая рука; с ответом он не складывается. Перезарядка 8 секунд.",
		"Камертон при пустом Темпе за 2 секунды настройки меняет 8 ушибов на 1 Темп, перезарядка 25 секунд.",
		"Для камертона нужен свой клинок во второй руке; камертон бывает только один.",
	)
	role = HERETIC_ROLE_PASSIVE
	route = PATH_BLADE
	cost = 1
	required_atoms = list(/obj/item/kitchen/fork, /obj/item/stack/rods, /obj/item/stack/rods)
	result_atoms = list(/obj/item/heretic_path_relic/tuning_fork)
	var/datum/weakref/blade_ref

/datum/eldritch_knowledge/blade_guard/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	blade_ref = knowledge ? WEAKREF(knowledge) : null
	return ..()

/datum/eldritch_knowledge/blade_guard/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_blade/knowledge = blade_ref?.resolve()
	knowledge?.clear_feint(src)
	blade_ref = null
	return ..()

/datum/eldritch_knowledge/blade_guard/Destroy()
	on_body_lose(null)
	return ..()

/datum/eldritch_knowledge/spell/blade_throat
	name = "Клинок у горла"
	summary = "Клинок к горлу соседа: он замирает до 12 секунд и идёт за вами шагом, цель охоты уводится разрезом."
	details = list(
		"Годится сбитая с ног цель или цель с пустой рукой после вашего ответа, не позже 3 секунд.",
		"Полсекунды замаха: отошедшая за это время цель уходит от захвата. Защита от магии спасает от клинка.",
		"Заложник не двигается сам и идёт за вами шагом, обряд сердцем над ним работает; растолкать - 2 секунды.",
		"Цель охоты у горла сердце уводит разрезом в изнанку за 1,5 секунды.",
		"Срывают: шаг дальше клетки, 15+ урона вам одним ударом, оглушение, падение, клинок не в руке.",
		"Удар нулевым жезлом по вам или по заложнику тоже освобождает его.",
		"После захвата цель минуту невосприимчива к нему и 15 секунд - к любому захвату. Перезарядка 45 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Остриё замерло у самой кожи. Теперь он слушает каждое моё слово."
	route = PATH_BLADE
	cost = 2
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_blade_throat

/datum/eldritch_knowledge/spell/blade_recall
	name = "Память стали"
	summary = "Зов клинка возвращает ваш тёмный клинок с пола в свободную руку."
	details = list(
		"Клинок должен лежать на виду не дальше 7 клеток.",
		"Клинок в чужих руках или в закрытом контейнере не откликается.",
	)
	role = HERETIC_ROLE_SUPPORT
	route = PATH_BLADE
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blade/recall

/datum/eldritch_knowledge/blade_riposte
	name = "Ошибка противника"
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	summary = "Ответный удар после парирования сбивает врага с ног на 0,6 секунды."
	details = list(
		"Сбитый ответом враг годится для Клинка у горла, пока лежит.",
		"Удар после финта не сбивает.",
	)
	role = HERETIC_ROLE_CONTROL
	route = PATH_BLADE
	cost = 2

/datum/eldritch_knowledge/spell/blade_dance
	name = "Ритм поединка"
	summary = "Танец граней: за 1 Темп 10 секунд вы двигаетесь быстрее."
	details = list(
		"Ответные удары во время танца лечат 5 ушибов и возвращают 1 Темп.",
		"Выпавший из руки клинок обрывает танец. Перезарядка 30 секунд.",
	)
	role = HERETIC_ROLE_SUPPORT
	route = PATH_BLADE
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blade/dance

/datum/eldritch_knowledge/final_eldritch/blade_final
	parallax_scene = ANTAG_SCENE_HERETIC_BLADE
	name = "Последний поединок"
	summary = "Вокруг вас кружат четыре клинка, ваш клинок пьёт кровь, открывается Буря клинков."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа; место обряда узнает станция, 30 секунд на помеху.",
		"Общая стойкость вознесения; Выжидание и финт больше не требуют свободной руки.",
		"Клинок орбиты целиком принимает один удар, бросок или снаряд; новый растёт раз в 6 секунд.",
		"Картечь - это отдельные дробины: один выстрел сдирает всю орбиту.",
		"Удар тёмным клинком по живому врагу лечит вам четверть урона, ответ после парирования +12 ушибов.",
		"Буря клинков: по клинку орбиты во врагов в 7 клетках, 20 ушибов и 20 выносливости, раз в 30 секунд.",
		"Смерть снимает эти усиления, оживление возвращает.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Острие остановилось у самого сердца мира. Теперь вокруг меня кружит сталь, и каждый удар, летящий ко мне, встречает свой клинок."
	route = PATH_BLADE
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_blade/storm)
	var/datum/weakref/blade_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/blade_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/blade = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(blade)
		blade.ascension_active = TRUE
		blade_knowledge_ref = WEAKREF(blade)
	user.AddComponent(/datum/component/heretic_blade_orbit)

/datum/eldritch_knowledge/final_eldritch/blade_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_blade_orbit))
	var/datum/eldritch_knowledge/base_blade/blade = blade_knowledge_ref?.resolve()
	if(blade)
		blade.ascension_active = FALSE
	blade_knowledge_ref = null
	return ..()

/datum/component/heretic_blade_orbit
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/list/obj/effect/heretic_orbit_blade/orbit_blades = list()
	var/regen_timer

/datum/component/heretic_blade_orbit/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	for(var/count in 1 to HERETIC_BLADE_ORBIT_MAX)
		add_blade()

/datum/component/heretic_blade_orbit/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_RUN_BLOCK, PROC_REF(intercept))

/datum/component/heretic_blade_orbit/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_LIVING_RUN_BLOCK)

/datum/component/heretic_blade_orbit/Destroy()
	deltimer(regen_timer)
	regen_timer = null
	var/atom/movable/owner = parent
	var/turf/place = get_turf(owner)
	for(var/obj/effect/heretic_orbit_blade/blade as anything in orbit_blades)
		if(place)
			new /obj/effect/temp_visual/heretic_blade_fade(place, blade.orbit_angle())
		owner.vis_contents -= blade
	QDEL_LIST(orbit_blades)
	return ..()

/datum/component/heretic_blade_orbit/proc/add_blade(grown = FALSE)
	var/list/taken = list()
	for(var/obj/effect/heretic_orbit_blade/blade as anything in orbit_blades)
		taken += blade.slot
	var/slot = 0
	while(slot in taken)
		slot++
	var/obj/effect/heretic_orbit_blade/blade = new(null, slot, grown)
	orbit_blades += blade
	var/atom/movable/owner = parent
	owner.vis_contents += blade

/datum/component/heretic_blade_orbit/proc/remove_blades(list/blades)
	var/atom/movable/owner = parent
	for(var/obj/effect/heretic_orbit_blade/blade as anything in blades)
		orbit_blades -= blade
		owner.vis_contents -= blade
		qdel(blade)
	start_regeneration()

/// Удар принимает клинок, ближайший на круге к стороне удара: он вспыхивает, а осколки летят туда же.
/datum/component/heretic_blade_orbit/proc/shatter_blade(attack_angle)
	var/obj/effect/heretic_orbit_blade/nearest
	var/nearest_gap = INFINITY
	for(var/obj/effect/heretic_orbit_blade/blade as anything in orbit_blades)
		var/gap = abs(MODULUS(blade.orbit_angle() - attack_angle + 180, 360) - 180)
		if(gap < nearest_gap)
			nearest = blade
			nearest_gap = gap
	if(!nearest)
		return
	var/atom/movable/owner = parent
	heretic_blade_shatter_fx(get_turf(owner), nearest.orbit_angle(), attack_angle)
	orbit_blades -= nearest
	owner.vis_contents -= nearest
	qdel(nearest)
	start_regeneration()

/datum/component/heretic_blade_orbit/proc/start_regeneration()
	if(!regen_timer && length(orbit_blades) < HERETIC_BLADE_ORBIT_MAX)
		regen_timer = addtimer(CALLBACK(src, PROC_REF(regenerate)), HERETIC_BLADE_ORBIT_REGEN, TIMER_STOPPABLE)

/datum/component/heretic_blade_orbit/proc/regenerate()
	regen_timer = null
	if(length(orbit_blades) >= HERETIC_BLADE_ORBIT_MAX)
		return
	add_blade(TRUE)
	heretic_vfx_burst(parent, /particles/heretic_ascension/blade/regrow)
	playsound(parent, 'sound/items/unsheath.ogg', HERETIC_BLADE_REGROW_VOLUME, TRUE)
	start_regeneration()

/// Сторона, с которой пришёл удар: от нападающего, от места броска или против полёта снаряда.
/datum/component/heretic_blade_orbit/proc/attack_angle(mob/living/source, atom/object, mob/aggressor)
	var/turf/source_turf = get_turf(source)
	for(var/atom/origin as anything in list(aggressor, object))
		var/turf/origin_turf = get_turf(origin)
		if(origin_turf && origin_turf != source_turf)
			return Get_Angle(source_turf, origin_turf)
	if(istype(object, /obj/item/projectile))
		var/obj/item/projectile/projectile = object
		return MODULUS(projectile.Angle + 180, 360)
	return rand(0, 359)

/datum/component/heretic_blade_orbit/proc/intercept(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(!length(orbit_blades) || source.stat == DEAD || !heretic_blade_blockable(real_attack, damage, attack_type, return_list))
		return BLOCK_NONE
	var/mob/aggressor = heretic_blade_aggressor(object, attacker)
	if(ismob(aggressor) && (aggressor == source || IS_HERETIC(aggressor) || IS_HERETIC_MONSTER(aggressor)))
		return BLOCK_NONE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(source)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!QDELETED(knowledge?.active_parry) && knowledge.active_parry.would_parry(source, attack_type, aggressor))
		return BLOCK_NONE
	shatter_blade(attack_angle(source, object, aggressor))
	playsound(source, 'modular_bluemoon/sound/heretic/parry.ogg', 50, TRUE)
	source.visible_message(span_warning("Кружащий клинок принимает на себя [attack_text] и разлетается осколками!"), span_notice("Клинок орбиты отбил [attack_text]. Осталось клинков: [length(orbit_blades)]."))
	return BLOCK_SUCCESS

/obj/effect/proc_holder/spell/self/heretic_blade
	clothes_req = FALSE
	charge_max = 10 SECONDS
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "mansus_grasp"
	action_background_icon_state = "bg_ecult"
	var/required_knowledge = /datum/eldritch_knowledge/base_blade
	var/requires_blade = TRUE
	var/resource_cost = 0

/obj/effect/proc_holder/spell/self/heretic_blade/can_cast(mob/user, skipcharge, silent)
	if(!..() || !heretic_require_knowledge(user, silent, required_knowledge) || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/base_blade, resource_cost))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return heretic_check(user, !requires_blade || knowledge.held_blade(user), silent, "Возьмите собственный тёмный клинок в руку.")

/obj/effect/proc_holder/spell/self/heretic_blade/parry
	name = "Выжидание"
	desc = "За 2 секунды отбейте три удара или выстрела своим клинком; улучшенное Выжидание длится 3 секунды и даёт четыре блока. Выстрелы Выжидание тоже гасит, каждый тратит блок; пули и лазеры, летящие спереди в секторе 90 градусов, при этом отлетают в сторону, мимо стрелка. Блоки работают и против одновременных попаданий; вторая рука должна быть свободна или держать хватку Мансуса, после вознесения это условие снимается. Парирование даёт бесплатный ответный удар по нападавшему. Пока Выжидание готово, удары принимает оно, а не клинки орбиты."
	summary = "На 2 секунды: 3 блока, бесплатный ответ, пули спереди отлетают вбок."
	charge_max = 8 SECONDS
	action_icon_state = "furious_steel"

/obj/effect/proc_holder/spell/self/heretic_blade/parry/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge?.begin_parry(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_blade/parry/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return heretic_check(user, QDELETED(knowledge.active_parry), silent, "Выжидание уже включено.") && heretic_check(user, knowledge.offhand_free(user), silent, "Выжидание не включено: освободите вторую руку.")

/obj/effect/proc_holder/spell/self/heretic_blade/recall
	name = "Зов клинка"
	desc = "Верните свой клинок с пола в свободную руку. Требуются видимость и расстояние до семи клеток."
	summary = "Возвращает свой клинок с пола в свободную руку, до 7 клеток на виду."
	required_knowledge = /datum/eldritch_knowledge/spell/blade_recall
	requires_blade = FALSE
	action_icon_state = "shatter"

/obj/effect/proc_holder/spell/self/heretic_blade/recall/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge || !heretic.get_knowledge(required_knowledge) || !length(user.get_empty_held_indexes()))
		heretic_revert_cast(user)
		return
	for(var/datum/weakref/blade_ref in knowledge.created_blades)
		var/obj/item/melee/sickly_blade/duelist/blade = blade_ref.resolve()
		if(blade?.bound_mind != user.mind || !isturf(blade.loc) || !(blade in view(7, user)))
			continue
		if(!user.put_in_hands(blade))
			heretic_revert_cast(user)
			return
		playsound(user, 'sound/magic/repulse.ogg', 35, TRUE)
		return
	heretic_revert_cast(user, "В поле зрения нет вашего свободно лежащего клинка.")

/obj/effect/proc_holder/spell/self/heretic_blade/dance
	name = "Танец граней"
	desc = "Потратьте 1 Темп: десять секунд ускоренного движения, ответные удары лечат 5 ушибов и дают Темп. Потеря клинка прерывает танец."
	summary = "За 1 Темп 10 секунд быстрее, ответные удары лечат 5 ушибов и дают Темп."
	required_knowledge = /datum/eldritch_knowledge/spell/blade_dance
	charge_max = 30 SECONDS
	action_icon_state = "cursed_steel"
	resource_cost = 1

/obj/effect/proc_holder/spell/self/heretic_blade/dance/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge?.held_blade(user) || !heretic.get_knowledge(required_knowledge) || !knowledge.spend_combat_resource(resource_cost))
		heretic_revert_cast(user)
		return
	user.apply_status_effect(/datum/status_effect/heretic_blade_dance)

/datum/status_effect/heretic_blade_dance
	id = "heretic_blade_dance"
	duration = 10 SECONDS
	tick_interval = 0.5 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REPLACE
	on_remove_on_mob_delete = TRUE

/datum/status_effect/heretic_blade_dance/on_apply()
	. = ..()
	if(!.)
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_blade_dance)
	return TRUE

/datum/status_effect/heretic_blade_dance/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_blade_dance)
	return ..()

/datum/status_effect/heretic_blade_dance/tick()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(owner)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge?.held_blade(owner))
		qdel(src)

/datum/movespeed_modifier/heretic_blade_dance
	multiplicative_slowdown = -0.4

/obj/effect/proc_holder/spell/self/heretic_blade/storm
	name = "Буря клинков"
	desc = "Бросьте кружащие вокруг вас клинки в ближайших видимых врагов в семи клетках, по клинку на врага, до четырёх целей: каждый получает 20 ушибов и 20 урона выносливости. Окна, решётки и стены перехватывают клинки. Нужен хотя бы один клинок на орбите; свой клинок в руке не нужен. Тратятся только брошенные клинки, остальные продолжают кружить; брошенные отрастают по одному раз в 6 секунд. Перезарядка 30 секунд."
	summary = "Клинки орбиты летят в ближних врагов в 7 клетках: по 20 ушибов и 20 выносливости."
	required_knowledge = /datum/eldritch_knowledge/final_eldritch/blade_final
	requires_blade = FALSE
	charge_max = HERETIC_BLADE_STORM_COOLDOWN
	action_icon_state = "blade_master"

/obj/effect/proc_holder/spell/self/heretic_blade/storm/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	return heretic_check(user, knowledge.ascension_active, silent, "Сначала завершите вознесение.") && heretic_check(user, length(orbit?.orbit_blades), silent, "Вокруг вас не кружит ни одного клинка.")

/obj/effect/proc_holder/spell/self/heretic_blade/storm/proc/line_clear(atom/start, atom/end)
	var/turf/previous
	for(var/turf/tile as anything in get_line(get_turf(start), get_turf(end)))
		if(!heretic_line_tile_open(tile))
			return FALSE
		if(previous && previous.x != tile.x && previous.y != tile.y)
			if(!heretic_line_tile_open(locate(previous.x, tile.y, tile.z)) || !heretic_line_tile_open(locate(tile.x, previous.y, tile.z)))
				return FALSE
		previous = tile
	return TRUE

/obj/effect/proc_holder/spell/self/heretic_blade/storm/proc/storm_targets(mob/living/user, limit)
	var/list/candidates = list()
	for(var/mob/living/candidate in view(HERETIC_BLADE_STORM_RANGE, user))
		candidates += candidate
	var/list/chosen = list()
	for(var/distance in 1 to HERETIC_BLADE_STORM_RANGE)
		for(var/mob/living/candidate as anything in candidates)
			if(length(chosen) >= limit)
				return chosen
			if(get_dist(user, candidate) == distance && line_clear(user, candidate) && heretic_can_affect(user, candidate))
				chosen += candidate
	return chosen

/obj/effect/proc_holder/spell/self/heretic_blade/storm/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	if(!knowledge?.ascension_active || !length(orbit?.orbit_blades))
		heretic_revert_cast(user)
		return
	if(!isturf(user.loc))
		heretic_revert_cast(user, "Сначала выйдите наружу: из укрытия или меха клинкам не вылететь.")
		return
	var/list/victims = storm_targets(user, min(length(orbit.orbit_blades), HERETIC_BLADE_STORM_TARGETS))
	if(!length(victims))
		heretic_revert_cast(user, "Рядом нет видимых врагов на открытой линии, клинкам некуда лететь.")
		return
	var/turf/origin = get_turf(user)
	var/list/launched = orbit.orbit_blades.Copy(1, length(victims) + 1)
	for(var/index in 1 to length(victims))
		var/mob/living/victim = victims[index]
		var/obj/effect/heretic_orbit_blade/blade = launched[index]
		heretic_blade_storm_fx(origin, victim, blade.orbit_angle(), index % 2 ? 1 : -1, index == 1)
		victim.apply_damage(HERETIC_BLADE_STORM_BRUTE, BRUTE, BODY_ZONE_CHEST)
		victim.adjustStaminaLoss(HERETIC_BLADE_STORM_STAMINA)
		log_combat(user, victim, "поражает Бурей клинков")
	orbit.remove_blades(launched)
	heretic_blade_storm_cast_fx(user)
	playsound(user, 'sound/weapons/rapierhit.ogg', 60, TRUE)
	user.visible_message(span_danger("Клинки, кружившие вокруг [user], разом срываются к врагам!"))

/obj/effect/proc_holder/spell/pointed/heretic_lunge
	name = "Выпад"
	desc = "За 1 Темп сблизьтесь с противником до пяти клеток по свободному пути: 20 ушибов, 20 урона выносливости и падение на 1,5 секунды. Выпад по только что парированному противнику также расходует и проводит ответный удар. Требуется собственный тёмный клинок в руке."
	summary = "Рывок к врагу до 5 клеток за 1 Темп: 20 ушибов, 20 выносливости, падение на 1,5 секунды."
	clothes_req = FALSE
	charge_max = 10 SECONDS
	range = 5
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "cleave"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/heretic_lunge/can_target(atom/target, mob/user, silent)
	if(!heretic_check(user, isliving(target), silent, "Укажите самого противника: предметы и пол не подходят для выпада."))
		return FALSE
	var/mob/living/victim = target
	if(!heretic_check(user, victim.stat != DEAD, silent, "Выпад нельзя направить на мёртвую цель."))
		return FALSE
	if(!heretic_check(user, victim != user && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim), silent, "Выпад нельзя направить на себя или другого служителя Мансуса.", target = victim))
		return FALSE
	return heretic_check(user, heretic_can_affect(user, victim, chargecost = 0), silent, "Цель защищена от магии. Выпад её не достанет.", target = victim)

/obj/effect/proc_holder/spell/pointed/heretic_lunge/can_cast(mob/user, skipcharge, silent)
	if(!..() || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/spell/blade_lunge) || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/base_blade, 1))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return heretic_check(user, knowledge.held_blade(user), silent, "Возьмите собственный тёмный клинок в руку.")

/obj/effect/proc_holder/spell/pointed/heretic_lunge/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/mob/living/victim = length(targets) ? targets[1] : null
	var/failure_reason
	if(!knowledge?.held_blade(user))
		failure_reason = "Возьмите собственный тёмный клинок в руку."
	else if(!heretic.get_knowledge(/datum/eldritch_knowledge/spell/blade_lunge))
		failure_reason = "Сначала изучите Выпад."
	else if(!isliving(victim))
		failure_reason = "Цель исчезла. Выберите самого противника."
	else if(!(victim in view(range, user)))
		failure_reason = "Цель вышла из поля зрения или дальше пяти клеток."
	else if(knowledge.combat_resource < 1)
		failure_reason = "Для выпада нужен 1 Темп."
	if(failure_reason)
		user.log_message("Выпад отменён: [failure_reason] Клинок [!!knowledge?.held_blade(user)], знание [!!heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)], цель [key_name(victim)], в поле зрения [victim in view(range, user)], Темп [knowledge?.combat_resource].", LOG_ATTACK)
		heretic_revert_cast(user, failure_reason)
		return
	var/turf/start = get_turf(user)
	var/turf/route_step = start
	for(var/steps in 1 to range)
		if(get_dist(route_step, victim) <= 1)
			break
		route_step = get_step_towards(route_step, victim)
		if(is_blocked_turf(route_step, TRUE))
			user.log_message("Выпад к [key_name(victim)] отменён: преграда [AREACOORD(route_step)], старт [AREACOORD(start)], Темп [knowledge.combat_resource] сохранён.", LOG_ATTACK)
			heretic_revert_cast(user, "Прямая линия для выпада перекрыта. Темп и перезарядка сохранены.")
			return
	if(!heretic_can_affect(user, victim))
		failure_reason = "Цель мертва или защищена от магии. Темп и перезарядка сохранены."
	else if(!knowledge.spend_combat_resource())
		failure_reason = "Для выпада нужен 1 Темп. Перезарядка сохранена."
	if(failure_reason)
		user.log_message("Выпад к [key_name(victim)] отменён: [failure_reason] Темп [knowledge.combat_resource].", LOG_ATTACK)
		heretic_revert_cast(user, failure_reason)
		return
	for(var/steps in 1 to range)
		if(user.Adjacent(victim))
			break
		new /obj/effect/temp_visual/heretic_afterimage(get_turf(user), user, "#a99aca")
		if(!step_towards(user, victim))
			break
	if(!user.Adjacent(victim))
		if(user.loc == start)
			knowledge.gain_combat_resource()
			heretic_revert_cast(user, "Сближение не удалось. Темп и перезарядка сохранены.")
		else
			heretic_check(user, FALSE, FALSE, "Вы не достали цель. Темп потрачен на сближение.")
		user.log_message("Выпад не достал [key_name(victim)] [AREACOORD(victim)]: старт [AREACOORD(start)], финиш [AREACOORD(user)], Темп [knowledge.combat_resource], возврат [user.loc == start].", LOG_ATTACK)
		return
	COOLDOWN_START(knowledge, idle_tempo, HERETIC_BLADE_IDLE_TEMPO_DELAY)
	var/damage_before = victim.getBruteLoss()
	victim.adjustBruteLoss(20)
	victim.adjustStaminaLoss(20)
	victim.Knockdown(HERETIC_BLADE_LUNGE_KNOCKDOWN)
	knowledge.try_riposte(victim, user)
	log_combat(user, victim, "поражает выпадом", addition = "старт [AREACOORD(start)]; ушибы: [round(victim.getBruteLoss() - damage_before, 0.1)]; Темп: [knowledge.combat_resource]")
	new /obj/effect/temp_visual/dir_setting/heretic_slash(get_turf(user), get_dir(user, victim))
	playsound(victim, 'sound/weapons/rapierhit.ogg', 50, TRUE)

/obj/effect/proc_holder/spell/pointed/heretic_feint
	name = "Финт"
	desc = "За 1 Темп раскройте видимого противника до трёх клеток. Через 0,6 секунды следующее попадание клинком или выпадом в течение трёх секунд нанесёт ещё 10 ушибов. Нужны свой клинок и свободная вторая рука. Стены, Выжидание и уже открытый ответ мешают финту; усиления парирования на него не действуют."
	summary = "За 1 Темп раскрывает врага в 3 клетках: следующее попадание нанесёт ещё 10 ушибов."
	clothes_req = FALSE
	range = HERETIC_BLADE_FEINT_RANGE
	charge_max = HERETIC_BLADE_FEINT_COOLDOWN
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "blade_feint"
	action_background_icon_state = "bg_ecult"
	active_msg = "Выберите противника для финта."
	deactive_msg = "Вы опускаете остриё."

/obj/effect/proc_holder/spell/pointed/heretic_feint/can_cast(mob/user, skipcharge, silent)
	if(!..() || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/blade_guard) || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/base_blade, 1))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!heretic_check(user, knowledge.held_blade(user), silent, "Возьмите собственный тёмный клинок в руку.") || !heretic_check(user, knowledge.offhand_free(user), silent, "Освободите вторую руку для финта."))
		return FALSE
	if(!heretic_check(user, QDELETED(knowledge.active_parry), silent, "Сначала завершите Выжидание.") || !heretic_check(user, world.time >= knowledge.riposte_until, silent, "Сначала проведите доступный ответный удар или дождитесь конца его окна."))
		return FALSE
	return heretic_check(user, COOLDOWN_FINISHED(knowledge, feint_cooldown), silent, "Финт ещё восстанавливается.")

/obj/effect/proc_holder/spell/pointed/heretic_feint/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return heretic_check(user, isliving(target) && knowledge?.valid_feint_target(user, target), silent, "Нужен доступный для удара противник рядом с вами, без защиты от магии.", target = target)

/obj/effect/proc_holder/spell/pointed/heretic_feint/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!length(targets) || !isliving(targets[1]) || !knowledge?.feint(user, targets[1]))
		heretic_revert_cast(user)

/datum/eldritch_knowledge/base_blade/proc/challenge_key(mob/living/target)
	var/datum/person = target.mind || target
	return REF(person)

/datum/eldritch_knowledge/base_blade/proc/challenge_busy_reason()
	if(active_duel)
		return "Дуэль уже идёт."
	if(challenged_ref?.resolve())
		return "Вы уже ждёте ответа на вызов."
	if(!COOLDOWN_FINISHED(src, challenge_lockout))
		return "После проигранной дуэли вызов закрыт ещё на [heretic_capture_seconds_left(challenge_lockout)] с."
	return null

/datum/eldritch_knowledge/base_blade/proc/challenge_block_reason(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!isliving(user) || heretic?.get_knowledge(type) != src || heretic.role_removed)
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_containment_reason(user) || challenge_busy_reason()
	if(reason)
		return reason
	if(user.incapacitated() || !isturf(user.loc))
		return "Сейчас вы не можете бросить вызов."
	if(!ishuman(target) || target == user)
		return "Вызов бросают человеку."
	var/mob/living/carbon/human/rival = target
	if(!rival.mind)
		return "В этом теле нет того, кто примет вызов."
	if(IS_HERETIC(rival) || IS_HERETIC_MONSTER(rival))
		return "Мансус не стравливает своих."
	if(rival.stat != CONSCIOUS)
		return "Вызов принимают только в сознании."
	if(!isturf(rival.loc) || rival.z != user.z || get_dist(user, rival) > HERETIC_BLADE_CHALLENGE_RANGE)
		return "Цель должна стоять не дальше [HERETIC_BLADE_CHALLENGE_RANGE] клеток."
	if(heretic_blade_hurt_recently(user))
		return "Вы ещё в бою: вызов возможен после [HERETIC_BLADE_CHALLENGE_CALM / (1 SECONDS)] секунд без урона."
	if(heretic_blade_hurt_recently(rival))
		return "[rival] ещё в бою: вызов возможен, когда [HERETIC_BLADE_CHALLENGE_CALM / (1 SECONDS)] секунд его никто не ранит."
	if(!heretic_can_affect(user, rival, chargecost = 0))
		return "Цель защищена от магии: клятва её не свяжет."
	var/repeat_at = challenge_repeat[challenge_key(rival)]
	if(repeat_at > world.time)
		return "[rival] уже отвечал на вызов: повторный - через [heretic_capture_seconds_left(repeat_at)] с."
	return heretic.deed_wait_reason("challenge:[challenge_key(rival)]") || heretic.pocket_pull_reason(user, rival, get_turf(rival), hunt_only = FALSE)

/// Запрос уходит игроку асинхронно, а без игрока в теле вызов сразу считается отказом.
/datum/eldritch_knowledge/base_blade/proc/challenge(mob/living/user, mob/living/target)
	challenge_failure = challenge_block_reason(user, target)
	if(challenge_failure)
		return FALSE
	open_challenge(user, target)
	if(!target.client)
		decline_duel(target, "в теле нет игрока", counts = FALSE)
	else
		INVOKE_ASYNC(src, PROC_REF(ask_duel), user, target, challenge_serial)
	return TRUE

/datum/eldritch_knowledge/base_blade/proc/open_challenge(mob/living/user, mob/living/target)
	challenge_serial++
	challenger_ref = WEAKREF(user)
	challenged_ref = WEAKREF(target)
	deltimer(challenge_timer)
	challenge_timer = addtimer(CALLBACK(src, PROC_REF(challenge_expired), challenge_serial), HERETIC_BLADE_CHALLENGE_TIMEOUT, TIMER_STOPPABLE)
	user.visible_message(span_warning("[user] указывает на [target] и бросает вызов на дуэль!"), span_notice("Вы бросаете вызов [target]. Ответ ждёт [HERETIC_BLADE_CHALLENGE_TIMEOUT / (1 SECONDS)] секунд."))
	log_game("[key_name(user)] бросает вызов на дуэль [key_name(target)] в [AREACOORD(user)].")
	notify_resource_changed()

/datum/eldritch_knowledge/base_blade/proc/close_challenge()
	deltimer(challenge_timer)
	challenge_timer = null
	challenger_ref = null
	challenged_ref = null
	notify_resource_changed()

/datum/eldritch_knowledge/base_blade/proc/clear_challenge()
	close_challenge()
	active_duel?.finish(HERETIC_BLADE_DUEL_DRAW, "дуэлянт-еретик покинул тело")
	active_duel = null

/datum/eldritch_knowledge/base_blade/proc/ask_duel(mob/living/user, mob/living/target, serial)
	var/answer = tgui_alert(target, "[user.name] бросает вам вызов на дуэль. Примете - вас обоих уведёт на арену в изнанке, тесную комнату без свидетелей, на [HERETIC_BLADE_DUEL_DURATION / (1 SECONDS)] секунд: упавший или сдавшийся проиграл. Вызвавший дерётся только клинком: любое его заклинание, кроме Выжидания и призыва сердца или кодекса, - его поражение, и тогда [HERETIC_BLADE_BRAND_DURATION / (1 MINUTES)] минут на его шее будет виден свежий порез. Проигравшего вас клятва удержит на месте [HERETIC_BLADE_OATH_HOLD / (1 SECONDS)] секунд. Отказ ничего не стоит.", "Вызов на дуэль", list(HERETIC_BLADE_CHALLENGE_ACCEPT, HERETIC_BLADE_CHALLENGE_DECLINE), HERETIC_BLADE_CHALLENGE_TIMEOUT)
	if(QDELETED(src) || serial != challenge_serial || challenged_ref?.resolve() != target)
		return
	if(answer == HERETIC_BLADE_CHALLENGE_ACCEPT)
		accept_duel(target)
	else
		decline_duel(target, answer ? "отказ" : "молчание")

/datum/eldritch_knowledge/base_blade/proc/challenge_expired(serial)
	if(serial != challenge_serial)
		return
	challenge_timer = null
	var/mob/living/target = challenged_ref?.resolve()
	if(target)
		decline_duel(target, "молчание")
	else
		close_challenge()

/datum/eldritch_knowledge/base_blade/proc/remember_challenge(mob/living/target)
	for(var/key in challenge_repeat.Copy())
		if(challenge_repeat[key] <= world.time)
			challenge_repeat -= key
	challenge_repeat[challenge_key(target)] = world.time + HERETIC_BLADE_CHALLENGE_REPEAT

/datum/eldritch_knowledge/base_blade/proc/accept_duel(mob/living/target)
	var/mob/living/user = challenger_ref?.resolve()
	if(!user || !target || challenged_ref?.resolve() != target)
		return FALSE
	close_challenge()
	var/turf/accepted_at = get_turf(target)
	log_game("[key_name(target)] принимает вызов на дуэль от [key_name(user)] в [AREACOORD(target)].")
	var/datum/heretic_blade_duel/duel = new(src, user, target)
	active_duel = duel
	var/reason = duel.start()
	if(reason)
		if(active_duel == duel)
			active_duel = null
		qdel(duel)
		to_chat(user, span_warning("Дуэль с [target] не началась: [reason]"))
		to_chat(target, span_warning("Дуэль не началась: [reason]"))
		log_game("Дуэль [key_name(user)] и [key_name(target)] не началась: [reason]")
		return FALSE
	remember_challenge(target)
	count_challenge(user, target, TRUE, accepted_at)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_blade/proc/decline_duel(mob/living/target, reason, counts = TRUE)
	var/mob/living/user = challenger_ref?.resolve()
	if(!target || challenged_ref?.resolve() != target)
		return FALSE
	close_challenge()
	remember_challenge(target)
	log_game("[key_name(target)] не принимает вызов на дуэль от [key_name(user)]: [reason].")
	if(!user)
		return TRUE
	if(counts)
		count_challenge(user, target, FALSE)
	to_chat(user, span_warning("[target] не принимает вызов: [reason]. Снова вызвать - через [HERETIC_BLADE_CHALLENGE_REPEAT / (1 MINUTES)] минут."))
	return TRUE

/// Шаг дела ложится на станции, где бросили или приняли вызов, а не в изнанке.
/datum/eldritch_knowledge/base_blade/proc/count_challenge(mob/living/user, mob/living/target, accepted, atom/trace_at = target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	var/key = challenge_key(target)
	var/counted = heretic.advance_deed("challenge:[key]", trace_at, silent = TRUE)
	if(accepted)
		heretic.advance_deed("duel:[key]", trace_at, silent = TRUE, chained = counted)

/datum/eldritch_knowledge/base_blade/proc/finish_duel(datum/heretic_blade_duel/duel, outcome, reason)
	if(active_duel == duel)
		active_duel = null
	var/mob/living/user = duel.champion
	var/mob/living/rival = duel.rival
	var/datum/heretic_pocket/arena = duel.open_arena()
	log_game("Дуэль [key_name(user)] и [key_name(rival)] окончена ([outcome]): [reason].")
	switch(outcome)
		if(HERETIC_BLADE_DUEL_WON)
			if(user)
				to_chat(user, span_notice("Дуэль выиграна: [reason]."))
			bind_oath(user, rival)
			var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
			if(arena?.contains(rival) && rival.mind && rival.mind == heretic?.hunt_target)
				arena.restart_timer(HERETIC_POCKET_DURATION)
				to_chat(user, span_notice("Соперник - ваша цель охоты: проведите обряд сердцем здесь, пока держит клятва. Изнанка продержится ещё [HERETIC_POCKET_DURATION / (1 SECONDS)] с."))
			else
				arena?.collapse("дуэль выиграна", heretic_escapes = TRUE)
		if(HERETIC_BLADE_DUEL_LOST)
			arena?.collapse("дуэль проиграна")
			combat_resource = 0
			COOLDOWN_START(src, challenge_lockout, HERETIC_BLADE_DUEL_LOCKOUT)
			brand_loser(user)
			if(user)
				to_chat(user, span_warning("Дуэль проиграна: [reason]. Темп потерян, новый вызов - через [HERETIC_BLADE_DUEL_LOCKOUT / (1 MINUTES)] минут."))
			if(rival)
				to_chat(rival, span_notice("Вы выиграли дуэль."))
		else
			arena?.collapse("дуэль окончена вничью")
			for(var/mob/living/fighter in list(user, rival))
				to_chat(fighter, span_notice("Дуэль окончена без победителя: [reason]."))
	notify_resource_changed()

/datum/eldritch_knowledge/base_blade/proc/brand_loser(mob/living/user)
	if(QDELETED(user))
		return
	user.apply_status_effect(/datum/status_effect/heretic_blade_brand)
	for(var/obj/item/melee/sickly_blade/held in user.held_items)
		user.dropItemToGround(held)
	user.visible_message(span_warning("Клинок выскальзывает из руки [user], а на шее проступает свежий порез-знак."), span_userdanger("Клинок выскальзывает из руки, и шею обжигает клеймо проигранного поединка."))

/datum/eldritch_knowledge/base_blade/proc/bind_oath(mob/living/user, mob/living/rival)
	if(QDELETED(user) || QDELETED(rival))
		return FALSE
	var/reason = heretic_capture_block_reason(user, rival, HERETIC_BLADE_OATH_CAPTURE)
	if(reason)
		to_chat(user, span_warning("Клятва не легла на [rival]: [reason]"))
		to_chat(rival, span_notice("Вы проиграли дуэль, но клятва вас не связала."))
		return FALSE
	var/datum/status_effect/heretic_blade_oath/oath = rival.apply_status_effect(/datum/status_effect/heretic_blade_oath)
	if(!oath || QDELETED(oath))
		return FALSE
	log_combat(user, rival, "связывает клятвой проигранной дуэли")
	return TRUE

/datum/eldritch_knowledge/base_blade/proc/disarm(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic?.get_knowledge(/datum/eldritch_knowledge/blade_disarm) || !isliving(victim) || !isturf(victim.loc))
		return FALSE
	var/key = REF(victim)
	if(disarm_ready_at[key] > world.time)
		return FALSE
	var/obj/item/weapon = victim.get_active_held_item()
	if(!weapon || HAS_TRAIT(weapon, TRAIT_NODROP) || (weapon.item_flags & (ABSTRACT | HAND_ITEM)) || !victim.dropItemToGround(weapon) || QDELETED(weapon))
		return FALSE
	var/direction = get_dir(user, victim) || user.dir
	var/turf/landing = get_turf(victim)
	for(var/step_index in 1 to HERETIC_BLADE_DISARM_DISTANCE)
		var/turf/next = get_step(landing, direction)
		if(!next || next.is_blocked_turf(TRUE))
			break
		landing = next
	weapon.forceMove(landing)
	for(var/old_key in disarm_ready_at.Copy())
		if(disarm_ready_at[old_key] <= world.time)
			disarm_ready_at -= old_key
	disarm_ready_at[key] = world.time + HERETIC_BLADE_DISARM_COOLDOWN
	new /obj/effect/temp_visual/dir_setting/heretic_slash(get_turf(victim), direction)
	victim.visible_message(span_danger("Тёмный клинок выбивает [weapon] из руки [victim]!"), span_userdanger("Тёмный клинок выбивает [weapon] у вас из руки!"))
	log_combat(user, victim, "выбивает [weapon] из руки")
	return TRUE

/datum/eldritch_knowledge/base_blade/proc/throat_ready(mob/living/victim)
	if(heretic_capture_downed(victim))
		return TRUE
	return !victim.get_active_held_item() && last_riposte_victim?.resolve() == victim && world.time - last_riposte_at <= HERETIC_BLADE_THROAT_WINDOW

/datum/eldritch_knowledge/base_blade/proc/throat_block_reason(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!isliving(user) || heretic?.get_knowledge(type) != src || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/blade_throat))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_BLADE_THROAT_CAPTURE)
	if(reason)
		return reason
	if(!QDELETED(throat_hold))
		return "Вы уже держите заложника."
	var/mob/living/victim = target
	if(victim.has_status_effect(/datum/status_effect/heretic_blade_throat))
		return "У горла [victim] уже держат клинок."
	if(!held_blade(user))
		return "Возьмите собственный тёмный клинок в руку."
	if(!isturf(user.loc) || !isturf(victim.loc) || !user.Adjacent(victim))
		return "Цель должна стоять вплотную к вам."
	if(!throat_ready(victim))
		return "Клинок к горлу приставляют сбитой с ног цели или цели с пустой рукой после вашего ответа, не позже [HERETIC_BLADE_THROAT_WINDOW / (1 SECONDS)] секунд."
	return null

/datum/eldritch_knowledge/base_blade/proc/draw_throat(mob/living/user, mob/living/victim)
	throat_failure = throat_block_reason(user, victim)
	if(throat_failure)
		return FALSE
	user.visible_message(span_danger("[user] заносит тёмный клинок к горлу [victim]!"), span_notice("Вы заносите клинок к горлу [victim]."))
	playsound(victim, 'sound/items/unsheath.ogg', 40, TRUE)
	addtimer(CALLBACK(src, PROC_REF(seize_throat), user, victim), HERETIC_BLADE_THROAT_TELEGRAPH)
	return TRUE

/datum/eldritch_knowledge/base_blade/proc/seize_throat(mob/living/user, mob/living/victim)
	if(QDELETED(user) || QDELETED(victim))
		return FALSE
	var/reason = throat_block_reason(user, victim)
	if(reason)
		to_chat(user, span_warning("Клинок у горла сорвался: [reason]"))
		return FALSE
	var/datum/status_effect/heretic_blade_throat/hold = victim.apply_status_effect(/datum/status_effect/heretic_blade_throat, user, src)
	if(!hold || QDELETED(hold))
		return FALSE
	throat_hold = hold
	return TRUE

/proc/heretic_blade_hurt_recently(mob/living/fighter)
	var/mob/living/carbon/human/body = fighter
	return istype(body) && !isnull(body.last_hurt_at) && world.time - body.last_hurt_at < HERETIC_BLADE_CHALLENGE_CALM

/// Урон по всем видам без поправок конечностей: удар в руку считается целиком.
/proc/heretic_blade_damage_total(mob/living/body)
	return body.getBruteLoss() + body.getFireLoss() + body.getToxLoss() + body.getOxyLoss() + body.getCloneLoss() + body.getStaminaLoss()

/proc/heretic_blade_duel_beaten(mob/living/fighter)
	return fighter.stat != CONSCIOUS || heretic_capture_downed(fighter) || fighter.IsStun() || fighter.IsParalyzed() || fighter.IsUnconscious()

/datum/heretic_blade_duel
	var/datum/weakref/blade_ref
	var/mob/living/champion
	var/mob/living/rival
	var/datum/heretic_pocket/arena
	var/end_timer
	var/finished = FALSE
	var/datum/action/innate/heretic_blade_surrender/surrender_action

/datum/heretic_blade_duel/New(datum/eldritch_knowledge/base_blade/blade, mob/living/new_champion, mob/living/new_rival)
	. = ..()
	blade_ref = WEAKREF(blade)
	champion = new_champion
	rival = new_rival

/// Причина, по которой арена не открылась, или null; принятый вызов уводит обоих в изнанку без удержания.
/datum/heretic_blade_duel/proc/start()
	if(!fighters_ready())
		return "один из дуэлянтов лежит или не может драться."
	var/turf/first = get_turf(champion)
	var/turf/second = get_turf(rival)
	if(!first || !second || first.z != second.z || get_dist(first, second) > HERETIC_BLADE_CHALLENGE_RANGE)
		return "дуэлянты разошлись дальше [HERETIC_BLADE_CHALLENGE_RANGE] клеток."
	var/datum/antagonist/heretic/heretic = IS_HERETIC(champion)
	if(!heretic)
		return "вызвавший больше не еретик."
	var/reason = heretic.pocket_pull_reason(champion, rival, second, hunt_only = FALSE)
	if(reason)
		return reason
	if(!heretic.pocket_pull(champion, rival, second, 0, CALLBACK(src, PROC_REF(fighters_ready)), "[champion] вскидывает тёмный клинок в салюте, и [rival] принимает вызов.", hunt_only = FALSE, hold_on_entry = FALSE, victim_text = "Вы принимаете вызов, и [champion] вскидывает тёмный клинок в салюте.", duration = HERETIC_BLADE_DUEL_DURATION, intro = FALSE))
		return "арена в изнанке не открылась."
	if(QDELETED(src) || finished)
		heretic.pocket?.collapse("дуэль отменена")
		return "дуэль отменена."
	arena = heretic.pocket
	// Конец дуэли решает её таймер: изнанка держится с запасом, а разрывы называют срок дуэли.
	arena.restart_timer(HERETIC_BLADE_ARENA_DURATION, HERETIC_BLADE_DUEL_DURATION)
	RegisterSignal(arena, COMSIG_HERETIC_POCKET_COLLAPSING, PROC_REF(on_arena_collapsing))
	for(var/mob/living/fighter as anything in list(champion, rival))
		RegisterSignal(fighter, COMSIG_MOVABLE_MOVED, PROC_REF(on_fighter_moved))
		RegisterSignal(fighter, COMSIG_PARENT_QDELETING, PROC_REF(on_fighter_deleted))
	RegisterSignal(champion, COMSIG_MOB_CAST_SPELL, PROC_REF(on_champion_cast))
	surrender_action = new(src)
	surrender_action.Grant(rival)
	START_PROCESSING(SSfastprocess, src)
	end_timer = addtimer(CALLBACK(src, PROC_REF(expire)), HERETIC_BLADE_DUEL_DURATION, TIMER_STOPPABLE)
	to_chat(champion, span_notice("Арена в изнанке на [HERETIC_BLADE_DUEL_DURATION / (1 SECONDS)] секунд. Упадёте, покинете арену или возьмётесь за Хватку или заклинание, кроме Выжидания и призыва сердца или кодекса, - проиграете."))
	to_chat(rival, span_userdanger("Арена в изнанке на [HERETIC_BLADE_DUEL_DURATION / (1 SECONDS)] секунд. Упадёте или вырветесь из изнанки - проиграете; сдаться можно кнопкой «[HERETIC_BLADE_SURRENDER]». Если соперник колдует, кроме Выжидания и призыва сердца или кодекса, поражение его."))
	log_game("Дуэль [key_name(champion)] и [key_name(rival)] начинается в изнанке, вход в [AREACOORD(second)].")
	return null

/datum/heretic_blade_duel/proc/fighters_ready()
	return !QDELETED(champion) && !QDELETED(rival) && !heretic_blade_duel_beaten(champion) && !heretic_blade_duel_beaten(rival)

/// Изнанка этой дуэли, пока она открыта.
/datum/heretic_blade_duel/proc/open_arena()
	return arena?.active ? arena : null

/datum/heretic_blade_duel/proc/contains(atom/thing)
	return arena?.active && arena.contains(thing)

/datum/heretic_blade_duel/process(seconds_per_tick)
	check_outcome()

/datum/heretic_blade_duel/proc/check_outcome()
	if(finished)
		return
	if(QDELETED(champion) || champion.stat == DEAD || heretic_blade_duel_beaten(champion))
		finish(HERETIC_BLADE_DUEL_LOST, "вас свалили")
	else if(!contains(champion))
		finish(HERETIC_BLADE_DUEL_LOST, "вы покинули арену")
	else if(QDELETED(rival) || rival.stat == DEAD)
		finish(HERETIC_BLADE_DUEL_DRAW, "соперник погиб")
	else if(heretic_blade_duel_beaten(rival))
		finish(HERETIC_BLADE_DUEL_WON, "соперник повержен")
	else if(!contains(rival))
		finish(HERETIC_BLADE_DUEL_WON, "соперник покинул арену")

/datum/heretic_blade_duel/proc/surrender(mob/living/fighter)
	if(finished || fighter != rival)
		return FALSE
	rival.visible_message(span_warning("[rival] сдаётся."))
	finish(HERETIC_BLADE_DUEL_WON, "соперник сдался")
	return TRUE

/datum/heretic_blade_duel/proc/expire()
	end_timer = null
	finish(HERETIC_BLADE_DUEL_DRAW, "время вышло")

/datum/heretic_blade_duel/proc/finish(outcome, reason)
	if(finished)
		return
	finished = TRUE
	var/datum/eldritch_knowledge/base_blade/blade = blade_ref?.resolve()
	if(blade)
		blade.finish_duel(src, outcome, reason)
	else if(arena?.active)
		arena.collapse("дуэль прервана")
	qdel(src)

/datum/heretic_blade_duel/proc/on_fighter_moved(datum/source)
	SIGNAL_HANDLER
	check_outcome()

/datum/heretic_blade_duel/proc/on_fighter_deleted(datum/source)
	SIGNAL_HANDLER
	check_outcome()

/// Упавший еретик проигрывает и тогда, когда арену закрыл его же крит; вырвавшийся соперник проигрывает; иначе закрытие снаружи - ничья.
/datum/heretic_blade_duel/proc/on_arena_collapsing(datum/source, reason, mob/living/culprit)
	SIGNAL_HANDLER
	if(QDELETED(champion) || champion.stat == DEAD || heretic_blade_duel_beaten(champion))
		finish(HERETIC_BLADE_DUEL_LOST, "вас свалили")
	else if(culprit && culprit == rival)
		finish(HERETIC_BLADE_DUEL_WON, "соперник вырвался из изнанки")
	else
		finish(HERETIC_BLADE_DUEL_DRAW, "арена закрылась: [reason]")

/datum/heretic_blade_duel/proc/on_champion_cast(mob/living/source, obj/effect/proc_holder/spell/spell)
	SIGNAL_HANDLER
	if(istype(spell, /obj/effect/proc_holder/spell/self/heretic_blade/parry) || istype(spell, /obj/effect/proc_holder/spell/self/heretic_summon))
		return
	finish(HERETIC_BLADE_DUEL_LOST, "заклинание в честном поединке")

/datum/heretic_blade_duel/Destroy()
	finished = TRUE
	STOP_PROCESSING(SSfastprocess, src)
	deltimer(end_timer)
	end_timer = null
	QDEL_NULL(surrender_action)
	for(var/mob/living/fighter in list(champion, rival))
		UnregisterSignal(fighter, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_MOB_CAST_SPELL))
	if(arena)
		UnregisterSignal(arena, COMSIG_HERETIC_POCKET_COLLAPSING)
	var/datum/eldritch_knowledge/base_blade/blade = blade_ref?.resolve()
	if(blade?.active_duel == src)
		blade.active_duel = null
	champion = null
	rival = null
	arena = null
	blade_ref = null
	return ..()

/datum/action/innate/heretic_blade_surrender
	name = "Сдаться"
	desc = "Признать поражение в дуэли. Клятва удержит вас на месте 12 секунд."
	icon_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	button_icon_state = "blade_surrender"
	var/datum/heretic_blade_duel/duel
	var/asking = FALSE

/datum/action/innate/heretic_blade_surrender/New(datum/heretic_blade_duel/new_duel)
	. = ..()
	duel = new_duel

/datum/action/innate/heretic_blade_surrender/Destroy()
	duel = null
	return ..()

/datum/action/innate/heretic_blade_surrender/Activate()
	INVOKE_ASYNC(src, PROC_REF(confirm), owner)

/datum/action/innate/heretic_blade_surrender/proc/confirm(mob/living/fighter)
	if(asking)
		return
	asking = TRUE
	var/answer = wants_surrender(fighter)
	if(QDELETED(src))
		return
	asking = FALSE
	if(!answer || QDELETED(duel) || QDELETED(fighter) || fighter != owner)
		return
	duel.check_outcome()
	if(!QDELETED(duel))
		duel.surrender(fighter)

/// Дуэль не длится дольше своего срока, поэтому и окно сдачи не держит кнопку дольше.
/datum/action/innate/heretic_blade_surrender/proc/wants_surrender(mob/living/fighter)
	return tgui_alert(fighter, "Сдаться? Клятва дуэли удержит вас на месте [HERETIC_BLADE_OATH_HOLD / (1 SECONDS)] секунд.", "Дуэль", list(HERETIC_BLADE_SURRENDER, HERETIC_BLADE_KEEP_FIGHTING), HERETIC_BLADE_DUEL_DURATION) == HERETIC_BLADE_SURRENDER

/datum/status_effect/heretic_blade_oath
	id = "heretic_blade_oath"
	duration = HERETIC_BLADE_OATH_HOLD
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blade_oath
	examine_text = span_warning("SUBJECTPRONOUN скован клятвой проигранной дуэли и не может пошевелиться. Удар нулевым жезлом разорвёт клятву, а растолкать его можно за 2 секунды.")
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/bound = FALSE

/datum/status_effect/heretic_blade_oath/on_apply()
	. = ..()
	if(!.)
		return
	// Свой экземпляр не продлевает и не снимает чужой паралич.
	restraint = new(list(owner, HERETIC_BLADE_OATH_HOLD, TRUE))
	bound = TRUE
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignals(owner, list(COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN), PROC_REF(end_oath))
	heretic_capture_hold(owner, HERETIC_BLADE_OATH_CAPTURE)
	owner.visible_message(span_warning("[owner] застывает: клятва проигранной дуэли держит крепче цепей."), span_userdanger("Вы проиграли дуэль, и клятва сковывает вас на [HERETIC_BLADE_OATH_HOLD / (1 SECONDS)] секунд!"))

/datum/status_effect/heretic_blade_oath/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и клятва дуэли рвётся."), span_notice("Вы разрываете клятву дуэли нулевым жезлом."))
	log_game("[key_name(user)] разрывает клятву дуэли на [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_blade_oath/proc/end_oath(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_blade_oath/on_remove()
	UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	if(bound)
		heretic_capture_unhold(owner, HERETIC_BLADE_OATH_CAPTURE)
		heretic_capture_release(owner, HERETIC_BLADE_OATH_CAPTURE)
	return ..()

/atom/movable/screen/alert/status_effect/heretic_blade_oath
	name = "Клятва дуэли"
	desc = "Вы проиграли дуэль и не можете пошевелиться, пока держит клятва. Удар нулевым жезлом её разорвёт, а товарищ может 2 секунды вас расталкивать."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blade_oath"

/datum/status_effect/heretic_blade_brand
	id = "heretic_blade_brand"
	duration = HERETIC_BLADE_BRAND_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blade_brand
	examine_text = span_warning("SUBJECTPRONOUN носит на шее свежий порез в форме знака: клеймо проигранного поединка.")

/atom/movable/screen/alert/status_effect/heretic_blade_brand
	name = "Клеймо поединка"
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blade_brand"

/atom/movable/screen/alert/status_effect/heretic_blade_brand/Initialize(mapload)
	. = ..()
	desc = "Вы проиграли честный поединок: [HERETIC_BLADE_BRAND_DURATION / (1 MINUTES)] минут на вашей шее виден свежий порез-знак."

/datum/status_effect/heretic_blade_throat
	id = "heretic_blade_throat"
	duration = HERETIC_BLADE_THROAT_DURATION
	tick_interval = HERETIC_BLADE_THROAT_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blade_throat
	examine_text = span_warning("У горла SUBJECTPRONOUN держат тёмный клинок: это заложник. Удар нулевым жезлом по нему или по держащему обрывает захват, а заложника можно растолкать за 2 секунды.")
	var/mob/living/holder
	var/datum/weakref/blade_ref
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/holder_damage
	var/hit_at = -1
	var/hit_damage = 0
	var/release_reason
	var/held = FALSE

/datum/status_effect/heretic_blade_throat/on_creation(mob/living/new_owner, mob/living/new_holder, datum/eldritch_knowledge/base_blade/blade)
	holder = new_holder
	blade_ref = WEAKREF(blade)
	return ..()

/datum/status_effect/heretic_blade_throat/on_apply()
	. = ..()
	if(!.)
		return
	if(QDELETED(holder))
		return FALSE
	restraint = new(list(owner, HERETIC_BLADE_THROAT_DURATION, TRUE))
	held = TRUE
	holder_damage = heretic_blade_damage_total(holder)
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_hostage_moved))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	heretic_capture_hold(owner, HERETIC_BLADE_THROAT_CAPTURE)
	RegisterSignal(holder, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(holder, COMSIG_MOVABLE_MOVED, PROC_REF(on_holder_moved))
	RegisterSignal(holder, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_holder_health))
	RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(on_holder_deleted))
	holder.visible_message(span_danger("[holder] приставляет тёмный клинок к горлу [owner]! Это заложник."), span_notice("Клинок у горла [owner]: ведите заложника шагом, не отходите дальше клетки и не выпускайте клинок."))
	to_chat(owner, span_userdanger("К вашему горлу приставлен клинок: вы не можете пошевелиться!"))
	log_combat(holder, owner, "приставляет клинок к горлу")

/datum/status_effect/heretic_blade_throat/tick()
	var/reason = break_reason()
	if(reason)
		release(reason)

/datum/status_effect/heretic_blade_throat/proc/break_reason()
	var/datum/eldritch_knowledge/base_blade/blade = blade_ref?.resolve()
	if(QDELETED(holder) || !blade)
		return "держащий исчез"
	if(holder.stat != CONSCIOUS || holder.incapacitated() || heretic_capture_downed(holder))
		return "держащего оглушили или сбили"
	if(!blade.held_blade(holder))
		return "клинок выпал из руки"
	if(holder.z != owner.z || get_dist(holder, owner) > 1)
		return "держащий отошёл"
	return null

/datum/status_effect/heretic_blade_throat/proc/release(reason)
	if(QDELETED(src))
		return
	release_reason = reason
	qdel(src)

/datum/status_effect/heretic_blade_throat/proc/on_holder_moved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER
	if(isturf(old_loc) && get_dist(owner, holder) > 1 && get_dist(owner, old_loc) <= 1 && owner.z == old_loc.z)
		owner.Move(old_loc, get_dir(owner, old_loc))
	if(QDELETED(src))
		return
	if(get_dist(owner, holder) > 1 || owner.z != holder.z)
		release("держащий отошёл")

/datum/status_effect/heretic_blade_throat/proc/on_hostage_moved(atom/movable/source)
	SIGNAL_HANDLER
	if(get_dist(owner, holder) > 1 || owner.z != holder.z)
		release("заложника увели")

/datum/status_effect/heretic_blade_throat/proc/on_holder_health(mob/living/carbon/source)
	SIGNAL_HANDLER
	var/damage = heretic_blade_damage_total(holder)
	var/delta = damage - holder_damage
	holder_damage = damage
	if(delta <= 0)
		return
	// Один удар доходит несколькими пересчётами здоровья за тик, поэтому урон тика складывается.
	if(hit_at != world.time)
		hit_at = world.time
		hit_damage = 0
	hit_damage += delta
	if(round(hit_damage, DAMAGE_PRECISION) >= HERETIC_BLADE_THROAT_BREAK_DAMAGE)
		release("держащий получил сильный удар")

/datum/status_effect/heretic_blade_throat/proc/on_attackby(atom/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и клинок у горла дрожит и опускается."), span_notice("Вы касаетесь [source] нулевым жезлом и освобождаете заложника."))
	log_game("[key_name(user)] освобождает заложника [key_name(owner)] нулевым жезлом в [AREACOORD(source)].")
	release("нулевой жезл")
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_blade_throat/proc/on_sacrifice(datum/source)
	SIGNAL_HANDLER
	release("начался обряд")

/datum/status_effect/heretic_blade_throat/proc/on_shaken(datum/source)
	SIGNAL_HANDLER
	release("заложника растолкали")

/datum/status_effect/heretic_blade_throat/proc/on_holder_deleted(datum/source)
	SIGNAL_HANDLER
	release("держащий исчез")

/datum/status_effect/heretic_blade_throat/on_remove()
	UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_MOVABLE_MOVED, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	if(holder)
		UnregisterSignal(holder, list(COMSIG_PARENT_ATTACKBY, COMSIG_MOVABLE_MOVED, COMSIG_CARBON_UPDATEHEALTH, COMSIG_PARENT_QDELETING))
	if(!QDELETED(restraint) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	var/datum/eldritch_knowledge/base_blade/blade = blade_ref?.resolve()
	if(blade?.throat_hold == src)
		blade.throat_hold = null
	if(held)
		heretic_capture_unhold(owner, HERETIC_BLADE_THROAT_CAPTURE)
		if(holder)
			to_chat(holder, span_warning("Заложник свободен: [release_reason || "время вышло"]."))
		log_combat(holder, owner, "отпускает заложника", addition = release_reason || "время вышло")
		heretic_capture_release(owner, HERETIC_BLADE_THROAT_CAPTURE)
	holder = null
	blade_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_blade_throat
	name = "Клинок у горла"
	desc = "К горлу приставлен тёмный клинок: вы не двигаетесь сами и идёте за держащим. Спасёт сильный удар по нему, нулевой жезл, товарищ, который 2 секунды будет вас расталкивать, или если вас уведут."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blade_hostage"

/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge
	name = "Вызов"
	desc = "Бросьте вызов на дуэль человеку не дальше 5 клеток; оба 10 секунд должны быть без урона. Вызов бросают только там, где может открыться изнанка: на станции, не в зоне без телепортации и пока своя изнанка не открыта и не затягивается. На ответ у него 20 секунд. Принявший уходит с вами в изнанку на 60 секунд: упавший или сдавшийся проиграл, ничья выводит обоих к входу. Вы деретесь только клинком и Выжиданием: Хватка или другое заклинание, кроме призыва сердца или кодекса, - поражение. Соперник, вырвавшийся из изнанки, проиграл. Победа связывает соперника клятвой на 12 секунд, растолкать его можно за 2 секунды; над целью охоты обряд идёт там же, остальных изнанка выбрасывает у входа, а вас - к своему выходу. Поражение обнуляет Темп, роняет клинок, на 5 минут оставляет на шее свежий порез-знак и закрывает вызовы на 5 минут. Отказ или молчание ничего не дают, но этого человека снова можно вызвать только через 5 минут."
	summary = "Дуэль с человеком в 5 клетках: изнанка на 60 секунд, проигравшего держит клятва."
	clothes_req = FALSE
	range = HERETIC_BLADE_CHALLENGE_RANGE
	charge_max = 1 SECONDS
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "blade_challenge"
	action_background_icon_state = "bg_ecult"
	aim_assist_radius = 1
	active_msg = "Выберите того, кому бросите вызов."
	deactive_msg = "Вы опускаете клинок."

/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge/can_cast(mob/user, skipcharge, silent)
	if(!..() || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/base_blade))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/reason = knowledge.challenge_busy_reason()
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/reason = knowledge ? knowledge.challenge_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = isliving(target) ? target : null)

/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!length(targets) || !knowledge?.challenge(user, targets[1]))
		heretic_revert_cast(user, knowledge?.challenge_failure)

/obj/effect/proc_holder/spell/pointed/heretic_blade_throat
	name = "Клинок у горла"
	desc = "Приставьте тёмный клинок к горлу соседа, который сбит с ног или остался с пустой рукой после вашего ответа не позже 3 секунд. Через полсекунды цель замирает до 12 секунд и идёт за вами шагом, обряд сердцем над ней работает; цель охоты сердце уводит разрезом в изнанку за 1,5 секунды. Шаг дальше клетки, 15+ урона вам одним ударом, оглушение, падение, выпавший клинок, нулевой жезл или 2 секунды растолкать освобождают заложника. Перезарядка 45 секунд."
	summary = "Заложник: сбитый или обезоруженный ответом сосед замирает до 12 секунд."
	clothes_req = FALSE
	range = 1
	charge_max = HERETIC_BLADE_THROAT_COOLDOWN
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "blade_throat"
	action_background_icon_state = "bg_ecult"
	aim_assist_radius = 1
	active_msg = "Выберите соседнюю цель для клинка у горла."
	deactive_msg = "Вы опускаете клинок."

/obj/effect/proc_holder/spell/pointed/heretic_blade_throat/can_cast(mob/user, skipcharge, silent)
	if(!..() || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/spell/blade_throat) || !heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/base_blade))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return heretic_check(user, knowledge.held_blade(user), silent, "Возьмите собственный тёмный клинок в руку.") && heretic_check(user, QDELETED(knowledge.throat_hold), silent, "Вы уже держите заложника.")

/obj/effect/proc_holder/spell/pointed/heretic_blade_throat/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/reason = knowledge ? knowledge.throat_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = isliving(target) ? target : null)

/obj/effect/proc_holder/spell/pointed/heretic_blade_throat/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!length(targets) || !knowledge?.draw_throat(user, targets[1]))
		heretic_revert_cast(user, knowledge?.throat_failure)

#undef HERETIC_BLADE_LIMIT
#undef HERETIC_BLADE_LUNGE_KNOCKDOWN
#undef HERETIC_BLADE_FEINT_WINDUP
#undef HERETIC_BLADE_FEINT_WINDOW
#undef HERETIC_BLADE_FEINT_COOLDOWN
#undef HERETIC_BLADE_FEINT_DAMAGE
#undef HERETIC_BLADE_FEINT_RANGE
#undef HERETIC_BLADE_IDLE_TEMPO_DELAY
#undef HERETIC_BLADE_IDLE_TEMPO_CAP
#undef HERETIC_BLADE_REGROW_VOLUME
#undef HERETIC_BLADE_OATH_CAPTURE
#undef HERETIC_BLADE_THROAT_CAPTURE
#undef HERETIC_BLADE_THROAT_CHECK
#undef HERETIC_BLADE_DUEL_WON
#undef HERETIC_BLADE_DUEL_LOST
#undef HERETIC_BLADE_DUEL_DRAW
#undef HERETIC_BLADE_CHALLENGE_ACCEPT
#undef HERETIC_BLADE_CHALLENGE_DECLINE
#undef HERETIC_BLADE_SURRENDER
#undef HERETIC_BLADE_KEEP_FIGHTING
