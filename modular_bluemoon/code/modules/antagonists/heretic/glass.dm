#define HERETIC_GLASS_RANGE 5
#define HERETIC_GLASS_BARRIER_LIFETIME (12 SECONDS)
#define HERETIC_GLASS_PRISM_LIFETIME (120 SECONDS)
#define HERETIC_GLASS_ATTACK_LIMIT 3
#define HERETIC_GLASS_PANE_CRAFT "glass_pane"
#define HERETIC_GLASS_PANE_CLUE "В стекле отражается не эта комната."
#define HERETIC_GLASS_PANE_ALPHA 60
#define HERETIC_GLASS_CAPTURE "glass"
#define HERETIC_GLASS_MARK_BLIND (1 SECONDS)
#define HERETIC_GLASS_STORM_BLIND (3 SECONDS)
#define HERETIC_GLASS_STORM_PANE_RANGE 7
#define HERETIC_GLASS_BARRIER_COOLDOWN (8 SECONDS)
#define HERETIC_GLASS_CASKET_RANGE 3
#define HERETIC_GLASS_CASKET_COST 2
#define HERETIC_GLASS_CASKET_TELEGRAPH (1 SECONDS)
#define HERETIC_GLASS_CASKET_DURATION (10 SECONDS)
#define HERETIC_GLASS_CASKET_INTEGRITY 90
#define HERETIC_GLASS_CASKET_MELEE_MULTIPLIER 1.5
#define HERETIC_GLASS_CASKET_COOLDOWN (45 SECONDS)
#define HERETIC_GLASS_CASKET_GROWTH_LIFETIME (HERETIC_GLASS_CASKET_TELEGRAPH * 2)
#define HERETIC_GLASS_CASKET_GROWTH_SCALE 0.4
#define HERETIC_GLASS_CASKET_GROWTH_ALPHA 200
#define HERETIC_GLASS_GAZE_DURATION (20 SECONDS)
#define HERETIC_GLASS_GAZE_COOLDOWN (20 SECONDS)
#define HERETIC_GLASS_PASSAGE_TIME (1 SECONDS)
#define HERETIC_GLASS_PASSAGE_TRACE (30 SECONDS)
#define HERETIC_GLASS_PASSAGE_COOLDOWN (2 SECONDS)
#define HERETIC_GLASS_BEAM_DAMAGE 30
#define HERETIC_GLASS_SPLIT_DAMAGE 24
#define HERETIC_GLASS_REFRACTION_BONUS 6
#define HERETIC_GLASS_BARRIER_REFLECTIONS 2
#define HERETIC_GLASS_BARRIER_LIMIT 2
#define HERETIC_GLASS_REFLECTION_WEAR 15
#define HERETIC_GLASS_INK "#d8b3e2"
#define HERETIC_GLASS_PRISM_WHITE "#e9f9ff"
#define HERETIC_GLASS_FACET_OFFSET 12
#define HERETIC_GLASS_FACET_TIME (0.4 SECONDS)
#define HERETIC_GLASS_STREAK_LENGTH 48
#define HERETIC_GLASS_STREAK_WIDTH 0.8
#define HERETIC_GLASS_STREAK_START 0.1
#define HERETIC_GLASS_STREAK_GROW (0.08 SECONDS)
#define HERETIC_GLASS_STREAK_FADE (0.3 SECONDS)
#define HERETIC_GLASS_FLASH_COOLDOWN (0.5 SECONDS)
#define HERETIC_GLASS_FLASH_RANGE 2
#define HERETIC_GLASS_FLASH_POWER 1.2
#define HERETIC_GLASS_FLASH_TIME (0.3 SECONDS)
#define HERETIC_GLASS_CRACK_TIME (0.5 SECONDS)
#define HERETIC_GLASS_CRACK_COOLDOWN (0.3 SECONDS)
#define HERETIC_GLASS_BEAM_WARN_WIDTH 0.3
#define HERETIC_GLASS_BEAM_WARN_ALPHA 90
#define HERETIC_GLASS_BEAM_CHARGED_WIDTH 0.5
#define HERETIC_GLASS_BEAM_CHARGED_ALPHA 170
#define HERETIC_GLASS_BEAM_WARN_RISE 0.3
#define HERETIC_GLASS_BEAM_FIRE_WIDTH 1.5
#define HERETIC_GLASS_BEAM_FADE_WIDTH 0.2
#define HERETIC_GLASS_BEAM_FIRE_TIME (0.08 SECONDS)
#define HERETIC_GLASS_BEAM_FADE (0.35 SECONDS)
#define HERETIC_GLASS_GATHER_RADIUS 2
#define HERETIC_GLASS_VOLLEY_FLASH_RANGE 5
#define HERETIC_GLASS_VOLLEY_FLASH_POWER 2
#define HERETIC_GLASS_VOLLEY_FLASH_TIME (0.4 SECONDS)
#define HERETIC_GLASS_VOLLEY_QUAKE 0.12
#define HERETIC_GLASS_VOLLEY_QUAKE_TIME (0.35 SECONDS)
#define HERETIC_GLASS_VOLLEY_QUAKE_RADIUS 7

/datum/heretic_path/glass
	id = PATH_GLASS
	deed_type = /datum/heretic_deed/glass
	name = "Стекло"
	tagline = "Смотрит и стреляет через окна станции, уходит сквозь стекло, запирает жертву в витраж."
	craft_summary = "Хваткой настройте окно или зеркало: до 6 стёкол смотрят и стреляют светом."
	capture_summary = "Витраж держит цель 10 секунд; у своего стекла её уводят в изнанку сердцем или рукой по другому своему стеклу."
	escape_summary = "Шаг сквозь своё окно выводит по ту сторону стекла; из изнанки выходите к своим стёклам."
	strength_points = list(
		"Настроенные стёкла - глаза по всей станции через Вдовью призму.",
		"Луч бьёт на 5 клеток без подготовки, призмы достают из-за угла.",
		"Витраж держит цель 10 секунд: хватит, чтобы начать обряд.",
		"Шаг сквозь окно отрывает от погони там, где нет двери.",
		"Преграды пропускают ваши лучи и возвращают лазеры.",
		"Цель охоты у своего стекла, одну или с вашими трещинами, утянет в изнанку рука по другому своему стеклу.",
	)
	weakness_points = list(
		"Нулевой жезл снимает настройку, а вставленное заново окно уже не ваше.",
		"Лучи и Витраж заранее видны: клетки подсвечены, от саркофага можно отойти.",
		"Саркофаг отражает лазеры, но удары и броски бьют его в полтора раза сильнее.",
		"Призмы и преграды разбиваются, пули преграда не отражает.",
		"Уйти сквозь стекло можно только там, где заранее настроено окно.",
		"Кражу видно 2 секунды: стекло рябит, цель предупреждена; схватите её или уведите от стекла.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_glass,
		/datum/eldritch_knowledge/glass_grasp,
		/datum/eldritch_knowledge/spell/glass_shards,
		/datum/eldritch_knowledge/spell/glass_casket,
		/datum/eldritch_knowledge/glass_mark,
		/datum/eldritch_knowledge/glass_relic,
		/datum/eldritch_knowledge/glass_passage,
		/datum/eldritch_knowledge/glass_temper,
		/datum/eldritch_knowledge/spell/glass_storm,
		/datum/eldritch_knowledge/final_eldritch/glass_final,
	)

/datum/eldritch_knowledge/base_glass
	name = "Первая трещина"
	summary = "Настраивает окна и зеркала Хваткой и даёт бесплатный луч на 5 клеток."
	details = list(
		"Хватка по окну или зеркалу настраивает стекло, не разбивая его.",
		"Держится до 6 стёкол, новое вытесняет самое старое; каждый отдел идёт в дело один раз.",
		"Преломлённый луч: укажите цель или клетку, через 0,6 секунды он бьёт на 30 ушибов.",
		"Луч бесплатный, перезарядка 6 секунд; ваши призмы стреляют вместе с ним.",
		"Нож и лист стекла на руне дают стеклянный клинок.",
		"Экипаж видит в настроенном стекле чужую комнату, нулевой жезл снимает настройку.",
		"«Помощь» по своему стеклу крадёт цель охоты у другого своего стекла, если она одна или треснула: 2 с, раз в 90 с.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Я смотрел сквозь стекло, пока не заметил трещину на той стороне неба."
	route = PATH_GLASS
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/glass)
	result_atoms = list(/obj/item/melee/sickly_blade/glass)
	combat_resource = 2
	combat_resource_name = "Грани"
	resource_rules = list(
		"Начальный запас 2 из 4, одна грань возвращается каждые 4 секунды.",
		"Взрыв Метки Стекла клинком даёт ещё одну грань.",
		"Призма, преграда и шаг сквозь стекло стоят 1 грань, Витраж - 2.",
		"Лучи бесплатны, их ограничивает только перезарядка.",
		"Смерть и смена тела рассыпают грани, призмы и саркофаги; настроенные стёкла остаются.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_glass/release
	grasp_visual = /obj/effect/temp_visual/heretic_glass/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/glass_grasp.ogg'
	grasp_catchphrase = "STI'KLAS PRI'SIMENA"
	var/mob/living/glass_body
	var/list/datum/heretic_glass_attack/attacks = list()
	var/list/obj/structure/heretic_glass_prism/prisms = list()
	var/list/obj/structure/heretic_glass_barrier/barriers = list()
	var/list/obj/structure/heretic_glass_casket/caskets = list()
	var/list/datum/status_effect/heretic_glass_fracture/fractures = list()
	var/list/datum/status_effect/eldritch/glass/marks = list()
	var/list/obj/effect/temp_visual/heretic_glass/visuals = list()
	/// Окна и зеркала с ремеслом «glass_pane», старейшее первым.
	var/list/atom/attuned_panes = list()
	var/list/blind_timers = list()
	var/datum/heretic_glass_network/active_network
	var/glass_generation = 0
	var/ascension_active = FALSE
	var/glass_failure
	COOLDOWN_DECLARE(facet_regeneration)
	COOLDOWN_DECLARE(barrier_cooldown)
	COOLDOWN_DECLARE(theft_cooldown)

/datum/eldritch_knowledge/base_glass/on_body_gain(mob/living/user)
	if(!user?.mind || glass_body == user)
		return
	if(glass_body)
		on_body_lose(glass_body)
	glass_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_temper()
	COOLDOWN_START(src, facet_regeneration, ascension_active ? 2 SECONDS : 4 SECONDS)

/datum/eldritch_knowledge/base_glass/on_body_lose(mob/living/user)
	if(glass_body)
		UnregisterSignal(glass_body, COMSIG_PARENT_QDELETING)
	glass_body = null
	ascension_active = FALSE
	remove_combat_power()
	clear_glass()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_glass/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(glass_body)

/datum/eldritch_knowledge/base_glass/on_death(mob/user)
	clear_glass()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_glass/Destroy()
	on_body_lose(glass_body)
	for(var/key in blind_timers.Copy())
		var/datum/timedevent/cure = SStimer.timer_id_dict[blind_timers[key]]
		cure?.callBack.Invoke()
	blind_timers.Cut()
	for(var/atom/pane as anything in attuned_panes.Copy())
		qdel(heretic_craft_on(pane, HERETIC_GLASS_PANE_CRAFT))
	attuned_panes.Cut()
	return ..()

/datum/eldritch_knowledge/base_glass/proc/clear_glass()
	glass_generation++
	QDEL_NULL(active_network)
	QDEL_LIST(attacks)
	QDEL_LIST(prisms)
	QDEL_LIST(barriers)
	QDEL_LIST(caskets)
	QDEL_LIST(fractures)
	QDEL_LIST(marks)
	QDEL_LIST(visuals)

/datum/eldritch_knowledge/base_glass/proc/clear_knowledge_effects(datum/eldritch_knowledge/knowledge)
	for(var/datum/heretic_glass_attack/attack as anything in attacks.Copy())
		if(attack.knowledge_ref?.resolve() == knowledge)
			qdel(attack)
	for(var/obj/structure/heretic_glass_prism/prism as anything in prisms.Copy())
		if(prism.knowledge_ref?.resolve() == knowledge)
			qdel(prism)
	for(var/obj/structure/heretic_glass_barrier/barrier as anything in barriers.Copy())
		if(barrier.knowledge_ref?.resolve() == knowledge)
			qdel(barrier)
	for(var/obj/structure/heretic_glass_casket/casket as anything in caskets.Copy())
		if(casket.knowledge_ref?.resolve() == knowledge)
			qdel(casket)

/datum/eldritch_knowledge/base_glass/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == glass_body && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_GLASS && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_glass/proc/update_temper(ignore_temper = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass_body)
	var/datum/eldritch_knowledge/glass_temper/temper = heretic?.get_knowledge(/datum/eldritch_knowledge/glass_temper)
	if(ignore_temper || QDELETED(temper))
		temper = null
	combat_resource_max = ascension_active ? 8 : temper ? temper.passive_values[temper.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	for(var/obj/structure/heretic_glass_barrier/barrier as anything in barriers.Copy())
		var/damage = barrier.max_integrity - barrier.obj_integrity
		barrier.max_integrity = temper ? 45 + 15 * temper.passive_level : 45
		barrier.obj_integrity = max(0, barrier.max_integrity - damage)
		if(!barrier.obj_integrity)
			qdel(barrier)
	notify_resource_changed()

/datum/eldritch_knowledge/base_glass/combat_resource_state()
	return "Призм: [length(prisms)] из [ascension_active ? 5 : 3]. Настроено стёкол: [length(attuned_panes)] из [HERETIC_GLASS_ATTUNE_LIMIT]."

/datum/eldritch_knowledge/base_glass/on_mark_detonated(mob/living/user, mob/living/target)
	if(can_use(user) && isturf(target?.loc) && heretic_can_affect(user, target, chargecost = 0))
		gain_combat_resource()

/datum/eldritch_knowledge/base_glass/on_life(mob/user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, facet_regeneration))
		return
	gain_combat_resource()
	COOLDOWN_START(src, facet_regeneration, ascension_active ? 2 SECONDS : 4 SECONDS)

/datum/eldritch_knowledge/base_glass/proc/line_clear(atom/start, atom/end, max_distance = HERETIC_GLASS_RANGE, allow_prisms = FALSE, pass_tables = FALSE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > max_distance)
		return FALSE
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!ray_tile_open(tile, allow_prisms, pass_tables))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/ray_tile_open(turf/tile, allow_prisms = TRUE, pass_tables = FALSE)
	if(!isopenturf(tile))
		return FALSE
	for(var/obj/obstacle in tile)
		if(!obstacle.density || (pass_tables && (obstacle.pass_flags_self & PASSTABLE)))
			continue
		if(allow_prisms && istype(obstacle, /obj/structure/heretic_glass_prism))
			var/obj/structure/heretic_glass_prism/prism = obstacle
			if(prism.glass_ref?.resolve() == src)
				continue
		if(allow_prisms && istype(obstacle, /obj/structure/heretic_glass_barrier))
			var/obj/structure/heretic_glass_barrier/barrier = obstacle
			if(barrier.glass_ref?.resolve() == src)
				continue
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/fracture(mob/living/victim)
	return victim.apply_status_effect(/datum/status_effect/heretic_glass_fracture, src)

/datum/eldritch_knowledge/base_glass/proc/fractured_by_me(mob/living/victim)
	var/datum/status_effect/heretic_glass_fracture/fracture = victim?.has_status_effect(/datum/status_effect/heretic_glass_fracture)
	return fracture?.glass_ref?.resolve() == src

/datum/eldritch_knowledge/base_glass/proc/glass_blind_source()
	return "heretic_glass_blind_[REF(src)]"

/// Более короткая вспышка не сокращает уже идущую слепоту от того же еретика.
/datum/eldritch_knowledge/base_glass/proc/blind(mob/living/victim, duration)
	var/source = glass_blind_source()
	var/key = REF(victim)
	var/datum/timedevent/current = SStimer.timer_id_dict[blind_timers[key]]
	if(current && current.timeToRun >= world.time + duration && HAS_TRAIT_FROM(victim, TRAIT_BLIND, source))
		return
	victim.become_blind(source)
	blind_timers[key] = addtimer(CALLBACK(src, PROC_REF(end_blind), WEAKREF(victim), key), duration, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE | TIMER_NO_HASH_WAIT)

/datum/eldritch_knowledge/base_glass/proc/end_blind(datum/weakref/victim_ref, key)
	blind_timers -= key
	var/mob/living/victim = victim_ref.resolve()
	victim?.cure_blind(glass_blind_source())

/datum/eldritch_knowledge/base_glass/proc/pane_usable(obj/structure/pane)
	if(QDELETED(pane) || !isturf(pane.loc))
		return FALSE
	if(istype(pane, /obj/structure/mirror))
		return !pane.broken
	return istype(pane, /obj/structure/window) && pane.obj_integrity > 0

/datum/eldritch_knowledge/base_glass/proc/attune(obj/structure/pane, mob/living/user)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !can_use(user) || !pane_usable(pane))
		return FALSE
	if(pane.GetComponent(/datum/component/heretic_craft))
		grasp_failure_reason = (pane in attuned_panes) ? "Это стекло уже настроено: выберите другое окно или зеркало." : "На этом стекле уже лежит чужое ремесло."
		return FALSE
	grasp_failure_reason = heretic.deed_wait_reason(heretic.deed_key_for(pane))
	if(grasp_failure_reason)
		return FALSE
	while(length(attuned_panes) >= HERETIC_GLASS_ATTUNE_LIMIT)
		var/atom/oldest = attuned_panes[1]
		log_game("[key_name(user)] теряет настройку Стекла на [oldest] ([oldest.type]) в [AREACOORD(oldest)]: её вытеснило новое стекло.")
		attuned_panes -= oldest
		qdel(heretic_craft_on(oldest, HERETIC_GLASS_PANE_CRAFT))
	var/mutable_appearance/marking = mutable_appearance('modular_bluemoon/icons/obj/heretic_glass_effects.dmi', "glass_mark", alpha = HERETIC_GLASS_PANE_ALPHA)
	pane.AddComponent(/datum/component/heretic_craft, src, HERETIC_GLASS_PANE_CRAFT, HERETIC_GLASS_PANE_CLUE, marking)
	attuned_panes += pane
	RegisterSignal(pane, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_pane_hand))
	playsound(pane, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 40, TRUE)
	to_chat(user, span_eldritch("[pane] теперь ваш глазок. Настроено стёкол: [length(attuned_panes)] из [HERETIC_GLASS_ATTUNE_LIMIT]."))
	log_game("[key_name(user)] настраивает стекло [pane] ([pane.type]) под ремесло Стекла в [AREACOORD(pane)].")
	heretic.advance_deed(heretic.deed_key_for(pane), get_turf(user))
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_glass/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_GLASS_PANE_CRAFT)
		return
	attuned_panes -= crafted
	UnregisterSignal(crafted, COMSIG_ATOM_ATTACK_HAND)
	notify_resource_changed()

/datum/eldritch_knowledge/base_glass/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/structure/pane as anything in attuned_panes)
		if(pane_usable(pane))
			heretic_add_pocket_exit(., "Стекло - [get_area_name(pane, TRUE)]", heretic_pocket_landing(get_turf(pane)))

/datum/eldritch_knowledge/base_glass/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в стекло", "text" = "Стекло рядом с [victim] подаётся, как вода.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель в своём саркофаге или готова к обряду и стоит у своего настроенного стекла, еретик рядом с ней.
/datum/eldritch_knowledge/base_glass/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/held = FALSE
	for(var/obj/structure/heretic_glass_casket/casket as anything in caskets)
		if(casket.victim == victim)
			held = TRUE
			break
	if(!held && !heretic.hunt_target_ready(victim))
		return FALSE
	return !!pane_near(victim)

/datum/eldritch_knowledge/base_glass/proc/pane_near(mob/living/victim)
	for(var/obj/structure/pane as anything in attuned_panes)
		if(pane_usable(pane) && pane.z == victim.z && get_dist(pane, victim) <= 1)
			return pane
	return null

/datum/eldritch_knowledge/base_glass/proc/on_pane_hand(atom/source, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(user) || user.a_intent != INTENT_HELP || !can_use(user) || get_dist(user, source) > 1)
		return NONE
	var/list/doors = theft_doors(user, source)
	if(!length(doors))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(offer_theft), user, source, doors)
	return COMPONENT_NO_ATTACK_HAND

/// Цель охоты у своих стёкол на уровне стекла, которого коснулся еретик: подпись -> list("victim", "pane").
/datum/eldritch_knowledge/base_glass/proc/theft_doors(mob/living/user, obj/structure/through)
	. = list()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/mob/living/carbon/human/victim = heretic?.hunt_target?.current
	if(!istype(victim) || victim.stat == DEAD)
		return
	for(var/obj/structure/pane as anything in attuned_panes)
		if(theft_holds(user, through, pane, victim))
			.[heretic_unique_label(., "Стекло - [get_area_name(pane, TRUE)]: [victim.real_name]")] = list("victim" = victim, "pane" = pane)

/datum/eldritch_knowledge/base_glass/proc/theft_holds(mob/living/user, obj/structure/through, obj/structure/pane, mob/living/victim)
	if(!can_use(user) || !(through in attuned_panes) || !(pane in attuned_panes) || !pane_usable(through) || !pane_usable(pane))
		return FALSE
	if(through.z != user.z || get_dist(user, through) > 1 || pane.z != through.z)
		return FALSE
	if(QDELETED(victim) || !isturf(victim.loc) || victim.z != pane.z || get_dist(victim, pane) > 1)
		return FALSE
	if(victim.buckled || (victim.pulledby && victim.pulledby != user))
		return FALSE
	return fractured_by_me(victim) || heretic_pocket_alone(victim, user, HERETIC_GLASS_THEFT_ALONE_RANGE)

/datum/eldritch_knowledge/base_glass/proc/offer_theft(mob/living/user, obj/structure/through, list/doors)
	if(!COOLDOWN_FINISHED(src, theft_cooldown))
		to_chat(user, span_warning("Стекло ещё не отзывается на кражу: осталось [heretic_capture_seconds_left(theft_cooldown)] с."))
		return FALSE
	var/choice = tgui_input_list(user, "Кого утянуть сквозь стекло?", "Кража сквозь стекло", doors)
	if(!choice || QDELETED(src))
		return FALSE
	return steal_through(user, through, choice)

/// Удалённая дверь: условие проверяется каждый тик, перезарядка тратится только на удачный вход.
/datum/eldritch_knowledge/base_glass/proc/steal_through(mob/living/user, obj/structure/through, choice)
	var/list/doors = theft_doors(user, through)
	var/list/door = doors[choice]
	if(!door)
		to_chat(user, span_warning("У того стекла больше нет цели для кражи."))
		return FALSE
	if(!COOLDOWN_FINISHED(src, theft_cooldown))
		to_chat(user, span_warning("Стекло ещё не отзывается на кражу: осталось [heretic_capture_seconds_left(theft_cooldown)] с."))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/mob/living/victim = door["victim"]
	var/obj/structure/pane = door["pane"]
	var/turf/entry = get_turf(victim)
	var/datum/callback/check = CALLBACK(src, PROC_REF(theft_holds), user, through, pane, victim)
	if(!heretic.pocket_pull_check(user, victim, entry, check, TRUE))
		return FALSE
	new /obj/effect/temp_visual/heretic_glass/grasp(get_turf(pane), src)
	playsound(pane, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 50, TRUE)
	log_game("[key_name(user)] тянет [key_name(victim)] сквозь стекло [pane] в [AREACOORD(pane)] от стекла в [AREACOORD(through)].")
	if(!heretic.pocket_pull(user, victim, entry, HERETIC_GLASS_THEFT_TIME, check, "Стекло рядом идёт рябью, из него тянется рука.", hold_on_entry = FALSE, victim_text = "Стекло рядом с вами идёт рябью - из него тянется рука!"))
		return FALSE
	COOLDOWN_START(src, theft_cooldown, HERETIC_GLASS_THEFT_COOLDOWN)
	return TRUE

/// Каждое настроенное стекло рядом бьёт лучом в сторону заклинателя.
/datum/eldritch_knowledge/base_glass/proc/pane_cells(mob/living/user)
	var/list/cells = list()
	var/turf/target = get_turf(user)
	for(var/obj/structure/pane as anything in attuned_panes)
		var/turf/start = get_turf(pane)
		if(!pane_usable(pane) || !target || start == target || start.z != target.z || get_dist(start, target) > HERETIC_GLASS_STORM_PANE_RANGE)
			continue
		var/list/beam_cells = trace_ray(start, get_dir(start, target), aimed_turf = target)
		for(var/list/cell as anything in beam_cells)
			var/list/path = cell["path"]
			path.Cut(1, 2)
			cell["pane"] = WEAKREF(pane)
		cells += beam_cells
	return cells

/datum/eldritch_knowledge/base_glass/proc/prism_snapshot(obj/structure/heretic_glass_prism/prism)
	return list("ref" = WEAKREF(prism), "dir" = prism.dir, "split" = prism.split, "turf" = get_turf(prism))

/// Каждая отмеченная клетка хранит весь путь луча и положения его призм.
/datum/eldritch_knowledge/base_glass/proc/trace_ray(turf/start, direction, obj/structure/heretic_glass_prism/source_prism, turf/aimed_turf)
	var/list/result = list()
	var/list/queue = list()
	var/list/first_nodes = list()
	var/list/first_path = list(start)
	if(source_prism)
		first_nodes += list(prism_snapshot(source_prism))
	if(source_prism && !aimed_turf)
		for(var/output_dir in source_prism.output_directions())
			queue += list(list("place" = start, "dir" = output_dir, "path" = first_path.Copy(), "nodes" = first_nodes.Copy(), "split" = source_prism.split))
	else
		var/aim_delta_x = aimed_turf ? aimed_turf.x - start.x : 0
		var/aim_delta_y = aimed_turf ? aimed_turf.y - start.y : 0
		queue += list(list("place" = start, "dir" = direction, "path" = first_path.Copy(), "nodes" = first_nodes.Copy(), "split" = FALSE, "aim_delta_x" = aim_delta_x, "aim_delta_y" = aim_delta_y))
		if(source_prism?.split)
			var/list/split_outputs = source_prism.output_directions(get_dir(start, aimed_turf))
			queue += list(list("place" = start, "dir" = split_outputs[1], "path" = first_path.Copy(), "nodes" = first_nodes.Copy(), "split" = TRUE))
	var/cell_budget = ascension_active ? 18 : 12
	var/refraction_limit = ascension_active ? 5 : 3
	while(length(queue) && cell_budget > 0)
		var/list/branch = queue[1]
		queue.Cut(1, 2)
		var/turf/tile = branch["place"]
		var/list/path = branch["path"]
		var/list/nodes = branch["nodes"]
		var/aim_delta_x = branch["aim_delta_x"] || 0
		var/aim_delta_y = branch["aim_delta_y"] || 0
		var/aim_steps = max(abs(aim_delta_x), abs(aim_delta_y))
		for(var/step_index in 1 to HERETIC_GLASS_RANGE)
			if(cell_budget-- <= 0)
				break
			if(aim_steps)
				var/offset_x = SIGN(aim_delta_x) * round(abs(aim_delta_x) * step_index / aim_steps + 0.5)
				var/offset_y = SIGN(aim_delta_y) * round(abs(aim_delta_y) * step_index / aim_steps + 0.5)
				tile = locate(start.x + offset_x, start.y + offset_y, start.z)
			else
				tile = get_step(tile, branch["dir"])
			if(!tile || !ray_tile_open(tile))
				break
			path += tile
			var/obj/structure/heretic_glass_prism/prism = locate() in tile
			if(prism)
				var/seen = FALSE
				for(var/list/snapshot as anything in nodes)
					var/datum/weakref/prism_ref = snapshot["ref"]
					if(prism_ref.resolve() == prism)
						seen = TRUE
						break
				if(seen || length(nodes) >= refraction_limit)
					break
				nodes += list(prism_snapshot(prism))
				for(var/output_dir in prism.output_directions())
					queue += list(list("place" = tile, "dir" = output_dir, "path" = path.Copy(), "nodes" = nodes.Copy(), "split" = branch["split"] || prism.split))
				break
			result += list(list("tile" = tile, "dir" = branch["dir"], "path" = path.Copy(), "nodes" = nodes.Copy(), "split" = branch["split"]))
	return result

/datum/eldritch_knowledge/base_glass/proc/route_valid(list/cell)
	var/datum/weakref/pane_ref = cell["pane"]
	if(pane_ref)
		var/obj/structure/pane = pane_ref.resolve()
		if(!pane_usable(pane) || !(pane in attuned_panes))
			return FALSE
	var/list/allowed_prisms = list()
	var/list/nodes = cell["nodes"]
	for(var/list/snapshot as anything in nodes)
		var/datum/weakref/prism_ref = snapshot["ref"]
		var/obj/structure/heretic_glass_prism/prism = prism_ref.resolve()
		if(!prism || prism.glass_ref?.resolve() != src || get_turf(prism) != snapshot["turf"] || prism.dir != snapshot["dir"] || prism.split != snapshot["split"])
			return FALSE
		allowed_prisms += prism
	var/list/path = cell["path"]
	for(var/turf/tile as anything in path)
		if(!ray_tile_open(tile))
			return FALSE
		var/obj/structure/heretic_glass_prism/prism = locate() in tile
		if(prism && !(prism in allowed_prisms))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/release(mob/living/user, atom/target)
	var/turf/destination = get_turf(target)
	if(!can_use(user) || !destination || destination == get_turf(user) || destination.z != user.z || get_dist(user, target) > HERETIC_GLASS_RANGE || length(attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		return FALSE
	var/list/cells = trace_ray(get_turf(user), get_dir(user, target), aimed_turf = destination)
	var/obj/structure/heretic_glass_prism/source_prism = locate() in destination
	if(source_prism?.glass_ref?.resolve() == src)
		cells += relay_cells(user, source_prism = source_prism)
	else
		cells += relay_cells(user, aimed_turf = destination)
	if(!length(cells))
		return FALSE
	new /datum/heretic_glass_attack(src, cells, 0.6 SECONDS, src)
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/relay_cells(mob/living/user, turf/aimed_turf, obj/structure/heretic_glass_prism/source_prism)
	var/list/cells = list()
	if(!can_use(user))
		return cells
	var/list/connected = list()
	var/list/queue = list(list("place" = get_turf(user), "path" = list(get_turf(user)), "nodes" = list()))
	while(length(queue))
		var/list/branch = queue[1]
		queue.Cut(1, 2)
		var/list/previous_nodes = branch["nodes"]
		for(var/obj/structure/heretic_glass_prism/prism as anything in prisms)
			if(prism in connected || (source_prism && !length(previous_nodes) && prism != source_prism))
				continue
			if(!line_clear(branch["place"], prism, allow_prisms = TRUE))
				continue
			connected += prism
			var/list/path = branch["path"]
			path = path.Copy()
			var/list/nodes = previous_nodes.Copy()
			for(var/turf/tile as anything in get_line(branch["place"], get_turf(prism)))
				path += tile
				var/obj/structure/heretic_glass_prism/link = locate() in tile
				if(link)
					nodes += list(prism_snapshot(link))
			queue += list(list("place" = get_turf(prism), "path" = path, "nodes" = nodes))
			if(get_turf(prism) == aimed_turf)
				continue
			var/list/beam_cells = trace_ray(get_turf(prism), aimed_turf ? get_dir(prism, aimed_turf) : prism.dir, prism, aimed_turf)
			for(var/list/cell as anything in beam_cells)
				cell["path"] = path + cell["path"]
				cell["nodes"] = nodes + cell["nodes"]
			cells += beam_cells
	return cells

/datum/eldritch_knowledge/base_glass/proc/valid_prism_turf(mob/living/user, turf/place)
	return !prism_placement_failure(user, place)

/datum/eldritch_knowledge/base_glass/proc/prism_placement_failure(mob/living/user, turf/place)
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	if(!isopenturf(place) || isspaceturf(place) || istype(place, /turf/open/lava))
		return "Выберите клетку открытого пола; космос, стены и лава не подходят."
	if(length(prisms) >= (ascension_active ? 5 : 3))
		return "Достигнут предел призм: [ascension_active ? 5 : 3]. Уберите одну или дождитесь её исчезновения."
	if(!ray_tile_open(place, FALSE))
		return "Клетка занята плотным предметом или призмой. Выберите свободную клетку."
	for(var/mob/living/occupant in place)
		return "На выбранной клетке стоит живое существо. Выберите свободную клетку."
	if(!line_clear(user, place, allow_prisms = TRUE))
		return "До клетки нужна свободная линия не длиннее пяти клеток."
	return null

/datum/eldritch_knowledge/base_glass/proc/shards(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	if(!can_use(user) || QDELETED(required))
		return FALSE
	if(istype(target, /obj/structure/heretic_glass_prism))
		var/obj/structure/heretic_glass_prism/prism = target
		if(prism.glass_ref?.resolve() != src || !line_clear(user, prism, allow_prisms = TRUE))
			return FALSE
		prism.face_user(user)
		return TRUE
	if(!isturf(target) || !valid_prism_turf(user, target) || !spend_combat_resource())
		return FALSE
	var/obj/structure/heretic_glass_prism/prism = new(target, src)
	prism.face_user(user)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/valid_barrier_turf(mob/living/user, turf/place)
	if(!can_use(user) || !isopenturf(place) || isspaceturf(place) || istype(place, /turf/open/lava) || !line_clear(user, place) || length(barriers) >= HERETIC_GLASS_BARRIER_LIMIT)
		return FALSE
	for(var/mob/living/occupant in place)
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/create_barrier(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	if(QDELETED(required) || !valid_barrier_turf(user, place) || !spend_combat_resource())
		return null
	var/obj/structure/heretic_glass_barrier/barrier = new(place, src)
	update_temper()
	playsound(place, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 45, TRUE)
	return barrier

/datum/eldritch_knowledge/base_glass/proc/radial_cells(mob/living/user)
	var/list/cells = list()
	if(!can_use(user))
		return cells
	for(var/direction in GLOB.alldirs)
		cells += trace_ray(get_turf(user), direction)
	return cells

/datum/eldritch_knowledge/base_glass/proc/storm(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	if(!can_use(user) || QDELETED(required) || length(attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		return FALSE
	var/list/cells = radial_cells(user) + relay_cells(user) + pane_cells(user)
	if(!length(cells))
		return FALSE
	new /datum/heretic_glass_attack(src, cells, 1 SECONDS, required, bonus_damage = 10, blind_time = HERETIC_GLASS_STORM_BLIND)
	user.visible_message(span_danger("[user] соединяет пальцы. Вокруг вспыхивают расходящиеся лучи!"))
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/crown(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/final_eldritch/glass_final/required = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	if(!can_use(user) || !ascension_active || !required?.finished || required.applied_body != user || active_network || length(attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		return FALSE
	if(!length(radial_cells(user)) && !length(relay_cells(user)))
		return FALSE
	active_network = new(src, required)
	return TRUE

/// Незрячие от квирка или повязки сами по себе не в счёт, как сон и добровольный отдых.
/datum/eldritch_knowledge/base_glass/proc/casket_ready(mob/living/victim)
	if(heretic_capture_downed(victim) || fractured_by_me(victim))
		return TRUE
	var/source = glass_blind_source()
	if(HAS_TRAIT_FROM(victim, TRAIT_BLIND, source))
		return TRUE
	return victim.eye_blind && victim.stat == CONSCIOUS && !HAS_TRAIT(victim, TRAIT_BLIND)

/datum/eldritch_knowledge/base_glass/proc/casket_block_reason(mob/living/user, atom/target, check_cost = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_GLASS_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(locate(/obj/structure/heretic_glass_casket) in victim.loc)
		return "Цель уже заперта в стекле."
	if(!isturf(victim.loc) || victim.z != user.z || !line_clear(user, victim, HERETIC_GLASS_CASKET_RANGE, pass_tables = TRUE))
		return "Цель должна стоять на полу не дальше трёх клеток по открытой линии; столы линию не закрывают."
	if(!casket_ready(victim))
		return "Витраж смыкается только вокруг сбитой с ног, обессиленной, ослеплённой вспышкой или покрытой вашими трещинами цели. Сон, добровольный отдых и слепота от природы или под повязкой сами по себе не делают цель доступной."
	if(check_cost && combat_resource < HERETIC_GLASS_CASKET_COST)
		return "Для Витража нужно [HERETIC_GLASS_CASKET_COST] грани."
	return null

/datum/eldritch_knowledge/base_glass/proc/casket(mob/living/user, mob/living/victim)
	glass_failure = casket_block_reason(user, victim)
	if(glass_failure || !spend_combat_resource(HERETIC_GLASS_CASKET_COST))
		return FALSE
	var/turf/place = get_turf(victim)
	var/obj/effect/temp_visual/heretic_glass/casket_growth/growth = new(place, src, HERETIC_GLASS_CASKET_GROWTH_LIFETIME)
	addtimer(CALLBACK(src, PROC_REF(seal_casket), user, victim, place, growth, glass_generation), HERETIC_GLASS_CASKET_TELEGRAPH)
	user.visible_message(span_danger("Вокруг [victim] из воздуха нарастают цветные стеклянные плитки!"), span_notice("Витраж нарастает вокруг [victim]."))
	playsound(place, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 50, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/seal_casket(mob/living/user, mob/living/victim, turf/place, obj/effect/growth, generation)
	qdel(growth)
	if(QDELETED(src) || generation != glass_generation || QDELETED(user))
		return FALSE
	if(QDELETED(victim) || victim.loc != place)
		to_chat(user, span_warning("Цель ушла из-под стекла, и Витраж рассыпался."))
		return FALSE
	var/reason = casket_block_reason(user, victim, check_cost = FALSE)
	if(reason)
		to_chat(user, span_warning("Витраж рассыпался: [reason]"))
		return FALSE
	new /obj/structure/heretic_glass_casket(place, src, victim)
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/passage_exit(mob/living/user, obj/structure/window/pane)
	var/turf/origin = get_turf(user)
	var/turf/pane_turf = get_turf(pane)
	if(!origin || !pane_turf || origin.z != pane_turf.z)
		return null
	if(pane.fulltile)
		var/direction = get_dir(origin, pane_turf)
		return (get_dist(origin, pane_turf) == 1 && (direction in GLOB.cardinals)) ? get_step(pane_turf, direction) : null
	if(origin == pane_turf)
		return get_step(pane_turf, pane.dir)
	return get_step(pane_turf, pane.dir) == origin ? pane_turf : null

/datum/eldritch_knowledge/base_glass/proc/passage_failure(mob/living/user, obj/structure/window/pane)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/glass_passage)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	if(!istype(pane) || QDELETED(pane) || pane.obj_integrity <= 0 || !isturf(pane.loc))
		return "Укажите целое окно."
	if(!(pane in attuned_panes))
		return "Сквозь стекло ведёт только ваше настроенное окно: сначала коснитесь его Хваткой."
	var/turf/exit = passage_exit(user, pane)
	if(!exit)
		return "Встаньте вплотную к окну: к полноклеточному - сбоку, не по диагонали, к направленному - по одну из его сторон."
	if(exit.is_blocked_turf(FALSE, null, list(pane)))
		return "За окном стена или плотный предмет: выйти некуда."
	if(combat_resource < 1)
		return "Для шага сквозь стекло нужна 1 грань."
	return null

/datum/eldritch_knowledge/base_glass/proc/passage_ready(mob/living/user, obj/structure/window/pane)
	return !passage_failure(user, pane)

/datum/eldritch_knowledge/base_glass/proc/step_through(mob/living/user, obj/structure/pane)
	glass_failure = passage_failure(user, pane)
	if(glass_failure)
		return FALSE
	var/obj/structure/window/window = pane
	user.visible_message(span_warning("[user] прижимается к [window], и стекло подаётся, как вода."), span_notice("Стекло принимает вас."))
	new /obj/effect/temp_visual/heretic_glass/grasp(get_turf(window), src)
	playsound(window, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 40, TRUE)
	if(!do_after(user, HERETIC_GLASS_PASSAGE_TIME, target = window, extra_checks = CALLBACK(src, PROC_REF(passage_ready), user, window)))
		glass_failure = passage_failure(user, window) || "Шаг прерван: секунду стойте у окна неподвижно."
		return FALSE
	glass_failure = passage_failure(user, window)
	if(glass_failure || !spend_combat_resource())
		return FALSE
	var/turf/origin = get_turf(user)
	var/turf/exit = passage_exit(user, window)
	if(!do_teleport(user, exit, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != exit)
		gain_combat_resource()
		glass_failure = "Стекло не пропустило: здесь что-то мешает переходу."
		return FALSE
	window.AddComponent(/datum/component/heretic_glass_passage_trace)
	new /obj/effect/temp_visual/heretic_glass/burst(exit, src)
	log_game("[key_name(user)] проходит сквозь окно [window] из [AREACOORD(origin)] в [AREACOORD(exit)].")
	return TRUE

/datum/heretic_glass_attack
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/datum/weakref/body_ref
	var/datum/weakref/network_ref
	var/network_id
	var/turf/origin
	var/list/cells
	var/list/obj/effect/temp_visual/heretic_glass/warnings = list()
	var/list/obj/effect/temp_visual/heretic_glass/beam/beams
	var/generation
	var/release_timer
	var/stationary
	var/resolved = FALSE
	var/damage_bonus = 0
	var/blind_duration = 0

/datum/heretic_glass_attack/New(datum/eldritch_knowledge/base_glass/glass, list/beam_cells, delay, datum/eldritch_knowledge/required, must_stay = FALSE, datum/heretic_glass_network/network, bonus_damage = 0, blind_time = 0)
	. = ..()
	glass_ref = WEAKREF(glass)
	knowledge_ref = WEAKREF(required)
	body_ref = WEAKREF(glass.glass_body)
	origin = get_turf(glass.glass_body)
	cells = beam_cells
	generation = glass.glass_generation
	stationary = must_stay
	damage_bonus = bonus_damage
	blind_duration = blind_time
	if(network)
		network_ref = WEAKREF(network)
		network_id = REF(network)
	glass.attacks += src
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_source_deleted))
	if(stationary)
		RegisterSignal(glass.glass_body, COMSIG_MOVABLE_MOVED, PROC_REF(on_source_deleted))
	var/list/warned = list()
	for(var/list/cell as anything in cells)
		var/turf/tile = cell["tile"]
		if(tile in warned)
			continue
		warned += tile
		warnings += new /obj/effect/temp_visual/heretic_glass/warning(tile, glass, delay)
	playsound(origin, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 40, FALSE)
	release_timer = addtimer(CALLBACK(src, PROC_REF(resolve)), delay, TIMER_STOPPABLE)
	if(network)
		show_charge(glass, delay)

/// Витраж копит свет: будущие лучи проступают тонкими линиями, свет стягивается к герою.
/datum/heretic_glass_attack/proc/show_charge(datum/eldritch_knowledge/base_glass/glass, delay)
	beams = list()
	for(var/list/segment as anything in beam_segments())
		var/obj/effect/temp_visual/heretic_glass/beam/beam = new(segment[1], glass, delay + HERETIC_GLASS_BEAM_FIRE_TIME + HERETIC_GLASS_BEAM_FADE)
		beam.start_node = segment[3]
		beam.end_node = segment[4]
		beam.charge(segment[2], delay)
		beams += beam
	heretic_vfx_gather(origin, HERETIC_GLASS_INK, HERETIC_GLASS_GATHER_RADIUS, delay)

/// Прямые отрезки лучей: от начала пути через каждую призму до последней клетки ветви.
/datum/heretic_glass_attack/proc/beam_segments()
	var/list/segments = list()
	var/cell_count = length(cells)
	for(var/index in 1 to cell_count)
		var/list/cell = cells[index]
		var/list/path = cell["path"]
		if(index < cell_count)
			var/list/next_cell = cells[index + 1]
			var/list/next_path = next_cell["path"]
			if(length(next_path) == length(path) + 1 && next_path[length(path)] == cell["tile"])
				continue
		var/list/node_refs = list()
		for(var/list/snapshot as anything in cell["nodes"])
			node_refs[snapshot["turf"]] = snapshot["ref"]
		var/list/corners = list(path[1])
		for(var/turf/tile as anything in path)
			if(node_refs[tile] && tile != corners[length(corners)])
				corners += tile
		if(corners[length(corners)] != cell["tile"])
			corners += cell["tile"]
		for(var/corner in 2 to length(corners))
			add_segment(segments, corners[corner - 1], corners[corner], node_refs)
	return segments

/// Отрезок, лежащий на уже найденном луче из той же точки, только удлиняет его.
/datum/heretic_glass_attack/proc/add_segment(list/segments, turf/start, turf/finish, list/node_refs)
	var/delta_x = finish.x - start.x
	var/delta_y = finish.y - start.y
	if(!delta_x && !delta_y)
		return
	for(var/list/segment as anything in segments)
		if(segment[1] != start)
			continue
		var/turf/other = segment[2]
		var/other_x = other.x - start.x
		var/other_y = other.y - start.y
		if(delta_x * other_y != delta_y * other_x || delta_x * other_x + delta_y * other_y <= 0)
			continue
		if(abs(delta_x) + abs(delta_y) > abs(other_x) + abs(other_y))
			segment[2] = finish
			segment[4] = node_refs[finish]
		return
	segments += list(list(start, finish, node_refs[start], node_refs[finish]))

/// Залп: линии вспыхивают во всю ширину, свет бьёт от места призыва, первый залп сотрясает пол. Линии оборванных маршрутов гаснут.
/datum/heretic_glass_attack/proc/fire_beams(list/lit_tiles)
	for(var/obj/effect/temp_visual/heretic_glass/beam/beam as anything in beams)
		if(QDELETED(beam))
			continue
		var/datum/weakref/start_node = beam.start_node
		var/datum/weakref/end_node = beam.end_node
		if((start_node && !start_node.resolve()) || (end_node ? !end_node.resolve() : !(beam.end_tile in lit_tiles)))
			beam.fizzle()
		else
			beam.fire()
	beams = null
	heretic_vfx_flash(origin, HERETIC_GLASS_PRISM_WHITE, HERETIC_GLASS_VOLLEY_FLASH_RANGE, HERETIC_GLASS_VOLLEY_FLASH_POWER, HERETIC_GLASS_VOLLEY_FLASH_TIME)
	var/datum/heretic_glass_network/network = network_ref?.resolve()
	if(network?.pulses == 1)
		heretic_vfx_quake(origin, HERETIC_GLASS_VOLLEY_QUAKE_RADIUS, HERETIC_GLASS_VOLLEY_QUAKE, HERETIC_GLASS_VOLLEY_QUAKE_TIME)

/datum/heretic_glass_attack/proc/on_source_deleted(datum/source)
	SIGNAL_HANDLER
	var/datum/heretic_glass_network/network = network_ref?.resolve()
	if(network)
		qdel(network)
	qdel(src)

/datum/heretic_glass_attack/proc/resolve()
	if(QDELETED(src) || resolved)
		return FALSE
	resolved = TRUE
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/mob/living/user = body_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!glass?.can_use(user) || glass.glass_generation != generation || !required || heretic.get_knowledge(required.type) != required || (stationary && get_turf(user) != origin) || (network_ref && !network_ref.resolve()) || (!network_ref && !glass.line_clear(user, origin, allow_prisms = TRUE)))
		qdel(src)
		return FALSE
	QDEL_LIST(warnings)
	var/eternal = !isnull(network_ref)
	var/list/mob/living/hit_damage = list()
	var/list/mob/living/blinded = list()
	var/list/rendered = list()
	var/list/refracted_targets = list()
	for(var/list/cell as anything in cells)
		if(!glass.route_valid(cell))
			continue
		var/list/nodes = cell["nodes"]
		if(network_ref && !length(nodes) && !glass.line_clear(user, origin, allow_prisms = TRUE))
			continue
		if(network_ref && length(nodes))
			var/list/source_snapshot = nodes[1]
			var/datum/weakref/source_ref = source_snapshot["ref"]
			if(!glass.line_clear(user, source_ref.resolve(), allow_prisms = TRUE))
				continue
		var/turf/tile = cell["tile"]
		if(!(tile in rendered))
			rendered += tile
			var/obj/effect/temp_visual/heretic_glass/shard/visual = new(tile, glass)
			visual.setDir(cell["dir"])
		for(var/mob/living/victim in tile)
			var/damage = (cell["split"] ? HERETIC_GLASS_SPLIT_DAMAGE : HERETIC_GLASS_BEAM_DAMAGE) + damage_bonus
			if(length(nodes))
				damage += HERETIC_GLASS_REFRACTION_BONUS
				refracted_targets |= victim
			var/blind_time = blind_duration
			if(glass.fractured_by_me(victim))
				if(eternal)
					damage += HERETIC_GLASS_ETERNAL_FRACTURE_BONUS
				else
					blind_time = max(blind_duration, HERETIC_GLASS_FRACTURE_BLIND)
			if(blind_time)
				blinded[victim] = max(blinded[victim] || 0, blind_time)
			hit_damage[victim] = max(hit_damage[victim], damage)
	for(var/mob/living/victim as anything in hit_damage)
		if(!heretic_can_affect(user, victim))
			continue
		var/damage_before = victim.getBruteLoss()
		victim.adjustBruteLoss(hit_damage[victim])
		if((victim in refracted_targets) && victim.getBruteLoss() > damage_before)
			heretic.advance_combat_deed(victim, PATH_GLASS)
		if(blinded[victim])
			glass.blind(victim, blinded[victim])
		log_combat(user, victim, "поражает преломлённым лучом")
		if(beams)
			heretic_vfx_burst(victim, /particles/heretic_ascension/glass)
	if(beams)
		fire_beams(rendered)
	playsound(origin, stationary || network_ref ? 'modular_bluemoon/sound/heretic/glass_storm.ogg' : 'modular_bluemoon/sound/heretic/glass_release.ogg', 55, TRUE)
	qdel(src)
	return TRUE

/datum/heretic_glass_attack/Destroy()
	deltimer(release_timer)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.attacks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	var/mob/living/user = body_ref?.resolve()
	if(stationary && user)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	QDEL_LIST(warnings)
	for(var/obj/effect/temp_visual/heretic_glass/beam/beam as anything in beams)
		if(!QDELETED(beam))
			beam.fizzle()
	beams = null
	cells = null
	origin = null
	glass_ref = null
	knowledge_ref = null
	body_ref = null
	network_ref = null
	return ..()

/datum/heretic_glass_network
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/list/watched_nodes = list()
	var/pulse_timer
	var/pulses = 0
	var/generation

/datum/heretic_glass_network/New(datum/eldritch_knowledge/base_glass/glass, datum/eldritch_knowledge/required)
	. = ..()
	glass_ref = WEAKREF(glass)
	knowledge_ref = WEAKREF(required)
	generation = glass.glass_generation
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	pulse()

/datum/heretic_glass_network/proc/watch_node(obj/structure/heretic_glass_prism/prism)
	if(QDELETED(prism) || watched_nodes[REF(prism)])
		return
	watched_nodes[REF(prism)] = WEAKREF(prism)
	RegisterSignal(prism, COMSIG_PARENT_QDELETING, PROC_REF(on_node_deleted))

/datum/heretic_glass_network/proc/on_node_deleted(datum/source)
	SIGNAL_HANDLER
	watched_nodes.Remove(REF(source))
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)

/datum/heretic_glass_network/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/heretic_glass_network/proc/pulse()
	if(QDELETED(src) || pulses >= 3)
		return FALSE
	deltimer(pulse_timer)
	pulse_timer = null
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/mob/living/user = glass?.glass_body
	if(!glass?.can_use(user) || !glass.ascension_active || glass.glass_generation != generation || !required)
		qdel(src)
		return FALSE
	var/list/cells = glass.radial_cells(user) + glass.relay_cells(user)
	if(!length(cells) || length(glass.attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		qdel(src)
		return FALSE
	for(var/list/cell as anything in cells)
		var/list/nodes = cell["nodes"]
		for(var/list/snapshot as anything in nodes)
			var/datum/weakref/prism_ref = snapshot["ref"]
			watch_node(prism_ref.resolve())
	new /datum/heretic_glass_attack(glass, cells, 1 SECONDS, required, FALSE, src, 14)
	for(var/prism_id in watched_nodes)
		var/datum/weakref/prism_ref = watched_nodes[prism_id]
		var/obj/structure/heretic_glass_prism/prism = prism_ref.resolve()
		if(prism)
			new /obj/effect/temp_visual/heretic_glass/storm(get_turf(prism), glass)
	pulses++
	if(pulses < 3)
		pulse_timer = addtimer(CALLBACK(src, PROC_REF(pulse)), 4 SECONDS, TIMER_STOPPABLE)
	else
		pulse_timer = addtimer(CALLBACK(src, PROC_REF(expire)), 3 SECONDS, TIMER_STOPPABLE)
	return TRUE

/datum/heretic_glass_network/proc/expire()
	qdel(src)

/datum/heretic_glass_network/Destroy()
	deltimer(pulse_timer)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass)
		if(glass.active_network == src)
			glass.active_network = null
		for(var/datum/heretic_glass_attack/attack as anything in glass.attacks.Copy())
			if(attack.network_id == REF(src))
				qdel(attack)
	for(var/prism_id in watched_nodes)
		var/datum/weakref/prism_ref = watched_nodes[prism_id]
		var/obj/structure/heretic_glass_prism/prism = prism_ref.resolve()
		if(prism)
			UnregisterSignal(prism, COMSIG_PARENT_QDELETING)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	watched_nodes.Cut()
	glass_ref = null
	knowledge_ref = null
	return ..()

/datum/status_effect/heretic_glass_fracture
	id = "heretic_glass_fracture"
	duration = 12 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_glass_fracture
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/glass_ref
	var/mutable_appearance/fracture_overlay

/datum/status_effect/heretic_glass_fracture/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_glass/glass)
	if(QDELETED(glass))
		qdel(src)
		return
	glass_ref = WEAKREF(glass)
	fracture_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_glass_effects.dmi', "glass_mark", BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/heretic_glass_fracture/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass || owner.stat == DEAD || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))
		return FALSE
	glass.fractures += src
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_fracture))
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_glass_fracture/proc/update_fracture(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += fracture_overlay

/datum/status_effect/heretic_glass_fracture/on_remove()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.fractures.Remove(src)
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_icon()
	return ..()

/datum/status_effect/heretic_glass_fracture/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_glass_fracture/Destroy()
	. = ..()
	QDEL_NULL(fracture_overlay)
	glass_ref = null
	return .

/atom/movable/screen/alert/status_effect/heretic_glass_fracture
	name = "Стеклянные трещины"
	desc = "Любой луч заклинателя ослепит вас на 2 секунды, а волна Вечного витража вместо этого ранит сильнее; стеклянный саркофаг может сомкнуться вокруг вас. Трещины исчезают через 12 секунд после последней хватки или взрыва метки."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "glass_fracture"

/datum/status_effect/eldritch/glass
	id = "glass_mark"
	mark_name = "Метка Стекла"
	mark_alert_state = "sigil_glass"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	effect_sprite = "glass_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/glass_release.ogg'
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref

/datum/status_effect/eldritch/glass/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_glass/glass)
	if(glass)
		glass_ref = WEAKREF(glass)
	return ..()

/datum/status_effect/eldritch/glass/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass.glass_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/glass_mark)
	if(QDELETED(required))
		return FALSE
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	glass.marks += src
	return TRUE

/datum/status_effect/eldritch/glass/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/eldritch/glass/on_remove()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.marks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	return ..()

/datum/status_effect/eldritch/glass/on_effect()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass?.can_use(glass.glass_body) && heretic_can_affect(glass.glass_body, owner, chargecost = 0))
		owner.adjustBruteLoss(8)
		glass.fracture(owner)
		glass.blind(owner, HERETIC_GLASS_MARK_BLIND)
		new /obj/effect/temp_visual/heretic_glass/burst(get_turf(owner), glass)
	return ..()

/obj/structure/heretic_glass_prism
	name = "refracting prism"
	desc = "Стеклянный узел на тонкой оправе. При выстреле создателя в цель связанные призмы целятся в выбранную клетку; выстрел в призму запускает общий залп по стрелкам. Связь требует свободной линии до соседнего узла в пяти клетках. Создатель касанием руки переключает один луч или два. В раздвоенном режиме при выстреле в цель один луч идёт точно в выбранную клетку, второй отходит на 45°; при выстреле в призму оба луча расходятся от стрелки на 45°. Прочность 75; призму можно разбить или разрушить нулевым жезлом."
	icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	icon_state = "glass_prism"
	density = TRUE
	anchored = TRUE
	max_integrity = 75
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/split = FALSE
	var/expires_at

/obj/structure/heretic_glass_prism/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass)
	. = ..()
	if(QDELETED(glass))
		return INITIALIZE_HINT_QDEL
	glass_ref = WEAKREF(glass)
	glass.prisms += src
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass.glass_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	if(QDELETED(required))
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	expires_at = world.time + HERETIC_GLASS_PRISM_LIFETIME
	START_PROCESSING(SSobj, src)

/obj/structure/heretic_glass_prism/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_glass_prism/proc/face_user(mob/living/user)
	setDir(user.dir & NORTH ? NORTH : user.dir & SOUTH ? SOUTH : user.dir)
	playsound(src, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 30, TRUE)

/obj/structure/heretic_glass_prism/proc/output_directions(facing = dir)
	return split ? list(turn(facing, 45), turn(facing, -45)) : list(facing)

/obj/structure/heretic_glass_prism/proc/toggle_split()
	split = !split
	icon_state = split ? "glass_prism_split" : "glass_prism"

/obj/structure/heretic_glass_prism/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass?.can_use(user) || !user.Adjacent(src))
		return ..()
	toggle_split()
	to_chat(user, span_eldritch("[src] теперь [split ? "расщепляет луч надвое" : "поворачивает луч по стрелке"]."))
	playsound(src, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 35, TRUE)

/obj/structure/heretic_glass_prism/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_glass_prism/process()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass || QDELETED(glass.glass_body) || glass.glass_body.stat == DEAD || world.time >= expires_at)
		qdel(src)
		return PROCESS_KILL

/obj/structure/heretic_glass_prism/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.prisms.Remove(src)
	glass?.notify_resource_changed()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	glass_ref = null
	knowledge_ref = null
	return ..()

/proc/heretic_glass_reflectable(obj/item/projectile/projectile)
	return is_energy_reflectable_projectile(projectile) && !istype(projectile, /obj/item/projectile/bullet)

/proc/heretic_glass_reflect(atom/source, obj/item/projectile/projectile, datum/eldritch_knowledge/base_glass/glass)
	projectile.setAngle(projectile.Angle + 180)
	projectile.ignore_source_check = TRUE
	projectile.homing = FALSE
	if(projectile.homing_target && projectile.homing_target != projectile.firer && projectile.homing_target != projectile.fired_from && projectile.homing_target != projectile.original)
		projectile.UnregisterSignal(projectile.homing_target, COMSIG_PARENT_QDELETING)
	projectile.homing_target = null
	projectile.range = max(0, min(projectile.range, projectile.decayedRange) - projectile.reflect_range_decrease)
	projectile.decayedRange = projectile.range
	new /obj/effect/temp_visual/heretic_glass/burst(get_turf(source), glass)
	playsound(source, 'modular_bluemoon/sound/heretic/glass_release.ogg', 55, TRUE)
	source.visible_message(span_warning("[source] вспыхивает и отражает [projectile]!"))

/obj/structure/heretic_glass_barrier
	name = "refracted pane"
	desc = "Острое стекло застыло поперёк прохода. Оно задерживает всех, включая создателя, но пропускает его стеклянные лучи. Первые два отражаемых энергетических выстрела возвращаются по обратной траектории, повреждая стекло. Пули не отражаются. Разбейте преграду или коснитесь её нулевым жезлом. Создатель может убрать её рукой."
	icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	icon_state = "glass_barrier"
	anchored = TRUE
	density = TRUE
	opacity = FALSE
	max_integrity = 45
	var/reflections_left = HERETIC_GLASS_BARRIER_REFLECTIONS
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/expires_at

/obj/structure/heretic_glass_barrier/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass)
	. = ..()
	if(QDELETED(glass))
		return INITIALIZE_HINT_QDEL
	glass_ref = WEAKREF(glass)
	glass.barriers += src
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass.glass_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	if(!required)
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	expires_at = world.time + HERETIC_GLASS_BARRIER_LIFETIME
	START_PROCESSING(SSobj, src)

/obj/structure/heretic_glass_barrier/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_glass_barrier/examine(mob/user)
	. = ..()
	. += span_notice("Осталось отражений: [reflections_left].")

/obj/structure/heretic_glass_barrier/bullet_act(obj/item/projectile/projectile)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!reflections_left || !glass || QDELETED(glass.glass_body) || glass.glass_body.stat == DEAD || world.time >= expires_at || !heretic_glass_reflectable(projectile))
		return ..()
	reflections_left--
	heretic_glass_reflect(src, projectile, glass)
	take_damage(max(HERETIC_GLASS_REFLECTION_WEAR, projectile.damage), BRUTE, sound_effect = FALSE)
	return BULLET_ACT_FORCE_PIERCE

/obj/structure/heretic_glass_barrier/process()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass || QDELETED(glass.glass_body) || glass.glass_body.stat == DEAD || world.time >= expires_at)
		qdel(src)
		return PROCESS_KILL

/obj/structure/heretic_glass_barrier/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass?.can_use(user) && user.Adjacent(src))
		playsound(src, 'modular_bluemoon/sound/heretic/glass_release.ogg', 40, TRUE)
		qdel(src)
		return
	return ..()

/obj/structure/heretic_glass_barrier/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_glass_barrier/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.barriers.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	glass_ref = null
	knowledge_ref = null
	return ..()

/obj/structure/heretic_glass_casket
	name = "stained glass casket"
	desc = "Цветные стеклянные плитки сомкнулись вокруг человека: внутри не шевельнуться, снаружи не утащить, клетку не пройти. Лазеры и энергия отражаются от стекла, а удары в ближнем бою и брошенные предметы бьют его в полтора раза сильнее. Прочность 90; нулевой жезл рассеивает витраж сразу, а «Помощью» по стеклу запертого можно растолкать за 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	icon_state = "glass_barrier"
	anchored = TRUE
	density = TRUE
	opacity = FALSE
	layer = ABOVE_MOB_LAYER
	max_integrity = HERETIC_GLASS_CASKET_INTEGRITY
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/mob/living/victim
	var/victim_was_anchored = FALSE
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/expires_at
	var/expire_timer

/obj/structure/heretic_glass_casket/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass, mob/living/held)
	. = ..()
	if(QDELETED(glass) || QDELETED(held))
		return INITIALIZE_HINT_QDEL
	glass_ref = WEAKREF(glass)
	glass.caskets += src
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass.glass_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	if(QDELETED(required))
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	expires_at = world.time + HERETIC_GLASS_CASKET_DURATION
	hold(held)
	expire_timer = addtimer(CALLBACK(src, PROC_REF(expire)), HERETIC_GLASS_CASKET_DURATION, TIMER_STOPPABLE)
	log_combat(glass.glass_body, held, "запирает в стеклянный саркофаг")

/obj/structure/heretic_glass_casket/proc/hold(mob/living/held)
	victim = held
	victim_was_anchored = held.anchored
	held.pulledby?.stop_pulling()
	held.stop_pulling()
	held.buckled?.unbuckle_mob(held, TRUE)
	held.set_anchored(TRUE)
	// Свой экземпляр не продлевает и не снимает чужой паралич.
	restraint = new(list(held, HERETIC_GLASS_CASKET_DURATION, TRUE))
	RegisterSignal(held, COMSIG_MOVABLE_MOVED, PROC_REF(on_victim_moved))
	RegisterSignals(held, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN), PROC_REF(on_victim_lost))
	heretic_capture_hold(held, HERETIC_GLASS_CAPTURE)

/obj/structure/heretic_glass_casket/proc/release()
	var/mob/living/held = victim
	if(!held)
		return
	victim = null
	UnregisterSignal(held, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	heretic_capture_unhold(held, HERETIC_GLASS_CAPTURE)
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && restraint.duration <= expires_at)
		qdel(restraint)
	restraint = null
	if(QDELETED(held))
		return
	held.set_anchored(victim_was_anchored)
	heretic_capture_release(held, HERETIC_GLASS_CAPTURE)

/obj/structure/heretic_glass_casket/proc/on_victim_moved(datum/source)
	SIGNAL_HANDLER
	if(victim?.loc != loc)
		qdel(src)

/obj/structure/heretic_glass_casket/proc/on_victim_lost(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_glass_casket/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_glass_casket/proc/expire()
	qdel(src)

/obj/structure/heretic_glass_casket/examine(mob/user)
	. = ..()
	if(victim)
		. += span_warning("Внутри застыл [victim].")
	if(expires_at)
		. += span_notice("Стекло рассыплется через [CEILING(max(0, expires_at - world.time) / (1 SECONDS), 1)] с.")

/obj/structure/heretic_glass_casket/bullet_act(obj/item/projectile/projectile)
	if(!heretic_glass_reflectable(projectile))
		return ..()
	heretic_glass_reflect(src, projectile, glass_ref?.resolve())
	return BULLET_ACT_FORCE_PIERCE

/obj/structure/heretic_glass_casket/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir, armour_penetration = 0)
	. = ..()
	if(damage_flag == MELEE)
		. *= HERETIC_GLASS_CASKET_MELEE_MULTIPLIER

/// Запертого не достать кликом по телу: «Помощь» по саркофагу расталкивает его сквозь стекло.
/obj/structure/heretic_glass_casket/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(act_intent != INTENT_HELP || !victim || !isliving(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user) || !user.Adjacent(victim))
		return ..()
	heretic_capture_shake(user, victim)

/obj/structure/heretic_glass_casket/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/nullrod))
		user.visible_message(span_warning("[user] касается [src] нулевым жезлом, и витраж осыпается цветной пылью."))
		qdel(src)
		return STOP_ATTACK_PROC_CHAIN
	if(istype(item, /obj/item/living_heart) && victim && IS_HERETIC(user))
		item.melee_attack_chain(user, victim, params)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/structure/heretic_glass_casket/Destroy()
	deltimer(expire_timer)
	if(isturf(loc))
		new /obj/effect/temp_visual/heretic_glass/burst(loc)
		playsound(loc, 'modular_bluemoon/sound/heretic/glass_release.ogg', 50, TRUE)
	release()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.caskets -= src
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	glass_ref = null
	knowledge_ref = null
	return ..()

/obj/effect/temp_visual/heretic_glass/casket_growth
	icon_state = "glass_barrier"
	alpha = 0

/obj/effect/temp_visual/heretic_glass/casket_growth/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass, lifetime)
	. = ..()
	transform = matrix() * HERETIC_GLASS_CASKET_GROWTH_SCALE
	animate(src, alpha = HERETIC_GLASS_CASKET_GROWTH_ALPHA, transform = matrix(), time = HERETIC_GLASS_CASKET_TELEGRAPH, easing = QUAD_EASING | EASE_IN)

/datum/component/heretic_glass_passage_trace
	dupe_mode = COMPONENT_DUPE_HIGHLANDER
	var/mutable_appearance/crack
	var/fade_timer

/datum/component/heretic_glass_passage_trace/Initialize()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	var/atom/pane = parent
	crack = mutable_appearance('modular_bluemoon/icons/effects/heretic_vfx.dmi', "glass_crack")
	pane.add_overlay(crack)
	RegisterSignal(pane, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	fade_timer = addtimer(CALLBACK(src, PROC_REF(fade)), HERETIC_GLASS_PASSAGE_TRACE, TIMER_STOPPABLE)

/datum/component/heretic_glass_passage_trace/proc/fade()
	qdel(src)

/datum/component/heretic_glass_passage_trace/proc/on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("По стеклу тянется свежая трещина, хотя само окно цело.")

/datum/component/heretic_glass_passage_trace/Destroy(force, silent)
	deltimer(fade_timer)
	var/atom/pane = parent
	pane?.cut_overlay(crack)
	crack = null
	return ..()

/obj/item/melee/sickly_blade/glass
	name = "refracted blade"
	desc = "Полупрозрачный клинок с лезвием, расколотым на десятки острых граней. В каждой из них отражается свой оттенок пустого неба."
	icon = 'modular_bluemoon/icons/obj/heretic_glass.dmi'
	icon_state = "glass_blade"
	item_state = "glass_blade"
	route = PATH_GLASS
	mark_type = /datum/status_effect/eldritch/glass

/obj/item/heretic_path_relic/glass
	name = "widow's prism"
	desc = "Ручная линза в потемневшей оправе. Примените её в руке и выберите одно из настроенных стёкол: до 20 секунд вы смотрите его глазами, а собственное тело не видит окружения. Движение, любой урон (и по выносливости), оглушение, беспамятство, выпавшая из рук линза или снятая со стекла настройка обрывают взгляд. Перезарядка 20 секунд после взгляда."
	icon = 'modular_bluemoon/icons/obj/heretic_glass.dmi'
	icon_state = "glass_relic"
	var/mob/living/gazer
	var/atom/gaze_pane
	var/datum/component/heretic_craft/gaze_craft
	var/gaze_health
	var/gaze_stamina
	var/gaze_timer

/obj/item/heretic_path_relic/glass/attack_self(mob/living/user)
	var/list/choices = gaze_choices(user)
	if(!length(choices))
		to_chat(user, span_warning("Нет настроенного стекла, сквозь которое можно смотреть."))
		return FALSE
	var/choice = tgui_input_list(user, "Сквозь какое стекло смотреть?", name, choices)
	if(!choice || !choices[choice])
		return FALSE
	return gaze(user, choices[choice])

/// Подписи «Отдел: имя» для выбора стекла; одноимённые стёкла в отделе нумеруются.
/obj/item/heretic_path_relic/glass/proc/gaze_choices(mob/living/user)
	var/list/choices = list()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!glass || !authorized(user))
		return choices
	for(var/obj/structure/pane as anything in glass.attuned_panes)
		if(!glass.pane_usable(pane))
			continue
		var/base_label = "[get_area_name(pane, TRUE)]: [pane.name]"
		var/label = base_label
		var/copy = 1
		while(choices[label])
			copy++
			label = "[base_label] ([copy])"
		choices[label] = pane
	return choices

/obj/item/heretic_path_relic/glass/proc/gaze(mob/living/user, atom/pane)
	if(gazer || !authorized(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/component/heretic_craft/craft = heretic_craft_on(pane, HERETIC_GLASS_PANE_CRAFT)
	if(!glass?.can_use(user) || !(pane in glass.attuned_panes) || !glass.pane_usable(pane) || !craft)
		return FALSE
	gazer = user
	gaze_pane = pane
	gaze_craft = craft
	gaze_health = user.health
	gaze_stamina = user.getStaminaLoss()
	RegisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(on_gaze_broken))
	RegisterSignal(user, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_gazer_health))
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_gazer_damaged))
	RegisterSignal(user, COMSIG_MOB_STATCHANGE, PROC_REF(on_gazer_stat))
	RegisterSignal(user, list(COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_UNCONSCIOUS, COMSIG_LIVING_STATUS_SLEEP), PROC_REF(on_gazer_disabled))
	RegisterSignal(src, COMSIG_ITEM_DROPPED, PROC_REF(on_gaze_broken))
	RegisterSignal(craft, COMSIG_PARENT_QDELETING, PROC_REF(on_gaze_broken))
	user.reset_perspective(pane)
	gaze_timer = addtimer(CALLBACK(src, PROC_REF(end_gaze)), HERETIC_GLASS_GAZE_DURATION, TIMER_STOPPABLE)
	to_chat(user, span_eldritch("Вы смотрите сквозь [pane]: [get_area_name(pane, TRUE)]. Движение, урон или оглушение вернут взгляд в тело."))
	log_game("[key_name(user)] смотрит сквозь настроенное стекло [pane] в [AREACOORD(pane)].")
	return TRUE

/obj/item/heretic_path_relic/glass/proc/on_gaze_broken(datum/source)
	SIGNAL_HANDLER
	end_gaze()

/obj/item/heretic_path_relic/glass/proc/on_gazer_health(mob/living/source)
	SIGNAL_HANDLER
	if(source.health < gaze_health || source.getStaminaLoss() > gaze_stamina || source.incapacitated() || source.stat != CONSCIOUS)
		end_gaze()
		return
	gaze_health = source.health
	gaze_stamina = source.getStaminaLoss()

/obj/item/heretic_path_relic/glass/proc/on_gazer_damaged(mob/living/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		end_gaze()

/obj/item/heretic_path_relic/glass/proc/on_gazer_stat(mob/living/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat != CONSCIOUS)
		end_gaze()

/obj/item/heretic_path_relic/glass/proc/on_gazer_disabled(mob/living/source, amount)
	SIGNAL_HANDLER
	if(amount > 0)
		end_gaze()

/obj/item/heretic_path_relic/glass/proc/end_gaze()
	if(!gazer)
		return
	deltimer(gaze_timer)
	gaze_timer = null
	var/mob/living/viewer = gazer
	UnregisterSignal(viewer, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_CARBON_UPDATEHEALTH, COMSIG_MOB_APPLY_DAMAGE, COMSIG_MOB_STATCHANGE, COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_UNCONSCIOUS, COMSIG_LIVING_STATUS_SLEEP))
	UnregisterSignal(src, COMSIG_ITEM_DROPPED)
	if(gaze_craft)
		UnregisterSignal(gaze_craft, COMSIG_PARENT_QDELETING)
	gazer = null
	gaze_pane = null
	gaze_craft = null
	COOLDOWN_START(src, relic_cooldown, HERETIC_GLASS_GAZE_COOLDOWN)
	if(QDELETED(viewer))
		return
	viewer.reset_perspective(null)
	to_chat(viewer, span_notice("Взгляд возвращается в ваше тело."))

/obj/item/heretic_path_relic/glass/Destroy()
	end_gaze()
	return ..()

/obj/effect/temp_visual/heretic_glass
	icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	icon_state = "glass_shard"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	var/datum/weakref/glass_ref

/obj/effect/temp_visual/heretic_glass/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass, lifetime)
	if(!QDELETED(glass))
		glass_ref = WEAKREF(glass)
		glass.visuals += src
	if(!isnull(lifetime))
		duration = lifetime
	return ..()

/obj/effect/temp_visual/heretic_glass/Destroy()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.visuals.Remove(src)
	glass_ref = null
	return ..()

/obj/effect/temp_visual/heretic_glass/grasp
	icon_state = "glass_grasp"

/obj/effect/temp_visual/heretic_glass/shard

/obj/effect/temp_visual/heretic_glass/burst
	icon_state = "glass_burst"

/obj/effect/temp_visual/heretic_glass/warning
	icon_state = "glass_warning"
	duration = 2 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_glass/storm
	icon_state = "glass_storm"
	duration = 1.5 SECONDS

/// Вспышка грани в точке преломления.
/obj/effect/temp_visual/heretic_glass/facet
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "glass_facet"
	duration = HERETIC_GLASS_FACET_TIME

/obj/effect/temp_visual/heretic_glass/facet/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass, lifetime)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))

/// Отрезок луча от центра клетки: спрайт растягивается вдоль, до залпа тонкой линией копит свет, в залп вспыхивает во всю ширину.
/obj/effect/temp_visual/heretic_glass/beam
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "glass_beam"
	appearance_flags = NONE
	alpha = 0
	var/angle = 0
	var/length = 0
	var/fired = FALSE
	var/fizzled = FALSE
	var/turf/end_tile
	var/datum/weakref/start_node
	var/datum/weakref/end_node

/obj/effect/temp_visual/heretic_glass/beam/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass, lifetime)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))

/obj/effect/temp_visual/heretic_glass/beam/Destroy()
	end_tile = null
	start_node = null
	end_node = null
	return ..()

/obj/effect/temp_visual/heretic_glass/beam/proc/line_matrix(width, share = 1)
	var/matrix/line = matrix()
	line.Scale(width, length * share / world.icon_size)
	line.Translate(0, length * share / 2)
	line.Turn(angle)
	return line

/obj/effect/temp_visual/heretic_glass/beam/proc/charge(turf/target, delay)
	end_tile = target
	var/delta_x = (target.x - x) * world.icon_size
	var/delta_y = (target.y - y) * world.icon_size
	length = sqrt(delta_x * delta_x + delta_y * delta_y)
	angle = Get_Angle(src, target)
	transform = line_matrix(HERETIC_GLASS_BEAM_WARN_WIDTH)
	animate(src, alpha = HERETIC_GLASS_BEAM_WARN_ALPHA, time = delay * HERETIC_GLASS_BEAM_WARN_RISE, easing = SINE_EASING | EASE_OUT)
	animate(alpha = HERETIC_GLASS_BEAM_CHARGED_ALPHA, transform = line_matrix(HERETIC_GLASS_BEAM_CHARGED_WIDTH), time = delay * (1 - HERETIC_GLASS_BEAM_WARN_RISE), easing = QUAD_EASING | EASE_IN)

/obj/effect/temp_visual/heretic_glass/beam/proc/fire()
	if(fired || fizzled)
		return
	fired = TRUE
	deltimer(timerid)
	timerid = QDEL_IN_STOPPABLE(src, HERETIC_GLASS_BEAM_FIRE_TIME + HERETIC_GLASS_BEAM_FADE)
	animate(src, alpha = 255, transform = line_matrix(HERETIC_GLASS_BEAM_FIRE_WIDTH), time = HERETIC_GLASS_BEAM_FIRE_TIME, easing = CUBIC_EASING | EASE_OUT)
	animate(alpha = 0, transform = line_matrix(HERETIC_GLASS_BEAM_FADE_WIDTH), time = HERETIC_GLASS_BEAM_FADE, easing = SINE_EASING | EASE_IN)

/// Несостоявшийся луч гаснет, не вспыхнув.
/obj/effect/temp_visual/heretic_glass/beam/proc/fizzle()
	if(fired || fizzled)
		return
	fizzled = TRUE
	deltimer(timerid)
	timerid = QDEL_IN_STOPPABLE(src, HERETIC_GLASS_BEAM_FADE)
	animate(src, alpha = 0, time = HERETIC_GLASS_BEAM_FADE, easing = SINE_EASING | EASE_IN)

/// Короткий след отражённого луча: вырастает из точки по курсу и тает.
/obj/effect/temp_visual/heretic_glass/beam/proc/streak(streak_angle, streak_length)
	fired = TRUE
	angle = streak_angle
	length = streak_length
	alpha = 255
	transform = line_matrix(HERETIC_GLASS_STREAK_WIDTH, HERETIC_GLASS_STREAK_START)
	animate(src, transform = line_matrix(HERETIC_GLASS_STREAK_WIDTH), time = HERETIC_GLASS_STREAK_GROW, easing = CUBIC_EASING | EASE_OUT)
	animate(alpha = 0, time = HERETIC_GLASS_STREAK_FADE, easing = SINE_EASING | EASE_IN)

/datum/eldritch_knowledge/base_glass/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !(istype(target, /obj/structure/window) || istype(target, /obj/structure/mirror)))
		return FALSE
	return attune(target, user)

/datum/eldritch_knowledge/glass_grasp
	name = "Стеклянная ладонь"
	summary = "Хватка оставляет на враге трещины на 12 секунд."
	details = list(
		"Ваш луч ослепляет треснувшую цель на 2 секунды без прибавки урона; Вечный витраж не слепит, а бьёт на 14 сильнее.",
		"Треснувшую цель Витраж запирает, даже если она стоит на ногах.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "На ладони проступили линии. Каждая разделяла мир на две неравные части."
	cost = 1
	route = PATH_GLASS

/datum/eldritch_knowledge/glass_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!proximity_flag || !glass?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	glass.fracture(target)
	return TRUE

/datum/eldritch_knowledge/spell/glass_shards
	name = "Оправа для света"
	summary = "Ставит призмы, которые стреляют вместе с вами, и прозрачные преграды от лазеров."
	details = list(
		"За грань ставит призму в 5 клетках: 75 прочности, живёт 2 минуты, одновременно до 3.",
		"Призмы на свободной линии до 5 клеток стреляют в вашу цель и добавляют лучу 6 ушибов.",
		"Выстрел в свою призму пускает залп по её стрелкам - так бьют из-за угла.",
		"Повторный выбор поворачивает стрелку, касание рукой переключает один луч или два.",
		"В намерении разоружения за грань встаёт преграда: 12 секунд, 45 прочности, до двух, перезарядка 8 секунд.",
		"Преграда держит всех, пропускает ваши лучи и возвращает до 2 лазеров; пули не отражает.",
		"Нулевой жезл сразу разрушает призму и преграду.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Я поднял осколок. Разрез на пальце появился раньше, чем я коснулся края."
	cost = 1
	route = PATH_GLASS
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_glass/shards

/datum/eldritch_knowledge/spell/glass_shards/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/glass_mark
	name = "Метка Стекла"
	summary = "Хватка ставит метку на 15 секунд, удар стеклянным клинком её взрывает."
	details = list(
		"Взрыв наносит 8 ушибов и ослепляет на 1 секунду.",
		"Цель получает трещины на 12 секунд: лучи её ослепляют, Витраж запирает даже стоящую.",
		"Взрыв по живому врагу возвращает одну грань.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Трещина обогнула сердце и замкнулась. Стекло ждало первого удара."
	cost = 2
	route = PATH_GLASS

/datum/eldritch_knowledge/glass_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!proximity_flag || !glass?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/glass, glass)
	return TRUE

/datum/eldritch_knowledge/glass_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		QDEL_LIST(glass.marks)

/datum/eldritch_knowledge/spell/glass_casket
	name = "Витраж"
	summary = "За 2 грани запирает поверженную цель в стеклянный саркофаг на 10 секунд."
	details = list(
		"Цель в 3 клетках по открытой линии; столы и операционный стол линию не закрывают.",
		"Годится сбитая с ног, обессиленная, ослеплённая вспышкой или треснувшая цель; сон, отдых и повязка - нет.",
		"Стекло нарастает секунду: если цель сошла с клетки, Витраж рассыпается.",
		"Цель неподвижна; сердце начинает обряд сквозь стекло, а у вашего стекла уводит её в изнанку на 3 с удержания.",
		"Прочность 90: лазеры отражаются, удары и броски бьют в полтора раза сильнее.",
		"После выхода цель минуту невосприимчива к Витражу и 15 секунд - к любому захвату еретиков.",
		"Антимагия, нулевой жезл и 2 секунды растолкать спасают от саркофага. Перезарядка 45 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Свет лёг на неё цветными плитками, и каждая плитка держала крепче цепи."
	cost = 2
	route = PATH_GLASS
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_glass/casket

/datum/eldritch_knowledge/spell/glass_casket/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/glass_relic
	name = "Вдовья призма"
	summary = "Линза из листа стекла и слитка серебра: 20 секунд смотрите глазами настроенного стекла."
	details = list(
		"Примените линзу в руке и выберите стекло по названию отдела.",
		"Пока вы смотрите, своё тело не видит окружения.",
		"Взгляд рвут движение, любой урон, оглушение, выпавшая линза или снятая настройка.",
		"Перезарядка 20 секунд; линзу можно отнять, одновременно только одна.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Вдова держала призму перед свечой. На стене горели три огня, и ни один не грел."
	cost = 1
	route = PATH_GLASS
	required_atoms = list(/obj/item/stack/sheet/glass, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/glass)

/datum/eldritch_knowledge/glass_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/glass_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/glass)

/datum/eldritch_knowledge/glass_passage
	name = "Сквозь стекло"
	summary = "За грань проходите сквозь своё настроенное окно на клетку по ту сторону."
	details = list(
		"Встаньте вплотную: к полноклеточному окну сбоку, к направленному - по одну из сторон.",
		"Секунду стойте неподвижно, затем выходите; окно остаётся целым.",
		"Чужое или ненастроенное окно не пускает, как и стена или плотный предмет за ним.",
		"Наручники и щит разума закрывают проход. Перезарядка 2 секунды.",
		"30 секунд на окне видна свежая трещина.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Стекло не разбилось. Оно просто вспомнило, что я всегда был по ту сторону."
	cost = 1
	route = PATH_GLASS
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_glass/passage

/datum/eldritch_knowledge/glass_passage/on_body_gain(mob/living/user)
	grant_combat_power(user)

/datum/eldritch_knowledge/glass_passage/on_body_lose(mob/living/user)
	remove_combat_power()

/datum/eldritch_knowledge/glass_temper
	name = "Закалка"
	summary = "Запас граней растёт до 5, прочность преград - до 60."
	details = list(
		"Новая вместимость не заполняет запас: грани набираются как обычно.",
		"Уже стоящие преграды получают новую прочность, полученный урон сохраняется.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Огонь не расплавил стекло. Он выжег из него право гнуться."
	cost = 2
	route = PATH_GLASS
	passive_values = list(5, 6, 7)
	passive_desc = "Вместимость составляет 5 / 6 / 7 граней, прочность преград — 60 / 75 / 90. Вознесение даёт вместимость 8. Улучшение не заполняет запас, не чинит прежний урон и не восстанавливает отражения."
	var/datum/weakref/glass_ref

/datum/eldritch_knowledge/glass_temper/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		glass_ref = WEAKREF(glass)
	on_passive_upgrade(user)

/datum/eldritch_knowledge/glass_temper/on_passive_upgrade(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.update_temper()

/datum/eldritch_knowledge/glass_temper/on_lose(mob/user)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.update_temper(ignore_temper = TRUE)
	return ..()

/datum/eldritch_knowledge/glass_temper/Destroy()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.update_temper(ignore_temper = TRUE)
	glass_ref = null
	return ..()

/datum/eldritch_knowledge/spell/glass_storm
	name = "Перекрёстный свет"
	summary = "Восемь лучей вокруг вас, залп сети призм и свет из настроенных стёкол рядом."
	details = list(
		"Стёкла в 7 клетках бьют в вашу сторону, призмы - по стрелкам.",
		"Секунду клетки подсвечены, двигаться можно.",
		"Урон 40 напрямую, 46 через призму, 40 после раздвоения; пересечения бьют один раз.",
		"Все поражённые слепнут на 3 секунды.",
		"Призмы и грани не нужны. Перезарядка 35 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Свет ударил в грань и распался на восемь лезвий. Каждое смотрело туда, куда смотрел я."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_GLASS
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_glass/storm

/datum/eldritch_knowledge/spell/glass_storm/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/final_eldritch/glass_final
	parallax_scene = ANTAG_SCENE_HERETIC_GLASS
	name = "Расколоть небосвод"
	summary = "Тело становится витражом, лучи бьют дальше, открывается Вечный витраж."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; обряд длится 30 секунд.",
		"До 5 призм, запас 8 граней, грань возвращается каждые 2 секунды.",
		"Луч преломляется до 5 раз и проходит 18 клеток вместо 3 и 12.",
		"35% лазеров и энергетических лучей отлетают от вас назад веером.",
		"Вечный витраж: 3 волны через 4 секунды, урон 44, через призму 50, трещины +14 без слепоты, перезарядка 45 секунд.",
		"Цена: пули не преломляются, удары оружием в ближнем бою бьют на четверть сильнее.",
		"Разбитая призма гасит только идущие через неё лучи.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Небо раскололось без звука. Осколки остановились передо мной, ожидая, какую форму я придам пустоте."
	route = PATH_GLASS
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_glass/crown)
	var/datum/weakref/glass_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/glass_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		glass_knowledge_ref = WEAKREF(glass)
		glass.ascension_active = TRUE
		glass.update_temper()
	user.AddComponent(/datum/component/heretic_glass_stained)

/datum/eldritch_knowledge/final_eldritch/glass_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_glass_stained))
	var/datum/eldritch_knowledge/base_glass/glass = glass_knowledge_ref?.resolve()
	glass_knowledge_ref = null
	if(glass)
		glass.ascension_active = FALSE
		glass.clear_glass()
		glass.update_temper()
	return ..()

/// Витраж вознесения: часть энергетических лучей преломляется, а удары оружием бьют сильнее.
/datum/component/heretic_glass_stained
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/refract_chance = HERETIC_GLASS_REFRACT_CHANCE
	var/melee_fragility = HERETIC_GLASS_MELEE_FRAGILITY
	var/crack_armed_at = -1
	var/crack_brute_before = 0
	var/datum/weakref/crack_attacker
	COOLDOWN_DECLARE(refract_flash)
	COOLDOWN_DECLARE(crack_flash)

/datum/component/heretic_glass_stained/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/heretic_glass_stained/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_RUN_BLOCK, PROC_REF(refract))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_health_changed))

/datum/component/heretic_glass_stained/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_PARENT_EXAMINE, COMSIG_CARBON_UPDATEHEALTH))

/datum/component/heretic_glass_stained/proc/refract(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	var/obj/item/projectile/projectile = heretic_try_deflect(source, real_attack, object, attack_type, refract_chance, list(ENERGY, LASER))
	if(!projectile)
		return BLOCK_NONE
	. = BLOCK_SUCCESS | BLOCK_REDIRECTED
	playsound(source, 'sound/effects/Glasshit.ogg', 40, TRUE)
	source.visible_message(span_warning("[projectile] преломляется в стеклянном теле [source] и отлетает назад!"), span_notice("Витраж преломляет [projectile]."))
	show_refraction(source, projectile)

/// Грань вспыхивает в точке попадания, отражённый луч чертит короткий след по новому курсу.
/datum/component/heretic_glass_stained/proc/show_refraction(mob/living/source, obj/item/projectile/projectile)
	var/turf/place = get_turf(source)
	var/angle = projectile.Angle
	var/offset_x = round(sin(angle) * HERETIC_GLASS_FACET_OFFSET)
	var/offset_y = round(cos(angle) * HERETIC_GLASS_FACET_OFFSET)
	var/obj/effect/temp_visual/heretic_glass/facet/facet = new(place)
	facet.pixel_x += offset_x
	facet.pixel_y += offset_y
	var/obj/effect/temp_visual/heretic_glass/beam/trace = new(place, null, HERETIC_GLASS_STREAK_GROW + HERETIC_GLASS_STREAK_FADE)
	trace.pixel_x += offset_x
	trace.pixel_y += offset_y
	trace.streak(angle, HERETIC_GLASS_STREAK_LENGTH)
	heretic_vfx_spray(place, /particles/heretic_ascension/glass, angle, HERETIC_GLASS_FACET_OFFSET)
	if(!COOLDOWN_FINISHED(src, refract_flash))
		return
	COOLDOWN_START(src, refract_flash, HERETIC_GLASS_FLASH_COOLDOWN)
	heretic_vfx_flash(place, HERETIC_GLASS_PRISM_WHITE, HERETIC_GLASS_FLASH_RANGE, HERETIC_GLASS_FLASH_POWER, HERETIC_GLASS_FLASH_TIME)

/// Надбавка к множителю урона от удара предметом; союзники еретика бьют без неё.
/datum/component/heretic_glass_stained/proc/melee_bonus(obj/item/weapon, mob/living/attacker)
	var/mob/living/owner = parent
	if(!weapon || weapon.damtype != BRUTE || owner.stat == DEAD)
		return 0
	if(attacker && (attacker == owner || IS_HERETIC(attacker) || IS_HERETIC_MONSTER(attacker)))
		return 0
	crack_armed_at = world.time
	crack_brute_before = owner.getBruteLoss()
	crack_attacker = WEAKREF(attacker)
	return melee_fragility

/// Трещины проступают, только если хрупкий удар в этот тик действительно ранил.
/datum/component/heretic_glass_stained/proc/on_health_changed(mob/living/carbon/source)
	SIGNAL_HANDLER
	if(crack_armed_at != world.time || source.getBruteLoss() <= crack_brute_before)
		return
	crack_armed_at = -1
	show_fragility(crack_attacker?.resolve())

/// Удар проступает на витраже трещинами, осколки летят дальше по ходу удара.
/datum/component/heretic_glass_stained/proc/show_fragility(mob/living/attacker)
	var/mob/living/owner = parent
	if(!isturf(owner.loc) || !COOLDOWN_FINISHED(src, crack_flash))
		return
	COOLDOWN_START(src, crack_flash, HERETIC_GLASS_CRACK_COOLDOWN)
	var/obj/effect/abstract/heretic_vfx_attached/cracks = heretic_vfx_attach(owner, 'modular_bluemoon/icons/effects/heretic_vfx.dmi', "glass_crack", 255, 0, upright = FALSE)
	cracks?.fade_out(HERETIC_GLASS_CRACK_TIME)
	var/angle = attacker && get_turf(attacker) != owner.loc ? Get_Angle(attacker, owner) : rand(0, 359)
	heretic_vfx_spray(owner, /particles/heretic_ascension/glass, angle, HERETIC_GLASS_FACET_OFFSET / 2)
	heretic_vfx_pulse(owner, HERETIC_GLASS_PRISM_WHITE, 1, HERETIC_GLASS_CRACK_TIME)

/datum/component/heretic_glass_stained/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Кожа отливает витражом: часть лазеров и энергетических лучей преломляется, но пули проходят, а удары оружием колют это тело как стекло.")

/mob/living/carbon/human/check_weakness(obj/item/weapon, mob/living/attacker)
	. = ..()
	var/datum/component/heretic_glass_stained/stained = GetComponent(/datum/component/heretic_glass_stained)
	if(stained)
		. += stained.melee_bonus(weapon, attacker)

/obj/effect/proc_holder/spell/pointed/heretic_glass
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	range = HERETIC_GLASS_RANGE
	selection_type = "view"
	aim_assist = FALSE
	active_msg = "Укажите цель для стеклянных граней."
	deactive_msg = "Грани возвращаются в ладонь."

/obj/effect/proc_holder/spell/pointed/heretic_glass/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	return ..() && heretic_check(user, glass?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_glass/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	return heretic_check(user, glass?.can_use(user) && glass.line_clear(user, target), silent, "Проверьте свободный пол, запас граней и прямую видимость цели.")

/obj/effect/proc_holder/spell/pointed/heretic_glass/release
	name = "Преломлённый луч"
	desc = "Выберите цель или клетку в 5 клетках: через 0,6 секунды вы и связанные призмы выстрелите в неё. Бесплатно, перезарядка 6 секунд."
	summary = "Луч в цель или клетку через 0,6 секунды: 30 ушибов, призмы стреляют вместе."
	action_icon_state = "glass_release"
	charge_max = 6 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_glass/release/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/destination = get_turf(target)
	if(!heretic_check(user, glass?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	if(!heretic_check(user, destination && destination != get_turf(user) && destination.z == user.z && get_dist(user, destination) <= range, silent, "Выберите цель или клетку не дальше пяти клеток от вас. Грани для луча не нужны."))
		return FALSE
	return heretic_check(user, !isliving(target) || heretic_can_affect(user, target, chargecost = 0), silent, "Луч не заденет эту цель: она мертва или защищена от магии.", target = target)

/obj/effect/proc_holder/spell/pointed/heretic_glass/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!length(targets) || !glass?.release(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_glass/shards
	name = "Поставить призму"
	desc = "За грань ставит призму на свободный пол в 5 клетках, повторный выбор поворачивает её стрелку. В намерении разоружения вместо призмы встаёт преграда на 12 секунд."
	summary = "Призма за грань; в намерении разоружения - преграда от лазеров."
	action_icon_state = "glass_shards"
	charge_max = 2 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!glass?.can_use(user))
		return heretic_check(user, FALSE, silent, "Способность недоступна вашему пути или текущему телу.")
	if(user.a_intent == INTENT_DISARM)
		return can_target_barrier(glass, target, user, silent)
	if(istype(target, /obj/structure/heretic_glass_prism))
		var/obj/structure/heretic_glass_prism/prism = target
		if(!heretic_check(user, prism.glass_ref?.resolve() == glass, silent, "Поворачивать можно только собственную призму."))
			return FALSE
		return heretic_check(user, glass.line_clear(user, prism, allow_prisms = TRUE), silent, "До своей призмы нужна свободная линия не длиннее пяти клеток.")
	if(!heretic_check(user, isturf(target), silent, "Для новой призмы укажите саму клетку пола."))
		return FALSE
	var/reason = glass.prism_placement_failure(user, target)
	if(!heretic_check(user, !reason, silent, reason))
		return FALSE
	return heretic_check(user, glass.combat_resource >= 1, silent, "Для новой призмы нужна 1 грань. Дождитесь восстановления запаса; поворот своей призмы бесплатен.")

/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/proc/can_target_barrier(datum/eldritch_knowledge/base_glass/glass, atom/target, mob/user, silent)
	if(!heretic_check(user, COOLDOWN_FINISHED(glass, barrier_cooldown), silent, "Преграда восстанавливается: осталось [CEILING(COOLDOWN_TIMELEFT(glass, barrier_cooldown) / (1 SECONDS), 1)] с."))
		return FALSE
	if(!heretic_check(user, glass.combat_resource >= 1, silent, "Для преграды нужна 1 грань. Дождитесь восстановления запаса."))
		return FALSE
	if(!heretic_check(user, length(glass.barriers) < HERETIC_GLASS_BARRIER_LIMIT, silent, "Уже стоят две преграды. Уберите одну рукой или дождитесь, пока она исчезнет."))
		return FALSE
	return heretic_check(user, isturf(target) && glass.valid_barrier_turf(user, target), silent, "Укажите свободный пол без существ не дальше пяти клеток по прямой линии; космос и лава не подходят.")

/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!length(targets) || !glass)
		heretic_revert_cast(user)
		return
	if(user.a_intent != INTENT_DISARM)
		if(!glass.shards(user, targets[1]))
			heretic_revert_cast(user)
		return
	if(!isturf(targets[1]) || !glass.create_barrier(user, targets[1]))
		heretic_revert_cast(user)
		return
	COOLDOWN_START(glass, barrier_cooldown, HERETIC_GLASS_BARRIER_COOLDOWN)

/obj/effect/proc_holder/spell/pointed/heretic_glass/casket
	name = "Витраж"
	desc = "Заприте в стеклянный саркофаг сбитую, обессиленную, ослеплённую или треснувшую цель в 3 клетках. Стекло нарастает секунду и держит цель 10 секунд, перезарядка 45 секунд."
	summary = "Саркофаг на 10 секунд для поверженной цели в 3 клетках, 2 грани."
	action_icon_state = "glass_casket"
	range = HERETIC_GLASS_CASKET_RANGE
	charge_max = HERETIC_GLASS_CASKET_COOLDOWN

/obj/effect/proc_holder/spell/pointed/heretic_glass/casket/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!heretic_check(user, glass?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = glass.casket_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_glass/casket/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!length(targets) || !glass?.casket(user, targets[1]))
		heretic_revert_cast(user, glass?.glass_failure)

/obj/effect/proc_holder/spell/pointed/heretic_glass/passage
	name = "Сквозь стекло"
	desc = "Укажите своё настроенное окно вплотную к себе: через секунду за грань вы выйдете по ту сторону. Перезарядка 2 секунды."
	summary = "Шаг за грань сквозь своё настроенное окно вплотную к вам."
	action_icon_state = "glass_barrier"
	range = 1
	charge_max = HERETIC_GLASS_PASSAGE_COOLDOWN

/obj/effect/proc_holder/spell/pointed/heretic_glass/passage/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!heretic_check(user, glass?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = glass.passage_failure(user, target)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_glass/passage/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!length(targets) || !glass?.step_through(user, targets[1]))
		heretic_revert_cast(user, glass?.glass_failure)

/obj/effect/proc_holder/spell/self/heretic_glass
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_glass/storm
	name = "Перекрёстный свет"
	desc = "Через секунду бьют восемь лучей вокруг вас, ваши призмы и настроенные стёкла в 7 клетках; поражённые слепнут на 3 секунды. Двигаться можно, перезарядка 35 секунд."
	summary = "Лучи вокруг, залп призм и свет стёкол: 40 ушибов и слепота на 3 секунды."
	action_icon_state = "glass_storm"
	charge_max = 35 SECONDS

/obj/effect/proc_holder/spell/self/heretic_glass/storm/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!glass?.storm(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_glass/crown
	name = "Вечный витраж"
	desc = "Три волны: восемь лучей вокруг вас и свет из призм, каждая предупреждает за секунду. Урон 44 напрямую и 50 через призму, по вашим трещинам на 14 больше и без слепоты. Перезарядка 45 секунд."
	summary = "Три волны света вокруг вас через 4 секунды, 44 ушиба за луч."
	action_icon_state = "glass_ascend"
	charge_max = 45 SECONDS

/obj/effect/proc_holder/spell/self/heretic_glass/crown/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	return ..() && heretic_check(user, glass?.can_use(user) && glass.ascension_active, silent, "Сначала завершите вознесение этого пути.")

/obj/effect/proc_holder/spell/self/heretic_glass/crown/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!glass?.crown(user))
		heretic_revert_cast(user)

#undef HERETIC_GLASS_RANGE
#undef HERETIC_GLASS_BARRIER_LIFETIME
#undef HERETIC_GLASS_PRISM_LIFETIME
#undef HERETIC_GLASS_ATTACK_LIMIT
#undef HERETIC_GLASS_PANE_CRAFT
#undef HERETIC_GLASS_PANE_CLUE
#undef HERETIC_GLASS_PANE_ALPHA
#undef HERETIC_GLASS_CAPTURE
#undef HERETIC_GLASS_MARK_BLIND
#undef HERETIC_GLASS_STORM_BLIND
#undef HERETIC_GLASS_STORM_PANE_RANGE
#undef HERETIC_GLASS_BARRIER_COOLDOWN
#undef HERETIC_GLASS_CASKET_RANGE
#undef HERETIC_GLASS_CASKET_COST
#undef HERETIC_GLASS_CASKET_TELEGRAPH
#undef HERETIC_GLASS_CASKET_DURATION
#undef HERETIC_GLASS_CASKET_INTEGRITY
#undef HERETIC_GLASS_CASKET_MELEE_MULTIPLIER
#undef HERETIC_GLASS_CASKET_COOLDOWN
#undef HERETIC_GLASS_CASKET_GROWTH_LIFETIME
#undef HERETIC_GLASS_CASKET_GROWTH_SCALE
#undef HERETIC_GLASS_CASKET_GROWTH_ALPHA
#undef HERETIC_GLASS_GAZE_DURATION
#undef HERETIC_GLASS_GAZE_COOLDOWN
#undef HERETIC_GLASS_PASSAGE_TIME
#undef HERETIC_GLASS_PASSAGE_TRACE
#undef HERETIC_GLASS_PASSAGE_COOLDOWN
#undef HERETIC_GLASS_BEAM_DAMAGE
#undef HERETIC_GLASS_SPLIT_DAMAGE
#undef HERETIC_GLASS_REFRACTION_BONUS
#undef HERETIC_GLASS_BARRIER_REFLECTIONS
#undef HERETIC_GLASS_BARRIER_LIMIT
#undef HERETIC_GLASS_REFLECTION_WEAR
#undef HERETIC_GLASS_INK
#undef HERETIC_GLASS_PRISM_WHITE
#undef HERETIC_GLASS_FACET_OFFSET
#undef HERETIC_GLASS_FACET_TIME
#undef HERETIC_GLASS_STREAK_LENGTH
#undef HERETIC_GLASS_STREAK_WIDTH
#undef HERETIC_GLASS_STREAK_START
#undef HERETIC_GLASS_STREAK_GROW
#undef HERETIC_GLASS_STREAK_FADE
#undef HERETIC_GLASS_FLASH_COOLDOWN
#undef HERETIC_GLASS_FLASH_RANGE
#undef HERETIC_GLASS_FLASH_POWER
#undef HERETIC_GLASS_FLASH_TIME
#undef HERETIC_GLASS_CRACK_TIME
#undef HERETIC_GLASS_CRACK_COOLDOWN
#undef HERETIC_GLASS_BEAM_WARN_WIDTH
#undef HERETIC_GLASS_BEAM_WARN_ALPHA
#undef HERETIC_GLASS_BEAM_CHARGED_WIDTH
#undef HERETIC_GLASS_BEAM_CHARGED_ALPHA
#undef HERETIC_GLASS_BEAM_WARN_RISE
#undef HERETIC_GLASS_BEAM_FIRE_WIDTH
#undef HERETIC_GLASS_BEAM_FADE_WIDTH
#undef HERETIC_GLASS_BEAM_FIRE_TIME
#undef HERETIC_GLASS_BEAM_FADE
#undef HERETIC_GLASS_GATHER_RADIUS
#undef HERETIC_GLASS_VOLLEY_FLASH_RANGE
#undef HERETIC_GLASS_VOLLEY_FLASH_POWER
#undef HERETIC_GLASS_VOLLEY_FLASH_TIME
#undef HERETIC_GLASS_VOLLEY_QUAKE
#undef HERETIC_GLASS_VOLLEY_QUAKE_TIME
#undef HERETIC_GLASS_VOLLEY_QUAKE_RADIUS
