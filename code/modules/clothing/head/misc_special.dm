/*
 * Contents:
 *		Welding mask
 *		Cakehat
 *		Ushanka
 *		Pumpkin head
 *		Kitty ears
 *		Cardborg disguise
 *		Wig
 *		Bronze hat
 */

/*
 * Welding mask
 */
/obj/item/clothing/head/welding
	name = "Welding Helmet"
	desc = "A head-mounted face cover designed to protect the wearer completely from space-arc eye."
	icon_state = "welding"
	item_state = "welding"
	can_toggle = TRUE
	custom_materials = list(/datum/material/iron=1750, /datum/material/glass=400)
	flash_protect = 2
	tint = 2
	armor = list(MELEE = 10, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 60)
	actions_types = list(/datum/action/item_action/toggle)
	flags_inv = HIDEMASK|HIDEEYES|HIDEFACE
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	visor_flags_inv = HIDEMASK|HIDEEYES|HIDEFACE
	visor_flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	resistance_flags = FIRE_PROOF
	mutantrace_variation = STYLE_MUZZLE
	var/paint = null

/obj/item/clothing/head/welding/attack_self(mob/user)
	weldingvisortoggle(user)

/obj/item/clothing/head/welding/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/toy/crayon/spraycan))
		if(paint)
			to_chat(user, "<span class = 'warning'>Похоже, тут уже есть слой краски!</span>")
			return
		var/obj/item/toy/crayon/spraycan/C = I
		if(C.is_capped)
			to_chat(user, "<span class = 'warning'>Вы не можете раскрасить [src], пока крышка [C] закрыта!</span>")
			return
		var/list/weld_icons = list("Flame" = image(icon = src.icon, icon_state = "welding_redflame"),
									"Blue Flame" = image(icon = src.icon, icon_state = "welding_blueflame"),
									"White Flame" = image(icon = src.icon, icon_state = "welding_white"))
		var/list/weld = list("Flame" = "welding_redflame",
							"Blue Flame" = "welding_blueflame",
							"White Flame" = "welding_white")
		var/choice = show_radial_menu(user, src, weld_icons)
		if(!choice || I.loc != user || !Adjacent(user))
			return
		if(C.charges <= 0)
			to_chat(user, "<span class = 'warning'>Похоже, краска кончилась.</span>")
			return
		icon_state = weld[choice]
		paint = weld[choice]
		C.charges--
		update_icon()
	if(istype(I, /obj/item/soap) && (icon_state != initial(icon_state)))
		icon_state = initial(icon_state)
		paint = null
		update_icon()
	else
		return ..()

/*
 * Cakehat
 */
/obj/item/clothing/head/hardhat/cakehat
	name = "cakehat"
	desc = "You put the cake on your head. Brilliant."
	icon_state = "hardhat0_cakehat"
	item_state = "hardhat0_cakehat"
	hat_type = "cakehat"
	hitsound = 'sound/weapons/tap.ogg'
	flags_inv = HIDEEARS|HIDEHAIR
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	brightness_on = 2 //luminosity when on
	flags_cover = HEADCOVERSEYES
	heat = 1000

	beepsky_fashion = /datum/beepsky_fashion/cake

/obj/item/clothing/head/hardhat/cakehat/process()
	var/turf/location = src.loc
	if(ishuman(location))
		var/mob/living/carbon/human/M = location
		if(M.is_holding(src) || M.head == src)
			location = M.loc

	if(isturf(location))
		location.hotspot_expose(700, 1)

/obj/item/clothing/head/hardhat/cakehat/turn_on()
	..()
	force = 15
	throwforce = 15
	damtype = BURN
	hitsound = 'sound/items/welder.ogg'
	START_PROCESSING(SSobj, src)

/obj/item/clothing/head/hardhat/cakehat/turn_off()
	..()
	force = 0
	throwforce = 0
	damtype = BRUTE
	hitsound = 'sound/weapons/tap.ogg'
	STOP_PROCESSING(SSobj, src)

/obj/item/clothing/head/hardhat/cakehat/get_temperature()
	return on * heat
/*
 * Ushanka
 */
/obj/item/clothing/head/ushanka
	name = "ushanka"
	desc = "Perfect for winter in Siberia, da?"
	icon_state = "ushankadown"
	item_state = "ushankadown"
	alternate_screams = RUSSIAN_SCREAMS
	flags_inv = HIDEEARS|HIDEHAIR
	var/earflaps = TRUE
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = COAT_MAX_TEMP_PROTECT
	///Sprite visible when the ushanka flaps are folded up.
	var/upsprite = "ushankaup"
	///Sprite visible when the ushanka flaps are folded down.
	var/downsprite = "ushankadown"

	dog_fashion = /datum/dog_fashion/head/ushanka

/obj/item/clothing/head/ushanka/attack_self(mob/user)
	if(earflaps)
		icon_state = upsprite
		item_state = upsprite
		to_chat(user, "<span class='notice'>You raise the ear flaps on the ushanka.</span>")
	else
		icon_state = downsprite
		item_state = downsprite
		to_chat(user, "<span class='notice'>You lower the ear flaps on the ushanka.</span>")
	earflaps = !earflaps

/obj/item/clothing/head/ushanka/soviet
	name = "soviet ushanka"
	desc = "For the union!"
	flags_inv = HIDEEARS
	icon_state = "sovietushankadown"
	item_state = "sovietushankadown"
	upsprite = "sovietushankaup"
	downsprite = "sovietushankadown"

/obj/item/clothing/head/ushanka/black
	name = "Soviet Black Ushanka"
	desc = "For the union!"
	flags_inv = HIDEEARS
	icon_state = "blackushankadown"
	item_state = "blackushankadown"
	upsprite = "blackushankaup"
	downsprite = "blackushankadown"

/*
 * Pumpkin head
 */
/obj/item/clothing/head/hardhat/pumpkinhead
	name = "carved pumpkin"
	desc = "A jack o' lantern! Believed to ward off evil spirits."
	icon_state = "hardhat0_pumpkin"
	item_state = "hardhat0_pumpkin"
	hat_type = "pumpkin"
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	brightness_on = 2 //luminosity when on
	flags_cover = HEADCOVERSEYES

/*
 * Kitty ears
 */
/obj/item/clothing/head/kitty
	name = "kitty ears"
	desc = "A pair of kitty ears. Meow!"
	icon_state = "kitty"
	color = "#999999"
	dynamic_hair_suffix = ""

	dog_fashion = /datum/dog_fashion/head/kitty
	beepsky_fashion = /datum/beepsky_fashion/cat

/obj/item/clothing/head/kitty/equipped(mob/living/carbon/human/user, slot)
	if(ishuman(user) && slot == ITEM_SLOT_HEAD)
		update_icon(ALL, user)
		user.update_inv_head() //Color might have been changed by update_icon.
	..()

/obj/item/clothing/head/kitty/update_icon(updates, mob/living/carbon/human/user)
	. = ..()
	if(ishuman(user))
		add_atom_colour("#[user.hair_color]", FIXED_COLOUR_PRIORITY)

/obj/item/clothing/head/kitty/genuine
	desc = "A pair of kitty ears. A tag on the inside says \"Hand made from real cats.\""


/obj/item/clothing/head/hardhat/reindeer
	name = "novelty reindeer hat"
	desc = "Some fake antlers and a very fake red nose."
	icon_state = "hardhat0_reindeer"
	item_state = "hardhat0_reindeer"
	hat_type = "reindeer"
	flags_inv = 0
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	brightness_on = 1 //luminosity when on
	dynamic_hair_suffix = ""

	dog_fashion = /datum/dog_fashion/head/reindeer

/obj/item/clothing/head/cardborg
	name = "cardborg helmet"
	desc = "A helmet made out of a box."
	icon_state = "cardborg_h"
	item_state = "cardborg_h"
	flags_cover = HEADCOVERSEYES
	alternate_screams = list('modular_citadel/sound/voice/scream_silicon.ogg')
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT

	dog_fashion = /datum/dog_fashion/head/cardborg

/obj/item/clothing/head/cardborg/equipped(mob/living/user, slot)
	..()
	if(ishuman(user) && slot == ITEM_SLOT_HEAD)
		var/mob/living/carbon/human/H = user
		if(istype(H.wear_suit, /obj/item/clothing/suit/cardborg))
			var/obj/item/clothing/suit/cardborg/CB = H.wear_suit
			CB.disguise(user, src)

/obj/item/clothing/head/cardborg/dropped(mob/living/user)
	..()
	user.remove_alt_appearance("standard_borg_disguise")



/obj/item/clothing/head/wig
	name = "wig"
	desc = "A bunch of hair without a head attached."
	icon = 'icons/mob/hair.dmi'	  // default icon for all hairs
	icon_state = "hair_vlong"
	flags_inv = HIDEHAIR
	color = "#000"
	var/hair_style = "Very Long Hair"

/obj/item/clothing/head/wig/Initialize(mapload)
	. = ..()
	icon_state = "" //Shitty hack that i dont know if it is even neccesary to deal with the vendor stack exception
	update_icon()

/obj/item/clothing/head/wig/update_icon_state()
	var/datum/sprite_accessory/S = GLOB.hair_styles_list[hair_style]
	if(!S)
		icon = 'icons/obj/clothing/hats.dmi'
		icon_state = "pwig"
	else
		icon = S.icon
		icon_state = S.icon_state

/obj/item/clothing/head/wig/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(!isinhands)
		var/datum/sprite_accessory/S = GLOB.hair_styles_list[hair_style]
		if(!S)
			return
		var/mutable_appearance/M = mutable_appearance(S.icon, S.icon_state,layer = -HAIR_LAYER)
		M.appearance_flags |= RESET_COLOR
		M.color = color
		. += M

/obj/item/clothing/head/wig/random/Initialize(mapload)
	hair_style = pick(GLOB.hair_styles_list - "Bald") //Don't want invisible wig
	color = "#[random_short_color()]"
	. = ..()

/obj/item/clothing/head/bronze
	name = "bronze hat"
	desc = "A crude helmet made out of bronze plates. It offers very little in the way of protection."
	icon = 'icons/obj/clothing/clockwork_garb.dmi'
	icon_state = "clockwork_helmet_old"
	flags_inv = HIDEEARS|HIDEHAIR
	armor = list(MELEE = 5, BULLET = 0, LASER = -5, ENERGY = 0, BOMB = 10, BIO = 0, RAD = 0, FIRE = 20, ACID = 20)

/obj/item/clothing/head/foilhat
	name = "tinfoil hat"
	desc = "Thought control rays, psychotronic scanning. Don't mind that, I'm protected cause I made this hat."
	icon_state = "foilhat"
	item_state = "foilhat"
	armor = list(MELEE = 0, BULLET = 0, LASER = -5,ENERGY = 0, BOMB = 0, BIO = 0, RAD = -5, FIRE = 0, ACID = 0)
	equip_delay_other = 140
	var/datum/brain_trauma/mild/phobia/conspiracies/paranoia
	var/warped = FALSE
	clothing_flags = IGNORE_HAT_TOSS

/obj/item/clothing/head/foilhat/Initialize(mapload)
	. = ..()
	if(!warped)
		AddComponent(/datum/component/anti_magic, FALSE, FALSE, TRUE, ITEM_SLOT_HEAD, 6, TRUE, null, CALLBACK(src, PROC_REF(warp_up)))
	else
		warp_up()

/obj/item/clothing/head/foilhat/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_HEAD || warped)
		return
	if(paranoia)
		QDEL_NULL(paranoia)
	paranoia = new()
	paranoia.clonable = FALSE
	user.gain_trauma(paranoia, TRAUMA_RESILIENCE_MAGIC)
	to_chat(user, "<span class='warning'>As you don the foiled hat, an entire world of conspiracy theories and seemingly insane ideas suddenly rush into your mind. What you once thought unbelievable suddenly seems.. undeniable. Everything is connected and nothing happens just by accident. You know too much and now they're out to get you. </span>")

/obj/item/clothing/head/foilhat/MouseDrop(atom/over_object)
	//God Im sorry
	if(!warped && iscarbon(usr))
		var/mob/living/carbon/C = usr
		if(src == C.head)
			to_chat(C, "<span class='userdanger'>Why would you want to take this off? Do you want them to get into your mind?!</span>")
			return
	return ..()

/obj/item/clothing/head/foilhat/dropped(mob/user)
	. = ..()
	if(paranoia)
		QDEL_NULL(paranoia)

/obj/item/clothing/head/foilhat/proc/warp_up()
	name = "scorched tinfoil hat"
	desc = "A badly warped up hat. Quite unprobable this will still work against any of fictional and contemporary dangers it used to."
	warped = TRUE
	if(!isliving(loc) || !paranoia)
		return
	var/mob/living/target = loc
	if(target.get_item_by_slot(ITEM_SLOT_HEAD) != src)
		return
	QDEL_NULL(paranoia)
	if(!target.IsUnconscious())
		to_chat(target, "<span class='warning'>Your zealous conspirationism rapidly dissipates as the donned hat warps up into a ruined mess. All those theories starting to sound like nothing but a ridicolous fanfare.</span>")

/obj/item/clothing/head/foilhat/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!warped && iscarbon(user))
		var/mob/living/carbon/C = user
		if(src == C.head)
			to_chat(user, "<span class='userdanger'>Why would you want to take this off? Do you want them to get into your mind?!</span>")
			return
	return ..()

/obj/item/clothing/head/foilhat/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	if(!warped)
		warp_up()

//The "pocket" for the M1 helmet so you can tuck things into the elastic band

/datum/component/storage/concrete/pockets/tiny/spacenam
	attack_hand_interact = TRUE		//So you can actually see what you stuff in there

//families
/obj/item/clothing/head/irs
	name = "internal revenue service cap"
	icon_state = "irs_hat"
	item_state = "irs_hat"

/obj/item/clothing/head/pg
	name = "powder ganger beanie"
	icon_state = "pg_hat"
	item_state = "pg_hat"

/obj/item/clothing/head/tmc
	name = "Lost M.C. bandana"
	icon_state = "tmc_hat"
	item_state = "tmc_hat"

/obj/item/clothing/head/deckers
	name = "Decker headphones"
	icon_state = "decker_hat"
	item_state = "decker_hat"

/obj/item/clothing/head/morningstar
	name = "Morningstar beret"
	icon_state = "morningstar_hat"
	item_state = "morningstar_hat"

/obj/item/clothing/head/saints
	name = "Saints hat"
	icon_state = "saints_hat"
	item_state = "saints_hat"
	//BLUEMOON ADD рескин под шляпу из Sanabi
	unique_reskin = list(
		"Sanabi" = list(
			RESKIN_ICON_STATE = "sanabi_hat",
			RESKIN_ITEM_STATE = "sanabi_hat",
			RESKIN_ICON_STATE_FILE = 'modular_bluemoon/icons/obj/clothing/hats.dmi',
			RESKIN_WORN_STATE_FILE = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
		)
	)
	//BLUEMOON ADD END

/obj/item/clothing/head/allies
	name = "allies helmet"
	icon_state = "allies_helmet"
	item_state = "allies_helmet"

/obj/item/clothing/head/yuri
	name = "yuri initiate helmet"
	icon_state = "yuri_helmet"
	item_state = "yuri_helmet"
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT

/obj/item/clothing/head/sybil_slickers
	name = "sybil slickers helmet"
	icon_state = "football_helmet_blue"
	item_state = "football_helmet_blue"

/obj/item/clothing/head/basil_boys
	name = "basil boys helmet"
	icon_state = "football_helmet_red"
	item_state = "football_helmet_red"
