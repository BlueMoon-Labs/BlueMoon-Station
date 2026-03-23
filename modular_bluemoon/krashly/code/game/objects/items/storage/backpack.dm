/obj/item/storage/backpack/satchel/lfwb
	name = "fabric satchel"
	desc = "Bag with a flimsy closure and slit sides."
	icon_state = "satchel"
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/backpack.dmi'

/obj/item/storage/belt/medical/aesculapus
	name = "aesculapus medical belt"
	desc = "Can hold various medical equipment."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/belt.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/belt.dmi'
	icon_state = "medicalbelt"
	item_state = "medicalbelt"
	content_overlays = FALSE

//InteQ

/obj/item/storage/backpack/security/inteq
	name = "combat backpack"
	desc = "Comfortable and stylish backpack."
	icon_state = "backpack_inteq"
	item_state = "backpack_inteq"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/backpack.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/backpack.dmi'

/obj/item/storage/backpack/satchel/inteq
	name = "combat satchel"
	desc = "The bag looks like a mail bag and has brown-yellow inserts."
	icon_state = "satchel_inteq"
	item_state = "satchel_inteq"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/backpack.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/backpack.dmi'

/obj/item/storage/belt/military/inteq
	name = "combat webbing"
	desc = "Can hold various 'suspicious' items."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/belt.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/belt.dmi'
	icon_state = "inteq_webbing"
	item_state = "inteq_webbing"
	content_overlays = FALSE

//Duffels

/obj/item/storage/backpack/duffelbag/syndie/inteq
	name = "Suspicious Looking Duffel Bag"
	desc = "A large duffel bag for holding extra tactical supplies."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/backpack.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/backpack.dmi'
	icon_state = "duffel-inteq"
	item_state = "duffel-inteqeammo"
	slowdown = 0
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

/obj/item/storage/backpack/duffelbag/syndie/inteq/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.silent = TRUE

//Parent ^^^

/obj/item/storage/backpack/duffelbag/syndie/inteq/hitman
	desc = "A large duffel bag for holding extra things. There is a InteQ logo on the back."

/obj/item/storage/backpack/duffelbag/syndie/inteq/hitman/PopulateContents()
	new /obj/item/clothing/under/suit/black(src)
	new /obj/item/clothing/accessory/waistcoat(src)
	new /obj/item/clothing/suit/toggle/lawyer/black(src)
	new /obj/item/clothing/shoes/laceup(src)
	new /obj/item/clothing/gloves/color/black(src)
	new /obj/item/clothing/glasses/sunglasses(src)
	new /obj/item/clothing/head/fedora(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/med
	name = "medical duffel bag"
	desc = "A large duffel bag for holding extra tactical medical supplies."
	icon_state = "duffel-inteqmed"
	item_state = "duffel-inteqmed"

/obj/item/storage/backpack/duffelbag/syndie/inteq/surgery
	name = "surgery duffel bag"
	desc = "A suspicious looking duffel bag for holding surgery tools."
	icon_state = "duffel-inteqmed"
	item_state = "duffel-inteqmed"

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
	new /obj/item/mmi/syndie(src)
	new /obj/item/implantcase(src)
	new /obj/item/implanter(src)
	new /obj/item/reagent_containers/medspray/sterilizine(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/surgery_adv
	name = "advanced surgery duffel bag"
	desc = "A large duffel bag for holding surgical tools. Bears the logo of an advanced med-tech firm."

/obj/item/storage/backpack/duffelbag/syndie/inteq/surgery_adv/PopulateContents()
	new /obj/item/scalpel/advanced(src)
	new /obj/item/retractor/advanced(src)
	new /obj/item/surgicaldrill/advanced(src)
	new /obj/item/bonesetter(src)
	new /obj/item/blood_filter(src)
	new /obj/item/surgical_drapes(src)
	new /obj/item/clothing/suit/straight_jacket(src)
	new /obj/item/clothing/mask/muzzle(src)
	new /obj/item/mmi/syndie(src)
	new /obj/item/implantcase(src)
	new /obj/item/implanter(src)
	new /obj/item/reagent_containers/medspray/sterilizine(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo
	name = "ammunition duffel bag"
	desc = "A large duffel bag for holding extra weapons ammunition and supplies."

/obj/item/storage/backpack/duffelbag/syndie/inteq/shotgun
	desc = "A large duffel bag, packed to the brim with Bulldog shotgun drum magazines."

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/shotgun/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/ammo_box/magazine/m12g(src)
	new /obj/item/ammo_box/magazine/m12g/stun(src)
	new /obj/item/ammo_box/magazine/m12g/slug(src)
	new /obj/item/ammo_box/magazine/m12g/dragon(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/smg
	desc = "A large duffel bag, packed to the brim with C-20r magazines."

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/smg/PopulateContents()
	for(var/i in 1 to 9)
		new /obj/item/ammo_box/magazine/smgm45(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/hermes
	desc = "A large duffel bag, packed to the brim with various exosuit ammo."

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/hermes/PopulateContents()
	new /obj/item/mecha_ammo/incendiary(src)
	new /obj/item/mecha_ammo/incendiary(src)
	new /obj/item/mecha_ammo/incendiary(src)
	new /obj/item/mecha_ammo/flashbang(src)
	new /obj/item/mecha_ammo/flashbang(src)
	new /obj/item/mecha_ammo/flashbang(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/ares
	desc = "A large duffel bag, packed to the brim with various exosuit ammo."

/obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/ares/PopulateContents()
	new /obj/item/mecha_ammo/lmg(src)
	new /obj/item/mecha_ammo/lmg(src)
	new /obj/item/mecha_ammo/lmg(src)
	new /obj/item/mecha_ammo/scattershot(src)
	new /obj/item/mecha_ammo/scattershot(src)
	new /obj/item/mecha_ammo/scattershot(src)
	new /obj/item/mecha_ammo/missiles_he(src)
	new /obj/item/mecha_ammo/missiles_he(src)
	new /obj/item/mecha_ammo/missiles_he(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/c20rbundle
	desc = "A large duffel bag containing a C-20r, some magazines, and a cheap looking suppressor."

/obj/item/storage/backpack/duffelbag/syndie/inteq/c20rbundle/PopulateContents()
	new /obj/item/ammo_box/magazine/smgm45(src)
	new /obj/item/ammo_box/magazine/smgm45(src)
	new /obj/item/gun/ballistic/automatic/c20r(src)
	new /obj/item/suppressor/specialoffer(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/bulldogbundle
	desc = "A large duffel bag containing a Bulldog, some drums, and a pair of thermal imaging glasses."

/obj/item/storage/backpack/duffelbag/syndie/inteq/bulldogbundle/PopulateContents()
	new /obj/item/ammo_box/magazine/m12g(src)
	new /obj/item/gun/ballistic/automatic/shotgun/bulldog(src)
	new /obj/item/ammo_box/magazine/m12g/stun(src)
	new /obj/item/clothing/glasses/thermal/syndi(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/med/medicalbundle
	desc = "A large duffel bag containing a tactical medkit, a Donksoft machine gun, a big jumbo box of riot darts, and a knock-off pair of magboots."

/obj/item/storage/backpack/duffelbag/syndie/inteq/med/medicalbundle/PopulateContents()
	new /obj/item/clothing/shoes/magboots/syndie(src)
	new /obj/item/storage/firstaid/tactical/nukeop(src)
	new /obj/item/gun/ballistic/automatic/l6_saw/toy(src)
	new /obj/item/ammo_box/foambox/riot(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/med/bioterrorbundle
	desc = "A large duffel bag containing deadly chemicals, a handheld chem sprayer, Bioterror foam grenade, a Donksoft assault rifle, box of riot grade darts, a dart pistol, and a box of syringes."

/obj/item/storage/backpack/duffelbag/syndie/inteq/med/bioterrorbundle/PopulateContents()
	new /obj/item/reagent_containers/spray/chemsprayer/bioterror(src)
	new /obj/item/storage/box/syndie_kit/chemical(src)
	new /obj/item/gun/syringe/syndicate(src)
	new /obj/item/gun/ballistic/automatic/c20r/toy(src)
	new /obj/item/storage/box/syringes(src)
	new /obj/item/ammo_box/foambox/riot(src)
	new /obj/item/grenade/chem_grenade/bioterrorfoam(src)
	if(prob(5))
		new /obj/item/reagent_containers/food/snacks/pizza/pineapple(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/c4/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/grenade/plastic/c4(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/x4/PopulateContents()
	for(var/i in 1 to 3)
		new /obj/item/grenade/plastic/x4(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/firestarter
	desc = "A large duffel bag containing a New Russian pyro backpack sprayer, Elite hardsuit, a Stechkin APS pistol, minibomb, ammo, and other equipment."

/obj/item/storage/backpack/duffelbag/syndie/inteq/firestarter/PopulateContents()
	new /obj/item/clothing/under/syndicate/soviet(src)
	new /obj/item/watertank/op(src)
	new /obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq(src)
	new /obj/item/gun/ballistic/automatic/pistol/APS(src)
	new /obj/item/ammo_box/magazine/pistolm9mm(src)
	new /obj/item/ammo_box/magazine/pistolm9mm(src)
	new /obj/item/reagent_containers/food/drinks/bottle/vodka/badminka(src)
	new /obj/item/reagent_containers/syringe/stimulants(src)
	new /obj/item/grenade/syndieminibomb(src)

/obj/item/storage/backpack/duffelbag/syndie/inteq/shredderbundle
	desc = "A large duffel bag containing two CX Shredders, some magazines, an elite hardsuit, and a chest rig."

/obj/item/storage/backpack/duffelbag/syndie/inteq/shredderbundle/PopulateContents()
	new /obj/item/ammo_box/magazine/flechette/shredder(src)
	new /obj/item/ammo_box/magazine/flechette/shredder(src)
	new /obj/item/ammo_box/magazine/flechette/shredder(src)
	new /obj/item/ammo_box/magazine/flechette/shredder(src)
	new /obj/item/gun/ballistic/automatic/flechette/shredder(src)
	new /obj/item/gun/ballistic/automatic/flechette/shredder(src)
	new /obj/item/storage/belt/military(src)
	new /obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq(src)
