/obj/item/integrated_circuit/logic
	name = "logic gate"
	desc = "Этот крошечный чип решит за вас!"
	extended_desc = "Логические схемы будут рассматривать значение null, 0 и строку \"\" как FALSE, а все остальное как TRUE."
	complexity = 1
	outputs = list("результат" = IC_PINTYPE_BOOLEAN)
	activators = list("сравнить" = IC_PINTYPE_PULSE_IN)
	category_text = "Логика"
	power_draw_per_use = 1

/obj/item/integrated_circuit/logic/do_work()
	push_data()

/obj/item/integrated_circuit/logic/binary
	inputs = list("A" = IC_PINTYPE_ANY,"B" = IC_PINTYPE_ANY)
	activators = list("сравнить" = IC_PINTYPE_PULSE_IN, "при TRUE" = IC_PINTYPE_PULSE_OUT, "при FALSE" = IC_PINTYPE_PULSE_OUT)

/obj/item/integrated_circuit/logic/binary/do_work()
	var/datum/integrated_io/A = inputs[1]
	var/datum/integrated_io/B = inputs[2]
	var/datum/integrated_io/O = outputs[1]
	O.data = do_compare(A, B) ? TRUE : FALSE

	if(get_pin_data(IC_OUTPUT, 1))
		activate_pin(2)
	else
		activate_pin(3)
	..()

/obj/item/integrated_circuit/logic/binary/proc/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	return FALSE

/obj/item/integrated_circuit/logic/binary/proc/comparable(var/datum/integrated_io/A, var/datum/integrated_io/B)
	return (isnum(A.data) && isnum(B.data)) || (istext(A.data) && istext(B.data))

/obj/item/integrated_circuit/logic/unary
	inputs = list("A" = IC_PINTYPE_ANY)
	activators = list("сравнить" = IC_PINTYPE_PULSE_IN, "при сравнении" = IC_PINTYPE_PULSE_OUT)

/obj/item/integrated_circuit/logic/unary/do_work()
	var/datum/integrated_io/A = inputs[1]
	var/datum/integrated_io/O = outputs[1]
	O.data = do_check(A) ? TRUE : FALSE
	..()
	activate_pin(2)

/obj/item/integrated_circuit/logic/unary/proc/do_check(var/datum/integrated_io/A)
	return FALSE

/obj/item/integrated_circuit/logic/binary/equals
	name = "equal gate"
	desc = "Эта схема сравнивает два значения и выдает сигнал TRUE, если они совпадают."
	icon_state = "equal"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/equals/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	return A.data == B.data

/obj/item/integrated_circuit/logic/binary/jklatch
	name = "JK latch"
	desc = "Эта схема представляет собой синхронизированный триггер JK."
	icon_state = "jklatch"
	inputs = list("J" = IC_PINTYPE_ANY,"K" = IC_PINTYPE_ANY)
	outputs = list("Q" = IC_PINTYPE_BOOLEAN,"!Q" = IC_PINTYPE_BOOLEAN)
	activators = list("входящий импульс C" = IC_PINTYPE_PULSE_IN, "исходящий импульс Q" = IC_PINTYPE_PULSE_OUT, "исходящий импульс !Q" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/lstate=FALSE

/obj/item/integrated_circuit/logic/binary/jklatch/do_work()
	var/datum/integrated_io/A = inputs[1]
	var/datum/integrated_io/B = inputs[2]
	var/datum/integrated_io/O = outputs[1]
	var/datum/integrated_io/Q = outputs[2]
	if(A.data)
		if(B.data)
			lstate=!lstate
		else
			lstate = TRUE
	else
		if(B.data)
			lstate=FALSE
	O.data = lstate ? TRUE : FALSE
	Q.data = !lstate ? TRUE : FALSE
	if(get_pin_data(IC_OUTPUT, 1))
		activate_pin(2)
	else
		activate_pin(3)
	push_data()

/obj/item/integrated_circuit/logic/binary/rslatch
	name = "RS latch"
	desc = "Этот элемент представляет собой синхронизированный триггер RS. Если и R, и S имеют значение TRUE, его состояние не изменится."
	icon_state = "sr_nor"
	inputs = list("S" = IC_PINTYPE_ANY,"R" = IC_PINTYPE_ANY)
	outputs = list("Q" = IC_PINTYPE_BOOLEAN,"!Q" = IC_PINTYPE_BOOLEAN)
	activators = list("входящий импульс C" = IC_PINTYPE_PULSE_IN, "исходящий импульс Q" = IC_PINTYPE_PULSE_OUT, "исходящий импульс !Q" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/lstate=FALSE

/obj/item/integrated_circuit/logic/binary/rslatch/do_work()
	var/datum/integrated_io/A = inputs[1]
	var/datum/integrated_io/B = inputs[2]
	var/datum/integrated_io/O = outputs[1]
	var/datum/integrated_io/Q = outputs[2]
	if(A.data)
		if(!B.data)
			lstate=TRUE
	else
		if(B.data)
			lstate=FALSE
	O.data = lstate ? TRUE : FALSE
	Q.data = !lstate ? TRUE : FALSE
	if(get_pin_data(IC_OUTPUT, 1))
		activate_pin(2)
	else
		activate_pin(3)
	push_data()

/obj/item/integrated_circuit/logic/binary/gdlatch
	name = "gated D latch"
	desc = "Эта схема представляет собой синхронизированный D-триггер."
	icon_state = "gated_d"
	inputs = list("D" = IC_PINTYPE_ANY,"E" = IC_PINTYPE_ANY)
	outputs = list("Q" = IC_PINTYPE_BOOLEAN,"!Q" = IC_PINTYPE_BOOLEAN)
	activators = list("входящий импульс C" = IC_PINTYPE_PULSE_IN, "исходящий импульс Q" = IC_PINTYPE_PULSE_OUT, "исходящий импульс !Q" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/lstate=FALSE

/obj/item/integrated_circuit/logic/binary/gdlatch/do_work()
	var/datum/integrated_io/A = inputs[1]
	var/datum/integrated_io/B = inputs[2]
	var/datum/integrated_io/O = outputs[1]
	var/datum/integrated_io/Q = outputs[2]
	if(B.data)
		if(A.data)
			lstate=TRUE
		else
			lstate=FALSE

	O.data = lstate ? TRUE : FALSE
	Q.data = !lstate ? TRUE : FALSE
	if(get_pin_data(IC_OUTPUT, 1))
		activate_pin(2)
	else
		activate_pin(3)
	push_data()

/obj/item/integrated_circuit/logic/binary/not_equals
	name = "not equal gate"
	desc = "Эта схема сравнивает два значения и выдает сигнал TRUE, если они не совпадают."
	icon_state = "not_equal"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/not_equals/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	return A.data != B.data

/obj/item/integrated_circuit/logic/binary/and
	name = "and gate"
	desc = "Эта схема выдаст сигнал TRUE, если оба входа принимают значение TRUE."
	icon_state = "and"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/and/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	return A.data && B.data

/obj/item/integrated_circuit/logic/binary/or
	name = "or gate"
	desc = "Эта схема выдаст сигнал TRUE, если хотя бы один из входов принимает значение 'TRUE'."
	icon_state = "or"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/or/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	return A.data || B.data

/obj/item/integrated_circuit/logic/binary/xor
	name = "xor gate"
	desc = "Эта схема выдаст сигнал TRUE, если только один из входов принимает значение TRUE."
	icon_state = "xor"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/xor/do_compare(datum/integrated_io/A, datum/integrated_io/B)
	return (!!A.data + !!B.data) == 1

/obj/item/integrated_circuit/logic/binary/less_than
	name = "less than gate"
	desc = "Эта схема вернет значение TRUE, если первое входное значение меньше второго."
	icon_state = "less_than"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/less_than/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	if(comparable(A, B))
		return A.data < B.data

/obj/item/integrated_circuit/logic/binary/less_than_or_equal
	name = "less than or equal gate"
	desc = "Эта схема вернет значение TRUE, если первое входное значение меньше или равно второму."
	icon_state = "less_than_or_equal"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/less_than_or_equal/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	if(comparable(A, B))
		return A.data <= B.data

/obj/item/integrated_circuit/logic/binary/greater_than
	name = "greater than gate"
	desc = "Эта схема вернет значение TRUE, если первое входное значение больше второго."
	icon_state = "greater_than"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/greater_than/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	if(comparable(A, B))
		return A.data > B.data

/obj/item/integrated_circuit/logic/binary/greater_than_or_equal
	name = "greater than or equal gate"
	desc = "Эта схема вернет значение TRUE, если первое входное значение больше или равно второму."
	icon_state = "greater_than_or_equal"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/logic/binary/greater_than_or_equal/do_compare(var/datum/integrated_io/A, var/datum/integrated_io/B)
	if(comparable(A, B))
		return A.data >= B.data

/obj/item/integrated_circuit/logic/unary/not
	name = "not gate"
	desc = "Эта схема инвертирует поступающий на него сигнал."
	icon_state = "not"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	activators = list("invert" = IC_PINTYPE_PULSE_IN, "on inverted" = IC_PINTYPE_PULSE_OUT)

/obj/item/integrated_circuit/logic/unary/not/do_check(var/datum/integrated_io/A)
	return !A.data
