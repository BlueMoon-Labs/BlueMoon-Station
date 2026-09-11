#define HERETIC_ECHO_RANGE 5
#define HERETIC_ECHO_LINK_RANGE 7
#define HERETIC_ECHO_WARNING_TIME (0.8 SECONDS)
#define HERETIC_ECHO_RECOVERY_TIME (8 SECONDS)
#define HERETIC_ECHO_RELEASE_DAMAGE 24
#define HERETIC_ECHO_RELEASE_STAMINA 25
#define HERETIC_ECHO_REFRAIN_DAMAGE 18
#define HERETIC_ECHO_REFRAIN_STAMINA 15
#define HERETIC_ECHO_REPEAT_DAMAGE 22
#define HERETIC_ECHO_REPEAT_STAMINA 25
#define HERETIC_ECHO_HARVEST_TIME (6 SECONDS)
#define HERETIC_ECHO_RESONATOR_LIFETIME (30 SECONDS)
#define HERETIC_ECHO_RESONATOR_LIMIT 2
#define HERETIC_ECHO_ATTACK_LIMIT 4
#define HERETIC_ECHO_ASCENDED_CAPACITY 8
#define HERETIC_ECHO_CROSS 1
#define HERETIC_ECHO_DIAGONALS 2
#define HERETIC_ECHO_RING 3
#define HERETIC_ECHO_DEED_WHISPER_RANGE 5

/datum/heretic_path/echo
	id = PATH_ECHO
	deed_type = /datum/heretic_deed/echo
	name = "Эхо"
	desc = "Ударьте звуком и заставьте врага отступить перед повтором. Каждое попадание возвращает силу для нового залпа."
	strengths = "Быстрый первый удар, сильные повторы и давление на стрелков в проходах. Резонаторы расширяют охват."
	weaknesses = "Звон поражает прежние клетки: из них можно уйти. Преграды глушат волны, резонаторы можно разбить."
	knowledge = list(
		/datum/eldritch_knowledge/base_echo,
		/datum/eldritch_knowledge/echo_grasp,
		/datum/eldritch_knowledge/spell/echo_refrain,
		/datum/eldritch_knowledge/echo_mark,
		/datum/eldritch_knowledge/echo_fork,
		/datum/eldritch_knowledge/echo_upgrade,
		/datum/eldritch_knowledge/spell/echo_resonator,
		/datum/eldritch_knowledge/echo_sustain,
		/datum/eldritch_knowledge/spell/echo_crescendo,
		/datum/eldritch_knowledge/final_eldritch/echo_final,
	)

/datum/eldritch_knowledge/base_echo
	name = "Звук за закрытой дверью"
	desc = "Нож и металлический прут создают звенящий клинок. «Последний удар» отмечает крест вокруг вас и вскоре поражает оставшихся в нём врагов. Попадания клинком и волнами возвращают резонанс для следующих атак; пустой запас медленно восстанавливается. Стены гасят звук, а выход с отмеченного пола позволяет уклониться."
	gain_text = "За дверью спели последнюю ноту. Она прозвучала снова, когда я перестал слушать."
	route = PATH_ECHO
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/rods)
	result_atoms = list(/obj/item/melee/sickly_blade/echo)
	combat_resource = 2
	combat_resource_name = "Резонанс"
	combat_resource_desc = "Попадание клинком или волной даёт единицу раз в 6 секунд, хватка — две, взрыв метки — одну. Пустой запас восстанавливается до единицы за 8 секунд. Последний удар и резонатор стоят единицу; Припев бесплатен. Крещендо расходует весь запас. Смена тела сохраняет резонанс, но обрывает прежние волны."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_echo/release
	grasp_visual = /obj/effect/temp_visual/heretic_echo/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/echo_grasp.ogg'
	var/mob/living/echo_body
	var/list/datum/heretic_echo_attack/attacks = list()
	var/list/obj/structure/heretic_echo_resonator/resonators = list()
	var/list/datum/status_effect/eldritch/echo/marks = list()
	var/list/datum/status_effect/heretic_echo_ringing/ringing = list()
	var/echo_generation = 0
	var/diagonal_echo = FALSE
	var/ascension_active = FALSE
	COOLDOWN_DECLARE(grasp_harvest)
	COOLDOWN_DECLARE(ascended_resonance)

/datum/eldritch_knowledge/base_echo/on_body_gain(mob/living/user)
	if(!user?.mind || echo_body == user)
		return
	if(echo_body)
		on_body_lose(echo_body)
	echo_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_capacity()
	COOLDOWN_START(src, ascended_resonance, 8 SECONDS)

/datum/eldritch_knowledge/base_echo/on_body_lose(mob/living/user)
	if(echo_body)
		UnregisterSignal(echo_body, COMSIG_PARENT_QDELETING)
	echo_body = null
	ascension_active = FALSE
	diagonal_echo = FALSE
	remove_combat_power()
	clear_echo()
	notify_resource_changed()

/datum/eldritch_knowledge/base_echo/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(echo_body)

/datum/eldritch_knowledge/base_echo/on_death(mob/user)
	clear_echo()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_echo/Destroy()
	on_body_lose(echo_body)
	return ..()

/datum/eldritch_knowledge/base_echo/proc/clear_echo()
	echo_generation++
	QDEL_LIST(attacks)
	QDEL_LIST(resonators)
	QDEL_LIST(marks)
	QDEL_LIST(ringing)

/datum/eldritch_knowledge/base_echo/proc/clear_knowledge_effects(datum/eldritch_knowledge/knowledge)
	for(var/datum/heretic_echo_attack/attack as anything in attacks.Copy())
		if(attack.knowledge_ref?.resolve() == knowledge)
			qdel(attack)
	for(var/obj/structure/heretic_echo_resonator/resonator as anything in resonators.Copy())
		if(resonator.knowledge_ref?.resolve() == knowledge)
			qdel(resonator)

/datum/eldritch_knowledge/base_echo/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == echo_body && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_ECHO && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_echo/proc/update_capacity(ignore_sustain = FALSE, ignore_ascension = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(echo_body)
	var/datum/eldritch_knowledge/echo_sustain/sustain = heretic?.get_knowledge(/datum/eldritch_knowledge/echo_sustain)
	var/datum/eldritch_knowledge/final_eldritch/echo_final/final_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	if(ignore_sustain || QDELETED(sustain))
		sustain = null
	var/ascended_capacity = !ignore_ascension && !QDELETED(final_knowledge) && final_knowledge.finished && heretic.ascended
	combat_resource_max = ascended_capacity ? HERETIC_ECHO_ASCENDED_CAPACITY : sustain ? sustain.passive_values[sustain.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_echo/get_combat_resource_data()
	var/list/data = ..()
	data["description"] = "[combat_resource_desc] Рисунок: [diagonal_echo ? "диагонали" : "крест"]. Резонаторов: [length(resonators)] из [HERETIC_ECHO_RESONATOR_LIMIT]."
	return data

/datum/eldritch_knowledge/base_echo/proc/harvest(mob/living/user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, resource_harvest))
		return FALSE
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, HERETIC_ECHO_HARVEST_TIME)
	return TRUE

/datum/eldritch_knowledge/base_echo/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && isturf(target?.loc) && heretic_can_affect(user, target, chargecost = 0))
		harvest(user)

/datum/eldritch_knowledge/base_echo/on_mark_detonated(mob/living/user, mob/living/target)
	if(can_use(user) && isturf(target?.loc) && heretic_can_affect(user, target, chargecost = 0))
		gain_combat_resource()

/datum/eldritch_knowledge/base_echo/on_life(mob/user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, ascended_resonance))
		return
	if(ascension_active || combat_resource < 1)
		gain_combat_resource()
	COOLDOWN_START(src, ascended_resonance, HERETIC_ECHO_RECOVERY_TIME)

/datum/eldritch_knowledge/base_echo/proc/tile_open(turf/tile)
	return isopenturf(tile) && !tile.is_blocked_turf(exclude_mobs = TRUE)

/datum/eldritch_knowledge/base_echo/proc/line_clear(atom/start, atom/end, max_distance = HERETIC_ECHO_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > max_distance)
		return FALSE
	var/turf/previous
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!tile_open(tile))
			return FALSE
		if(previous && previous.x != tile.x && previous.y != tile.y)
			if(!tile_open(locate(previous.x, tile.y, tile.z)) || !tile_open(locate(tile.x, previous.y, tile.z)))
				return FALSE
		previous = tile
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/set_ringing(mob/living/victim)
	return victim.apply_status_effect(/datum/status_effect/heretic_echo_ringing, src)

/datum/eldritch_knowledge/base_echo/proc/pattern_turfs(turf/center, radius, shape)
	var/list/tiles = list()
	for(var/turf/tile in range(radius, center))
		var/offset_x = abs(tile.x - center.x)
		var/offset_y = abs(tile.y - center.y)
		if(shape == HERETIC_ECHO_CROSS && offset_x && offset_y)
			continue
		if(shape == HERETIC_ECHO_DIAGONALS && offset_x != offset_y)
			continue
		if(shape == HERETIC_ECHO_RING && max(offset_x, offset_y) != radius)
			continue
		if(line_clear(center, tile, radius))
			tiles += tile
	return tiles

/datum/eldritch_knowledge/base_echo/proc/make_pattern(turf/center, radius, shape, damage, stamina, relay = FALSE)
	var/list/zones = list()
	var/list/cells = pattern_turfs(center, radius, shape)
	if(length(cells))
		zones += list(list("center" = center, "cells" = cells, "radius" = radius, "damage" = damage, "stamina" = stamina))
	if(relay)
		for(var/obj/structure/heretic_echo_resonator/resonator as anything in resonators)
			if(!resonator.valid_source() || !line_clear(echo_body, resonator, HERETIC_ECHO_LINK_RANGE))
				continue
			var/turf/relay_center = get_turf(resonator)
			var/list/relay_cells = pattern_turfs(relay_center, 1, shape)
			if(length(relay_cells))
				zones += list(list("center" = relay_center, "cells" = relay_cells, "radius" = 1, "damage" = damage, "stamina" = stamina, "resonator" = WEAKREF(resonator)))
	return zones

/datum/eldritch_knowledge/base_echo/proc/start_attack(mob/living/user, list/patterns, datum/eldritch_knowledge/required, immediate_first = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !length(patterns) || QDELETED(required) || heretic.get_knowledge(required.type) != required || length(attacks) >= HERETIC_ECHO_ATTACK_LIMIT)
		return FALSE
	var/datum/heretic_echo_attack/attack = new(src, patterns, required)
	if(immediate_first)
		attack.resolve()
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/release(mob/living/user)
	if(!can_use(user) || combat_resource < 1 || length(attacks) >= HERETIC_ECHO_ATTACK_LIMIT || !tile_open(get_turf(user)))
		return FALSE
	var/list/pattern = make_pattern(get_turf(user), 2, diagonal_echo ? HERETIC_ECHO_DIAGONALS : HERETIC_ECHO_CROSS, HERETIC_ECHO_RELEASE_DAMAGE, HERETIC_ECHO_RELEASE_STAMINA, TRUE)
	if(!length(pattern) || !start_attack(user, list(pattern), src))
		return FALSE
	spend_combat_resource()
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/refrain(mob/living/user, turf/center)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_refrain)
	if(!can_use(user) || !line_clear(user, center))
		return FALSE
	var/list/opening = make_pattern(center, 0, HERETIC_ECHO_CROSS, HERETIC_ECHO_REFRAIN_DAMAGE, HERETIC_ECHO_REFRAIN_STAMINA)
	var/list/repeat = make_pattern(center, 1, diagonal_echo ? HERETIC_ECHO_DIAGONALS : HERETIC_ECHO_CROSS, HERETIC_ECHO_REPEAT_DAMAGE, HERETIC_ECHO_REPEAT_STAMINA, TRUE)
	return length(opening) && length(repeat) && start_attack(user, list(opening, repeat), required, immediate_first = TRUE)

/datum/eldritch_knowledge/base_echo/proc/create_resonator(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_resonator)
	if(!can_use(user) || !required || !line_clear(user, place) || isspaceturf(place) || istype(place, /turf/open/lava) || length(resonators) >= HERETIC_ECHO_RESONATOR_LIMIT)
		return FALSE
	for(var/obj/structure/heretic_echo_resonator/resonator as anything in resonators)
		if(get_turf(resonator) == place)
			return FALSE
	if(!spend_combat_resource())
		return FALSE
	new /obj/structure/heretic_echo_resonator(place, src, required)
	playsound(place, 'modular_bluemoon/sound/heretic/echo_cast.ogg', 45, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/crescendo(mob/living/user, turf/center)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_crescendo)
	if(!can_use(user) || !required || !line_clear(user, center) || combat_resource < 2)
		return FALSE
	var/resonance = combat_resource
	var/list/patterns = list()
	for(var/shape in list(HERETIC_ECHO_CROSS, HERETIC_ECHO_DIAGONALS, HERETIC_ECHO_RING))
		patterns += list(make_pattern(center, 2, shape, 18 + 2 * resonance, 18 + 2 * resonance))
	if(!start_attack(user, patterns, required))
		return FALSE
	spend_combat_resource(resonance)
	user.visible_message(span_danger("[user] взмахивает рукой, задавая такт. На полу расходятся линии звона!"))
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/final_chorus(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/final_eldritch/echo_final/required = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	if(!can_use(user) || !ascension_active || !required?.finished || required.applied_body != user || !tile_open(get_turf(user)))
		return FALSE
	var/list/patterns = list()
	for(var/radius in 1 to 3)
		patterns += list(make_pattern(get_turf(user), radius, HERETIC_ECHO_RING, 32, 35))
	if(!start_attack(user, patterns, required))
		return FALSE
	new /obj/effect/temp_visual/heretic_echo/ascend(get_turf(user))
	user.visible_message(span_userdanger("[user] поднимает ладони. Невидимый хор вступает голос за голосом!"))
	return TRUE

/// Все волны хранят прежние клетки; следующий такт заново показывает предупреждение.
/datum/heretic_echo_attack
	var/datum/weakref/echo_ref
	var/datum/weakref/knowledge_ref
	var/datum/weakref/body_ref
	var/turf/origin
	var/list/patterns
	var/list/obj/effect/temp_visual/heretic_echo/warnings = list()
	var/generation
	var/pulse_index = 1
	var/release_timer
	var/resolving = FALSE

/datum/heretic_echo_attack/New(datum/eldritch_knowledge/base_echo/echo, list/attack_patterns, datum/eldritch_knowledge/required)
	. = ..()
	echo_ref = WEAKREF(echo)
	knowledge_ref = WEAKREF(required)
	body_ref = WEAKREF(echo.echo_body)
	origin = get_turf(echo.echo_body)
	patterns = attack_patterns
	generation = echo.echo_generation
	echo.attacks += src
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_source_deleted))
	warn_pulse()

/datum/heretic_echo_attack/proc/on_source_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/heretic_echo_attack/proc/valid_source()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/mob/living/user = body_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && echo?.can_use(user) && echo.echo_generation == generation && !QDELETED(required) && heretic.get_knowledge(required.type) == required && echo.line_clear(user, origin, HERETIC_ECHO_LINK_RANGE)

/datum/heretic_echo_attack/proc/warn_pulse()
	if(!valid_source() || pulse_index > length(patterns))
		qdel(src)
		return FALSE
	var/list/warned = list()
	var/list/zones = patterns[pulse_index]
	for(var/list/zone as anything in zones)
		var/list/cells = zone["cells"]
		for(var/turf/tile as anything in cells)
			if(tile in warned)
				continue
			warned += tile
			var/obj/effect/temp_visual/heretic_echo/warning/visual = new(tile)
			visual.color = pulse_index == 2 ? "#fff1be" : pulse_index == 3 ? "#daac70" : COLOR_WHITE
			warnings += visual
	playsound(origin, 'modular_bluemoon/sound/heretic/echo_cast.ogg', 50, FALSE)
	release_timer = addtimer(CALLBACK(src, PROC_REF(resolve)), HERETIC_ECHO_WARNING_TIME, TIMER_STOPPABLE)
	return TRUE

/datum/heretic_echo_attack/proc/resolve()
	if(QDELETED(src) || resolving)
		return FALSE
	resolving = TRUE
	deltimer(release_timer)
	release_timer = null
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	var/mob/living/user = body_ref?.resolve()
	if(!valid_source())
		qdel(src)
		return FALSE
	QDEL_LIST(warnings)
	var/list/mob/living/hit_damage = list()
	var/list/mob/living/hit_stamina = list()
	var/list/mob/living/hit_tiles = list()
	var/list/rendered = list()
	var/list/zones = patterns[pulse_index]
	for(var/list/zone as anything in zones)
		var/turf/center = zone["center"]
		var/datum/weakref/node_ref = zone["resonator"]
		if(node_ref)
			var/obj/structure/heretic_echo_resonator/resonator = node_ref.resolve()
			if(!resonator?.valid_source() || resonator.echo_ref?.resolve() != echo || get_turf(resonator) != center || !echo.line_clear(origin, center, HERETIC_ECHO_LINK_RANGE))
				continue
		else if(!echo.line_clear(origin, center))
			continue
		if(!echo.line_clear(user, center, HERETIC_ECHO_LINK_RANGE))
			continue
		var/list/cells = zone["cells"]
		for(var/turf/tile as anything in cells)
			if(!echo.line_clear(center, tile, zone["radius"]))
				continue
			if(!(tile in rendered))
				rendered += tile
				new /obj/effect/temp_visual/heretic_echo/burst(tile)
			for(var/mob/living/victim in tile)
				if(victim.loc != tile)
					continue
				hit_damage[victim] = max(hit_damage[victim], zone["damage"])
				hit_stamina[victim] = max(hit_stamina[victim], zone["stamina"])
				hit_tiles[victim] = tile
	for(var/mob/living/victim as anything in hit_damage)
		var/can_affect = heretic_can_affect(user, victim)
		if(!valid_source())
			qdel(src)
			return FALSE
		if(!can_affect || QDELETED(victim) || victim.loc != hit_tiles[victim])
			continue
		var/damage_before = victim.getBruteLoss()
		victim.adjustBruteLoss(hit_damage[victim])
		if(!valid_source())
			qdel(src)
			return FALSE
		if(QDELETED(victim) || victim.loc != hit_tiles[victim])
			continue
		victim.adjustStaminaLoss(hit_stamina[victim])
		if(!valid_source())
			qdel(src)
			return FALSE
		if(QDELETED(victim) || victim.loc != hit_tiles[victim])
			continue
		echo.set_ringing(victim)
		if(!valid_source())
			qdel(src)
			return FALSE
		if(QDELETED(victim) || victim.loc != hit_tiles[victim])
			continue
		if(victim.getBruteLoss() > damage_before)
			echo.harvest(user)
		if(!valid_source())
			qdel(src)
			return FALSE
		log_combat(user, victim, "поражает отложенным звоном")
	playsound(origin, 'modular_bluemoon/sound/heretic/echo_burst.ogg', 60, TRUE)
	pulse_index++
	if(pulse_index > length(patterns))
		qdel(src)
	else
		resolving = FALSE
		warn_pulse()
	return TRUE

/datum/heretic_echo_attack/Destroy()
	deltimer(release_timer)
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	echo?.attacks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	QDEL_LIST(warnings)
	patterns = null
	origin = null
	echo_ref = null
	knowledge_ref = null
	body_ref = null
	return ..()

/obj/structure/heretic_echo_resonator
	name = "sepulchral resonator"
	desc = "Три латунные трубы поют чужими голосами. Повторяют слабым звоном Последний удар и Припев хозяина. Разбейте резонатор или коснитесь его нулевым жезлом, чтобы оборвать повтор."
	icon = 'modular_bluemoon/icons/obj/heretic_echo.dmi'
	icon_state = "echo_resonator"
	anchored = TRUE
	density = FALSE
	max_integrity = 35
	var/datum/weakref/echo_ref
	var/datum/weakref/knowledge_ref
	var/generation
	var/expiry_timer
	var/expires_at

/obj/structure/heretic_echo_resonator/Initialize(mapload, datum/eldritch_knowledge/base_echo/echo, datum/eldritch_knowledge/required)
	. = ..()
	if(QDELETED(echo) || QDELETED(required))
		return INITIALIZE_HINT_QDEL
	echo_ref = WEAKREF(echo)
	knowledge_ref = WEAKREF(required)
	generation = echo.echo_generation
	echo.resonators += src
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_source_deleted))
	expires_at = world.time + HERETIC_ECHO_RESONATOR_LIFETIME
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), HERETIC_ECHO_RESONATOR_LIFETIME, TIMER_STOPPABLE)
	echo.notify_resource_changed()

/obj/structure/heretic_echo_resonator/proc/valid_source()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(echo?.echo_body)
	return !QDELETED(src) && isturf(loc) && echo && required && echo.echo_generation == generation && heretic?.get_knowledge(required.type) == required && !heretic.role_removed && world.time < expires_at

/obj/structure/heretic_echo_resonator/proc/on_source_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_echo_resonator/proc/expire()
	qdel(src)

/obj/structure/heretic_echo_resonator/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_echo_resonator/attack_hand(mob/living/user)
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(echo?.can_use(user) && user.Adjacent(src))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_echo_resonator/Destroy()
	deltimer(expiry_timer)
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(echo)
		echo.resonators.Remove(src)
		echo.notify_resource_changed()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	echo_ref = null
	knowledge_ref = null
	return ..()

/datum/status_effect/heretic_echo_ringing
	id = "heretic_echo_ringing"
	duration = 12 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_echo_ringing
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/echo_ref
	var/mutable_appearance/ringing_overlay

/datum/status_effect/heretic_echo_ringing/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_echo/echo)
	if(QDELETED(echo))
		qdel(src)
		return
	echo_ref = WEAKREF(echo)
	ringing_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_echo_effects.dmi', "echo_ringing", BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/heretic_echo_ringing/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(!echo || owner.stat == DEAD || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))
		return FALSE
	echo.ringing += src
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_overlay))
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_echo_ringing/proc/update_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += ringing_overlay

/datum/status_effect/heretic_echo_ringing/on_remove()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	echo?.ringing.Remove(src)
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_icon()
	return ..()

/datum/status_effect/heretic_echo_ringing/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_echo_ringing/Destroy()
	. = ..()
	QDEL_NULL(ringing_overlay)
	echo_ref = null
	return .

/atom/movable/screen/alert/status_effect/heretic_echo_ringing
	name = "Остаточный звон"
	desc = "Чужая нота держится за ваше тело. Усиленный клинок её владельца наносит ещё 5 ушибов. Звон исчезнет через 12 секунд после последнего попадания магии."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_echo"

/datum/status_effect/eldritch/echo
	id = "echo_mark"
	mark_name = "Метка Эха"
	mark_alert_state = "sigil_echo"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_echo_effects.dmi'
	effect_sprite = "echo_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/echo_grasp.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_echo/wave
	var/datum/weakref/echo_ref

/datum/status_effect/eldritch/echo/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_echo/echo)
	if(echo)
		echo_ref = WEAKREF(echo)
	return ..()

/datum/status_effect/eldritch/echo/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(!echo)
		return FALSE
	echo.marks += src
	return TRUE

/datum/status_effect/eldritch/echo/on_remove()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	echo?.marks.Remove(src)
	return ..()

/datum/status_effect/eldritch/echo/on_effect()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	var/mob/living/user = echo?.echo_body
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/echo_mark)
	if(echo?.can_use(user) && isturf(owner.loc) && echo.line_clear(user, owner) && heretic_can_affect(user, owner, chargecost = 0))
		echo.set_ringing(owner)
		var/list/pattern = echo.make_pattern(get_turf(owner), 1, HERETIC_ECHO_CROSS, 20, 20)
		echo.start_attack(user, list(pattern), required)
	return ..()

/obj/item/melee/sickly_blade/echo
	name = "keening blade"
	desc = "Два узких лезвия сходятся у латунной рукояти. Между ними вибрирует нота, от которой ноют зубы."
	icon = 'modular_bluemoon/icons/obj/heretic_echo.dmi'
	icon_state = "echo_blade"
	item_state = "echo_blade"
	route = PATH_ECHO
	mark_type = /datum/status_effect/eldritch/echo

/obj/item/heretic_path_relic/echo_fork
	name = "mourning lyre"
	desc = "Ручная лира с асимметричной костяной рамой, тремя латунными струнами и подвесным язычком. В руке создателя меняет рисунок Последнего удара, Припева и их повторов: крест или диагонали. Уже начавшийся звон сохраняет прежний рисунок. Перезарядка — 10 секунд."
	icon_state = "echo_fork"

/obj/item/heretic_path_relic/echo_fork/attack_self(mob/living/user)
	return retune(user)

/obj/item/heretic_path_relic/echo_fork/proc/retune(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!authorized(user) || !echo?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	echo.diagonal_echo = !echo.diagonal_echo
	echo.notify_resource_changed()
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	to_chat(user, span_eldritch("Вы касаетесь струн лиры. Следующие удары расходятся [echo.diagonal_echo ? "по диагоналям" : "крестом"]."))
	new /obj/effect/temp_visual/heretic_echo/wave(get_turf(user))
	playsound(user, 'modular_bluemoon/sound/heretic/echo_grasp.ogg', 40, FALSE)
	return TRUE

/obj/effect/temp_visual/heretic_echo
	icon = 'modular_bluemoon/icons/obj/heretic_echo_effects.dmi'
	icon_state = "echo_wave"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_echo/grasp
	icon_state = "echo_grasp"

/obj/effect/temp_visual/heretic_echo/wave

/obj/effect/temp_visual/heretic_echo/burst
	icon_state = "echo_burst"

/obj/effect/temp_visual/heretic_echo/warning
	icon_state = "echo_warning"
	duration = HERETIC_ECHO_WARNING_TIME
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_echo/ascend
	icon_state = "echo_ascend"
	duration = 2.4 SECONDS

/datum/eldritch_knowledge/base_echo/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !proximity_flag || !istype(target, /obj/item/radio/intercom) || !isturf(target.loc))
		return FALSE
	var/obj/item/radio/intercom/speaker = target
	if(!speaker.on || !heretic.advance_deed(heretic.deed_key_for(speaker), get_turf(user)))
		return FALSE
	speaker.audible_message(span_hear("Из динамика [speaker] доносится хриплый шёпот на незнакомом языке."), hearing_distance = HERETIC_ECHO_DEED_WHISPER_RANGE)
	playsound(speaker, 'modular_bluemoon/sound/heretic/echo_cast.ogg', 45, TRUE)
	return TRUE

/datum/eldritch_knowledge/echo_grasp
	name = "Звенящая хватка"
	desc = "Хватка Мансуса оставляет Остаточный звон на 12 секунд и даёт 2 единицы резонанса раз в 6 секунд. Звон подготавливает врага к усиленному клинку. Антимагия и союзники не дают ресурса."
	gain_text = "Я коснулся горла. Голос ответил из пустой ладони."
	cost = 1
	route = PATH_ECHO

/datum/eldritch_knowledge/echo_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!proximity_flag || !echo?.can_use(user) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	echo.set_ringing(target)
	if(COOLDOWN_FINISHED(echo, grasp_harvest))
		echo.gain_combat_resource(2)
		COOLDOWN_START(echo, grasp_harvest, HERETIC_ECHO_HARVEST_TIME)
	return TRUE

/datum/eldritch_knowledge/spell/echo_refrain
	name = "Припев"
	desc = "Ударьте по выбранной клетке в пяти клетках: 18 ушибов и 15 урона выносливости сразу. Через 0,8 секунды крест вокруг неё повторит удар на 22 ушиба и 25 выносливости. От повтора можно уклониться. Не требует резонанса, перезарядка — 14 секунд. Лира меняет рисунок повтора; резонаторы расширяют его охват."
	gain_text = "Я вычеркнул строку. Хор пропел её ещё раз."
	cost = 1
	route = PATH_ECHO
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_echo/refrain

/datum/eldritch_knowledge/spell/echo_refrain/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/echo_mark
	name = "Метка Эха"
	desc = "Хватка Мансуса оставляет метку на 15 секунд. Удар клинком возвращает единицу резонанса и отмечает крест вокруг цели: через 0,8 секунды повтор нанесёт 20 ушибов и 20 урона выносливости. Из креста можно выйти. Метка оставляет Остаточный звон на 12 секунд."
	gain_text = "В партитуре было написано моё имя. Следующая нота принадлежала уже не мне."
	cost = 2
	route = PATH_ECHO

/datum/eldritch_knowledge/echo_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!proximity_flag || !echo?.can_use(user) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/echo, echo)
	return TRUE

/datum/eldritch_knowledge/echo_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(echo)
		QDEL_LIST(echo.marks)
		echo.clear_knowledge_effects(src)

/datum/eldritch_knowledge/echo_fork
	name = "Поминальная лира"
	desc = "Лист золота и металлический прут создают лиру. В руке создателя она переключает крест и диагонали у Последнего удара, Припева и их резонаторных повторов. Уже начатый звон не меняется. Перезарядка — 10 секунд, ресурс не расходуется. Можно иметь одну лиру."
	gain_text = "Я отпустил струны. Третья продолжала звучать, хотя я её не касался."
	cost = 1
	route = PATH_ECHO
	required_atoms = list(/obj/item/stack/sheet/mineral/gold, /obj/item/stack/rods)
	result_atoms = list(/obj/item/heretic_path_relic/echo_fork)

/datum/eldritch_knowledge/echo_fork/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/echo_fork/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/echo_fork)

/datum/eldritch_knowledge/echo_fork/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(echo)
		echo.diagonal_echo = FALSE
		echo.notify_resource_changed()

/datum/eldritch_knowledge/echo_upgrade
	name = "Режущая нота"
	desc = "Звенящий клинок наносит ещё 10 ушибов противнику с вашим Остаточным звоном. Звон оставляют хватка, метка и попадания волн; он длится 12 секунд."
	gain_text = "Я заточил сталь, слушая, где обрывается её песня."
	cost = 2
	route = PATH_ECHO

/datum/eldritch_knowledge/echo_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!proximity_flag || !echo?.can_use(user) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/mob/living/victim = target
	var/datum/status_effect/heretic_echo_ringing/effect = victim.has_status_effect(/datum/status_effect/heretic_echo_ringing)
	if(effect?.echo_ref?.resolve() == echo)
		victim.adjustBruteLoss(10)

/datum/eldritch_knowledge/spell/echo_resonator
	name = "Голос из пустой трубы"
	desc = "Поставьте резонатор в пяти клетках за единицу резонанса. Он повторяет Последний удар и отголосок Припева с полным уроном, расширяя область поражения. Перекрытие волн не умножает урон. Можно иметь два; каждый живёт 30 секунд и имеет 35 прочности. Связь работает в семи клетках без преград. Нулевой жезл разрушает резонатор; свой можно убрать рукой."
	gain_text = "Труба была пуста. Я услышал, как внутри набрали воздуха."
	cost = 1
	route = PATH_ECHO
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_echo/resonator

/datum/eldritch_knowledge/spell/echo_resonator/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/echo_sustain
	name = "Долгое послезвучие"
	desc = "Предел резонанса возрастает до 5. Улучшения пассивки увеличивают его до 6 и 7. Знание не создаёт резонанс само по себе."
	gain_text = "Певцы давно замолчали. Своды продолжали держать их голоса."
	cost = 2
	route = PATH_ECHO
	passive_values = list(5, 6, 7)
	passive_desc = "Предел резонанса — 5 / 6 / 7 единиц. Вознесение увеличивает его до 8."

/datum/eldritch_knowledge/echo_sustain/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo?.update_capacity()

/datum/eldritch_knowledge/echo_sustain/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(echo && echo.echo_body == user)
		echo.update_capacity(TRUE)

/datum/eldritch_knowledge/echo_sustain/on_passive_upgrade(mob/living/user)
	on_body_gain(user)

/datum/eldritch_knowledge/spell/echo_crescendo
	name = "Крещендо"
	desc = "Расходует весь резонанс, минимум 2. Вокруг выбранной точки звучат крест, диагонали и кольцо радиусом две клетки. Каждый рисунок предупреждает за 0,8 секунды. Такт наносит по 18 ушибов и урона выносливости плюс по 2 за единицу резонанса: при запасе 4 — по 26. Двигайтесь между рисунками, чтобы уклониться. Перезарядка — 40 секунд."
	gain_text = "Первым вступил один голос. Последним — хор, которому не хватало места под небом."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_ECHO
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_echo/crescendo

/datum/eldritch_knowledge/spell/echo_crescendo/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/final_eldritch/echo_final
	parallax_scene = ANTAG_SCENE_HERETIC_ECHO
	name = "Регент Последнего Хора"
	desc = "После трёх назначенных душ принесите три человеческих трупа. Обряд раскрывает место станции и длится 30 секунд. Вознесение увеличивает предел резонанса до 8 и восстанавливает единицу каждые 8 секунд, пока вы способны действовать. Вы не нуждаетесь в дыхании и получаете на четверть меньше ушибов и ожогов. «Последняя служба» бесплатно выпускает три кольца радиусом 1, 2 и 3 клетки вокруг вашей прежней позиции. Каждое отмечает пол за 0,8 секунды и наносит 32 ушиба и 35 урона выносливости. Перезарядка — 35 секунд."
	gain_text = "Я поднял руку. Мёртвые не воскресли — они запели."
	route = PATH_ECHO
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_traits = list(TRAIT_NOBREATH)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_echo/final)

/datum/eldritch_knowledge/final_eldritch/echo_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/echo_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(echo)
		echo.ascension_active = TRUE
		echo.update_capacity()

/datum/eldritch_knowledge/final_eldritch/echo_final/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(echo)
		echo.ascension_active = FALSE
		echo.clear_knowledge_effects(src)
		if(echo.echo_body == user)
			echo.update_capacity(ignore_ascension = TRUE)
	return ..()

/obj/effect/proc_holder/spell/self/heretic_echo
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_echo/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	return ..() && echo?.can_use(user)

/obj/effect/proc_holder/spell/self/heretic_echo/release
	name = "Последний удар"
	desc = "За единицу резонанса отметьте крест радиусом две клетки вокруг себя. Через 0,8 секунды он нанесёт 24 ушиба и 25 урона выносливости. Лира меняет рисунок; резонаторы повторяют его с полным уроном. Из отмеченного пола можно выйти."
	charge_max = 12 SECONDS
	action_icon_state = "echo_release"

/obj/effect/proc_holder/spell/self/heretic_echo/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!echo?.release(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_echo/final
	name = "Последняя служба"
	desc = "Вокруг прежней позиции расходятся три кольца радиусом 1, 2 и 3 клетки. Каждое предупреждает за 0,8 секунды и наносит 32 ушиба и 35 урона выносливости. Не расходует резонанс. Требует вознесения."
	charge_max = 35 SECONDS
	action_icon_state = "echo_final"

/obj/effect/proc_holder/spell/self/heretic_echo/final/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!echo?.final_chorus(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_echo
	clothes_req = FALSE
	invocation_type = "none"
	range = HERETIC_ECHO_RANGE
	selection_type = "view"
	aim_assist = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	active_msg = "Укажите место, где прозвучит эхо."
	deactive_msg = "Вы гасите последнюю ноту."

/obj/effect/proc_holder/spell/pointed/heretic_echo/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	return ..() && echo?.can_use(user)

/obj/effect/proc_holder/spell/pointed/heretic_echo/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	return target && (isturf(target) || isturf(target.loc)) && echo?.can_use(user) && echo.line_clear(user, target)

/obj/effect/proc_holder/spell/pointed/heretic_echo/refrain
	name = "Припев"
	desc = "Выбранная клетка сразу получает удар на 18 ушибов и 15 выносливости. Через 0,8 секунды крест вокруг неё нанесёт 22 ушиба и 25 выносливости. От повтора можно уклониться. Не требует резонанса."
	charge_max = 14 SECONDS
	action_icon_state = "echo_refrain"

/obj/effect/proc_holder/spell/pointed/heretic_echo/refrain/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.refrain(user, get_turf(targets[1])))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_echo/resonator
	name = "Погребальный резонатор"
	desc = "За единицу резонанса поставьте резонатор: 35 прочности, 30 секунд жизни. Повторяет Последний удар и отголосок Припева с полным уроном. Можно иметь два в семи клетках без преград. Перекрытие волн не умножает урон; разрушение отменяет подготовленный повтор."
	charge_max = 8 SECONDS
	action_icon_state = "echo_resonator"

/obj/effect/proc_holder/spell/pointed/heretic_echo/resonator/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.create_resonator(user, get_turf(targets[1])))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_echo/crescendo
	name = "Крещендо"
	desc = "Вокруг выбранной точки звучат крест, диагонали и кольцо. Каждый рисунок предупреждает за 0,8 секунды и наносит по 18 ушибов и урона выносливости плюс по 2 за единицу резонанса. Расходует весь запас, минимум 2."
	charge_max = 40 SECONDS
	action_icon_state = "echo_crescendo"

/obj/effect/proc_holder/spell/pointed/heretic_echo/crescendo/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.crescendo(user, get_turf(targets[1])))
		revert_cast(user)

#undef HERETIC_ECHO_RANGE
#undef HERETIC_ECHO_LINK_RANGE
#undef HERETIC_ECHO_WARNING_TIME
#undef HERETIC_ECHO_RECOVERY_TIME
#undef HERETIC_ECHO_RELEASE_DAMAGE
#undef HERETIC_ECHO_RELEASE_STAMINA
#undef HERETIC_ECHO_REFRAIN_DAMAGE
#undef HERETIC_ECHO_REFRAIN_STAMINA
#undef HERETIC_ECHO_REPEAT_DAMAGE
#undef HERETIC_ECHO_REPEAT_STAMINA
#undef HERETIC_ECHO_HARVEST_TIME
#undef HERETIC_ECHO_RESONATOR_LIFETIME
#undef HERETIC_ECHO_RESONATOR_LIMIT
#undef HERETIC_ECHO_ATTACK_LIMIT
#undef HERETIC_ECHO_ASCENDED_CAPACITY
#undef HERETIC_ECHO_CROSS
#undef HERETIC_ECHO_DIAGONALS
#undef HERETIC_ECHO_RING
#undef HERETIC_ECHO_DEED_WHISPER_RANGE
