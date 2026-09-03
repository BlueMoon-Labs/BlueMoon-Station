// This is special hardware configuration program.
// It is to be used only with modular computers.
// It allows you to toggle components of your device.

/datum/computer_file/program/computerconfig
	filename = "compconfig"
	filedesc = "Hardware Configuration Tool"
	extended_desc = "This program allows configuration of computer's hardware"
	program_icon_state = "generic"
	unsendable = 1
	undeletable = 1
	size = 4
	available_on_ntnet = 0
	requires_ntnet = FALSE
	tgui_id = "NtosConfiguration"
	program_icon = "cog"

	var/obj/item/modular_computer/movable = null


/datum/computer_file/program/computerconfig/ui_data(mob/user)
	movable = computer
	if(!istype(movable))
		movable = null

	// No computer connection, we can't get data from that.
	if(!movable)
		return FALSE

	var/list/data = get_header_data()

	var/obj/item/computer_hardware/hard_drive/hard_drive = movable.all_components[MC_HDD]
	if(hard_drive)
		data["disk_size"] = hard_drive.max_capacity
		data["disk_used"] = hard_drive.used_capacity
	else
		data["disk_size"] = movable.max_capacity
		data["disk_used"] = 0
		for(var/datum/computer_file/F in movable.stored_files)
			data["disk_used"] += F.size

	data["power_usage"] = movable.last_power_usage

	var/battery_percent = movable.get_battery_percent()
	data["battery_exists"] = !isnull(battery_percent)
	if(!isnull(battery_percent))
		data["battery_percent"] = round(battery_percent)
		var/obj/item/stock_parts/cell/cell = movable.get_cell()
		if(cell)
			data["battery_rating"] = cell.maxcharge
			data["battery"] = list("max" = cell.maxcharge, "charge" = round(cell.charge))

	var/list/all_entries[0]
	for(var/I in movable.all_components)
		var/obj/item/computer_hardware/H = movable.all_components[I]
		all_entries.Add(list(list(
		"name" = H.name,
		"desc" = H.desc,
		"enabled" = H.enabled,
		"critical" = H.critical,
		"powerusage" = H.power_usage
		)))

	data["hardware"] = all_entries
	return data


/datum/computer_file/program/computerconfig/ui_act(action,params)
	. = ..()
	if(.)
		return
	switch(action)
		if("PC_toggle_component")
			var/obj/item/computer_hardware/H = movable.find_hardware_by_name(params["name"])
			if(H && istype(H))
				H.enabled = !H.enabled
			. = TRUE
