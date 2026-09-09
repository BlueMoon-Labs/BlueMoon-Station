//////////////////////////////////////////////////////////////////////////////
//////////////////////// Тарков Индастриз //////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// BLUEMOON ADD - Эксклюзивный каталог, доступен только консоли
// /obj/machinery/computer/cargo/express/tar

/datum/supply_pack/tar
	group = "Tarkov"
	exclusive_consoles = list(/obj/machinery/computer/cargo/express/tar)
	crate_type = /obj/structure/closet/crate/tarkov

/datum/supply_pack/tar/fal
	name = "Ящик с винтовками 308 калибра"
	desc = "Старые, надежные. очень опасные и смертоносные в ящике три копмлекта."
	cost = 17500
	contains = list(/obj/item/gun/ballistic/automatic/fal,
					/obj/item/gun/ballistic/automatic/fal,
					/obj/item/gun/ballistic/automatic/fal,
					/obj/item/ammo_box/magazine/fal,
					/obj/item/ammo_box/magazine/fal,
					/obj/item/ammo_box/magazine/fal)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/mag
	name = "Ящик с Магазинами 308 калибра"
	desc = "Магазины для винтовки 308 калибра."
	cost = 10000
	contains = list(/obj/item/ammo_box/magazine/fal,
					/obj/item/ammo_box/magazine/fal,
					/obj/item/ammo_box/magazine/fal)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/ak
	name = "Ящик с Калашами"
	desc = "Старые, надежные. очень опасные и смертоносные. Это оружие прошло века, ему не страшна ни грязь, ни холод, оружие что по сей день всё еще актуальный. в ящике три копмлекта."
	cost = 15000
	contains = list(/obj/item/gun/ballistic/automatic/ak47/akm,
					/obj/item/gun/ballistic/automatic/ak47/akm,
					/obj/item/gun/ballistic/automatic/ak47/akm,
					/obj/item/ammo_box/magazine/ak47,
					/obj/item/ammo_box/magazine/ak47,
					/obj/item/ammo_box/magazine/ak47)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/akmags
	name = "Ящик с Магазинами для Калаша"
	desc = "Вам кажется эти магазины еще с времен создания оружия."
	cost = 7500
	contains = list(/obj/item/ammo_box/magazine/ak47,
					/obj/item/ammo_box/magazine/ak47,
					/obj/item/ammo_box/magazine/ak47)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/arcd
	name = "Ящик c ARCD"
	desc = "Улучшенная, доработаная версия Строителя что может на растоянии строить стени и двери."
	cost = 10000
	contains = list(/obj/item/construction/rcd/arcd)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/surplus
	name = "Ящик с Винтовками"
	desc = "Надежные винтовки со времен старых войн Содержит 3 набора."
	cost = 7500
	contains = list(/obj/item/gun/ballistic/automatic/surplus,
					/obj/item/gun/ballistic/automatic/surplus,
					/obj/item/gun/ballistic/automatic/surplus,
					/obj/item/ammo_box/magazine/m10mm/rifle,
					/obj/item/ammo_box/magazine/m10mm/rifle,
					/obj/item/ammo_box/magazine/m10mm/rifle)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/surplusmag
	name = "Ящик с патронами для винтовок"
	desc = "Ящик с магазинами для винтовок"
	cost = 2500
	contains = list(/obj/item/ammo_box/magazine/m10mm/rifle,
					/obj/item/ammo_box/magazine/m10mm/rifle,
					/obj/item/ammo_box/magazine/m10mm/rifle)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/tommygun
	name = "Ящик с Автоматами Томпсона"
	desc = "Надежные Автоматы со времен старых войн Содержит 3 набора."
	cost = 10000
	contains = list(/obj/item/gun/ballistic/automatic/tommygun,
					/obj/item/gun/ballistic/automatic/tommygun,
					/obj/item/gun/ballistic/automatic/tommygun,
					/obj/item/ammo_box/magazine/tommygunm45,
					/obj/item/ammo_box/magazine/tommygunm45,
					/obj/item/ammo_box/magazine/tommygunm45)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/tommygunmag
	name = "Ящик с Магазинами для Томпсона"
	desc = "Магазины для Томпсона."
	cost = 10000
	contains = list(/obj/item/ammo_box/magazine/tommygunm45,
					/obj/item/ammo_box/magazine/tommygunm45,
					/obj/item/ammo_box/magazine/tommygunm45)
	crate_name = "Ящик Тарков Индастриз"

/datum/supply_pack/tar/ar
	name = "Ящик с Автоматами NT-ARG 'Boarder' "
	desc = "Не спрашивайте откуда у нас Оружие, просто знайте что оно вполне себе надежное."
	cost = 12500
	contains = list(/obj/item/gun/ballistic/automatic/ar,
					/obj/item/gun/ballistic/automatic/ar,
					/obj/item/gun/ballistic/automatic/ar,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556)

/datum/supply_pack/tar/armag
	name = "Ящик с Магазинами под калибр 5.56"
	desc = "Универсальные магазины под калибр 5.56."
	cost = 12500
	contains = list(/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556)

/datum/supply_pack/tar/inquisitor
	name = "Ящик с Броней Инквизиции"
	desc = "Найденые в поле боя, броня успела в местах проржаветь от крови и времени, однако они всё еще надежные. В коплекте 3 штуки."
	cost = 20000
	contains = list(/obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor/old,
					/obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor/old,
					/obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor/old)
