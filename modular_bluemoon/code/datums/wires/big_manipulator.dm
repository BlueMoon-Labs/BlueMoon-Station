/datum/wires/big_manipulator
	holder_type = /obj/machinery/big_manipulator
	proper_name = "Big_Manipulator"

/datum/wires/big_manipulator/New(atom/holder)
	wires = list(
		WIRE_ON,
		WIRE_DROP,
	)
	return ..()

/datum/wires/big_manipulator/interactable(mob/user)
	var/obj/machinery/big_manipulator/holder_manipulator = holder

	return holder_manipulator.panel_open ? ..() : FALSE

/datum/wires/big_manipulator/get_status()
	var/obj/machinery/big_manipulator/holder_manipulator = holder
	var/list/status = list()
	status += "The big light bulb [holder_manipulator.power_access_wire_cut ? "is off" : "is glowing [holder_manipulator.on ? "green" : "red"]"]."
	status += "The small light bulb [holder_manipulator.held_object ? "is glowing bright green" : "is off"]."
	status += "The number on the display shows [length(holder_manipulator.tasks)]."
	return status

/datum/wires/big_manipulator/on_pulse(wire, user)
	var/obj/machinery/big_manipulator/holder_manipulator = holder
	switch(wire)
		if(WIRE_ON)
			holder_manipulator.try_press_on(usr)
		if(WIRE_DROP)
			holder_manipulator.drop_held_atom()

/datum/wires/big_manipulator/on_cut(wire, mend = FALSE)
	var/obj/machinery/big_manipulator/holder_manipulator = holder
	if(wire == WIRE_ON)
		if(mend)
			holder_manipulator.power_access_wire_cut = FALSE
			return
		holder_manipulator.power_access_wire_cut = TRUE
		if(holder_manipulator.on)
			holder_manipulator.toggle_power_state(null)
