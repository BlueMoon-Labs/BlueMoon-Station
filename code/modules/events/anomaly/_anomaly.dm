/datum/round_event_control/anomaly
	name = "Anomaly: Energetic Flux"
	typepath = /datum/round_event/anomaly

	min_players = 1
	max_occurrences = 0 //This one probably shouldn't occur! It'd work, but it wouldn't be very fun.
	weight = 15
	earliest_start = 10 MINUTES
	category = EVENT_CATEGORY_ANOMALIES
	description = "This anomaly shocks and explodes. This is the base type."
	admin_setup = list(/datum/event_admin_setup/set_location/anomaly)

/datum/round_event/anomaly
	start_when = ANOMALY_START_HARMFUL_TIME
	announce_when = ANOMALY_ANNOUNCE_HARMFUL_TIME
	var/area/impact_area
	var/datum/anomaly_placer/placer = new()
	var/obj/effect/anomaly/anomaly_path = /obj/effect/anomaly/flux
	///The admin-chosen spawn location.
	var/turf/spawn_location

/datum/round_event/anomaly/announce(fake)
	priority_announce("Обнаружен гипер-энергетический поток на [ANOMALY_ANNOUNCE_DANGEROUS_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_flux.ogg')

/datum/round_event/anomaly/start()
    var/turf/anomaly_turf
    if(spawn_location)
        impact_area = get_area(spawn_location)
        anomaly_turf = spawn_location
    else
        impact_area = placer.findValidArea()
        anomaly_turf = placer.findValidTurf(impact_area)

    if(!anomaly_turf)
        return

    . = new anomaly_path(anomaly_turf)
    if(.)
        apply_anomaly_properties(.)
        announce_to_ghosts(.)

/// Make any further post-creation modifications to the anomaly
/datum/round_event/anomaly/proc/apply_anomaly_properties(obj/effect/anomaly/new_anomaly)
	return

/datum/event_admin_setup/set_location/anomaly
	input_text = "Spawn anomaly at your current location?"

/datum/event_admin_setup/set_location/anomaly/apply_to_event(datum/round_event/anomaly/event)
	event.spawn_location = chosen_turf

