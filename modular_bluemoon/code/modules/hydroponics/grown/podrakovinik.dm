/obj/item/seeds/schizoshroom
	name = "pack of podrakovinik mycelium"
	desc = "This mycelium grows into podrakovinik mushrooms."
	icon = 'modular_bluemoon/icons/obj/hydroponics/podrakovinik.dmi'
	icon_state = "mycelium-podrakovinik"
	species = "podrakovinik"
	plantname = "podrakovinik"
	product = /obj/item/reagent_containers/food/snacks/grown/mushroom/schizoshroom
	maturation = 7
	production = 1
	yield = 5
	potency = 15
	growthstages = 3
	genes = list(/datum/plant_gene/trait/plant_type/fungal_metabolism)
	growing_icon = 'modular_bluemoon/icons/obj/hydroponics/podrakovinik.dmi'
	reagents_add = list(/datum/reagent/psyshillium = 0.15, /datum/reagent/consumable/nutriment = 0.02)

/obj/item/reagent_containers/food/snacks/grown/mushroom/schizoshroom
	seed = /obj/item/seeds/schizoshroom
	name = "Podrakovinik"
	desc = "Те самые грибы, которые растут в общественных туалетах."
	icon = 'modular_bluemoon/icons/obj/hydroponics/podrakovinik.dmi'
	icon_state = "podrakovinik"
	filling_color = "#DAA520"
	wine_power = 80
