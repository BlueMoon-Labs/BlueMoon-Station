/*
 * Wood
 */

GLOBAL_LIST_INIT(wood_recipes_generic, list (
	new/datum/stack_recipe_list("Pews", list(
		new /datum/stack_recipe("Pew (Middle)", /obj/structure/chair/pew, 3, one_per_turf = TRUE, on_floor = TRUE),
		new /datum/stack_recipe("Pew (Left)", /obj/structure/chair/pew/left, 3, one_per_turf = TRUE, on_floor = TRUE),
		new /datum/stack_recipe("Pew (Right)", /obj/structure/chair/pew/right, 3, one_per_turf = TRUE, on_floor = TRUE),
		)),
	new/datum/stack_recipe_list("Weaponry", list(
		new/datum/stack_recipe("Rifle Stock", /obj/item/weaponcrafting/stock, 10, time = 20),
		new/datum/stack_recipe("Buckler", /obj/item/shield/riot/buckler, 25, time = 120),
		new/datum/stack_recipe("Baseball Bat", /obj/item/melee/baseball_bat, 25, time = 100),
		)),
	new/datum/stack_recipe_list("Painting", list(
		new/datum/stack_recipe("Picture Frame", /obj/item/wallframe/picture, 1, time = 10),
		new/datum/stack_recipe("Painting Frame", /obj/item/wallframe/painting, 1, time = 10),
		new/datum/stack_recipe("Large Painting Frame", /obj/item/wallframe/painting/large, 1, time = 10),
		)),
	new/datum/stack_recipe_list("Doors", list(
		new/datum/stack_recipe("Door", /obj/structure/mineral_door/wood, 10, time = 20, one_per_turf = TRUE, on_floor = TRUE),
		new/datum/stack_recipe("Rustic Door", /obj/structure/mineral_door/woodrustic, 10, time = 20, one_per_turf = TRUE, on_floor = TRUE),
		)),
	new/datum/stack_recipe_list("Gardening", list(
		new/datum/stack_recipe("Barrel", /obj/structure/fermenting_barrel, 10, time = 20, one_per_turf = TRUE, on_floor = TRUE),
		new/datum/stack_recipe("Bucket", /obj/item/reagent_containers/glass/bucket/wood, 2, time = 30),
		new/datum/stack_recipe("Stick For Angry Plants", /obj/item/scythe/stick, 25, time = 100),
		new/datum/stack_recipe("Drying Rack", /obj/machinery/smartfridge/drying_rack, 10, time = 15, one_per_turf = TRUE, on_floor = TRUE),
		new/datum/stack_recipe("Loom", /obj/structure/loom, 10, time = 15, one_per_turf = TRUE, on_floor = TRUE),
		new/datum/stack_recipe("Apiary", /obj/structure/beebox, 40, time = 50),
		new/datum/stack_recipe("Honey Frame", /obj/item/honey_frame, 5, time = 10),
		)),
	new/datum/stack_recipe("Sandals", /obj/item/clothing/shoes/sandal, 1),
	new/datum/stack_recipe("Sauna Oven", /obj/structure/sauna_oven, 50, time = 15 SECONDS, one_per_turf = TRUE, on_floor = TRUE),
	new/datum/stack_recipe("Tiki Mask", /obj/item/clothing/mask/gas/tiki_mask, 2),
	new/datum/stack_recipe("Rolling Pin", /obj/item/kitchen/rollingpin, 2, time = 30),
	new/datum/stack_recipe("Unrolling Pin", /obj/item/kitchen/unrollingpin, 2, time = 30),
	new/datum/stack_recipe("Coffin", /obj/structure/closet/crate/coffin, 5, time = 15, one_per_turf = TRUE, on_floor = TRUE),
	new/datum/stack_recipe("Book Case", /obj/structure/bookcase, 3, time = 15, one_per_turf = TRUE, on_floor = TRUE),
	new/datum/stack_recipe("Ore Box", /obj/structure/ore_box, 4, time = 50, one_per_turf = TRUE, on_floor = TRUE),
	new/datum/stack_recipe("Display Case Chassis", /obj/structure/displaycase_chassis, 5, one_per_turf = TRUE, on_floor = TRUE),
	new/datum/stack_recipe("Mortar", /obj/item/reagent_containers/glass/mortar, 3),
	new/datum/stack_recipe("Notice Board Frame", /obj/item/wallframe/noticeboard, 5, time = 10),
	new/datum/stack_recipe("Stamp Block", /obj/item/stamp_block, 10, time = 10),
	new/datum/stack_recipe("Cup", /obj/item/reagent_containers/food/drinks/drinkingglass/wooden, 1, time = 50),
	))

GLOBAL_LIST_INIT(wood_recipes, list (
	new/datum/stack_recipe_list("Floor Tiles", list(
		new/datum/stack_recipe("Floor Tile", /obj/item/stack/tile/wood, 1, 4, 20),
		new/datum/stack_recipe("Large floor Tile", /obj/item/stack/tile/wood/wood_large, 1, 4, 20),
		new/datum/stack_recipe("Tiled floor Tile", /obj/item/stack/tile/wood/wood_tiled, 1, 4, 20),
		new/datum/stack_recipe("Diagonal Floor Tile", /obj/item/stack/tile/wood/wood_diagonal, 1, 4, 20),
		)),
	new/datum/stack_recipe_list("Chairs", list(
		new/datum/stack_recipe("Chair", /obj/structure/chair/wood, 3, time = 10, one_per_turf = TRUE, on_floor = TRUE),
		new/datum/stack_recipe("Winged Chair", /obj/structure/chair/wood/wings, 3, time = 10, one_per_turf = TRUE, on_floor = TRUE),
		new/datum/stack_recipe("Plywood Chair", /obj/structure/chair/comfy/plywood, 4, time = 10, one_per_turf = TRUE, on_floor = TRUE),
		)),
	new/datum/stack_recipe_list("Barricade", list(
		new/datum/stack_recipe("Barricade", /obj/structure/barricade/wooden, 5, time = 50, one_per_turf = TRUE, on_floor = TRUE),
		new/datum/stack_recipe("Half-Barricade", /obj/structure/deployable_barricade/wooden, 5, time = 2 SECONDS, one_per_turf = TRUE, on_floor = TRUE),
		)),
	new/datum/stack_recipe("Table Frame", /obj/structure/table_frame/wood, 2, time = 10),
	new/datum/stack_recipe("Crate", /obj/structure/closet/crate/wooden, 6, time = 50, one_per_turf = TRUE, on_floor = TRUE),
	new/datum/stack_recipe("Dog Bed", /obj/structure/bed/dogbed, 10, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new/datum/stack_recipe("Dresser", /obj/structure/dresser, 10, time = 15, one_per_turf = TRUE, on_floor = TRUE),
	))

/obj/item/stack/sheet/mineral/wood
	name = "wooden plank"
	desc = "One can only guess that this is a bunch of wood. You might be able to make a stake with this if you use something sharp on it"
	singular_name = "wood plank"
	icon_state = "sheet-wood"
	item_state = "sheet-wood"
	icon = 'icons/obj/stack_objects.dmi'
	custom_materials = list(/datum/material/wood=MINERAL_MATERIAL_AMOUNT)
	sheettype = "wood"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 0)
	resistance_flags = FLAMMABLE
	merge_type = /obj/item/stack/sheet/mineral/wood
	material_type = /datum/material/wood
	grind_results = list(/datum/reagent/cellulose = 20)
	walltype = /turf/closed/wall/mineral/wood
	var/wood_type = "wood_recipes"

/obj/item/stack/sheet/mineral/wood/attackby(obj/item/W, mob/user, params) // NOTE: sheet_types.dm is where the WOOD stack lives. Maybe move this over there.
	// Taken from /obj/item/stack/rods/attackby in [rods.dm]
	if(W.get_sharpness())
		user.visible_message("[user] begins whittling [src] into a pointy object.", \
				 "<span class='notice'>You begin whittling [src] into a sharp point at one end.</span>", \
				 "<span class='italics'>You hear wood carving.</span>")
		// 8 Second Timer
		if(!do_after(user, 8 SECONDS,  src))
			return
		// Make Stake
		var/obj/item/stake/basic/new_item = new(user.loc)
		user.visible_message("[user] finishes carving a stake out of [src].", \
				 "<span class='notice'>You finish carving a stake out of [src].</span>")
		// Prepare to Put in Hands (if holding wood)
		var/obj/item/stack/sheet/mineral/wood/N = src
		var/replace = (user.get_inactive_held_item() == N)
		// Use Wood
		N.use(1)
		// If stack depleted, put item in that hand (if it had one)
		if (!N && replace)
			user.put_in_hands(new_item)
	if(istype(W, merge_type))
		var/obj/item/stack/S = W
		if(merge(S))
			to_chat(user, "<span class='notice'>Your [S.name] stack now contains [S.get_amount()] [S.singular_name]\s.</span>")
	else
		. = ..()

/obj/item/stack/sheet/mineral/wood/get_main_recipes()
	. = ..()
	. += GLOB.wood_recipes_generic
	. += GLOB.vars[wood_type]

/obj/item/stack/sheet/mineral/wood/twenty
	amount = 20

/obj/item/stack/sheet/mineral/wood/fifty
	amount = 50

/*
 * Shadow Wood
 */
GLOBAL_LIST_INIT(shadow_wood_recipes, list ( \
	new /datum/stack_recipe("Floor Tile", /obj/item/stack/tile/wood/shadow, 1, 4, 20),
	new /datum/stack_recipe("Table Frame", /obj/structure/table_frame/shadow_wood, 2, time = 10),
	new /datum/stack_recipe("Chair", /obj/structure/chair/wood/shadow, 3, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Crate", /obj/structure/closet/crate/wooden/shadow, 6, time = 50, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Bed", /obj/structure/bed/shadow, 2, time = 70, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Double Bed", /obj/structure/bed/double/shadow, 4, time = 140, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Barricade", /obj/structure/barricade/wooden/shadow, 5, time = 50, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Dog Bed", /obj/structure/bed/dogbed/shadow, 10, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Dresser", /obj/structure/dresser/shadow, 10, time = 15, one_per_turf = TRUE, on_floor = TRUE),
	))

/obj/item/stack/sheet/mineral/wood/shadow
	name = "shadow wood"
	desc = "An purplish wood, it has nothing of special besides its color."
	singular_name = "shadow wood plank"
	icon_state = "sheet-shadow_wood"
	item_state = "sheet-shadow_wood"
	icon = 'modular_splurt/icons/obj/stack_objects.dmi'
	sheettype = "shadow_wood"
	merge_type = /obj/item/stack/sheet/mineral/wood/shadow
	novariants = TRUE
	grind_results = list(/datum/reagent/carbon = 20)
	walltype = /turf/closed/wall/mineral/wood/shadow
	wood_type = "shadow_wood_recipes"

/obj/item/stack/sheet/mineral/wood/shadow/fifty
	amount = 50

GLOBAL_LIST_INIT(mush_wood_recipes, list (
	new /datum/stack_recipe("Floor Tile", /obj/item/stack/tile/wood/mushroom, 1, 4, 20),
	new /datum/stack_recipe("Table Frame", /obj/structure/table_frame/mushwood, 2, time = 10),
	new /datum/stack_recipe("Chair", /obj/structure/chair/wood/mushroom, 3, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Barricade", /obj/structure/barricade/wooden/mushroom, 5, time = 50, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Dog Bed", /obj/structure/bed/dogbed/mushroom, 10, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Dresser", /obj/structure/dresser/mushroom, 10, time = 15, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("Crate", /obj/structure/closet/crate/wooden/mushroom, 6, time = 50, one_per_turf = TRUE, on_floor = TRUE),
	))

/*
 * Mushroom Wood
 */

/obj/item/stack/sheet/mineral/wood/mushroom
	name = "mushroom \"wood\""
	desc = "A material similar to wood, except for being fireproof."
	singular_name = "mushroom plank"
	icon_state = "sheet-mush_wood"
	item_state = "sheet-mush_wood"
	icon = 'modular_splurt/icons/obj/stack_objects.dmi'
	sheettype = "mush_wood"
	merge_type = /obj/item/stack/sheet/mineral/wood/mushroom
	novariants = TRUE
	grind_results = list(/datum/reagent/carbon = 20)
	walltype = /turf/closed/wall/mineral/wood/mushroom
	wood_type = "mush_wood_recipes"

/obj/item/stack/sheet/mineral/wood/mushroom/fifty
	amount = 50
