/*/////////////////////////////////////////////////////////////////////////////////
///////																		///////
///////								Star Trek Stuffs						///////
///////																		///////
*//////////////////////////////////////////////////////////////////////////////////
//  <3 Nienhaus && Joan.
// I made the Voy and DS9 stuff tho. - Poojy
// Armor lists for even Heads of Staff is Nulled out do round start armor as well most armor going onto the suit itself rather then a armor slot - Trilby
///////////////////////////////////////////////////////////////////////////////////

//DS9

/obj/item/clothing/suit/storage/trek/ds9
	name = "Padded Overcoat"
	desc = "The overcoat worn by all officers of the 2380s."
	icon = 'modular_citadel/icons/obj/clothing/trek_item_icon.dmi'
	icon_state = "trek_ds9_coat"
	mob_overlay_icon = 'modular_citadel/icons/mob/clothing/trek_mob_icon.dmi'
	item_state = "trek_ds9_coat"
	body_parts_covered = CHEST|GROIN|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	permeability_coefficient = 0.50
	allowed = list(
		/obj/item/flashlight, /obj/item/analyzer,
		/obj/item/radio, /obj/item/tank/internals/emergency_oxygen,
		/obj/item/reagent_containers/hypospray, /obj/item/healthanalyzer,/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/glass/bottle/vial,/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/pill,/obj/item/storage/pill_bottle, /obj/item/restraints/handcuffs,/obj/item/hypospray
		)
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	brc_mitigation_bonus = 0  // BLUEMOON ADD

/obj/item/clothing/suit/storage/trek/ds9/equipped(mob/user, slot)  // BLUEMOON ADD
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && brc_mitigation_bonus > 0 && isliving(user))
		user.brc_mitigation += brc_mitigation_bonus
		brc_worn = TRUE

/obj/item/clothing/suit/storage/trek/ds9/dropped(mob/user)  // BLUEMOON ADD
	. = ..()
	if(brc_worn && isliving(user))
		user.brc_mitigation = max(0, user.brc_mitigation - brc_mitigation_bonus)
		brc_worn = FALSE

/obj/item/clothing/suit/storage/trek/ds9/admiral // Only for adminuz
	name = "Admiral Overcoat"
	desc = "Admirality specialty coat to keep flag officers fashionable and protected."
	icon_state = "trek_ds9_coat_adm"
	item_state = "trek_ds9_coat_adm"
	permeability_coefficient = 0.01
	armor = list(MELEE = 50, BULLET = 50, LASER = 50,ENERGY = 50, BOMB = 50, BIO = 50, RAD = 50, FIRE = 50, ACID = 50)
	brc_mitigation_bonus = 15  // BLUEMOON ADD

//MODERN ish Joan sqrl sprites. I think

//For general use
/obj/item/clothing/suit/storage/fluff/fedcoat
	name = "Federation Uniform Jacket"
	desc = "A uniform jacket from the United Federation. Set phasers to awesome."
	icon = 'modular_citadel/icons/obj/clothing/trek_item_icon.dmi'
	mob_overlay_icon = 'modular_citadel/icons/mob/clothing/trek_mob_icon.dmi'
	icon_state = "fedcoat"
	item_state = "fedcoat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|GROIN|ARMS
	allowed = list(
		/obj/item/tank/internals/emergency_oxygen,
		/obj/item/flashlight,
		/obj/item/analyzer,
		/obj/item/radio,
		/obj/item/gun,
		/obj/item/melee/baton,
		/obj/item/restraints/handcuffs,
		/obj/item/reagent_containers/hypospray,
		/obj/item/hypospray,
		/obj/item/healthanalyzer,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/glass/bottle/vial,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/storage/pill_bottle,
		/obj/item/taperecorder)
	armor = list(MELEE = 35, BULLET = 30, LASER = 30, ENERGY = 40, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 10)
	brc_mitigation_bonus = 10  // BLUEMOON ADD
	var/unbuttoned = FALSE

/obj/item/clothing/suit/storage/fluff/fedcoat/equipped(mob/user, slot)  // BLUEMOON ADD
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && brc_mitigation_bonus > 0 && isliving(user))
		user.brc_mitigation += brc_mitigation_bonus
		brc_worn = TRUE

/obj/item/clothing/suit/storage/fluff/fedcoat/dropped(mob/user)  // BLUEMOON ADD
	. = ..()
	if(brc_worn && isliving(user))
		user.brc_mitigation = max(0, user.brc_mitigation - brc_mitigation_bonus)
		brc_worn = FALSE

/obj/item/clothing/suit/storage/fluff/fedcoat/verb/toggle()
	set name = "Toggle coat buttons"
	set category = "Object"
	set src in usr

	var/mob/living/L = usr
	if(!istype(L) || !CHECK_MOBILITY(L, MOBILITY_USE))
		return FALSE

	switch(unbuttoned)
		if(FALSE)
			icon_state = "[initial(icon_state)]_open"
			item_state = "[initial(item_state)]_open"
			unbuttoned = TRUE
			to_chat(usr,"You unbutton the coat.")
		if(TRUE)
			icon_state = "[initial(icon_state)]"
			item_state = "[initial(item_state)]"
			unbuttoned = FALSE
			to_chat(usr,"You button up the coat.")
	usr.update_inv_wear_suit()

//Variants
/obj/item/clothing/suit/storage/fluff/fedcoat/medsci
	icon_state = "fedblue"
	item_state = "fedblue"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 0, ACID = 45)

/obj/item/clothing/suit/storage/fluff/fedcoat/eng
	icon_state = "fedeng"
	item_state = "fedeng"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 20, FIRE = 30, ACID = 45)

/obj/item/clothing/suit/storage/fluff/fedcoat/capt
	icon_state = "fedcapt"
	item_state = "fedcapt"
	armor = list(MELEE = 50, BULLET = 40, LASER = 50, ENERGY = 50, BOMB = 25, BIO = 0, RAD = 0, FIRE = 100, ACID = 90, WOUND = 30)
	brc_mitigation_bonus = 15  // BLUEMOON ADD

//"modern" ones for fancy

/obj/item/clothing/suit/storage/fluff/modernfedcoat
	name = "Modern Federation Uniform Jacket"
	desc = "A modern uniform jacket from the United Federation."
	icon = 'modular_citadel/icons/obj/clothing/trek_item_icon.dmi'
	mob_overlay_icon = 'modular_citadel/icons/mob/clothing/trek_mob_icon.dmi'
	icon_state = "fedmodern"
	item_state = "fedmodern"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	body_parts_covered = CHEST|GROIN|ARMS
	allowed = list(
	/obj/item/tank/internals/emergency_oxygen,
		/obj/item/flashlight,
		/obj/item/analyzer,
		/obj/item/radio,
		/obj/item/gun,
		/obj/item/melee/baton,
		/obj/item/restraints/handcuffs,
		/obj/item/reagent_containers/hypospray,
		/obj/item/hypospray,
		/obj/item/healthanalyzer,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/glass/bottle/vial,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/storage/pill_bottle,
		/obj/item/taperecorder)
	armor = list("melee" = 50, "bullet" = 40, "laser" = 50, "energy" = 50, "bomb" = 25, "bio" = 0, "rad" = 0, "fire" = 100, "acid" = 90, "wound" = 30)
	brc_mitigation_bonus = 15  // BLUEMOON ADD

/obj/item/clothing/suit/storage/fluff/modernfedcoat/equipped(mob/user, slot)  // BLUEMOON ADD
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && brc_mitigation_bonus > 0 && isliving(user))
		user.brc_mitigation += brc_mitigation_bonus
		brc_worn = TRUE

/obj/item/clothing/suit/storage/fluff/modernfedcoat/dropped(mob/user)  // BLUEMOON ADD
	. = ..()
	if(brc_worn && isliving(user))
		user.brc_mitigation = max(0, user.brc_mitigation - brc_mitigation_bonus)
		brc_worn = FALSE

//Variants
/obj/item/clothing/suit/storage/fluff/modernfedcoat/medsci
	icon_state = "fedmodernblue"
	item_state = "fedmodernblue"
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 50, "rad" = 0, "fire" = 0, "acid" = 45, "wound" = 0)


/obj/item/clothing/suit/storage/fluff/modernfedcoat/eng
	icon_state = "fedmoderneng"
	item_state = "fedmoderneng"
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 20, "fire" = 30, "acid" = 45, "wound" = 0)

/obj/item/clothing/suit/storage/fluff/modernfedcoat/sec
	icon_state = "fedmodernsec"
	item_state = "fedmodernsec"
	armor = list("melee" = 30, "bullet" = 30, "laser" = 30, "energy" = 40, "bomb" = 25, "bio" = 0, "rad" = 0, "fire" = 70, "acid" = 90, "wound" = 10)
	brc_mitigation_bonus = 10  // BLUEMOON ADD

/obj/item/clothing/head/caphat/formal/fedcover
	name = "Federation Officer's Cap"
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 25)
	desc = "An officer's cap that demands discipline from the one who wears it."
	icon = 'modular_citadel/icons/obj/clothing/trek_item_icon.dmi'
	icon_state = "fedcapofficer"
	mob_overlay_icon = 'modular_citadel/icons/mob/clothing/trek_mob_icon.dmi'
	item_state = "fedcapofficer"

//Variants
/obj/item/clothing/head/caphat/formal/fedcover/medsci
	icon_state = "fedcapsci"
	item_state = "fedcapsci"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 0, ACID = 45, WOUND = 0)

/obj/item/clothing/head/caphat/formal/fedcover/eng
	icon_state = "fedcapeng"
	item_state = "fedcapeng"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 20, FIRE = 30, ACID = 45, WOUND = 0)

/obj/item/clothing/head/caphat/formal/fedcover/sec
	icon_state = "fedcapsec"
	item_state = "fedcapsec"
	armor = list(MELEE = 40, BULLET = 30, LASER = 25, ENERGY = 10, BOMB = 25, BIO = 10, RAD = 0, FIRE = 50, ACID = 60, WOUND = 20)

/obj/item/clothing/head/caphat/formal/fedcover/black
	icon_state = "fedcapblack"
	item_state = "fedcapblack"
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 25)

//orvilike caps
/obj/item/clothing/head/kepi/orvi
	name = "\improper Federation kepi"
	desc = "A visored cap worn by all officers since 2550s."
	icon_state = "kepi_ass"

/obj/item/clothing/head/kepi/orvi/command
	icon_state = "kepi_com"
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 25)

/obj/item/clothing/head/kepi/orvi/sec
	icon_state = "kepi_sec"
	armor = list(MELEE = 40, BULLET = 30, LASER = 25, ENERGY = 10, BOMB = 25, BIO = 10, RAD = 0, FIRE = 50, ACID = 60, WOUND = 20)

/obj/item/clothing/head/kepi/orvi/eng
	icon_state = "kepi_eng"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 20, FIRE = 30, ACID = 45, WOUND = 0)

/obj/item/clothing/head/kepi/orvi/medsci
	icon_state = "kepi_medsci"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 0, ACID = 45, WOUND = 0)

/obj/item/clothing/head/kepi/orvi/service
	icon_state = "kepi_srv"
