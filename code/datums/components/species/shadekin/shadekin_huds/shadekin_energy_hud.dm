/atom/movable/screen/shadekin/dark_energy_level
	name = "Уровень темной энергии"
	desc = "Демонстрирует уровень энергии"
	icon_state = "shadekin-0-0"
	screen_loc = ui_shadekin_energy_level

	var/icon_state_stages = 4
	var/cashed_max_energy = 100

/atom/movable/screen/shadekin/dark_energy_level/SetRegister()
	RegisterSignal(owner, COMSIG_SHADEKIN_ENERGY_LIGTH_LEVEL, PROC_REF(dark_energy_handler))

/atom/movable/screen/shadekin/dark_energy_level/DelUnregister()
	UnregisterSignal(owner, COMSIG_SHADEKIN_ENERGY_LIGTH_LEVEL)

/atom/movable/screen/shadekin/dark_energy_level/on_gain()
	cashed_max_energy = SEND_SIGNAL(owner, COMSIG_SHADEKIN_GET_MAX_ENERGY_LEVEL)

/atom/movable/screen/shadekin/dark_energy_level/proc/update_energy_hud(dark_energy = 100, dark_level = 1)


/atom/movable/screen/shadekin/dark_energy_level/proc/dark_energy_handler(datum/source, energy_level, ligth_level)
	SIGNAL_HANDLER
	to_chat(owner, "Уровень дарк хуйни: [energy_level] уровень света: [ligth_level]")
