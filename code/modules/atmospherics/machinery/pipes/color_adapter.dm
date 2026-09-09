/// Paint decides whether two pipes join, so a network that has to cross a colour
/// boundary on purpose needs somewhere to do it. Repainting a segment grey works
/// and is what the RPD offers, but it leaves nothing on the map to say the
/// boundary was deliberate; this does, and it draws each side in its neighbour's
/// own colour so the join reads at a glance.
/obj/machinery/atmospherics/pipe/color_adapter
	icon = 'icons/obj/atmospherics/pipes/color_adapter.dmi'
	icon_state = "adapter_map-3"
	name = "color adapter"
	desc = "Метровый отрезок трубы, которым стыкуют трубопроводы разной окраски."
	dir = SOUTH
	initialize_directions = NORTH|SOUTH
	pipe_flags = PIPING_CARDINAL_AUTONORMALIZE | PIPING_ALL_COLORS
	device_type = BINARY
	construction_type = /obj/item/pipe/binary
	pipe_state = "adapter_center"
	paintable = FALSE
	var/mutable_appearance/center

/obj/machinery/atmospherics/pipe/color_adapter/Initialize(mapload)
	icon_state = ""
	center = mutable_appearance(icon, "adapter_center")
	return ..()

/obj/machinery/atmospherics/pipe/color_adapter/SetInitDirections()
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = NORTH|SOUTH
		if(EAST, WEST)
			initialize_directions = EAST|WEST

/// The adapter itself stays unpainted; each stub takes the colour of the pipe it
/// reaches, which is the only thing that makes the tile readable as a boundary
/// rather than as a grey pipe someone forgot to paint.
/obj/machinery/atmospherics/pipe/color_adapter/update_icon()
	cut_overlays()
	if(!center)
		center = mutable_appearance(icon, "adapter_center")
	PIPING_LAYER_DOUBLE_SHIFT(center, piping_layer)
	add_overlay(center)
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(!node)
			continue
		add_overlay(getpipeimage('icons/obj/atmospherics/pipes/manifold.dmi', "pipe-[piping_layer]", \
			get_dir(src, node), node.pipe_color || rgb(255, 255, 255), piping_layer))
	update_layer()
	update_alpha()

/obj/machinery/atmospherics/pipe/color_adapter/layer1
	piping_layer = 1
	icon_state = "adapter_map-1"

/obj/machinery/atmospherics/pipe/color_adapter/layer2
	piping_layer = 2
	icon_state = "adapter_map-2"

/obj/machinery/atmospherics/pipe/color_adapter/layer4
	piping_layer = 4
	icon_state = "adapter_map-4"

/obj/machinery/atmospherics/pipe/color_adapter/layer5
	piping_layer = 5
	icon_state = "adapter_map-5"
