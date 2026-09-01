/datum/outfit/plasmaman/centcom
	name = "CentCom Plasmaman"

	head = /obj/item/clothing/head/helmet/space/plasmaman/captain/centcom
	uniform = /obj/item/clothing/under/plasmaman/captain/centcom
	id = /obj/item/card/id
	ears = /obj/item/radio/headset/headset_cent/commander
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	back = /obj/item/storage/backpack/satchel/leather
	suit = /obj/item/clothing/suit/armor/bulletproof
	l_pocket = /obj/item/ammo_box/a357
	suit_store = /obj/item/gun/ballistic/revolver/mateba
	glasses = /obj/item/clothing/glasses/thermal

/datum/outfit/plasmaman/centcom/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

	var/obj/item/implant/mindshield/L = new //Here you go Deuryn
	L.implant(H, null, 1)

	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()//They get full station access.
	W.access += get_centcom_access("Death Commando")//Let's add their alloted CentCom access.
	W.assignment = "CentCom Official"
	W.registered_name = H.real_name
	W.update_label()
