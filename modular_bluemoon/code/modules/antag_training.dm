GLOBAL_DATUM(antag_training_spawner, /obj/effect/mob_spawn/antag_training)
GLOBAL_LIST_EMPTY(antag_training_sessions)
GLOBAL_LIST_EMPTY(antag_training_pending)
GLOBAL_LIST_EMPTY(antag_training_arenas)
GLOBAL_LIST_EMPTY(antag_training_free_levels)
GLOBAL_LIST_EMPTY(antag_training_rooms)
GLOBAL_VAR_INIT(antag_training_building, FALSE)
GLOBAL_VAR_INIT(antag_training_work_tick, -1)
GLOBAL_VAR_INIT(antag_training_work_usage, 0)

/obj/effect/mob_spawn/antag_training
	name = "training ground entrance"
	job_description = "Тренировочный полигон"
	mob_name = "участник тренировки"
	short_desc = "Арены, тир, противники, лаборатория и учебные роли. Одному или с друзьями."
	flavour_text = "Войдите на общий полигон для совместных тренировок. Пульт выдаёт снаряжение, создаёт цели, восстанавливает здоровье и меняет учебную роль."
	important_info = "Тренировка изолирована от раунда. Возвращение в призрака сохраняет прежние ограничения на вход в игру. Совместный полигон предполагает добровольные бои и эксперименты между участниками."
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
	if(!allow_spawn(user) || jobban_isbanned(user, banType))
		return FALSE
	var/list/programs = list()
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		programs[initial(program_type.name)] = program_type
	var/choice = tgui_input_list(user, "Выберите личную программу для общего полигона. Вход означает согласие на совместные тренировки и PvP. Свою роль можно сменить позже.", job_description, programs)
	if(!choice || QDELETED(user) || !allow_spawn(user) || jobban_isbanned(user, banType))
		return FALSE
	var/datum/antag_training_arena/shared = GLOB.antag_training_arenas["shared"]
	if(shared?.finished)
		to_chat(user, span_notice("Общий полигон очищается. Попробуйте немного позже."))
		return FALSE
	to_chat(user, span_notice("Подготавливаем учебного персонажа и полигон. Это может занять несколько секунд."))
	var/player_key = user.ckey
	GLOB.antag_training_pending |= player_key
	var/datum/antag_training_session/session = new(programs[choice])
	var/prepared = session.prepare()
	GLOB.antag_training_pending -= player_key
	if(!prepared || QDELETED(user) || !allow_spawn(user) || jobban_isbanned(user, banType) || !session.connect(user))
		qdel(session)
		return FALSE
	return TRUE

/area/antag_training
	name = "Тренировочный полигон"
	hidden = TRUE
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	area_flags = RADIO_BLACKOUT | NO_ALERTS
	var/datum/antag_training_arena/arena

/area/antag_training/Entered(atom/movable/mover, atom/oldloc)
	if(!isobserver(mover) && arena && !arena.finished && oldloc && get_area(oldloc) != src && mover.training_origin?.resolve() != arena)
		mover.forceMove(get_turf(oldloc) || SSmapping.get_station_center())
		return
	return ..()

/datum/antag_training_arena
	var/code
	var/ready = FALSE
	var/finished = FALSE
	var/resetting = FALSE
	var/reset_zone_id
	var/list/members = list()
	var/list/targets = list()
	var/list/target_minds = list()
	var/list/zones = list()
	var/list/datum/weakref/created_atoms = list()
	var/list/datum/weakref/issued_items = list()
	var/list/datum/weakref/placed_structures = list()
	var/datum/turf_reservation/reservation
	var/datum/space_level/private_level
	var/area/antag_training/room
	var/turf/entry_turf
	var/supply_count = 0
	var/next_target_id = 0
	var/next_spawn_at = 0
	var/next_reset_at = 0
	var/pending_reset_zone
	var/list/reset_votes = list()
	var/reset_vote_timer
	var/reset_vote_deadline = 0
	var/next_reset_request_at = 0

/datum/antag_training_arena/proc/prepare()
	if(GLOB.antag_training_building || length(GLOB.antag_training_arenas) >= ANTAG_TRAINING_MAX_ARENAS)
		return FALSE
	GLOB.antag_training_building = TRUE
	code = "shared"
	GLOB.antag_training_arenas[code] = src
	if(length(GLOB.antag_training_free_levels))
		private_level = pick_n_take(GLOB.antag_training_free_levels)
	else
		private_level = SSmapping.add_new_zlevel("Тренировочный полигон", list(ZTRAIT_ANTAG_TRAINING = TRUE, ZTRAIT_VIRTUAL_REALITY = TRUE, ZTRAIT_AWAY = TRUE))
	GLOB.antag_training_building = FALSE
	if(!private_level)
		return FALSE
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
		SSmapping.used_turfs[tile] = reservation
		room.contents += tile
		yield_work()
	build_zones()
	build_ground()
	entry_turf = locate(28, 28, level)
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
		if(!TICK_CHECK && TICK_USAGE_TO_MS(GLOB.antag_training_work_usage) < ANTAG_TRAINING_WORK_BUDGET_MS)
			return
		stoplag()

/datum/antag_training_arena/proc/begin_cleanup()
	if(finished)
		return
	finished = TRUE
	ready = FALSE
	cancel_reset()
	INVOKE_ASYNC(src, PROC_REF(cleanup))

/datum/antag_training_arena/proc/cleanup()
	while(resetting)
		stoplag()
	dispose_contents(TRUE)
	qdel(src)

/datum/antag_training_arena/proc/dispose_contents(yielding = FALSE)
	if(room)
		for(var/mob/dead/observer/observer in GLOB.dead_mob_list)
			if(get_area(observer) == room)
				observer.forceMove(SSmapping.get_station_center())
	QDEL_LIST(target_minds)
	var/list/created_copy = created_atoms.Copy()
	created_atoms.Cut()
	for(var/datum/weakref/created_ref as anything in created_copy)
		var/atom/movable/created = created_ref?.resolve()
		if(isliving(created))
			var/mob/living/body = created
			QDEL_NULL(body.mind)
		qdel(created)
		if(yielding)
			yield_work()
	QDEL_LIST(targets)
	issued_items.Cut()
	placed_structures.Cut()
	if(reservation)
		SSmapping.used_turfs -= reservation.reserved_turfs
		for(var/turf/tile as anything in reservation.reserved_turfs)
			clear_tile(tile)
			GLOB.areas_by_type[world.area].contents += tile
			tile.ChangeTurf(/turf/open/space, /turf/open/space, CHANGETURF_SKIP)
			if(yielding)
				yield_work()
		reservation.reserved_turfs.Cut()
	QDEL_NULL(reservation)
	if(room)
		room.arena = null
	room = null

/datum/antag_training_arena/Destroy()
	finished = TRUE
	for(var/datum/antag_training_session/member as anything in members.Copy())
		member.finish()
	cancel_reset()
	dispose_contents()
	GLOB.antag_training_arenas -= code
	if(private_level)
		GLOB.antag_training_free_levels |= private_level
	private_level = null
	entry_turf = null
	zones.Cut()
	return ..()

/datum/antag_training_arena/proc/clear_tile(turf/tile, preserve_players = FALSE)
	for(var/atom/movable/thing in tile.contents.Copy())
		if(isobserver(thing) || istype(thing, /atom/movable/lighting_object))
			continue
		if(preserve_players)
			var/protected = FALSE
			for(var/datum/antag_training_session/member as anything in members)
				if(thing.contains_atom(member.current_body))
					protected = TRUE
					break
			if(protected)
				continue
		if(isliving(thing))
			var/mob/living/body = thing
			QDEL_NULL(body.mind)
		qdel(thing)

/datum/antag_training_session
	var/player_key
	var/datum/weakref/return_mind
	var/return_name
	var/return_can_reenter = FALSE
	var/return_started_as_observer
	var/turf/return_turf
	var/mob/living/carbon/human/avatar
	var/mob/living/current_body
	var/datum/mind/avatar_mind
	var/datum/antag_training_program/program
	var/datum/antag_training_arena/arena
	var/datum/action/antag_training_controls/controls
	var/datum/action/antag_training_exit/exit_action
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

/datum/antag_training_session/New(program_type = /datum/antag_training_program/free)
	program = new program_type

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
	arena.cancel_reset()
	arena.members += src
	return create_avatar()

/datum/antag_training_session/proc/create_avatar()
	avatar = new(arena.entry_turf)
	avatar.real_name = return_name || "Участник [length(arena.members)]"
	avatar.name = avatar.real_name
	avatar.mind_initialize()
	avatar_mind = avatar.mind
	avatar_mind.add_antag_datum(/datum/antagonist/ghost_role/antag_training)
	avatar.equipOutfit(/datum/outfit/antag_training)
	if(!program.setup(src))
		return FALSE
	controls = new(src)
	exit_action = new(src)
	RegisterSignal(avatar_mind, COMSIG_MIND_TRANSFER, PROC_REF(on_body_transfer))
	bind_body(avatar)
	return TRUE

/datum/antag_training_session/proc/connect(mob/dead/observer/user)
	if(finished || QDELETED(user) || !istype(user) || !current_body || connected)
		return FALSE
	player_key = user.ckey || REF(src)
	if(GLOB.antag_training_sessions[player_key])
		return FALSE
	return_mind = user.mind ? WEAKREF(user.mind) : null
	return_name = user.real_name
	return_can_reenter = user.can_reenter_corpse
	return_started_as_observer = user.started_as_observer
	return_turf = get_turf(user)
	GLOB.antag_training_sessions[player_key] = src
	connected = TRUE
	user.transfer_ckey(current_body, FALSE)
	current_body.real_name = return_name
	current_body.name = return_name
	START_PROCESSING(SSprocessing, src)
	to_chat(current_body, span_boldnotice("Полигон готов. «Пульт полигона» открывает зоны, снаряжение, цели и учебные роли. «Выйти в призрака» завершает ваш сеанс. После смерти вы восстановитесь в центре."))
	return TRUE

/datum/antag_training_session/proc/bind_body(mob/living/body)
	if(current_body)
		UnregisterSignal(current_body, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING, COMSIG_MOB_GHOSTIZE, COMSIG_MOVABLE_MOVED, COMSIG_MOB_PRE_PLAYER_CHANGE))
	current_body = body
	ADD_TRAIT(body, TRAIT_NO_MIDROUND_ANTAG, REF(src))
	ADD_TRAIT(body, TRAIT_EXEMPT_HEALTH_EVENTS, REF(src))
	RegisterSignal(body, COMSIG_MOB_DEATH, PROC_REF(on_death))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(body, COMSIG_MOB_GHOSTIZE, PROC_REF(on_ghostize))
	RegisterSignal(body, COMSIG_MOB_PRE_PLAYER_CHANGE, PROC_REF(on_body_taken))
	RegisterSignal(body, COMSIG_MOVABLE_MOVED, PROC_REF(update_safety))
	update_safety()
	controls.Grant(body)
	exit_action.Grant(body)

/datum/antag_training_session/proc/on_body_taken(mob/living/source, mob/living/new_body, mob/old_body)
	SIGNAL_HANDLER
	if(isobserver(old_body) || (old_body?.ckey && old_body.ckey == player_key))
		return
	if(old_body?.mind != avatar_mind)
		to_chat(old_body, span_warning("Тело другого участника занято. Для проверки переноса разума используйте учебную цель."))
		return COMPONENT_STOP_MIND_TRANSFER

/datum/antag_training_session/proc/on_body_transfer(datum/mind/source, mob/living/new_body, mob/living/old_body)
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
	if(finished || resetting || QDELETED(current_body))
		return
	current_body.forceMove(arena.entry_turf)
	heal_self()
	to_chat(current_body, span_notice("Вы восстановлены в центре. Можно продолжать тренировку."))

/datum/antag_training_session/proc/on_body_deleted()
	SIGNAL_HANDLER
	if(!resetting && !finished)
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
	if(current_body.client)
		disconnected_at = 0
	else if(!disconnected_at)
		disconnected_at = world.time
	else if(world.time >= disconnected_at + ANTAG_TRAINING_DISCONNECT_GRACE)
		finish()

/datum/antag_training_session/proc/restore_observer()
	var/datum/mind/source_mind = return_mind?.resolve()
	var/mob/dead/observer/observer = new(return_turf, source_mind?.current)
	observer.mind = source_mind
	observer.real_name = return_name
	observer.name = return_name
	observer.can_reenter_corpse = return_can_reenter
	observer.started_as_observer = return_started_as_observer
	current_body?.transfer_ckey(observer, FALSE)
	return observer

/datum/antag_training_session/proc/finish(delete_session = TRUE)
	if(finished)
		return
	finished = TRUE
	STOP_PROCESSING(SSprocessing, src)
	if(connected)
		. = restore_observer()
	GLOB.antag_training_sessions -= player_key
	if(delete_session)
		qdel(src)

/datum/antag_training_session/proc/clear_avatar()
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

/datum/antag_training_session/proc/discard_body(mob/living/body)
	for(var/datum/antag_training_session/member as anything in arena?.members)
		if(member != src && member.current_body == body)
			return
	qdel(body)

/datum/antag_training_session/Destroy()
	finish(FALSE)
	clear_avatar()
	QDEL_NULL(program)
	if(arena)
		arena.members -= src
		arena.member_left(src)
		if(!length(arena.members) && !QDELETED(arena))
			arena.begin_cleanup()
		else if(!arena.finished && weak_reference)
			INVOKE_ASYNC(arena, TYPE_PROC_REF(/datum/antag_training_arena, cleanup_owner), weak_reference)
	arena = null
	return_mind = null
	return_turf = null
	return ..()

/datum/antag_training_session/proc/can_control(mob/user)
	return !finished && !resetting && !arena?.finished && !QDELETED(user) && user == current_body && get_area(user) == arena?.room

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
	name = "Выйти в призрака"
	desc = "Вернуться в призрака. Полигон освободится после выхода последнего участника."
	icon_icon = 'icons/mob/actions/actions_vr.dmi'
	button_icon_state = "logout"
	var/datum/antag_training_session/session

/datum/action/antag_training_exit/New(datum/antag_training_session/training)
	..()
	session = training

/datum/action/antag_training_exit/Trigger()
	if(!session || owner != session.current_body)
		return FALSE
	session.finish()
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
