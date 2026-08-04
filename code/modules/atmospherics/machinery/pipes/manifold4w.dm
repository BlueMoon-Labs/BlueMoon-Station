//4-Way Manifold

/obj/machinery/atmospherics/pipe/manifold4w
	icon = 'icons/obj/atmospherics/pipes/manifold.dmi'
	icon_state = "manifold4w-3"

	name = "4-way pipe manifold"
	desc = "A manifold composed of regular pipes."

	initialize_directions = NORTH|SOUTH|EAST|WEST

	device_type = QUATERNARY

	construction_type = /obj/item/pipe/quaternary
	pipe_state = "manifold4w"

	var/mutable_appearance/center

/obj/machinery/atmospherics/pipe/manifold4w/Initialize(mapload)
	icon_state = ""
	center = mutable_appearance(icon, "manifold4w_center")
	return ..()

/obj/machinery/atmospherics/pipe/manifold4w/SetInitDirections()
	initialize_directions = initial(initialize_directions)

/obj/machinery/atmospherics/pipe/manifold4w/update_icon()
	cut_overlays()
	if(!center)
		center = mutable_appearance(icon, "manifold_center")
	PIPING_LAYER_DOUBLE_SHIFT(center, piping_layer)
	add_overlay(center)

	//Add non-broken pieces
	for(var/i in 1 to device_type)
		if(nodes[i])
			add_overlay( getpipeimage(icon, "pipe-[piping_layer]", get_dir(src, nodes[i])) )
	update_layer()
	update_alpha()

/obj/machinery/atmospherics/pipe/manifold4w/reinforced
	icon = 'icons/obj/atmospherics/pipes/reinforced_manifold.dmi'
	name = "reinforced 4-way pipe manifold"
	desc = "Четырёхходовой коллектор из толстостенных труб. Держит высокое давление ценой просвета."
	pressure_rating = PIPE_PRESSURE_RATING_REINFORCED
	volume_per_node = PIPE_VOLUME_PER_NODE_REINFORCED
	pipe_state = "reinforced_manifold4w"
