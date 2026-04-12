/obj/item/integrated_circuit/memory
	name = "memory chip"
	desc = "Этот крошечный чип может хранить один элемент данных."
	icon_state = "memory"
	complexity = 1
	inputs = list()
	outputs = list()
	activators = list("установить" = IC_PINTYPE_PULSE_IN, "при установке" = IC_PINTYPE_PULSE_OUT)
	category_text = "Память"
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 1
	var/number_of_pins = 1

/obj/item/integrated_circuit/memory/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		inputs["ввод [i]"] = IC_PINTYPE_ANY // This is just a string since pins don't get built until ..() is called.
		outputs["вывод [i]"] = IC_PINTYPE_ANY
	complexity = number_of_pins
	. = ..()

/obj/item/integrated_circuit/memory/examine(mob/user)
	. = ..()
	var/i
	for(i = 1, i <= outputs.len, i++)
		var/datum/integrated_io/O = outputs[i]
		var/data = "nothing"
		if(isweakref(O.data))
			var/datum/d = O.data_as_type(/datum)
			if(d)
				data = "[d]"
		else if(!isnull(O.data))
			data = O.data
		. += "В [src] данные [data] сохранены по адресу [i]."

/obj/item/integrated_circuit/memory/do_work()
	for(var/i = 1 to inputs.len)
		var/datum/integrated_io/I = inputs[i]
		var/datum/integrated_io/O = outputs[i]
		O.data = I.data
		O.push_data()
	activate_pin(2)

/obj/item/integrated_circuit/memory/tiny
	name = "small memory circuit"
	desc = "Эта схема может хранить два элемента данных."
	icon_state = "memory4"
	power_draw_per_use = 2
	number_of_pins = 2

/obj/item/integrated_circuit/memory/medium
	name = "medium memory circuit"
	desc = "Эта схема может хранить четыре элемента данных."
	icon_state = "memory4"
	power_draw_per_use = 2
	number_of_pins = 4

/obj/item/integrated_circuit/memory/large
	name = "large memory circuit"
	desc = "Эта большая схема может хранить восемь элементов данных."
	icon_state = "memory8"
	power_draw_per_use = 4
	number_of_pins = 8

/obj/item/integrated_circuit/memory/huge
	name = "large memory stick"
	desc = "На этой схеме можно сохранить до шестнадцати записей."
	icon_state = "memory16"
	w_class = WEIGHT_CLASS_SMALL
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 8
	number_of_pins = 16

/obj/item/integrated_circuit/memory/constant
	name = "constant chip"
	desc = "Этот крошечный чип может хранить один фрагмент данных, который невозможно перезаписать без его отсоединения."
	icon_state = "memory"
	inputs = list()
	outputs = list("output pin" = IC_PINTYPE_ANY)
	activators = list("push data" = IC_PINTYPE_PULSE_IN)
	var/accepting_refs = FALSE
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	number_of_pins = 0

/obj/item/integrated_circuit/memory/constant/do_work()
	var/datum/integrated_io/O = outputs[1]
	O.push_data()

/obj/item/integrated_circuit/memory/constant/emp_act()
	for(var/i in 1 to activators.len)
		var/datum/integrated_io/activate/A = activators[i]
		A.scramble()

/obj/item/integrated_circuit/memory/constant/save_special()
	var/datum/integrated_io/O = outputs[1]
	if(istext(O.data) || isnum(O.data))
		return O.data

/obj/item/integrated_circuit/memory/constant/load_special(special_data)
	var/datum/integrated_io/O = outputs[1]
	if(istext(special_data) || isnum(special_data))
		O.data = special_data

/obj/item/integrated_circuit/memory/constant/attack_self(mob/user)
	var/datum/integrated_io/O = outputs[1]
	if(!user.IsAdvancedToolUser())
		return
	var/type_to_use = input("Пожалуйста, выберите тип.","[src] type setting") as null|anything in list("строка","число","ссылка", "null")

	var/new_data = null
	switch(type_to_use)
		if("строка")
			accepting_refs = FALSE
			new_data = input("Теперь введите строку.","[src] string writing") as null|text
			if(istext(new_data) && user.IsAdvancedToolUser())
				O.data = new_data
				to_chat(user, "<span class='notice'>Вы устанавливаете в память [src] [O.display_data(O.data)].</span>")
		if("число")
			accepting_refs = FALSE
			new_data = input("Теперь введите число.","[src] number writing") as null|num
			if(isnum(new_data) && user.IsAdvancedToolUser())
				O.data = new_data
				to_chat(user, "<span class='notice'>Вы устанавливаете в память [src] [O.display_data(O.data)].</span>")
		if("ссылка")
			accepting_refs = TRUE
			to_chat(user, "<span class='notice'>Вы включаете сканер ссылок [src].  Проведите им по \
            объекту, чтобы получить ссылку на этот объект и сохранить её в памяти.</span>")
		if("null")
			O.data = null
			to_chat(user, "<span class='notice'>Вы сбросили содержимое [src] до нуля.</span>")

/obj/item/integrated_circuit/memory/constant/afterattack(atom/target, mob/living/user, proximity)
	. = ..()
	if(accepting_refs && proximity)
		var/datum/integrated_io/O = outputs[1]
		O.data = WEAKREF(target)
		visible_message("<span class='notice'>[user] проводит [src] над [target].</span>")
		to_chat(user, "<span class='notice'>Вы установили в память [src] ссылку на [O.display_data(O.data)]. Сканер ссылок \
        теперь отключен.</span>")
		accepting_refs = FALSE
