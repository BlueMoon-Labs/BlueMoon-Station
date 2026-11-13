/**********************Mine areas**************************/

/area/mine
	icon_state = "mining"
	has_gravity = STANDARD_GRAVITY
	area_flags = VALID_TERRITORY | UNIQUE_AREA | FLORA_ALLOWED

/area/mine/explored
	name = "Mine"
	icon_state = "explored"
	always_unpowered = TRUE
	requires_power = TRUE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE
	outdoors = TRUE
	flags_1 = NONE
	// ambience_index = AMBIENCE_MINING
	ambientsounds = MINING
	area_flags = VALID_TERRITORY | UNIQUE_AREA | NO_ALERTS
	sound_environment = SOUND_AREA_STANDARD_STATION
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 220 SECONDS

/area/mine/unexplored
	name = "Mine"
	icon_state = "unexplored"
	always_unpowered = TRUE
	requires_power = TRUE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE
	outdoors = TRUE
	flags_1 = NONE
	// ambience_index = AMBIENCE_MINING
	ambientsounds = MINING
	area_flags = VALID_TERRITORY | UNIQUE_AREA | NO_ALERTS | CAVES_ALLOWED | FLORA_ALLOWED | MOB_SPAWN_ALLOWED | MEGAFAUNA_SPAWN_ALLOWED
	map_generator = /datum/map_generator/cave_generator
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 220 SECONDS

// ------------------------------------ //

/area/mine/lobby
	name = "Mining Post"
	icon_state = "mining_lobby"

/area/mine/storage
	name = "Mining Post Storage"
	icon_state = "mining_storage"

/area/mine/production
	name = "Mining Post Starboard Wing"
	icon_state = "mining_production"

/area/mine/mechbay
	name = "Mining Post Mech Bay"
	icon_state = "mechbay"

/area/mine/abandoned
	name = "Abandoned Mining Post"

/area/mine/living_quarters
	name = "Mining Post Port Wing"
	icon_state = "mining_living"

/area/mine/eva
	name = "Mining Post EVA"
	icon_state = "mining_eva"

/area/mine/eva/lower
	name = "Mining Post Lower EVA"

/area/mine/medical
	name = "Mining Post Medical"

/area/mine/maintenance
	name = "Mining Post Maintenance"

/area/mine/cafeteria
	name = "Mining Post Cafeteria"
	icon_state = "mining_labor_cafe"

// ------------------------------------ //

/area/mine/common
	name = "Public Mining Post Park Area"
	icon_state = "mining"

/area/mine/common/upper
	name = "Public Mining Post Floor 2"
	icon_state = "mining"

/area/mine/common/lower
	name = "Public Mining Post Floor 1"
	icon_state = "mining"

/area/mine/common/eva
	name = "Public Mining Post EVA"
	icon_state = "mining_eva"

/area/mine/common/dorm1
	name = "Public Mining Post Dorm 1"
	icon_state = "mining"

/area/mine/common/dorm2
	name = "Public Mining Post Dorm 2"
	icon_state = "mining"

/area/mine/common/hydroponics
	name = "Public Mining Post Hydroponics"
	icon_state = "mining_labor_hydro"

/area/mine/common/atrium
	name = "Public Mining Post Atrium"
	icon_state = "mining"

/area/mine/common/pool
	name = "Public Mining Post Pool Area"
	icon_state = "mining"

/area/mine/common/sauna
	name = "Public Mining Post Sauna"
	icon_state = "mining"

/area/mine/common/medical
	name = "Public Mining Post Medical"
	icon_state = "mining"

/area/mine/common/maintenance/north
	name = "Public Mining Post North Maintenance"
	icon_state = "mining"

/area/mine/common/maintenance/west
	name = "Public Mining Post West Maintenance"
	icon_state = "mining"

/area/mine/common/maintenance/south
	name = "Public Mining Post South Maintenance"
	icon_state = "mining"

// ------------------------------------ //

/area/mine/laborcamp
	name = "Labor Camp"
	icon_state = "mining_labor"

/area/mine/laborcamp/mining
	name = "Labor Camp Mining Area"
	icon_state = "mining_labor"

/area/mine/laborcamp/security
	name = "Lavaland Security Post"
	icon_state = "security"
	// ambience_index = AMBIENCE_DANGER
	ambientsounds = HIGHSEC

/area/mine/laborcamp/security/maintetance
	name = "Lavaland Sec-Post Maintenance"
	icon_state = "security"
	// ambience_index = AMBIENCE_DANGER
	ambientsounds = HIGHSEC

/area/mine/laborcamp/security/outdoors_maintetance
	name = "Lavaland Sec-Post Outdoors Maintenance"
	icon_state = "security"
	// ambience_index = AMBIENCE_DANGER
	ambientsounds = HIGHSEC

/area/mine/laborcamp/entry
	name = "Labor Camp Entry"
	icon_state = "security"
	// ambience_index = AMBIENCE_DANGER
	ambientsounds = HIGHSEC

/area/mine/laborcamp/maintenance/south
	name = "Labor Camp South Maintenance"
	icon_state = "security"

/area/mine/laborcamp/maintenance/west
	name = "Labor Camp West Maintenance"
	icon_state = "security"

// ------------------------------------ //

/area/mine/engineering
	name = "Lavaland Engi-Post Lobby"
	icon_state = "mining"

/area/mine/engineering/maintenance
	name = "Lavaland Engi-Post Maintenance"
	icon_state = "mining"

/area/mine/engineering/telecomms_floor1
	name = "Lavaland Engi-Post Telecomms"
	icon_state = "mining"

/area/mine/engineering/telecomms_floor2
	name = "Lavaland Engi-Post Telecomms"
	icon_state = "mining"

/area/mine/engineering/recycling
	name = "Lavaland Engi-Post Recycling Area"
	icon_state = "mining"

/**********************Lavaland Areas**************************/

/area/lavaland
	icon_state = "mining"
	has_gravity = STANDARD_GRAVITY
	flags_1 = NONE
	area_flags = VALID_TERRITORY | UNIQUE_AREA | FLORA_ALLOWED
	sound_environment = SOUND_AREA_LAVALAND
	shipambience = 'sound/ambience/zone/magma.ogg'
	ambientsounds = MINING

	always_unpowered = TRUE
	requires_power = TRUE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE

/area/lavaland/surface
	name = "Lavaland"
	icon_state = "explored"
	area_flags = VALID_TERRITORY | UNIQUE_AREA | FLORA_ALLOWED | NO_ALERTS
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 220 SECONDS

/area/lavaland/underground
	name = "Lavaland Caves"
	icon_state = "unexplored"
	area_flags = VALID_TERRITORY | UNIQUE_AREA | FLORA_ALLOWED | NO_ALERTS
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 220 SECONDS

/area/lavaland/necropolis
	name = "Necropolis Dungeon"
	icon_state = "necropolis_dungeon"
	sound_environment = SOUND_AREA_LARGE_SOFTFLOOR
	area_flags = UNIQUE_AREA | NO_ALERTS | NOTELEPORT
	min_ambience_cooldown = 60 SECONDS
	max_ambience_cooldown = 120 SECONDS

/area/lavaland/surface/outdoors
	name = "Lavaland Wastes"
	outdoors = TRUE

/area/lavaland/surface/jungles
	name = "Lavaland Wastes"
	outdoors = FALSE

/area/lavaland/surface/outdoors/unexplored //monsters and ruins spawn here
	icon_state = "unexplored"
	area_flags = VALID_TERRITORY | UNIQUE_AREA | CAVES_ALLOWED | FLORA_ALLOWED | MOB_SPAWN_ALLOWED | NO_ALERTS
	map_generator = /datum/map_generator/cave_generator/lavaland

/area/lavaland/surface/outdoors/unexplored/danger //megafauna will also spawn here
	icon_state = "danger"
	area_flags = VALID_TERRITORY | UNIQUE_AREA | CAVES_ALLOWED | FLORA_ALLOWED | MOB_SPAWN_ALLOWED | MEGAFAUNA_SPAWN_ALLOWED | NO_ALERTS

/area/lavaland/surface/outdoors/explored
	name = "Lavaland Labor Camp"
	area_flags = VALID_TERRITORY | UNIQUE_AREA | NO_ALERTS

/**********************Ice Moon Areas**************************/

/area/icemoon
	icon_state = "mining"
	has_gravity = STANDARD_GRAVITY
	flags_1 = NONE
	area_flags = UNIQUE_AREA | FLORA_ALLOWED
	sound_environment = SOUND_AREA_ICEMOON

/area/icemoon/surface
	name = "Icemoon"
	icon_state = "explored"
	always_unpowered = TRUE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE
	requires_power = TRUE
	// ambience_index = AMBIENCE_MINING
	ambientsounds = MINING
	area_flags = UNIQUE_AREA | FLORA_ALLOWED | NO_ALERTS
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 220 SECONDS

/area/icemoon/surface/outdoors // weather happens here
	name = "Icemoon Wastes"
	outdoors = TRUE

/// Погода есть, генерации и спавна нет.
/area/icemoon/surface/outdoors/nospawn

/area/icemoon/surface/outdoors/less_spawns

/area/icemoon/surface/outdoors/noruins
	area_flags = UNIQUE_AREA | FLORA_ALLOWED | MOB_SPAWN_ALLOWED | CAVES_ALLOWED | NO_ALERTS
	map_generator = /datum/map_generator/cave_generator/icemoon/surface

/area/icemoon/surface/outdoors/labor_camp
	name = "Icemoon Labor Camp"
	area_flags = UNIQUE_AREA | NO_ALERTS

/area/icemoon/surface/outdoors/unexplored //monsters and ruins spawn here
	icon_state = "unexplored"
	area_flags = UNIQUE_AREA | FLORA_ALLOWED | MOB_SPAWN_ALLOWED | CAVES_ALLOWED | NO_ALERTS

/area/icemoon/surface/outdoors/unexplored/rivers // rivers spawn here
	icon_state = "danger"
	map_generator = /datum/map_generator/cave_generator/icemoon/surface

/area/icemoon/surface/outdoors/unexplored/rivers/no_monsters
	area_flags = UNIQUE_AREA | FLORA_ALLOWED | CAVES_ALLOWED | NO_ALERTS

/area/icemoon/underground
	name = "Icemoon Caves"
	outdoors = TRUE
	always_unpowered = TRUE
	requires_power = TRUE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE
	// ambience_index = AMBIENCE_MINING
	ambientsounds = MINING
	area_flags = UNIQUE_AREA | FLORA_ALLOWED | NO_ALERTS
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 220 SECONDS

/area/icemoon/underground/unexplored // mobs and megafauna and ruins spawn here
	name = "Icemoon Caves"
	icon_state = "unexplored"
	area_flags = CAVES_ALLOWED | FLORA_ALLOWED | MOB_SPAWN_ALLOWED | MEGAFAUNA_SPAWN_ALLOWED | NO_ALERTS

/area/icemoon/underground/unexplored/no_rivers
	area_flags = CAVES_ALLOWED | FLORA_ALLOWED | NO_ALERTS
	map_generator = /datum/map_generator/cave_generator/icemoon

/area/icemoon/underground/unexplored/rivers // rivers spawn here
	icon_state = "danger"
	map_generator = /datum/map_generator/cave_generator/icemoon

/area/icemoon/underground/unexplored/rivers/deep
	map_generator = /datum/map_generator/cave_generator/icemoon/deep

/// Пещеры без мобов у рек и построек станции.
/area/icemoon/underground/unexplored/rivers/deep/shoreline
	area_flags = UNIQUE_AREA | FLORA_ALLOWED | CAVES_ALLOWED | NO_ALERTS

/area/icemoon/underground/explored // ruins can't spawn here
	name = "Icemoon Underground"
	area_flags = UNIQUE_AREA | NO_ALERTS

/area/icemoon/underground/explored/graveyard
	name = "Graveyard"
	ambientsounds = SPOOKY
