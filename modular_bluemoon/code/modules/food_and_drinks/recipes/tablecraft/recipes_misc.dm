/datum/crafting_recipe/food/redbayseasoning
	name = "Red Bay Seasoning"
	reqs = list(
		/datum/reagent/consumable/blackpepper = 5,
		/obj/item/reagent_containers/food/snacks/grown/herbs = 1,
		/datum/reagent/consumable/garlic = 3,
		/datum/reagent/consumable/sodiumchloride = 5,
		/obj/item/reagent_containers/food/condiment = 1,
	)
	result = /obj/item/reagent_containers/food/condiment/red_bay
	subcategory = CAT_MISCFOOD

/datum/crafting_recipe/food/shrimpwrap
	name = "Shrimp wrap"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/tortilla = 1,
		/obj/item/reagent_containers/food/snacks/grown/cabbage = 1,
		/obj/item/reagent_containers/food/snacks/cheesewedge = 1,
		/obj/item/reagent_containers/food/snacks/meat/shrimp = 2,
	)
	result = /obj/item/reagent_containers/food/snacks/shrimpwrap
	subcategory = CAT_SEAFOOD

/datum/crafting_recipe/food/shrimppizza
	name = "Shrimp pizza"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/pizzabread = 1,
		/obj/item/reagent_containers/food/snacks/meat/shrimp = 4,
		/obj/item/reagent_containers/food/snacks/cheesewedge = 1,
		/obj/item/reagent_containers/food/snacks/grown/tomato = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/pizza/shrimp
	subcategory = CAT_PIZZA

/datum/crafting_recipe/food/shrimp_sushi
	name = "Ebi Hosomaki"
	reqs = list(
		/datum/reagent/consumable/soysauce = 3,
		/obj/item/reagent_containers/food/snacks/sushi_rice = 1,
		/obj/item/reagent_containers/food/snacks/meat/shrimp = 2,
		/obj/item/reagent_containers/food/snacks/sea_weed = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/shrimp_sushi
	subcategory = CAT_SEAFOOD

/datum/crafting_recipe/food/shrimp_onigiri
	name = "Shrimp Onigiri"
	reqs = list(
		/datum/reagent/consumable/soysauce = 1,
		/obj/item/reagent_containers/food/snacks/sushi_rice = 1,
		/obj/item/reagent_containers/food/snacks/meat/shrimp = 1,
		/obj/item/reagent_containers/food/snacks/sea_weed = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/shrimp_onigiri
	subcategory = CAT_SEAFOOD


/datum/crafting_recipe/food/shrimpbun
	name = "Shrimp bun"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/bun = 1,
		/obj/item/reagent_containers/food/snacks/meat/shrimp = 1,
	)
	result = /obj/item/reagent_containers/food/snacks/shrimpbun
	subcategory = CAT_BREAD

/datum/crafting_recipe/food/shrimpskewer
	name = "Shrimp skewer"
	reqs = list(
		/obj/item/stack/rods = 1,
		/obj/item/reagent_containers/food/snacks/meat/shrimp = 3,
	)
	result = /obj/item/reagent_containers/food/snacks/kebab/shrimp
	subcategory = CAT_MEAT
