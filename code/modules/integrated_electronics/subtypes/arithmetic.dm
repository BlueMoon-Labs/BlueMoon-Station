//These circuits do simple math.
/obj/item/integrated_circuit/arithmetic
	complexity = 1
	inputs = list(
		"A" = IC_PINTYPE_NUMBER,
		"B" = IC_PINTYPE_NUMBER,
		"C" = IC_PINTYPE_NUMBER,
		"D" = IC_PINTYPE_NUMBER,
		"E" = IC_PINTYPE_NUMBER,
		"F" = IC_PINTYPE_NUMBER,
		"G" = IC_PINTYPE_NUMBER,
		"H" = IC_PINTYPE_NUMBER
		)
	outputs = list("result" = IC_PINTYPE_NUMBER)
	activators = list("compute" = IC_PINTYPE_PULSE_IN, "on computed" = IC_PINTYPE_PULSE_OUT)
	category_text = "Arithmetic"
	power_draw_per_use = 5 // Math is pretty cheap.

// +Adding+ //

/obj/item/integrated_circuit/arithmetic/addition
	name = "addition circuit"
	desc = "Эта схема может складывать числа."
	extended_desc = "Порядок вычисления следующий: <br>\
    result = ((((A + B) + C) + D) ... ) и так далее, пока не будут сложены все пины. \
    Выводы с нулевым значением игнорируются."
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/addition/do_work()
	var/result = 0
	for(var/k in 1 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(isnum(I))
			result += I

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// -Subtracting- //

/obj/item/integrated_circuit/arithmetic/subtraction
	name = "subtraction circuit"
	desc = "Эта схема может вычитать числа."
	extended_desc = "Порядок вычислений следующий: <br>\
    result = ((((A - B) - C) - D) ... ) и так далее, пока не будут вычтены все пины. \
    Выводы с нулевым значением игнорируются.  Вывод A <b>должен</b> быть числом, иначе схема не будет работать."
	icon_state = "subtraction"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/subtraction/do_work()
	var/datum/integrated_io/A = inputs[1]
	if(!isnum(A.data))
		return
	var/result = A.data

	for(var/k in 2 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(isnum(I))
			result -= I

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// *Multiply* //

/obj/item/integrated_circuit/arithmetic/multiplication
	name = "multiplication circuit"
	desc = "Эта схема может умножать числа."
	extended_desc = "Порядок вычислений следующий: <br>\
    result = ((((A * B) * C) * D) ... ) и так далее, пока не будут умножены все пины. \
    Выводы с нулевым значением игнорируются. Вывод A <b>должен</b> быть числом, иначе схема не будет работать."
	icon_state = "multiplication"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH


/obj/item/integrated_circuit/arithmetic/multiplication/do_work()
	var/datum/integrated_io/A = inputs[1]
	if(!isnum(A.data))
		return
	var/result = A.data
	for(var/k in 2 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(isnum(I))
			result *= I

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// /Division/  //

/obj/item/integrated_circuit/arithmetic/division
	name = "division circuit"
	desc = "Эта схема умеет делить числа. Даже не думайте пробовать делить на ноль!"
	extended_desc = "Порядок вычислений следующий: <br>\
    result = ((((A / B) / C) / D) ... ) и так далее, пока не будут разделены все пины. \
    Выводы с нулевым значением и выводы, содержащие 0, игнорируются. Вывод A <b>должен</b> быть числом, иначе схема не будет работать."
	icon_state = "division"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/division/do_work()
	var/datum/integrated_io/A = inputs[1]
	if(!isnum(A.data))
		return
	var/result = A.data


	for(var/k in 2 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(isnum(I) && (I != 0))
			result /= I


	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

//^ Exponent ^//

/obj/item/integrated_circuit/arithmetic/exponent
	name = "exponent circuit"
	desc = "Выводит A в степени B."
	icon_state = "exponent"
	inputs = list("A" = IC_PINTYPE_NUMBER, "B" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/exponent/do_work()
	var/result = 0
	var/datum/integrated_io/A = inputs[1]
	var/datum/integrated_io/B = inputs[2]
	if(isnum(A.data) && isnum(B.data))
		result = A.data ** B.data

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// +-Sign-+ //

/obj/item/integrated_circuit/arithmetic/sign
	name = "sign circuit"
	desc = "Эта схема позволяет определить, является ли число положительным, отрицательным или равным нулю."
	extended_desc = "Выдаст 1, -1 или 0 в зависимости от того, является ли A положительным числом, отрицательным числом или нулем соответственно."
	icon_state = "sign"
	inputs = list("A" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/sign/do_work()
	var/result = 0
	var/datum/integrated_io/A = inputs[1]
	if(isnum(A.data))
		if(A.data > 0)
			result = 1
		else if (A.data < 0)
			result = -1
		else
			result = 0

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// Round //

/obj/item/integrated_circuit/arithmetic/round
	name = "round circuit"
	desc = "Округляет A до ближайшего кратного B числа."
	extended_desc = "Если для B не указано число, то вместо него будет выведено целое значение A, округленное в меньшую сторону."
	icon_state = "round"
	inputs = list("A" = IC_PINTYPE_NUMBER, "B" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/round/do_work()
	var/result = 0
	var/datum/integrated_io/A = inputs[1]
	var/datum/integrated_io/B = inputs[2]
	if(isnum(A.data))
		if(isnum(B.data) && B.data != 0)
			result = round(A.data, B.data)
		else
			result = round(A.data)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// Absolute //

/obj/item/integrated_circuit/arithmetic/absolute
	name = "absolute circuit"
	desc = "В результате выводится неотрицательная версия введенного числа. Это можно также рассматривать как его расстояние от нуля."
	icon_state = "absolute"
	inputs = list("A" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/absolute/do_work()
	var/result = 0
	for(var/k in 1 to inputs.len)
		var/datum/integrated_io/I = inputs[k]
		I.pull_data()
		if(isnum(I.data))
			result = abs(I.data)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// Averaging //

/obj/item/integrated_circuit/arithmetic/average
	name = "average circuit"
	desc = "Эта схема среднего качества. Она вычислит среднее значение введенных вами чисел."
	extended_desc = "Обратите внимание, что нулевые значения пинов игнорируются, тогда как пины со значением 0 учитываются при вычислении среднего значения."
	icon_state = "average"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/average/do_work()
	var/result = 0
	var/inputs_used = 0
	for(var/k in 2 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(isnum(I))
			inputs_used++
			result += I

	if(inputs_used)
		result = result / inputs_used

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// Pi, because why the hell not? //
/obj/item/integrated_circuit/arithmetic/pi
	name = "pi constant circuit"
	desc = "Не рекомендуется использовать для приготовления пищи. При получении импульса выдает '3,14159'."
	icon_state = "pi"
	inputs = list()
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/pi/Initialize(mapload)
	. = ..()
	desc = "Не рекомендуется использовать для приготовления пищи. При получении импульса выдает значение '[PI]'."

/obj/item/integrated_circuit/arithmetic/pi/do_work()
	set_pin_data(IC_OUTPUT, 1, PI)
	push_data()
	activate_pin(2)

// Random //
/obj/item/integrated_circuit/arithmetic/random
	name = "random number generator circuit"
	desc = "В результате получается случайное (целое) число в диапазоне от A до B включительно."
	extended_desc = "'Включая' означает, что верхняя граница входит в диапазон чисел; например, при L = 1 и H = 3 возможны \
    результаты 1, 2 или 3. То, что H является более большим числом, чем L, не является <i>строго</i> обязательным условием."
	icon_state = "random"
	inputs = list("L" = IC_PINTYPE_NUMBER,"H" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/random/do_work()
	var/result = 0
	var/L = get_pin_data(IC_INPUT, 1)
	var/H = get_pin_data(IC_INPUT, 2)

	if(isnum(L) && isnum(H))
		result = rand(L, H)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// Square Root //

/obj/item/integrated_circuit/arithmetic/square_root
	name = "square root circuit"
	desc = "Эта программа выводит квадратный корень из введенного вами числа."
	icon_state = "square_root"
	inputs = list("A" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/square_root/do_work()
	var/result = 0
	var/I = get_pin_data(IC_INPUT, 1)
	result = sqrt(I)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// % Modulo % //

/obj/item/integrated_circuit/arithmetic/modulo
	name = "modulo circuit"
	desc = "Возвращает остаток от деления A на B."
	icon_state = "modulo"
	inputs = list("A" = IC_PINTYPE_NUMBER, "B" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/arithmetic/modulo/do_work()
	var/result = 0
	var/A = get_pin_data(IC_INPUT, 1)
	var/B = get_pin_data(IC_INPUT, 2)
	if(isnum(A) && isnum(B) && B != 0)
		result = A % B

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// -Max- //
/obj/item/integrated_circuit/arithmetic/max
	name = "max circuit"
	desc = "Эта схема выдает наибольшее число."
	extended_desc = "Выводится наибольшее число. Нулевое значение игнорируется."
	icon_state = "addition"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/min_comparision = FALSE

/obj/item/integrated_circuit/arithmetic/max/do_work()
	var/result
	for(var/k in 1 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(!isnum(I))
			continue
		if(!isnum(result) || (!min_comparision && I > result) || (min_comparision && I < result))
			result = I
	if(!isnum(result))
		result = 0
	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

// -Min- //
/obj/item/integrated_circuit/arithmetic/max/min
	name = "min circuit"
	desc = "Эта схема выдает наименьшее число."
	extended_desc = "Выводится наименьшее число. Нулевое значение игнорируется. Если число не найдено, выводится 0."
	min_comparision = TRUE
