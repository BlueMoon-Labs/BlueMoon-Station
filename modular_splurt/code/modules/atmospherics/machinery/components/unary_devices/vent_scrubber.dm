//Currently unused as their qdeletion in tryStoredRoom causes runtimes (along with normal pipes).
/obj/machinery/atmospherics/components/unary/vent_scrubber/hilbertshotel

/obj/machinery/atmospherics/components/unary/vent_scrubber/hilbertshotel/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(turn_on)), 3 SECONDS)

/obj/machinery/atmospherics/components/unary/vent_scrubber/hilbertshotel/proc/turn_on()
	on = TRUE
	update_appearance()

/obj/machinery/atmospherics/components/unary/vent_scrubber/hilbertshotel/layer4
	piping_layer = 4
	icon_state = "scrub_map-4"

/obj/machinery/atmospherics/components/unary/vent_scrubber/hilbertshotel/layer5
	piping_layer = 5
	icon_state = "scrub_map-5"
