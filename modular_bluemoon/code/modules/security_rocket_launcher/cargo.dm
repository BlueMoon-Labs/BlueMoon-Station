// Карго-заказы для «VARS». Порт с Bubberstation.

/datum/supply_pack/security/armory/rocket_launcher
	name = "Security Missile Launcher Crate"
	desc = "Содержит одну ракетную систему переменного активного радара \"VARS\" для нужд службы безопасности."
	cost = CARGO_CRATE_VALUE * 50 //10000
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/rocketlauncher/security)
	crate_name = "security missile launcher crate"

/datum/supply_pack/security/armory/rocket_launcher_ammo
	name = "Security Missile Launcher Ammo Pack"
	desc = "Содержит ящик из семи ОФ-ракет \"VARS\" для ракетной системы переменного активного радара."
	cost = CARGO_CRATE_VALUE * 7 //1400
	access = ACCESS_ARMORY
	contains = list(/obj/item/storage/box/security_missiles)
	crate_name = "security missile launcher ammo crate"
