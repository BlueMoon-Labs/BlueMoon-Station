GLOBAL_DATUM(antag_training_spawner, /obj/effect/mob_spawn/antag_training)
GLOBAL_LIST_EMPTY(antag_training_sessions)
GLOBAL_LIST_EMPTY(antag_training_pending)
GLOBAL_LIST_EMPTY(antag_training_arenas)
GLOBAL_LIST_EMPTY(antag_training_free_levels)
GLOBAL_LIST_EMPTY(antag_training_rooms)
GLOBAL_VAR_INIT(antag_training_building, FALSE)
GLOBAL_VAR_INIT(antag_training_work_tick, -1)
GLOBAL_VAR_INIT(antag_training_work_usage, 0)
GLOBAL_VAR_INIT(antag_training_round_end_hooked, FALSE)

/obj/effect/mob_spawn/antag_training
	name = "training ground entrance"
	job_description = "Тренировочный полигон"
	mob_name = "участник тренировки"
	short_desc = "Арены, тир, противники, лаборатория и учебные роли. Одному или с друзьями."
	flavour_text = "Войдите на общий полигон своей куклой из активного слота персонажа или стандартным учебным персонажем. Пульт выдаёт снаряжение, создаёт цели, восстанавливает здоровье и меняет учебную роль."
	important_info = "Тренировка изолирована от раунда. Выйти можно в призрака с прежними ограничениями на вход в игру или в Гост-Кафе; с концом раунда сеанс закрывается. Совместный полигон предполагает добровольные бои и эксперименты между участниками."
	roundstart = FALSE
	death = FALSE
	uses = -1
	permanent = TRUE
	skip_reentry_check = TRUE
	banType = ROLE_GHOSTROLE
	category = "misc"

/obj/effect/mob_spawn/antag_training/can_latejoin()
	return FALSE

/obj/effect/mob_spawn/antag_training/allow_spawn(mob/user, silent = FALSE)
	return isobserver(user) && user.client && SSticker.HasRoundStarted() && !GLOB.antag_training_sessions[user.ckey] && !(user.ckey in GLOB.antag_training_pending)

/obj/effect/mob_spawn/antag_training/attack_ghost(mob/user, latejoinercalling)
	if(!allow_spawn(user) || jobban_isbanned(user, banType) || antag_training_round_over(user))
		return FALSE
	var/datum/antag_training_catalog/catalog = new(user, src)
	if(SStgui.get_open_ui(user, catalog))
		return TRUE
	qdel(catalog)
	return FALSE

/obj/effect/mob_spawn/antag_training/proc/begin_training(mob/user, program_type, use_character, role_id)
	if(!allow_spawn(user) || jobban_isbanned(user, banType))
		return null
	return start_antag_training(user, program_type, use_character, null, role_id)

/obj/effect/mob_spawn/antag_training/proc/catalog_closed(mob/viewer)
	return

/area/antag_training
	name = "Training Grounds"
	hidden = TRUE
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	area_flags = NO_ALERTS
	var/datum/antag_training_arena/arena

/area/antag_training/Entered(atom/movable/mover, atom/oldloc)
	if(!isobserver(mover) && arena && !arena.finished && oldloc && get_area(oldloc) != src && mover.training_origin?.resolve() != arena)
		mover.forceMove(get_turf(oldloc) || SSmapping.get_station_center())
		return
	return ..()

/datum/antag_training_arena
	var/code
	var/obj/machinery/telecomms/allinone/antag_training/relay
	var/ready = FALSE
	var/finished = FALSE
	var/resetting = FALSE
	var/reset_zone_id
	var/list/members = list()
	var/list/targets = list()
	var/list/target_minds = list()
	var/list/zones = list()
	var/list/datum/antag_training_sector/sectors = list()
	var/datum/antag_training_hub/hub
	var/list/datum/weakref/created_atoms = list()
	var/list/datum/weakref/issued_items = list()
	var/list/datum/weakref/placed_structures = list()
	var/datum/turf_reservation/reservation
	var/datum/space_level/private_level
	var/area/antag_training/room
	var/turf/entry_turf
	var/supply_count = 0
	var/last_supply_prune = -1
	var/next_target_id = 0
	var/next_spawn_at = 0
	var/next_reset_at = 0
	var/pending_reset_zone
	var/list/reset_votes = list()
	var/reset_vote_timer
	var/reset_vote_deadline = 0
	var/next_reset_request_at = 0
	var/empty_grace = ANTAG_TRAINING_EMPTY_GRACE
	var/close_timer

/datum/antag_training_arena/proc/prepare()
	if(GLOB.antag_training_building || length(GLOB.antag_training_arenas) >= ANTAG_TRAINING_MAX_ARENAS)
		return FALSE
	code = "shared"
	GLOB.antag_training_arenas[code] = src
	// Рантайм внутри build() возвращает сюда null.
	if(build() == TRUE)
		return TRUE
	GLOB.antag_training_building = FALSE
	GLOB.antag_training_arenas -= code
	code = null
	return FALSE

/datum/antag_training_arena/proc/build()
	GLOB.antag_training_building = TRUE
	if(length(GLOB.antag_training_free_levels))
		private_level = pick_n_take(GLOB.antag_training_free_levels)
	else
		private_level = SSmapping.add_new_zlevel("Тренировочный полигон", list(ZTRAIT_ANTAG_TRAINING = TRUE, ZTRAIT_VIRTUAL_REALITY = TRUE, ZTRAIT_AWAY = TRUE))
	GLOB.antag_training_building = FALSE
	if(!private_level)
		return FALSE
	set_level_gate(TRUE)
	var/level = private_level.z_value
	var/list/available = block(locate(1, 1, level), locate(ANTAG_TRAINING_SIZE, ANTAG_TRAINING_SIZE, level))
	reservation = new
	reservation.reserved_turfs = available
	reservation.width = ANTAG_TRAINING_SIZE
	reservation.height = ANTAG_TRAINING_SIZE
	reservation.bottom_left_coords = list(1, 1, level)
	reservation.top_right_coords = list(ANTAG_TRAINING_SIZE, ANTAG_TRAINING_SIZE, level)
	room = GLOB.antag_training_rooms[private_level]
	if(!room)
		room = new
		GLOB.antag_training_rooms[private_level] = room
	room.arena = src
	for(var/turf/tile as anything in available)
		room.contents += tile
		yield_work()
	build_zones()
	build_ground()
	hub = new(src)
	entry_turf = (hub.load() && hub.landmark_turf("hub_arrival")) || locate(28, 28, level)
	relay = new(locate(1, 1, level))
	ready = TRUE
	return TRUE

/datum/controller/subsystem/mapping/proc/preload_training_levels()
	while(length(GLOB.antag_training_free_levels) + length(GLOB.antag_training_arenas) < ANTAG_TRAINING_MAX_ARENAS)
		GLOB.antag_training_free_levels += add_new_zlevel("Тренировочный полигон", list(ZTRAIT_ANTAG_TRAINING = TRUE, ZTRAIT_VIRTUAL_REALITY = TRUE, ZTRAIT_AWAY = TRUE))
		CHECK_TICK

/datum/antag_training_arena/proc/yield_work()
	while(TRUE)
		if(world.time != GLOB.antag_training_work_tick)
			GLOB.antag_training_work_tick = world.time
			GLOB.antag_training_work_usage = TICK_USAGE_REAL
		// Отложенная работа не наследует остаток квоты последней подсистемы MC.
		if(ANTAG_TRAINING_TICK_FREE && TICK_USAGE_TO_MS(GLOB.antag_training_work_usage) < ((finished && !length(members)) ? ANTAG_TRAINING_CLOSE_BUDGET_MS : ANTAG_TRAINING_WORK_BUDGET_MS))
			return
		stoplag()

/// Вышел последний участник: арена ждёт возвращения, вход в это время попадает в неё же.
/datum/antag_training_arena/proc/schedule_close()
	if(finished)
		return
	if(!empty_grace)
		begin_cleanup()
		return
	cancel_close()
	close_timer = addtimer(CALLBACK(src, PROC_REF(close_if_empty)), empty_grace, TIMER_STOPPABLE)

/datum/antag_training_arena/proc/close_if_empty()
	close_timer = null
	if(!length(members))
		begin_cleanup()

/datum/antag_training_arena/proc/cancel_close()
	deltimer(close_timer)
	close_timer = null

/datum/antag_training_arena/proc/begin_cleanup()
	if(finished)
		return
	cancel_close()
	finished = TRUE
	ready = FALSE
	duel?.finish("Полигон закрывается.")
	cancel_reset()
	INVOKE_ASYNC(src, PROC_REF(cleanup))

/datum/antag_training_arena/proc/cleanup()
	while(resetting || sectors_busy() || hub?.busy())
		stoplag()
	dispose_contents(TRUE)
	qdel(src)

/datum/antag_training_arena/proc/dispose_contents(yielding = FALSE)
	QDEL_NULL(relay)
	for(var/mob/dead/observer/observer in GLOB.dead_mob_list)
		if(owns_area(get_area(observer)))
			observer.forceMove(SSmapping.get_station_center())
	QDEL_LIST(target_minds)
	// Хаб целиком убирается раньше поштучной очистки: сети под его полом удаляются пачками.
	hub?.release(yielding)
	var/list/created_copy = created_atoms.Copy()
	created_atoms.Cut()
	for(var/datum/weakref/created_ref as anything in created_copy)
		dispose_atom(created_ref?.resolve())
		if(yielding)
			yield_work()
	QDEL_LIST(targets)
	issued_items.Cut()
	placed_structures.Cut()
	for(var/sector_id in sectors)
		var/datum/antag_training_sector/sector = sectors[sector_id]
		sector.unload(yielding)
	if(reservation)
		release_tiles(reservation.reserved_turfs, yielding)
		reservation.reserved_turfs.Cut()
	QDEL_NULL(reservation)
	if(room)
		room.arena = null
	room = null

/datum/antag_training_arena/Destroy()
	finished = TRUE
	QDEL_NULL(duel)
	for(var/datum/antag_training_session/member as anything in members.Copy())
		member.finish()
	cancel_close()
	cancel_reset()
	dispose_contents()
	QDEL_LIST_ASSOC_VAL(sectors)
	QDEL_NULL(hub)
	set_level_gate(FALSE)
	GLOB.antag_training_arenas -= code
	if(private_level)
		GLOB.antag_training_free_levels |= private_level
	private_level = null
	entry_turf = null
	zones.Cut()
	return ..()

/// Удаляет атом полигона; шкаф сначала теряет содержимое, иначе высыпал бы его на клетку под повторную уборку.
/datum/antag_training_arena/proc/dispose_atom(atom/movable/thing)
	if(QDELETED(thing))
		return
	if(istype(thing, /obj/structure/closet))
		for(var/atom/movable/inside as anything in thing.contents.Copy())
			dispose_atom(inside)
	if(isliving(thing))
		var/mob/living/body = thing
		QDEL_NULL(body.mind)
	qdel(thing)

/datum/antag_training_arena/proc/clear_tile(turf/tile, preserve_players = FALSE)
	var/list/handled = list()
	// Шкафы и машины при удалении высыпают содержимое на клетку - его забирает следующий проход.
	for(var/pass in 1 to ANTAG_TRAINING_CLEAR_PASSES)
		var/list/batch = tile.contents - handled
		if(!length(batch))
			return
		handled += batch
		for(var/atom/movable/thing as anything in batch)
			if(isobserver(thing) || istype(thing, /atom/movable/lighting_object) || thing == relay)
				continue
			if(preserve_players)
				var/protected = FALSE
				for(var/datum/antag_training_session/member as anything in members)
					if(thing.contains_atom(member.current_body))
						protected = TRUE
						break
				if(protected)
					continue
			dispose_atom(thing)

/datum/antag_training_session
	var/player_key
	var/datum/weakref/return_mind
	var/return_name
	var/return_can_reenter = FALSE
	var/return_started_as_observer
	var/turf/return_turf
	var/datum/weakref/return_body
	var/datum/weakref/return_pod
	var/mob/living/carbon/human/avatar
	/// Живое тело или камера-моб роли (оверминд, болезнь): камерам сеанс не меняет здоровье и защиту центра.
	var/mob/current_body
	var/datum/mind/avatar_mind
	var/datum/antag_training_program/program
	var/datum/antag_training_role/role
	var/datum/preferences/character_preferences
	var/datum/antag_training_arena/arena
	var/datum/action/antag_training_controls/controls
	var/datum/action/antag_training_exit/exit_action
	var/datum/tgui_alert/async/antag_training_exit/exit_prompt
	var/exit_prompt_type = /datum/tgui_alert/async/antag_training_exit
	var/disconnected_at = 0
	var/connected = FALSE
	var/finished = FALSE
	var/resetting = FALSE
	var/next_supply_at = 0
	var/next_heal_at = 0
	var/next_restart_at = 0
	var/next_action_at = 0
	var/recovery_timer
	var/defeats = 0
	var/auto_recover = TRUE
	var/cleaning_personal = FALSE

/datum/antag_training_session/New(program_type = /datum/antag_training_program/free, datum/preferences/selected_preferences, role_id = ANTAG_TRAINING_ROLE_DEFAULT)
	program = new program_type
	character_preferences = selected_preferences
	role = antag_training_role(role_id) || antag_training_role(ANTAG_TRAINING_ROLE_DEFAULT)

/datum/antag_training_session/proc/prepare(datum/antag_training_arena/shared_arena)
	shared_arena ||= GLOB.antag_training_arenas["shared"]
	if(shared_arena)
		while(!QDELETED(shared_arena) && !shared_arena.finished && !shared_arena.ready)
			stoplag()
		if(QDELETED(shared_arena) || shared_arena.finished)
			return FALSE
	arena = shared_arena
	if(!arena)
		arena = new
		if(!arena.prepare())
			return FALSE
	arena.cancel_close()
	arena.cancel_reset()
	arena.members += src
	return create_avatar()

/// Кукла участника: внешность из слота персонажа или учебное имя и форма полигона.
/datum/antag_training_session/proc/build_avatar_body(turf/where)
	var/mob/living/carbon/human/body = new(where)
	if(character_preferences)
		character_preferences.copy_to(body, roundstart_checks = FALSE, initial_spawn = TRUE)
		character_preferences.apply_tattoos_to_human(body)
	else
		body.real_name = return_name || "Участник [length(arena.members)]"
		body.name = body.real_name
	body.equipOutfit(/datum/outfit/antag_training)
	mark_kit(body)
	return body

/datum/antag_training_session/proc/create_avatar()
	avatar = build_avatar_body(arena.entry_turf)
	avatar.mind_initialize()
	avatar_mind = avatar.mind
	if(program.allowed_roles & role.kind)
		if(role.kind & ANTAG_TRAINING_ROLES_SILICON)
			var/datum/antag_training_role/silicon/silicon_role = role
			if(!silicon_role.build_body(src))
				return FALSE
			discard_body(avatar)
			avatar = null
		else
			if(!role.apply(src, avatar))
				return FALSE
			mark_kit(avatar)
	avatar_mind.add_antag_datum(/datum/antagonist/ghost_role/antag_training)
	if(!program.setup(src))
		return FALSE
	mark_kit(avatar_mind.current)
	controls = new(src)
	exit_action = new(src)
	RegisterSignal(avatar_mind, COMSIG_MIND_TRANSFER, PROC_REF(on_body_transfer))
	bind_body(avatar_mind.current)
	if(program.sector && !scenario_placing)
		INVOKE_ASYNC(src, PROC_REF(enter_sector), arena.sectors[program.sector])
	return TRUE

/// Клетка, куда сеанс ставит тело при входе в сектор программы.
/datum/antag_training_program/proc/sector_entry_turf(datum/antag_training_sector/sector)
	return sector.spawn_turf()

/// Меняет должность и пересобирает тело той же программой. override_scenario - осознанное решение админа стенда поверх слота партии.
/datum/antag_training_session/proc/set_role(role_id, override_scenario = FALSE)
	var/datum/antag_training_role/next_role = antag_training_role(role_id)
	if(!next_role || next_role == role || !antag_training_role_compatible(program.type, next_role))
		return FALSE
	if(!override_scenario && scenario_role_locked())
		return FALSE
	var/datum/antag_training_role/previous = role
	role = next_role
	if(!restart(program.type, TRUE))
		role = previous
		return FALSE
	log_game("Полигон: [key_name(current_body)] меняет должность «[previous.name]» на «[role.name]»[override_scenario ? " решением админа стенда поверх слота сценария" : ""].")
	return TRUE

/datum/antag_training_session/proc/enter_sector(datum/antag_training_sector/sector)
	var/mob/body = current_body
	if(sector?.entry_refusal(src))
		practice_message(sector.entry_refusal(src))
		return FALSE
	var/fresh = sector?.state != ANTAG_TRAINING_SECTOR_READY
	if(!sector || !sector.load() || finished || arena.finished || QDELETED(body) || current_body != body)
		return FALSE
	// За время загрузки сектор могла занять группа.
	if(sector.entry_refusal(src))
		practice_message(sector.entry_refusal(src))
		return FALSE
	body.forceMove(program.sector_entry_turf(sector))
	if(fresh)
		play_training_sound(ANTAG_TRAINING_SOUND_SECTOR_LOAD)
	return TRUE

/datum/antag_training_session/proc/connect(mob/user, obj/machinery/antag_training_pod/pod)
	if(finished || QDELETED(user) || !current_body || connected || antag_training_round_over(user))
		return FALSE
	if(pod ? (QDELETED(pod) || pod.occupant != user || !isliving(user) || user.loc != pod) : !isobserver(user))
		return FALSE
	player_key = user.ckey || REF(src)
	if(GLOB.antag_training_sessions[player_key])
		return FALSE
	return_mind = user.mind ? WEAKREF(user.mind) : null
	return_name = user.real_name
	return_turf = get_turf(user)
	if(pod)
		return_body = WEAKREF(user)
		return_pod = WEAKREF(pod)
		return_can_reenter = FALSE
		pod.hold(user, src)
		exit_action.update_destination()
	else
		var/mob/dead/observer/observer = user
		return_can_reenter = observer.can_reenter_corpse
		return_started_as_observer = observer.started_as_observer
	GLOB.antag_training_sessions[player_key] = src
	if(!GLOB.antag_training_round_end_hooked)
		GLOB.antag_training_round_end_hooked = TRUE
		SSticker.OnRoundend(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(antag_training_round_end)))
	connected = TRUE
	// Мини-станция и площадки хаба дорогие: грузятся, когда на полигон пришёл живой игрок, а не при сборке арены.
	if(arena.hub)
		INVOKE_ASYNC(arena.hub, TYPE_PROC_REF(/datum/antag_training_hub, load_station))
	log_game("[key_name(user)] входит на тренировочный полигон[pod ? " из капсулы Гост-Кафе" : ""], программа «[program.name]».")
	user.transfer_ckey(current_body, FALSE)
	if(!character_preferences && !program.avatar_name && current_body == avatar)
		current_body.real_name = return_name
		current_body.name = return_name
	START_PROCESSING(SSprocessing, src)
	play_training_sound(ANTAG_TRAINING_SOUND_ENTER)
	to_chat(current_body, span_boldnotice("Полигон готов. «Пульт полигона» открывает зоны, снаряжение, цели и учебные роли. Голографический стенд в каждой зоне называет её упражнения, нажатие на него открывает их в пульте. «[exit_action.name]» завершает ваш сеанс. После смерти вы восстановитесь в вестибюле хаба."))
	if(current_body.client)
		ui_interact(current_body)
	return TRUE

/datum/antag_training_session/proc/bind_body(mob/body)
	if(arena?.duel?.includes(src))
		arena.duel.finish("Дуэль завершена: участник сменил тело.")
	if(current_body)
		current_body.clear_alert("antag_training_safe")
		UnregisterSignal(current_body, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING, COMSIG_MOB_GHOSTIZE, COMSIG_MOVABLE_MOVED, COMSIG_MOB_PRE_PLAYER_CHANGE))
	current_body = body
	ADD_TRAIT(body, TRAIT_NO_MIDROUND_ANTAG, REF(src))
	ADD_TRAIT(body, TRAIT_EXEMPT_HEALTH_EVENTS, REF(src))
	if(isliving(body))
		RegisterSignal(body, COMSIG_MOB_DEATH, PROC_REF(on_death))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(body, COMSIG_MOB_GHOSTIZE, PROC_REF(on_ghostize))
	RegisterSignal(body, COMSIG_MOB_PRE_PLAYER_CHANGE, PROC_REF(on_body_taken))
	RegisterSignal(body, COMSIG_MOVABLE_MOVED, PROC_REF(update_safety))
	update_safety()
	controls.Grant(body)
	exit_action.Grant(body)
	exercise_run?.rebind()

/datum/antag_training_session/proc/on_body_taken(mob/source, mob/new_body, mob/old_body)
	SIGNAL_HANDLER
	if(isobserver(old_body) || (old_body?.ckey && old_body.ckey == player_key))
		return
	if(old_body?.mind != avatar_mind)
		to_chat(old_body, span_warning("Тело другого участника занято. Для проверки переноса разума используйте учебную цель."))
		return COMPONENT_STOP_MIND_TRANSFER

/datum/antag_training_session/proc/on_body_transfer(datum/mind/source, mob/new_body, mob/old_body)
	SIGNAL_HANDLER
	bind_body(new_body)

/datum/antag_training_session/proc/on_death()
	SIGNAL_HANDLER
	if(!recovery_timer)
		defeats++
		if(auto_recover)
			recovery_timer = addtimer(CALLBACK(src, PROC_REF(recover)), 3 SECONDS, TIMER_STOPPABLE)
	return COMPONENT_BLOCK_DEATH_BROADCAST

/datum/antag_training_session/proc/recover()
	recovery_timer = null
	if(finished || resetting || program.body_lost(src) || QDELETED(current_body))
		return
	// Ядро ИИ стоит на своём месте, его не переносят.
	var/place = isAI(current_body) ? "своём ядре" : "вестибюле хаба"
	if(!isAI(current_body))
		current_body.forceMove(arena.entry_turf)
	heal_self()
	play_training_sound(ANTAG_TRAINING_SOUND_RECOVER)
	to_chat(current_body, span_notice("Вы восстановлены в [place]. Можно продолжать тренировку."))

/datum/antag_training_session/proc/on_body_deleted()
	SIGNAL_HANDLER
	if(!resetting && !finished && !program.body_lost(src))
		finish(FALSE)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), src), 0)

/datum/antag_training_session/proc/on_ghostize()
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(finish)), 0)
	return COMPONENT_BLOCK_GHOSTING | COMPONENT_DO_NOT_PENALIZE_GHOSTING

/datum/antag_training_session/process()
	if(QDELETED(current_body))
		finish()
		return
	update_practice()
	if(current_body.client)
		disconnected_at = 0
	else if(!disconnected_at)
		disconnected_at = world.time
	else if(world.time >= disconnected_at + ANTAG_TRAINING_DISCONNECT_GRACE)
		finish()

/datum/antag_training_session/proc/restore_player(to_cafe = FALSE)
	var/mob/living/body = return_body?.resolve()
	var/obj/machinery/antag_training_pod/pod = return_pod?.resolve() || body?.loc
	var/to_body = body && !body.key
	if(to_body)
		current_body?.transfer_ckey(body, FALSE)
		// Автокрио считает простой тела от момента отключения игрока, а не от входа в капсулу.
		if(!body.client && current_body)
			body.lastclienttime = client_left_at()
	if(istype(pod) && (src in pod.sessions))
		pod.release(src)
	if(to_body)
		return body
	var/mob/dead/observer/observer = restore_observer()
	if(to_cafe)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(antag_training_send_to_cafe), observer)
	return observer

/datum/antag_training_session/proc/restore_observer()
	var/datum/mind/source_mind = return_mind?.resolve()
	var/mob/dead/observer/observer = new(return_turf, source_mind?.current)
	observer.mind = source_mind
	observer.real_name = return_name
	observer.name = return_name
	observer.can_reenter_corpse = return_can_reenter
	observer.started_as_observer = return_started_as_observer
	current_body?.transfer_ckey(observer, FALSE)
	if(!observer.client && current_body)
		observer.lastclienttime = client_left_at()
	return observer

/// Когда игрок покинул тело сеанса: у камер-мобов нет своей отметки, её заменяет замеченное сеансом отключение.
/datum/antag_training_session/proc/client_left_at()
	var/mob/living/body = current_body
	if(istype(body))
		return body.lastclienttime
	return disconnected_at || world.time

/datum/antag_training_session/proc/request_exit(mob/user)
	if(finished || user != current_body)
		return FALSE
	if(return_body)
		finish()
		return TRUE
	// Без кэша банов проверка уходит в БД и спит, поэтому флаг вопроса проверяется уже после неё.
	var/cafe_banned = jobban_isbanned(user, ROLE_GHOSTCAFE)
	if(finished || user != current_body || exit_prompt)
		return FALSE
	var/list/choices = list(ANTAG_TRAINING_EXIT_GHOST)
	if(!cafe_banned)
		choices += ANTAG_TRAINING_EXIT_CAFE
	choices += ANTAG_TRAINING_EXIT_STAY
	// Без ожидания ответа в кадре: окно ссылается на сеанс и куклу только слабо.
	var/datum/tgui_alert/async/antag_training_exit/prompt = new exit_prompt_type(user, "Куда вернуться после тренировки?", "Выход с полигона", choices, CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(antag_training_exit_answered), WEAKREF(src), WEAKREF(user)), 0, TRUE)
	prompt.session_ref = WEAKREF(src)
	exit_prompt = prompt
	prompt.ui_interact(user)
	if(exit_prompt == prompt && !SStgui.get_open_ui(user, prompt))
		exit_prompt = null
		qdel(prompt)
		return FALSE
	return TRUE

/datum/antag_training_session/proc/answer_exit(mob/user, choice)
	exit_prompt = null
	if(finished || QDELETED(user) || user != current_body || !(choice in list(ANTAG_TRAINING_EXIT_GHOST, ANTAG_TRAINING_EXIT_CAFE)))
		return FALSE
	finish(to_cafe = (choice == ANTAG_TRAINING_EXIT_CAFE))
	return TRUE

/proc/antag_training_exit_answered(datum/weakref/session_ref, datum/weakref/user_ref, choice)
	var/datum/antag_training_session/session = session_ref.resolve()
	session?.answer_exit(user_ref.resolve(), choice)

/datum/tgui_alert/async/antag_training_exit
	var/datum/weakref/session_ref

/datum/tgui_alert/async/antag_training_exit/ui_close(mob/user)
	. = ..()
	var/datum/antag_training_session/session = session_ref?.resolve()
	if(session?.exit_prompt == src)
		session.exit_prompt = null

/datum/antag_training_session/proc/finish(delete_session = TRUE, to_cafe = FALSE)
	if(finished)
		return
	finished = TRUE
	QDEL_NULL(exit_prompt)
	if(arena?.duel?.includes(src))
		arena.duel.finish("Дуэль завершена: участник вышел.")
	STOP_PROCESSING(SSprocessing, src)
	if(connected)
		. = restore_player(to_cafe)
	GLOB.antag_training_sessions -= player_key
	if(delete_session)
		qdel(src)

/proc/antag_training_round_end()
	for(var/player_key in GLOB.antag_training_sessions.Copy())
		var/datum/antag_training_session/session = GLOB.antag_training_sessions[player_key]
		var/mob/returned = session?.finish()
		if(returned)
			to_chat(returned, span_notice("Раунд окончен: сеанс полигона завершён."))

/proc/antag_training_round_over(mob/user)
	if(SSticker.current_state < GAME_STATE_FINISHED)
		return FALSE
	to_chat(user, span_warning("Раунд окончен: полигон закрыт до следующего раунда."))
	return TRUE

/datum/antag_training_session/proc/clear_avatar()
	stop_practice()
	stop_exercise()
	recipe_cache = null
	recipe_cache_size = -1
	deltimer(recovery_timer)
	recovery_timer = null
	if(current_body)
		UnregisterSignal(current_body, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING, COMSIG_MOB_GHOSTIZE, COMSIG_MOVABLE_MOVED, COMSIG_MOB_PRE_PLAYER_CHANGE))
	if(avatar_mind)
		UnregisterSignal(avatar_mind, COMSIG_MIND_TRANSFER)
	QDEL_NULL(controls)
	QDEL_NULL(exit_action)
	QDEL_NULL(avatar_mind)
	if(current_body && current_body != avatar)
		discard_body(current_body)
	current_body = null
	discard_body(avatar)
	avatar = null

/datum/antag_training_session/proc/discard_body(mob/body)
	for(var/datum/antag_training_session/member as anything in arena?.members)
		if(member != src && member.current_body == body)
			return
	qdel(body)

/datum/antag_training_session/Destroy()
	finish(FALSE)
	clear_avatar()
	QDEL_NULL(program)
	character_preferences = null
	if(arena)
		arena.members -= src
		arena.member_left(src)
		if(!length(arena.members) && !QDELETED(arena))
			arena.schedule_close()
		else if(!arena.finished && weak_reference)
			INVOKE_ASYNC(arena, TYPE_PROC_REF(/datum/antag_training_arena, cleanup_owner), weak_reference)
	arena = null
	return_mind = null
	return_turf = null
	return_body = null
	return_pod = null
	return ..()

/datum/antag_training_session/proc/can_control(mob/user)
	return !finished && !resetting && !arena?.finished && !QDELETED(user) && user == current_body && arena?.owns_area(get_area(user))

/datum/antagonist/ghost_role/antag_training
	name = "Участник тренировки"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	prevent_roundtype_conversion = FALSE

/datum/antagonist/ghost_role/antag_training/create_team(datum/team/team)
	return

/datum/action/antag_training_controls
	name = "Пульт полигона"
	desc = "Зоны, снаряжение, цели, здоровье и учебные роли."
	icon_icon = 'icons/obj/machines/sleeper.dmi'
	button_icon_state = "sleeper"
	var/datum/antag_training_session/session

/datum/action/antag_training_controls/New(datum/antag_training_session/training)
	..()
	session = training

/datum/action/antag_training_controls/Trigger()
	if(!session?.can_control(owner))
		return FALSE
	session.ui_interact(owner)
	return TRUE

/datum/action/antag_training_controls/Destroy()
	session = null
	return ..()

/datum/action/antag_training_exit
	name = "Выйти с полигона"
	desc = "Вернуться в призрака или прийти в Гост-Кафе. Пустой полигон несколько минут ждёт возвращения, потом закрывается."
	icon_icon = 'icons/mob/actions/actions_vr.dmi'
	button_icon_state = "logout"
	var/datum/antag_training_session/session

/datum/action/antag_training_exit/New(datum/antag_training_session/training)
	..()
	session = training
	update_destination()

/datum/action/antag_training_exit/proc/update_destination()
	if(!session?.return_body)
		return
	name = "Вернуться в тело"
	desc = "Проснуться в капсуле Гост-Кафе. Пустой полигон несколько минут ждёт возвращения, потом закрывается."
	UpdateButtons()

/datum/action/antag_training_exit/Trigger()
	if(!session || owner != session.current_body)
		return FALSE
	INVOKE_ASYNC(session, TYPE_PROC_REF(/datum/antag_training_session, request_exit), owner)
	return TRUE

/datum/action/antag_training_exit/Destroy()
	session = null
	return ..()

/datum/outfit/antag_training
	name = "Training participant"
	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/sneakers/black
	back = /obj/item/storage/backpack
	l_pocket = /obj/item/restraints/handcuffs
