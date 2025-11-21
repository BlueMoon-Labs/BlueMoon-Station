/*
Unused icons for new areas are "awaycontent1" ~ "awaycontent30"
*/


// Away Missions
/area/awaymission
	name = "Strange Location"
	icon_state = "away"
	has_gravity = STANDARD_GRAVITY
	// ambience_index = AMBIENCE_AWAY
	ambientsounds = AWAY_MISSION
	sound_environment = SOUND_ENVIRONMENT_ROOM

/area/awaymission/beach
	name = "Beach"
	icon_state = "away"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	shipambience = 'sound/ambience/zone/beach.ogg'
	ambientsounds = list('sound/ambience/shore.ogg', 'sound/ambience/seag1.ogg','sound/ambience/seag2.ogg','sound/ambience/seag2.ogg','sound/ambience/ambiodd.ogg','sound/ambience/ambinice.ogg')

/area/awaymission/beachhotel
	name = "Beach hotel"
	icon_state = "crew_quarters"
	has_gravity = STANDARD_GRAVITY
	shipambience = 'sound/ambience/zone/beach.ogg'
	ambientsounds = list('sound/ambience/shore.ogg', 'sound/ambience/seag1.ogg','sound/ambience/seag2.ogg','sound/ambience/seag2.ogg','sound/ambience/ambiodd.ogg','sound/ambience/ambinice.ogg')


/area/awaymission/errorroom
	name = "Super Secret Room"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	has_gravity = STANDARD_GRAVITY

/area/awaymission/vr
	name = "Virtual Reality"
	icon_state = "awaycontent1"
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	var/pacifist = TRUE // if when you enter this zone, you become a pacifist or not
	var/death = FALSE // if when you enter this zone, you die
	// network_root_id = "VR"

/area/awaymission/InteQ

	name = "InteQGate"
	icon_state = "away"
	has_gravity = STANDARD_GRAVITY
	// ambience_index = AMBIENCE_AWAY
	ambientsounds = AWAY_MISSION
	sound_environment = SOUND_ENVIRONMENT_ROOM


/area/awaymission/InteQ/ForChasmArea //Зона, куда попадают упавшие в чазм
	name = "pit"

//сам код чазма
/turf/open/chasm/gateInteQ
	name = "pit"

/turf/open/chasm/gateInteQ/Initialize(mapload)
	. = ..()
	var/turf/T = safepick(get_area_turfs(/area/awaymission/InteQ/ForChasmArea))
	if(T)
		set_target(T)

/area/awaymission/InteQ/lvl2

	name = "InteQGate"
	icon_state = "away"
	has_gravity = STANDARD_GRAVITY
	// ambience_index = AMBIENCE_AWAY
	ambientsounds = AWAY_MISSION
	sound_environment = SOUND_ENVIRONMENT_ROOM

/area/awaymission/InteQ/lvl3
	name = "InteQGate"
	icon_state = "away"
	has_gravity = STANDARD_GRAVITY
	// ambience_index = AMBIENCE_AWAY
	ambientsounds = AWAY_MISSION
	sound_environment = SOUND_ENVIRONMENT_ROOM
