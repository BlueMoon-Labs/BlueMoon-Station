#define HERETIC_MOON_RANGE 5
#define HERETIC_MOON_WITNESS_RANGE 7
#define HERETIC_MOON_BASE_LIMIT 2
#define HERETIC_MOON_SHROUD_LIMIT 3
#define HERETIC_MOON_ASCENDED_LIMIT 5
#define HERETIC_MOON_PRESSURE 18
#define HERETIC_MOON_ASCENDED_PRESSURE 30
#define HERETIC_MOON_DAMAGE 5
#define HERETIC_MOON_ASCENDED_DAMAGE 10
#define HERETIC_MOON_HEALTH 30
#define HERETIC_MOON_SHROUD_HEALTH 40
#define HERETIC_MOON_ASCENDED_HEALTH 50
#define HERETIC_MOON_LIFETIME (45 SECONDS)
#define HERETIC_MOON_POST_WANDER_CHANCE 50
#define HERETIC_MOON_SLEEPWALK_FILTER "heretic_moon_sleepwalk"
#define HERETIC_MOON_SLEEPWALK_PATH_LIMIT 20
#define HERETIC_MOON_SLEEPWALK_ROUTE_MISSES 2
#define HERETIC_MOON_DOOR_ALERT "heretic_moon_door"
#define HERETIC_MOON_REFRACTION_RADIUS 2
#define HERETIC_MOON_MASQUERADE_RANGE 7
#define HERETIC_MOON_MASQUERADE_TARGETS 5
#define HERETIC_MOON_MASQUERADE_STAMINA 30
#define HERETIC_MOON_MASQUERADE_CONFUSION 3
#define HERETIC_MOON_MASQUERADE_LIFETIME (10 SECONDS)
#define HERETIC_MOON_SHROUD_AURA_ALPHA 20
#define HERETIC_MOON_SILVER "#dce8ff"
#define HERETIC_MOON_GHOST_TIME (0.3 SECONDS)
#define HERETIC_MOON_GHOST_ALPHA 140
#define HERETIC_MOON_GHOST_SPLIT 6
#define HERETIC_MOON_SHATTER_TIME (0.35 SECONDS)
#define HERETIC_MOON_SHATTER_SCALE 1.15
#define HERETIC_MOON_SHATTER_FLASH_RANGE 2
#define HERETIC_MOON_SHATTER_FLASH_POWER 1.2
#define HERETIC_MOON_SHATTER_FLASH_TIME (0.3 SECONDS)
#define HERETIC_MOON_EYE_HEIGHT 20
#define HERETIC_MOON_EYE_DIM "#9aa2c8"
#define HERETIC_MOON_EYE_FLICKER (0.7 SECONDS)
#define HERETIC_MOON_HALO_SIZE 2
#define HERETIC_MOON_HALO_COLOR "#c9d8ff70"
#define HERETIC_MOON_JITTER_INTERVAL (1 SECONDS)
#define HERETIC_MOON_JITTER_CHANCE 40
#define HERETIC_MOON_JITTER_OFFSET 3
#define HERETIC_MOON_MASQUERADE_GHOST_OFFSET 8
#define HERETIC_MOON_MASQUERADE_WAVE_TIME (0.4 SECONDS)
#define HERETIC_MOON_MASQUERADE_FLASH_POWER 1.5
#define HERETIC_MOON_MASQUERADE_FLASH_TIME (0.5 SECONDS)
#define HERETIC_MOON_MASQUERADE_QUAKE 0.1
#define HERETIC_MOON_MASQUERADE_QUAKE_TIME (0.3 SECONDS)

/proc/get_heretic_moon(mob/user)
	var/datum/antagonist/heretic/heretic = user?.mind?.has_antag_datum(/datum/antagonist/heretic)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_moon)

/datum/eldritch_knowledge/base_moon
	name = "Лицо под водой"
	summary = "Двойники-отражения бьют и прикрывают вас, а Хватка в «Помощи» по полу ставит двойника на посту."
	details = list(
		"«Лунное отражение»: копия на видимом полу в 5 клетках и ещё одна рядом с вами, пока позволяет предел.",
		"Копии повторяют вашу речь, гонятся за целью клинка и бьют её раз в секунду: 5 ушибов и 18 выносливости.",
		"Соседняя копия раз в 4 секунды принимает выстрел вместо вас; удары и пули разбивают копии.",
		"Двойник на посту: Хватка в «Помощи» по полу, один, 10 минут бродит в 2 клетках и выглядит как вы.",
		"«Голос двойника» повторяет вашу речь из двойника; отдел станции идёт в дело, когда двойника увидит экипаж.",
		"Двойник не моргает; 30 урона, нулевой жезл или вспышка в 3 клетках его рассеивают. Из изнанки выходите к нему.",
		"Нож и осколок стекла на руне дают лунный клинок.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Отражение подняло голову раньше меня."
	cost = 0
	route = PATH_MOON
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard)
	result_atoms = list(/obj/item/melee/sickly_blade/moon)
	resource_rules = list(
		"Держится 2 отражения, с Сумеречным покровом 3, после вознесения 5; новое вытесняет старейшее.",
		"Копия живёт 45 секунд, с покровом 60 / 75 / 90; прочность 30, с покровом 40, после вознесения 50.",
		"Копия бьёт цель раз в секунду: 5 ушибов и 18 выносливости, после вознесения 10 и 30; броня снижает ушибы.",
		"Соседняя копия ловит снаряд раз в 4 секунды; после вознесения - любая в 2 клетках, без задержки.",
		"Двойник на посту не входит в предел, не дерётся и держится 10 минут.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_moon/post_voice
	var/list/mob/living/simple_animal/hostile/illusion/heretic_moon/reflections = list()
	var/list/mob/living/simple_animal/hostile/illusion/heretic_moon/temporary_reflections = list()
	var/mob/living/moon_body
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/reflection_spell
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/post/post_double
	var/post_voice = FALSE
	var/list/datum/status_effect/heretic_moon_sleepwalk/sleepwalkers = list()
	var/moon_failure
	var/shrouded = FALSE
	var/refracting = FALSE
	var/ascension_active = FALSE
	var/next_interception = 0

/datum/eldritch_knowledge/base_moon/on_body_gain(mob/living/user)
	if(!user?.mind || moon_body == user)
		return
	if(moon_body)
		on_body_lose(moon_body)
	moon_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(user, COMSIG_LIVING_RUN_BLOCK, PROC_REF(intercept_projectile))
	RegisterSignal(user, COMSIG_LIVING_SEND_SPEECH, PROC_REF(relay_speech))
	reflection_spell = new
	user.mind.AddSpell(reflection_spell)
	grant_combat_power(user)
	if(!QDELETED(post_double))
		post_double.bind_model(user)

/datum/eldritch_knowledge/base_moon/on_body_lose(mob/living/user)
	if(moon_body)
		UnregisterSignal(moon_body, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_RUN_BLOCK, COMSIG_LIVING_SEND_SPEECH))
		moon_body.remove_status_effect(/datum/status_effect/heretic_moon_shroud)
	moon_body = null
	QDEL_NULL(reflection_spell)
	remove_combat_power()
	clear_reflections()
	wake_sleepwalkers()

/datum/eldritch_knowledge/base_moon/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(moon_body)

/datum/eldritch_knowledge/base_moon/proc/relay_speech(mob/living/source, message, message_range, atom/movable/speech_source, bubble_type, list/spans, datum/language/message_language, message_mode)
	SIGNAL_HANDLER
	if(source != moon_body || source.stat == DEAD || speech_source != source || !length(message))
		return
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections)
		if(QDELETED(reflection) || reflection.stat == DEAD || reflection.parent_mob != source)
			continue
		INVOKE_ASYNC(reflection, TYPE_PROC_REF(/atom/movable, send_speech), message, message_range, reflection, bubble_type, spans?.Copy(), message_language, message_mode)
	if(post_voice && !QDELETED(post_double) && isturf(post_double.loc))
		INVOKE_ASYNC(post_double, TYPE_PROC_REF(/atom/movable, send_speech), message, message_range, post_double, bubble_type, spans?.Copy(), message_language, message_mode)

/datum/eldritch_knowledge/base_moon/proc/intercept_projectile(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(!real_attack || damage <= 0 || !(attack_type & ATTACK_TYPE_PROJECTILE) || source != moon_body || source.incapacitated())
		return BLOCK_NONE
	if(!ascension_active && world.time < next_interception)
		return BLOCK_NONE
	if(ismob(attacker) && (attacker == source || IS_HERETIC(attacker) || IS_HERETIC_MONSTER(attacker)))
		return BLOCK_NONE
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections)
		if(QDELETED(reflection) || reflection.stat == DEAD || !isturf(reflection.loc))
			continue
		if(ascension_active)
			if(reflection.z != source.z || get_dist(source, reflection) > HERETIC_MOON_ASCENDED_INTERCEPT_RANGE || !heretic_edge_line_clear(source, reflection))
				continue
		else if(!source.Adjacent(reflection))
			continue
		if(!ascension_active)
			next_interception = world.time + 4 SECONDS
		new /obj/effect/temp_visual/heretic_afterimage(get_turf(source), source, "#becfee")
		source.visible_message(span_warning("Снаряд попадает в отражение [source], рассыпая его серебристой пылью!"))
		reflection.death()
		return BLOCK_SUCCESS
	return BLOCK_NONE

/datum/eldritch_knowledge/base_moon/on_death(mob/user)
	clear_reflections()
	wake_sleepwalkers()
	moon_body?.remove_status_effect(/datum/status_effect/heretic_moon_shroud)

/datum/eldritch_knowledge/base_moon/Destroy()
	on_body_lose(moon_body)
	if(!QDELETED(post_double))
		var/mob/living/simple_animal/hostile/illusion/heretic_moon/post/post = post_double
		post_double = null
		qdel(post)
	return ..()

/datum/eldritch_knowledge/base_moon/proc/clear_reflections(keep_temporary = FALSE)
	var/list/doomed = reflections.Copy()
	if(!keep_temporary)
		doomed += temporary_reflections
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in doomed)
		qdel(reflection)
	reflections.Cut()
	if(!keep_temporary)
		temporary_reflections.Cut()

/datum/eldritch_knowledge/base_moon/proc/reflection_limit()
	return ascension_active ? HERETIC_MOON_ASCENDED_LIMIT : shrouded ? HERETIC_MOON_SHROUD_LIMIT : HERETIC_MOON_BASE_LIMIT

/datum/eldritch_knowledge/base_moon/proc/reflection_health()
	return ascension_active ? HERETIC_MOON_ASCENDED_HEALTH : shrouded ? HERETIC_MOON_SHROUD_HEALTH : HERETIC_MOON_HEALTH

/datum/eldritch_knowledge/base_moon/proc/sync_reflection_auras(manifest = FALSE)
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections + temporary_reflections)
		reflection.sync_ascension_aura(manifest)

/datum/eldritch_knowledge/base_moon/proc/trim_reflections()
	while(length(reflections) > reflection_limit())
		var/mob/living/simple_animal/hostile/illusion/heretic_moon/oldest = reflections[1]
		reflections -= oldest
		qdel(oldest)

/datum/eldritch_knowledge/base_moon/get_combat_resource_data()
	return combat_resource_payload("Отражения", length(reflections), reflection_limit())

/datum/eldritch_knowledge/base_moon/combat_resource_state()
	var/voice = "Голос двойника [post_voice ? "включён" : "выключен"]."
	if(QDELETED(post_double))
		return "Двойника на посту нет. [voice]"
	var/minutes_left = max(1, CEILING((post_double.reflection_expires_at - world.time) / (1 MINUTES), 1))
	return "Двойник на посту: [get_area_name(post_double, TRUE)], ещё [minutes_left] мин. [voice]"

/datum/eldritch_knowledge/base_moon/proc/moon_heretic()
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	return heretic || IS_HERETIC(moon_body)

/datum/eldritch_knowledge/base_moon/proc/can_use(mob/living/user, ignore_grab = FALSE)
	return !QDELETED(src) && isliving(user) && user == moon_body && user.stat == CONSCIOUS && isturf(user.loc) && !user.incapacitated(ignore_grab = ignore_grab)

/datum/eldritch_knowledge/base_moon/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !isturf(target) || user.a_intent != INTENT_HELP)
		return FALSE
	return place_post(user, target)

/datum/eldritch_knowledge/base_moon/proc/place_post(mob/living/user, turf/place)
	grasp_failure_reason = null
	if(!istype(place) || !isliving(user) || user != moon_body)
		return FALSE
	if(!isopenturf(place) || isgroundlessturf(place) || place.is_blocked_turf(exclude_mobs = FALSE))
		grasp_failure_reason = "Двойник встаёт только на свободный пол: не на стену, не в космос и не на занятую клетку."
		return FALSE
	if(!QDELETED(post_double))
		var/mob/living/simple_animal/hostile/illusion/heretic_moon/post/old = post_double
		post_double = null
		log_game("[key_name(user)] теряет двойника на посту Луны в [AREACOORD(old)]: его заменил новый.")
		qdel(old)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/post/post = new(place, src, user, HERETIC_MOON_POST_LIFETIME)
	if(QDELETED(post))
		return FALSE
	post_double = post
	new /obj/effect/temp_visual/heretic_path_feedback(place, "cosmic_ring", "#d6e2ff", 9)
	playsound(place, 'modular_bluemoon/sound/heretic/moon_reflection.ogg', 30, TRUE)
	to_chat(user, span_eldritch("Двойник встал на пост: [get_area_name(place, TRUE)]. Он простоит до [HERETIC_MOON_POST_LIFETIME / (1 MINUTES)] минут; отдел станции засчитается в дело, когда двойника увидит кто-то из экипажа."))
	log_game("[key_name(user)] ставит двойника на посту Луны в [AREACOORD(place)].")
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_moon/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_MOON_POST_CRAFT)
		return
	if(crafted == post_double)
		post_double = null
		if(moon_body)
			to_chat(moon_body, span_warning("Ваш двойник на посту рассеялся."))
		notify_resource_changed()
	if(!QDELETED(crafted))
		qdel(crafted)

/datum/eldritch_knowledge/base_moon/proc/toggle_post_voice(mob/living/user)
	post_voice = !post_voice
	var/state = post_voice ? "Двойник на посту теперь повторяет вашу речь." : "Двойник на посту замолкает."
	if(post_voice && QDELETED(post_double))
		state += " Сейчас двойника нет: поставьте его Хваткой в «Помощи» по полу."
	to_chat(user, span_notice(state))
	notify_resource_changed()

/datum/eldritch_knowledge/base_moon/proc/wake_sleepwalkers()
	for(var/datum/status_effect/heretic_moon_sleepwalk/walk as anything in sleepwalkers.Copy())
		qdel(walk)
	sleepwalkers.Cut()

/datum/eldritch_knowledge/base_moon/proc/sleepwalk_of(mob/living/victim)
	for(var/datum/status_effect/heretic_moon_sleepwalk/walk as anything in sleepwalkers)
		if(walk.owner == victim && walk.asleep && !QDELETED(walk))
			return walk
	return null

/// Ждущая копия зеркала или двойник на посту: к ним идёт сомнамбула, у них открывается отражение.
/datum/eldritch_knowledge/base_moon/proc/door_anchor_valid(mob/living/anchor)
	if(QDELETED(anchor) || !isturf(anchor.loc))
		return FALSE
	if(anchor == post_double)
		return TRUE
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = anchor
	return istype(reflection) && reflection.holding_position && (reflection in reflections)

/datum/eldritch_knowledge/base_moon/pocket_exits(mob/living/user)
	. = list()
	if(door_anchor_valid(post_double))
		heretic_add_pocket_exit(., "Двойник - [get_area_name(post_double, TRUE)]", heretic_pocket_beside(post_double))
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections)
		if(door_anchor_valid(reflection))
			heretic_add_pocket_exit(., "Копия - [get_area_name(reflection, TRUE)]", heretic_pocket_beside(reflection))

/datum/eldritch_knowledge/base_moon/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в лунный сон", "text" = "[victim] шагает во сне прямо сквозь завесу.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель спит на ходу от своей Сомнамбулы, еретик рядом с ней.
/datum/eldritch_knowledge/base_moon/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	return !isnull(sleepwalk_of(victim))

/datum/eldritch_knowledge/base_moon/proc/sleepwalk_block_reason(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/moon_sleepwalk)
	if(QDELETED(src) || !user || user != moon_body || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_MOON_CAPTURE)
	if(reason)
		return reason
	if(!can_use(user))
		return "Вы не можете действовать: дождитесь конца оглушения и выйдите на пол."
	var/mob/living/victim = target
	if(!iscarbon(victim))
		return "Во сне на ходу бродят только люди и им подобные."
	if(victim.stat >= UNCONSCIOUS)
		return "Цель без сознания: Сомнамбула ведёт только тех, кто стоит на ногах."
	if(victim.has_status_effect(/datum/status_effect/heretic_moon_sleepwalk))
		return "Цель уже засыпает на ходу."
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_MOON_SLEEPWALK_RANGE)
		return "Цель должна стоять на полу не дальше пяти клеток от вас."
	if(!victim.has_status_effect(/datum/status_effect/heretic_moon_daze))
		return "Сомнамбула берёт только цель под лунным помутнением: сначала коснитесь её Хваткой, взорвите на ней Метку Луны, накройте Затмением или Осколками света."
	return null

/datum/eldritch_knowledge/base_moon/proc/sleepwalk(mob/living/user, mob/living/victim)
	moon_failure = sleepwalk_block_reason(user, victim)
	if(moon_failure)
		return FALSE
	var/datum/status_effect/heretic_moon_sleepwalk/walk = victim.apply_status_effect(/datum/status_effect/heretic_moon_sleepwalk, src)
	if(!walk || QDELETED(walk))
		moon_failure = "Сомнамбула не удержала цель."
		return FALSE
	log_combat(user, victim, "насылает Сомнамбулу")
	return TRUE

/// Причина сорвать Сомнамбулу к концу телеграфа, или null.
/datum/eldritch_knowledge/base_moon/proc/sleepwalk_hold_reason(mob/living/victim)
	if(!can_use(moon_body))
		return "вы не удержали заклятие"
	if(victim.stat >= UNCONSCIOUS)
		return "цель потеряла сознание"
	if(!heretic_can_affect(moon_body, victim, chargecost = 0))
		return "цель защищена от магии"
	if(!isturf(victim.loc) || victim.z != moon_body.z || get_dist(moon_body, victim) > HERETIC_MOON_SLEEPWALK_RANGE)
		return "цель ушла дальше пяти клеток"
	return null

/// Сомнамбулу зовёт ближайшая копия, оставленная ждать зеркалом, цель охоты - и двойник на посту неподалёку, а без них - сам еретик.
/datum/eldritch_knowledge/base_moon/proc/sleepwalk_destination(mob/living/victim)
	var/turf/victim_turf = get_turf(victim)
	if(!victim_turf)
		return null
	var/mob/living/best
	var/best_distance = INFINITY
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections)
		if(!reflection.holding_position || !isturf(reflection.loc) || reflection.z != victim_turf.z)
			continue
		var/distance = get_dist(reflection, victim_turf)
		if(distance < best_distance)
			best = reflection
			best_distance = distance
	var/datum/antagonist/heretic/heretic = moon_heretic()
	if(victim.mind && victim.mind == heretic?.hunt_target && door_anchor_valid(post_double) && post_double.z == victim_turf.z)
		var/post_distance = get_dist(post_double, victim_turf)
		if(post_distance <= HERETIC_MOON_SLEEPWALK_POST_RANGE && post_distance < best_distance)
			best = post_double
	if(best)
		return best
	if(moon_body && isturf(moon_body.loc) && moon_body.z == victim_turf.z)
		return moon_body
	return null

/datum/eldritch_knowledge/base_moon/proc/sleepwalk_safe_turf(turf/tile)
	return isopenturf(tile) && !isgroundlessturf(tile)

/// Запасной шаг, пока маршрута нет: прямо или на 45 градусов в сторону.
/datum/eldritch_knowledge/base_moon/proc/sleepwalk_step(mob/living/victim, atom/destination)
	var/turf/here = get_turf(victim)
	var/turf/goal = get_turf(destination)
	if(!here || !goal || !isturf(victim.loc) || victim.buckled || get_dist(here, goal) <= 1)
		return FALSE
	var/direction = get_dir(here, goal)
	for(var/step_direction in list(direction, turn(direction, 45), turn(direction, -45)))
		var/turf/next = get_step(here, step_direction)
		if(!next || get_dist(next, goal) >= get_dist(here, goal) || !sleepwalk_safe_turf(next) || next.is_blocked_turf(exclude_mobs = TRUE))
			continue
		if(victim.Move(next, step_direction))
			return TRUE
	return FALSE

/datum/eldritch_knowledge/base_moon/proc/return_block_reason(mob/living/user)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/moon_shroud)
	if(QDELETED(src) || !user || user != moon_body || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	if(!can_use(user, ignore_grab = TRUE))
		return "Вы не можете действовать: дождитесь конца оглушения и выйдите на пол."
	if(user.buckled || user.anchored)
		return "Вы пристёгнуты или закреплены: отражение вас не заберёт."
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/post/post = post_double
	if(QDELETED(post) || !isturf(post.loc))
		return "Двойника на посту нет: поставьте его Хваткой в намерении «Помощь» по полу."
	if(post.z != user.z)
		return "Двойник стоит на другом уровне: вернуться можно только к двойнику на этом же уровне."
	var/area/origin_area = get_area(user)
	var/area/post_area = get_area(post)
	if(HAS_TRAIT(user, TRAIT_NO_TELEPORT) || (origin_area.area_flags & NOTELEPORT) || (post_area.area_flags & NOTELEPORT))
		return "Отражения здесь не пускают: место закрыто для телепортации."
	return null

/datum/eldritch_knowledge/base_moon/proc/return_ready(mob/living/user)
	return !return_block_reason(user)

/datum/eldritch_knowledge/base_moon/proc/return_to_post(mob/living/user)
	moon_failure = return_block_reason(user)
	if(moon_failure)
		return FALSE
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/post/post = post_double
	user.visible_message(span_warning("Силуэт [user] бледнеет и запаздывает, как отражение в тёмной воде."), span_notice("Вы тянетесь к двойнику на посту: две секунды стойте на месте."))
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(user), "cosmic_ring", "#d6e2ff", HERETIC_MOON_RETURN_CHANNEL)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(post), "cosmic_ring", "#d6e2ff", HERETIC_MOON_RETURN_CHANNEL)
	playsound(user, 'modular_bluemoon/sound/heretic/moon_reflection.ogg', 35, TRUE)
	if(!do_after(user, HERETIC_MOON_RETURN_CHANNEL, target = user, timed_action_flags = IGNORE_INCAPACITATED, extra_checks = CALLBACK(src, PROC_REF(return_ready), user)))
		moon_failure = return_block_reason(user) || "Возвращение прервано: две секунды стойте на месте."
		return FALSE
	moon_failure = return_block_reason(user)
	if(moon_failure)
		return FALSE
	post = post_double
	var/turf/origin = get_turf(user)
	var/turf/destination = get_turf(post)
	user.pulledby?.stop_pulling()
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		moon_failure = "Отражение не пустило: у двойника что-то мешает переходу."
		return FALSE
	post.forceMove(origin)
	post.anchor_turf = origin
	new /obj/effect/temp_visual/heretic_afterimage(origin, user, "#becfee")
	playsound(destination, 'modular_bluemoon/sound/heretic/moon_step.ogg', 35, TRUE)
	log_game("[key_name(user)] возвращается в отражение: из [AREACOORD(origin)] на место двойника в [AREACOORD(destination)].")
	return TRUE

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

/datum/eldritch_knowledge/base_moon/proc/create_reflection(mob/living/user, turf/target, list/visible, replace_oldest = FALSE)
	if((!replace_oldest && length(reflections) >= reflection_limit()) || !valid_reflection_turf(target, user, visible))
		return null
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/existing as anything in reflections)
		if(get_turf(existing) == target)
			return null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/moon_shroud/shroud = heretic?.get_knowledge(/datum/eldritch_knowledge/moon_shroud)
	var/lifetime = shrouded && shroud ? shroud.passive_values[shroud.passive_level] : HERETIC_MOON_LIFETIME
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = spawn_reflection(user, target, lifetime)
	if(!reflection)
		return null
	reflections += reflection
	trim_reflections()
	notify_resource_changed()
	return reflection

/datum/eldritch_knowledge/base_moon/proc/spawn_reflection(mob/living/user, turf/target, lifetime)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = new(target, src, user, lifetime)
	if(QDELETED(reflection))
		return null
	new /obj/effect/temp_visual/heretic_path_feedback(target, "cosmic_ring", "#d6e2ff", 9)
	playsound(target, 'modular_bluemoon/sound/heretic/moon_reflection.ogg', 30, TRUE)
	return reflection

/// Копия, уже стоящая под владельцем, служит приманкой; иначе новая встаёт на его клетку или рядом.
/datum/eldritch_knowledge/base_moon/proc/leave_decoy(mob/living/user)
	var/turf/origin = get_turf(user)
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/existing as anything in reflections)
		if(get_turf(existing) == origin)
			return existing
	var/list/visible = view(HERETIC_MOON_RANGE, user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/decoy = create_reflection(user, origin, visible, replace_oldest = TRUE)
	if(decoy)
		return decoy
	for(var/direction in GLOB.alldirs)
		decoy = create_reflection(user, get_step(origin, direction), visible, replace_oldest = TRUE)
		if(decoy)
			return decoy
	return null

/datum/eldritch_knowledge/base_moon/proc/masquerade_targets(mob/living/user)
	var/list/candidates = list()
	for(var/mob/living/candidate in view(HERETIC_MOON_MASQUERADE_RANGE, user))
		if(!istype(candidate, /mob/living/simple_animal/hostile/illusion/heretic_moon))
			candidates += candidate
	var/list/chosen = list()
	for(var/distance in 0 to HERETIC_MOON_MASQUERADE_RANGE)
		for(var/mob/living/candidate as anything in candidates)
			if(length(chosen) >= HERETIC_MOON_MASQUERADE_TARGETS)
				return chosen
			if(get_dist(user, candidate) == distance && heretic_can_affect(user, candidate))
				chosen += candidate
	return chosen

/datum/eldritch_knowledge/base_moon/proc/masquerade_spot(mob/living/victim)
	var/turf/center = get_turf(victim)
	for(var/direction in shuffle(GLOB.alldirs))
		var/turf/spot = get_step(center, direction)
		if(istype(spot, /turf/open/floor) && !spot.is_blocked_turf() && center.Adjacent(spot))
			return spot
	return null

/// Временные копии маскарада не входят в предел и не вытесняют обычные отражения.
/datum/eldritch_knowledge/base_moon/proc/masquerade_strike(mob/living/user, mob/living/victim)
	victim.adjustStaminaLoss(HERETIC_MOON_MASQUERADE_STAMINA)
	victim.confused = max(victim.confused, HERETIC_MOON_MASQUERADE_CONFUSION)
	victim.apply_status_effect(/datum/status_effect/heretic_lunatic)
	log_combat(user, victim, "окружил лунным маскарадом")
	var/turf/spot = masquerade_spot(victim)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/shade = spot && spawn_reflection(user, spot, HERETIC_MOON_MASQUERADE_LIFETIME)
	if(shade)
		shade.leash_range = HERETIC_MOON_MASQUERADE_RANGE
		temporary_reflections += shade
		shade.GiveTarget(victim)
	mirror_flash(victim)

/// Цель маскарада на миг двоится серебряным отражением.
/datum/eldritch_knowledge/base_moon/proc/mirror_flash(mob/living/victim)
	new /obj/effect/temp_visual/heretic_moon_mirror(get_turf(victim), victim, pick(-HERETIC_MOON_GHOST_SPLIT, HERETIC_MOON_GHOST_SPLIT))
	heretic_vfx_pulse(victim, HERETIC_MOON_SILVER, 2, HERETIC_MOON_GHOST_TIME)

/// В миг удара от героя в обе стороны отскакивают отражения, серебряная волна несёт маскарад по залу.
/datum/eldritch_knowledge/base_moon/proc/masquerade_visuals(mob/living/user)
	var/turf/center = get_turf(user)
	new /obj/effect/temp_visual/heretic_moon_mirror(center, user, HERETIC_MOON_MASQUERADE_GHOST_OFFSET)
	new /obj/effect/temp_visual/heretic_moon_mirror(center, user, -HERETIC_MOON_MASQUERADE_GHOST_OFFSET)
	heretic_vfx_pulse(user, HERETIC_MOON_SILVER, 2, HERETIC_MOON_MASQUERADE_WAVE_TIME / 2)
	heretic_vfx_shockwave(center, HERETIC_MOON_SILVER, HERETIC_MOON_MASQUERADE_RANGE, HERETIC_MOON_MASQUERADE_WAVE_TIME)
	heretic_vfx_burst(center, /particles/heretic_ascension/moon)
	heretic_vfx_flash(center, HERETIC_MOON_SILVER, HERETIC_MOON_MASQUERADE_RANGE, HERETIC_MOON_MASQUERADE_FLASH_POWER, HERETIC_MOON_MASQUERADE_FLASH_TIME)
	heretic_vfx_quake(center, HERETIC_MOON_MASQUERADE_RANGE, HERETIC_MOON_MASQUERADE_QUAKE, HERETIC_MOON_MASQUERADE_QUAKE_TIME)

/datum/eldritch_knowledge/base_moon/proc/direct_reflections(mob/living/victim)
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in reflections)
		if(!reflection.holding_position && reflection.CanAttack(victim))
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
	clear_reflections(keep_temporary = TRUE)
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
	maxHealth = HERETIC_MOON_HEALTH
	health = HERETIC_MOON_HEALTH
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
	hud_possible = list(HEALTH_HUD, STATUS_HUD, ID_HUD, WANTED_HUD, IMPLOYAL_HUD, IMPCHEM_HUD, IMPTRACK_HUD, NANITE_HUD, DIAG_NANITE_FULL_HUD, ANTAG_HUD, RAD_HUD)
	var/sensors_shown
	var/datum/weakref/knowledge_ref
	var/reflection_expires_at
	var/reflection_expiry_timer
	var/holding_position = FALSE
	var/leash_range = HERETIC_MOON_RANGE
	var/obj/effect/heretic_ascension_aura/aura_back
	var/obj/effect/heretic_ascension_aura/aura_front
	var/obj/effect/abstract/heretic_particle_holder/shimmer
	var/shattered = FALSE

/mob/living/simple_animal/hostile/illusion/heretic_moon/Initialize(mapload, datum/eldritch_knowledge/base_moon/knowledge, mob/living/model, duration = HERETIC_MOON_LIFETIME)
	. = ..()
	if(!knowledge || !model)
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(knowledge)
	parent_mob = model
	maxHealth = knowledge.reflection_health()
	health = maxHealth
	setDir(model.dir)
	add_to_all_human_data_huds()
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
	sync_ascension_aura()
	sync_huds()

/// Нимб вознесённого держится в vis_contents, а не в appearance, поэтому копия заводит свой.
/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/sync_ascension_aura(manifest = FALSE)
	sync_shimmer()
	var/obj/effect/heretic_ascension_aura/model
	if(!QDELETED(parent_mob))
		model = locate() in parent_mob.vis_contents
	if(!model)
		QDEL_NULL(aura_back)
		QDEL_NULL(aura_front)
		return
	if(aura_back)
		return
	aura_back = new(null, model.path_id)
	aura_front = new(null, model.path_id, TRUE)
	aura_back.follow(src)
	aura_front.follow(src)
	vis_contents += list(aura_back, aura_front)
	if(manifest)
		aura_back.manifest()
		aura_front.manifest()

/// Копии вознёсшейся Луны изредка вспыхивают серебряными бликами.
/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/sync_shimmer()
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	var/ascended = knowledge?.ascension_active && stat != DEAD
	if(ascended && !shimmer)
		shimmer = heretic_vfx_attach_particles(src, /particles/heretic_ascension/moon/shimmer)
	else if(!ascended && shimmer)
		heretic_vfx_release_particles(src, shimmer)
		shimmer = null

/// Разбитая копия вспыхивает серебром и разлетается осколками зеркала.
/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/shatter()
	var/turf/place = get_turf(src)
	if(shattered || !place)
		return
	shattered = TRUE
	new /obj/effect/temp_visual/heretic_moon_shatter(place, src)
	heretic_vfx_burst(place, /particles/heretic_ascension/moon/shards)
	heretic_vfx_flash(place, HERETIC_MOON_SILVER, HERETIC_MOON_SHATTER_FLASH_RANGE, HERETIC_MOON_SHATTER_FLASH_POWER, HERETIC_MOON_SHATTER_FLASH_TIME)

/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/sync_huds()
	if(!hud_list || QDELETED(parent_mob) || !parent_mob.hud_list)
		return
	for(var/hud_key in hud_list)
		if(hud_key == ANTAG_HUD)
			continue
		var/image/holder = hud_list[hud_key]
		var/image/mirrored = parent_mob.hud_list[hud_key]
		if(!istype(holder) || !istype(mirrored))
			continue
		holder.icon_state = mirrored.icon_state
		holder.pixel_y = mirrored.pixel_y
	var/datum/atom_hud/data/human/medical/basic/basic_medhud = GLOB.huds[DATA_HUD_MEDICAL_BASIC]
	var/sensors_on = basic_medhud.check_sensors(src)
	if(sensors_on != sensors_shown)
		sensors_shown = sensors_on
		basic_medhud.update_suit_sensors(src)

/mob/living/simple_animal/hostile/illusion/heretic_moon/med_hud_set_health()
	sync_huds()

/mob/living/simple_animal/hostile/illusion/heretic_moon/med_hud_set_status()
	sync_huds()

/mob/living/simple_animal/hostile/illusion/heretic_moon/BiologicalLife(delta_time, times_fired)
	. = ..()
	if(QDELETED(src))
		return
	reflection_life(delta_time)

/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/reflection_life(delta_time)
	if(QDELETED(parent_mob) || parent_mob.stat == DEAD)
		qdel(src)
		return
	sync_appearance()

/mob/living/simple_animal/hostile/illusion/heretic_moon/GetVoice()
	if(!QDELETED(parent_mob))
		return parent_mob.GetVoice()
	return ..()

/mob/living/simple_animal/hostile/illusion/heretic_moon/get_alt_name()
	if(!QDELETED(parent_mob))
		return parent_mob.get_alt_name()
	return ..()

/mob/living/simple_animal/hostile/illusion/heretic_moon/say_mod(input, message_mode)
	if(!QDELETED(parent_mob))
		return parent_mob.say_mod(input, message_mode)
	return ..()

/mob/living/simple_animal/hostile/illusion/heretic_moon/CanAttack(atom/the_target)
	if(holding_position || !..() || !isturf(the_target.loc) || QDELETED(parent_mob) || parent_mob.stat == DEAD)
		return FALSE
	if(the_target.z != parent_mob.z || get_dist(parent_mob, the_target) > leash_range || istype(the_target, /mob/living/simple_animal/hostile/illusion/heretic_moon))
		return FALSE
	return heretic_can_affect(parent_mob, the_target, chargecost = 0)

/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/hold_position(hold)
	holding_position = hold
	LoseTarget()
	if(hold)
		ADD_TRAIT(src, TRAIT_AI_PAUSED, REF(src))
	else
		REMOVE_TRAIT(src, TRAIT_AI_PAUSED, REF(src))

/mob/living/simple_animal/hostile/illusion/heretic_moon/AttackingTarget()
	if(!CanAttack(target) || !Adjacent(target))
		return FALSE
	var/mob/living/victim = target
	var/obj/item/weapon = parent_mob.get_active_held_item()
	setDir(get_dir(src, victim))
	do_attack_animation(victim, used_item = weapon)
	if(!victim.has_status_effect(/datum/status_effect/heretic_moon_pressure) && heretic_can_affect(parent_mob, victim))
		var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
		var/pressure = knowledge?.ascension_active ? HERETIC_MOON_ASCENDED_PRESSURE : HERETIC_MOON_PRESSURE
		var/damage = knowledge?.ascension_active ? HERETIC_MOON_ASCENDED_DAMAGE : HERETIC_MOON_DAMAGE
		victim.apply_status_effect(/datum/status_effect/heretic_moon_pressure)
		var/stamina_before = victim.getStaminaLoss()
		victim.adjustStaminaLoss(pressure)
		victim.apply_damage(damage, BRUTE, BODY_ZONE_CHEST, victim.run_armor_check(victim.get_bodypart(BODY_ZONE_CHEST) || BODY_ZONE_CHEST, MELEE))
		playsound(victim, weapon?.hitsound || 'sound/weapons/punch1.ogg', 35, TRUE)
		log_combat(parent_mob, victim, "атаковал лунным отражением")
		if(victim.getStaminaLoss() > stamina_before)
			var/datum/antagonist/heretic/heretic = IS_HERETIC(parent_mob)
			heretic?.advance_combat_deed(victim, PATH_MOON)
	return TRUE

/datum/status_effect/heretic_moon_pressure
	id = "heretic_moon_pressure"
	duration = 1 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

/mob/living/simple_animal/hostile/illusion/heretic_moon/Destroy()
	deltimer(reflection_expiry_timer)
	reflection_expiry_timer = null
	if(isturf(loc) && !shattered)
		new /obj/effect/temp_visual/heretic_grasp/moon(get_turf(src))
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	if(knowledge)
		knowledge.reflections -= src
		knowledge.temporary_reflections -= src
		knowledge.notify_resource_changed()
	QDEL_NULL(aura_back)
	QDEL_NULL(aura_front)
	heretic_vfx_release_particles(src, shimmer)
	shimmer = null
	knowledge_ref = null
	parent_mob = null
	return ..()

/mob/living/simple_animal/hostile/illusion/heretic_moon/death(gibbed)
	if(stat == DEAD)
		return FALSE
	burst_refraction()
	visible_message(span_warning("[src] рассыпается серебристой пылью."))
	shatter()
	playsound(src, 'modular_bluemoon/sound/heretic/moon_break.ogg', 45, TRUE)
	return ..()

/mob/living/simple_animal/hostile/illusion/heretic_moon/proc/burst_refraction()
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	if(!knowledge?.refracting || !knowledge.moon_body)
		return
	for(var/mob/living/victim in view(HERETIC_MOON_REFRACTION_RADIUS, src))
		if(!heretic_can_affect(knowledge.moon_body, victim))
			continue
		victim.blur_eyes(4)
		victim.confused = max(victim.confused, 2)
		victim.apply_status_effect(/datum/status_effect/heretic_moon_daze)
		if(!victim.has_status_effect(/datum/status_effect/heretic_moon_refraction))
			victim.apply_status_effect(/datum/status_effect/heretic_moon_refraction)
			victim.adjustStaminaLoss(25)

/datum/status_effect/heretic_moon_refraction
	id = "heretic_moon_refraction"
	duration = 2 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

/// Ремесло Луны: копия хозяина стоит на посту как алиби, не дерётся и переживает его смерть.
/mob/living/simple_animal/hostile/illusion/heretic_moon/post
	var/turf/anchor_turf
	var/wander_chance = HERETIC_MOON_POST_WANDER_CHANCE

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/Initialize(mapload, datum/eldritch_knowledge/base_moon/knowledge, mob/living/model, duration = HERETIC_MOON_POST_LIFETIME)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	maxHealth = HERETIC_MOON_POST_HEALTH
	health = maxHealth
	anchor_turf = get_turf(src)
	hold_position(TRUE)
	RegisterSignal(model, COMSIG_PARENT_QDELETING, PROC_REF(on_model_deleted))
	RegisterSignal(SSdcs, COMSIG_GLOB_BRIGHT_FLASH, PROC_REF(on_bright_flash))
	AddComponent(/datum/component/heretic_craft, knowledge, HERETIC_MOON_POST_CRAFT, HERETIC_MOON_POST_CLUE)

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/proc/bind_model(mob/living/model)
	if(parent_mob == model)
		return
	if(parent_mob)
		UnregisterSignal(parent_mob, COMSIG_PARENT_QDELETING)
	parent_mob = model
	RegisterSignal(model, COMSIG_PARENT_QDELETING, PROC_REF(on_model_deleted))
	sync_appearance()

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/proc/on_model_deleted(datum/source)
	SIGNAL_HANDLER
	parent_mob = null

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/reflection_life(delta_time)
	if(!QDELETED(parent_mob) && parent_mob.stat != DEAD)
		sync_appearance()
	wander()
	look_for_witnesses()

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/burst_refraction()
	return

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/examine(mob/user)
	if(QDELETED(parent_mob) || parent_mob.stat == DEAD)
		. = list("Это [src].")
	else
		. = parent_mob.examine(user)
	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, .)

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/proc/wander()
	if(!isturf(loc) || !anchor_turf || buckled || pulledby || calling_sleepwalker() || !prob(wander_chance))
		return FALSE
	var/direction = pick(GLOB.cardinals)
	var/turf/next = get_step(src, direction)
	setDir(direction)
	if(!next || next.z != anchor_turf.z || isgroundlessturf(next) || next.is_blocked_turf(exclude_mobs = FALSE))
		return FALSE
	var/next_distance = get_dist(next, anchor_turf)
	if(next_distance > HERETIC_MOON_POST_RADIUS && next_distance >= get_dist(src, anchor_turf))
		return FALSE
	return Move(next, direction)

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/proc/calling_sleepwalker()
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	for(var/datum/status_effect/heretic_moon_sleepwalk/walk as anything in knowledge?.sleepwalkers)
		if(walk.door_anchor?.resolve() == src)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/proc/look_for_witnesses()
	var/turf/place = get_turf(src)
	if(!place)
		return
	var/list/candidates = SSspatial_grid.initialized ? SSspatial_grid.orthogonal_range_search(place, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, HERETIC_MOON_WITNESS_RANGE) : GLOB.player_list
	for(var/mob/living/carbon/human/viewer in candidates)
		if(!viewer.client || viewer.z != place.z || get_dist(viewer, place) > HERETIC_MOON_WITNESS_RANGE || !can_see(viewer, src, HERETIC_MOON_WITNESS_RANGE))
			continue
		if(witnessed_by(viewer))
			return

/// Клиент зрителя проверяет обход в Life, здесь - только кто он и видит ли.
/mob/living/simple_animal/hostile/illusion/heretic_moon/post/proc/witnessed_by(mob/living/viewer)
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = knowledge?.moon_heretic()
	if(!heretic?.deed || heretic.deed.complete() || !isturf(loc) || !is_station_level(z) || !ishuman(viewer) || viewer == parent_mob || !viewer.mind)
		return FALSE
	if(viewer.stat != CONSCIOUS || viewer.is_blind() || IS_HERETIC(viewer) || IS_HERETIC_MONSTER(viewer))
		return FALSE
	var/key = heretic.deed_key_for(src)
	if(key in heretic.deed.counted_keys)
		return FALSE
	return heretic.advance_deed(key, src, silent = TRUE)

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/proc/on_bright_flash(datum/source, turf/origin, mob/user)
	SIGNAL_HANDLER
	var/turf/place = get_turf(src)
	if(!origin || !place || (user && user == parent_mob) || origin.z != place.z || get_dist(origin, place) > HERETIC_MOON_FLASH_RANGE)
		return
	if(!(place in heretic_field_view(HERETIC_MOON_FLASH_RANGE, origin)))
		return
	visible_message(span_warning("Вспышка проходит сквозь [src], и тот осыпается серебристой пылью!"))
	log_game("Двойник на посту Луны рассеян вспышкой в [AREACOORD(place)].")
	shatter()
	qdel(src)

/mob/living/simple_animal/hostile/illusion/heretic_moon/post/Destroy()
	anchor_turf = null
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
	return ..() && heretic_check(user, get_heretic_moon(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_moon/create
	name = "Лунное отражение"
	desc = "Создайте двойника на видимом свободном полу в пяти клетках и ещё одного возле себя, если позволяет предел. При полном пределе новая копия заменяет старейшую. Копии повторяют вашу речь, бьют врага раз в секунду на 5 ушибов и 18 урона выносливости, выдерживают 30 урона и перехватывают снаряды рядом с вами. До двух копий на 45 секунд, с Сумеречным покровом до трёх; перезарядка 8 секунд."
	summary = "Копия на полу в 5 клетках и вторая рядом с вами; при полном пределе заменяет старейшую."
	active_msg = "Выберите открытый пол для отражения."
	deactive_msg = "Лунный свет гаснет в вашей ладони."
	charge_max = 8 SECONDS
	self_castable = TRUE

/obj/effect/proc_holder/spell/pointed/heretic_moon/create/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	return heretic_check(user, knowledge && isturf(target) && knowledge.valid_reflection_turf(target, user), silent, "Укажите саму клетку видимого свободного пола в пяти клетках; стены, космос и занятые клетки не подходят.")

/obj/effect/proc_holder/spell/pointed/heretic_moon/create/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!length(targets) || !knowledge || !knowledge.create_reflection(user, targets[1], replace_oldest = TRUE))
		heretic_revert_cast(user)
		return
	if(length(knowledge.reflections) < knowledge.reflection_limit())
		if(!knowledge.create_reflection(user, get_turf(user)))
			for(var/direction in GLOB.cardinals)
				if(knowledge.create_reflection(user, get_step(user, direction)))
					break

/obj/effect/proc_holder/spell/pointed/heretic_moon/exchange
	name = "Зеркальный обмен"
	desc = "Поменяйтесь местами с выбранным своим двойником в видимости до пяти клеток. Обмен оставляет копию на вашем прежнем месте. Оба места должны быть свободным полом. Перезарядка 12 секунд."
	summary = "Меняет вас местами со своей копией в 5 клетках. Перезарядка 12 секунд."
	active_msg = "Выберите своё отражение для обмена местами."
	deactive_msg = "Вы оставляете отражения на своих местах."
	charge_max = 12 SECONDS
	aim_assist = TRUE
	action_icon_state = "mind_gate"

/obj/effect/proc_holder/spell/pointed/heretic_moon/exchange/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	return heretic_check(user, knowledge && istype(target, /mob/living/simple_animal/hostile/illusion/heretic_moon) && knowledge.can_exchange(user, target), silent, "Выберите своё отражение в видимости до пяти клеток. Оба места должны быть свободным полом.")

/obj/effect/proc_holder/spell/pointed/heretic_moon/exchange/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || !knowledge.exchange(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_moon
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "moon_smile"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_moon/can_cast(mob/user, skipcharge, silent)
	if(!..() || !heretic_check(user, get_heretic_moon(user), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/containment = heretic_containment_reason(user)
	if(containment)
		return heretic_check(user, FALSE, silent, containment)
	var/mob/living/caster = user
	return heretic_check(user, !istype(caster) || !caster.incapacitated(ignore_grab = usable_while_grabbed), silent, "Вы не можете действовать: дождитесь окончания оглушения или освободитесь.")

/obj/effect/proc_holder/spell/self/heretic_moon/mirage
	name = "Шествие миражей"
	desc = "Замените старые отражения новой группой двойников вокруг себя до текущего предела и поменяйтесь местами со случайной копией, если обмен возможен. Перезарядка 25 секунд."
	summary = "Новая группа копий вокруг вас и обмен со случайной из них. Перезарядка 25 секунд."
	charge_max = 25 SECONDS
	action_icon_state = "moon_parade"

/obj/effect/proc_holder/spell/self/heretic_moon/mirage/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || !knowledge.create_mirages(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_moon/eclipse
	name = "Лунное затмение"
	desc = "Вспышка в двух клетках вокруг вас и вокруг каждой вашей копии не дальше пяти клеток от вас наносит врагам 30 урона выносливости, путает и замедляет их на 3 секунды; 6 секунд задетые под лунным помутнением. На вашем месте остаётся копия, а если оно занято, то рядом; вы почти исчезаете на 4 секунды, атака раскрывает вас. Перезарядка 45 секунд."
	summary = "Вспышка вокруг вас и копий: 30 выносливости, спутанность и помутнение; вы почти исчезаете."
	charge_max = 45 SECONDS
	action_icon_state = "moon_ringleader"

/obj/effect/proc_holder/spell/self/heretic_moon/eclipse/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || user != knowledge.moon_body || !isturf(user.loc) || user.incapacitated())
		heretic_revert_cast(user)
		return
	var/list/visible = view(2, user)
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in knowledge.reflections)
		if(reflection.z == user.z && get_dist(user, reflection) <= HERETIC_MOON_RANGE)
			visible |= view(2, reflection)
	knowledge.leave_decoy(user)
	for(var/mob/living/victim in visible)
		if(!heretic_can_affect(user, victim))
			continue
		victim.blur_eyes(6)
		victim.confused = max(victim.confused, 3)
		victim.adjustStaminaLoss(30)
		victim.apply_status_effect(/datum/status_effect/heretic_moon_opening)
		victim.apply_status_effect(/datum/status_effect/heretic_moon_daze)
	user.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 4 SECONDS)
	for(var/turf/tile in visible)
		new /obj/effect/temp_visual/heretic_path_feedback(tile, "cosmic_carpet", "#b0c1e5", 6)
	new /obj/effect/temp_visual/heretic_spell/moon(get_turf(user))
	playsound(user, 'modular_bluemoon/sound/heretic/moon_eclipse.ogg', 45, TRUE)

/obj/effect/proc_holder/spell/self/heretic_moon/masquerade
	name = "Лунный маскарад"
	desc = "До пяти ближайших видимых врагов в семи клетках получают 30 урона выносливости, путаются на 3 секунды и на 12 секунд становятся лунатиками: их выстрелы уходят в сторону. Рядом с каждым встаёт временная копия и нападает на него. Такие копии живут 10 секунд и не занимают место среди обычных отражений. Без врагов в поле зрения маскарад не срабатывает. Перезарядка 40 секунд."
	summary = "До 5 врагов в 7 клетках: 30 выносливости, выстрелы мимо 12 секунд и копия рядом."
	charge_max = 40 SECONDS
	action_icon_state = "moon_masquerade"

/obj/effect/proc_holder/spell/self/heretic_moon/masquerade/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge || user != knowledge.moon_body || !isturf(user.loc) || user.incapacitated())
		heretic_revert_cast(user)
		return
	var/list/victims = knowledge.masquerade_targets(user)
	if(!length(victims))
		heretic_revert_cast(user, "Рядом нет видимых врагов, маскараду некого окружить.")
		return
	for(var/mob/living/victim as anything in victims)
		knowledge.masquerade_strike(user, victim)
	knowledge.masquerade_visuals(user)
	playsound(user, 'modular_bluemoon/sound/heretic/moon_eclipse.ogg', 45, TRUE)

/obj/effect/proc_holder/spell/self/heretic_moon/post_voice
	name = "Голос двойника"
	desc = "Включает и выключает повтор вашей речи из двойника на посту: пока голос включён, двойник вслух говорит вашим голосом всё, что говорите вы. Работает, пока двойник стоит, и в чужой хватке."
	summary = "Включает и выключает повтор вашей речи голосом двойника на посту."
	charge_max = 1 SECONDS
	usable_while_grabbed = TRUE
	action_icon_state = "moon_voice"

/obj/effect/proc_holder/spell/self/heretic_moon/post_voice/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge)
		heretic_revert_cast(user)
		return
	knowledge.toggle_post_voice(user)

/obj/effect/proc_holder/spell/self/heretic_moon/return_post
	name = "Возвращение в отражение"
	desc = "Две секунды стойте на месте: вы и двойник на посту меняетесь местами, даже если вас держат. Только к двойнику на этом же уровне; наручники, щит разума, запрет телепортации и зоны без телепортации не пускают. Перезарядка 60 секунд."
	summary = "2 секунды - и вы меняетесь местами с двойником на посту, даже из чужой хватки."
	charge_max = HERETIC_MOON_RETURN_COOLDOWN
	action_icon_state = "moon_return"
	usable_while_grabbed = TRUE

/obj/effect/proc_holder/spell/self/heretic_moon/return_post/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge?.return_to_post(user))
		heretic_revert_cast(user, knowledge?.moon_failure)

/obj/effect/proc_holder/spell/pointed/heretic_moon/sleepwalk
	name = "Сомнамбула"
	desc = "Укажите цель под лунным помутнением не дальше пяти клеток. Секунду её веки тяжелеют, затем 10 секунд она спит стоя с закрытыми глазами: не владеет телом и готова к обряду. Раз в секунду цель шагает к вашей копии, оставленной ждать серебряным зеркалом, а цель охоты - и к двойнику на посту не дальше 10 клеток; без них - к вам; обходит преграды, проходит сквозь людей и двери, к которым у неё есть доступ, и не ступает в космос, пропасть или лаву, а дойдя, стоит. Цель охоты, дошедшая до копии или двойника, даёт вам значок «Увести в отражение»: за 1 секунду он уводит её в изнанку, где бы на этом уровне вы ни стояли. Будят 2 секунды растолкать, удар нулевым жезлом и вспышка в трёх клетках. Потеря сознания или смерть обрывают сон. Антимагия защищает; после пробуждения цель минуту невосприимчива к Сомнамбуле. Перезарядка 40 секунд."
	summary = "Цель под помутнением 10 секунд спит на ходу и идёт к копии или к вам, цель охоты - и к двойнику."
	active_msg = "Укажите цель под лунным помутнением."
	deactive_msg = "Лунный сон рассеивается в вашей ладони."
	charge_max = HERETIC_MOON_SLEEPWALK_COOLDOWN
	range = HERETIC_MOON_SLEEPWALK_RANGE
	aim_assist = TRUE
	aim_assist_radius = 1
	action_icon_state = "moon_sleepwalk"

/obj/effect/proc_holder/spell/pointed/heretic_moon/sleepwalk/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!heretic_check(user, knowledge, silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = knowledge.sleepwalk_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_moon/sleepwalk/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!length(targets) || !knowledge?.sleepwalk(user, targets[1]))
		heretic_revert_cast(user, knowledge?.moon_failure)

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
	// KEEP_APART выводит нимб из-под фильтра тела.
	for(var/obj/effect/heretic_ascension_aura/aura in owner.vis_contents)
		aura.alpha = HERETIC_MOON_SHROUD_AURA_ALPHA
	RegisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER), PROC_REF(reveal))
	return TRUE

/datum/status_effect/heretic_moon_shroud/proc/reveal()
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_moon_shroud/on_remove()
	owner.remove_filter(filter_name)
	for(var/obj/effect/heretic_ascension_aura/aura in owner.vis_contents)
		aura.alpha = 255
	UnregisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER))
	return ..()

/datum/status_effect/heretic_moon_shroud/be_replaced()
	// Базовый be_replaced обнуляет owner без on_remove.
	on_remove()
	return ..()

/datum/eldritch_knowledge/moon_grasp
	name = "Касание серебра"
	summary = "Хватка размывает зрение, отнимает ещё 20 выносливости, посылает двойников на врага и путает его взгляд."
	details = list(
		"Цель 6 секунд под лунным помутнением: её берёт Сомнамбула.",
		"Вы почти исчезаете на 1 секунду, чтобы сменить позицию.",
		"Первая же атака снимает покров.",
	)
	role = HERETIC_ROLE_GRASP
	cost = 1
	route = PATH_MOON

/datum/eldritch_knowledge/moon_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.blur_eyes(3)
	victim.adjustStaminaLoss(20)
	victim.apply_status_effect(/datum/status_effect/heretic_moon_daze)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	knowledge?.direct_reflections(victim)
	if(isliving(user))
		var/mob/living/caster = user
		caster.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 1 SECONDS)
	return TRUE

/datum/eldritch_knowledge/spell/moon_exchange
	name = "Зеркальный обмен"
	summary = "Меняет вас местами со своей копией в 5 клетках прямой видимости."
	details = list(
		"Оба места - свободный пол; сквозь стены и закрытые двери обмен не ведёт.",
		"На вашем прежнем месте остаётся копия. Перезарядка 12 секунд.",
	)
	role = HERETIC_ROLE_SUPPORT
	cost = 1
	route = PATH_MOON
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_moon/exchange

/datum/eldritch_knowledge/moon_mark
	name = "Метка Луны"
	summary = "Хватка ставит метку, удар лунным клинком её взрывает."
	details = list(
		"Взрыв: 20 урона выносливости, размытое зрение, спутанность и замедление на 3 секунды.",
		"После взрыва цель 6 секунд под лунным помутнением: её берёт Сомнамбула.",
		"Двойники устремляются к цели клинка.",
	)
	role = HERETIC_ROLE_MARK
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
	owner.apply_status_effect(/datum/status_effect/heretic_moon_daze)
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
	summary = "Возвращение в отражение к двойнику на посту, серебряное зеркало и больше прочных копий."
	details = list(
		"«Возвращение в отражение»: 2 секунды на месте - и вы меняетесь местами с двойником на посту.",
		"Работает в чужой хватке, только на своём уровне; наручники и зоны без телепортации не пускают. Перезарядка 60 с.",
		"Держится 3 отражения, новые выдерживают 40 урона и живут 60 / 75 / 90 секунд по уровню покрова.",
		"Зеркальный обмен делает вас почти прозрачным на секунду, атака снимает покров.",
		"Осколок стекла и лист серебра на руне дают серебряное зеркало, одно на еретика.",
		"Зеркалом выберите копию: в «Помощи» она ждёт и зовёт сомнамбул, во «Вреде» гонится; затем укажите врага или пол.",
		"Из изнанки можно выйти к ждущей копии, на соседнюю с ней клетку.",
	)
	role = HERETIC_ROLE_ESCAPE
	cost = 1
	route = PATH_MOON
	required_atoms = list(/obj/item/shard, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/silver_mirror)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_moon/return_post
	var/datum/weakref/moon_ref
	var/datum/weakref/body_ref

/datum/eldritch_knowledge/moon_shroud/on_body_gain(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge)
		return
	moon_ref = WEAKREF(knowledge)
	body_ref = WEAKREF(user)
	knowledge.shrouded = TRUE
	grant_combat_power(user)
	knowledge.notify_resource_changed()

/datum/eldritch_knowledge/moon_shroud/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/knowledge = moon_ref?.resolve()
	if(knowledge)
		knowledge.shrouded = FALSE
		for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in knowledge.reflections)
			if(reflection.holding_position)
				reflection.hold_position(FALSE)
		knowledge.trim_reflections()
		knowledge.notify_resource_changed()
	var/mob/living/body = body_ref?.resolve()
	body?.remove_status_effect(/datum/status_effect/heretic_moon_shroud)
	remove_combat_power()
	moon_ref = null
	body_ref = null

/datum/eldritch_knowledge/moon_shroud/Destroy()
	on_body_lose(null)
	return ..()

/datum/eldritch_knowledge/spell/moon_sleepwalk
	name = "Сомнамбула"
	summary = "Цель под помутнением 10 секунд спит на ходу и идёт к копии или к вам, цель охоты - и к двойнику."
	details = list(
		"Помутнение - 6 секунд после Хватки, взрыва Метки Луны, Затмения или Осколков света; цель в 5 клетках.",
		"Секунду веки цели тяжелеют, затем 10 секунд она спит стоя с закрытыми глазами и готова к обряду.",
		"Раз в секунду шагает к копии, ждущей у зеркала, цель охоты - и к двойнику в 10 клетках; иначе к вам.",
		"Обходит преграды, проходит свои двери и сквозь людей; в космос, пропасть и лаву не ступает.",
		"Цель охоты у копии или двойника: значок «Увести в отражение» за 1 секунду уводит её в изнанку с любого места уровня.",
		"Будят 2 секунды растолкать, нулевой жезл и вспышка в 3 клетках; потеря сознания обрывает сон, антимагия защищает.",
		"После сна цель минуту невосприимчива к Сомнамбуле, к любому захвату - 15 секунд. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Она шла ко мне с закрытыми глазами. Луна светила ей вместо взгляда."
	cost = 2
	route = PATH_MOON
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_moon/sleepwalk

/datum/eldritch_knowledge/spell/moon_mirage
	name = "Шествие миражей"
	summary = "Заменяет отражения новой группой вокруг вас и меняет вас местами со случайной копией."
	details = list(
		"Копий - до текущего предела, на свободном полу в 2 клетках.",
		"Запрет телепортации оставляет вас на месте, копии всё равно встают. Перезарядка 25 секунд.",
	)
	role = HERETIC_ROLE_DEFENSE
	cost = 1
	route = PATH_MOON
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_moon/mirage

/datum/eldritch_knowledge/moon_refraction
	name = "Осколки света"
	summary = "Разбитая копия вспыхивает: враги в 2 клетках путаются и теряют 25 выносливости."
	details = list(
		"Задетые 6 секунд под лунным помутнением - их берёт Сомнамбула.",
		"Урон выносливости одной цели - не чаще раза в 2 секунды.",
		"Истёкшие и заменённые копии не вспыхивают, двойник на посту - тоже.",
	)
	role = HERETIC_ROLE_CONTROL
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
	summary = "Вспышка вокруг вас и ваших копий: 30 урона выносливости, спутанность и замедление врагам."
	details = list(
		"Радиус 2 клетки вокруг вас и каждой копии не дальше 5 клеток; каждая цель страдает один раз.",
		"Задетые замедлены на 3 секунды и 6 секунд под лунным помутнением.",
		"На вашем месте остаётся копия, а вы почти исчезаете на 4 секунды; атака снимает покров.",
		"Перезарядка 45 секунд.",
	)
	role = HERETIC_ROLE_CONTROL
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_MOON
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_moon/eclipse

/datum/eldritch_knowledge/final_eldritch/moon_final
	parallax_scene = ANTAG_SCENE_HERETIC_MOON
	name = "Обратная сторона Луны"
	summary = "До пяти прочных копий, перехват выстрелов без задержки и Лунный маскарад."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место и 30 секунд может помешать.",
		"Общая стойкость вознесения; до 5 отражений, удары 10 ушибов и 30 выносливости, прочность 50.",
		"Любая копия в 2 клетках на открытой линии ловит снаряд без задержки.",
		"Лунный маскарад: до 5 ближайших врагов в 7 клетках теряют 30 выносливости и путаются на 3 секунды.",
		"Задетые 12 секунд стреляют мимо, рядом с каждым 10 секунд бьётся своя копия. Перезарядка 40 секунд.",
		"Слабость: чужая вспышка в 3 клетках разбивает копии рядом и ослепляет вас на 2 секунды.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Я видел другую сторону. Там каждый взгляд принадлежит мне, но яркий свет всё ещё режет глаза."
	cost = 3
	route = PATH_MOON
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_moon/masquerade)
	var/datum/weakref/moon_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/moon_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = ..()
	if(.)
		to_chat(user, span_eldritch("За каждым плечом теперь скрывается ещё одна ваша тень. Предел отражений увеличен до пяти, копии в двух клетках на открытой линии без устали ловят выстрелы, а «Лунный маскарад» натравит тени на врагов вокруг и собьёт им прицел. Берегитесь чужих вспышек: свет разбивает отражения рядом и слепит вас."))

/datum/eldritch_knowledge/final_eldritch/moon_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(!knowledge)
		return
	moon_knowledge_ref = WEAKREF(knowledge)
	knowledge.ascension_active = TRUE
	knowledge.sync_reflection_auras(manifest = TRUE)
	user.AddComponent(/datum/component/heretic_moon_circus, knowledge)

/datum/eldritch_knowledge/final_eldritch/moon_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_moon_circus))
	var/datum/eldritch_knowledge/base_moon/knowledge = moon_knowledge_ref?.resolve()
	moon_knowledge_ref = null
	if(knowledge)
		knowledge.ascension_active = FALSE
		knowledge.trim_reflections()
	. = ..()
	knowledge?.sync_reflection_auras()

/// Цирк отражений вознёсшейся Луны: вспышка рядом разбивает копии и слепит владельца.
/datum/component/heretic_moon_circus
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/knowledge_ref

/datum/component/heretic_moon_circus/Initialize(datum/eldritch_knowledge/base_moon/knowledge)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	knowledge_ref = WEAKREF(knowledge)

/datum/component/heretic_moon_circus/RegisterWithParent()
	RegisterSignal(SSdcs, COMSIG_GLOB_BRIGHT_FLASH, PROC_REF(on_bright_flash))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_moon_circus/UnregisterFromParent()
	UnregisterSignal(SSdcs, COMSIG_GLOB_BRIGHT_FLASH)
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

/datum/component/heretic_moon_circus/proc/on_bright_flash(datum/source, turf/origin, mob/user)
	SIGNAL_HANDLER
	var/mob/living/owner = parent
	var/turf/owner_turf = get_turf(owner)
	if(user == owner || !origin || !owner_turf || owner.stat == DEAD || origin.z != owner_turf.z || get_dist(origin, owner_turf) > HERETIC_MOON_FLASH_RANGE)
		return
	if(!(owner_turf in heretic_field_view(HERETIC_MOON_FLASH_RANGE, origin)))
		return
	var/datum/eldritch_knowledge/base_moon/knowledge = knowledge_ref?.resolve()
	if(knowledge)
		for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection as anything in knowledge.reflections + knowledge.temporary_reflections)
			if(reflection.z == owner_turf.z && get_dist(reflection, owner_turf) <= HERETIC_MOON_FLASH_RANGE)
				reflection.shatter()
				qdel(reflection)
	owner.blind_eyes(HERETIC_MOON_FLASH_BLIND)
	owner.blur_eyes(HERETIC_MOON_FLASH_BLUR)
	playsound(owner_turf, 'modular_bluemoon/sound/heretic/moon_break.ogg', 50, TRUE)
	owner.visible_message(span_warning("Вспышка рассекает отражения вокруг [owner], и они осыпаются серебристой пылью!"), span_userdanger("Свет режет глаза, отражения вокруг вас разбиты!"))

/datum/component/heretic_moon_circus/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Вокруг мелькают серебристые отражения, готовые принять выстрел на себя. Яркая вспышка рядом разобьёт их и на миг ослепит хозяина.")

/// Лунатик после маскарада: оружие в руках бьёт мимо. Над головой мерцает лунное око, тело в серебряном ореоле иногда двоится.
/datum/status_effect/heretic_lunatic
	id = "heretic_lunatic"
	duration = HERETIC_MOON_LUNATIC_DURATION
	tick_interval = HERETIC_MOON_JITTER_INTERVAL
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_lunatic
	var/obj/effect/abstract/heretic_vfx_attached/eye

/datum/status_effect/heretic_lunatic/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_HERETIC_LUNATIC, id)
	owner.add_filter(HERETIC_MOON_LUNATIC_HALO, 2, drop_shadow_filter(x = 0, y = 0, size = HERETIC_MOON_HALO_SIZE, color = HERETIC_MOON_HALO_COLOR))
	eye = heretic_vfx_attach(owner, 'modular_bluemoon/icons/effects/heretic_vfx.dmi', "moon_eye")
	if(eye)
		eye.pixel_y = HERETIC_MOON_EYE_HEIGHT
		animate(eye, color = HERETIC_MOON_EYE_DIM, time = HERETIC_MOON_EYE_FLICKER, loop = -1, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
		animate(color = COLOR_WHITE, time = HERETIC_MOON_EYE_FLICKER, easing = SINE_EASING)
	return TRUE

/datum/status_effect/heretic_lunatic/tick()
	if(prob(HERETIC_MOON_JITTER_CHANCE) && heretic_vfx_watched(owner))
		jitter()

/// Тело лунатика на миг двоится зеркальным отражением.
/datum/status_effect/heretic_lunatic/proc/jitter()
	if(!isturf(owner?.loc))
		return null
	return new /obj/effect/temp_visual/heretic_moon_mirror(owner.loc, owner, pick(-HERETIC_MOON_JITTER_OFFSET, HERETIC_MOON_JITTER_OFFSET))

/datum/status_effect/heretic_lunatic/on_remove()
	REMOVE_TRAIT(owner, TRAIT_HERETIC_LUNATIC, id)
	owner.remove_filter(HERETIC_MOON_LUNATIC_HALO)
	eye?.fade_out()
	eye = null
	return ..()

/datum/status_effect/heretic_lunatic/Destroy()
	. = ..()
	QDEL_NULL(eye)

/atom/movable/screen/alert/status_effect/heretic_lunatic
	name = "Лунатик"
	desc = "Лунный маскарад сбил вам прицел: выстрелы уходят в сторону. Проходит через 12 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "moon_lunatic"

/datum/status_effect/heretic_moon_daze
	id = "heretic_moon_daze"
	duration = HERETIC_MOON_DAZE_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_moon_daze
	examine_text = span_warning("SUBJECTPRONOUN смотрит сквозь вас, взгляд плывёт серебром.")

/atom/movable/screen/alert/status_effect/heretic_moon_daze
	name = "Лунное помутнение"
	desc = "6 секунд еретик Луны может усыпить вас на ходу. Держитесь дальше пяти клеток от него."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "moon_daze"

/// Сомнамбула: секунду цель засыпает, затем спит стоя своим удержанием и раз в секунду шагает к зовущей копии.
/datum/status_effect/heretic_moon_sleepwalk
	id = "heretic_moon_sleepwalk"
	duration = HERETIC_MOON_SLEEPWALK_TELEGRAPH + HERETIC_MOON_SLEEPWALK_DURATION
	tick_interval = HERETIC_MOON_SLEEPWALK_STEP
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_moon_sleepwalk
	examine_text = span_warning("SUBJECTPRONOUN бредёт с закрытыми глазами, будто во сне. Растолкайте 2 секунды, коснитесь нулевым жезлом или ослепите вспышкой, и сон рассеется.")
	var/datum/weakref/moon_ref
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/sleep_timer
	var/asleep_until
	var/list/turf/route
	var/turf/route_goal
	var/route_misses = 0
	var/planning = FALSE
	var/applied = FALSE
	var/asleep = FALSE
	var/interrupted = FALSE
	/// Копия или двойник, у которых спящая стоит сейчас.
	var/datum/weakref/door_anchor
	var/datum/weakref/door_viewer
	var/datum/weakref/watched_anchor

/datum/status_effect/heretic_moon_sleepwalk/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_moon/moon)
	moon_ref = WEAKREF(moon)
	return ..()

/datum/status_effect/heretic_moon_sleepwalk/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_moon/moon = moon_ref?.resolve()
	if(!. || !moon?.moon_body)
		return FALSE
	applied = TRUE
	moon.sleepwalkers += src
	heretic_capture_hold(owner, HERETIC_MOON_CAPTURE)
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_door_moved))
	RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_collapse))
	RegisterSignal(SSdcs, COMSIG_GLOB_BRIGHT_FLASH, PROC_REF(on_bright_flash))
	sleep_timer = addtimer(CALLBACK(src, PROC_REF(fall_asleep)), HERETIC_MOON_SLEEPWALK_TELEGRAPH, TIMER_STOPPABLE)
	if(isturf(owner.loc))
		new /obj/effect/temp_visual/heretic_moon_mirror(owner.loc, owner, pick(-HERETIC_MOON_GHOST_SPLIT, HERETIC_MOON_GHOST_SPLIT))
	heretic_vfx_pulse(owner, HERETIC_MOON_SILVER, 2, HERETIC_MOON_SLEEPWALK_TELEGRAPH)
	owner.visible_message(span_warning("Взгляд [owner] стекленеет, веки медленно опускаются."), span_userdanger("Веки наливаются свинцом: вы засыпаете на ходу! Если вас растолкают, вы проснётесь."))
	return TRUE

/datum/status_effect/heretic_moon_sleepwalk/proc/fall_asleep()
	deltimer(sleep_timer)
	sleep_timer = null
	if(asleep || QDELETED(src) || !owner)
		return
	var/datum/eldritch_knowledge/base_moon/moon = moon_ref?.resolve()
	var/reason = moon ? moon.sleepwalk_hold_reason(owner) : "заклятие угасло"
	if(reason)
		interrupted = TRUE
		if(moon?.moon_body)
			to_chat(moon.moon_body, span_warning("Сомнамбула сорвалась: [reason]."))
		qdel(src)
		return
	asleep = TRUE
	asleep_until = world.time + HERETIC_MOON_SLEEPWALK_DURATION
	duration = asleep_until
	next_tick = world.time + HERETIC_MOON_SLEEPWALK_STEP
	// Без этого признака паралич удержания уложил бы спящего на пол.
	ADD_TRAIT(owner, TRAIT_MOBILITY_NOREST, id)
	owner.become_blind(id)
	heretic_spirit_passmob_on(owner, id)
	restraint = new(list(owner, HERETIC_MOON_SLEEPWALK_DURATION, TRUE))
	owner.add_filter(HERETIC_MOON_SLEEPWALK_FILTER, 2, drop_shadow_filter(x = 0, y = 0, size = HERETIC_MOON_HALO_SIZE, color = HERETIC_MOON_HALO_COLOR))
	owner.visible_message(span_warning("[owner] закрывает глаза и идёт, как во сне."), span_userdanger("Вы спите на ходу и не владеете телом. Если вас растолкают 2 секунды, коснутся нулевым жезлом или рядом сверкнёт вспышка, вы проснётесь."))
	log_combat(moon.moon_body, owner, "усыпляет на ходу Сомнамбулой")

/datum/status_effect/heretic_moon_sleepwalk/tick()
	if(!asleep || owner.stat >= UNCONSCIOUS)
		return
	var/datum/eldritch_knowledge/base_moon/moon = moon_ref?.resolve()
	var/atom/destination = moon?.sleepwalk_destination(owner)
	var/turf/goal = get_turf(destination)
	// Спящая, которую трясут или тянут в изнанку, стоит: шаг сорвал бы чужое действие.
	if(goal && get_dist(owner, goal) > 1 && !LAZYLEN(owner.targeted_by))
		walk_toward(moon, goal)
	update_reflection_door(moon, destination)

/datum/status_effect/heretic_moon_sleepwalk/proc/walk_toward(datum/eldritch_knowledge/base_moon/moon, turf/goal)
	if(!planning && (isnull(route) || goal != route_goal))
		INVOKE_ASYNC(src, PROC_REF(plan_route), goal)
	if(length(route) && follow_route(moon))
		return
	if(!length(route))
		moon.sleepwalk_step(owner, goal)

/// get_path_to может уснуть в очереди поиска, поэтому маршрут строится вне tick().
/datum/status_effect/heretic_moon_sleepwalk/proc/plan_route(turf/goal)
	planning = TRUE
	var/list/found = get_path_to(owner, goal, HERETIC_MOON_SLEEPWALK_PATH_LIMIT, 1, owner?.get_idcard(), TRUE, null, TRUE, src)
	if(QDELETED(src))
		return
	planning = FALSE
	route = found
	route_goal = goal
	route_misses = 0

/// Каждая клетка маршрута проверяется заново: поиск не знает про лаву и пропасти.
/datum/status_effect/heretic_moon_sleepwalk/proc/follow_route(datum/eldritch_knowledge/base_moon/moon)
	var/turf/here = get_turf(owner)
	var/turf/next = route[1]
	if(!here || !isturf(owner.loc) || owner.buckled || next.z != here.z || get_dist(here, next) != 1 || !moon.sleepwalk_safe_turf(next))
		route = null
		return FALSE
	if(owner.Move(next, get_dir(here, next)))
		route.Cut(1, 2)
		route_misses = 0
		return TRUE
	if(++route_misses >= HERETIC_MOON_SLEEPWALK_ROUTE_MISSES)
		route = null
	return TRUE

/// Цель охоты, дошедшая до копии или двойника, даёт еретику значок «Увести в отражение», пока изнанка её примет.
/datum/status_effect/heretic_moon_sleepwalk/proc/update_reflection_door(datum/eldritch_knowledge/base_moon/moon, atom/destination)
	var/mob/living/heretic_body = moon?.moon_body
	var/is_anchor = heretic_body && destination != heretic_body && moon.door_anchor_valid(destination)
	watch_anchor(is_anchor ? destination : null)
	door_anchor = (is_anchor && get_dist(owner, destination) <= 1) ? WEAKREF(destination) : null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(heretic_body)
	if(heretic && reflection_door_holds(heretic_body) && !heretic.pocket_pull_reason(heretic_body, owner, get_turf(owner)))
		show_reflection_door(heretic_body)
	else
		hide_reflection_door()

/// Шаг спящей или зовущей её копии обновляет дверь сразу, не дожидаясь шага сна.
/datum/status_effect/heretic_moon_sleepwalk/proc/on_door_moved(datum/source)
	SIGNAL_HANDLER
	if(!asleep || QDELETED(src))
		return
	var/datum/eldritch_knowledge/base_moon/moon = moon_ref?.resolve()
	update_reflection_door(moon, moon?.sleepwalk_destination(owner))

/datum/status_effect/heretic_moon_sleepwalk/proc/watch_anchor(atom/movable/anchor)
	var/atom/movable/watched = watched_anchor?.hard_resolve()
	if(watched == anchor)
		return
	if(watched)
		UnregisterSignal(watched, COMSIG_MOVABLE_MOVED)
	watched_anchor = anchor ? WEAKREF(anchor) : null
	if(anchor)
		RegisterSignal(anchor, COMSIG_MOVABLE_MOVED, PROC_REF(on_door_moved))

/// Спящая стоит у своей копии или двойника, еретик на том же уровне и может действовать.
/datum/status_effect/heretic_moon_sleepwalk/proc/reflection_door_holds(mob/living/user)
	var/datum/eldritch_knowledge/base_moon/moon = moon_ref?.resolve()
	var/mob/living/anchor = door_anchor?.resolve()
	if(QDELETED(src) || !asleep || !moon || user != moon.moon_body || !moon.can_use(user) || !moon.door_anchor_valid(anchor))
		return FALSE
	return isturf(owner.loc) && owner.z == anchor.z && get_dist(owner, anchor) <= 1 && user.z == owner.z

/datum/status_effect/heretic_moon_sleepwalk/proc/show_reflection_door(mob/living/heretic_body)
	if(door_viewer?.resolve() == heretic_body)
		return
	hide_reflection_door()
	var/atom/movable/screen/alert/heretic_moon_door/alert = heretic_body.throw_alert(HERETIC_MOON_DOOR_ALERT, /atom/movable/screen/alert/heretic_moon_door)
	if(!alert)
		return
	alert.walk_ref = WEAKREF(src)
	door_viewer = WEAKREF(heretic_body)
	to_chat(heretic_body, span_eldritch("[owner] спит у вашего отражения. Нажмите «Увести в отражение», и через [HERETIC_POCKET_PULL_TIME / (1 SECONDS)] с цель будет в изнанке, где бы вы ни стояли на этом уровне."))

/datum/status_effect/heretic_moon_sleepwalk/proc/hide_reflection_door()
	var/mob/living/viewer = door_viewer?.resolve()
	door_viewer = null
	var/atom/movable/screen/alert/heretic_moon_door/alert = viewer?.alerts[HERETIC_MOON_DOOR_ALERT]
	if(istype(alert) && alert.walk_ref?.hard_resolve() == src)
		viewer.clear_alert(HERETIC_MOON_DOOR_ALERT)

/datum/status_effect/heretic_moon_sleepwalk/proc/step_into_reflection(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !reflection_door_holds(user))
		to_chat(user, span_warning("Отражение закрылось: цель проснулась, отошла от копии или вы на другом уровне."))
		return FALSE
	var/mob/living/victim = owner
	return heretic.pocket_pull(user, victim, get_turf(victim), HERETIC_POCKET_PULL_TIME, CALLBACK(src, PROC_REF(reflection_door_holds), user), "Отражение рядом с [victim] раскрывается, и спящий шагает в него.")

/datum/status_effect/heretic_moon_sleepwalk/proc/wake(message)
	if(QDELETED(src))
		return
	interrupted = TRUE
	owner.visible_message(span_notice(message), span_notice("Вы вздрагиваете и просыпаетесь."))
	qdel(src)

/datum/status_effect/heretic_moon_sleepwalk/proc/on_shaken(datum/source, mob/living/helper)
	SIGNAL_HANDLER
	wake("[helper] расталкивает [owner], и тот открывает глаза.")

/datum/status_effect/heretic_moon_sleepwalk/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	log_game("[key_name(user)] будит сомнамбулу [key_name(owner)] нулевым жезлом в [AREACOORD(owner)].")
	wake("[user] касается [owner] нулевым жезлом, и лунный сон рассыпается.")
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_moon_sleepwalk/proc/on_bright_flash(datum/source, turf/origin, mob/user)
	SIGNAL_HANDLER
	var/turf/place = get_turf(owner)
	if(!origin || !place || origin.z != place.z || get_dist(origin, place) > HERETIC_MOON_FLASH_RANGE)
		return
	if(place in heretic_field_view(HERETIC_MOON_FLASH_RANGE, origin))
		wake("Вспышка бьёт [owner] сквозь веки, и сон рассеивается.")

/datum/status_effect/heretic_moon_sleepwalk/proc/on_sacrifice(datum/source)
	SIGNAL_HANDLER
	interrupted = TRUE
	qdel(src)

/datum/status_effect/heretic_moon_sleepwalk/proc/on_stat_change(datum/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat >= UNCONSCIOUS)
		on_collapse()

/datum/status_effect/heretic_moon_sleepwalk/proc/on_collapse(datum/source)
	SIGNAL_HANDLER
	interrupted = TRUE
	qdel(src)

/datum/status_effect/heretic_moon_sleepwalk/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_MOB_STATCHANGE, COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))
		UnregisterSignal(SSdcs, COMSIG_GLOB_BRIGHT_FLASH)
		deltimer(sleep_timer)
		sleep_timer = null
		hide_reflection_door()
		watch_anchor(null)
		door_anchor = null
		heretic_capture_unhold(owner, HERETIC_MOON_CAPTURE)
		// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся; удаляемый моб снимет его сам.
		if(!QDELETED(restraint) && !QDELETED(owner) && restraint.duration <= asleep_until)
			qdel(restraint)
		restraint = null
		REMOVE_TRAIT(owner, TRAIT_MOBILITY_NOREST, id)
		if(asleep)
			heretic_spirit_passmob_off(owner, id)
		owner.cure_blind(id)
		owner.remove_filter(HERETIC_MOON_SLEEPWALK_FILTER)
		var/datum/eldritch_knowledge/base_moon/moon = moon_ref?.resolve()
		moon?.sleepwalkers -= src
		if(asleep && !interrupted && owner.stat != DEAD)
			owner.visible_message(span_notice("[owner] открывает глаза и растерянно оглядывается."), span_notice("Вы просыпаетесь стоя и не помните дороги."))
		heretic_capture_release(owner, HERETIC_MOON_CAPTURE)
	moon_ref = null
	route = null
	route_goal = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_moon_sleepwalk
	name = "Сомнамбула"
	desc = "Вы спите на ходу и 10 секунд идёте туда, куда зовёт луна. Если вас растолкают 2 секунды, коснутся нулевым жезлом или рядом сверкнёт вспышка, вы проснётесь."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "moon_sleeper"

/atom/movable/screen/alert/heretic_moon_door
	name = "Увести в отражение"
	desc = "Цель охоты спит у вашей ждущей копии или двойника на посту. Нажмите: через 1 секунду она в изнанке, а вы вместе с ней, где бы вы ни стояли на этом уровне. Не двигайтесь, пока завеса тянет цель."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "moon_door"
	clickable_glow = TRUE
	var/datum/weakref/walk_ref

/atom/movable/screen/alert/heretic_moon_door/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/datum/status_effect/heretic_moon_sleepwalk/walk = walk_ref?.resolve()
	if(walk)
		INVOKE_ASYNC(walk, TYPE_PROC_REF(/datum/status_effect/heretic_moon_sleepwalk, step_into_reflection), owner)

/// Зеркальный двойник облика: отскакивает в сторону и гаснет, ссылку на образец не хранит.
/obj/effect/temp_visual/heretic_moon_mirror
	randomdir = FALSE
	duration = HERETIC_MOON_GHOST_TIME

/obj/effect/temp_visual/heretic_moon_mirror/Initialize(mapload, atom/model, offset = 0)
	if(model)
		appearance = model.appearance
		render_target = null
	var/matrix/flipped = matrix(transform)
	flipped.Scale(-1, 1)
	transform = flipped
	color = HERETIC_MOON_SILVER
	alpha = 0
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = BELOW_MOB_LAYER
	. = ..()
	animate(src, pixel_x = pixel_x + offset, time = duration, easing = QUAD_EASING | EASE_OUT)
	animate(src, alpha = HERETIC_MOON_GHOST_ALPHA, time = duration * 0.25, flags = ANIMATION_PARALLEL)
	animate(alpha = HERETIC_MOON_GHOST_ALPHA / 2, time = duration * 0.15)
	animate(alpha = HERETIC_MOON_GHOST_ALPHA, time = duration * 0.15)
	animate(alpha = 0, time = duration * 0.45, easing = SINE_EASING | EASE_IN)

/// Последний облик разбитой копии: белеет, раздаётся и гаснет.
/obj/effect/temp_visual/heretic_moon_shatter
	randomdir = FALSE
	duration = HERETIC_MOON_SHATTER_TIME
	var/static/list/silver_flash = list(0.45, 0, 0, 0, 0.45, 0, 0, 0, 0.5, 0.6, 0.65, 0.72)

/obj/effect/temp_visual/heretic_moon_shatter/Initialize(mapload, atom/model)
	if(model)
		appearance = model.appearance
		render_target = null
	color = silver_flash
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	. = ..()
	var/matrix/burst = matrix(transform)
	burst.Scale(HERETIC_MOON_SHATTER_SCALE)
	animate(src, transform = burst, alpha = 0, time = duration, easing = CUBIC_EASING | EASE_OUT)

/// Луна: осколки разбитого зеркала разлетаются, вращаются и ловят свет.
/particles/heretic_ascension/moon/shards
	icon_state = list("mirror_shard_1" = 2, "mirror_shard_2" = 3, "moon_mote" = 1)
	count = 16
	spawning = 8
	velocity = generator("circle", 3, 6)
	gravity = list(0, -0.25)
	friction = 0.1
	spin = generator("num", -16, 16)
	lifespan = 0.9 SECONDS
	fade = 0.4 SECONDS
	fadein = 0

/// Луна: редкие серебряные блики на копиях вознёсшейся.
/particles/heretic_ascension/moon/shimmer
	icon_state = list("moon_mote" = 3, "mirror_shard_2" = 1)
	count = 4
	spawning = 0.15
	position = generator("box", list(-9, -12, 0), list(9, 12, 0))
	velocity = generator("box", list(-0.1, 0, 0), list(0.1, 0.25, 0))
	friction = 0
	spin = 0
	lifespan = 1.2 SECONDS
	fadein = 0.4 SECONDS
	fade = 0.6 SECONDS

/obj/item/melee/sickly_blade/moon
	name = "moonlight blade"
	desc = "Серебристый клинок с двойным лезвием. Его отражение всегда немного запаздывает."
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	icon_state = "moon_blade"
	item_state = "moon_blade"
	mark_type = /datum/status_effect/eldritch/moon
	route = PATH_MOON

#undef HERETIC_MOON_RANGE
#undef HERETIC_MOON_WITNESS_RANGE
#undef HERETIC_MOON_BASE_LIMIT
#undef HERETIC_MOON_SHROUD_LIMIT
#undef HERETIC_MOON_ASCENDED_LIMIT
#undef HERETIC_MOON_PRESSURE
#undef HERETIC_MOON_ASCENDED_PRESSURE
#undef HERETIC_MOON_DAMAGE
#undef HERETIC_MOON_ASCENDED_DAMAGE
#undef HERETIC_MOON_HEALTH
#undef HERETIC_MOON_SHROUD_HEALTH
#undef HERETIC_MOON_ASCENDED_HEALTH
#undef HERETIC_MOON_LIFETIME
#undef HERETIC_MOON_POST_WANDER_CHANCE
#undef HERETIC_MOON_SLEEPWALK_FILTER
#undef HERETIC_MOON_SLEEPWALK_PATH_LIMIT
#undef HERETIC_MOON_SLEEPWALK_ROUTE_MISSES
#undef HERETIC_MOON_DOOR_ALERT
#undef HERETIC_MOON_REFRACTION_RADIUS
#undef HERETIC_MOON_MASQUERADE_RANGE
#undef HERETIC_MOON_MASQUERADE_TARGETS
#undef HERETIC_MOON_MASQUERADE_STAMINA
#undef HERETIC_MOON_MASQUERADE_CONFUSION
#undef HERETIC_MOON_MASQUERADE_LIFETIME
#undef HERETIC_MOON_SHROUD_AURA_ALPHA
#undef HERETIC_MOON_SILVER
#undef HERETIC_MOON_GHOST_TIME
#undef HERETIC_MOON_GHOST_ALPHA
#undef HERETIC_MOON_GHOST_SPLIT
#undef HERETIC_MOON_SHATTER_TIME
#undef HERETIC_MOON_SHATTER_SCALE
#undef HERETIC_MOON_SHATTER_FLASH_RANGE
#undef HERETIC_MOON_SHATTER_FLASH_POWER
#undef HERETIC_MOON_SHATTER_FLASH_TIME
#undef HERETIC_MOON_EYE_HEIGHT
#undef HERETIC_MOON_EYE_DIM
#undef HERETIC_MOON_EYE_FLICKER
#undef HERETIC_MOON_HALO_SIZE
#undef HERETIC_MOON_HALO_COLOR
#undef HERETIC_MOON_JITTER_INTERVAL
#undef HERETIC_MOON_JITTER_CHANCE
#undef HERETIC_MOON_JITTER_OFFSET
#undef HERETIC_MOON_MASQUERADE_GHOST_OFFSET
#undef HERETIC_MOON_MASQUERADE_WAVE_TIME
#undef HERETIC_MOON_MASQUERADE_FLASH_POWER
#undef HERETIC_MOON_MASQUERADE_FLASH_TIME
#undef HERETIC_MOON_MASQUERADE_QUAKE
#undef HERETIC_MOON_MASQUERADE_QUAKE_TIME
