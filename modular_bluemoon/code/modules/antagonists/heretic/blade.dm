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
	desc = "Открывает Путь Клинка: отбивайте атаки, сближайтесь и отвечайте усиленным ударом. Для парирования держите свой клинок, оставив вторую руку свободной; хватка Мансуса в ней не мешает, а после вознесения вторая рука не нужна. Обычные попадания и парирования пополняют Темп для выпада и танца, после изучения «Вызова» его даёт и хватка. Пустой Темп вне боя восстанавливается до единицы. Нож и лист стали создают тёмный клинок; можно иметь три."
	gain_text = "Между взмахом и раной есть мгновение. Отныне оно принадлежит мне."
	route = PATH_BLADE
	cost = 0
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/melee/sickly_blade/duelist)
	combat_resource_name = "Темп"
	combat_resource_desc = "Начальный запас — 2 Темпа. Удар тёмным клинком даёт 1 Темп раз в 4 секунды; парирование и активация метки также дают Темп, хватка — после изучения «Вызова». Если Темп пуст, а 8 секунд вы не наносили ударов клинком и не парировали, возвращается 1 Темп. Выпад, финт, танец и круговой разрез стоят по 1 Темпу. Ответ после парирования бесплатен."
	combat_resource = 2
	combat_resource_max = 3
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_blade/parry
	var/list/created_blades = list()
	var/datum/weakref/duel_target
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

/datum/eldritch_knowledge/base_blade/on_body_gain(mob/living/user)
	grant_combat_power(user)

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
	QDEL_NULL(active_parry)
	QDEL_NULL(opening_effect)
	user?.remove_status_effect(/datum/status_effect/heretic_blade_dance)
	riposte_target = null
	riposte_until = 0
	riposte_ready_at = 0
	feint_opening = FALSE
	feint_knowledge_ref = null
	duel_target = null

/datum/eldritch_knowledge/base_blade/Destroy()
	QDEL_NULL(active_parry)
	QDEL_NULL(opening_effect)
	created_blades.Cut()
	duel_target = null
	riposte_target = null
	feint_knowledge_ref = null
	return ..()

/datum/eldritch_knowledge/base_blade/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !isitem(target) || !isturf(target.loc))
		return FALSE
	var/obj/item/steel = target
	if(steel.sharpness == SHARP_NONE || steel.anchored || istype(steel, /obj/item/melee/sickly_blade))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return FALSE
	var/turf/steel_turf = get_turf(steel)
	playsound(steel_turf, 'sound/items/screwdriver.ogg', 40, TRUE)
	new /obj/effect/temp_visual/heretic_grasp/blade(steel_turf)
	user.visible_message(span_warning("[steel] рассыпается стальной стружкой в ладони [user]."))
	heretic.advance_deed("[steel.type]", steel_turf)
	qdel(steel)
	return TRUE

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
		user.visible_message(span_warning("[user] поднимает тёмный клинок, выжидая чужой удар."), span_notice("Парирование включено: блоков — [active_parry.blocks_left], длительность — [window / (1 SECONDS)] сек."))
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
	duel_target = WEAKREF(attacker)
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

/datum/eldritch_knowledge/base_blade/on_mark_detonated(mob/living/user, mob/living/target)
	. = ..()
	duel_target = WEAKREF(target)

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
	var/bonus = 18
	if(from_feint)
		bonus = HERETIC_BLADE_FEINT_DAMAGE
	else if(heretic.get_knowledge(/datum/eldritch_knowledge/blade_upgrade))
		bonus += 10
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
		to_chat(owner, span_warning("Парирование не действует! [reason]"))
	else if(!reason && !stance_ready)
		to_chat(owner, span_notice("Парирование снова действует."))
	stance_ready = !reason
	if(linked_alert)
		var/remaining = CEILING(max(0, expires_at - world.time) / (1 SECONDS), 1)
		linked_alert.name = stance_ready ? "Парирование: активно" : "Парирование: не действует"
		linked_alert.desc = "Осталось блоков: [blocks_left]; времени: [remaining] сек. [reason || "Держите свой клинок в руке и оставьте вторую руку свободной."]"
		linked_alert.color = stance_ready ? "#b6c9f4" : "#ff7766"
		linked_alert.maptext = MAPTEXT("<div style='text-align:center;font-size:8px;background-color:#17111d'>[stance_ready ? blocks_left : "!"]<br>[remaining]с</div>")
	return stance_ready

/atom/movable/screen/alert/status_effect/heretic_parry
	name = "Парирование"
	desc = "Свой клинок и свободная вторая рука позволяют отражать атаки."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_blade"
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
			to_chat(owner, span_notice("Парирование окончено: [blocks_left ? "время стойки вышло" : "все блоки израсходованы"]."))
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
	if(!blocks_left)
		qdel(src)
	else
		update_stance_feedback()
	return BLOCK_SUCCESS

/datum/eldritch_knowledge/blade_grasp
	parent_type = /datum/eldritch_knowledge/spell
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blade/sweep
	name = "Вызов"
	desc = "Открывает Круговой разрез: за 1 Темп нанесите соседним врагам 20 ушибов и 25 урона выносливости, оттолкнув на клетку. Стены перекрывают удар; перезарядка 14 секунд. Хватка также наносит ещё 10 урона выносливости и восстанавливает 1 Темп."
	gain_text = "Я различаю в толпе лишь одно движение."
	route = PATH_BLADE
	cost = 1

/datum/eldritch_knowledge/blade_grasp/on_mansus_grasp(atom/target, mob/living/user, proximity_flag)
	if(!proximity_flag || !heretic_can_affect(user, target))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge)
		return FALSE
	knowledge.duel_target = WEAKREF(target)
	knowledge.gain_combat_resource()
	var/mob/living/victim = target
	victim.adjustStaminaLoss(10)
	return TRUE

/datum/eldritch_knowledge/spell/blade_lunge
	name = "Шаг между ударами"
	desc = "Открывает выпад: за 1 Темп сблизьтесь с видимой целью на расстоянии до пяти клеток и нанесите 20 ушибов и 20 урона выносливости, опрокинув цель на 1,5 секунды. По противнику, чью атаку вы только что парировали, выпад также проводит ответный удар. Стены и закрытые двери преграждают путь. Перезарядка 10 секунд."
	route = PATH_BLADE
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_lunge

/datum/eldritch_knowledge/blade_mark
	name = "Метка поединка"
	desc = "Хватка оставляет метку Клинка. Попадание тёмным клинком активирует её: цель теряет 25 выносливости, а вы получаете 1 Темп."
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
	desc = "Окно «Выжидания» увеличивается до 3 секунд, а запас — до четырёх блоков. Парирование восстанавливает 10 выносливости. Открывает Финт: за 1 Темп, со своим клинком и свободной второй рукой, раскройте видимую цель до трёх клеток. Через 0,6 секунды открывается трёхсекундное окно для дополнительных 10 ушибов следующим попаданием. Финт не складывается с ответом после парирования и не получает его усилений; перезарядка 8 секунд. Вилка и два стальных прута создают камертон: при пустом Темпе две секунды настройки обменивают 8 ушибов на 1 Темп; нужен клинок во второй руке. Можно иметь один камертон."
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

/datum/eldritch_knowledge/blade_upgrade
	name = "Точная линия"
	desc = "Ответный удар после парирования наносит 28 дополнительных ушибов вместо 18. Его проводит следующее попадание клинком или Выпад по последнему нападавшему в течение пяти секунд. Бонус не расходует Темп; сам Выпад по-прежнему стоит 1 Темп."
	route = PATH_BLADE
	cost = 2

/datum/eldritch_knowledge/spell/blade_recall
	name = "Память стали"
	desc = "Позволяет вернуть в свободную руку свой тёмный клинок, лежащий на полу в поле зрения не далее семи клеток. Чужие руки и закрытые контейнеры удержат оружие."
	route = PATH_BLADE
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blade/recall

/datum/eldritch_knowledge/blade_riposte
	name = "Ошибка противника"
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	desc = "Успешный ответный удар после парирования сбивает противника с ног на 0,6 секунды."
	route = PATH_BLADE
	cost = 2

/datum/eldritch_knowledge/spell/blade_dance
	name = "Ритм поединка"
	desc = "За 1 Темп на 10 секунд вы двигаетесь быстрее. Ответные удары в это время лечат 5 ушибов и дают дополнительный Темп."
	route = PATH_BLADE
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blade/dance

/datum/eldritch_knowledge/final_eldritch/blade_final
	parallax_scene = ANTAG_SCENE_HERETIC_BLADE
	name = "Последний поединок"
	desc = "После трёх подношений проведите обряд над тремя трупами. Начало обряда раскроет его место станции и даст экипажу 30 секунд, чтобы помешать. После вознесения вы получаете общую стойкость вознесения. Вокруг вас кружат четыре клинка: каждый целиком принимает на себя один удар, бросок или снаряд и разбивается, новый появляется раз в 6 секунд. Картечь - это отдельные дробины, один выстрел сдирает всю орбиту. Попадание тёмным клинком по живому врагу лечит вам четверть нанесённого им урона. Ответный удар после парирования получает ещё 12 урона; удар после финта не усиливается. Парирование и финт больше не требуют свободной второй руки. «Буря клинков» бросает все кружащие клинки в ближайших видимых врагов в семи клетках, по клинку на врага: 20 ушибов и 20 урона выносливости каждому, окна, решётки и стены перехватывают клинок. После броска орбита собирается заново. Перезарядка 30 секунд. Смерть снимает эти усиления, оживление возвращает."
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

/datum/component/heretic_blade_orbit/proc/remove_blades(amount = 1)
	var/atom/movable/owner = parent
	for(var/count in 1 to min(amount, length(orbit_blades)))
		var/obj/effect/heretic_orbit_blade/blade = orbit_blades[length(orbit_blades)]
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
	desc = "За 2 секунды отбейте три удара или снаряда своим клинком; улучшенная стойка длится 3 секунды и даёт четыре блока. Блоки работают и против одновременных попаданий; вторая рука должна быть свободна или держать хватку Мансуса, после вознесения это условие снимается. Парирование даёт бесплатный ответный удар по нападавшему. Пока стойка готова, удары принимает она, а не клинки орбиты."
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
	return heretic_check(user, QDELETED(knowledge.active_parry), silent, "Вы уже удерживаете стойку.") && heretic_check(user, knowledge.offhand_free(user), silent, "Парирование не включено: освободите вторую руку.")

/obj/effect/proc_holder/spell/self/heretic_blade/recall
	name = "Зов клинка"
	desc = "Верните свой клинок с пола в свободную руку. Требуются видимость и расстояние до семи клеток."
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

/obj/effect/proc_holder/spell/self/heretic_blade/sweep
	name = "Круговой разрез"
	desc = "За 1 Темп нанесите соседним врагам 20 ушибов и 25 урона выносливости, оттолкнув на клетку. Требуется собственный тёмный клинок; стены перекрывают удар."
	required_knowledge = /datum/eldritch_knowledge/blade_grasp
	charge_max = 14 SECONDS
	action_icon_state = "cleave"
	resource_cost = 1
	var/sweep_damage = 20
	var/sweep_stamina = 25

/obj/effect/proc_holder/spell/self/heretic_blade/sweep/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge?.held_blade(user) || !heretic.get_knowledge(required_knowledge) || !isturf(user.loc) || !knowledge.spend_combat_resource(resource_cost))
		heretic_revert_cast(user)
		return
	var/turf/center = get_turf(user)
	for(var/mob/living/victim in range(1, center))
		if(!isturf(victim.loc) || is_blocked_turf(get_turf(victim), TRUE) || !user.Adjacent(victim) || !heretic_can_affect(user, victim))
			continue
		victim.adjustBruteLoss(sweep_damage)
		victim.adjustStaminaLoss(sweep_stamina)
		COOLDOWN_START(knowledge, idle_tempo, HERETIC_BLADE_IDLE_TEMPO_DELAY)
		new /obj/effect/temp_visual/dir_setting/heretic_slash(get_turf(victim), get_dir(user, victim))
		if(!victim.anchored && !victim.buckled)
			step_away(victim, center)
		log_combat(user, victim, "поражает круговым разрезом")
	playsound(user, 'sound/weapons/rapierhit.ogg', 60, TRUE)
	user.visible_message(span_danger("[user] описывает тёмным клинком широкий круг!"))

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
	desc = "Бросьте кружащие вокруг вас клинки в ближайших видимых врагов в семи клетках, по клинку на врага, до четырёх целей: каждый получает 20 ушибов и 20 урона выносливости. Окна, решётки и стены перехватывают клинки. Нужен хотя бы один клинок на орбите; свой клинок в руке не нужен. Орбита собирается заново по клинку раз в 6 секунд. Перезарядка 30 секунд."
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
	var/list/launch_angles = list()
	for(var/obj/effect/heretic_orbit_blade/blade as anything in orbit.orbit_blades)
		launch_angles += blade.orbit_angle()
	for(var/index in 1 to length(victims))
		var/mob/living/victim = victims[index]
		heretic_blade_storm_fx(origin, victim, launch_angles[index], index % 2 ? 1 : -1, index == 1)
		victim.apply_damage(HERETIC_BLADE_STORM_BRUTE, BRUTE, BODY_ZONE_CHEST)
		victim.adjustStaminaLoss(HERETIC_BLADE_STORM_STAMINA)
		log_combat(user, victim, "поражает Бурей клинков")
	orbit.remove_blades(length(orbit.orbit_blades))
	heretic_blade_storm_cast_fx(user)
	playsound(user, 'sound/weapons/rapierhit.ogg', 60, TRUE)
	user.visible_message(span_danger("Клинки, кружившие вокруг [user], разом срываются к врагам!"))

/obj/effect/proc_holder/spell/pointed/heretic_lunge
	name = "Выпад"
	desc = "За 1 Темп сблизьтесь с противником до пяти клеток по свободному пути: 20 ушибов, 20 урона выносливости и падение на 1,5 секунды. Выпад по только что парированному противнику также расходует и проводит ответный удар. Требуется собственный тёмный клинок в руке."
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
	knowledge.duel_target = WEAKREF(victim)
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
	desc = "За 1 Темп раскройте видимого противника до трёх клеток. Через 0,6 секунды следующее попадание клинком или выпадом в течение трёх секунд нанесёт ещё 10 ушибов. Нужны свой клинок и свободная вторая рука. Стены, стойка и уже открытый ответ мешают финту; усиления парирования на него не действуют."
	clothes_req = FALSE
	range = HERETIC_BLADE_FEINT_RANGE
	charge_max = HERETIC_BLADE_FEINT_COOLDOWN
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "furious_steel"
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
	if(!heretic_check(user, QDELETED(knowledge.active_parry), silent, "Сначала завершите текущую стойку.") || !heretic_check(user, world.time >= knowledge.riposte_until, silent, "Сначала проведите доступный ответный удар или дождитесь конца его окна."))
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
