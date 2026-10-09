/obj/effect/landmark/transport
	icon = 'modular_bluemoon/icons/effects/transport_landmarks.dmi'

/// Platforms and navigation beacons of a tram line
/obj/effect/landmark/transport/nav_beacon/tram
	name = "tram destination"
	icon_state = "tram"
	/// the looping sound effect that is played while moving
	var/datum/looping_sound/tram/tram_loop
	/// What sound do we play when we arrive at this station?
	var/arrival_sound = 'modular_bluemoon/sound/machines/tram/other_line_processed.ogg'
	/// The ID of the tram we're linked to
	var/specific_transport_id = TRAMSTATION_LINE_1
	/// The ID of that particular destination
	var/platform_code = null
	/// Icons for the tgui console to list out for what is at this location
	var/list/tgui_icons = list()

/obj/effect/landmark/transport/nav_beacon/tram/Initialize(mapload)
	. = ..()
	tram_loop = new(src)
	LAZYADDASSOCLIST(SStransport.nav_beacons, specific_transport_id, src)

/obj/effect/landmark/transport/nav_beacon/tram/Destroy()
	LAZYREMOVEASSOC(SStransport.nav_beacons, specific_transport_id, src)
	if(isnull(SStransport.nav_beacons))
		SStransport.nav_beacons = list()
	QDEL_NULL(tram_loop)
	return ..()

/obj/effect/landmark/transport/nav_beacon/tram/nav
	name = "tram nav beacon"
	invisibility = INVISIBILITY_MAXIMUM // nav aids can't be abstract since they stay with the tram

/obj/effect/landmark/transport/nav_beacon/tram/platform

/// Gives its specific_transport_id to the tram or elevator it is mapped on
/obj/effect/landmark/transport/transport_id
	name = "transport init landmark"
	icon_state = "lift_id"
	///what specific id we give to the tram we're placed on, should explicitely set this if its a subtype, or weird things might happen
	var/specific_transport_id

//tramstation

/obj/effect/landmark/transport/transport_id/tramstation/line_1
	specific_transport_id = TRAMSTATION_LINE_1

/obj/effect/landmark/transport/nav_beacon/tram/nav/tramstation/main
	name = "tram announcement system"
	specific_transport_id = TRAM_NAV_BEACONS
	dir = WEST

/obj/effect/landmark/transport/nav_beacon/tram/platform/tramstation/west
	name = "Arrivals"
	platform_code = TRAMSTATION_WEST
	tgui_icons = list("Arrivals" = "plane-arrival", "Command" = "bullhorn", "Security" = "gavel")
	arrival_sound = 'modular_bluemoon/sound/machines/tram/arrivals_line_processed.ogg'

/obj/effect/landmark/transport/nav_beacon/tram/platform/tramstation/central
	name = "Medical"
	platform_code = TRAMSTATION_CENTRAL
	tgui_icons = list("Service" = "cocktail", "Medical" = "plus", "Engineering" = "wrench")
	arrival_sound = 'modular_bluemoon/sound/machines/tram/medical_line_processed.ogg'

/obj/effect/landmark/transport/nav_beacon/tram/platform/tramstation/east
	name = "Escape"
	platform_code = TRAMSTATION_EAST
	tgui_icons = list("Departures" = "plane-departure", "Cargo" = "box", "Science" = "flask")
	arrival_sound = 'modular_bluemoon/sound/machines/tram/escape_line_processed.ogg'

//map-agnostic landmarks

/obj/effect/landmark/transport/nav_beacon/tram/nav/immovable_rod
	name = "DESTINATION/NOT/FOUND"
	specific_transport_id = IMMOVABLE_ROD_DESTINATIONS

/datum/looping_sound/tram
	start_sound = 'modular_bluemoon/sound/machines/tram/tram_start.ogg'
	start_length = 2.219 SECONDS
	mid_sounds = 'modular_bluemoon/sound/machines/tram/tram_loop.ogg'
	mid_length = 2.219 SECONDS
	extra_range = 10
