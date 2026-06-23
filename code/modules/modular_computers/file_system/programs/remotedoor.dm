/**
 * Remote Door Control - PDA cartridge program
 *
 * Allows remote opening/closing of nearby airlocks.
 */
/datum/computer_file/program/remotedoor
	filename = "remotedoor"
	filedesc = "Remote Door Control"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "generic"
	extended_desc = "This program allows remote control of nearby airlocks and doors."
	requires_ntnet = FALSE
	transfer_access = null
	usage_flags = PROGRAM_ON_TABLETS
	size = 4
	tgui_id = "NtosRemoteDoor"
	program_icon = "door-open"
	available_on_ntnet = FALSE

/datum/computer_file/program/remotedoor/ui_data(mob/user)
	var/list/data = get_header_data()

	var/list/doors = list()
	for(var/obj/machinery/door/airlock/A in view(3, get_turf(computer?.physical || src)))
		if(!A.requiresID())
			doors += list(list(
				"name" = A.name,
				"ref" = REF(A),
				"open" = !A.density,
			))

	data["doors"] = doors
	return data

/datum/computer_file/program/remotedoor/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle")
			var/obj/machinery/door/airlock/A = locate(params["ref"]) in view(3, get_turf(computer?.physical || src))
			if(!A || A.requiresID())
				return FALSE
			if(A.density)
				A.open()
			else
				A.close()
			return TRUE
