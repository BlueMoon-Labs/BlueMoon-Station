//Lifeweb Haron

/datum/map_template/shuttle/ruin/lf_haron
	prefix = "_maps/shuttles/bluemoon/"
	suffix = "lifeweb_haron"
	name = "Haron Shuttle"

/obj/machinery/computer/shuttle/lf_haron
	name = "Haron Control"
	desc = "Используется для полётов на Хароне."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/lf_haron
	shuttleId = "lf_haron"
	possible_destinations = "whiteship_home;lf_haron_custom"

/obj/item/circuitboard/computer/lf_haron
	name = "Haron Control Console (Computer Board)"
	build_path = /obj/machinery/computer/shuttle/lf_haron

/obj/machinery/computer/camera_advanced/shuttle_docker/lf_haron
	name = "Haron Navigation Computer"
	desc = "Навигационная консоль Харона."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "lf_haron"
	lock_override = NONE
	shuttlePortId = "lf_haron_custom"
	jump_to_ports = list("whiteship_away" = 1, "whiteship_home" = 1)
	view_range = 7
	x_offset = 0
	y_offset = 0

/area/shuttle/lf_haron
	name = "Haron"

//Golem's shuttle

/datum/map_template/shuttle/golems
	prefix = "_maps/RandomRuins/AnywhereRuins/"
	suffix = "golem_ship"
	name = "Shuttle 'Freedom'"

/obj/machinery/computer/shuttle/golems
	name = "Freedom Control"
	desc = "Используется для полётов на 'Свободе'."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/golems
	shuttleId = "golem_ship"
	possible_destinations = "whiteship_home;golems_custom"

/obj/item/circuitboard/computer/golems
	name = "Freedom Control Console (Computer Board)"
	build_path = /obj/machinery/computer/shuttle/golems

/obj/machinery/computer/camera_advanced/shuttle_docker/golems
	name = "Freedom Navigation Computer"
	desc = "Навигационная консоль 'Свободы'."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "golems"
	lock_override = NONE
	shuttlePortId = "golems_custom"
	jump_to_ports = list("whiteship_away" = 1, "whiteship_home" = 1)
	view_range = 7
	x_offset = 0
	y_offset = 0

/area/shuttle/golems
	name = "Freedom Shuttle"
