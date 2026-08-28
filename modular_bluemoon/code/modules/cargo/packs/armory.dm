/datum/supply_pack/security/armory/ak12r
	name = "Pink AK-12 Rifle Crate"
	desc = "Contains one high-powered, fully automatic rifle, and three mags. Requires Armory access to open."
	cost = 12000 // АК-12 для сбух всегда было рофлом за 35 тысяч. за эти деньги можно купить 4 ящика ВТ и 4 ящика патрон к ним, вооружив ВООБЩЕ всех
	contains = list(/obj/item/gun/ballistic/automatic/ak12/r,
					/obj/item/ammo_box/magazine/ak12/r,
					/obj/item/ammo_box/magazine/ak12/r,
					/obj/item/ammo_box/magazine/ak12/r)
	crate_name = "pink ak12 rifle crate"

/datum/supply_pack/security/armory/alliance_case
	name = "Alliance Assasin Cases"
	desc = "Хранит в себе два женских специализированных боевых костюма. Требует доступ к Арсеналу для открытия ящичка."
	cost = 49000
	contains = list(/obj/item/storage/toolbox/infiltrator/alliance,
					/obj/item/storage/toolbox/infiltrator/alliance)
	crate_name = "Alliance Assasin Cases Crate"

/datum/supply_pack/security/armory/pact_ninja_case
	name = "PACT Ninja Case"
	desc = "Хранит в себе специализированный боевой костюм с оружием ближнего боя. Требует доступ к Арсеналу для открытия ящичка."
	cost = 29990
	contains = list(/obj/item/storage/toolbox/infiltrator/pact_ninja)
	crate_name = "PACT Ninja Case Crate"
