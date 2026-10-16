/obj/item/modular_computer/pda/install_default_programs()
	. = ..()
	if(!has_pda_programs || !SSntnet.is_enabled())
		return
	var/obj/item/computer_hardware/hard_drive/hard_drive = all_components[MC_HDD]
	var/datum/computer_file/program/ntnet/browser = new
	browser.computer = src
	if(hard_drive)
		hard_drive.store_file(browser)
	else
		store_file(browser)
