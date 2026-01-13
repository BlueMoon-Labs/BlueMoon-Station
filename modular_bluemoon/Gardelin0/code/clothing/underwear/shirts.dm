/obj/item/clothing/underwear/shirt/blouse_female
	name = "feminie blouse"
	desc = "A feminie blouse."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "blouse_female"
	under_type = /obj/item/clothing/underwear/shirt
	body_parts_covered = CHEST | ARMS
	slot_flags = ITEM_SLOT_SHIRT
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/underwear/shirt/longsleeve_croptop
	name = "longsleeve croptop"
	desc = "A longsleeve croptop."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "longsleeve_croptop"
	under_type = /obj/item/clothing/underwear/shirt
	body_parts_covered = CHEST | ARMS
	slot_flags = ITEM_SLOT_SHIRT

/obj/item/clothing/underwear/shirt/longsleeve_croptop_female
	name = "feminie longsleeve croptop"
	desc = "A longsleeve croptop. This variation is made for females."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "longsleeve_croptop_female"
	under_type = /obj/item/clothing/underwear/shirt
	body_parts_covered = CHEST | ARMS
	slot_flags = ITEM_SLOT_SHIRT
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/underwear/shirt/formalshirt
	name = "formal shirt"
	desc = "A formal shirt."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "formalshirt"
	body_parts_covered = CHEST | ARMS

/obj/item/clothing/underwear/shirt/poly_shirt
	name = "polychromic shirt"
	desc = "A polychromic shirt with long sleeves."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_shirt"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_shirt/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_lightshirt
	name = "polychromic light shirt"
	desc = "A light polychromic shirt without long sleeves."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_lightshirt"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_lightshirt/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/formalshirt_light
	name = "light formal shirt"
	desc = "A light formal shirt without sleeves."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "formalshirt_light"
	body_parts_covered = CHEST

/obj/item/clothing/underwear/shirt/transparent_top
	name = "transparent top"
	desc = "A transparent top, made for concubines and belly dancers!"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "transparent_top"
	body_parts_covered = CHEST

/obj/item/clothing/underwear/shirt/poly_corset
	name = "polychromic corset"
	desc = "A polychromic corset. Nanotrasen is not resposible for any organ damage."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_corset"
	body_parts_covered = CHEST
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_corset/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/revealing_shirt
	name = "revealing shirt"
	desc = "A sexy office uniform, that has a low cropped front to show off some chest, or bra."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "revealing_shirt"
	body_parts_covered = ARMS
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/underwear/shirt/poly_shortertop
	name = "polychromic short top"
	desc = "A short polychromic top."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_shortertop"
	body_parts_covered = CHEST
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_shortertop/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/formalshirt_thin
	name = "thin formal shirt"
	desc = "A formal shirt made out of thin material."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "formalshirt_thin"
	body_parts_covered = CHEST | ARMS

/obj/item/clothing/underwear/shirt/poly_mesh
	name = "polychromic mesh top"
	desc = "A transparent polychromic top made for those, who love to reveal their chest with style. Great with pantyhose!"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_mesh"
	body_parts_covered = CHEST
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_mesh/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater
	name = "polychromic sweater"
	desc = "A polychromic sweater."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_sweater"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_sweater/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater/verb/worn_layer()
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

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless
	name = "shoulderless polychromic sweater"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_sweater_shoulderless"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless/verb/worn_layer()
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

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt
	name = "shoulderless polychromic sweater alt"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_sweater_shoulderlessalt"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt/verb/worn_layer()
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

/obj/item/clothing/underwear/shirt/poly_keyholesweater
	name = "polychromic keyhole sweater"
	desc = "What is the point of this, anyway?"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	icon_state = "poly_keyholesweater"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_keyholesweater/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_keyholesweater/verb/worn_layer()
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
