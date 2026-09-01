/obj/machinery/atmospherics/components/binary
	icon = 'icons/obj/atmospherics/components/binary_devices.dmi'
	dir = SOUTH
	initialize_directions = SOUTH|NORTH
	use_power = IDLE_POWER_USE
	device_type = BINARY
	layer = GAS_PUMP_LAYER

/obj/machinery/atmospherics/components/binary/ui_port_labels()
	return list("Вход", "Выход")

/obj/machinery/atmospherics/components/binary/SetInitDirections()
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = NORTH|SOUTH
		if(EAST, WEST)
			initialize_directions = EAST|WEST

/obj/machinery/atmospherics/components/binary/hide(intact)
	update_icon()
	..()

/obj/machinery/atmospherics/components/binary/getNodeConnects()
	return list(turn(dir, 180), dir)

/// В импортированном листе у каждого корпуса сенсорного клапана два варианта,
/// разнесённые на восемь пикселей вдоль трубы. С мапспрайтом и подложкой трубы
/// совпадает только второй; первый уезжает вниз и упирается индикатором в самый
/// край тайла.
///
/// К слою прокладки выбор отношения не имеет: слой уже отрабатывает
/// PIPING_LAYER_SHIFT на самой машине, и корпус вместе с подложками уезжает в
/// свою полосу целиком. Прежний выбор по чётности слоя означал, что на слоях
/// 1, 3 и 5 - включая слой по умолчанию - рисовался именно сдвинутый вариант.
#define SENSOR_VALVE_BODY_OFFSET 2
