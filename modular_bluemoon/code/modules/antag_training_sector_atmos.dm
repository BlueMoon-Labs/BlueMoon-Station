/area/antag_training/sector/atmos
	name = "Training Atmos Sector"

/datum/antag_training_sector/atmos
	id = "atmos"
	name = "Атмос"
	desc = "Атмосферный цех «Пневма»: трубы окрашены по газам и подписаны у портов, смеситель и фильтр, канистры газов, вентиляции и скрубберы, пожарные шлюзы, зал пробоев с вакуумной камерой. Сброс сектора возвращает воздух."
	map_path = "_maps/templates/antag_training/atmos.dmm"
	area_type = /area/antag_training/sector/atmos
	origin_x = 126
	origin_y = 1
	spawn_offset = list(3, 14)
	target_offset = list(23, 14)

// Жёлтый спрайт пустой канистры среди подтипов занят proto, а делить спрайт можно только с предком.
/obj/machinery/portable_atmospherics/canister/proto/training
	name = /obj/machinery/portable_atmospherics/canister::name
	desc = /obj/machinery/portable_atmospherics/canister::desc
