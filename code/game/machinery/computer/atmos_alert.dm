/obj/machinery/computer/atmos_alert
	name = "atmospheric alert console"
	desc = "Used to monitor the station's air alarms."
	circuit = /obj/item/circuitboard/computer/atmos_alert
	icon_screen = "alert:0"
	icon_keyboard = "atmos_key"
	///Ассоциативные списки зона -> list("cause", "cause_gas", "time", "source").
	///Раньше здесь лежали одни имена зон, и по консоли нельзя было понять,
	///что именно случилось и когда.
	var/list/priority_alarms = list()
	var/list/minor_alarms = list()
	var/receive_frequency = FREQ_ATMOS_ALARMS
	var/datum/radio_frequency/radio_connection

	light_color = LIGHT_COLOR_CYAN

/obj/machinery/computer/atmos_alert/Initialize(mapload)
	. = ..()
	set_frequency(receive_frequency)

/obj/machinery/computer/atmos_alert/Destroy()
	SSradio.remove_object(src, receive_frequency)
	return ..()

/obj/machinery/computer/atmos_alert/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosAlertConsole", name)
		ui.open()

/obj/machinery/computer/atmos_alert/ui_data(mob/user)
	var/list/data = list()

	data["priority"] = build_alert_entries(priority_alarms)
	data["minor"] = build_alert_entries(minor_alarms)

	return data

///Разворачивает хранилище тревог в плоский список для tgui.
/obj/machinery/computer/atmos_alert/proc/build_alert_entries(list/source)
	var/list/entries = list()
	for(var/zone in source)
		var/list/record = source[zone]
		var/raised_at = record?["time"]
		entries += list(list(
			"zone" = zone,
			"cause" = record?["cause"],
			"cause_gas" = record?["cause_gas"],
			"source" = record?["source"],
			"clock" = record?["clock"],
			"age" = isnull(raised_at) ? null : DisplayTimeText(world.time - raised_at),
		))
	return entries

/obj/machinery/computer/atmos_alert/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("clear")
			var/zone = params["zone"]
			if(zone in priority_alarms)
				to_chat(usr, "<span class='notice'>Тревога высокого приоритета по зоне [zone] снята.</span>")
				priority_alarms -= zone
				. = TRUE
			if(zone in minor_alarms)
				to_chat(usr, "<span class='notice'>Малая тревога по зоне [zone] снята.</span>")
				minor_alarms -= zone
				. = TRUE
		if("clear_all")
			if(!length(priority_alarms) && !length(minor_alarms))
				return
			to_chat(usr, "<span class='notice'>Все атмосферные тревоги сняты.</span>")
			priority_alarms.Cut()
			minor_alarms.Cut()
			. = TRUE
	update_icon()

/obj/machinery/computer/atmos_alert/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, receive_frequency)
	receive_frequency = new_frequency
	radio_connection = SSradio.add_object(src, receive_frequency, RADIO_ATMOSIA)

/obj/machinery/computer/atmos_alert/receive_signal(datum/signal/signal)
	if(!signal)
		return

	var/zone = signal.data["zone"]
	var/severity = signal.data["alert"]

	if(!zone || !severity)
		return

	minor_alarms -= zone
	priority_alarms -= zone
	if(severity != "severe" && severity != "minor")
		update_icon()
		return

	var/list/record = list(
		"cause" = signal.data["cause"],
		"cause_gas" = signal.data["cause_gas"],
		"source" = signal.data["source"],
		"clock" = gameTimestamp("hh:mm:ss"),
		"time" = world.time,
	)
	if(severity == "severe")
		priority_alarms[zone] = record
	else
		minor_alarms[zone] = record
	update_icon()
	return

/obj/machinery/computer/atmos_alert/update_overlays()
	. = ..()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)
	var/overlay_state = icon_screen
	if(machine_stat & (NOPOWER|BROKEN))
		. |= "[icon_keyboard]_off"
		return
	. |= icon_keyboard
	if(priority_alarms.len)
		overlay_state = "alert:2"
	else if(minor_alarms.len)
		overlay_state = "alert:1"
	else
		overlay_state = "alert:0"
	. |= overlay_state
	SSvis_overlays.add_vis_overlay(src, icon, overlay_state, layer, plane, dir)
	SSvis_overlays.add_vis_overlay(src, icon, overlay_state, EMISSIVE_LAYER, EMISSIVE_PLANE, dir, alpha=128)
