//////////////////////////////////////////////////////////////////////////////
////////////////////////////// Deep Space /////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// BLUEMOON ADD - Эксклюзивный каталог, доступен только консоли
// /obj/machinery/computer/cargo/express/ds

/datum/supply_pack/ds
	group = "Deep Space"
	exclusive_consoles = list(/obj/machinery/computer/cargo/express/ds)
	crate_type = /obj/structure/closet/crate/syndie

/datum/supply_pack/ds/fpin
	name = "Syndicate firing pins"
	desc = "Бойки с привязкой на имлпант системы - свой/чужой. Содержит 6 штук."
	cost = 7500
	contains = list(/obj/item/firing_pin/implant/pindicate,
					/obj/item/firing_pin/implant/pindicate,
					/obj/item/firing_pin/implant/pindicate,
					/obj/item/firing_pin/implant/pindicate,
					/obj/item/firing_pin/implant/pindicate,
					/obj/item/firing_pin/implant/pindicate)
	crate_name = "deep space crate"


/datum/supply_pack/ds/redsoft
	name = "Syndicate Softsuit"
	desc = "Надёжные и изъятые с хранения костюмы для борьбы с вакуумом в условиях боевых действий. Содержит 3 комплекта."
	cost = 7500
	contains = list(/obj/item/clothing/suit/space/syndicate,
					/obj/item/clothing/suit/space/syndicate,
					/obj/item/clothing/suit/space/syndicate,
					/obj/item/clothing/head/helmet/space/syndicate,
					/obj/item/clothing/head/helmet/space/syndicate,
					/obj/item/clothing/head/helmet/space/syndicate)
	crate_name = "deep space crate"

/datum/supply_pack/ds/redmod
	name = "Blood Red Modsuit"
	desc = "Самая первая модель МОД костюма синдиката. Всё ещё достаточно бронирован и функционален."
	cost = 15000
	contains = list(/obj/item/mod/control/pre_equipped/traitor)
	crate_name = "deep space crate"

/datum/supply_pack/ds/red
	name = "Blood Red Syndicate Hardsuit"
	desc = "Новенькие и свеженькие костюмы для боевых задач. Содержит 3 штуки"
	cost = 15000
	contains = list(/obj/item/clothing/suit/space/hardsuit/syndi,
					/obj/item/clothing/suit/space/hardsuit/syndi,
					/obj/item/clothing/suit/space/hardsuit/syndi)
	crate_name = "deep space crate"

/datum/supply_pack/ds/makarov
	name = "Ящик с комплектами ПМ"
	desc = "Старая конструкция с новыми материалами и производством синдиката. Идеально для полевых операций. Содержит 3 набора."
	cost = 15000
	contains = list(/obj/item/storage/box/syndie_kit/pistol,
					/obj/item/storage/box/syndie_kit/pistol,
					/obj/item/storage/box/syndie_kit/pistol)
	crate_name = "deep space crate"

/datum/supply_pack/ds/makarovmag
	name = "Ящик с Магазинами для ПМ"
	desc = "Новенькие Магазины для Макарова"
	cost = 3000
	contains = list(/obj/item/ammo_box/magazine/m10mm,
					/obj/item/ammo_box/magazine/m10mm,
					/obj/item/ammo_box/magazine/m10mm,
					/obj/item/ammo_box/magazine/m10mm)
	crate_name = "deep space crate"

/datum/supply_pack/ds/redinfil
	name = "Tactical operative equipment"
	desc = "Экипировка инфильтратора времён корпоративной войны с Нанотрейзен. Вам кажется она всё ещё пахнет как новый автомобиль..."
	cost = 18000
	contains = list(/obj/item/storage/toolbox/infiltrator)
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
	desc = "Новенькие и свеженькие костюмы для работы в зимних условиях. Оснащены дорогим синт. мехом по требованию консорциума."
	cost = 27000
	contains = list(/obj/item/clothing/suit/space/hardsuit/syndi/elite/winter,
					/obj/item/clothing/suit/space/hardsuit/syndi/elite/winter)
	crate_name = "deep space crate"

/datum/supply_pack/ds/cybersun
	name = "Cybersun Hardsuit"
	desc = "Новенькие и свеженькие Киберсан костюмы для боевых задач. Содержит 2 штуки"
	cost = 17000
	contains = list(/obj/item/clothing/suit/space/hardsuit/cybersun,
					/obj/item/clothing/suit/space/hardsuit/cybersun)
	crate_name = "deep space crate"

/datum/supply_pack/ds/sniper
	name = "Снайперская Винтовка"
	desc = "Большая, Запрещенная, и крайне убойная винтовка для устранения всего живого что существует. В комплекте одна винтовка и магазины."
	cost = 35000
	contains = list(/obj/item/gun/ballistic/automatic/sniper_rifle,
					/obj/item/ammo_box/magazine/sniper_rounds,
					/obj/item/ammo_box/magazine/sniper_rounds)
	crate_name = "deep space crate"

/datum/supply_pack/ds/elite_mod
	name = "Cybersun Modsuit"
	desc = "Лучший МОД костюм Киберсан. Пусть и в силу возраста немного уступает аналогам всё ещё является одним из лучших в секторе."
	cost = 37000
	contains = list(/obj/item/mod/control/pre_equipped/elite)
	crate_name = "deep space crate"

/datum/supply_pack/ds/m90gl
	name = "Ящик с M-90GL"
	desc = "Компактный карабин для устранения целей. Имеет подствольник. В комплекте 2 штуки"
	cost = 27000
	contains = list(/obj/item/gun/ballistic/automatic/m90,
					/obj/item/gun/ballistic/automatic/m90,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556)
	crate_name = "deep space crate"

/datum/supply_pack/ds/m90glmag
	name = "Ящик с Магазинами для M90GL"
	desc = "Новенькие Магазины для карабина. !ГРАНАТЫ В КОМПЛЕКТ НЕ ВХОДЯТ! "
	cost = 12000
	contains = list(/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556)
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

/datum/supply_pack/ds/acr
	name = "Ящик с ACR"
	desc = "Старая штурмовая винтовка синдиката на промежуточный калибр. Устарела но всё ещё страшна в бою. Содержит 2 экземпляра."
	cost = 23000
	contains = list(/obj/item/gun/ballistic/automatic/acr5m30,
					/obj/item/gun/ballistic/automatic/acr5m30,
					/obj/item/ammo_box/magazine/acr5m30,
					/obj/item/ammo_box/magazine/acr5m30)
	crate_name = "deep space crate"


/datum/supply_pack/ds/ACRmag
	name = "Ящик с Магазинами для ACR"
	desc = "Магазины для ШВ"
	cost = 7000
	contains = list(/obj/item/ammo_box/magazine/acr5m30,
					/obj/item/ammo_box/magazine/acr5m30,
					/obj/item/ammo_box/magazine/acr5m30/ap,
					/obj/item/ammo_box/magazine/acr5m30/ap)
	crate_name = "deep space crate"

/datum/supply_pack/ds/esword
	name = "Ящик с Лазерными Мечами"
	desc = "Лазерные мечи. В коплекте 3 штуки."
	cost = 25000
	contains = list(/obj/item/melee/transforming/energy/sword,
					/obj/item/melee/transforming/energy/sword,
					/obj/item/melee/transforming/energy/sword)
	crate_name = "deep space crate"
