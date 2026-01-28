/// Uniforms

/obj/item/clothing/under/rank/security/officer/formal/sol
	name = "solfed formal uniform"
	desc = "The latest in fashionable solar outfits."
	icon_state = "formal_solgov"
	item_state = "formal_solgov"
	alt_covers_chest = TRUE
	can_adjust = TRUE
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_digi.dmi'
	unique_reskin = list()

/obj/item/clothing/under/rank/security/officer/formal/sol/armorless
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0,  WOUND = 0)

/obj/item/clothing/under/rank/security/officer/solfed_military
	name = "solfed military uniform"
	desc = "Less tactical, but still cozy."
	icon_state = "solfed"
	item_state = "solfed"
	can_adjust = FALSE
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_digi.dmi'
	unique_reskin = list(
		"Military" = list("icon_state" = "solfed"),
	)

/obj/item/clothing/under/rank/captain/sol
	name = "solfed captain uniform"
	desc = "A very sleek Solar captains uniform for those who think they're commanding a battleship."
	icon_state = "solgov_captain"
	item_state = "solgov_captain"
	can_adjust = FALSE
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_digi.dmi'

/obj/item/clothing/under/sol_dress
	name = "solfed dress"
	desc = "A fancy dress."
	icon_state = "solgov_dress"
	item_state = "solgov_dress"
	body_parts_covered = CHEST|GROIN
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'

/// Suits

/obj/item/clothing/suit/armor/vest/warden/sol_robe
	name = "solfed robe"
	desc = "A blue robe with golden rank pips and armored fibers."
	icon_state = "solgov_robe"
	item_state = "solgov_robe"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'
	unique_reskin = list(
		"Robe" = list("icon_state" = "solgov_robe"),
		"Bureaucrat Robe" = list("icon_state" = "solgov_bureaucrat_robe")
	)

/obj/item/clothing/suit/armor/solfed_coat
	name = "SolFed Officer Coat"
	desc = "A greatcoat enhanced with a special alloy for some extra protection and style for those with a commanding presence."
	icon_state = "armor_solgov_trenchcoat"
	item_state = "armor_solgov_trenchcoat"
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	armor = list(MELEE = 55, BULLET = 65, LASER = 65, ENERGY = 65, BOMB = 40, BIO = 50, RAD = 100, FIRE = 40, ACID = 50,  WOUND = 40)

// Cloaks
/obj/item/clothing/neck/cloak/cape
	name = "solar federation cape"
	desc = "Worn by the servants of Sol."
	icon_state = "solgov_weibel"
	item_state = "solgov_weibel"
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'

/obj/item/clothing/neck/cloak/cloak
	name = "solar federation cloak"
	desc = "Property of the Solar fleet commanders and diplomacy personnel."
	icon_state = "solgov_cloak"
	item_state = "solgov_cloak"
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'

/// Hats and Headphones

/obj/item/clothing/head/HoS/beret/sol
	name = "solfed military beret"
	desc = "A robust beret for the combatants of Solar Federation."
	icon_state = "beret_solgov"
	item_state = "beret_solgov"
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol_head.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_head.dmi'

/obj/item/clothing/head/HoS/beret/sol/security
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)

/obj/item/clothing/head/HoS/beret/sol/plain
	name = "solfed beret"
	desc = "A blue beret for SolFed diplomacy personnel."
	icon_state = "beret_solgovplain"
	item_state = "beret_solgovplain"

/obj/item/clothing/head/HoS/beret/sol/plain/armorless
	desc = "A blue beret made in SolFed style."
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0,  WOUND = 0)

/obj/item/clothing/head/HoS/beret/sol/cap
	name = "solfed cap"
	desc = "A blue SolFed Cap with armored fibers."
	icon_state = "cap_solgov"
	item_state = "cap_solgov"

/obj/item/clothing/head/HoS/beret/sol/cap/armorless
	desc = "A blue SolFed Cap without any protection."
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0,  WOUND = 0)

/obj/item/radio/headset/sol
	name = "SolFed Headset"
	desc = "A bluish headset, used by SolFed personnel"
	icon_state = "solgov_headset"
	item_state = "solgov_headset"
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol_head.dmi'
	//mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_head.dmi'
	radiosound = 'modular_bluemoon/kovac_shitcode/sound/radio.ogg'
	freerange = FALSE
	freqlock = TRUE
	bowman = FALSE
	keyslot = new /obj/item/encryptionkey/headset_syndicate/sol
	keyslot2 = new /obj/item/encryptionkey/headset_com

/obj/item/radio/headset/sol/command
	name = "SolFed Command Headset"
	desc = "A commanding headset to gather your underlings."
	command = TRUE

/obj/item/radio/headset/sol/bowman
	name = "SolFed Bowman Headset"
	desc = "A bluish advanced headset, used by SolFed military. Protects your ears from flashbangs."
	icon_state = "solgov_headset_alt"
	item_state = "solgov_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/sol/bowman/command
	name = "SolFed Bowman Command Headset"
	desc = "A bluish advanced headset, used by SolFed military. Protects your ears from flashbangs. Helps your to command your men."
	command = TRUE

// SolFed Hardsuit
/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/sol
	name = "FCS SolFed hardsuit helmet"
	desc = "Just like the old times."
	icon_state = "hardsuit0-solfed"
	item_state = "hardsuit0-solfed"
	hardsuit_type = "solfed"
	armor = list(MELEE = 70, BULLET = 55, LASER = 50, ENERGY = 50, BOMB = 65, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 50)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	actions_types = list()
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol_head.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_head.dmi'

/obj/item/clothing/suit/space/hardsuit/ert/alert/sol
	name = "FCS SolFed hardsuit"
	desc = "The default Future Combat Systems Solar marine hardsuit. Provided with special fibers and armor plates."
	icon_state = "hardsuit0-solfed"
	item_state = "hardsuit0-solfed"
	hardsuit_type = "solfed"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/sol
	armor = list(MELEE = 70, BULLET = 55, LASER = 50, ENERGY = 50, BOMB = 65, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 50)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	//mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol.dmi'
	tail_state = "ce"
	anthro_mob_worn_overlay = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_digi.dmi'

/// Advanced hardsuit

/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/sol/adv
	name = "FCS-B SolFed hardsuit helmet"
	icon_state = "hardsuit0-solfeds"
	item_state = "hardsuit0-solfeds"
	hardsuit_type = "solfeds"
	tail_state = "ert-alert"
	armor = list(MELEE = 75, BULLET = 75, LASER = 75, ENERGY = 75, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 75)

/obj/item/clothing/suit/space/hardsuit/ert/alert/sol/adv
	name = "FCS-B SolFed hardsuit"
	desc = "A reinforced Future Combat Systems Solar marine hardsuit. Provided with special fibers and armor plates."
	icon_state = "hardsuit0-solfeds"
	item_state = "hardsuit0-solfeds"
	hardsuit_type = "solfeds"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/sol/adv
	armor = list(MELEE = 75, BULLET = 75, LASER = 75, ENERGY = 75, BOMB = 100, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 75)

/// Outfits (ERT military suits were stored in ert.dm)

/datum/outfit/sol_diplomacy
	name = "SolFed Diplomacy Worker"

	id = /obj/item/card/id/sol
	//belt =
	//glasses = /obj/item/clothing/glasses/sunglasses
	ears = /obj/item/radio/headset/sol
	//gloves =
	uniform =  /obj/item/clothing/under/rank/security/officer/formal/sol
	//suit =
	back =	/obj/item/storage/backpack/satchel
	shoes = /obj/item/clothing/shoes/laceup
	head = /obj/item/clothing/head/HoS/beret/sol/cap
	r_hand = /obj/item/storage/briefcase/lawyer
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/poster/sol=5)

	implants = list(/obj/item/implant/anchor)

/datum/outfit/sol_diplomacy/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_SOL)
	R.freqlock = TRUE

	H.grant_language(/datum/language/modular_sand/solcommon, TRUE, TRUE)

	var/obj/item/card/id/W = H.wear_id
	W.registered_name = H.real_name
	W.access = get_all_inteq_access()
	W.update_label()

/datum/outfit/sol_diplomacy/slut
	name = "SolFed Secretary?"
	uniform = /obj/item/clothing/under/rank/security/officer/formal/sol
	suit = /obj/item/clothing/under/sol_dress

/datum/outfit/sol_diplomacy/secret_service
	name = "SolFed Secret Service"
	uniform = /obj/item/clothing/under/rank/security/officer/solfed_military
	suit = /obj/item/clothing/suit/armor/vest/agent

	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/gun/energy/disabler=1)

/datum/outfit/sol_diplomacy/consul
	name = "SolFed Consul"

	//glasses = /obj/item/clothing/glasses/hud/security/sunglasses/inteq
	ears = /obj/item/radio/headset/sol/command
	gloves = /obj/item/clothing/gloves/color/black
	//suit =
	neck = /obj/item/clothing/neck/cloak/cape
	head = /obj/item/clothing/head/HoS/beret/sol/plain
	r_hand = /obj/item/gun/ballistic/automatic/pistol/g22
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/poster/sol=5, /obj/item/ammo_box/magazine/m10mm_large/soporific=2)

	implants = list(/obj/item/implant/mindshield)

/datum/outfit/sol_diplomacy/consul/admiral
	name = "SolFed Fleet Admiral"

	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	head = /obj/item/clothing/head/HoS/beret/sol
	belt = /obj/item/storage/belt/sabre
	ears = /obj/item/radio/headset/sol/bowman/command
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	suit = /obj/item/clothing/suit/armor/vest/warden/sol_robe
	neck = /obj/item/clothing/neck/cloak/cloak
	r_hand = /obj/item/gun/energy/laser/captain
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/gun/energy/disabler=1)
