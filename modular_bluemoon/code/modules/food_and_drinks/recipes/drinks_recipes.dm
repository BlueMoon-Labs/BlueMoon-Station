// Kvass crafting
/datum/chemical_reaction/kvass
	name = "Kvass"
	id = /datum/reagent/consumable/kvass
	results = list(/datum/reagent/consumable/kvass = 3)
	required_reagents = list(/datum/reagent/consumable/ethanol/beer = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/flour = 1)

/datum/chemical_reaction/icelatte
	name = "Iced Latte"
	id = /datum/reagent/consumable/icelatte
	results = list(/datum/reagent/consumable/icelatte = 3)
	required_reagents = list(/datum/reagent/consumable/ice = 1, /datum/reagent/consumable/cafe_latte = 2)

/datum/chemical_reaction/raf
	name = "Raf"
	id = /datum/reagent/consumable/raf
	results = list(/datum/reagent/consumable/raf = 4)
	required_reagents = list(/datum/reagent/consumable/cafe_latte = 1, /datum/reagent/consumable/milk = 1, /datum/reagent/consumable/cream = 1, /datum/reagent/consumable/sugar = 1)

/datum/chemical_reaction/iceraf
	name = "Iced Raf"
	id = /datum/reagent/consumable/iceraf
	results = list(/datum/reagent/consumable/iceraf = 3)
	required_reagents = list(/datum/reagent/consumable/ice = 1, /datum/reagent/consumable/raf = 2)

/datum/chemical_reaction/americano
	name = "Americano"
	id = /datum/reagent/consumable/americano
	results = list(/datum/reagent/consumable/americano = 3)
	required_reagents = list(/datum/reagent/consumable/coffee = 1, /datum/reagent/water = 2)

/datum/chemical_reaction/iceamericano
	name = "Iced Americano"
	id = /datum/reagent/consumable/iceamericano
	results = list(/datum/reagent/consumable/iceamericano = 3)
	required_reagents = list(/datum/reagent/consumable/ice = 1, /datum/reagent/consumable/americano = 2)
