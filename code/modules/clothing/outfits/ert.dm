
/obj/item/paper/beamgun_istruction
	name = "Инструкция по пользованию Medical Beamgun"
	default_raw_text = "<b>*ПРЕДУПРЕЖДЕНИЕ, НЕ СКРЕЩИВАЙТЕ ДВА ЛУЧА ИЛИ БОЛЕЕ*</b>"

/datum/outfit/ert
	name = "ERT Common"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	uniform = /obj/item/clothing/under/syndicate/combat/ert
	accessory = list(/obj/item/clothing/accessory/bodycamera)
	shoes = /obj/item/clothing/shoes/combat/swat/knife
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	ears = /obj/item/radio/headset/headset_cent/alt

	internals_slot = ITEM_SLOT_RPOCKET
	l_pocket = /obj/item/extinguisher/mini
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double
	suit_store = /obj/item/gun/energy/e_gun/nuclear/ert

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

	implants = list(
		/obj/item/implant/mindshield,
		/obj/item/implant/deathrattle/centcom,
		/obj/item/implant/weapons_auth,
		/obj/item/implant/radio/centcom,
		)
	cybernetic_implants = list(/obj/item/organ/cyberimp/eyes/hud/security,/obj/item/organ/cyberimp/chest/nutrimentextreme, /obj/item/organ/cyberimp/chest/chem_implant)


/datum/outfit/ert/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/implant/mindshield/L = new
	L.implant(H, null, 1)

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

	var/obj/item/card/id/W = H.wear_id
	if(W)
		W.registered_name = H.real_name
		W.update_label()

/datum/outfit/ert/commander/green
	name = "ERT Commander - Green Alert"

	id = /obj/item/card/id/ert
	head = /obj/item/clothing/head/helmet/swat/command
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/armor/hos/command
	suit_store = /obj/item/gun/energy/modular_laser_rifle/carbine
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	back = /obj/item/storage/backpack/ert_commander
	belt = /obj/item/storage/belt/military/ert_min

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/ert_commander=1,
		/obj/item/storage/firstaid/regular=1,
		)

	cybernetic_implants = list(/obj/item/organ/cyberimp/eyes/hud/security,/obj/item/organ/cyberimp/chest/nutrimentextreme, /obj/item/organ/cyberimp/chest/chem_implant)

/datum/outfit/ert/commander
	name = "ERT Commander - Blue Alert"

	id = /obj/item/card/id/ert
	suit = /obj/item/clothing/suit/space/hardsuit/ert
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	back = /obj/item/storage/backpack/ert_commander
	belt = /obj/item/storage/belt/military/ert_min
	suit_store = /obj/item/gun/ballistic/automatic/ar

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/ert_commander=1,
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/storage/box/ammo/m556=1,\
		/obj/item/gun/energy/e_gun/nuclear/ert=1,\
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/shield,
	)

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/commander/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/commander/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	. = ..()

	if(visualsOnly)
		return
	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()

/datum/outfit/ert/commander/alert
	name = "ERT Commander - Amber Alert"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	belt = /obj/item/storage/belt/military/ert_max
	suit_store = /obj/item/gun/energy/modular_laser_rifle
	l_pocket = /obj/item/gun/ballistic/revolver/mateba
	shoes = /obj/item/clothing/shoes/magboots/syndie/advance

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/box/ert_commander=1,\
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/gun/energy/e_gun/nuclear/ert=1,\
		/obj/item/ammo_box/a357=2,\
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/commander/alert/red
	name = "ERT Commander - Red Alert"
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit_store = /obj/item/gun/energy/modular_laser_rifle/zealstar
	l_pocket = /obj/item/gun/energy/pulse/pistol/loyalpin
	shoes = /obj/item/clothing/shoes/magboots/advance/debug

	backpack_contents = list(/obj/item/storage/box/survival/centcom_max=1,\
		/obj/item/storage/box/ert_commander=1,
		/obj/item/storage/firstaid/tactical/ert_first = 1,\
		/obj/item/storage/firstaid/tactical/ert_second = 1,\
		/obj/item/reagent_containers/hypospray/combat/nanites=1,\
		/obj/item/gun/energy/e_gun/nuclear/ert=1,\
		)
	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/security/green
	name = "ERT Security - Green Alert"

	id = /obj/item/card/id/ert/Security
	head = /obj/item/clothing/head/helmet/swat/security
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/armor/hos/security
	suit_store = /obj/item/gun/energy/modular_laser_rifle/carbine
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	belt = /obj/item/storage/belt/military/ert_min
	back = /obj/item/storage/backpack/ert_commander/ert_security

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/regular=1,
		/obj/item/storage/box/handcuffs=1,\
		/obj/item/gun/energy/e_gun/dragnet=1,
		)

	cybernetic_implants = list(/obj/item/organ/cyberimp/eyes/hud/security,/obj/item/organ/cyberimp/chest/nutrimentextreme, /obj/item/organ/cyberimp/chest/chem_implant)

/datum/outfit/ert/security
	name = "ERT Security - Blue Alert"

	id = /obj/item/card/id/ert/Security
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/space/hardsuit/ert/sec
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	belt = /obj/item/storage/belt/military/ert_min
	back = /obj/item/storage/backpack/ert_commander/ert_security
	suit_store = /obj/item/gun/ballistic/automatic/ar

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\

		/obj/item/storage/box/handcuffs=1,\
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/storage/box/ammo/m556 = 1,
		/obj/item/gun/energy/e_gun/dragnet=1,
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/shield,
	)

/datum/outfit/ert/security/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/hos
	R.recalculateChannels()

/datum/outfit/ert/security/alert
	name = "ERT Security - Amber Alert"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sec
	suit_store = /obj/item/gun/energy/modular_laser_rifle
	l_pocket = /obj/item/gun/ballistic/revolver/mateba
	belt = /obj/item/storage/belt/military/ert_max


	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/box/handcuffs=1,\
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/gun/energy/e_gun/dragnet=1,\
		/obj/item/gun/energy/e_gun/nuclear/ert=1,\
		/obj/item/ammo_box/a357=2,\
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/security/alert/red
	name = "ERT Security - Red Alert"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit_store = /obj/item/gun/energy/modular_laser_rifle/zealstar
	l_pocket = /obj/item/gun/energy/pulse/pistol/loyalpin

	backpack_contents = list(/obj/item/storage/box/survival/centcom_max=1,\
		/obj/item/storage/firstaid/tactical/ert_first = 1,\
		/obj/item/storage/firstaid/tactical/ert_second = 1,\
		/obj/item/reagent_containers/hypospray/combat/nanites=1,\
		/obj/item/storage/box/handcuffs=1,\
		/obj/item/gun/energy/e_gun/dragnet=1,
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/medic/green
	name = "ERT Medic - Green Alert"

	id = /obj/item/card/id/ert/Medical
	head = /obj/item/clothing/head/helmet/swat/medical
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/armor/hos/medical
	suit_store = /obj/item/gun/energy/modular_laser_rifle/carbine
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	back = /obj/item/storage/backpack/ert_commander/ert_medical
	belt = /obj/item/defibrillator/compact/loaded_ert
	l_hand = null

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/tactical/ert_first = 1,
		/obj/item/storage/firstaid/tactical/ert_second = 1,
		/obj/item/gun/medbeam=1,
		/obj/item/paper/beamgun_istruction=1,
		/obj/item/roller=1,
		/obj/item/bodybag/bluespace=1,
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/surgery,
	)

/datum/outfit/ert/medic
	name = "ERT Medic - Blue Alert"

	id = /obj/item/card/id/ert/Medical
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/space/hardsuit/ert/med
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	back = /obj/item/storage/backpack/ert_commander/ert_medical
	belt = /obj/item/defibrillator/compact/loaded_ert
	suit_store = /obj/item/gun/ballistic/automatic/ar

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/tactical/ert_first = 1,\
		/obj/item/storage/firstaid/tactical/ert_second = 1,\
		/obj/item/storage/box/ammo/m556=1,\
		/obj/item/reagent_containers/hypospray/combat=1,\
		/obj/item/gun/medbeam=1,\
		/obj/item/paper/beamgun_istruction=1,\
		/obj/item/roller=1,\
		/obj/item/bodybag/bluespace=1,\
		/obj/item/gun/energy/e_gun/nuclear/ert=1,\
	)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/surgery/advanced,
	)

/datum/outfit/ert/medic/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	ADD_TRAIT(H, TRAIT_SURGEON, TRAIT_GENERIC)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/cmo
	R.recalculateChannels()

/datum/outfit/ert/medic/alert
	name = "ERT Medic - Amber Alert"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/med
	suit_store = /obj/item/gun/energy/modular_laser_rifle
	l_pocket = /obj/item/gun/ballistic/revolver/mateba

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/gun/energy/e_gun/nuclear/ert=1,
		/obj/item/storage/firstaid/tactical/ert_first = 1,
		/obj/item/storage/firstaid/tactical/ert_second = 1,
		/obj/item/reagent_containers/hypospray/combat/nanites=1,\
		/obj/item/gun/medbeam=1,
		/obj/item/paper/beamgun_istruction=1,
		/obj/item/roller=1,
		/obj/item/bodybag/bluespace=1,
		/obj/item/ammo_box/a357=2,\
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/surgery/advanced,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/medic/alert/red
	name = "ERT Medic - Red Alert"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	suit_store = /obj/item/gun/energy/modular_laser_rifle/zealstar
	l_pocket = /obj/item/gun/energy/pulse/pistol/loyalpin

	backpack_contents = list(/obj/item/storage/box/survival/centcom_max=1,\
		/obj/item/storage/firstaid/tactical/ert_first = 1,
		/obj/item/storage/firstaid/tactical/ert_second = 1,
		/obj/item/reagent_containers/hypospray/combat/nanites=1,\
		/obj/item/gun/medbeam=1,
		/obj/item/paper/beamgun_istruction=1,
		/obj/item/roller=1,
		/obj/item/bodybag/bluespace=1,
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/surgery/advanced,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/engineer/green
	name = "ERT Engineer - Green Alert"

	id = /obj/item/card/id/ert/Engineer
	head = /obj/item/clothing/head/helmet/swat/engineer
	suit = /obj/item/clothing/suit/armor/hos/engineer
	suit_store = /obj/item/gun/energy/modular_laser_rifle/carbine
	glasses =  /obj/item/clothing/glasses/meson/night/ert
	back = /obj/item/storage/backpack/ert_commander/ert_engineering
	belt = /obj/item/storage/belt/utility/chief/full

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/rcd_ammo/large=2,
		/obj/item/construction/rcd/combat=1,
		/obj/item/inducer=1,
		/obj/item/stock_parts/cell/vortex=1,
	)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/eyes/robotic/shield,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/toolset,
	)


/datum/outfit/ert/engineer
	name = "ERT Engineer - Blue Alert"

	id = /obj/item/card/id/ert/Engineer
	suit = /obj/item/clothing/suit/space/hardsuit/ert/engi
	glasses =  /obj/item/clothing/glasses/meson/night/ert
	back = /obj/item/storage/backpack/ert_commander/ert_engineering
	belt = /obj/item/storage/belt/utility/chief/full
	suit_store = /obj/item/gun/ballistic/automatic/ar

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/box/ammo/m556=1,
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/rcd_ammo/large=2,
		/obj/item/construction/rcd/combat=1,
		/obj/item/inducer=1,
		/obj/item/stock_parts/cell/vortex=1,
		/obj/item/gun/energy/e_gun/nuclear/ert=1,\
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/eyes/robotic/shield,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/toolset/advanced,
	)

/datum/outfit/ert/engineer/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/ce
	R.recalculateChannels()

/datum/outfit/ert/engineer/alert
	name = "ERT Engineer - Amber Alert"

	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/engi
	suit_store = /obj/item/gun/energy/modular_laser_rifle
	l_pocket = /obj/item/gun/ballistic/revolver/mateba


	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/gun/energy/e_gun/nuclear/ert=1,\
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/construction/rcd/combat=1,
		/obj/item/inducer/sci/combat=1,
		/obj/item/stock_parts/cell/vortex=1,
		/obj/item/ammo_box/a357=2,\
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/eyes/robotic/shield,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/toolset/advanced,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/engineer/alert/red
	name = "ERT Engineer - Red Alert"

	suit_store = /obj/item/gun/energy/modular_laser_rifle/zealstar
	l_pocket = /obj/item/gun/energy/pulse/pistol/loyalpin


	backpack_contents = list(/obj/item/storage/box/survival/centcom_max=1,\
		/obj/item/storage/firstaid/tactical/ert_first = 1,\
		/obj/item/storage/firstaid/tactical/ert_second = 1,\
		/obj/item/reagent_containers/hypospray/combat/nanites=1,\
		/obj/item/construction/rcd/combat=1,
		/obj/item/inducer/sci/combat=1,
		/obj/item/stock_parts/cell/vortex=1,
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/toolset/advanced,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/janitor
	name = "ERT Janitor"

	l_hand = /obj/item/storage/bag/trash/bluespace
	id = /obj/item/card/id/ert
	mask = /obj/item/clothing/mask/gas/sechailer/syndicate
	head = /obj/item/clothing/head/helmet/swat/janitor
	suit = /obj/item/clothing/suit/armor/hos/janitor
	glasses = /obj/item/clothing/glasses/night/syndicate
	back = /obj/item/storage/backpack/ert_commander/ert_janitor
	belt = /obj/item/storage/belt/janitor/ert_maid


	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/firstaid/regular=1,\
		/obj/item/storage/box/ammo/cleaning_grenades=1,
		/obj/item/bodybag/bluespace=1,
		/obj/item/mop/advanced=1,
		/obj/item/gun/energy/broom=1,
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant,
		/obj/item/organ/cyberimp/arm/janitor,
		)


/datum/outfit/ert/janitor/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return
	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()

/datum/outfit/ert/greybois
	name = "Emergency Assistant"

	uniform = /obj/item/clothing/under/color/grey/glorf
	suit = /obj/item/clothing/suit/hazardvest
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/color/fyellow
	ears = /obj/item/radio/headset
	head = /obj/item/clothing/head/soft/grey
	belt = /obj/item/storage/belt/utility/full
	back = /obj/item/storage/backpack
	mask = /obj/item/clothing/mask/gas
	l_hand = /obj/item/storage/toolbox/plastitanium
	id = /obj/item/card/id


	backpack_contents = list(/obj/item/storage/box/survival/centcom,
		/obj/item/storage/firstaid/regular,
		)

/datum/outfit/ert/greybois/greygod
	l_hand = /obj/item/spear/grey_tide
	gloves = /obj/item/clothing/gloves/color/yellow

/datum/outfit/ert/greybois/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return
	var/obj/item/card/id/W = H.wear_id
	W.registered_name = H.real_name
	W.assignment = "Assistant"
	W.special_assignment = "assistant"
	W.access = list(ACCESS_MAINT_TUNNELS,ACCESS_CENT_GENERAL)
	W.update_label()
	H.sec_hud_set_ID()

/datum/outfit/ert/commander/inquisitor
	name = "Inquisition Commander"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	l_hand = /obj/item/gun/ballistic/automatic/proto
	suit = /obj/item/clothing/suit/space/hardsuit/ert/paranormal
	belt = /obj/item/storage/belt/military/ert_max

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/ert_commander=1,
		/obj/item/storage/firstaid/tactical/ert_first = 1,\
		/obj/item/storage/firstaid/tactical/ert_second = 1,\
		/obj/item/reagent_containers/hypospray/combat/nanites=1,\
		/obj/item/storage/box/ammo/holy=1,
		/obj/item/storage/box/ammo/smgap=1,
		/obj/item/nullrod=1,
		/obj/item/storage/book/bible = 1,
		/obj/item/aspergillum/ert = 1, // BLUEMOON EDIT - кропило ЕРТ
		/obj/item/reagent_containers/food/drinks/bottle/holywater = 1 // BLUEMOON EDIT - кропило ЕРТ
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)


/datum/outfit/ert/security/inquisitor
	name = "Inquisition Security"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	suit = /obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor
	l_hand = /obj/item/gun/ballistic/automatic/proto
	belt = /obj/item/storage/belt/military/ert_max

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/firstaid/regular=1,
		/obj/item/gun/energy/e_gun/dragnet=1,
		/obj/item/storage/box/ammo/smgap=1,
		/obj/item/storage/box/ammo/holy=1,
		/obj/item/storage/box/handcuffs=1,
		/obj/item/nullrod=1,
		/obj/item/storage/book/bible = 1,
		/obj/item/aspergillum/ert = 1, // BLUEMOON EDIT - кропило ЕРТ
		/obj/item/reagent_containers/food/drinks/bottle/holywater = 1 // BLUEMOON EDIT - кропило ЕРТ
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)


/datum/outfit/ert/medic/inquisitor
	name = "Inquisition Medic"

	mask = /obj/item/clothing/mask/gas/sechailer/swat
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	suit = /obj/item/clothing/suit/space/hardsuit/ert/paranormal/inquisitor
	l_hand = /obj/item/gun/ballistic/automatic/proto
	belt = /obj/item/defibrillator/compact/loaded_ert

	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/ammo/smgap=1,\
		/obj/item/storage/box/ammo/holy=1,
		/obj/item/reagent_containers/hypospray/combat=1,\
		/obj/item/gun/medbeam=1,\
		/obj/item/paper/beamgun_istruction=1,
		/obj/item/roller=1,
		/obj/item/nullrod=1,
		/obj/item/storage/book/bible = 1,
		/obj/item/aspergillum/ert = 1, // BLUEMOON EDIT - кропило ЕРТ
		/obj/item/reagent_containers/food/drinks/bottle/holywater = 1 // BLUEMOON EDIT - кропило ЕРТ
		)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/surgery/advanced,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

//Агенты ЦК

/datum/outfit/ert/centcom_official
	name = "CentCom Official"
	uniform = /obj/item/clothing/under/syndicate/sniper
	suit = /obj/item/clothing/suit/armor/vest/agent
	shoes = /obj/item/clothing/shoes/laceup
	head = /obj/item/clothing/head/HoS/beret/syndicate
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	belt = /obj/item/storage/belt/military/ert_max
	back = /obj/item/storage/backpack/satchel
	mask = null
	id = /obj/item/card/id/ert


	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,
		/obj/item/storage/box/ert_commander=1,
		)

	implants = list(
		/obj/item/implant/mindshield,
		/obj/item/implant/deathrattle/centcom,
		/obj/item/implant/weapons_auth,
		/obj/item/implant/radio/centcom,
		/obj/item/implant/cqc,
	)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/mouth/breathing_tube,
	)

/datum/outfit/ert/centcom_official/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()

	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()//They get full station access.
	W.access += get_centcom_access("Death Commando")//Let's add their alloted CentCom access.
	W.assignment = "CentCom Official"
	W.registered_name = H.real_name
	W.update_label()
