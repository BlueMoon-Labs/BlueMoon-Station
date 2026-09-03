/obj/machinery/atmospherics/pipe/heat_exchanging/junction
	icon = 'icons/obj/atmospherics/pipes/he-junction.dmi'
	icon_state = "pipe11-3"

	name = "junction"
	desc = "A one meter junction that connects regular and heat-exchanging pipe."

	minimum_temperature_difference = 300
	thermal_conductivity = WALL_HEAT_TRANSFER_COEFFICIENT

	dir = SOUTH

	device_type = BINARY

	construction_type = /obj/item/pipe/directional
	pipe_state = "junction"

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/SetInitDirections()
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = SOUTH|NORTH
		if(EAST, WEST)
			initialize_directions = WEST|EAST

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/getNodeConnects()
	return list(turn(dir, 180), dir)

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/isConnectable(obj/machinery/atmospherics/target, given_layer, he_type_check)
	if(dir == get_dir(target, src))
		return ..(target, given_layer, FALSE) //we want a normal pipe instead
	return ..(target, given_layer, TRUE)

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/update_icon()
	. = ..()
	// Обе половины джанкшена - и толстая теплообменная, и тонкая обычная -
	// сидят в кадре ровно там же, где их соседи на слое по умолчанию (полоса
	// 8..22, тонкая труба 13..17), поэтому один пиксельный сдвиг уводит в свой
	// слой сразу обе. Запечённые кадры вдобавок гоняли развилку по вертикали;
	// теперь она стоит на месте на всех слоях.
	icon_state = "pipe[nodes[1] ? "1" : "0"][nodes[2] ? "1" : "0"]-[PIPING_LAYER_DEFAULT]"
	apply_layer_offset()
	update_layer()
	update_alpha()

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/layer1
	piping_layer = 1
	icon_state = "pipe11-1"

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/layer2
	piping_layer = 2
	icon_state = "pipe11-2"

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/layer4
	piping_layer = 4
	icon_state = "pipe11-4"

/obj/machinery/atmospherics/pipe/heat_exchanging/junction/layer5
	piping_layer = 5
	icon_state = "pipe11-5"
