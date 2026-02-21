/datum/round_event_control/spawners
	name = "Portal in netherworld (base type)"
	typepath = /datum/round_event/spawners

	min_players = 1
	max_occurrences = 0 // base type, no spawn
	weight = 5
	earliest_start = 25 MINUTES
	category = EVENT_CATEGORY_SPAWNERS
	description = "Don't spawn."
	admin_setup = list(/datum/event_admin_setup/set_location/spawners)

/datum/round_event_control/spawners/nether
	name = "Portal in netherworld"
	max_occurrences = 1

/datum/round_event/spawners
	start_when = ANOMALY_START_DANGEROUS_TIME
	announce_when = ANOMALY_ANNOUNCE_DANGEROUS_TIME
	var/area/impact_area
	var/datum/anomaly_placer/placer = new()
	var/obj/structure/spawner/spawner_path = /obj/structure/spawner/nether
	///The admin-chosen spawn location.
	var/turf/spawn_location
	var/triggersound = 'sound/announcer/classic/_admin_horror_music.ogg'

/datum/round_event/spawners/announce(fake)
	do_announce()

/datum/round_event/spawners/proc/do_announce()
	set waitfor = FALSE
	sound_to_playing_players('sound/magic/lightning_chargeup.ogg')
	sleep(80)
	priority_announce("На [station_name()] зафиксирован разрыв в пространстве. Приготовьтесь к столкновению с угрозами из иных планов.", "Центральное Командование, Отдел Работы с Реальностью", triggersound)

/datum/round_event/spawners/start()
    var/turf/T
    if(spawn_location)
        impact_area = get_area(spawn_location)
        T = spawn_location
    else
        impact_area = placer.findValidArea()
        T = placer.findValidTurf(impact_area)

    if(!T)
        return

    . = new spawner_path(T)
    if(.)
        apply_spawner_properties(.)
        announce_to_ghosts(.)

/// Make any further post-creation modifications to the anomaly
/datum/round_event/spawners/proc/apply_spawner_properties(obj/effect/anomaly/new_anomaly)
	return

/datum/event_admin_setup/set_location/spawners
	input_text = "Spawn portal at your current location?"

/datum/event_admin_setup/set_location/spawners/apply_to_event(datum/round_event/anomaly/event)
	event.spawn_location = chosen_turf
