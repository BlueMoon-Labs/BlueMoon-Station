/datum/outfit/lfwb_ordinator
	name = "Ординатор Трибунала"

	uniform = /obj/item/clothing/under/syndicate/ordinator
	suit = /obj/item/clothing/suit/armor/hos/ordinator
	head = /obj/item/clothing/head/helmet/knight/ordinator
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	mask = /obj/item/clothing/mask/gas/atmos/lfwb
	glasses = /obj/item/clothing/glasses/hud/security/lfwb
	back = /obj/item/storage/backpack/rucksack
	l_pocket = /obj/item/ammo_box/magazine/fal
	r_pocket = /obj/item/flashlight/lantern
	suit_store = /obj/item/gun/ballistic/automatic/fal
	belt = /obj/item/storage/belt/grenade/full
	r_hand = /obj/item/claymore/baron
	l_hand = /obj/item/gun/energy/taser/bolestrel
	id = /obj/item/card/id/ert
	ears = /obj/item/radio/headset/headset_cent/alt

	backpack_contents = list(/obj/item/storage/box/survival/security=1,\
		/obj/item/storage/firstaid/tactical/slaver=1,\
		/obj/item/sign/flag/ravenheart/alt=1,\
		/obj/item/storage/box/raven_box/posters=1,\
		/obj/item/ammo_box/c308=1,\
		/obj/item/grenade/plastic/x4=1)

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/lfwb_ordinator/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

	var/obj/item/implant/mindshield/L = new //Here you go Deuryn
	L.implant(H, null, 1)

	var/obj/item/card/id/ert/W = H.wear_id
	W.access = get_all_accesses()//They get full station access.
	W.access += get_centcom_access("Death Commando")//Let's add their alloted CentCom access.
	W.registered_name = H.real_name
	W.assignment = "Tribunal Ordinator"
	W.update_label()

/datum/outfit/lfwb_ordinator/officer
	name = "Офицер-ординатор трибунала"
	uniform = /obj/item/clothing/under/syndicate/ordinator/leader
	suit = /obj/item/clothing/suit/armor/hos/ordinator/leader
	l_hand = /obj/item/gun/energy/taser/legax

/datum/outfit/lfwb_ordinator/officer/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)

/datum/outfit/ert/commander/rabbit
	name = "Rabbit Team Leader"

	uniform = /obj/item/clothing/under/suit/lobotomy/rabbit
	head = /obj/item/clothing/head/rabbit_helmet
	suit = /obj/item/clothing/suit/armor/ego_gear/rabbit
	l_hand = /obj/item/gun/energy/e_gun/rabbit/captain
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	belt = /obj/item/storage/belt/military/ert_max
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/commander/rabbit/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	if(visualsOnly)
		return

	var/obj/item/implant/explosive/L = new/obj/item/implant/explosive(H)
	L.implant(H, null, 1)
	H.faction |= "rabbit"
	..()

/datum/outfit/ert/security/rabbit
	name = "Rabbit Team"

	uniform = /obj/item/clothing/under/suit/lobotomy/rabbit
	head = /obj/item/clothing/head/rabbit_helmet/grunt
	suit = /obj/item/clothing/suit/armor/ego_gear/rabbit/grunts
	l_hand = /obj/item/gun/energy/e_gun/rabbit
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	belt = /obj/item/storage/belt/military/ert_max
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1)

	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutrimentextreme,
		/obj/item/organ/cyberimp/chest/chem_implant/plus,
		/obj/item/organ/cyberimp/arm/shield,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/cyberimp/chest/thrusters,
	)

/datum/outfit/ert/security/rabbit/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	if(visualsOnly)
		return

	var/obj/item/implant/explosive/L = new/obj/item/implant/explosive(H)
	L.implant(H, null, 1)
	H.faction |= "rabbit"
	..()

//Огненные ЕРТшники. Костюмы.
/datum/outfit/ert/firesquad_commander
	name = "Firesquad Commander"

	id = /obj/item/card/id/ert
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sec/fire
	suit_store = /obj/item/gun/energy/laser/hellgun/immolator/multi
	glasses = /obj/item/clothing/glasses/thermal/eyepatch
	back = /obj/item/storage/backpack/rucksack
	belt = /obj/item/storage/belt/grenade/fire_grenade
	r_hand = /obj/item/gun/energy/laser/hellgun
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/clothing/mask/gas/sechailer/swat=1,\
		/obj/machinery/igniter=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/stack/sheet/mineral/plasma/thirty, \
		/obj/item/gun/energy/m2a100)
	l_pocket = /obj/item/melee/transforming/energy/sword/saber

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/firesquad_commander/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/firesquad_commander/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return
	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()

/datum/outfit/ert/firesquad_trooper
	name = "Firesquad Trooper"

	id = /obj/item/card/id/ert/Security
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sec/fire
	suit_store = /obj/item/gun/energy/laser/hellgun/immolator/multi
	glasses = /obj/item/clothing/glasses/thermal/eyepatch
	back = /obj/item/storage/backpack/rucksack
	belt = /obj/item/storage/belt/grenade/fire_grenade
	l_hand = /obj/item/gun/energy/laser/hellgun
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/clothing/mask/gas/sechailer=1,\
		/obj/machinery/igniter=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/stack/sheet/mineral/plasma/thirty, \
		/obj/item/gun/energy/m2a100)

/datum/outfit/ert/firesquad_trooper/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/hos
	R.recalculateChannels()

//Тяжелые ЕРТшники. Костюмы.
/datum/outfit/ert/heavysquad_commander
	name = "Heavy Weapons Commander"

	id = /obj/item/card/id/ert
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/ert_commander
	belt = /obj/item/storage/belt/grenade/full
	r_hand = /obj/item/gun/ballistic/automatic/shotgun/bulldog/unrestricted
	//l_hand = /obj/item/melee/powerfist
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/clothing/mask/gas/sechailer/swat=1,\
		/obj/item/choice_beacon/ert_mech=1,\
		/obj/item/storage/box/syndie_kit/revolver=1,\
		/obj/item/grenade/plastic/x4=1,
		/obj/item/storage/ifak=1,\
		/obj/item/ammo_box/magazine/m12g/slug=3)
	l_pocket = /obj/item/melee/transforming/energy/sword/saber

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/heavysquad_commander/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/heavysquad_commander/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return
	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()

/datum/outfit/ert/heavysquad_trooper
	name = "Heavy Weapons Trooper"

	id = /obj/item/card/id/ert/Security
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sec
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/ert_commander/ert_security
	belt = /obj/item/storage/belt/grenade/full
	r_hand = /obj/item/gun/ballistic/automatic/ar
	l_hand = /obj/item/melee/powerfist
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/clothing/mask/gas/sechailer=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/ammo_box/magazine/m556=3)

/datum/outfit/ert/heavysquad_trooper/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/hos
	R.recalculateChannels()

/datum/outfit/ert/heavysquad_machinegun
	name = "Heavy Squad Machinegunner"

	id = /obj/item/card/id/ert/Security
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sec
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/ert_commander/ert_security
	belt = /obj/item/storage/belt/security/full
	r_hand = /obj/item/gun/ballistic/automatic/l6_saw/unrestricted
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/ammo_box/magazine/mm712x82=2)

/datum/outfit/ert/heavysquad_machinegun/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/hos
	R.recalculateChannels()

//Zeal Team ERT. Костюмы.
/datum/outfit/zeal_team
	name = "Zeal Team Commando"

	uniform = /obj/item/clothing/under/syndicate
	head = /obj/item/clothing/head/helmet/juggernaut
	suit = /obj/item/clothing/suit/armor/heavy/juggernaut
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	glasses = /obj/item/clothing/glasses/hud/toggle/thermal
	back = /obj/item/storage/backpack/rucksack
	l_pocket = /obj/item/melee/transforming/energy/sword/saber
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double
	belt = /obj/item/storage/belt/grenade/full
	r_hand = /obj/item/gun/ballistic/automatic/l6_saw/unrestricted
	id = /obj/item/card/id/ert
	ears = /obj/item/radio/headset/headset_cent/alt

	backpack_contents = list(/obj/item/storage/box/survival/security=1,\
		/obj/item/storage/firstaid/tactical=1,\
		/obj/item/pinpointer/nuke=1,\
		/obj/item/grenade/plastic/x4=1,\
		/obj/item/ammo_box/magazine/mm712x82=2)

	give_space_cooler_if_synth = TRUE

/datum/outfit/zeal_team/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

	var/obj/item/implant/mindshield/MS = new
	MS.implant(H, null, 1)
	var/obj/item/organ/cyberimp/brain/anti_stun/AS = new
	AS.Insert(H, null, 1)

	var/obj/item/card/id/death/W = H.wear_id
	W.access = get_all_accesses()//They get full station access.
	W.access += get_centcom_access("Emergency Response Team Commander")//Let's add their alloted CentCom access.
	W.registered_name = H.real_name
	W.update_label(W.registered_name)

/datum/outfit/zeal_team/officer
	name = "Zeal Team Officer"

/datum/outfit/zeal_team/officer/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)

//Русский ОБР. Костюмы.
/datum/outfit/ert/ert_russian_soldier
	name = "NRI Spetsnaz Soldier"

	id = /obj/item/card/id/nri
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/nri
	//head = /obj/item/clothing/head/helmet/alt
	uniform = /obj/item/clothing/under/rank/security/officer/nri_military
	mask = /obj/item/clothing/mask/gas/syndicate/ds/mouth
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/hecu/black
	belt = /obj/item/storage/belt/military/russianweb
	ears = /obj/item/radio/headset/nri/bowman
	r_hand = /obj/item/gun/ballistic/automatic/l6_saw/pkmp
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/clothing/mask/gas/sechailer=1,\
		/obj/item/gun/ballistic/revolver/mateba=1,
		/obj/item/storage/ifak=1,\
		/obj/item/ammo_box/magazine/mm712x82=2)

/datum/outfit/ert/ert_russian_soldier/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.recalculateChannels()

	R.set_frequency(FREQ_NRI)

	H.grant_language(/datum/language/modular_sand/technorussian, TRUE, TRUE)

	var/obj/item/card/id/nri/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label(W.registered_name)


/datum/outfit/ert/ert_russian_support
	name = "NRI Spetsnaz Support"

	id = /obj/item/card/id/nri
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/nri/adv
	//head = /obj/item/clothing/head/helmet/alt
	uniform = /obj/item/clothing/under/rank/security/officer/nri_military
	mask = /obj/item/clothing/mask/gas/syndicate/ds/mouth
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/rucksack/green
	belt = /obj/item/storage/belt/military/russianweb
	ears = /obj/item/radio/headset/nri/bowman
	r_hand = /obj/item/gun/ballistic/automatic/ak12
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/gun/medbeam=1,
		/obj/item/storage/firstaid/tactical=1,\
		/obj/item/storage/barricade=1,\
		/obj/item/ammo_box/magazine/ak12=4)

/datum/outfit/ert/ert_russian_support/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.recalculateChannels()

	R.set_frequency(FREQ_NRI)

	H.grant_language(/datum/language/modular_sand/technorussian, TRUE, TRUE)

	var/obj/item/card/id/nri/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label(W.registered_name)

/datum/outfit/ert/ert_russian_leader
	name = "NRI Spetsnaz Leader"

	id = /obj/item/card/id/nri
	neck = /obj/item/clothing/neck/cloak/nri_cloak
	suit = /obj/item/clothing/suit/armor/nri_vest
	head = /obj/item/clothing/head/HoS/beret/nri
	uniform = /obj/item/clothing/under/rank/security/officer/nri_military
	mask = /obj/item/clothing/mask/gas/syndicate/ds/mouth
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/hecu
	belt = /obj/item/storage/belt/grenade/full
	l_pocket = /obj/item/melee/transforming/energy/sword/saber
	ears = /obj/item/radio/headset/nri/bowman/command
	r_hand = /obj/item/gun/ballistic/automatic/vss
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/choice_beacon/nri_mech=1,\
		/obj/item/storage/box/syndie_kit/revolver=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/ammo_box/magazine/vss_mag=4)

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/ert_russian_leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/ert_russian_leader/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.recalculateChannels()

	R.set_frequency(FREQ_NRI)

	H.grant_language(/datum/language/modular_sand/technorussian, TRUE, TRUE)

	var/obj/item/card/id/nri/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label(W.registered_name)


//Солдаты армии Солнечной Системы
/datum/outfit/ert/sol_soldier
	name = "SolFed Marine"

	id = /obj/item/card/id/sol
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sol
//	head = /obj/item/clothing/head/helmet/alt
	uniform = /obj/item/clothing/under/rank/security/officer/solfed_military
	mask = /obj/item/clothing/mask/gas/syndicate/ds/coif
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/hecu/black
	belt = /obj/item/storage/belt/military/inteq
	ears = /obj/item/radio/headset/sol/bowman
	r_hand = /obj/item/gun/ballistic/automatic/m16a4
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/ammo_box/magazine/m16=4)

/datum/outfit/ert/sol_soldier/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_SOL)
	R.freqlock = TRUE

	H.grant_language(/datum/language/modular_sand/solcommon, TRUE, TRUE)

	var/obj/item/card/id/sol/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label(W.registered_name)

///////////////

/datum/outfit/ert/sol_soldier_support
	name = "SolFed Marine Support"

	id = /obj/item/card/id/sol
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sol/adv
//	head = /obj/item/clothing/head/helmet/alt
	uniform = /obj/item/clothing/under/rank/security/officer/solfed_military
	mask = /obj/item/clothing/mask/gas/syndicate/ds/coif
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/rucksack
	belt = /obj/item/storage/belt/military/inteq
	ears = /obj/item/radio/headset/sol/bowman
	r_hand = /obj/item/gun/ballistic/automatic/laser
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/gun/medbeam=1,
		/obj/item/storage/firstaid/tactical=1,\
		/obj/item/ammo_box/magazine/recharge = 4,\
		/obj/item/storage/barricade=1)

/datum/outfit/ert/sol_soldier_support/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_SOL)
	R.freqlock = TRUE

	H.grant_language(/datum/language/modular_sand/solcommon, TRUE, TRUE)

	var/obj/item/card/id/sol/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label(W.registered_name)


///////////

/datum/outfit/ert/sol_soldier_demo
	name = "SolFed Demoman"

	id = /obj/item/card/id/sol
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/sol
//	head = /obj/item/clothing/head/helmet/alt
	uniform = /obj/item/clothing/under/rank/security/officer/solfed_military
	mask = /obj/item/clothing/mask/gas/syndicate/ds/coif
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/hecu/black
	belt = /obj/item/storage/belt/grenade/full
	r_hand = /obj/item/gun/ballistic/rocketlauncher/unrestricted
	ears = /obj/item/radio/headset/sol/bowman
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/grenade/plastic/c4=3,\
		/obj/item/ammo_casing/caseless/rocket=3)

/datum/outfit/ert/sol_soldier_demo/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_SOL)
	R.freqlock = TRUE

	H.grant_language(/datum/language/modular_sand/solcommon, TRUE, TRUE)

	var/obj/item/card/id/sol/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label(W.registered_name)


/datum/outfit/ert/sol_soldier_leader
	name = "SolFed Commander"

	id = /obj/item/card/id/sol
	suit = /obj/item/clothing/suit/armor/solfed_coat
	head = /obj/item/clothing/head/HoS/beret/sol
	uniform = /obj/item/clothing/under/rank/captain/sol
	mask = /obj/item/clothing/mask/gas/syndicate/ds/coif
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/hecu/black
	belt = /obj/item/storage/belt/military/inteq
	ears = /obj/item/radio/headset/sol/bowman/command
	l_pocket = /obj/item/melee/transforming/energy/sword/saber
	r_hand = /obj/item/gun/ballistic/automatic/shotgun/bulldog/unrestricted
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/storage/ifak=1,\
		/obj/item/gun/ballistic/automatic/pistol/deagle=1,\
        /obj/item/ammo_box/magazine/m50=2,\
		/obj/item/choice_beacon/sol_mech=1,\
		/obj/item/ammo_box/magazine/m12g/slug=4)

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/sol_soldier_leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/sol_soldier_leader/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_SOL)
	R.freqlock = TRUE

	H.grant_language(/datum/language/modular_sand/solcommon, TRUE, TRUE)

	var/obj/item/card/id/sol/W = H.wear_id
	W.registered_name = H.real_name
	W.update_label(W.registered_name)



///Агенты Внутренних Дел
/datum/outfit/ert/ntr_ert_leader
	name = "Internal Affairs Squad Leader"

	id = /obj/item/card/id/ert
	uniform = /obj/item/clothing/under/rank/civilian/lawyer/black/alt
	suit = /obj/item/clothing/suit/armor/vest/agent
	head = /obj/item/clothing/head/beret/sec/syndicate
	shoes = /obj/item/clothing/shoes/laceup
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	back = /obj/item/storage/backpack/ert_commander/ert_security
	belt = /obj/item/storage/belt/military/ert_min
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/storage/box/ert_commander=1,
		/obj/item/storage/firstaid/regular=1,)
	accessory = list(/obj/item/clothing/accessory/lawyers_badge)

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/ntr_ert_leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/ntr_ert_leader/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return
	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()

/datum/outfit/ert/ntr_ert_agent
	name = "Internal Affairs Squad Agent"

	id = /obj/item/card/id/ert/Security
	uniform = /obj/item/clothing/under/syndicate/sniper
	suit = /obj/item/clothing/suit/armor/vest/agent
	shoes = /obj/item/clothing/shoes/laceup
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	back = /obj/item/storage/backpack/ert_commander/ert_security
	belt = /obj/item/storage/belt/military/ert_min
	backpack_contents = list(/obj/item/storage/box/survival/centcom=1,\
		/obj/item/pda/heads=1,
		/obj/item/stamp/law=1,
		/obj/item/storage/firstaid/regular=1,)
	accessory = list(/obj/item/clothing/accessory/lawyers_badge)

/datum/outfit/ert/ntr_ert_agent/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/hos
	R.recalculateChannels()


///Горничные
/datum/outfit/ert/maid_leader
	name = "Tactical Maid Leader"

	id = /obj/item/card/id/ert
	uniform = /obj/item/clothing/under/syndicate/maid
	//suit = /obj/item/clothing/suit/armor/vest/agent
	gloves = /obj/item/clothing/gloves/combat/maid
	head = /obj/item/clothing/head/maid/syndicate
	shoes = /obj/item/clothing/shoes/sneakers/noslip
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/hecu/black
	belt = /obj/item/storage/belt/janitor/ert_maid
	mask = /obj/item/clothing/mask/gas/sechailer/syndicate
	r_hand = /obj/item/mop/advanced
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/storage/ifak=1)
	l_pocket = /obj/item/dualsaber

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/ert/maid_leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/ert/maid_leader/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return
	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()
	var/datum/martial_art/the_sleeping_carp/justablue = new
	justablue.teach(H)

/datum/outfit/ert/maid
	name = "Tactical Maid"

	id = /obj/item/card/id/ert
	uniform = /obj/item/clothing/under/syndicate/maid
	//suit = /obj/item/clothing/suit/armor/vest/agent
	gloves = /obj/item/clothing/gloves/combat/maid
	shoes = /obj/item/clothing/shoes/sneakers/noslip
	head = /obj/item/clothing/head/maid/syndicate
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	back = /obj/item/storage/backpack/hecu/black
	belt = /obj/item/storage/belt/janitor/ert_maid
	r_hand = /obj/item/mop/advanced
	mask = /obj/item/clothing/mask/gas/sechailer/syndicate
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
		/obj/item/storage/ifak=1)

/datum/outfit/ert/maid/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return
	var/obj/item/radio/R = H.ears
	R.keyslot = new /obj/item/encryptionkey/heads/captain
	R.recalculateChannels()
	var/datum/martial_art/cqc/justablue = new
	justablue.teach(H)
