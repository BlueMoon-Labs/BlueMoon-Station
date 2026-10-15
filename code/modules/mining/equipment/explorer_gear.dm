/****************Explorer's Suit and Mask****************/
/obj/item/clothing/suit/hooded/explorer
	name = "Explorer Suit"
	desc = "An armoured suit for exploring harsh environments."
	icon_state = "explorer-normal"
	item_state = "explorer-normal"
	tail_state = "atmos"
	var/suit_type = "normal"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	cold_protection = CHEST|GROIN|LEGS|ARMS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	hoodtype = /obj/item/clothing/head/hooded/explorer
	armor_type = /datum/armor/suit_explorer
	flags_inv = HIDEJUMPSUIT|HIDETAUR|HIDETAIL
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe, /obj/item/device/cooler/lavaland) // BLUEMOON ADD - добавлен лавалендовский ПОУ
	resistance_flags = FIRE_PROOF
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC|STYLE_PAW_TAURIC
	no_t = TRUE

/obj/item/clothing/suit/hooded/explorer/standard/improved
	name = "E.D.N IV Suit"
	desc = "Укрепленная зимняя одежда с противоударными пластинами. Баллон на спине с некой субстанцией разносит по всему костюму оранжевую слабо-светящуюся жидкость. На плечевой пластине нанесена надпись: E.D.N IV."
	icon_state = "explorer-improved"
	item_state = "explorer-normal"
	hoodtype = /obj/item/clothing/head/hooded/explorer/standard/improved
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	armor_type = /datum/armor/suit_improved

/obj/item/clothing/suit/hooded/explorer/standard/improved/upgrade_icon(datum/source, amount, maxamount)
	if(amount)
		name = "reinforced [initial(name)]"
		suit_type = "explorer-improved_goliath"
		if(amount == maxamount)
			suit_type = "explorer-improved_goliath_full"
	icon_state = "[suit_type]"
	item_state = "[suit_type]"
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		if(wearer.wear_suit == src)
			wearer.update_inv_wear_suit()

/obj/item/clothing/suit/hooded/explorer/standard/improved/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		ADD_TRAIT(user, TRAIT_ASHSTORM_IMMUNE, "improved_suit")

/obj/item/clothing/suit/hooded/explorer/standard/improved/dropped(mob/living/carbon/human/user)
	..()
	if (HAS_TRAIT_FROM(user, TRAIT_ASHSTORM_IMMUNE, "improved_suit"))
		REMOVE_TRAIT(user, TRAIT_ASHSTORM_IMMUNE, "improved_suit")

/obj/item/clothing/head/hooded/explorer
	name = "Explorer Hood"
	desc = "An armoured hood for exploring harsh environments."
	icon_state = "explorer-normal"
	item_state = "explorer-normal"
	var/suit_type = "normal"
	var/basestate = "normal"
	body_parts_covered = HEAD
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	cold_protection = HEAD
	armor_type = /datum/armor/head_explorer
	resistance_flags = FIRE_PROOF

/obj/item/clothing/head/hooded/explorer/standard/improved
	name = "E.D.N IV Helmet"
	desc = "Укрепленный зимний шлем с противоударными пластинами."
	icon_state = "explorer-improved"
	item_state = "explorer-normal"
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	actions_types = list(/datum/action/item_action/toggle_helmet_light)
	armor_type = /datum/armor/head_improved

/obj/item/clothing/head/hooded/explorer/standard/improved/upgrade_icon(datum/source, amount, maxamount)
	if(amount)
		name = "reinforced [initial(name)]"
		suit_type = "explorer-improved_goliath"
		if(amount == maxamount)
			suit_type = "explorer-improved_goliath_full"
	icon_state = "[suit_type]"
	item_state = "[suit_type]"
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		if(wearer.head == src)
			wearer.update_inv_head()

/obj/item/clothing/head/hooded/explorer/standard/improved/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		ADD_TRAIT(user, TRAIT_ASHSTORM_IMMUNE, "improved_hood")

/obj/item/clothing/head/hooded/explorer/standard/improved/dropped(mob/living/carbon/human/user)
	..()
	if (HAS_TRAIT_FROM(user, TRAIT_ASHSTORM_IMMUNE, "improved_hood"))
		REMOVE_TRAIT(user, TRAIT_ASHSTORM_IMMUNE, "improved_hood")

/obj/item/clothing/suit/hooded/explorer/standard
	hoodtype = /obj/item/clothing/head/hooded/explorer/standard

/obj/item/clothing/head/hooded/explorer/standard

/obj/item/clothing/suit/hooded/explorer/standard/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/armor_plate)
	RegisterSignal(src, COMSIG_ARMOR_PLATED, PROC_REF(upgrade_icon))

/obj/item/clothing/suit/hooded/explorer/standard/proc/upgrade_icon(datum/source, amount, maxamount)
	if(amount)
		name = "reinforced [initial(name)]"
		suit_type = "normal_goliath"
		if(amount == maxamount)
			suit_type = "normal_goliath_full"
	icon_state = "explorer-[suit_type]"
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		if(wearer.wear_suit == src)
			wearer.update_inv_wear_suit()

/obj/item/clothing/head/hooded/explorer/standard/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/armor_plate)
	RegisterSignal(src, COMSIG_ARMOR_PLATED, PROC_REF(upgrade_icon))

/obj/item/clothing/head/hooded/explorer/standard/proc/upgrade_icon(datum/source, amount, maxamount)
	if(amount)
		name = "reinforced [initial(name)]"
		suit_type = "normal_goliath"
		if(amount == maxamount)
			suit_type = "normal_goliath_full"
	icon_state = "explorer-[suit_type]"
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		if(wearer.head == src)
			wearer.update_inv_head()

/obj/item/clothing/mask/gas/explorer
	name = "Explorer Gas Mask"
	desc = "A military-grade gas mask that can be connected to an air supply."
	icon_state = "gas_mining"
	item_state = "explorer_gasmask"
	visor_flags = BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS
	visor_flags_inv = HIDEFACIALHAIR
	visor_flags_cover = MASKCOVERSMOUTH
	actions_types = list(/datum/action/item_action/adjust)
	armor_type = /datum/armor/exo_and_explorer
	resistance_flags = FIRE_PROOF

/obj/item/clothing/mask/gas/explorer/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/gas/explorer/adjustmask(mob/user)
	..()
	w_class = mask_adjusted ? WEIGHT_CLASS_NORMAL : WEIGHT_CLASS_SMALL
	flags_inv = mask_adjusted ? (HIDEEYES|HIDEFACE|HIDEFACIALHAIR) : (HIDEEYES|HIDEFACE|HIDEFACIALHAIR|HIDESNOUT)
	user?.update_inv_head()

/obj/item/clothing/mask/gas/explorer/folded/Initialize(mapload)
	. = ..()
	adjustmask()

/obj/item/clothing/suit/space/hostile_environment
	name = "H.E.C.K. suit"
	desc = "Hostile Environment Cross-Kinetic Suit: A suit designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	item_state = "hostile_env"
	clothing_flags = THICKMATERIAL //not spaceproof
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF | GOLIATH_RESISTANCE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC|STYLE_PAW_TAURIC
	slowdown = 0
	armor_type = /datum/armor/hostile_environment_suit
	brc_mitigation_bonus = 15  // BLUEMOON ADD
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe)

/obj/item/clothing/suit/space/hostile_environment/equipped(mob/user, slot)  // BLUEMOON ADD
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING && brc_mitigation_bonus > 0 && isliving(user))
		user.brc_mitigation += brc_mitigation_bonus
		brc_worn = TRUE

/obj/item/clothing/suit/space/hostile_environment/dropped(mob/user)  // BLUEMOON ADD
	. = ..()
	if(brc_worn && isliving(user))
		user.brc_mitigation = max(0, user.brc_mitigation - brc_mitigation_bonus)
		brc_worn = FALSE

/obj/item/clothing/suit/space/hostile_environment/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/spraycan_paintable)
	START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/space/hostile_environment/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/clothing/suit/space/hostile_environment/process()
	var/mob/living/carbon/C = loc
	if(istype(C) && prob(2)) //cursed by bubblegum
		if(prob(15))
			new /datum/hallucination/oh_yeah(C)
			to_chat(C, "<span class='colossus'><b>[pick("I AM IMMORTAL.","I SHALL TAKE BACK WHAT'S MINE.","I SEE YOU.","YOU CANNOT ESCAPE ME FOREVER.","DEATH CANNOT HOLD ME.")]</b></span>")
		else
			to_chat(C, "<span class='warning'>[pick("You hear faint whispers.","You smell ash.","You feel hot.","You hear a roar in the distance.")]</span>")

/obj/item/clothing/head/helmet/space/hostile_environment
	name = "H.E.C.K. helmet"
	desc = "Hostile Environiment Cross-Kinetic Helmet: A helmet designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	item_state = "hostile_env"
	w_class = WEIGHT_CLASS_NORMAL
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	clothing_flags = THICKMATERIAL // no space protection
	armor_type = /datum/armor/hostile_environment_helmet
	resistance_flags = FIRE_PROOF | LAVA_PROOF

/obj/item/clothing/head/helmet/space/hostile_environment/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/spraycan_paintable)
	update_icon()


/obj/item/clothing/head/helmet/space/hostile_environment/update_overlays()
	. = ..()
	var/mutable_appearance/glass_overlay = mutable_appearance(icon, "hostile_env_glass")
	glass_overlay.appearance_flags = RESET_COLOR
	. += glass_overlay

/obj/item/clothing/head/helmet/space/hostile_environment/worn_overlays(isinhands, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(!isinhands)
		var/mutable_appearance/M = mutable_appearance('icons/mob/clothing/head.dmi', "hostile_env_glass")
		M.appearance_flags = RESET_COLOR
		. += M

/****************HEVA Suit and Mask****************/

/obj/item/clothing/suit/hooded/explorer/heva
	name = "HEVA suit"
	desc = "The Hazardous Environments extra-Vehicular Activity suit, developed by WanTon & Sons Perilous Mining and sold to Nanotrasen for missions within inhospitable, mineral-rich zones. \
			Its sleek plating deflects most biological - radioactive - and chemical substances and materials. Most notably, this will negate the effects of ash storms and give goliaths better grip against you."
	icon_state = "heva"
	item_state = "heva"
	w_class = WEIGHT_CLASS_BULKY
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	hoodtype = /obj/item/clothing/head/hooded/explorer/heva
	armor_type = /datum/armor/suit_heva
	resistance_flags = FIRE_PROOF | GOLIATH_WEAKNESS

/obj/item/clothing/head/hooded/explorer/heva
	name = "HEVA hood"
	desc = "The Hazardous Environments extra-Vehiclar Activity hood, developed by WanTon & Sons Perilous Mining. \
			Its sleek plating deflects most biological - radioactive - and chemical substances and materials. An instructive tag dictates that the provided mask is required for full protection."
	icon_state = "heva"
	item_state = "heva"
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	armor_type = /datum/armor/head_heva
	resistance_flags = FIRE_PROOF | GOLIATH_WEAKNESS
	mutantrace_variation = STYLE_MUZZLE

/obj/item/clothing/head/hooded/explorer/heva/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		ADD_TRAIT(user, TRAIT_ASHSTORM_IMMUNE, "heva_suit")

/obj/item/clothing/head/hooded/explorer/heva/dropped(mob/living/carbon/human/user)
	..()
	if (HAS_TRAIT_FROM(user, TRAIT_ASHSTORM_IMMUNE, "heva_suit"))
		REMOVE_TRAIT(user, TRAIT_ASHSTORM_IMMUNE, "heva_suit")

/obj/item/clothing/mask/gas/heva
	name = "HEVA mask"
	desc = "The Hazardous Environments extra-Vehiclar Activity mask, developed by WanTon & Sons Perilous Mining. \
			Its sleek plating deflects most biological - radioactive - and chemical substances and materials. An instructive tag dictates that the provided protective attire is required for full protection."
	icon_state = "heva"
	item_state = "heva"
	flags_inv = HIDEFACIALHAIR|HIDEFACE|HIDEEYES|HIDEEARS|HIDEHAIR
	armor_type = /datum/armor/mask_heva

/****************Exo-Suit and Mask****************/

/obj/item/clothing/suit/hooded/explorer/exo
	name = "Exo-suit"
	desc = "A robust suit for fighting dangerous animals. Its design and material make it harder for a Goliath to keep their grip on the wearer."
	icon_state = "exo"
	item_state = "exo"
	icon = 'modular_sand/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/suit_digi.dmi'
	w_class = WEIGHT_CLASS_BULKY
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	hoodtype = /obj/item/clothing/head/hooded/explorer/exo
	armor_type = /datum/armor/exo
	resistance_flags = FIRE_PROOF | GOLIATH_RESISTANCE

/obj/item/clothing/head/hooded/explorer/exo
	name = "Exo-hood"
	desc = "A robust helmet for fighting dangerous animals. Its design and material make it harder for a Goliath to keep their grip on the wearer."
	icon = 'modular_sand/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "exo"
	item_state = "exo"
	armor_type = /datum/armor/exo
	resistance_flags = FIRE_PROOF | GOLIATH_RESISTANCE

/obj/item/clothing/mask/gas/exo
	name = "Exosuit Mask"
	desc = "A face-covering mask that can be connected to an air supply. Intended for use with the Exosuit."
	icon_state = "exo"
	item_state = "exo"
	resistance_flags = FIRE_PROOF
	armor_type = /datum/armor/exo_and_explorer
