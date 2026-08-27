/mob/living/carbon/human
	var/infiltrator_active = FALSE

/obj/item/mod/module/infiltrator
	name = "infiltrator MOD module"
	desc = "Скрывает ваше лицо от трекинга ИИ и чужих глаз, делая полностью неузнаваемым."
	icon_state = "infiltrator"
	complexity = 1
	idle_power_cost = 0
	removable = FALSE

/obj/item/mod/module/infiltrator/on_install()
	. = ..()
	var/obj/item/clothing/mod_part/head/head = mod.mod_parts[MOD_PART_HEAD]
	head.blockTracking = TRUE

/obj/item/mod/module/infiltrator/on_uninstall()
	. = ..()
	var/obj/item/clothing/mod_part/head/head = mod.mod_parts[MOD_PART_HEAD]
	head.blockTracking = FALSE

/obj/item/mod/module/infiltrator/on_suit_activation()
	. = ..()
	if(!mod.wearer)
		return
	mod.wearer.infiltrator_active = TRUE
	mod.wearer.set_bark("bump")
	mod.wearer.digitalcamo = TRUE
	mod.wearer.digitalinvis = TRUE
	// var/list/need_to_conseal = list()
	// wearer.apply_bodypart_overlays(need_to_conseal, update = TRUE, effect_datum = /datum/overlay_effect/mod_effect/white_noize)

/obj/item/mod/module/infiltrator/on_suit_deactivation()
	. = ..()
	mod.wearer.infiltrator_active = FALSE
	mod.wearer.set_bark(mod.wearer.client.prefs.bark_id)
	mod.wearer.digitalinvis = FALSE
	mod.wearer.digitalcamo = FALSE

/mob/living/carbon/human/GetVoice()
	. = ..()
	if(. == src.real_name && src.infiltrator_active == TRUE)
		return "Unknown"

/mob/living/carbon/human/examine(mob/user, silent)
	var/mob/living/carbon/human/H
	if(istype(user, /mob/living/carbon/human))
		H = user
	if(H && infiltrator_active && !H.infiltrator_active) //Если осматривающий это человек, у осматриваемого инфильтраторка активна и осматривающий не имеет активной инфильтраторки
		return . = span_big_warning("Вы не можете разглядеть совершенно ничего на теле этого существа.")
	else
		. = ..()

/mob/living/carbon/human/examine_more(mob/user)
	var/mob/living/carbon/human/H
	if(istype(user, /mob/living/carbon/human))
		H = user
	if(H && infiltrator_active && !H.infiltrator_active)
		return . = span_warning("Это существо одето в странный желтый МОД, но лицо и любые возможные приметы скрыты белым шумом.")
	else
		. = ..()

/obj/item/mod/module/storage_upgrader
	name = "MOD Storage Updgrader"
	desc = "Модуль расширения для хранилища МОДа, работающий за счёт технологии BLUESPACE.\
	Позволяет увеличить размер встроенного рюкзака до уроня БС сумки."
	var/obj/item/mod/module/storage/linked_storage_module

/obj/item/mod/module/storage_upgrader/on_install()
	. = ..()
	for(var/obj/item/mod/module/M in mod.modules)
		if(istype(M, /obj/item/mod/module/storage))
			linked_storage_module = M
	linked_storage_module.max_volume = STORAGE_VOLUME_MOD_UPLINK_UPDATER

/obj/item/mod/module/storage_upgrader/on_uninstall()
	. = ..()
	if(!linked_storage_module)
		return
	linked_storage_module.max_volume = initial(linked_storage_module.max_volume)
