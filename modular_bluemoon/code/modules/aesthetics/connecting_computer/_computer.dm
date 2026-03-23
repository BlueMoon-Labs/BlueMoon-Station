/obj/machinery/computer
	///Determines if the computer can connect to other computers (no arcades, etc.)
	var/connectable = TRUE

/obj/machinery/computer/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()

	if(connectable)
		AddComponent(/datum/component/connectable_computer)
