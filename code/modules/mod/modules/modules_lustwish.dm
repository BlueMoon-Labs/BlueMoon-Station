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
	module_type = MODULE_TOGGLE
	startup_with_suit = TRUE
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
	var/datum/weakref/trauma_ref
	var/hypno_message

/obj/item/mod/module/hypno_visor/Destroy()
	clear_hypnosis()
	return ..()

/obj/item/mod/module/hypno_visor/attack_self(mob/user)
	. = ..()
	edit_message(user)

/obj/item/mod/module/hypno_visor/proc/can_edit(mob/user)
	if(!user || user.incapacitated())
		return FALSE
	return mod ? (user == mod.wearer || user == mod.ai) : user.is_holding(src)

/obj/item/mod/module/hypno_visor/proc/edit_message(mob/user)
	if(!can_edit(user))
		return FALSE
	var/message = tgui_input_text(user, "Выберите гипно-фразу.", default = hypno_message, max_length = MAX_MESSAGE_LEN)
	if(isnull(message) || QDELETED(src) || !can_edit(user))
		return FALSE
	var/restart = active
	if(restart)
		on_deactivation()
	hypno_message = message
	if(restart)
		on_activation()
	return TRUE

/obj/item/mod/module/hypno_visor/get_configuration()
	. = ..()
	.["message"] = add_ui_configuration("Гипно-фраза", "text", hypno_message)

/obj/item/mod/module/hypno_visor/configure_edit(key, value)
	if(key == "message")
		return edit_message(usr)

/obj/item/mod/module/hypno_visor/on_activation()
	if(active)
		return TRUE
	if(!(mod?.wearer?.client?.prefs.cit_toggles & HYPNO))
		return FALSE
	if(!length(hypno_message) || !..())
		return FALSE
	var/datum/brain_trauma/induced_hypnosis/trauma = new(hypno_message)
	if(!mod.wearer.gain_trauma(trauma, TRAUMA_RESILIENCE_MAGIC))
		qdel(trauma)
		on_deactivation()
		return FALSE
	trauma_ref = WEAKREF(trauma)
	update_modsuit_slot()
	return TRUE

/obj/item/mod/module/hypno_visor/on_deactivation()
	clear_hypnosis()
	return ..()

/obj/item/mod/module/hypno_visor/proc/clear_hypnosis()
	var/datum/brain_trauma/trauma = trauma_ref?.resolve()
	trauma_ref = null
	if(trauma)
		qdel(trauma)

/obj/item/mod/module/hypno_visor/on_install()
	. = ..()
	if(!(mod.skin in allowed_overlay_skins))
		overlay_state_active = null

/obj/item/mod/module/hypno_visor/on_uninstall(deleting = FALSE)
	. = ..()
	if(isnull(overlay_state_active))
		overlay_state_active = initial(overlay_state_active)
