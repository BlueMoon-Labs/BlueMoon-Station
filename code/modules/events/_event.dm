
#define RANDOM_EVENT_ADMIN_INTERVENTION_TIME 30

//this datum is used by the events controller to dictate how it selects events
/datum/round_event_control
	parent_type = /datum/director_action
	director_kind = DIRECTOR_KIND_EVENT
	max_occurrences = 20
	earliest_start = 30 MINUTES
	var/name						//The human-readable name of the event
	var/category					//The category of the event
	var/description					//The description of the event
	var/typepath					//The typepath of the event datum /datum/round_event

	var/holidayID = ""				//string which should be in the SSholidays.holidays list if you wish this event to be holiday-specific
									//anything with a (non-null) holidayID which does not match holiday, cannot run.
	var/wizardevent = FALSE
	var/random = FALSE				//If the event has occured randomly, or if it was forced by an admin or in-game occurance
	var/alert_observers = TRUE		//should we let the ghosts and admins know this event is firing
									//should be disabled on events that fire a lot

	var/triggering	//admin cancellation

	/// Datum that will handle admin options for forcing the event.
	/// If there are no options, just leave it as an empty list.
	var/list/datum/event_admin_setup/admin_setup = list()

/datum/round_event_control/New()
	if(config && !wizardevent) // Magic is unaffected by configs
		earliest_start = CEILING(earliest_start * CONFIG_GET(number/events_min_time_mul), 1)
		min_players = CEILING(min_players * CONFIG_GET(number/events_min_players_mul), 1)
	// Дефолты severity/cost/intensity по категории. Тела датумов могут переопределить severity
	// явно выше по цепочке New() (переопределения живут как var-инициализация, а не в New()),
	// поэтому здесь только достраиваем то, что ещё не проставлено.
	if(isnull(severity))
		switch(category)
			if(EVENT_CATEGORY_FRIENDLY, EVENT_CATEGORY_HOLIDAY, EVENT_CATEGORY_WIZARD)
				severity = DIRECTOR_SEVERITY_FLAVOR
			if(EVENT_CATEGORY_JANITORIAL, EVENT_CATEGORY_BUREAUCRATIC, EVENT_CATEGORY_SPAWNERS)
				severity = DIRECTOR_SEVERITY_MINOR
			if(EVENT_CATEGORY_HEALTH, EVENT_CATEGORY_ENGINEERING, EVENT_CATEGORY_AI)
				severity = DIRECTOR_SEVERITY_MODERATE
			if(EVENT_CATEGORY_SPACE, EVENT_CATEGORY_INVASION, EVENT_CATEGORY_ENTITIES, EVENT_CATEGORY_ANOMALIES)
				severity = DIRECTOR_SEVERITY_MAJOR
			else
				severity = DIRECTOR_SEVERITY_MINOR
	if(!cost)
		switch(severity)
			if(DIRECTOR_SEVERITY_FLAVOR)
				cost = 0
			if(DIRECTOR_SEVERITY_MINOR)
				cost = 2
			if(DIRECTOR_SEVERITY_MODERATE)
				cost = 6
			if(DIRECTOR_SEVERITY_MAJOR)
				// 25 при капле MAJOR-кошелька ~0.15-0.2/мин означало "первый мажор через три часа";
				// 20 с поднятой долей MAJOR в профилях даёт мажору шанс в пределах длинного раунда.
				cost = 20
			if(DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST)
				cost = 10
	if(!intensity)
		switch(severity)
			if(DIRECTOR_SEVERITY_MINOR)
				intensity = 5
			if(DIRECTOR_SEVERITY_MODERATE)
				intensity = 15
			if(DIRECTOR_SEVERITY_MAJOR)
				intensity = 40
			if(DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST)
				intensity = 15
	if(!intensity_linger)
		switch(severity)
			if(DIRECTOR_SEVERITY_MAJOR)
				intensity_linger = 10 MINUTES
			if(DIRECTOR_SEVERITY_MODERATE)
				// One-shot спавнеры (аномалии, манекен) гаснут за тик, а их последствия живут
				// минуты: без linger панель показывала intensity 0 при двух живых аномалиях,
				// и порог тишины не видел только что случившийся контент.
				intensity_linger = 8 MINUTES
			if(DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST)
				// Антаг-события - спавнеры: событие гаснет за тик, а кошмар/дракон живут дальше.
				// Долгий linger держит их вклад в antag_load (клапан давления) без трекинга моба;
				// провал спавна снимает вклад сразу (см. refund_failed_spawn в ghost_role.dm).
				intensity_linger = 30 MINUTES
	if(!length(admin_setup))
		return
	var/list/admin_setup_types = admin_setup.Copy()
	admin_setup.Cut()
	for(var/admin_setup_type in admin_setup_types)
		admin_setup += new admin_setup_type(src)

/datum/round_event_control/wizard
	category = EVENT_CATEGORY_WIZARD
	wizardevent = TRUE
	var/can_be_midround_wizard = TRUE

/datum/round_event_control/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	if(wizardevent != SSdirector.wizardmode)
		return FALSE
	if(holidayID && (!SSholidays.holidays || !SSholidays.holidays[holidayID]))
		return FALSE
	return TRUE

/datum/round_event_control/wizard/can_fire(datum/director_signals/signals)
	if(istype(SSticker.mode, /datum/game_mode/dynamic))
		var/datum/game_mode/dynamic/mode = SSticker.mode
		if(locate(/datum/dynamic_ruleset/midround/from_ghosts/wizard) in mode.executed_rules)
			return can_be_midround_wizard && ..()
	return ..()



/// admin_window: открывать ли 30-секундное окно отмены с повторной проверкой.
/// Запуски через директора (execute_action) идут с FALSE - у директора своё окно
/// отмены для MODERATE+ в announce_pick(), второе окно подряд не нужно.
/datum/round_event_control/proc/preRunEvent(admin_window = TRUE)
	if(!ispath(typepath, /datum/round_event))
		return EVENT_CANT_RUN

	if (SEND_GLOBAL_SIGNAL(COMSIG_GLOB_PRE_RANDOM_EVENT, src) & CANCEL_PRE_RANDOM_EVENT)
		return EVENT_INTERRUPTED

	triggering = TRUE
	if (admin_window && alert_observers)
		message_admins("Random Event triggering in [RANDOM_EVENT_ADMIN_INTERVENTION_TIME] seconds: [name] (<a href='?src=[REF(src)];cancel=1'>CANCEL</a>)")
		sleep(RANDOM_EVENT_ADMIN_INTERVENTION_TIME SECONDS)
		if(!can_fire(SSdirector.collect_signals()))
			message_admins("Second pre-condition check for [name] failed, skipping...")
			return EVENT_INTERRUPTED

	if(!triggering)
		return EVENT_CANCELLED	//admin cancelled
	triggering = FALSE
	return EVENT_READY

/datum/round_event_control/Topic(href, href_list)
	..()
	if(href_list["cancel"])
		if(!triggering)
			to_chat(usr, "<span class='admin'>You are too late to cancel that event</span>")
			return
		triggering = FALSE
		message_admins("[key_name_admin(usr)] cancelled event [name].")
		log_admin_private("[key_name(usr)] cancelled event [name].")
		SSblackbox.record_feedback("tally", "event_admin_cancelled", 1, typepath)

/*
Runs the event
* Arguments:
* - random: shows if the event was triggered randomly, or by on purpose by an admin or an item
* - announce_chance_override: if the value is not null, overrides the announcement chance when an admin calls an event
*/
/datum/round_event_control/proc/runEvent(random = FALSE, announce_chance_override = null, admin_forced = FALSE, increase_occurrences = TRUE)
	var/datum/round_event/E = new typepath()
	E.triggered_randomly = random
	if(admin_forced && length(admin_setup))
		//not part of the signal because it's conditional and relies on usr heavily
		for(var/datum/event_admin_setup/admin_setup_datum in admin_setup)
			admin_setup_datum.apply_to_event(E)
	E.current_players = get_active_player_count(alive_check = 1, afk_check = 1, human_check = 1)
	E.control = src
	SSblackbox.record_feedback("tally", "event_ran", 1, "[E]")
	if(increase_occurrences)
		occurrences++

	if(announce_chance_override != null)
		E.announce_chance = announce_chance_override

	testing("[time2text(world.time, "hh:mm:ss")] [E.type]")
	if(random)
		log_game("Random Event triggering: [name] ([typepath])")
	if (alert_observers)
		deadchat_broadcast(" has just been[random ? " randomly" : ""] triggered!", "<b>[name]</b>", message_type=DEADCHAT_ANNOUNCEMENT) //STOP ASSUMING IT'S BADMINS!
	return E

//Special admins setup
/datum/round_event_control/proc/admin_setup()
	return

/datum/round_event_control/action_name()
	return name

/datum/round_event_control/execute_action()
	var/result = preRunEvent(admin_window = FALSE)
	if(result == EVENT_CANT_RUN)
		max_occurrences = 0
		return FALSE
	if(result != EVENT_READY)
		return FALSE
	// occurrences считает только директор (spend_and_execute/run_forced_events/wizard_beat),
	// иначе запуск через бит учитывался бы дважды.
	runEvent(random = TRUE, increase_occurrences = FALSE)
	return TRUE

/datum/round_event	//NOTE: Times are measured in master controller ticks!
	var/processing = TRUE
	/// Set from runEvent(): true if the event was rolled by the random event system (not from admin/item).
	var/triggered_randomly = FALSE
	var/datum/round_event_control/control

	/// When in the lifetime to call start().
	/// This is in seconds - so 1 = ~2 seconds in.
	var/start_when = 0
	/// When in the lifetime to call announce(). If you don't want it to announce use announce_chance, below.
	/// This is in seconds - so 1 = ~2 seconds in.
	var/announce_when = 0
	/// Probability of announcing, used in prob(), 0 to 100, default 100. Called in process, and for a second time in the ion storm event.
	var/announce_chance = 100
	/// When in the lifetime the event should end.
	/// This is in seconds - so 1 = ~2 seconds in.
	var/end_when = 0

	/// How long the event has existed. You don't need to change this.
	var/activeFor = 0
	/// Amount of of alive, non-AFK human players on server at the time of event start
	var/current_players = 0
	/// Can be faked by fake news event.
	var/fakeable = TRUE

//Called first before processing.
//Allows you to setup your event, such as randomly
//setting the start_when and or announce_when variables.
//Only called once.
//EDIT: if there's anything you want to override within the new() call, it will not be overridden by the time this proc is called.
//It will only have been overridden by the time we get to announce() start() tick() or end() (anything but setup basically).
//This is really only for setting defaults which can be overridden later when New() finishes.
/datum/round_event/proc/setup()
	return

//Called when the tick is equal to the start_when variable.
//Allows you to start before announcing or vice versa.
//Only called once.
/datum/round_event/proc/start()
	return

/**
  * Called after something followable has been spawned by an event
  * Provides ghosts a follow link to an atom if possible
  * Only called once.
  */
/datum/round_event/proc/announce_to_ghosts(atom/atom_of_interest)
	if(control.alert_observers)
		if (atom_of_interest)
			notify_ghosts("[control.name] has an object of interest: [atom_of_interest]!", source=atom_of_interest, action=NOTIFY_ORBIT, header="Something's Interesting!")
	return

//Called when the tick is equal to the announce_when variable.
//Allows you to announce before starting or vice versa.
//Only called once.
/datum/round_event/proc/announce(fake)
	return

//Called on or after the tick counter is equal to start_when.
//You can include code related to your event or add your own
//time stamped events.
//Called more than once.
/datum/round_event/proc/tick()
	return

//Called on or after the tick is equal or more than end_when
//You can include code related to the event ending.
//Do not place spawn() in here, instead use tick() to check for
//the activeFor variable.
//For example: if(activeFor == myOwnVariable + 30) doStuff()
//Only called once.
/datum/round_event/proc/end()
	return

//Do not override this proc, instead use the appropiate procs.
//This proc will handle the calls to the appropiate procs.
/datum/round_event/process()
	if(!processing)
		return

	if(activeFor == start_when)
		processing = FALSE
		start()
		processing = TRUE

	if(activeFor == announce_when && prob(announce_chance))
		processing = FALSE
		announce(FALSE)
		processing = TRUE

	if(start_when < activeFor && activeFor < end_when)
		processing = FALSE
		tick()
		processing = TRUE

	if(activeFor == end_when)
		processing = FALSE
		end()
		processing = TRUE

	// Everything is done, let's clean up.
	if(activeFor >= end_when && activeFor >= announce_when && activeFor >= start_when)
		processing = FALSE
		kill()

	activeFor++


//Garbage collects the event by removing it from the global events list,
//which should be the only place it's referenced.
//Called when start(), announce() and end() has all been called.
/datum/round_event/proc/kill()
	SSdirector.running -= src
	if(control)
		SSdirector.remove_intensity(control.action_name(), control.intensity_linger)


//Sets up the event then adds the event to the the list of running events
/datum/round_event/New(my_processing = TRUE)
	setup()
	processing = my_processing
	SSdirector.running += src
	return ..()
