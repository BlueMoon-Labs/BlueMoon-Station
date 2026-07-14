/obj/item/inteq/uplink
	name = "InteQ uplink"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq-uplink.dmi'
	icon_state = "inteq-uplink"
	desc = "Обычная портативная рация, подключённая к местным телекоммуникационным сетям. (Можно уничтожить аплинк нажав Alt + Click.)"
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
	desc = "Обычная портативная рация, подключённая к местным телекоммуникационным сетям. (Можно уничтожить аплинк нажав Alt + Click.)"
	dog_fashion = /datum/dog_fashion/back

/obj/item/inteq/uplink/radio/nuclear
	name = "InteQ Radio Uplink"
	uplink_flag = UPLINK_NUKE_OPS

/obj/item/syndicate_uplink
	name = "Syndicate Uplink"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq-uplink.dmi'
	icon_state = "syndicate-uplink"
	item_state = "walkietalkie"
	desc = "Обычная портативная рация, подключённая к местным телекоммуникационным сетям. (Можно уничтожить аплинк нажав Alt + Click.)"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	dog_fashion = /datum/dog_fashion/back

	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL
	var/uplink_flag = UPLINK_SYNDICATE

/obj/item/syndicate_uplink/Initialize(mapload, owner, tc_amount = 10, syndicate = TRUE)
	. = ..()
	AddComponent(/datum/component/uplink/syndicate, owner, FALSE, TRUE, uplink_flag, tc_amount, syndicate)

/obj/item/syndicate_uplink/AltClick(mob/user)
	. = ..()
	var/pred = alert("Сжечь Аплинк?","Аплинк", "Да", "Нет")
	if(pred == "Да")
		to_chat(user, span_warning("Аплинк превращается в пепел на ваших глазах."))
		qdel(src)
	else
		return

//Аплинк экипажа Синдистанции

/obj/item/syndicate_uplink/station
	name = "Syndicate & Nanotrasen Crew Uplink"
	desc = "Аплинк, имеющий в своём ассортименте только разрешенные к использованию контрабандные предметы и \
			некоторые дополнительные, разрешенные ПАКТом элементы снабжения."
	uplink_flag = UPLINK_SYNDICATE_PACT_CREW

/obj/item/syndicate_uplink/station/Initialize(mapload, owner, tc_amount = 10, syndicate = TRUE)
	. = ..()
	var/datum/component/old_component = GetComponent(/datum/component/uplink/syndicate)
	old_component.Destroy()//я не смог решить иначе. Оно ТК суммирует :(
	AddComponent(/datum/component/uplink/syndicate/pact, owner, FALSE, TRUE, uplink_flag, tc_amount, syndicate)

/datum/component/uplink/syndicate/pact
	name = "Pact Uplink"

/datum/component/uplink/syndicate/pact/ui_data(mob/user)
	. = ..()
	.["uplink_type"] = name

/obj/item/syndicate_uplink_high
	name = "Great One Syndicate Uplink"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq-uplink.dmi'
	icon_state = "syndicate-uplink"
	item_state = "walkietalkie"
	desc = "Обычная портативная рация, подключённая к местным телекоммуникационным сетям. (Можно уничтожить аплинк нажав Alt + Click.)"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	dog_fashion = /datum/dog_fashion/back

	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL
	var/uplink_flag = UPLINK_SYNDICATE

/obj/item/syndicate_uplink_high/Initialize(mapload, owner, tc_amount = 10, syndicate = TRUE)
	. = ..()
	AddComponent(/datum/component/uplink/syndicate, owner, FALSE, TRUE, uplink_flag, tc_amount, syndicate)

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
