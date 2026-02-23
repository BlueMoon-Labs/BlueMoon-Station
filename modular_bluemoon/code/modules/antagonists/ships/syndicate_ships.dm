/area/shuttle/syndicate/fighter
	name = "Syndicate Fighter"

/obj/item/circuitboard/computer/syndicate/fighter
	build_path = /obj/machinery/computer/shuttle/syndicate/fighter

/obj/machinery/computer/shuttle/syndicate/fighter
	name = "Syndicate Fighter Console"
	desc = "Used to control the Syndicate Fighter."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	req_access = list(ACCESS_SYNDICATE)
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/syndicate/fighter
	shuttleId = "syndicate_fighter"
	possible_destinations = "syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;syndicate_fighter_custom;whiteship_z4"

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/fighter
	name = "Syndicate Fighter Computer"
	desc = "Used to designate a precise transit location for the Syndicate Fighter."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "syndicate_fighter"
	lock_override = NONE
	shuttlePortId = "syndicate_fighter_custom"
	jump_to_ports = list("ds2_syndicate" = 1, "whiteship_home" = 1)
	view_range = 5.5
	x_offset = 7
	y_offset = 1
	space_turfs_only = FALSE

/area/shuttle/syndicate/dropship
	name = "Syndicate Dropship"

/obj/item/circuitboard/computer/syndicate/dropship
	build_path = /obj/machinery/computer/shuttle/syndicate/dropship

/obj/machinery/computer/shuttle/syndicate/dropship
	name = "Syndicate Dropship Console"
	desc = "Used to control the Syndicate Dropship."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	req_access = list(ACCESS_SYNDICATE)
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/syndicate/dropship
	shuttleId = "syndicate_dropship"
	possible_destinations = "syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;syndicate_dropship_custom;whiteship_z4"

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/dropship
	name = "Syndicate Dropship Computer"
	desc = "Used to designate a precise transit location for the Syndicate Dropship."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "syndicate_dropship"
	lock_override = NONE
	shuttlePortId = "syndicate_dropship_custom"
	jump_to_ports = list("ds2_syndicate" = 1, "whiteship_home" = 1)
	view_range = 5.5
	x_offset = 7
	y_offset = 1
	space_turfs_only = FALSE

/area/shuttle/syndicate/frigate
	name = "Syndicate Battle Frigate"

/obj/item/circuitboard/computer/syndicate/frigate
	build_path = /obj/machinery/computer/shuttle/syndicate/frigate

/obj/machinery/computer/shuttle/syndicate/frigate
	name = "Syndicate Battle Frigate Console"
	desc = "Used to control the Syndicate Frigate."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	req_access = list(ACCESS_SYNDICATE)
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/syndicate/frigate
	shuttleId = "syndicate_frigate"
	possible_destinations = "syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;syndicate_frigate_custom;whiteship_z4"

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/frigate
	name = "Syndicate Frigate Computer"
	desc = "Used to designate a precise transit location for the Syndicate Frigate."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "syndicate_frigate"
	lock_override = NONE
	shuttlePortId = "syndicate_frigate_custom"
	jump_to_ports = list("ds2_syndicate" = 1, "whiteship_home" = 1)
	view_range = 5.5
	x_offset = 7
	y_offset = 1
	space_turfs_only = FALSE
