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
#define HERETIC_ECHO_CRESCENDO_RADIUS 3
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
#define HERETIC_ECHO_TAP_CRAFT "echo_tap"
#define HERETIC_ECHO_TAP_CLUE "Динамик повторяет слова с задержкой."
#define HERETIC_ECHO_CAPTURE "echo"
#define HERETIC_ECHO_LULLABY_RANGE 5
#define HERETIC_ECHO_LULLABY_COST 2
#define HERETIC_ECHO_LULLABY_COOLDOWN (40 SECONDS)
#define HERETIC_ECHO_LULLABY_BLUR 2
#define HERETIC_ECHO_LULLABY_COLOR "#b9c4f0"
#define HERETIC_ECHO_LULLABY_NOTE_OFFSET 16
#define HERETIC_ECHO_LULLABY_CHECK (0.2 SECONDS)
#define HERETIC_ECHO_VOICE_COOLDOWN (20 SECONDS)
#define HERETIC_ECHO_VOICE_RANGE 7
#define HERETIC_ECHO_VOICE_MODE "Голос"
#define HERETIC_ECHO_NOISE_SCREAM "Крик"
#define HERETIC_ECHO_NOISE_GLASS "Звон стекла"
#define HERETIC_ECHO_NOISE_VOLUME 80
#define HERETIC_ECHO_HUSH_COOLDOWN (60 SECONDS)
#define HERETIC_ECHO_HUSH_MODE "Тишина"
#define HERETIC_ECHO_ETHER_SPELL_DELAY (1 SECONDS)
#define HERETIC_ECHO_HUSH_TRAIT "heretic_echo_hush"
#define HERETIC_ECHO_RESONATOR_COOLDOWN (8 SECONDS)

/datum/heretic_path/echo
	id = PATH_ECHO
	deed_type = /datum/heretic_deed/echo
	name = "Эхо"
	tagline = "Слушает станцию через интеркомы, усыпляет звенящих врагов и уходит в эфир."
	craft_summary = "Хватка по интеркому ставит прослушку: до 4 интеркомов передают вам речь рядом с пометкой отдела."
	capture_summary = "Хватка даёт звон, Колыбельная за 3 секунды усыпляет на 10 секунд; спящую сердце уводит в изнанку."
	escape_summary = "Уйти в эфир от своего интеркома к другому за 1,5 секунды, вдали от них - Тишина; из изнанки - к интеркому."
	strength_points = list(
		"До 4 интеркомов передают вам речь рядом, Чужой голос говорит из них любым именем.",
		"Звенящая хватка на 12 секунд глушит рацию цели.",
		"Колыбельная усыпляет на 10 секунд, а 3 секунды напева цель идёт на 40% медленнее.",
		"Засыпающую будит только удар другого существа от 10 урона: свой урон и выносливость не в счёт.",
		"Последний удар сразу бьёт всю область 5×5, повтор крестом достаёт дальше.",
		"Уйти в эфир уводит сквозь станцию от интеркома к интеркому за 1,5 секунды.",
	)
	weakness_points = list(
		"Прослушанный интерком повторяет слова с задержкой: отвёртка или нулевой жезл снимают прослушку.",
		"Колыбельную рвут сильный удар, 2 секунды растолкать и уход дальше 5 клеток, даже на руках.",
		"Выход из эфира выдаёт хрип динамика; без прослушанных интеркомов уйти некуда.",
		"Тишина длится 4 секунды и рвётся от атаки, заклинания и полученного урона.",
		"Сильный повтор бьёт по отмеченным клеткам: из них можно уйти, преграды гасят волну.",
		"Чужой голос звучит с пометкой «(сквозь помехи)» и не уходит в рацию.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_echo,
		/datum/eldritch_knowledge/echo_grasp,
		/datum/eldritch_knowledge/spell/echo_lullaby,
		/datum/eldritch_knowledge/echo_mark,
		/datum/eldritch_knowledge/echo_fork,
		/datum/eldritch_knowledge/spell/echo_voice,
		/datum/eldritch_knowledge/spell/echo_ether,
		/datum/eldritch_knowledge/echo_sustain,
		/datum/eldritch_knowledge/spell/echo_crescendo,
		/datum/eldritch_knowledge/final_eldritch/echo_final,
	)

/datum/eldritch_knowledge/base_echo
	name = "Звук за закрытой дверью"
	summary = "Последний удар бьёт по площади; Хватка по интеркому ставит прослушку."
	details = list(
		"Нож и металлический прут создают звенящий клинок.",
		"Последний удар за единицу: сразу вся область 5×5, затем повтор крестом до 3 клеток; стены гасят оба такта.",
		"Хватка по интеркому ставит прослушку: он передаёт вам обычную речь рядом с названием отдела.",
		"Радиопереговоры и ваша речь не передаются; оглохнув или потеряв сознание, вы не слышите.",
		"До 4 прослушек, новая вытесняет старую; смерть их не снимает; отдел засчитывается делу один раз.",
		"Экипаж видит, что динамик повторяет слова с задержкой; отвёртка или нулевой жезл снимают прослушку.",
		"Из изнанки выходите к своему интеркому.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "За дверью спели последнюю ноту. Она прозвучала снова, когда я перестал слушать."
	route = PATH_ECHO
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/rods)
	result_atoms = list(/obj/item/melee/sickly_blade/echo)
	combat_resource = 2
	combat_resource_name = "Резонанс"
	resource_rules = list(
		"Начальный запас 2 из 4; пустой запас восстанавливается до единицы за 8 секунд.",
		"Попадание клинком или волной даёт единицу раз в 6 секунд, Хватка - две, взрыв метки - одну.",
		"Последний удар, резонатор лиры и уход в эфир стоят единицу, Колыбельная - две.",
		"Крещендо расходует весь запас; Чужой голос и Тишина бесплатны.",
		"Смена тела сохраняет резонанс, но обрывает прежние волны; прослушки остаются.",
	)
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
	var/list/datum/status_effect/heretic_echo_lullaby/lullabies = list()
	var/list/datum/status_effect/heretic_echo_hush/hushes = list()
	/// Интеркомы с ремеслом «echo_tap», старейший первым.
	var/list/obj/item/radio/intercom/taps = list()
	var/last_relay_line
	var/last_relay_time
	var/echo_failure
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
	for(var/obj/item/radio/intercom/intercom as anything in taps.Copy())
		untap(intercom)
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
	QDEL_LIST(lullabies)
	QDEL_LIST(hushes)

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

/datum/eldritch_knowledge/base_echo/combat_resource_state()
	. = "Рисунок повторов: [diagonal_echo ? "диагонали" : "крест"]. Резонаторов: [length(resonators)] из [HERETIC_ECHO_RESONATOR_LIMIT]. Прослушек: [length(taps)] из [HERETIC_ECHO_TAP_LIMIT]."
	var/obj/structure/heretic_echo_resonator/conductor = conductor_ref?.resolve()
	. += conductor ? " Лира направляет поздние отзвуки через выбранный резонатор. Связь требует открытой линии в семи клетках." : " Выберите свой резонатор щелчком лиры: он повторит Крещендо и Последнюю службу."

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

/datum/eldritch_knowledge/base_echo/proc/tap(obj/item/radio/intercom/intercom, mob/living/user)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !can_use(user) || !istype(intercom) || QDELETED(intercom) || !isturf(intercom.loc))
		return FALSE
	if(intercom.GetComponent(/datum/component/heretic_craft))
		grasp_failure_reason = (intercom in taps) ? "Этот интерком уже слушает для вас: выберите другой." : "На этом интеркоме уже лежит чужое ремесло."
		return FALSE
	grasp_failure_reason = heretic.deed_wait_reason(heretic.deed_key_for(intercom))
	if(grasp_failure_reason)
		return FALSE
	while(length(taps) >= HERETIC_ECHO_TAP_LIMIT)
		var/obj/item/radio/intercom/oldest = taps[1]
		log_game("[key_name(user)] теряет прослушку Эха на [oldest] ([oldest.type]) в [AREACOORD(oldest)]: её вытеснила новая.")
		untap(oldest)
	intercom.AddComponent(/datum/component/heretic_craft, src, HERETIC_ECHO_TAP_CRAFT, HERETIC_ECHO_TAP_CLUE)
	taps += intercom
	RegisterSignal(intercom, COMSIG_MOVABLE_HEAR, PROC_REF(on_tap_hear))
	RegisterSignal(intercom, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_tap_tool))
	playsound(intercom, 'modular_bluemoon/sound/heretic/echo_cast.ogg', 35, TRUE)
	to_chat(user, span_eldritch("[intercom] теперь передаёт вам речь рядом с собой: [get_area_name(intercom, TRUE)]. Прослушек: [length(taps)] из [HERETIC_ECHO_TAP_LIMIT]."))
	log_game("[key_name(user)] ставит прослушку Эха на [intercom] ([intercom.type]) в [AREACOORD(intercom)].")
	heretic.advance_deed(heretic.deed_key_for(intercom), intercom)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/untap(obj/item/radio/intercom/intercom)
	if(!(intercom in taps))
		return
	taps -= intercom
	UnregisterSignal(intercom, list(COMSIG_MOVABLE_HEAR, COMSIG_ATOM_ITEM_INTERACTION))
	qdel(heretic_craft_on(intercom, HERETIC_ECHO_TAP_CRAFT))
	notify_resource_changed()

/datum/eldritch_knowledge/base_echo/on_craft_removed(atom/crafted, craft_id)
	if(craft_id == HERETIC_ECHO_TAP_CRAFT)
		untap(crafted)

/datum/eldritch_knowledge/base_echo/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/item/radio/intercom/intercom as anything in taps)
		heretic_add_pocket_exit(., "Интерком - [get_area_name(intercom, TRUE)]", heretic_pocket_landing(get_turf(intercom)))

/datum/eldritch_knowledge/base_echo/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в тишину", "text" = "Над [victim] обрывается беззвучная нота.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель спит от своей Колыбельной или готова к обряду у своего интеркома, еретик рядом с ней.
/datum/eldritch_knowledge/base_echo/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	if(knocked_out_by_capture(victim))
		return TRUE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic.hunt_target_ready(victim))
		return FALSE
	for(var/obj/item/radio/intercom/intercom as anything in taps)
		var/turf/place = get_turf(intercom)
		if(place?.z == victim.z && get_dist(place, victim) <= HERETIC_ECHO_TAP_DOOR_RANGE)
			return TRUE
	return FALSE

/// Интерком слышит и радио, которое сам транслирует: такое сообщение приходит с частотой и не пересказывается.
/datum/eldritch_knowledge/base_echo/proc/on_tap_hear(obj/item/radio/intercom/source, list/hearing_args)
	SIGNAL_HANDLER
	var/mob/living/listener = echo_body
	var/atom/movable/speaker = hearing_args[HEARING_SPEAKER]
	var/raw_message = hearing_args[HEARING_RAW_MESSAGE]
	var/datum/language/language = hearing_args[HEARING_LANGUAGE]
	if(hearing_args[HEARING_RADIO_FREQ] || !raw_message || QDELETED(listener) || listener.stat == DEAD || speaker == listener || istype(speaker, /atom/movable/virtualspeaker/heretic_echo))
		return
	if(language && initial(language.visual_language))
		return
	if(language && !listener.has_language(language))
		var/datum/language/dialect = GLOB.language_datum_instances[language]
		raw_message = dialect.scramble(raw_message)
	var/line = "[get_area_name(source, TRUE)]: [speaker.GetVoice()] [hearing_args[HEARING_MESSAGE_MODE] == MODE_WHISPER ? "шепчет" : "говорит"] «[raw_message]»"
	// Интерком передаёт одну реплику в Hear() дважды.
	if(line == last_relay_line && world.time == last_relay_time)
		return
	last_relay_line = line
	last_relay_time = world.time
	listener.show_message(span_eldritch(line), MSG_AUDIBLE)

/datum/eldritch_knowledge/base_echo/proc/on_tap_tool(obj/item/radio/intercom/source, mob/living/user, obj/item/tool, params)
	SIGNAL_HANDLER
	if(tool.tool_behaviour != TOOL_SCREWDRIVER)
		return NONE
	tool.play_tool_sound(source)
	user.visible_message(span_warning("[user] вскрывает [source] отвёрткой и вытряхивает из динамика чужой звон."), span_notice("Вы вскрываете [source]: в динамике дрожал чужой звон. Прослушка снята."))
	log_game("[key_name(user)] снимает прослушку Эха с [source] отвёрткой в [AREACOORD(source)].")
	untap(source)
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/datum/eldritch_knowledge/base_echo/proc/rung_by_me(mob/living/victim)
	var/datum/status_effect/heretic_echo_ringing/effect = victim?.has_status_effect(/datum/status_effect/heretic_echo_ringing)
	return effect?.echo_ref?.resolve() == src

/datum/eldritch_knowledge/base_echo/proc/lullaby_block_reason(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_lullaby)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_ECHO_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!isturf(victim.loc) || !line_clear(user, victim, HERETIC_ECHO_LULLABY_RANGE))
		return "Цель должна стоять не дальше пяти клеток по открытой линии."
	if(victim.has_status_effect(/datum/status_effect/heretic_echo_lullaby))
		return "Цель уже засыпает."
	if(!rung_by_me(victim))
		return "Колыбельная берёт только цель с вашим Остаточным звоном: сначала коснитесь её Хваткой или заденьте волной."
	if(combat_resource < HERETIC_ECHO_LULLABY_COST)
		return "Нужно [HERETIC_ECHO_LULLABY_COST] резонанса."
	return null

/datum/eldritch_knowledge/base_echo/proc/lullaby(mob/living/user, mob/living/victim)
	echo_failure = lullaby_block_reason(user, victim)
	if(echo_failure || !spend_combat_resource(HERETIC_ECHO_LULLABY_COST))
		return FALSE
	if(!victim.apply_status_effect(/datum/status_effect/heretic_echo_lullaby, src))
		gain_combat_resource(HERETIC_ECHO_LULLABY_COST)
		echo_failure = "Колыбельная не удержала цель."
		return FALSE
	playsound(victim, 'modular_bluemoon/sound/heretic/echo_grasp.ogg', 30, TRUE)
	log_combat(user, victim, "убаюкивает Колыбельной Эха")
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/voice_block_reason(mob/living/user, obj/item/radio/intercom/intercom)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_voice)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	if(QDELETED(intercom) || !(intercom in taps) || !isturf(intercom.loc))
		return "Нужен интерком с вашей прослушкой."
	return null

/// Невидимые символы и смена направления письма могли бы переставить пометку помех перед именем.
/proc/heretic_echo_has_format_chars(text)
	var/char = ""
	for(var/index = 1, index <= length(text), index += length(char))
		char = text[index]
		var/code = text2ascii(char)
		if((code >= 0x200B && code <= 0x200F) || (code >= 0x202A && code <= 0x202E) || (code >= 0x2066 && code <= 0x2069))
			return TRUE
	return FALSE

/datum/eldritch_knowledge/base_echo/proc/fake_voice(mob/living/user, obj/item/radio/intercom/intercom, voice_name, phrase)
	echo_failure = voice_block_reason(user, intercom)
	if(echo_failure)
		return FALSE
	if(!user.can_speak_basic("[phrase]"))
		echo_failure = "Сейчас вам нельзя говорить в игровом чате."
		return FALSE
	voice_name = reject_bad_text(trim("[voice_name]"), HERETIC_ECHO_VOICE_NAME_LEN, ascii_only = FALSE)
	if(!voice_name || CHAT_FILTER_CHECK(voice_name) || heretic_echo_has_format_chars(voice_name))
		echo_failure = "Имя не подходит: до [HERETIC_ECHO_VOICE_NAME_LEN] символов, без угловых скобок, косых черт, невидимых символов и запрещённых слов."
		return FALSE
	phrase = trim(copytext_char("[phrase]", 1, MAX_MESSAGE_LEN))
	if(!phrase)
		echo_failure = "Нечего сказать: фраза пуста."
		return FALSE
	if(CHAT_FILTER_CHECK(phrase))
		echo_failure = "Мансус не повторит эту фразу: в ней запрещённое слово."
		return FALSE
	voice_name = sanitize(voice_name)
	phrase = sanitize(phrase)
	var/atom/movable/virtualspeaker/heretic_echo/voice = new(null, intercom, null)
	voice.name = voice_name
	voice.send_speech(phrase, HERETIC_ECHO_VOICE_RANGE, intercom, spans = list(), message_language = /datum/language/common)
	qdel(voice)
	user.log_talk(phrase, LOG_SAY, tag = "чужой голос «[voice_name]» через [intercom] в [AREACOORD(intercom)]")
	user.log_message("говорит чужим голосом «[voice_name]» через [intercom] в [AREACOORD(intercom)]: [phrase]", LOG_GAME)
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/fake_noise(mob/living/user, obj/item/radio/intercom/intercom, noise)
	echo_failure = voice_block_reason(user, intercom)
	if(echo_failure)
		return FALSE
	var/noise_sound
	var/noise_text
	switch(noise)
		if(HERETIC_ECHO_NOISE_SCREAM)
			noise_sound = pick('sound/voice/scream/scream_m1.ogg', 'sound/voice/scream/scream_f1.ogg')
			noise_text = "Из динамика [intercom] рвётся истошный крик!"
		if(HERETIC_ECHO_NOISE_GLASS)
			noise_sound = SFX_SHATTER
			noise_text = "Из динамика [intercom] раздаётся звон бьющегося стекла!"
		else
			echo_failure = "Такого шума динамик не знает."
			return FALSE
	playsound(intercom, noise_sound, HERETIC_ECHO_NOISE_VOLUME, TRUE)
	intercom.visible_message(span_danger(noise_text), blind_message = span_danger(noise_text))
	user.log_message("поднимает шум «[noise]» в [intercom] в [AREACOORD(intercom)]", LOG_GAME)
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/hush(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_ether)
	echo_failure = heretic_containment_reason(user)
	if(echo_failure)
		return FALSE
	if(!can_use(user) || QDELETED(required))
		echo_failure = "Способность недоступна вашему пути или текущему телу."
		return FALSE
	if(user.has_status_effect(/datum/status_effect/heretic_echo_hush))
		echo_failure = "Тишина уже держится."
		return FALSE
	if(!user.apply_status_effect(/datum/status_effect/heretic_echo_hush, src))
		echo_failure = "Тишина не легла."
		return FALSE
	log_game("[key_name(user)] уходит в Тишину Эха в [AREACOORD(user)].")
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/adjacent_tap(mob/living/user)
	for(var/obj/item/radio/intercom/intercom as anything in taps)
		var/turf/place = get_turf(intercom)
		if(place?.z == user.z && get_dist(user, place) <= HERETIC_ECHO_ETHER_REACH)
			return intercom
	return null

/// Свои интеркомы на уровне еретика, кроме того, у которого он стоит: подпись -> интерком.
/datum/eldritch_knowledge/base_echo/proc/ether_choices(mob/living/user)
	. = list()
	var/obj/item/radio/intercom/from_tap = adjacent_tap(user)
	if(!from_tap)
		return
	for(var/obj/item/radio/intercom/intercom as anything in taps)
		var/turf/place = get_turf(intercom)
		if(intercom != from_tap && place?.z == user.z)
			.[heretic_unique_label(., "Интерком - [get_area_name(intercom, TRUE)]")] = intercom

/datum/eldritch_knowledge/base_echo/proc/ether_exit(obj/item/radio/intercom/to_tap)
	var/turf/center = get_turf(to_tap)
	if(!center || isgroundlessturf(center))
		return null
	if(isopenturf(center) && !center.is_blocked_turf(exclude_mobs = TRUE))
		return center
	for(var/turf/open/tile in RANGE_TURFS(HERETIC_ECHO_ETHER_REACH, center))
		if(tile != center && !isgroundlessturf(tile) && !tile.is_blocked_turf(exclude_mobs = TRUE) && heretic_step_open(center, tile))
			return tile
	return null

/datum/eldritch_knowledge/base_echo/proc/ether_failure(mob/living/user, obj/item/radio/intercom/from_tap, obj/item/radio/intercom/to_tap)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/echo_ether)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/turf/entry = get_turf(from_tap)
	if(!(from_tap in taps) || entry?.z != user.z || get_dist(user, entry) > HERETIC_ECHO_ETHER_REACH)
		return "Встаньте вплотную к своему интеркому."
	if(!(to_tap in taps) || to_tap == from_tap)
		return "Выйти можно только из другого своего интеркома."
	var/turf/exit_place = get_turf(to_tap)
	if(exit_place?.z != user.z)
		return "Этот интерком на другом уровне: эфир ведёт только к интеркомам на вашем уровне."
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Вас что-то держит на месте: в эфир не уйти."
	var/turf/exit = ether_exit(to_tap)
	if(!exit)
		return "У того интеркома некуда выйти: все клетки рядом заняты."
	var/area/origin_area = get_area(user)
	var/area/exit_area = get_area(exit)
	if((origin_area.area_flags & NOTELEPORT) || (exit_area.area_flags & NOTELEPORT))
		return "Эфир здесь глух: вход или выход в зоне, закрытой для телепортации."
	if(combat_resource < HERETIC_ECHO_ETHER_COST)
		return "Нужна [HERETIC_ECHO_ETHER_COST] единица резонанса."
	return null

/datum/eldritch_knowledge/base_echo/proc/ether_ready(mob/living/user, obj/item/radio/intercom/from_tap, obj/item/radio/intercom/to_tap)
	return !ether_failure(user, from_tap, to_tap)

/// Уход в эфир: полторы секунды у своего интеркома, выход из другого своего, и его динамик хрипит.
/datum/eldritch_knowledge/base_echo/proc/ether(mob/living/user, obj/item/radio/intercom/from_tap, obj/item/radio/intercom/to_tap)
	echo_failure = ether_failure(user, from_tap, to_tap)
	if(echo_failure)
		return FALSE
	user.visible_message(span_warning("[user] прижимается к [from_tap], и его очертания рассыпаются в шум."), span_notice("Вы уходите в эфир."))
	playsound(from_tap, 'sound/misc/interference.ogg', 40, TRUE)
	if(!do_after(user, HERETIC_ECHO_ETHER_TIME, target = from_tap, extra_checks = CALLBACK(src, PROC_REF(ether_ready), user, from_tap, to_tap)))
		echo_failure = ether_failure(user, from_tap, to_tap) || "Уход в эфир прерван: полторы секунды стойте у интеркома неподвижно."
		return FALSE
	echo_failure = ether_failure(user, from_tap, to_tap)
	if(echo_failure || !spend_combat_resource(HERETIC_ECHO_ETHER_COST))
		return FALSE
	var/turf/origin = get_turf(user)
	var/turf/exit = ether_exit(to_tap)
	if(!do_teleport(user, exit, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != exit)
		gain_combat_resource(HERETIC_ECHO_ETHER_COST)
		echo_failure = "Эфир не вынес вас: у выхода что-то мешает."
		return FALSE
	playsound(to_tap, 'sound/misc/interference.ogg', 60, TRUE)
	to_tap.audible_message(span_warning("[to_tap] хрипит помехами."))
	log_game("[key_name(user)] уходит в эфир Эха из [AREACOORD(origin)] к [to_tap] в [AREACOORD(exit)].")
	return TRUE

/datum/eldritch_knowledge/base_echo/proc/create_resonator(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/echo_fork)
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
	desc = "Три латунные трубы поют чужими голосами. Повторяют Последний удар хозяина с полным уроном. Разбейте резонатор или коснитесь его нулевым жезлом, чтобы оборвать повтор."
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
	RegisterSignal(owner, COMSIG_MOVABLE_USING_RADIO, PROC_REF(jam_radio))
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_echo_ringing/proc/update_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += ringing_overlay

/datum/status_effect/heretic_echo_ringing/proc/jam_radio(atom/movable/source, obj/item/radio/radio)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(echo?.echo_body)
	if(!heretic?.get_knowledge(/datum/eldritch_knowledge/echo_grasp))
		return NONE
	// Интерком с микрофоном рядом слышит одну реплику дважды: жалуемся только на свою рацию.
	if(get_atom_on_turf(radio) == owner)
		owner.show_message(span_warning("В ушах звенит так, что [radio] не слышит вашего голоса."))
	return COMPONENT_CANNOT_USE_RADIO

/datum/status_effect/heretic_echo_ringing/on_remove()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	echo?.ringing.Remove(src)
	UnregisterSignal(owner, list(COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_MOVABLE_USING_RADIO))
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
	desc = "Чужая нота держится за ваше тело: рация может не услышать вашего голоса, тогда говорите вслух. Еретик может усыпить звенящую цель Колыбельной - держитесь от него дальше пяти клеток. Второе попадание одной последовательности на 1,5 секунды блокирует стрельбу и удары предметами: уходите с отмеченного пола. Звон исчезнет через 12 секунд после последнего попадания магии."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "echo_ring_note"

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
	icon_state = "echo_concussion"

/datum/status_effect/heretic_echo_lullaby
	id = "heretic_echo_lullaby"
	duration = HERETIC_ECHO_LULLABY_DROWSE
	tick_interval = HERETIC_ECHO_LULLABY_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_echo_lullaby
	examine_text = span_warning("SUBJECTPRONOUN клюёт носом, над головой дрожит бледная нота. Разбудите сильным ударом, растолкайте или уведите (унесите) дальше пяти клеток от поющего.")
	var/datum/weakref/echo_ref
	var/mob/living/singer
	var/mutable_appearance/note
	var/applied = FALSE
	var/interrupted = FALSE
	var/foreign_hit_at = -1

/datum/status_effect/heretic_echo_lullaby/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_echo/echo)
	echo_ref = WEAKREF(echo)
	singer = echo?.echo_body
	return ..()

/datum/status_effect/heretic_echo_lullaby/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(!. || !echo || QDELETED(singer))
		return FALSE
	applied = TRUE
	echo.lullabies += src
	note = mutable_appearance('modular_bluemoon/icons/obj/heretic_echo_effects.dmi', "echo_mark", ABOVE_MOB_LAYER)
	note.color = HERETIC_ECHO_LULLABY_COLOR
	note.pixel_y = HERETIC_ECHO_LULLABY_NOTE_OFFSET
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_overlay))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_distance))
	RegisterSignal(singer, COMSIG_MOVABLE_MOVED, PROC_REF(check_distance))
	RegisterSignal(singer, COMSIG_PARENT_QDELETING, PROC_REF(wake))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice_starting))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(wake))
	RegisterSignal(owner, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_attacker_set))
	RegisterSignal(owner, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_bullet))
	RegisterSignal(owner, COMSIG_ATOM_HITBY, PROC_REF(on_hitby))
	heretic_capture_hold(owner, HERETIC_ECHO_CAPTURE)
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/heretic_echo_lullaby, multiplicative_slowdown = owner.movement_delay() * (1 / (1 - HERETIC_ECHO_LULLABY_SLOWDOWN) - 1))
	owner.update_icon()
	owner.blur_eyes(HERETIC_ECHO_LULLABY_BLUR)
	owner.visible_message(span_warning("[owner] клюёт носом, над головой дрожит бледная нота."), span_userdanger("Веки тяжелеют, в ушах звучит колыбельная. Уйдите от поющего дальше пяти клеток, иначе уснёте!"))
	return TRUE

/datum/status_effect/heretic_echo_lullaby/proc/update_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += note

/// Будит только сильный удар другого существа: удар в ближнем бою называет нападавшего до урона, пуля и бросок несут урон с собой.
/datum/status_effect/heretic_echo_lullaby/proc/on_damage(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	var/struck = foreign_hit_at == world.time
	foreign_hit_at = -1
	if(struck && heavy_hit(damage, damagetype))
		wake()

/datum/status_effect/heretic_echo_lullaby/proc/heavy_hit(damage, damagetype)
	return damage >= HERETIC_ECHO_LULLABY_WAKE_DAMAGE && damagetype != STAMINA

/datum/status_effect/heretic_echo_lullaby/proc/on_attacker_set(datum/source, mob/attacker)
	SIGNAL_HANDLER
	if(attacker && attacker != owner)
		foreign_hit_at = world.time

/datum/status_effect/heretic_echo_lullaby/proc/on_bullet(datum/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	if(projectile?.firer && projectile.firer != owner && !projectile.nodamage && heavy_hit(projectile.damage, projectile.damage_type))
		wake()

/datum/status_effect/heretic_echo_lullaby/proc/on_hitby(datum/source, atom/movable/hitting_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	var/obj/item/thrown = hitting_atom
	if(istype(thrown) && throwingdatum?.thrower && throwingdatum.thrower != owner && heavy_hit(thrown.throwforce, thrown.damtype))
		wake()

/datum/status_effect/heretic_echo_lullaby/tick()
	check_distance()

/datum/status_effect/heretic_echo_lullaby/proc/check_distance(datum/source)
	SIGNAL_HANDLER
	if(!singer_near())
		wake()

/// По клеткам, а не по самим мобам: цель в шкафу или на руках уносят без её собственного шага.
/datum/status_effect/heretic_echo_lullaby/proc/singer_near()
	var/turf/singer_turf = get_turf(singer)
	var/turf/owner_turf = get_turf(owner)
	return singer_turf && owner_turf && singer_turf.z == owner_turf.z && get_dist(singer_turf, owner_turf) <= HERETIC_ECHO_LULLABY_RANGE

/datum/status_effect/heretic_echo_lullaby/proc/wake()
	SIGNAL_HANDLER
	if(QDELETED(src))
		return
	interrupted = TRUE
	owner.visible_message(span_notice("[owner] вздрагивает и стряхивает дремоту."), span_notice("Вы вздрагиваете, и колыбельная обрывается."))
	qdel(src)

/datum/status_effect/heretic_echo_lullaby/proc/on_sacrifice_starting(datum/source)
	SIGNAL_HANDLER
	interrupted = TRUE
	qdel(src)

/datum/status_effect/heretic_echo_lullaby/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_MOB_APPLY_DAMAGE, COMSIG_MOVABLE_MOVED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_ATTACKER_SET, COMSIG_ATOM_BULLET_ACT, COMSIG_ATOM_HITBY))
		heretic_capture_unhold(owner, HERETIC_ECHO_CAPTURE)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_echo_lullaby)
		if(singer)
			UnregisterSignal(singer, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
		owner.update_icon()
		var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
		echo?.lullabies -= src
		// Истёкший срок без срыва отличает досмотренную колыбельную от прерванной.
		var/fell_asleep = !interrupted && echo && world.time >= duration && owner.stat != DEAD && singer_near()
		if(fell_asleep)
			owner.Sleeping(HERETIC_ECHO_LULLABY_SLEEP)
			heretic_capture_knock_out(owner, echo, HERETIC_ECHO_CAPTURE, HERETIC_ECHO_LULLABY_SLEEP)
			owner.visible_message(span_warning("[owner] засыпает под колыбельную, которой никто не пел."), span_userdanger("Колыбельная дотягивает последнюю ноту, и вы засыпаете."))
		heretic_capture_release(owner, HERETIC_ECHO_CAPTURE, fell_asleep ? HERETIC_ECHO_LULLABY_SLEEP : 0)
	singer = null
	note = null
	echo_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_echo_lullaby
	name = "Колыбельная"
	desc = "Веки тяжелеют, ноги идут на 40% медленнее. Через 3 секунды вы уснёте на 10 секунд. Уйдите от поющего дальше пяти клеток; разбудит и сильный удар или тот, кто растолкает вас 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "echo_drowse"

/datum/movespeed_modifier/heretic_echo_lullaby
	variable = TRUE

/datum/status_effect/heretic_echo_hush
	id = "heretic_echo_hush"
	duration = HERETIC_ECHO_HUSH_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_echo_hush
	var/datum/weakref/echo_ref
	var/applied = FALSE
	var/previous_alpha

/datum/status_effect/heretic_echo_hush/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_echo/echo)
	echo_ref = WEAKREF(echo)
	return ..()

/datum/status_effect/heretic_echo_hush/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
	if(!. || !echo)
		return FALSE
	applied = TRUE
	echo.hushes += src
	previous_alpha = owner.alpha
	owner.alpha = HERETIC_ECHO_HUSH_ALPHA
	ADD_TRAIT(owner, TRAIT_SILENT_STEP, HERETIC_ECHO_HUSH_TRAIT)
	RegisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_CAST_SPELL, COMSIG_MOB_THROW, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER), PROC_REF(break_hush))
	RegisterSignal(owner, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_unarmed))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage))
	owner.visible_message(span_warning("[owner] бледнеет и тает в воздухе, как звук, который перестали слушать."), span_notice("Тишина смыкается вокруг вас: вы почти невидимы, шагов не слышно. Атака, заклинание или рана разорвут её."))
	return TRUE

/datum/status_effect/heretic_echo_hush/proc/on_unarmed(datum/source, atom/target)
	SIGNAL_HANDLER
	if(isliving(target) && target != owner && owner.a_intent != INTENT_HELP)
		break_hush()

/datum/status_effect/heretic_echo_hush/proc/on_damage(datum/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		break_hush()

/datum/status_effect/heretic_echo_hush/proc/break_hush()
	SIGNAL_HANDLER
	if(!QDELETED(src))
		qdel(src)

/datum/status_effect/heretic_echo_hush/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_CAST_SPELL, COMSIG_MOB_THROW, COMSIG_MOB_ATTACK_RANGED, COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_MOB_APPLY_DAMAGE))
		REMOVE_TRAIT(owner, TRAIT_SILENT_STEP, HERETIC_ECHO_HUSH_TRAIT)
		// Прозрачность, изменённая кем-то другим во время Тишины, остаётся как есть.
		if(owner.alpha == HERETIC_ECHO_HUSH_ALPHA)
			owner.alpha = previous_alpha
		var/datum/eldritch_knowledge/base_echo/echo = echo_ref?.resolve()
		echo?.hushes -= src
		to_chat(owner, span_notice("Тишина рассеивается: вас снова видно и слышно."))
	echo_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_echo_hush
	name = "Тишина"
	desc = "Вы почти невидимы, шагов не слышно. Любая ваша атака, заклинание или полученный урон разорвут Тишину."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "echo_hush"

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
	desc = "Ручная лира на колоколе-резонаторе. Щелчок лирой по полу в намерении «Помощь» в пяти клетках по открытой линии ставит резонатор за единицу резонанса: он повторяет Последний удар с полным уроном, живёт 30 секунд, держит 35 прочности; резонаторов не больше двух, новый - раз в 8 секунд. Применение в руке меняет крест и диагонали повторов Последнего удара. Alt-клик готовит удержание следующего повтора на 3 секунды, следующий Alt-клик выпускает его раньше. Голубой рисунок показывает удержанный звук; перед ударом он снова предупреждает за 0,8 секунды. Удержанный повтор не продолжает диссонанс первого удара. Настройка доступна раз в 10 секунд. Щёлкните лирой по своему резонатору в семи клетках: Крещендо и Последняя служба повторят вокруг него весь рисунок. Повторный щелчок снимает выбор. Нужна открытая линия к резонатору; пересечения одного такта не умножают урон."
	icon = 'modular_bluemoon/icons/obj/heretic_echo.dmi'
	icon_state = "echo_fork"
	COOLDOWN_DECLARE(resonator_cooldown)

/obj/item/heretic_path_relic/echo_fork/attack_self(mob/living/user)
	return retune(user)

/obj/item/heretic_path_relic/echo_fork/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(isturf(target) && user.a_intent == INTENT_HELP)
		return place_resonator(user, target)
	if(!istype(target, /obj/structure/heretic_echo_resonator))
		return
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

/obj/item/heretic_path_relic/echo_fork/proc/place_resonator(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!authorized(user) || !echo?.can_use(user))
		return FALSE
	if(!COOLDOWN_FINISHED(src, resonator_cooldown))
		to_chat(user, span_warning("Струны ещё дрожат: новый резонатор через [DisplayTimeText(COOLDOWN_TIMELEFT(src, resonator_cooldown))]."))
		return FALSE
	if(!echo.create_resonator(user, place))
		to_chat(user, span_warning("Резонатор не встаёт: нужен свободный пол в пяти клетках по открытой линии, единица резонанса и не больше двух резонаторов."))
		return FALSE
	COOLDOWN_START(src, resonator_cooldown, HERETIC_ECHO_RESONATOR_COOLDOWN)
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
	to_chat(user, span_eldritch("Следующий повтор Последнего удара задержится на 3 секунды. Alt-клик по лире отпустит его раньше; перед ударом прозвучит обычное предупреждение."))
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
	if(!proximity_flag || !istype(target, /obj/item/radio/intercom))
		return FALSE
	return tap(target, user)

/datum/eldritch_knowledge/echo_grasp
	name = "Звенящая хватка"
	summary = "Хватка оставляет Остаточный звон на 12 секунд: рация цели молчит."
	details = list(
		"Голос звенящей цели слышен только рядом, по рации он не уходит.",
		"Звенящую цель можно усыпить Колыбельной.",
		"Даёт 2 резонанса раз в 6 секунд; антимагия и союзники ресурса не дают.",
	)
	role = HERETIC_ROLE_GRASP
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

/datum/eldritch_knowledge/spell/echo_lullaby
	name = "Колыбельная"
	summary = "За 2 резонанса звенящая цель в 5 клетках через 3 секунды засыпает на 10 секунд."
	details = list(
		"Нужен ваш Остаточный звон на цели и открытая линия до 5 клеток.",
		"3 секунды напева: зрение плывёт, шаг на 40% медленнее.",
		"Будят удар другого существа от 10 урона, 2 секунды растолкать и уход дальше 5 клеток, даже на руках.",
		"Свой урон цели, урон выносливости и клик «Помощи» не будят.",
		"Спящая готова к обряду; сердце уводит её в изнанку, как и готовую цель в 3 клетках от прослушки.",
		"Антимагия защищает; потом цель минуту невосприимчива, к любому захвату - 15 секунд. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Я пел, пока звон не стал тишиной, а тишина - сном."
	cost = 1
	route = PATH_ECHO
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_echo/lullaby

/datum/eldritch_knowledge/echo_mark
	name = "Метка Эха"
	summary = "Хватка ставит метку на 15 секунд, удар клинком её взрывает повтором крестом."
	details = list(
		"Взрыв возвращает единицу резонанса и отмечает крест вокруг цели.",
		"Через 0,8 секунды повтор: 20 ушибов и 20 выносливости; из креста можно выйти.",
		"Метка оставляет Остаточный звон на 12 секунд.",
	)
	role = HERETIC_ROLE_MARK
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
	summary = "Лист золота и прут дают лиру: резонаторы расширяют Последний удар, лира меняет рисунок."
	details = list(
		"Щелчок лирой по полу в «Помощи» в 5 клетках ставит резонатор за единицу: 30 секунд, 35 прочности.",
		"Резонатор повторяет Последний удар с полным уроном; их не больше двух, новый раз в 8 секунд.",
		"Связь с резонатором - в 7 клетках без преград; нулевой жезл его разрушает, свой убирается рукой.",
		"Применение в руке переключает крест и диагонали повторов, раз в 10 секунд.",
		"Alt-клик держит следующий повтор до 3 секунд голубым рисунком на прежних клетках, повторный выпускает его.",
		"Щелчок по своему резонатору: Крещендо и Последняя служба повторят рисунок вокруг него.",
		"Настройка и удержание резонанс не тратят; лира одна, пересечения одного такта не умножают урон.",
	)
	role = HERETIC_ROLE_RELIC
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

/datum/eldritch_knowledge/spell/echo_voice
	name = "Чужой голос"
	summary = "Из интеркома с прослушкой звучит фраза чужим голосом, крик или звон стекла."
	details = list(
		"«Голос»: имя до 26 символов и фраза, её слышно вслух рядом с интеркомом.",
		"У имени пометка «(сквозь помехи)», по рации голос не уходит.",
		"«Крик» и «Звон стекла» поднимают громкий шум у динамика.",
		"Бесплатно, перезарядка 20 секунд.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Я заговорил, и динамик ответил голосом, которого у меня никогда не было."
	cost = 2
	route = PATH_ECHO
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_echo/voice

/datum/eldritch_knowledge/spell/echo_ether
	name = "Уйти в эфир"
	summary = "От своего интеркома к другому своему на уровне за 1,5 секунды; вдали от них - Тишина."
	details = list(
		"Встаньте вплотную к своему интеркому и выберите другой свой интерком на этом уровне.",
		"Через 1,5 секунды вы выходите у него, его динамик хрипит помехами. Единица резонанса, перезарядка 45 секунд.",
		"Второй режим - Тишина: 4 секунды почти невидимы и беззвучны; бесплатно, перезарядка 60 секунд.",
		"У эфира и Тишины свои перезарядки: после одного режима другой готов сразу.",
		"Вдали от своего интеркома способность сразу включает Тишину.",
		"Тишину рвут атака, заклинание и полученный урон.",
		"Наручники, щит разума и зоны без телепортации не пускают; снятая прослушка закрывает выход.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Последняя нота угасла, и вместе с ней угас я."
	cost = 1
	route = PATH_ECHO
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_echo/ether

/datum/eldritch_knowledge/echo_sustain
	name = "Долгое послезвучие"
	summary = "Запас резонанса растёт до 5."
	details = list(
		"Улучшения: 6 и 7, вознесение - 8.",
		"Само знание резонанс не создаёт.",
	)
	role = HERETIC_ROLE_PASSIVE
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
	summary = "Весь резонанс уходит в три рисунка вокруг точки: крест, диагонали и кольцо радиусом 3."
	details = list(
		"Каждый рисунок предупреждает за 0,8 секунды; между ними можно уклониться.",
		"Такт: по 18 ушибов и выносливости плюс по 2 за единицу резонанса, при запасе 4 - по 26.",
		"Каждый поражённый получает Остаточный звон на 12 секунд.",
		"Повторное попадание одной последовательности на 1,5 секунды блокирует стрельбу и удары предметами.",
		"Нужно не меньше 2 резонанса, перезарядка 40 секунд.",
		"Выбранный лирой резонатор в 7 клетках повторяет рисунок; его разрушение отменяет повторы.",
	)
	role = HERETIC_ROLE_ATTACK
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
	summary = "Попадания по вам отвечают звуковым крестом, запас растёт, открывается Последняя служба."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место обряда, он длится 30 секунд.",
		"Общая стойкость вознесения, запас резонанса 8, единица каждые 8 секунд, пока вы можете действовать.",
		"Отзвук: попадание больше чем на 5 здоровья не чаще раза в 2 секунды ставит крест в 3 клетки вокруг вас.",
		"Через 0,8 секунды крест бьёт на 15 ушибов и 15 выносливости и оставляет звон; стены его глушат.",
		"Последняя служба: три волны вокруг прежней позиции, каждая 32 ушиба и 35 выносливости, предупреждение 0,8 секунды.",
		"Соседние волны перекрываются: цель в 1-2 клетках от центра задевают две. Перезарядка 35 секунд.",
		"Выбранный лирой резонатор повторяет рисунок; пересечения не усиливают один такт.",
	)
	role = HERETIC_ROLE_ASCENSION
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
	desc = "За единицу резонанса сразу бьёт область 5×5: 12 ушибов и 10 выносливости; через 0,8 секунды отмеченный крест в 3 клетки - 24 ушиба и 25 выносливости. Из креста можно уйти, два попадания на 1,5 секунды блокируют стрельбу и удары предметами."
	summary = "Сразу 12 ушибов по области 5×5, через 0,8 секунды крест: 24 ушиба и 25 выносливости."
	charge_max = 12 SECONDS
	action_icon_state = "echo_release"

/obj/effect/proc_holder/spell/self/heretic_echo/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!echo?.release(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_echo/final
	name = "Последняя служба"
	desc = "Вокруг прежней позиции расходятся три волны шириной в две клетки; каждая предупреждает за 0,8 секунды и наносит 32 ушиба и 35 урона выносливости. Не расходует резонанс, требует вознесения."
	summary = "Три волны вокруг прежней позиции по 32 ушиба и 35 выносливости, без резонанса."
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

/obj/effect/proc_holder/spell/pointed/heretic_echo/lullaby
	name = "Колыбельная"
	desc = "Цель с вашим Остаточным звоном в 5 клетках 3 секунды клюёт носом и идёт на 40% медленнее, затем засыпает на 10 секунд. Будят удар другого существа от 10 урона, 2 секунды растолкать и уход дальше 5 клеток; 2 резонанса."
	summary = "Звенящая цель в 5 клетках через 3 секунды засыпает на 10 секунд; 2 резонанса."
	charge_max = HERETIC_ECHO_LULLABY_COOLDOWN
	range = HERETIC_ECHO_LULLABY_RANGE
	aim_assist = TRUE
	action_icon_state = "echo_lullaby"
	active_msg = "Укажите звенящую цель."

/obj/effect/proc_holder/spell/pointed/heretic_echo/lullaby/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!heretic_check(user, echo, silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = echo.lullaby_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_echo/lullaby/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.lullaby(user, targets[1]))
		heretic_revert_cast(user, echo?.echo_failure)

/obj/effect/proc_holder/spell/self/heretic_echo/voice
	name = "Чужой голос"
	desc = "Интерком со своей прослушкой бесплатно произносит вслух фразу от имени до 26 символов с пометкой «(сквозь помехи)», по рации голос не уходит. Режимы «Крик» и «Звон стекла» поднимают в динамике громкий шум."
	summary = "Фраза чужим голосом, крик или звон стекла из вашего интеркома."
	charge_max = HERETIC_ECHO_VOICE_COOLDOWN
	action_icon_state = "echo_voice"

/obj/effect/proc_holder/spell/self/heretic_echo/voice/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(echo?.taps))
		heretic_revert_cast(user, "Нужна прослушка: сначала коснитесь интеркома Хваткой Мансуса.")
		return
	var/list/choices = list()
	for(var/obj/item/radio/intercom/intercom as anything in echo.taps)
		choices["[length(choices) + 1]. [get_area_name(intercom, TRUE)]"] = intercom
	var/choice = length(choices) == 1 ? choices[1] : tgui_input_list(user, "Через какой интерком звучать?", name, choices)
	if(QDELETED(src))
		return
	if(!(choice in choices))
		heretic_revert_cast(user, "Отменено: интерком не выбран.")
		return
	var/obj/item/radio/intercom/intercom = choices[choice]
	var/mode = tgui_input_list(user, "Что прозвучит из динамика?", name, list(HERETIC_ECHO_VOICE_MODE, HERETIC_ECHO_NOISE_SCREAM, HERETIC_ECHO_NOISE_GLASS))
	if(QDELETED(src))
		return
	if(!mode)
		heretic_revert_cast(user, "Отменено: режим не выбран.")
		return
	if(mode != HERETIC_ECHO_VOICE_MODE)
		if(QDELETED(echo) || !echo.fake_noise(user, intercom, mode))
			heretic_revert_cast(user, echo?.echo_failure)
		return
	var/voice_name = tgui_input_text(user, "Чьим голосом говорить? До [HERETIC_ECHO_VOICE_NAME_LEN] символов.", name, max_length = HERETIC_ECHO_VOICE_NAME_LEN)
	if(QDELETED(src))
		return
	if(!voice_name)
		heretic_revert_cast(user, "Отменено: имя не введено.")
		return
	var/phrase = tgui_input_text(user, "Что сказать? Слушатели увидят у имени пометку «(сквозь помехи)».", name, max_length = MAX_MESSAGE_LEN)
	if(QDELETED(src))
		return
	if(!phrase)
		heretic_revert_cast(user, "Отменено: фраза не введена.")
		return
	if(QDELETED(echo) || !echo.fake_voice(user, intercom, voice_name, phrase))
		heretic_revert_cast(user, echo?.echo_failure)

/obj/effect/proc_holder/spell/self/heretic_echo/ether
	name = "Уйти в эфир"
	desc = "Вплотную к своему интеркому выберите другой свой интерком на этом уровне: через 1,5 секунды вы выходите у него, а его динамик хрипит; единица резонанса, своя перезарядка 45 секунд. Вдали от интеркома или по выбору - Тишина на 4 секунды со своей перезарядкой 60 секунд."
	summary = "От своего интеркома к другому за 1,5 секунды или Тишина на 4 секунды; у режимов свои перезарядки."
	charge_max = HERETIC_ECHO_ETHER_SPELL_DELAY
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "echo_ether"
	var/channeling = FALSE
	COOLDOWN_DECLARE(ether_cooldown)
	COOLDOWN_DECLARE(hush_cooldown)

/obj/effect/proc_holder/spell/self/heretic_echo/ether/proc/choose_exit(mob/living/user, list/choices)
	return tgui_input_list(user, "Из какого интеркома выйти?", name, choices)

/obj/effect/proc_holder/spell/self/heretic_echo/ether/proc/wait_reason()
	. = "Тишина восстановится через [heretic_capture_seconds_left(hush_cooldown)] с."
	if(!COOLDOWN_FINISHED(src, ether_cooldown))
		. += " Эфир - через [heretic_capture_seconds_left(ether_cooldown)] с."

/// У эфира и Тишины свои перезарядки: предлагаются только готовые режимы.
/obj/effect/proc_holder/spell/self/heretic_echo/ether/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!echo)
		heretic_revert_cast(user)
		return
	if(channeling)
		heretic_revert_cast(user, "Уход в эфир уже идёт.")
		return
	var/obj/item/radio/intercom/from_tap = echo.adjacent_tap(user)
	var/list/exits = COOLDOWN_FINISHED(src, ether_cooldown) ? echo.ether_choices(user) : list()
	var/hush_ready = COOLDOWN_FINISHED(src, hush_cooldown)
	var/choice = HERETIC_ECHO_HUSH_MODE
	if(length(exits))
		var/list/choices = exits.Copy()
		if(hush_ready)
			choices += HERETIC_ECHO_HUSH_MODE
		choice = choose_exit(user, choices)
		if(QDELETED(src))
			return
		if(!(choice in choices))
			heretic_revert_cast(user, "Уход отменён: выход не выбран.")
			return
	else if(!hush_ready)
		heretic_revert_cast(user, wait_reason())
		return
	if(choice == HERETIC_ECHO_HUSH_MODE)
		if(QDELETED(echo) || !echo.hush(user))
			heretic_revert_cast(user, echo?.echo_failure)
			return
		COOLDOWN_START(src, hush_cooldown, HERETIC_ECHO_HUSH_COOLDOWN)
		return
	channeling = TRUE
	var/escaped = !QDELETED(echo) && echo.ether(user, from_tap, exits[choice])
	channeling = FALSE
	if(!escaped)
		heretic_revert_cast(user, echo?.echo_failure)
		return
	COOLDOWN_START(src, ether_cooldown, HERETIC_ECHO_ETHER_COOLDOWN)

/obj/effect/proc_holder/spell/pointed/heretic_echo/crescendo
	name = "Крещендо"
	desc = "Весь резонанс, минимум 2: вокруг точки звучат крест, диагонали и кольцо радиусом 3, каждый с предупреждением 0,8 секунды и уроном 18 + 2 за единицу. Поражённые получают Остаточный звон, повторное попадание на 1,5 секунды блокирует стрельбу."
	summary = "Весь резонанс уходит в крест, диагонали и кольцо вокруг точки."
	charge_max = 40 SECONDS
	action_icon_state = "echo_crescendo"

/obj/effect/proc_holder/spell/pointed/heretic_echo/crescendo/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_echo/echo = heretic?.get_knowledge(/datum/eldritch_knowledge/base_echo)
	if(!length(targets) || !echo?.crescendo(user, get_turf(targets[1])))
		heretic_revert_cast(user)

/// Голос из интеркома: радио его не подхватывает, у имени пометка помех.
/atom/movable/virtualspeaker/heretic_echo
	name = "distant voice"

/atom/movable/virtualspeaker/heretic_echo/get_alt_name()
	return " (сквозь помехи)"

/atom/movable/virtualspeaker/heretic_echo/IsVocal()
	return FALSE

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
#undef HERETIC_ECHO_CRESCENDO_RADIUS
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
#undef HERETIC_ECHO_TAP_CRAFT
#undef HERETIC_ECHO_TAP_CLUE
#undef HERETIC_ECHO_CAPTURE
#undef HERETIC_ECHO_LULLABY_RANGE
#undef HERETIC_ECHO_LULLABY_CHECK
#undef HERETIC_ECHO_LULLABY_COST
#undef HERETIC_ECHO_LULLABY_COOLDOWN
#undef HERETIC_ECHO_LULLABY_BLUR
#undef HERETIC_ECHO_LULLABY_COLOR
#undef HERETIC_ECHO_LULLABY_NOTE_OFFSET
#undef HERETIC_ECHO_VOICE_COOLDOWN
#undef HERETIC_ECHO_VOICE_RANGE
#undef HERETIC_ECHO_VOICE_MODE
#undef HERETIC_ECHO_NOISE_SCREAM
#undef HERETIC_ECHO_NOISE_GLASS
#undef HERETIC_ECHO_NOISE_VOLUME
#undef HERETIC_ECHO_HUSH_COOLDOWN
#undef HERETIC_ECHO_HUSH_MODE
#undef HERETIC_ECHO_ETHER_SPELL_DELAY
#undef HERETIC_ECHO_HUSH_TRAIT
#undef HERETIC_ECHO_RESONATOR_COOLDOWN
