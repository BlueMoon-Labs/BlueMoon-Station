// -----------------------------------------[bundle]-----------------------------[bundle]----------------------------------[bundle]-------------------------------------
// 1. Инфильтраторка. В аплинке интекью
/obj/item/storage/toolbox/infiltrator/inteq/PopulateContents()
	new /obj/item/clothing/head/helmet/infiltrator/inteq(src)
	new /obj/item/clothing/suit/armor/vest/infiltrator/inteq(src)
	new /obj/item/clothing/under/inteq/tactical_gorka(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated/infiltrator/inteq(src)
	new /obj/item/clothing/mask/infiltrator/inteq(src)
	new /obj/item/clothing/shoes/combat/sneakboots/inteq(src)
// 2. Космодесантник В аплинке интекью
/obj/item/storage/box/syndie_kit/spacehero
	name = "Death Angel armor kit"
	icon_state = "inteqbox"

/obj/item/storage/box/syndie_kit/spacehero/PopulateContents()
	new /obj/item/autosurgeon/syndicate/inteq/astartes(src)
	new /obj/item/clothing/shoes/jackboots/powerbots(src)
	new /obj/item/clothing/mask/gas/sechailer/angrymarin(src)
	new /obj/item/clothing/suit/space/syndicate/darktemplar(src)
	new /obj/item/clothing/head/helmet/space/syndicate/darktemplar(src)
	new /obj/item/clothing/under/syndicate/combat(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated(src)
	new	/obj/item/nullrod/claymore/chainsaw_sword/real(src)
// 3. Грейтайдер В аплинке интекью
/obj/item/storage/box/syndie_kit/grayhero
	name = "Grey tide"
	icon_state = "inteqbox"

/obj/item/storage/box/syndie_kit/grayhero/PopulateContents()
	new /obj/item/clothing/under/color/grey/glorf(src)
	new	/obj/item/clothing/shoes/chameleon/noslip(src)
	new	/obj/item/clothing/gloves/color/yellow(src)
	new	/obj/item/storage/belt/utility/full(src)
	new	/obj/item/clothing/mask/gas(src)
	new	/obj/item/clothing/glasses/phantomthief/syndicate(src)
	new	/obj/item/spear/grey_tide(src)
// 4. Безумное мочилово В аплинке интекью
/obj/item/storage/box/inteq_kit/hank/PopulateContents()
	new /obj/item/clothing/suit/armor/hank (src)
	new /obj/item/clothing/head/helmet/hank (src)
// 5. Бронирование В аплинке интекью
/obj/item/storage/box/inteq_kit/quetkid/PopulateContents()
	new /obj/item/armorkit/inteq(src)
	new /obj/item/armorkit/helmet/inteq(src)
// 6. Туллбоксы Интекью В аплинке интекью
/obj/item/storage/toolbox/inteq/PopulateContents()
	new /obj/item/screwdriver/nuke/inteq(src)
	new /obj/item/wrench/combat/inteq(src)
	new /obj/item/weldingtool/largetank(src)
	new /obj/item/crowbar/brown(src)
	new /obj/item/wirecutters/brown(src)
	new /obj/item/multitool(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated(src)

/obj/item/storage/toolbox/inteq/cooler/PopulateContents()
	new /obj/item/screwdriver/power/inteq(src)
	new /obj/item/crowbar/power/inteq(src)
	new /obj/item/weldingtool/experimental/inteq(src)
	new /obj/item/multitool/tricorder(src)
	new /obj/item/inducer/inteq(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated(src)
// 7. Хирургические сумки В аплинке интекью
/obj/item/storage/backpack/duffelbag/syndie/inteq/surgery/PopulateContents()
	new /obj/item/scalpel(src)
	new /obj/item/hemostat(src)
	new /obj/item/retractor(src)
	new /obj/item/circular_saw(src)
	new /obj/item/surgicaldrill(src)
	new /obj/item/cautery(src)
	new /obj/item/bonesetter(src)
	new /obj/item/blood_filter(src)
	new /obj/item/surgical_drapes(src)
	new /obj/item/clothing/suit/straight_jacket(src)
	new /obj/item/clothing/mask/muzzle(src)
	new /obj/item/mmi/inteq(src)
	new /obj/item/implantcase(src)
	new /obj/item/implanter(src)
	new /obj/item/reagent_containers/medspray/sterilizine(src)
	new /obj/item/tank/internals/anesthetic(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/surgery_adv/PopulateContents()
	new /obj/item/scalpel/advanced(src)
	new /obj/item/retractor/advanced(src)
	new /obj/item/surgicaldrill/advanced(src)
	new /obj/item/bonesetter(src)
	new /obj/item/surgical_drapes(src)
	new /obj/item/clothing/suit/straight_jacket(src)
	new /obj/item/clothing/mask/muzzle(src)
	new /obj/item/mmi/inteq(src)
	new /obj/item/implantcase(src)
	new /obj/item/implanter(src)
	new /obj/item/reagent_containers/medspray/sterilizine(src)
	new /obj/item/tank/internals/anesthetic(src)
// 8. Боевые наборы FTU. Доступны охранникам корабля FTU во время мидгейм ивента торговцев
/obj/item/storage/backpack/satchel/ftu
	name = "Trading Looking Satchel Bag"
	desc = "A large satchel bag for holding extra tactical supplies."

/obj/item/storage/backpack/satchel/ftu/shootgun
	name = "Набор №473. Спецификация: Инженер. Основное оружие: AA12"

/obj/item/storage/backpack/satchel/ftu/shootgun/PopulateContents()
	new /obj/item/storage/box/survival/security/radio(src)
	new /obj/item/gun/ballistic/automatic/shotgun/aa12(src)
	for(var/i in 1 to 3)
		new /obj/item/ammo_box/magazine/aa12/small(src)
	new /obj/item/storage/belt/utility/syndicate(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated(src)

/obj/item/storage/backpack/satchel/ftu/fire
	name = "Набор №343. Спецификация: Чистильщик. Основное оружие: M2a100"

/obj/item/storage/backpack/satchel/ftu/fire/PopulateContents()
	new /obj/item/storage/box/survival/security/radio(src)
	new /obj/item/gun/energy/m2a100(src)
	for(var/i in 1 to 10)
		new /obj/item/stack/sheet/mineral/plasma(src)
	new /obj/item/extinguisher (src)
	new /obj/item/grenade/stingbang/shred(src)
	new /obj/item/grenade/stingbang/shred(src)

/obj/item/storage/backpack/satchel/ftu/sniper
	name = "Набор №476. Спецификация: Солдат. Основное оружие: FAL"

/obj/item/storage/backpack/satchel/ftu/sniper/PopulateContents()
	new /obj/item/storage/box/survival/security/radio(src)
	new /obj/item/gun/ballistic/automatic/fal(src)
	for(var/i in 1 to 3)
		new /obj/item/ammo_box/magazine/fal(src)
	new /obj/item/chameleon(src)

/obj/item/storage/backpack/satchel/ftu/med
	name = "Набор №678. Спецификация: Медик. Основное оружие: SMG .22"

/obj/item/storage/backpack/satchel/ftu/med/PopulateContents()
	new /obj/item/storage/box/survival/security/radio(src)
	new /obj/item/gun/ballistic/automatic/smg22(src)
	for(var/i in 1 to 5)
		new/obj/item/ammo_box/magazine/smg22(src)
	new /obj/item/storage/belt/medical/surgery_belt_adv(src)
	new /obj/item/storage/firstaid/tactical(src)
// 9. Гитарная сумка. Доступна в карго
/obj/item/storage/backpack/guitarbag/loaded/PopulateContents()
	new /obj/item/instrument/guitar(src)
// 10. Гитарная сумка с винтовкой. В аплинке интекью
/obj/item/storage/backpack/guitarbag/sniper/PopulateContents()
	new /obj/item/gun/ballistic/automatic/m1garand(src)
	new /obj/item/ammo_box/magazine/garand(src)
	new /obj/item/disk/design_disk/adv/ammo/garand(src)
// 11. Револьвер интека. В аплинке интекью
/obj/item/storage/box/inteq_kit/revolver/PopulateContents()
	new /obj/item/gun/ballistic/revolver/inteq(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357/ap(src)
	new /obj/item/ammo_box/a357/dumdum(src)
// 12. Дверные мины. В аплинке интекью
/obj/item/storage/box/inteq_kit/doorgoboom/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/doorCharge(src)
// 13. Взрывчатка. В аплинке интекью
/obj/item/storage/backpack/duffelbag/syndie/inteq/c4/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/grenade/plastic/c4(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/x4/PopulateContents()
	for(var/i in 1 to 3)
		new /obj/item/grenade/plastic/x4(src)

// -----------------------------------------[Outfit]-----------------------------[Outfit]----------------------------------[Outfit]-------------------------------------
// 1. Аутфит интекью
/datum/outfit/inteq_dead
	back = /obj/item/storage/backpack
	name = "InteQ corps"
	suit = /obj/item/clothing/suit/armor/inteq
	uniform = /obj/item/clothing/under/inteq
	shoes = /obj/item/clothing/shoes/combat/swat/knife
	gloves = /obj/item/clothing/gloves/combat
	head = /obj/item/clothing/head/helmet/swat/inteq
	mask = /obj/item/clothing/mask/gas/inteq
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double
	id = /obj/item/card/id/inteq
// 2. Форма солдата FTU
/datum/outfit/ftu/solder
	name = "FTU Solder"
	uniform = /obj/item/clothing/under/inteq/tactical_gorka
	belt = /obj/item/storage/belt/military/assault
	shoes = /obj/item/clothing/shoes/workboots/mining
	gloves = /obj/item/clothing/gloves/fingerless
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses/inteq
	suit = /obj/item/clothing/suit/armor/vest/ftu
	head = /obj/item/clothing/head/helmet/skull/ftu
	neck = /obj/item/clothing/neck/cloak/ftu
	l_hand = /obj/item/choice_beacon/ftu
	r_pocket = /obj/item/kitchen/knife/combat/survival/knuckledagger
	id = /obj/item/card/id/away/ftu
// 3. Форма КМа FTU
/datum/outfit/ftu/qm
	name = "FTU QM"
	uniform = /obj/item/clothing/under/rank/cargo/qm
	belt = /obj/item/storage/belt/military/assault
	neck = /obj/item/clothing/neck/cloak
	back = /obj/item/storage/backpack/satchel
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/beret/qm
	glasses = /obj/item/clothing/glasses/sunglasses
	l_pocket = /obj/item/gun/energy/pulse/pistol/inteq
	id = /obj/item/card/id/away/ftu
	backpack_contents = list(/obj/item/storage/box/survival/security/radio, /obj/item/paper/fluff/traid_ship/qm)
// 4. Форма работяги FTU
/datum/outfit/ftu/crew
	name = "FTU Crew"
	uniform = /obj/item/clothing/under/inteq/tactical_gorka/ftu
	belt = /obj/item/storage/belt/military/assault
	shoes = /obj/item/clothing/shoes/workboots/mining
	gloves = /obj/item/clothing/gloves/fingerless
	head = /obj/item/clothing/head/soft/orange
	back = /obj/item/storage/backpack/satchel
	l_pocket = /obj/item/choice_beacon/ftu
	r_pocket = /obj/item/kitchen/knife/combat/survival/knuckledagger
	id = /obj/item/card/id/away/ftu
	backpack_contents = list(/obj/item/storage/box/survival/security/radio)
