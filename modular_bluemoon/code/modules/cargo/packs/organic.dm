/datum/supply_pack/organic/kvass_barrel
	name = "Kvass Barrel Crate"
	desc = "Выдалась слишком \"жаркая\" смена? Охладитесь и расслабьтесь с помощью кваса(tm), приготовленного по традиционным старинным рецептам! Содержит бочку кваса."
	cost = 6000
	contains = list(/obj/structure/reagent_dispensers/kvass_barrel)
	crate_name = "kvass barrel crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/organic/kvass_bottles
	name = "Kvass Bottles Crate"
	desc = "Выдалась слишком \"жаркая\" смена? Охладитесь и расслабьтесь с помощью кваса(tm), приготовленного по традиционным старинным рецептам! Содержит 10 бутылок кваса."
	cost = 2000
	contains = list(/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass,
					/obj/item/reagent_containers/food/drinks/kvass)
	crate_name = "kvass bottles crate"
	crate_type = /obj/structure/closet/crate/freezer

/datum/supply_pack/organic/shrimp
	name = "Shrimp Crate"
	desc = "Партия свежемороженых креветок для станции. Содержит 3 вакуумные упаковки, в каждой по 8 креветок."
	cost = 3000
	contains = list(/obj/item/storage/box/shrimp_pack,
					/obj/item/storage/box/shrimp_pack,
					/obj/item/storage/box/shrimp_pack)
	crate_name = "shrimp crate"
	crate_type = /obj/structure/closet/crate/freezer
