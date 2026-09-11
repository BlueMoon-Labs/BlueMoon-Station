#define HERETIC_MOON_RANGE 5
#define HERETIC_MOON_BASE_LIMIT 2
#define HERETIC_MOON_UPGRADED_LIMIT 3
#define HERETIC_MOON_ASCENDED_LIMIT 5
#define HERETIC_MOON_PRESSURE 8
#define HERETIC_MOON_UPGRADED_PRESSURE 12
#define HERETIC_MOON_ASCENDED_PRESSURE 20

/proc/get_heretic_moon(mob/user)
	var/datum/antagonist/heretic/heretic = user?.mind?.has_antag_datum(/datum/antagonist/heretic)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_moon)

/datum/eldritch_knowledge/base_moon
	name = "Лицо под водой"
	desc = "Открывает Путь Луны. Нож и осколок стекла создают лунный клинок. Отражения повторяют ваш облик и экипировку, движутся и преследуют врагов поблизости. Их ложные удары наносят 8 урона выносливости не чаще раза в две секунды на цель, независимо от числа копий. До двух отражений на 45 секунд; создание раз в 15 секунд. Копии разбиваются от ударов и снарядов."
	gain_text = "Отражение подняло голову раньше меня."
	cost = 0
	route = PATH_MOON
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard)
	result_atoms = list(/obj/item/melee/sickly_blade/moon)
	var/list/mob/living/simple_animal/hostile/illusion/heretic_moon/reflections = list()
	var/mob/living/moon_body
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/reflection_spell
	var/upgraded = FALSE
	var/shrouded = FALSE
	var/refracting = FALSE
	var/ascension_active = FALSE

/datum/eldritch_knowledge/base_moon/on_body_gain(mob/living/user)
	if(!user?.mind || moon_body == user)
		return
	if(moon_body)
		on_body_lose(moon_body)
	moon_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	reflection_spell = new
	user.mind.AddSpell(reflection_spell)

/datum/eldritch_knowledge/base_moon/on_body_lose(mob/living/user)
	if(moon_body)
		UnregisterSignal(moon_body, COMSIG_PARENT_QDELETING)
		moon_body.remove_status_effect(/datum/status_effect/heretic_moon_shroud)
	moon_body = null
	QDEL_NULL(reflection_spell)
	clear_reflections()

/datum/eldritch_knowledge/base_moon/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(moon_body)

/datum/eldritch_knowledge/base_moon/on_death(mob/user)
	clear_reflections()
	moon_body?.remove_status_effect(/datum/status_effect/heretic_moon_shroud)

/datum/eldritch_knowledge/base_moon/Destroy()
	on_body_lose(moon_body)
	return ..()

/datum/eldritch_knowledge/base_moon/proc/clear_reflections()
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections.Copy())
		qdel(reflection)
	reflections.Cut()

/datum/eldritch_knowledge/base_moon/proc/reflection_limit()
	return ascension_active ? HERETIC_MOON_ASCENDED_LIMIT : upgraded ? HERETIC_MOON_UPGRADED_LIMIT : HERETIC_MOON_BASE_LIMIT

/datum/eldritch_knowledge/base_moon/proc/trim_reflections()
	while(length(reflections) > reflection_limit())
		var/mob/living/simple_animal/hostile/illusion/heretic_moon/oldest = reflections[1]
		reflections -= oldest
		qdel(oldest)

/datum/eldritch_knowledge/base_moon/get_combat_resource_data()
	return list(
		"name" = "Отражения",
		"value" = length(reflections),
		"max" = reflection_limit(),
		"description" = "Двойники преследуют врагов и изматывают их ложными ударами. Попадание клинком направляет копии на вашу цель. Зеркальный обмен меняет вас местами со своей копией в пределах пяти клеток. Отражения хрупки и исчезают со временем.",
	)

/// Оба конца обмена остаются на открытом полу: нельзя выбрать шкаф, стену или космос.
/datum/eldritch_knowledge/base_moon/proc/valid_reflection_turf(turf/target, mob/living/user, list/visible, mob/living/simple_animal/hostile/illusion/heretic_moon/ignored_reflection)
	if(!user || user != moon_body || !isturf(user.loc) || user.stat != CONSCIOUS || user.incapacitated())
		return FALSE
	if(!istype(target, /turf/open/floor) || target.z != user.z || get_dist(user, target) > HERETIC_MOON_RANGE)
		return FALSE
	if(!visible)
		visible = view(HERETIC_MOON_RANGE, user)
	if(!(target in visible) || target.is_blocked_turf(source_atom = user, ignore_atoms = list(ignored_reflection)))
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_moon/proc/create_reflection(mob/living/user, turf/target, list/visible)
	if(length(reflections) >= reflection_limit() || !valid_reflection_turf(target, user, visible))
		return null
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/existing as anything in reflections)
		if(get_turf(existing) == target)
			return null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/moon_shroud/shroud = heretic?.get_knowledge(/datum/eldritch_knowledge/moon_shroud)
	var/lifetime = shrouded && shroud ? shroud.passive_values[shroud.passive_level] : 45 SECONDS
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = new(target, src, user, lifetime)
	reflections += reflection
	notify_resource_changed()
	new /obj/effect/temp_visual/heretic_path_feedback(target, "cosmic_ring", "#d6e2ff", 9)
	playsound(target, 'modular_bluemoon/sound/heretic/moon_reflection.ogg', 30, TRUE)
	return reflection

/datum/eldritch_knowledge/base_moon/proc/direct_reflections(mob/living/victim)
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections)
		if(reflection.CanAttack(victim))
			reflection.GiveTarget(victim)

/datum/eldritch_knowledge/base_moon/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && heretic_can_affect(user, target, chargecost = 0))
		direct_reflections(target)

/datum/eldritch_knowledge/base_moon/proc/create_mirages(mob/living/user)
	var/list/visible = view(2, user)
	var/list/positions = list()
	for(var/turf/open/floor/position in visible)
		if(position != get_turf(user) && valid_reflection_turf(position, user, visible))
			positions += position
	if(!length(positions))
		return FALSE
	clear_reflections()
	for(var/turf/position as anything in shuffle(positions))
		create_reflection(user, position, visible)
		if(length(reflections) >= reflection_limit())
			break
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in shuffle(reflections))
		if(exchange(user, reflection))
			break
	return length(reflections) > 0

/datum/eldritch_knowledge/base_moon/proc/can_exchange(mob/living/user, mob/living/simple_animal/hostile/illusion/heretic_moon/reflection)
	if(QDELETED(reflection) || !(reflection in reflections) || reflection.knowledge_ref?.resolve() != src)
		return FALSE
	if(!isturf(reflection.loc) || reflection.buckled)
		return FALSE
	if(!user || user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return FALSE
	var/turf/destination = get_turf(reflection)
	var/turf/origin = get_turf(user)
	if(origin == destination)
		return FALSE
	var/list/visible = view(HERETIC_MOON_RANGE, user)
	if(!valid_reflection_turf(origin, user, visible) || !valid_reflection_turf(destination, user, visible, reflection))
		return FALSE
	var/area/origin_area = get_area(origin)
	var/area/destination_area = get_area(destination)
	return !(origin_area.area_flags & NOTELEPORT) && !(destination_area.area_flags & NOTELEPORT)

/datum/eldritch_knowledge/base_moon/proc/exchange(mob/living/user, mob/living/simple_animal/hostile/illusion/heretic_moon/reflection)
	if(!can_exchange(user, reflection))
		return FALSE
	var/turf/origin = get_turf(user)
	var/turf/destination = get_turf(reflection)
	new /obj/effect/temp_visual/heretic_afterimage(origin, user, "#becfee")
	new /obj/effect/temp_visual/heretic_afterimage(destination, reflection, "#becfee")
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		return FALSE
	if(!QDELETED(reflection))
		reflection.forceMove(origin)
		reflection.sync_appearance()
	playsound(destination, 'modular_bluemoon/sound/heretic/moon_step.ogg', 35, TRUE)
	user.visible_message(span_warning("На мгновение силуэт [user] раздваивается."))
	if(shrouded)
		user.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 1 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/illusion/heretic_moon
	name = "moon reflection"
	maxHealth = 15
	health = 15
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	faction = list("heretics")
	retaliates_against_faction = FALSE
	vision_range = HERETIC_MOON_RANGE
	aggro_vision_range = HERETIC_MOON_RANGE
	atmos_requirements = list()
	minbodytemp = 0
	maxbodytemp = INFINITY
	healable = FALSE
	deathmessage = null
	harm_intent_damage = 10
	vore_active = FALSE
	vore_flags = NONE
	var/datum/weakref/knowledge_ref
	var/reflection_expires_at
	var/reflection_expiry_timer

/mob/living/simple_animal/hostile/illusion/heretic_moon/Initialize(mapload, datum/eldritch_knowledge/base_moon/knowledge, mob/living/model, duration = 45 SECONDS)
	. = ..()
	if(!knowledge || !model)
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(knowledge)
	parent_mob = model
	setDir(model.dir)
	sync_appearance()
	reflection_expires_at = world.time + duration
	reflection_expiry_timer = QDEL_IN_STOPPABLE(src, duration)

/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/sync_appearance()
	if(QDELETED(parent_mob))
		return
	var/facing = dir
	appearance = parent_mob.appearance
	name = parent_mob.name
	real_name = parent_mob.real_name
	gender = parent_mob.gender
	icon_living = parent_mob.icon_state
	setDir(facing)
	var/datum/status_effect/heretic_moon_shroud/shroud = parent_mob.has_status_effect(/datum/status_effect/heretic_moon_shroud)
	if(shroud)
		var/list/copied_filters = parent_mob.filters.Copy()
		var/shroud_index = parent_mob.get_filter_index(shroud.filter_name)
		// Copy() создаёт новые фильтры, поэтому исходную ссылку нельзя вычесть из копии.
		if(shroud_index && shroud_index <= length(copied_filters))
			copied_filters.Cut(shroud_index, shroud_index + 1)
		filters = copied_filters

/mob/living/simple_animal/hostile/illusion/heretic_moon/BiologicalLife(delta_time, times_fired)
	. = ..()
	if(QDELETED(src))
		return
	if(QDELETED(parent_mob) || parent_mob.stat == DEAD)
		qdel(src)
		return
	sync_appearance()

/mob/living/simple_animal/hostile/illusion/heretic_moon/CanAttack(atom/the_target)
	if(!..() || !isturf(the_target.loc) || QDELETED(parent_mob) || parent_mob.stat == DEAD)
		return FALSE
	if(the_target.z != parent_mob.z || get_dist(parent_mob, the_target) > HERETIC_MOON_RANGE || istype(the_target, /mob/living/simple_animal/hostile/illusion/heretic_moon))
		return FALSE
	return heretic_can_affect(parent_mob, the_target, chargecost = 0)

/mob/living/simple_animal/hostile/illusion/heretic_moon/AttackingTarget()
	if(!CanAttack(target) || !Adjacent(target))
		return FALSE
	var/mob/living/victim = target
	setDir(get_dir(src, victim))
	do_attack_animation(victim, used_item = parent_mob.get_active_held_item())
	if(!victim.has_status_effect(/datum/status_effect/heretic_moon_pressure) && heretic_can_affect(parent_mob, victim))
		var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
		var/pressure = knowledge?.ascension_active ? HERETIC_MOON_ASCENDED_PRESSURE : knowledge?.upgraded ? HERETIC_MOON_UPGRADED_PRESSURE : HERETIC_MOON_PRESSURE
		victim.apply_status_effect(/datum/status_effect/heretic_moon_pressure)
		victim.adjustStaminaLoss(pressure)
		playsound(victim, 'sound/weapons/punchmiss.ogg', 35, TRUE)
	return TRUE

/datum/status_effect/heretic_moon_pressure
	id = "heretic_moon_pressure"
	duration = 2 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

/mob/living/simple_animal/hostile/illusion/heretic_moon/Destroy()
	deltimer(reflection_expiry_timer)
	reflection_expiry_timer = null
	if(isturf(loc))
		new /obj/effect/temp_visual/heretic_grasp/moon(get_turf(src))
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	if(knowledge)
		knowledge.reflections -= src
		knowledge.notify_resource_changed()
	knowledge_ref = null
	parent_mob = null
	return ..()

/mob/living/simple_animal/hostile/illusion/heretic_moon/death(gibbed)
	if(stat == DEAD)
		return FALSE
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	if(knowledge?.refracting && knowledge.moon_body)
		for(var/mob/living/victim in view(1, src))
			if(!heretic_can_affect(knowledge.moon_body, victim))
				continue
			victim.blur_eyes(4)
			victim.confused = max(victim.confused, 2)
			if(!victim.has_status_effect(/datum/status_effect/heretic_moon_pressure))
				victim.apply_status_effect(/datum/status_effect/heretic_moon_pressure)
				victim.adjustStaminaLoss(15)
	visible_message(span_warning("[src] рассыпается серебристой пылью."))
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(src), "eye_flash", "#dce8ff", 6)
	for(var/direction in GLOB.cardinals)
		var/obj/effect/temp_visual/heretic_path_feedback/shard = new(get_turf(src), "cosmic_gem", "#c9d8f2", 6)
		animate(shard, pixel_x = 14 * (direction == EAST ? 1 : direction == WEST ? -1 : 0), pixel_y = 14 * (direction == NORTH ? 1 : direction == SOUTH ? -1 : 0), alpha = 0, time = 6)
	playsound(src, 'modular_bluemoon/sound/heretic/moon_break.ogg', 45, TRUE)
	return ..()

/obj/effect/proc_holder/spell/pointed/heretic_moon
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "moon_smile"
	action_background_icon_state = "bg_ecult"
	range = HERETIC_MOON_RANGE
	selection_type = "view"
	aim_assist = FALSE

/obj/effect/proc_holder/spell/pointed/heretic_moon/can_cast(mob/user, skipcharge, silent)
	return ..() && get_heretic_moon(user)

/obj/effect/proc_holder/spell/pointed/heretic_moon/create
	name = "Лунное отражение"
	desc = "Создайте подвижного двойника на видимом свободном полу. Он повторяет ваш облик и изматывает ближайших врагов ложными ударами. Перезарядка 15 секунд; число копий ограничено."
	active_msg = "Выберите открытый пол для отражения."
	deactive_msg = "Лунный свет гаснет в вашей ладони."
	charge_max = 15 SECONDS
	self_castable = TRUE

/obj/effect/proc_holder/spell/pointed/heretic_moon/create/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || !isturf(target) || !knowledge.valid_reflection_turf(target, user) || length(knowledge.reflections) >= knowledge.reflection_limit())
		if(!silent)
			to_chat(user, span_warning("Нужен видимый свободный пол и место для нового отражения."))
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/pointed/heretic_moon/create/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || !knowledge.create_reflection(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_moon/exchange
	name = "Зеркальный обмен"
	desc = "Поменяйтесь местами с выбранным своим двойником в видимости до пяти клеток. Обмен оставляет копию на вашем прежнем месте. Оба места должны быть свободным полом. Перезарядка 12 секунд."
	active_msg = "Выберите своё отражение для обмена местами."
	deactive_msg = "Вы оставляете отражения на своих местах."
	charge_max = 12 SECONDS
	aim_assist = TRUE
	action_icon_state = "mind_gate"

/obj/effect/proc_holder/spell/pointed/heretic_moon/exchange/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || !istype(target, /mob/living/simple_animal/hostile/illusion/heretic_moon) || !knowledge.can_exchange(user, target))
		if(!silent)
			to_chat(user, span_warning("Нельзя обменяться с этим отражением: нужен свободный пол и прямая видимость."))
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/pointed/heretic_moon/exchange/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || !knowledge.exchange(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_moon
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "moon_smile"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_moon/can_cast(mob/user, skipcharge, silent)
	return ..() && get_heretic_moon(user)

/obj/effect/proc_holder/spell/self/heretic_moon/mirage
	name = "Шествие миражей"
	desc = "Замените старые отражения новой группой двойников вокруг себя до текущего предела и поменяйтесь местами со случайной копией, если обмен возможен. Перезарядка 25 секунд."
	charge_max = 25 SECONDS
	action_icon_state = "moon_parade"

/obj/effect/proc_holder/spell/self/heretic_moon/mirage/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || !knowledge.create_mirages(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_moon/eclipse
	name = "Лунное затмение"
	desc = "Вы и ваши двойники в пяти клетках вызываете вспышки радиусом две клетки, путая врагов. Вы оставляете копию на своём месте и почти исчезаете на четыре секунды; атака раскрывает вас. Перезарядка 45 секунд."
	charge_max = 45 SECONDS
	action_icon_state = "moon_ringleader"

/obj/effect/proc_holder/spell/self/heretic_moon/eclipse/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge)
		return
	var/list/visible = view(2, user)
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in knowledge.reflections)
		if(reflection.z == user.z && get_dist(user, reflection) <= HERETIC_MOON_RANGE)
			visible |= view(2, reflection)
	for(var/mob/living/victim in visible)
		if(!heretic_can_affect(user, victim))
			continue
		victim.blur_eyes(6)
		victim.confused = max(victim.confused, 3)
	if(length(knowledge.reflections) >= knowledge.reflection_limit())
		qdel(knowledge.reflections[1])
	knowledge.create_reflection(user, get_turf(user))
	user.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 4 SECONDS)
	for(var/turf/tile in visible)
		new /obj/effect/temp_visual/heretic_path_feedback(tile, "cosmic_carpet", "#b0c1e5", 6)
	new /obj/effect/temp_visual/heretic_spell/moon(get_turf(user))
	playsound(user, 'modular_bluemoon/sound/heretic/moon_eclipse.ogg', 45, TRUE)

/// Именованный фильтр не переписывает alpha, невидимость или чужие эффекты тела.
/datum/status_effect/heretic_moon_shroud
	id = "heretic_moon_shroud"
	duration = 3 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	on_remove_on_mob_delete = TRUE
	var/filter_name

/datum/status_effect/heretic_moon_shroud/on_creation(mob/living/new_owner, duration_override = 3 SECONDS)
	duration = duration_override
	return ..()

/datum/status_effect/heretic_moon_shroud/on_apply()
	. = ..()
	filter_name = "moon-shroud-[REF(src)]"
	owner.add_filter(filter_name, 30, color_matrix_filter(list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,0.08, 0,0,0,0)))
	RegisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER), PROC_REF(reveal))
	return TRUE

/datum/status_effect/heretic_moon_shroud/proc/reveal()
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_moon_shroud/on_remove()
	owner.remove_filter(filter_name)
	UnregisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER))
	return ..()

/datum/status_effect/heretic_moon_shroud/be_replaced()
	// Базовый be_replaced обнуляет owner без on_remove.
	on_remove()
	return ..()

/datum/eldritch_knowledge/moon_grasp
	name = "Касание серебра"
	desc = "Хватка Мансуса размывает зрение врага, наносит 8 дополнительного урона выносливости и направляет на него двойников. Вы почти исчезаете на одну секунду, чтобы сменить позицию; следующая атака снимает покров."
	cost = 1
	route = PATH_MOON

/datum/eldritch_knowledge/moon_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.blur_eyes(3)
	victim.adjustStaminaLoss(8)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	knowledge?.direct_reflections(victim)
	if(isliving(user))
		var/mob/living/caster = user
		caster.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 1 SECONDS)
	return TRUE

/datum/eldritch_knowledge/spell/moon_exchange
	name = "Зеркальный обмен"
	desc = "Позволяет менять позицию с выбранным своим отражением в пределах пяти клеток и прямой видимости. Обмен не переносит через стены и закрытые двери."
	cost = 1
	route = PATH_MOON
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_moon/exchange

/datum/eldritch_knowledge/moon_mark
	name = "Метка Луны"
	desc = "Хватка наносит Метку Луны. Удар лунным клинком активирует её: жертва получает 20 урона выносливости, замедляется на три секунды и теряет ориентацию. Двойники устремляются к вашей цели."
	cost = 2
	route = PATH_MOON

/datum/eldritch_knowledge/moon_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/moon)
	return TRUE

/datum/status_effect/eldritch/moon
	id = "moon_mark"
	mark_name = "Метка Луны"
	mark_alert_state = "sigil_moon"
	effect_sprite = "emark6"
	detonation_sound = 'modular_bluemoon/sound/heretic/moon_break.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_path_feedback/moon_mark

/datum/status_effect/eldritch/moon/on_effect()
	owner.blur_eyes(8)
	owner.confused = max(owner.confused, 5)
	owner.adjustStaminaLoss(20)
	owner.apply_status_effect(/datum/status_effect/heretic_moon_opening)
	return ..()

/datum/status_effect/heretic_moon_opening
	id = "heretic_moon_opening"
	duration = 3 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

/datum/status_effect/heretic_moon_opening/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening)
	return TRUE

/datum/status_effect/heretic_moon_opening/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening)
	return ..()

/datum/movespeed_modifier/heretic_moon_opening
	multiplicative_slowdown = 1.5

/datum/eldritch_knowledge/moon_shroud
	name = "Сумеречный покров"
	desc = "Новые отражения живут 60 секунд. Зеркальный обмен делает вас почти прозрачным на одну секунду; атака снимает покров. Осколок стекла и лист серебра создают ручное зеркало: наведите его на копию, затем на свободный пол, чтобы переставить отражение после секунды подготовки. Можно иметь одно зеркало."
	cost = 1
	route = PATH_MOON
	required_atoms = list(/obj/item/shard, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/silver_mirror)

/datum/eldritch_knowledge/moon_shroud/on_body_gain(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.shrouded = TRUE

/datum/eldritch_knowledge/moon_shroud/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.shrouded = FALSE
	user?.remove_status_effect(/datum/status_effect/heretic_moon_shroud)

/datum/eldritch_knowledge/moon_upgrade
	name = "Третий силуэт"
	desc = "Вы можете поддерживать три отражения. Их ложные удары наносят 12 урона выносливости вместо 8; общий интервал на цель остаётся равным двум секундам."
	cost = 2
	route = PATH_MOON

/datum/eldritch_knowledge/moon_upgrade/on_body_gain(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.upgraded = TRUE

/datum/eldritch_knowledge/moon_upgrade/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.upgraded = FALSE
		knowledge.trim_reflections()

/datum/eldritch_knowledge/spell/moon_mirage
	name = "Шествие миражей"
	desc = "Замените старые отражения новой группой двойников вокруг себя до текущего предела и затеряйтесь среди них, обменявшись со случайной копией. Запреты телепортации сохраняются. Перезарядка 25 секунд."
	cost = 1
	route = PATH_MOON
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_moon/mirage

/datum/eldritch_knowledge/moon_refraction
	name = "Осколки света"
	desc = "Разбитый двойник размывает зрение и путает врагов в соседних клетках, нанося 15 урона выносливости. Урон делит двухсекундный интервал с ложными ударами копий. Истечение времени и замена отражений не вызывают вспышку."
	cost = 2
	route = PATH_MOON

/datum/eldritch_knowledge/moon_refraction/on_body_gain(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.refracting = TRUE

/datum/eldritch_knowledge/moon_refraction/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.refracting = FALSE

/datum/eldritch_knowledge/spell/moon_eclipse
	name = "Лунное затмение"
	desc = "Вызовите вспышки вокруг себя и своих двойников в пяти клетках: враги в двух клетках от каждого силуэта теряют ориентацию. Оставьте копию вместо себя и почти исчезните на четыре секунды. Атака снимает покров. Перезарядка 45 секунд."
	cost = 2
	sacs_needed = 3
	route = PATH_MOON
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_moon/eclipse

/datum/eldritch_knowledge/final_eldritch/moon_final
	parallax_scene = ANTAG_SCENE_HERETIC_MOON
	name = "Обратная сторона Луны"
	desc = "После пяти жертв принесите три человеческих трупа на руну и завершите вознесение. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. Вы поддерживаете до пяти отражений; их ложные удары наносят 20 урона выносливости с общим интервалом две секунды на цель. Вы получаете ослабление входящих ранений."
	gain_text = "Я видел другую сторону. Там каждый взгляд принадлежит мне."
	cost = 3
	route = PATH_MOON
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	damage_modifier = 0.6

/datum/eldritch_knowledge/final_eldritch/moon_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = ..()
	if(.)
		on_body_gain(user)
		to_chat(user, span_eldritch("За каждым плечом теперь скрывается ещё одна ваша тень. Предел отражений увеличен до пяти."))

/datum/eldritch_knowledge/final_eldritch/moon_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished)
		return
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.ascension_active = TRUE

/datum/eldritch_knowledge/final_eldritch/moon_final/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(knowledge)
		knowledge.ascension_active = FALSE
		knowledge.trim_reflections()
	return ..()

/obj/item/melee/sickly_blade/moon
	name = "лунный клинок"
	desc = "Серебристый клинок с двойным лезвием. Его отражение всегда немного запаздывает."
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	icon_state = "moon_blade"
	item_state = "moon_blade"
	mark_type = /datum/status_effect/eldritch/moon
	route = PATH_MOON

#undef HERETIC_MOON_RANGE
#undef HERETIC_MOON_BASE_LIMIT
#undef HERETIC_MOON_UPGRADED_LIMIT
#undef HERETIC_MOON_ASCENDED_LIMIT
#undef HERETIC_MOON_PRESSURE
#undef HERETIC_MOON_UPGRADED_PRESSURE
#undef HERETIC_MOON_ASCENDED_PRESSURE
