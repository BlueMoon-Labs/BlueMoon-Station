/// This is an atmospherics pipe which can relay air up/down a deck.
/obj/machinery/atmospherics/pipe/simple/multiz
	name = "multi deck pipe adapter"
	desc = "An adapter which allows pipes to connect to other pipenets on different decks."
	icon = 'icons/obj/multiz.dmi'
	icon_state = "adapter-2"

	dir = SOUTH
	initialize_directions = SOUTH
	pipe_flags = 0

	construction_type = /obj/item/pipe/directional
	layer = HIGH_OBJ_LAYER
	device_type = TRINARY
	pipe_state = "multiz"

	///Our central icon
	var/mutable_appearance/center = null
	///The pipe icon
	var/mutable_appearance/pipe = null
	///Reference to the node
	var/obj/machinery/atmospherics/front_node = null

/obj/machinery/atmospherics/pipe/simple/multiz/New()
	icon_state = ""
	center = mutable_appearance(icon, "adapter_center", layer = HIGH_OBJ_LAYER)
	pipe = mutable_appearance(icon, "pipe-[piping_layer]")
	return ..()

/obj/machinery/atmospherics/pipe/simple/multiz/SetInitDirections()
	initialize_directions = dir

/obj/machinery/atmospherics/pipe/simple/multiz/update_overlays()
	. = ..()
	pipe.color = front_node ? front_node.pipe_color : rgb(255, 255, 255)
	pipe.icon_state = "pipe-[piping_layer]"
	. += pipe
	center.pixel_x = PIPING_LAYER_P_X * (piping_layer - PIPING_LAYER_DEFAULT)
	. += center

// /obj/machinery/atmospherics/pipe/simple/multiz/update_icon()
// 	. = ..()
// 	cut_overlays() //This adds the overlay showing it's a multiz pipe. This should go above turfs and such
// 	var/image/multiz_overlay_node = new(src) //If we have a firing state, light em up!
// 	multiz_overlay_node.icon = 'icons/obj/atmos.dmi'
// 	multiz_overlay_node.icon_state = "multiz_pipe"
// 	multiz_overlay_node.layer = HIGH_OBJ_LAYER
// 	add_overlay(multiz_overlay_node)

///Attempts to locate a multiz pipe that's above us, if it finds one it merges us into its pipenet
// BLUEMOON CHANGE Переписываем чтобы работало КрАсИвО
/obj/machinery/atmospherics/pipe/simple/multiz/atmosinit(list/node_connects)
	..()
	for(var/obj/machinery/atmospherics/target in get_step(src, initialize_directions))
		if(can_be_node(target, 1))
			nodes[1] = target
			break
	var/turf/T = get_turf(src)
	for(var/obj/machinery/atmospherics/pipe/simple/multiz/above in SSmapping.get_turf_above(T))
		if(!isConnectable(above, piping_layer))
			continue
		nodes[2] = above
		break
	for(var/obj/machinery/atmospherics/pipe/simple/multiz/below in SSmapping.get_turf_below(T))
		if(!isConnectable(below, piping_layer))
			continue
		nodes[3] = below
		break
	update_icon()
// BLUEMOON CHANGE END
