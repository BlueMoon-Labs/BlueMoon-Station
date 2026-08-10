/datum/crafting_recipe/flower_crown
	name = "Flower Crown"
	result = /obj/item/clothing/head/flower_crown
	reqs = list(/obj/item/reagent_containers/food/snacks/grown/poppy = 3,
					/obj/item/reagent_containers/food/snacks/grown/poppy/lily = 3,
					/obj/item/grown/sunflower = 3
					)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/sunflower_crown
	name = "Sunflower Crown"
	result = /obj/item/clothing/head/sunflower_crown
	reqs = list(/obj/item/grown/sunflower = 5)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/poppy_crown
	name = "Poppy Crown"
	result = /obj/item/clothing/head/poppy_crown
	reqs = list(/obj/item/reagent_containers/food/snacks/grown/poppy = 5)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/lily_crown
	name = "Lily Crown"
	result = /obj/item/clothing/head/lily_crown
	reqs = list(/obj/item/reagent_containers/food/snacks/grown/poppy/lily = 5)
	time = 2 SECONDS
	category = CAT_CLOTHING

/datum/crafting_recipe/geranium_crown
	name = "Geranium Crown"
	result = /obj/item/clothing/head/geranium_crown
	reqs = list(/obj/item/reagent_containers/food/snacks/grown/poppy/geranium = 5)
	time = 2 SECONDS
	category = CAT_CLOTHING
