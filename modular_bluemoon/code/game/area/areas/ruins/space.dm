/// RUIN OF HOTEL

/area/ruin/space/has_grav/bluemoon/hotel
	name = "Hotel"

/area/ruin/space/has_grav/bluemoon/hotel/guestroom
	name = "Hotel Guest Room"
	icon_state = "Sleep"
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/hotel/guestroom/shower)

/area/ruin/space/has_grav/bluemoon/hotel/guestroom/shower
	name = "Hotel Guest Shower"
	icon_state = "shower"
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/hotel/guestroom/room_1
	name = "Hotel Guest Room 1"

/area/ruin/space/has_grav/bluemoon/hotel/guestroom/room_2
	name = "Hotel Guest Room 2"

/area/ruin/space/has_grav/bluemoon/hotel/guestroom/room_3
	name = "Hotel Guest Room 3"

/area/ruin/space/has_grav/bluemoon/hotel/guestroom/room_4
	name = "Hotel Guest Room 4"

/area/ruin/space/has_grav/bluemoon/hotel/guestroom/room_5
	name = "Hotel Guest Room 5"

/area/ruin/space/has_grav/bluemoon/hotel/guestroom/room_6
	name = "Hotel Guest Room 6"

/area/ruin/space/has_grav/bluemoon/hotel/security
	name = "Hotel Security Post"
	icon_state = "security"

/area/ruin/space/has_grav/bluemoon/hotel/pool
	name = "Hotel Pool Room"
	icon_state = "fitness"
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/hotel/pool/shower)

/area/ruin/space/has_grav/bluemoon/hotel/pool/shower
	name = "Hotel Pool Shower"
	icon_state = "shower"
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/hotel/bar
	name = "Hotel Bar"
	icon_state = "cafeteria"

/area/ruin/space/has_grav/bluemoon/hotel/power
	name = "Hotel Power Room"
	icon_state = "engine_smes"

/area/ruin/space/has_grav/bluemoon/hotel/custodial
	name = "Hotel Custodial Closet"
	icon_state = "janitor"

/area/ruin/space/has_grav/bluemoon/hotel/shuttle
	name = "Hotel Shuttle"
	icon_state = "shuttle"
	requires_power = FALSE

/area/ruin/space/has_grav/bluemoon/hotel/dock
	name = "Hotel Shuttle Dock"
	icon_state = "start"

/area/ruin/space/has_grav/bluemoon/hotel/workroom
	name = "Hotel Staff Room"
	icon_state = "crew_quarters"

// Deep Space 2.
/// DS-2 'Blessed', Forward Operating Base
/area/ruin/space/has_grav/bluemoon/deepspacetwo
	name = "DS-2" //If DS-1 is so great...
	icon = 'icons/area/areas_centcom.dmi'
	icon_state = "syndie-ship"

//Cargo
/area/ruin/space/has_grav/bluemoon/deepspacetwo/cargo
	name = "DS-2 'Blessed' | Warehouse"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/cargo/hangar
	name = "DS-2 'Blessed' | Hangar"

//Bridge
/area/ruin/space/has_grav/bluemoon/deepspacetwo/bridge
	name = "DS-2 'Blessed' | Bridge"
	icon_state = "syndie-control"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/bridge/cl
	name = "DS-2 'Blessed' | Corporate Liaison's Office"
	sound_environment = SOUND_AREA_WOODFLOOR

/area/ruin/space/has_grav/bluemoon/deepspacetwo/bridge/admiral
	name = "DS-2 'Blessed' | Station Admiral's Office"
	sound_environment = SOUND_AREA_WOODFLOOR

/area/ruin/space/has_grav/bluemoon/deepspacetwo/bridge/vault
	name = "DS-2 'Blessed' | Vault"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/bridge/eva
	name = "DS-2 'Blessed' | E.V.A."

//Security
/area/ruin/space/has_grav/bluemoon/deepspacetwo/security
	name = "DS-2 'Blessed' | Security"
	ambientsounds = HIGHSEC
/area/ruin/space/has_grav/bluemoon/deepspacetwo/security/armory
	name = "DS-2 'Blessed' | Armory"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/security/lawyer
	name = "DS-2 'Blessed' | Interrogation Office"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/security/prison
	name = "DS-2 'Blessed' | Long-Term Brig"
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/deepspacetwo/security/prison_shower)

/area/ruin/space/has_grav/bluemoon/deepspacetwo/security/prison_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "DS-2 'Blessed' | Brig Shower Room"
	sub_areas = list()
	valid_to_shower = TRUE

//Service
/area/ruin/space/has_grav/bluemoon/deepspacetwo/service
	name = "DS-2 'Blessed' | Service Wing"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/service/diner
	name = "DS-2 'Blessed' | Diner"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/service/dorms
	name = "DS-2 'Blessed' | Dormitories"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/service/dorms/fitness
	name = "DS-2 'Blessed' | Fitness Room"
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/deepspacetwo/service/dorms/fitness_shower)

/area/ruin/space/has_grav/bluemoon/deepspacetwo/service/dorms/fitness_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "DS-2 'Blessed' | Shower Room"
	sub_areas = list()
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/deepspacetwo/service/lounge
	name = "DS-2 'Blessed' | Lounge"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/service/hydroponics
	name = "DS-2 'Blessed' | Hydroponics"

//Hallways
/area/ruin/space/has_grav/bluemoon/deepspacetwo/halls
	name = "DS-2 'Blessed' | Central Halls"

//Engineering
/area/ruin/space/has_grav/bluemoon/deepspacetwo/engineering
	name = "DS-2 'Blessed' | Engineering"

//Research
/area/ruin/space/has_grav/bluemoon/deepspacetwo/research
	name = "DS-2 'Blessed' | Research"

//Medbay
/area/ruin/space/has_grav/bluemoon/deepspacetwo/medbay
	name = "DS-2 'Blessed' | Medical Bay"

/area/ruin/space/has_grav/bluemoon/deepspacetwo/medbay/chem
	name = "DS-2 'Blessed' | Chemistry"

/// SYNDICATE LISTENING POST STATION
/area/ruin/space/has_grav/bluemoon/listeningstation
	name = "Listening Post"
	icon_state = "yellow"
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/listeningstation_shower)

/area/ruin/space/has_grav/bluemoon/listeningstation_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "Listening Post Shower"
	sub_areas = list()
	valid_to_shower = TRUE

//Port Tarkon

/area/ruin/space/has_grav/bluemoon/port_tarkon
	name = "P-T Cryo-Storage"
	always_unpowered = FALSE
	ambientsounds = HIGHSEC

/area/ruin/space/has_grav/bluemoon/port_tarkon/afthall
	name = "P-T Aft Hallway"

/area/ruin/space/has_grav/bluemoon/port_tarkon/forehall
	name = "P-T Fore Hallway"

/area/ruin/space/has_grav/bluemoon/port_tarkon/starboardhall
	name = "P-T Starboard Hallway"

/area/ruin/space/has_grav/bluemoon/port_tarkon/porthall
	name = "P-T Port Hallway"

/area/ruin/space/has_grav/bluemoon/port_tarkon/trauma
	name = "P-T Trauma Center"
	icon_state = "medbay1"

/area/ruin/space/has_grav/bluemoon/port_tarkon/developement
	name = "P-T Developement Center"
	icon_state = "research"

/area/ruin/space/has_grav/bluemoon/port_tarkon/comms
	name = "P-T Communication Center"
	icon_state = "captain"

/area/ruin/space/has_grav/bluemoon/port_tarkon/power1
	name = "P-T Solar Control"
	icon_state = "engine"

/area/ruin/space/has_grav/bluemoon/port_tarkon/centerhall
	name = "P-T Central Hallway"
	icon_state = "hallC"
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/port_tarkon/centerhall/shower)

/area/ruin/space/has_grav/bluemoon/port_tarkon/centerhall/shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "P-T Shower Room"
	sub_areas = list()
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/port_tarkon/secoff
	name = "P-T Security Office"
	icon_state = "security"

/area/ruin/space/has_grav/bluemoon/port_tarkon/atmos
	name = "P-T Atmospheric Center"
	icon_state = "engine"

/area/ruin/space/has_grav/bluemoon/port_tarkon/kitchen
	name = "P-T Kitchen"
	icon_state = "cafeteria"

/area/ruin/space/has_grav/bluemoon/port_tarkon/garden
	name = "P-T Garden"
	icon_state = "garden"

/area/ruin/space/has_grav/bluemoon/port_tarkon/cargo
	name = "P-T Cargo Center"
	icon_state = "cargo"

/area/ruin/space/has_grav/bluemoon/port_tarkon/mining
	name = "P-T Mining Office"
	icon_state = "cargo"

/area/ruin/space/has_grav/bluemoon/port_tarkon/storage
	name = "P-T Warehouse"
	icon_state = "cargo"

/area/ruin/space/has_grav/bluemoon/port_tarkon/toolstorage
	name = "P-T Tool Storage"
	icon_state = "tool_storage"

/area/ruin/space/has_grav/bluemoon/port_tarkon/observ
	name = "P-T Observatory"
	icon_state = "crew_quarters"

/area/ruin/space/has_grav/bluemoon/port_tarkon/dorms
	name = "P-T Dorms"
	icon_state = "crew_quarters"

/area/solars/tarkon
	name = "\improper P-T Solar Array"
	icon_state = "solarsS"
	has_gravity = STANDARD_GRAVITY

/// ABDUCTOR CRUSH SPACE RUIN
/area/ruin/space/bluemoon/abductorcrush
	name = "Abductor InteQ Crush"
	icon_state = "yellow"
	requires_power = FALSE
