/obj/item/integrated_circuit/input/integrity_analyzer

	name = "integrity analyzer"
	desc = "Multifunctional engineering circuit designed for analyzing object integrity using numerous sensors and probes"
	icon_state = "video_camera"
	extended_desc = "Многофункциональный инженерный анализатор, способный определить работоспособность объекта, \
	степень его структурной целостности, и провести общий анализ. Предмет должен находится вплотную к интегральному корпусу для анализа. \
	Входной пин принимает референс на анализируемый объект. Выход 'integrity' даёт относительную целостность объекта в процентах. \
	Выход 'analysis' выдаёт текстовую строку с оценкой состояния."
	complexity = 4
	inputs = list("target" = IC_PINTYPE_REF)
	outputs = list(
		"integrity" = IC_PINTYPE_NUMBER,
		"analysis" = IC_PINTYPE_STRING
		)
	activators = list(
		"analyze" = IC_PINTYPE_PULSE_IN,
		"on success" = IC_PINTYPE_PULSE_OUT,
		"on failure" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 25

/obj/item/integrated_circuit/input/integrity_analyzer/do_work()
	if(!assembly)
		return

	var/obj/O = get_pin_data_as_type(IC_INPUT, 1, /obj)
	if(!istype(O) || !(O in range(1, get_turf(src))))	// Not an object and/or is too far
		activate_pin(3)
		return

	if(O.max_integrity <= 0)	// integrity check not possible
		set_pin_data(IC_OUTPUT, 1, 100)
		set_pin_data(IC_OUTPUT, 2, "Объект [O] не может быть подвержен структурному анализу.")
		push_data()
		activate_pin(2)
		return

	var/integrity_percent = clamp(round(((O.obj_integrity / O.max_integrity) * 100), 0.1), 0, 100)
	set_pin_data(IC_OUTPUT, 1, integrity_percent)
	switch(integrity_percent)
		if(100)
			set_pin_data(IC_OUTPUT, 2, "Объект [O] не имеет повреждений.")
		if(50 to 99)
			set_pin_data(IC_OUTPUT, 2, "Объект [O] слегка повреждён.")
		if(25 to 50)
			set_pin_data(IC_OUTPUT, 2, "Объект [O] значительно повреждён.")
		if(0 to 25)
			set_pin_data(IC_OUTPUT, 2, "Объект [O] критически повреждён!")
	push_data()
	activate_pin(2)
