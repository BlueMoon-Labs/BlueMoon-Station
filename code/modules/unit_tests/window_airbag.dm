/// The colour adapter exists so a network can cross a paint boundary on purpose.
/// If it stops joining either side, it is worse than the grey pipe it replaces.
/datum/unit_test/color_adapter_bridges_paint/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/east = locate(room.x + 1, room.y, room.z)
	var/turf/open/west = locate(room.x - 1, room.y, room.z)
	TEST_ASSERT(istype(east) && istype(west), "test location has no open turfs on both sides")

	var/obj/machinery/atmospherics/pipe/color_adapter/adapter = allocate(/obj/machinery/atmospherics/pipe/color_adapter, room)
	var/obj/machinery/atmospherics/pipe/simple/red = allocate(/obj/machinery/atmospherics/pipe/simple, west)
	var/obj/machinery/atmospherics/pipe/simple/blue = allocate(/obj/machinery/atmospherics/pipe/simple, east)
	for(var/obj/machinery/atmospherics/piece as anything in list(adapter, red, blue))
		piece.setDir(EAST)
		piece.SetInitDirections()
	red.pipe_color = GLOB.pipe_paint_colors["red"]
	blue.pipe_color = GLOB.pipe_paint_colors["blue"]

	TEST_ASSERT(!red.connection_check(blue, red.piping_layer),
		"two differently painted pipes connected without an adapter between them")
	TEST_ASSERT(adapter.connection_check(red, adapter.piping_layer), "the adapter refused the red side")
	TEST_ASSERT(adapter.connection_check(blue, adapter.piping_layer), "the adapter refused the blue side")
	TEST_ASSERT(!adapter.paintable, "the adapter can be painted, which would mean nothing")
	TEST_ASSERT(!adapter.paint(GLOB.pipe_paint_colors["red"]), "painting the adapter reported success")
