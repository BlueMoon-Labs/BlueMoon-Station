// PORT: tgstation@14140a6355d1 code/datums/ai/_ai_controller.dm
// Адаптации BlueMoon:
// - AI_STATUS_IDLE = полный сон (ноль обработки), у tg спящие ещё бродят;
// - сигналы: COMSIG_MOB_CLIENT_LOGIN/LOGOUT, COMSIG_MOVABLE_Z_CHANGED c
//   аргументами (old_z, new_z), COMSIG_PARENT_QDELETING/PREQDELETED;
// - idle_behavior - инстанс на контроллер, а не синглтон подсистемы;
// - блэкборд-сеттеры сохранены из прежней версии (уже соответствуют tg).

/*
AI controllers are a datumized form of AI that simulates the input a player would otherwise give to a atom. What this means is that these datums
have ways of interacting with a specific atom and control it. They posses a blackboard with the information the AI knows and has, and will plan behaviors it will try to execute through
multiple modular subtrees with behaviors
*/

/datum/ai_controller
	///The atom this controller is controlling
	var/atom/pawn
	/**
	 * This is a list of variables the AI uses and can be mutated by actions.
	 *
	 * When an action is performed you pass this list and any relevant keys for the variables it can mutate.
	 *
	 * DO NOT set values in the blackboard directly, and especially not if you're adding a datum reference to this!
	 * Use the setters, this is important for reference handing.
	 */
	var/list/blackboard = list()
	///Bitfield of traits for this AI to handle extra behavior
	var/ai_traits = NONE
	///Current actions planned to be performed by the AI in the upcoming plan
	var/list/planned_behaviors = list()
	///Current actions being performed by the AI (assoc: behavior -> TRUE)
	var/list/current_behaviors = list()
	///Current actions and their respective last time ran as an assoc list.
	var/list/behavior_cooldowns = list()
	///Current status of AI (ON/OFF/IDLE)
	var/ai_status
	///Current movement target of the AI, generally set by decision making.
	var/atom/current_movement_target
	///Identifier for what last touched our movement target, so it can be cleared conditionally
	var/movement_target_source
	///Stored arguments for behaviors given during their initial creation
	var/list/behavior_args = list()
	///Tracks recent pathing attempts, if we fail too many in a row we fail our current plans.
	var/pathing_attempts
	///Can the AI remain in control if there is a client?
	var/continue_processing_when_client = FALSE
	///distance to give up on target
	var/max_target_distance = 14
	///Максимальная длина JPS-маршрута; держим на проверенном дефолте, дальность зрения её НЕ раздувает
	var/max_path_length = AI_MAX_PATH_LENGTH
	///All subtrees this AI has available, will run them in order, so make sure they're in the order you want them to run. On initialization of this type, it will start as a typepath(s) and get converted to references of ai_subtrees found in GLOB.ai_subtrees when init_subtrees() is called
	var/list/planning_subtrees
	///Lazily-computed cache: does the plan include an obstacle-clearing subtree (attack_obstacle_in_path)? null = uncomputed, invalidated by init_subtrees().
	var/tmp/clears_obstacles_cached = null

	///The idle behavior this AI performs when it has no actions (typepath on define, instance after New)
	var/datum/idle_behavior/idle_behavior = null
	///Окно ячеек грида вокруг пауна: по нему решаем сон/пробуждение
	var/datum/cell_tracker/our_cells

	// Movement related things here
	///Reference to the movement datum we use. Is a type on initialize but becomes a ref afterwards.
	var/datum/ai_movement/ai_movement = /datum/ai_movement/dumb
	///Delay between movements. This is on the controller so we can keep the movement datum singleton
	var/movement_delay = 0.1 SECONDS
	///Кулдаун перепрокладки JPS-пути (настраивается профилем, спека: 1.5-2 c)
	var/repath_delay = 1.5 SECONDS
	///Позволено ли пауну ходить по опасным турфам (лава и т.п.; лавалендские профили ставят TRUE)
	var/cross_dangerous_turfs = FALSE
	///Действует ли на этот контроллер усталость погони. FALSE у сценарных
	///преследователей и боссов, чья погоня и есть содержание боя.
	var/pursuit_leashed = TRUE
	///Наблюдения о типе угрозы: REF(стрелок) -> list(pass_flags снаряда, world.time).
	///Ключ строковый намеренно - модель не держит ссылок на мобов (см. threat_model.dm)
	var/list/threat_pass_flag_memory
	///Характер особи (см. temperament.dm). Роллится лениво через get_temperament().
	var/datum/ai_temperament/temperament

	///AI paused time
	var/paused_until = 0
	///Может ли этот AI засыпать без клиентов рядом
	var/can_idle = TRUE
	///Идёт ли моб проверять громкие звуки рядом (выстрелы, шлюзы); засадчики - нет
	var/investigates_noise = TRUE
	///Радиус окна "интересности" в турфах; переопределяется профилем по vision/aggro range
	var/interesting_dist = AI_DEFAULT_INTERESTING_DIST
	///Роль в тактической группе; конкретные профили переопределяют значение.
	var/ai_pack_role = AI_ROLE_FRONTLINE
	///Занятая кооперативная задача (например, один artificer на одного раненого конструкта).
	var/datum/ai_target_reservation/task_reservation
	/// TRUE if we're able to run, FALSE if we aren't
	/// Should not be set manually, override get_able_to_run() instead
	var/able_to_run = FALSE
#ifdef TESTING
	///Троттл снимков "завис с целью" (AI_TRACE): не чаще раза в 5 секунд
	var/stall_trace_after = 0
	///Последний турф пауна и время его смены: второй триггер STALL-снимка
	///("план есть, но ни шага, ни обмена уроном" - вечно проваливающийся план)
	var/turf/stall_last_turf
	var/stall_last_move_at = 0
	///Троттл спам-строк трассы по категориям (AI_TRACE_THROTTLED)
	var/list/trace_throttle_at
#endif
	/// are we even able to plan?
	var/able_to_plan = TRUE
	/// are we currently on failed planning timeout?
	var/on_failed_planning_timeout = FALSE

/datum/ai_controller/New(atom/new_pawn)
	change_ai_movement_type(ai_movement)
	init_subtrees()

	if(ispath(idle_behavior))
		idle_behavior = new idle_behavior

	if(!isnull(new_pawn)) //юнит-тестам нужен контроллер в изоляции
		PossessPawn(new_pawn)

/datum/ai_controller/Destroy(force)
	release_ai_target_reservation()
	release_pack_focus()
	UnpossessPawn(FALSE)
	if(ai_status)
		GLOB.ai_controllers_by_status[ai_status] -= src
		SSai_controllers.currentrun -= src
	our_cells = null
	set_movement_target(type, null)
	if(ai_movement.moving_controllers[src])
		ai_movement.stop_moving_towards(src)
	return ..()

///Whether this pawn has stable voluntary movement in vacuum and can survive
///planning a route through it. Nearby push-off objects are deliberately not
///enough: a path may continue through many empty space tiles.
/datum/ai_controller/proc/can_path_through_space()
	if(cross_dangerous_turfs)
		return TRUE
	var/mob/mob_pawn = pawn
	if(!istype(mob_pawn))
		return FALSE
	if(!(mob_pawn.spacewalk || HAS_TRAIT(mob_pawn, TRAIT_SPACEWALK) || (mob_pawn.movement_type & FLYING) || HAS_TRAIT(mob_pawn, TRAIT_FREE_FLOAT_MOVEMENT)))
		return FALSE
	var/mob/living/simple_animal/simple_pawn = mob_pawn
	return !istype(simple_pawn) || !simple_pawn.requires_safe_atmosphere()

///Shared dangerous-turf gate for direct movement, breach routing and tactical
///repositioning. Space-capable pawns may cross vacuum without gaining blanket
///permission to walk into lava, chasms or open-space holes.
/datum/ai_controller/proc/can_enter_dangerous_turf(turf/candidate)
	if(!candidate)
		return FALSE
	if(!is_type_in_typecache(candidate, GLOB.dangerous_turfs) || cross_dangerous_turfs)
		return TRUE
	var/mob/mob_pawn = pawn
	if(islava(candidate))
		return istype(mob_pawn) && ((mob_pawn.movement_type & (FLYING | FLOATING)) || HAS_TRAIT(mob_pawn, TRAIT_LAVA_IMMUNE))
	if(istype(candidate, /turf/open/chasm) || istype(candidate, /turf/open/openspace))
		return istype(mob_pawn) && (mob_pawn.movement_type & (FLYING | FLOATING))
	return isspaceturf(candidate) && can_path_through_space()

///Whether the pawn may enter this turf without choosing a lethal environment.
///This is the tactical one-step gate; pressure-barrier edge checks remain in
///obstacle_policy because they need both the source and destination turfs.
/datum/ai_controller/proc/can_enter_turf(turf/candidate)
	if(!can_enter_dangerous_turf(candidate))
		return FALSE
	var/mob/living/simple_animal/simple_pawn = pawn
	return !istype(simple_pawn) || simple_pawn.can_safely_enter_turf(candidate)

///TRUE when a step is blocked by mobs only. Static blockers still belong to
///JPS/obstacle policy and must not be mistaken for a transient combat queue.
/datum/ai_controller/proc/is_mob_only_blocked_step(turf/check_turf)
	if(!check_turf?.is_blocked_turf(source_atom = pawn))
		return FALSE
	return !check_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = pawn)

///Sets the current movement target, with an optional param to override the movement behavior
/datum/ai_controller/proc/set_movement_target(source, atom/target, datum/ai_movement/new_movement)
	if(current_movement_target)
		UnregisterSignal(current_movement_target, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_PREQDELETED))
	if(!isnull(target) && !isatom(target))
		stack_trace("[pawn]'s current movement target is not an atom, rather a [target.type]! Did you accidentally set it to a weakref?")
		CancelActions()
		return
	movement_target_source = source
	current_movement_target = target
	if(!isnull(current_movement_target))
		RegisterSignal(current_movement_target, COMSIG_MOVABLE_MOVED, PROC_REF(on_movement_target_move))
		RegisterSignal(current_movement_target, COMSIG_PARENT_PREQDELETED, PROC_REF(on_movement_target_delete))
	else
		//Без цели двигаться некуда. Отпускаем запись сразу: датумы /datum/ai_movement -
		//бессмертные синглтоны из SSai_movement, и moving_controllers[src] держит уже
		//удалённую цель до следующего прогона поведения или до смерти пешки. Для мобов,
		//которые после потери цели уходят в AI_STATUS_IDLE, это "до конца раунда".
		stop_ai_movement()
	if(new_movement)
		change_ai_movement_type(new_movement)

///Overrides the current ai_movement of this controller with a new one
/datum/ai_controller/proc/change_ai_movement_type(datum/ai_movement/new_movement)
	//Смена типа движения оставляла запись висеть в СТАРОМ синглтоне - тот больше никем
	//не опрашивается, снять её потом уже некому.
	stop_ai_movement()
	ai_movement = SSai_movement.movement_types[new_movement]

///Completely replaces the planning_subtrees with a new set based on argument provided, list provided must contain specifically typepaths
/datum/ai_controller/proc/replace_planning_subtrees(list/typepaths_of_new_subtrees)
	planning_subtrees = typepaths_of_new_subtrees
	init_subtrees()

///Loops over the subtrees in planning_subtrees and looks at the ai_controllers to grab a reference, ENSURE planning_subtrees ARE TYPEPATHS AND NOT INSTANCES/REFERENCES BEFORE EXECUTING THIS
/datum/ai_controller/proc/init_subtrees()
	clears_obstacles_cached = null //пересобираем: набор сабтри поменялся
	if(!LAZYLEN(planning_subtrees))
		return
	var/list/temp_subtree_list = list()
	for(var/subtree in planning_subtrees)
		var/subtree_instance = GLOB.ai_subtrees[subtree]
		temp_subtree_list += subtree_instance
	planning_subtrees = temp_subtree_list

///TRUE if this controller's plan clears obstacles on its own path (attack_obstacle_in_path).
///Movement uses this to keep a wall-smasher bee-lining and breaking through instead of
///paying for a JPS detour: the obstacle behavior removes the wall on the direct line.
/datum/ai_controller/proc/clears_obstacles_in_path()
	if(isnull(clears_obstacles_cached))
		clears_obstacles_cached = FALSE
		for(var/datum/ai_planning_subtree/subtree as anything in planning_subtrees)
			if(istype(subtree, /datum/ai_planning_subtree/attack_obstacle_in_path))
				clears_obstacles_cached = TRUE
				break
	return clears_obstacles_cached

///Proc to move from one pawn to another, this will destroy the target's existing controller.
/datum/ai_controller/proc/PossessPawn(atom/new_pawn)
	SHOULD_CALL_PARENT(TRUE)
	if(pawn) //Reset any old signals
		UnpossessPawn(FALSE)

	if(istype(new_pawn.ai_controller)) //Existing AI, kill it.
		QDEL_NULL(new_pawn.ai_controller)

	if(TryPossessPawn(new_pawn) & AI_CONTROLLER_INCOMPATIBLE)
		qdel(src)
		CRASH("[src] attached to [new_pawn] but these are not compatible!")

	pawn = new_pawn
	pawn.ai_controller = src

	//Контроллерный simple_animal не живёт в легаси-бакетах: его планирует SSai_controllers
	if(istype(new_pawn, /mob/living/simple_animal))
		var/mob/living/simple_animal/simple_pawn = new_pawn
		simple_pawn.unenroll_legacy_ai()

	var/turf/pawn_turf = get_turf(pawn)
	if(pawn_turf)
		while(GLOB.ai_controllers_by_zlevel.len < world.maxz)
			GLOB.ai_controllers_by_zlevel.len++
			GLOB.ai_controllers_by_zlevel[GLOB.ai_controllers_by_zlevel.len] = list()
		GLOB.ai_controllers_by_zlevel[pawn_turf.z] += src

	reset_ai_status()
	RegisterSignal(pawn, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_changed_z_level))
	RegisterSignal(pawn, COMSIG_MOVABLE_ENTERED_NULLSPACE, PROC_REF(on_changed_z_level))
	RegisterSignal(pawn, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_changed))
	RegisterSignal(pawn, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_sentience_gained))
	RegisterSignal(pawn, COMSIG_PARENT_QDELETING, PROC_REF(on_pawn_qdeleted))
	update_able_to_run()
	setup_able_to_run()

	our_cells = new(interesting_dist, interesting_dist, 1)
	set_new_cells()

	RegisterSignal(pawn, COMSIG_MOVABLE_MOVED, PROC_REF(update_grid))

/datum/ai_controller/proc/update_grid(datum/source)
	SIGNAL_HANDLER

	set_new_cells()
	if(current_movement_target)
		check_target_max_distance()

/datum/ai_controller/proc/on_movement_target_move(atom/source)
	SIGNAL_HANDLER
	check_target_max_distance()

/datum/ai_controller/proc/on_movement_target_delete(atom/source)
	SIGNAL_HANDLER
	set_movement_target(source = type, target = null)

/datum/ai_controller/proc/check_target_max_distance()
	if(get_dist(current_movement_target, pawn) > max_target_distance)
		CancelActions()

///Пересчитать окно ячеек; на новые подписаться на вход/выход клиентов, со старых отписаться
/datum/ai_controller/proc/set_new_cells()
	if(isnull(our_cells))
		return

	var/turf/our_turf = get_turf(pawn)

	if(isnull(our_turf))
		clear_tracked_cells()
		return

	var/list/cell_collections = our_cells.recalculate_cells(our_turf)

	for(var/datum/old_grid as anything in cell_collections[2])
		UnregisterSignal(old_grid, list(SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), SPATIAL_GRID_CELL_EXITED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)))

	for(var/datum/spatial_grid_cell/new_grid as anything in cell_collections[1])
		RegisterSignal(new_grid, SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), PROC_REF(on_client_enter))
		RegisterSignal(new_grid, SPATIAL_GRID_CELL_EXITED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), PROC_REF(on_client_exit))

	recalculate_idle()

///Отписаться от текущего spatial-grid окна (nullspace/unpossess).
/datum/ai_controller/proc/clear_tracked_cells()
	if(isnull(our_cells))
		return
	for(var/datum/spatial_grid_cell/cell as anything in our_cells.member_cells)
		UnregisterSignal(cell, list(SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), SPATIAL_GRID_CELL_EXITED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)))
	our_cells.member_cells.Cut()

///TRUE, если в отслеживаемых ячейках нет живых клиентов и можно засыпать
/datum/ai_controller/proc/should_idle()
	if(!can_idle || isnull(our_cells))
		return FALSE
	//пустое окно = не на гриде: спать нельзя - будить будет некому
	if(!length(our_cells.member_cells))
		return FALSE
	for(var/datum/spatial_grid_cell/grid as anything in our_cells.member_cells)
		if(locate(/mob/living) in grid.client_contents)
			return FALSE
	return TRUE

///Пересчитать сон: exited - кто только что покинул ячейку (атом или список)
/datum/ai_controller/proc/recalculate_idle(datum/exited)
	if(ai_status == AI_STATUS_OFF)
		return

	var/distance = INFINITY
	if(islist(exited))
		var/list/exited_list = exited
		distance = get_dist(pawn, exited_list[1])
	else if(isatom(exited))
		var/atom/exited_atom = exited
		distance = get_dist(pawn, exited_atom)

	if(distance <= interesting_dist) //ушедший всё ещё внутри окна интересности
		return

	if(should_idle())
		set_ai_status(AI_STATUS_IDLE)

///Пробуждение: живой клиент вошёл в одну из отслеживаемых ячеек
/datum/ai_controller/proc/on_client_enter(datum/source, list/target_list)
	SIGNAL_HANDLER

	if(!(locate(/mob/living) in target_list))
		return

	if(ai_status == AI_STATUS_IDLE)
		set_ai_status(AI_STATUS_ON)

/datum/ai_controller/proc/on_client_exit(datum/source, datum/exited)
	SIGNAL_HANDLER

	recalculate_idle(exited)

/// Sets the AI on or off based on current conditions, call to reset after you've manually disabled it somewhere
/datum/ai_controller/proc/reset_ai_status()
	set_ai_status(get_expected_ai_status())

/**
 * Gets the AI status we expect the AI controller to be on at this current moment.
 * Returns AI_STATUS_OFF if it's inhabited by a Client and shouldn't be, if it's dead and cannot act while dead, or is on a z level without clients.
 * Returns AI_STATUS_IDLE if there are no clients within the interesting window.
 * Returns AI_STATUS_ON otherwise.
 */
/datum/ai_controller/proc/get_expected_ai_status()
	if(isnull(get_turf(pawn)))
		return AI_STATUS_OFF

	if(!ismob(pawn))
		return AI_STATUS_ON

	var/mob/living/mob_pawn = pawn
	if(!continue_processing_when_client && mob_pawn.client)
		return AI_STATUS_OFF

	if(mob_pawn.stat == DEAD)
		if(ai_traits & CAN_ACT_WHILE_DEAD)
			return AI_STATUS_ON
		return AI_STATUS_OFF

	var/turf/pawn_turf = get_turf(mob_pawn)
	if(islist(SSmobs.clients_by_zlevel) && pawn_turf.z <= SSmobs.clients_by_zlevel.len && !length(SSmobs.clients_by_zlevel[pawn_turf.z]))
		return AI_STATUS_OFF
	if(on_failed_planning_timeout || !able_to_run)
		return AI_STATUS_OFF
	if(should_idle())
		return AI_STATUS_IDLE
	return AI_STATUS_ON

///Смена z пауна: переложить по z-бакетам и пересчитать статус
/datum/ai_controller/proc/on_changed_z_level(atom/source, old_z, new_z)
	SIGNAL_HANDLER
	if(isturf(old_z))
		var/turf/old_turf = old_z
		old_z = old_turf.z
	if(isturf(new_z))
		var/turf/new_turf = new_z
		new_z = new_turf.z
	if(old_z && GLOB.ai_controllers_by_zlevel.len >= old_z)
		GLOB.ai_controllers_by_zlevel[old_z] -= src
	if(!new_z)
		clear_tracked_cells()
		set_ai_status(AI_STATUS_OFF)
		CancelActions()
		return
	while(GLOB.ai_controllers_by_zlevel.len < new_z)
		GLOB.ai_controllers_by_zlevel.len++
		GLOB.ai_controllers_by_zlevel[GLOB.ai_controllers_by_zlevel.len] = list()
	GLOB.ai_controllers_by_zlevel[new_z] += src
	reset_ai_status()

///Abstract proc for initializing the pawn to the new controller
/datum/ai_controller/proc/TryPossessPawn(atom/new_pawn)
	return

///Proc for deinitializing the pawn to the old controller
/datum/ai_controller/proc/UnpossessPawn(destroy)
	SHOULD_CALL_PARENT(TRUE)
	if(isnull(pawn))
		//Либо контроллер завели без пауна, либо пауна унёс харддел - в DM ссылка
		//на удалённый объект молча становится null. Во втором случае выход без
		//снятия с очередей оставлял осиротевший контроллер в unplanned-пуле
		//навсегда: он фейлился каждый планировочный тик (idle_random_walk).
		release_ai_target_reservation()
		release_pack_focus()
		set_ai_status(AI_STATUS_OFF)
		remove_from_unplanned_controllers()
		if(destroy)
			qdel(src)
		return
	release_ai_target_reservation()
	release_pack_focus()

	set_ai_status(AI_STATUS_OFF)
	UnregisterSignal(pawn, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_MOVABLE_ENTERED_NULLSPACE, COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_STATCHANGE, COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	clear_able_to_run()
	if(our_cells)
		clear_tracked_cells()
	if(ai_movement.moving_controllers[src])
		ai_movement.stop_moving_towards(src)
	var/turf/pawn_turf = get_turf(pawn)
	if(pawn_turf && GLOB.ai_controllers_by_zlevel.len >= pawn_turf.z)
		GLOB.ai_controllers_by_zlevel[pawn_turf.z] -= src
	remove_from_unplanned_controllers()
	pawn.ai_controller = null
	pawn = null
	if(destroy)
		qdel(src)

/datum/ai_controller/proc/setup_able_to_run()
	//paused_until обрабатывается вручную в PauseAi()
	RegisterSignal(pawn, SIGNAL_ADDTRAIT(TRAIT_AI_PAUSED), PROC_REF(update_able_to_run))
	RegisterSignal(pawn, SIGNAL_REMOVETRAIT(TRAIT_AI_PAUSED), PROC_REF(update_able_to_run))

/datum/ai_controller/proc/clear_able_to_run()
	UnregisterSignal(pawn, list(SIGNAL_ADDTRAIT(TRAIT_AI_PAUSED), SIGNAL_REMOVETRAIT(TRAIT_AI_PAUSED)))

/datum/ai_controller/proc/update_able_to_run()
	SIGNAL_HANDLER
	var/run_flags = get_able_to_run()
	if(run_flags & AI_UNABLE_TO_RUN)
		able_to_run = FALSE
		SSmove_manager.stop_looping(pawn) //stop moving
	else
		able_to_run = TRUE
	set_ai_status(get_expected_ai_status(), run_flags)

///Returns NONE if the ai controller can actually run at the moment, AI_UNABLE_TO_RUN otherwise
/datum/ai_controller/proc/get_able_to_run()
	if(HAS_TRAIT(pawn, TRAIT_AI_PAUSED))
		return AI_UNABLE_TO_RUN
	if(world.time < paused_until)
		return AI_UNABLE_TO_RUN
	return NONE

///Runs any actions that are currently running
/datum/ai_controller/process(delta_time)
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)

		// Convert the current behaviour action cooldown to realtime seconds from deciseconds
		// Then pick the max of this and the delta_time passed to ai_controller.process()
		// Action cooldowns cannot happen faster than delta_time, so delta_time should be the value used in this scenario.
		var/action_delta_time = max(current_behavior.get_cooldown(src) * 0.1, delta_time)

		if(!(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_MOVEMENT))
			if(behavior_cooldowns[current_behavior] > world.time) //Still on cooldown
				continue
			ProcessBehavior(action_delta_time, current_behavior)
			return

		if(isnull(current_movement_target))
			fail_behavior(current_behavior)
			return

		//Stops pawns from performing such actions that should require the target to be adjacent.
		var/atom/movable/moving_pawn = pawn
		var/can_reach = !(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_REACH) || moving_pawn.CanReach(current_movement_target)
		if(can_reach && current_behavior.required_distance >= get_dist(moving_pawn, current_movement_target)) ///Are we close enough to engage?
			if(ai_movement.moving_controllers[src] == current_movement_target) //We are close enough, if we're moving stop.
				ai_movement.stop_moving_towards(src)

			if(behavior_cooldowns[current_behavior] > world.time) //Still on cooldown
				continue
			ProcessBehavior(action_delta_time, current_behavior)
			return

		if(ai_movement.moving_controllers[src] != current_movement_target) //We're too far, if we're not already moving start doing it.
			ai_movement.start_moving_towards(src, current_movement_target, current_behavior.required_distance) //Then start moving

		if(current_behavior.behavior_flags & AI_BEHAVIOR_MOVE_AND_PERFORM) //If we can move and perform then do so.
			if(behavior_cooldowns[current_behavior] > world.time) //Still on cooldown
				continue
			//Чистый INSTANT в пути ("ещё иду, действия не было") не съедает тик
			//процессинга. Иначе мили-подход/pursue, однажды встав в списке
			//раньше файндера, морил восприятие голодом на всю погоню: последняя
			//подтверждённая позиция протухала, разжалование скрывшейся цели не
			//наступало до самой адьяценси, перевыбор целей был мёртв.
			if(ProcessBehavior(action_delta_time, current_behavior) == AI_BEHAVIOR_INSTANT)
				continue
			return

///This is where you decide what actions are taken by the AI.
/datum/ai_controller/proc/SelectBehaviors(delta_time)
	SHOULD_NOT_SLEEP(TRUE) //Fuck you don't sleep in procs like this.
	planned_behaviors.Cut()

	for(var/datum/ai_planning_subtree/subtree as anything in planning_subtrees)
		if(subtree.SelectBehaviors(src, delta_time) == SUBTREE_RETURN_FINISH_PLANNING)
			break

	for(var/datum/ai_behavior/forgotten_behavior as anything in current_behaviors - planned_behaviors)
		var/list/arguments = list(src, FALSE)
		var/list/stored_arguments = behavior_args[forgotten_behavior.type]
		if(stored_arguments)
			arguments += stored_arguments
		forgotten_behavior.finish_action(arglist(arguments))

#ifdef TESTING
	//детектор "завис": цель есть, а план пуст ЛИБО план есть, но моб давно ни
	//шагнул, ни обменялся уроном (вечно проваливающиеся поведения - за весь
	//round-23.35.57 прежний детектор пустого плана не сработал НИ РАЗУ, хотя
	//мобы стояли минутами). Снимок раз в 5 секунд, чтобы лог читался глазами.
	var/turf/stall_turf = get_turf(pawn)
	if(stall_turf != stall_last_turf)
		stall_last_turf = stall_turf
		stall_last_move_at = world.time
	if(blackboard_key_exists(BB_AI_CURRENT_TARGET) && world.time >= stall_trace_after)
		var/stall_plan_empty = !length(planned_behaviors) && !length(current_behaviors)
		var/stall_no_progress = (world.time - stall_last_move_at > AI_STALL_NO_PROGRESS_TIME) \
			&& (world.time - (blackboard[BB_AI_LAST_EXCHANGE_AT] || 0) > AI_STALL_NO_PROGRESS_TIME)
		if(stall_plan_empty || stall_no_progress)
			stall_trace_after = world.time + 5 SECONDS
			ai_trace_stall_snapshot()
#endif

#ifdef TESTING
///Трассировка решений ИИ (см. AI_TRACE): категория, паун с позицией, сообщение
/datum/ai_controller/proc/ai_trace(category, message)
	var/pawn_tag = "no-pawn"
	if(pawn)
		var/turf/pawn_turf = get_turf(pawn)
		pawn_tag = "[pawn.type] ([pawn_turf ? "[pawn_turf.x],[pawn_turf.y],[pawn_turf.z]" : "null"])"
	WRITE_LOG(GLOB.ai_trace_log, "[category] | [pawn_tag] [REF(src)] | [message]")

///Троттлёная трасса (AI_TRACE_THROTTLED): повторяющаяся каждый план строка
///пишется не чаще AI_TRACE_THROTTLE_TIME на контроллер - лог обязан читаться
/datum/ai_controller/proc/ai_trace_throttled(category, message)
	if(world.time < (trace_throttle_at?[category] || 0))
		return
	LAZYSET(trace_throttle_at, category, world.time + AI_TRACE_THROTTLE_TIME)
	ai_trace(category, message)

///Подсказка "что именно заблокировало маршрут" для трассы исчерпанного пути:
///без неё "маршрут исчерпан" не отвечал на главный вопрос разбора - обо что
/datum/ai_controller/proc/ai_trace_route_block_hint(atom/target)
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || QDELETED(target))
		return ""
	var/turf/blocked = ai_get_blocked_path_turf(living_pawn, target)
	if(!blocked)
		return ""
	var/atom/culprit
	for(var/atom/movable/candidate as anything in blocked)
		if(candidate.density)
			culprit = candidate
			break
	if(!culprit && blocked.density)
		culprit = blocked
	return " (преграда: [culprit || "ребро/направленная"] на ([blocked.x],[blocked.y],[blocked.z]))"

///Снимок застрявшего контроллера: всё, что нужно для диагноза стойки одним взглядом
/datum/ai_controller/proc/ai_trace_stall_snapshot()
	var/atom/target = blackboard[BB_AI_CURRENT_TARGET]
	var/list/bits = list()
	bits += "state=[blackboard[BB_AI_STATE] || "null"]"
	bits += "target=[target] dist=[QDELETED(target) ? "-" : get_dist(pawn, target)]"
	bits += "status=[ai_status] able_to_run=[able_to_run] paused=[paused_until > world.time ? "да" : "нет"]"
	bits += "move_target=[current_movement_target || "нет"]"
	var/datum/move_loop/loop = SSmove_manager.processing_on(pawn, SSai_movement)
	bits += "move_loop=[loop ? "[loop.type]" : "нет"]"
	bits += "band=[blackboard[BB_AI_MIN_DISTANCE] || 0]-[blackboard[BB_AI_MAX_DISTANCE] || 0]"
	bits += "frustration=[blackboard[BB_AI_FRUSTRATION] || 0] pathing_attempts=[pathing_attempts]"
	bits += "route_retry_in=[max(0, (blackboard[BB_AI_ROUTE_RETRY_AT] || 0) - world.time)]"
	bits += "lane_deadlock_in=[max(0, (blackboard[BB_AI_LANE_DEADLOCK_UNTIL] || 0) - world.time)]"
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(istype(hostile_pawn) && hostile_pawn.ranged && !QDELETED(target))
		bits += "lane=[hostile_pawn.CheckRangedFireLane(target) ? "ПЕРЕКРЫТА" : "чиста"]"
		bits += "ranged_cooldown_in=[max(0, hostile_pawn.ranged_cooldown - world.time)]"
	ai_trace("STALL", bits.Join(" | "))
#endif

///This proc handles changing ai status, and starts/stops processing if required.
/datum/ai_controller/proc/set_ai_status(new_ai_status, additional_flags = NONE)
	if(ai_status == new_ai_status)
		return FALSE //no change

	//снять старый статус
	if(ai_status)
		GLOB.ai_controllers_by_status[ai_status] -= src
		SSai_controllers.currentrun -= src
	remove_from_unplanned_controllers()
	stop_previous_processing()
	ai_status = new_ai_status
	GLOB.ai_controllers_by_status[new_ai_status] += src
	//проснувшийся с целью моб перестаёт быть "спокойным дальним" для троттла
	//Life - снимаем бронь бакета SSmobs
	if(new_ai_status == AI_STATUS_ON && isliving(pawn) && !isnull(blackboard[BB_AI_CURRENT_TARGET]))
		var/mob/living/living_pawn = pawn
		living_pawn.wake_life()
	switch(ai_status)
		if(AI_STATUS_OFF)
			if(!(additional_flags & AI_PREVENT_CANCEL_ACTIONS))
				CancelActions()
			stop_ai_movement()
			return
		if(AI_STATUS_IDLE)
			//полный сон: никакой обработки; действия отменяем, чтобы не висели
			CancelActions()
			stop_ai_movement()
			return
	if(!length(current_behaviors))
		add_to_unplanned_controllers()
		return
	start_ai_processing()

/datum/ai_controller/proc/start_ai_processing()
	if(ai_status == AI_STATUS_ON)
		START_PROCESSING(SSai_behaviors, src)

/datum/ai_controller/proc/stop_previous_processing()
	if(ai_status == AI_STATUS_ON)
		STOP_PROCESSING(SSai_behaviors, src)

///Guarantees the AI move loop is torn down. CancelActions() only reaches the loop
///through a movement behavior that happens to be planned at this exact moment; when
///a player takes control (status -> OFF via on_sentience_gained) or the loop
///otherwise outlives its owning behavior, it keeps living on SSai_movement and
///stepping the pawn toward the stale AI target every movement_delay - overriding the
///client's own keypresses so controls feel completely dead. Stopping is idempotent.
/datum/ai_controller/proc/stop_ai_movement()
	//istype, а не просто проверка на null: до первого change_ai_movement_type() в ai_movement
	//лежит ТИПОПУТЬ, а не инстанс, и moving_controllers у него - разделяемый список-дефолт типа.
	if(!istype(ai_movement))
		return
	if(ai_movement.moving_controllers[src])
		ai_movement.stop_moving_towards(src)

/datum/ai_controller/proc/PauseAi(time)
	paused_until = world.time + time
	update_able_to_run()
	addtimer(CALLBACK(src, PROC_REF(update_able_to_run)), time)

///Шаг, который поведение делает Move()-ом МИМО мув-лупа: сайдстеп-уворот и
///боковое перестроение стрелка. Такой шаг обязан стоить ровно столько же,
///сколько обычный, иначе моб получает бесплатные тайлы сверх movement_delay -
///именно отсюда бралось "перепрыгивают через вас, появляются слева-справа".
///Два следствия: спрайту выставляется glide (без него шаг щёлкает и читается
///телепортом), а активный мув-луп сдвигается на ту же задержку, чтобы не
///добавить второй шаг в том же окне. Возвращает результат Move().
/datum/ai_controller/proc/ai_step_outside_loop(turf/destination)
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || !destination)
		return FALSE
	//диагональ платит x√2, как игрок и как штатный мув-луп (movement_step_delay
	//в обоих): сайдстепы turn(dir, 45) и перестроения по alldirs - сплошь
	//диагонали, и без надбавки уворот снова получал скрытые 1.33x скорости.
	//Цена и glide считаются по НАМЕРЕНИЮ до шага (glide обязан стоять до Move,
	//иначе спрайт щёлкает); редкий частичный диагональный Move переплачивает
	//кардинальный шаг - ошибка в честную сторону, бесплатных тайлов нет.
	var/step_dir = get_dir(living_pawn, destination)
	var/step_delay = movement_step_delay(max(movement_delay, world.tick_lag), ISDIAGONALDIR(step_dir), world.tick_lag)
	living_pawn.set_glide_size(MOVEMENT_ADJUSTED_GLIDE_SIZE(step_delay, 1))
	if(!living_pawn.Move(destination, step_dir))
		return FALSE
	var/datum/move_loop/loop = SSmove_manager.processing_on(living_pawn, SSai_movement)
	loop?.pause_for(step_delay)
	return TRUE

///Пристёгнутый паун не двигается: его Move() толкал бы незаанкоренный стул.
///Вместо катания моб выбирается сам, но не чаще AI_UNBUCKLE_COOLDOWN -
///user_unbuckle_mob спит в do_after, а зовём мы его из сигнал-хендлера мувера.
/datum/ai_controller/proc/request_unbuckle()
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || !living_pawn.buckled)
		return FALSE
	if(world.time < (blackboard[BB_AI_UNBUCKLE_AT] || 0))
		return FALSE
	blackboard[BB_AI_UNBUCKLE_AT] = world.time + AI_UNBUCKLE_COOLDOWN
	INVOKE_ASYNC(living_pawn, TYPE_PROC_REF(/mob/living, resist_buckle))
	return TRUE

/datum/ai_controller/proc/add_to_unplanned_controllers()
	if(ai_status != AI_STATUS_ON || isnull(idle_behavior))
		return
	GLOB.unplanned_controllers[src] = TRUE

/datum/ai_controller/proc/remove_from_unplanned_controllers()
	GLOB.unplanned_controllers -= src
	SSunplanned_controllers.currentrun -= src

/datum/ai_controller/proc/modify_cooldown(datum/ai_behavior/behavior, new_cooldown)
	behavior_cooldowns[behavior] = new_cooldown

///Call this to add a behavior to the stack.
/datum/ai_controller/proc/queue_behavior(behavior_type, ...)
	var/datum/ai_behavior/behavior = GET_AI_BEHAVIOR(behavior_type)
	if(!behavior)
		CRASH("Behavior [behavior_type] not found.")
	var/list/arguments = args.Copy()
	arguments[1] = src

	if(current_behaviors[behavior]) //ещё в плане: не добавляем заново, но помечаем запланированным
		planned_behaviors[behavior] = TRUE
		return

	if(!behavior.setup(arglist(arguments)))
		return

	var/should_exit_unplanned = !length(current_behaviors)
	planned_behaviors[behavior] = TRUE
	current_behaviors[behavior] = TRUE

	arguments.Cut(1, 2)
	if(length(arguments))
		behavior_args[behavior_type] = arguments
	else
		behavior_args -= behavior_type

	if(!(behavior.behavior_flags & AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION)) //this one blocks planning!
		able_to_plan = FALSE

	if(should_exit_unplanned)
		exit_unplanned_mode()

/datum/ai_controller/proc/check_able_to_plan()
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		if(!(current_behavior.behavior_flags & AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION)) //We have a behavior that blocks planning
			return FALSE
	return TRUE

/datum/ai_controller/proc/dequeue_behavior(datum/ai_behavior/behavior)
	current_behaviors -= behavior
	able_to_plan = check_able_to_plan()
	if(!length(current_behaviors))
		enter_unplanned_mode()

/datum/ai_controller/proc/exit_unplanned_mode()
	remove_from_unplanned_controllers()
	start_ai_processing()

/datum/ai_controller/proc/enter_unplanned_mode()
	add_to_unplanned_controllers()
	stop_previous_processing()

///Выполнить поведение; возвращает флаги perform() - вызывающий цикл различает
///чистый INSTANT-проход ("в пути") от реально состоявшегося действия
/datum/ai_controller/proc/ProcessBehavior(delta_time, datum/ai_behavior/behavior)
	var/list/arguments = list(delta_time, src)
	var/list/stored_arguments = behavior_args[behavior.type]
	if(stored_arguments)
		arguments += stored_arguments

	var/process_flags = behavior.perform(arglist(arguments))
	. = process_flags
	if(process_flags & AI_BEHAVIOR_DELAY)
		behavior_cooldowns[behavior] = world.time + behavior.get_cooldown(src)
	if(process_flags & AI_BEHAVIOR_FAILED)
		arguments[1] = src
		arguments[2] = FALSE
		behavior.finish_action(arglist(arguments))
	else if(process_flags & AI_BEHAVIOR_SUCCEEDED)
		arguments[1] = src
		arguments[2] = TRUE
		behavior.finish_action(arglist(arguments))

/datum/ai_controller/proc/CancelActions()
	if(!length(current_behaviors))
		return
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		fail_behavior(current_behavior)

/datum/ai_controller/proc/fail_behavior(datum/ai_behavior/current_behavior)
	var/list/arguments = list(src, FALSE)
	var/list/stored_arguments = behavior_args[current_behavior.type]
	if(stored_arguments)
		arguments += stored_arguments
	current_behavior.finish_action(arglist(arguments))

///Смена stat пауна: пересчитать статус и работоспособность
/datum/ai_controller/proc/on_stat_changed(mob/living/source, new_stat)
	SIGNAL_HANDLER
	reset_ai_status()
	update_able_to_run()

/datum/ai_controller/proc/on_sentience_gained()
	SIGNAL_HANDLER
	UnregisterSignal(pawn, COMSIG_MOB_CLIENT_LOGIN)
	if(!continue_processing_when_client)
		set_ai_status(AI_STATUS_OFF) //Can't do anything while player is connected
	RegisterSignal(pawn, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_sentience_lost))

/datum/ai_controller/proc/on_sentience_lost()
	SIGNAL_HANDLER
	UnregisterSignal(pawn, COMSIG_MOB_CLIENT_LOGOUT)
	reset_ai_status()
	RegisterSignal(pawn, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_sentience_gained))

///Паун удаляется: погасить контроллер
/datum/ai_controller/proc/on_pawn_qdeleted()
	SIGNAL_HANDLER
	release_ai_target_reservation()
	release_pack_focus()
	set_ai_status(AI_STATUS_OFF)
	set_movement_target(type, null)
	if(ai_movement.moving_controllers[src])
		ai_movement.stop_moving_towards(src)

/// Use this proc to define how your controller defines what access the pawn has for the sake of pathfinding, likely pointing to whatever ID slot is relevant
/datum/ai_controller/proc/get_access()
	return

///Optional fallback for controllers which can deliberately clear obstacles.
///The normal, much cheaper JPS route is always attempted first.
/datum/ai_controller/proc/get_path_through_obstacles(atom/target, max_distance, minimum_distance, obj/item/card/id/id, simulated_only, turf/avoid, skip_first, datum/cancel_source)
	return

///Returns the minimum required distance to preform one of our current behaviors. Honestly this should just be cached or something but fuck you
/datum/ai_controller/proc/get_minimum_distance()
	var/minimum_distance = max_target_distance
	// right now I'm just taking the shortest minimum distance of our current behaviors, at some point in the future
	// we should let whatever sets the current_movement_target also set the min distance and max path length
	// (or at least cache it on the controller)
	for(var/datum/ai_behavior/iter_behavior as anything in current_behaviors)
		if(iter_behavior.required_distance < minimum_distance)
			minimum_distance = iter_behavior.required_distance
	return minimum_distance

/datum/ai_controller/proc/planning_failed()
	on_failed_planning_timeout = TRUE
	set_ai_status(get_expected_ai_status())
	addtimer(CALLBACK(src, PROC_REF(resume_planning)), AI_FAILED_PLANNING_COOLDOWN)

/datum/ai_controller/proc/resume_planning()
	on_failed_planning_timeout = FALSE
	set_ai_status(get_expected_ai_status())

/// Returns true if we have a blackboard key with the provided key and it is not qdeleting
/datum/ai_controller/proc/blackboard_key_exists(key)
	var/datum/key_value = blackboard[key]
	if(isdatum(key_value))
		return !QDELETED(key_value)
	if(islist(key_value))
		return length(key_value) > 0
	return !!key_value

/// Signal sent when a blackboard key is set to a new value
#define COMSIG_AI_BLACKBOARD_KEY_SET(blackboard_key) "ai_blackboard_key_set_[blackboard_key]"

/// Signal sent when a blackboard key is cleared
#define COMSIG_AI_BLACKBOARD_KEY_CLEARED(blackboard_key) "ai_blackboard_key_clear_[blackboard_key]"

/**
 * Used to manage references to datum by AI controllers
 *
 * * tracked_datum - something being added to an ai blackboard
 * * key - the associated key
 */
#define TRACK_AI_DATUM_TARGET(tracked_datum, key) do { \
	if(isweakref(tracked_datum)) { \
		var/datum/weakref/_bad_weakref = tracked_datum; \
		stack_trace("Weakref (Actual datum: [_bad_weakref.resolve()]) found in ai datum blackboard! \
			This is an outdated method of ai reference handling, please remove it."); \
	}; \
	else if(isdatum(tracked_datum)) { \
		var/datum/_tracked_datum = tracked_datum; \
		if(!HAS_TRAIT_FROM(_tracked_datum, TRAIT_AI_TRACKING, "[REF(src)]_[key]")) { \
			RegisterSignal(_tracked_datum, COMSIG_PARENT_QDELETING, PROC_REF(sig_remove_from_blackboard), override = TRUE); \
			ADD_TRAIT(_tracked_datum, TRAIT_AI_TRACKING, "[REF(src)]_[key]"); \
		}; \
	}; \
} while(FALSE)

/**
 * Used to clear previously set reference handing by AI controllers
 *
 * * tracked_datum - something being removed from an ai blackboard
 * * key - the associated key
 */
#define CLEAR_AI_DATUM_TARGET(tracked_datum, key) do { \
	if(isdatum(tracked_datum)) { \
		var/datum/_tracked_datum = tracked_datum; \
		REMOVE_TRAIT(_tracked_datum, TRAIT_AI_TRACKING, "[REF(src)]_[key]"); \
		if(!HAS_TRAIT(_tracked_datum, TRAIT_AI_TRACKING)) { \
			UnregisterSignal(_tracked_datum, COMSIG_PARENT_QDELETING); \
		}; \
	}; \
} while(FALSE)

/// Used for above to track all the keys that have registered a signal
#define TRAIT_AI_TRACKING "tracked_by_ai"

/**
 * Sets the key to the passed "thing".
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/set_blackboard_key(key, thing)
	// Assume it is an error when trying to set a value overtop a list
	if(islist(blackboard[key]))
		CRASH("set_blackboard_key attempting to set a blackboard value to key [key] when it's a list!")
	// Don't do anything if it's already got this value
	if (blackboard[key] == thing)
		return

	// Clear existing values
	if(!isnull(blackboard[key]))
		clear_blackboard_key(key)

	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] = thing
	post_blackboard_key_set(key)

/**
 * Sets the key at index thing to the passed value
 *
 * Assumes the key value is already a list, if not throws an error.
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/set_blackboard_key_assoc(key, thing, value)
	if(!islist(blackboard[key]))
		CRASH("set_blackboard_key_assoc called on non-list key [key]!")
	// Don't do anything if it's already got this value
	if (blackboard[key][thing] == value)
		return

	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] = value
	post_blackboard_key_set(key)

/**
 * Similar to [proc/set_blackboard_key_assoc] but operates under the assumption the key is a lazylist (so it will create a list)
 * More dangerous / easier to override values, only use when you want to use a lazylist
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/set_blackboard_key_assoc_lazylist(key, thing, value)
	LAZYINITLIST(blackboard[key])
	// Don't do anything if it's already got this value
	if (blackboard[key][thing] == value)
		return

	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] = value
	post_blackboard_key_set(key)

/**
 * Called after we set a blackboard key, forwards signal information.
 */
/datum/ai_controller/proc/post_blackboard_key_set(key)
	if (isnull(pawn))
		return
	//появление цели снимает бронь бакета SSmobs: should_bypass_life_throttle()
	//обязан увидеть её на ближайшем проходе, а не через 4 фаера
	if(key == BB_AI_CURRENT_TARGET && ai_status == AI_STATUS_ON && isliving(pawn))
		var/mob/living/living_pawn = pawn
		living_pawn.wake_life()
	SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_SET(key))

/**
 * Adds the passed "thing" to the associated key
 *
 * Works with lists or numbers, but not lazylists.
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/add_blackboard_key(key, thing)
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] += thing

/**
 * Similar to [proc/add_blackboard_key], but performs an insertion rather than an add
 * Throws an error if the key is not a list already, intended only for use with lists
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/insert_blackboard_key(key, thing)
	if(!islist(blackboard[key]))
		CRASH("insert_blackboard_key called on non-list key [key]!")
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] |= thing

/**
 * Adds the passed "thing" to the associated key, assuming key is intended to be a lazylist (so it will create a list)
 * More dangerous / easier to override values, only use when you want to use a lazylist
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/add_blackboard_key_lazylist(key, thing)
	LAZYINITLIST(blackboard[key])
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] += thing

/**
 * Similar to [proc/insert_blackboard_key_lazylist], but performs an insertion / or rather than an add
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/insert_blackboard_key_lazylist(key, thing)
	LAZYINITLIST(blackboard[key])
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] |= thing

/**
 * Adds the value to the inner list at key with the inner key set to "thing"
 * Throws an error if the key is not a list already, intended only for use with lists
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/add_blackboard_key_assoc(key, thing, value)
	if(!islist(blackboard[key]))
		CRASH("add_blackboard_key_assoc called on non-list key [key]!")
	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] += value


/**
 * Similar to [proc/add_blackboard_key_assoc], assuming key is intended to be a lazylist (so it will create a list)
 * More dangerous / easier to override values, only use when you want to use a lazylist
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/add_blackboard_key_assoc_lazylist(key, thing, value)
	LAZYINITLIST(blackboard[key])
	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] += value

/**
 * Clears the passed key, resetting it to null
 *
 * Not intended for use with list keys - use [proc/remove_thing_from_blackboard_key] if you are removing a value from a list at a key
 *
 * * key - A blackboard key
 */
/datum/ai_controller/proc/clear_blackboard_key(key)
	//Match set_blackboard_key's same-value no-op contract. Broadcasting a clear
	//for an already absent key makes adapters repeat LoseTarget(), movement
	//cancellation and signals during every failed acquisition pass.
	if(isnull(blackboard[key]))
		return
	CLEAR_AI_DATUM_TARGET(blackboard[key], key)
	blackboard[key] = null
	if(isnull(pawn))
		return
	SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_CLEARED(key))

/**
 * Remove the passed thing from the associated blackboard key
 *
 * Intended for use with lists, if you're just clearing a reference from a key use [proc/clear_blackboard_key]
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/remove_thing_from_blackboard_key(key, thing)
	var/associated_value = blackboard[key]
	if(thing == associated_value)
		stack_trace("remove_thing_from_blackboard_key was called un-necessarily in a situation where clear_blackboard_key would suffice. ")
		clear_blackboard_key(key)
		return

	if(!islist(associated_value))
		CRASH("remove_thing_from_blackboard_key called with an invalid \"thing\" argument ([thing]). \
			(The associated value of the passed key is not a list and is also not the passed thing, meaning it is clearing an unintended value.)")

	for(var/inner_key in associated_value)
		if(inner_key == thing)
			// flat list
			CLEAR_AI_DATUM_TARGET(thing, key)
			associated_value -= thing
			return
		else if(associated_value[inner_key] == thing)
			// assoc list
			CLEAR_AI_DATUM_TARGET(thing, key)
			associated_value -= inner_key
			return

	CRASH("remove_thing_from_blackboard_key called with an invalid \"thing\" argument ([thing]). \
		(The passed value is not tracked in the passed list.)")

/// Signal proc to go through every key and remove the datum from all keys it finds
/datum/ai_controller/proc/sig_remove_from_blackboard(datum/source)
	SIGNAL_HANDLER

	var/list/list/remove_queue = list(blackboard)
	var/index = 1
	while(index <= length(remove_queue))
		var/list/next_to_clear = remove_queue[index]
		for(var/inner_value in next_to_clear)
			var/associated_value = next_to_clear[inner_value]
			// We are a lists of lists, add the next value to the queue so we can handle references in there
			// (But we only need to bother checking the list if it's not empty.)
			if(islist(inner_value) && length(inner_value))
				UNTYPED_LIST_ADD(remove_queue, inner_value)

			// We found the value that's been deleted. Clear it out from this list
			else if(inner_value == source)
				next_to_clear -= inner_value

			// We are an assoc lists of lists, the list at the next value so we can handle references in there
			// (But again, we only need to bother checking the list if it's not empty.)
			if(islist(associated_value) && length(associated_value))
				UNTYPED_LIST_ADD(remove_queue, associated_value)

			// We found the value that's been deleted, it was an assoc value. Clear it out entirely
			else if(associated_value == source)
				next_to_clear -= inner_value

		index += 1

#undef TRACK_AI_DATUM_TARGET
#undef CLEAR_AI_DATUM_TARGET
#undef TRAIT_AI_TRACKING
