/obj/machinery/computer/shuttle_flight/exploration
	name = "Vanguard Igla shuttle"
	desc = "Для сам знаешь чего."
	circuit = /obj/item/circuitboard/computer/exploration_shuttle
	shuttleId = "exploration"
	possible_destinations = "exploration_home"
	req_access = list(ACCESS_GATEWAY)
	//WHITE-STEEL PORT: рация консоли для вещания в общий канал (авто-возврат шаттла).
	var/obj/item/radio/radio
	var/radio_key = /obj/item/encryptionkey/headset_exp

/obj/machinery/computer/shuttle_flight/exploration/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	radio = new(src)
	radio.subspace_transmission = TRUE
	radio.keyslot = new radio_key
	radio.recalculateChannels()

/obj/machinery/computer/shuttle_flight/exploration/Destroy()
	QDEL_NULL(radio)
	. = ..()

//WHITE-STEEL PORT: вещание сообщения через общую рацию от лица консоли управления шаттлом.
/obj/machinery/computer/shuttle_flight/exploration/proc/speak_common(message)
	radio?.talk_into(src, message, null)

/obj/machinery/computer/shuttle_flight/exploration/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock, idnum, override)
	return

/datum/map_template/shuttle/exploration
	port_id = "exploration"
	suffix = "shuttle"
	name = "Vanguard Igla shuttle"
	can_be_bought = FALSE

/obj/docking_port/stationary/exploration
	name = "Vanguard Igla shuttle docking key"
	shuttle_id = "exploration_home"
	roundstart_template = /datum/map_template/shuttle/exploration
	dwidth = 5
	width = 13
	height = 7
