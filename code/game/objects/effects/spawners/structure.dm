/*
Because mapping is already tedious enough this spawner let you spawn generic
"sets" of objects rather than having to make the same object stack again and
again.
*/

/obj/effect/spawner/structure
	name = "map structure spawner"
	var/list/spawn_list

/obj/effect/spawner/structure/Initialize(mapload)
	. = ..()
	if(spawn_list && spawn_list.len)
		for(var/I in spawn_list)
			spawn_structure(I, get_turf(src))
	return INITIALIZE_HINT_QDEL

/obj/effect/spawner/structure/proc/spawn_structure(structure_type, turf/location)
	return new structure_type(location)


//normal windows

/obj/effect/spawner/structure/window
	icon = 'icons/obj/structures_spawners.dmi'
	icon_state = "window_spawner"
	name = "Window Spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/fulltile)
	dir = SOUTH
	var/electrochromatic
	var/electrochromatic_id
	// Автоматическое оснащение аирбагами или оконными фаерлоками.
	var/install_airbags = TRUE
	// Защиту получают только окна, созданные этим спавнером.
	var/list/spawned_windows

/obj/effect/spawner/structure/window/Initialize(mapload)
	..()
	. = INITIALIZE_HINT_LATELOAD
	if(!electrochromatic)
		return
	if(!electrochromatic_id)
		stack_trace("Electrochromatic Window Spawner set without electromatic id.")
		return
	if(electrochromatic_id[1] == "!")
		electrochromatic_id = SSmapping.get_obfuscated_id(electrochromatic_id)
	for(var/obj/structure/window/W as anything in spawned_windows)
		W.electrochromatic_id = electrochromatic_id
		W.make_electrochromatic()
		if(electrochromatic == ELECTROCHROMATIC_DIMMED)
			W.electrochromatic_dim()

/obj/effect/spawner/structure/window/LateInitialize()
	. = ..()
	// Соседние турфы и все окна спавнера уже готовы к выбору защиты.
	for(var/obj/structure/window/window as anything in spawned_windows)
		if(install_airbags && !QDELETED(window))
			setup_window_safety(window)
	qdel(src)

/obj/effect/spawner/structure/window/spawn_structure(structure_type, turf/location)
	var/atom/movable/spawned_structure = ..()
	if(istype(spawned_structure, /obj/structure/window))
		LAZYADD(spawned_windows, spawned_structure)
	return spawned_structure

/obj/effect/spawner/structure/window/proc/setup_window_safety(obj/structure/window/window)
	if(!window.anchored || !window.density || !isturf(window.loc) || window.CanAtmosPass == ATMOS_PASS_YES)
		return
	var/turf/window_turf = get_turf(window)
	var/area/window_area = get_area(window)
	// Тип стекла не определяет принадлежность шаттлу: в капсулах бывает обычное окно.
	var/use_firelock = istype(window, /obj/structure/window/shuttle) || istype(window_area, /area/survivalpod) || isshuttleturf(window_turf) || SSshuttle.is_in_shuttle_bounds(window)
	if(!use_firelock && SSmapping.station_window_firelocks && is_station_level(window_turf.z))
		var/station_window = window_area.is_station_member()
		var/borders_space = isspaceturf(window_turf)
		for(var/turf/neighbor in range(1, window_turf))
			if(!station_window && istype(window_area, /area/space))
				var/area/neighbor_area = get_area(neighbor)
				station_window = neighbor_area.is_station_member()
			borders_space = borders_space || isspaceturf(neighbor)
		use_firelock = station_window && borders_space

	if(use_firelock)
		if(!(locate(/obj/machinery/door/firedoor/window) in window_turf))
			new /obj/machinery/door/firedoor/window(window_turf)
		return
	window.install_airbag()

//shutter
/obj/effect/spawner/structure/window/shutter
	name = "shutter window spawner"
	icon_state = "shwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/fulltile)

//reinforced

/obj/effect/spawner/structure/window/reinforced
	name = "reinforced window spawner"
	icon_state = "rwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile)

//reinforced shutter
/obj/effect/spawner/structure/window/reinforced/shutter
	name = "reinforced shutter window spawner"
	icon_state = "shrwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile)

/obj/effect/spawner/structure/window/hollow
	name = "hollow Window Spawner"
	icon_state = "hwindow_spawner_full"
	spawn_list = list(/obj/structure/grille, /obj/structure/window, /obj/structure/window/spawner/north, /obj/structure/window/spawner/east, /obj/structure/window/spawner/west)

/obj/effect/spawner/structure/window/hollow/end
	icon_state = "hwindow_spawner_end"

/obj/effect/spawner/structure/window/hollow/end/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/spawner/north, /obj/structure/window/spawner/east, /obj/structure/window/spawner/west)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window, /obj/structure/window/spawner/north, /obj/structure/window/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window, /obj/structure/window/spawner/east, /obj/structure/window/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window, /obj/structure/window/spawner/north, /obj/structure/window/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/middle
	icon_state = "hwindow_spawner_middle"

/obj/effect/spawner/structure/window/hollow/middle/Initialize(mapload)
	switch(dir)
		if(NORTH,SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window, /obj/structure/window/spawner/north)
		if(EAST,WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/spawner/east, /obj/structure/window/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/directional
	icon_state = "hwindow_spawner_directional"

/obj/effect/spawner/structure/window/hollow/directional/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/spawner/north)
		if(NORTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/spawner/north, /obj/structure/window/spawner/east)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/spawner/east)
		if(SOUTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window, /obj/structure/window/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window)
		if(SOUTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window, /obj/structure/window/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/spawner/west)
		if(NORTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/spawner/north, /obj/structure/window/spawner/west)
	. = ..()

//reinforced

/obj/effect/spawner/structure/window/reinforced
	name = "reinforced Window Spawner"
	icon_state = "rwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile)

/obj/effect/spawner/structure/window/reinforced/no_firelock
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile)

/obj/effect/spawner/structure/window/hollow/reinforced
	name = "hollow reinforced Window Spawner"
	icon_state = "hrwindow_spawner_full"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced, /obj/structure/window/reinforced/spawner/north, /obj/structure/window/reinforced/spawner/east, /obj/structure/window/reinforced/spawner/west)

/obj/effect/spawner/structure/window/hollow/reinforced/end
	icon_state = "hrwindow_spawner_end"

/obj/effect/spawner/structure/window/hollow/reinforced/end/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/spawner/north, /obj/structure/window/reinforced/spawner/east, /obj/structure/window/reinforced/spawner/west)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced, /obj/structure/window/reinforced/spawner/north, /obj/structure/window/reinforced/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced, /obj/structure/window/reinforced/spawner/east, /obj/structure/window/reinforced/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced, /obj/structure/window/reinforced/spawner/north, /obj/structure/window/reinforced/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/reinforced/middle
	icon_state = "hrwindow_spawner_middle"

/obj/effect/spawner/structure/window/hollow/reinforced/middle/Initialize(mapload)
	switch(dir)
		if(NORTH,SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced, /obj/structure/window/reinforced/spawner/north)
		if(EAST,WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/spawner/east, /obj/structure/window/reinforced/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/reinforced/directional
	icon_state = "hrwindow_spawner_directional"

/obj/effect/spawner/structure/window/hollow/reinforced/directional/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/spawner/north)
		if(NORTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/spawner/north, /obj/structure/window/reinforced/spawner/east)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/spawner/east)
		if(SOUTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced, /obj/structure/window/reinforced/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced)
		if(SOUTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced, /obj/structure/window/reinforced/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/spawner/west)
		if(NORTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/spawner/north, /obj/structure/window/reinforced/spawner/west)
	. = ..()

//tinted and electrochromatic

/obj/effect/spawner/structure/window/reinforced/tinted
	name = "tinted reinforced Window Spawner"
	icon_state = "twindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/tinted/fulltile)

/obj/effect/spawner/structure/window/reinforced/tinted/electrochromatic
	name = "electrochromatic reinforced Window Spawner"
	electrochromatic = ELECTROCHROMATIC_DIMMED

//shuttle window

/obj/effect/spawner/structure/window/shuttle
	name = "shuttle Window Spawner"
	icon_state = "swindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/shuttle)


//plastitanium window

/obj/effect/spawner/structure/window/plastitanium
	name = "plastitanium Window Spawner"
	icon_state = "plastitaniumwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/plastitanium)

//plastitanium pirate window

/obj/effect/spawner/structure/window/plastitanium/pirate
	spawn_list = list(/obj/structure/grille, /obj/structure/window/plastitanium/pirate)

//ice window

/obj/effect/spawner/structure/window/ice
	name = "ice Window Spawner"
	icon_state = "icewindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile/ice)


//survival pod window

/obj/effect/spawner/structure/window/survival_pod
	name = "pod Window Spawner"
	icon_state = "podwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/shuttle/survival_pod)

/obj/effect/spawner/structure/window/hollow/survival_pod
	name = "hollow pod Window Spawner"
	icon_state = "podwindow_spawner_full"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod, /obj/structure/window/reinforced/survival_pod/north, /obj/structure/window/reinforced/survival_pod/east, /obj/structure/window/reinforced/survival_pod/west)

/obj/effect/spawner/structure/window/hollow/survival_pod/end
	icon_state = "podwindow_spawner_end"

/obj/effect/spawner/structure/window/hollow/survival_pod/end/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod/north, /obj/structure/window/reinforced/survival_pod/east, /obj/structure/window/reinforced/survival_pod/west)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod, /obj/structure/window/reinforced/survival_pod/north, /obj/structure/window/reinforced/survival_pod/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod, /obj/structure/window/reinforced/survival_pod/east, /obj/structure/window/reinforced/survival_pod/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod, /obj/structure/window/reinforced/survival_pod/north, /obj/structure/window/reinforced/survival_pod/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/survival_pod/middle
	icon_state = "podwindow_spawner_middle"

/obj/effect/spawner/structure/window/hollow/survival_pod/middle/Initialize(mapload)
	switch(dir)
		if(NORTH,SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod, /obj/structure/window/reinforced/survival_pod/north)
		if(EAST,WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod/east, /obj/structure/window/reinforced/survival_pod/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/survival_pod/directional
	icon_state = "podwindow_spawner_directional"

/obj/effect/spawner/structure/window/hollow/survival_pod/directional/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod/north)
		if(NORTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod/north, /obj/structure/window/reinforced/survival_pod/east)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod/east)
		if(SOUTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod, /obj/structure/window/reinforced/survival_pod/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod)
		if(SOUTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod, /obj/structure/window/reinforced/survival_pod/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod/west)
		if(NORTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/survival_pod/north, /obj/structure/window/reinforced/survival_pod/west)
	. = ..()


//plasma windows

/obj/effect/spawner/structure/window/plasma
	name = "plasma Window Spawner"
	icon_state = "pwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/fulltile)

/obj/effect/spawner/structure/window/hollow/plasma
	name = "hollow plasma Window Spawner"
	icon_state = "phwindow_spawner_full"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma, /obj/structure/window/plasma/spawner/north, /obj/structure/window/plasma/spawner/east, /obj/structure/window/plasma/spawner/west)

/obj/effect/spawner/structure/window/hollow/plasma/end
	icon_state = "phwindow_spawner_end"

/obj/effect/spawner/structure/window/hollow/plasma/end/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/spawner/north, /obj/structure/window/plasma/spawner/east, /obj/structure/window/plasma/spawner/west)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma, /obj/structure/window/plasma/spawner/north, /obj/structure/window/plasma/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma, /obj/structure/window/plasma/spawner/east, /obj/structure/window/plasma/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma, /obj/structure/window/plasma/spawner/north, /obj/structure/window/plasma/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/plasma/middle
	icon_state = "phwindow_spawner_middle"

/obj/effect/spawner/structure/window/hollow/plasma/middle/Initialize(mapload)
	switch(dir)
		if(NORTH,SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma, /obj/structure/window/plasma/spawner/north)
		if(EAST,WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/spawner/east, /obj/structure/window/plasma/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/plasma/directional
	icon_state = "phwindow_spawner_directional"

/obj/effect/spawner/structure/window/hollow/plasma/directional/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/spawner/north)
		if(NORTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/spawner/north, /obj/structure/window/plasma/spawner/east)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/spawner/east)
		if(SOUTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma, /obj/structure/window/plasma/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma)
		if(SOUTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma, /obj/structure/window/plasma/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/spawner/west)
		if(NORTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/spawner/north, /obj/structure/window/plasma/spawner/west)
	. = ..()

//plasma reinforced

/obj/effect/spawner/structure/window/plasma/reinforced
	name = "reinforced plasma Window Spawner"
	icon_state = "prwindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/fulltile)

/obj/effect/spawner/structure/window/hollow/plasma/reinforced
	name = "hollow reinforced plasma Window Spawner"
	icon_state = "phrwindow_spawner_full"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced, /obj/structure/window/plasma/reinforced/spawner/north, /obj/structure/window/plasma/reinforced/spawner/east, /obj/structure/window/plasma/reinforced/spawner/west)

/obj/effect/spawner/structure/window/hollow/plasma/reinforced/end
	icon_state = "phrwindow_spawner_end"

/obj/effect/spawner/structure/window/hollow/plasma/reinforced/end/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/spawner/north, /obj/structure/window/plasma/reinforced/spawner/east, /obj/structure/window/plasma/reinforced/spawner/west)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced, /obj/structure/window/plasma/reinforced/spawner/north, /obj/structure/window/plasma/reinforced/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced, /obj/structure/window/plasma/reinforced/spawner/east, /obj/structure/window/plasma/reinforced/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced, /obj/structure/window/plasma/reinforced/spawner/north, /obj/structure/window/plasma/reinforced/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/plasma/reinforced/middle
	icon_state = "phrwindow_spawner_middle"

/obj/effect/spawner/structure/window/hollow/plasma/reinforced/middle/Initialize(mapload)
	switch(dir)
		if(NORTH,SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced, /obj/structure/window/plasma/reinforced/spawner/north)
		if(EAST,WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/spawner/east, /obj/structure/window/plasma/reinforced/spawner/west)
	. = ..()

/obj/effect/spawner/structure/window/hollow/plasma/reinforced/directional
	icon_state = "phrwindow_spawner_directional"

/obj/effect/spawner/structure/window/hollow/plasma/reinforced/directional/Initialize(mapload)
	switch(dir)
		if(NORTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/spawner/north)
		if(NORTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/spawner/north, /obj/structure/window/plasma/reinforced/spawner/east)
		if(EAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/spawner/east)
		if(SOUTHEAST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced, /obj/structure/window/plasma/reinforced/spawner/east)
		if(SOUTH)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced)
		if(SOUTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced, /obj/structure/window/plasma/reinforced/spawner/west)
		if(WEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/spawner/west)
		if(NORTHWEST)
			spawn_list = list(/obj/structure/grille, /obj/structure/window/plasma/reinforced/spawner/north, /obj/structure/window/plasma/reinforced/spawner/west)
	. = ..()

//Ratvar

/obj/effect/spawner/structure/window/clockwork
	name = "Ratvar Window Spawner"
	icon_state = "clockwork_window"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/bronze/fulltile)
