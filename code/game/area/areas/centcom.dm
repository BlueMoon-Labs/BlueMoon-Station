
// CENTCOM

// Side note, be sure to change the network_root_id of any areas that are not a part of centcom
// and just using the z space as safe harbor.  It shouldn't matter much as centcom z is isolated
// from everything anyway

/area/centcom
	name = "CentCom"
	icon = 'icons/area/areas_centcom.dmi'
	icon_state = "centcom"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	area_flags = UNIQUE_AREA | NOTELEPORT
	flags_1 = NONE

/area/centcom/arena
	name = "CentCom Arena"

/area/centcom/control
	name = "CentCom Docks"

/area/centcom/evac
	name = "CentCom Recovery Ship"

/area/centcom/supply
	name = "CentCom Supply Shuttle Dock"

/area/centcom/ferry
	name = "CentCom Transport Shuttle Dock"

/area/centcom/prison
	name = "Admin Prison"

/area/centcom/holding
	name = "Holding Facility"

// BLUEMOON ADD START - размещаю здесь для удобства чтения
/area/centcom/holding/exterior // зона со светом
	name = "Holding Facility Exterior"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
// BLUEMOON ADD END

/area/centcom/vip
	name = "VIP Zone"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

// dear mappers who make winterball: THROW YOUR AREAS IN A DIFFERENT MAP, THIS IS DEFAULT GAME STUFF NOT EVENT STUFF
/area/centcom/winterball
	name = "winterball Zone"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/centcom/supplypod/supplypod_temp_holding
	name = "Supplypod Shipping lane"
	icon_state = "supplypod_flight"

/area/centcom/supplypod
	name = "Supplypod Facility"
	icon_state = "supplypod"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/centcom/supplypod/podStorage
	name = "Supplypod Storage"
	icon_state = "supplypod_holding"

/area/centcom/supplypod/loading
	name = "Supplypod Loading Facility"
	icon_state = "supplypod_loading"
	var/loading_id = ""

/area/centcom/supplypod/loading/Initialize(mapload)
	. = ..()
	if(!loading_id)
		CRASH("[type] created without a loading_id")
	if(GLOB.supplypod_loading_bays[loading_id])
		CRASH("Duplicate loading bay area: [type] ([loading_id])")
	GLOB.supplypod_loading_bays[loading_id] = src

/area/centcom/supplypod/loading/one
	name = "Bay #1"
	loading_id = "1"

/area/centcom/supplypod/loading/two
	name = "Bay #2"
	loading_id = "2"

/area/centcom/supplypod/loading/three
	name = "Bay #3"
	loading_id = "3"

/area/centcom/supplypod/loading/four
	name = "Bay #4"
	loading_id = "4"

/area/centcom/supplypod/loading/ert
	name = "ERT Bay"
	loading_id = "5"
//THUNDERDOME

/area/tdome
	name = "Thunderdome"
	icon_state = "yellow"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	flags_1 = NONE

/area/tdome/arena
	name = "Thunderdome Arena"
	icon_state = "thunder"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/tdome/arena_source
	name = "Thunderdome Arena Template"
	icon_state = "thunder"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/tdome/tdome1
	name = "Thunderdome (Team 1)"
	icon_state = "green"

/area/tdome/tdome2
	name = "Thunderdome (Team 2)"
	icon_state = "green"

/area/tdome/tdomeadmin
	name = "Thunderdome (Admin.)"
	icon_state = "purple"

/area/tdome/tdomeobserve
	name = "Thunderdome (Observer.)"
	icon_state = "purple"

//EVENT

/area/eventcontent
	name = "EventArea1"
	icon = 'modular_bluemoon/icons/turf/event_areas.dmi'
	icon_state = "eventcontent1"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	area_flags = UNIQUE_AREA | NOTELEPORT
	flags_1 = NONE

/area/eventcontent/a02
	name = "EventArea2"
	icon_state = "eventcontent2"

/area/eventcontent/a03
	name = "EventArea3"
	icon_state = "eventcontent3"

/area/eventcontent/a04
	name = "EventArea4"
	icon_state = "eventcontent4"

/area/eventcontent/a05
	name = "EventArea5"
	icon_state = "eventcontent5"

/area/eventcontent/a06
	name = "EventArea6"
	icon_state = "eventcontent6"

/area/eventcontent/a07
	name = "EventArea7"
	icon_state = "eventcontent7"

/area/eventcontent/a08
	name = "EventArea8"
	icon_state = "eventcontent8"

/area/eventcontent/a09
	name = "EventArea9"
	icon_state = "eventcontent9"

/area/eventcontent/a10
	name = "EventArea10"
	icon_state = "eventcontent10"

/area/eventcontent/a11
	name = "EventArea11"
	icon_state = "eventcontent11"

/area/eventcontent/a12
	name = "EventArea12"
	icon_state = "eventcontent12"

/area/eventcontent/a13
	name = "EventArea13"
	icon_state = "eventcontent13"

/area/eventcontent/a14
	name = "EventArea14"
	icon_state = "eventcontent14"

/area/eventcontent/a15
	name = "EventArea15"
	icon_state = "eventcontent15"

/area/eventcontent/a16
	name = "EventArea16"
	icon_state = "eventcontent16"

/area/eventcontent/a17
	name = "EventArea17"
	icon_state = "eventcontent17"

/area/eventcontent/a18
	name = "EventArea18"
	icon_state = "eventcontent18"

/area/eventcontent/a19
	name = "EventArea19"
	icon_state = "eventcontent19"

/area/eventcontent/a20
	name = "EventArea20"
	icon_state = "eventcontent20"

/area/eventcontent/a21
	name = "EventArea21"
	icon_state = "eventcontent21"

/area/eventcontent/a22
	name = "EventArea22"
	icon_state = "eventcontent22"

/area/eventcontent/a23
	name = "EventArea23"
	icon_state = "eventcontent23"

/area/eventcontent/a24
	name = "EventArea24"
	icon_state = "eventcontent24"

/area/eventcontent/a25
	name = "EventArea25"
	icon_state = "eventcontent25"

/area/eventcontent/a26
	name = "EventArea26"
	icon_state = "eventcontent26"

/area/eventcontent/a27
	name = "EventArea27"
	icon_state = "eventcontent27"

/area/eventcontent/a28
	name = "EventArea28"
	icon_state = "eventcontent28"

/area/eventcontent/a29
	name = "EventArea29"
	icon_state = "eventcontent29"

/area/eventcontent/a30
	name = "EventArea30"
	icon_state = "eventcontent30"

//ENEMY

//Wizard
/area/wizard_station
	name = "Wizard's Den"
	icon_state = "yellow"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	area_flags = VALID_TERRITORY | UNIQUE_AREA | NOTELEPORT
	flags_1 = NONE
	// network_root_id = "MAGIC_NET"

//Abductors
/area/abductor_ship
	name = "Abductor Ship"
	icon_state = "yellow"
	requires_power = FALSE
	area_flags = VALID_TERRITORY | UNIQUE_AREA | NOTELEPORT
	has_gravity = STANDARD_GRAVITY
	flags_1 = NONE
	// network_root_id = "ALIENS"

//Syndicates
/area/syndicate_mothership
	name = "Syndicate Mothership"
	icon_state = "syndie-ship"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	area_flags = VALID_TERRITORY | UNIQUE_AREA | NOTELEPORT
	flags_1 = NONE
	ambientsounds = SHUTTLE_MILITARY
	shipambience = 'sound/ambience/zone/stadium.ogg'
	min_ambience_cooldown = 15 SECONDS
	max_ambience_cooldown = 40 SECONDS

/area/syndicate_mothership/control
	name = "Syndicate Control Room"
	icon_state = "syndie-control"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED

/area/syndicate_mothership/elite_squad
	name = "Syndicate Elite Squad"
	icon_state = "syndie-elite"

/area/fabric_of_reality
	name = "Tear in the Fabric of Reality"
	requires_power = FALSE
	has_gravity = TRUE
	area_flags = UNIQUE_AREA | NOTELEPORT

//CAPTURE THE FLAG
/area/ctf
	name = "Capture the Flag"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	flags_1 = NONE
	ambientsounds = ARENA_MUSIC

/area/ctf/control_room
	name = "Control Room A"

/area/ctf/control_room2
	name = "Control Room B"

/area/ctf/central
	name = "Central"

/area/ctf/main_hall
	name = "Main Hall A"

/area/ctf/main_hall2
	name = "Main Hall B"

/area/ctf/corridor
	name = "Corridor A"

/area/ctf/corridor2
	name = "Corridor B"

/area/ctf/flag_room
	name = "Flag Room A"

/area/ctf/flag_room2
	name = "Flag Room B"

/area/ctf/arena
	name = "Deathmatch Arena"
	icon_state = "red"
	requires_power = 0
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED

// REEBE

/area/reebe
	name = "Reebe"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	area_flags = HIDDEN_AREA | NOTELEPORT | UNIQUE_AREA
	ambientsounds = REEBE

/area/reebe/city_of_cogs
	name = "City of Cogs"
	icon_state = "purple"
	area_flags = NOTELEPORT | UNIQUE_AREA
