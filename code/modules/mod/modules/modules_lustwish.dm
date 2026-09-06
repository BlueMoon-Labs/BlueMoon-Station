/obj/item/mod/module/nudity_lover
	name = "Genitals Hardlight Module"
	desc = "Доработанный штатный проектор твёрдого цвета от Silver Love Co. \
	Позволяет беспрепядственно демонстрировать собственное тело даже в открытом космосе."
	icon_state = "genital_hardlight"
	custom_price = 50
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
	required_modpart_index = MOD_PART_HEAD
	overlay_state_active  = "module_hypno_overlay"
	overlay_icon_file ='icons/obj/clothing/modsuit/mod_modules.dmi'
	custom_price = 150
	var/list/allowed_overlay_skins = list(
		"lustwish",
		// "standard", не могу проверить сейчас, работает ли оно на рескине стандарт-ластвиш. Но на обычном стандарте выглядит плохо.
	)
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

/obj/item/mod/module/hypno_visor/on_suit_activation()
	if(!mod.is_active())
		return
	if(!iscarbon(mod.wearer) || !(mod.wearer.client?.prefs.cit_toggles & HYPNO))
		return to_chat(mod.wearer, span_warning("Разум сопротивляется гипно-эффектам: Отключение"))
	if(hypno_message == "" || isnull(hypno_message))
		hypno_message = "Чтобы настроить модуль нужно его вытащить и нажать рукой на нём кнопку."
	active = TRUE
	mod.wearer.gain_trauma(new /datum/brain_trauma/induced_hypnosis(hypno_message), TRAUMA_RESILIENCE_MAGIC)
	update_modsuit_slot()

/obj/item/mod/module/hypno_visor/on_suit_deactivation()
	if(!mod.wearer)
		return
	active = FALSE
	mod.wearer.cure_trauma_type(/datum/brain_trauma/induced_hypnosis, TRAUMA_RESILIENCE_MAGIC)
	update_modsuit_slot()

/obj/item/mod/module/hypno_visor/on_install()
	. = ..()
	if(!(mod.skin in allowed_overlay_skins))
		overlay_state_active = null

/obj/item/mod/module/hypno_visor/on_uninstall(deleting = FALSE)
	. = ..()
	if(isnull(overlay_state_active))
		overlay_state_active = initial(overlay_state_active)
