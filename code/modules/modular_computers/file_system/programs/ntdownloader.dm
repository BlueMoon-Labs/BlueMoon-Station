/datum/computer_file/program/ntnetdownload
	filename = "ntsoftwarehub"
	filedesc = "NT Software Hub"
	program_icon_state = "generic"
	extended_desc = "Позволяет загружать программное обеспечение из официальных репозиториев NT."
	unsendable = TRUE
	undeletable = TRUE
	size = 4
	requires_ntnet = TRUE
	requires_ntnet_feature = NTNET_SOFTWAREDOWNLOAD
	available_on_ntnet = FALSE
	ui_header = "downloader_finished.gif"
	tgui_id = "NtosNetDownloader"
	program_icon = "download"

	var/datum/computer_file/program/downloaded_file = null
	var/hacked_download = FALSE
	var/download_completion = FALSE //GQ of downloaded data.
	var/download_netspeed = 0
	var/downloaderror = ""
	var/obj/item/modular_computer/my_computer = null
	var/emagged = FALSE
	var/list/main_repo
	var/list/antag_repo
	var/list/show_categories = list(
		PROGRAM_CATEGORY_CREW,
		PROGRAM_CATEGORY_ENGI,
		PROGRAM_CATEGORY_ROBO,
		PROGRAM_CATEGORY_SUPL,
		PROGRAM_CATEGORY_MISC,
	)

/datum/computer_file/program/ntnetdownload/run_program()
	. = ..()
	main_repo = SSnetworks.station_network.available_station_software
	antag_repo = SSnetworks.station_network.available_antag_software

/datum/computer_file/program/ntnetdownload/run_emag()
	if(emagged)
		return FALSE
	emagged = TRUE
	return TRUE


/datum/computer_file/program/ntnetdownload/proc/begin_file_download(filename)
	if(downloaded_file)
		return FALSE

	var/datum/computer_file/program/PRG = SSnetworks.station_network.find_ntnet_file_by_name(filename)

	if(!PRG || !istype(PRG))
		return FALSE

	// Attempting to download antag only program, but without having emagged/syndicate computer. No.
	if(PRG.available_on_syndinet && !emagged)
		return FALSE

	var/obj/item/computer_hardware/hard_drive/hard_drive = computer.all_components[MC_HDD]

	if(hard_drive)
		if(!hard_drive.can_store_file(PRG))
			return FALSE
	else
		if(!computer)
			return FALSE
		var/name = PRG.filename + "." + PRG.filetype
		for(var/datum/computer_file/file in computer.stored_files)
			if((file.filename + "." + file.filetype) == name)
				return FALSE
		if(computer.stored_files.len >= 999)
			return FALSE
		var/used = 0
		for(var/datum/computer_file/F in computer.stored_files)
			used += F.size
		if((used + PRG.size) > computer.max_capacity)
			return FALSE

	ui_header = "downloader_running.gif"

	if(PRG in main_repo)
		generate_network_log("Began downloading file [PRG.filename].[PRG.filetype] from NTNet Software Repository.")
		hacked_download = FALSE
	else if(PRG in antag_repo)
		generate_network_log("Began downloading file **ENCRYPTED**.[PRG.filetype] from unspecified server.")
		hacked_download = TRUE
	else
		generate_network_log("Began downloading file [PRG.filename].[PRG.filetype] from unspecified server.")
		hacked_download = FALSE

	downloaded_file = PRG.clone()

/datum/computer_file/program/ntnetdownload/proc/abort_file_download()
	if(!downloaded_file)
		return
	generate_network_log("Aborted download of file [hacked_download ? "**ENCRYPTED**" : "[downloaded_file.filename].[downloaded_file.filetype]"].")
	downloaded_file = null
	download_completion = FALSE
	ui_header = "downloader_finished.gif"

/datum/computer_file/program/ntnetdownload/proc/complete_file_download()
	if(!downloaded_file)
		return
	generate_network_log("Completed download of file [hacked_download ? "**ENCRYPTED**" : "[downloaded_file.filename].[downloaded_file.filetype]"].")
	var/obj/item/computer_hardware/hard_drive/hard_drive = computer.all_components[MC_HDD]
	if(hard_drive)
		if(!hard_drive.store_file(downloaded_file))
			downloaderror = "I/O ERROR - Unable to save file. Check whether you have enough free space on your hard drive and whether your hard drive is properly connected. If the issue persists contact your system administrator for assistance."
	else if(computer)
		computer.store_file(downloaded_file)
	else
		downloaderror = "I/O ERROR - Unable to save file. Storage device unavailable."
	downloaded_file = null
	download_completion = FALSE
	ui_header = "downloader_finished.gif"

/datum/computer_file/program/ntnetdownload/process_tick()
	if(!downloaded_file)
		return
	if(download_completion >= downloaded_file.size)
		complete_file_download()
	// Download speed according to connectivity state. NTNet server is assumed to be on unlimited speed so we're limited by our local connectivity
	download_netspeed = 0
	// Speed defines are found in misc.dm
	switch(ntnet_status)
		if(1)
			download_netspeed = NTNETSPEED_LOWSIGNAL
		if(2)
			download_netspeed = NTNETSPEED_HIGHSIGNAL
		if(3)
			download_netspeed = NTNETSPEED_ETHERNET
		else
			download_netspeed = NTNETSPEED_HIGHSIGNAL
	download_completion += download_netspeed

/datum/computer_file/program/ntnetdownload/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("PRG_downloadfile")
			if(!downloaded_file)
				begin_file_download(params["filename"])
			return TRUE
		if("PRG_reseterror")
			if(downloaderror)
				download_completion = FALSE
				download_netspeed = FALSE
				downloaded_file = null
				downloaderror = ""
			return TRUE
	return FALSE

/datum/computer_file/program/ntnetdownload/ui_data(mob/user)
	my_computer = computer

	if(!istype(my_computer))
		return
	var/list/access = list()
	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	if(card_slot)
		access = card_slot.GetAccess()
	if(!length(access) && istype(computer, /obj/item/modular_computer/pda))
		var/obj/item/modular_computer/pda/pda = computer
		if(pda.stored_id)
			access = pda.stored_id.GetAccess()
	if(!length(access) && istype(computer, /obj/item/modular_computer/pda/silicon/cyborg))
		var/obj/item/modular_computer/pda/silicon/cyborg/borg_pda = computer
		access = borg_pda.get_department_access()
	if(!length(access) && istype(computer, /obj/item/modular_computer/tablet/integrated))
		var/obj/item/modular_computer/tablet/integrated/borg_tablet = computer
		access = borg_tablet.get_department_access()

	var/list/data = get_header_data()

	data["downloading"] = !!downloaded_file
	data["error"] = downloaderror || FALSE

	// Download running. Wait please..
	if(downloaded_file)
		data["downloadname"] = downloaded_file.filename
		data["downloaddesc"] = downloaded_file.filedesc
		data["downloadsize"] = downloaded_file.size
		data["downloadspeed"] = download_netspeed
		data["downloadcompletion"] = round(download_completion, 0.1)

	var/obj/item/computer_hardware/hard_drive/hard_drive = my_computer.all_components[MC_HDD]
	if(hard_drive)
		data["disk_size"] = hard_drive.max_capacity
		data["disk_used"] = hard_drive.used_capacity
	else
		data["disk_size"] = my_computer.max_capacity
		data["disk_used"] = 0
		for(var/datum/computer_file/F in my_computer.stored_files)
			data["disk_used"] += F.size
	data["emagged"] = emagged

	var/list/repo = antag_repo | main_repo
	var/list/program_categories = list()

	for(var/I in repo)
		var/datum/computer_file/program/P = I
		if(P.available_on_syndinet && !emagged)
			continue
		if(!(P.category in program_categories))
			program_categories.Add(P.category)
		var/installed = FALSE
		if(hard_drive)
			installed = !!hard_drive.find_file_by_name(P.filename)
		else
			installed = !!my_computer.find_file_by_name(P.filename)
		var/restriction = ""
		if(P.available_on_syndinet)
			restriction = "Требуется доступ к SyndiNet (устройство взломано)"
		else if(P.transfer_access)
			if(islist(P.transfer_access))
				var/list/access_names = list()
				for(var/req_access in P.transfer_access)
					var/desc = get_access_desc(req_access)
					if(desc)
						access_names += desc
				if(length(access_names))
					var/comma_sep = ", "
					restriction = "Требуется доступ для скачивания: [jointext(access_names, comma_sep)]"
			else
				var/desc = get_access_desc(P.transfer_access)
				if(desc)
					restriction = "Требуется доступ для скачивания: [desc]"
		else if(P.required_access)
			if(islist(P.required_access))
				var/list/access_names = list()
				for(var/req_access in P.required_access)
					var/desc = get_access_desc(req_access)
					if(desc)
						access_names += desc
				if(length(access_names))
					var/comma_sep = ", "
					restriction = "Требуется доступ для запуска: [jointext(access_names, comma_sep)]"
			else
				var/desc = get_access_desc(P.required_access)
				if(desc)
					restriction = "Требуется доступ для запуска: [desc]"
		data["programs"] += list(list(
			"icon" = P.program_icon,
			"filename" = P.filename,
			"filedesc" = P.filedesc,
			"fileinfo" = P.extended_desc,
			"category" = P.category,
			"installed" = installed,
			"compatible" = check_compatibility(P),
			"size" = P.size,
			"access" = emagged && P.available_on_syndinet ? TRUE : P.can_run(user,transfer = 1, access = access),
			"verifiedsource" = P.available_on_ntnet,
			"restriction" = restriction,
		))

	data["categories"] = show_categories & program_categories

	return data

/datum/computer_file/program/ntnetdownload/proc/check_compatibility(datum/computer_file/program/P)
	var/hardflag = computer.hardware_flag

	if(P?.is_supported_by_hardware(hardflag,0))
		return TRUE
	return FALSE

/datum/computer_file/program/ntnetdownload/kill_program(forced)
	abort_file_download()
	return ..()

////////////////////////
//Syndicate Downloader//
////////////////////////

/// This app only lists programs normally found in the emagged section of the normal downloader app

/datum/computer_file/program/ntnetdownload/syndicate
	filename = "syndownloader"
	filedesc = "Software Download Tool"
	program_icon_state = "generic"
	extended_desc = "Позволяет загружать программное обеспечение из общих репозиториев Синдиката."
	requires_ntnet = FALSE
	ui_header = "downloader_finished.gif"
	tgui_id = "NtosNetDownloader"
	emagged = TRUE

/datum/computer_file/program/ntnetdownload/syndicate/run_program()
	. = ..()
	main_repo = SSnetworks.station_network.available_antag_software
	antag_repo = null
