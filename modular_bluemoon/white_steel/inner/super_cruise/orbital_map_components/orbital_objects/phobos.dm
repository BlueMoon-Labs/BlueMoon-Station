//Centcom Z-Level.
//Syndicate infiltrator level.
/datum/orbital_object/z_linked/phobos
	name = "Озон"
	mass = 50000
	radius = 350
	static_object = TRUE
	render_mode = RENDER_MODE_PLANET
	priority = 20

/datum/orbital_object/z_linked/phobos/New()
	. = ..()
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	linked_map.center = src
