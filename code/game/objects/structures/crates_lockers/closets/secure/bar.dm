/obj/structure/closet/secure_closet/bar
	name = "booze storage"
	req_access = list(ACCESS_BAR)
	icon_state = "cabinet"
	resistance_flags = FLAMMABLE
	max_integrity = 70
	material_drop = /obj/item/stack/sheet/mineral/wood
	cutting_tool = TOOL_SCREWDRIVER
	door_anim_time = 0 // no animation

/obj/structure/closet/secure_closet/bar/PopulateContents()
	..()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/food/drinks/beer( src )

/obj/structure/closet/secure_closet/bar/lavaland_bartender_booze

/obj/structure/closet/secure_closet/bar/lavaland_bartender_booze/PopulateContents()
	new /obj/item/vending_refill/cigarette(src)
	new /obj/item/vending_refill/boozeomat(src)
	new /obj/item/storage/backpack/duffelbag(src)
	for(var/i in 1 to 14)
		new /obj/item/reagent_containers/food/drinks/beer/light(src)
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/food/drinks/sillycup(src)

/obj/structure/closet/secure_closet/bar/lavaland_bartender_clothes
