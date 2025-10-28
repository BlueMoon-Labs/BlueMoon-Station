/atom/movable/screen/shadekin/dark_energy_level
	name = "Уровень темной энергии"
	desc = "Демонстрирует уровень энергии"
	icon_state = "shadekin-0-0"
	screen_loc = ui_shadekin_energy_level
	mouse_over_pointer = MOUSE_HAND_POINTER

	//От неакттуальности данных на один тик, еще никто не умирал
	var/cashed_max_energy = 100
	var/last_energy_level = 100
	var/last_ligth_level = 1

/atom/movable/screen/shadekin/dark_energy_level/SetRegister()
	RegisterSignal(owner, COMSIG_SHADEKIN_ENERGY_LIGTH_LEVEL, PROC_REF(dark_energy_handler))

/atom/movable/screen/shadekin/dark_energy_level/DelUnregister()
	UnregisterSignal(owner, COMSIG_SHADEKIN_ENERGY_LIGTH_LEVEL)

/atom/movable/screen/shadekin/dark_energy_level/on_gain()
	//Впринципе не очень важно следить за актуальнстью данных, если это будут менять педали, то пусть перезапустят худы проком
	cashed_max_energy = SEND_SIGNAL(owner, COMSIG_SHADEKIN_GET_MAX_ENERGY_LEVEL)

//Логика скопирована из первоисточника, поэтому немного всратая (возможно)
/atom/movable/screen/shadekin/dark_energy_level/proc/update_energy_hud(dark_energy = 100, dark_level = 1)
	var/l_icon = 0
	var/e_icon = 0
	switch(dark_level)
		if(0.8 to 1)
			l_icon = 0
		if(0.6 to 0.8)
			l_icon = 1
		if(0.4 to 0.6)
			l_icon = 2
		if(0.2 to 0.4)
			l_icon = 3
		if(0 to 0.2)
			l_icon = 4

	switch((dark_energy / cashed_max_energy) * 100)
		if(0 to 24)
			e_icon = 0
		if(25 to 49)
			e_icon = 1
		if(50 to 74)
			e_icon = 2
		if(75 to 99)
			e_icon = 3
		if(100 to INFINITY)
			e_icon = 4

	icon_state = "shadekin-[l_icon]-[e_icon]"

/atom/movable/screen/shadekin/dark_energy_level/proc/dark_energy_handler(datum/source, energy_level, ligth_level)
	SIGNAL_HANDLER
	last_energy_level = energy_level
	last_ligth_level = ligth_level

	update_energy_hud(energy_level, ligth_level)

/atom/movable/screen/shadekin/dark_energy_level/Click(location,control,params)
	to_chat(usr, examine_block(span_notice("Уровень освещенности: <b>[round(last_ligth_level, 0.1)]</b>.<br>\
		<br>Уровень темной энергии: <b>[last_energy_level]/[cashed_max_energy]</b>.")))

