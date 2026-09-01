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

/datum/crafting_recipe/makeshift_platecarrier
	name = "Makeshift Plate Carrier"
	result = /obj/item/clothing/suit/armor/hos/platecarrier/makeshift
	reqs = list(
		/obj/item/clothing/suit/armor/vest = 1,
		/obj/item/storage/belt/security = 1,
	)
	tools = list(TOOL_WIRECUTTER)
	time = 60
	category = CAT_CLOTHING

/datum/crafting_recipe/makeshift_platecarrier/New()
	. = ..()
	blacklist |= (subtypesof(/obj/item/clothing/suit/armor/vest) - list(/obj/item/clothing/suit/armor/vest/alt))

/datum/crafting_recipe/makeshift_platecarrier/check_requirements(mob/user, list/collected_requirements)
	for(var/obj/item/storage/belt/security/belt in collected_requirements[/obj/item/storage/belt/security])
		if(belt.contents.len)
			return FALSE
	return TRUE
