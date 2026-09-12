/obj/item/melee/sickly_blade/duelist
	name = "тёмный клинок"
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
	desc = "Открывает Путь Клинка: отбивайте атаки, сближайтесь и отвечайте усиленным ударом. Для парирования держите свой клинок, оставив вторую руку свободной. Обычные попадания, парирования и хватка пополняют Темп для выпада и танца. Нож и лист стали создают тёмный клинок; можно иметь два."
	gain_text = "Между взмахом и раной есть мгновение. Отныне оно принадлежит мне."
	route = PATH_BLADE
	cost = 0
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/melee/sickly_blade/duelist)
	combat_resource_name = "Темп"
	combat_resource_desc = "Начальный запас — 2 Темпа. Удар тёмным клинком даёт 1 Темп раз в 4 секунды; парирование, изученная хватка и активация метки также дают Темп. Выпад стоит 1 Темп, танец — 2. Ответ после парирования бесплатен."
	combat_resource = 2
	combat_resource_max = 3
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_blade/parry
	var/list/created_blades = list()
	var/datum/weakref/duel_target
	var/datum/weakref/riposte_target
	var/riposte_until = 0
	var/datum/status_effect/heretic_parry/active_parry
	var/datum/status_effect/heretic_blade_opening/opening_effect
	var/next_strike_tempo = 0

/datum/eldritch_knowledge/base_blade/on_body_gain(mob/living/user)
	grant_combat_power(user)

/datum/eldritch_knowledge/base_blade/on_body_lose(mob/living/user)
	remove_combat_power()
	QDEL_NULL(active_parry)
	QDEL_NULL(opening_effect)
	user?.remove_status_effect(/datum/status_effect/heretic_blade_dance)
	riposte_target = null
	riposte_until = 0
	duel_target = null

/datum/eldritch_knowledge/base_blade/Destroy()
	QDEL_NULL(active_parry)
	QDEL_NULL(opening_effect)
	created_blades.Cut()
	duel_target = null
	riposte_target = null
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
	if(length(created_blades) >= 2)
		to_chat(user, span_warning("У вас уже есть два тёмных клинка. Потерянный клинок можно вернуть изученным зовом."))
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

/datum/eldritch_knowledge/base_blade/proc/begin_parry(mob/living/user, master = FALSE)
	if(!held_blade(user) || !length(user.get_empty_held_indexes()) || !QDELETED(active_parry))
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	var/window = heretic.get_knowledge(/datum/eldritch_knowledge/blade_guard) ? 3 SECONDS : 2 SECONDS
	if(master)
		if(!heretic.ascended || !heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/blade_final))
			return FALSE
		window = 6 SECONDS
	active_parry = user.apply_status_effect(/datum/status_effect/heretic_parry, src, window, master ? 6 : 2, master)
	user.visible_message(span_warning("[user] поднимает тёмный клинок, выжидая чужой удар."))
	return !!active_parry

/datum/eldritch_knowledge/base_blade/proc/record_parry(mob/living/user, mob/living/attacker)
	gain_combat_resource()
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/blade_guard/guard = heretic?.get_knowledge(/datum/eldritch_knowledge/blade_guard)
	if(guard)
		user.adjustStaminaLoss(-guard.passive_values[guard.passive_level])
	if(!heretic_can_affect(user, attacker, chargecost = 0))
		return
	duel_target = WEAKREF(attacker)
	riposte_target = WEAKREF(attacker)
	riposte_until = world.time + 5 SECONDS
	QDEL_NULL(opening_effect)
	opening_effect = attacker.apply_status_effect(/datum/status_effect/heretic_blade_opening, src)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(user), "eye_flash", "#b4ceff", 6, get_dir(user, attacker))
	to_chat(user, span_notice("Удар отбит! Следующее попадание по [attacker] в течение пяти секунд станет ответным ударом."))

/datum/eldritch_knowledge/base_blade/on_mark_detonated(mob/living/user, mob/living/target)
	. = ..()
	duel_target = WEAKREF(target)

/datum/eldritch_knowledge/base_blade/on_eldritch_blade(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(!proximity_flag || !held_blade(user) || !heretic_can_affect(user, target, chargecost = 0))
		return
	if(world.time >= next_strike_tempo)
		gain_combat_resource()
		next_strike_tempo = world.time + 4 SECONDS
	if(world.time >= riposte_until || riposte_target?.resolve() != target)
		return
	riposte_target = null
	riposte_until = 0
	QDEL_NULL(opening_effect)
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	var/mob/living/victim = target
	var/bonus = 18
	if(heretic.get_knowledge(/datum/eldritch_knowledge/blade_upgrade))
		bonus += 10
	if(heretic.ascended)
		bonus += 12
	victim.adjustBruteLoss(bonus)
	victim.adjustStaminaLoss(15)
	if(heretic.get_knowledge(/datum/eldritch_knowledge/blade_riposte))
		victim.Knockdown(0.6 SECONDS)
	if(user.has_status_effect(/datum/status_effect/heretic_blade_dance))
		user.adjustBruteLoss(-5)
		gain_combat_resource()
	new /obj/effect/temp_visual/dir_setting/heretic_slash(get_turf(user), get_dir(user, victim), TRUE)
	playsound(victim, 'sound/weapons/rapierhit.ogg', 55, TRUE)
	user.visible_message(span_danger("[user] отвечает точным выпадом по [victim]!"))

/datum/status_effect/heretic_parry
	id = "heretic_parry"
	duration = 2 SECONDS
	tick_interval = -1
	alert_type = null
	status_type = STATUS_EFFECT_REPLACE
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/knowledge_ref
	var/expires_at
	var/blocks_left = 1
	var/master_stance = FALSE
	var/next_block = 0
	var/mutable_appearance/stance_overlay

/datum/status_effect/heretic_parry/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blade/knowledge, window, blocks, master = FALSE)
	knowledge_ref = WEAKREF(knowledge)
	duration = window
	expires_at = world.time + window
	blocks_left = blocks
	master_stance = master
	return ..()

/datum/status_effect/heretic_parry/on_apply()
	. = ..()
	if(!.)
		return FALSE
	RegisterSignal(owner, COMSIG_LIVING_RUN_BLOCK, PROC_REF(parry_attack))
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(keep_stance_overlay))
	stance_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_feedback.dmi', "ring_leader_effect", ABOVE_MOB_LAYER)
	stance_overlay.color = master_stance ? "#edc767" : "#b6c9f4"
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_parry/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_ATOM_UPDATE_OVERLAYS))
	owner.update_icon()
	stance_overlay = null
	var/datum/eldritch_knowledge/base_blade/knowledge = knowledge_ref?.resolve()
	if(knowledge?.active_parry == src)
		knowledge.active_parry = null
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

/datum/status_effect/heretic_blade_opening/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blade/knowledge)
	knowledge_ref = WEAKREF(knowledge)
	return ..()

/datum/status_effect/heretic_blade_opening/on_apply()
	. = ..()
	if(!.)
		return FALSE
	opening_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_feedback.dmi', "sigil_blade", ABOVE_MOB_LAYER)
	opening_overlay.transform = matrix() * 0.6
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(keep_opening_overlay))
	owner.update_icon()
	to_chat(owner, span_userdanger("Ваш удар отбит: пять секунд противник может ответить усиленным выпадом. Разорвите дистанцию!"))
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

/datum/status_effect/heretic_parry/proc/parry_attack(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(!real_attack || (damage <= 0 && !(attack_type & ATTACK_TYPE_UNARMED)) || world.time >= expires_at || world.time < next_block || blocks_left <= 0)
		return BLOCK_NONE
	if((attack_type & ATTACK_TYPE_PARRY_COUNTERATTACK) || !(attack_type & (ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED | ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_THROWN)))
		return BLOCK_NONE
	var/datum/eldritch_knowledge/base_blade/knowledge = knowledge_ref?.resolve()
	if(!knowledge?.held_blade(source) || !length(source.get_empty_held_indexes()))
		return BLOCK_NONE
	if(ismob(attacker) && (attacker == source || IS_HERETIC(attacker) || IS_HERETIC_MONSTER(attacker)))
		return BLOCK_NONE
	if(!(attack_type & (ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_THROWN)) && !source.Adjacent(attacker))
		return BLOCK_NONE
	blocks_left--
	next_block = world.time + 0.3 SECONDS
	knowledge.record_parry(source, attacker)
	playsound(source, 'modular_bluemoon/sound/heretic/parry.ogg', 60, TRUE)
	if(!blocks_left)
		qdel(src)
	return BLOCK_SUCCESS

/datum/eldritch_knowledge/blade_grasp
	name = "Вызов"
	desc = "Хватка Мансуса наносит ещё 10 урона выносливости и восстанавливает 1 Темп. Запас Темпа также пополняется обычными ударами тёмного клинка."
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
	desc = "Открывает выпад: за 1 Темп сблизьтесь с видимой целью на расстоянии до пяти клеток и нанесите 20 ушибов и 20 урона выносливости. Стены и закрытые двери преграждают путь. Перезарядка 10 секунд."
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
	name = "Неподвижная грань"
	desc = "Окно «Выжидания» увеличивается до 3 секунд; лимит остаётся равным двум блокам. Парирование восстанавливает 10 выносливости. Вилка и два стальных прута создают камертон: при пустом Темпе две секунды настройки обменивают 8 ушибов на 1 Темп; нужен клинок во второй руке. Можно иметь один камертон."
	route = PATH_BLADE
	cost = 1
	required_atoms = list(/obj/item/kitchen/fork, /obj/item/stack/rods, /obj/item/stack/rods)
	result_atoms = list(/obj/item/heretic_path_relic/tuning_fork)

/datum/eldritch_knowledge/blade_upgrade
	name = "Точная линия"
	desc = "Ответный удар после парирования наносит 28 дополнительных ушибов вместо 18. Темп не расходуется; ответ действует против последнего нападавшего в течение пяти секунд."
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
	desc = "Успешный ответный удар после парирования сбивает противника с ног на 0,6 секунды."
	route = PATH_BLADE
	cost = 2

/datum/eldritch_knowledge/spell/blade_dance
	name = "Ритм поединка"
	desc = "За 2 Темпа на 10 секунд вы двигаетесь быстрее. Ответные удары в это время лечат 5 ушибов и дают дополнительный Темп."
	route = PATH_BLADE
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blade/dance

/datum/eldritch_knowledge/final_eldritch/blade_final
	parallax_scene = ANTAG_SCENE_HERETIC_BLADE
	name = "Последний поединок"
	desc = "После трёх подношений проведите обряд над тремя трупами. Начало обряда раскроет его место станции и даст экипажу 30 секунд, чтобы помешать. Ответный удар получает ещё 12 урона. «Тысяча граней» на 6 секунд блокирует до шести ударов или снарядов, не чаще раза в 0,3 секунды. Нужен свой клинок и свободная вторая рука."
	gain_text = "Острие остановилось у самого сердца мира. Я ещё решаю, наносить ли удар."
	route = PATH_BLADE
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_blade/master)

/datum/eldritch_knowledge/final_eldritch/blade_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	return TRUE

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
	if(!..() || !isliving(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return knowledge && heretic.get_knowledge(required_knowledge) && knowledge.combat_resource >= resource_cost && (!requires_blade || knowledge.held_blade(user))

/obj/effect/proc_holder/spell/self/heretic_blade/parry
	name = "Выжидание"
	desc = "За 2 секунды отбейте два удара или снаряда своим клинком; улучшенная стойка длится 3 секунды. Между блоками 0,3 секунды, вторая рука должна быть свободна. Парирование даёт бесплатный ответный удар по нападавшему."
	charge_max = 8 SECONDS
	action_icon_state = "furious_steel"

/obj/effect/proc_holder/spell/self/heretic_blade/parry/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge?.begin_parry(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_blade/parry/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return QDELETED(knowledge.active_parry) && length(user.get_empty_held_indexes())

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
		revert_cast(user)
		return
	for(var/datum/weakref/blade_ref in knowledge.created_blades)
		var/obj/item/melee/sickly_blade/duelist/blade = blade_ref.resolve()
		if(blade?.bound_mind != user.mind || !isturf(blade.loc) || !(blade in view(7, user)))
			continue
		if(!user.put_in_hands(blade))
			revert_cast(user)
			return
		playsound(user, 'sound/magic/repulse.ogg', 35, TRUE)
		return
	to_chat(user, span_warning("В поле зрения нет вашего свободно лежащего клинка."))
	revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_blade/dance
	name = "Танец граней"
	desc = "Потратьте 2 Темпа: десять секунд ускоренного движения, ответные удары лечат 5 ушибов и дают Темп. Потеря клинка прерывает танец."
	required_knowledge = /datum/eldritch_knowledge/spell/blade_dance
	charge_max = 30 SECONDS
	action_icon_state = "cursed_steel"
	resource_cost = 2

/obj/effect/proc_holder/spell/self/heretic_blade/dance/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!knowledge?.held_blade(user) || !heretic.get_knowledge(required_knowledge) || !knowledge.spend_combat_resource(resource_cost))
		revert_cast(user)
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

/obj/effect/proc_holder/spell/self/heretic_blade/master
	name = "Тысяча граней"
	desc = "На 6 секунд отразите до шести ударов или снарядов, не чаще раза в 0,3 секунды. Требуются собственный тёмный клинок и свободная вторая рука."
	required_knowledge = /datum/eldritch_knowledge/final_eldritch/blade_final
	charge_max = 45 SECONDS
	action_icon_state = "blade_master"

/obj/effect/proc_holder/spell/self/heretic_blade/master/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(!heretic?.ascended || !heretic.get_knowledge(required_knowledge) || !knowledge?.begin_parry(user, master = TRUE))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_blade/master/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return heretic.ascended && QDELETED(knowledge.active_parry) && length(user.get_empty_held_indexes())

/obj/effect/proc_holder/spell/pointed/heretic_lunge
	name = "Выпад"
	desc = "За 1 Темп сблизьтесь с противником до пяти клеток по свободному пути: 20 ушибов и 20 урона выносливости. Требуется собственный тёмный клинок в руке."
	clothes_req = FALSE
	charge_max = 10 SECONDS
	range = 5
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "cleave"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/heretic_lunge/can_target(atom/target, mob/user, silent)
	return heretic_can_affect(user, target, chargecost = 0)

/obj/effect/proc_holder/spell/pointed/heretic_lunge/can_cast(mob/user, skipcharge, silent)
	if(!..() || !isliving(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return knowledge?.held_blade(user) && heretic.get_knowledge(/datum/eldritch_knowledge/spell/blade_lunge) && knowledge.combat_resource > 0

/obj/effect/proc_holder/spell/pointed/heretic_lunge/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/mob/living/victim = length(targets) ? targets[1] : null
	if(!knowledge?.held_blade(user) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/blade_lunge) || !isliving(victim) || !(victim in view(range, user)) || knowledge.combat_resource < 1)
		revert_cast(user)
		return
	var/turf/start = get_turf(user)
	var/turf/route_step = start
	for(var/steps in 1 to range)
		if(get_dist(route_step, victim) <= 1)
			break
		route_step = get_step_towards(route_step, victim)
		if(is_blocked_turf(route_step, TRUE))
			to_chat(user, span_warning("Путь для выпада перекрыт."))
			revert_cast(user)
			return
	if(!heretic_can_affect(user, victim) || !knowledge.spend_combat_resource())
		revert_cast(user)
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
			revert_cast(user)
		to_chat(user, span_warning("Путь для выпада перекрыт."))
		return
	knowledge.duel_target = WEAKREF(victim)
	victim.adjustBruteLoss(20)
	victim.adjustStaminaLoss(20)
	new /obj/effect/temp_visual/dir_setting/heretic_slash(get_turf(user), get_dir(user, victim))
	playsound(victim, 'sound/weapons/rapierhit.ogg', 50, TRUE)
