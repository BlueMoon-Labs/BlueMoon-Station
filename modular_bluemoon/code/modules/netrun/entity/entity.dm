/**
 * Сетевая сущность: разум, живущий внутри узлов сети.
 * Видит и слышит вокруг узла-носителя, говорит его динамиком, прыгает по узлам.
 */
/mob/camera/netrun_entity
	name = "сетевая сущность"
	real_name = "сетевая сущность"
	desc = "Процесс, которому кто-то дал имя."
	see_in_dark = 2
	var/datum/component/netrun_node/host_node
	var/datum/netrun_console/entity/console
	var/blinded = FALSE
	var/integrity = 100
	var/max_integrity = 100
	var/next_hop = 0
	/// Owns the route and its single cancellable timer.
	var/datum/netrun_entity_navigation/navigation
	// Боевые состояния
	var/combat_stun_until = 0
	var/combat_shield_until = 0
	var/combat_shield_factor = 1
	/// Пока активно - лёд считает след потерянным и не перезахватывает процесс (заметание следов).
	var/combat_ignore_until = 0
	var/datum/netrun_dive_link/dive_link
	var/datum/action/innate/netrun_console/console_action
	var/datum/action/innate/netrun_rename/rename_action
	/// Autonomous processes do not publish a virtual PDA into the crew messenger directory.
	var/has_messenger = TRUE
	/// Console implementation created in Initialize; autonomous subtypes choose theirs before ..().
	var/console_type = /datum/netrun_console/entity

/mob/camera/netrun_entity/Initialize(mapload, datum/component/netrun_node/start)
	. = ..()
	if(!assemble_modules())
		return INITIALIZE_HINT_QDEL
	SSnetrun.entities += src
	if(start)
		// Initial residency authorizes only this host, without opening its LAN.
		console.access_session.node_access[start.address] = NETRUN_ACCESS_USER
		console.access_session.residency_address = start.address
		enter_node(start)

/mob/camera/netrun_entity/Destroy()
	SSnetrun.entities -= src
	navigation?.cancel()
	leave_node()
	destroy_modules()
	QDEL_NULL(module_host)
	return ..()

/mob/camera/netrun_entity/Login()
	. = ..()
	get_persona()
	if(!client)
		return
	if(!entity_modules["neural_feedback"])
		install_module(/datum/netrun_entity_module/neural_feedback)
	console?.activate()
	to_chat(src, span_notice("Вы — процесс в сети станции. Мир виден через доступную оптику: камеры, киберглаза и взломанные HUD-очки. \
		В окне устройства включите «Смотреть». Говорить и слышать можно через интеркомы — включите микрофон или динамик. Кнопка «Сеть» \
		открывает карту; переходы между узлами — Shift+WASD по положению на карте (наведя фокус на карту)."))
	INVOKE_ASYNC(console, TYPE_PROC_REF(/datum, ui_interact), src)
	update_vision()

/mob/camera/netrun_entity/get_status_tab_items()
	. = ..()
	. += "Целостность: [integrity]/[max_integrity]"
	. += "Узел: [host_node ? "[host_node.get_name()] [host_node.address]" : "нет"]"
	if(console)
		. += "Трассировка: [round(console.intrusion.trace)]%"

// MARK: Узлы

/mob/camera/netrun_entity/proc/enter_node(datum/component/netrun_node/node, following_route = FALSE)
	if(!node)
		return FALSE
	if(!following_route)
		navigation?.cancel()
	leave_node()
	host_node = node
	LAZYADD(node.entities, src)
	RegisterSignal(node, COMSIG_NETRUN_NODE_MOVED, PROC_REF(on_host_moved))
	abstract_move(node.physical_turf())
	console.map_view.viewed_network_id = node.network?.id
	console.map_view.selected_address = node.address
	node.touch()
	node.notify_changed(NETRUN_CHANGED_OCCUPANTS)
	SEND_SIGNAL(src, COMSIG_NETRUN_ENTITY_NODE_CHANGED, null, node)
	// Traps and alarms react to the arrival itself; a listener may delete this process.
	node.fortress?.on_arrival(src)
	if(QDELETED(src) || host_node != node)
		return TRUE
	console.finish_user_action(node)
	return TRUE

/// Запоминаем пройденный путь погружения. При возврате на уже пройденный узел
/// петля срезается - цепочка остаётся кратчайшей фактически пройденной.
/mob/camera/netrun_entity/proc/track_route(datum/component/netrun_node/node)
	return dive_link?.track_route(node)

/mob/camera/netrun_entity/proc/leave_node()
	if(!host_node)
		return
	var/datum/component/netrun_node/old = host_node
	UnregisterSignal(old, COMSIG_NETRUN_NODE_MOVED)
	LAZYREMOVE(host_node.entities, src)
	old.notify_changed(NETRUN_CHANGED_OCCUPANTS)
	host_node = null
	SEND_SIGNAL(src, COMSIG_NETRUN_ENTITY_NODE_CHANGED, old, null)
	old.wake_defenses()

/// Movement authority is separate from machine USER and native ID access.
/// Acquired gateway GUEST and an ordinary LAN key open the same traversal;
/// fortress gates still require USER on their own node.
/datum/netrun_console/proc/can_traverse_node(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(QDELETED(node) || !node.network)
		return FALSE
	var/level = node_level(node, tree)
	if(level >= NETRUN_ACCESS_USER)
		return TRUE
	if(node.fortress?.gate_blocks(src))
		return FALSE
	return access_session.acquired_network_level(node.network) >= NETRUN_ACCESS_GUEST || has_key(node.network, TRUE)

/// Можно ли перепрыгнуть в узел
/mob/camera/netrun_entity/proc/can_enter(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(!node || node == host_node || !host_node || console.is_locked())
		return FALSE
	console.refresh_route_node(host_node)
	console.refresh_route_node(node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	if(!graph.edge_between(host_node.address, node.address) || !netrun_link_available(host_node, node))
		return FALSE
	// Свежий расчёт доступа через path-tree, минуя кэш уровней UI: иначе только что
	// полученный USER может не учитываться до следующего обновления интерфейса.
	var/owns_tree = !tree
	if(owns_tree)
		tree = console.connection.read_path_tree(TRUE)
	. = console.can_traverse_node(node, tree)
	if(owns_tree)
		console.release_path_tree(tree)

/// Понятная причина отказа в переходе - для журнала консоли.
/mob/camera/netrun_entity/proc/hop_denial(datum/component/netrun_node/node)
	if(!node)
		return "Переход невозможен: узел не найден."
	if(!host_node)
		return "Переход невозможен: нет текущего узла."
	if(console.is_locked())
		return "Переход невозможен: точка подключения заблокирована трассировкой."
	if(is_stunned())
		return "Переход невозможен: процесс оглушён."
	if(world.time < next_hop)
		return "Переход невозможен: перезарядка перехода."
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	if(!(node.address in graph.neighbors(host_node.address)) || !netrun_link_available(host_node, node))
		return "Переход невозможен: узел не является прямым соседом или связь с ним недоступна."
	if(node.fortress?.gate_blocks(console) && console.node_level(node) < NETRUN_ACCESS_USER)
		return "Переход невозможен: врата крепости закрыты — ключ ЛВС не действует, нужен доступ ПОЛЬЗОВАТЕЛЯ к узлу."
	return "Переход невозможен: нужен доступ ПОЛЬЗОВАТЕЛЯ к узлу, добытый вход ЛВС или её ключ."

/mob/camera/netrun_entity/proc/hop(datum/component/netrun_node/node, following_route = FALSE)
	if(!following_route)
		navigation?.cancel()
	if(world.time < next_hop || is_stunned() || !can_enter(node))
		return FALSE
	var/datum/netrun_combat_encounter/encounter = console.get_combat_encounter()
	if(encounter?.active && !encounter.spend(console, 1, TRUE))
		console.combat_log("Для выхода из боя нужен ваш ход и одно очко действий.", "bad")
		return FALSE
	next_hop = world.time + 1 SECONDS
	enter_node(node, following_route)
	if(!QDELETED(encounter))
		encounter.resolve(console)
	return TRUE

/// A gateway transition is an ordinary authorized hop between two operational relays.
/mob/camera/netrun_entity/proc/can_relay_hop(datum/component/netrun_node/node)
	if(!netrun_quantum_link(host_node, node))
		return FALSE
	return can_enter(node)

/mob/camera/netrun_entity/proc/relay_hop(datum/component/netrun_node/node)
	if(!can_relay_hop(node))
		return FALSE
	return hop(node)

/// Путь из соседних узлов, в каждый из которых процесс может войти (online + USER/ключ).
/mob/camera/netrun_entity/proc/enterable_path(datum/component/netrun_node/target)
	return navigation?.path_to(target) || list()

/// Автопроход по уже открытому пути: шаг за шагом к выбранному узлу.
/mob/camera/netrun_entity/proc/travel_to(datum/component/netrun_node/target)
	return navigation?.start(target) || FALSE

/mob/camera/netrun_entity/Move(NewLoc, direct)
	// Перемещение по сети идёт по положению узлов НА КАРТЕ, а не по их физическим
	// координатам в мире. Раскладка карты известна только клиенту, поэтому WASD/переходы
	// обрабатывает интерфейс карты (Shift+WASD), а не мировое движение камеры.
	return FALSE

/mob/camera/netrun_entity/forceMove(atom/destination)
	return abstract_move(destination)

/// Empty resident processes have no clock to advance. Navigation and link changes
/// own their timers; players, neural bodies and integrity repair still need ticks.
/mob/camera/netrun_entity/proc/needs_processing()
	return !!client || modules_need_processing()

/mob/camera/netrun_entity/proc/on_host_moved(datum/source, datum/component/netrun_node/node, turf/old_position, turf/position)
	SIGNAL_HANDLER
	if(node == host_node && position != loc)
		abstract_move(position)

/// Синхронизация активного процесса с носителем, вызывается консолью раз в секунду
/mob/camera/netrun_entity/proc/process_tick(delta)
	process_modules(delta)
	if(QDELETED(src))
		return
	SEND_SIGNAL(src, COMSIG_NETRUN_ENTITY_TICK, delta)

/// Есть ли ещё физический маршрут от текущего узла назад к точке входа погружения.
/mob/camera/netrun_entity/proc/dive_link_intact()
	return dive_link?.link_intact() || FALSE

/// Broken physical return paths eject the neural user on the first failed check.
/mob/camera/netrun_entity/proc/check_dive_link(delta)
	return dive_link?.check_link(delta) || FALSE

/// Compatibility entry point: neural processes cannot remain stranded after a break.
/mob/camera/netrun_entity/proc/strand_in_network()
	return dive_link?.strand_in_network()

// MARK: Зрение через доступные оптические устройства

/mob/camera/netrun_entity/proc/vision_source()
	// An explicitly opened stream takes priority over the entity's physical host.
	var/datum/netrun_console/view_console = netrun_watch_console || console
	if(view_console?.watch_target())
		return view_console.remote_session.watch_node.parent
	if(QDELETED(host_node) || !host_node.is_online())
		return null
	if(console.node_level(host_node) < NETRUN_ACCESS_USER)
		return null
	var/atom/source = host_node.parent
	return source.netrun_view_target() ? source : null

/mob/camera/netrun_entity/proc/current_vision_target()
	var/atom/source = vision_source()
	return source?.netrun_view_target()

/mob/camera/netrun_entity/proc/update_vision()
	if(!client)
		return
	var/atom/source = vision_source()
	var/atom/eye = source?.netrun_view_target()
	if(eye)
		var/datum/netrun_console/view_console = netrun_watch_console || console
		if(view_console?.watch_target() && view_console.remote_session.watch_eye)
			eye = view_console.remote_session.watch_eye
		if(blinded)
			clear_fullscreen("netrun_blind")
			blinded = FALSE
		if(client.eye != eye)
			reset_perspective(eye)
		var/list/settings = source.netrun_view_settings()
		see_in_dark = settings["see_in_dark"]
		sight = settings["sight"]
		see_invisible = settings["see_invisible"]
		clear_fullscreen("remote_view", 0)
		var/atom/source_eye = source.netrun_view_target()
		source_eye?.get_remote_view_fullscreens(src)
	else
		clear_fullscreen("remote_view", 0)
		see_in_dark = initial(see_in_dark)
		sight = initial(sight)
		see_invisible = initial(see_invisible)
		if(client.eye != src)
			reset_perspective(null)
		if(!blinded)
			overlay_fullscreen("netrun_blind", /atom/movable/screen/fullscreen/scaled/blind)
			blinded = TRUE

// MARK: Роль процесса

/// Archetype id of an autonomous bot; null for players and ghost-role residents.
/mob/camera/netrun_entity/proc/netrun_bot_kind()
	return null

/// Does this process wake sleeping ICE and mark its LAN as contested? Sanctioned
/// station processes (police, maintenance) patrol without waking every department.
/mob/camera/netrun_entity/proc/defense_threat()
	return TRUE

/// Resident players and their owned agents share the real owner's personal identity.
/mob/camera/netrun_entity/proc/netrun_faction()
	return console?.get_personal_faction_id()

/// Console that launched this process as its agent; null for independent processes.
/mob/camera/netrun_entity/proc/netrun_owner_console()
	return null

/// Short state shown on contact cards.
/mob/camera/netrun_entity/proc/contact_state()
	return is_stunned() ? "оглушён" : (dive_link?.body ? "погружение" : "резидент")

// MARK: Боевой интерфейс

/mob/camera/netrun_entity/proc/combat_name()
	return real_name

/mob/camera/netrun_entity/proc/is_stunned()
	return world.time < combat_stun_until

/// Status changes wake the owner's UI and other sessions observing this process.
/mob/camera/netrun_entity/proc/combat_changed()
	console?.combat_context?.changed()
	host_node?.notify_changed(NETRUN_CHANGED_OCCUPANTS)

/mob/camera/netrun_entity/proc/apply_damage(amount, reason, datum/netrun_console/attacker)
	if(world.time < combat_shield_until)
		amount *= combat_shield_factor
	if(amount > 0)
		netrun_actor_attacked(attacker?.netrun_actor())
	take_integrity(amount, reason)

/mob/camera/netrun_entity/proc/apply_stun(duration)
	combat_stun_until = max(combat_stun_until, world.time + duration)
	combat_changed()
	to_chat(src, span_userdanger("Ваш процесс оглушён!"))

/mob/camera/netrun_entity/proc/apply_shield(pct, duration)
	var/new_factor = clamp(1 - pct / 100, 0.1, 1)
	// A weaker shield cannot replace or extend an active stronger one.
	if(world.time < combat_shield_until && new_factor > combat_shield_factor)
		return
	combat_shield_until = world.time + duration
	combat_shield_factor = new_factor
	combat_changed()

/mob/camera/netrun_entity/proc/apply_heal(amount)
	integrity = min(max_integrity, integrity + amount)
	combat_changed()
	to_chat(src, span_notice("Целостность восстановлена: [round(integrity)]/[max_integrity]."))

// MARK: Урон

/mob/camera/netrun_entity/proc/take_integrity(amount, reason)
	if(QDELETED(src))
		return
	integrity -= amount
	SEND_SIGNAL(src, COMSIG_NETRUN_ENTITY_INTEGRITY, integrity, max_integrity, reason)
	combat_changed()
	to_chat(src, span_userdanger("Целостность нарушена[reason ? ": [reason]" : ""]! ([max(0, round(integrity))]/[max_integrity])"))
	if(integrity <= 0)
		dissolve()

/// Принудительно выбросить сущность из текущего узла (команда purge)
/mob/camera/netrun_entity/proc/eject_from_node()
	var/datum/component/netrun_node/old = host_node
	var/datum/netrun_network/network = old?.network
	var/list/candidates = list()
	for(var/datum/component/netrun_node/candidate as anything in network?.nodes)
		if(candidate != old && candidate.is_online())
			candidates += candidate
	if(!length(candidates))
		var/datum/netrun_network/public = SSnetrun.get_network(NETRUN_LAN_PUBLIC)
		for(var/datum/component/netrun_node/candidate as anything in public.nodes)
			if(candidate.is_online())
				candidates += candidate
	to_chat(src, span_userdanger("Вас вычищают из узла [old?.address]!"))
	if(length(candidates))
		enter_node(pick(candidates))
	else
		leave_node()
		update_vision()

/mob/camera/netrun_entity/proc/host_lost()
	navigation?.cancel()
	var/datum/netrun_network/network = host_node?.network
	leave_node()
	if(QDELETED(src))
		return
	var/list/candidates = list()
	for(var/datum/component/netrun_node/node as anything in network?.nodes)
		if(node.is_online() && !QDELETED(node.parent))
			candidates += node
	if(!length(candidates))
		to_chat(src, span_userdanger("Узел-носитель уничтожен, бежать некуда."))
		dissolve()
		return
	enter_node(pick(candidates))
	take_integrity(20, "узел-носитель уничтожен")

/mob/camera/netrun_entity/netrun_traced(datum/netrun_console/traced)
	// Процесс не выбрасывает из узла: его предупреждают, что он обнаружен, и к нему идёт защита.
	to_chat(src, span_userdanger("Система защиты вас обнаружила! Заметайте следы (демон «ЗАМЕСТИ СЛЕДЫ») или уходите — к вам направляются процессы защиты."))

/mob/camera/netrun_entity/proc/dissolve()
	if(QDELETED(src))
		return
	if(dive_link?.body)
		to_chat(src, span_userdanger("Связь с сетью разорвана! Вас выбрасывает обратно в тело."))
		var/mob/living/carbon/body = dive_link.body
		return_to_body()
		body.adjustOrganLoss(ORGAN_SLOT_BRAIN, 30)
		body.Paralyze(10 SECONDS)
		return
	to_chat(src, span_userdanger("Ваш процесс распадается на шум."))
	host_node?.network?.add_log("Резидентный процесс [real_name] завершён.")
	ghostize(FALSE)
	qdel(src)

// MARK: Речь

/mob/camera/netrun_entity/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	if(client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, span_danger("Вы не можете говорить (мут)."))
			return
		if(!(ignore_spam || forced) && client.handle_spam_prevention(message, MUTE_IC))
			return
	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!length(message))
		return
	// Процессы, делящие узел, слышат друг друга напрямую по внутренней шине -
	// даже если у узла нет динамика для внешнего мира.
	var/heard_locally = FALSE
	for(var/mob/camera/netrun_entity/other as anything in host_node?.entities)
		to_chat(other, span_notice("\[шина [host_node.address]] [span_name(real_name)]: [message]"))
		if(other != src)
			heard_locally = TRUE
	if(!(SEND_SIGNAL(src, COMSIG_NETRUN_ENTITY_SPEAK, message, spans)) && !heard_locally)
		to_chat(src, span_warning("У этого узла нет доступного микрофона с динамиком. Речь остаётся во внутренней шине."))

/mob/camera/netrun_entity/emote(act, m_type = 1, message = null, intentional = FALSE, forced = FALSE)
	return

// MARK: Погружение

/// Нетраннер уходит в сеть: тело без сознания, разум - в сущности
/proc/netrun_start_dive(mob/living/carbon/body, datum/component/netrun_node/start)
	if(!body?.mind || !start)
		return
	var/mob/camera/netrun_entity/entity = new(start.physical_turf(), start)
	entity.set_net_name(body.real_name, "Нетраннер")
	entity.dive_link.attach(body, start)
	body.SetUnconscious(5 SECONDS)
	body.mind.transfer_to(entity)
	body.visible_message(span_notice("[body] обмякает, глаза закатываются под веки."))
	return entity

/mob/camera/netrun_entity/proc/return_to_body()
	return dive_link?.return_to_body()

/mob/camera/netrun_entity/proc/release_body()
	return dive_link?.release_body()

// MARK: Консоль сущности

/datum/netrun_console/entity
	name = "сознание"
	origin = NETRUN_ORIGIN_ENTITY
	tgui_title = "Сеть"
	initial_storage_capacity = 10 * NETRUN_STORAGE_SCALE

/datum/netrun_console/entity/New(atom/host, origin)
	. = ..()
	state_override = GLOB.always_state

/datum/netrun_console/entity/ui_status(mob/user, datum/ui_state/state)
	return user == host ? ..() : UI_CLOSE

/datum/netrun_console/entity/ui_interact(mob/user, datum/tgui/ui)
	if(user != host)
		return
	return ..()

/datum/netrun_console/entity/proc/entity()
	return host

/datum/netrun_console/entity/home_networks()
	. = list()
	var/mob/camera/netrun_entity/entity = host
	if(entity?.host_node?.network)
		. += entity.host_node.network

/datum/netrun_console/entity/is_home_network(datum/netrun_network/network, datum/netrun_path_tree/tree)
	var/mob/camera/netrun_entity/entity = host
	return network && entity?.host_node?.network == network

/datum/netrun_console/entity/has_uplink()
	return ..()

/datum/netrun_console/entity/user_access(fresh = FALSE)
	if(!fresh && access_cache)
		return access_cache
	. = credential_access(fresh)

/datum/netrun_console/entity/add_ui_context_sources(list/targets)
	// Body lifecycle and cable continuity belong to dive_link. Its ID was captured
	// on entry, so equipment changes in the unconscious body are not UI inputs.
	return

/// A connected shard remains in the unconscious body's implant, not in the process.
/datum/netrun_console/entity/eject_shard(mob/user)
	var/mob/camera/netrun_entity/entity = host
	if(entity?.dive_link?.body)
		log_line("Шард находится в теле; извлечь его из сети нельзя.", "bad")
		return
	return ..()

/datum/netrun_console/entity/log_source()
	return "резидентный процесс"

/datum/netrun_console/entity/needs_live_refresh()
	. = ..()
	if(.)
		return
	var/mob/camera/netrun_entity/entity = host
	if(!entity)
		return FALSE
	if(get_combat_encounter()?.active)
		return FALSE
	// Integrity self-repair, stun/shield windows, hop cooldown and auto-travel all advance by time.
	return entity.integrity < entity.max_integrity || entity.is_stunned() || world.time < entity.combat_shield_until || world.time < entity.next_hop || entity.navigation?.is_active()

/datum/netrun_console/entity/process_tick(delta)
	. = ..()
	var/mob/camera/netrun_entity/entity = host
	entity?.process_tick(delta)

/datum/netrun_console/entity/host_actions()
	. = ..()
	var/mob/camera/netrun_entity/entity = host
	if(entity?.dive_link?.body)
		. += list(list("id" = "return", "name" = "Вернуться в тело", "icon" = "person-walking-arrow-right"))

/datum/netrun_console/entity/host_act(action, list/params, mob/user)
	var/mob/camera/netrun_entity/entity = host
	if(user != entity)
		return FALSE
	if(entity?.dispatch_module_action(action, params, user))
		return TRUE
	return ..()

/datum/netrun_console/entity/entity_data()
	var/mob/camera/netrun_entity/entity = host
	if(!entity)
		return null
	return list(
		"name" = entity.real_name,
		"persona" = entity.get_persona().ui_payload(),
		"integrity" = round(entity.integrity),
		"max_integrity" = entity.max_integrity,
		"host" = entity.host_node?.address,
		"host_name" = entity.host_node?.get_name(),
		"diving" = !!entity.dive_link?.body,
		"travel" = entity.navigation?.ui_payload(),
	)

/datum/action/innate/netrun_console
	name = "Сеть"
	desc = "Открыть карту сети."
	button_icon_state = "camera_jump"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	background_icon_state = "bg_tech_blue"

/datum/action/innate/netrun_console/Activate()
	var/mob/camera/netrun_entity/entity = owner
	if(istype(entity))
		entity.console.ui_interact(entity)

/datum/action/innate/netrun_rename
	name = "Переименовать"
	desc = "Задать имя процесса."
	button_icon_state = "repeat"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	background_icon_state = "bg_tech_blue"

/datum/action/innate/netrun_rename/Activate()
	var/mob/camera/netrun_entity/entity = owner
	if(!istype(entity))
		return
	var/new_name = tgui_input_text(entity, "Имя процесса", "Переименование", entity.real_name, 42)
	new_name = reject_bad_name(new_name, allow_numbers = TRUE)
	if(!new_name)
		return
	entity.rename_persona(new_name)
	to_chat(entity, span_notice("Имя изменено на [new_name]."))
