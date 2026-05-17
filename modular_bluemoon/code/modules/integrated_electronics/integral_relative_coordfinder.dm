/obj/item/integrated_circuit/input/relative_cfinder

	name = "relative coordfinder"
	desc = "Distance sensor and accelerometer combined in one circuit. Returns object's relative coordinates."
	icon_state = "recorder"
	extended_desc = "Компактный сенсор, определяющий дистанцию до цели и её положение в пространстве. \
	На входной пин подаётся референс к объекту. Выходные пины выдают координаты X и Y, а также дистанцию до цели. \
	Для определения координаты необходимо, чтобы цель была в поле зрения корпуса, в который установлена плата."
	complexity = 2
	inputs = list("target" = IC_PINTYPE_REF)
	outputs = list(
		"X" = IC_PINTYPE_NUMBER,
		"Y" = IC_PINTYPE_NUMBER,
		"distance" = IC_PINTYPE_NUMBER
		)
	activators = list(
		"scan" = IC_PINTYPE_PULSE_IN,
		"on scan" = IC_PINTYPE_PULSE_OUT,
		"on failure" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4

/obj/item/integrated_circuit/input/relative_cfinder/do_work()
	if(!assembly)
		return
	var/atom/T = get_pin_data_as_type(IC_INPUT, 1, /atom)
	var/turf/L = get_turf(src)
	if(!istype(T) || !(T in view(L)))
		activate_pin(3)
		return
	set_pin_data(IC_OUTPUT, 1, T.x-L.x)
	set_pin_data(IC_OUTPUT, 2, T.y-L.y)
	set_pin_data(IC_OUTPUT, 3, sqrt((T.x-L.x)*(T.x-L.x)+ (T.y-L.y)*(T.y-L.y)))
	push_data()
	activate_pin(2)

