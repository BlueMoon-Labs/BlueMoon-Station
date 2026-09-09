/obj/item/seeds/cocaleaf
	name = "coca leaf seed pack"
	desc = "These seeds grow into coca shrubs. They make you feel energized just looking at them..."
	icon = 'modular_bluemoon/cocaine/icons/seeds_cocoleaf.dmi'
	growing_icon = 'modular_bluemoon/cocaine/icons/growing_cocoleaf.dmi'
	icon_state = "seed-cocoleaf"
	species = "cocoleaf"
	plantname = "Coca Leaves"
	maturation = 8
	potency = 20
	growthstages = 1
	growing_icon_offset_y = 10
	product = /obj/item/reagent_containers/food/snacks/grown/cocaleaf
	mutatelist = list()
	reagents_add = list(/datum/reagent/drug/cocaine = 0.3, /datum/reagent/consumable/nutriment = 0.15)

/obj/item/reagent_containers/food/snacks/grown/cocaleaf
	seed = /obj/item/seeds/cocaleaf
	name = "coca leaf"
	desc = "A leaf of the coca shrub, which contains a potent psychoactive alkaloid known as 'cocaine'."
	icon = 'modular_bluemoon/cocaine/icons/harvest_cocoleaf.dmi'
	icon_state = "cocoleaf"
	foodtype = FRUIT
	tastes = list("leaves" = 1)
	distill_reagent = /datum/reagent/consumable/ethanol/sins_delight
