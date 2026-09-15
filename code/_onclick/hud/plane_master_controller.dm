///Atom that manages and controls multiple planes. It's an atom so we can hook into add_filter etc. Multiple controllers can control one plane.
/atom/movable/plane_master_controller
	///List of planes in this controllers control. Initially this is a normal list, but becomes an assoc list of plane numbers as strings | plane instance
	var/list/controlled_planes = list()
	/// Несмещённые плоскости из объявления типа.
	var/list/true_planes
	///hud that owns this controller
	var/datum/hud/owner_hud


INITIALIZE_IMMEDIATE(/atom/movable/plane_master_controller)

///Ensures that all the planes are correctly in the controlled_planes list.
/atom/movable/plane_master_controller/Initialize(mapload, datum/hud/hud)
	. = ..()
	owner_hud = hud
	true_planes = controlled_planes
	controlled_planes = list()
	for(var/i in true_planes)
		if(!length(owner_hud.get_true_plane_masters(i)))
			stack_trace("[i] isn't a valid plane master layer for [owner_hud.type], are you sure it exists in the first place?")
	adopt_plane_masters()

/// Подхватить мастеров, достроенных после нас, вместе с уже повешенными фильтрами.
/atom/movable/plane_master_controller/proc/adopt_plane_masters()
	for(var/true_plane in true_planes)
		for(var/atom/movable/screen/plane_master/instance as anything in owner_hud.get_true_plane_masters(true_plane))
			var/plane_key = "[instance.plane]"
			if(controlled_planes[plane_key])
				continue
			controlled_planes[plane_key] = instance
			for(var/filter_name in filter_data)
				var/list/params = filter_data[filter_name]
				instance.add_filter(filter_name, params["priority"], params - "priority")

// From BeeStation
/atom/movable/plane_master_controller/Destroy()
	if(owner_hud)
		owner_hud.plane_master_controllers -= src
		owner_hud = null
	controlled_planes.Cut()
	return ..()

///Full override so we can just use filterrific
/atom/movable/plane_master_controller/add_filter(name, priority, list/params)
	. = ..()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		pm_iterator.add_filter(name, priority, params)

///Full override so we can just use filterrific
/atom/movable/plane_master_controller/remove_filter(name_or_names)
	. = ..()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		pm_iterator.remove_filter(name_or_names)

/atom/movable/plane_master_controller/update_filters()
	. = ..()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		pm_iterator.update_filters()

///Gets all filters for this controllers plane masters
/atom/movable/plane_master_controller/proc/get_filters(name)
	. = list()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		. += pm_iterator.get_filter(name)

///Transitions all filters owned by this plane master controller
/atom/movable/plane_master_controller/transition_filter(name, time, list/new_params, easing, loop)
	. = ..()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		pm_iterator.transition_filter(name, time, new_params, easing, loop)

///Full override so we can just use filterrific
/atom/movable/plane_master_controller/add_atom_colour(coloration, colour_priority)
	. = ..()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		pm_iterator.add_atom_colour(coloration, colour_priority)


///Removes an instance of colour_type from the atom's atom_colours list
/atom/movable/plane_master_controller/remove_atom_colour(colour_priority, coloration)
	. = ..()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		pm_iterator.remove_atom_colour(colour_priority, coloration)


///Resets the atom's color to null, and then sets it to the highest priority colour available
/atom/movable/plane_master_controller/update_atom_colour()
	for(var/i in controlled_planes)
		var/atom/movable/screen/plane_master/pm_iterator = controlled_planes[i]
		pm_iterator.update_atom_colour()


/atom/movable/plane_master_controller/game
	name = PLANE_MASTERS_GAME
	controlled_planes = list(FLOOR_PLANE, GAME_PLANE, WALL_PLANE, ABOVE_WALL_PLANE, LIGHTING_PLANE, EMISSIVE_PLANE)
