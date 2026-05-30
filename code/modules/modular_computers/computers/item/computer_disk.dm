/obj/item/computer_disk
	name = "data disk"
	desc = "Removable disk used to store data."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk6"
	w_class = WEIGHT_CLASS_TINY
	/// The amount of storage space on the disk
	var/max_capacity = 16
	/// The amount of storage space filled
	var/used_capacity = 0
	/// List of stored files on this drive. DO NOT MODIFY DIRECTLY!
	var/list/datum/computer_file/stored_files = list()
	/// List of all programs that the disk should start with.
	var/list/datum/computer_file/starting_programs = list()

/obj/item/computer_disk/Initialize(mapload)
	. = ..()
	for(var/programs in starting_programs)
		var/datum/computer_file/program_type = new programs
		add_file(program_type)

/obj/item/computer_disk/Destroy(force)
	QDEL_LIST(stored_files)
	return ..()

/obj/item/computer_disk/proc/add_file(datum/computer_file/file)
	if((file.size + used_capacity) > max_capacity)
		return FALSE
	stored_files += file
	file.disk_host = src
	used_capacity += file.size
	return TRUE

/obj/item/computer_disk/proc/remove_file(datum/computer_file/file)
	if(!(file in stored_files))
		return FALSE
	stored_files -= file
	used_capacity -= file.size
	qdel(file)
	return TRUE

