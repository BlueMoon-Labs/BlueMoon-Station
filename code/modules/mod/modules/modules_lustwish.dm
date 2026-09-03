/obj/item/mod/module/nudity_lover
	name = "Genitals Hardlight Module"
	desc = "Доработанный штатный проектор твёрдого цвета от Silver Love Co. \
	Позволяет беспрепядственно демонстрировать собственное тело даже в открытом космосе."
	complexity = 0
	idle_power_cost = 0

/obj/item/mod/module/nudity_lover/on_install()
	. = ..()
	mod.allowed_genital_overlays = TRUE

/obj/item/mod/module/nudity_lover/on_uninstall()
	. = ..()
	mod.allowed_genital_overlays = FALSE

/obj/item/mod/module/hypno_visor
	name = "hypnosis module"
	desc = "A module inserted into the visor of a suit in which commands can be processed. Use on self to set directives."
	icon_state = "module_hypno"
	module_type = MODULE_PASSIVE
	complexity = 0
	idle_power_cost = 0
	incompatible_modules = list(/obj/item/mod/module/hypno_visor)
	// required_slots = list(ITEM_SLOT_HEAD)
	// overlay_state_inactive = "module_hypno_overlay"
	// overlay_icon_file
	var/hypno_message

/obj/item/mod/module/hypno_visor/Destroy()
	if(!mod)
		return ..()
	if(mod.wearer) //&& part_activated
		mod.wearer.cure_trauma_type(/datum/brain_trauma/induced_hypnosis, TRAUMA_RESILIENCE_MAGIC)
	return ..()

/obj/item/mod/module/hypno_visor/attack_self(mob/user)
	. = ..()
	hypno_message = tgui_input_text(user, "Выберите гипно-фразу.", max_length = MAX_MESSAGE_LEN)

//Тут важно доработать сигналы для on_part_activation и deactivation
//так же иметь переменную part_activated для проверок.

// /obj/item/mod/module/hypno_visor/on_part_activation()
// 	if(mod.wearer.client?.prefs.cit_toggles & HYPNO)
// 		return to_chat(mod.wearer, span_warning("Разум сопротивляется гипно-эффектам: Отключение"))
// 	if(hypno_message == "" || isnull(hypno_message))
// 		hypno_message = "Подчиняйся"
// 	mod.wearer.gain_trauma(new /datum/brain_trauma/induced_hypnosis(hypno_message), TRAUMA_RESILIENCE_MAGIC)

// /obj/item/mod/module/hypno_visor/on_part_deactivation(deleting = FALSE)
// 	mod.wearer.cure_trauma_type(/datum/brain_trauma/induced_hypnosis, TRAUMA_RESILIENCE_MAGIC)

// /obj/item/mod/module/hypno_visor/on_install()
// 	. = ..()
// 	if(mod.skin != "lustwish")
// 		overlay_state_inactive = null // Visual thing. Removes the overlay if it's not a part of the lustwish suit.

// /obj/item/mod/module/hypno_visor/on_uninstall(deleting = FALSE)
// 	. = ..()
// 	if(isnull(overlay_state_inactive))
// 		overlay_state_inactive = initial(overlay_state_inactive)
