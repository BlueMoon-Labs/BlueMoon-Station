// Simple Pipe
// The regular pipe you see everywhere, including bent ones.

/obj/machinery/atmospherics/pipe/simple
	icon = 'icons/obj/atmospherics/pipes/simple.dmi'
	icon_state = "pipe11-3"

	name = "pipe"
	desc = "Метр отрезка обыкновенной трубы."

	dir = SOUTH
	initialize_directions = SOUTH|NORTH
	pipe_flags = PIPING_CARDINAL_AUTONORMALIZE

	device_type = BINARY

	construction_type = /obj/item/pipe/binary/bendable
	pipe_state = "simple"

/obj/machinery/atmospherics/pipe/simple/SetInitDirections()
	if(dir in GLOB.diagonals)
		initialize_directions = dir
		return
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = SOUTH|NORTH
		if(EAST, WEST)
			initialize_directions = EAST|WEST

/obj/machinery/atmospherics/pipe/simple/update_icon()
	. = ..()
	icon_state = "pipe[nodes[1] ? "1" : "0"][nodes[2] ? "1" : "0"]-[piping_layer]"
	update_layer()
	update_alpha()

/// Толстостенная труба под высокое давление. Платит за стенку просветом,
/// поэтому ставить её везде невыгодно: разводка теряет буфер и начинает
/// дёргаться. Смысл в том, чтобы инженер ставил её точечно - на горячий контур
/// и магистраль, а не подряд.
/obj/machinery/atmospherics/pipe/simple/reinforced
	icon = 'icons/obj/atmospherics/pipes/reinforced.dmi'
	name = "reinforced pipe"
	desc = "Метр толстостенной трубы. Держит высокое давление, но просвет у неё меньше обычного."
	pressure_rating = PIPE_PRESSURE_RATING_REINFORCED
	volume_per_node = PIPE_VOLUME_PER_NODE_REINFORCED
	pipe_state = "reinforced_simple"
