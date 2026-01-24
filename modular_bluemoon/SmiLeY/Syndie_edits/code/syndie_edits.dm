//DS-2/Syndicate clothing.

/obj/item/clothing/suit/toggle/captains_parade/syndicate
	name = "syndicate captain's vest"
	desc = "A sinister looking vest of advanced armor worn over a black and red fireproof jacket. The gold collar and shoulders denote that this belongs to a high ranking syndicate officer."
	icon = 'modular_bluemoon/smiley/syndie_edits/icons/obj.dmi'
	mob_overlay_icon = 'modular_bluemoon/smiley/syndie_edits/icons/worn.dmi'
	icon_state = "syndievest"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/toggle/captains_parade/syndicate/winter
	name = "syndicate captain's winter vest"
	desc = "A sinister yet comfortable looking vest of advanced armor worn over a black and red fireproof jacket. The fur is said to be from wolves on the icemoon."
	icon = 'modular_bluemoon/smiley/syndie_edits/icons/obj.dmi'
	mob_overlay_icon = 'modular_bluemoon/smiley/syndie_edits/icons/worn.dmi'
	icon_state = "syndievest_winter"
	body_parts_covered = CHEST|ARMS
	cold_protection = CHEST|GROIN|ARMS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	resistance_flags = FIRE_PROOF

/obj/item/clothing/head/hats/warden/syndicate
	name = "Master At Arms' Police Hat"
	desc = "A fashionable police cap emblazoned with a golden badge, issued to the Master at Arms. Protects the head from impacts."
	icon = 'icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'icons/mob/clothing/head.dmi'
	icon_state = "policehelm_syndie"
	dog_fashion = null

/obj/item/clothing/head/helmet/swat/ds
	name = "SWAT helmet"
	desc = "A robust and spaceworthy helmet with a small cross on it along with 'IP' written across the earpad."
	icon = 'icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'icons/mob/clothing/head.dmi'
	icon_state = "swat_ds"

/obj/item/clothing/head/beret/sec/syndicate
	name = "brig officer's beret"
	desc = "A stylish and protective beret, produced and manufactured by Interdyne Pharmaceuticals with help from the Gorlex Marauders."
	icon_state = "beret_badge"

/obj/item/clothing/mask/gas/syndicate/ds
	name = "balaclava"
	desc = "A fancy balaclava, while it doesn't muffle your voice, it's fireproof and has a miniature rebreather for internals. Comfy to boot!"
	icon = 'icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'icons/mob/clothing/mask.dmi'
	icon_state = "balaclava_ds"
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS|HIDEFACIALHAIR

/obj/item/clothing/mask/gas/sechailer/syndicate
	name = "Neck Gaiter"
	desc = "For the agent wanting to keep a low profile whilst concealing their identity. Has a small respirator to be used with internals."
	actions_types = list(/datum/action/item_action/adjust)
	icon_state = "half_mask"
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	icon = 'icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'icons/mob/clothing/mask.dmi'

/obj/item/clothing/shoes/combat
	icon = 'icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'icons/mob/clothing/feet.dmi'
	icon_state = "combat"

/obj/item/clothing/gloves/combat
	icon = 'icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'icons/mob/clothing/hands.dmi'
	icon_state = "combat"

/obj/item/clothing/gloves/combat/wizard
	icon = 'icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = null

/obj/item/clothing/gloves/tackler/combat/insulated
	icon = 'icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'icons/mob/clothing/hands.dmi'
	icon_state = "combat"

/obj/item/clothing/gloves/krav_maga/combatglovesplus
	icon = 'icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'icons/mob/clothing/hands.dmi'
	icon_state = "combat"

/obj/item/clothing/gloves/krav_maga/combatglovesplus/maa
	name = "master at arms' combat gloves"
	desc = "A set of combat gloves plus emblazoned with red knuckles, showing dedication to the trade while also hiding any blood left after use."
	icon_state = "maagloves"

/obj/item/storage/belt/security/webbing/ds
	name = "brig officer webbing"
	icon = 'icons/obj/clothing/belts.dmi'
	mob_overlay_icon = 'icons/mob/clothing/belt.dmi'
	icon_state = "webbingds"
	item_state = "webbingds"
	custom_premium_price = 450 // потому что это улучшенная версия пояса которая вмещает всё что нужно

/obj/item/storage/belt/security/webbing/ds/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 7
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.can_hold = typecacheof(list(
		/obj/item/melee/baton,
		/obj/item/melee/classic_baton,
		/obj/item/grenade,
		/obj/item/reagent_containers/spray/pepper,
		/obj/item/restraints/handcuffs,
		/obj/item/assembly/flash/handheld,
		/obj/item/clothing/glasses,
		/obj/item/ammo_casing/shotgun,
		/obj/item/ammo_box,
		/obj/item/reagent_containers/food/snacks/donut,
		/obj/item/kitchen/knife/combat,
		/obj/item/flashlight/seclite,
		/obj/item/melee/classic_baton/telescopic,
		/obj/item/radio,
		/obj/item/clothing/gloves,
		/obj/item/restraints/legcuffs/bola,
		/obj/item/holosign_creator/security
		))

/obj/item/clothing/suit/armor/bulletproof/old
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "bulletproof-wm"

/obj/item/clothing/under/syndicate/overalls
	name = "Utility Overalls Turtleneck"
	desc = "A pair of spiffy overalls with a turtleneck underneath, useful for both engineering and botanical work."
	icon_state = "syndicate_overalls"
	can_adjust = TRUE

/obj/item/clothing/under/syndicate/overalls/skirt
	name = "Utility Overalls Skirtleneck"
	desc = "A pair of spiffy overalls with a turtleneck underneath, this one is a skirt instead, breezy."
	icon_state = "syndicate_overallskirt"
	dying_key = DYE_REGISTRY_JUMPSKIRT
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP

/obj/item/clothing/head/maid/syndicate
	name = "Tactical Maid Headband"
	desc = "Tacticute."
	icon_state = "syndimaid_headband"
	icon = 'icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'icons/mob/clothing/head.dmi'

/obj/item/clothing/gloves/combat/maid
	name = "Combat Maid Sleeves"
	desc = "These 'tactical' gloves and sleeves are fireproof and electrically insulated. Warm to boot."
	icon_state = "syndimaid_arms"

/obj/item/clothing/under/syndicate/maid
	name = "Tactical Maid Outfit"
	desc = "A 'tactical' skirtleneck fashioned to the likeness of a maid outfit. Why the Syndicate has these, you'll never know."
	icon_state = "syndimaid"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	dying_key = DYE_REGISTRY_JUMPSKIRT
	can_adjust = FALSE

/obj/item/clothing/under/syndicate/maid/Initialize(mapload)
	. = ..()
	var/obj/item/clothing/accessory/maidcorset/syndicate/A = new (src)
	attach_accessory(A)

/obj/item/clothing/under/syndicate/maid_revealing
	name = "Revealing Tactical Maid Outfit"
	desc = "A 'tactical' skirtleneck fashioned to the likeness of a maid outfit. Why the Syndicate has these, you'll never know."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/object/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/uniform.dmi'
	icon_state = "maid_revealing"
	item_state = "maid_revealing"
	fitted = NO_FEMALE_UNIFORM
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	dying_key = DYE_REGISTRY_JUMPSKIRT
	can_adjust = FALSE

/obj/item/clothing/accessory/maidcorset/syndicate
	name = "Syndicate Maid Apron"
	desc = "Practical? No. Tactical? Also no. Cute? Most definitely yes."
	icon = 'icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'icons/mob/clothing/accessories.dmi'
	icon_state = "syndimaid_corset"

/obj/item/clothing/head/soft/sec/syndicate
	name = "engine tech utility cover"
	desc = "A utility cover for an engine technician, there's a tag that reads 'IP-DS-2'."
	icon = 'icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'icons/mob/clothing/head.dmi'
	icon_state = "dssoft"
	soft_type = "ds"

/obj/item/clothing/suit/hooded/wintercoat/syndicate
	name = "syndicate winter coat"
	desc = "A sinister black coat with red accents and a fancy mantle, it feels like it can take a hit. The zipper tab looks like a triple headed snake in the shape of an S, spooky."
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "coatsyndie"
	item_state = "coatwinter"
	armor = list(MELEE = 25, BULLET = 15, LASER = 30, ENERGY = 40, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 45, WOUND = 10)
	hoodtype = /obj/item/clothing/head/hooded/winterhood/syndicate

/obj/item/clothing/suit/hooded/wintercoat/syndicate/Initialize(mapload)
	. = ..()
	allowed += GLOB.security_wintercoat_allowed

/obj/item/clothing/head/hooded/winterhood/syndicate
	desc = "A sinister black hood with armor padding."
	icon = 'icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'icons/mob/clothing/head.dmi'
	icon_state = "hood_syndie"
	armor = list(MELEE = 35, BULLET = 30, LASER = 30, ENERGY = 40, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 10)

/obj/item/clothing/suit/armor/vest/infiltrator/gorlex_harness
	name = "Engine Technician Harness"
	desc = "A blood-red engineering technician harness. You can't seem to figure out a use to it, but it seems to seal magnetically in some places."
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "gorlexharness"

/obj/item/storage/box/firingpins/syndicate
	name = "box of syndicate firing pins"
	desc = "A box full of special syndicate firing pins which allow only syndicate operatives to use weapons with those firing pins."

/obj/item/storage/box/firingpins/syndicate/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/firing_pin/implant/pindicate(src)
