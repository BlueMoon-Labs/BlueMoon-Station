///////////////
//Tools  Arms//
///////////////

/obj/item/organ/cyberimp/arm/toolset/advanced
	name = "advanced integrated toolset implant"
	desc = "A very advanced version of the regular toolset implant, has alien stuff!"
// 	BLUEMOON COMMENTING OUT using own list of tools below
//	contents = newlist(/obj/item/screwdriver/abductor,
//						/obj/item/wrench/abductor,
//						/obj/item/weldingtool/abductor,
//						/obj/item/crowbar/abductor,
//						/obj/item/wirecutters/abductor,
//						/obj/item/multitool/abductor,
//						/obj/item/analyzer/ranged)
// 	BLUEMOON ADD START
	contents = newlist(/obj/item/screwdriver/advanced,
						/obj/item/crowbar/advanced,
						/obj/item/wrench/advanced,
						/obj/item/wirecutters/advanced,
						/obj/item/weldingtool/advanced,
						/obj/item/analyzer/ranged,
						/obj/item/multitool/advanced)
// 	BLUEMOON ADD END

/obj/item/organ/cyberimp/arm/toolset/advanced/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s integrated dagger!</span>")
	add_item(new /obj/item/pen/edagger)
	return TRUE

/obj/item/organ/cyberimp/arm/surgery/advanced
	name = "advanced integrated surgical implant"
	desc = "A very advanced version of the regular surgical implant, has alien stuff!"
	contents = newlist(/obj/item/surgical_drapes/advanced,
						/obj/item/scalpel/alien,
						/obj/item/hemostat/alien,
						/obj/item/retractor/alien,
						/obj/item/circular_saw/alien,
						/obj/item/cautery/alien,
						/obj/item/blood_filter/augment,
						/obj/item/surgicaldrill/alien)

/obj/item/organ/cyberimp/arm/surgery/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s integrated dagger!</span>")
	add_item(/obj/item/pen/edagger)
	return TRUE
