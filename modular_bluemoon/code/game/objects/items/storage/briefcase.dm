/obj/item/storage/briefcase/lawyer/family/loadout //changed due to PopulateContents() containing other stuff
	name = "battered briefcase"
	icon_state = "gbriefcase"
	lefthand_file = 'icons/mob/inhands/equipment/briefcase_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/briefcase_righthand.dmi'
	desc = "Старый кейс с золотой внутренней отделкой. Сегодня их не делают настолько же качественными. В комплекте с поясным карабином!"
	slot_flags = ITEM_SLOT_BELT

/obj/item/storage/briefcase/lawyer/family/loadout/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 7
	STR.max_items = 4
	STR.allow_other_storages = FALSE

/obj/item/storage/briefcase/lawyer/family/loadout/PopulateContents()
	new /obj/item/pen/fountain(src)
	new /obj/item/paper_bin(src)

/obj/item/case_with_bipki
	name = "\proper bipki case"
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
	light_color = LIGHT_COLOR_HOLY_MAGIC
	light_power = 10
	var/opened = FALSE

/obj/item/case_with_bipki/interact(mob/living/carbon/user)
	if(opened)
		return
	if(!istype(user))
		to_chat(user, "У вас не получается открыть этот чемодан.")
		return
	visible_message("[user] медленно и осторожно открывает чемодан с бипками...")
	if(!do_after(user, 5 SECONDS, src))
		return
	opened = TRUE
	update_icon(UPDATE_ICON_STATE)
	set_light(5)
	to_chat(user, "<span class='large_brass bold'>Вы видите бипки.</span>")
	stoplag(5 SECONDS)
	// user.dust()
	if(loc == user)
		user.dropItemToGround(src, silent = TRUE)
	user.fakedeath(src, FALSE)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, cure_fakedeath)), 60 SECONDS)
	stoplag(5 SECONDS)
	opened = FALSE
	update_icon(UPDATE_ICON_STATE)
	set_light(0)

/obj/item/case_with_bipki/update_icon_state()
	. = ..()
	icon_state = "briefcase_bipki[opened ? "_o" : ""]"

/obj/item/case_with_bipki/examine(mob/user)
	. = ..()
	if(opened)
		. += span_warning("Яркий свет не позволяет вам увидеть содержимое кейса.")
