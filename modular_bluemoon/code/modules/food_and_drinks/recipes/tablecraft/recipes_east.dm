
/*/datum/crafting_recipe
	var/list/machinery
	var/list/steps
	var/non_craftable
	var/list/tool_behaviors		/// String defines of items needed but not consumed. Lazy list.

///////////   GRINDER   ///////////

/datum/crafting_recipe/food/grinder
	machinery = list(/obj/machinery/reagentgrinder)
	steps = list("Put into grinder and grind")
	category = CAT_MISCFOOD
	non_craftable = TRUE

/datum/crafting_recipe/food/grinder/bonito
	reqs = list(/obj/item/reagent_containers/food/snacks/dried_fish = 1)
	result = /datum/reagent/consumable/bonito

/datum/crafting_recipe/food/knife/raw_noodles
	reqs = list(/obj/item/reagent_containers/food/snacks/rice_dough = 1)
	result = /obj/item/reagent_containers/food/snacks/spaghetti/rawnoodles
	category = CAT_MISCFOOD

///////////   KNIFE   ///////////

/datum/crafting_recipe/food/knife
	tool_behaviors = list(TOOL_KNIFE)
	steps = list("Slice with a knife")
	category = CAT_MISCFOOD
	non_craftable = TRUE

/datum/crafting_recipe/food/knife/raw_noodles
	reqs = list(/obj/item/reagent_containers/food/snacks/rice_dough = 1)
	result = /obj/item/reagent_containers/food/snacks/spaghetti/rawnoodles
	category = CAT_EAST*/

///////////   KNIFE   ///////////

/datum/crafting_recipe/food/raw_noodles
	reqs = list(/obj/item/reagent_containers/food/snacks/rice_dough = 1)
	result = /obj/item/reagent_containers/food/snacks/spaghetti/rawnoodles
	subcategory = CAT_EAST

/datum/crafting_recipe/food/rice_dough
	name = "Rice dough"
	reqs = list(
		/datum/reagent/consumable/flour = 10,
		/datum/reagent/consumable/rice = 10,
		/datum/reagent/water = 10,
	)
	result = /obj/item/reagent_containers/food/snacks/rice_dough
	subcategory = CAT_EAST

/datum/crafting_recipe/food/tonkatsuwurst
	name = "Tonkatsuwurst"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/sausage = 1,
		/obj/item/reagent_containers/food/snacks/fries = 1,
		/datum/reagent/consumable/worcestershire = 3,
		/datum/reagent/consumable/red_bay = 2,
	)
	result = /obj/item/reagent_containers/food/snacks/tonkatsuwurst
	subcategory = CAT_EAST
