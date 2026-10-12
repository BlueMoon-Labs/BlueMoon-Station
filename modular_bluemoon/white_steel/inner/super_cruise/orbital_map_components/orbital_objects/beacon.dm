/datum/orbital_object/z_linked/beacon
	name = "Неопознанный Сигнал"
	mass = 0
	radius = 10
	can_dock_anywhere = TRUE
	render_mode = RENDER_MODE_BEACON
	//The attached event
	var/datum/ruin_event/ruin_event
	//WHITE-STEEL PORT: суффикс имени сигнала (#номер и предупреждение события).
	//Сохраняется, чтобы не терять его при подписи по генератору руины.
	var/signal_suffix = ""
	//WHITE-STEEL PORT: выбирать ли тему генерации заранее, чтобы подписать сигнал по типу руины.
	var/pick_ruin_generator = FALSE
	var/datum/generator_settings/planned_generator

/datum/orbital_object/z_linked/beacon/New()
	. = ..()
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	ruin_event = SSorbits.get_event()
	//WHITE-STEEL PORT: выбираем тему генерации заранее — она определит и подпись сигнала,
	//и то, какая руина будет сгенерирована при стыковке.
	if(pick_ruin_generator && !planned_generator)
		planned_generator = pick_generator_settings()
	signal_suffix = " #[rand(1, 9)][linked_map.object_count][rand(1, 9)]"
	if(ruin_event?.warning_message)
		signal_suffix += " ([ruin_event.warning_message])"
	name = "[get_signal_prefix()][signal_suffix]"
	//Link the ruin event to ourselves
	ruin_event?.linked_z = src

//WHITE-STEEL PORT: префикс подписи сигнала. По умолчанию — исходное имя маяка,
//для руин — название темы генерации ("Вражеский сигнал" и т.д.).
/datum/orbital_object/z_linked/beacon/proc/get_signal_prefix()
	if(planned_generator?.signal_name)
		return planned_generator.signal_name
	return initial(name)

/datum/orbital_object/z_linked/beacon/post_map_setup()
	//Orbit around the systems sun
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 2000 + 25 * linked_z_level[1].z_value)

/datum/orbital_object/z_linked/beacon/weak
	name = "Слабый Сигнал"

//====================
// Asteroids
//====================

/datum/orbital_object/z_linked/beacon/ruin/asteroid
	name = "Астероид"
	render_mode = RENDER_MODE_DEFAULT
	pick_ruin_generator = FALSE

/datum/orbital_object/z_linked/beacon/ruinasteroid/New()
	. = ..()
	radius = rand(5, 15)

/datum/orbital_object/z_linked/beacon/ruin/asteroid/finish_z_level_assignment(datum/space_level/assigned_space_level)
	. = ..()
	generate_asteroids(world.maxx / 2, world.maxy / 2, assigned_space_level.z_value, 120, rand(-0.5, 0), rand(40, 70))

/datum/orbital_object/z_linked/beacon/ruin/asteroid/post_map_setup()
	//Orbit around the systems central gravitional body
	//Pack closely together to make an asteriod belt.
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 800 + 20 * rand(-19, 19))

//====================
// Random-Ruin z-levels
//====================
/datum/orbital_object/z_linked/beacon/ruin
	//The linked objective to the ruin, for generating extra stuff if required.
	var/datum/orbital_objective/linked_objective
	//WHITE-STEEL PORT: подписывать сигнал по теме генерации этой руины.
	pick_ruin_generator = TRUE

/datum/orbital_object/z_linked/beacon/ruin/Destroy()
	//Remove linked objective.
	if(linked_objective)
		linked_objective.linked_beacon = null
		linked_objective = null
	. = ..()

/datum/orbital_object/z_linked/beacon/ruin/finish_z_level_assignment(datum/space_level/assigned_space_level)
	. = ..()
	generate_space_ruin(world.maxx / 2, world.maxy / 2, assigned_space_level.z_value, 100, 100, linked_objective, planned_generator, ruin_event)

/datum/orbital_object/z_linked/beacon/ruin/post_map_setup()
	//Orbit around the systems sun
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 2000 + 25 * rand(40, 20))


//====================
//Stranded shuttles
//====================
/datum/orbital_object/z_linked/beacon/ruin/stranded_shuttle
	name = "Аварийный маяк"
	static_object = TRUE
	pick_ruin_generator = FALSE

/datum/orbital_object/z_linked/beacon/ruin/stranded_shuttle/finish_z_level_assignment(datum/space_level/assigned_space_level)
	. = ..()
	generate_asteroids(world.maxx / 2, world.maxy / 2, assigned_space_level.z_value, 120, -0.4, 40)

/datum/orbital_object/z_linked/beacon/ruin/stranded_shuttle/post_map_setup()
	return

//====================
//Interdiction
//====================
/datum/orbital_object/z_linked/beacon/ruin/interdiction
	name = "Аварийный маяк"
	static_object = TRUE
	pick_ruin_generator = FALSE

/datum/orbital_object/z_linked/beacon/ruin/interdiction/post_map_setup()
	return
