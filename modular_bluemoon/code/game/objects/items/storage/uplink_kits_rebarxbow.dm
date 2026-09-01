/obj/item/storage/box/syndie_kit/rebarxbowsyndie
	name = "Boxed Rebar Crossbow"
	desc = "A scoped weapon with low armor penetration, but devastating against flesh. Features instruction manual for making specialty ammo."

/obj/item/storage/box/syndie_kit/rebarxbowsyndie/PopulateContents()
	new /obj/item/book/granter/crafting_recipe/rebarxbowsyndie_ammo(src)
	new /obj/item/gun/ballistic/rebarxbow/syndie(src)
	new /obj/item/storage/bag/rebar_quiver/syndicate(src)
