/obj/item/radio/headset/headset_cent/commander/alt/generic
	name = "\improper bowman headset"
	desc = "A headset for emergency response personnel. Protects ears from flashbangs."
	icon_state = "cent_headset_alt"
	item_state = "cent_headset_alt"
	bowman = TRUE

/obj/item/gun/energy/taser/debug
	ammo_type = list(/obj/item/ammo_casing/energy/electrode/debug)

/obj/item/ammo_casing/energy/electrode/debug
	e_cost = 1

/obj/item/clothing/suit/armor/vest/darkcarapace/debug
	name = "Bluespace Tech"
	desc = "A sleek piece of armour designed for Bluespace agents."
	icon = 'icons/obj/custom.dmi'
	mob_overlay_icon = 'icons/mob/clothing/custom_w.dmi'
	icon_state = "darkcarapace"
	item_state = "darkcarapace"
	blood_overlay_type = "armor"
	armor = list("melee" = 95, "bullet" = 95, "laser" = 95, "energy" = 95, "bomb" = 95, "bio" = 95, "rad" = 100, "fire" = 98, "acid" = 98)

/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/debug
	name = "Bluespace Tech Helmet"
	desc = "A specialised helmet for Bluespace agents."
	armor = list("melee" = 99, "bullet" = 99, "laser" = 99, "energy" = 99, "bomb" = 99, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100)

/obj/item/clothing/suit/space/hardsuit/ert/alert/debug
	name = "Bluespace Tech Hardsuit"
	desc = "A specialised hardsuit for Bluespace agents."
	armor = list("melee" = 99, "bullet" = 99, "laser" = 99, "energy" = 99, "bomb" = 99, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/debug

/obj/item/storage/backpack/holding/duffel/debug
	name = "Special Duffel Bag of Holding"
	desc = "A special duffel bag that opens into a localized pocket of Blue Space."
	icon_state = "holdingduffel"
	item_state = "holdingduffel"

/obj/item/storage/backpack/holding/duffel/debug/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = MAX_WEIGHT_CLASS_BAG_OF_HOLDING
	STR.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT
	STR.max_volume = STORAGE_VOLUME_BAG_OF_HOLDING_DEBUG

/obj/item/clothing/shoes/combat/debug
	clothing_flags = NOSLIP

/obj/item/storage/belt/military/abductor/full/debug
	name = "\improper Bluespace Tech's belt"

/obj/item/storage/belt/military/abductor/full/debug/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = MAX_WEIGHT_CLASS_BAG_OF_HOLDING
	STR.storage_flags = STORAGE_FLAGS_LEGACY_DEFAULT
	STR.max_volume = STORAGE_VOLUME_BAG_OF_HOLDING_DEBUG
	STR.max_combined_w_class = 25
	STR.max_items = 12

/obj/item/storage/belt/military/abductor/full/debug/PopulateContents()
	new /obj/item/screwdriver/abductor(src)
	new /obj/item/wrench/abductor(src)
	new /obj/item/weldingtool/abductor(src)
	new /obj/item/crowbar/abductor(src)
	new /obj/item/wirecutters/abductor(src)
	new /obj/item/multitool/abductor(src)
	new /obj/item/stack/cable_coil(src, 30, TRUE, "white")
	new /obj/item/lightreplacer/blue(src)
	new /obj/item/analyzer/ranged(src)
	new /obj/item/extinguisher/advanced(src)
	new /obj/item/holosign_creator/combifan(src)
	new /obj/item/pipe_dispenser/bluespace(src)

/datum/outfit/debug/bst //Debug objs
	name = "!Bluespace Tech"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/armor/vest/darkcarapace/debug
	glasses = null
	ears = /obj/item/radio/headset/headset_cent/commander/alt/generic
	mask = null
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	belt = /obj/item/storage/belt/military/abductor/full/debug
	shoes = /obj/item/clothing/shoes/combat/debug
	id = /obj/item/card/id/debug/bst
	back = /obj/item/storage/backpack/holding/duffel/debug
	box = /obj/item/storage/box/debugtools
	suit_store = /obj/item/gun/energy/pulse
	backpack_contents = list(
		/obj/item/melee/transforming/energy/axe=1,\
		/obj/item/storage/part_replacer/bluespace/tier5=1,\
		/obj/item/debug/human_spawner=1,\
		/obj/item/gun/energy/taser/debug=1,\
		/obj/item/clothing/glasses/debug,\
		/obj/item/clothing/mask/gas/welding/up,\
		/obj/item/tank/internals/oxygen,\
		)
	implants = list(/obj/item/implant/mindshield, /obj/item/implant/deathrattle/centcom, /obj/item/implant/weapons_auth, /obj/item/implant/radio/centcom)

/datum/outfit/debug/bsthardsuit //Debug objs plus hardsuit
	name = "!Bluespace Tech (Hardsuit)"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/debug
	glasses = /obj/item/clothing/glasses/debug
	ears = /obj/item/radio/headset/headset_cent/commander/alt/generic
	mask = /obj/item/clothing/mask/gas/welding/up
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	belt = /obj/item/storage/belt/military/abductor/full/debug
	shoes = /obj/item/clothing/shoes/magboots/advance/debug
	id = /obj/item/card/id/debug/bst
	back = /obj/item/storage/backpack/holding/duffel/debug
	box = /obj/item/storage/box/debugtools
	suit_store = /obj/item/tank/internals/oxygen
	internals_slot = ITEM_SLOT_SUITSTORE
	backpack_contents = list(
		/obj/item/melee/transforming/energy/axe=1,\
		/obj/item/storage/part_replacer/bluespace/tier5=1,\
		/obj/item/debug/human_spawner=1,\
		/obj/item/gun/energy/pulse=1,\
		/obj/item/storage/lockbox/anti_singulo=1,\
		/obj/item/gun/energy/taser/debug,\
		)
	implants = list(/obj/item/implant/mindshield, /obj/item/implant/deathrattle/centcom, /obj/item/implant/weapons_auth, /obj/item/implant/radio/centcom)

/datum/outfit/chrono_agent
	name = "Timeline Eradication Agent"
	uniform = /obj/item/clothing/under/rank/rnd/scientist
	suit = /obj/item/clothing/suit/space/chronos
	back = /obj/item/chrono_eraser
	head = /obj/item/clothing/head/helmet/space/chronos
	mask = /obj/item/clothing/mask/breath
	belt = /obj/item/storage/belt/military/abductor/full
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	glasses = /obj/item/clothing/glasses/night
	shoes = /obj/item/clothing/shoes/combat
	id = /obj/item/card/id
	suit_store = /obj/item/tank/internals/oxygen
	ears = /obj/item/radio/headset/headset_cent/alt

/datum/outfit/chrono_agent/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	var/obj/item/card/id/W = H.wear_id
	W.icon_state = "centcom"
	W.access = get_all_accesses()//They get full station access.
	W.access += get_centcom_access("TED Agent")//Let's add their alloted CentCom access.
	W.assignment = "Timeline Eradication Agent"
	W.registered_name = H.real_name
	W.update_label()
