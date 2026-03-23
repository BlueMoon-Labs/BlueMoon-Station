/// Uniforms

/obj/item/clothing/under/rank/security/officer/nri_military
	name = "nri military uniform"
	desc = "keep calm and wait for russians."
	icon_state = "nri_soldier"
	item_state = "nri_soldier"
	can_adjust = FALSE
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus_digi.dmi'
	alternate_screams = RUSSIAN_SCREAMS
	unique_reskin = list(
		"Spetsnaz" = list("icon_state" = "nri_soldier"),
		"PMC" = list("icon_state" = "nri_engineer")
	)

/// Suits

/obj/item/clothing/suit/armor/nri_coat
	name = "NRI Official Coat"
	desc = "A greatcoat with armored fibers included to protect Empire officials."
	icon_state = "nri_coat"
	item_state = "nri_coat"
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	alternate_screams = RUSSIAN_SCREAMS
	armor = list(MELEE = 55, BULLET = 65, LASER = 65, ENERGY = 65, BOMB = 40, BIO = 50, RAD = 100, FIRE = 40, ACID = 50,  WOUND = 40)

/obj/item/clothing/suit/armor/nri_vest
	name = "NRI Officer Vest"
	desc = "Very well. Now, shoot me if you can, pidor."
	icon_state = "warden_jacket_newtg"
	item_state = "warden_jacket_newtg"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	armor = list(MELEE = 55, BULLET = 65, LASER = 65, ENERGY = 65, BOMB = 40, BIO = 50, RAD = 100, FIRE = 40, ACID = 50,  WOUND = 40)

/obj/item/clothing/suit/armor/nri_coat/armorless
	desc = "A greatcoat without armored fibers for cosplay purposes."
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0,  WOUND = 0)

// Cloaks
/obj/item/clothing/neck/cloak/nri_cape
	name = "new russian empire cape"
	desc = "Worn by the servants of NRI."
	icon_state = "nri_cape"
	item_state = "nri_cape"
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'

/obj/item/clothing/neck/cloak/nri_cloak
	name = "new russian empire cloak"
	desc = "Belongs to the Russian diplomacy personnel and commanders."
	icon_state = "nri_cloak"
	item_state = "nri_cloak"
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'

/// Hats and Headphones

/obj/item/clothing/head/HoS/beret/nri
	name = "nri military beret"
	desc = "A robust beret for the combatants of New Russian Empire."
	icon_state = "rus_beret"
	item_state = "rus_beret"
	alternate_screams = RUSSIAN_SCREAMS
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'

/obj/item/clothing/head/HoS/beret/nri/security
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)

/obj/item/clothing/head/HoS/beret/nri/cap
	name = "nri cap"
	desc = "A NRI Cap with armored fibers."
	icon_state = "admiral_cap"
	item_state = "admiral_cap"

/obj/item/clothing/head/HoS/beret/nri/cap/armorless
	desc = "A NRI Cap without any protection."
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0,  WOUND = 0)

/obj/item/radio/headset/nri
	name = "NRI Headset"
	desc = "A green headset, used by NRI personnel"
	icon_state = "rus_headset"
	item_state = "rus_headset"
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'
	radiosound = 'modular_bluemoon/kovac_shitcode/sound/radio_rus.ogg'
	freerange = FALSE
	freqlock = TRUE
	bowman = FALSE
	keyslot = new /obj/item/encryptionkey/headset_syndicate/nri
	keyslot2 = new /obj/item/encryptionkey/headset_com

/obj/item/radio/headset/nri/command
	name = "NRI Command Headset"
	desc = "A commanding headset to shut up loudly."
	command = TRUE

/obj/item/radio/headset/nri/bowman
	name = "NRI Bowman Headset"
	desc = "A green advanced headset, used by NRI Military. Protects your ears from flashbangs."
	icon_state = "rus_headset_alt"
	item_state = "rus_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/nri/bowman/command
	name = "NRI Bowman Command Headset"
	desc = "A green advanced headset, used by NRI military. Protects your ears from flashbangs. Helps your to command your men."
	command = TRUE


// NRI Hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/nri
	name = "Ratnik-4 hardsuit helmet"
	desc = "Stay with me, cyka!"
	icon_state = "hardsuit0-russian"
	item_state = "hardsuit0-russian"
	hardsuit_type = "russiansuit"
	armor = list(MELEE = 70, BULLET = 55, LASER = 50, ENERGY = 50, BOMB = 65, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 50)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	actions_types = list()
	//mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/space/hardsuit/ert/alert/nri
	name = "Ratnik-4 hardsuit"
	desc = "Reinforced greenish hardsuit, designated for NRI special forces."
	icon_state = "russiansuit"
	item_state = "russiansuit"
	alternate_screams = RUSSIAN_SCREAMS
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/nri
	armor = list(MELEE = 70, BULLET = 55, LASER = 50, ENERGY = 50, BOMB = 65, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 50)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT

//// NRI Hardsuit - Advanced - with healing (vox-like) feature
/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/nri/adv
	name = "Ratnik-4M hardsuit helmet"
	icon_state = "hardsuit0-russians"
	item_state = "hardsuit0-russians"
	hardsuit_type = "russiansuits"
	armor = list(MELEE = 70, BULLET = 65, LASER = 60, ENERGY = 60, BOMB = 80, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 60)

/obj/item/clothing/suit/space/hardsuit/ert/alert/nri/adv
	name = "Ratnik-4M 'Voskhod' hardsuit"
	icon_state = "russiansuits"
	item_state = "russiansuits"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/nri/adv
	armor = list(MELEE = 70, BULLET = 65, LASER = 60, ENERGY = 60, BOMB = 80, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 60)
	var/mob/living/carbon/human/wearer

/obj/item/clothing/suit/space/hardsuit/ert/alert/nri/adv/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		wearer = user
		START_PROCESSING(SSobj, src)
		playsound(get_turf(src), 'sound/rig/shortbeep.ogg', 100, 1, 1)
		to_chat(wearer, "<span class='warning'>Медицинский интерфейс костюма загружен. Убедитесь, что шлем костюма экипирован.</span>")

/obj/item/clothing/suit/space/hardsuit/ert/alert/nri/adv/dropped(mob/user)
	wearer = null
	STOP_PROCESSING(SSobj, src)
	..()

/obj/item/clothing/suit/space/hardsuit/ert/alert/nri/adv/Destroy()
	STOP_PROCESSING(SSobj, src)
	wearer = null
	return ..()

/obj/item/clothing/suit/space/hardsuit/ert/alert/nri/adv/process(damage)
	if(!wearer)
		STOP_PROCESSING(SSobj, src)
		return
	if(wearer.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(!istype(wearer.head, /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/nri/adv))
		return
	if(damage > 9)
		wearer.adjustToxLoss(0.7) // this will kill the wearer after a while if the suit is not repaired or removed
	else if(wearer.reagents.get_reagent_amount(/datum/reagent/medicine/tricordrazine) > 5)
		return // safe tricordrazine injection
	if(damage > 19)
		wearer.adjustToxLoss(1) // this will kill the wearer much faster
	wearer.reagents.add_reagent(/datum/reagent/medicine/tricordrazine, REAGENTS_METABOLISM)

// green webbing
/obj/item/storage/belt/military/russianweb
	desc = "A set of tactical webbing worn by NRI Spetsnaz troopers."
	icon_state = "russianweb"
	item_state = "russianweb"

////////////////////////////////////////////////////////////////////

/// Outfits (ERT military suits were stored in ert.dm)

/datum/outfit/nri_diplomacy // WIP
	name = "NRI Diplomacy Worker"

	id = /obj/item/card/id/nri
	//belt =
	//glasses = /obj/item/clothing/glasses/sunglasses
	ears = /obj/item/radio/headset/nri
	//gloves =
	uniform =  /obj/item/clothing/under/rank/security/officer/nri_military
	suit = /obj/item/clothing/suit/armor/nri_coat
	back =	/obj/item/storage/backpack/satchel
	shoes = /obj/item/clothing/shoes/jackboots
	//head =
	r_hand = /obj/item/storage/briefcase/lawyer
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/poster/nri=5)

	//implants = list(/obj/item/implant/mindshield)

/datum/outfit/nri_diplomacy/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_NRI)
	R.freqlock = TRUE

	H.grant_language(/datum/language/modular_sand/technorussian, TRUE, TRUE)

/datum/outfit/nri_diplomacy/consul
	name = "NRI Consul"

	//glasses = /obj/item/clothing/glasses/hud/security/sunglasses/inteq
	ears = /obj/item/radio/headset/nri/command
	gloves = /obj/item/clothing/gloves/color/black
	//suit =
	neck = /obj/item/clothing/neck/cloak/nri_cape
	head = /obj/item/clothing/head/HoS/beret/nri/cap/armorless
	//r_hand = /obj/item/gun/ballistic/automatic/pistol/g22
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/poster/nri=5)

	implants = list(/obj/item/implant/mindshield)

/datum/outfit/nri_diplomacy/consul/admiral
	name = "NRI Fleet Admiral"

	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	head = /obj/item/clothing/head/HoS/beret/nri/cap
	belt = /obj/item/storage/belt/sabre/rapier
	ears = /obj/item/radio/headset/nri/bowman/command
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	neck = /obj/item/clothing/neck/cloak/nri_cloak
	r_hand = /obj/item/gun/ballistic/shotgun/automatic/rsh12
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/poster/nri=5, /obj/item/ammo_box/shotgun/loaded/buckshot=4)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////area

//NRI Antagonist clothes and stuff

/obj/item/clothing/under/syndicate/nri_drg
	name = "covert ops tactical uniform"
	desc = "A non-descript and slightly suspicious looking uniform."
	icon_state = "nri_drg"
	item_state = "nri_drg"
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_drg.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_drg.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_drg_digi.dmi'
	can_adjust = FALSE
	unique_reskin = list(
		"Camo" = list("icon_state" = "nri_drg"),
		"Turtleneck" = list("icon_state" = "nri_drg_alt")
	)
