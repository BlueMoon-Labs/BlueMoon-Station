/obj/item/clothing/under/bm/gift_ribbon
	name = "Gift ribbon"
	desc = "You know how to use it, right? You know... right?"
	icon_state = "gift_ribbon"
	mutantrace_variation = STYLE_DIGITIGRADE|USE_TAUR_CLIP_MASK|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/bm/sigu
	name = "SIGU"
	desc = "Tactical uniform of a special-special purpose unit."
	icon_state = "sigu"
	item_state = "coatsecurity"
	body_parts_covered = CHEST|ARMS
	armor = list(MELEE = 10, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 30, ACID = 30, WOUND = 20)

/obj/item/clothing/under/bm/regaloutfit
	name = "Regal-Looking Feminine Outfit"
	desc = "An erotic top and panties tucked under a skirt. Everywhere, on the folds, you can see gold inserts, how rich!"
	icon_state = "regal"
	item_state = "capspacehelmet"
	body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	armor = list(MELEE = 10, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 30, ACID = 30, WOUND = 10)

/obj/item/clothing/under/bm/utility
	name = "green utility uniform"
	desc = "A green utility uniform, eerily reminds of these that the Terrans use."
	icon_state = "utilgreen"

/obj/item/clothing/under/bm/utility/navy
	name = "navy utility uniform"
	desc = "A navy utility uniform, primarily seen in SolGov fleet use."
	icon_state = "utilnavy"

/obj/item/clothing/under/bm/utility/tan
	name = "tan utility uniform"
	desc = "A tan utility uniform, now all you need is a FUCKIN' CAS!"
	icon_state = "utiltan"

/obj/item/clothing/under/bm/chronos
	name = "new mecca uniform"
	desc = "In this suit, your grandfather fucked cromag."
	icon_state = "torch_uniform"
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS
	flags_inv = HIDEGLOVES|HIDESHOES
	alt_covers_chest = FALSE

/obj/item/clothing/under/dress/white
	name = "white dress"
	desc = "A tight white dress"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "dress_white"
	item_state = "dress_white"
	body_parts_covered = CHEST|GROIN
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/blackjumpskirt
	name = "black jumpskirt"
	desc = "A black jumpskirt, with a pink undershirt."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "blackjumpskirt"
	item_state = "blackjumpskirt"
	body_parts_covered = CHEST|GROIN|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/dress/gown
	name = "silk gown"
	desc = "A long silky sleeveless gown with a flared hem."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "gowndress"
	item_state = "gowndress"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE
	flags_inv = HIDESHOES
	alternate_worn_layer = ABOVE_SHOES_LAYER

/obj/item/clothing/under/dress/longdress
	name = "maxi dress"
	desc = "A sleeveless dress that reaches the wearer's ankles."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "longdress"
	item_state = "longdress"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE
	flags_inv = HIDESHOES
	alternate_worn_layer = ABOVE_SHOES_LAYER

/obj/item/clothing/under/dress/skirt/nightie
	name = "transparent nightie"
	desc = "Famous girls nightwear. You can see right through it!"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "nightie"
	item_state = "nightie"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/shortdress
	name = "short dress"
	desc = "A short plain sleeveless dress."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "shortdress"
	item_state = "shortdress"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/minidress
	name = "mini dress"
	desc = "A very short plain sleeveless dress. It almost covers nothing at all!"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "minidress"
	item_state = "minidress"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/tightevening
	name = "tight evening dress"
	desc = "A fancy short plain sleeveless dress. It is really tight!"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "tightevening"
	item_state = "tightevening"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/leather
	name = "leather skirt"
	desc = "A short skirt, made of leather material."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "skirt_leather"
	item_state = "skirt_leather"
	body_parts_covered = GROIN
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/short
	name = "short skirt"
	desc = "A short skirt, made of some semi-gloss material."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "skirt_short"
	item_state = "skirt_short"
	body_parts_covered = GROIN
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/long
	name = "long skirt"
	desc = "A long skirt, made of some semi-gloss material that reaches the wearer's ankles."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "skirt_long"
	item_state = "skirt_long"
	body_parts_covered = GROIN|LEGS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE
	flags_inv = HIDESHOES
	alternate_worn_layer = ABOVE_SHOES_LAYER

/obj/item/clothing/under/dress/skirt/pleatedmedium
	name = "pleated skirt"
	desc = "A pleated skirt, made of some semi-gloss material."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "skirt_pleated"
	item_state = "skirt_pleated"
	body_parts_covered = GROIN
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/pleatedshort
	name = "short pleated skirt"
	desc = "A short pleated skirt, made of some semi-gloss material."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "skirt_pleatedshort"
	item_state = "skirt_pleatedshort"
	body_parts_covered = GROIN
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/vintage
	name = "vintage dress"
	desc = "Makes you want to dance!"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "vintage_dress"
	item_state = "vintage_dress"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/polychromic/evening
	name = "fancy evening dress"
	desc = "An evening dress made with the finest silk."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "evening"
	item_state = "evening"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	body_parts_covered = GROIN|CHEST|ARMS
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE
	var/list/poly_colors = list("#391D2B", "#F96C72")

/obj/item/clothing/under/dress/polychromic/evening/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, poly_colors, 2)

/obj/item/clothing/under/dress/party
	name = "party dress"
	desc = "Fancy and with style!"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "party_dress"
	item_state = "party_dress"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/transparent
	name = "transparent skirt"
	desc = "A transparent skirt, made for concubines and belly dancers!"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "skirt_transparent"
	item_state = "skirt_transparent"
	body_parts_covered = GROIN
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/toga
	name = "half-shoulder white toga"
	desc = "A short simple cloth toga, covering just one of the shoulders. It has a fancy spheric golden button."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "toga"
	item_state = "toga"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/dress/skirt/lustymaid
	name = "Revealing Maid Uniform"
	desc = "A sexy maid uniform, that has a low cropped front to show off some chest, or bra. And a short dress that reveals thighs."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "maid_revealing"
	item_state = "maid_revealing"
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/dress/skirt/maidsexy
	name = "Sexy Maid Uniform"
	desc = "A sexy maid uniform that reveals everything."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "sexymaid"
	item_state = "sexymaid"
	body_parts_covered = NONE
	fitted = NO_FEMALE_UNIFORM
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/dress/turtledress
	name = "Turtleneck dress"
	desc = "It moves with the body, and it's flattering too, because it accentuates the face and elongates the figure."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "turtledress"
	item_state = "turtledress"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/commissar
	name = "Commissar Uniform"
	desc = "A great way to cosplay the hero of the Imperium!"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/uniform_digi.dmi'
	icon_state = "commissar"
	item_state = "commissar"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC

/obj/item/clothing/under/poly_sweater
	name = "polychromic sweater"
	desc = "A polychromic sweater."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "poly_sweater"
	item_state = "poly_sweater"
	body_parts_covered = CHEST | ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/poly_sweater/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_sweater(usr.loc)
				for(var/obj/item/clothing/accessory/poly_sweater/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_sweater(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_sweater/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_sweater(usr.loc)
				for(var/obj/item/clothing/under/poly_sweater/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)

/obj/item/clothing/under/poly_sweater_shoulderless
	name = "shoulderless polychromic sweater"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "poly_sweater_shoulderless"
	item_state = "poly_sweater_shoulderless"
	body_parts_covered = CHEST | ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/poly_sweater_shoulderless/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_sweater_shoulderless(usr.loc)
				for(var/obj/item/clothing/accessory/poly_sweater_shoulderless/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_sweater_shoulderless(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_sweater_shoulderless(usr.loc)
				for(var/obj/item/clothing/under/poly_sweater_shoulderless/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)

/obj/item/clothing/under/poly_sweater_shoulderlessalt
	name = "shoulderless polychromic sweater alt"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "poly_sweater_shoulderlessalt"
	item_state = "poly_sweater_shoulderlessalt"
	body_parts_covered = CHEST | ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/poly_sweater_shoulderlessalt/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_sweater_shoulderlessalt(usr.loc)
				for(var/obj/item/clothing/accessory/poly_sweater_shoulderlessalt/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_sweater_shoulderlessalt(usr.loc)
				for(var/obj/item/clothing/under/poly_sweater_shoulderlessalt/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)

/obj/item/clothing/under/poly_keyholesweater
	name = "polychromic keyhole sweater"
	desc = "What is the point of this, anyway?"
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	icon_state = "poly_keyholesweater"
	item_state = "poly_keyholesweater"
	body_parts_covered = CHEST | ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE

/obj/item/clothing/under/poly_keyholesweater/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_keyholesweater(usr.loc)
				for(var/obj/item/clothing/accessory/poly_keyholesweater/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_keyholesweater(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_keyholesweater/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_keyholesweater(usr.loc)
				for(var/obj/item/clothing/under/poly_keyholesweater/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)
