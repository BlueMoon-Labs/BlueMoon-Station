//Donator drinks
/datum/chemical_reaction/honeystones_love
	results = list(/datum/reagent/consumable/honeystones_love = 2)
	required_reagents = list(/datum/reagent/consumable/honey = 7, /datum/reagent/drug/aphrodisiacplus = 1, /datum/reagent/consumable/orangejuice = 1, /datum/reagent/consumable/milk= 1)

// Other stuff

// BLUEMOON ADD START || Shadekin Mutation Toxin
// Температура реакции токсина мутации шейдкина (47 °C).
#define SHADEKIN_MUTATION_REQUIRED_TEMP 320

/datum/chemical_reaction/mutationtoxin/shadekin
	name = "токсин мутации шейдкина"
	id = /datum/reagent/mutationtoxin/shadekin
	results = list(/datum/reagent/mutationtoxin/shadekin = 1)
	required_reagents = list(
		/datum/reagent/consumable/bananashake = 3,
		/datum/reagent/medicine/mannitol = 2,
		/datum/reagent/drug/happiness = 2,
		/datum/reagent/mutationtoxin = 1
	)
	required_temp = SHADEKIN_MUTATION_REQUIRED_TEMP
// BLUEMOON ADD END
