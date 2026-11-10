/// What typepath of the hallucination
#define HALLUCINATION_ARG_TYPE 1
/// Where the hallucination came from, for logging
#define HALLUCINATION_ARG_SOURCE 2
/// Onwards from this index, it's the arglist that gets passed into the hallucination created.
#define HALLUCINATION_ARGLIST 3

/datum/round_event_control/mass_hallucination
	name = "Mass Hallucination"
	typepath = /datum/round_event/mass_hallucination
	// Флавор, но навязчивый: звуки и видения ловит вся станция разом, посреди спокойной сцены
	// это мешает. Метка mild режет его вес в мягких профилях (Extended/Light).
	weight = 40
	max_occurrences = 3
	min_players = 1
	disruption = DIRECTOR_DISRUPTION_MILD
	var/forced_hallucination
	category = EVENT_CATEGORY_HEALTH
	severity = DIRECTOR_SEVERITY_FLAVOR
	description = "Multiple crewmembers start to hallucinate the same thing."
	admin_setup = list(/datum/event_admin_setup/mass_hallucination)

/datum/round_event/mass_hallucination
	fakeable = FALSE
	/// For admins, what hallucination did we pick
	var/admin_forced_hallucination
	/// For admins, what arguments are we passing to said hallucination
	var/list/admin_forced_args

/// Кому вообще имеет смысл рассылать массовую галлюцинацию.
/// Проверка клиента здесь ключевая: в раунде 10137 событие создало сто галлюцинаций за одну
/// секунду, и все сто целей были обезьянами без ключа - показывать их было буквально некому,
/// а тик и строку в investigate-логе каждая из них съела.
/datum/round_event/mass_hallucination/proc/get_hallucination_targets()
	. = list()
	for(var/mob/living/carbon/carbon_target in GLOB.alive_mob_list)
		if(!carbon_target.client)
			continue
		if(HAS_TRAIT(carbon_target, TRAIT_EXEMPT_HEALTH_EVENTS))
			continue
		. += carbon_target

/datum/round_event/mass_hallucination/start()
	var/datum/round_event_control/mass_hallucination/M = control
	var/list/targets = get_hallucination_targets()
	if(!length(targets))
		return
	if(M.forced_hallucination)
		INVOKE_ASYNC(src, PROC_REF(hallucinate_targets), targets, M.forced_hallucination)
		return

	switch(rand(1,4))
		if(1) //same sound for everyone
			var/sound = pick("airlock","airlock_pry","console","explosion","far_explosion","mech","glass","alarm","beepsky","mech","wall_decon","door_hack","tesla","seth")
			INVOKE_ASYNC(src, PROC_REF(hallucinate_targets), targets, /datum/hallucination/sounds, sound)
		if(2)
			var/weirdsound = pick("phone","hallelujah","highlander","hyperspace","game_over","creepy","tesla")
			INVOKE_ASYNC(src, PROC_REF(hallucinate_targets), targets, /datum/hallucination/weird_sounds, weirdsound)
		if(3)
			var/stationmessage = pick("ratvar","shuttle dock","blob alert","malf ai","heretic","cult summon","meteors","supermatter")
			INVOKE_ASYNC(src, PROC_REF(hallucinate_targets), targets, /datum/hallucination/stationmessage, stationmessage)
		if(4 to 6)
			var/picked_hallucination = pick(	/datum/hallucination/bolts,
												/datum/hallucination/chat,
												/datum/hallucination/message,
												/datum/hallucination/bolts,
												/datum/hallucination/fake_flood,
												/datum/hallucination/battle,
												/datum/hallucination/fire,
												/datum/hallucination/self_delusion,
												/datum/hallucination/death,
												/datum/hallucination/delusion,
												/datum/hallucination/oh_yeah)
			INVOKE_ASYNC(src, PROC_REF(hallucinate_targets), targets, picked_hallucination)

/// Галлюцинация каждой цели стоит до десятка мс (картинки на всех людей станции, поиск дверей вокруг):
/// сотня целей одним куском давала до 1.2 с стоп-кадра. Цели обходятся кусками по тикам.
/datum/round_event/mass_hallucination/proc/hallucinate_targets(list/targets, hallucination_type, hallucination_arg)
	for(var/mob/living/carbon/C as anything in targets)
		if(QDELETED(C) || !C.client)
			continue
		if(isnull(hallucination_arg))
			new hallucination_type(C, TRUE)
		else
			new hallucination_type(C, TRUE, hallucination_arg)
		CHECK_TICK

/datum/event_admin_setup/mass_hallucination
	/// For admins, what hallucination did we pick
	var/admin_forced_hallucination
	/// For admins, what arguments are we passing to said hallucination
	var/list/admin_forced_args

/datum/event_admin_setup/mass_hallucination/prompt_admins()
	var/force = tgui_alert(usr, "Do you want to force a hallucination?", event_control.name, list("Yes", "No", "Cancel"))
	if(force == "Cancel")
		return ADMIN_CANCEL_EVENT
	if(force != "Yes")
		return

	if(!check_rights(R_FUN))
		return

	var/force_what = tgui_alert(usr, "Generic hallucination or Custom configured delusion? (Delusions are those which make people appear as other mobs)", event_control.name, list("Hallucination", "Custom Delusion", "Cancel"))
	switch(force_what)
		if("Cancel")
			return ADMIN_CANCEL_EVENT

		if("Hallucination")
			var/chosen = select_hallucination_type(usr, "What hallucination should be forced for [event_control.name]?", event_control.name)
			if(!chosen || !check_rights(R_FUN))
				return ADMIN_CANCEL_EVENT

			admin_forced_hallucination = chosen

		if("Custom Delusion")
			var/list/chosen_args = create_delusion(usr)
			if(!length(chosen_args) || !check_rights(R_FUN))
				return ADMIN_CANCEL_EVENT

			admin_forced_hallucination = chosen_args[HALLUCINATION_ARG_TYPE]
			admin_forced_args = chosen_args.Copy(HALLUCINATION_ARGLIST)

/datum/event_admin_setup/mass_hallucination/apply_to_event(datum/round_event/mass_hallucination/event)
	event.admin_forced_hallucination = admin_forced_hallucination
	event.admin_forced_args = admin_forced_args
