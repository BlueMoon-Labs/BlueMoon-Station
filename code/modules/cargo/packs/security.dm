
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Security ////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/security
	group = "Security"
	access = ACCESS_SECURITY
	crate_type = /obj/structure/closet/crate/secure/gear
	can_private_buy = FALSE

/datum/supply_pack/security/ammo
	name = "Ammo Crate - General Purpose"
	desc = "Содержит два магазина на 20 патронов для автоматической винтовки WT550, три коробки картечи, три коробки резиновых патронов и специальные скорострельные патроны 38 калибра. Для открытия требуется доступ СБ."
	cost = 2500
	contains = list(/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/rubbershot,
					/obj/item/storage/box/rubbershot,
					/obj/item/storage/box/rubbershot,
					/obj/item/ammo_box/c38/trac,
					/obj/item/ammo_box/c38/hotshot,
					/obj/item/ammo_box/c38/iceblox)
	crate_name = "ammo crate"

/datum/supply_pack/security/armor
	name = "Armor Crate"
	desc = "Три жилета из хорошо скругленной, прилично защищающей брони. Требуется доступ СБ."
	cost = 1200
	contains = list(/obj/item/clothing/suit/armor/vest,
					/obj/item/clothing/suit/armor/vest,
					/obj/item/clothing/suit/armor/vest)
	crate_name = "armor crate"

/datum/supply_pack/security/disabler
	name = "Disabler Crate"
	desc = "Три дизейблера, истощающих выносливость. Требуется доступ СБ."
	cost = 1300
	contains = list(/obj/item/gun/energy/disabler,
					/obj/item/gun/energy/disabler,
					/obj/item/gun/energy/disabler)
	crate_name = "disabler crate"

/datum/supply_pack/security/forensics
	name = "Forensics Crate"
	desc = "Идите по горячим следам преступника с помощью Nanotrasen's Detective Essentials(tm). Содержит криминалистический сканер, шесть пакетов для улик, фотоаппарат, магнитофон, белый карандаш и, конечно же, федору. Для открытия требуется доступ СБ."
	cost = 1800
	contains = list(/obj/item/detective_scanner,
					/obj/item/storage/box/evidence,
					/obj/item/camera,
					/obj/item/taperecorder,
					/obj/item/toy/crayon/white,
					/obj/item/clothing/head/fedora/det_hat)
	crate_name = "forensics crate"
	can_private_buy = TRUE

/datum/supply_pack/security/helmets
	name = "Helmets Crate"
	desc = "Содержит три стандартных шлема. Требуется доступ безопасности, чтобы открыть."
	cost = 1200
	contains = list(/obj/item/clothing/head/helmet/sec,
					/obj/item/clothing/head/helmet/sec,
					/obj/item/clothing/head/helmet/sec)
	crate_name = "helmet crate"

/datum/supply_pack/security/plate_carriers
	name = "Plate Carrier Crate"
	desc = "Contains three standard-issue cool Plate Carriers. Requires Security access to open." // Я не знаю как это перевести
	cost = 2000
	contains = list(/obj/item/clothing/suit/armor/hos/platecarrier,
					/obj/item/clothing/suit/armor/hos/platecarrier,
					/obj/item/clothing/suit/armor/hos/platecarrier)
	crate_name = "plate carrier crate"

/datum/supply_pack/security/laser
	name = "Lasers Crate"
	desc = "Содержит три смертоносных высокоэнергетических лазерных оружия. Требуется доступ безопасности, чтобы открыть."
	cost = 1750
	contains = list(/obj/item/gun/energy/laser,
					/obj/item/gun/energy/laser,
					/obj/item/gun/energy/laser)
	crate_name = "laser crate"

/datum/supply_pack/security/russianclothing
	name = "Russian Surplus Clothing"
	desc = "Старый русский ящик, полный излишков брони, которую они использовали раньше! Имеет два комплекта пуленепробиваемой брони, несколько костюмов профсоюза и несколько теплых шапок!"
	contraband = TRUE
	cost = 7500 // Its basicly sec suits, good boots/gloves
	contains = list(/obj/item/clothing/under/syndicate/rus_army,
					/obj/item/clothing/under/syndicate/rus_army,
					/obj/item/clothing/shoes/combat,
					/obj/item/clothing/shoes/combat,
					/obj/item/clothing/head/helmet/rus_helmet,
					/obj/item/clothing/head/helmet/rus_helmet,
					/obj/item/clothing/head/helmet/rus_cap,
					/obj/item/clothing/head/helmet/rus_cap,
					/obj/item/clothing/head/helmet/rus_ushanka,
					/obj/item/clothing/head/helmet/rus_ushanka,
					/obj/item/clothing/suit/armor/bulletproof,
					/obj/item/clothing/suit/armor/bulletproof,
					/obj/item/clothing/head/helmet/alt,
					/obj/item/clothing/head/helmet/alt,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas)
	crate_name = "surplus russian clothing"
	crate_type = /obj/structure/closet/crate/secure/soviet

/datum/supply_pack/security/russian_partisan
	name = "Russian Partisan Gear"
	desc = "Старый ящик с снаряжением русского партизана, поставляется с полным русским снаряжением, заряженной запасной винтовкой и вторым магазином."
	contraband = TRUE
	cost = 6500
	contains = list(/obj/item/clothing/suit/armor/navyblue/russian,
					/obj/item/clothing/shoes/combat,
					/obj/item/clothing/head/helmet/rus_helmet,
					/obj/item/clothing/suit/armor/bulletproof,
					/obj/item/clothing/head/helmet/alt,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/under/syndicate/rus_army,
					/obj/item/clothing/mask/gas)
	crate_name = "surplus russian gear"
	crate_type = /obj/structure/closet/crate/secure/soviet

/datum/supply_pack/security/russian_partisan/fill(obj/structure/closet/crate/C)
	..()
	if(prob(20))
		new /obj/effect/spawner/bundle/crate/mosin(C)
	else
		new /obj/effect/spawner/bundle/crate/surplusrifle(C)

/datum/supply_pack/security/sechardsuit
	name = "Sec Hardsuits crate"
	desc = "Три защитных костюма для ловли негодяев в открытом космосе! В комплекте поставляется балон и маска."
	cost = 9000 // half of SWAT gear for have the armor and half the gear
	contains = list(/obj/item/clothing/suit/space/hardsuit/security,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/hardsuit/security,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/hardsuit/security,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas)
	crate_name = "sec hardsuit crate"

/datum/supply_pack/security/securitybarriers
	name = "Security Barrier Grenades"
	desc = "Остановите штурм с помощью четырех гранат защитного барьера. Для открытия требуется доступ СБ."
	contains = list(/obj/item/grenade/barrier,
					/obj/item/grenade/barrier,
					/obj/item/grenade/barrier,
					/obj/item/grenade/barrier)
	cost = 2000
	crate_name = "security barriers crate"
	can_private_buy = TRUE

/datum/supply_pack/security/securityclothes
	name = "Security Clothing Crate"
	desc = "Содержит соответствующую экипировку для службы безопасности станции. Содержит наряды для вардена, главы службы безопасности и двух офицеров службы безопасности. Каждый наряд поставляется с соответствующим рангу комбинезоном, костюмом и беретом. Для открытия требуется доступ СБ."
	cost = 3250
	contains = list(/obj/item/clothing/under/rank/security/officer/formal,
					/obj/item/clothing/under/rank/security/officer/formal,
					/obj/item/clothing/suit/armor/navyblue,
					/obj/item/clothing/suit/armor/navyblue,
					/obj/item/clothing/head/beret/sec/navyofficer,
					/obj/item/clothing/head/beret/sec/navyofficer,
					/obj/item/clothing/under/rank/security/warden/formal,
					/obj/item/clothing/suit/armor/vest/warden/navyblue,
					/obj/item/clothing/head/beret/sec/navywarden,
					/obj/item/clothing/under/rank/security/head_of_security/formal,
					/obj/item/clothing/suit/armor/hos/navyblue,
					/obj/item/clothing/head/beret/sec/navyhos)
	crate_name = "security clothing crate"
	can_private_buy = TRUE

/datum/supply_pack/security/supplies
	name = "Security Supplies Crate"
	desc = "Содержит семь светошумовых гранат, семь гранат со слезоточивым газом, шесть вспышек и семь наручников. Для открытия требуется доступ СБ"
	cost = 1200
	contains = list(/obj/item/storage/box/flashbangs,
					/obj/item/storage/box/teargas,
					/obj/item/storage/box/flashes,
					/obj/item/storage/box/handcuffs)
	crate_name = "security supply crate"

/datum/supply_pack/security/firingpins
	name = "Standard Firing Pins Crate"
	desc = "Обновите свой арсенал с помощью 10 стандартных боекомплектов. Для открытия требуется доступ СБ."
	cost = 2000
	contains = list(/obj/item/storage/box/firingpins,
					/obj/item/storage/box/firingpins)
	crate_name = "firing pins crate"

/datum/supply_pack/security/justiceinbound
	name = "Standard Justice Enforcer Crate"
	desc = "Это оно. Жемчужина в короне Нанотрасена. Альфа и Омега защитных головных уборов. Гарантированно вселит страх в сердца всех без исключения преступников на борту станции. Также поставляется с защитным противогазом. Для открытия требуется доступ СБ."
	cost = 6000 //justice comes at a price. An expensive, noisy price.
	contraband = TRUE
	contains = list(/obj/item/clothing/head/helmet/justice,
					/obj/item/clothing/mask/gas/sechailer)
	crate_name = "security clothing crate"
	can_private_buy = TRUE

/datum/supply_pack/security/baton
	name = "Stun Batons Crate"
	desc = "Вооружите Силы Гражданской Обороны тремя электрошоковыми дубинками. Батарейки в комплекте. Для открытия требуется доступ СБ."
	cost = 1200
	contains = list(/obj/item/melee/baton/loaded,
					/obj/item/melee/baton/loaded,
					/obj/item/melee/baton/loaded)
	crate_name = "stun baton crate"

/datum/supply_pack/security/taser
	name = "Taser Crate"
	desc = "Содержит три гибридных электрошокера, способных стрелять обоими электродами. Для открытия требуется доступ СБ"
	cost = 3500
	contains = list(/obj/item/gun/energy/e_gun/advtaser,
					/obj/item/gun/energy/e_gun/advtaser,
					/obj/item/gun/energy/e_gun/advtaser)
	crate_name = "taser crate"

/datum/supply_pack/security/wall_flash
	name = "Wall-Mounted Flash Crate"
	desc = "Содержит четыре настенные вспышки. Требуется доступ СБ"
	cost = 1000
	contains = list(/obj/item/storage/box/wall_flash,
					/obj/item/storage/box/wall_flash,
					/obj/item/storage/box/wall_flash,
					/obj/item/storage/box/wall_flash)
	crate_name = "wall-mounted flash crate"

/datum/supply_pack/security/hunting
	name = "Hunting Gear"
	desc = "Даже в космосе мы можем найти добычу для охоты, в этом ящике есть все, что нужно хорошему охотнику для спортивного времяпрепровождения. Чтобы открыть этот ящик, нужен доступ в оружейную. Настоящему охотнику нужна только бутылка хорошего коньяка, хорошее пальто, несколько хороших сигар и, конечно же, охотничье ружье."
	cost = 3500
	contraband = TRUE
	contains = list(/obj/item/clothing/head/flatcap,
					/obj/item/clothing/suit/hooded/wintercoat/captain,
					/obj/item/reagent_containers/food/drinks/bottle/cognac,
					/obj/item/storage/fancy/cigarettes/cigars/havana,
					/obj/item/clothing/gloves/color/white,
					/obj/item/clothing/under/rank/civilian/curator,
					/obj/item/gun/ballistic/shotgun/lethal)
	access = ACCESS_ARMORY
	crate_name = "sporting crate"
	crate_type = /obj/structure/closet/crate/secure // Would have liked a wooden crate but access >:(

/datum/supply_pack/security/dumdum
	name = ".38 DumDum Speedloader"
	desc = "Содержит один спидлоадер 38-го калибра DumDum. Для открытия требуется доступ СБ."
	cost = 1200
	access = FALSE
	access_any = list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS)
	contains = list(/obj/item/ammo_box/c38/dumdum)
	crate_name = ".38 dumdum crate"

/datum/supply_pack/security/match
	name = ".38 Match Grade Speedloader"
	desc = "Содержит один спидлоадер 38 калибра, идеально подходящий для демонстрации трюковых выстрелов. Требуется доступ СБ."
	cost = 1200
	access = FALSE
	access_any = list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS)
	contains = list(/obj/item/ammo_box/c38/match)
	crate_name = ".38 match crate"

/datum/supply_pack/security/stingpack
	name = "Stingbang Grenade Pack"
	desc = "Содержит пять гранат \"stingbang\", идеально подходящих для прекращения беспорядков и совершения немыслимых с моральной точки зрения розыгрышей. Для открытия требуется доступ СБ."
	cost = 2500
	contains = list(/obj/item/storage/box/stingbangs)
	crate_name = "stingbang grenade pack crate"

/datum/supply_pack/security/stingpack/single
	name = "Stingbang Single-Pack"
	desc = "Содержит одну гранату \"stingbang\", идеально подходящую для подлых розыгрышей. Для открытия требуется доступ СБ."
	cost = 1400
	contains = list(/obj/item/grenade/stingbang)

