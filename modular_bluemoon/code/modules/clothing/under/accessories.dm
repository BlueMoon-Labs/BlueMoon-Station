//regular
/obj/item/clothing/accessory/badge_nt
	name = "NT specialist badge"
	desc = "A regular badge given to NT employees"
	icon_state = "badge_nt"
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'

/obj/item/clothing/accessory/badge_syndi
	name = "Syndicate specialist badge"
	desc = "A regular badge given to Syndicate employees"
	icon_state = "badge_syndi"
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'

/obj/item/clothing/accessory/armband/hcaarmband
	name = "HCA armband"
	desc = "A black and white armband depicting two swords crossed around the fascia within wreaths representing prosperity. This flag refers to the political party of the Human Commonwealth."
	icon_state = "hcaarmbanditem"
	item_state = "hcaarmbanditem"
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'
	strip_delay = 60
	dog_fashion = null

/obj/item/clothing/accessory/armband/polyband
	name = "medical guard armband"
	desc = "An armband, usually worn by the station's security forces to display which department they're assigned to."
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'
	icon_state = "polyband"

/obj/item/clothing/accessory/waistcoat_color
	name = "waistcoat"
	desc = "For some classy, murderous fun."
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'
	icon_state = "waistcoat_color"
	item_state = "waistcoat_color"
	minimize_when_attached = FALSE

/obj/item/clothing/accessory/poly_sweater
	name = "polychromic sweater"
	desc = "A polychromic sweater."
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'
	icon_state = "poly_sweater"
	item_state = "poly_sweater"
	minimize_when_attached = FALSE

/obj/item/clothing/accessory/poly_sweater/verb/worn_layer()
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

/obj/item/clothing/accessory/poly_sweater_shoulderless
	name = "shoulderless polychromic sweater"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'
	icon_state = "poly_sweater_shoulderless"
	item_state = "poly_sweater_shoulderless"
	minimize_when_attached = FALSE

/obj/item/clothing/accessory/poly_sweater_shoulderless/verb/worn_layer()
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

/obj/item/clothing/accessory/poly_sweater_shoulderlessalt
	name = "shoulderless polychromic sweater alt"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'
	icon_state = "poly_sweater_shoulderlessalt"
	item_state = "poly_sweater_shoulderlessalt"
	minimize_when_attached = FALSE

/obj/item/clothing/accessory/poly_sweater_shoulderlessalt/verb/worn_layer()
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

/obj/item/clothing/accessory/poly_keyholesweater
	name = "polychromic keyhole sweater"
	desc = "What is the point of this, anyway?"
	icon = 'modular_bluemoon/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/accessories.dmi'
	icon_state = "poly_keyholesweater"
	item_state = "poly_keyholesweater"
	minimize_when_attached = FALSE

/obj/item/clothing/accessory/poly_keyholesweater/verb/worn_layer()
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
