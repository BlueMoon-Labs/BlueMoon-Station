/obj/machinery/quantum_server
	name = "quantum server"

	circuit = /obj/item/circuitboard/machine/quantum_server
	density = TRUE
	desc = "Громоздкая вычислительная машина, предназначенная для создания виртуальных доменов."
	icon = 'icons/obj/machines/bitrunning.dmi'
	base_icon_state = "qserver"
	icon_state = "qserver"
	var/capacitor_coefficient = 1
	var/datum/lazy_template/virtual_domain/generated_domain
	var/domain_randomized = FALSE
	var/is_ready = TRUE
	var/glitch_chance = 0.2
	var/list/datum/weakref/avatar_connection_refs = list()
	var/list/datum/weakref/mutation_candidate_refs = list()
	var/list/datum/weakref/spawned_threat_refs = list()
	var/multiplayer_bonus = 1.1
	var/nohit_bonus = 0.8
	var/points = 0
	var/retries_spent = 0
	var/scanner_tier = 1
	var/server_cooldown_time = 2 MINUTES
	var/servo_bonus = 0
	var/threat = 0
	var/threat_prob_max = 15
	var/list/turf/exit_turfs = list()
	/// Клетки приёма груза текущего домена; турфы резервации переживают её освобождение вместе с сигналами
	var/list/turf/goal_turfs = list()
	var/broadcasting = FALSE
	COOLDOWN_DECLARE(broadcast_toggle_cd)
	COOLDOWN_DECLARE(polling_cooldown)

/obj/machinery/quantum_server/Initialize(mapload)
	. = ..()
	register_context()
	RegisterSignals(src, list(COMSIG_MACHINERY_BROKEN, COMSIG_MACHINERY_POWER_LOST), PROC_REF(on_broken))
	RegisterSignal(src, COMSIG_QDELETING, PROC_REF(on_delete))

/obj/machinery/quantum_server/Destroy(force)
	mutation_candidate_refs.Cut()
	avatar_connection_refs.Cut()
	spawned_threat_refs.Cut()
	exit_turfs.Cut()
	release_goal_turfs()
	QDEL_NULL(generated_domain)
	return ..()

/obj/machinery/quantum_server/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = NONE
	if(isnull(held_item))
		return

	if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Закрыть" : "Открыть"] панель"
		return CONTEXTUAL_SCREENTIP_SET
	else if(held_item.tool_behaviour == TOOL_CROWBAR && panel_open)
		context[SCREENTIP_CONTEXT_LMB] = "Разобрать"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/quantum_server/examine(mob/user)
	. = ..()

	. += span_infoplain("Требует много энергии. Обеспечьте достаточное питание.")

	. += span_notice("Панель обслуживания можно [EXAMINE_HINT("открутить")] и [panel_open ? "закрыть" : "открыть"].")
	if(panel_open)
		. += span_notice("Корпус можно [EXAMINE_HINT("поддеть")] и разобрать.")

	var/upgraded = FALSE
	if(capacitor_coefficient < 1)
		. += span_infoplain("- Система охлаждения сокращает перезарядку на [(1 - capacitor_coefficient) * 100]%.")
		upgraded = TRUE

	if(servo_bonus > 0.2)
		. += span_infoplain("- Манипуляторы увеличивают награду в [servo_bonus] раз.")
		. += span_infoplain("- Травмы при аварийном отключении снижены на [servo_bonus * 100]%.")
		upgraded = TRUE

	if(!upgraded)
		. += span_notice("Производительность неоптимальна. Улучшенные компоненты откроют данные домена, сократят перезарядку и увеличат награду.")

	if(!is_ready)
		. += span_notice("Идёт охлаждение. Подождите немного.")

	if(isobserver(user) && (obj_flags & EMAGGED))
		. += span_notice("Тревожные огни мигают красным. Сервер был взломан.")

/obj/machinery/quantum_server/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()

	if(obj_flags & EMAGGED)
		return

	obj_flags |= EMAGGED
	glitch_chance *= 2
	threat_prob_max *= 2
	SEND_SIGNAL(src, COMSIG_BITRUNNER_SERVER_EMAGGED)

	add_overlay(mutable_appearance('icons/obj/machines/bitrunning.dmi', "emag_overlay"))
	balloon_alert(user, "система взломана...")
	playsound(src, 'sound/effects/sparks1.ogg', 35, vary = TRUE)

/obj/machinery/quantum_server/update_appearance(updates)
	if(isnull(generated_domain) || !is_operational)
		set_light(l_on = FALSE)
		return ..()

	set_light(l_range = 2, l_power = 1.5, l_color = is_ready ? LIGHT_COLOR_BABY_BLUE : LIGHT_COLOR_FIRE, l_on = TRUE)
	return ..()

/obj/machinery/quantum_server/update_icon_state()
	if(isnull(generated_domain) || !is_operational)
		icon_state = base_icon_state
		return ..()

	icon_state = "[base_icon_state]_[is_ready ? "on" : "off"]"
	return ..()

/obj/machinery/quantum_server/base_item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/bitrunning_debug))
		balloon_alert(user, "*голосом хакера* я внутри")
		obj_flags |= EMAGGED
		glitch_chance = 0.5
		capacitor_coefficient = 0.1
		points = 100
		return ITEM_INTERACT_SUCCESS

	return ..()

/obj/machinery/quantum_server/crowbar_act(mob/living/user, obj/item/crowbar)
	. = NONE
	if(!is_ready)
		balloon_alert(user, "он раскалён!")
		return ITEM_INTERACT_FAILURE
	if(length(get_active_avatar_connections()))
		balloon_alert(user, "все клиенты должны отключиться!")
		return ITEM_INTERACT_FAILURE
	if(default_deconstruction_crowbar(crowbar))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/quantum_server/screwdriver_act(mob/living/user, obj/item/screwdriver)
	. = NONE
	if(!is_ready)
		balloon_alert(user, "он раскалён!")
		return ITEM_INTERACT_FAILURE
	if(default_deconstruction_screwdriver(user, "[base_icon_state]_panel", base_icon_state, screwdriver))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/quantum_server/RefreshParts()
	var/capacitor_rating = 1.15
	var/obj/item/stock_parts/capacitor/cap = locate() in component_parts
	if(cap)
		capacitor_rating -= cap.rating * 0.15

	capacitor_coefficient = capacitor_rating

	var/obj/item/stock_parts/scanning_module/scanner = locate() in component_parts
	if(scanner)
		scanner_tier = scanner.rating

	var/servo_rating = 0
	for(var/obj/item/stock_parts/manipulator/servo in component_parts)
		servo_rating += servo.rating * 0.1

	servo_bonus = servo_rating

	SEND_SIGNAL(src, COMSIG_MACHINERY_REFRESH_PARTS)
	return ..()

/obj/machinery/quantum_server/proc/start_broadcasting_network(network)
	return

/obj/machinery/quantum_server/proc/stop_broadcasting_network(network)
	return

/obj/machinery/quantum_server/proc/set_network_broadcast_status(network, status)
	return

#define GRADE_D "D"
#define GRADE_C "C"
#define GRADE_B "B"
#define GRADE_A "A"
#define GRADE_S "S"

/obj/machinery/quantum_server/proc/calculate_rewards()
	var/rewards_base = 0.8

	if(domain_randomized)
		rewards_base += 0.2

	rewards_base += servo_bonus

	rewards_base += (length(spawned_threat_refs) * 2)

	rewards_base += get_multiplayer_bonus()

	rewards_base += get_nohit_bouns()

	return rewards_base

/obj/machinery/quantum_server/proc/get_multiplayer_bonus()
	var/total = 0
	var/multiplayer = FALSE
	for(var/datum/component/avatar_connection/connection as anything in get_active_avatar_connections())
		if(multiplayer)
			total += multiplayer_bonus
		multiplayer = TRUE
	return total

/obj/machinery/quantum_server/proc/get_nohit_bouns()
	if(generated_domain.domain_flags & DOMAIN_NO_NOHIT_BONUS)
		return 0

	var/total = 0
	for(var/datum/component/avatar_connection/connection as anything in get_active_avatar_connections())
		if(connection.nohit)
			total += nohit_bonus
	return total

/obj/machinery/quantum_server/proc/generate_loot(obj/cache, obj/machinery/byteforge/chosen_forge)
	SSblackbox.record_feedback("tally", "bitrunning_domain_primary_completed", 1, generated_domain.key)
	for(var/mob/person in cache.contents)
		SEND_SIGNAL(person, COMSIG_BITRUNNER_CACHE_SEVER)

	spark_at_location(cache)
	qdel(cache)
	SEND_SIGNAL(src, COMSIG_BITRUNNER_DOMAIN_COMPLETE, cache, generated_domain.reward_points)

	points += generated_domain.reward_points
	playsound(src, 'sound/machines/terminal_success.ogg', 30, vary = TRUE)

	var/bonus = calculate_rewards()

	var/time_difference = world.time - generated_domain.start_time
	var/grade = grade_completion(time_difference)

	var/obj/structure/closet/crate/secure/bitrunning/decrypted/reward_cache = new(src, generated_domain, bonus)

	var/obj/item/paper/certificate = new(reward_cache)
	certificate.add_raw_text(get_completion_certificate(time_difference, grade))
	certificate.name = "certificate of domain completion"
	certificate.update_appearance()
	reward_cache.set_manifest(certificate)

	if(can_generate_tech_disk(grade))
		SSblackbox.record_feedback("tally", "bitrunning_bepis_rewarded", 1, generated_domain.key)
		new /obj/item/disk/design_disk(reward_cache)
		generated_domain.disk_reward_spawned = TRUE

	chosen_forge.start_to_spawn(reward_cache)
	return TRUE

/obj/machinery/quantum_server/proc/generate_secondary_loot(obj/curiosity, obj/machinery/byteforge/chosen_forge)
	SSblackbox.record_feedback("tally", "bitrunning_domain_secondary_completed", 1, generated_domain.key)
	spark_at_location(curiosity)
	qdel(curiosity)

	var/turf/reward_turf = get_turf(chosen_forge) || get_turf(src)
	var/obj/item/storage/lockbox/bitrunning/decrypted/reward_curiosity = new(reward_turf, generated_domain)

	chosen_forge.start_to_spawn(reward_curiosity)
	return TRUE

/obj/machinery/quantum_server/proc/get_completion_certificate(time_difference, grade)
	var/base_points = generated_domain.reward_points
	if(domain_randomized)
		base_points -= 1

	var/bonuses = calculate_rewards()

	var/domain_threats = length(spawned_threat_refs)

	var/completion_time = "### Время прохождения: [DisplayTimeText(time_difference)]\n"

	var/completion_grade = "\n---\n\n# Оценка: [grade]"

	var/text = "# Certificate of Domain Completion\n\n---\n\n"

	text += "### [generated_domain.name][domain_randomized ? " (Случайный)" : ""]\n"
	text += "- **Сложность:** [generated_domain.difficulty]\n"
	text += "- **Угрозы:** [domain_threats]\n"
	text += "- **Базовая награда:** [base_points][domain_randomized ? " +1" : ""]\n\n"
	text += "- **Общий бонус:** [bonuses]x\n\n"

	if(bonuses <= 1)
		text += completion_time
		text += completion_grade
		return text

	text += "### Бонусы\n"
	if(domain_randomized)
		text += "- **Случайный домен:** + 0.2\n"

	var/mp_bonus = get_multiplayer_bonus()
	if(mp_bonus)
		text += "- **Мультиплеер:** + [mp_bonus]\n"

	var/nohit_bonus = get_nohit_bouns()
	if(nohit_bonus)
		text += "- **Без урона:** + [nohit_bonus]\n"

	if(domain_threats > 0)
		text += "- **Угрозы:** + [domain_threats * 2]\n"

	var/servo_rating = servo_bonus

	if(servo_rating > 0.2)
		text += "- **Компоненты:** + [servo_rating]\n"

	text += completion_time
	text += completion_grade

	return text

/obj/machinery/quantum_server/proc/can_generate_tech_disk(grade)
	if(generated_domain.disk_reward_spawned)
		return FALSE

	if(!LAZYLEN(SSresearch.techweb_nodes_experimental))
		return FALSE

	var/static/list/passing_grades = list()
	if(!passing_grades.len)
		passing_grades = list(GRADE_A,GRADE_S)

	return  generated_domain.difficulty >= BITRUNNER_DIFFICULTY_MEDIUM && (grade in passing_grades)

/obj/machinery/quantum_server/proc/grade_completion(completion_time)
	var/score = length(spawned_threat_refs) * 5
	score += generated_domain.reward_points

	var/base = generated_domain.difficulty + 1
	var/time_score = 1

	if(completion_time <= 1 MINUTES)
		time_score = 10
	else if(completion_time <= 2 MINUTES)
		time_score = 5
	else if(completion_time <= 5 MINUTES)
		time_score = 3
	else if(completion_time <= 10 MINUTES)
		time_score = 2
	else
		time_score = 1

	score += time_score * base

	threat += score

	switch(score)
		if(1 to 4)
			return GRADE_D
		if(5 to 7)
			return GRADE_C
		if(8 to 10)
			return GRADE_B
		if(11 to 13)
			return GRADE_A
		else
			return GRADE_S

#undef GRADE_D
#undef GRADE_C
#undef GRADE_B
#undef GRADE_A
#undef GRADE_S

#define POLLING_COOLDOWN_TIME 2 MINUTES

/// Возвращает только живые подключения и попутно чистит мёртвые ссылки.
/obj/machinery/quantum_server/proc/get_active_avatar_connections()
	var/list/datum/component/avatar_connection/active = list()

	for(var/datum/weakref/connection_ref as anything in avatar_connection_refs.Copy())
		var/datum/component/avatar_connection/connection = connection_ref.resolve()
		if(isnull(connection) || QDELETED(connection) || connection.disconnecting)
			avatar_connection_refs -= connection_ref
			continue
		active += connection

	return active

/obj/machinery/quantum_server/proc/begin_shutdown(mob/user)
	if(isnull(generated_domain))
		return

	var/list/datum/component/avatar_connection/connections = get_active_avatar_connections()
	if(!length(connections))
		balloon_alert_to_viewers("отключение домена...")
		playsound(src, 'sound/machines/terminal_off.ogg', 40, vary = TRUE)
		reset()
		return

	balloon_alert_to_viewers("оповещение клиентов...")
	playsound(src, 'sound/machines/terminal_alert.ogg', 100, vary = TRUE)
	user.visible_message(
		span_danger("[user] начинает отключать сервер!"),
		span_notice("Вы начинаете отключать клиентов..."),
		span_danger("Слышна лихорадочная работа по клавиатуре."),
	)

	SEND_SIGNAL(src, COMSIG_BITRUNNER_SHUTDOWN_ALERT, user)

	if(!do_after(user, 20 SECONDS, src))
		return

	reset()

/obj/machinery/quantum_server/proc/cold_boot_map(map_key, was_random_selection)
	if(!is_ready)
		return FALSE

	if(isnull(map_key))
		balloon_alert_to_viewers("домен не указан!")
		return FALSE

	if(generated_domain)
		balloon_alert_to_viewers("сначала остановите текущий домен!")
		return FALSE

	if(length(get_active_avatar_connections()))
		balloon_alert_to_viewers("все клиенты должны отключиться!")
		return FALSE

	is_ready = FALSE
	playsound(src, 'sound/machines/terminal_processing.ogg', 30, 2)

	if(!load_domain(map_key) || !load_map_items() || !load_mob_segments())
		balloon_alert_to_viewers("инициализация не удалась!")
		scrub_vdom()
		is_ready = TRUE
		return FALSE

	// Фиксируем способ выбора домена для статистики.
	var/selection_type

	if(was_random_selection)
		selection_type = "random selection"
	else
		if(generated_domain.can_view_name(scanner_tier, points))
			selection_type = "full information"
		else
			selection_type = "redacted information"
	SSblackbox.record_feedback("nested tally", "bitrunning_domain_loaded", 1, list(selection_type, map_key))

	is_ready = TRUE

	var/spawn_chance = clamp((threat * glitch_chance), 5, threat_prob_max)
	if(prob(spawn_chance))
		setup_glitch()

	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 30, vary = TRUE)
	balloon_alert_to_viewers("домен загружен.")
	generated_domain.start_time = world.time
	points -= generated_domain.cost
	use_power = ACTIVE_POWER_USE
	update_appearance()

	if(broadcasting)
		start_broadcasting_network(BITRUNNER_CAMERA_NET)

	if(generated_domain.announce_to_ghosts)
		notify_ghosts("Битраннеры загрузили домен с возможностью взаимодействия с призраками. Проверьте меню спавнеров.",
			src,
			"Matrix Glitch",
		)

	return TRUE

/obj/machinery/quantum_server/proc/load_domain(map_key)
	for(var/datum/lazy_template/virtual_domain/available in SSbitrunning.all_domains)
		if(map_key == available.key && points >= available.cost)
			generated_domain = available
			break

	if(!generated_domain)
		return FALSE

	if(generated_domain.mission_min_candidates && (!COOLDOWN_FINISHED(src, polling_cooldown)))
		say("Алгоритмы продвинутых NPC перезагружаются. Подождите [DisplayTimeText(polling_cooldown)] или загрузите другой домен.")
		playsound(src, "sound/machines/buzz-[pick("sigh", "two")].ogg", 50, TRUE)
		return FALSE

	var/list/mob/lucky_ghosts
	if(generated_domain.mission_min_candidates)
		playsound(src, 'sound/machines/chime.ogg', 50, TRUE)
		say("Загрузка продвинутых NPC...")
		var/list/mob/candidates = pollCandidates("Хотите сыграть за виртуального [generated_domain.spawner_role] в домене битраннера?", ROLE_GHOST_ROLE, null, null, 15 SECONDS, POLL_IGNORE_SHUTTLE_DENIZENS, TRUE)
		for(var/amount in 1 to generated_domain.mission_max_candidates)
			if(length(candidates))
				LAZYADD(lucky_ghosts, pick_n_take(candidates))

		if(length(lucky_ghosts) < generated_domain.mission_min_candidates)
			notify_ghosts("Недостаточно кандидатов на роль [generated_domain.spawner_role]! Миссия отменена!")
			playsound(src, "sound/machines/buzz-[pick("sigh", "two")].ogg", 50, TRUE)
			say("Ошибка! Не удалось загрузить продвинутых NPC. Попробуйте снова или выберите другой домен.")
			COOLDOWN_START(src, polling_cooldown, POLLING_COOLDOWN_TIME)
			return FALSE

		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
		say("Успешно!")

	generated_domain.load_advanced_npcs(lucky_ghosts)
	RegisterSignal(generated_domain, COMSIG_LAZY_TEMPLATE_LOADED, PROC_REF(on_template_loaded))
	generated_domain.lazy_load()

	return TRUE

/obj/machinery/quantum_server/proc/load_map_items()
	release_goal_turfs()
	var/turf/cache_turfs = list()
	var/turf/curiosity_turfs = list()

	for(var/obj/effect/landmark/bitrunning/thing in GLOB.bitrunning_landmarks.Copy())
		if(istype(thing, /obj/effect/landmark/bitrunning/hololadder_spawn))
			exit_turfs += get_turf(thing)
			qdel(thing)
			continue

		if(istype(thing, /obj/effect/landmark/bitrunning/cache_goal_turf))
			register_goal_turf(get_turf(thing))
			qdel(thing)
			continue

		if(istype(thing, /obj/effect/landmark/bitrunning/cache_spawn))
			cache_turfs += get_turf(thing)
			qdel(thing)
			continue

		if(istype(thing, /obj/effect/landmark/bitrunning/curiosity_spawn))
			curiosity_turfs += get_turf(thing)
			qdel(thing)
			continue

		if(istype(thing, /obj/effect/landmark/bitrunning/loot_signal))
			var/turf/signaler_turf = get_turf(thing)
			signaler_turf.AddComponent(/datum/component/bitrunning_points, generated_domain)
			qdel(thing)
			continue

		if(istype(thing, /obj/effect/landmark/bitrunning/permanent_exit))
			var/turf/tile = get_turf(thing)
			exit_turfs += tile
			qdel(thing)

			new /obj/structure/hololadder(tile)

	for(var/datum/turf_reservation/reservation as anything in generated_domain.reservations)
		for(var/turf/tile as anything in reservation.reserved_turfs)
			for(var/obj/effect/mob_spawn/human/virtual_domain/spawner in tile)
				if(QDELETED(spawner))
					continue
				if(!generated_domain.announce_to_ghosts)
					qdel(spawner)
					continue
				spawner.invisibility = 0
				spawner.density = FALSE
				generated_domain.ghost_spawners += spawner

	if(!length(exit_turfs))
		CRASH("Не удалось найти клетки выхода в сгенерированном домене.")
	// Модульные домены могут иметь только выход в сейфхаусе — доставляем ящик туда.
	if(!length(goal_turfs) && length(exit_turfs))
		register_goal_turf(exit_turfs[1])
	if(!length(goal_turfs))
		CRASH("Не удалось найти клетки отправки в сгенерированном домене.")
	if(!attempt_spawn_cache(cache_turfs))
		return FALSE

	while(length(curiosity_turfs))
		var/turf/picked_turf = attempt_spawn_curiosity(curiosity_turfs)
		if(!picked_turf)
			break
		generated_domain.secondary_loot_generated += 1
		curiosity_turfs -= picked_turf

	return TRUE

/obj/machinery/quantum_server/proc/register_goal_turf(turf/tile)
	if(isnull(tile) || (tile in goal_turfs))
		return
	goal_turfs += tile
	RegisterSignal(tile, COMSIG_ATOM_ENTERED, PROC_REF(on_goal_turf_entered))
	RegisterSignal(tile, COMSIG_ATOM_EXAMINE, PROC_REF(on_goal_turf_examined))

/obj/machinery/quantum_server/proc/release_goal_turfs()
	for(var/turf/tile as anything in goal_turfs)
		UnregisterSignal(tile, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXAMINE))
	goal_turfs.Cut()

/obj/machinery/quantum_server/proc/reset(fast = FALSE)
	is_ready = FALSE

	sever_connections()

	if(!fast)
		notify_spawned_threats()
		addtimer(CALLBACK(src, PROC_REF(scrub_vdom)), 15 SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE)
	else
		scrub_vdom()

	addtimer(CALLBACK(src, PROC_REF(cool_off)), ROUND_UP(server_cooldown_time * capacitor_coefficient), TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_DELETE_ME)
	update_appearance()

	use_power = IDLE_POWER_USE
	domain_randomized = FALSE
	retries_spent = 0

	stop_broadcasting_network(BITRUNNER_CAMERA_NET)

/obj/machinery/quantum_server/proc/scrub_vdom()
	sever_connections()
	SEND_SIGNAL(src, COMSIG_BITRUNNER_DOMAIN_SCRUBBED)

	if(generated_domain)
		generated_domain.ghost_spawners.Cut()
		generated_domain.ghost_mobs.Cut()

	if(generated_domain && length(generated_domain.reservations))
		var/datum/turf_reservation/res = generated_domain.reservations[1]
		// Освобождение резервации может уснуть, поэтому не блокируем обработчик сигнала.
		INVOKE_ASYNC(res, TYPE_PROC_REF(/datum/turf_reservation, Release))

	var/list/creatures = spawned_threat_refs + mutation_candidate_refs
	for(var/datum/weakref/creature_ref as anything in creatures)
		var/mob/living/creature = creature_ref?.resolve()
		if(isnull(creature))
			continue

		qdel(creature)

	generated_domain.secondary_loot_generated = 0

	avatar_connection_refs.Cut()
	exit_turfs = list()
	release_goal_turfs()
	generated_domain = null
	mutation_candidate_refs.Cut()
	spawned_threat_refs.Cut()

#undef POLLING_COOLDOWN_TIME

/obj/machinery/quantum_server/proc/attempt_spawn_cache(list/possible_turfs)
	if(!length(possible_turfs))
		return TRUE

	shuffle_inplace(possible_turfs)
	var/turf/chosen_turf = validate_turf(pick(possible_turfs))

	if(isnull(chosen_turf))
		possible_turfs.Remove(chosen_turf)
		chosen_turf = validate_turf(pick(possible_turfs))
		if(isnull(chosen_turf))
			CRASH("vdom: after two attempts, could not find a valid turf for cache")

	new /obj/structure/closet/crate/secure/bitrunning/encrypted(chosen_turf)
	return TRUE

/obj/machinery/quantum_server/proc/attempt_spawn_curiosity(list/possible_turfs)
	if(!length(possible_turfs))
		return FALSE

	if(generated_domain.secondary_loot_generated >= counterlist_sum(generated_domain.secondary_loot))
		return FALSE

	shuffle_inplace(possible_turfs)
	var/turf/chosen_turf = validate_turf(pick(possible_turfs))

	if(isnull(chosen_turf))
		possible_turfs.Remove(chosen_turf)
		chosen_turf = validate_turf(pick(possible_turfs))
		if(isnull(chosen_turf))
			CRASH("vdom: after two attempts, could not find a valid turf for curiosity")

	new /obj/item/storage/lockbox/bitrunning/encrypted(chosen_turf)
	return chosen_turf

/obj/machinery/quantum_server/proc/generate_avatar(turf/destination, datum/outfit/netsuit, datum/preferences/prefs, load_loadout = FALSE, appearance_only = FALSE)
	var/mob/living/carbon/human/avatar = new(destination)

	if(!isnull(prefs))
		if(appearance_only)
			prefs.copy_appearance_to(avatar)
		else
			prefs.copy_to(avatar)
	ADD_TRAIT(avatar, TRAIT_CANNOT_CRYSTALIZE, "Bitrunning")
	var/outfit_path = generated_domain.forced_outfit || netsuit
	var/datum/outfit/to_wear = new outfit_path()

	to_wear.belt = /obj/item/bitrunning_host_monitor
	to_wear.ears = null
	to_wear.glasses = null
	to_wear.gloves = null
	to_wear.l_pocket = null
	to_wear.r_pocket = null
	to_wear.suit = null
	to_wear.suit_store = null

	avatar.equipOutfit(to_wear, visualsOnly = TRUE)

	var/obj/item/clothing/under/avatar_uniform = avatar.w_uniform
	if(istype(avatar_uniform))
		avatar_uniform.sensor_flags = NONE
		avatar_uniform.has_sensor = NO_SENSORS
		avatar_uniform.sensor_mode = SENSOR_OFF
		avatar_uniform.sensor_mode_intended = SENSOR_OFF

	if(!generated_domain.forced_outfit)
		for(var/obj/thing in avatar.held_items)
			qdel(thing)

	var/obj/item/storage/backpack/bag = avatar.back
	if(istype(bag))
		QDEL_LIST(bag.contents)

		bag.contents += list(
			new /obj/item/storage/box/survival(bag),
			new /obj/item/storage/firstaid/regular(bag),
			new /obj/item/flashlight(bag),
		)

	var/obj/item/card/id/outfit_id = avatar.wear_id
	if(outfit_id)
		outfit_id.registered_account = new /datum/bank_account(avatar.real_name)
		outfit_id.registered_name = avatar.real_name
		outfit_id.assignment = "Bit Avatar"
		outfit_id.special_assignment = "bitavatar"
		outfit_id.update_label()

	return avatar

/obj/machinery/quantum_server/proc/load_mob_segments()
	if(!length(generated_domain.mob_modules))
		return TRUE

	var/current_index = 1
	shuffle_inplace(generated_domain.mob_modules)

	for(var/obj/effect/landmark/bitrunning/mob_segment/landmark in GLOB.bitrunning_landmarks.Copy())
		if(current_index > length(generated_domain.mob_modules))
			stack_trace("vdom: mobs segments are set to unique, but there are more landmarks than available segments")
			return FALSE

		var/path
		if(generated_domain.modular_unique_mobs)
			path = generated_domain.mob_modules[current_index]
			current_index += 1
		else
			path = pick(generated_domain.mob_modules)

		var/datum/modular_mob_segment/segment = new path()
		var/list/mob_spawns = landmark.spawn_mobs(get_turf(landmark), segment)
		if(length(mob_spawns))
			mutation_candidate_refs += mob_spawns

		qdel(landmark)
		qdel(segment)

	return TRUE

/obj/machinery/quantum_server/proc/stock_gear(mob/living/carbon/human/avatar, mob/living/carbon/human/neo, datum/lazy_template/virtual_domain/generated_domain)
	var/domain_forbids_flags = generated_domain.domain_flags

	var/import_ban = list()
	var/disk_ban = list()
	if(domain_forbids_flags & DOMAIN_FORBIDS_ITEMS)
		import_ban += "провезённое цифровое снаряжение"
		disk_ban += "предметы"
	if(domain_forbids_flags & DOMAIN_FORBIDS_ABILITIES)
		import_ban += "импортированные способности"
		disk_ban += "силы"

	if(length(import_ban))
		to_chat(neo, span_warning("Этот домен запрещает использование [english_list(import_ban)]; внешне загруженные [english_list(disk_ban)] не будут выданы!"))

	var/return_flags = NONE
	for(var/obj/item/disk/bitrunning/disk in neo.GetAllContents(/obj/item/disk/bitrunning))
		return_flags |= disk.load_onto_avatar(neo, avatar, domain_forbids_flags)

	if(return_flags & BITRUNNER_GEAR_LOAD_FAILED)
		to_chat(neo, span_warning("Один из внешних источников данных не смог загрузиться. Проверьте пересекающиеся или неактивные диски."))
	if(return_flags & BITRUNNER_GEAR_LOAD_BLOCKED)
		to_chat(neo, span_warning("Один из внешних источников данных заблокирован. Проверьте ограничения домена."))

/obj/machinery/quantum_server/proc/on_broken(datum/source)
	SIGNAL_HANDLER

	sever_connections()

/obj/machinery/quantum_server/proc/on_delete(datum/source)
	SIGNAL_HANDLER

	sever_connections()

	if(generated_domain)
		scrub_vdom()

	if(is_ready)
		return
	// Если сервер удаляют во время перезарядки, плату нужно изъять.
	var/obj/item/circuitboard/machine/quantum_server/circuit = locate(/obj/item/circuitboard/machine/quantum_server) in contents
	if(circuit)
		qdel(circuit)

/obj/machinery/quantum_server/proc/on_goal_turf_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	var/obj/machinery/byteforge/chosen_forge = get_random_nearby_forge()
	if(isnull(chosen_forge))
		return

	if((obj_flags & EMAGGED) && isliving(arrived))
		var/mob/living/creature = arrived

		if(!creature.mind?.has_antag_datum(/datum/antagonist/bitrunning_glitch, check_subtypes = TRUE))
			return

		INVOKE_ASYNC(src, PROC_REF(station_spawn), arrived, chosen_forge)
		return

	if(istype(arrived, /obj/structure/closet/crate/secure/bitrunning/encrypted))
		generate_loot(arrived, chosen_forge)
		return

	if(istype(arrived, /obj/item/storage/lockbox/bitrunning/encrypted))
		generate_secondary_loot(arrived, chosen_forge, generated_domain)
		return

/obj/machinery/quantum_server/proc/on_goal_turf_examined(datum/source, mob/examiner, list/examine_text)
	SIGNAL_HANDLER

	examine_text += span_info("Под вашим взглядом пол едва пульсирует потоками закодированных данных.")
	examine_text += span_info("Похоже, это часть места, предназначенного для получения зашифрованных грузов.")

/obj/machinery/quantum_server/proc/on_template_loaded(datum/lazy_template/source, list/created_atoms)
	SIGNAL_HANDLER

	for(var/thing in created_atoms)
		if(isliving(thing))
			var/mob/living/creature = thing

			if(istype(creature, /mob/living/simple_animal/hostile/megafauna))
				var/mob/living/simple_animal/hostile/megafauna/boss = creature
				boss.make_virtual_megafauna()
				continue

			mutation_candidate_refs.Add(WEAKREF(creature))
			continue

		if(istype(thing, /obj/effect/mob_spawn/human/virtual_domain))
			RegisterSignal(thing, COMSIG_BITRUNNER_SPAWNED, PROC_REF(on_threat_created))
			RegisterSignal(thing, COMSIG_GHOSTROLE_SPAWNED, PROC_REF(on_domain_mob_spawned))
			continue

	UnregisterSignal(source, COMSIG_LAZY_TEMPLATE_LOADED)

	generated_domain.setup_domain(created_atoms)

/obj/machinery/quantum_server/proc/on_threat_created(datum/source, mob/living/threat)
	SIGNAL_HANDLER

	add_threats(threat)

/obj/machinery/quantum_server/proc/on_domain_mob_spawned(datum/source, mob/living/spawned)
	SIGNAL_HANDLER

	if(QDELETED(spawned))
		return

	spawned.AddComponent(/datum/component/virtual_entity, src)

/obj/machinery/quantum_server/proc/add_threats(mob/living/threat)
	spawned_threat_refs.Add(WEAKREF(threat))
	SEND_SIGNAL(src, COMSIG_BITRUNNER_THREAT_CREATED)
	threat.AddComponent(/datum/component/virtual_entity, src)

/obj/machinery/quantum_server/proc/get_antagonist_role()
	var/static/list/glitch_roles
	if(isnull(glitch_roles))
		glitch_roles = subtypesof(/datum/antagonist/bitrunning_glitch)
	var/list/available = list()

	for(var/datum/antagonist/bitrunning_glitch/subtype as anything in glitch_roles)
		if(threat >= initial(subtype.threat))
			available += subtype

	if(!length(available))
		return
	shuffle_inplace(available)
	var/datum/antagonist/bitrunning_glitch/chosen = pick(available)

	threat -= initial(chosen.threat) * 0.5

	return chosen

/obj/machinery/quantum_server/proc/get_mutation_target()
	var/datum/weakref/target_ref = pick(mutation_candidate_refs)
	var/mob/living/resolved = target_ref.resolve()

	if(resolved)
		return resolved

	mutation_candidate_refs.Remove(target_ref)
	if(!length(mutation_candidate_refs))
		return

	target_ref = pick(mutation_candidate_refs)
	resolved = target_ref.resolve()
	return resolved

/obj/machinery/quantum_server/proc/notify_spawned_threats()
	for(var/datum/weakref/baddie_ref as anything in spawned_threat_refs)
		var/mob/living/baddie = baddie_ref.resolve()
		if(isnull(baddie?.mind) || baddie.stat >= UNCONSCIOUS)
			continue

		var/atom/movable/screen/alert/bitrunning/alert = baddie.throw_alert(
			ALERT_BITRUNNER_RESET,
			/atom/movable/screen/alert/bitrunning,
			new_master = src,
		)
		alert.name = "Queue Deletion"
		alert.desc = "Сервер перезагружается. Забвение близко."

		to_chat(baddie, span_userdanger("Вы помечены на удаление! Спасибо за службу."))

/obj/machinery/quantum_server/proc/remove_threat(mob/living/threat)
	spawned_threat_refs.Remove(WEAKREF(threat))

/obj/machinery/quantum_server/proc/setup_glitch(datum/antagonist/bitrunning_glitch/forced_role)
	if(!validate_mutation_candidates())
		return

	var/mob/living/mutation_target = get_mutation_target()
	if(isnull(mutation_target))
		CRASH("vdom: After two attempts, no valid mutation target was found.")

	var/atom/thing = mutation_target
	thing.create_digital_aura()

	var/datum/antagonist/bitrunning_glitch/chosen_role = forced_role || get_antagonist_role()
	var/role_name = initial(chosen_role.name)
	var/list/mob/candidates = pollCandidatesForMob(
		"<span class='ooc'>В виртуальном домене появляется временная роль антагониста.</span>\
		\n<span class='boldnotice'>По завершении вы вернётесь в прежнее тело.</span>\
		\nРоль: [role_name]",
		ROLE_GLITCH,
		null,
		null,
		20 SECONDS,
		mutation_target,
		POLL_IGNORE_GLITCH,
		priority_check = FALSE,
	)
	var/mob/chosen_one = length(candidates) ? pick(candidates) : null
	spawn_glitch(chosen_role, mutation_target, chosen_one)
	return mutation_target

/obj/machinery/quantum_server/proc/spawn_glitch(datum/antagonist/bitrunning_glitch/chosen_role, mob/living/mutation_target, mob/dead/observer/ghost)
	if(QDELETED(mutation_target))
		return

	if(QDELETED(src) || isnull(ghost) || isnull(generated_domain) || !is_ready || !is_operational)
		var/atom/thing = mutation_target
		thing.remove_digital_aura()
		return

	var/role_name = initial(chosen_role.name)

	var/mob/living/new_mob
	switch(role_name)
		if(ROLE_NETGUARDIAN)
			new_mob = new /mob/living/simple_animal/hostile/netguardian(mutation_target.loc)
		else
			new_mob = new /mob/living/carbon/human(mutation_target.loc)

	mutation_target.gib()

	var/datum/mind/ghost_mind = ghost.mind
	new_mob.ckey = ghost.ckey

	if(ghost_mind)
		new_mob.AddComponent(/datum/component/temporary_body, ghost_mind, ghost_mind.current, TRUE)

	var/datum/mind/antag_mind = new_mob.mind
	antag_mind.add_antag_datum(chosen_role)
	antag_mind.assigned_role = ROLE_GLITCH

	playsound(new_mob, 'sound/magic/Ethereal_Exit.ogg', 50, vary = TRUE)
	message_admins("[ADMIN_LOOKUPFLW(new_mob)] стал виртуальным антагонистом по событию.")

	add_threats(new_mob)

/obj/machinery/quantum_server/proc/station_spawn(mob/living/antag, obj/machinery/byteforge/chosen_forge)
	antag.balloon_alert(antag, "сканирование...")
	chosen_forge.setup_particles(angry = TRUE)
	SEND_SIGNAL(src, COMSIG_BITRUNNER_STATION_SPAWN)

	var/timeout = 2 SECONDS
	if(!ishuman(antag))
		timeout = 10 SECONDS

	if(!do_after(antag, timeout) || QDELETED(chosen_forge) || QDELETED(antag) || QDELETED(src) || !is_ready || !is_operational)
		chosen_forge.setup_particles()
		return

	var/datum/component/glitch/effect = antag.AddComponent(/datum/component/glitch, \
		server = src, \
		forge = chosen_forge, \
	)

	chosen_forge.flicker(angry = TRUE)
	if(!do_after(antag, 1 SECONDS))
		chosen_forge.setup_particles()
		qdel(effect)
		return

	chosen_forge.flash()

	if(ishuman(antag))
		reset_equipment(antag)

	var/datum/antagonist/antag_datum = antag.mind?.has_antag_datum(/datum/antagonist/bitrunning_glitch)
	if(istype(antag_datum))
		antag_datum.show_in_check_antagonists = TRUE

	var/datum/component/temp_body = antag.GetComponent(/datum/component/temporary_body)
	if(temp_body)
		qdel(temp_body)

	do_teleport(antag, get_turf(chosen_forge), forced = TRUE, asoundin = 'sound/magic/Ethereal_Enter.ogg', asoundout = 'sound/magic/Ethereal_Exit.ogg', channel = TELEPORT_CHANNEL_QUANTUM)

/obj/machinery/quantum_server/proc/validate_mutation_candidates()
	for(var/datum/weakref/creature_ref as anything in mutation_candidate_refs)
		var/mob/living/creature = creature_ref?.resolve()
		if(isnull(creature) || creature.mind)
			mutation_candidate_refs.Remove(creature_ref)

	if(!length(mutation_candidate_refs))
		return FALSE

	shuffle_inplace(mutation_candidate_refs)

	return TRUE

#define MAX_DISTANCE 4

/obj/machinery/quantum_server/proc/cool_off()
	is_ready = TRUE
	update_appearance()
	balloon_alert_to_viewers("перезарядка завершена")

/obj/machinery/quantum_server/proc/get_avatar_data()
	var/list/hosted_avatars = list()

	for(var/datum/component/avatar_connection/connection as anything in get_active_avatar_connections())
		var/mob/living/creature = connection.parent
		var/mob/living/pilot = connection.old_body_ref?.resolve()

		hosted_avatars += list(list(
			"health" = creature.health,
			"name" = creature.name,
			"pilot" = pilot,
			"brute" = creature.getBruteLoss(),
			"burn" = creature.getFireLoss(),
			"tox" = creature.getToxLoss(),
			"oxy" = creature.getOxyLoss(),
		))

	return hosted_avatars

/obj/machinery/quantum_server/proc/get_avatar_destination() as /atom
	if(length(generated_domain.custom_spawns))
		var/atom/valid_spawner

		while(isnull(valid_spawner))
			var/atom/chosen = pick(generated_domain.custom_spawns)
			if(QDELETED(chosen))
				generated_domain.custom_spawns -= chosen
				continue

			valid_spawner = chosen
			break

		return valid_spawner

	if(!length(exit_turfs))
		return

	if(retries_spent >= length(exit_turfs))
		return

	var/turf/exit_tile
	for(var/turf/dest_turf in exit_turfs)
		if(!locate(/obj/structure/hololadder) in dest_turf)
			exit_tile = dest_turf
			break

	if(isnull(exit_tile))
		return

	var/obj/structure/hololadder/wayout = new(exit_tile, src)
	if(isnull(wayout))
		return

	retries_spent += 1

	return wayout

/obj/machinery/quantum_server/proc/get_random_nearby_forge()
	var/list/nearby_forges = list()

	for(var/obj/machinery/byteforge/forge in oview(MAX_DISTANCE, src))
		nearby_forges += forge

	return pick(nearby_forges)

/obj/machinery/quantum_server/proc/get_random_domain_id()
	if(points < 1)
		return

	var/list/random_domains = list()

	for(var/datum/lazy_template/virtual_domain/available as anything in SSbitrunning.all_domains)
		var/init_cost = available.cost

		if(!(available.domain_flags & DOMAIN_TEST_ONLY) && \
			init_cost <= points && \
			init_cost > BITRUNNER_COST_NONE && \
			init_cost < BITRUNNER_COST_EXTREME \
		)
			random_domains.Add(available)

	if(!length(random_domains))
		return
	shuffle_inplace(random_domains)
	var/datum/lazy_template/virtual_domain/selected = pick(random_domains)
	domain_randomized = TRUE

	return selected.key

/obj/machinery/quantum_server/proc/reset_equipment(mob/living/carbon/human/person)
	for(var/obj/item in person.get_equipped_items(TRUE))
		qdel(item)

	var/datum/antagonist/bitrunning_glitch/antag_datum = locate() in person.mind?.antag_datums
	if(isnull(antag_datum?.preview_outfit))
		return

	person.equipOutfit(antag_datum.preview_outfit)

	antag_datum.fix_agent_id()

/obj/machinery/quantum_server/proc/sever_connections()
	if(isnull(generated_domain) || !length(get_active_avatar_connections()))
		return

	SEND_SIGNAL(src, COMSIG_BITRUNNER_QSRV_SEVER)

/obj/machinery/quantum_server/proc/spark_at_location(obj/cache)
	playsound(cache, 'sound/magic/blink.ogg', 50, vary = TRUE)
	do_sparks(5, FALSE, get_turf(cache))

/obj/machinery/quantum_server/proc/start_new_connection(mob/living/carbon/human/neo, datum/outfit/netsuit) as /mob/living/carbon/human
	var/atom/entry_atom = get_avatar_destination()
	if(isnull(entry_atom))
		return
	var/datum/preferences/pref
	var/load_loadout = FALSE
	var/appearance_only = FALSE
	var/obj/item/disk/bitrunning/prefs/prefdisk = locate() in neo.get_contents()
	if(prefdisk)
		load_loadout = prefdisk.include_loadout
		appearance_only = prefdisk.appearance_only
		pref = prefdisk.loaded_preference
	var/mob/living/carbon/new_avatar = generate_avatar(get_turf(entry_atom), netsuit, prefs = pref, load_loadout = load_loadout, appearance_only = appearance_only)

	if(!length(generated_domain.custom_spawns))
		return new_avatar

	if(istype(entry_atom, /obj/effect/mob_spawn/human/virtual_domain))
		var/obj/effect/mob_spawn/human/virtual_domain/spawner = entry_atom
		spawner.artificial_spawn(new_avatar)

	if(!generated_domain.keep_custom_spawns)
		generated_domain.custom_spawns -= entry_atom
		qdel(entry_atom)

	return new_avatar

/obj/machinery/quantum_server/proc/toggle_broadcast()
	if(!COOLDOWN_FINISHED(src, broadcast_toggle_cd))
		return FALSE

	broadcasting = !broadcasting

	if(generated_domain)
		COOLDOWN_START(src, broadcast_toggle_cd, 5 SECONDS)
		set_network_broadcast_status(BITRUNNER_CAMERA_NET, broadcasting)
	return TRUE

/obj/machinery/quantum_server/proc/validate_turf(turf/chosen_turf)
	if(!chosen_turf.is_blocked_turf())
		return chosen_turf

	for(var/turf/tile in get_adjacent_open_turfs(chosen_turf))
		if(!tile.is_blocked_turf())
			return chosen_turf

#undef MAX_DISTANCE
