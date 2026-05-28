/// What typepath of the hallucination
#define HALLUCINATION_ARG_TYPE 1
/// Where the hallucination came from, for logging
#define HALLUCINATION_ARG_SOURCE 2
/// Onwards from this index, it's the arglist that gets passed into the hallucination created.
#define HALLUCINATION_ARGLIST 3

/datum/round_event_control/mass_hallucination
	name = "Mass Hallucination"
	typepath = /datum/round_event/mass_hallucination
	weight = 60
	max_occurrences = 5
	min_players = 1
	var/forced_hallucination
	category = EVENT_CATEGORY_HEALTH
	description = "Multiple crewmembers start to hallucinate the same thing."
	admin_setup = list(/datum/event_admin_setup/mass_hallucination)

/datum/round_event/mass_hallucination
	fakeable = FALSE
	/// For admins, what hallucination did we pick
	var/admin_forced_hallucination
	/// For admins, what arguments are we passing to said hallucination
	var/list/admin_forced_args

/datum/round_event/mass_hallucination/start()
	var/datum/round_event_control/mass_hallucination/M = control
	if(M.forced_hallucination)
		for(var/mob/living/carbon/C in GLOB.alive_mob_list)
			if (HAS_TRAIT(C,TRAIT_EXEMPT_HEALTH_EVENTS))
				continue
			new M.forced_hallucination(C, TRUE)
		return

	switch(rand(1,4))
		if(1) //same sound for everyone
			var/sound = pick("airlock","airlock_pry","console","explosion","far_explosion","mech","glass","alarm","beepsky","mech","wall_decon","door_hack","tesla","seth")
			for(var/mob/living/carbon/C in GLOB.alive_mob_list)
				new /datum/hallucination/sounds(C, TRUE, sound)
		if(2)
			var/weirdsound = pick("phone","hallelujah","highlander","hyperspace","game_over","creepy","tesla")
			for(var/mob/living/carbon/C in GLOB.alive_mob_list)
				new /datum/hallucination/weird_sounds(C, TRUE, weirdsound)
		if(3)
			var/stationmessage = pick("ratvar","shuttle dock","blob alert","malf ai","heretic","cult summon","meteors","supermatter")
			for(var/mob/living/carbon/C in GLOB.alive_mob_list)
				new /datum/hallucination/stationmessage(C, TRUE, stationmessage)
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
			for(var/mob/living/carbon/C in GLOB.alive_mob_list)
				if (HAS_TRAIT(C,TRAIT_EXEMPT_HEALTH_EVENTS))
					continue
				new picked_hallucination(C, TRUE)

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
