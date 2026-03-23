/datum/outfit/ninja_pre
	name = "Space Ninja"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/space/space_ninja/pre
	mask = /obj/item/clothing/mask/gas/space_ninja
	head = /obj/item/clothing/head/helmet/space/space_ninja
	shoes = /obj/item/clothing/shoes/space_ninja
	gloves = /obj/item/clothing/gloves/space_ninja
	suit_store = /obj/item/tank/internals/oxygen
	internals_slot = ITEM_SLOT_SUITSTORE

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

	cybernetic_implants = list(/obj/item/organ/cyberimp/chest/nutrimentextreme)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/datum/outfit/ninja
	name = "Space Ninja - Spider"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/space/space_ninja
	glasses = /obj/item/clothing/glasses/night/syndicate
	mask = /obj/item/clothing/mask/gas/space_ninja
	head = /obj/item/clothing/head/helmet/space/space_ninja
	ears = /obj/item/radio/headset
	shoes = /obj/item/clothing/shoes/space_ninja
	gloves = /obj/item/clothing/gloves/space_ninja
	l_pocket = /obj/item/grenade/plastic/c4/ninja
	r_pocket = /obj/item/hypospray/mkii/CMO/combat
	suit_store = /obj/item/tank/internals/oxygen
	internals_slot = ITEM_SLOT_SUITSTORE
	belt = /obj/item/energy_katana
	back = /obj/item/storage/backpack/hipbag
	implants = list(/obj/item/implant/explosive)
	backpack_contents = list(/obj/item/reagent_containers/glass/bottle/vial/large/combat=1)


/datum/outfit/ninja/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(istype(H.wear_suit, suit))
		var/obj/item/clothing/suit/space/space_ninja/S = H.wear_suit
		if(istype(H.belt, belt))
			S.energyKatana = H.belt
	H.grant_language(/datum/language/neokanji)
	var/datum/language_holder/LH = H.get_language_holder()
	LH.selected_language = /datum/language/neokanji


///////////////////////////////////////////area
/datum/outfit/ninja_ronin
	name = "Space Ninja - Ronin"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/space/space_ninja/ronin
	glasses = /obj/item/clothing/glasses/night/syndicate/red
	mask = /obj/item/clothing/mask/gas/space_ninja
	head = /obj/item/clothing/head/helmet/space/space_ninja
	ears = /obj/item/radio/headset
	shoes = /obj/item/clothing/shoes/space_ninja
	gloves = /obj/item/clothing/gloves/space_ninja
	l_pocket = /obj/item/grenade/plastic/c4/ninja
	r_pocket = /obj/item/hypospray/mkii/CMO/combat
	suit_store = /obj/item/tank/internals/oxygen
	internals_slot = ITEM_SLOT_SUITSTORE
	belt = /obj/item/energy_naginata
	back = /obj/item/storage/backpack/hipbag
	implants = list(/obj/item/implant/explosive)
	backpack_contents = list(/obj/item/reagent_containers/glass/bottle/vial/large/combat=2)


/datum/outfit/ninja_ronin/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(istype(H.wear_suit, suit))
		var/obj/item/clothing/suit/space/space_ninja/ronin/S = H.wear_suit
		if(istype(H.belt, belt))
			S.energyNaginata = H.belt
	H.grant_language(/datum/language/neokanji)
	var/datum/language_holder/LH = H.get_language_holder()
	LH.selected_language = /datum/language/neokanji


///////////////////////////////////////////////////////

///////////////////////////////////////////area
/datum/outfit/ninja_wisdom
	name = "Space Ninja - Wisdom"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/space/space_ninja/wisdom
	glasses = /obj/item/clothing/glasses/hud/health/night/syndicate
	mask = /obj/item/clothing/mask/gas/space_ninja
	head = /obj/item/clothing/head/helmet/space/space_ninja
	neck = /obj/item/clothing/neck/cloak/ninjascarf_new
	ears = /obj/item/radio/headset
	shoes = /obj/item/clothing/shoes/space_ninja
	gloves = /obj/item/clothing/gloves/space_ninja
	l_pocket = /obj/item/grenade/plastic/c4/ninja
	r_pocket = /obj/item/hypospray/mkii/CMO/combat
	suit_store = /obj/item/tank/internals/oxygen
	internals_slot = ITEM_SLOT_SUITSTORE
	//belt =
	back = /obj/item/storage/backpack/hipbag
	implants = list(/obj/item/implant/explosive)
	backpack_contents = list(/obj/item/tank/jetpack/oxygen/harness=1) // У этого подтипа ниндзя нет рывков, а добраться до станции как-то надо, да и по космосу немного полетать сможет.

/datum/outfit/ninja_wisdom/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.grant_language(/datum/language/neokanji)
	var/datum/language_holder/LH = H.get_language_holder()
	LH.selected_language = /datum/language/neokanji

	var/datum/martial_art/the_sleeping_carp/B = new
	B.teach(H)

///////////////////////////////////////////////////////
