// PORT: tgstation@14140a6355d1 code/controllers/subsystem/ai_controllers.dm
// Планировщик активных контроллеров: обходит ТОЛЬКО бакет AI_STATUS_ON.
// Спящие (IDLE) и выключенные (OFF) контроллеры не трогаются вообще -
// пробуждение событийное (см. on_client_enter / update_z / adjustHealth).
/// The subsystem used to tick [/datum/ai_controller] instances. Handling the re-checking of plans.
SUBSYSTEM_DEF(ai_controllers)
	name = "AI Controller Ticker"
	flags = SS_POST_FIRE_TIMING|SS_BACKGROUND
	priority = FIRE_PRIORITY_NPC
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	init_order = INIT_ORDER_AI_CONTROLLERS
	wait = 0.5 SECONDS //Plan every half second if required, not great not terrible.

	///Планируемый в этом фире срез активных контроллеров
	var/list/currentrun = list()

/datum/controller/subsystem/ai_controllers/Initialize()
	. = ..()
	setup_subtrees()
	//Пол скорости погони считается заново здесь, а не только из ValidateAndSet
	//конфига: GLOBAL_VAR_INIT печёт его до того, как world.tick_lag выставлен из
	//конфига, а без строки RUN_DELAY в конфиге ValidateAndSet не зовётся вовсе -
	//мир без строки (CI) жил с мусорным полом навсегда.
	update_ai_pursuit_speed_floor()

/datum/controller/subsystem/ai_controllers/stat_entry(msg)
	msg = "ON:[length(GLOB.ai_controllers_by_status[AI_STATUS_ON])]|IDLE:[length(GLOB.ai_controllers_by_status[AI_STATUS_IDLE])]|OFF:[length(GLOB.ai_controllers_by_status[AI_STATUS_OFF])]"
	return ..()

/datum/controller/subsystem/ai_controllers/proc/setup_subtrees()
	for(var/subtree_type in subtypesof(/datum/ai_planning_subtree))
		var/datum/ai_planning_subtree/subtree = new subtree_type
		GLOB.ai_subtrees[subtree_type] = subtree

/datum/controller/subsystem/ai_controllers/fire(resumed)
	if(!resumed)
		var/list/active_controllers = GLOB.ai_controllers_by_status[AI_STATUS_ON]
		src.currentrun = active_controllers.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(length(currentrun))
		var/datum/ai_controller/ai_controller = currentrun[currentrun.len]
		currentrun.len--

		if(QDELETED(ai_controller) || isnull(ai_controller.pawn))
			continue
		if(!ai_controller.able_to_plan)
			continue

		AI_METRIC_INC(planning_cycles)
		ai_controller.SelectBehaviors(wait * 0.1)
		if(!LAZYLEN(ai_controller.current_behaviors)) //Still no plan
			ai_controller.planning_failed()

		if(MC_TICK_CHECK)
			return
