/obj/item/reagent_containers/crack
	name = "crack"
	desc = "A rock of freebase cocaine, otherwise known as crack."
	icon = 'modular_bluemoon/cocaine/icons/crack.dmi'
	icon_state = "crack"
	volume = 10
	list_reagents = list(/datum/reagent/drug/cocaine/freebase_cocaine = 10)

/obj/item/reagent_containers/crackbrick
	name = "crack brick"
	desc = "A brick of crack cocaine."
	icon = 'modular_bluemoon/cocaine/icons/crack.dmi'
	icon_state = "crackbrick"
	volume = 40
	list_reagents = list(/datum/reagent/drug/cocaine/freebase_cocaine = 40)

/obj/item/reagent_containers/crackbrick/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(attacking_item.get_sharpness())
		user.visible_message(span_notice("[user] starts cutting \the [src] into rocks."))
		if(do_after(user, 2 SECONDS, target = src))
			user.show_message(span_notice("You cut \the [src] into some rocks."), MSG_VISUAL)
			for(var/i = 1 to 4)
				new /obj/item/reagent_containers/crack(user.loc)
			qdel(src)

/datum/crafting_recipe/crackbrick
	name = "Crack brick"
	result = /obj/item/reagent_containers/crackbrick
	reqs = list(/obj/item/reagent_containers/crack = 4)
	parts = list(/obj/item/reagent_containers/crack = 4)
	time = 20
	category = CAT_CHEMISTRY

/obj/item/reagent_containers/cocaine
	name = "cocaine"
	desc = "Reenact your favorite scenes from Scarface!"
	icon = 'modular_bluemoon/cocaine/icons/crack.dmi'
	icon_state = "cocaine"
	volume = 5
	list_reagents = list(/datum/reagent/drug/cocaine = 5)

/obj/item/reagent_containers/cocaine/proc/snort(mob/living/user)
	if(!iscarbon(user))
		return
	var/mob/living/carbon/C = user
	var/covered = ""
	if(C.is_mouth_covered(head_only = 1))
		covered = "headgear"
	else if(C.is_mouth_covered(mask_only = 1))
		covered = "mask"
	if(covered)
		to_chat(user, span_warning("You have to remove your [covered] first!"))
		return
	var/obj/item/organ/lungs/lungs = C.getorganslot(ORGAN_SLOT_LUNGS)
	if(isnull(lungs))
		to_chat(user, span_warning("You have to be able to breathe to snort the cocaine!"))
		return
	user.visible_message(span_notice("[user] starts snorting the [src]."))
	if(do_after(user, 3 SECONDS, target = src))
		to_chat(user, span_notice("You finish snorting the [src]."))
		if(reagents.total_volume)
			reagents.trans_to(user, reagents.total_volume, log = "snort cocaine")
		qdel(src)

/obj/item/reagent_containers/cocaine/attack_self(mob/user)
	snort(user)

/obj/item/reagent_containers/cocainebrick
	name = "cocaine brick"
	desc = "A brick of cocaine. Good for transport!"
	icon = 'modular_bluemoon/cocaine/icons/crack.dmi'
	icon_state = "cocainebrick"
	volume = 25
	list_reagents = list(/datum/reagent/drug/cocaine = 25)

/obj/item/reagent_containers/cocainebrick/attack_self(mob/user)
	user.visible_message(span_notice("[user] starts breaking up the [src]."))
	if(do_after(user, 1 SECONDS, target = src))
		to_chat(user, span_notice("You finish breaking up the [src]."))
		for(var/i = 1 to 5)
			new /obj/item/reagent_containers/cocaine(user.loc)
		qdel(src)

/datum/crafting_recipe/cocainebrick
	name = "Cocaine brick"
	result = /obj/item/reagent_containers/cocainebrick
	reqs = list(/obj/item/reagent_containers/cocaine = 5)
	parts = list(/obj/item/reagent_containers/cocaine = 5)
	time = 20
	category = CAT_CHEMISTRY

/datum/export/crack   // Всё ниженаписанное в два раза дешевле, чем в НовоТГ, адаптировано под экономику БлюМуна
	cost = CARGO_CRATE_VALUE * 0.25
	unit_name = "crack"
	export_types = list(/obj/item/reagent_containers/crack)
	include_subtypes = FALSE

/datum/export/crack/crackbrick
	cost = CARGO_CRATE_VALUE * 1.5
	unit_name = "crack brick"
	export_types = list(/obj/item/reagent_containers/crackbrick)
	include_subtypes = FALSE

/datum/export/cocaine
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "cocaine"
	export_types = list(/obj/item/reagent_containers/cocaine)
	include_subtypes = FALSE

/datum/export/cocainebrick
	cost = CARGO_CRATE_VALUE * 1.25
	unit_name = "cocaine brick"
	export_types = list(/obj/item/reagent_containers/cocainebrick)
	include_subtypes = FALSE
