/obj/machinery/atmospherics/components/unary/outlet_injector/hilbertshotel

/obj/machinery/atmospherics/components/unary/outlet_injector/hilbertshotel/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(turn_on)), 3 SECONDS)

/obj/machinery/atmospherics/components/unary/outlet_injector/hilbertshotel/proc/turn_on()
	on = TRUE
	update_appearance()

/obj/machinery/atmospherics/components/unary/outlet_injector/hilbertshotel/layer4
	piping_layer = 4
	icon_state = "inje_map-4"

/obj/machinery/atmospherics/components/unary/outlet_injector/hilbertshotel/layer5
	piping_layer = 5
	icon_state = "inje_map-5"
