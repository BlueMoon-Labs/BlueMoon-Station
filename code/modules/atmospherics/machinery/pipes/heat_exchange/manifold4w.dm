//4-Way Manifold

/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w
	icon = 'icons/obj/atmospherics/pipes/he-manifold.dmi'
	icon_state = "manifold4w-3"

	name = "4-way pipe manifold"
	desc = "A manifold composed of heat-exchanging pipes."

	initialize_directions = NORTH|SOUTH|EAST|WEST

	device_type = QUATERNARY

	construction_type = /obj/item/pipe/quaternary
	pipe_state = "he_manifold4w"
	// Корпус манифолда сдвигается по обеим осям сразу, а патрубки при этом
	// обязаны дотягиваться до края тайла - то есть меняют длину, а не только
	// положение. Рантайм-сдвиг это не воспроизводит, и лист нарисован ровно
	// под средние слои. См. apply_layer_offset() у прямой трубы.
	pipe_flags = PIPING_INNER_LAYERS_ONLY

	var/mutable_appearance/center

/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w/New()
	icon_state = ""
	center = mutable_appearance(icon, "manifold4w_center")
	return ..()

/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w/SetInitDirections()
	initialize_directions = initial(initialize_directions)

/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w/update_icon()
	cut_overlays()

	PIPING_LAYER_DOUBLE_SHIFT(center, piping_layer)
	add_overlay(center)

	//Add non-broken pieces
	for(var/i in 1 to device_type)
		if(nodes[i])
			add_overlay( getpipeimage(icon, "pipe-[piping_layer]", get_dir(src, nodes[i])) )

	update_layer()
	update_alpha()


/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w/layer2
	piping_layer = 2
	icon_state = "manifold4w-2"

/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w/layer4
	piping_layer = 4
	icon_state = "manifold4w-4"
