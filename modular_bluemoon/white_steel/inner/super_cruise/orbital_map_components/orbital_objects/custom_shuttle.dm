/datum/orbital_object/shuttle/custom_shuttle
	name = "DIY-шаттл"
	var/fuel_consumption_rate = 1
	var/obj/machinery/computer/shuttle_flight/custom_shuttle/attached_console

/datum/orbital_object/shuttle/custom_shuttle/Destroy()
	attached_console = null
	. = ..()

/datum/orbital_object/shuttle/custom_shuttle/process()
	if(!attached_console)
		return
	attached_console.consume_fuel(ORBITAL_UPDATE_RATE_SECONDS * fuel_consumption_rate * thrust / 100)
	if(attached_console.check_stranded())
		return
	max_thrust = (3 * arctan(attached_console.calculated_acceleration / 20)) / 90
	. = ..()
