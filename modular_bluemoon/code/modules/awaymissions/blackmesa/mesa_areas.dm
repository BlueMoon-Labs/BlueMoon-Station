/area/awaymission/ihategordon
	name = "Main sector H complex"
	shipambience ='modular_bluemoon/sound/ambience/mesa/ambinside.ogg'
	ambientsounds = list('modular_bluemoon/sound/ambience/mesa/metal1.ogg' , 'modular_bluemoon/sound/ambience/mesa/metal2.ogg' , 'modular_bluemoon/sound/ambience/mesa/metal3.ogg' , 'modular_bluemoon/sound/ambience/mesa/metal5.ogg' , 'modular_bluemoon/sound/ambience/mesa/metal6.ogg' , 'modular_bluemoon/sound/ambience/mesa/metal7.ogg' )
	area_flags = NOTELEPORT

/area/awaymission/ihategordon/entrance
	name = "Facility entrance"
	icon_state = "awaycontent1"

/area/awaymission/ihategordon/underground_tunnels
	name = "Facility tunnels"
	icon_state = "awaycontent4"

/area/awaymission/ihategordon/entrance_hall
	name = "Facility hall"
	icon_state = "awaycontent11"

/area/awaymission/ihategordon/hyperlaser_chamber
	name = "Facility hyperlaser research chamber"
	icon_state = "awaycontent14"

/area/awaymission/ihategordon/science_tunnel
	name = "Facility science tunnel"
	icon_state = "awaycontent15"

/area/awaymission/ihategordon/big_offices
	name = "Big Facility offices"
	icon_state = "awaycontent18"

/area/awaymission/ihategordon/cryo_room
	name = "Facility cryochambers reseach room"
	icon_state = "awaycontent21"

/area/awaymission/ihategordon/tram_room
	name = "Facility tram stop"
	icon_state = "awaycontent23"

/area/awaymission/ihategordon/tram_tunnel
	name = "tram tunnel"
	icon_state = "awaycontent25"

/area/awaymission/ihategordon/dorm_offices
	name = "Facility dorm offices"
	icon_state = "awaycontent27"

/area/awaymission/ihategordon/sci_medbay
	name = "Facility medbay"
	icon_state = "awaycontent3"

/area/awaymission/ihategordon/turret_lockdown_hall
	name = "Facility lockdown hall"
	icon_state = "awaycontent5"

/area/awaymission/ihategordon/emitter_chambers
	name = "Facility emitter testing room"
	icon_state = "awaycontent7"

/area/awaymission/ihategordon/sec_armory
	name = "Facility armory"
	icon_state = "awaycontent8"

/area/awaymission/ihategordon/hecu_camp_hall
	name = "Facility hecu halls"
	icon_state = "awaycontent10"

/area/awaymission/ihategordon/hecu_camp_medbay
	name = "Facility hecu medbay"
	icon_state = "awaycontent12"

/area/awaymission/ihategordon/hecu_camp_bus_stop
	name = "Facility hecu bus stop"
	icon_state = "awaycontent13"

/area/awaymission/ihategordon/hecu_abandoned_camp
	name = "Facility destroyed hecu camps"
	icon_state = "awaycontent16"

/area/awaymission/ihategordon/server_rooms
	name = "Facility desroyed servers"
	icon_state = "awaycontent19"

/area/awaymission/ihategordon/rocks
	name = "Facility rocks"
	icon_state = "awaycontent20"
	outdoors = TRUE
	var/initial_gas_mix = OPENTURF_DEFAULT_ATMOS

/area/awaymission/ihategordon/dining_room
	name = "main dining room"
	icon_state = "awaycontent21"

/area/awaymission/ihategordon/facility_hallway
	name = "facility hallway"
	icon_state = "awaycontent4"

/area/awaymission/ihategordon/dorm_rooms
	name = "restrooms"
	icon_state = "awaycontent6"

/area/awaymission/ihategordon/dorm_rooms/stillalive
	name = "Still Alive Room"
	icon_state = "awaycontent6"
	shipambience = 'modular_bluemoon/sound/ambience/mesa/stillalive.ogg'
	ambientsounds = list()

/area/awaymission/ihategordon/secret_rooms
	name = "secret"
	icon_state = "awaycontent28"

/area/awaymission/ihategordon/gonome
	name = "gonome boss battle"
	icon_state = "awaycontent29"

/area/awaymission/ihategordon/sectorhnorthoffices
	name = "sector H north offices"
	icon_state = "north"

/area/awaymission/ihategordon/sectorhsecoffices
	name = "sector H security offices"
	icon_state = "security"

/area/awaymission/ihategordon/opposing
	name = "east sector H complex entrance"
	icon_state = "1"

/area/awaymission/ihategordon/opposing/comlpex
	name = "east sector H complex"
	icon_state = "2"

/area/awaymission/ihategordon/opposing/end
	name = "east sector H complex ending"
	icon_state = "3"

/area/awaymission/ihategordon/outsideofmesa
	name = "Outside of facility"
	icon_state = "awaycontent6"
	outdoors = TRUE
	shipambience ='modular_bluemoon/sound/ambience/mesa/outside.ogg'
	ambientsounds = list( 'modular_bluemoon/sound/ambience/mesa/battle1.ogg' , 'modular_bluemoon/sound/ambience/mesa/battle2.ogg' , 'modular_bluemoon/sound/ambience/mesa/battle3.ogg' , 'modular_bluemoon/sound/ambience/mesa/battle4.ogg' , 'modular_bluemoon/sound/ambience/mesa/battle5.ogg' , 'modular_bluemoon/sound/ambience/mesa/battle6.ogg' , 'modular_bluemoon/sound/ambience/mesa/battle7.ogg' )
	var/initial_gas_mix = OPENTURF_DEFAULT_ATMOS

/area/awaymission/ihategordon/outsideofmesa/hecu_camp
	name = "Facility hecu main camp"
	icon_state = "awaycontent15"
	outdoors = TRUE

/area/awaymission/ihategordon/outsideofmesa/restricted_zone
	name = "Facility restricted zone"
	icon_state = "awaycontent25"
	outdoors = TRUE

/area/awaymission/ihategordon/outsideofmesa/bombardment
	name = "Bombardment Zone"
	icon_state = "awaycontent26"
	outdoors = TRUE


/area/awaymission/ihategordon/hecuannouce
	name = "hecu warning announcement area"
	icon_state = "3"

// =============================================================================
// IHATEGORDON CUSTOM ZONES
// Специальные зоны для кастомного космоса и ивентов
// =============================================================================

/area/awaymission/ihategordon/custom_space
	name = "Ihategordon Void"
	icon_state = "space"
	always_unpowered = TRUE
	power_environ = FALSE
	power_light = FALSE
	power_equip = FALSE
	requires_power = FALSE
	shipambience = 'modular_bluemoon/sound/ambience/mesa/xenambience.ogg'
	ambientsounds = 'modular_bluemoon/sound/ambience/mesa/xenambience.ogg'
	has_gravity = FALSE
	var/ignore_mesa_events = TRUE

/area/awaymission/ihategordon/custom_walking
	name = "Ihategordon Walking Zone"
	icon_state = "awaycontent1"
	shipambience = 'modular_bluemoon/sound/ambience/mesa/xenambience.ogg'
	ambientsounds = 'modular_bluemoon/sound/ambience/mesa/xenambience.ogg'
	has_gravity = TRUE
	var/ignore_mesa_events = TRUE

/area/awaymission/ihategordon/custom_event
	name = "Ihategordon Event Zone"
	icon_state = "awaycontent2"
	shipambience = 'modular_bluemoon/sound/ambience/mesa/xenambience.ogg'
	ambientsounds = 'modular_bluemoon/sound/ambience/mesa/xenambience.ogg'
	has_gravity = TRUE
