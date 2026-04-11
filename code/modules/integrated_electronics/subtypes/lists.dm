//These circuits do things with lists, and use special list pins for stability.
/obj/item/integrated_circuit/lists
	complexity = 1
	inputs = list(
		"ввод" = IC_PINTYPE_LIST
		)
	outputs = list(
		"результат" = IC_PINTYPE_STRING
		)
	activators = list(
		"вычислить" = IC_PINTYPE_PULSE_IN,
		"при вычислении" = IC_PINTYPE_PULSE_OUT
		)
	category_text = "Списки"
	power_draw_per_use = 20
	cooldown_per_use = 1

/obj/item/integrated_circuit/lists/pick
	name = "pick circuit"
	desc = "Эта схема выберет случайный элемент из входного списка и выведет его."
	extended_desc = "The input list is not modified."
	icon_state = "addition"
	outputs = list(
		"результат" = IC_PINTYPE_ANY
		)
	activators = list(
		"вычислить" = IC_PINTYPE_PULSE_IN,
		"при успехе" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT,
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	cooldown_per_use = 1

/obj/item/integrated_circuit/lists/pick/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1) // List pins guarantee that there is a list inside, even if just an empty one.
	if(input_list.len)
		set_pin_data(IC_OUTPUT, 1, pick(input_list))
		push_data()
		activate_pin(2)
	else
		activate_pin(3)


/obj/item/integrated_circuit/lists/append
	name = "append circuit"
	desc = "Эта схема добавит элемент в список."
	extended_desc = "Новый элемент всегда будет находиться в конце списка."
	inputs = list(
		"список для добавления" = IC_PINTYPE_LIST,
		"ввод" = IC_PINTYPE_ANY
		)
	outputs = list(
		"добавленный список" = IC_PINTYPE_LIST
		)
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/lists/append/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/list/output_list = list()
	var/new_entry = get_pin_data(IC_INPUT, 2)
	output_list = input_list.Copy()
	output_list.Add(new_entry)

	set_pin_data(IC_OUTPUT, 1, output_list)
	push_data()
	activate_pin(2)


/obj/item/integrated_circuit/lists/search
	name = "search circuit"
	desc = "Эта схема определяет индекс нужного элемента в списке."
	extended_desc = "Поиск начнется с позиции 1 и вернет первую найденную позицию."
	inputs = list(
		"список" = IC_PINTYPE_LIST,
		"нужный объект" = IC_PINTYPE_ANY
		)
	outputs = list(
		"индекс" = IC_PINTYPE_NUMBER
		)
	activators = list(
		"вычислить" = IC_PINTYPE_PULSE_IN,
		"при успехе" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT,
		)
	icon_state = "addition"
	complexity = 2
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	cooldown_per_use = 1

/obj/item/integrated_circuit/lists/search/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/output = input_list.Find(get_pin_data(IC_INPUT, 2))

	set_pin_data(IC_OUTPUT, 1, output)
	push_data()

	if(output)
		activate_pin(2)
	else
		activate_pin(3)


/obj/item/integrated_circuit/lists/filter
	name = "filter circuit"
	desc = "Эта схема просматривает список в поисках элементов, соответствующих заданным критериям, и выводит два списка: \
    один, содержащий только найденные элементы, и другой, из которого эти элементы были удалены."
	extended_desc = "Образец принимает списки. Если совпадений не найдено, исходный список выводится на выход 1."
	inputs = list(
		"вводный список" = IC_PINTYPE_LIST,
		"образец" = IC_PINTYPE_ANY
		)
	outputs = list(
		"отфильтрованный список" = IC_PINTYPE_LIST,
		"совпадающий список" = IC_PINTYPE_LIST
		)
	activators = list(
		"вычислить" = IC_PINTYPE_PULSE_IN,
		"при совпадении" = IC_PINTYPE_PULSE_OUT,
		"при отсутствии совпадений" = IC_PINTYPE_PULSE_OUT
		)
	complexity = 6
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/lists/filter/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/sample = get_pin_data(IC_INPUT, 2)
	var/list/sample_list = islist(sample) ? uniqueList(sample) : null
	var/list/output_list1 = input_list.Copy()
	var/list/output_list2 = list()
	var/list/output = list()

	for(var/input_item in input_list)
		if(sample_list)
			for(var/sample_item in sample_list)
				if(!isnull(sample_item))
					if(istext(input_item) && istext(sample_item) && findtext(input_item, sample_item))
						output += input_item
					if(istype(input_item, /atom) && istext(sample_item))
						var/atom/input_item_atom = input_item
						if(istext(sample_item) && findtext(input_item_atom.name, sample_item))
							output += input_item
				if(!istext(input_item))
					if(input_item == sample_item)
						output += input_item
		else
			if(!isnull(sample))
				if(istext(input_item) && istext(sample) && findtext(input_item, sample))
					output += input_item
					continue
				if(istype(input_item, /atom) && istext(sample))
					var/atom/input_itema = input_item
					if(findtext(input_itema.name, sample))
						output += input_item
			if(!istext(input_item))
				if(input_item == sample)
					output += input_item

	output_list1.Remove(output)
	output_list2.Add(output)
	set_pin_data(IC_OUTPUT, 1, output_list1)
	set_pin_data(IC_OUTPUT, 2, output_list2)
	push_data()

	output_list1 ~! input_list ? activate_pin(2) : activate_pin(3)

/obj/item/integrated_circuit/lists/listset
	name = "list set circuit"
	desc = "Эта схема удалит из списка все повторяющиеся записи."
	extended_desc = "Если дубликатов нет, список в выводе останется без изменений."
	inputs = list(
		"список" = IC_PINTYPE_LIST
		)
	outputs = list(
		"отфильтрованный список" = IC_PINTYPE_LIST
		)
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/lists/listset/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	input_list = uniqueList(input_list)

	set_pin_data(IC_OUTPUT, 1, input_list)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/lists/at
	name = "at circuit"
	desc = "Эта схема выбирает элемент из списка по указанному индексу."
	extended_desc = "Если по указанному индексу элемент отсутствует, результатом будет null."
	inputs = list(
		"список" = IC_PINTYPE_LIST,
		"индекс" = IC_PINTYPE_INDEX
		)
	outputs = list(
		"элемент" = IC_PINTYPE_ANY
		)
	activators = list(
		"вычислить" = IC_PINTYPE_PULSE_IN,
		"при успехе" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT
		)
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	cooldown_per_use = 1

/obj/item/integrated_circuit/lists/at/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/index = get_pin_data(IC_INPUT, 2)

	if(!length(input_list) || !isnum(index) || index < 1 || index > length(input_list))
		set_pin_data(IC_OUTPUT, 1, null)
		push_data()
		activate_pin(3)
		return

	set_pin_data(IC_OUTPUT, 1, input_list[index])
	push_data()
	activate_pin(2)


/obj/item/integrated_circuit/lists/delete
	name = "delete circuit"
	desc = "Эта схема удаляет элемент из списка по индексу."
	extended_desc = "Если по указанному индексу элемента нет, выходной список останется без изменений."
	inputs = list(
		"список" = IC_PINTYPE_LIST,
		"индекс" = IC_PINTYPE_INDEX
		)
	outputs = list(
		"выходной список" = IC_PINTYPE_LIST
		)
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/lists/delete/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/list/red_list = list()
	var/index = get_pin_data(IC_INPUT, 2)

	if(length(input_list))
		for(var/j in 1 to input_list.len)
			var/I = input_list[j]
			if(j != index)
				red_list.Add(I)
	set_pin_data(IC_OUTPUT, 1, red_list)
	push_data()
	activate_pin(2)


/obj/item/integrated_circuit/lists/write
	name = "write circuit"
	desc = "Эта схема записывает элемент в список по указанному индексу."
	extended_desc = "Если по указанному индексу элемента нет, то будет выведен тот же список, что и раньше."
	inputs = list(
		"список" = IC_PINTYPE_LIST,
		"индекс" = IC_PINTYPE_INDEX,
		"элемент" = IC_PINTYPE_ANY
		)
	outputs = list(
		"отредактированный список" = IC_PINTYPE_LIST
		)
	activators = list(
		"вычислить" = IC_PINTYPE_PULSE_IN,
		"при успехе" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT,
		)
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/lists/write/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/index = get_pin_data(IC_INPUT, 2)
	var/item = get_pin_data(IC_INPUT, 3)

	if(!length(input_list) || !isnum(index) || index < 1 || index > length(input_list))
		set_pin_data(IC_OUTPUT, 1, input_list)
		push_data()
		activate_pin(3)
		return

	if(!islist(item))
		var/list/red_list = input_list.Copy()			//crash proof
		red_list[index] = item
		set_pin_data(IC_OUTPUT, 1, red_list)
		push_data()
		activate_pin(2)


/obj/item/integrated_circuit/lists/len
	name = "len circuit"
	desc = "Эта схема вернет длину списка."
	inputs = list(
		"список" = IC_PINTYPE_LIST,
		)
	outputs = list(
		"длина списка" = IC_PINTYPE_NUMBER
		)
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/lists/len/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	set_pin_data(IC_OUTPUT, 1, input_list.len)
	push_data()
	activate_pin(2)
	cooldown_per_use = 1


/obj/item/integrated_circuit/lists/jointext
	name = "join text circuit"
	desc = "Эта схема объединит два списка в один и выведет его в виде строки."
	extended_desc = "По умолчанию весь список будет преобразован в строку."
	icon_state = "join"
	inputs = list(
		"список для присоединения" = IC_PINTYPE_LIST,//
		"разделитель" = IC_PINTYPE_STRING,
		"начало" = IC_PINTYPE_INDEX,
		"конец" = IC_PINTYPE_NUMBER
		)
	inputs_default = list(
		"2" = ", ",
		"4" = 0
		)
	outputs = list(
		"присоединенный текст" = IC_PINTYPE_STRING
		)
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	cooldown_per_use = 1

/obj/item/integrated_circuit/lists/jointext/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/delimiter = get_pin_data(IC_INPUT, 2)
	var/start = get_pin_data(IC_INPUT, 3)
	var/end = get_pin_data(IC_INPUT, 4)

	var/result = null

	if(input_list.len && delimiter && !isnull(start) && !isnull(end))
		result = jointext(input_list, delimiter, start, end)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)


/obj/item/integrated_circuit/lists/constructor
	name = "large list constructor"
	desc = "Эта схема формирует список из не более шестнадцати входных значений."
	icon_state = "constr8"
	inputs = list()
	outputs = list(
		"результат" = IC_PINTYPE_LIST
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/number_of_pins = 16

/obj/item/integrated_circuit/lists/constructor/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		inputs["ввод [i]"] = IC_PINTYPE_ANY // This is just a string since pins don't get built until ..() is called.
	complexity = number_of_pins / 2
	. = ..()

/obj/item/integrated_circuit/lists/constructor/do_work()
	var/list/output_list = list()
	for(var/i = 1 to number_of_pins)
		var/data = get_pin_data(IC_INPUT, i)

		// No nested lists
		if(!islist(data))
			output_list += data
		else
			output_list += null

	set_pin_data(IC_OUTPUT, 1, output_list)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/lists/constructor/small
	name = "list constructor"
	desc = "Эта схема сформирует список из не более четырёх входных значений."
	icon_state = "constr"
	number_of_pins = 4

/obj/item/integrated_circuit/lists/constructor/medium
	name = "medium list constructor"
	desc = "Эта схема сформирует список из не более восьми входных значений."
	icon_state = "constr8"
	number_of_pins = 8


/obj/item/integrated_circuit/lists/deconstructor
	name = "large list deconstructor"
	desc = "Эта схема запишет первые шестнадцать элементов входного списка, начиная с указанного индекса, в ячейки выходных значений."
	icon_state = "deconstr8"
	inputs = list(
		"входной список" = IC_PINTYPE_LIST,
		"индекс" = IC_PINTYPE_INDEX
		)
	outputs = list()
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/number_of_pins = 16

/obj/item/integrated_circuit/lists/deconstructor/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		outputs["вывод [i]"] = IC_PINTYPE_ANY // This is just a string since pins don't get built until ..() is called.
	complexity = number_of_pins / 2
	. = ..()

/obj/item/integrated_circuit/lists/deconstructor/do_work()
	var/list/input_list = get_pin_data(IC_INPUT, 1)
	var/start_index = get_pin_data(IC_INPUT, 2)

	for(var/i = 1 to number_of_pins)
		var/list_index = i + start_index - 1
		if(list_index < 1 || list_index > input_list.len)
			set_pin_data(IC_OUTPUT, i, null)
		else
			set_pin_data(IC_OUTPUT, i, input_list[list_index])

	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/lists/deconstructor/small
	name = "list deconstructor"
	desc = "Эта схема запишет первые четыре элемента входного списка, начиная с указанного индекса, в ячейки выходных значений."
	icon_state = "deconstr"
	number_of_pins = 4

/obj/item/integrated_circuit/lists/deconstructor/medium
	name = "medium list deconstructor"
	desc = "Эта схема запишет первые восемь элементов входного списка, начиная с указанного индекса, в ячейки выходных значений."
	number_of_pins = 8
