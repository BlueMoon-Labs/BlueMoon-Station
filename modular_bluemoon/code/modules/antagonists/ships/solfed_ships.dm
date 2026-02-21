/area/shuttle/solfed/corvette
	name = "Solar Federation Corvette"

/obj/item/circuitboard/computer/solfed/corvette
	build_path = /obj/machinery/computer/shuttle/solfed/corvette

/obj/machinery/computer/shuttle/solfed/corvette
	name = "Solar Federation Corvette Console"
	desc = "Used to control the Solar Federation Corvette."
	req_access = list(ACCESS_SYNDICATE)
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/solfed/corvette
	shuttleId = "solfed_corvette"
	possible_destinations = "syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;solfed_corvette_custom;whiteship_z4"

/obj/machinery/computer/camera_advanced/shuttle_docker/solfed/corvette
	name = "Solar Federation Corvette Computer"
	desc = "Used to designate a precise transit location for the Solar Federation Corvette."
	shuttleId = "solfed_corvette"
	lock_override = NONE
	shuttlePortId = "solfed_corvette_custom"
	jump_to_ports = list("ds2_syndicate" = 1, "whiteship_home" = 1)
	view_range = 5.5
	x_offset = 7
	y_offset = 1
	space_turfs_only = FALSE

/area/shuttle/solfed/destroyer
	name = "Solar Federation Destroyer"

/obj/item/circuitboard/computer/solfed/destroyer
	build_path = /obj/machinery/computer/shuttle/solfed/destroyer

/obj/machinery/computer/shuttle/solfed/destroyer
	name = "Solar Federation Destroyer Console"
	desc = "Used to control the Solar Federation Destroyer."
	req_access = list(ACCESS_SYNDICATE)
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/solfed/destroyer
	shuttleId = "solfed_destroyer"
	possible_destinations = "syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;solfed_destroyer_custom;whiteship_z4"

/obj/machinery/computer/camera_advanced/shuttle_docker/solfed/destroyer
	name = "Solar Federation Destroyer Computer"
	desc = "Used to designate a precise transit location for the Solar Federation Destroyer."
	shuttleId = "solfed_destroyer"
	lock_override = NONE
	shuttlePortId = "solfed_destroyer_custom"
	jump_to_ports = list("ds2_syndicate" = 1, "whiteship_home" = 1)
	view_range = 5.5
	x_offset = 7
	y_offset = 1
	space_turfs_only = FALSE

/area/shuttle/solfed/frigate
	name = "Solar Federation Battle Frigate"

/obj/item/circuitboard/computer/solfed/frigate
	build_path = /obj/machinery/computer/shuttle/solfed/frigate

/obj/machinery/computer/shuttle/solfed/frigate
	name = "Solar Federation Battle Frigate Console"
	desc = "Used to control the Solar Federation Battle Frigate."
	req_access = list(ACCESS_SYNDICATE)
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/solfed/frigate
	shuttleId = "solfed_frigate"
	possible_destinations = "syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;solfed_frigate_custom;whiteship_z4"

/obj/machinery/computer/camera_advanced/shuttle_docker/solfed/frigate
	name = "Solar Federation Battle Frigate Computer"
	desc = "Used to designate a precise transit location for the Solar Federation Battle Frigate."
	shuttleId = "solfed_frigate"
	lock_override = NONE
	shuttlePortId = "solfed_frigate_custom"
	jump_to_ports = list("ds2_syndicate" = 1, "whiteship_home" = 1)
	view_range = 5.5
	x_offset = 7
	y_offset = 1
	space_turfs_only = FALSE
