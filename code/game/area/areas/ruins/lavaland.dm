//Lavaland Ruins

/area/ruin/lavaland/unpowered
	always_unpowered = FALSE

/area/ruin/lavaland/unpowered/no_grav
	has_gravity = FALSE

/area/ruin/lavaland/powered
	requires_power = FALSE

/area/ruin/lavaland/powered/beach
	icon_state = "dk_yellow"
	shipambience = 'sound/ambience/zone/magma.ogg'
	ambientsounds = list('sound/ambience/shore.ogg', 'sound/ambience/seag1.ogg','sound/ambience/seag2.ogg','sound/ambience/seag2.ogg','sound/ambience/ambiodd.ogg','sound/ambience/ambinice.ogg')

/area/ruin/lavaland/powered/clownplanet
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/animal_hospital
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/snow_biodome
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/gluttony
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/golem_ship
	name = "Free Golem Ship"
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/greed
	icon_state = "dk_yellow"

/area/ruin/lavaland/unpowered/hierophant
	name = "Hierophant's Arena"
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/pride
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/seedvault
	icon_state = "dk_yellow"

/area/ruin/lavaland/unpowered/elephant_graveyard
	name = "Elephant Graveyard"
	icon_state = "dk_yellow"

/area/ruin/lavaland/powered/graveyard_shuttle
	name = "Elephant Graveyard"
	icon_state = "green"

// Deep Space One. Bluemoon.
/area/ruin/lavaland/unpowered/deepspaceone
	name = "Secret Syndicate Base"
	icon_state = "dk_yellow"
	ambientsounds = HIGHSEC

/area/ruin/lavaland/unpowered/deepspaceone/engineering
	name = "DS-1 'Dune' | Engineering"

/area/ruin/lavaland/unpowered/deepspaceone/medbay
	name = "DS-1 'Dune' | Medbay"

/area/ruin/lavaland/unpowered/deepspaceone/arrivals
	name = "DS-1 'Dune' | Arrivals"

/area/ruin/lavaland/unpowered/deepspaceone/bar
	name = "DS-1 'Dune' | Bar"

/area/ruin/lavaland/unpowered/deepspaceone/main
	name = "DS-1 'Dune' | Primary Hallway"
	sub_areas = list(/area/ruin/lavaland/unpowered/deepspaceone/main_shower)

/area/ruin/lavaland/unpowered/deepspaceone/main_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "DS-1 'Dune' | Shower Room"
	valid_to_shower = TRUE

/area/ruin/lavaland/unpowered/deepspaceone/cargo
	name = "DS-1 'Dune' | Cargo Bay"

/area/ruin/lavaland/unpowered/deepspaceone/comms_officer_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "DS-1 'Dune' | Comm Shower Room"
	valid_to_shower = TRUE

/area/ruin/lavaland/unpowered/deepspaceone/chemistry
	name = "DS-1 'Dune' | Chemistry"

/area/ruin/lavaland/unpowered/deepspaceone/virology
	name = "DS-1 'Dune' | Virology"

/area/ruin/lavaland/unpowered/deepspaceone/testlab
	name = "DS-1 'Dune' | Experimentation Lab"

/area/ruin/lavaland/unpowered/deepspaceone/dormitories
	name = "DS-1 'Dune' | Dormitories"

/area/ruin/lavaland/unpowered/deepspaceone/biolab
	name = "DS-1 'Dune' | Biolab"

/area/ruin/lavaland/unpowered/deepspaceone/telecomms
	name = "DS-1 'Dune' | Telecommunications"

/area/ruin/lavaland/unpowered/deepspaceone/circuits
	name = "DS-1 'Dune' | Circuit Lab"

/area/ruin/lavaland/unpowered/deepspaceone/security
	name = "DS-1 'Dune' | Security"

/area/ruin/lavaland/unpowered/deepspaceone/armory
	name = "DS-1 'Dune' | Armory"

/area/ruin/lavaland/unpowered/deepspaceone/comms_officer
	name = "DS-1 'Dune' | Communication Officer"
	sub_areas = list(/area/ruin/lavaland/unpowered/deepspaceone/comms_officer_shower)

/area/ruin/lavaland/unpowered/deepspaceone/reactor
	name = "DS-1 'Dune' | Reactor"

/area/ruin/lavaland/unpowered/deepspaceone/virology
	name = "DS-1 'Dune' | Virology"

/area/ruin/lavaland/unpowered/deepspaceone/general_staff
	name = "DS-1 'Dune' | General Staff Quarters"

/area/ruin/lavaland/unpowered/deepspaceone/chemistry
	name = "DS-1 'Dune' | General Chemistry"

//Xeno Nest

/area/ruin/lavaland/unpowered/xenonest
	name = "The Hive"
	always_unpowered = TRUE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE

//ash walker nest
/area/ruin/lavaland/unpowered/ash_walkers
	icon_state = "red"

/area/ruin/lavaland/unpowered/ash_walkers/female
	icon_state = "red"

/area/ruin/space/has_grav/russianbunker
	name = "Russian Bunker"
	area_flags = NOTELEPORT
