/obj/item/integrated_circuit/input/integral_surgical_scanner

	name = "surgical scanner"
	desc = "Хирургический сканер, предназначенный для анализа состояния пациента и этапов операции"
	icon_state = "video_camera"
	extended_desc = "Сложное медицинское устройство, использующее встроенную медицинску базу данных для анализа пациента. \
	При пульсации входного пина, проверяет состояние пациента, на которого дан референс (conscious/unconscious/dead), \
	и выдаёт основные данные проводимой операции, если таковая проводится. \
	Часть тела, на которой проводится операция, выдаётся в формате строки (head,eyes,l_arm). Данный формат принимается модулем Usage. \
	В пин suggested tools передаётся список инструментов с наивысшим шансом на успех для данного шага операции. \
	Если на пациенте проводится несколько операций одновременно - показывает лишь информацию о самой первой. \
	В силу технических ограничений, схема не может определить альтернативный шаг операции."
	complexity = 16
	w_class = WEIGHT_CLASS_SMALL
	inputs = list("patient" = IC_PINTYPE_REF)
	outputs = list(
		"patient state" = IC_PINTYPE_STRING,
		"patient health" = IC_PINTYPE_NUMBER,
		"operating" = IC_PINTYPE_BOOLEAN,
		"target body part" = IC_PINTYPE_STRING,
		"current operation" = IC_PINTYPE_STRING,
		"next step" = IC_PINTYPE_STRING,
		"suggested tools" = IC_PINTYPE_LIST,
		)
	activators = list(
		"analyze" = IC_PINTYPE_PULSE_IN,
		"on analyze" = IC_PINTYPE_PULSE_OUT,
		"on failure" = IC_PINTYPE_PULSE_OUT
		)
	cooldown_per_use = 5
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 80

	var/static/list/patient_state_strings = list(	// give patient's state in a simple, predictable format
	"[CONSCIOUS]" = "conscious",
	"[SOFT_CRIT]" = "conscious",
	"[UNCONSCIOUS]" = "unconscious",
	"[DEAD]" = "dead"
	)

/obj/item/integrated_circuit/input/integral_surgical_scanner/do_work()
	var/mob/living/H = get_pin_data_as_type(IC_INPUT, 1, /mob/living)
	if(!istype(H) || !H.Adjacent(get_turf(src)))	// Invalid input and/or far away from assembly
		activate_pin(3)
		return
	set_pin_data(IC_OUTPUT, 1, patient_state_strings["[H.stat]"] || "unknown")
	set_pin_data(IC_OUTPUT, 2, H.health)
	if(!H.surgeries.len)
		set_pin_data(IC_OUTPUT, 3, FALSE)
		set_pin_data(IC_OUTPUT, 4, null)
		set_pin_data(IC_OUTPUT, 5, null)
		set_pin_data(IC_OUTPUT, 6, null)
		set_pin_data(IC_OUTPUT, 7, null)
		push_data()
		activate_pin(2)
		return
	set_pin_data(IC_OUTPUT, 3, TRUE)
	var/datum/surgery/surgery = H.surgeries[1]	// I don't care, really. No one starts several operations at once anyway.
	var/datum/surgery_step/next_step = surgery.get_surgery_step()
	if(next_step)	// give nulls to 6 and 7 if there's no step, to prevent stale data from being pushed
		var/max_chance_tools = next_step.get_max_chance_implements()
		set_pin_data(IC_OUTPUT, 6, next_step.name)
		if(length(max_chance_tools))	// same thing for tools
			set_pin_data(IC_OUTPUT, 7, max_chance_tools)
		else
			set_pin_data(IC_OUTPUT, 7, null)
	else
		set_pin_data(IC_OUTPUT, 6, null)
		set_pin_data(IC_OUTPUT, 7, null)
	set_pin_data(IC_OUTPUT, 4, surgery.location)	// formatted like l_arm, head, eyes. Useful for interacting with Usage Module
	set_pin_data(IC_OUTPUT, 5, surgery.name)
	push_data()
	activate_pin(2)
	return
