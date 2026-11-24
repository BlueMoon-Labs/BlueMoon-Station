/datum/bounty/item/assistant/condom
	name = "Filled Condom"
	description = "На ЦК творится что-то странное: просят наполненные презервативы. Подойдут и купленные в автомате, если наполнили их вы."
	reward = 6666
	required_count = 5
	wanted_types = list(/obj/item/genital_equipment/condom)

/datum/bounty/item/assistant/condom/applies_to(obj/O)
	if(!..())
		return FALSE
	var/obj/item/genital_equipment/condom/T = O
	return T.reagents.total_volume > 0

/// Автомат продаёт только пустые: заказу нужно то, чем презерватив наполнили.
/datum/bounty/item/assistant/condom/econ_accepts_bought(atom/movable/thing)
	return TRUE

