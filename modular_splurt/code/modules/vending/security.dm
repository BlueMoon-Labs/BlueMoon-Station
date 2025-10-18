/* BLUEMOON EDIT - CODE OVERRIDDEN IN 'modular_bluemoon\code\modules\vending\security.dm'
/obj/machinery/vending/security/Initialize()
	var/list/extra_products = list(
		/obj/item/ammo_box/magazine/e45/taser = 10,
		/obj/item/device/hailer = 10,
		/obj/item/clothing/suit/armor/vest/peacekeeper = 5,
		/obj/item/clothing/suit/armor/vest/metrocop = 2,
		/obj/item/clothing/head/helmet/metrocop = 2,
		/obj/item/storage/bag/security = 5,
		/obj/item/clothing/head/helmet/blueshirt = 5,
		/obj/item/clothing/head/helmet/hephaestus = 5,
		/obj/item/clothing/under/rank/security/officer/blueshirt = 5,
		/obj/item/clothing/suit/armor/vest/blueshirt = 5,
		/obj/item/armorkit/security = 5,
		/obj/item/armorkit/security/helmet = 5
	)
	var/list/extra_contraband = list(
		/obj/item/storage/belt/slut = 5,
		/obj/item/bdsm_whip/ridingcrop = 3,
		/obj/item/electropack/shockcollar/security = 5,
		/obj/item/clothing/suit/armor/vest/stripper = 5,
		/obj/item/clothing/suit/armor/vest/stripper/bikini = 5,
		/obj/item/clothing/neck/petcollar/locked/security = 5,
		/obj/item/grenade/secbed = 3,
		/obj/item/dildo/flared/gigantic = 3
	)
	LAZYADD(products, extra_products)
	LAZYADD(contraband, extra_contraband)

	var/list/rem_premium = list(
		/obj/item/clothing/head/helmet/blueshirt,
		/obj/item/clothing/under/rank/security/officer/blueshirt,
		/obj/item/clothing/suit/armor/vest/blueshirt
	)
	LAZYREMOVE(premium, rem_premium)
	. = ..()
// BLUEMOON EDIT - CODE OVERRIDDEN IN 'modular_bluemoon\code\modules\vending\wardrobes.dm'
/obj/machinery/vending/wardrobe/sec_wardrobe/Initialize()
	var/list/extra_products = list(
		/obj/item/clothing/head/beret/sec/peacekeeper/cap = 5,
		/obj/item/clothing/head/beret/sec/peacekeeper = 5,
		/obj/item/clothing/mask/balaclava/breath = 5,
		/obj/item/clothing/mask/gas/syndicate/ds/wide = 3,
		/obj/item/clothing/mask/gas/syndicate/ds/mouth = 3,
		/obj/item/clothing/mask/gas/syndicate/ds/coif = 2,
		/obj/item/clothing/under/rank/security/officer/peacekeeper =5,
		/obj/item/clothing/under/rank/security/officer/metrocop = 2,
		/obj/item/clothing/under/rank/security/skirt/slut = 5,
		/obj/item/clothing/under/rank/security/skirt/slut/pink = 5,
		/obj/item/clothing/under/rank/security/stripper = 5,
		/obj/item/clothing/suit/hooded/corpus/s = 5,
		/obj/item/clothing/head/utilcover = 5,
		/obj/item/clothing/under/bm/utility = 5,
		/obj/item/clothing/under/bm/utility/navy = 5,
		/obj/item/clothing/under/bm/utility/tan = 5
	)
	var/list/extra_premium = list(
		/obj/item/clothing/gloves/latexsleeves/security = 5,
		/obj/item/clothing/shoes/jackboots/tall = 5,
		/obj/item/clothing/shoes/jackboots/alliance = 5,
		/obj/item/clothing/under/custom/mw2_russian_para = 5,
		/obj/item/clothing/under/bm/sigu = 5,
		/obj/item/clothing/head/beret/sec/bitch = 5
	)
	LAZYADD(products, extra_products)
	LAZYADD(premium, extra_premium)
	. = ..()
*/

/obj/structure/closet/secure_closet/brigdoc
	name = "brig physician's locker"
	req_access = list(ACCESS_BRIGDOC)
	icon_state = "brigdoc"

/obj/structure/closet/secure_closet/brigdoc/PopulateContents()
	..()
	new /obj/item/clothing/under/rank/brigdoc(src)
	new /obj/item/clothing/under/rank/brigdoc/skirt(src)
	new /obj/item/radio/headset/headset_brigdoc(src)
	new /obj/item/radio/headset/headset_brigdoc/alt(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/clothing/gloves/color/latex/nitrile(src)
	new /obj/item/clothing/head/brigdoc(src)
	new /obj/item/defibrillator/loaded(src) //BLUEMOOB Change - поменял на заряженный ибо батареек у БМов нет
	new /obj/item/storage/belt/medical(src)
	new /obj/item/pinpointer/crew(src)
	new /obj/item/clothing/suit/brigdoc(src)
	new /obj/item/clothing/suit/armor/brigdoc(src)
	new /obj/item/clothing/suit/armor/brigdoc/labcoat(src)
	new /obj/item/mod/module/clamp(src) //BLUEMOOB ADDITION - для перемещения сверхтяжёлых персонажей
	new /obj/item/reagent_containers/glass/bottle/morphine(src) // BLUEMOON ADD - для операций
	new /obj/item/roller/heavy(src) // BLUEMOON - HEAVY_QUIRKS - ADD - каталка для сверхтяжей

/obj/structure/closet/secure_closet/blueshield
	name = "blueshield's locker"
	req_access = list(ACCESS_BLUESHIELD)
	icon_state = "bs"
	var/pack_amount = 2

/obj/structure/closet/secure_closet/blueshield/PopulateContents()
	..()
	for(var/i in 1 to pack_amount)
		new /obj/item/clothing/head/helmet/sec(src)
		new /obj/item/flashlight/seclite(src)
		new /obj/item/clothing/mask/gas/sechailer/swat/blueshield(src)
		new /obj/item/grenade/flashbang(src)
		new /obj/item/armorkit/blueshield(src)
		new /obj/item/armorkit/blueshield/helmet(src)
		new /obj/item/clothing/neck/cloak/blueshield(src)

/obj/structure/closet/secure_closet/bridgesec
	name = "bridge officer's locker"
	req_access = list(ACCESS_BRIDGE_OFFICER)
	icon_state = "bridge"

/obj/structure/closet/secure_closet/bridgesec/PopulateContents()
	..()
	new /obj/item/radio/headset/headset_bo(src)
	new /obj/item/radio/headset/headset_bo(src)
	new /obj/item/radio/headset/headset_bo/bowman(src)
	new /obj/item/radio/headset/headset_bo/bowman(src)
	new /obj/item/clipboard(src)
	new /obj/item/clipboard(src)
	new /obj/item/clothing/neck/petcollar(src)
	new /obj/item/clothing/neck/petcollar(src)

//do not map these in anywhere but if you do, Central command only!!! These are for Admin spawn only!!!!

/obj/structure/closet/secure_closet/mopp
	name = "advance MOPP locker"
	req_access = list(ACCESS_CENT_GENERAL)
	icon_state = "secure"

/obj/structure/closet/secure_closet/mopp/PopulateContents()
	..()
	new /obj/item/tank/internals/plasmamandouble(src)
	new /obj/item/tank/internals/doubleoxygen(src)
	new /obj/item/clothing/head/helmet/cbrn/mopp/advance(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/clothing/suit/cbrn/mopp/advance(src)
	new /obj/item/clothing/gloves/cbrn/mopp/advance(src)
	new /obj/item/clothing/shoes/jackboots/cbrn/mopp/advance (src)
	new /obj/item/clothing/mask/gas/sechailer/mopp/advance(src)

/obj/structure/closet/secure_closet/commandmopp
	name = "advance MOPP locker 'Commander'"
	req_access = list(ACCESS_CENT_GENERAL)
	icon_state = "secure"

/obj/structure/closet/secure_closet/commandmopp/PopulateContents()
	..()
	new /obj/item/tank/internals/plasmamandouble(src)
	new /obj/item/tank/internals/doubleoxygen(src)
	new /obj/item/clothing/head/helmet/cbrn/mopp/advance(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/clothing/suit/cbrn/mopp/advance/commander(src)
	new /obj/item/clothing/gloves/cbrn/mopp/advance(src)
	new /obj/item/clothing/shoes/jackboots/cbrn/mopp/advance (src)
	new /obj/item/clothing/mask/gas/sechailer/mopp/advance(src)

/obj/structure/closet/secure_closet/secmopp
	name = "advance MOPP locker 'secuirity'"
	req_access = list(ACCESS_CENT_GENERAL)
	icon_state = "secure"

/obj/structure/closet/secure_closet/secmopp/PopulateContents()
	..()
	new /obj/item/tank/internals/plasmamandouble(src)
	new /obj/item/tank/internals/doubleoxygen(src)
	new /obj/item/clothing/head/helmet/cbrn/mopp/advance(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/clothing/suit/cbrn/mopp/advance/security(src)
	new /obj/item/clothing/gloves/cbrn/mopp/advance(src)
	new /obj/item/clothing/shoes/jackboots/cbrn/mopp/advance (src)
	new /obj/item/clothing/mask/gas/sechailer/mopp/advance(src)

/obj/structure/closet/secure_closet/medmopp
	name = "advance MOPP locker 'medical'"
	req_access = list(ACCESS_CENT_GENERAL)
	icon_state = "secure"

/obj/structure/closet/secure_closet/medmopp/PopulateContents()
	..()
	new /obj/item/tank/internals/plasmamandouble(src)
	new /obj/item/tank/internals/doubleoxygen(src)
	new /obj/item/clothing/head/helmet/cbrn/mopp/advance(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/clothing/suit/cbrn/mopp/advance/medical(src)
	new /obj/item/clothing/gloves/cbrn/mopp/advance(src)
	new /obj/item/clothing/shoes/jackboots/cbrn/mopp/advance (src)
	new /obj/item/clothing/mask/gas/sechailer/mopp/advance(src)

/obj/structure/closet/secure_closet/engimopp
	name = "advance MOPP locker 'engineering'"
	req_access = list(ACCESS_CENT_GENERAL)
	icon_state = "secure"

/obj/structure/closet/secure_closet/engimopp/PopulateContents()
	..()
	new /obj/item/tank/internals/plasmamandouble(src)
	new /obj/item/tank/internals/doubleoxygen(src)
	new /obj/item/clothing/head/helmet/cbrn/mopp/advance(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/clothing/suit/cbrn/mopp/advance/engi(src)
	new /obj/item/clothing/gloves/cbrn/mopp/advance(src)
	new /obj/item/clothing/shoes/jackboots/cbrn/mopp/advance (src)
	new /obj/item/clothing/mask/gas/sechailer/mopp/advance(src)


/obj/structure/closet/secure_closet/hosnew //ITS LOCKER CLEAN OUT DAY! -Radar
	name = "\proper head of security's locker"
	req_access = list(ACCESS_HOS)
	icon_state = "hos"

/obj/structure/closet/secure_closet/hosnew/PopulateContents()
	..()
	new /obj/item/storage/bag/ammo(src)
	new /obj/item/cartridge/hos(src)
	new /obj/item/radio/headset/heads/hos(src)
	new /obj/item/storage/lockbox/medal/sec(src)
	new /obj/item/megaphone/sec(src)
	new /obj/item/holosign_creator/security(src)
	new /obj/item/storage/lockbox/loyalty(src)
	new /obj/item/clothing/mask/gas/sechailer/swat/hos(src)
	new /obj/item/autosurgeon/breathing_tube(src)
	new /obj/item/storage/box/flashbangs(src)
	new /obj/item/shield/riot/tele(src)
	new /obj/item/storage/belt/military(src) //BLUEMOON add
	new /obj/item/storage/belt/security/full(src)
	new /obj/item/flashlight/seclite(src)
	new /obj/item/pinpointer/nuke(src)
	new /obj/item/circuitboard/machine/techfab/department/security(src)
	new /obj/item/storage/photo_album/HoS(src)
	new /obj/item/card/id/departmental_budget/sec(src)
	new /obj/item/lighter/hos(src)
	new /obj/item/mod/construction/armor/safeguard(src)
	new /obj/item/mod/module/jetpack(src)
	new /obj/item/mod/module/holster(src)
	new /obj/item/choice_beacon/box/desk(src) //BLUEMOON ADD

/obj/structure/closet/secure_closet/ntr
	name = "representative's locker"
	req_access = list(ACCESS_HOS)
	icon_state = "ntr"

/obj/structure/closet/secure_closet/ntr/PopulateContents()
	..()
	new /obj/item/megaphone/sec(src)
	new /obj/item/radio/headset/headset_cent/ntr(src)
	new /obj/item/radio/headset/headset_cent/ntr/alt (src)
	new /obj/item/stamp/syndicate(src)
	new /obj/item/stamp/ntr(src)
	new /obj/item/lighter/nt_rep(src)
	new /obj/item/clothing/accessory/lawyers_badge(src)
	new /obj/item/camera/detective(src)
	new /obj/item/storage/box/evidence(src)
	new /obj/item/melee/classic_baton/ntcane(src)
	new /obj/item/folder/blue(src) //BLUEMOON add
	new /obj/item/folder/red(src) //BLUEMOON add
	new /obj/item/folder(src)
	new /obj/item/storage/garment_case/ntr(src) //BLUEMOON add
	new /obj/item/storage/backpack/captain/ntr(src) //BLUEMOON add
	new /obj/item/storage/backpack/satchel/cap/ntr(src) //BLUEMOON add
	new /obj/item/storage/backpack/duffelbag/captain/ntr(src) //BLUEMOON add
	new /obj/item/choice_beacon/box/desk(src) //BLUEMOON add
