/obj/item/storage/bag/rebar_quiver
	name = "rebar quiver"
	desc = "An oxygen tank cut in half, used for holding sharpened rods for the rebar crossbow."
	icon = 'modular_bluemoon/icons/obj/guns/quivers.dmi'
	icon_state = "rebar_quiver"
	item_state = "rebar_quiver"
	slot_flags = ITEM_SLOT_BACK | ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/rebar_quiver/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.max_combined_w_class = 30
	STR.max_items = 20
	STR.can_hold = typecacheof(/obj/item/ammo_casing/rebar)

/obj/item/storage/bag/rebar_quiver/syndicate
	name = "syndicate rebar quiver"
	desc = "A specialized quiver meant to hold any kind of bolts intended for use with the rebar crossbow. \
		Clearly a better design than a cut up oxygen tank..."
	icon_state = "syndie_quiver_0"
	item_state = "holyquiver"
	slot_flags = ITEM_SLOT_NECK
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/item/storage/bag/rebar_quiver/syndicate/PopulateContents()
	for(var/i in 1 to 20)
		new /obj/item/ammo_casing/rebar/syndie(src)

/obj/item/storage/bag/rebar_quiver/syndicate/update_icon_state()
	switch(contents.len)
		if(0)
			icon_state = "syndie_quiver_0"
		if(1 to 7)
			icon_state = "syndie_quiver_1"
		if(8 to 13)
			icon_state = "syndie_quiver_2"
		if(14 to INFINITY)
			icon_state = "syndie_quiver_3"
	return ..()

/obj/item/storage/bag/harpoon_quiver
	name = "harpoon quiver"
	desc = "A quiver for holding magnetic spears."
	icon = 'modular_bluemoon/icons/obj/guns/quivers.dmi'
	icon_state = "rebar_quiver"
	item_state = "rebar_quiver"
	slot_flags = ITEM_SLOT_BACK | ITEM_SLOT_BELT | ITEM_SLOT_SUITSTORE
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/storage/bag/harpoon_quiver/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 40
	STR.max_items = 40
	STR.display_numerical_stacking = TRUE
	STR.can_hold = typecacheof(/obj/item/ammo_casing/caseless/magspear)

/obj/item/storage/bag/harpoon_quiver/PopulateContents()
	for(var/i in 1 to 40)
		new /obj/item/ammo_casing/caseless/magspear(src)
