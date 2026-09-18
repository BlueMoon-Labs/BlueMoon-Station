#define PETSPLOSION_MAX_DUPES 400
/// activeFor ticks between replication waves
#define PETSPLOSION_WAVE_INTERVAL 30

/datum/round_event_control/wizard/petsplosion //the horror
	name = "Petsplosion"
	weight = 2
	typepath = /datum/round_event/wizard/petsplosion
	max_occurrences = 1 //Exponential growth is nothing to sneeze at!
	earliest_start = 0 MINUTES
	var/mobs_to_dupe = 0
	description = "Rapidly multiplies the animals on the station."

/datum/round_event_control/wizard/petsplosion/preRunEvent(admin_window = TRUE)
	for(var/mob/living/simple_animal/F in GLOB.alive_mob_list)
		if(!ishostile(F) && is_station_level(F.z))
			mobs_to_dupe++
	if(mobs_to_dupe > 100 || !mobs_to_dupe)
		return EVENT_CANT_RUN

	return ..()

/datum/round_event/wizard/petsplosion
	end_when = 61 //1 minute (+1 tick for end_when not to interfere with tick)
	var/countdown = 0
	var/mobs_duped = 0
	var/max_dupes = PETSPLOSION_MAX_DUPES

/datum/round_event/wizard/petsplosion/tick()
	if(activeFor < PETSPLOSION_WAVE_INTERVAL * countdown) // 0 seconds : 2 animals | 30 seconds : 4 animals | 1 minute : 8 animals
		return
	countdown += 1
	var/list/to_dupe = list()
	for(var/mob/living/simple_animal/F in GLOB.alive_mob_list) //If you cull the heard before the next replication, things will be easier for you
		if(!ishostile(F) && is_station_level(F.z))
			to_dupe += F
	for(var/mob/living/simple_animal/F as anything in to_dupe)
		if(mobs_duped >= max_dupes)
			kill()
			return
		if(QDELETED(F))
			continue
		new F.type(F.loc)
		mobs_duped++
		CHECK_TICK

#undef PETSPLOSION_MAX_DUPES
#undef PETSPLOSION_WAVE_INTERVAL
