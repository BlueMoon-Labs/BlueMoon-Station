//////////////////////////////////////////////////////////////////////////////
////////////////////////////// Deep Space /////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// BLUEMOON ADD - Эксклюзивный каталог, доступен только консоли
// /obj/machinery/computer/cargo/express/ds

/datum/supply_pack/ds
	group = "Deep Space"
	exclusive_consoles = list(/obj/machinery/computer/cargo/express/ds)
	crate_type = /obj/structure/closet/crate/syndie

/datum/supply_pack/ds/red
	name = "Blood Red Syndicate Hardsuit"
	desc = "Новенькие и свеженькие костюмы для боевых задач. Содержит 3 штуки"
	cost = 15000
	contains = list(/obj/item/clothing/suit/space/hardsuit/syndi,
					/obj/item/clothing/suit/space/hardsuit/syndi,
					/obj/item/clothing/suit/space/hardsuit/syndi)
	crate_name = "deep space crate"

/datum/supply_pack/ds/elite
	name = "Elite Syndicate Hardsuit"
	desc = "Новенькие и свеженькие костюмы для боевых задач. Содержит 2 штуки"
	cost = 25000
	contains = list(/obj/item/clothing/suit/space/hardsuit/syndi/elite,
					/obj/item/clothing/suit/space/hardsuit/syndi/elite)
	crate_name = "deep space crate"

/datum/supply_pack/ds/elitewinter
	name = "Elite winter Syndicate Hardsuit"
	desc = "Новенькие и свеженькие костюмы для боевых задач. Содержит 2 штуки"
	cost = 27000
	contains = list(/obj/item/clothing/suit/space/hardsuit/syndi/elite/winter,
					/obj/item/clothing/suit/space/hardsuit/syndi/elite/winter)
	crate_name = "deep space crate"

/datum/supply_pack/ds/cybersun
	name = "Cybersun Hardsuit"
	desc = "Новенькие и свеженькие Киберсан костюмы для боевых задач. Содержит 2 штуки"
	cost = 27000
	contains = list(/obj/item/clothing/suit/space/hardsuit/cybersun,
					/obj/item/clothing/suit/space/hardsuit/cybersun)
	crate_name = "deep space crate"

/datum/supply_pack/ds/sniper
	name = "Снайперская Винтовка"
	desc = "Большая, Запрещенная, и крайне убойная винтовка для устранения всего живого что существует. В комплекте одна винтовка и магазин."
	cost = 30000
	contains = list(/obj/item/gun/ballistic/automatic/sniper_rifle,
					/obj/item/ammo_box/magazine/sniper_rounds)
	crate_name = "deep space crate"

/datum/supply_pack/ds/c20r
	name = "Ящик с C-20r"
	desc = "Компактный автомат для устранения целей. содержит 2 штуки"
	cost = 25000
	contains = list(/obj/item/gun/ballistic/automatic/c20r,
					/obj/item/gun/ballistic/automatic/c20r,
					/obj/item/ammo_box/magazine/smgm45,
					/obj/item/ammo_box/magazine/smgm45)
	crate_name = "deep space crate"

/datum/supply_pack/ds/c20rmag
	name = "Ящик с Магазинами для C-20r"
	desc = "Новенькие Магазины для ПП"
	cost = 10000
	contains = list(/obj/item/ammo_box/magazine/smgm45,
					/obj/item/ammo_box/magazine/smgm45,
					/obj/item/ammo_box/magazine/smgm45,
					/obj/item/ammo_box/magazine/smgm45)
	crate_name = "deep space crate"

/datum/supply_pack/ds/esword
	name = "Ящик с Лазерными Мечами"
	desc = "Лазерные мечи. В коплекте 3 штуки."
	cost = 25000
	contains = list(/obj/item/melee/transforming/energy/sword,
					/obj/item/melee/transforming/energy/sword,
					/obj/item/melee/transforming/energy/sword)
	crate_name = "deep space crate"
