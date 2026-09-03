/**
 * Status Display Controller - PDA cartridge program
 *
 * Allows changing messages on station status displays.
 */
/datum/computer_file/program/statusdisplay
	filename = "statdisp"
	filedesc = "Status Display Control"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "generic"
	extended_desc = "This program allows setting messages and alerts on station status displays."
	requires_ntnet = FALSE
	transfer_access = null
	usage_flags = PROGRAM_ON_TABLETS
	size = 4
	available_on_ntnet = FALSE
	tgui_id = "NtosStatusDisplay"
	program_icon = "tv"

/datum/computer_file/program/statusdisplay/ui_data(mob/user)
	var/list/data = get_header_data()
	return data

/datum/computer_file/program/statusdisplay/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("set_message")
			var/msg1 = params["msg1"]
			var/msg2 = params["msg2"]
			if(!msg1)
				return FALSE
			post_status("message", msg1, msg2)
			return TRUE
		if("set_alert")
			var/alert_type = params["alert"]
			if(!alert_type)
				return FALSE
			post_status("alert", alert_type)
			return TRUE

/datum/computer_file/program/statusdisplay/proc/post_status(command, data1, data2)
	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)
	if(!frequency)
		return
	var/datum/signal/status_signal = new(list("command" = command))
	switch(command)
		if("message")
			status_signal.data["msg1"] = data1
			status_signal.data["msg2"] = data2
		if("alert")
			status_signal.data["picture_state"] = data1
	frequency.post_signal(src, status_signal)
