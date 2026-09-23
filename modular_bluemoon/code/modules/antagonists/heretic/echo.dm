#define HERETIC_ECHO_RANGE 5
#define HERETIC_ECHO_LINK_RANGE 7
#define HERETIC_ECHO_WARNING_TIME (0.8 SECONDS)
#define HERETIC_ECHO_RECOVERY_TIME (8 SECONDS)
#define HERETIC_ECHO_RELEASE_DAMAGE 24
#define HERETIC_ECHO_RELEASE_STAMINA 25
#define HERETIC_ECHO_OPENING_DAMAGE 12
#define HERETIC_ECHO_OPENING_STAMINA 10
#define HERETIC_ECHO_OPENING_RADIUS 2
#define HERETIC_ECHO_RELEASE_RADIUS 3
#define HERETIC_ECHO_REFRAIN_RADIUS 1
#define HERETIC_ECHO_REPEAT_RADIUS 2
#define HERETIC_ECHO_CRESCENDO_RADIUS 3
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
#define HERETIC_ECHO_WAVE 4
#define HERETIC_ECHO_BAND 5
#define HERETIC_ECHO_DEED_WHISPER_RANGE 5
#define HERETIC_ECHO_DISSONANCE_DURATION (1.5 SECONDS)
#define HERETIC_ECHO_HOLD_TIME (3 SECONDS)
#define HERETIC_ECHO_INK "#d9bb73"
#define HERETIC_ECHO_RING_COUNT 3
#define HERETIC_ECHO_RING_STEP (0.12 SECONDS)
#define HERETIC_ECHO_RING_TIME (0.5 SECONDS)
#define HERETIC_ECHO_TOLL_RADIUS 3
#define HERETIC_ECHO_TOLL_VOLUME 45
#define HERETIC_ECHO_WAVE_TIME (0.5 SECONDS)
#define HERETIC_ECHO_DUST_SPREAD 6
#define HERETIC_ECHO_FINAL_QUAKE 0.12
#define HERETIC_ECHO_FINAL_QUAKE_TIME (0.35 SECONDS)
#define HERETIC_ECHO_FINAL_QUAKE_RADIUS 7
#define HERETIC_ECHO_FINAL_FLASH_RANGE 5
#define HERETIC_ECHO_FINAL_FLASH_POWER 1.5
#define HERETIC_ECHO_FINAL_FLASH_TIME (0.4 SECONDS)

/datum/heretic_path/echo
	id = PATH_ECHO
	deed_type = /datum/heretic_deed/echo
	name = "Эхо"
	desc = "Накройте врагов широкой звуковой волной и поймайте их сильным повтором. Ближняя и средняя дистанция, без обязательной подготовки."
	strengths = "Сплошной первый удар по площади, дальние отзвуки и короткая контузия за два попадания одной последовательности. Резонаторы расширяют охват повторов. Вознёсшийся отвечает на попадание, снявшее больше 5 здоровья, не чаще раза в 2 секунды: через 0,8 секунды вокруг него бьёт крест в три клетки и оставляет Остаточный звон, как обычные волны."
	weaknesses = "Сильный повтор поражает отмеченные клетки: из них можно уйти. Преграды глушат даже первую волну, резонаторы можно разбить. Отзвук вознёсшегося не достаёт дальше трёх клеток и мимо креста: стреляйте издалека и не стойте с ним на одной линии."
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
	desc = "Нож и металлический прут создают звенящий клинок. «Последний удар» сразу накрывает всю область в двух клетках вокруг вас, затем повторяет звук отмеченным крестом до трёх клеток. Попадания возвращают резонанс. Первый удар не требует ловушек; от сильного повтора можно уйти, стены гасят оба такта."
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
	grasp_catchphrase = "A'IDAS AT'SAKO"
	var/mob/living/echo_body
	var/list/datum/heretic_echo_attack/attacks = list()
	var/list/obj/structure/heretic_echo_resonator/resonators = list()
	var/list/datum/status_effect/eldritch/echo/marks = list()
	var/list/datum/status_effect/heretic_echo_ringing/ringing = list()
	var/list/datum/status_effect/heretic_echo_dissonance/dissonances = list()
	var/echo_generation = 0
	var/diagonal_echo = FALSE
	var/hold_next_repeat = FALSE
	var/datum/weakref/conductor_ref
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
	hold_next_repeat = FALSE
	conductor_ref = null
	QDEL_LIST(attacks)
	QDEL_LIST(resonators)
	QDEL_LIST(marks)
	QDEL_LIST(ringing)
	QDEL_LIST(dissonances)

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
	data["description"] = "[combat_resource_desc] Рисунок повторов: [diagonal_echo ? "диагонали" : "крест"]. Резонаторов: [length(resonators)] из [HERETIC_ECHO_RESONATOR_LIMIT]."
	var/obj/structure/heretic_echo_resonator/conductor = conductor_ref?.resolve()
	data["description"] += conductor ? " Лира направляет поздние отзвуки через выбранный резонатор. Связь требует открытой линии в семи клетках." : " Выберите свой резонатор щелчком лиры: он повторит Крещендо и Последнюю службу."
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
		if(shape == HERETIC_ECHO_BAND && max(offset_x, offset_y) < radius - 1)
			continue
		if(line_clear(center, tile, radius))
			tiles += tile
	return tiles

/datum/eldritch_knowledge/base_echo/proc/make_pattern(turf/center, radius, shape, damage, stamina, relay = FALSE, directed = FALSE)
	var/list/zones = list()
	var/list/cells = pattern_turfs(center, radius, shape)
	if(length(cells))
		zones += list(list("center" = center, "cells" = cells, "radius" = radius, "damage" = damage, "stamina" = stamina))
	if(relay || directed)
		for(var/obj/structure/heretic_echo_resonator/resonator as anything in resonators)
			if(directed && resonator != conductor_ref?.resolve())
				continue
			if(!resonator.valid_source() || !line_clear(echo_body, resonator, HERETIC_ECHO_LINK_RANGE))
				continue
			var/turf/relay_center = get_turf(resonator)
			var/relay_radius = directed ? radius : 1
			var/list/relay_cells = pattern_turfs(relay_center, relay_radius, shape)
			if(length(relay_cells))
				zones += list(list("center" = relay_center, "cells" = relay_cells, "radius" = relay_radius, "damage" = damage, "stamina" = stamina, "resonator" = WEAKREF(resonator)))
	return zones

/datum/eldritch_knowledge/base_echo/proc/start_attack(mob/living/user, list/patterns, datum/eldritch_knowledge/required, immediate_first = FALSE, chorus = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !length(patterns) || QDELETED(required) || heretic.get_knowledge(required.type) != required || length(attacks) >= HERETIC_ECHO_ATTACK_LIMIT)
		return FALSE
	var/datum/heretic_echo_attack/attack = new(src, patterns, required, chorus)
	if(immediate_first)
		attack.hold_repeat = hold_next_repeat
		hold_next_repeat = FALSE
		attack.resolve()
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/release(mob/living/user)
	if(!can_use(user) || combat_resource < 1 || length(attacks) >= HERETIC_ECHO_ATTACK_LIMIT || !tile_open(get_turf(user)))
		return FALSE
	var/list/opening = make_pattern(get_turf(user), HERETIC_ECHO_OPENING_RADIUS, HERETIC_ECHO_WAVE, HERETIC_ECHO_OPENING_DAMAGE, HERETIC_ECHO_OPENING_STAMINA)
	var/list/repeat = make_pattern(get_turf(user), HERETIC_ECHO_RELEASE_RADIUS, diagonal_echo ? HERETIC_ECHO_DIAGONALS : HERETIC_ECHO_CROSS, HERETIC_ECHO_RELEASE_DAMAGE, HERETIC_ECHO_RELEASE_STAMINA, TRUE)
	if(!length(opening) || !length(repeat) || !spend_combat_resource())
		return FALSE
	if(!start_attack(user, list(opening, repeat), src, immediate_first = TRUE))
		gain_combat_resource()
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/refrain(mob/living/user, turf/center)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_refrain)
	if(!can_use(user) || !line_clear(user, center))
		return FALSE
	var/list/opening = make_pattern(center, HERETIC_ECHO_REFRAIN_RADIUS, HERETIC_ECHO_WAVE, HERETIC_ECHO_REFRAIN_DAMAGE, HERETIC_ECHO_REFRAIN_STAMINA)
	var/list/repeat = make_pattern(center, HERETIC_ECHO_REPEAT_RADIUS, diagonal_echo ? HERETIC_ECHO_DIAGONALS : HERETIC_ECHO_CROSS, HERETIC_ECHO_REPEAT_DAMAGE, HERETIC_ECHO_REPEAT_STAMINA, TRUE)
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
		patterns += list(make_pattern(center, HERETIC_ECHO_CRESCENDO_RADIUS, shape, 18 + 2 * resonance, 18 + 2 * resonance, directed = TRUE))
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
		patterns += list(make_pattern(get_turf(user), radius, HERETIC_ECHO_BAND, 32, 35, directed = TRUE))
	if(!start_attack(user, patterns, required, chorus = TRUE))
		return FALSE
	new /obj/effect/temp_visual/heretic_echo/ascend(get_turf(user))
	toll(user)
	user.visible_message(span_userdanger("[user] поднимает ладони. Невидимый хор вступает голос за голосом!"))
	return TRUE

/// Колокол набирает звук перед первой волной: кольцо стягивается к герою, тот вспыхивает золотом, бьёт колокол.
/datum/eldritch_knowledge/base_echo/proc/toll(mob/living/user)
	heretic_vfx_gather(user, HERETIC_ECHO_INK, HERETIC_ECHO_TOLL_RADIUS, HERETIC_ECHO_WARNING_TIME)
	heretic_vfx_pulse(user, HERETIC_ECHO_INK, 2, HERETIC_ECHO_WARNING_TIME)
	playsound(user, 'sound/effects/gong.ogg', HERETIC_ECHO_TOLL_VOLUME, TRUE)

/datum/eldritch_knowledge/base_echo/proc/reprise(mob/living/user, datum/eldritch_knowledge/final_eldritch/echo_final/required)
	if(!required?.finished || required.applied_body != user || !can_use(user) || length(attacks) >= HERETIC_ECHO_ATTACK_LIMIT)
		return FALSE
	var/list/pattern = make_pattern(get_turf(user), HERETIC_ECHO_REPRISE_RADIUS, HERETIC_ECHO_CROSS, HERETIC_ECHO_REPRISE_DAMAGE, HERETIC_ECHO_REPRISE_STAMINA)
	if(!length(pattern) || !start_attack(user, list(pattern), required))
		return FALSE
	sound_rings(get_turf(user))
	return TRUE

/// От героя одно за другим расходятся золотые кольца звука, за ними звучит крест.
/datum/eldritch_knowledge/base_echo/proc/sound_rings(turf/center)
	heretic_vfx_shockwave(center, HERETIC_ECHO_INK, HERETIC_ECHO_REPRISE_RADIUS, HERETIC_ECHO_RING_TIME)
	for(var/ring in 1 to HERETIC_ECHO_RING_COUNT - 1)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_vfx_shockwave), center, HERETIC_ECHO_INK, HERETIC_ECHO_REPRISE_RADIUS, HERETIC_ECHO_RING_TIME), ring * HERETIC_ECHO_RING_STEP)
	heretic_vfx_burst(center, /particles/heretic_ascension/echo)

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
	var/list/mob/living/sounded = list()
	var/release_timer
	var/resolving = FALSE
	var/hold_repeat = FALSE
	var/held = FALSE
	var/chorus = FALSE

/datum/heretic_echo_attack/New(datum/eldritch_knowledge/base_echo/echo, list/attack_patterns, datum/eldritch_knowledge/required, chorus_attack = FALSE)
	. = ..()
	chorus = chorus_attack
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

/datum/heretic_echo_attack/proc/hold_pulse()
	if(!valid_source())
		qdel(src)
		return FALSE
	held = TRUE
	hold_repeat = FALSE
	sounded.Cut()
	var/list/warned = list()
	var/list/zones = patterns[pulse_index]
	for(var/list/zone as anything in zones)
		var/list/cells = zone["cells"]
		for(var/turf/tile as anything in cells)
			if(tile in warned)
				continue
			warned += tile
			warnings += new /obj/effect/temp_visual/heretic_echo/warning/held(tile)
	release_timer = addtimer(CALLBACK(src, PROC_REF(release_held)), HERETIC_ECHO_HOLD_TIME, TIMER_STOPPABLE)
	return TRUE

/datum/heretic_echo_attack/proc/release_held()
	if(!held || QDELETED(src))
		return FALSE
	held = FALSE
	deltimer(release_timer)
	release_timer = null
	QDEL_LIST(warnings)
	return warn_pulse()

/datum/heretic_echo_attack/proc/resolve()
	if(QDELETED(src) || resolving || held)
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
	var/list/sounding = list()
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
		sounding += list(zone)
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
		if(victim in sounded)
			victim.apply_status_effect(/datum/status_effect/heretic_echo_dissonance, echo)
		else
			sounded += victim
		echo.set_ringing(victim)
		if(!valid_source())
			qdel(src)
			return FALSE
		if(QDELETED(victim) || victim.loc != hit_tiles[victim])
			continue
		if(victim.getBruteLoss() > damage_before)
			echo.harvest(user)
			var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
			heretic?.advance_combat_deed(victim, PATH_ECHO)
		if(!valid_source())
			qdel(src)
			return FALSE
		log_combat(user, victim, "поражает отложенным звоном")
	if(chorus)
		chorus_wave(sounding)
	playsound(origin, 'modular_bluemoon/sound/heretic/echo_burst.ogg', 60, TRUE)
	pulse_index++
	if(pulse_index > length(patterns))
		qdel(src)
	else
		resolving = FALSE
		if(hold_repeat && pulse_index == 2)
			hold_pulse()
		else
			warn_pulse()
	return TRUE

/// Волна Последней службы доходит кольцом до своей полосы и поднимает там пыль; последняя волна сотрясает пол.
/datum/heretic_echo_attack/proc/chorus_wave(list/zones)
	for(var/list/zone as anything in zones)
		var/turf/center = zone["center"]
		var/radius = zone["radius"]
		heretic_vfx_shockwave(center, HERETIC_ECHO_INK, radius, HERETIC_ECHO_WAVE_TIME)
		var/obj/effect/temp_visual/heretic_vfx/burst/dust = heretic_vfx_burst(center, /particles/heretic_ascension/echo/dust)
		if(dust)
			dust.particles.position = generator("circle", (radius - 1) * world.icon_size, radius * world.icon_size + HERETIC_ECHO_DUST_SPREAD)
	if(pulse_index < length(patterns))
		return
	heretic_vfx_flash(origin, HERETIC_ECHO_INK, HERETIC_ECHO_FINAL_FLASH_RANGE, HERETIC_ECHO_FINAL_FLASH_POWER, HERETIC_ECHO_FINAL_FLASH_TIME)
	heretic_vfx_quake(origin, HERETIC_ECHO_FINAL_QUAKE_RADIUS, HERETIC_ECHO_FINAL_QUAKE, HERETIC_ECHO_FINAL_QUAKE_TIME)

/datum/heretic_echo_attack/Destroy()
	deltimer(release_timer)
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	echo?.attacks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	QDEL_LIST(warnings)
	patterns = null
	sounded = null
	origin = null
	echo_ref = null
	knowledge_ref = null
	body_ref = null
	return ..()

/obj/structure/heretic_echo_resonator
	name = "sepulchral resonator"
	desc = "Три латунные трубы поют чужими голосами. Повторяют Последний удар и Припев хозяина с полным уроном. Разбейте резонатор или коснитесь его нулевым жезлом, чтобы оборвать повтор."
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

/obj/structure/heretic_echo_resonator/examine(mob/user)
	. = ..()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(echo?.conductor_ref?.resolve() == src)
		. += span_notice("Лира настроена на этот резонатор: он повторяет Крещендо и Последнюю службу. Разрушение узла обрывает его отзвуки.")

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
		if(echo.conductor_ref && echo.conductor_ref == weak_reference)
			echo.conductor_ref = null
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
	desc = "Чужая нота держится за ваше тело. Усиленный клинок её владельца наносит ещё 10 ушибов. Второе попадание одной последовательности на 1,5 секунды блокирует стрельбу и удары предметами: уходите с отмеченного пола. Звон исчезнет через 12 секунд после последнего попадания магии."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_echo"

/datum/status_effect/heretic_echo_dissonance
	id = "heretic_echo_dissonance"
	duration = HERETIC_ECHO_DISSONANCE_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_echo_dissonance
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/echo_ref

/datum/status_effect/heretic_echo_dissonance/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_echo/echo)
	if(QDELETED(echo))
		qdel(src)
		return
	echo_ref = WEAKREF(echo)
	return ..()

/datum/status_effect/heretic_echo_dissonance/on_apply()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(!..() || QDELETED(echo) || !echo.can_use(echo.echo_body) || owner.stat == DEAD)
		return FALSE
	var/blocked = SEND_SIGNAL(owner, COMSIG_LIVING_STATUS_DAZE, HERETIC_ECHO_DISSONANCE_DURATION, TRUE, FALSE)
	if((blocked & COMPONENT_NO_STUN) || QDELETED(src) || QDELETED(owner) || QDELETED(echo) || !echo.can_use(echo.echo_body) || owner.stat == DEAD)
		return FALSE
	if(!(owner.status_flags & CANKNOCKDOWN) || HAS_TRAIT(owner, TRAIT_STUNIMMUNE) || owner.absorb_stun(HERETIC_ECHO_DISSONANCE_DURATION, FALSE))
		return FALSE
	if(QDELETED(src) || QDELETED(owner) || QDELETED(echo) || !echo.can_use(echo.echo_body) || owner.stat == DEAD)
		return FALSE
	echo.dissonances += src
	ADD_TRAIT(owner, TRAIT_MOBILITY_NOUSE, REF(src))
	if(QDELETED(src) || QDELETED(owner) || QDELETED(echo) || !echo.can_use(echo.echo_body))
		return FALSE
	to_chat(owner, span_userdanger("Ударная волна сбивает координацию! Вы можете двигаться, но 1,5 секунды не можете стрелять или бить предметами."))
	return TRUE

/datum/status_effect/heretic_echo_dissonance/on_remove()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	echo?.dissonances.Remove(src)
	REMOVE_TRAIT(owner, TRAIT_MOBILITY_NOUSE, REF(src))
	return ..()

/atom/movable/screen/alert/status_effect/heretic_echo_dissonance
	name = "Звуковая контузия"
	desc = "Повторная волна на 1,5 секунды блокирует стрельбу и удары предметами. Вы можете двигаться и говорить; оружие остаётся в руках."
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
	desc = "Ручная лира на колоколе-резонаторе. Применение в руке меняет крест и диагонали повторов Последнего удара и Припева. Alt-клик готовит удержание следующего повтора на 3 секунды, следующий Alt-клик выпускает его раньше. Голубой рисунок показывает удержанный звук; перед ударом он снова предупреждает за 0,8 секунды. Удержанный повтор не продолжает диссонанс первого удара. Настройка доступна раз в 10 секунд. Щёлкните лирой по своему резонатору в семи клетках: Крещендо и Последняя служба повторят вокруг него весь рисунок. Повторный щелчок снимает выбор. Нужна открытая линия к резонатору; пересечения одного такта не умножают урон."
	icon = 'modular_bluemoon/icons/obj/heretic_echo.dmi'
	icon_state = "echo_fork"

/obj/item/heretic_path_relic/echo_fork/attack_self(mob/living/user)
	return retune(user)

/obj/item/heretic_path_relic/echo_fork/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(!istype(target, /obj/structure/heretic_echo_resonator))
		return ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/obj/structure/heretic_echo_resonator/resonator = target
	if(!authorized(user) || !echo?.can_use(user) || resonator.echo_ref?.resolve() != echo || !resonator.valid_source() || !echo.line_clear(user, resonator, HERETIC_ECHO_LINK_RANGE))
		return FALSE
	var/obj/structure/heretic_echo_resonator/previous = echo.conductor_ref?.resolve()
	previous?.set_light(0)
	if(previous == resonator)
		echo.conductor_ref = null
		to_chat(user, span_eldritch("Вы снимаете настройку: поздние волны больше не повторяются резонатором."))
	else
		echo.conductor_ref = WEAKREF(resonator)
		resonator.set_light(2, 1, "#85ccd4")
		to_chat(user, span_eldritch("Выбранный резонатор светится голубым. Крещендо и Последняя служба прозвучат также вокруг него; пересечения одного такта не умножают урон."))
	echo.notify_resource_changed()
	return TRUE

/obj/item/heretic_path_relic/echo_fork/AltClick(mob/living/user)
	return hold_echo(user)

/obj/item/heretic_path_relic/echo_fork/proc/hold_echo(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!authorized(user) || !echo?.can_use(user))
		return FALSE
	for(var/datum/heretic_echo_attack/attack as anything in echo.attacks)
		if(attack.held)
			to_chat(user, span_eldritch("Вы отпускаете задержанную ноту. Через 0,8 секунды отмеченные клетки ответят звоном."))
			return attack.release_held()
	if(echo.hold_next_repeat)
		echo.hold_next_repeat = FALSE
		to_chat(user, span_eldritch("Вы снимаете пальцы со струн. Следующий повтор прозвучит без задержки."))
		return TRUE
	if(!COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	echo.hold_next_repeat = TRUE
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	to_chat(user, span_eldritch("Следующий повтор Последнего удара или Припева задержится на 3 секунды. Alt-клик по лире отпустит его раньше; перед ударом прозвучит обычное предупреждение."))
	return TRUE

/obj/item/heretic_path_relic/echo_fork/proc/retune(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!authorized(user) || !echo?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	echo.diagonal_echo = !echo.diagonal_echo
	echo.notify_resource_changed()
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	to_chat(user, span_eldritch("Вы касаетесь струн лиры. Следующие повторы расходятся [echo.diagonal_echo ? "по диагоналям" : "крестом"]."))
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

/obj/effect/temp_visual/heretic_echo/warning/held
	duration = HERETIC_ECHO_HOLD_TIME
	color = "#85ccd4"

/obj/effect/temp_visual/heretic_echo/ascend
	icon_state = "echo_ascend"
	duration = 2.4 SECONDS

/// Эхо: пыль, поднятая волной звука, клубится и оседает.
/particles/heretic_ascension/echo/dust
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("steam_1" = 3, "steam_2" = 2, "steam_3" = 1)
	color = "#b9a57c"
	velocity = generator("circle", 0.3, 1)
	gravity = list(0, 0.06)
	friction = 0.08
	grow = 0.02
	lifespan = 1.2 SECONDS
	fade = 0.8 SECONDS
	fadein = 0.1 SECONDS

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
	desc = "Выберите точку в пяти клетках: вся область 3×3 вокруг неё сразу получает 18 ушибов и 15 урона выносливости. Через 0,8 секунды отмеченный крест радиусом две клетки повторит удар на 22 ушиба и 25 выносливости. От повтора можно уклониться. Попадание обоих тактов на 1,5 секунды блокирует стрельбу и удары предметами, сохраняя движение. Не требует резонанса, перезарядка — 14 секунд. Лира меняет рисунок повтора; резонаторы расширяют его охват."
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
	desc = "Лист золота и металлический прут создают лиру. Применение в руке переключает крест и диагонали повторов Последнего удара и Припева, включая резонаторные. Alt-клик готовит удержание следующего повтора на 3 секунды; повторный Alt-клик выпускает его раньше или отменяет подготовку. Голубой рисунок сохраняет прежние клетки, затем даёт обычное предупреждение за 0,8 секунды. Удержанный повтор не продолжает диссонанс первого удара. Настройка раз в 10 секунд, выпуск свободный. Резонанс не расходуется; можно иметь одну лиру. Щёлкните лирой по своему резонатору в семи клетках: Крещендо и Последняя служба повторят вокруг него весь рисунок. Повторный щелчок снимает выбор. Нужна открытая линия к резонатору; пересечения одного такта не умножают урон."
	gain_text = "Я отпустил струны. Третья продолжала звучать, хотя я её не касался."
	cost = 1
	route = PATH_ECHO
	required_atoms = list(/obj/item/stack/sheet/mineral/gold, /obj/item/stack/rods)
	result_atoms = list(/obj/item/heretic_path_relic/echo_fork)
	var/datum/weakref/echo_ref

/datum/eldritch_knowledge/echo_fork/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo_ref = echo ? WEAKREF(echo) : null

/datum/eldritch_knowledge/echo_fork/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/echo_fork/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/echo_fork)

/datum/eldritch_knowledge/echo_fork/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(echo)
		echo.diagonal_echo = FALSE
		echo.hold_next_repeat = FALSE
		var/obj/structure/heretic_echo_resonator/conductor = echo.conductor_ref?.resolve()
		conductor?.set_light(0)
		echo.conductor_ref = null
		for(var/datum/heretic_echo_attack/attack as anything in echo.attacks.Copy())
			if(attack.held)
				qdel(attack)
		echo.notify_resource_changed()
	echo_ref = null

/datum/eldritch_knowledge/echo_fork/Destroy()
	on_body_lose(null)
	return ..()

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
	desc = "Расходует весь резонанс, минимум 2. Вокруг выбранной точки звучат крест, диагонали и кольцо радиусом три клетки. Каждый рисунок предупреждает за 0,8 секунды. Такт наносит по 18 ушибов и урона выносливости плюс по 2 за единицу резонанса: при запасе 4 — по 26. Повторное попадание одной последовательности на 1,5 секунды блокирует стрельбу и удары предметами, сохраняя движение. Двигайтесь между рисунками, чтобы уклониться. Перезарядка — 40 секунд. Выбранный лирой резонатор повторяет рисунок при открытой связи в семи клетках; пересечения не усиливают один такт. Разрушение резонатора отменяет его повторы."
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
	desc = "После трёх назначенных душ принесите три человеческих трупа. Обряд раскрывает место станции и длится 30 секунд. Вознесение увеличивает предел резонанса до 8 и восстанавливает единицу каждые 8 секунд, пока вы способны действовать. Вы получаете общую стойкость вознесения. Отзвук: попадание врага, снявшее больше 5 здоровья, не чаще раза в 2 секунды отмечает крест в три клетки вокруг вас, через 0,8 секунды он наносит 15 ушибов и 15 урона выносливости и оставляет Остаточный звон, как обычные волны. Стены глушат отзвук, из креста можно уйти. «Последняя служба» бесплатно выпускает три волны вокруг вашей прежней позиции: первая накрывает центр и соседние клетки, вторая — клетки в 1–2 шагах, третья — в 2–3. Соседние волны перекрываются: неподвижную цель в одной-двух клетках от центра задевают две волны подряд. Каждая отмечает пол за 0,8 секунды и наносит 32 ушиба и 35 урона выносливости. Перезарядка — 35 секунд. Выбранный лирой резонатор повторяет рисунок при открытой связи в семи клетках; пересечения не усиливают один такт. Разрушение резонатора отменяет его повторы."
	gain_text = "Я поднял руку. Мёртвые не воскресли — они запели."
	route = PATH_ECHO
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_echo/final)
	var/datum/weakref/echo_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/echo_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!echo)
		return
	echo_knowledge_ref = WEAKREF(echo)
	echo.ascension_active = TRUE
	echo.update_capacity()
	if(iscarbon(user))
		user.AddComponent(/datum/component/heretic_echo_reprise, echo, src)

/datum/eldritch_knowledge/final_eldritch/echo_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_echo_reprise))
	var/datum/eldritch_knowledge/base_echo/echo = echo_knowledge_ref?.resolve()
	echo_knowledge_ref = null
	if(echo)
		echo.ascension_active = FALSE
		echo.clear_knowledge_effects(src)
		if(echo.echo_body == user)
			echo.update_capacity(ignore_ascension = TRUE)
	return ..()

/// Отзвук вознесения: настоящее попадание врага отвечает отложенным крестом вокруг героя.
/datum/component/heretic_echo_reprise
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/echo_ref
	var/datum/weakref/finale_ref
	var/loss_before_hit = 0
	var/hit_time = -1
	var/hit_landed = FALSE
	COOLDOWN_DECLARE(reprise_cooldown)

/datum/component/heretic_echo_reprise/Initialize(datum/eldritch_knowledge/base_echo/echo, datum/eldritch_knowledge/final_eldritch/echo_final/finale)
	if(!iscarbon(parent) || QDELETED(echo) || QDELETED(finale))
		return COMPONENT_INCOMPATIBLE
	echo_ref = WEAKREF(echo)
	finale_ref = WEAKREF(finale)

/datum/component/heretic_echo_reprise/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_RUN_BLOCK, PROC_REF(on_attacked))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage_applied))
	RegisterSignal(parent, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_health_changed))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_echo_reprise/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_MOB_APPLY_DAMAGE, COMSIG_CARBON_UPDATEHEALTH, COMSIG_PARENT_EXAMINE))

/// Урон после брони и стойкости виден только в updatehealth того же тика, поэтому здесь попадание лишь запоминается.
/datum/component/heretic_echo_reprise/proc/on_attacked(mob/living/carbon/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	hit_time = -1
	hit_landed = FALSE
	if(!real_attack || (ismob(attacker) && (attacker == source || IS_HERETIC(attacker) || IS_HERETIC_MONSTER(attacker))))
		return BLOCK_NONE
	hit_time = world.time
	loss_before_hit = source.getBruteLoss() + source.getFireLoss()
	return BLOCK_NONE

/datum/component/heretic_echo_reprise/proc/on_damage_applied(mob/living/carbon/source, damage, damagetype)
	SIGNAL_HANDLER
	if(hit_time == world.time && damage > 0 && (damagetype == BRUTE || damagetype == BURN))
		hit_landed = TRUE

/datum/component/heretic_echo_reprise/proc/on_health_changed(mob/living/carbon/source)
	SIGNAL_HANDLER
	if(hit_time != world.time || !hit_landed)
		return
	var/damage_taken = source.getBruteLoss() + source.getFireLoss() - loss_before_hit
	if(!damage_taken)
		return
	hit_time = -1
	hit_landed = FALSE
	if(damage_taken <= HERETIC_ECHO_REPRISE_MIN_DAMAGE || !COOLDOWN_FINISHED(src, reprise_cooldown))
		return
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(echo?.reprise(source, finale_ref?.resolve()))
		COOLDOWN_START(src, reprise_cooldown, HERETIC_ECHO_REPRISE_COOLDOWN)

/datum/component/heretic_echo_reprise/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Воздух вокруг звенит: попадание, снявшее больше 5 здоровья, не чаще раза в 2 секунды отзывается через 0,8 секунды крестом в три клетки и оставляет звон. Стреляйте издалека и не стойте с ним на одной линии, стены глушат отзвук.")

/obj/effect/proc_holder/spell/self/heretic_echo
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_echo/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	return ..() && heretic_check(user, echo?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_echo/release
	name = "Последний удар"
	desc = "За единицу резонанса сразу ударьте по всей области 5×5 вокруг себя: 12 ушибов и 10 урона выносливости. Через 0,8 секунды отмеченный крест радиусом три клетки нанесёт 24 ушиба и 25 выносливости. Лира меняет рисунок повтора, резонаторы расширяют его. От повтора можно уйти; два попадания на 1,5 секунды блокируют стрельбу и удары предметами, сохраняя движение."
	charge_max = 12 SECONDS
	action_icon_state = "echo_release"

/obj/effect/proc_holder/spell/self/heretic_echo/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!echo?.release(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_echo/final
	name = "Последняя служба"
	desc = "Вокруг прежней позиции расходятся три волны шириной в две клетки: до 1 шага от центра, 1–2 и 2–3 шага. Соседние волны перекрываются: неподвижную цель в одной-двух клетках от центра задевают две волны подряд. Каждая предупреждает за 0,8 секунды и наносит 32 ушиба и 35 урона выносливости. Не расходует резонанс. Требует вознесения. Выбранный лирой резонатор повторяет рисунок при открытой связи в семи клетках; пересечения не усиливают один такт. Разрушение резонатора отменяет его повторы."
	charge_max = 35 SECONDS
	action_icon_state = "echo_final"

/obj/effect/proc_holder/spell/self/heretic_echo/final/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!echo?.final_chorus(user))
		heretic_revert_cast(user)

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
	return ..() && heretic_check(user, echo?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_echo/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	return heretic_check(user, target && (isturf(target) || isturf(target.loc)) && echo?.can_use(user) && echo.line_clear(user, target), silent, "Выберите видимую цель или клетку: стены и контейнеры перекрывают действие.")

/obj/effect/proc_holder/spell/pointed/heretic_echo/refrain
	name = "Припев"
	desc = "Вся область 3×3 вокруг выбранной точки сразу получает 18 ушибов и 15 урона выносливости. Через 0,8 секунды отмеченный крест радиусом две клетки нанесёт 22 ушиба и 25 выносливости. От повтора можно уклониться. Попадание обоих тактов на 1,5 секунды блокирует стрельбу и удары предметами, сохраняя движение. Не требует резонанса."
	charge_max = 14 SECONDS
	action_icon_state = "echo_refrain"

/obj/effect/proc_holder/spell/pointed/heretic_echo/refrain/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.refrain(user, get_turf(targets[1])))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_echo/resonator
	name = "Погребальный резонатор"
	desc = "За единицу резонанса поставьте резонатор: 35 прочности, 30 секунд жизни. Повторяет Последний удар и отголосок Припева с полным уроном. Можно иметь два в семи клетках без преград. Перекрытие волн не умножает урон; разрушение отменяет подготовленный повтор."
	charge_max = 8 SECONDS
	action_icon_state = "echo_resonator"

/obj/effect/proc_holder/spell/pointed/heretic_echo/resonator/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.create_resonator(user, get_turf(targets[1])))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_echo/crescendo
	name = "Крещендо"
	desc = "Вокруг выбранной точки звучат крест, диагонали и кольцо радиусом три клетки. Каждый рисунок предупреждает за 0,8 секунды и наносит по 18 ушибов и урона выносливости плюс по 2 за единицу резонанса. Повторное попадание этой последовательности на 1,5 секунды блокирует стрельбу и удары предметами, сохраняя движение. Расходует весь запас, минимум 2."
	charge_max = 40 SECONDS
	action_icon_state = "echo_crescendo"

/obj/effect/proc_holder/spell/pointed/heretic_echo/crescendo/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.crescendo(user, get_turf(targets[1])))
		heretic_revert_cast(user)

#undef HERETIC_ECHO_RANGE
#undef HERETIC_ECHO_LINK_RANGE
#undef HERETIC_ECHO_WARNING_TIME
#undef HERETIC_ECHO_RECOVERY_TIME
#undef HERETIC_ECHO_RELEASE_DAMAGE
#undef HERETIC_ECHO_RELEASE_STAMINA
#undef HERETIC_ECHO_OPENING_DAMAGE
#undef HERETIC_ECHO_OPENING_STAMINA
#undef HERETIC_ECHO_OPENING_RADIUS
#undef HERETIC_ECHO_RELEASE_RADIUS
#undef HERETIC_ECHO_REFRAIN_RADIUS
#undef HERETIC_ECHO_REPEAT_RADIUS
#undef HERETIC_ECHO_CRESCENDO_RADIUS
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
#undef HERETIC_ECHO_WAVE
#undef HERETIC_ECHO_BAND
#undef HERETIC_ECHO_DEED_WHISPER_RANGE
#undef HERETIC_ECHO_DISSONANCE_DURATION
#undef HERETIC_ECHO_HOLD_TIME
#undef HERETIC_ECHO_INK
#undef HERETIC_ECHO_RING_COUNT
#undef HERETIC_ECHO_RING_STEP
#undef HERETIC_ECHO_RING_TIME
#undef HERETIC_ECHO_TOLL_RADIUS
#undef HERETIC_ECHO_TOLL_VOLUME
#undef HERETIC_ECHO_WAVE_TIME
#undef HERETIC_ECHO_DUST_SPREAD
#undef HERETIC_ECHO_FINAL_QUAKE
#undef HERETIC_ECHO_FINAL_QUAKE_TIME
#undef HERETIC_ECHO_FINAL_QUAKE_RADIUS
#undef HERETIC_ECHO_FINAL_FLASH_RANGE
#undef HERETIC_ECHO_FINAL_FLASH_POWER
#undef HERETIC_ECHO_FINAL_FLASH_TIME
