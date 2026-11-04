/obj/item/mod/module/remote_control
	name = "MOD remote control module"
	desc = "Позволяет владельцу связанного пульта управлять костюмом. Перед установкой извлеките пульт, активировав модуль в руке."
	icon = 'icons/obj/clothing/modsuit/mod_remote.dmi'
	icon_state = "module_remote"
	required_modpart_index = MOD_PART_CHEST
	mod_module_flags = MOD_MODULE_GENERAL
	incompatible_modules = list(/obj/item/mod/module/remote_control)
	overlay_state_inactive = "module_remote_overlay"
	overlay_icon_file = 'icons/obj/clothing/modsuit/mod_remote.dmi'
	var/datum/weakref/remote_ref

/obj/item/mod/module/remote_control/Initialize(mapload)
	. = ..()
	var/obj/item/mod/remote/remote = new(src, src)
	remote_ref = WEAKREF(remote)

/obj/item/mod/module/remote_control/attack_self(mob/user)
	var/obj/item/mod/remote/remote = remote_ref?.resolve()
	if(remote?.loc == src)
		user.put_in_hands(remote)
		return
	balloon_alert(user, "пульт уже извлечён")

/obj/item/mod/module/remote_control/can_install(obj/item/mod/control/suit, mob/user)
	var/obj/item/mod/remote/remote = remote_ref?.resolve()
	if(remote?.loc != src)
		return TRUE
	if(user)
		balloon_alert(user, "сначала извлеките пульт")
	return FALSE

/obj/item/mod/module/remote_control/Destroy()
	var/obj/item/mod/remote/remote = remote_ref?.resolve()
	if(remote?.loc == src)
		qdel(remote)
	else if(remote)
		remote.module_ref = null
	remote_ref = null
	return ..()

/obj/item/mod/remote
	name = "MOD remote control"
	desc = "Связанный пульт управления модульным костюмом. Тот, у кого находится пульт, может управлять костюмом."
	icon = 'icons/obj/clothing/modsuit/mod_remote.dmi'
	icon_state = "remote_item"
	w_class = WEIGHT_CLASS_SMALL
	var/datum/weakref/module_ref

/obj/item/mod/remote/Initialize(mapload, obj/item/mod/module/remote_control/module)
	. = ..()
	module_ref = module ? WEAKREF(module) : null

/obj/item/mod/remote/Destroy()
	module_ref = null
	return ..()

/obj/item/mod/remote/proc/get_suit()
	RETURN_TYPE(/obj/item/mod/control)
	var/obj/item/mod/module/remote_control/module = module_ref?.resolve()
	if(module && (module in module.mod?.modules))
		return module.mod
	return null

/obj/item/mod/remote/attack_self(mob/user)
	ui_interact(user)

/obj/item/mod/remote/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MODsuitRemote", name)
		ui.open()

/obj/item/mod/remote/ui_data(mob/user)
	var/obj/item/mod/control/suit = get_suit()
	var/list/data = suit ? suit.ui_data(user) : list()
	if(suit)
		data += suit.ui_static_data(user)
	data["linked_suit"] = !!suit
	return data

/obj/item/mod/remote/ui_static_data(mob/user)
	return get_suit()?.ui_static_data(user) || list()

/obj/item/mod/remote/ui_act(action, list/params)
	if(..())
		return TRUE
	return send_command(usr, action, params)

/obj/item/mod/remote/proc/send_command(mob/user, action, list/params)
	var/obj/item/mod/control/suit = get_suit()
	if(!suit || !user?.canUseTopic(src, BE_CLOSE))
		return FALSE
	return suit.handle_ui_action(action, params, user)
