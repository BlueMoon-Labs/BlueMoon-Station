/datum/mod_theme/asset_protection
	parent_type = /datum/mod_theme/centcom
	name = "Asset Protection"
	desc = "Облегчённая версия Apocryphal для подразделения защиты активов Nanotrasen."
	extended_desc = "Костюм подразделения защиты активов Nanotrasen сочетает броню, термостойкий корпус и усовершенствованные приводы. Он уступает Apocryphal в защите, но позволяет телохранителю свободно двигаться и пользоваться специализированными модулями."
	default_skin = "asset_protection"
	armor_type = /datum/armor/modsuit_asset_protection
	brc_mitigation_bonus = 20
	complexity_max = DEFAULT_MAX_COMPLEXITY
	skins = list(
		"asset_protection" = list(
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEEARS|HIDEHAIR,
				SEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEMASK|HIDEEYES|HIDEFACE|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
	)

/datum/mod_theme/asset_protection/apply_theme_stats(obj/item/mod/control/modsuit, new_skin)
	. = ..()
	for(var/obj/item/piece in modsuit.get_mod_parts(include_cell = FALSE, include_mod = TRUE))
		piece.flags_1 |= PREVENT_CONTENTS_EXPLOSION_1

/datum/armor/modsuit_asset_protection
	melee = 50
	bullet = 40
	laser = 50
	energy = 50
	bomb = 50
	bio = 100
	fire = 100
	acid = 100
	wound = 15

/obj/item/mod/control/pre_equipped/asset_protection
	theme = /datum/mod_theme/asset_protection
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage/bluespace,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/emp_shield/advanced,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/jetpack,
		/obj/item/mod/module/projectile_dampener,
		/obj/item/mod/module/status_readout,
	)

/obj/item/mod/control/pre_equipped/asset_protection/set_wearer(mob/user)
	. = ..()
	for(var/obj/item/mod/module/jetpack/jetpack in modules)
		generate_ability_button(jetpack, user)

/datum/outfit/asset_protection
	name = "Asset Protection Specialist"
	uniform = /obj/item/clothing/under/syndicate/sniper
	back = /obj/item/mod/control/pre_equipped/asset_protection
	shoes = /obj/item/clothing/shoes/combat/swat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	mask = /obj/item/clothing/mask/gas/sechailer/swat
	glasses = /obj/item/clothing/glasses/hud/toggle/thermal
	l_pocket = /obj/item/melee/classic_baton/telescopic/contractor_baton
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double
	belt = /obj/item/storage/belt/military/ert_max
	l_hand = /obj/item/gun/energy/pulse/carbine/loyalpin
	id = /obj/item/card/id/ert
	ears = /obj/item/radio/headset/headset_cent/alt
	internals_slot = ITEM_SLOT_RPOCKET
	give_space_cooler_if_synth = TRUE
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom = 1,
		/obj/item/storage/firstaid/tactical = 1,
		/obj/item/melee/baton/loaded = 1,
	)
	implants = list(/obj/item/implant/mindshield, /obj/item/implant/deathrattle/centcom)
	cybernetic_implants = list(
		/obj/item/organ/cyberimp/eyes/hud/security,
		/obj/item/organ/cyberimp/chest/nutriment/plus,
	)

/datum/outfit/asset_protection/post_equip(mob/living/carbon/human/member, visualsOnly = FALSE, client/preference_source)
	. = ..()
	if(visualsOnly)
		return
	var/obj/item/radio/headset/radio = member.ears
	radio.set_frequency(FREQ_CENTCOM)
	radio.freqlock = TRUE
	var/obj/item/card/id/card = member.wear_id
	card.assignment = "Asset Protection"
	card.registered_name = member.real_name
	card.update_label()

/datum/outfit/asset_protection/leader
	name = "Asset Protection Officer"
	head = /obj/item/clothing/head/helmet/space/beret
