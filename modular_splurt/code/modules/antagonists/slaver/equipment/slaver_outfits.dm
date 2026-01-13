/datum/outfit/slaver
	name = "Slave Trader"

	uniform = /obj/item/clothing/under/syndicate
	glasses = /obj/item/clothing/glasses/sunglasses
	shoes = /obj/item/clothing/shoes/workboots
	gloves = /obj/item/clothing/gloves/color/black
	back = /obj/item/storage/backpack
	ears = /obj/item/radio/headset/pirate/bowman //BLUEMOON ADD
	id = /obj/item/card/id/syndicate/slaver
	backpack_contents = list(/obj/item/storage/box/survival,\
		/obj/item/kitchen/knife/combat/survival)
	var/command_radio = FALSE

/datum/outfit/slaver/leader
	name = "Slave Master"

	id = /obj/item/card/id/syndicate/slaver/leader
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	command_radio = TRUE

// BLUEMOON ADD START - командная коробочка для командира
/obj/item/radio/headset/pirate/bowman //И бовманки
	bowman = TRUE

/obj/item/radio/headset/pirate/bowman/Initialize(mapload)
	. = ..()
	bowmanize()

/datum/outfit/slaver/leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/slaver/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	. = ..()

	var/obj/item/card/id/W = H.wear_id
	W.registered_name = H.real_name
	W.assignment = name
	W.update_label()

	H.faction |= ROLE_SLAVER
	H.update_icons()
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_PIRATE)
	R.freqlock = TRUE
	if(command_radio)
		R.command = TRUE
