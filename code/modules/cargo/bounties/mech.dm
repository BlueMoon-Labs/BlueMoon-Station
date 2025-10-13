/datum/bounty/item/mech/New()
	..()
	description = "Upper management has requested one [name] mech be sent as soon as possible. Ship it to receive a large payment."

/datum/bounty/item/mech/ship(obj/O)
	if(!applies_to(O))
		return
	if(istype(O, /obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/M = O
		M.wreckage = null // So the mech doesn't explode.
	..()

/datum/bounty/item/mech/mark_high_priority(scale_reward)
	return ..(max(scale_reward * 0.7, 1.2))

/datum/bounty/item/mech/ripley
	name = "APLU \"Ripley\""
	reward = 28000
	wanted_types = list(/obj/vehicle/sealed/mecha/working/ripley)
	exclude_types = list(/obj/vehicle/sealed/mecha/working/ripley/firefighter)

/datum/bounty/item/mech/firefighter
	name = "APLU \"Firefighter\""
	reward = 35000
	wanted_types = list(/obj/vehicle/sealed/mecha/working/ripley/firefighter)

/datum/bounty/item/mech/odysseus
	name = "Odysseus"
	reward = 25000
	wanted_types = list(/obj/vehicle/sealed/mecha/medical/odysseus)

/datum/bounty/item/mech/gygax
	name = "Gygax"
	reward = 55000
	wanted_types = list(/obj/vehicle/sealed/mecha/combat/gygax)

/datum/bounty/item/mech/durand
	name = "Durand"
	reward = 53000
	wanted_types = list(/obj/vehicle/sealed/mecha/combat/durand)

/datum/bounty/item/mech/phazon
	name = "Phazon"
	reward = 66600
	wanted_types = list(/obj/vehicle/sealed/mecha/combat/phazon)

/datum/bounty/item/mech/medigax // BLUEMOON ADD
	name = "Medical Gygax"
	reward = 34200
	wanted_types = list(/obj/vehicle/sealed/mecha/medical/medigax)

/datum/bounty/item/mech/savannah_ivanov // BLUEMOON ADD
	name = "Savannah Ivanov"
	reward = 57000
	wanted_types = list(/obj/vehicle/sealed/mecha/combat/savannah_ivanov)
