// Port Tarkon Atmos Control

/obj/machinery/air_sensor/tarkon
	name = "gas sensor"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "gsensor1"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 0)

/obj/machinery/computer/atmos_control/tarkon
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon

/obj/item/circuitboard/computer/atmos_control/tarkon
	name = "Tarkov Atmospheric Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon

/obj/machinery/computer/atmos_control/tarkon/oxygen_tank
	name = "Tarkov Oxygen Supply Control"
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon/oxygen_tank
	sensors = list(ATMOS_GAS_MONITOR_TARKOFF_O2 = "Oxygen Supply")

/obj/item/circuitboard/computer/atmos_control/tarkon/oxygen_tank
	name = "Tarkov Oxygen Supply Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon/oxygen_tank

/obj/machinery/air_sensor/tarkon/oxygen_tank
	name = "oxygen tank gas sensor"
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_O2

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/oxygen_input/tarkon
	id = ATMOS_GAS_MONITOR_TARKOFF_O2

/obj/machinery/atmospherics/components/unary/vent_pump/siphon/atmos/oxygen_output/tarkon
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_O2

/obj/machinery/computer/atmos_control/tarkon/plasma_tank
	name = "Tarkov Plasma Supply Control"
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon/plasma_tank
	sensors = list(ATMOS_GAS_MONITOR_TARKOFF_PLAS = "Plasma Supply")

/obj/item/circuitboard/computer/atmos_control/tarkon/plasma_tank
	name = "Tarkov Plasma Supply Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon/plasma_tank

/obj/machinery/air_sensor/tarkon/plasma_tank
	name = "plasma tank gas sensor"
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_PLAS

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/toxin_input/tarkon
	id = ATMOS_GAS_MONITOR_TARKOFF_PLAS

/obj/machinery/atmospherics/components/unary/vent_pump/siphon/atmos/toxin_output/tarkon
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_PLAS

/obj/machinery/computer/atmos_control/tarkon/mix_tank
	name = "Tarkov Mix Chamber Control"
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon/mix_tank
	sensors = list(ATMOS_GAS_MONITOR_TARKOFF_MIX = "Mix Chamber")

/obj/item/circuitboard/computer/atmos_control/tarkon/mix_tank
	name = "Tarkov Gas Mix Supply Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon/mix_tank

/obj/machinery/air_sensor/tarkon/mix_tank
	name = "mix tank gas sensor"
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_MIX

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/air_input/tarkon
	id = ATMOS_GAS_MONITOR_TARKOFF_MIX

/obj/machinery/atmospherics/components/unary/vent_pump/high_volume/siphon/atmos/air_output/tarkon
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_MIX

/obj/machinery/computer/atmos_control/tarkon/nitrogen_tank
	name = "Tarkov Nitrogen Supply Control"
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon/nitrogen_tank
	sensors = list(ATMOS_GAS_MONITOR_TARKOFF_N2 = "Nitrogen Supply")

/obj/item/circuitboard/computer/atmos_control/tarkon/nitrogen_tank
	name = "Tarkov Nitrogen Supply Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon/nitrogen_tank

/obj/machinery/air_sensor/tarkon/nitrogen_tank
	name = "nitrogen tank gas sensor"
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_N2

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/nitrogen_input/tarkon
	id = ATMOS_GAS_MONITOR_TARKOFF_N2

/obj/machinery/atmospherics/components/unary/vent_pump/siphon/atmos/nitrogen_output/tarkon
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_N2

/obj/machinery/computer/atmos_control/tarkon/nitrous_tank
	name = "Tarkov Nitrous Oxide Supply Control"
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon/nitrous_tank
	sensors = list(ATMOS_GAS_MONITOR_TARKOFF_N2O = "Nitrous Oxide Supply")

/obj/item/circuitboard/computer/atmos_control/tarkon/nitrous_tank
	name = "Tarkov Nitrous Oxide Supply Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon/nitrous_tank

/obj/machinery/air_sensor/tarkon/nitrous_tank
	name = "nitrous oxide tank gas sensor"
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_N2O

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/nitrous_input/tarkon
	id = ATMOS_GAS_MONITOR_TARKOFF_N2O

/obj/machinery/atmospherics/components/unary/vent_pump/siphon/atmos/nitrous_output/tarkon
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_N2O

/obj/machinery/computer/atmos_control/tarkon/carbon_tank
	name = "Tarkov Carbon Dioxide Supply Control"
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon/carbon_tank
	sensors = list(ATMOS_GAS_MONITOR_TARKOFF_CO2 = "Carbon Dioxide Supply")

/obj/item/circuitboard/computer/atmos_control/tarkon/carbon_tank
	name = "Tarkov Carbon Dioxide Supply Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon/carbon_tank

/obj/machinery/air_sensor/tarkon/carbon_tank
	name = "carbon dioxide tank gas sensor"
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_CO2

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/carbon_input/tarkon
	id = ATMOS_GAS_MONITOR_TARKOFF_CO2

/obj/machinery/atmospherics/components/unary/vent_pump/siphon/atmos/carbon_output/tarkon
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_CO2

/obj/machinery/computer/atmos_control/tarkon/incinerator
	name = "Tarkov Incinerator Chamber Control"
	circuit = /obj/item/circuitboard/computer/atmos_control/tarkon/incinerator
	sensors = list(ATMOS_GAS_MONITOR_TARKOFF_INCINERATOR = "Incinerator Chamber")

/obj/item/circuitboard/computer/atmos_control/tarkon/incinerator
	name = "Tarkov Incinerator Chamber Control"
	build_path = /obj/machinery/computer/atmos_control/tarkon/incinerator

/obj/machinery/air_sensor/tarkon/incinerator_tank
	name = "incinerator chamber gas sensor"
	id_tag = ATMOS_GAS_MONITOR_TARKOFF_INCINERATOR

/obj/machinery/airlock_sensor/incinerator_tarkon
	id_tag = INCINERATOR_TARKOFF_AIRLOCK_SENSOR
	master_tag = INCINERATOR_TARKOFF_AIRLOCK_CONTROLLER

/obj/machinery/door/airlock/public/glass/incinerator/tarkon_interior
	name = "Turbine Interior Airlock"
	id_tag = INCINERATOR_TARKOFF_AIRLOCK_INTERIOR

/obj/machinery/door/airlock/public/glass/incinerator/tarkon_exterior
	name = "Turbine Exterior Airlock"
	id_tag = INCINERATOR_TARKOFF_AIRLOCK_EXTERIOR

/obj/machinery/embedded_controller/radio/airlock_controller/incinerator_tarkon
	name = "Incinerator Access Console"
	airpump_tag = INCINERATOR_TARKOFF_DP_VENTPUMP
	exterior_door_tag = INCINERATOR_TARKOFF_AIRLOCK_EXTERIOR
	id_tag = INCINERATOR_TARKOFF_AIRLOCK_CONTROLLER
	interior_door_tag = INCINERATOR_TARKOFF_AIRLOCK_INTERIOR
	sanitize_external = TRUE
	sensor_tag = INCINERATOR_TARKOFF_AIRLOCK_SENSOR

/obj/machinery/atmospherics/components/binary/dp_vent_pump/high_volume/incinerator_tarkon
	id = INCINERATOR_TARKOFF_DP_VENTPUMP

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/incinerator_input/tarkon
	id = ATMOS_GAS_MONITOR_TARKOFF_INCINERATOR

/obj/machinery/igniter/incinerator_tarkon
	id = INCINERATOR_TARKOFF_IGNITER

/obj/machinery/button/ignition/incinerator/tarkon
	id = INCINERATOR_TARKOFF_IGNITER
