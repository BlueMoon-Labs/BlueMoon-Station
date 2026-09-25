/obj/machinery/computer/shuttle_flight/exploration
	name = "Vanguard Igla shuttle"
	desc = "Для сам знаешь чего."
	circuit = /obj/item/circuitboard/computer/exploration_shuttle
	shuttleId = "exploration"
	possible_destinations = "exploration_home"
	req_access = list(ACCESS_GATEWAY)

/obj/machinery/computer/shuttle_flight/exploration/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock, idnum, override)
	return

/datum/map_template/shuttle/exploration
	port_id = "exploration"
	suffix = "shuttle"
	name = "Vanguard Igla shuttle"
	can_be_bought = FALSE

/obj/docking_port/stationary/exploration
	name = "Vanguard Igla shuttle docking key"
	shuttle_id = "exploration_home"
	roundstart_template = /datum/map_template/shuttle/exploration
	dwidth = 5
	width = 13
	height = 7
