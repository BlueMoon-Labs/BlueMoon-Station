/obj/item/storage/briefcase/lawyer/family/loadout //changed due to PopulateContents() containing other stuff
	name = "battered  briefcase"
	icon_state = "gbriefcase"
	lefthand_file = 'icons/mob/inhands/equipment/briefcase_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/briefcase_righthand.dmi'
	desc = "An old briefcase with a golden trim. It's clear they don't make them as good as they used to. Comes with an added belt clip!"
	slot_flags = ITEM_SLOT_BELT

/obj/item/storage/briefcase/lawyer/family/loadout/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 14

/obj/item/storage/briefcase/lawyer/family/loadout/PopulateContents()
	new /obj/item/pen/fountain(src)
	new /obj/item/paper_bin(src)

/obj/item/case_with_bipki
	name = "bipki case"
	desc = "Легендарный чемодан с бипками! Стоп, а что такое бипки?"
	icon = 'modular_bluemoon/icons/obj/bipki.dmi'
	icon_state = "briefcase_bipki"
	lefthand_file = 'icons/mob/inhands/equipment/briefcase_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/briefcase_righthand.dmi'
	item_state = "briefcase"
	force = 8
	attack_verb = list("ударил", "огрел")
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	w_class = WEIGHT_CLASS_BULKY
	var/opened = FALSE

/obj/item/case_with_bipki/interact(mob/living/carbon/user)
	if(!istype(user))
		to_chat(user, "У вас не получается открыть этот чемодан.")
		return
	visible_message("[user] медленно и осторожно открывает чемодан с бипками...")
	if(!do_after(user, 5 SECONDS, src))
		return
	opened = TRUE
	update_icon(UPDATE_ICON_STATE)
	to_chat(user, "<span class='large_brass bold'>Вы видите бипки.</span>")
	stoplag(3 SECONDS)
	// user.dust()
	user.dropItemToGround(src, TRUE, TRUE)
	user.fakedeath(src, FALSE)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, cure_fakedeath)), 60 SECONDS)
	stoplag(4 SECONDS)
	opened = FALSE
	update_icon(UPDATE_ICON_STATE)

/obj/item/case_with_bipki/update_icon_state()
	. = ..()
	icon_state = "briefcase_bipki[opened ? "_o" : ""]"

/obj/item/case_with_bipki/examine(mob/user)
	. = ..()
	if(opened)
		. += span_warning("Яркий свет не позволяет вам увидеть содержимое кейса.")
