/obj/item/integrated_circuit/input/gravity_sensor

	name = "gravity sensor"
	desc = "A circuit designed for determining the presence of gravitational forces"
	icon_state = "gps"
	extended_desc = "Универсальная схема, включающая в себя акселерометр и гравиметр. При пульсации входного пина, определяет, воздействуют ли на интегральный корпус гравитационные силы."
	complexity = 2
	inputs = list()
	outputs = list("gravity detected" = IC_PINTYPE_BOOLEAN)
	activators = list(
		"check gravity" = IC_PINTYPE_PULSE_IN,
		"on gravity detected" = IC_PINTYPE_PULSE_OUT,
		"on no gravity detected" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 5

/obj/item/integrated_circuit/input/gravity_sensor/do_work()
	if(!assembly)
		return
	if(has_gravity(assembly))
		set_pin_data(IC_OUTPUT, 1, TRUE)
		push_data()
		activate_pin(2)
	else
		set_pin_data(IC_OUTPUT, 1, FALSE)
		push_data()
		activate_pin(3)
