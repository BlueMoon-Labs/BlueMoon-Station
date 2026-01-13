/obj/item/inteq/uplink
	name = "InteQ uplink"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq-uplink.dmi'
	icon_state = "inteq-uplink"
	desc = "A basic handheld radio that communicates with local telecommunication networks. (You can turn Uplink to dust if you Alt + Click it.)"
	dog_fashion = /datum/dog_fashion/back

	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL

	var/uplink_flag = UPLINK_TRAITORS

/obj/item/inteq/uplink/Initialize(mapload, owner, tc_amount = 30)
	. = ..()
	AddComponent(/datum/component/uplink/inteq, owner, FALSE, TRUE, uplink_flag, tc_amount)

/obj/item/inteq/uplink/AltClick(mob/user)
	. = ..()
	var/pred = alert("Сжечь Аплинк?","Аплинк", "Да", "Нет")
	if(pred == "Да")
		to_chat(user, span_warning("Аплинк превращается в пепел на ваших глазах."))
		new /obj/effect/decal/cleanable/ash(get_turf(user))
		qdel(src)
	else
		return

/obj/item/inteq/uplink/radio
	name = "InteQ Radio Uplink"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq-uplink.dmi'
	icon_state = "inteq-uplink"
	desc = "A basic handheld radio that communicates with local telecommunication networks. (You can turn Uplink to dust if you Alt + Click it.)"
	dog_fashion = /datum/dog_fashion/back

/obj/item/inteq/uplink/radio/nuclear
	name = "InteQ Radio Uplink"
	uplink_flag = UPLINK_NUKE_OPS

/obj/item/syndicate_uplink
	name = "Syndicate Uplink"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq-uplink.dmi'
	icon_state = "syndicate-uplink"
	item_state = "walkietalkie"
	desc = "A basic handheld radio that communicates with local telecommunication networks. (You can turn Uplink to dust if you Alt + Click it.)"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	dog_fashion = /datum/dog_fashion/back

	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL
	var/uplink_flag = UPLINK_SYNDICATE

/obj/item/syndicate_uplink/Initialize(mapload, owner, tc_amount = 10)
	. = ..()
	AddComponent(/datum/component/uplink/syndicate, owner, FALSE, TRUE, uplink_flag, tc_amount)

/obj/item/syndicate_uplink/AltClick(mob/user)
	. = ..()
	var/pred = alert("Сжечь Аплинк?","Аплинк", "Да", "Нет")
	if(pred == "Да")
		to_chat(user, span_warning("Аплинк превращается в пепел на ваших глазах."))
		qdel(src)
	else
		return

/obj/item/syndicate_uplink_high
	name = "Great One Syndicate Uplink"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq-uplink.dmi'
	icon_state = "syndicate-uplink"
	item_state = "walkietalkie"
	desc = "A basic handheld radio that communicates with local telecommunication networks. (You can turn Uplink to dust if you Alt + Click it.)"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	dog_fashion = /datum/dog_fashion/back

	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL
	var/uplink_flag = UPLINK_SYNDICATE

/obj/item/syndicate_uplink_high/Initialize(mapload, owner, tc_amount = 20)
	. = ..()
	AddComponent(/datum/component/uplink/syndicate, owner, FALSE, TRUE, uplink_flag, tc_amount)

/obj/item/syndicate_uplink_high/AltClick(mob/user)
	. = ..()
	var/pred = alert("Сжечь Аплинк?","Аплинк", "Да", "Нет")
	if(pred == "Да")
		to_chat(user, span_warning("Аплинк превращается в пепел на ваших глазах."))
		qdel(src)
	else
		return

/obj/item/syndicate_uplink_high/nuclear
	name = "syndicate strike team uplink"
	uplink_flag = UPLINK_SYNDICATE
