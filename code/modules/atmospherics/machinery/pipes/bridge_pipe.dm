/// A visually raised straight pipe which may cross a perpendicular pipe on the
/// same layer without joining it.
/obj/machinery/atmospherics/pipe/bridge_pipe
	icon = 'icons/obj/atmospherics/pipes/bridge_pipe.dmi'
	icon_state = "bridge_map-3"
	name = "bridge pipe"
	desc = "A raised pipe for crossing a perpendicular pipenet without connecting to it."
	dir = SOUTH
	// Above every other pipe element: a bridge that draws in the shared pipe
	// layer loses to the pipe it crosses on an arbitrary tie-break, and the
	// whole point of the sprite is that it visibly rides over.
	layer = HIGH_PIPE_LAYER
	initialize_directions = NORTH|SOUTH
	pipe_flags = PIPING_CARDINAL_AUTONORMALIZE | PIPING_BRIDGE
	device_type = BINARY
	construction_type = /obj/item/pipe/binary
	pipe_state = "bridge_center"
	var/mutable_appearance/center

/obj/machinery/atmospherics/pipe/bridge_pipe/Initialize(mapload)
	icon_state = ""
	center = mutable_appearance(icon, "bridge_center")
	return ..()

/obj/machinery/atmospherics/pipe/bridge_pipe/SetInitDirections()
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = NORTH|SOUTH
		if(EAST, WEST)
			initialize_directions = EAST|WEST

/// The inherited proc would put the bridge back on the shared pipe layer on the
/// first update_icon(). Both visibility levels get their own raised value: a
/// pipe on bare plating is drawn too, so the tie has to be broken there as well.
/obj/machinery/atmospherics/pipe/bridge_pipe/update_layer()
	layer = (level == PIPE_VISIBLE_LEVEL ? HIGH_PIPE_LAYER : HIGH_PIPE_HIDDEN_LAYER) + (piping_layer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_LCHANGE

/obj/machinery/atmospherics/pipe/bridge_pipe/update_icon()
	cut_overlays()
	if(!center)
		center = mutable_appearance(icon, "bridge_center")
	PIPING_LAYER_DOUBLE_SHIFT(center, piping_layer)
	add_overlay(center)
	for(var/i in 1 to device_type)
		if(nodes[i])
			add_overlay(getpipeimage('icons/obj/atmospherics/pipes/manifold.dmi', "pipe-[piping_layer]", get_dir(src, nodes[i])))
	update_layer()
	update_alpha()
