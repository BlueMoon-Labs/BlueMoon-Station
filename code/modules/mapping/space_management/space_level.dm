/datum/space_level
	var/name = "NAME MISSING"
	var/list/neigbours = list()
	var/list/traits
	var/z_value = 1 //actual z placement
	var/linkage = SELFLOOPING
	var/xi
	var/yi   //imaginary placements on the grid
	/// Whether lighting infrastructure (objects, corners) has been created for this z-level
	var/lighting_initialized = FALSE
	/// Orbital body this z-level is linked to (supercruise system, WHITESTEEL)
	var/datum/orbital_object/z_linked/orbital_body
	/// Is something generating on this level? (supercruise system, WHITESTEEL)
	var/generating = FALSE

/datum/space_level/New(new_z, new_name, list/new_traits = list(), orbital_body_type)
	z_value = new_z
	name = new_name
	traits = new_traits
	set_linkage(new_traits[ZTRAIT_LINKAGE])
	if(orbital_body_type)
		orbital_body = new orbital_body_type()
		orbital_body.link_to_z(src)
