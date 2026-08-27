/mob/living/carbon/human
	var/infiltrator_active = FALSE

/obj/item/mod/module/infiltrator
	name = "infiltrator MOD module"
	desc = "Скрывает ваше лицо от трекинга ИИ и чужих глаз, делая полностью неузнаваемым."
	icon_state = "infiltrator"
	module_type = MODULE_TOGGLE
	complexity = 1
	idle_power_cost = 0
	removable = FALSE
	required_modpart_index = MOD_PART_HEAD
	startup_with_suit = TRUE

/obj/item/mod/module/infiltrator/on_install()
	. = ..()
	var/obj/item/clothing/mod_part/head/head = mod.mod_parts[MOD_PART_HEAD]
	head.blockTracking = TRUE

/obj/item/mod/module/infiltrator/on_uninstall()
	. = ..()
	var/obj/item/clothing/mod_part/head/head = mod.mod_parts[MOD_PART_HEAD]
	head.blockTracking = FALSE

/obj/item/mod/module/infiltrator/on_activation()
	. = ..()
	if(!mod.wearer || !.) //если родитель выдал FALSE
		return
	mod.wearer.infiltrator_active = TRUE
	mod.wearer.set_bark("bump")
	mod.wearer.digitalcamo = TRUE
	mod.wearer.digitalinvis = TRUE

/obj/item/mod/module/infiltrator/on_deactivation()
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
