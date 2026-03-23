/datum/bounty/item/engineering/gas
	name = "Full Tank of Pluoxium"
	description = "CentCom RnD is researching extra compact internals. Ship us a tank full of Pluoxium and you'll be compensated."
	reward = 20000
	wanted_types = list(/obj/item/tank)
	var/moles_required = 20 // A full tank is 28 moles, but CentCom ignores that fact.
	var/gas_type = GAS_PLUOXIUM

/datum/bounty/item/engineering/gas/applies_to(obj/O)
	if(!..())
		return FALSE
	var/obj/item/tank/T = O
	return T.air_contents.get_moles(gas_type) >= moles_required

//datum/bounty/item/engineering/gas/nitryl_tank
//	name = "Full Tank of Nitryl"
//	description = "The non-human staff of Station 88 has been volunteered to test performance enhancing drugs. Ship them a tank full of Nitryl so they can get started."
//	gas_type = GAS_NITRYL

/datum/bounty/item/engineering/gas/tritium_tank
	name = "Full Tank of Tritium"
	description = "Station 49 is looking to kickstart their research program. Ship them a tank full of Tritium."
	gas_type = GAS_TRITIUM

/datum/bounty/item/engineering/gas/bz_tank
	name = "Full Tank of BZ gas"
	reward = 20000
	description = "Station 69 is in need of sleep gas for their xenobiology division. Place full tank of BZ gas."
	gas_type = GAS_BZ

/datum/bounty/item/engineering/pacman
	name = "P.A.C.M.A.N.-type port. generator"
	description = "A neighboring station had a problem with their SMES, and now need something to power their communications console. Can you send them a P.A.C.M.A.N.?"
	reward = 9000
	wanted_types = list(/obj/machinery/power/port_gen/pacman)

/datum/bounty/item/engineering/superpacman
	name = "S.U.P.E.R.P.A.C.M.A.N.-type port. gen."
	description = "A neighboring station got their RBMK engine exploded as well with their SMES units. They have some uranium left, though. Can you send them a S.U.P.E.R.P.A.C.M.A.N.?"
	reward = 10000
	wanted_types = list(/obj/machinery/power/port_gen/pacman/super)

/datum/bounty/item/engineering/mrspacman
	name = "M.R.S.P.A.C.M.A.N.-type port. gen."
	description = "A neighboring station got a harvester goal to deal with with a need to supply the machine with some real power. Can you send them a M.R.S.P.A.C.M.A.N.?"
	reward = 11500
	wanted_types = list(/obj/machinery/power/port_gen/pacman/mrs)

/datum/bounty/item/engineering/canisters
	name = "Gas Canisters"
	description = "After a recent debacle in a nearby sector, 8 gas canisters are needed for containing an experimental aerosol before it kills all the local fauna."
	reward = 5200
	required_count = 8 //easy to make
	wanted_types = list(/obj/machinery/portable_atmospherics/canister)

/datum/bounty/item/engineering/microwave
	name = "Microwaves"
	description = "Due to a shortage of microwaves, our chefs are incapable of keeping up with our sheer volume of orders. We need at least three microwaves to keep up with our crew's dietary habits."
	reward = 7500
	required_count = 2
	wanted_types = list(/obj/machinery/microwave)
/* BLUEMOON DEL это старый тип гидропоники, его не достать
/datum/bounty/item/engineering/hydroponicstrays
	name = "Hydroponics Tray"
	description = "The garden has become a hot spot of late, they need a few more hydroponics tray to grow more flowers."
	reward = 2500
	required_count = 5
	wanted_types = list(/obj/machinery/hydroponics)
*/
/datum/bounty/item/engineering/rcd
	name = "Spare RCD"
	description = "Construction and repairs to are shuttles are going slowly. As it turns out, we're a little short on RCDs, can you send us a few?"
	reward = 5000
	required_count = 3
	wanted_types = list(/obj/item/construction/rcd)

/datum/bounty/item/engineering/rpd
	name = "Spare RPD"
	description = "Our Atmospheric Technicians are still living in the past, relying on stationary pipe dispensers to produce the pipes necessary to accomplish their strenuous tasks. They could use an upgrade. Could you send us some Rapid Pipe Dispensers?"
	reward = 5900
	required_count = 3
	wanted_types = list(/obj/item/pipe_dispenser)

/datum/bounty/item/engineering/heaters
	name = "Space Heaters"
	description = "The kitchen freezer was left open and now the whole place is frozen solid! We need a few space heaters to warm it back up before anyone gets hungry."
	reward = 4500
	required_count = 2
	wanted_types = list(/obj/machinery/space_heater)

/datum/bounty/item/engineering/arcadetrail
	name = "Orion Trail Arcade Games"
	description = "The staff have nothing to do when off-work. Can you send us some Orion Trail games to play?"
	reward = 8700
	required_count = 2
	wanted_types = list(/obj/machinery/computer/arcade/orion_trail)

/datum/bounty/item/engineering/arcadebattle
	name = "Battle Arcade Games"
	description = "The staff have nothing to do when off-work. Can you send us some Battle Arcade games to play?"
	reward = 8700
	required_count = 2
	wanted_types = list(/obj/machinery/computer/arcade/battle)

/datum/bounty/item/engineering/energy_ball
	name = "Contained Tesla Ball"
	description = "Station 24 is being overrun by hordes of angry Mothpeople. They are requesting the ultimate bug zapper."
	reward = 70000 //requires 14k credits of purchases, not to mention cooperation with engineering/heads of staff to set up inside the cramped shuttle
	wanted_types = list(/obj/singularity/energy_ball)

/datum/bounty/item/engineering/emitter
	name = "Emitter"
	description = "We think there may be a defect in your station's emitter designs, based on the sheer number of delaminations your sector seems to see. Ship us one of yours."
	reward = 3300
	wanted_types = list(/obj/machinery/power/emitter)

/datum/bounty/item/engineering/hydro_tray
	name = "Hydroponics Tray"
	description = "The lab technicians are trying to figure out how to lower the power drain of hydroponics trays, but we fried our last one. Mind building one for us?"
	reward = 3000
	wanted_types = list(/obj/machinery/hydroponics/constructable)

/datum/bounty/item/engineering/cablecoil
	name = "Cables"
	description = "We are out of pre-shift cables for our nearest stations, could you send us some?"
	reward = 2300
	required_count = 120
	wanted_types = list(/obj/item/stack/cable_coil)

