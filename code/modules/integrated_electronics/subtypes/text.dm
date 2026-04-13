/obj/item/integrated_circuit/text
	name = "text thingy"
	desc = "Занимается обработкой текста."
	category_text = "Текст"
	complexity = 1

// - Text Replacer - //
/obj/item/integrated_circuit/text/text_replacer
	name = "find-replace circuit"
	desc = "Заменяет в тексте совпадающие фрагменты на другой текст."
	extended_desc = "Принимает строку (стог сена) и возвращает её, заменяя все вхождения подстроки (иголки) на замену."
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	inputs = list(
		"строка" = IC_PINTYPE_STRING,
		"подстрока" = IC_PINTYPE_STRING,
		"замена" = IC_PINTYPE_STRING
	)
	activators = list(
		"заменить" = IC_PINTYPE_PULSE_IN,
		"при замене" = IC_PINTYPE_PULSE_OUT
	)
	outputs = list(
		"заменённая строка" = IC_PINTYPE_STRING
	)

/obj/item/integrated_circuit/text/text_replacer/do_work()
	set_pin_data(IC_OUTPUT, 1,replacetext(get_pin_data(IC_INPUT, 1), get_pin_data(IC_INPUT, 2), get_pin_data(IC_INPUT, 3)))
	push_data()
	activate_pin(2)
