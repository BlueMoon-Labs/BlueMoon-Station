// Areas used by Tramstation that the other station maps never needed.

/area/asteroid/tramstation
	name = "Station Asteroid"
	icon_state = "cave"
	outdoors = TRUE
	has_gravity = FALSE
	requires_power = TRUE
	always_unpowered = TRUE
	power_equip = FALSE
	power_light = FALSE
	power_environ = FALSE

/area/hallway/primary/tram
	name = "Primary Tram"
	icon_state = "hallC"

/area/hallway/primary/tram/left
	name = "Port Tram Dock"
	icon_state = "hallP"

/area/hallway/primary/tram/center
	name = "Central Tram Dock"

/area/hallway/primary/tram/right
	name = "Starboard Tram Dock"
	icon_state = "hallS"

/area/hallway/secondary/construction/engineering
	name = "Engineering Hallway"

/area/escapepodbay
	name = "Pod Bay"
	icon_state = "escape"

/area/maintenance/central/greater
	name = "Greater Central Maintenance"

/area/maintenance/central/lesser
	name = "Lesser Central Maintenance"

/area/maintenance/starboard/greater
	name = "Greater Starboard Maintenance"

/area/maintenance/starboard/lesser
	name = "Lesser Starboard Maintenance"

/area/maintenance/tram
	name = "Primary Tram Maintenance"

/area/maintenance/tram/left
	name = "Port Tram Underpass"

/area/maintenance/tram/mid
	name = "Central Tram Underpass"

/area/maintenance/tram/right
	name = "Starboard Tram Underpass"

/area/maintenance/radshelter
	name = "Radstorm Shelter"

/area/maintenance/radshelter/civil
	name = "Civilian Radstorm Shelter"

/area/solars/port/asteroid
	name = "Port Asteroid Solar Array"
	has_gravity = STANDARD_GRAVITY

/area/solars/starboard/fore/asteroid
	name = "Starboard Bow Asteroid Solar Array"
	has_gravity = STANDARD_GRAVITY

/area/engineering/supermatter_room
	name = "Supermatter Engine Room"
	icon_state = "engine"
	sound_environment = SOUND_AREA_LARGE_ENCLOSED

/area/engineering/atmos/pumproom
	name = "Atmospherics Pumping Room"

/area/ai_monitored/turret_protected/aisat/maint
	name = "AI Satellite Maintenance"

/area/science/lower
	name = "Lower Science Division"

/area/science/breakroom
	name = "Science Break Room"

/area/science/mixing/testlab
	name = "Ordnance Testing Lab"

/area/science/mixing/office
	name = "Ordnance Office"

/area/science/mixing/freezer
	name = "Ordnance Freezer Chamber"

/area/cargo/lobby
	name = "Cargo Lobby"

/area/cargo/drone_bay
	name = "Drone Bay"

/area/cargo/miningfoundry
	name = "Mining Foundry"

/area/cargo/miningdock/cafeteria
	name = "Mining Cafeteria"

/area/cargo/miningdock/oresilo
	name = "Mining Ore Silo Storage"

/area/cargo/den
	name = "Cargo Den"

/area/commons/fitness/recreation/entertainment
	name = "Entertainment Center"

/area/commons/dorms/laundry
	name = "Laundry Room"

/area/service/bar/backroom
	name = "Bar Backroom"

/area/security/interrogation
	name = "Interrogation Room"

/area/security/lockers
	name = "Security Locker Room"

/area/security/mechbay
	name = "Security Mechbay"

/area/security/evidence
	name = "Evidence Storage"

/area/security/prison/safe
	name = "Prison Wing Cells"

/area/security/courtroom/holding
	name = "Courtroom Prisoner Holding Room"

/area/ruin/space/has_grav/syndicate_outpost
	name = "Syndicate Outpost"
	icon_state = "syndie-control"
	area_flags = HIDDEN_AREA
