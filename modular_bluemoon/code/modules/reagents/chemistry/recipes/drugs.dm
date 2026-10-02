/datum/chemical_reaction/powder_cocaine
	name = "Powder Cocaine"
	id = "powder_cocaine"
	is_cold_recipe = TRUE
	required_reagents = list(/datum/reagent/drug/cocaine = 10)
	required_temp = 250
	mix_message = "The solution freezes into a powder!"
	mob_react = FALSE

/datum/chemical_reaction/powder_cocaine/on_reaction(datum/reagents/holder, multiplier)
	var/location = get_turf(holder.my_atom)
	for(var/i = 1, i <= multiplier, i++)
		new /obj/item/reagent_containers/cocaine(location)

/datum/chemical_reaction/freebase_cocaine
	name = "Freebase Cocaine"
	id = "freebase_cocaine"
	required_reagents = list(/datum/reagent/drug/cocaine = 10, /datum/reagent/water = 5, /datum/reagent/ash = 10)
	required_temp = 480
	mob_react = FALSE

/datum/chemical_reaction/freebase_cocaine/on_reaction(datum/reagents/holder, multiplier)
	var/location = get_turf(holder.my_atom)
	for(var/i = 1, i <= multiplier, i++)
		new /obj/item/reagent_containers/crack(location)
