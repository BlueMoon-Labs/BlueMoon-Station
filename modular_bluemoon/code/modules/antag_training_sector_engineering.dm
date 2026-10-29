/area/antag_training/sector/engineering
	name = "Training Engineering"
	requires_power = TRUE
	// При requires_power Initialize() не трогает свет, а родитель держит DISABLED - полный свет без ламп.
	dynamic_lighting = DYNAMIC_LIGHTING_ENABLED

/area/antag_training/sector/engineering/cable_room
	name = "Training Cable Room"

/obj/machinery/power/apc/highcap/ten_k/antag_training
	locked = FALSE
	start_charge = 100
	auto_name = TRUE

/obj/machinery/power/apc/highcap/ten_k/antag_training/cable_room
	start_charge = 0

/datum/antag_training_sector/engineering
	id = "engineering"
	name = "Инженерный сектор"
	desc = "Машинный зал «Гефест»: питание как на станции - SMES, APC, генератор P.A.C.M.A.N. на месте сгоревшего, солнечные панели, комната с неподключённым щитком под прокладку кабеля и взлом шлюзов."
	map_path = "_maps/templates/antag_training/engineering.dmm"
	area_type = /area/antag_training/sector/engineering
	origin_x = 91
	origin_y = 1
	spawn_offset = list(5, 25)
	target_offset = list(26, 18)
	/// Комната под прокладку - своя область со своим щитком, который не подключён к сети.
	var/area/antag_training/sector/cable_room

/datum/antag_training_sector/engineering/place(datum/antag_training_arena/owner)
	var/area/antag_training/sector/room_area = GLOB.areas_by_type[/area/antag_training/sector/engineering/cable_room] || new /area/antag_training/sector/engineering/cable_room
	room_area.arena = owner
	room_area.reset_state()
	cable_room = room_area
	return ..()

/datum/antag_training_sector/engineering/Destroy()
	var/datum/antag_training_arena/owner = arena
	. = ..()
	if(cable_room?.arena == owner)
		cable_room.arena = null
	cable_room = null
