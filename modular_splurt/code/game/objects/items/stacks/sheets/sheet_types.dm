/obj/item/stack/sheet/silk
	name = "silk"
	desc = "A long soft material. This one is just made out of cotton rather then any spiders or wyrms"
	singular_name = "silk sheet"
	icon_state = "sheet-silk"
	item_state = "sheet-cloth"
	novariants = TRUE
	merge_type = /obj/item/stack/sheet/silk
	grind_results = list(/datum/reagent/cellulose = 2)

//obj/item/stack/sheet/silk/Initialize(mapload, new_amount, merge = TRUE)
//	recipes = GLOB.silk_recipes
//	return ..()


GLOBAL_LIST_INIT(micro_bricks_recipes, list( \
	new /datum/stack_recipe("Road fourway", /obj/structure/micro_brick/road_fourway, 2, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	new /datum/stack_recipe("Road threeway", /obj/structure/micro_brick/road_threeway, 2, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	new /datum/stack_recipe("Road straight", /obj/structure/micro_brick/road_straight, 2, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	new /datum/stack_recipe("Road turn", /obj/structure/micro_brick/Road_turn, 2, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	null, \
	new /datum/stack_recipe("Small houses", /obj/structure/micro_brick/small_house, 5, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	new /datum/stack_recipe("Small business", /obj/structure/micro_brick/small_business, 5, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	new /datum/stack_recipe("Small warehouse", /obj/structure/micro_brick/small_warehouse, 5, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	new /datum/stack_recipe("Small museum", /obj/structure/micro_brick/small_museum, 5, time = 2, one_per_turf = TRUE, on_floor = TRUE), \
	null, \
	new /datum/stack_recipe("Small moon", /obj/item/moon, 5, time = 2), \
	null, \
	))

/obj/item/stack/sheet/micro_bricks
	name = "Micro Bricks"
	desc = "an studless version of the iconic bricks for recreation use on station with big crewmembers "
	singular_name = "Micro Brick"
	icon = 'modular_splurt/icons/obj/stack_objects.dmi'
	icon_state = "SmallBucket"
	item_state = "SmallBucket"
	custom_materials = list(/datum/material/iron=MINERAL_MATERIAL_AMOUNT)
	flags_1 = CONDUCT_1
	resistance_flags = FIRE_PROOF
	merge_type = /obj/item/stack/sheet/micro_bricks

/obj/item/stack/sheet/micro_bricks/fifty
	amount = 50

/obj/item/stack/sheet/micro_bricks/twenty
	amount = 20

/obj/item/stack/sheet/micro_bricks/ten
	amount = 10

/obj/item/stack/sheet/micro_bricks/five
	amount = 5

/obj/item/stack/sheet/micro_bricks/get_main_recipes()
	. = ..()
	. += GLOB.micro_bricks_recipes

// Hijack recipe loading to add new entries
/obj/item/stack/sheet/cloth/get_main_recipes()
	. = ..()
	. += new/datum/stack_recipe("handmade collar", /obj/item/clothing/neck/petcollar/handmade, 2) \
