/datum/bounty/item/alien_organs
	name = "Alien Organs"
	description = "NT изучает биологию ксеноморфов: пришлите органы из их тел. Напечатанные на станции не принимаются."
	reward = 35000
	required_count = 3
	wanted_types = list(/obj/item/organ/brain/alien, /obj/item/organ/alien, /obj/item/organ/body_egg/alien_embryo)

/// Нужна настоящая биология ксеноморфа: органы, напечатанные на станции, не годятся.
/datum/bounty/item/alien_organs/applies_to(obj/O)
	return ..() && !islist(O.econ_print_cap)

/datum/bounty/item/alien_organs/econ_shortfall(atom/movable/thing)
	if(islist(thing.econ_print_cap) && is_type_in_list(thing, wanted_types))
		return "[thing.name]: напечатан на станции, а NT нужны органы из тел ксеноморфов"

/datum/bounty/item/syndicate_documents
	name = "Syndicate Documents"
	description = "Intel regarding the syndicate is highly prized at CentCom. If you find syndicate documents, ship them. You could save lives."
	reward = 40000
	wanted_types = list(/obj/item/documents/syndicate, /obj/item/documents/photocopy)

/datum/bounty/item/syndicate_documents/applies_to(obj/O)
	if(!..())
		return FALSE
	if(istype(O, /obj/item/documents/photocopy))
		var/obj/item/documents/photocopy/Copy = O
		return (Copy.copy_type && ispath(Copy.copy_type, /obj/item/documents/syndicate))
	return TRUE

/datum/bounty/item/adamantine
	name = "Adamantine"
	description = "Nanotrasen's anomalous materials division is in desparate need for Adamantine. Send them a large shipment and we'll make it worth your while."
	reward = 30000
	required_count = 10
	wanted_types = list(/obj/item/stack/sheet/mineral/adamantine)
