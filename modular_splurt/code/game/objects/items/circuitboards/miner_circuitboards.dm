///BlueMoon totally edited
// Legitimately putting this here because I want people to be able to build gas miners
// Pretty neat, right?

#define PATH_NITROMINER 	/obj/machinery/atmospherics/miner/nitrogen
#define PATH_OXYMINER  		/obj/machinery/atmospherics/miner/oxygen
#define PATH_PLASMAMINER 	/obj/machinery/atmospherics/miner/toxins
#define PATH_DIOMINER		/obj/machinery/atmospherics/miner/carbon_dioxide

/obj/item/circuitboard/machine/gas_miner
	name = "Gas Miner (Machine Board)"
	desc = "Плата газодобытчика, использующего газовый гигант и туманности неподалёку от станции для получения ценных газов."
	icon_state = "engineering"
	build_path = /obj/machinery/atmospherics/miner/nitrogen
	req_components = list(
		/obj/item/stock_parts/micro_laser = 10,	// I'm evil. Yes, 10.
		/obj/item/stack/cable_coil = 1,
		/obj/item/stock_parts/manipulator = 5,	// Yes, 5 of these.
		/obj/item/stock_parts/scanning_module = 5,	// You hear me last time
		ANOMALY_CORE_PYRO = 1
	)

/obj/item/circuitboard/machine/gas_miner/Initialize()
	. = ..()
	if (build_path)
		build_path = PATH_NITROMINER

/obj/item/circuitboard/machine/gas_miner/examine(mob/user)
	. = ..()
	. += span_notice("При помощи мультитула можно изменить вводные добычи определённых газов.")

/obj/item/circuitboard/machine/gas_miner/attackby(obj/item/I, mob/user, params)
	if (istype(I, /obj/item/multitool))
		var/obj/item/circuitboard/new_type
		var/new_setting
		switch(build_path)
			if (PATH_NITROMINER)
				new_type = /obj/item/circuitboard/machine/gas_miner/oxygen
				new_setting = "кислорода"
			if (PATH_OXYMINER)
				new_type = /obj/item/circuitboard/machine/gas_miner/toxin
				new_setting = "плазмы"
			if (PATH_PLASMAMINER)
				new_type = /obj/item/circuitboard/machine/gas_miner/carbon_dioxide
				new_setting = "углекислого газа"
			if (PATH_DIOMINER)
				new_type = /obj/item/circuitboard/machine/gas_miner/nitrogen
				new_setting = "азота"
		name = initial(new_type.name)
		build_path = initial(new_type.build_path)
		I.play_tool_sound(src)
		to_chat(user, span_notice("Вы настроили сканнеры газодобытчика на поиск [new_setting]."))
	else
		return ..()

/obj/item/circuitboard/machine/gas_miner/nitrogen
	name = "Nitrogen Gas Miner (Machine Board)"
	build_path = PATH_NITROMINER

/obj/item/circuitboard/machine/gas_miner/oxygen
	name = "Oxygen Gas Miner (Machine Board)"
	build_path = PATH_OXYMINER

/obj/item/circuitboard/machine/gas_miner/toxin
	name = "Plasma Gas Miner (Machine Board)"
	build_path = PATH_PLASMAMINER

/obj/item/circuitboard/machine/gas_miner/carbon_dioxide
	name = "Carbon Dioxide Gas Miner (Machine Board)"
	build_path = PATH_DIOMINER
