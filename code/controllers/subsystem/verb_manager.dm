/**
 * SSverb_manager (порт tg/Paradise): очередь отложенных вербов.
 *
 * Вербы игроков исполняются BYOND'ом в той же части тика, что и остальной DM,
 * и когда тик уже переполнен, дорогой верб (осмотр, резист, речь) добивает его
 * до овертайма. Вместо этого верб оборачивается в /datum/callback/verb_callback
 * и, если TICK_USAGE выше порога, откладывается в очередь этой подсистемы:
 * она SS_TICKER с максимальным приоритетом и прогоняет всю очередь в начале
 * следующего тика без yield'ов.
 *
 * По умолчанию очередь пуста почти всегда: при незагруженном тике макрос
 * QUEUE_OR_CALL_VERB исполняет верб немедленно.
 */
SUBSYSTEM_DEF(verb_manager)
	name = "Verb Manager"
	wait = 1
	flags = SS_TICKER | SS_NO_INIT
	priority = FIRE_PRIORITY_DELAYED_VERBS
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	///list of callbacks to execute, cleared every run
	var/list/datum/callback/verb_callback/verb_queue = list()
	///running average of verbs executed from the queue per second
	var/verbs_executed_per_second = 0
	///if TRUE, verbs from admins can also be queued (normally they bypass)
	var/can_queue_admin_verbs = FALSE
	///emergency bypass: TRUE makes everything execute immediately
	var/FOR_ADMINS_IF_VERBS_FUCKED_immediately_execute_all_verbs = FALSE
	///message admins when a verb gets queued (debug)
	var/message_admins_on_queue = FALSE
	///TRUE = always queue regardless of tick usage (unless the bypass is on). Used by subtypes and tests.
	var/always_queue = FALSE

///wrapper for the QUEUE_OR_CALL_VERB macros: queue on an overloaded tick,
///otherwise execute immediately. Exists so the macro evaluates the callback
///expression exactly once.
/proc/_queue_or_call_verb(datum/callback/verb_callback/incoming_callback, ...)
	if(!_queue_verb(arglist(args)))
		incoming_callback.InvokeAsync()

/**
 * Global entry point (called through the TRY_QUEUE_VERB family of macros).
 * Returns TRUE if the callback was queued, FALSE if the caller should just
 * execute it now.
 */
/proc/_queue_verb(datum/callback/verb_callback/incoming_callback, tick_check, datum/controller/subsystem/verb_manager/subsystem_to_use = SSverb_manager, ...)
	if(QDELETED(incoming_callback))
		stack_trace("_queue_verb() given a deleted callback!")
		return FALSE
	if(!istext(incoming_callback.object) && QDELETED(incoming_callback.object)) //just in case the object is GLOBAL_PROC
		stack_trace("_queue_verb() given a callback with a deleted object!")
		return FALSE
	//we want unit tests to be able to directly call procs that would normally be player input
#ifndef UNIT_TESTS
	if(QDELETED(usr) || isnull(usr.client))
		stack_trace("_queue_verb() returned false because it wasn't called from player input!")
		return FALSE
#endif
	if(!istype(subsystem_to_use))
		stack_trace("_queue_verb() was given an invalid subsystem to queue for!")
		return FALSE

	if((TICK_USAGE < tick_check) && !subsystem_to_use.always_queue)
		return FALSE

	var/list/args_to_check = args.Copy()
	args_to_check.Cut(2, 4) //cut out tick_check and subsystem_to_use

	//any subsystem can define additional checks on the verification args
	if(!subsystem_to_use.can_queue_verb(arglist(args_to_check)))
		return FALSE

	return subsystem_to_use.queue_verb(incoming_callback)

/**
 * Subsystem-level gate: FALSE means "execute immediately instead".
 * Subtypes may take additional arguments after the callback.
 */
/datum/controller/subsystem/verb_manager/proc/can_queue_verb(datum/callback/verb_callback/incoming_callback)
	if(always_queue && !FOR_ADMINS_IF_VERBS_FUCKED_immediately_execute_all_verbs)
		return TRUE
	if((usr?.client?.holder && !can_queue_admin_verbs) \
	|| (!initialized && !(flags & SS_NO_INIT)) \
	|| FOR_ADMINS_IF_VERBS_FUCKED_immediately_execute_all_verbs \
	|| !(runlevels & Master.current_runlevel))
		return FALSE
	return TRUE

///actually queue the callback. Subtypes may override for additional handling.
/datum/controller/subsystem/verb_manager/proc/queue_verb(datum/callback/verb_callback/incoming_callback)
	. = FALSE //errored
	if(message_admins_on_queue)
		message_admins("[name] verb queuing: tick usage: [TICK_USAGE]%, proc: [incoming_callback.delegate], object: [incoming_callback.object], usr: [usr]")
	verb_queue += incoming_callback
	return TRUE

/datum/controller/subsystem/verb_manager/fire(resumed)
	run_verb_queue()

///runs through all of this subsystem's queue of verb callbacks WITHOUT yielding
/datum/controller/subsystem/verb_manager/proc/run_verb_queue()
	var/executed_verbs = 0
	for(var/datum/callback/verb_callback/queued_callback as anything in verb_queue)
		if(!istype(queued_callback))
			stack_trace("non /datum/callback/verb_callback inside [name]'s verb_queue!")
			continue
		// Замер синхронной части верба: дорогой верб раньше был неотличим
		// от анонимного "DM вне МК" в логе тик-спайков
		var/invoke_started = TICK_USAGE
		queued_callback.InvokeAsync()
		var/invoke_cost_ms = TICK_DELTA_TO_MS(TICK_USAGE - invoke_started)
		if(SStick_spikes && invoke_cost_ms >= SStick_spikes.slow_work_threshold_ms)
			SStick_spikes.record_slow_work("верб", SStick_spikes.callback_desc(queued_callback), invoke_cost_ms)
		executed_verbs++
	verb_queue.Cut()
	verbs_executed_per_second = MC_AVERAGE(verbs_executed_per_second, executed_verbs / (wait * world.tick_lag / 10))

/datum/controller/subsystem/verb_manager/stat_entry(msg)
	msg = "Q:[length(verb_queue)] V/S:[round(verbs_executed_per_second, 0.01)]"
	return ..()

/datum/controller/subsystem/verb_manager/Recover()
	verb_queue = SSverb_manager.verb_queue
