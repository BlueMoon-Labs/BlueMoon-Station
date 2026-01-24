//Template Stuff
#define GHC_MISC "Misc"
#define GHC_APARTMENT "Apartment"
#define GHC_BEACH "Beach"
#define GHC_STATION "Station"
#define GHC_WINTER "Winter"
#define GHC_SPECIAL "Special"

/datum/map_template/hilbertshotel
	name = "Hotel Room"
	mappath = '_maps/templates/hilbertshotel/hilbertshotel.dmm'
	var/landingZoneRelativeX = 2
	var/landingZoneRelativeY = 8
	var/category = GHC_MISC //Room categorizing
	var/donator_tier = DONATOR_GROUP_NONE //For donator rooms // WIP content
	var/list/ckeywhitelist = list() //For ckey locked donator rooms // WIP content

/datum/map_template/hilbertshotel/lore
	name = "Doctor Hilbert's Deathbed"
	mappath = '_maps/templates/hilbertshotel/hilbertshotellore.dmm'

/datum/map_template/hilbertshotelstorage
	name = "Hilbert's Hotel Storage"
	mappath = '_maps/templates/hilbertshotel/hilbertshotelstorage.dmm'

/datum/map_template/hilbertshotel/apartment
	name = "Apartment"
	mappath = '_maps/templates/hilbertshotel/apartment.dmm'
	category = GHC_APARTMENT

/datum/map_template/hilbertshotel/apartment/one
	name = "Apartment-1"
	mappath = '_maps/templates/hilbertshotel/apartment_1.dmm'
	landingZoneRelativeX = 6
	landingZoneRelativeY = 2
	category = GHC_APARTMENT

/datum/map_template/hilbertshotel/apartment/two
	name = "Apartment-2"
	mappath = '_maps/templates/hilbertshotel/apartment_2.dmm'
	landingZoneRelativeX = 3
	landingZoneRelativeY = 11
	category = GHC_APARTMENT

/datum/map_template/hilbertshotel/apartment/three
	name = "Apartment-3"
	mappath = '_maps/templates/hilbertshotel/apartment_3.dmm'
	landingZoneRelativeX = 1
	landingZoneRelativeY = 10
	category = GHC_APARTMENT

/datum/map_template/hilbertshotel/apartment/bar
	name = "Apartment-Bar"
	mappath = '_maps/templates/hilbertshotel/apartment_bar.dmm'
	landingZoneRelativeX = 2
	landingZoneRelativeY = 7
	category = GHC_STATION

/datum/map_template/hilbertshotel/apartment/syndi
	name = "Apartment-Syndi"
	mappath = '_maps/templates/hilbertshotel/apartment_syndi.dmm'
	landingZoneRelativeX = 2
	landingZoneRelativeY = 9
	category = GHC_APARTMENT

/datum/map_template/hilbertshotel/apartment/dojo
	name = "Apartment-dojo"
	mappath = '_maps/templates/hilbertshotel/apartment_dojo.dmm'
	landingZoneRelativeX = 1
	landingZoneRelativeY = 10
	category = GHC_SPECIAL

/datum/map_template/hilbertshotel/apartment/sauna
	name = "Apartment-Sauna"
	mappath = '_maps/templates/hilbertshotel/apartment_sauna.dmm'
	landingZoneRelativeX = 1
	landingZoneRelativeY = 10
	category = GHC_STATION

/datum/map_template/hilbertshotel/apartment/beach
	name = "Apartment-Beach"
	mappath = '_maps/templates/hilbertshotel/apartment_beach.dmm'
	landingZoneRelativeX = 4
	landingZoneRelativeY = 1
	category = GHC_BEACH

/datum/map_template/hilbertshotel/apartment/forest
	name = "Apartment-Forest"
	mappath = '_maps/templates/hilbertshotel/apartment_forest.dmm'
	landingZoneRelativeX = 6
	landingZoneRelativeY = 1
	category = GHC_MISC

/datum/map_template/hilbertshotel/apartment/jungle
	name = "Apartment-Jungle"
	mappath = '_maps/templates/hilbertshotel/apartment_jungle.dmm'
	landingZoneRelativeX = 1
	landingZoneRelativeY = 6
	category = GHC_APARTMENT

/datum/map_template/hilbertshotel/apartment/prison
	name = "Apartment-Prison"
	mappath = '_maps/templates/hilbertshotel/apartment_prison.dmm'
	landingZoneRelativeX = 1
	landingZoneRelativeY = 10
	category = GHC_MISC

/datum/map_template/hilbertshotel/apartment/winter
	name = "Apartment-Winter"
	mappath = '_maps/templates/hilbertshotel/apartment_winter.dmm'
	landingZoneRelativeX = 11
	landingZoneRelativeY = 1
	category = GHC_WINTER

/datum/map_template/hilbertshotel/apartment/sport
	name = "Apartment-GYM"
	mappath = '_maps/templates/hilbertshotel/apartment_sportzone.dmm'
	landingZoneRelativeX = 1
	landingZoneRelativeY = 10
	category = GHC_STATION

/datum/map_template/hilbertshotel/apartment/capsule
	name = "Apartment-Capsule"
	mappath = '_maps/templates/hilbertshotel/apartment_capsule.dmm'
	landingZoneRelativeX = 1
	landingZoneRelativeY = 8
	category = GHC_MISC

/datum/map_template/hilbertshotel/apartment/train
	name = "Apartment-Train"
	mappath = '_maps/templates/hilbertshotel/apartment_train.dmm'
	landingZoneRelativeX = 6
	landingZoneRelativeY = 1
	category = GHC_MISC

#undef GHC_MISC
#undef GHC_APARTMENT
#undef GHC_BEACH
#undef GHC_STATION
#undef GHC_WINTER
#undef GHC_SPECIAL
