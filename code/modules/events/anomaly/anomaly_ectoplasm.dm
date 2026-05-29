#define ANOMALY_INTENSITY_MINOR "Minor Intensity"
#define ANOMALY_INTENSITY_MODERATE "Moderate Intensity"
#define ANOMALY_INTENSITY_MAJOR "Major Intensity"

/datum/round_event_control/anomaly/anomaly_ectoplasm
	name = "Anomaly: Ectoplasmic Outburst"
	description = "Anomaly that produces an effect of varying intensity based on how many ghosts are orbiting it."
	typepath = /datum/round_event/anomaly/anomaly_ectoplasm
	min_players = 30
	max_occurrences = 2
	weight = 4 //Rare because of it's wacky and silly nature
	category = EVENT_CATEGORY_ANOMALIES
	admin_setup = list(/datum/event_admin_setup/set_location/anomaly, /datum/event_admin_setup/anomaly_ectoplasm)

/datum/round_event/anomaly/anomaly_ectoplasm
	anomaly_path = /obj/effect/anomaly/ectoplasm
	start_when = ANOMALY_START_HARMFUL_TIME
	announce_when = ANOMALY_ANNOUNCE_HARMFUL_TIME
	///The admin-set impact effect intensity override
	var/effect_override
	///The admin-set number of ghosts, for use in calculating impact size.
	var/orbit_override

/datum/round_event/anomaly/anomaly_ectoplasm/apply_anomaly_properties(obj/effect/anomaly/ectoplasm/created_anomaly)
	if(isnull(effect_override) || isnull(orbit_override))
		return

	created_anomaly.override_ghosts = TRUE
	created_anomaly.effect_power = effect_override
	created_anomaly.ghosts_orbiting = orbit_override
	created_anomaly.intensity_update()

/datum/round_event/anomaly/anomaly_ectoplasm/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Паранормальная эктоплазменная вспышка зафиксирована на [ANOMALY_ANNOUNCE_HARMFUL_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_ectoplasm.ogg')

/datum/event_admin_setup/anomaly_ectoplasm
	///The admin-selected intensity
	var/chosen_effect
	///The number of ghosts the admin has selected to simulate orbiting the anomaly.
	var/ghost_override

/datum/event_admin_setup/anomaly_ectoplasm/prompt_admins()
	if(tgui_alert(usr, "Override the anomaly effect and power?", "You'll be ruining the authenticity.", list("Yes", "No")) != "Yes")
		return

	var/list/power_values = list(ANOMALY_INTENSITY_MINOR, ANOMALY_INTENSITY_MODERATE, ANOMALY_INTENSITY_MAJOR)
	var/chosen = tgui_input_list(usr, "Provide effect override", "Criiiiinge.", power_values)
	if(!chosen)
		return ADMIN_CANCEL_EVENT

	ghost_override = tgui_input_number(usr, "How many ghosts do you want simulate orbiting your anomaly? (determines the effect radius).", "Seriously, CRINGE.", 0, 20, 1)
	if(isnull(ghost_override))
		return ADMIN_CANCEL_EVENT

	switch(chosen)
		if(ANOMALY_INTENSITY_MINOR)
			chosen_effect = 10
		if(ANOMALY_INTENSITY_MODERATE)
			chosen_effect = 35
		if(ANOMALY_INTENSITY_MAJOR)
			chosen_effect = 50

/datum/event_admin_setup/anomaly_ectoplasm/apply_to_event(datum/round_event/anomaly/anomaly_ectoplasm/event)
	event.effect_override = chosen_effect
	event.orbit_override = ghost_override

#undef ANOMALY_INTENSITY_MINOR
#undef ANOMALY_INTENSITY_MODERATE
#undef ANOMALY_INTENSITY_MAJOR
