/obj/item/integrated_circuit/transfer
	category_text = "Передача данных"
	power_draw_per_use = 2

/obj/item/integrated_circuit/transfer/multiplexer
	name = "two multiplexer"
	desc = "В профессиональной среде это устройство обычно называют 'мультиплексором' или селектором данных. Оно передает данные с одного из выбранных входов на выход."
	extended_desc = "Первый входной пин используется для выбора того из остальных входных пинов, данные с которого будут переданы на выход. \
    Если выбранный вход находится за пределами допустимого диапазона, выходные данные не передаются."
	complexity = 2
	icon_state = "mux2"
	inputs = list("выбор ввода" = IC_PINTYPE_NUMBER)
	outputs = list("вывод" = IC_PINTYPE_ANY)
	activators = list("выбрать" = IC_PINTYPE_PULSE_IN, "при выборе" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4
	var/number_of_pins = 2

/obj/item/integrated_circuit/transfer/multiplexer/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		inputs["ввод [i]"] = IC_PINTYPE_ANY // This is just a string since pins don't get built until ..() is called.

	complexity = number_of_pins
	. = ..()
	desc += " Он имеет [number_of_pins] входных пинов."
	extended_desc += " Диапазон этого мультиплексора составляет от 1 до [inputs.len - 1]."

/obj/item/integrated_circuit/transfer/multiplexer/do_work()
	var/input_index = get_pin_data(IC_INPUT, 1)

	if(!isnull(input_index) && (input_index >= 1 && input_index < inputs.len))
		set_pin_data(IC_OUTPUT, 1,get_pin_data(IC_INPUT, input_index + 1))
		push_data()
	activate_pin(2)

/obj/item/integrated_circuit/transfer/multiplexer/medium
	name = "four multiplexer"
	icon_state = "mux4"
	number_of_pins = 4

/obj/item/integrated_circuit/transfer/multiplexer/large
	name = "eight multiplexer"
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "mux8"
	number_of_pins = 8

/obj/item/integrated_circuit/transfer/multiplexer/huge
	name = "sixteen multiplexer"
	icon_state = "mux16"
	w_class = WEIGHT_CLASS_SMALL
	number_of_pins = 16

/obj/item/integrated_circuit/transfer/demultiplexer
	name = "two demultiplexer"
	desc = "В профессиональной среде это обычно называют «демультиплексором». Он перенаправляет данные с входа на один из выбранных выходов."
	extended_desc = "Первый входной пин используется для выбора того, на какой из выходных пинов будут передаваться данные со второго входного пина. \
    Если выбранный выход находится за пределами допустимого диапазона, выходной сигнал не подается."
	complexity = 2
	icon_state = "dmux2"
	inputs = list("выбор вывода" = IC_PINTYPE_NUMBER, "ввод" = IC_PINTYPE_ANY)
	outputs = list()
	activators = list("выбрать" = IC_PINTYPE_PULSE_IN, "при выборе" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4
	var/number_of_pins = 2

/obj/item/integrated_circuit/transfer/demultiplexer/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		outputs["вывод [i]"] = IC_PINTYPE_ANY
	complexity = number_of_pins

	. = ..()
	desc += " Он имеет [number_of_pins] выходных пинов."
	extended_desc += " Этот демультиплексор имеет диапазон от 1 до [outputs.len]."

/obj/item/integrated_circuit/transfer/demultiplexer/do_work()
	var/output_index = get_pin_data(IC_INPUT, 1)
	if(!isnull(output_index) && (output_index >= 1 && output_index <= outputs.len))
		var/datum/integrated_io/O = outputs[output_index]
		O.data = get_pin_data(IC_INPUT, 2)
		O.push_data()

	activate_pin(2)

/obj/item/integrated_circuit/transfer/demultiplexer/medium
	name = "four demultiplexer"
	icon_state = "dmux4"
	number_of_pins = 4

/obj/item/integrated_circuit/transfer/demultiplexer/large
	name = "eight demultiplexer"
	icon_state = "dmux8"
	w_class = WEIGHT_CLASS_SMALL
	number_of_pins = 8

/obj/item/integrated_circuit/transfer/demultiplexer/huge
	name = "sixteen demultiplexer"
	icon_state = "dmux16"
	w_class = WEIGHT_CLASS_SMALL
	number_of_pins = 16

/obj/item/integrated_circuit/transfer/pulsedemultiplexer
	name = "two pulse demultiplexer"
	desc = "Селекторный переключатель для выбора пина, который необходимо активировать по номеру."
	extended_desc = "Первый входной пин используется для выбора того, какой из выводов импульсного выхода будет активирован после включения схемы. \
    Если выбранный выход находится за пределами допустимого диапазона, выходной сигнал не подается."
	complexity = 2
	icon_state = "dmux2"
	inputs = list("выбор вывода" = IC_PINTYPE_NUMBER)
	outputs = list()
	activators = list("выбрать" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4
	var/number_of_pins = 2

/obj/item/integrated_circuit/transfer/pulsedemultiplexer/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		activators["вывод [i]"] = IC_PINTYPE_PULSE_OUT
	complexity = number_of_pins

	. = ..()
	desc += " Он имеет [number_of_pins] выходных пинов."
	extended_desc += " Диапазон этого импульсного демультиплексора составляет от 1 до [activators.len - 1]."

/obj/item/integrated_circuit/transfer/pulsedemultiplexer/do_work()
	var/output_index = get_pin_data(IC_INPUT, 1)

	if(output_index == clamp(output_index, 1, number_of_pins))
		activate_pin(round(output_index + 1 ,1))

/obj/item/integrated_circuit/transfer/pulsedemultiplexer/medium
	name = "four pulse demultiplexer"
	icon_state = "dmux4"
	number_of_pins = 4

/obj/item/integrated_circuit/transfer/pulsedemultiplexer/large
	name = "eight pulse demultiplexer"
	icon_state = "dmux8"
	w_class = WEIGHT_CLASS_SMALL
	number_of_pins = 8

/obj/item/integrated_circuit/transfer/pulsedemultiplexer/huge
	name = "sixteen pulse demultiplexer"
	icon_state = "dmux16"
	w_class = WEIGHT_CLASS_SMALL
	number_of_pins = 16

/obj/item/integrated_circuit/transfer/pulsemultiplexer
	name = "two pulse multiplexer"
	desc = "Пульсируйте пины, чтобы выбрать значение, которое нужно отправить."
	extended_desc = "Входные импульсы используются для выбора того, данные с какого из входных пинов будут переданы на выход."
	complexity = 2
	icon_state = "dmux2"
	inputs = list()
	outputs = list("вывод" = IC_PINTYPE_ANY)
	activators = list("при выборе" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4
	var/number_of_pins = 2

/obj/item/integrated_circuit/transfer/pulsemultiplexer/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		inputs["ввод [i]"] = IC_PINTYPE_ANY
	for(var/i = 1 to number_of_pins)
		activators["ввод [i]"] = IC_PINTYPE_PULSE_IN
	complexity = number_of_pins

	. = ..()
	desc += " Он имеет [number_of_pins] импульсных пинов и [number_of_pins] входных пинов."
	extended_desc += " Диапазон этого импульсного мультиплексора составляет от 1 до [activators.len - 1]."

/obj/item/integrated_circuit/transfer/pulsemultiplexer/do_work(ord)
	var/input_index = ord - 2

	if(!isnull(input_index) && (input_index >= 0 && input_index < inputs.len))
		set_pin_data(IC_OUTPUT, 1,get_pin_data(IC_INPUT, input_index + 1))
		push_data()
	activate_pin(1)

/obj/item/integrated_circuit/transfer/pulsemultiplexer/medium
	name = "four pulse multiplexer"
	icon_state = "dmux4"
	number_of_pins = 4

/obj/item/integrated_circuit/transfer/pulsemultiplexer/large
	name = "eight pulse multiplexer"
	icon_state = "dmux8"
	w_class = WEIGHT_CLASS_SMALL
	number_of_pins = 8

/obj/item/integrated_circuit/transfer/pulsemultiplexer/huge
	name = "sixteen pulse multiplexer"
	icon_state = "dmux16"
	w_class = WEIGHT_CLASS_SMALL
	number_of_pins = 16

/obj/item/integrated_circuit/transfer/wire_node
	name = "wire node"
	desc = "Просто соединительный узел, облегчающий прокладку проводов. Передает импульс с входа на выход."
	icon_state = "wire_node"
	activators = list("вход импульса" = IC_PINTYPE_PULSE_IN, "выход импульса" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 0
	complexity = 0
	size = 0.1

/obj/item/integrated_circuit/transfer/wire_node/do_work()
	activate_pin(2)
