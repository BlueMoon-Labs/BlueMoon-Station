// Рецепт креветки в биогенераторе - открывается только когда стоит
// T4-манипулятор. Разблокировка/блокировка идёт из
// /obj/machinery/biogenerator/RefreshParts().
/datum/design/shrimp
	name = "Shrimp"
	id = "shrimp"
	build_type = BIOGENERATOR
	materials = list(/datum/material/biomass = 4242)
	build_path = /obj/item/reagent_containers/food/snacks/meat/rawshrimp
	category = list("Food")
