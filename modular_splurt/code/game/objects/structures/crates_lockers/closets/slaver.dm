/obj/structure/closet/slaver
	name = "slaver closet"
	desc = "Filled with the cheapest gear credits can buy."
	icon_state = "syndicate"

/obj/structure/closet/slaver/PopulateContents()
	..()

	new /obj/item/clothing/under/syndicate/skirt(src)
	new /obj/item/clothing/under/syndicate(src)
	new /obj/item/clothing/shoes/workboots(src)
	new /obj/item/storage/belt/military(src)
	new /obj/item/radio/headset/pirate(src)
	new /obj/item/crowbar/red(src)
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/assembly/flash(src)
	new /obj/item/melee/classic_baton/telescopic(src)
	new /obj/item/reagent_containers/hypospray/medipen/survival(src)
	new /obj/item/reagent_containers/hypospray/medipen/lewdsleepy(src)
	new /obj/item/slaver/gizmo(src)

//Copy of above in crate version
/obj/structure/closet/crate/slaver_loadout
	name = "slave trader standard issue loadout"

/obj/structure/closet/crate/slaver_loadout/PopulateContents()
	..()

	new /obj/item/clothing/under/syndicate/skirt(src)
	new /obj/item/clothing/under/syndicate(src)
	new /obj/item/clothing/shoes/workboots(src)
	new /obj/item/storage/belt/military(src)
	new /obj/item/radio/headset/pirate(src)
	new /obj/item/crowbar/red(src)
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/assembly/flash(src)
	new /obj/item/melee/classic_baton/telescopic(src)
	new /obj/item/reagent_containers/hypospray/medipen/survival(src)
	new /obj/item/reagent_containers/hypospray/medipen/lewdsleepy(src)
	new /obj/item/slaver/gizmo(src)

/obj/structure/closet/crate/slave_kink
	name = "Kinkmate Supply"

/obj/structure/closet/crate/slave_kink/PopulateContents()
	. = ..()

	new /obj/item/vending_refill/kink(src)
	new /obj/item/vending_refill/kink(src)
